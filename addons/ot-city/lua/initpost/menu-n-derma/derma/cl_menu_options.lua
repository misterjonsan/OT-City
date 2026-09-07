local PANEL = {}

hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_dark = Color(6, 14, 24, 155)
local clr_dark_hover = Color(12, 24, 38, 190)
local clr_verygray = Color(3, 5, 9, 235)
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local MENU_MUSIC_URL = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/Danny_Elfman_-_Main_Titles_OST_Charlie_and_the_Chocolate_Factory_(SkySound.cc).mp3"

ZMM_MusicVol = ZMM_MusicVol or 0
ZMM_MusicState = ZMM_MusicState or "stopped"

local function SmoothNoise(t, f1, f2, f3, phase)
    local a = math.sin((t + phase) * f1 * math.pi * 2)
    local b = math.sin((t + phase * 1.7) * f2 * math.pi * 2 + 2.399)
    local c = math.sin((t + phase * 2.3) * f3 * math.pi * 2 + 5.131)

    return math.Clamp(a * 0.55 + b * 0.30 + c * 0.15, -1, 1)
end

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
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
end

local function DrawSlant(x, y, w, h, skew, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w + skew, y = y},
        {x = x + w, y = y + h},
        {x = x, y = y + h}
    })
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("ZC_MM_Title", {
        font = "Montserrat SemiBold",
        size = math.floor(112 * s + 0.5),
        weight = 800,
        italic = true,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_SubTitle", {
        font = "Montserrat SemiBold",
        size = math.floor(46 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Team", {
        font = "Montserrat Medium",
        size = math.floor(21 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Close", {
        font = "Montserrat SemiBold",
        size = math.floor(34 * s + 0.5),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Cat", {
        font = "Montserrat SemiBold",
        size = math.floor(24 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Opt", {
        font = "Montserrat Medium",
        size = math.floor(22 * s + 0.5),
        weight = 500,
        antialias = true,
        extended = true
    })
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_MM_FontsOptions", CreateFonts)

hook.Add("Think", "ZMM_MusicFade", function()
    local menuOpen = (MainMenu and IsValid(MainMenu)) or (hg_options and IsValid(hg_options))

    if not menuOpen then
        ZMM_MusicState = "out"
    end

    if not IsValid(ZMM_MusicChannel) then
        return
    end

    local ft = FrameTime()

    if ZMM_MusicState == "in" then
        ZMM_MusicVol = Lerp(ft * 1.1, ZMM_MusicVol, 1)
    elseif ZMM_MusicState == "out" then
        ZMM_MusicVol = Lerp(ft * 3.0, ZMM_MusicVol, 0)

        if ZMM_MusicVol <= 0.01 then
            ZMM_MusicChannel:Stop()
            ZMM_MusicChannel = nil
            ZMM_MusicVol = 0
            ZMM_MusicState = "stopped"
            ZMM_PlayingURL = nil

            return
        end
    end

    ZMM_MusicChannel:SetVolume(math.Clamp(ZMM_MusicVol, 0, 1))
end)

function PANEL:StartMusic()
    ZMM_DesiredURL = MENU_MUSIC_URL
    ZMM_MusicState = "in"

    if IsValid(ZMM_MusicChannel) and ZMM_PlayingURL == MENU_MUSIC_URL then
        return
    end

    if IsValid(ZMM_MusicChannel) then
        ZMM_MusicChannel:Stop()
        ZMM_MusicChannel = nil
    end

    ZMM_MusicVol = 0
    ZMM_PlayingURL = MENU_MUSIC_URL

    local url = MENU_MUSIC_URL

    sound.PlayURL(url, "noplay noblock", function(channel, errID, errName)
        if not IsValid(channel) then
            return
        end

        if ZMM_DesiredURL ~= url then
            channel:Stop()

            return
        end

        ZMM_MusicChannel = channel
        channel:SetVolume(0)
        channel:EnableLooping(true)
        channel:Play()
    end)
end

function hg.settings:AddOpt(strCategory, strConVar, strTitle, bDecimals, bString)
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = {strCategory, strConVar, strTitle, bDecimals or false, bString or false}
end

hg.settings:AddOpt("Оптимизация", "hg_potatopc", "Режим слабого ПК")
hg.settings:AddOpt("Оптимизация", "hg_anims_draw_distance", "Дистанция прорисовки анимаций")
hg.settings:AddOpt("Оптимизация", "hg_anim_fps", "FPS анимаций")
hg.settings:AddOpt("Оптимизация", "hg_attachment_draw_distance", "Дистанция прорисовки обвесов")
hg.settings:AddOpt("Оптимизация", "hg_maxsmoketrails", "Максимум дымовых следов")
hg.settings:AddOpt("Оптимизация", "hg_tpik_distance", "Дистанция прорисовки TPIK")

hg.settings:AddOpt("Кровь", "hg_blood_draw_distance", "Дистанция прорисовки крови")
hg.settings:AddOpt("Кровь", "hg_blood_fps", "FPS крови")
hg.settings:AddOpt("Кровь", "hg_blood_sprites", "Спрайты крови (ОТКЛЮЧЕНО ДЛЯ ВСЕХ)")
hg.settings:AddOpt("Кровь", "hg_old_blood", "Изменить цвет крови")

hg.settings:AddOpt("Интерфейс", "hg_font", "Сменить пользовательский шрифт", false, true)

hg.settings:AddOpt("Оружие", "hg_weaponshotblur_enable", "Размытие при стрельбе")
hg.settings:AddOpt("Оружие", "hg_dynamic_mags", "Динамический осмотр патронов")

hg.settings:AddOpt("Вид", "hg_firstperson_death", "Смерть от первого лица")
hg.settings:AddOpt("Вид", "hg_fov", "Угол обзора (FOV)")
hg.settings:AddOpt("Вид", "mzb_MoodleHud", "Включить иконки состояния (голод, жажда и т.д.)")
hg.settings:AddOpt("Вид", "hg_coolgloves", "Красивые перчатки")
hg.settings:AddOpt("Вид", "hg_newspectate", "Плавная камера наблюдателя")
hg.settings:AddOpt("Вид", "mzb_MoodleHud_enabled", "Худ состояния персонажа")
hg.settings:AddOpt("Вид", "hg_change_gloves", "Модель перчаток")
hg.settings:AddOpt("Вид", "hg_cshs_fake", "Камера рагдолла C'sHS")
hg.settings:AddOpt("Вид", "hg_gun_cam", "Камера оружия (ТОЛЬКО АДМИН)")
hg.settings:AddOpt("Вид", "hg_nofovzoom", "Отключить/включить зум FOV")

if not ConVarExists("hg_headshotsound") then
    CreateClientConVar("hg_headshotsound", "1", true, false, "headshot hit sound", 0, 1)
end

hg.settings:AddOpt("Звук", "hg_dmusic", "Динамическая музыка")
hg.settings:AddOpt("Звук", "hg_headshotsound", "Звук попадания в голову")
hg.settings:AddOpt("Звук", "hg_quietshots", "Включить/выключить тихие звуки выстрелов (ДЛЯ ТРУСОВ)")

hg.settings:AddOpt("Игра", "hg_old_notificate", "Старые уведомления")
hg.settings:AddOpt("Игра", "hg_random_appearance", "Включить/выключить случайную внешность")
hg.settings:AddOpt("Игра", "hg_cheats", "Включить/выключить читы")

function PANEL:GetLayoutData(w, h)
    local s = Sc()

    local headerX = math.floor(216 * s)
    local headerY = math.floor(36 * s)
    local lineX = headerX - math.floor(21 * s)
    local lineY = headerY + math.floor(200 * s)
    local contentX = lineX + math.floor(81 * s)
    local contentY = lineY + math.floor(26 * s)
    local contentW = math.min(SX(1290), w - contentX - SX(165))
    local contentH = h - contentY - SX(40)

    return headerX, headerY, lineX, lineY, contentX, contentY, contentW, contentH
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:SetY(ScrH())
    self:SetX(0)
    self:SetTitle("")
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetBlurStrengh(0)
    self:SetDraggable(false)
    self:ShowCloseButton(false)

    self.Options = {}
    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()

    self:StartMusic()

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.fDock = vgui.Create("DScrollPanel", self)
    self.fDock.Paint = nil

    local vbar = self.fDock:GetVBar()
    vbar:SetWide(SX(9))

    function vbar:Paint(w, h)
        surface.SetDrawColor(168, 212, 245, 16)
        surface.DrawRect(w * 0.5 - 1, 0, 1, h)
    end

    function vbar.btnGrip:Paint(w, h)
        DrawRound(math.max(2, SX(4)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 215))
    end

    function vbar.btnUp:Paint(w, h)
    end

    function vbar.btnDown:Paint(w, h)
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
        btn.HoverLerp = LerpFT(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverLerp, 8, 16),
            Lerp(btn.HoverLerp, 18, 60),
            Lerp(btn.HoverLerp, 30, 96),
            Lerp(btn.HoverLerp, 155, 225)
        )

        local outline = Color(
            clr_accent.r,
            clr_accent.g,
            clr_accent.b,
            70 + btn.HoverLerp * 150
        )

        local txt = Color(
            Lerp(btn.HoverLerp, 235, clr_accent.r),
            Lerp(btn.HoverLerp, 235, clr_accent.g),
            Lerp(btn.HoverLerp, 235, clr_accent.b),
            245
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, outline, 1)

        draw.SimpleText("×", "ZC_MM_Close", w * 0.5, h * 0.48, txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    for _, t in SortedPairs(hg.settings.tbl) do
        for _, tbl in SortedPairs(t) do
            local convar = GetConVar(tbl[2])

            if convar then
                local isBool = convar:GetMin() == 0 and convar:GetMax() == 1
                self:CreateOption(tbl[1], isBool, convar, tbl[4], tbl[3] or convar:GetName(), nil, tbl[5])
            end
        end
    end

    self:InvalidateLayout(true)
end

function PANEL:First()
    self:MoveTo(self:GetX(), 0, 0.32, 0, 0.2, function() end)
    self:AlphaTo(255, 0.18, 0.08, nil)
end

function PANEL:PerformLayout(w, h)
    local _, _, _, _, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)

    if IsValid(self.fDock) then
        self.fDock:SetPos(contentX, contentY)
        self.fDock:SetSize(contentW, contentH)
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
        surface.SetDrawColor(clr_verygray)
        surface.DrawRect(0, 0, w, h)

        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(clr_verygray)
        surface.DrawRect(0, 0, w, h)

        return
    end

    local now = RealTime()

    self.BGStartTime = self.BGStartTime or now
    self.BGLastTime = self.BGLastTime or now

    local elapsed = now - self.BGStartTime
    local dt = math.Clamp(now - self.BGLastTime, 0, 0.1)

    self.BGLastTime = now

    local zoomTarget = 1.18 + (SmoothNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
    local panTargetX = SmoothNoise(elapsed, 0.0131, 0.0223, 0.0367, 1.3)
    local panTargetY = SmoothNoise(elapsed, 0.0117, 0.0196, 0.0341, 4.9)

    self.BGZoom = self.BGZoom or zoomTarget
    self.BGPanX = self.BGPanX or panTargetX
    self.BGPanY = self.BGPanY or panTargetY

    local blend = 1 - math.exp(-dt * 1.35)

    self.BGZoom = self.BGZoom + (zoomTarget - self.BGZoom) * blend
    self.BGPanX = self.BGPanX + (panTargetX - self.BGPanX) * blend
    self.BGPanY = self.BGPanY + (panTargetY - self.BGPanY) * blend

    local baseScale = math.max(w / iw, h / ih)
    local scale = baseScale * self.BGZoom
    local drawW = iw * scale
    local drawH = ih * scale

    local safeX = (drawW - w) * 0.5
    local safeY = (drawH - h) * 0.5

    if safeX < 0 then safeX = 0 end
    if safeY < 0 then safeY = 0 end

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

    draw.NoTexture()

    surface.SetDrawColor(1, 4, 8, 125)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(2, 7, 14, 230)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(1560), h)

    surface.SetDrawColor(2, 7, 14, 115)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(2280), h)

    draw.NoTexture()

    local headerX, headerY, lineX, lineY, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)
    local s = Sc()

    surface.SetFont("ZC_MM_Title")
    local xW = surface.GetTextSize("OT-")
    local shadow = Color(2, 8, 14, 190)

    draw.SimpleText("OT-", "ZC_MM_Title", headerX + SX(2), headerY + SX(3), shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZC_MM_Title", headerX + xW + SX(2), headerY + SX(3), shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "ZC_MM_Title", headerX, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZC_MM_Title", headerX + xW, headerY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local stripeY = headerY + math.floor(122 * s)
    local stripeH = math.max(2, math.floor(4 * s))

    DrawSlant(headerX + math.floor(4 * s), stripeY, math.floor(150 * s), stripeH, math.floor(10 * s), clr_accent)
    DrawSlant(headerX + math.floor(168 * s), stripeY, math.floor(30 * s), stripeH, math.floor(10 * s), clr_cyan)

    draw.SimpleText("Настройки", "ZC_MM_SubTitle", headerX, headerY + math.floor(140 * s), Color(240, 248, 255, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local lineW = math.max(2, SX(2))

    DrawRound(lineW, lineX - lineW, contentY, lineW * 3, contentH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 26))
    DrawRound(lineW * 0.5, lineX, contentY, lineW, contentH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 235))
end

function PANEL:CreateCategory(strCategory)
    local fDock = self.fDock

    if not self.Options[strCategory] then
        local category = vgui.Create("DLabel", fDock)

        category:Dock(TOP)
        category:SetTall(SX(63))
        category:SetText(strCategory)
        category:SetFont("ZC_MM_Cat")
        category:SetTextColor(Color(200, 232, 255, 235))
        category:DockMargin(0, SX(22), SX(30), SX(9))
        category:SetContentAlignment(4)

        category.Paint = function(_, w, h)
            DrawRound(1, 0, h - math.max(1, SX(2)), SX(114), math.max(1, SX(2)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190))
        end
    end

    self.Options[strCategory] = self.Options[strCategory] or {}

    return self.Options[strCategory]
end

function PANEL:CreateOption(strCategory, bType, cConVar, bDecimals, strTitle, strDesc, bString)
    if not cConVar then
        return
    end

    local fDock = self.fDock
    local Category = self:CreateCategory(strCategory)

    Category[cConVar:GetName()] = vgui.Create("DPanel", fDock)

    local opt = Category[cConVar:GetName()]

    opt:Dock(TOP)
    opt:SetTall(SX(72))
    opt:DockMargin(0, 0, SX(30), SX(10))
    opt.HoverLerp = 0

    function opt:Paint(w, h)
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(self.HoverLerp, clr_dark.r, clr_dark_hover.r),
            Lerp(self.HoverLerp, clr_dark.g, clr_dark_hover.g),
            Lerp(self.HoverLerp, clr_dark.b, clr_dark_hover.b),
            Lerp(self.HoverLerp, clr_dark.a, clr_dark_hover.a)
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 12 + self.HoverLerp * 42), 1)
        DrawRound(1, 0, SX(16), math.max(2, SX(2)), h - SX(32), Color(clr_accent.r, clr_accent.g, clr_accent.b, 65 + self.HoverLerp * 125))
    end

    opt.NLabel = vgui.Create("DLabel", opt)

    local NLbl = opt.NLabel
    local descText = strDesc or string.NiceName(cConVar:GetHelpText())

    if descText == "" then
        NLbl:SetText(strTitle)
    else
        NLbl:SetText(strTitle .. "\n" .. descText)
    end

    NLbl:SetFont("ZC_MM_Opt")
    NLbl:SetTextColor(clr_text)
    NLbl:SetContentAlignment(4)
    NLbl:Dock(LEFT)
    NLbl:DockMargin(SX(30), 0, SX(24), 0)
    NLbl:SetWide(SX(560))

    if bString then
        opt.TextInput = vgui.Create("DTextEntry", opt)

        local TextInput = opt.TextInput

        TextInput:Dock(RIGHT)
        TextInput:SetWide(SX(360))
        TextInput:DockMargin(SX(24), SX(16), SX(24), SX(16))
        TextInput:SetValue(cConVar:GetString())
        TextInput:SetPlaceholderText(cConVar:GetName())
        TextInput:SetFont("ZC_MM_Opt")
        TextInput:SetTextColor(Color(240, 248, 255, 235))
        TextInput:SetCursorColor(clr_accent)
        TextInput:SetDrawBackground(false)

        function TextInput:Paint(w, h)
            local rad = math.max(3, SX(5))

            DrawRound(rad, 0, 0, w, h, Color(4, 10, 18, 150))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self:IsEditing() and 180 or 55), 1)

            self:DrawTextEntryText(Color(240, 248, 255, 235), clr_accent, Color(255, 255, 255, 235))
        end

        function TextInput:OnLoseFocus()
            cConVar:SetString(self:GetValue())
        end
    elseif bType then
        opt.Button = vgui.Create("DButton", opt)

        local btn = opt.Button

        btn:SetText("")
        btn:Dock(RIGHT)
        btn:SetWide(SX(126))
        btn:DockMargin(SX(24), SX(20), SX(24), SX(20))
        btn.On = cConVar:GetBool()

        function btn:Paint(w, h)
            self.Lerp = LerpFT(0.2, self.Lerp or (self.On and 1 or 0), self.On and 1 or 0)

            DrawRound(h * 0.5, 0, 0, w, h, Color(4, 10, 18, 150))
            DrawRoundOutlined(h * 0.5, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 55 + self.Lerp * 155), 1)

            local pad = math.max(2, SX(3))
            local knobW = h - pad * 2
            local knobX = Lerp(self.Lerp, pad, w - knobW - pad)

            DrawRound(knobW * 0.5, knobX, pad, knobW, knobW, Color(
                Lerp(self.Lerp, 120, clr_accent.r),
                Lerp(self.Lerp, 140, clr_accent.g),
                Lerp(self.Lerp, 160, clr_accent.b),
                235
            ))
        end

        function btn:DoClick()
            cConVar:SetBool(not cConVar:GetBool())
            self.On = cConVar:GetBool()
        end
    else
        local Slid = vgui.Create("DNumSlider", opt)

        Slid:Dock(RIGHT)
        Slid:SetWide(SX(555))
        Slid:DockMargin(SX(24), SX(9), SX(24), SX(9))
        Slid:SetText("")
        Slid:SetMin(cConVar:GetMin())
        Slid:SetMax(cConVar:GetMax())
        Slid:SetDecimals(bDecimals and 2 or 0)
        Slid:SetConVar(cConVar:GetName())

        if IsValid(Slid.TextArea) then
            Slid.TextArea:SetFont("ZC_MM_Opt")
            Slid.TextArea:SetTextColor(Color(240, 248, 255, 235))
            Slid.TextArea:SetDrawBackground(false)
            Slid.TextArea:SetWide(SX(135))
        end

        if IsValid(Slid.Slider) then
            Slid.Slider.Paint = function(_, w, h)
                DrawRound(2, 0, h * 0.5 - 2, w, 4, Color(140, 200, 245, 30))

                local fillW = w * Slid.Slider:GetSlideX()

                if fillW > 4 then
                    DrawRound(2, 0, h * 0.5 - 2, fillW, 4, Color(clr_accent.r, clr_accent.g, clr_accent.b, 175))
                end
            end

            if IsValid(Slid.Slider.Knob) then
                Slid.Slider.Knob.Paint = function(_, w, h)
                    DrawRound(math.floor(math.min(w, h) * 0.5), 0, 0, w, h, clr_accent)
                end
            end
        end
    end
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

vgui.Register("ZOptions", PANEL, "ZFrame")

concommand.Add("hg_settings", function()
    if hg_options and IsValid(hg_options) then
        hg_options:Close()
        hg_options = nil

        return
    end

    local s = vgui.Create("ZOptions")

    s:MakePopup()

    hg_options = s
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "options menu loaded\n")
