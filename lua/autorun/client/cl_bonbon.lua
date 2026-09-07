-- Full-screen Bonbon horror sequence.
-- Image file: garrysmod/materials/zcity/bonbon.png

local bonbonMaterial = Material("zcity/bonbon.png", "smooth noclamp")
local intruderMaterial = Material("zcity/bonbon_intruder.png", "smooth noclamp")
local effectStarted = 0
local effectEnds = 0
local effectDuration = 60
local effectMode = 0
local displayedFakeIP = ""
local fakeVIPCode = "FREE-VIP-0000-0000"
local blockingSoundStopped = false
local intruderFlashes = {}
local eyesFlashes = {}
local PREP_DURATION = 25
local FREEZE_DURATION = 0
local RUSH_DURATION = 0
local FINAL_HOLD_DURATION = 20
local BONBON_SOUND = "zcity/bonbon_milky.wav"
local BONBON_SOUND_FILE = "sound/" .. BONBON_SOUND
local BONBON_IP_SOUND_FILE = "sound/zcity/robotvoice.wav"
local allowedBonbonSound = BONBON_SOUND
local bonbonSound
local bonbonSoundPlayed = false
local bonbonSoundRequest = 0
local nextStutterFrame = 0
local stutterFrame = {
    time = 0,
    x = 0,
    y = 0,
    blackout = false,
    zoom = 1,
    glitchBurst = false
}

local messages = {
    {0.02, "do you believe in god?"},
    {0.11, "донать больше донать больше донать больше\nдонать больше донать больше"},
    {0.20, "くたばれ。くたばれ。くたばれ。\nくたばれ。くたばれ。くたばれ。"},
    {0.29, "die die die die die die die die die"},
    {0.38, "삶의 의미는 무엇인가요? 삶의 의미는 무엇인가요?\n삶의 의미는 무엇인가요? 삶의 의미는 무엇인가요?"},
    {0.48, "дрочить это грех"},
    {0.57, "i will hurt you"},
    {0.66, "dein computer ist am arsch."},
    {0.75, "тобі не соромно? тобі не соромно? тобі не соромно?\nтобі не соромно? тобі не соромно? тобі не соромно?"},
    {0.84, "we are already behind. we are already behind.\nwe are already behind. we are already behind."},
    {0.89, "Milky любит вас"},
    {0.93, "you were never alone."},
    {0.97, "lock the door."}
}

surface.CreateFont("ZCityBonbonLarge", {
    font = "Segoe UI",
    size = 76,
    weight = 1000,
    antialias = true,
    extended = true
})

surface.CreateFont("ZCityBonbonSmall", {
    font = "Segoe UI",
    size = 40,
    weight = 900,
    antialias = true,
    extended = true
})

surface.CreateFont("ZCityBonbonSwarm", {
    font = "Segoe UI",
    size = 32,
    weight = 800,
    antialias = true,
    extended = true
})

surface.CreateFont("ZCityBonbonCentral", {
    font = "Courier New",
    size = 70,
    weight = 1000,
    antialias = false,
    extended = true,
    outline = true,
    scanlines = 2
})

surface.CreateFont("ZCityBonbonImpact", {
    font = "Courier New",
    size = 108,
    weight = 1000,
    antialias = false,
    extended = true,
    outline = true,
    scanlines = 3
})

surface.CreateFont("ZCityBonbonCrushed", {
    font = "Courier New",
    size = 48,
    weight = 1000,
    antialias = false,
    extended = true,
    outline = true
})

surface.CreateFont("ZCityBonbonMicro", {
    font = "Tahoma",
    size = 10,
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZCityBonbonCode", {
    font = "Tahoma",
    size = 12,
    weight = 700,
    antialias = true,
    extended = true
})

local function isBonbonActive()
    return effectEnds > RealTime()
end

local function isBonbonBlocking()
    if not isBonbonActive() then return false end
    if effectMode == 1 then return true end
    return RealTime() - effectStarted >= PREP_DURATION
end

local function stopBonbonSound()
    bonbonSoundRequest = bonbonSoundRequest + 1
    if IsValid(bonbonSound) then
        bonbonSound:Stop()
    end
    bonbonSound = nil
    bonbonSoundPlayed = false
end

local function playBonbonSound()
    if bonbonSoundPlayed then return end
    bonbonSoundPlayed = true

    local soundFile = effectMode == 1 and BONBON_IP_SOUND_FILE or BONBON_SOUND_FILE
    if not file.Exists(soundFile, "GAME") then return end

    bonbonSoundRequest = bonbonSoundRequest + 1
    local request = bonbonSoundRequest

    sound.PlayFile(soundFile, "noplay", function(channel)
        if request ~= bonbonSoundRequest then
            if IsValid(channel) then channel:Stop() end
            return
        end
        if not IsValid(channel) or not isBonbonBlocking() then return end

        bonbonSound = channel
        channel:SetVolume(1)
        channel:SetPlaybackRate(1)
        channel:Play()
    end)
end

net.Receive("ZCityBonbonStart", function()
    local duration = math.max(net.ReadFloat(), 1)
    local mode = net.ReadUInt(2)
    local fakeIP = net.ReadString()
    local now = RealTime()

    if not isBonbonActive() then
        stopBonbonSound()
        effectStarted = now
        effectDuration = duration
        effectMode = mode
        displayedFakeIP = fakeIP
        fakeVIPCode = "FREE-VIP-" .. math.random(1000, 9999) .. "-" .. math.random(1000, 9999)
        blockingSoundStopped = false
        intruderFlashes = {}
        eyesFlashes = {}
        if mode == 0 then
            local actionStart = PREP_DURATION + FREEZE_DURATION + RUSH_DURATION
            local actionDuration = duration - actionStart - FINAL_HOLD_DURATION
            local flashCount = math.random(2, 3)
            for index = 1, flashCount do
                intruderFlashes[index] = {
                    time = actionStart + index * (actionDuration / (flashCount + 1)) + math.Rand(-0.35, 0.35),
                    duration = math.Rand(0.20, 0.35)
                }
            end

            local eyesCount = math.random(1, 2)
            for index = 1, eyesCount do
                eyesFlashes[index] = {
                    time = actionStart + index * (actionDuration / (eyesCount + 1)) + math.Rand(-0.5, 0.5),
                    duration = math.Rand(0.35, 0.7)
                }
            end
        end
    end
    effectEnds = math.max(effectEnds, now + duration)
    nextStutterFrame = 0
end)

local function materialCoverSize(material)
    local imageWidth = math.max(material:Width(), 1)
    local imageHeight = math.max(material:Height(), 1)
    local scale = math.max(ScrW() / imageWidth, ScrH() / imageHeight)
    return imageWidth * scale, imageHeight * scale
end

local function drawCenteredMaterial(material, width, alpha, xOffset, yOffset)
    local ratio = math.max(material:Height(), 1) / math.max(material:Width(), 1)
    local height = width * ratio
    surface.SetMaterial(material)
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawTexturedRect((ScrW() - width) * 0.5 + xOffset, (ScrH() - height) * 0.5 + yOffset, width, height)
end

local function drawCoverMaterial(material, xOffset, yOffset, alpha, zoom)
    local width, height = materialCoverSize(material)
    zoom = zoom or 1
    width, height = width * zoom, height * zoom
    local x = (ScrW() - width) * 0.5 + xOffset
    local y = (ScrH() - height) * 0.5 + yOffset

    surface.SetMaterial(material)
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawTexturedRect(x, y, width, height)
end

local function drawBonbonEyes(sw, sh)
    surface.SetMaterial(bonbonMaterial)
    surface.SetDrawColor(215, 215, 215, 255)
    surface.DrawTexturedRectUV(-sw * 0.08, -sh * 0.08, sw * 1.16, sh * 1.16, 0.24, 0.04, 0.69, 0.47)
end

local function currentMessage(progress)
    local selected, startAt, endAt
    for index, info in ipairs(messages) do
        if progress >= info[1] then
            startAt, selected = info[1], info[2]
            endAt = messages[index + 1] and messages[index + 1][1] or 1
        end
    end
    return selected, startAt, endAt
end

hook.Add("PostRenderVGUI", "ZCityBonbonScreen", function()
    if not isBonbonActive() then return end

    local now = RealTime()
    if now >= nextStutterFrame then
        stutterFrame.time = now
        stutterFrame.x = math.random(-12, 12)
        stutterFrame.y = math.random(-8, 8)
        stutterFrame.blackout = math.random(1, 11) == 1
        stutterFrame.zoom = math.random(1, 7) == 1 and math.Rand(1.12, 1.42) or 1
        stutterFrame.glitchBurst = math.random(1, 4) == 1
        nextStutterFrame = now + math.Rand(0.045, 0.16)
    end

    local visualTime = stutterFrame.time
    local elapsed = visualTime - effectStarted
    local introDuration = effectMode == 1 and 0 or PREP_DURATION
    local freezeDuration = effectMode == 1 and 0 or FREEZE_DURATION
    local rushDuration = effectMode == 1 and 0 or RUSH_DURATION
    local actionStart = introDuration + freezeDuration + rushDuration
    local holdStart = effectMode == 0 and effectDuration - FINAL_HOLD_DURATION or math.huge
    local actionDuration = math.max(holdStart - actionStart, 0.1)
    local progress = math.Clamp((elapsed - actionStart) / actionDuration, 0, 1)
    local sw, sh = ScrW(), ScrH()
    local pulse = math.abs(math.sin(visualTime * 13))
    local violent = progress > 0.72 and 1 or progress / 0.72
    local jitterX = stutterFrame.x * violent
    local jitterY = stutterFrame.y * violent
    local activeMaterial = bonbonMaterial
    local eyesOnly = false
    if effectMode == 0 then
        for _, flash in ipairs(intruderFlashes) do
            if elapsed >= flash.time and elapsed <= flash.time + flash.duration then
                activeMaterial = intruderMaterial
                break
            end
        end
        for _, flash in ipairs(eyesFlashes) do
            if elapsed >= flash.time and elapsed <= flash.time + flash.duration then
                eyesOnly = true
                break
            end
        end
    end

    if elapsed >= introDuration then
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, sw, sh)
    end

    if effectMode == 0 and elapsed >= holdStart then
        drawCoverMaterial(bonbonMaterial, 0, 0, 255, 1)
        draw.SimpleText("Milki обожает вас", "ZCityBonbonCentral", sw * 0.5 + 3, sh * 0.78 + 3, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Milki обожает вас", "ZCityBonbonCentral", sw * 0.5, sh * 0.78, Color(240, 240, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    if eyesOnly then
        drawBonbonEyes(sw, sh)
        return
    end

    if elapsed < introDuration then
        local microAlpha = 55 + math.abs(math.sin(visualTime * 0.8)) * 35
        local microX = sw * 0.5 + math.sin(visualTime * 0.18) * 3
        draw.SimpleText("бесплатный vip", "ZCityBonbonMicro", microX, sh * 0.5 - 11, Color(215, 215, 215, microAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("напишите код в чат", "ZCityBonbonMicro", microX, sh * 0.5 + 3, Color(200, 200, 200, microAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(fakeVIPCode, "ZCityBonbonCode", microX, sh * 0.5 + 18, Color(230, 230, 230, microAlpha + 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif elapsed < introDuration + freezeDuration then
        draw.SimpleText("бесплатный vip", "ZCityBonbonMicro", sw * 0.5, sh * 0.5 - 11, Color(225, 225, 225, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("напишите код в чат", "ZCityBonbonMicro", sw * 0.5, sh * 0.5 + 3, Color(215, 215, 215, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(fakeVIPCode, "ZCityBonbonCode", sw * 0.5, sh * 0.5 + 18, Color(240, 240, 240, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif elapsed < actionStart then
        local rush = math.Clamp((elapsed - introDuration - freezeDuration) / rushDuration, 0, 1) ^ 3
        local coverWidth = materialCoverSize(activeMaterial)
        drawCenteredMaterial(activeMaterial, Lerp(rush, sw * 0.16, coverWidth), 255, jitterX, jitterY)
    else
        drawCoverMaterial(activeMaterial, jitterX, jitterY, 255, stutterFrame.zoom)
    end

    -- Short displaced layers create a tearing/glitch impression.
    if elapsed >= actionStart and elapsed < holdStart and math.random(1, 5) == 1 then
        render.SetScissorRect(0, math.random(0, sh), sw, math.random(0, sh), true)
        drawCoverMaterial(activeMaterial, math.random(-18, 18), 0, 110)
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    if elapsed >= actionStart and elapsed < holdStart and stutterFrame.glitchBurst then
        local glitchSeed = math.floor(stutterFrame.time * 30)
        for index = 1, 11 do
            local blockX = (index * 347 + glitchSeed * 83) % sw
            local blockY = (index * 191 + glitchSeed * 127) % sh
            local blockWidth = 45 + (index * 97 + glitchSeed * 13) % math.max(math.floor(sw * 0.32), 46)
            local blockHeight = 4 + (index * 17 + glitchSeed) % 42
            local endX = math.min(blockX + blockWidth, sw)
            local endY = math.min(blockY + blockHeight, sh)

            render.SetScissorRect(blockX, blockY, endX, endY, true)
            drawCoverMaterial(activeMaterial, math.random(-75, 75), math.random(-18, 18), math.random(145, 235), stutterFrame.zoom)
        end
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    if elapsed >= actionStart and elapsed < holdStart then
        for y = math.floor((now * 105) % 7), sh, 7 do
            surface.SetDrawColor(0, 0, 0, 38)
            surface.DrawRect(0, y, sw, 1)
        end
    end

    if elapsed >= actionStart and elapsed < holdStart and stutterFrame.blackout then
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, sw, sh)
        return
    end

    if effectMode == 1 then
        local fakeText = "YOUR IP: " .. displayedFakeIP
        local jump = math.floor(stutterFrame.time * 8)
        for index = 1, 18 do
            local copyX = ((index * 431 + jump * 223) % 1000) / 1000 * sw
            local copyY = ((index * 277 + jump * 389) % 1000) / 1000 * sh
            draw.SimpleText(fakeText, "ZCityBonbonSmall", copyX, copyY, Color(220, 220, 220, 80), TEXT_ALIGN_CENTER)
        end
        draw.SimpleText(fakeText, "ZCityBonbonCentral", sw * 0.5 + stutterFrame.x, sh * 0.5, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(fakeText, "ZCityBonbonCentral", sw * 0.5, sh * 0.5 - 3, Color(245, 245, 245, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local message, messageStart, messageEnd = currentMessage(progress)
    if message then
        local messageProgress = math.Clamp((progress - messageStart) / math.max(messageEnd - messageStart, 0.001), 0, 1)
        local characterCount = utf8.len(message)
        local visible = math.Clamp(math.floor(messageProgress * characterCount * 4), 0, characterCount)
        local text = utf8.sub(message, 1, visible)
        local textSeed = math.floor(stutterFrame.time * 13)
        local font = textSeed % 5 == 0 and "ZCityBonbonImpact" or (textSeed % 3 == 0 and "ZCityBonbonCrushed" or "ZCityBonbonCentral")
        local readable = messageProgress >= 0.25 and messageProgress <= 0.78
        local hardJump = textSeed % 4 ~= 0
        local x = hardJump and sw * (0.18 + ((textSeed * 37) % 65) / 100) or sw * 0.5
        local y = hardJump and sh * (0.16 + ((textSeed * 53) % 66) / 100) or sh * 0.72
        x = x + stutterFrame.x * 2
        y = y + stutterFrame.y * 2
        local red = readable and 245 or 255
        local green = readable and 245 or 190 + pulse * 45

        if textSeed % 7 == 0 and utf8.len(text) > 4 then
            text = utf8.sub(text, 1, math.max(1, math.floor(utf8.len(text) * 0.58))) .. " //////////"
        elseif textSeed % 6 == 0 then
            text = "[[ " .. text .. " ]]"
        end

        if messageProgress >= 0.18 then
            local jumpSeed = math.floor(stutterFrame.time * 7)
            for index = 1, 20 do
                local copyX = ((index * 379 + jumpSeed * 181) % 1000) / 1000 * sw
                local copyY = ((index * 613 + jumpSeed * 307) % 1000) / 1000 * sh
                local copyAlpha = 45 + ((index * 29 + jumpSeed * 11) % 130)
                draw.DrawText(text, "ZCityBonbonSwarm", copyX, copyY, Color(225, 225, 225, copyAlpha), TEXT_ALIGN_CENTER)
            end
        end

        draw.DrawText(text, font, x + 3, y + 3, Color(0, 0, 0, 245), TEXT_ALIGN_CENTER)
        draw.DrawText(text, font, x - 2, y + 1, Color(80, 80, 80, readable and 125 or 190), TEXT_ALIGN_CENTER)
        draw.DrawText(text, font, x, y, Color(red, green, readable and 245 or 205, 255), TEXT_ALIGN_CENTER)

        if textSeed % 3 == 0 then
            for index = 1, 5 do
                local sliceY = (textSeed * 41 + index * 73) % sh
                local sliceHeight = 3 + (textSeed + index * 11) % 19
                render.SetScissorRect(0, sliceY, sw, math.min(sliceY + sliceHeight, sh), true)
                draw.DrawText(text, font, x + math.random(-55, 55), y + math.random(-8, 8), Color(245, 245, 245, 230), TEXT_ALIGN_CENTER)
            end
            render.SetScissorRect(0, 0, 0, 0, false)
        end
    end

    if progress > 0.96 then
        surface.SetDrawColor(255, 255, 255, math.random(80, 230))
        surface.DrawRect(0, 0, sw, sh)
    end
end)

hook.Add("EntityEmitSound", "ZCityBonbonMuteGame", function(soundData)
    if not isBonbonBlocking() then return end
    if allowedBonbonSound and soundData.SoundName == allowedBonbonSound then return end
    return false
end)

hook.Add("HUDShouldDraw", "ZCityBonbonHideHUD", function()
    if isBonbonBlocking() then return false end
end)

hook.Add("SpawnMenuOpen", "ZCityBonbonLockSpawnMenu", function()
    if isBonbonBlocking() then return false end
end)

hook.Add("ContextMenuOpen", "ZCityBonbonLockContextMenu", function()
    if isBonbonBlocking() then return false end
end)

hook.Add("ScoreboardShow", "ZCityBonbonLockScoreboard", function()
    if isBonbonBlocking() then return false end
end)

hook.Add("Think", "ZCityBonbonKeepScreen", function()
    if isBonbonBlocking() then
        if not blockingSoundStopped then
            RunConsoleCommand("stopsound")
            blockingSoundStopped = true
        end
        playBonbonSound()
        if gui.IsGameUIVisible() then gui.HideGameUI() end
    elseif bonbonSoundPlayed then
        stopBonbonSound()
    end
end)
