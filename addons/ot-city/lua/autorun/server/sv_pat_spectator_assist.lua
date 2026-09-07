AddCSLuaFile("autorun/sh_pat_spectator_assist.lua")
AddCSLuaFile("autorun/client/cl_pat_spectator_assist.lua")
include("autorun/sh_pat_spectator_assist.lua")

local addon = PAT_SPECTATOR_ASSIST
addon.Timeline = addon.Timeline or {}

util.AddNetworkString("PAT_SpectatorTimelineSync")
util.AddNetworkString("PAT_SpectatorTimelinePush")
util.AddNetworkString("PAT_SpectatorDeathRecap")

local function getBestRecordedAttacker(victim)
    local bestAttacker, bestHarm, bestTime = nil, -1, -1
    local damageTable = zb and zb.HarmDone and zb.HarmDone[victim] or nil
    local victimId = addon.GetEntityId(victim)
    local detailed = victimId and zb and zb.HarmDoneDetailed and zb.HarmDoneDetailed[victimId] or nil

    for attacker, harm in pairs(damageTable or {}) do
        if not IsValid(attacker) or attacker == victim then continue end

        local attackerId = addon.GetEntityId(attacker)
        local detail = attackerId and detailed and detailed[attackerId] or nil
        local lastAttacked = detail and tonumber(detail.lastattacked) or 0
        harm = tonumber(harm) or 0
        if lastAttacked > 0 and CurTime() - lastAttacked > 15 then continue end

        if harm > bestHarm or (harm == bestHarm and lastAttacked > bestTime) then
            bestAttacker = attacker
            bestHarm = harm
            bestTime = lastAttacked
        end
    end

    return bestAttacker
end

local function getPlayerOwner(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end
    if ent.organism and IsValid(ent.organism.fakePlayer) then return ent.organism.fakePlayer end
    if hg and hg.RagdollOwner then
        local owner = hg.RagdollOwner(ent)
        if IsValid(owner) and owner:IsPlayer() then return owner end
    end
    return nil
end

local function getRecentDamageAttacker(victim)
    local data = IsValid(victim) and victim.patSpectatorAssistLastDamage or nil
    if not data or (CurTime() - (data.time or 0)) > 15 then return nil end
    if IsValid(data.attacker) and data.attacker ~= victim then return data.attacker end
    return nil
end

local function resolveAttacker(victim, attacker)
    local direct = getPlayerOwner(attacker)
    if IsValid(direct) and direct ~= victim then return direct end

    local recent = getRecentDamageAttacker(victim)
    if IsValid(recent) then return recent end

    local recorded = getBestRecordedAttacker(victim)
    if IsValid(recorded) and recorded ~= victim then return recorded end

    return nil
end

local function isConfirmedSelfInflicted(victim)
    local selfDamage = victim.patSpectatorAssistLastSelfDamage
    if not selfDamage or CurTime() - (selfDamage.time or 0) > 3 then return false end

    local otherDamage = victim.patSpectatorAssistLastDamage
    if otherDamage and (otherDamage.time or 0) >= (selfDamage.time or 0) then return false end

    return true
end

local function getCauseLabel(victim, inflictor, attacker, selfInflicted)
    if selfInflicted then return "самоубийство" end
    attacker = resolveAttacker(victim, attacker)

    if IsValid(inflictor) and not inflictor:IsPlayer() then
        return addon.PrettyClassName(inflictor:GetClass())
    end

    if IsValid(attacker) and attacker:IsPlayer() then
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) then
            return addon.PrettyClassName(wep:GetClass())
        end

        return "неизвестное оружие"
    end

    return addon.PrettyClassName(IsValid(inflictor) and inflictor:GetClass() or nil)
end

local function buildDeathSummary(victim, attacker, causeLabel, selfInflicted)
    local victimLabel = addon.GetEntityLabel(victim, "Неизвестный")

    if selfInflicted then
        return victimLabel .. " Умер из-за самоубийства."
    end

    if IsValid(attacker) then
        return addon.GetEntityLabel(attacker, "Неизвестный") .. " Убил " .. victimLabel .. "."
    end

    return victimLabel .. " Умер от " .. causeLabel .. "."
end

local function getTopContributors(victim)
    local contributors = {}
    local damageTable = zb and zb.HarmDone and zb.HarmDone[victim] or nil

    for attacker, harm in pairs(damageTable or {}) do
        if not IsValid(attacker) then continue end
        if not isnumber(harm) or harm <= 0 then continue end

        contributors[#contributors + 1] = {
            name = addon.GetEntityLabel(attacker, "Неизвестный"),
            harm = math.Round(harm, 1),
            share = math.Round((harm / math.max(zb and zb.MaximumHarm or 10, 1)) * 100)
        }
    end

    table.sort(contributors, function(a, b)
        return a.harm > b.harm
    end)

    while #contributors > 3 do
        table.remove(contributors)
    end

    return contributors
end

local function getAttackerDetail(victim, attacker)
    if not zb or not zb.HarmDoneDetailed then return nil end

    local victimId = addon.GetEntityId(victim)
    local attackerId = addon.GetEntityId(attacker)

    if not victimId or not attackerId then return nil end

    local detailed = zb.HarmDoneDetailed[victimId]
    if not detailed then return nil end

    return detailed[attackerId]
end

local function buildTimelineEntry(victim, inflictor, attacker, selfInflicted)
    if not selfInflicted then attacker = resolveAttacker(victim, attacker) end

    local causeLabel = getCauseLabel(victim, inflictor, attacker, selfInflicted)

    return {
        victim = addon.GetEntityLabel(victim, "Unknown"),
        attacker = addon.GetEntityLabel(attacker, "Environment"),
        cause = causeLabel,
        summary = buildDeathSummary(victim, attacker, causeLabel, selfInflicted),
        round = addon.GetRoundLabel(),
        time_left = addon.GetTimeLeft(),
        time_left_label = addon.FormatClock(addon.GetTimeLeft()),
        event_time = addon.GetTimeElapsed(),
        event_time_label = addon.FormatClock(addon.GetTimeElapsed()),
        timestamp = CurTime()
    }
end

local function buildDeathRecap(victim, inflictor, attacker, selfInflicted)
    if not selfInflicted then attacker = resolveAttacker(victim, attacker) end

    local causeLabel = getCauseLabel(victim, inflictor, attacker, selfInflicted)
    local summary

    if selfInflicted then
        summary = "Ты умер от самоубийства."
    elseif IsValid(attacker) then
        summary = "Ты был убит " .. addon.GetEntityLabel(attacker, "Unknown") .. "."
    else
        summary = "Ты умер от " .. causeLabel .. "."
    end

    local attackDetail = getAttackerDetail(victim, attacker)
    local org = victim.organism or {}

    return {
        summary = summary,
        attacker = addon.GetEntityLabel(attacker, "Environment"),
        cause = causeLabel,
        round = addon.GetRoundLabel(),
        time_left = addon.GetTimeLeft(),
        time_left_label = addon.FormatClock(addon.GetTimeLeft()),
        killed_at = addon.GetTimeElapsed(),
        killed_at_label = addon.FormatClock(addon.GetTimeElapsed()),
        hitgroup = attackDetail and addon.HitgroupNames[attackDetail.lasthitgroup] or nil,
        blood = math.Round(tonumber(org.blood) or 0),
        pain = math.Round(tonumber(org.pain) or 0),
        pulse = math.Round(tonumber(org.pulse) or 0),
        contributors = getTopContributors(victim)
    }
end

function addon.SendTimeline(ply)
    if not IsValid(ply) then return end

    net.Start("PAT_SpectatorTimelineSync")
        net.WriteTable(addon.Timeline or {})
    net.Send(ply)
end

hook.Add("ZB_PreRoundStart", "PAT_SpectatorAssist_ResetTimeline", function()
    addon.Timeline = {}

    net.Start("PAT_SpectatorTimelineSync")
        net.WriteTable({})
    net.Broadcast()
end)

hook.Add("PlayerInitialSpawn", "PAT_SpectatorAssist_SyncOnJoin", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        addon.SendTimeline(ply)
    end)
end)

hook.Add("HomigradDamage", "PAT_SpectatorAssist_TrackHomigradDamage", function(victim, damageInfo)
    local victimPlayer = getPlayerOwner(victim)
    if not IsValid(victimPlayer) then return end

    local attacker = getPlayerOwner(damageInfo:GetAttacker())
    if not IsValid(attacker) then return end

    local data = {
        attacker = attacker,
        inflictor = damageInfo:GetInflictor(),
        time = CurTime()
    }

    if attacker == victimPlayer then
        victimPlayer.patSpectatorAssistLastSelfDamage = data
    else
        victimPlayer.patSpectatorAssistLastDamage = data
    end
end)

hook.Add("EntityTakeDamage", "PAT_SpectatorAssist_TrackDamage", function(target, damageInfo)
    local victim = getPlayerOwner(target)
    if not IsValid(victim) then return end

    local attacker = getPlayerOwner(damageInfo:GetAttacker())
    if not IsValid(attacker) then return end

    if attacker == victim then return end

    victim.patSpectatorAssistLastDamage = {
        attacker = attacker,
        inflictor = damageInfo:GetInflictor(),
        time = CurTime()
    }
end)

hook.Add("PlayerDeath", "PAT_SpectatorAssist_RecordDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local selfInflicted = isConfirmedSelfInflicted(victim)
    if selfInflicted then
        attacker = victim
    else
        attacker = resolveAttacker(victim, attacker)
    end

    local entry = buildTimelineEntry(victim, inflictor, attacker, selfInflicted)

    table.insert(addon.Timeline, 1, entry)
    addon.TrimTimeline(addon.Timeline)

    net.Start("PAT_SpectatorTimelinePush")
        net.WriteTable(entry)
    net.Broadcast()

    if not IsValid(victim) or not victim:IsPlayer() then return end

    net.Start("PAT_SpectatorDeathRecap")
        net.WriteTable(buildDeathRecap(victim, inflictor, attacker, selfInflicted))
    net.Send(victim)
end)

hook.Add("PlayerDeathThink", "PAT_SpectatorAssist_VitalsSync", function(ply)
    if not IsValid(ply) or ply:Alive() then return end
    if not hg or not hg.send_organism then return end

    local target = ply.chosenSpectEntity or ply:GetNWEntity("spect")
    if not IsValid(target) or not target.organism then return end

    if (ply.patSpectatorAssistNextVitals or 0) >= CurTime() then return end
    ply.patSpectatorAssistNextVitals = CurTime() + 1

    hg.send_organism(target.organism, ply)
end)
