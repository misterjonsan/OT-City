local OPEN_MSG = "sf_mainmenu_open"
local CLOSE_MSG = "sf_mainmenu_close"
local READY_MSG = "sf_mainmenu_ready"

local MUSIC_URL = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/otcity-ost.mp3"
local MENU_MUSIC_REPEAT = 200

local LOAD_MIN_TIME = 3
local LOAD_MAX_TIME = 35
local RES_TIMEOUT = 12

local gScreen
local gOpen = false
local gMusic
local gMusicResolved = false

local bgMat = Material("materials/hud/otcity3.png", "smooth noclamp")

surface.CreateFont("SF_SPLASH_Text", {
    font = "Montserrat SemiBold",
    size = 28,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("SF_LOADING_Text", {
    font = "Montserrat SemiBold",
    size = 30,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("SF_LOADING_Sub", {
    font = "Montserrat Medium",
    size = 20,
    weight = 500,
    extended = true,
    antialias = true
})

surface.CreateFont("SF_LOADING_Percent", {
    font = "Montserrat SemiBold",
    size = 34,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("SF_LOADING_Tiny", {
    font = "Montserrat Medium",
    size = 16,
    weight = 500,
    extended = true,
    antialias = true
})

local LOADING_HEADLINES = {
    "Загружаем системы",
    "Вызываем Вилли Вонку",
    "Прогреваем двигатели",
    "Согласуем всё с админами",
    "Калибруем удачу",
    "Заправляем город топливом",
    "Подкручиваем гайки",
    "Будим охранника на выезде"
}

local LOADING_TIPS = {
    "Ещё немного — и ты в деле",
    "Самое время налить чай",
    "Готовим для тебя лучшее место",
    "За шоколадный билет доплата не нужна",
    "Не закрывай игру, осталось совсем чуть-чуть",
    "Каждый заход начинается именно так"
}

local function BuildDiskPoly(cx, cy, radius, segments)
    local poly = {}
    for i = 0, segments - 1 do
        local a = math.rad(i / segments * 360)
        poly[#poly + 1] = {x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius}
    end
    return poly
end

local function DrawSoftDisk(cx, cy, radius, col)
    draw.NoTexture()
    local alpha = col.a or 255
    surface.SetDrawColor(col.r, col.g, col.b, alpha * 0.28)
    surface.DrawPoly(BuildDiskPoly(cx, cy, radius * 1.55, 26))
    surface.SetDrawColor(col.r, col.g, col.b, alpha * 0.55)
    surface.DrawPoly(BuildDiskPoly(cx, cy, radius * 1.2, 26))
    surface.SetDrawColor(col.r, col.g, col.b, alpha)
    surface.DrawPoly(BuildDiskPoly(cx, cy, radius, 26))
end

local function ArcQuad(cx, cy, inner, outer, a0, a1)
    local c0, s0 = math.cos(a0), math.sin(a0)
    local c1, s1 = math.cos(a1), math.sin(a1)
    return {
        {x = cx + c0 * outer, y = cy + s0 * outer},
        {x = cx + c1 * outer, y = cy + s1 * outer},
        {x = cx + c1 * inner, y = cy + s1 * inner},
        {x = cx + c0 * inner, y = cy + s0 * inner}
    }
end

local function DrawSmoothArc(cx, cy, radius, thickness, deg0, deg1, colorFn)
    local span = deg1 - deg0
    if span <= 0 then return end

    local steps = math.Clamp(math.ceil(span / 1.5), 8, 220)
    local start = math.rad(deg0)
    local step = math.rad(span) / steps
    local overlap = step * 0.5
    local half = thickness * 0.5
    local feather = math.max(1, thickness * 0.45)

    draw.NoTexture()

    for i = 0, steps - 1 do
        local col = colorFn((i + 0.5) / steps)
        local alpha = col and (col.a or 255) or 0
        if alpha > 1 then
            local a0 = start + step * i - overlap
            local a1 = start + step * (i + 1) + overlap
            surface.SetDrawColor(col.r, col.g, col.b, alpha * 0.16)
            surface.DrawPoly(ArcQuad(cx, cy, radius - half - feather * 1.7, radius + half + feather * 1.7, a0, a1))
            surface.SetDrawColor(col.r, col.g, col.b, alpha * 0.38)
            surface.DrawPoly(ArcQuad(cx, cy, radius - half - feather, radius + half + feather, a0, a1))
            surface.SetDrawColor(col.r, col.g, col.b, alpha)
            surface.DrawPoly(ArcQuad(cx, cy, radius - half, radius + half, a0, a1))
        end
    end
end

local function DrawSpinner(cx, cy, radius, thickness, t, col)
    local base = col.a or 255
    local head = (t * 165) % 360
    local sweep = 150 + math.sin(t * 0.9) * 55

    DrawSmoothArc(cx, cy, radius, thickness, head - sweep, head, function(f)
        local fade = math.pow(math.Clamp(f, 0, 1), 2.1)
        return Color(col.r, col.g, col.b, base * fade)
    end)

    local hr = math.rad(head)
    DrawSoftDisk(cx + math.cos(hr) * radius, cy + math.sin(hr) * radius, thickness * 0.52, Color(col.r, col.g, col.b, base))

    local tr = math.rad(head - sweep)
    DrawSoftDisk(cx + math.cos(tr) * radius, cy + math.sin(tr) * radius, thickness * 0.3, Color(col.r, col.g, col.b, base * 0.12))
end

local function StopMenuMusic(immediate)
    timer.Remove("sf_mainmenu_music_repeat")
    timer.Remove("sf_mainmenu_music_fadeout")

    if not IsValid(gMusic) then
        gMusic = nil
        return
    end

    if immediate then
        gMusic:Stop()
        gMusic = nil
        return
    end

    local ch = gMusic
    local vol = ch:GetVolume()
    local step = 0

    timer.Create("sf_mainmenu_music_fadeout", 0.05, 20, function()
        if not IsValid(ch) then
            timer.Remove("sf_mainmenu_music_fadeout")
            return
        end

        step = step + 1
        ch:SetVolume(math.max(0, vol * (1 - step / 20)))

        if step >= 20 then
            ch:Stop()
            if gMusic == ch then gMusic = nil end
            timer.Remove("sf_mainmenu_music_fadeout")
        end
    end)
end

local function PreloadMusic()
    gMusicResolved = false

    if IsValid(gMusic) then
        gMusicResolved = true
        return
    end

    sound.PlayURL(MUSIC_URL, "noplay", function(ch)
        gMusicResolved = true
        if not IsValid(ch) then return end
        gMusic = ch
        gMusic:SetVolume(0)
    end)

    timer.Create("sf_mainmenu_music_timeout", RES_TIMEOUT, 1, function()
        gMusicResolved = true
    end)
end

local function PlayMenuMusic()
    if not IsValid(gMusic) then
        PreloadMusic()
        timer.Create("sf_mainmenu_music_retry", 0.5, 20, function()
            if not gOpen then
                timer.Remove("sf_mainmenu_music_retry")
                return
            end
            if IsValid(gMusic) then
                timer.Remove("sf_mainmenu_music_retry")
                PlayMenuMusic()
            end
        end)
        return
    end

    gMusic:SetVolume(0)
    gMusic:Play()

    local ch = gMusic
    local step = 0
    timer.Create("sf_mainmenu_music_fadein", 0.05, 20, function()
        if not IsValid(ch) then
            timer.Remove("sf_mainmenu_music_fadein")
            return
        end
        step = step + 1
        ch:SetVolume(math.min(0.7, 0.7 * (step / 20)))
    end)

    timer.Remove("sf_mainmenu_music_repeat")
    timer.Create("sf_mainmenu_music_repeat", MENU_MUSIC_REPEAT, 1, function()
        if not gOpen or not IsValid(gScreen) then return end
        StopMenuMusic(true)
        PreloadMusic()
        timer.Simple(1, function()
            if gOpen and IsValid(gScreen) then PlayMenuMusic() end
        end)
    end)
end

local function NotifyServer(msg)
    if netstream and netstream.Start then
        netstream.Start(msg)
    end
end

local function RemoveScreen()
    if IsValid(gScreen) then gScreen:Remove() end
    gScreen = nil
end

local function FinishAndClose()
    StopMenuMusic(false)
    NotifyServer(CLOSE_MSG)
    RemoveScreen()
    gOpen = false
    gui.EnableScreenClicker(false)
end

local function OpenMenu()
    RemoveScreen()
    RunConsoleCommand("third_person", "0")

    gOpen = true
    gui.EnableScreenClicker(false)
    PreloadMusic()

    gScreen = vgui.Create("DFrame")
    gScreen:SetSize(ScrW(), ScrH())
    gScreen:SetPos(0, 0)
    gScreen:SetTitle("")
    gScreen:ShowCloseButton(false)
    gScreen:SetDraggable(false)
    gScreen:MakePopup()
    gScreen:SetMouseInputEnabled(true)
    gScreen:SetKeyboardInputEnabled(true)

    local s = gScreen

    s.state = "loading"
    s.loadingStart = RealTime()
    s.readyAt = 0
    s.revealStart = 0
    s.closeStart = 0
    s.fade = 1

    s.samples = {}
    s.sampleIdx = 0
    s.sampleMax = 90
    s.avgFt = FrameTime()
    s.fpsBest = 1 / math.max(FrameTime(), 0.0001)
    s.lastHitch = RealTime()
    s.stableFrames = 0
    s.stableNeed = 60
    s.entCount = -1
    s.entsStableSince = RealTime()
    s.progress = 0
    s.progressTarget = 0
    s.stageText = "Инициализация"
    s.hintText = ""

    s.OnKeyCodePressed = function(self, key)
        if self.state ~= "screen" then return end
        if key == KEY_ESCAPE then return end
        self.state = "closing"
        self.closeStart = RealTime()
        self.fade = 1
    end

    s.OnMousePressed = function(self)
        if self.state ~= "screen" then return end
        self.state = "closing"
        self.closeStart = RealTime()
        self.fade = 1
    end

    s.UpdateLoading = function(self)
        local now = RealTime()
        local ft = FrameTime()
        local elapsed = now - self.loadingStart
        local focused = system.HasFocus()

        self.sampleIdx = (self.sampleIdx % self.sampleMax) + 1
        self.samples[self.sampleIdx] = ft

        local sum, count = 0, 0
        for i = 1, self.sampleMax do
            local v = self.samples[i]
            if v then
                sum = sum + v
                count = count + 1
            end
        end

        self.avgFt = sum / math.max(count, 1)

        local fps = 1 / math.max(self.avgFt, 0.0001)
        local instFps = 1 / math.max(ft, 0.0001)

        if elapsed > 1 and focused then
            self.fpsBest = math.max(self.fpsBest, instFps)
        end

        if ft > math.max(0.15, self.avgFt * 3.5) then
            self.lastHitch = now
        end

        local target = math.Clamp(self.fpsBest * 0.7, 20, 144)
        self.stableNeed = math.Clamp(math.floor(fps * 1.5), 45, 200)

        local smooth = focused and fps >= target and (now - self.lastHitch) >= 1.2

        if smooth then
            self.stableFrames = self.stableFrames + 1
        else
            self.stableFrames = math.max(0, self.stableFrames - 3)
        end

        local entCount = ents.GetCount()
        if self.entCount < 0 or math.abs(entCount - self.entCount) > 2 then
            self.entsStableSince = now
        end
        self.entCount = entCount

        local lp = LocalPlayer()
        local playerOk = IsValid(lp) and lp:GetModel() ~= nil and not lp:GetModel():find("error")
        local worldOk = (now - self.entsStableSince) >= 1.5 and entCount > 0
        local resOk = gMusicResolved and not bgMat:IsError()
        local fpsOk = self.stableFrames >= self.stableNeed
        local minOk = elapsed >= LOAD_MIN_TIME

        local pTime = math.Clamp(elapsed / LOAD_MIN_TIME, 0, 1) * 0.15
        local pPlayer = playerOk and 0.15 or 0
        local pRes = resOk and 0.2 or math.Clamp(elapsed / RES_TIMEOUT, 0, 1) * 0.12
        local pWorld = math.Clamp((now - self.entsStableSince) / 1.5, 0, 1) * 0.2
        local pFps = math.Clamp(self.stableFrames / self.stableNeed, 0, 1) * 0.3

        self.progressTarget = math.Clamp(pTime + pPlayer + pRes + pWorld + pFps, 0, 0.99)

        if not playerOk then
            self.stageText = "Собираем тебя по запчастям"
        elseif not resOk then
            self.stageText = "Раскрашиваем город"
        elseif not worldOk then
            self.stageText = "Расставляем всё по местам"
        elseif not fpsOk then
            self.stageText = "Договариваемся с твоей видеокартой"
        elseif not minOk then
            self.stageText = "Последние штрихи"
        else
            self.stageText = "Всё готово, добро пожаловать"
        end

        if not focused then
            self.hintText = "Вернись в игру — загрузка продолжится"
        else
            self.hintText = LOADING_TIPS[math.floor(now / 5) % #LOADING_TIPS + 1]
        end

        local allOk = minOk and playerOk and resOk and worldOk and fpsOk
        local forced = elapsed >= LOAD_MAX_TIME and playerOk

        if allOk or forced then
            self.state = "ready"
            self.readyAt = now
            self.progressTarget = 1
        end
    end

    s.Think = function(self)
        local ft = math.min(FrameTime(), 0.1)

        if self.state == "loading" then
            self:UpdateLoading()
        elseif self.state == "ready" then
            self.progressTarget = 1
            self.stageText = "Всё готово, добро пожаловать"
            if RealTime() - self.readyAt >= 0.6 then
                self.state = "screen"
                self.revealStart = RealTime()
                PlayMenuMusic()
            end
        end

        if self.progressTarget > self.progress then
            self.progress = math.min(self.progressTarget, self.progress + (self.progressTarget - self.progress) * math.min(1, ft * 6) + ft * 0.02)
        end
    end

    s.PaintLoading = function(self, w, h)
        local t = RealTime()

        surface.SetDrawColor(6, 7, 10, 255)
        surface.DrawRect(0, 0, w, h)

        local glow = 18 + math.sin(t * 0.8) * 8
        draw.NoTexture()
        surface.SetDrawColor(24, 28, 40, math.floor(glow))
        surface.DrawPoly(BuildDiskPoly(w * 0.5, h * 0.45, math.max(w, h) * 0.45, 72))

        local cx, cy = w * 0.5, h * 0.45
        local radius = math.floor(math.min(w, h) * 0.085)
        local thickness = math.max(4, math.floor(radius * 0.14))

        DrawSpinner(cx, cy, radius, math.max(2, thickness * 0.6), t, Color(255, 255, 255, 235))

        draw.SimpleText(math.floor(self.progress * 100) .. "%", "SF_LOADING_Percent", cx, cy, Color(255, 255, 255, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local dots = string.rep(".", math.floor(t * 2.5) % 4)
        local slot = t / 3.6
        local frac = slot % 1
        local headline = LOADING_HEADLINES[math.floor(slot) % #LOADING_HEADLINES + 1]
        local headAlpha = 250 * math.Clamp(math.min(frac / 0.18, (1 - frac) / 0.18), 0, 1)
        draw.SimpleText(headline .. dots, "SF_LOADING_Text", cx, cy + radius + 62, Color(255, 255, 255, headAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.stageText, "SF_LOADING_Sub", cx, cy + radius + 96, Color(200, 208, 222, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local barW = math.min(w * 0.34, 620)
        local barH = 4
        local barX = cx - barW * 0.5
        local barY = cy + radius + 130

        surface.SetDrawColor(255, 255, 255, 26)
        surface.DrawRect(barX, barY, barW, barH)
        surface.SetDrawColor(255, 255, 255, 220)
        surface.DrawRect(barX, barY, barW * self.progress, barH)

        local shineW = barW * 0.18
        local shineX = barX + ((t * 0.35) % 1) * (barW - shineW)
        surface.SetDrawColor(150, 190, 255, 70)
        surface.DrawRect(shineX, barY, math.min(shineW, math.max(0, barX + barW * self.progress - shineX)), barH)

        draw.SimpleText(self.hintText, "SF_LOADING_Tiny", cx, barY + 26, Color(140, 148, 162, 210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("OT CITY", "SF_LOADING_Tiny", cx, h - 42, Color(120, 126, 140, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    s.Paint = function(self, w, h)
        if self.state == "loading" or self.state == "ready" then
            self:PaintLoading(w, h)
            return
        end

        if self.state == "screen" then
            local t = math.Clamp((RealTime() - self.revealStart) / 0.8, 0, 1)

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMat)
            surface.DrawTexturedRect(0, 0, w, h)

            local overlay = math.floor(255 * (1 - t))
            if overlay > 0 then
                surface.SetDrawColor(0, 0, 0, overlay)
                surface.DrawRect(0, 0, w, h)
            end

            local textAlpha = math.floor(180 + math.sin(RealTime() * 3) * 75)
            if t < 1 then textAlpha = math.floor(textAlpha * t) end

            draw.SimpleText("Нажмите любую клавишу что-бы продолжить", "SF_SPLASH_Text", w * 0.5, h * 0.85, Color(255, 255, 255, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        if self.state == "closing" then
            local dt = RealTime() - self.closeStart
            self.fade = math.Clamp(1 - dt / 2.2, 0, 1)

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMat)
            surface.DrawTexturedRect(0, 0, w, h)

            draw.SimpleText("Нажмите любую клавишу что-бы продолжить", "SF_SPLASH_Text", w * 0.5, h * 0.85, Color(255, 255, 255, math.floor(255 * self.fade)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(0, 0, 0, math.floor(255 * (1 - self.fade)))
            surface.DrawRect(0, 0, w, h)

            if self.fade <= 0 then
                FinishAndClose()
            end
        end
    end

    NotifyServer(READY_MSG)
end

timer.Simple(0.1, function()
    if not netstream or not netstream.Hook then return end

    netstream.Hook(OPEN_MSG, function()
        if gOpen and IsValid(gScreen) then return end
        OpenMenu()
    end)

    netstream.Hook(CLOSE_MSG, function()
        if not gOpen then return end
        FinishAndClose()
    end)
end)

hook.Add("HUDShouldDraw", "sf_mainmenu_hidehud", function(name)
    if gOpen and IsValid(gScreen) then return false end
end)

hook.Add("PlayerBindPress", "sf_mainmenu_blockbinds", function(ply, bind, pressed)
    if not gOpen or not IsValid(gScreen) then return end
    if bind == "cancelselect" then return end
    return true
end)

hook.Add("CalcView", "sf_mainmenu_lockview", function()
    if not gOpen or not IsValid(gScreen) then return end
    if gScreen.state == "loading" or gScreen.state == "ready" then
        return { drawviewer = false }
    end
end)

hook.Add("ShutDown", "sf_mainmenu_shutdown", function()
    StopMenuMusic(true)
    RemoveScreen()
    gOpen = false
    gui.EnableScreenClicker(false)
end)
