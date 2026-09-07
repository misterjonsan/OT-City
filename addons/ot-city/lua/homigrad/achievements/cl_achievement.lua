hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = hg.achievements.achievements_data.created_achevements or {}

hg.achievements.MenuPanel = hg.achievements.MenuPanel or nil
hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}

local CreateMenuPanel
local time_wait = 0
local AchTable = hg.achievements.NewAchievements

BlurBackground = BlurBackground or hg.DrawBlur

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_dim = Color(150, 190, 220)
local clr_bg = Color(3, 5, 9, 235)
local clr_card = Color(6, 12, 20, 168)
local clr_card_hover = Color(12, 22, 36, 205)
local clr_locked = Color(112, 126, 140)

local MENU_MUSIC_URL = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/Danny_Elfman_-_Main_Titles_OST_Charlie_and_the_Chocolate_Factory_(SkySound.cc).mp3"

ZACH_MusicVol = ZACH_MusicVol or 0
ZACH_MusicState = ZACH_MusicState or "stopped"

concommand.Add("hg_achievements", function()
    CreateMenuPanel()
end)

local function DrawRound(rad, x, y, w, h, col)
    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(n * Sc())
end

local function DrawSlant(x, y, w, h, col, skew)
    skew = skew or h

    surface.SetDrawColor(col)
    draw.NoTexture()
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w + skew, y = y},
        {x = x + w, y = y + h},
        {x = x, y = y + h}
    })
end

local function SmoothNoise(t, f1, f2, f3, phase)
    phase = phase or 0

    return math.sin(t * f1 * math.pi * 2 + phase) * 0.55
        + math.sin(t * f2 * math.pi * 2 + phase + 2.399) * 0.30
        + math.sin(t * f3 * math.pi * 2 + phase + 5.131) * 0.15
end

local function Trim(text, font, maxW)
    text = tostring(text or "")

    surface.SetFont(font)

    if surface.GetTextSize(text) <= maxW then
        return text
    end

    local out = text

    while #out > 1 do
        if utf8 and utf8.len(out) and utf8.len(out) > 1 then
            out = string.sub(out, 1, utf8.offset(out, utf8.len(out)) - 1)
        else
            out = string.sub(out, 1, #out - 1)
        end

        if surface.GetTextSize(out .. "...") <= maxW then
            break
        end
    end

    return out .. "..."
end

local function DrawIcon(mat, x, y, size, alpha)
    if not mat or mat:IsError() then
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if not iw or iw <= 0 or not ih or ih <= 0 then
        iw, ih = 1, 1
    end

    local scale = math.min(size / iw, size / ih)
    local dw, dh = iw * scale, ih * scale

    surface.SetDrawColor(255, 255, 255, alpha or 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x + (size - dw) * 0.5, y + (size - dh) * 0.5, dw, dh)
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("ZAch_Brand", {
        font = "Bahnschrift",
        size = math.floor(44 * s),
        weight = 800,
        italic = true,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_Sub", {
        font = "Bahnschrift",
        size = math.floor(20 * s),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_Section", {
        font = "Bahnschrift",
        size = math.floor(22 * s),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_RowTitle", {
        font = "Bahnschrift",
        size = math.floor(24 * s),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_RowSmall", {
        font = "Bahnschrift",
        size = math.floor(19 * s),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_Desc", {
        font = "Montserrat Medium",
        size = math.floor(17 * s),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_Status", {
        font = "Bahnschrift",
        size = math.floor(16 * s),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZAch_Close", {
        font = "Bahnschrift",
        size = math.floor(34 * s),
        weight = 800,
        antialias = true,
        extended = true
    })
end

CreateFonts()
hook.Add("OnScreenSizeChanged", "XC_AchFonts", CreateFonts)

hook.Add("Think", "ZC_AchievementMusicFade", function()
    local menuOpen = hg.achievements.MenuPanel and IsValid(hg.achievements.MenuPanel)

    if not menuOpen then
        ZACH_MusicState = "out"
    end

    if not IsValid(ZACH_MusicChannel) then
        return
    end

    local ft = FrameTime()

    if ZACH_MusicState == "in" then
        ZACH_MusicVol = Lerp(ft * 1.1, ZACH_MusicVol, 1)
    elseif ZACH_MusicState == "out" then
        ZACH_MusicVol = Lerp(ft * 3.0, ZACH_MusicVol, 0)

        if ZACH_MusicVol <= 0.01 then
            ZACH_MusicChannel:Stop()
            ZACH_MusicChannel = nil
            ZACH_MusicVol = 0
            ZACH_MusicState = "stopped"
            ZACH_PlayingURL = nil
            return
        end
    end

    ZACH_MusicChannel:SetVolume(math.Clamp(ZACH_MusicVol, 0, 1))
end)

local function StartMenuMusic()
    ZACH_DesiredURL = MENU_MUSIC_URL
    ZACH_MusicState = "in"

    if IsValid(ZACH_MusicChannel) and ZACH_PlayingURL == MENU_MUSIC_URL then
        return
    end

    if IsValid(ZACH_MusicChannel) then
        ZACH_MusicChannel:Stop()
        ZACH_MusicChannel = nil
    end

    ZACH_MusicVol = 0
    ZACH_PlayingURL = MENU_MUSIC_URL

    local url = MENU_MUSIC_URL

    sound.PlayURL(url, "noplay noblock", function(channel)
        if not IsValid(channel) then
            return
        end

        if ZACH_DesiredURL ~= url then
            channel:Stop()
            return
        end

        ZACH_MusicChannel = channel
        channel:SetVolume(0)
        channel:EnableLooping(true)
        channel:Play()
    end)
end

local function GetPlayerAchievements()
    local sid = tostring(LocalPlayer():SteamID())
    hg.achievements.achievements_data.player_achievements[sid] = hg.achievements.achievements_data.player_achievements[sid] or {}

    return hg.achievements.achievements_data.player_achievements[sid]
end

local function GetAchievementProgress(ach)
    local localach = GetPlayerAchievements()
    local data = localach[ach.key] or {}
    local startValue = tonumber(ach.start_value) or 0
    local neededValue = tonumber(ach.needed_value) or 1
    local value = tonumber(data.value) or startValue
    local progress = math.Clamp(neededValue > 0 and (value / neededValue) or 0, 0, 1)
    local complete = value >= neededValue

    return value, neededValue, progress, complete
end

local function GetAchievementStats()
    local created = hg.achievements.achievements_data.created_achevements or {}
    local localach = GetPlayerAchievements()
    local total = table.Count(created)
    local unlocked = 0

    for _, ach in pairs(created) do
        local data = localach[ach.key]
        local value = tonumber(data and data.value) or tonumber(ach.start_value) or 0
        local needed = tonumber(ach.needed_value) or 1

        if value >= needed then
            unlocked = unlocked + 1
        end
    end

    return unlocked, total
end

local function CreateAchievementButton(parent, ach)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button:Dock(TOP)
    button:SetTall(SX(100))
    button:DockMargin(0, 0, SX(12), SX(10))
    button:SetCursor("hand")
    button.HoverLerp = 0
    button.BarLerp = 0
    button.Achievement = ach
    button.IconMat = isstring(ach.img) and Material(ach.img, "smooth") or ach.img

    function button:Paint(w, h)
        self.HoverLerp = LerpFT(0.16, self.HoverLerp or 0, self:IsHovered() and 1 or 0)

        local value, needed, progress, complete = GetAchievementProgress(self.Achievement)
        local accent = complete and clr_accent or clr_locked
        local rad = math.max(5, SX(12))

        self.BarLerp = LerpFT(0.2, self.BarLerp or 0, progress)

        local bg = Color(
            Lerp(self.HoverLerp, clr_card.r, clr_card_hover.r),
            Lerp(self.HoverLerp, clr_card.g, clr_card_hover.g),
            Lerp(self.HoverLerp, clr_card.b, clr_card_hover.b),
            Lerp(self.HoverLerp, clr_card.a, clr_card_hover.a)
        )

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(accent.r, accent.g, accent.b, 45 + self.HoverLerp * 95), 1)
        DrawRound(math.max(2, SX(3)), SX(2), SX(12), math.max(2, SX(4)), h - SX(24), Color(accent.r, accent.g, accent.b, 140 + self.HoverLerp * 100))

        local pad = SX(16)
        local iconSize = h - pad * 2
        local iconX = pad + SX(6)
        local iconRad = math.max(4, SX(10))
        local picSize = math.floor(iconSize * 0.58)
        local picOff = math.floor((iconSize - picSize) * 0.5)

        DrawRound(iconRad, iconX, pad, iconSize, iconSize, Color(255, 255, 255, 12))
        DrawIcon(self.IconMat, iconX + picOff, pad + picOff, picSize, complete and 255 or 165)
        DrawRoundOutlined(iconRad, iconX, pad, iconSize, iconSize, Color(accent.r, accent.g, accent.b, complete and 150 or 65), 1)

        local textX = iconX + iconSize + SX(16)
        local rightPad = SX(18)
        local textW = w - textX - rightPad
        local title = string.upper(self.Achievement.name or "Без названия")
        local statusText = complete and "ПОЛУЧЕНО" or "В ПРОЦЕССЕ"

        local percent = math.Round(progress * 100)
        local progressText = string.Comma(value) .. " / " .. string.Comma(needed)

        if self.Achievement.showpercent then
            progressText = progressText .. "  •  " .. percent .. "%"
        end

        surface.SetFont("ZAch_Status")
        local statusW = surface.GetTextSize(statusText)

        surface.SetFont("ZAch_RowSmall")
        local progressW = surface.GetTextSize(progressText)

        draw.SimpleText(Trim(title, "ZAch_RowTitle", textW - statusW - SX(16)), "ZAch_RowTitle", textX, SX(15), complete and clr_text or clr_locked, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(statusText, "ZAch_Status", w - rightPad, SX(19), complete and clr_accent or Color(clr_locked.r, clr_locked.g, clr_locked.b, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        local description = self.Achievement.description or "Нет описания"

        draw.SimpleText(Trim(description, "ZAch_Desc", textW - progressW - SX(18)), "ZAch_Desc", textX, SX(45), Color(clr_dim.r, clr_dim.g, clr_dim.b, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(progressText, "ZAch_RowSmall", w - rightPad, SX(44), Color(clr_text.r, clr_text.g, clr_text.b, 230), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        local barW = textW
        local barH = math.max(3, SX(7))
        local barY = h - SX(24)
        local barRad = math.max(2, math.floor(barH * 0.5))
        local fill = math.Clamp(self.BarLerp or 0, 0, 1)

        //draw.SimpleText(percent .. "%", "ZAch_Status", w - rightPad, barY - SX(7), Color(accent.r, accent.g, accent.b, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

        DrawRound(barRad, textX, barY, barW, barH, Color(255, 255, 255, 26))

        if fill > 0 then
            DrawRound(barRad, textX, barY, math.max(barH, barW * fill), barH, accent)
        end
    end

    return button
end

local PANEL = {}

function PANEL:StartMusic()
    StartMenuMusic()
end

function PANEL:GetLayoutData(w, h)
    local headerY = SX(36)
    local contentW = math.min(SX(840), w - SX(200))
    local contentX = math.floor((w - contentW) * 0.5)
    local contentY = headerY + SX(158)
    local contentH = h - contentY - SX(52)

    return headerY, contentX, contentY, contentW, contentH
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetTitle("")
    self:SetBorder(false)
    self:SetColorBG(clr_bg)
    self:SetBlurStrengh(0)
    self:SetDraggable(false)
    self:ShowCloseButton(false)

    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()
    self.OpenTime = RealTime()
    self.BGZoom = 1.18
    self.BGPanX = 0
    self.BGPanY = 0
    self.StatFill = 0

    self:StartMusic()

    self.Scroll = vgui.Create("DScrollPanel", self)
    self.Scroll.Paint = nil

    local vbar = self.Scroll:GetVBar()
    vbar:SetWide(math.max(3, SX(5)))
    vbar:SetHideButtons(true)

    function vbar:Paint(w, h)
        DrawRound(math.max(2, SX(3)), w * 0.5 - math.max(1, SX(1)), 0, math.max(1, SX(2)), h, Color(255, 255, 255, 20))
    end

    function vbar.btnGrip:Paint(w, h)
        DrawRound(math.max(2, SX(3)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 215))
    end

    function vbar.btnUp:Paint()
    end

    function vbar.btnDown:Paint()
    end

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("")
    self.CloseButton:SetCursor("hand")
    self.CloseButton.HoverLerp = 0

    self.CloseButton.DoClick = function()
        if IsValid(self) then
            self:Close()
        end
    end

    self.CloseButton.Paint = function(btn, w, h)
        btn.HoverLerp = LerpFT(0.16, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local rad = math.max(5, SX(12))
        local bg = Color(
            Lerp(btn.HoverLerp, clr_card.r, clr_card_hover.r),
            Lerp(btn.HoverLerp, clr_card.g, clr_card_hover.g),
            Lerp(btn.HoverLerp, clr_card.b, clr_card_hover.b),
            Lerp(btn.HoverLerp, 190, 235)
        )

        local txt = Color(
            Lerp(btn.HoverLerp, clr_text.r, clr_accent.r),
            Lerp(btn.HoverLerp, clr_text.g, clr_accent.g),
            Lerp(btn.HoverLerp, clr_text.b, clr_accent.b),
            245
        )

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + btn.HoverLerp * 150), 1)
        draw.SimpleText("×", "ZAch_Close", w * 0.5, h * 0.46, txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self:BuildContent()

    timer.Simple(0, function()
        if IsValid(self) then
            self:First()
        end
    end)
end

function PANEL:First()
    self:AlphaTo(255, 0.18, 0)
end

function PANEL:PerformLayout(w, h)
    local _, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)

    if IsValid(self.Scroll) then
        self.Scroll:SetPos(contentX, contentY)
        self.Scroll:SetSize(contentW, math.max(SX(80), contentH))
    end

    if IsValid(self.CloseButton) then
        local s = SX(46)
        self.CloseButton:SetSize(s, s)
        self.CloseButton:SetPos(w - s - SX(48), SX(40))
    end
end

function PANEL:PaintBackground(w, h)
    local mat = self.BGMaterial

    if not mat or mat:IsError() then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local elapsed = RealTime() - (self.BGStartTime or RealTime())
    local dt = math.Clamp(FrameTime(), 0, 0.1)
    local blend = 1 - math.exp(-dt * 1.35)
    local zoomTarget = 1.18 + (SmoothNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
    local panXTarget = SmoothNoise(elapsed, 0.0131, 0.0207, 0.0331, 1.3)
    local panYTarget = SmoothNoise(elapsed, 0.0113, 0.0181, 0.0293, 4.9)

    self.BGZoom = (self.BGZoom or zoomTarget) + (zoomTarget - (self.BGZoom or zoomTarget)) * blend
    self.BGPanX = (self.BGPanX or panXTarget) + (panXTarget - (self.BGPanX or panXTarget)) * blend
    self.BGPanY = (self.BGPanY or panYTarget) + (panYTarget - (self.BGPanY or panYTarget)) * blend

    local baseScale = math.max(w / iw, h / ih)
    local scale = baseScale * self.BGZoom
    local drawW = iw * scale
    local drawH = ih * scale
    local safeX = math.max((drawW - w) * 0.5, 0)
    local safeY = math.max((drawH - h) * 0.5, 0)
    local x = (w - drawW) * 0.5 + self.BGPanX * safeX * 0.72
    local y = (h - drawH) * 0.5 + self.BGPanY * safeY * 0.72

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Paint(w, h)
    self:PaintBackground(w, h)

    surface.SetDrawColor(1, 4, 8, 132)
    surface.DrawRect(0, 0, w, h)

    local headerY, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)
    local cx = w * 0.5

    surface.SetFont("ZAch_Brand")
    local otW = surface.GetTextSize("OT-")
    local brandW = otW + surface.GetTextSize("CITY")

    draw.SimpleText("OT-", "ZAch_Brand", cx - brandW * 0.5 + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZAch_Brand", cx - brandW * 0.5 + otW + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "ZAch_Brand", cx - brandW * 0.5, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZAch_Brand", cx - brandW * 0.5 + otW, headerY, clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("ДОСТИЖЕНИЯ", "ZAch_Sub", cx, headerY + SX(58), Color(clr_dim.r, clr_dim.g, clr_dim.b, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local stripeW = SX(48)
    local stripeY = headerY + SX(69)

    surface.SetFont("ZAch_Sub")
    local subW = surface.GetTextSize("ДОСТИЖЕНИЯ")

    DrawSlant(cx - subW * 0.5 - SX(18) - stripeW, stripeY, stripeW, math.max(2, SX(3)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190), SX(6))
    DrawSlant(cx + subW * 0.5 + SX(18), stripeY, stripeW, math.max(2, SX(3)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190), SX(6))

    local unlocked, total = GetAchievementStats()
    local frac = total > 0 and math.Clamp(unlocked / total, 0, 1) or 0

    self.StatFill = LerpFT(0.2, self.StatFill or 0, frac)

    local fill = math.Clamp(self.StatFill or 0, 0, 1)
    local barW = math.min(SX(560), w * 0.44)
    local barH = SX(18)
    local barX = cx - barW * 0.5
    local barY = headerY + SX(98)
    local barRad = math.max(3, math.floor(barH * 0.5))

    DrawRound(barRad, barX, barY, barW, barH, Color(255, 255, 255, 26))
    DrawRoundOutlined(barRad, barX, barY, barW, barH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60), 1)

    if fill > 0 then
        DrawRound(barRad, barX, barY, math.max(barH, barW * fill), barH, clr_accent)
    end

    draw.SimpleText("ОТКРЫТО: " .. unlocked .. " / " .. total, "ZAch_Status", barX, barY - SX(8), Color(clr_text.r, clr_text.g, clr_text.b, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

    if total > 0 and unlocked >= total then
        draw.SimpleText("ВСЕ ДОСТИЖЕНИЯ ПОЛУЧЕНЫ", "ZAch_Status", barX + barW, barY - SX(8), clr_cyan, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    else
        draw.SimpleText("ОСТАЛОСЬ: " .. math.max(total - unlocked, 0), "ZAch_Status", barX + barW, barY - SX(8), Color(clr_dim.r, clr_dim.g, clr_dim.b, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end

    draw.SimpleText(math.Round(frac * 100) .. "%", "ZAch_Status", cx, barY + barH + SX(4), Color(clr_dim.r, clr_dim.g, clr_dim.b, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local boxRad = math.max(6, SX(16))

    DrawRound(boxRad, contentX - SX(16), contentY - SX(16), contentW + SX(32), contentH + SX(32), Color(4, 9, 16, 148))
    DrawRoundOutlined(boxRad, contentX - SX(16), contentY - SX(16), contentW + SX(32), contentH + SX(32), Color(255, 255, 255, 14), 1)
end

function PANEL:BuildSectionLabel(parent, text)
    local category = vgui.Create("DPanel", parent)
    category:Dock(TOP)
    category:SetTall(SX(34))
    category:DockMargin(0, 0, SX(12), SX(10))

    category.Paint = function(_, w, h)
        draw.SimpleText(string.upper(text), "ZAch_Section", 0, h * 0.5 - SX(3), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetFont("ZAch_Section")
        local tw = surface.GetTextSize(string.upper(text))

        DrawSlant(tw + SX(14), h * 0.5 - SX(4), math.max(SX(28), w - tw - SX(30)), math.max(2, SX(3)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 130), SX(6))
    end
end

function PANEL:BuildContent()
    if not IsValid(self.Scroll) then
        return
    end

    self.Scroll:Clear()

    local canvas = self.Scroll:GetCanvas()

    self:BuildSectionLabel(canvas, "Список достижений")

    local achievements = hg.achievements.achievements_data.created_achevements or {}
    local sorted = {}

    for _, ach in pairs(achievements) do
        table.insert(sorted, ach)
    end

    table.sort(sorted, function(a, b)
        local _, _, pa, ca = GetAchievementProgress(a)
        local _, _, pb, cb = GetAchievementProgress(b)

        if ca ~= cb then
            return ca
        end

        if pa ~= pb then
            return pa > pb
        end

        return (a.name or "") < (b.name or "")
    end)

    if #sorted == 0 then
        local empty = vgui.Create("DPanel", canvas)
        empty:Dock(TOP)
        empty:SetTall(SX(72))
        empty:DockMargin(0, 0, SX(12), SX(10))

        empty.Paint = function(_, w, h)
            local rad = math.max(5, SX(12))

            DrawRound(rad, 0, 0, w, h, clr_card)
            DrawRoundOutlined(rad, 0, 0, w, h, Color(255, 255, 255, 14), 1)
            draw.SimpleText("Достижения ещё не загружены", "ZAch_RowSmall", w * 0.5, h * 0.5, Color(clr_dim.r, clr_dim.g, clr_dim.b, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        return
    end

    for _, ach in ipairs(sorted) do
        CreateAchievementButton(canvas, ach)
    end
end

function PANEL:UpdateValues()
    self:BuildContent()
end

function PANEL:Close()
    if self.Closing then
        return
    end

    self.Closing = true

    self:AlphaTo(0, 0.12, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZAchievementsMenu", PANEL, "ZFrame")

CreateMenuPanel = function()
    hg.achievements.LoadAchievements()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:Close()
        hg.achievements.MenuPanel = nil
        return
    end

    local frame = vgui.Create("ZAchievementsMenu")
    hg.achievements.MenuPanel = frame
    frame:MakePopup()
end

function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())]
end

net.Receive("req_ach", function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())] = net.ReadTable()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

net.Receive("hg_NewAchievement", function()
    local Ach = {
        time = CurTime() + 7.5,
        name = net.ReadString(),
        img = net.ReadString()
    }

    table.insert(AchTable, 1, Ach)
    surface.PlaySound("homigrad/vgui/achievement_earned.wav")
end)

hook.Add("HUDPaint", "hg_NewAchievement", function()
    local frametime = FrameTime() * 10

    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end

        local txt = "ДОСТИЖЕНИЕ"
        local name = ach.name or ""

        ach.img = isstring(ach.img) and Material(ach.img, "smooth") or ach.img
        ach.Lerp = Lerp(frametime, ach.Lerp or 0, math.min(ach.time - CurTime(), 1) * i)

        surface.SetFont("ZAch_RowSmall")
        local nameW, nameH = surface.GetTextSize(name)

        local hSize = SX(62)
        local iconSize = hSize - SX(16)
        local wSize = math.max(ScrW() * 0.2, nameW + iconSize + SX(60))
        local hPos = ScrH() - hSize * math.Clamp(ach.Lerp or 0, 0, 1) - SX(24)
        local xPos = SX(24)
        local rad = math.max(5, SX(14))

        DrawRound(rad, xPos, hPos, wSize, hSize, Color(6, 12, 20, 235))
        DrawRoundOutlined(rad, xPos, hPos, wSize, hSize, Color(clr_accent.r, clr_accent.g, clr_accent.b, 150), 1)
        DrawRound(math.max(2, SX(3)), xPos + SX(3), hPos + SX(10), math.max(2, SX(4)), hSize - SX(20), Color(clr_accent.r, clr_accent.g, clr_accent.b, 200))

        local iconX = xPos + SX(16)
        local iconY = hPos + (hSize - iconSize) * 0.5

        local picSize = math.floor(iconSize * 0.58)
        local picOff = math.floor((iconSize - picSize) * 0.5)

        DrawRound(math.max(4, SX(10)), iconX, iconY, iconSize, iconSize, Color(255, 255, 255, 12))
        DrawIcon(ach.img, iconX + picOff, iconY + picOff, picSize, 255)
        DrawRoundOutlined(math.max(4, SX(10)), iconX, iconY, iconSize, iconSize, Color(clr_accent.r, clr_accent.g, clr_accent.b, 140), 1)

        local textX = iconX + iconSize + SX(14)

        draw.SimpleText(txt, "ZAch_Status", textX, hPos + SX(12), clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(name, "ZAch_RowSmall", textX, hPos + SX(30), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if ach.time < CurTime() then
            table.remove(AchTable, i)
        end
    end
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "achievements menu loaded\n")
