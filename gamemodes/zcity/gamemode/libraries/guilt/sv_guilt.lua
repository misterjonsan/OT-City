zb = zb or {}
zb.MaxSovest = 120
zb.MaxKarma = 120
zb.MinSovest = -70

local SOVEST_MAX = 120
local SOVEST_MIN = -70
local SOVEST_DEFAULT = 100

local function MaxSovest()
    if zb.MaxSovest ~= SOVEST_MAX then
        zb.MaxSovest = SOVEST_MAX
    end
    if zb.MaxKarma ~= SOVEST_MAX then
        zb.MaxKarma = SOVEST_MAX
    end
    return SOVEST_MAX
end

local function ClampSovest(val)
    return math.Clamp(tonumber(val) or SOVEST_DEFAULT, SOVEST_MIN, MaxSovest())
end

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneSovest = zb.HarmDoneSovest or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "включить режим разработчика (включает трассировку урона)", 0, 1)
local zb_dev = ConVarExists("zb_dev") and GetConVar("zb_dev") or CreateConVar("zb_dev", 0, FCVAR_SERVER_CAN_EXECUTE, "dev режим zb", 0, 1)

local SOVEST_SAVE_EVERY = 180
local SOVEST_THINK_EVERY = 120

local function NowTS()
    return os.time()
end

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()
    return ClampSovest(self:GetMData("sovest", self:GetMData("karma", SOVEST_DEFAULT)))
end

function plyMeta:guilt_SetValue(val)
    val = ClampSovest(val)
    self.Sovest = ClampSovest(self.Sovest or val)
    self:SetMData("sovest", val)
    self:SetMData("sovest_max", MaxSovest())
    self.Karma = self.Sovest
    self:SetNetVar("Karma", self.Karma)
    self:SetNetVar("MaxSovest", MaxSovest())
    self:SetNetVar("MaxKarma", MaxSovest())
end

local function SyncLegacyKarma(ply)
    if not IsValid(ply) then return end
    ply.Sovest = ClampSovest(ply.Sovest)
    ply.Karma = ply.Sovest
    ply:SetNetVar("Karma", ply.Karma)
    ply:SetNetVar("Sovest", ply.Sovest)
    ply:SetNetVar("MaxSovest", MaxSovest())
    ply:SetNetVar("MaxKarma", MaxSovest())
end

local function GetVictimPlayer(v)
    if not IsValid(v) then return nil end
    if v:IsPlayer() then return v end
    if v.organism and v.organism.fakePlayer and IsValid(v.organism.fakePlayer) then return v.organism.fakePlayer end
    if hg and hg.RagdollOwner and isfunction(hg.RagdollOwner) then
        local o = hg.RagdollOwner(v)
        if IsValid(o) and o:IsPlayer() then return o end
    end
    if hg and hg.GetCurrentCharacter and isfunction(hg.GetCurrentCharacter) then
        local c = hg.GetCurrentCharacter(v)
        if IsValid(c) and c:IsPlayer() then return c end
        if IsValid(c) and c.organism and c.organism.fakePlayer and IsValid(c.organism.fakePlayer) then return c.organism.fakePlayer end
    end
    return nil
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    local len = diff:Length()
    if len <= 0.001 then return true end
    return (ply:GetAimVector():Dot(diff) / len) >= 0.8
end

local function SovestRegenRate(ply, sovest)
    local gain = tonumber(ply.SovestGain) or 0.55
    if sovest > SOVEST_DEFAULT then
        return (gain * 0.3) / SOVEST_THINK_EVERY
    end
    return gain / SOVEST_THINK_EVERY
end

local function ApplyOfflineRegen(ply, sovest, seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    sovest = ClampSovest(sovest)
    if seconds <= 0 then return ClampSovest(sovest) end

    if sovest < SOVEST_DEFAULT then
        local rateLow = SovestRegenRate(ply, sovest)
        local need = SOVEST_DEFAULT - sovest
        local tTo100 = need / math.max(rateLow, 0.0000001)
        if seconds <= tTo100 then
            sovest = sovest + seconds * rateLow
            return ClampSovest(sovest)
        end
        sovest = SOVEST_DEFAULT
        seconds = seconds - tTo100
    end

    local rateHigh = SovestRegenRate(ply, SOVEST_DEFAULT + 1)
    sovest = sovest + seconds * rateHigh
    return ClampSovest(sovest)
end

local function SaveSovestState(ply)
    if not IsValid(ply) then return end
    ply.Sovest = ClampSovest(ply.Sovest)
    ply:guilt_SetValue(ply.Sovest)
    if ply.SetMData then
        ply:SetMData("sovest_ts", NowTS())
        ply:SetMData("sovest_gain", tonumber(ply.SovestGain) or 0.55)
    end
    if mdata and isfunction(mdata.FlushPlayer) then
        mdata.FlushPlayer(ply)
    end
end

local function InitSovest(ply)
    if not IsValid(ply) then return end

    local stored = ClampSovest(ply:guilt_GetValue())
    local lastTS = tonumber(ply.GetMData and ply:GetMData("sovest_ts", ply:GetMData("karma_ts", NowTS())) or NowTS()) or NowTS()
    local savedGain = tonumber(ply.GetMData and ply:GetMData("sovest_gain", 0.75) or 0.55) or 0.55
    ply.SovestGain = ply.SovestGain or savedGain

    local delta = NowTS() - lastTS
    if delta > 0 then
        stored = ApplyOfflineRegen(ply, stored, delta)
    end

    ply.Sovest = ClampSovest(stored)
    ply:SetNetVar("Sovest", ply.Sovest)
    ply:guilt_SetValue(ply.Sovest)
    SyncLegacyKarma(ply)
    if ply.SetMData then
        ply:SetMData("sovest_ts", NowTS())
        ply:SetMData("sovest_gain", tonumber(ply.SovestGain) or 0.55)
    end

    local tid = "zb_sovestsave_" .. ply:SteamID64()
    timer.Remove(tid)
    timer.Create(tid, SOVEST_SAVE_EVERY, 0, function()
        if not IsValid(ply) then timer.Remove(tid) return end
        SaveSovestState(ply)
    end)
end

hook.Add("PlayerInitialSpawn", "ZB_Sovest_Load_MData", function(ply)
    local id = "zb_wait_mdata_" .. ply:EntIndex()
    timer.Create(id, 0.1, 0, function()
        if not IsValid(ply) then timer.Remove(id) return end
        if not mdata or not isfunction(mdata.IsLoaded) then return end
        if not mdata:IsLoaded(ply) then return end
        timer.Remove(id)
        InitSovest(ply)
    end)
end)

function zb.IsForce(Attacker)
    return Attacker.PlayerClassName == "police" or Attacker.PlayerClassName == "nationalguard" or Attacker.PlayerClassName == "swat"
end

function zb.ForcesAttackedInnocent(self, Victim)
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    return 1 * ((not Victim.LastAttacked or (Victim.LastAttacked + 10 > CurTime())) and 0 or 1) + 1 * (Victim:IsPlayer() and ((IsLookingAt(Victim, self:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistanceSqr(self:GetPos()) <= (72 * 72))))) and 0 or 1) or 1)
end

local function SmoothPenaltyFactor(amt)
    amt = math.Clamp(amt or 0, 0, 1)
    local x = amt
    local y = x * x
    y = 0.65 + 0.35 * y
    return y
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm)
    local Attacker = dmgInfo:GetAttacker()
    local Victim = ply

    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
    if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism and Victim.organism.fakePlayer and Victim.organism.alive)) then return end

    local victimPly = GetVictimPlayer(Victim) or Victim
    local attackerPly = Attacker

    local maxharm = zb.MaximumHarm
    if not maxharm or maxharm <= 0 then return end

    zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
    zb.HarmDoneSovest[Victim] = zb.HarmDoneSovest[Victim] or {}

    local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
    local newharm = math.Clamp(oldharmdone + (harm or 0), 0, maxharm)
    zb.HarmDone[Victim][Attacker] = newharm

    zb.HarmAttacked[Attacker] = (zb.HarmAttacked[Attacker] or 0) + (harm or 0)

    local deltaHarm = newharm - oldharmdone
    if deltaHarm < 0 then deltaHarm = 0 end
    local amt = deltaHarm / maxharm

    local inf = dmgInfo:GetInflictor()
    local attackerTeam = (IsValid(inf) and inf.team) or (Attacker:IsPlayer() and Attacker:Team()) or Attacker.team

    local idV = Victim:IsPlayer() and Victim:SteamID() or Victim:EntIndex()
    local idA = Attacker:IsPlayer() and Attacker:SteamID() or Attacker:EntIndex()
    zb.HarmDoneDetailed[idV] = zb.HarmDoneDetailed[idV] or {}
    zb.HarmDoneDetailed[idV][idA] = {
        harm = newharm,
        amt = newharm / maxharm,
        teamVictim = victimPly and victimPly:IsPlayer() and victimPly:Team() or (Victim.team or -1),
        teamAttacker = attackerTeam or -1,
        lasthitgroup = hitgroup,
        lastdmgtype = dmgInfo:GetDamageType(),
        lastattacked = CurTime(),
    }

    if hg_developer:GetBool() then
        Attacker:ChatPrint("Нанесённый урон сейчас: " .. math.Round(deltaHarm, 3))
        Attacker:ChatPrint("Доля от максимума: " .. math.Round(amt, 3))
        Attacker:ChatPrint("Всего нанесено: " .. math.Round(newharm, 3))
        Attacker:ChatPrint("Вины начислено: " .. math.Round((amt * 55), 3))
        Attacker:ChatPrint(" ")
    end

    hook.Run("HarmDone", Attacker, Victim, amt)

    local rnd = CurrentRound()
    if not rnd then return end
    if rnd.GuiltDisabled or (zb_dev and zb_dev:GetBool()) then return end
    if Attacker == Victim then return end

    local vChar = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(Victim)) or Victim
    vChar = (hg and hg.RagdollOwner and hg.RagdollOwner(vChar)) or vChar
    local aChar = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(Attacker)) or Attacker
    aChar = (hg and hg.RagdollOwner and hg.RagdollOwner(aChar)) or aChar

    victimPly = GetVictimPlayer(vChar) or victimPly
    attackerPly = Attacker

    zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
    zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}

    Attacker.LastAttacked = CurTime()

    if rnd.name == "hmcd" and victimPly and victimPly.isTraitor and not attackerPly.isTraitor and not zb.IsForce(attackerPly) then return end
    if rnd.name == "hmcd" and attackerPly.isTraitor and victimPly and not victimPly.isTraitor then return end
    if rnd.name ~= "hmcd" and (Attacker.Team and victimPly and victimPly.Team and attackerTeam ~= victimPly:Team()) then return end
    if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return end
    if victimPly and victimPly.Guilt and victimPly.Guilt > 1 and not zb.IsForce(Attacker) then return end
    if Attacker:IsBerserk() then return end
    if amt <= 0 then return end

    local victimWep = victimPly and victimPly:IsPlayer() and IsValid(victimPly:GetActiveWeapon()) and victimPly:GetActiveWeapon()
    local lookingMul = 1
    if victimPly and victimPly:IsPlayer() then
        local closeMelee = victimWep and ((ishgweapon(victimWep)) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and victimPly:EyePos():DistToSqr(Attacker:EyePos()) <= (90 * 90)))
        if IsLookingAt(victimPly, Attacker:EyePos()) and closeMelee then
            lookingMul = 0.85
        end
    end

    local victimSovestMul = 1
    if victimPly and victimPly:IsPlayer() then
        victimSovestMul = math.Clamp(((victimPly.Sovest or SOVEST_DEFAULT) / SOVEST_DEFAULT), 1, 1.3)
    end

    local baseAmt = amt * victimSovestMul * lookingMul
    local soften = SmoothPenaltyFactor(baseAmt)

    local add = baseAmt * maxharm
    add = add * (victimPly and victimPly:IsPlayer() and Attacker:PlayerClassEvent("Guilt", victimPly) or 1)
    add = add * 2.4
    add = add * soften

    local prevForgive = zb.GuiltTable[Victim] and zb.GuiltTable[Victim][Attacker] or 0
    local forgiveMul = math.Clamp(1 - (prevForgive / 280), 0.65, 1)
    add = add * forgiveMul

    local perHitCap = math.max(20, math.min(70, (zb.MaximumHarm or 60) * 1.10))
    add = math.Clamp(add, 0, perHitCap)

    local mul
    if rnd.GuiltCheck then
        mul = rnd.GuiltCheck(Attacker, victimPly or Victim, add, deltaHarm, baseAmt)
        add = add * (mul or 1)
    end

    local guiltadd = baseAmt * 105
    Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd

    local curK = Attacker.Sovest or SOVEST_DEFAULT
    Attacker.Sovest = ClampSovest(curK - add)

    zb.HarmDoneSovest[Victim][Attacker] = (zb.HarmDoneSovest[Victim][Attacker] or 0) + add

    Attacker:SetNetVar("Sovest", Attacker.Sovest)
    Attacker:guilt_SetValue(Attacker.Sovest)
    if Attacker.SetMData then
        Attacker:SetMData("sovest_ts", NowTS())
    end

    zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, 200)
end)

hook.Add("PlayerDeath", "GuiltKillPenalty", function(victim, _, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local rnd = CurrentRound()
    if not rnd or rnd.GuiltDisabled or (zb_dev and zb_dev:GetBool()) then return end
    if rnd.name == "hmcd" and victim.isTraitor and not attacker.isTraitor and not zb.IsForce(attacker) then return end
    if rnd.name == "hmcd" and attacker.isTraitor and not victim.isTraitor then return end
    if rnd.name ~= "hmcd" and attacker.Team and victim.Team and attacker:Team() ~= victim:Team() then return end
    if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return end
    if victim.Guilt and victim.Guilt > 1 and not zb.IsForce(attacker) then return end
    if attacker:IsBerserk() then return end

    local killPenalty = 28
    attacker.Sovest = ClampSovest((attacker.Sovest or SOVEST_DEFAULT) - killPenalty)
    attacker.Guilt = (attacker.Guilt or 0) + 70
    attacker:SetNetVar("Sovest", attacker.Sovest)
    attacker:guilt_SetValue(attacker.Sovest)
    if attacker.SetMData then attacker:SetMData("sovest_ts", NowTS()) end

    zb.HarmDoneSovest[victim] = zb.HarmDoneSovest[victim] or {}
    zb.HarmDoneSovest[victim][attacker] = (zb.HarmDoneSovest[victim][attacker] or 0) + killPenalty
end)

hook.Add("PlayerDisconnected", "GuiltSaveOnDisconect", function(ply)
    if not IsValid(ply) then return end
    local tid = "zb_sovestsave_" .. (ply:SteamID64() or ply:EntIndex())
    timer.Remove(tid)
    SaveSovestState(ply)
end)

hook.Add("Player Spawn", "SlowlyRestoreSovest", function(ply)
    if OverrideSpawn then return end
    ply.lastwarning = nil
    ply.Sovest = ClampSovest(ply.Sovest)
    ply:SetNetVar("Sovest", ply.Sovest)
    SyncLegacyKarma(ply)
    ply.Guilt = 0
end)

hook.Add("Player Think", "sovestgain", function(ply)
    if (ply.SovestGainThink or 0) > CurTime() then return end
    ply.SovestGainThink = CurTime() + SOVEST_THINK_EVERY

    ply.Sovest = ClampSovest(ply.Sovest)
    local rate = SovestRegenRate(ply, ply.Sovest) * SOVEST_THINK_EVERY
    ply.Sovest = ClampSovest(ply.Sovest + rate)
    ply:SetNetVar("Sovest", ply.Sovest)
    SyncLegacyKarma(ply)
    if ply.SetMData then
        ply:SetMData("sovest_ts", NowTS())
        ply:SetMData("sovest_gain", tonumber(ply.SovestGain) or 0.55)
    end
end)

hook.Add("Org Clear", "removesovestshaking", function(org)
    org.start_shaking = nil
end)

hook.Add("Should Fake Up", "sovest", function(ply)
    if ply.organism and ply.organism.start_shaking then return false end
end)

zb.SovestName = "Совесть"

local seizuremsgs = {
    "bllllhlhmmmbmmmmbmbmb",
    "bbb b-bbbbbb bllmbmmbb",
    "ddgdgg-d bbbglgggg",
    "mmmmammmm aaghbgbblllb",
    "hhel-bbbphphpppph",
    "zzzzblzzzmzzzzz",
}

hook.Add("Org Think", "Its_Sovest_Bro", function(owner, org, timeValue)
    if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
    if not owner:IsPlayer() or not owner:Alive() then return end

    local ply = owner
    local k = ClampSovest(ply.Sovest)
    local maxK = MaxSovest()

    if k < 55 then
        local chanceBase = math.Clamp(k, 20, maxK) * 360
        if ((math.random(chanceBase) == 1 or org.start_shaking)) then
            hg.StunPlayer(ply)
            local time = 14

            ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
                if not IsValid(ply) then return end
                ply:ChatPrint("У тебя эпилептический припадок.")
            end)

            org.start_shaking = org.start_shaking or (CurTime() + time)
            local ent = hg.GetCurrentCharacter(owner)
            local mul = ((org.start_shaking) - CurTime()) / time

            if mul > 0 and IsValid(ent) then
                local cnt = ent:GetPhysicsObjectCount()
                if cnt and cnt > 0 then
                    local idx = math.max(0, math.min(cnt - 1, math.random(cnt) - 1))
                    local ph = ent:GetPhysicsObjectNum(idx)
                    if IsValid(ph) then
                        ph:ApplyForceCenter(VectorRand(-720 * mul, 720 * mul))
                    end
                end
            else
                org.start_shaking = nil
            end
        else
            org.start_shaking = nil
        end
    end

    if k < 40 then
        if math.random(2300) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end)

hook.Add("ZB_EndRound", "savevalues", function()
    for _, ply in player.Iterator() do
        SaveSovestState(ply)
    end
end)

hook.Add("ZB_StartRound", "NO_HARM", function()
    for _, ply in player.Iterator() do
        if (ply.Guilt or 0) < 1 then
            ply.SovestGain = math.Clamp((ply.SovestGain or 0.55) + 0.15, 0.55, 0.95)
        else
            ply.SovestGain = 0.55
        end
        if ply.SetMData then
            ply:SetMData("sovest_gain", tonumber(ply.SovestGain) or 0.55)
        end
    end

    zb.HarmDone = {}
    zb.HarmDoneSovest = {}
end)

util.AddNetworkString("zb_sovest_query")
util.AddNetworkString("zb_sovest_list")
util.AddNetworkString("zb_sovest_forgive")
util.AddNetworkString("zb_sovest_admin")

local function SendForgiveList(ply)
    if not IsValid(ply) or ply:Alive() then return end
    local src = zb.HarmDoneSovest[ply] or {}
    local list = {}
    for ent, amount in pairs(src) do
        amount = tonumber(amount) or 0
        if IsValid(ent) and ent:IsPlayer() and amount > 0.01 then
            list[#list + 1] = { ent = ent, amount = amount }
        end
    end
    net.Start("zb_sovest_list")
    net.WriteUInt(math.min(#list, 255), 8)
    for i = 1, math.min(#list, 255) do
        net.WriteEntity(list[i].ent)
        net.WriteFloat(list[i].amount)
    end
    net.Send(ply)
end

net.Receive("zb_sovest_query", function(_, ply)
    SendForgiveList(ply)
end)

net.Receive("zb_sovest_forgive", function(_, ply)
    if not IsValid(ply) or ply:Alive() then return end
    local ent = net.ReadEntity()
    local src = zb.HarmDoneSovest[ply]
    if not IsValid(ent) or not src then return end
    local amount = tonumber(src[ent]) or 0
    if amount <= 0 then return end
    ent.Sovest = ClampSovest((ent.Sovest or SOVEST_DEFAULT) + amount)
    ent:SetNetVar("Sovest", ent.Sovest)
    ent:guilt_SetValue(ent.Sovest)
    if ent.SetMData then ent:SetMData("sovest_ts", NowTS()) end
    if zb.HarmDone[ply] then zb.HarmDone[ply][ent] = 0 end
    src[ent] = 0
    SendForgiveList(ply)
end)

net.Receive("zb_sovest_admin", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local values = {}
    for _, target in player.Iterator() do values[target:UserID()] = target.Sovest end
    net.Start("zb_sovest_admin")
    net.WriteTable(values)
    net.Send(ply)
end)

concommand.Add("hg_setsovest", function(ply, _, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local target = player.GetListByName(#args > 1 and args[1] or ply:Name())[1]
    if not IsValid(target) then return end
    target.Sovest = ClampSovest(tonumber(#args > 1 and args[2] or args[1]) or SOVEST_DEFAULT)
    target:SetNetVar("Sovest", target.Sovest)
    target:guilt_SetValue(target.Sovest)
    if target.SetMData then target:SetMData("sovest_ts", NowTS()) end
end)

hook.Add("Player Spawn", "GuiltKnown", function(ply)
    if ply.Sovest then
        ply:ChatPrint("Твоя текущая Совесть: " .. tostring(math.Round(ply.Sovest)))
    end
end)

hook.Add("ZC_SomeoneGetFallBy", "IdiotsMustBeKilled", function(Attacker, Victim)
    local rnd = CurrentRound()
    if not rnd then return end

    if rnd.GuiltDisabled or (zb_dev and zb_dev:GetBool()) then return end
    if Attacker == Victim then return end

    local victimPly = GetVictimPlayer(Victim) or Victim
    local attackerPly = Attacker

    if rnd.name == "hmcd" and victimPly and victimPly.isTraitor and not attackerPly.isTraitor and not zb.IsForce(attackerPly) then return end
    if rnd.name == "hmcd" and attackerPly.isTraitor and victimPly and not victimPly.isTraitor then return end
    if rnd.name ~= "hmcd" and (Attacker.Team and victimPly and victimPly.Team and Attacker:Team() ~= victimPly:Team()) then return end
    if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return end
    if victimPly and victimPly.Guilt and victimPly.Guilt > 1 then return end

    Attacker.Guilt = Attacker.Guilt or 0
    Attacker.Guilt = Attacker.Guilt < 9 and 10 or Attacker.Guilt
    Attacker.Sovest = ClampSovest((Attacker.Sovest or SOVEST_DEFAULT) - 6)
    Attacker:SetNetVar("Sovest", Attacker.Sovest)
    Attacker:guilt_SetValue(Attacker.Sovest)
end)
