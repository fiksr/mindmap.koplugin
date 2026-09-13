--[[--
MindMap Main Plugin for KOReader.
Provides AI Character Relationship Webs, Faction Maps, and Chronological Plot Timelines.
--]]--

local Device = require("device")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local util = require("util")
local _ = require("gettext")

-- Safe submodule loader
local plugin_dir = debug.getinfo(1, "S").source:match("@?(.*[/\\])") or ""
local Settings = dofile(plugin_dir .. "settings.lua")
local API = dofile(plugin_dir .. "api.lua")
local Visualizer = dofile(plugin_dir .. "visualizer.lua")
local Dialog = dofile(plugin_dir .. "dialog.lua")

-- Register into KOReader's menu order system
local function addToMenuOrder(module_path, section, name)
    local ok, order = pcall(require, module_path)
    if ok and order and order[section] then
        for idx, v in ipairs(order[section]) do
            if v == name then return end
        end
        table.insert(order[section], name)
    end
end
addToMenuOrder("ui/elements/reader_menu_order", "more_tools", "mindmap")
addToMenuOrder("ui/elements/filemanager_menu_order", "more_tools", "mindmap")

local MindMap = WidgetContainer:extend{
    name = "mindmap",
    is_doc_only = false,
}

function MindMap:init()
    self.settings = Settings:new()
    self.api = API:new(self.settings)

    if self.ui and self.ui.highlight then
        self:addToHighlightDialog()
    end

    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
end

function MindMap:getBookContext()
    local doc = self.ui and self.ui.document
    local props = (doc and doc.getProps and doc:getProps()) or (self.ui and self.ui.doc_props) or {}

    local title = props.display_title or props.title or (doc and doc.file and doc.file:match("([^/]+)%.%w+$")) or "Untitled Book"
    local author = props.authors or props.author or "Unknown Author"

    local t_part, a_part = title:match("^(.-)%s+[%-–—]%s+(.+)$")
    if t_part and a_part and #t_part > 0 and #a_part > 0 then
        title = t_part
        if not author or author == "Unknown Author" or #author == 0 then
            author = a_part
        end
    end

    local chapter_title = nil
    if self.ui and self.ui.toc and self.ui.toc.getTocTitleOfCurrentPage then
        local ok_ct, ct = pcall(function() return self.ui.toc:getTocTitleOfCurrentPage() end)
        if ok_ct and ct and #ct > 0 then
            chapter_title = ct:gsub("[\r\n]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    local cur_page = (self.ui and self.ui.getCurrentPage and self.ui:getCurrentPage())
                  or (self.ui and self.ui.view and self.ui.view.footer and self.ui.view.footer.pageno)
                  or 1
    local total_pages = (self.ui and self.ui.view and self.ui.view.footer and self.ui.view.footer.pages)
                     or (doc and doc.getPageCount and doc:getPageCount())
                     or 1

    local location_str = chapter_title or string.format("Page %d of %d", cur_page, total_pages)
    return title, author, location_str, cur_page, total_pages
end

function MindMap:addToHighlightDialog()
    self.ui.highlight:addToHighlightDialog("02_mindmap_relations", function(this)
        return {
            text = _("MindMap: Relations"),
            callback = function()
                this:highlightFromHoldPos()
                if not (this.selected_text and this.selected_text.text) then return end

                local char_name = util.cleanupSelectedText(this.selected_text.text):gsub("^%s+", ""):gsub("%s+$", "")
                if #char_name == 0 then return end
                this:onClose(true)

                self:onViewCharacterWeb(char_name)
            end,
        }
    end)
end

function MindMap:onViewCharacterWeb(char_name)
    local title, author, location_str = self:getBookContext()

    local cached = self.settings:getCached(title, "characters", char_name)
    if cached and #cached > 0 then
        Dialog.showCharacterWeb(char_name, title, location_str .. " (Offline Cache)", cached)
        return
    end

    local loading = Dialog.showLoading(string.format(_("Mapping character web for '%s'..."), char_name))

    UIManager:scheduleIn(0.1, function()
        local raw_text, err = self.api:getCharacterWeb(title, author, location_str, char_name)
        Dialog.closeLoading(loading)

        if raw_text and #raw_text > 0 then
            local formatted = Visualizer.formatCharacterWeb(char_name, title, location_str, raw_text)
            self.settings:saveCached(title, "characters", char_name, formatted)
            Dialog.showCharacterWeb(char_name, title, location_str, formatted)
        else
            UIManager:show(InfoMessage:new{
                text = string.format(_("Could not map relationships for '%s':\n%s"), char_name, tostring(err or "Unknown error")),
                timeout = 5,
            })
        end
    end)
end

function MindMap:onViewFactionWeb()
    local title, author, location_str = self:getBookContext()

    local cached = self.settings:getCached(title, "factions", "main_web")
    if cached and #cached > 0 then
        Dialog.showFactionWeb(title, location_str .. " (Offline Cache)", cached)
        return
    end

    local loading = Dialog.showLoading(_("Mapping book factions & power structures..."))

    UIManager:scheduleIn(0.1, function()
        local raw_text, err = self.api:getBookFactionsWeb(title, author, location_str)
        Dialog.closeLoading(loading)

        if raw_text and #raw_text > 0 then
            local formatted = Visualizer.formatFactionWeb(title, location_str, raw_text)
            self.settings:saveCached(title, "factions", "main_web", formatted)
            Dialog.showFactionWeb(title, location_str, formatted)
        else
            UIManager:show(InfoMessage:new{
                text = string.format(_("Could not generate faction web:\n%s"), tostring(err or "Unknown error")),
                timeout = 5,
            })
        end
    end)
end

function MindMap:onViewTimeline()
    local title, author, location_str = self:getBookContext()

    local cached = self.settings:getCached(title, "timelines", location_str)
    if cached and #cached > 0 then
        Dialog.showTimeline(title, location_str .. " (Offline Cache)", cached)
        return
    end

    local loading = Dialog.showLoading(_("Compiling chronological plot milestones..."))

    UIManager:scheduleIn(0.1, function()
        local raw_text, err = self.api:getPlotTimeline(title, author, location_str)
        Dialog.closeLoading(loading)

        if raw_text and #raw_text > 0 then
            local formatted = Visualizer.formatTimeline(title, location_str, raw_text)
            self.settings:saveCached(title, "timelines", location_str, formatted)
            Dialog.showTimeline(title, location_str, formatted)
        else
            UIManager:show(InfoMessage:new{
                text = string.format(_("Could not generate plot timeline:\n%s"), tostring(err or "Unknown error")),
                timeout = 5,
            })
        end
    end)
end

function MindMap:showCharacterSearchDialog()
    local dialog
    dialog = InputDialog:new{
        title = _("Search Character Dossier & Relations"),
        input_hint = _("e.g. Paul Atreides, Tyrion, Hercule Poirot"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function() UIManager:close(dialog) end,
                },
                {
                    text = _("Map"),
                    is_enter_default = true,
                    callback = function()
                        local val = dialog:getInputText():gsub("^%s+", ""):gsub("%s+$", "")
                        UIManager:close(dialog)
                        if #val > 0 then
                            self:onViewCharacterWeb(val)
                        end
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function MindMap:addToMainMenu(menu_items)
    menu_items.mindmap = {
        text = _("MindMap"),
        sorting_hint = "more_tools",
        sub_item_table_func = function()
            return self:getSubMenuItems()
        end,
        sub_item_table = self:getSubMenuItems(),
    }
end

function MindMap:getSubMenuItems()
    local has_doc = self.ui and self.ui.document and true or false
    return {
        {
            text = _("Book Factions & Houses Web"),
            enabled = has_doc,
            callback = function()
                self:onViewFactionWeb()
            end,
        },
        {
            text = _("Chronological Plot Timeline"),
            enabled = has_doc,
            callback = function()
                self:onViewTimeline()
            end,
        },
        {
            text = _("Search Character Dossier"),
            enabled = has_doc,
            callback = function()
                self:showCharacterSearchDialog()
            end,
        },
        {
            text_func = function()
                local lang = self.settings:getLanguage()
                local label = (lang == "serbian") and _("Serbian (Srpski - Latin)") or _("English")
                return string.format(_("Language: %s"), label)
            end,
            sub_item_table = {
                {
                    text = _("English"),
                    checked_func = function() return self.settings:getLanguage() == "english" end,
                    callback = function() self.settings:setLanguage("english") end,
                },
                {
                    text = _("Serbian (Srpski - Latin)"),
                    checked_func = function() return self.settings:getLanguage() == "serbian" end,
                    callback = function() self.settings:setLanguage("serbian") end,
                },
            },
        },
        {
            text = _("Import API Keys from Kindle Storage"),
            callback = function()
                local ok, imported, files = self.settings:importKeyFromFile()
                if ok then
                    local lines = { _("Keys imported successfully:") }
                    for prov, key in pairs(imported) do
                        local mask = #key > 8 and (key:sub(1, 4) .. "..." .. key:sub(-4)) or key
                        table.insert(lines, string.format("• %s: %s", prov:upper(), mask))
                    end
                    table.insert(lines, "\n" .. _("You can switch between Groq and Gemini anytime!"))
                    UIManager:show(InfoMessage:new{
                        text = table.concat(lines, "\n"),
                        timeout = 6,
                    })
                else
                    UIManager:show(InfoMessage:new{
                        text = _("No key files found on Kindle storage (/mnt/us/).\n\nYou can place groq_key.txt or gemini_key.txt via USB,\nthen tap this button again!"),
                        timeout = 8,
                    })
                end
            end,
        },
        {
            text_func = function()
                return string.format(_("AI Provider: %s (%s)"), self.settings:getProvider():upper(), self.settings:getModel())
            end,
            sub_item_table = {
                {
                    text = _("Groq (Free & Blazing Fast)"),
                    checked_func = function() return self.settings:getProvider() == "groq" end,
                    callback = function() self.settings:setProvider("groq") end,
                },
                {
                    text = _("Google Gemini"),
                    checked_func = function() return self.settings:getProvider() == "gemini" end,
                    callback = function() self.settings:setProvider("gemini") end,
                },
                {
                    text = _("OpenAI (GPT-4o-mini)"),
                    checked_func = function() return self.settings:getProvider() == "openai" end,
                    callback = function() self.settings:setProvider("openai") end,
                },
                {
                    text = _("DeepSeek (DeepSeek Chat)"),
                    checked_func = function() return self.settings:getProvider() == "deepseek" end,
                    callback = function() self.settings:setProvider("deepseek") end,
                },
                {
                    text = _("Local Ollama (100% Offline LAN)"),
                    checked_func = function() return self.settings:getProvider() == "ollama" end,
                    callback = function() self.settings:setProvider("ollama") end,
                },
            },
        },
        {
            text_func = function()
                return string.format(_("AI Model: %s"), self.settings:getModel())
            end,
            sub_item_table_func = function()
                local prov = self.settings:getProvider()
                if prov == "gemini" then
                    return {
                        {
                            text = _("Gemini 3.5 Flash-Lite (500 RPD Free)"),
                            checked_func = function() return self.settings:getModel() == "gemini-3.5-flash-lite" end,
                            callback = function() self.settings:setModel("gemini-3.5-flash-lite") end,
                        },
                        {
                            text = _("Gemini 2.5 Flash (20 RPD Free / Paid)"),
                            checked_func = function() return self.settings:getModel() == "gemini-2.5-flash" end,
                            callback = function() self.settings:setModel("gemini-2.5-flash") end,
                        },
                        {
                            text = _("Gemini 3.8 Flash"),
                            checked_func = function() return self.settings:getModel() == "gemini-3.8-flash" end,
                            callback = function() self.settings:setModel("gemini-3.8-flash") end,
                        },
                        {
                            text = _("Gemini 3.7 Flash"),
                            checked_func = function() return self.settings:getModel() == "gemini-3.7-flash" end,
                            callback = function() self.settings:setModel("gemini-3.7-flash") end,
                        },
                    }
                elseif prov == "groq" then
                    return {
                        {
                            text = _("GPT-OSS 120B (Recommended — 1K RPD, Best Quality)"),
                            checked_func = function() return self.settings:getModel() == "openai/gpt-oss-120b" end,
                            callback = function() self.settings:setModel("openai/gpt-oss-120b") end,
                        },
                        {
                            text = _("Qwen 3.8 27B (1K RPD — Strong Reasoning)"),
                            checked_func = function() return self.settings:getModel() == "qwen/qwen3.8-27b" end,
                            callback = function() self.settings:setModel("qwen/qwen3.8-27b") end,
                        },
                        {
                            text = _("GPT-OSS 20B (1K RPD — Fast & Lightweight)"),
                            checked_func = function() return self.settings:getModel() == "openai/gpt-oss-20b" end,
                            callback = function() self.settings:setModel("openai/gpt-oss-20b") end,
                        },
                    }
                end
                return {
                    {
                        text = string.format(_("Current: %s"), self.settings:getModel()),
                        enabled = false,
                    },
                }
            end,
        },
        {
            text_func = function()
                local prov = self.settings:getProvider()
                local cur_key = self.settings:getApiKey(prov)
                local status = (#cur_key > 0) and _("configured") or _("not set")
                return string.format(_("Edit %s Key (%s)"), prov:upper(), status)
            end,
            callback = function()
                local prov = self.settings:getProvider()
                local cur_key = self.settings:getApiKey(prov)
                local dialog
                dialog = InputDialog:new{
                    title = string.format(_("Enter %s API Key"), prov:upper()),
                    input = cur_key,
                    input_hint = prov == "groq" and "gsk_..." or (prov == "gemini" and "AIza..." or "API Key"),
                    buttons = {
                        {
                            {
                                text = _("Cancel"),
                                id = "close",
                                callback = function() UIManager:close(dialog) end,
                            },
                            {
                                text = _("Save"),
                                is_enter_default = true,
                                callback = function()
                                    local val = dialog:getInputText():gsub("[%s]+", "")
                                    self.settings:setApiKey(val, prov)
                                    UIManager:close(dialog)
                                    UIManager:show(InfoMessage:new{
                                        text = string.format(_("%s Key saved!"), prov:upper()),
                                        timeout = 2,
                                    })
                                end,
                            },
                        },
                    },
                }
                UIManager:show(dialog)
                dialog:onShowKeyboard()
            end,
        },
        {
            text = _("Clear Offline Cache"),
            callback = function()
                self.settings:clearCache()
                UIManager:show(InfoMessage:new{ text = _("MindMap offline cache cleared."), timeout = 2 })
            end,
        },
    }
end

return MindMap
