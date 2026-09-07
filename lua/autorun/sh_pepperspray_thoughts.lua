local pepperspray_irritation = {
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
    "ГЛАЗА ПЛАВЯТСЯ!! ОХУЕТЬ!!",
    "Я СДОХНУ БЛЯТЬ- Я НЕ ВИЖУ НИЧЕГО!!",
    "ВОДЫ!! ДАЙТЕ ВОДЫ!! ГЛАЗА!!",
}

local pepperspray_blind = {
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

local pepperspray_recovery = {
    "Кажется... я что-то вижу...",
    "Вроде полегче становится...",
    "Глаза всё ещё горят адски...",
    "Еле-еле различаю очертания...",
    "Никогда больше... блять, никогда больше...",
    "Лицо до сих пор как в огне...",
    "Зрение возвращается... медленно...",
    "Это была самая хуёвая вещь в моей жизни.",
}

local nextThoughtTime = {}
local THOUGHT_COOLDOWN = 10

hook.Add("InitPostEntity", "PepperSpray_ThoughtMessages", function()
    if not hg or not hg.get_status_message then return end

    local originalFunc = hg.get_status_message

    hg.get_status_message = function(ply)
        if not IsValid(ply) then return originalFunc(ply) end
        if not ply:IsPlayer() or not ply:Alive() then return originalFunc(ply) end

        local exposure = ply:GetNWFloat("PS_Exposure", 0)
        local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
        local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
        local tint = ply:GetNWFloat("PS_LingeringTint", 0)
        local now = CurTime()

        local isPhase2 = blindEnd > 0 and now < blindEnd
        local isPhase3 = not isPhase2 and recovStart > 0 and now - recovStart < 5
        local isPhase1 = not isPhase2 and not isPhase3 and (exposure > 0.3 or tint > 0)

        if isPhase1 or isPhase2 or isPhase3 then
            local id = ply:SteamID()

            if (nextThoughtTime[id] or 0) > now then
                return ""
            end

            nextThoughtTime[id] = now + THOUGHT_COOLDOWN

            if isPhase2 then
                return pepperspray_blind[math.random(#pepperspray_blind)]
            elseif isPhase3 then
                return pepperspray_recovery[math.random(#pepperspray_recovery)]
            end

            return pepperspray_irritation[math.random(#pepperspray_irritation)]
        end

        return originalFunc(ply)
    end

    local originalLikely = hg.likely_to_phrase

    if originalLikely then
        hg.likely_to_phrase = function(ply)
            if not IsValid(ply) then return originalLikely(ply) end
            if not ply:IsPlayer() or not ply:Alive() then return originalLikely(ply) end

            local exposure = ply:GetNWFloat("PS_Exposure", 0)
            local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
            local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
            local tint = ply:GetNWFloat("PS_LingeringTint", 0)
            local now = CurTime()

            if exposure > 0.3 or tint > 0 or (blindEnd > 0 and now < blindEnd) then
                return 100
            end

            if recovStart > 0 and now - recovStart < 5 then
                return 1.5
            end

            return originalLikely(ply)
        end
    end
end)

if SERVER then
    concommand.Add("hg_think", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        local id = ply:SteamID()
        local savedCD = nextThoughtTime[id]

        nextThoughtTime[id] = 0

        local str = hg.get_status_message(ply)

        if not str or str == "" then
            nextThoughtTime[id] = savedCD

            return
        end

        ply:Notify(str, 1, "phrase", 1, nil, Color(255, 255, 255))
    end)

    gameevent.Listen("player_disconnect")

    hook.Add("player_disconnect", "PepperSpray_ClearThoughtCD", function(data)
        if data and data.networkid then
            nextThoughtTime[data.networkid] = nil
        end
    end)
end
