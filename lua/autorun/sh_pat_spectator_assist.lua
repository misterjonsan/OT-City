PAT_SPECTATOR_ASSIST = PAT_SPECTATOR_ASSIST or {}

local addon = PAT_SPECTATOR_ASSIST

addon.MaxTimeline = addon.MaxTimeline or 14
addon.HitgroupNames = addon.HitgroupNames or {
    [HITGROUP_GENERIC] = "Универсальный",
    [HITGROUP_HEAD] = "Голова",
    [HITGROUP_CHEST] = "Грудь",
    [HITGROUP_STOMACH] = "Живот",
    [HITGROUP_LEFTARM] = "Левая рука",
    [HITGROUP_RIGHTARM] = "Правая рука",
    [HITGROUP_LEFTLEG] = "Левая нога",
    [HITGROUP_RIGHTLEG] = "Правая нога",
    [HITGROUP_GEAR] = "Броня"
}

function addon.FormatClock(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))

    local mins = math.floor(seconds / 60)
    local secs = seconds % 60

    return string.format("%02i:%02i", mins, secs)
end

function addon.PrettyClassName(className)
    className = tostring(className or "")

    if className == "" or className == "worldspawn" then
        return "world"
    end

    className = string.gsub(className, "^weapon_", "")
    className = string.gsub(className, "^ent_", "")
    className = string.gsub(className, "^obj_", "")
    className = string.gsub(className, "^npc_", "")
    className = string.gsub(className, "_", " ")

    return string.Trim(className)
end

function addon.TrimTimeline(tbl)
    while #tbl > addon.MaxTimeline do
        table.remove(tbl)
    end
end

function addon.GetRoundLabel()
    local round = CurrentRound and CurrentRound()
    if round then
        return round.PrintName or round.name or "Unknown"
    end

    return GAMEMODE and (GAMEMODE.PrintName or GAMEMODE.Name) or "Unknown"
end

function addon.GetTimeLeft()
    local roundStart = zb and zb.ROUND_START or CurTime()
    local roundTime = zb and zb.ROUND_TIME or 0
    return math.max((roundStart + roundTime) - CurTime(), 0)
end

function addon.GetTimeElapsed()
    local roundTime = zb and zb.ROUND_TIME or 0
    return math.max(roundTime - addon.GetTimeLeft(), 0)
end

function addon.GetEntityId(ent)
    if not IsValid(ent) then return nil end
    return ent:IsPlayer() and ent:SteamID() or ent:EntIndex()
end

function addon.GetEntityLabel(ent, fallback)
    if not IsValid(ent) then return fallback or "Unknown" end

    if ent:IsPlayer() then
        return ent:Name()
    end

    if ent.PrintName and ent.PrintName ~= "" then
        return ent.PrintName
    end

    return addon.PrettyClassName(ent:GetClass())
end

if SERVER then
    AddCSLuaFile()
end
