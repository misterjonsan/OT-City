MODE = MODE or {}
local MODE = MODE

local HM = nil

local function looksLikeHomicide(t)
    if not istable(t) then return false end
    if t.name ~= "hmcd" and t.PrintName ~= "Homicide" then return false end
    return istable(t.Types) or istable(t.Professions) or istable(t.RoleChooseRoundTypes)
end

local function hmcd()
    if looksLikeHomicide(HM) then return HM end

    if istable(zb) and istable(zb.modes) then
        if looksLikeHomicide(zb.modes.hmcd) then HM = zb.modes.hmcd return HM end
        for _, v in pairs(zb.modes) do
            if looksLikeHomicide(v) then HM = v return HM end
        end
    end

    if looksLikeHomicide(MODE) then HM = MODE return HM end
    if looksLikeHomicide(_G.MODE) then HM = _G.MODE return HM end
    return nil
end
MODE.GetHomicideMode = hmcd

local function hmField(name)
    local m = hmcd()
    local v = m and m[name]
    if v ~= nil then return v end
    return MODE[name]
end

local function syncModeTable()
    hmcd()
end

local XP_MAX = 1000000000
local SELECT_COOLDOWN = 0.5
local MAX_KEY_LEN = 32
local MIN_ROUND_SECONDS = 45
local KILL_XP_COOLDOWN = 60
local ROUND_XP_CAP = 30
local DEFAULT_UNLOCK = {doctor = 0, huntsman = 800, engineer = 2200, cook = 4500, builder = 8000, exorcist = 8000}
local DEFAULT_TITLES = {doctor = "Доктор", huntsman = "Охотник", engineer = "Инженер", cook = "Повар", builder = "Строитель", exorcist = "Экзорцист"}
local DEFAULT_SHORT = {
    doctor = "Осмотр состояния тела",
    huntsman = "Видит следы игроков",
    engineer = "Крафт взрывчатки",
    cook = "Восстанавливает насыщение союзникам",
    builder = "Заколачивает двери",
    exorcist = "Видит грешников и владеет Крестом",
}
local DEFAULT_COLORS = {
    doctor = Color(70, 200, 120),
    huntsman = Color(210, 170, 70),
    engineer = Color(90, 160, 230),
    cook = Color(230, 120, 90),
    builder = Color(180, 150, 110),
    exorcist = Color(200, 55, 65),
}
local DEFAULT_XP = {Kill = 4, Round = 6, Survive = 4}
local DEFAULT_ROUND_TYPES = {standard = true, soe = true}
local ACCENT = Color(120, 230, 150)
local AUTO_TITLE = "Авто (случайная)"

local function professionMeta(key)
    if key == nil or key == "" then return nil end
    local m = hmField("ProfessionMeta")
    if not istable(m) then return nil end
    return m[key]
end

local function professionTitle(key)
    if key == nil or key == "" then return AUTO_TITLE end
    local meta = professionMeta(key)
    if meta and isstring(meta.Title) and meta.Title ~= "" then return meta.Title end
    return DEFAULT_TITLES[key] or key
end
MODE.ProfessionTitle = professionTitle

local function professionShort(key)
    local meta = professionMeta(key)
    if meta and isstring(meta.Short) and meta.Short ~= "" then return meta.Short end
    return DEFAULT_SHORT[key]
end

local function professionColor(key)
    local meta = professionMeta(key)
    if meta and IsColor(meta.Color) then return meta.Color end
    return DEFAULT_COLORS[key] or ACCENT
end

local function profXPValue(field)
    local t = hmField("ProfXP")
    local v = istable(t) and tonumber(t[field]) or nil
    return v or DEFAULT_XP[field] or 0
end

local function notifyPlayer(ply, msg, col, tag, dur)
    if not IsValid(ply) then return end
    if isfunction(ply.Notify) then
        ply:Notify(msg, dur or 5, tag or "prof", 1, nil, col or ACCENT)
    else
        ply:ChatPrint(msg)
    end
end

local function isHomicideMode()
    if not istable(zb) or not istable(zb.modes) then return true end
    if not isfunction(CurrentRound) then return true end
    local cur = CurrentRound()
    if not istable(cur) then return true end
    if cur == hmcd() then return true end
    return cur.name == "hmcd"
end
MODE.IsHomicideMode = isHomicideMode

local function currentRoundType()
    local m = hmcd()
    local t = m and m.Type
    if t == nil or t == "" then
        local c = istable(zb) and zb.CROUND
        if isstring(c) and c ~= "" and c ~= "hmcd" then t = c end
    end
    if t == nil or t == "" then t = MODE.Type end
    if t == nil or t == "" then return nil end
    return t
end
MODE.CurrentRoundType = currentRoundType

local function roundAllowsProfessions()
    local t = currentRoundType()
    if t == nil then return false end
    local allowed = hmField("ProfessionsRoundTypes")
    if not istable(allowed) then allowed = DEFAULT_ROUND_TYPES end
    return allowed[t] == true
end
MODE.RoundAllowsProfessions = roundAllowsProfessions

local function isMDataLoaded(ply)
    return mdata and isfunction(mdata.IsLoaded) and mdata:IsLoaded(ply)
end

local function getProfXP(ply)
    if not IsValid(ply) then return 0 end
    local v = nil
    if isMDataLoaded(ply) and ply.GetMData then v = ply:GetMData(MODE.ProfXPKey, 0) end
    if (v == nil or v == "") and ply.GetPData then v = ply:GetPData(MODE.ProfXPKey, 0) end
    return math.floor(tonumber(v) or 0)
end

local function getProfChoice(ply)
    if not IsValid(ply) then return "" end
    local choice = nil
    if isMDataLoaded(ply) and ply.GetMData then choice = ply:GetMData(MODE.ProfChoiceKey, "") end
    if (choice == nil or choice == "") and ply.GetPData then choice = ply:GetPData(MODE.ProfChoiceKey, "") end
    return isstring(choice) and choice or ""
end

local function sendProfData(ply)
    if not IsValid(ply) then return end
    local xp = getProfXP(ply)
    local choice = getProfChoice(ply)
    ply:SetNWInt("HMCD_ProfXP", xp)
    ply:SetNWString("HMCD_ProfChoice", choice)
    net.Start("HMCD_ProfSync")
        net.WriteUInt(math.Clamp(xp, 0, XP_MAX), 30)
        net.WriteString(choice)
    net.Send(ply)
end

local function setProfXP(ply, amount)
    if not IsValid(ply) then return 0 end
    amount = math.Clamp(math.floor(tonumber(amount) or 0), 0, XP_MAX)
    if ply.SetPData then ply:SetPData(MODE.ProfXPKey, tostring(amount)) end
    if isMDataLoaded(ply) and ply.SetMData then
        ply:SetMData(MODE.ProfXPKey, amount)
    else
        ply.HMCDPendingProfXP = amount
    end
    ply:SetNWInt("HMCD_ProfXP", amount)
    timer.Simple(0, function() if IsValid(ply) then sendProfData(ply) end end)
    return amount
end

local function addProfXP(ply, amount)
    if not IsValid(ply) then return 0 end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return getProfXP(ply) end
    return setProfXP(ply, getProfXP(ply) + amount)
end

local function setProfChoice(ply, key)
    if not IsValid(ply) then return false end
    if not isstring(key) then key = "" end
    if ply.SetPData then ply:SetPData(MODE.ProfChoiceKey, key) end
    if isMDataLoaded(ply) and ply.SetMData then
        ply:SetMData(MODE.ProfChoiceKey, key)
    else
        ply.HMCDPendingProfChoice = key
    end
    ply:SetNWString("HMCD_ProfChoice", key)
    timer.Simple(0, function() if IsValid(ply) then sendProfData(ply) end end)
    return true
end

local function professionExists(key)
    if key == nil or key == "" then return false end
    local profs = hmField("Professions")
    if istable(profs) then return profs[key] ~= nil end
    return DEFAULT_UNLOCK[key] ~= nil
end

local function unlockCost(key)
    local meta = professionMeta(key)
    if meta and tonumber(meta.Unlock) then return tonumber(meta.Unlock) end
    return DEFAULT_UNLOCK[key] or 0
end

local function isUnlocked(xp, key)
    return (tonumber(xp) or 0) >= unlockCost(key)
end

local VIP_PROFESSIONS = {exorcist = true}

local function isVIPOnly(key)
    local meta = professionMeta(key)
    if meta and meta.VIP then return true end
    local shared = hmField("VIPProfessions")
    if istable(shared) and shared[key] then return true end
    return VIP_PROFESSIONS[key] == true
end
MODE.IsProfessionVIPOnly = isVIPOnly

local function isVIP(ply)
    if not IsValid(ply) or not isfunction(ply.GetUserGroup) then return false end
    local group = string.lower(string.Trim(tostring(ply:GetUserGroup() or "user")))
    return group ~= "" and group ~= "user"
end
MODE.IsVIPPlayer = isVIP

local function canTake(ply, key)
    if key == nil or key == "" then return true end
    if not professionExists(key) then return false end
    if not isUnlocked(getProfXP(ply), key) then return false end
    if isVIPOnly(key) and not isVIP(ply) then return false end
    return true
end
MODE.CanTakeProfession = canTake

local function getChosenProfession(ply)
    if not IsValid(ply) then return nil end
    local key = getProfChoice(ply)
    if not key or key == "" then return nil end
    if not canTake(ply, key) then return nil end
    return key
end

local function selectUnlockedProfession(list, ply)
    if not istable(list) or #list == 0 then return nil, nil end
    local xp = getProfXP(ply)
    local total = 0
    local pool = {}
    for index, entry in ipairs(list) do
        local weight = tonumber(entry[1]) or 0
        local prof = entry[2]
        if weight > 0 and prof and professionExists(prof) and isUnlocked(xp, prof) and canTake(ply, prof) then
            total = total + weight
            pool[#pool + 1] = {index = index, prof = prof, upto = total}
        end
    end
    if total <= 0 or #pool == 0 then return nil, nil end
    local roll = math.Rand(0, total)
    for _, entry in ipairs(pool) do
        if roll <= entry.upto then return entry.index, entry.prof end
    end
    local last = pool[#pool]
    return last.index, last.prof
end

local function Install()
    MODE = MODE or {}
    MODE.ProfXPKey = MODE.ProfXPKey or "hmcd_prof_xp"
    MODE.ProfChoiceKey = MODE.ProfChoiceKey or "hmcd_prof_choice"
    MODE.ProfXP = {Kill = 4, Round = 6, Survive = 4}
    MODE.ProfessionOrder = {"doctor", "huntsman", "engineer", "cook", "builder", "exorcist"}
    MODE.DefaultProfessions = {["doctor"] = {Chance = 1}, ["huntsman"] = {Chance = 1}, ["engineer"] = {Chance = 1}, ["cook"] = {Chance = 1}, ["builder"] = {Chance = 1}, ["exorcist"] = {Chance = 0.5}}
    MODE.ProfessionUnlockCost = unlockCost
    MODE.ProfessionExists = professionExists
    MODE.IsProfessionUnlocked = isUnlocked
    MODE.GetProfXP = getProfXP
    MODE.SetProfXP = setProfXP
    MODE.AddProfXP = addProfXP
    MODE.GetProfChoice = getProfChoice
    MODE.SetProfChoice = setProfChoice
    MODE.GetChosenProfession = getChosenProfession
    MODE.SelectUnlockedProfession = selectUnlockedProfession
    MODE.CanTakeProfession = canTake
    MODE.IsProfessionVIPOnly = isVIPOnly
    MODE.IsVIPPlayer = isVIP
    MODE.VIPProfessions = {exorcist = true}
end

Install()
timer.Simple(0, Install)
hook.Add("InitPostEntity", "HMCD_Professions_Install", Install)

util.AddNetworkString("HMCD_ProfSelect")
util.AddNetworkString("HMCD_ProfSync")

local function markRoundActive()
    if not isHomicideMode() then return end
    MODE.HMCDProfRoundActive = true
    MODE.HMCDProfRoundEnded = false
    MODE.HMCDProfRoundStarted = CurTime()
    for _, ply in player.Iterator() do
        if IsValid(ply) then
            ply.ProfRoundXP = 0
            ply.HMCDProfKillXP = nil
        end
    end
end

hook.Add("PlayerInitialSpawn", "HMCD_Professions_Sync", function(ply)
    ply.HMCDProfMDataSynced = false
    timer.Simple(2, function() if IsValid(ply) then sendProfData(ply) end end)
end)

hook.Add("Think", "HMCD_Professions_MDataSync", function()
    if (MODE.HMCDNextMDataSync or 0) > CurTime() then return end
    MODE.HMCDNextMDataSync = CurTime() + 0.5
    for _, ply in player.Iterator() do
        if IsValid(ply) and not ply.HMCDProfMDataSynced and isMDataLoaded(ply) then
            if ply.HMCDPendingProfXP ~= nil and ply.SetMData then
                ply:SetMData(MODE.ProfXPKey, ply.HMCDPendingProfXP)
                ply.HMCDPendingProfXP = nil
            end
            if ply.HMCDPendingProfChoice ~= nil and ply.SetMData then
                ply:SetMData(MODE.ProfChoiceKey, ply.HMCDPendingProfChoice)
                ply.HMCDPendingProfChoice = nil
            end
            ply.HMCDProfMDataSynced = true
            sendProfData(ply)
        end
    end
end)

concommand.Add("hmcd_prof_sync", function(ply)
    if IsValid(ply) then sendProfData(ply) end
end)

concommand.Add("hmcd_prof_setchoice", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local key = tostring(args[1] or "")
    if key ~= "" and not canTake(ply, key) then return end
    setProfChoice(ply, key)
    notifyPlayer(ply, "Выбрана профессия: " .. professionTitle(key), professionColor(key), "prof_choice", 4)
end)

net.Receive("HMCD_ProfSelect", function(len, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if ply.HMCDNextProfNet and now < ply.HMCDNextProfNet then return end
    ply.HMCDNextProfNet = now + SELECT_COOLDOWN
    local key = net.ReadString()
    if not isstring(key) or #key > MAX_KEY_LEN then return end
    if key == "" then
        setProfChoice(ply, "")
        notifyPlayer(ply, "Выбрана профессия: " .. AUTO_TITLE, ACCENT, "prof_choice", 4)
        return
    end
    if not canTake(ply, key) then
        if isVIPOnly(key) and not isVIP(ply) then
            notifyPlayer(ply, "Эта профессия доступна только VIP-игрокам.", Color(200, 55, 65), "prof_vip", 5)
        end
        return
    end
    setProfChoice(ply, key)
    notifyPlayer(ply, "Выбрана профессия: " .. professionTitle(key), professionColor(key), "prof_choice", 4)
end)

local function roundStartTime()
    if MODE.HMCDProfRoundStarted and MODE.HMCDProfRoundStarted > 0 then return MODE.HMCDProfRoundStarted end
    if MODE.StartRoundTime and MODE.StartRoundTime > 0 then return MODE.StartRoundTime end
    if zb and zb.ROUND_BEGIN then return zb.ROUND_BEGIN end
    if zb and zb.ROUND_START then return zb.ROUND_START end
    return 0
end

local function roundLongEnough()
    local started = roundStartTime()
    if started <= 0 then return true end
    return (CurTime() - started) >= MIN_ROUND_SECONDS
end

local function awardXP(ply, amount, cap)
    if not isHomicideMode() or not roundAllowsProfessions() then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply:Team() == TEAM_SPECTATOR then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if cap then
        local earned = ply.ProfRoundXP or 0
        if earned >= ROUND_XP_CAP then return end
        amount = math.min(amount, ROUND_XP_CAP - earned)
    end
    addProfXP(ply, amount)
    ply.ProfRoundXP = (ply.ProfRoundXP or 0) + amount
end

local function awardKillXP(victim, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end
    if attacker:Team() == TEAM_SPECTATOR then return end
    attacker.HMCDProfKillXP = attacker.HMCDProfKillXP or {}
    local sid = victim:SteamID64() or victim:SteamID() or tostring(victim)
    local now = CurTime()
    if attacker.HMCDProfKillXP[sid] and attacker.HMCDProfKillXP[sid] > now then return end
    attacker.HMCDProfKillXP[sid] = now + KILL_XP_COOLDOWN
    awardXP(attacker, profXPValue("Kill"), true)
end

hook.Add("PlayerDeath", "HMCD_Professions_XP", function(victim, inflictor, attacker) awardKillXP(victim, attacker) end)
hook.Add("Player_Death", "HMCD_Professions_XP", function(victim, inflictor, attacker) awardKillXP(victim, attacker) end)

local function finishRoundXP()
    if not isHomicideMode() or MODE.HMCDProfRoundEnded then return end
    MODE.HMCDProfRoundActive = true
    MODE.HMCDProfRoundEnded = true

    if not roundAllowsProfessions() then
        for _, ply in player.Iterator() do
            if IsValid(ply) then
                ply.ProfRoundXP = 0
                ply.HMCDProfKillXP = nil
            end
        end
        MODE.HMCDProfRoundActive = false
        return
    end

    local longEnough = roundLongEnough()
    local roundXP = profXPValue("Round")
    local surviveXP = profXPValue("Survive")
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:IsPlayer() and ply:Team() ~= TEAM_SPECTATOR then
            if longEnough then
                awardXP(ply, roundXP, true)
                if ply:Alive() and (not ply.organism or not ply.organism.incapacitated) then
                    awardXP(ply, surviveXP, true)
                end
            end
            local earned = ply.ProfRoundXP or 0
            if earned > 0 then
                notifyPlayer(ply, "Конец раунда: +" .. earned .. " опыта профессии", ACCENT, "prof_xp", 6)
                sendProfData(ply)
            end
            ply.ProfRoundXP = 0
            ply.HMCDProfKillXP = nil
        end
    end
    MODE.HMCDProfRoundActive = false
end

MODE.FinishProfRoundXP = finishRoundXP

hook.Add("ZB_RoundStart", "HMCD_Professions_XP_Reset", markRoundActive)
hook.Add("RoundStart", "HMCD_Professions_XP_Reset", markRoundActive)
hook.Add("OnRoundStart", "HMCD_Professions_XP_Reset", markRoundActive)
hook.Add("ZB_EndRound", "HMCD_Professions_XP", finishRoundXP)
hook.Add("HMCD_ProfessionsRoundEnd", "HMCD_Professions_XP", finishRoundXP)
hook.Add("RoundEnd", "HMCD_Professions_XP", finishRoundXP)
hook.Add("OnRoundEnd", "HMCD_Professions_XP", finishRoundXP)

local ASSIGN_DELAY = 1.5

local cvarAssignAll = CreateConVar("hmcd_prof_assign_all", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "1 - vydavat professiyu vsem, 0 - primerno polovine")
local cvarIgnoreUnlock = CreateConVar("hmcd_prof_ignore_unlock", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "1 - igonorirovat XP-razblokirovku pri sluchaynoy vydache")

local function professionPool()
    local pool = nil
    local t = currentRoundType()
    local rct = hmField("RoleChooseRoundTypes")
    if t and istable(rct) and istable(rct[t]) then pool = rct[t].Professions end
    if not istable(pool) then pool = hmField("DefaultProfessions") end
    return istable(pool) and pool or nil
end

local function applyProfession(ply, key)
    if not IsValid(ply) or not key or key == "" then return end
    syncModeTable()
    ply.Profession = key
    ply:SetNWString("HMCD_CurrentProfession", key)

    local profs = hmField("Professions")
    local def = istable(profs) and profs[key] or nil
    if def and isfunction(def.SpawnFunction) then def.SpawnFunction(ply) end

    hook.Run("HMCD_ProfessionAssigned", ply, key)

    local msg = "Ваша профессия: " .. professionTitle(key)
    local short = professionShort(key)
    if short then msg = msg .. " - " .. short end
    notifyPlayer(ply, msg, professionColor(key), "prof_assign", 6)
end
MODE.ApplyProfession = applyProfession

local function assignProfessions()
    syncModeTable()
    if not roundAllowsProfessions() then return end

    local pool = professionPool()
    if not pool then return end

    local weighted = {}
    for prof, info in pairs(pool) do
        local chance = (istable(info) and tonumber(info.Chance)) or 1
        if chance > 0 and professionExists(prof) then
            weighted[#weighted + 1] = {chance, prof}
        end
    end
    if #weighted == 0 then return end

    local pending = {}
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR and not ply.Profession then
            local chosen = getChosenProfession(ply)
            if chosen and pool[chosen] then
                applyProfession(ply, chosen)
            else
                pending[#pending + 1] = ply
            end
        end
    end
    if #pending == 0 then return end

    local quota = cvarAssignAll:GetBool() and #pending or math.max(1, math.ceil(#pending / 2))
    local ignoreUnlock = cvarIgnoreUnlock:GetBool()

    for _, ply in RandomPairs(pending) do
        if quota <= 0 then break end
        local index, prof
        if ignoreUnlock then
            index = math.random(#weighted)
            prof = weighted[index][2]
        else
            index, prof = selectUnlockedProfession(weighted, ply)
        end
        if prof then
            weighted[index][1] = weighted[index][1] / 2
            applyProfession(ply, prof)
            quota = quota - 1
        end
    end
end
MODE.AssignProfessions = assignProfessions

local function scheduleProfessionAssign()
    timer.Create("HMCD_Professions_Assign", ASSIGN_DELAY, 1, assignProfessions)
end

hook.Add("Think", "HMCD_Professions_CurrentSync", function()
    if (MODE.HMCDNextProfNWSync or 0) > CurTime() then return end
    MODE.HMCDNextProfNWSync = CurTime() + 0.5

    for _, ply in player.Iterator() do
        if IsValid(ply) then
            local prof = ply.Profession
            if not isstring(prof) then prof = "" end
            if ply:GetNWString("HMCD_CurrentProfession", "") ~= prof then
                ply:SetNWString("HMCD_CurrentProfession", prof)
            end
        end
    end
end)

concommand.Add("hmcd_prof_assign_now", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    assignProfessions()
end)

hook.Add("Think", "HMCD_Professions_RoundStateWatch", function()
    if not isHomicideMode() then return end
    local st = zb.ROUND_STATE
    if MODE.HMCDLastRoundState == nil then MODE.HMCDLastRoundState = st return end
    if st == MODE.HMCDLastRoundState then return end
    local old = MODE.HMCDLastRoundState
    MODE.HMCDLastRoundState = st
    if st == 1 then
        markRoundActive()
        scheduleProfessionAssign()
    elseif old == 1 and MODE.HMCDProfRoundActive then
        finishRoundXP()
    end
end)



timer.Simple(0, function()
    if MODE.HMCDProfEndRoundWrapped then return end
    if not isfunction(MODE.EndRound) then return end
    MODE.HMCDProfEndRoundWrapped = true
    local oldEndRound = MODE.EndRound
    function MODE:EndRound(...)
        local results = {oldEndRound(self, ...)}
        timer.Simple(0, function()
            if MODE.FinishProfRoundXP then MODE.FinishProfRoundXP() end
        end)
        return unpack(results)
    end
end)

concommand.Add("hmcd_prof_endround_xp", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    MODE.HMCDProfRoundEnded = false
    finishRoundXP()
end)

local function IsXPAdmin(ply)
    return not IsValid(ply) or ply:IsSuperAdmin()
end

local function ResolveTargets(token)
    local out = {}
    token = string.lower(tostring(token or ""))
    if token == "" then return out end
    if token == "all" or token == "*" or token == "@all" then
        for _, p in player.Iterator() do out[#out + 1] = p end
        return out
    end
    for _, p in player.Iterator() do
        if string.lower(p:SteamID()) == token or p:SteamID64() == token or string.find(string.lower(p:Nick()), token, 1, true) then
            out[#out + 1] = p
        end
    end
    return out
end

local function Reply(ply, msg)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
end

concommand.Add("hmcd_give_xp", function(ply, cmd, args)
    if not IsXPAdmin(ply) then return end
    local targets = ResolveTargets(args[1])
    local amount = math.floor(tonumber(args[2]) or 0)
    if #targets == 0 or amount == 0 then Reply(ply, "Использование: hmcd_give_xp <ник|steamid|all> <кол-во>") return end
    for _, t in ipairs(targets) do addProfXP(t, amount) Reply(ply, t:Nick() .. ": опыт " .. getProfXP(t)) end
end)

concommand.Add("hmcd_set_xp", function(ply, cmd, args)
    if not IsXPAdmin(ply) then return end
    local targets = ResolveTargets(args[1])
    local amount = math.floor(tonumber(args[2]) or 0)
    if #targets == 0 then Reply(ply, "Использование: hmcd_set_xp <ник|steamid|all> <опыт>") return end
    for _, t in ipairs(targets) do setProfXP(t, amount) Reply(ply, t:Nick() .. ": опыт " .. getProfXP(t)) end
end)

concommand.Add("hmcd_prof_debug", function(ply, cmd, args)
    local function line(msg) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end end
    line("=== HMCD PROF DEBUG (server) ===")
    line("XP rates: kill=" .. tostring(profXPValue("Kill")) .. " round=" .. tostring(profXPValue("Round")) .. " survive=" .. tostring(profXPValue("Survive")) .. " cap=" .. tostring(ROUND_XP_CAP))
    local hm = hmcd()
    line("Homicide table found: " .. tostring(hm ~= nil) .. " | via zb.modes: " .. tostring(istable(zb) and istable(zb.modes) and zb.modes.hmcd == hm))
    line("zb.CROUND: " .. tostring(istable(zb) and zb.CROUND) .. " | hm.Type: " .. tostring(hm and hm.Type) .. " | is hmcd round: " .. tostring(isHomicideMode()))
    line("Round type: " .. tostring(currentRoundType()) .. " | professions allowed: " .. tostring(roundAllowsProfessions()))
    line("Professions table: " .. tostring(istable(hmField("Professions"))) .. " | meta: " .. tostring(istable(hmField("ProfessionMeta"))) .. " | pool: " .. tostring(professionPool() ~= nil))
    line("local MODE.Type: " .. tostring(MODE.Type))
    line("Round active: " .. tostring(MODE.HMCDProfRoundActive) .. " ended=" .. tostring(MODE.HMCDProfRoundEnded) .. " state=" .. tostring(zb and zb.ROUND_STATE))
    local target = IsValid(ply) and ply or nil
    if args and args[1] and args[1] ~= "" then local r = ResolveTargets(args[1]); target = r[1] or target end
    if IsValid(target) then
        line("target: " .. target:Nick())
        line("XP: " .. tostring(getProfXP(target)))
        line("Choice: '" .. tostring(getProfChoice(target)) .. "'")
        line("GetChosenProfession: " .. tostring(getChosenProfession(target)))
        line("current Profession: " .. tostring(target.Profession))
        line("round earned: " .. tostring(target.ProfRoundXP or 0))
        for _, k in ipairs(MODE.ProfessionOrder or {}) do line("  " .. k .. ": cost=" .. tostring(unlockCost(k)) .. " unlocked=" .. tostring(isUnlocked(getProfXP(target), k))) end
    end
    line("=== END ===")
end)
