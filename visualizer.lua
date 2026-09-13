--[[--
MindMap Visualizer.
Formats AI responses and Markdown tables into clean, high-contrast Unicode box-drawing trees and dossiers optimized for E-Ink screens.
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
    for match in (str .. sep):gmatch("(.-)" .. sep) do
        table.insert(parts, match)
    end
    return parts
end

function Visualizer.formatCharacterWeb(char_name, book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "┌──────────────────────────────────────────────────────────┐")
    table.insert(out, string.format("│  👤 CHARACTER DOSSIER: %s", char_name:upper()))
    table.insert(out, string.format("│  📖 %s", book_title))
    table.insert(out, string.format("│  📍 Progress: %s", location_str))
    table.insert(out, "├──────────────────────────────────────────────────────────┤")
    table.insert(out, "│  ⚠️ Strictly spoiler-guarded up to this location.")
    table.insert(out, "└──────────────────────────────────────────────────────────┘\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        -- Skip table separators
        if l:find("^|%s*%-") or l:find("^|%s*:") then
            -- skip
        -- Parse markdown table rows
        elseif l:sub(1, 1) == "|" and l:sub(-1) == "|" then
            local raw_parts = splitByChar(l:sub(2, -2), "|")
            local parts = {}
            for _, p in ipairs(raw_parts) do
                local clean = p:gsub("%*%*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if #clean > 0 then table.insert(parts, clean) end
            end

            local first_lower = parts[1] and parts[1]:lower() or ""
            if first_lower ~= "character" and first_lower ~= "name" and first_lower ~= "figure" and first_lower ~= "faction" then
                if #parts >= 3 then
                    table.insert(out, string.format("  ├── %s (%s)\n      └── %s", parts[1], parts[2], parts[3]))
                elseif #parts == 2 then
                    table.insert(out, string.format("  ├── %s\n      └── %s", parts[1], parts[2]))
                end
            end

        -- Section Headings
        elseif l:find("^[#%*%-]*%s*[A-Z%s/&]+:") or l:find("^%*%*") or (l:find("^[A-Z]") and #l < 40 and not l:find("%.")) then
            local header = l:gsub("^[#%*%-]+%s*", ""):gsub("%*+", ""):gsub(":$", "")
            table.insert(out, "\n━━━━ " .. header .. " ━━━━")

        -- Bullets & Items
        elseif l:find("^[•%-%*]") then
            local item = l:gsub("^[•%-%*]%s*", ""):gsub("%*%*", "")
            local k, v = item:match("^(.-):%s*(.+)$")
            if k and v then
                table.insert(out, string.format("  ├── %s\n      └── %s", k, v))
            else
                table.insert(out, "  • " .. item)
            end
        else
            table.insert(out, l:gsub("%*%*", ""))
        end
    end

    return table.concat(out, "\n")
end

function Visualizer.formatFactionWeb(book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "┌──────────────────────────────────────────────────────────┐")
    table.insert(out, "│  👑 FACTIONS & HOUSES RELATIONSHIP WEB                   │")
    table.insert(out, string.format("│  📖 %s", book_title))
    table.insert(out, string.format("│  📍 Progress: %s", location_str))
    table.insert(out, "├──────────────────────────────────────────────────────────┤")
    table.insert(out, "│  ⚠️ Strictly spoiler-guarded up to this location.")
    table.insert(out, "└──────────────────────────────────────────────────────────┘\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        if l:find("^|%s*%-") or l:find("^|%s*:") then
            -- skip
        elseif l:sub(1, 1) == "|" and l:sub(-1) == "|" then
            local raw_parts = splitByChar(l:sub(2, -2), "|")
            local parts = {}
            for _, p in ipairs(raw_parts) do
                local clean = p:gsub("%*%*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if #clean > 0 then table.insert(parts, clean) end
            end
            local first_lower = parts[1] and parts[1]:lower() or ""
            if first_lower ~= "faction" and first_lower ~= "house" and first_lower ~= "group" and first_lower ~= "name" then
                if #parts >= 3 then
                    table.insert(out, string.format("   ├── %s: %s\n       └── %s", parts[1], parts[2], parts[3]))
                elseif #parts == 2 then
                    table.insert(out, string.format("   ├── %s\n       └── %s", parts[1], parts[2]))
                end
            end
        elseif l:find("^[#%*%-]*%s*[A-Z%s/&]+:") or l:find("^%*%*") or (l:find("^[A-Z]") and #l < 40 and not l:find("%.")) then
            local header = l:gsub("^[#%*%-]+%s*", ""):gsub("%*+", ""):gsub(":$", "")
            table.insert(out, "\n🏰 ━━━━ " .. header .. " ━━━━")
        elseif l:find("^[•%-%*]") then
            local item = l:gsub("^[•%-%*]%s*", ""):gsub("%*%*", "")
            local k, v = item:match("^(.-):%s*(.+)$")
            if k and v then
                table.insert(out, string.format("   ├── %s\n       └── %s", k, v))
            else
                table.insert(out, "   • " .. item)
            end
        else
            table.insert(out, l:gsub("%*%*", ""))
        end
    end

    return table.concat(out, "\n")
end

function Visualizer.formatTimeline(book_title, location_str, raw_ai_text)
    local out = {}
    table.insert(out, "┌──────────────────────────────────────────────────────────┐")
    table.insert(out, "│  ⏳ CHRONOLOGICAL PLOT TIMELINE                          │")
    table.insert(out, string.format("│  📖 %s", book_title))
    table.insert(out, string.format("│  📍 Progress: %s", location_str))
    table.insert(out, "├──────────────────────────────────────────────────────────┤")
    table.insert(out, "│  ⚠️ Strictly spoiler-guarded up to this location.")
    table.insert(out, "└──────────────────────────────────────────────────────────┘\n")

    local lines = cleanLines(raw_ai_text)
    for idx, l in ipairs(lines) do
        if l:find("^[#%*%-]*%s*◆") or l:find("^[#%*%-]*%s*Chapter") or l:find("^[#%*%-]*%s*Milestone") or l:find("^%d+%.") then
            local header = l:gsub("^[#%*%-]+%s*", ""):gsub("%*+", "")
            table.insert(out, "\n◆ ━━━━ " .. header .. " ━━━━")
        elseif l:find("^[•%-%*]") then
            local item = l:gsub("^[•%-%*]%s*", ""):gsub("%*%*", "")
            table.insert(out, "  • " .. item)
        else
            table.insert(out, "  " .. l:gsub("%*%*", ""))
        end
    end

    return table.concat(out, "\n")
end

return Visualizer
