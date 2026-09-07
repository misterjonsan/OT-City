local SPRAY_THRESHOLD = 2
local BLIND_MULTIPLIER = 10
local BLIND_CAP = 60
local SPRAY_CLASS = "weapon_pepperspray_tpik"

local PS_IRRITATION_PHRASES = {
    "БЛЯЯЯЯ МОИ ГЛАЗА!!",
    "ЧТО ЗА ХУЙНЯ- МОИ ГЛАЗА!!",
    "ЖЖЁТ!! БЛЯТЬ КАК ЖЖЁТ!!",
    "Я НИХУЯ НЕ ВИЖУ!!",
    "ЛИЦО ГОРИТ!! А-А-А-А!!",
    "А-А-А- УБЕРИ ЭТО!! УБЕРИ С МОЕГО ЛИЦА!!",
    "БЛЯТЬ БЛЯТЬ БЛЯТЬ ГЛАЗА МОИ!!",
    "ОНО В ГЛАЗАХ!! ГОСПОДИ КАК ЖЖЁТ!!",
    "Я НЕ МОГУ ДЫШАТЬ- ГЛАЗА- БЛЯТЬ!!",
    "ПОМОГИТЕ КТО-НИБУДЬ Я НЕ ВИЖУ!!",
    "ГОСПОДИ ПУСТЬ ЭТО ЗАКОНЧИТСЯ!!",
    "ВОДЫ!! ДАЙТЕ ВОДЫ!! ГЛАЗА!!",
}

local PS_BLIND_PHRASES = {
    "Я не вижу... вообще ничего не вижу...",
    "Кругом темнота... глаза не открываются...",
    "Жжёт даже с закрытыми глазами...",
    "Почему я не могу открыть глаза... блять...",
    "Я ослеп? Господи, я что, ослеп??",
    "Жжение не проходит. Не вижу ни хрена.",
    "Не могу разлепить глаза даже руками...",
    "Просто темнота... и огонь на лице...",
    "Пожалуйста... воды... глаза мои...",
    "Я полностью слепой. Пиздец. Пиздец. ПИЗДЕЦ.",
}

local PS_RECOVERY_PHRASES = {
    "Кажется... я что-то вижу...",
    "Вроде полегче становится...",
    "Глаза всё ещё горят адски...",
    "Еле-еле различаю очертания...",
    "Никогда больше... блять, никогда больше...",
    "Лицо до сих пор как в огне...",
    "Зрение возвращается... медленно...",
    "Это была самая хуёвая вещь в моей жизни.",
}

hg = hg or {}
hg.PS_IRRITATION_PHRASES = PS_IRRITATION_PHRASES
hg.PS_BLIND_PHRASES = PS_BLIND_PHRASES
hg.PS_RECOVERY_PHRASES = PS_RECOVERY_PHRASES

local function StopPlayerSprays(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local weps = ply:GetWeapons()

    for i = 1, #weps do
        local wep = weps[i]

        if IsValid(wep) and wep:GetClass() == SPRAY_CLASS then
            wep.IsSpraying = false

            if isfunction(wep.StopSpray) then
                wep:StopSpray()
            else
                wep:SetNWBool("IsSpraying", false)
            end
        end
    end
end

hook.Add("Org Think", "PepperSprayRegression", function(ply, org, dt)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    org.disorientation = org.disorientation or 0

    local now = CurTime()

    if not ply:Alive() then
        if ply:GetNWFloat("PS_Exposure", 0) ~= 0 then
            ply:SetNWFloat("PS_Exposure", 0)
            ply:SetNWFloat("PS_LastHitTime", 0)
            ply:SetNWFloat("PS_BlindEndTime", 0)
            ply:SetNWFloat("PS_BlindStartTime", 0)
            ply:SetNWFloat("PS_RecoveryStart", 0)
            ply:SetNWFloat("PS_LingeringTint", 0)

            org.blindness = nil
        end

        return
    end

    local exposure = ply:GetNWFloat("PS_Exposure", 0)
    local lastHit = ply:GetNWFloat("PS_LastHitTime", 0)
    local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)

    if lastHit > 0 and now - lastHit > 0.3 then
        exposure = math.Approach(exposure, 0, dt * 0.7)

        ply:SetNWFloat("PS_Exposure", exposure)
    end

    if exposure >= SPRAY_THRESHOLD and blindEnd < now then
        blindEnd = now + math.min(exposure * BLIND_MULTIPLIER, BLIND_CAP)

        ply:SetNWFloat("PS_BlindEndTime", blindEnd)
        ply:SetNWFloat("PS_BlindStartTime", now)

        org.blindness = 0.1
    end

    if blindEnd > 0 and now >= blindEnd then
        org.blindness = nil
        blindEnd = 0

        ply:SetNWFloat("PS_BlindEndTime", 0)
        ply:SetNWFloat("PS_BlindStartTime", 0)
        ply:SetNWFloat("PS_RecoveryStart", now)
    elseif blindEnd > 0 then
        org.blindness = 0.1
    end

    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)

    if recovStart > 0 and now - recovStart >= 5 then
        recovStart = 0

        ply:SetNWFloat("PS_RecoveryStart", 0)
    end

    if org.disorientation > 0 then
        org.disorientation = math.Approach(org.disorientation, 0, dt * 0.15)

        if org.disorientation < 0.1 then
            org.disorientation = 0
        end
    end

    local tint = ply:GetNWFloat("PS_LingeringTint", 0)

    if tint > 0 then
        local tintDecay = blindEnd > 0 and 0 or (dt * 1.5)

        if tintDecay > 0 then
            tint = math.Approach(tint, 0, tintDecay)

            ply:SetNWFloat("PS_LingeringTint", tint)
        end
    end

    local isPhase2 = blindEnd > 0
    local isPhase3 = not isPhase2 and recovStart > 0
    local isPhase1 = not isPhase2 and not isPhase3 and (exposure > 0.3 or tint > 0)

    if isPhase1 or isPhase2 or isPhase3 then
        ply.PS_NextCough = ply.PS_NextCough or 0

        if now >= ply.PS_NextCough then
            ply.PS_NextCough = now + math.Rand(2.0, 4.5)

            if hg and hg.organism and hg.organism.module and hg.organism.module.random_events then
                hg.organism.module.random_events.TriggerRandomEvent(ply, "Cough")
            else
                ply:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 75, 100)
            end
        end
    end
end)

local function ResetPepperSpray(ply)
    if not IsValid(ply) then return end

    ply:SetNWFloat("PS_Exposure", 0)
    ply:SetNWFloat("PS_LastHitTime", 0)
    ply:SetNWFloat("PS_BlindEndTime", 0)
    ply:SetNWFloat("PS_BlindStartTime", 0)
    ply:SetNWFloat("PS_RecoveryStart", 0)
    ply:SetNWFloat("PS_LingeringTint", 0)

    ply.PS_NextCough = 0

    if ply.organism then
        ply.organism.blindness = nil
        ply.organism.disorientation = 0
    end

    StopPlayerSprays(ply)
end

hook.Add("PlayerDeath", "PepperSprayResetOnDeath", ResetPepperSpray)
hook.Add("DoPlayerDeath", "PepperSprayResetOnDoDeath", ResetPepperSpray)
hook.Add("PlayerSilentDeath", "PepperSprayResetOnSilentDeath", ResetPepperSpray)
hook.Add("PlayerSpawn", "PepperSprayResetOnSpawn", ResetPepperSpray)
