--[[--
MindMap Dialog Presentation.
Presents character dossiers, relationship webs, and plot timelines using KOReader's native TextViewer.
--]]--

local InfoMessage = require("ui/widget/infomessage")
local TextViewer = require("ui/widget/textviewer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local Dialog = {}

function Dialog.showLoading(msg)
    local info = InfoMessage:new{
        text = msg or _("Mapping relationship web..."),
    }
    UIManager:show(info)
    return info
end

function Dialog.closeLoading(info_widget)
    if info_widget then
        UIManager:close(info_widget)
    end
end

function Dialog.showCharacterWeb(char_name, book_title, location_str, text)
    local title = string.format(_("Character Dossier: %s"), char_name)
    local viewer = TextViewer:new{
        title = title,
        text = text,
        text_type = "general",
    }
    UIManager:show(viewer)
end

function Dialog.showFactionWeb(book_title, location_str, text)
    local title = string.format(_("Factions Web: %s"), book_title)
    local viewer = TextViewer:new{
        title = title,
        text = text,
        text_type = "general",
    }
    UIManager:show(viewer)
end

function Dialog.showTimeline(book_title, location_str, text)
    local title = string.format(_("Plot Timeline: %s"), book_title)
    local viewer = TextViewer:new{
        title = title,
        text = text,
        text_type = "general",
    }
    UIManager:show(viewer)
end

return Dialog
