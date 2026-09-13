--[[--
MindMap Visualizer.
Formats AI responses into clean, elegant, e-ink typography.
Zero broken ASCII boxes, zero markdown tables, zero missing emoji glyphs.
--]]--

local Visualizer = {}

local function cleanLines(text)
    local lines = {}
    for l in (text or ""):gmatch("[^\r\n]+") do
        local trimmed = l:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed > 0 then
            table.insert(lines, trimmed)
        end
    end
    return lines
end

local function splitByChar(str, sep)
    local parts = {}
    for match in (str .. sep):gmatch("(.-)".. sep) do
        table.insert(parts, match)
    end
    return parts
end

local function stripMarkdown(s)
    if not s then return ""end
    return s:gsub("%*%*", ""):gsub("%*", ""):gsub("^[#%s]+", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function Visualizer.formatCharacterWeb(char_name, book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "==================================================")
    table.insert(out, "CHARACTER DOSSIER: ".. char_name:upper())
    table.insert(out, "Book: ".. (book_title or "Current Book"))
    table.insert(out, "Progress: ".. (location_str or "Current Location"))
    table.insert(out, "️ (Strictly spoiler-guarded up to this chapter)")
    table.insert(out, "==================================================\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        -- Skip table separators
        if l:find("^|%s*%-") or l:find("^|%s*:") then
            -- skip
        -- Convert markdown table row into clean entry
        elseif l:sub(1, 1) == "|"and l:sub(-1) == "|"then
            local raw_parts = splitByChar(l:sub(2, -2), "|")
            local parts = {}
            for _, p in ipairs(raw_parts) do
                local clean = stripMarkdown(p)
                if #clean > 0 then table.insert(parts, clean) end
            end

            local first_lower = parts[1] and parts[1]:lower() or ""
            if first_lower ~= "character"and first_lower ~= "name"and first_lower ~= "figure"and first_lower ~= "faction"then
                if #parts >= 3 then
                    table.insert(out, string.format("• %s (%s)\n  %s\n", parts[1], parts[2], parts[3]))
                elseif #parts == 2 then
                    table.insert(out, string.format("• %s\n  %s\n", parts[1], parts[2]))
                end
            end

        -- Section Headings
        elseif l:find("^[#%*%-]*%s*[A-Z%s/&]+:") or l:find("^%*%*") or (l:find("^[A-Z]") and #l < 45 and not l:find("%.")) then
            local header = stripMarkdown(l):gsub(":$", "")
            table.insert(out, "\n--- ".. header:upper() .. "---\n")

        -- Bullets & Items
        elseif l:find("^[•%-%*]") then
            local item = stripMarkdown(l:gsub("^[•%-%*]%s*", ""))
            local k, v = item:match("^(.-):%s*(.+)$")
            if k and v then
                table.insert(out, string.format("• %s:\n  %s\n", k, v))
            else
                table.insert(out, "• ".. item)
            end
        else
            table.insert(out, stripMarkdown(l))
        end
    end

    return table.concat(out, "\n")
end

function Visualizer.formatFactionWeb(book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "==================================================")
    table.insert(out, "FACTIONS & HOUSES: ".. (book_title or "Current Book"):upper())
    table.insert(out, "Progress: ".. (location_str or "Current Location"))
    table.insert(out, "️ (Strictly spoiler-guarded up to this chapter)")
    table.insert(out, "==================================================\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        if l:find("^|%s*%-") or l:find("^|%s*:") then
            -- skip
        elseif l:sub(1, 1) == "|"and l:sub(-1) == "|"then
            local raw_parts = splitByChar(l:sub(2, -2), "|")
            local parts = {}
            for _, p in ipairs(raw_parts) do
                local clean = stripMarkdown(p)
                if #clean > 0 then table.insert(parts, clean) end
            end
            local first_lower = parts[1] and parts[1]:lower() or ""
            if first_lower ~= "faction"and first_lower ~= "house"and first_lower ~= "group"and first_lower ~= "name"then
                if #parts >= 3 then
                    table.insert(out, string.format("• %s: %s\n  %s\n", parts[1], parts[2], parts[3]))
                elseif #parts == 2 then
                    table.insert(out, string.format("• %s\n  %s\n", parts[1], parts[2]))
                end
            end
        elseif l:find("^[#%*%-]*%s*[A-Z%s/&]+:") or l:find("^%*%*") or (l:find("^[A-Z]") and #l < 45 and not l:find("%.")) then
            local header = stripMarkdown(l):gsub(":$", "")
            table.insert(out, "\n--- ".. header:upper() .. "---\n")
        elseif l:find("^[•%-%*]") then
            local item = stripMarkdown(l:gsub("^[•%-%*]%s*", ""))
            local k, v = item:match("^(.-):%s*(.+)$")
            if k and v then
                table.insert(out, string.format("• %s:\n  %s\n", k, v))
            else
                table.insert(out, "• ".. item)
            end
        else
            table.insert(out, stripMarkdown(l))
        end
    end

    return table.concat(out, "\n")
end

function Visualizer.formatTimeline(book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "==================================================")
    table.insert(out, "CHRONOLOGICAL TIMELINE: ".. (book_title or "Current Book"):upper())
    table.insert(out, "Progress: ".. (location_str or "Current Location"))
    table.insert(out, "️ (Strictly spoiler-guarded up to this chapter)")
    table.insert(out, "==================================================\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        if l:find("^[#%*%-]*%s*Chapter") or l:find("^[#%*%-]*%s*Milestone") or l:find("^%d+%.") or l:find("^%[") then
            local header = stripMarkdown(l)
            table.insert(out, "\n[".. header .. "]\n")
        elseif l:find("^[•%-%*]") then
            local item = stripMarkdown(l:gsub("^[•%-%*]%s*", ""))
            table.insert(out, "• ".. item)
        else
            table.insert(out, stripMarkdown(l))
        end
    end

    return table.concat(out, "\n")
end

return Visualizer
