--[[--
MindMap Settings & Cache Manager.
Manages AI model configurations, API keys, and local caching of character relationship webs.
--]]--

local DataStorage = require("datastorage")
local lfs = require("libs/libkoreader-lfs")

local Settings = {}
Settings.__index = Settings

local DEFAULT_MODELS = {
    groq = "openai/gpt-oss-120b",
    gemini = "gemini-3.5-flash-lite",
    openai = "gpt-4o-mini",
    deepseek = "deepseek-chat",
    ollama = "llama3:latest",
}

function Settings:new()
    local o = setmetatable({}, self)
    return o
end

function Settings:get(key, default)
    if not G_reader_settings then return default end
    local val = G_reader_settings:readSetting("mindmap_" .. key)
    if val ~= nil then return val end
    return default
end

function Settings:save(key, val)
    if not G_reader_settings then return end
    G_reader_settings:saveSetting("mindmap_" .. key, val)
end

function Settings:getLanguage()
    return self:get("language", "english") -- "english" or "serbian"
end

function Settings:setLanguage(lang)
    self:save("language", lang)
end

function Settings:getProvider()
    return self:get("provider", "groq")
end

function Settings:setProvider(p)
    self:save("provider", p)
end

function Settings:getModel()
    local prov = self:getProvider()
    return self:get("model_" .. prov, DEFAULT_MODELS[prov] or "openai/gpt-oss-120b")
end

function Settings:setModel(m)
    local prov = self:getProvider()
    self:save("model_" .. prov, m)
end

function Settings:getOllamaUrl()
    return self:get("ollama_url", "http://192.168.1.100:11434")
end

function Settings:setOllamaUrl(url)
    self:save("ollama_url", url)
end

function Settings:getApiKey(prov)
    prov = prov or self:getProvider()
    local val = self:get("api_key_" .. prov, "")
    if val and #val > 0 then return val end

    -- Fallback to shared keys from bookrecap or morningpaper
    if G_reader_settings then
        local shared_br = G_reader_settings:readSetting("bookrecap_api_key_" .. prov)
        if shared_br and #shared_br > 0 then return shared_br end

        local shared_mp = G_reader_settings:readSetting("morningpaper_api_key_" .. prov)
        if shared_mp and #shared_mp > 0 then return shared_mp end

        local legacy = G_reader_settings:readSetting("bookrecap_api_key")
        if legacy and #legacy > 0 then
            if prov == "groq" and legacy:sub(1, 4) == "gsk_" then return legacy end
            if prov == "gemini" and legacy:sub(1, 4) == "AIza" then return legacy end
        end
    end
    return ""
end

function Settings:setApiKey(key, prov)
    prov = prov or self:getProvider()
    self:save("api_key_" .. prov, key)
end

-- Import API keys from Kindle root storage
function Settings:importKeyFromFile()
    local paths = {
        "/mnt/us/groq_key.txt",
        "/mnt/us/gemini_key.txt",
        "/mnt/us/ai_key.txt",
        DataStorage:getFullDataDir() .. "/groq_key.txt",
        DataStorage:getFullDataDir() .. "/gemini_key.txt",
    }
    local imported = {}
    local files_found = {}

    for idx, path in ipairs(paths) do
        if lfs.attributes(path, "mode") == "file" then
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                if content and #content > 0 then
                    content = content:gsub("[
%s]+", "")
                    table.insert(files_found, path)
                    if path:match("groq") or content:sub(1, 4) == "gsk_" then
                        self:setApiKey(content, "groq")
                        imported["groq"] = content
                    elseif path:match("gemini") or content:sub(1, 4) == "AIza" then
                        self:setApiKey(content, "gemini")
                        imported["gemini"] = content
                    end
                end
            end
        end
    end

    return next(imported) ~= nil, imported, files_found
end

-- Cache management
function Settings:getCacheKey(book_title, category, identifier)
    local clean_title = (book_title or "unknown"):gsub("%W+", "_"):lower()
    local clean_id = (identifier or "general"):gsub("%W+", "_"):lower()
    return string.format("%s_%s_%s", clean_title, category, clean_id)
end

function Settings:getCached(book_title, category, identifier)
    local cache = self:get("cache_" .. category, {})
    local key = self:getCacheKey(book_title, category, identifier)
    return cache[key]
end

function Settings:saveCached(book_title, category, identifier, content)
    local cache = self:get("cache_" .. category, {})
    local key = self:getCacheKey(book_title, category, identifier)
    cache[key] = content
    self:save("cache_" .. category, cache)
end

function Settings:clearCache()
    self:save("cache_characters", {})
    self:save("cache_factions", {})
    self:save("cache_timelines", {})
end

return Settings
