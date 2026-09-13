--[[--
MindMap AI Query Engine.
Handles API requests to Groq, Gemini, OpenAI, DeepSeek, and local Ollama with strict spoiler protection.
--]]--

local API = {}
API.__index = API

local json = nil
local ok, mod = pcall(require, "json")
if ok and mod and mod.decode then json = mod
else
    ok, mod = pcall(require, "rapidjson")
    if ok and mod and mod.decode then json = mod end
end

local function encodeJSON(val)
    if json and json.encode then return json.encode(val) end
    if type(val) == "string" then
        return string.format('"%s"', val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', ''))
    elseif type(val) == "number" or type(val) == "boolean" then
        return tostring(val)
    elseif type(val) == "table" then
        local is_array = (#val > 0)
        local parts = {}
        if is_array then
            for idx, v in ipairs(val) do
                table.insert(parts, encodeJSON(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(parts, string.format('"%s":%s', k, encodeJSON(v)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

local function decodeJSON(str)
    if json and json.decode then
        local ok_dec, res = pcall(json.decode, str)
        if ok_dec and res then return res end
    end
    return nil
end

function API:new(settings)
    local o = setmetatable({}, self)
    o.settings = settings
    return o
end

function API:sendChat(messages, system_prompt, max_tokens)
    local provider = self.settings:getProvider()
    local api_key = self.settings:getApiKey(provider)
    local model = self.settings:getModel()
    max_tokens = max_tokens or 650

    if provider ~= "ollama" and #api_key == 0 then
        return nil, string.format("API Key for %s is not set", provider:upper())
    end

    local url
    local headers = { "Content-Type: application/json" }
    local all_messages = {}

    if system_prompt and #system_prompt > 0 then
        table.insert(all_messages, { role = "system", content = system_prompt })
    end
    for idx, m in ipairs(messages) do
        table.insert(all_messages, m)
    end

    if provider == "groq" then
        url = "https://api.groq.com/openai/v1/chat/completions"
        table.insert(headers, "Authorization: Bearer " .. api_key)
    elseif provider == "gemini" then
        url = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        table.insert(headers, "Authorization: Bearer " .. api_key)
    elseif provider == "openai" then
        url = "https://api.openai.com/v1/chat/completions"
        table.insert(headers, "Authorization: Bearer " .. api_key)
    elseif provider == "deepseek" then
        url = "https://api.deepseek.com/chat/completions"
        table.insert(headers, "Authorization: Bearer " .. api_key)
    elseif provider == "ollama" then
        local base = self.settings:getOllamaUrl()
        url = base .. "/v1/chat/completions"
    end

    local payload = {
        model = model,
        messages = all_messages,
        temperature = 0.2,
        max_tokens = max_tokens,
    }

    local body_str = encodeJSON(payload)
    local safe_body = body_str:gsub("'", "'\\''")
    local header_args = ""
    for idx, h in ipairs(headers) do
        header_args = header_args .. string.format(' -H "%s"', h)
    end

    local cmd = string.format("curl -s -k -m 20 -X POST %s -d '%s' '%s' 2>/dev/null", header_args, safe_body, url)
    local handle = io.popen(cmd)
    if not handle then return nil, "Network execution failed" end
    local raw = handle:read("*a")
    handle:close()

    if not raw or #raw == 0 then return nil, "No response from AI server" end
    local res = decodeJSON(raw)
    if not res then return nil, "Invalid JSON received from server" end
    if res.error then
        local msg = (type(res.error) == "table" and res.error.message) or tostring(res.error)
        return nil, msg
    end
    if res.choices and res.choices[1] and res.choices[1].message then
        return res.choices[1].message.content
    end
    return nil, "Unexpected response format"
end

-- 1. Character Relationship Web & Dossier
function API:getCharacterWeb(title, author, location_str, char_name)
    local lang = self.settings:getLanguage()
    local lang_rule = (lang == "serbian")
        and "Respond strictly in natural Serbian (Latin alphabet)."
        or "Respond in clear English."

    local system_prompt = string.format([[
You are an expert literary scholar and reading companion creating a detailed, spoiler-guarded Character Relationship Dossier.
STRICT SPOILER RULES:
1. The reader is currently at: "%s" in the book "%s" by %s.
2. You MUST ONLY describe facts, alliances, rivalries, and revelations that have occurred UP TO THIS EXACT LOCATION.
3. NEVER reveal future betrayals, secret identities, deaths, plot twists, or events that happen later in the book or series.
4. %s

STRUCTURE YOUR OUTPUT CLEARLY WITH THESE HEADINGS:
- TITLE & FACTION: Full name, title/epithet, and current allegiance/house/organization.
- ROLE & CURRENT STATUS: 2-3 sentences summarizing who they are and what they are doing at this exact point in the story.
- RELATIONSHIP WEB: A list of 4-7 key relationships with other characters (e.g., Ally, Enemy/Rival, Family, Mentor/Student, Love Interest, Retainer) and a 1-sentence note for each relationship.
]], location_str or "Current Reading Progress", title or "Unknown Book", author or "Unknown Author", lang_rule)

    local user_prompt = string.format("Generate the Character Dossier & Relationship Web for '%s' in '%s'.", char_name, title)
    return self:sendChat({ { role = "user", content = user_prompt } }, system_prompt, 700)
end

-- 2. Book Factions & Major Houses Overview
function API:getBookFactionsWeb(title, author, location_str)
    local lang = self.settings:getLanguage()
    local lang_rule = (lang == "serbian")
        and "Respond strictly in natural Serbian (Latin alphabet)."
        or "Respond in clear English."

    local system_prompt = string.format([[
You are an expert literary companion creating a Factions & Houses Relationship Overview for the book "%s" by %s.
STRICT SPOILER RULES:
1. The reader is at: "%s".
2. Only include factions, houses, guilds, or groups introduced up to this point.
3. Absolutely NO future spoilers, secret allegiances, or future faction collapses.
4. %s

STRUCTURE YOUR OUTPUT:
For each major faction/house/group (3-5 groups):
- Faction Name & Symbol/Motto
- Motivation & Current Objective (at this point in the story)
- Key Known Members (Leaders, Champions, Retainers)
- Primary Rivals & Allies
]], title or "Unknown Book", author or "Unknown Author", location_str or "Current Reading Progress", lang_rule)

    local user_prompt = string.format("Generate the Faction & Power Structure Web for '%s'.", title)
    return self:sendChat({ { role = "user", content = user_prompt } }, system_prompt, 800)
end

-- 3. Chronological Plot Timeline
function API:getPlotTimeline(title, author, location_str)
    local lang = self.settings:getLanguage()
    local lang_rule = (lang == "serbian")
        and "Respond strictly in natural Serbian (Latin alphabet)."
        or "Respond in clear English."

    local system_prompt = string.format([[
You are an expert reading companion creating a Chronological Plot Milestone Timeline for "%s" by %s.
STRICT SPOILER RULES:
1. The reader is currently at: "%s".
2. Provide a chronological list of 4-7 major plot milestones that have occurred from the beginning of the book UP TO THIS EXACT LOCATION.
3. DO NOT include any event beyond this point.
4. %s

FORMAT:
For each milestone:
◆ [Chapter / Event Title]
  Summary of key narrative development and its consequence for the main characters.
]], title or "Unknown Book", author or "Unknown Author", location_str or "Current Reading Progress", lang_rule)

    local user_prompt = string.format("Generate the chronological plot milestone timeline for '%s' up to '%s'.", title, location_str)
    return self:sendChat({ { role = "user", content = user_prompt } }, system_prompt, 750)
end

return API
