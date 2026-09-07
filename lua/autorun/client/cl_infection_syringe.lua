
local INF = {
    phase       = 0,
    music       = nil,
    phase3_snd  = nil,
    redAlpha    = 0,
}

-- ── Таймер HUD ────────────────────────────────────────────────────────────────

local INF_POPUPS = {}   -- анимированные "+15" над таймером

-- Шрифт для таймера (большой красный)
surface.CreateFont("InfectionTimerFont", {
    font      = "Roboto Mono",
    size      = 52,
    weight    = 900,
    antialias = true,
})

-- Шрифт для "+15" попапа
surface.CreateFont("InfectionPlusFont", {
    font      = "Roboto Mono",
    size      = 34,
    weight    = 900,
    antialias = true,
})

-- Получаем +N секунд от сервера → создаём попап анимацию
net.Receive("Infection_BoomKillAdd", function()
    local seconds = net.ReadFloat()
    table.insert(INF_POPUPS, {
        text  = "+" .. math.floor(seconds),
        born  = RealTime(),
        life  = 1.8,
    })
end)

-- ── Звук / фазы ───────────────────────────────────────────────────────────────

local function StopPhase3Sound()
    if IsValid(INF.phase3_snd) then
        INF.phase3_snd:Stop()
        INF.phase3_snd = nil
    end
end

net.Receive("Infection_PhaseUpdate", function()
    INF.phase = net.ReadUInt(4)

    if INF.phase == 1 then
        INF.redAlpha = 0
        StopPhase3Sound()
        if IsValid(INF.music) then INF.music:Stop(); INF.music = nil end

    elseif INF.phase == 2 then
        INF.redAlpha = 0
        StopPhase3Sound()

    elseif INF.phase == 3 then
        INF.redAlpha = 0
        StopPhase3Sound()
        sound.PlayFile("sound/infection/phase3_loop.wav", "noblock", function(ch, err)
            if not IsValid(ch) then return end
            INF.phase3_snd = ch
            ch:EnableLooping(true)
            ch:SetVolume(0.9)
            ch:Play()
        end)

    elseif INF.phase == 4 then
        INF.redAlpha = 55

    elseif INF.phase == 5 then
        INF.redAlpha = 90
        StopPhase3Sound()
    end
end)

net.Receive("Infection_Activated", function()
    INF.phase = 5

    local tracks = {
        "sound/infection/infected_music.wav",
        "sound/infection/infected_music2.wav",
        "sound/infection/infected_music3.wav",
        "sound/infection/infected_music4.wav",
    }
    local chosen = tracks[math.random(#tracks)]
    sound.PlayFile(chosen, "noblock", function(ch, err)
        if not IsValid(ch) then return end
        INF.music = ch
        ch:EnableLooping(true)
        ch:SetVolume(0.85)
        ch:Play()
    end)

    net.Start("Infection_EyeGlow")
    net.SendToServer()
end)

net.Receive("Infection_Cleared", function()
    INF.phase    = 0
    INF.redAlpha = 0
    INF_POPUPS   = {}
    StopPhase3Sound()
    if IsValid(INF.music) then
        INF.music:Stop()
        INF.music = nil
    end
end)

-- ── Взрыв головы (эффект) ─────────────────────────────────────────────────────

net.Receive("Infection_HeadExplosion", function()
    local pos = net.ReadVector()

    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetNormal(Vector(0, 0, 1))
    ed:SetMagnitude(3)
    ed:SetScale(1)
    ed:SetRadius(12)
    util.Effect("BloodImpact", ed)

    for i = 1, 4 do
        local ed2 = EffectData()
        ed2:SetOrigin(pos)
        ed2:SetNormal(VectorRand())
        ed2:SetMagnitude(2)
        ed2:SetScale(0.8)
        util.Effect("BloodImpact", ed2)
    end
end)

-- ── Think: красный экран ──────────────────────────────────────────────────────

hook.Add("Think", "Infection_ClientThink", function()
    if INF.phase == 0 then return end

    local dt = FrameTime()

    if INF.phase >= 3 then
        local target = INF.phase == 3 and 40
                    or INF.phase == 4 and 65
                    or 90
        INF.redAlpha = math.Approach(INF.redAlpha, target, dt * 50)
    else
        INF.redAlpha = math.Approach(INF.redAlpha, 0, dt * 60)
    end
end)

-- ── HUDPaint: красный экран + таймер заражения ───────────────────────────────

hook.Add("HUDPaint", "Infection_HUD", function()
    if INF.phase == 0 then return end

    -- Красный экран
    if INF.redAlpha > 1 then
        surface.SetDrawColor(180, 0, 0, INF.redAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    -- Таймер только при полном заражении (phase 5)
    if INF.phase ~= 5 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local expiry    = ply:GetNWFloat("inf_boom_expiry", 0)
    local remaining = math.max(0, expiry - CurTime())

    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    local cs   = math.floor((remaining % 1) * 100)
    local timeStr = string.format("%d:%02d.%02d", mins, secs, cs)

    local cx = ScrW() / 2
    local cy = ScrH() - 70

    -- Пульсирующий фон таймера
    local pulse     = 0.08 + math.abs(math.sin(RealTime() * 3)) * 0.07
    local bgAlpha   = 160 + math.floor(math.sin(RealTime() * 3) * 30)
    local boxW      = 220
    local boxH      = 54
    local boxX      = cx - boxW / 2
    local boxY      = cy - boxH / 2

    -- Тёмный фон с красной обводкой
    surface.SetDrawColor(10, 0, 0, bgAlpha)
    surface.DrawRect(boxX, boxY, boxW, boxH)
    surface.SetDrawColor(200, 0, 0, 220)
    surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 2)

    -- Цвет таймера: мигает быстро когда мало времени
    local r, g, b = 255, 30, 30
    if remaining < 30 then
        local blink = math.floor(RealTime() * (remaining < 10 and 4 or 2)) % 2 == 0
        r = blink and 255 or 200
        g = blink and 30  or 0
        b = blink and 30  or 0
    end

    -- Текст таймера по центру
    draw.SimpleText(
        timeStr,
        "InfectionTimerFont",
        cx, cy,
        Color(r, g, b, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
    )

    -- ── +15 попапы над таймером ────────────────────────────────────────────────
    local now = RealTime()
    for i = #INF_POPUPS, 1, -1 do
        local p   = INF_POPUPS[i]
        local age = now - p.born

        if age >= p.life then
            table.remove(INF_POPUPS, i)
        else
            local t       = age / p.life           -- 0..1
            local alpha   = math.Clamp(255 * (1 - t * t), 0, 255)
            local offsetY = t * 70                 -- плывёт вверх на 70px

            draw.SimpleText(
                p.text,
                "InfectionPlusFont",
                cx,
                boxY - 18 - offsetY,
                Color(40, 255, 60, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
            )
        end
    end
end)

-- ── Хроматическая аберрация при phase >= 4 ───────────────────────────────────

local matChrom = Material("effects/shaders/merc_chromaticaberration")

hook.Add("RenderScreenspaceEffects", "Infection_Screen", function()
    if INF.phase < 4 then return end
    local str = INF.phase == 5 and (1.0 + math.sin(RealTime() * 3) * 0.4) or 0.7
    render.UpdateScreenEffectTexture()
    matChrom:SetFloat("$c0_x", str)
    matChrom:SetInt("$c0_y", 1)
    render.SetMaterial(matChrom)
    render.DrawScreenQuad()
end)

-- ── Сброс при InitPostEntity ──────────────────────────────────────────────────

hook.Add("InitPostEntity", "Infection_Reset", function()
    INF.phase    = 0
    INF.redAlpha = 0
    INF_POPUPS   = {}
    StopPhase3Sound()
    if IsValid(INF.music) then INF.music:Stop(); INF.music = nil end
end)
