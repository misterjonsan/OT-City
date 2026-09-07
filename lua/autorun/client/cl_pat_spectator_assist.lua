include("autorun/sh_pat_spectator_assist.lua")

local addon = PAT_SPECTATOR_ASSIST
local timeline = {}
local feed = {}
local deathRecap
local deathRecapReceivedAt = 0

local feedLimit = 5
local timelineLimit = 12
local feedLifetime = 18

local UI_MAIN = Color(31, 182, 255)
local UI_MAIN_SOFT = Color(127, 230, 255)
local UI_DARK = Color(3, 5, 9)
local UI_DARK_SOFT = Color(6, 12, 20)
local UI_CARD = Color(9, 18, 30)
local UI_TEXT = Color(240, 248, 255)
local UI_MUTED = Color(150, 190, 220)
local UI_SHADOW = Color(0, 0, 0, 200)

local colText = UI_TEXT
local colSoft = UI_MUTED
local colGood = UI_MAIN
local colWarn = Color(235, 185, 95)
local colBad = Color(235, 80, 70)
local colInfo = UI_MAIN_SOFT

local UI_RADIUS = 10

local function DrawUIBlock(x, y, w, h, col, radius)
    if w <= 0 or h <= 0 then return end
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))

    if RNDX and RNDX.Draw then
        RNDX.Draw(radius, x, y, w, h, col)
    elseif rndx and rndx.Draw then
        rndx.Draw(radius, x, y, w, h, col)
    else
        draw.RoundedBox(radius, x, y, w, h, col)
    end
end

local function DrawUIOutline(x, y, w, h, col, radius, thickness)
    if w <= 0 or h <= 0 then return end
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))
    thickness = thickness or 1

    if RNDX and RNDX.DrawOutlined then
        RNDX.DrawOutlined(radius, x, y, w, h, col, thickness)
    elseif rndx and rndx.DrawOutlined then
        rndx.DrawOutlined(radius, x, y, w, h, col, thickness)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        for i = 0, thickness - 1 do
            surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2)
        end
    end
end

local function DrawUIText(text, font, x, y, col, ax, ay)
    local sa = (col.a or 255) * 0.7
    draw.SimpleText(text, font, x + 1, y + 1, Color(UI_SHADOW.r, UI_SHADOW.g, UI_SHADOW.b, sa), ax, ay)
    draw.SimpleText(text, font, x, y, col, ax, ay)
end

local lastFontW, lastFontH = 0, 0

local function UIScale()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.72, 1.18)
end

local function S(value)
    return math.max(1, math.floor(value * UIScale() + 0.5))
end

local function EnsureFonts()
    if lastFontW == ScrW() and lastFontH == ScrH() then return end
    lastFontW, lastFontH = ScrW(), ScrH()

    surface.CreateFont("PAT_SpectatorAssistTitle", {
        font = "Montserrat SemiBold",
        size = S(24),
        weight = 600,
        antialias = true,
        extended = true
    })

    surface.CreateFont("PAT_SpectatorAssistBody", {
        font = "Montserrat Medium",
        size = S(18),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("PAT_SpectatorAssistSmall", {
        font = "Montserrat Medium",
        size = S(15),
        weight = 500,
        antialias = true,
        extended = true
    })
end

EnsureFonts()

local function measureText(text, fontName)
    surface.SetFont(fontName)
    return surface.GetTextSize(text or "")
end

local function wrapText(text, fontName, maxWidth)
    text = tostring(text or "")
    local lines = {}

    if text == "" then
        lines[1] = ""
        return lines
    end

    surface.SetFont(fontName)

    for rawLine in string.gmatch(text, "[^\n]+") do
        local current = ""

        for word in string.gmatch(rawLine, "%S+") do
            local candidate = current == "" and word or (current .. " " .. word)
            local candidateW = surface.GetTextSize(candidate)

            if candidateW <= maxWidth then
                current = candidate
            else
                if current ~= "" then
                    lines[#lines + 1] = current
                end

                local wordW = surface.GetTextSize(word)
                if wordW <= maxWidth then
                    current = word
                else
                    local partial = ""
                    for i = 1, utf8.len(word) or #word do
                        local ch = utf8.sub(word, i, i) or string.sub(word, i, i)
                        local nextPartial = partial .. ch
                        local nextW = surface.GetTextSize(nextPartial)

                        if nextW > maxWidth and partial ~= "" then
                            lines[#lines + 1] = partial
                            partial = ch
                        else
                            partial = nextPartial
                        end
                    end
                    current = partial
                end
            end
        end

        if current ~= "" then
            lines[#lines + 1] = current
        end
    end

    if #lines == 0 then
        lines[1] = ""
    end

    return lines
end

local function buildWrappedColorLines(items, fontName, maxWidth)
    local out = {}

    for _, item in ipairs(items or {}) do
        local wrapped = wrapText(item.text or "", fontName, maxWidth)
        for _, line in ipairs(wrapped) do
            out[#out + 1] = {
                text = line,
                color = item.color or colText
            }
        end
    end

    return out
end

local function calcWrappedBlockSize(items, title, fontTitle, fontBody, minW, maxW, lineHeight, titleHeight, bottomPadding, horizontalPadding)
    minW = minW or 240
    maxW = maxW or 420
    if maxW < minW then minW = maxW end
    lineHeight = S(lineHeight or 18)
    titleHeight = S(titleHeight or 40)
    bottomPadding = S(bottomPadding or 12)
    horizontalPadding = S(horizontalPadding or 24)

    local longest = 0
    if title and title ~= "" then
        longest = math.max(longest, measureText(title, fontTitle))
    end

    for _, item in ipairs(items or {}) do
        longest = math.max(longest, measureText(item.text or "", fontBody))
    end

    local width = math.Clamp(longest + horizontalPadding, minW, maxW)
    local wrapped = buildWrappedColorLines(items, fontBody, width - horizontalPadding)
    local height = titleHeight + (#wrapped * lineHeight) + bottomPadding

    return width, height, wrapped
end

local function pushFeed(title, details, color)
    title = tostring(title or "")
    details = tostring(details or "")

    local latest = feed[1]
    if latest and latest.title == title and latest.details == details then
        latest.time = CurTime()
        latest.color = color or latest.color
        return
    end

    table.insert(feed, 1, {
        title = title,
        details = details,
        color = color or colInfo,
        time = CurTime()
    })

    while #feed > feedLimit do
        table.remove(feed)
    end
end

local function pushTimeline(entry)
    if not istable(entry) then return end

    table.insert(timeline, 1, entry)

    while #timeline > timelineLimit do
        table.remove(timeline)
    end

    pushFeed("Смерть", entry.summary or "Игрок погиб.", colWarn)
end

local function drawCard(x, y, w, h, title, alpha)
    alpha = alpha or 1

    DrawUIBlock(x, y, w, h, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, 235 * alpha), UI_RADIUS)
    DrawUIBlock(x, y, w, h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 14 * alpha), UI_RADIUS)
    DrawUIOutline(x, y, w, h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 150 * alpha), UI_RADIUS, 1)

    if title and title ~= "" then
        DrawUIText(title, "PAT_SpectatorAssistTitle", x + S(14), y + S(9), Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, 255 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        DrawUIBlock(x + S(14), y + S(33), math.min(w - S(28), S(42)), S(2), Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 200 * alpha), 2)
    end
end

local function drawWrappedLines(lines, x, y, lineHeight, fontName)
    for i, line in ipairs(lines) do
        if line and line.text and line.text ~= "" then
            DrawUIText(line.text, fontName, x, y + ((i - 1) * lineHeight), line.color or colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
end

local function getSpectatorLines()
    local lines = {}
    local lply = LocalPlayer()
    local target = lply:GetNWEntity("spect")
    local viewMode = lply:GetNWInt("viewmode", 1)
    local org = IsValid(target) and (target.new_organism or target.organism) or nil
    local round = CurrentRound and CurrentRound()
    local cameraLabel = viewMode == 1 and "От первого лица" or (viewMode == 2 and "От третьего лица" or "Свободная камера")

    lines[#lines + 1] = {
        text = "Цель: " .. (IsValid(target) and target:Name() or "нет"),
        color = colText
    }

    if IsValid(target) and target.GetPlayerName then
        local characterName = target:GetPlayerName()
        if characterName and characterName ~= "" and characterName ~= target:Name() then
            lines[#lines + 1] = {
                text = "Персонаж: " .. characterName,
                color = colSoft
            }
        end
    end

    lines[#lines + 1] = {
        text = (round and (round.PrintName or round.name) or addon.GetRoundLabel()) .. " | " .. cameraLabel,
        color = colInfo
    }

    lines[#lines + 1] = {
        text = "До конца: " .. addon.FormatClock(addon.GetTimeLeft()),
        color = colInfo
    }

    if org then
        local status = org.critical and "Критическое состояние" or (org.otrub and "Без сознания") or (org.incapacitated and "Тяжёлое состояние") or "Стабилен"
        lines[#lines + 1] = {
            text = "Статус: " .. status,
            color = org.critical and colBad or (org.otrub and colWarn or colGood)
        }
    else
        lines[#lines + 1] = {
            text = "Статус: неизвестно",
            color = colWarn
        }
    end

    lines[#lines + 1] = {
        text = "ЛКМ — следующий | ПКМ — предыдущий | R — сменить вид",
        color = colSoft
    }

    return lines
end

local function getTimelineItems()
    local items = {}

    if #timeline == 0 then
        items[1] = {
            text = "Недавних смертей нет.",
            color = colSoft
        }
        return items
    end

    for i = 1, #timeline do
        local entry = timeline[i]
        items[#items + 1] = {
            text = "[" .. (entry.event_time_label or "--:--") .. "] " .. (entry.summary or "Игрок погиб."),
            color = colText
        }

        if entry.cause and entry.cause ~= "" and entry.cause ~= "неизвестное оружие" then
            items[#items + 1] = {
                text = "Причина: " .. tostring(entry.cause),
                color = colSoft
            }
        end
    end

    return items
end

local function getRecapItems(alpha)
    if not deathRecap then return {} end

    return {
        {
            text = deathRecap.summary or "Вы погибли.",
            color = ColorAlpha(colText, 255 * alpha)
        },
        {
            text = "Причина: " .. tostring(deathRecap.cause or "неизвестно"),
            color = ColorAlpha(colWarn, 255 * alpha)
        },
        {
            text = "Время: " .. tostring(deathRecap.killed_at_label or "--:--") .. " | Попадание: " .. tostring(deathRecap.hitgroup or "неизвестно"),
            color = ColorAlpha(colInfo, 255 * alpha)
        }
    }
end

local function drawTimelinePanel(x, y, maxWidth, maxHeight)
    local items = getTimelineItems()
    local w, h, wrapped = calcWrappedBlockSize(items, "Смерти", "PAT_SpectatorAssistTitle", "PAT_SpectatorAssistSmall", 260, maxWidth, 17, 40, 12, 24)
    h = math.min(h, maxHeight)

    drawCard(x, y, w, h, "Смерти")

    local availableLines = math.floor((h - S(52)) / S(17))
    local clipped = {}
    for i = 1, math.min(#wrapped, availableLines) do
        clipped[#clipped + 1] = wrapped[i]
    end

    drawWrappedLines(clipped, x + S(14), y + S(42), S(17), "PAT_SpectatorAssistSmall")
end

local function drawRecapPanel(x, y, maxWidth)
    if not deathRecap then return end

    local age = CurTime() - deathRecapReceivedAt
    local alpha = math.Clamp(1 - math.max(age - 8, 0) / 6, 0, 1)
    if alpha <= 0 then return end

    local items = getRecapItems(alpha)
    local w, h, wrapped = calcWrappedBlockSize(items, "Что случилось", "PAT_SpectatorAssistTitle", "PAT_SpectatorAssistBody", 280, maxWidth, 19, 40, 12, 24)

    drawCard(x, y, w, h, "Что случилось", alpha)
    drawWrappedLines(wrapped, x + S(14), y + S(42), S(19), "PAT_SpectatorAssistBody")
end

local function calcFeedEntrySize(entry, maxWidth)
    local titleLines = buildWrappedColorLines({
        { text = entry.title or "", color = entry.color or colInfo }
    }, "PAT_SpectatorAssistBody", maxWidth - S(20))

    local detailLines = buildWrappedColorLines({
        { text = entry.details or "", color = colSoft }
    }, "PAT_SpectatorAssistSmall", maxWidth - S(20))

    local height = S(8) + (#titleLines * S(18)) + S(4) + (#detailLines * S(16)) + S(8)
    return titleLines, detailLines, height
end

local function drawFeedStack(sw, sh)
    local maxWidth = math.max(S(220), math.min(S(360), math.floor(sw * 0.30)))
    maxWidth = math.min(maxWidth, sw - S(32))
    local x = sw - maxWidth - S(16)
    local y = sh - S(16)
    local shown = 0

    for i = 1, #feed do
        local entry = feed[i]
        local age = CurTime() - (entry.time or CurTime())

        if age <= feedLifetime then
            local alpha = math.Clamp(1 - math.max(age - 10, 0) / 8, 0.2, 1)
            local titleLines, detailLines, h = calcFeedEntrySize(entry, maxWidth)
            y = y - h

            drawCard(x, y, maxWidth, h, nil, alpha)

            local lineY = y + S(8)
            for _, line in ipairs(titleLines) do
                DrawUIText(line.text, "PAT_SpectatorAssistBody", x + S(12), lineY, ColorAlpha(line.color or colInfo, 255 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                lineY = lineY + S(18)
            end

            lineY = lineY + S(4)

            for _, line in ipairs(detailLines) do
                DrawUIText(line.text, "PAT_SpectatorAssistSmall", x + S(12), lineY, ColorAlpha(colSoft, 255 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                lineY = lineY + S(16)
            end

            y = y - S(8)
            shown = shown + 1
        end

        if shown >= 3 then
            break
        end
    end
end

net.Receive("PAT_SpectatorTimelineSync", function()
    timeline = net.ReadTable() or {}
end)

net.Receive("PAT_SpectatorTimelinePush", function()
    pushTimeline(net.ReadTable())
end)

net.Receive("PAT_SpectatorDeathRecap", function()
    deathRecap = net.ReadTable() or {}
    deathRecapReceivedAt = CurTime()
    pushFeed("Смерть", deathRecap.summary or "Информация обновлена.", colBad)
end)

hook.Add("OnPlayerChat", "PAT_SpectatorAssist_SystemMessages", function(ply, text)
    if IsValid(ply) then return end

    text = string.Trim(tostring(text or ""))
    if text == "" then return end

    pushFeed("Сервер", text, colInfo)
end)

hook.Add("HUDPaint", "PAT_SpectatorAssist_HUD", function()
    local lply = LocalPlayer()
    if not IsValid(lply) or lply:Alive() then return end

    EnsureFonts()

    local sw, sh = ScrW(), ScrH()
    local margin = S(16)
    local bottomReserve = S(52)

    local specItems = getSpectatorLines()
    local specW, specH, specWrapped = calcWrappedBlockSize(
        specItems,
        "Наблюдение",
        "PAT_SpectatorAssistTitle",
        "PAT_SpectatorAssistBody",
        280,
        math.max(S(220), math.min(S(460), math.floor(sw * 0.34))),
        18,
        40,
        14,
        24
    )

    drawCard(margin, margin, specW, specH, "Наблюдение")
    drawWrappedLines(specWrapped, margin + S(14), margin + S(42), S(18), "PAT_SpectatorAssistBody")

    local timelineMaxW = math.max(S(210), math.min(S(420), math.floor(sw * 0.32)))
    local timelineMaxH = math.max(S(150), math.min(S(260), math.floor(sh * 0.34)))
    drawTimelinePanel(sw - timelineMaxW - margin, margin, timelineMaxW, timelineMaxH)

    if deathRecap then
        local age = CurTime() - deathRecapReceivedAt
        local alpha = math.Clamp(1 - math.max(age - 8, 0) / 6, 0, 1)
        if alpha > 0 then
            local recapMaxW = math.max(S(240), math.min(S(480), math.floor(sw * 0.38)))
            local recapItems = getRecapItems(alpha)
            local recapW, recapH = calcWrappedBlockSize(
                recapItems,
                "Что случилось",
                "PAT_SpectatorAssistTitle",
                "PAT_SpectatorAssistBody",
                300,
                recapMaxW,
                19,
                40,
                12,
                24
            )

            drawRecapPanel(margin, math.max(margin, sh - recapH - margin - bottomReserve), recapMaxW)
        end
    end

    drawFeedStack(sw, sh)
end)
