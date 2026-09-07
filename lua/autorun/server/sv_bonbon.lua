-- Server controller for the Bonbon horror screen.

if not SERVER then return end

AddCSLuaFile("autorun/client/cl_bonbon.lua")
util.AddNetworkString("ZCityBonbonStart")

local BONBON_DURATION = 60
local BONBON_RETURN_DURATION = 8

local function findPlayerByUserID(value)
    local userID = tonumber(value)
    if not userID then return end

    for _, target in player.Iterator() do
        if target:UserID() == userID then return target end
    end
end

local function aimedPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local trace = ply:GetEyeTrace()
    if IsValid(trace.Entity) and trace.Entity:IsPlayer() then return trace.Entity end
end

local function sendBonbon(target, duration, mode, fakeIP)
    if not IsValid(target) or not target:IsPlayer() then return end

    net.Start("ZCityBonbonStart")
        net.WriteFloat(duration)
        net.WriteUInt(mode or 0, 2)
        net.WriteString(fakeIP or "")
    net.Send(target)
end

local function startBonbon(target)
    if not IsValid(target) or not target:IsPlayer() then return end
    sendBonbon(target, BONBON_DURATION, 0)

    local timerName = "ZCityBonbonReturn_" .. target:SteamID64()
    timer.Create(timerName, BONBON_DURATION + math.random(60, 180), 1, function()
        if not IsValid(target) or not target:IsPlayer() then return end
        local fakeIP = "203.0.113." .. math.random(2, 254)
        sendBonbon(target, BONBON_RETURN_DURATION, 1, fakeIP)
    end)
end

-- Starts on the player under the caller's crosshair; falls back to the caller.
concommand.Add("zb_sesh_bonbon", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    startBonbon(aimedPlayer(ply) or ply)
end)

concommand.Add("zb_sesh_bonbon_id", function(ply, _, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    startBonbon(findPlayerByUserID(args[1]))
end)
