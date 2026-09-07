local net = net
local timer = timer
local math = math
local EmitSound = EmitSound
local ParticleEffect = ParticleEffect
local EyePos = EyePos
local CurTime = CurTime
local math_random = math.random

local vector_up = vector_up or Vector(0, 0, 1)
local angle_effect = vector_up:Angle()

local NEAR_SOUNDS = {
    "ied/ied_detonate_01.wav",
    "ied/ied_detonate_02.wav",
    "ied/ied_detonate_03.wav"
}

local FAR_SOUNDS = {
    "ied/ied_detonate_dist_01.wav",
    "ied/ied_detonate_dist_02.wav",
    "ied/ied_detonate_dist_03.wav"
}

local NEAR_COUNT = #NEAR_SOUNDS
local FAR_COUNT = #FAR_SOUNDS

local EFFECTS = {
    [1] = "pcf_jack_incendiary_ground_sm2",
    [2] = "pcf_jack_groundsplode_medium",
    [3] = "pcf_jack_groundsplode_small"
}

local SPEED_OF_SOUND = 17836
local EFFECT_MAX_DIST_SQR = 4500 * 4500
local SOUND_MAX_DIST_SQR = 12000 * 12000
local EFFECT_WINDOW = 0.2
local MAX_EFFECTS_PER_WINDOW = 6
local SOUND_WINDOW = 0.15
local MAX_SOUNDS_PER_WINDOW = 8

local effectCount = 0
local effectWindowEnd = 0
local soundCount = 0
local soundWindowEnd = 0

local function PlaySndDist(near, far, pos, dist)
    local delay = dist / SPEED_OF_SOUND

    timer.Simple(delay, function()
        EmitSound(far, pos, 0, CHAN_WEAPON, 1, 110, 0, 100, 0, nil)
        EmitSound(near, pos, 0, CHAN_AUTO, 1, delay > 0.6 and 140 or 110, 0, 100, 0, nil)
    end)
end

net.Receive("hg_booom", function()
    local pos = net.ReadVector()
    local id = net.ReadUInt(3)
    local effect = EFFECTS[id]

    if not effect then return end

    local eyes = EyePos()
    local distSqr = pos:DistToSqr(eyes)
    local now = CurTime()

    if distSqr <= EFFECT_MAX_DIST_SQR then
        if now > effectWindowEnd then
            effectCount = 0
            effectWindowEnd = now + EFFECT_WINDOW
        end

        if effectCount < MAX_EFFECTS_PER_WINDOW then
            effectCount = effectCount + 1

            ParticleEffect(effect, pos, angle_effect)
        end
    end

    if distSqr > SOUND_MAX_DIST_SQR then return end

    if now > soundWindowEnd then
        soundCount = 0
        soundWindowEnd = now + SOUND_WINDOW
    end

    if soundCount >= MAX_SOUNDS_PER_WINDOW then return end

    soundCount = soundCount + 1

    PlaySndDist(NEAR_SOUNDS[math_random(NEAR_COUNT)], FAR_SOUNDS[math_random(FAR_COUNT)], pos, math.sqrt(distSqr))
end)
