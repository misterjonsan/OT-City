util.AddNetworkString("Infection_PhaseUpdate")
util.AddNetworkString("Infection_Activated")
util.AddNetworkString("Infection_Cleared")
util.AddNetworkString("Infection_HeadExplosion")
util.AddNetworkString("Infection_BoomKillAdd")

local HEAD_BOOM_DELAY = 180  
local MAX_BOOM_TIME   = 180  
local KILL_ADD        = 15   

local PHASE_DURATION = { [1]=15, [2]=15, [3]=15, [4]=15 }

local COUGH_SOUNDS = {
    "npc/headcrab_poison/ph_cough1.wav",
    "npc/headcrab_poison/ph_cough2.wav",
    "npc/headcrab_poison/ph_cough3.wav",
}

local function SendPhase(ply, phase)
    net.Start("Infection_PhaseUpdate")
        net.WriteUInt(phase, 4)
    net.Send(ply)
end

local function DoCough(ply)
    if not IsValid(ply) then return end
    local snd  = COUGH_SOUNDS[math.random(#COUGH_SOUNDS)]
    local char = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    char:EmitSound(snd, 75, math.random(85, 105))
end

local function ResolvePlayer(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end
    
    if ent:IsRagdoll() then
        local owner = ent.ply
        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end
        if hg and hg.RagdollOwner then
            local hgOwner = hg.RagdollOwner(ent)
            if IsValid(hgOwner) and hgOwner:IsPlayer() then
                return hgOwner
            end
        end
    end

    if ent.GetOwner and IsValid(ent:GetOwner()) then
        local owner = ent:GetOwner()
        if owner:IsPlayer() then return owner end
        if owner:IsRagdoll() then return ResolvePlayer(owner) end
    end
    
    if ent.ply and IsValid(ent.ply) and ent.ply:IsPlayer() then
        return ent.ply
    end

    return nil
end

function Infection_ResetBoomTimer(ply)
    if not IsValid(ply) then return end
    local expiry = CurTime() + HEAD_BOOM_DELAY
    ply:SetNWFloat("inf_boom_expiry", expiry)
    timer.Create("Infection_HeadBoom_" .. ply:UserID(), HEAD_BOOM_DELAY, 1, function()
        Infection_DoHeadExplosion(ply)
    end)
end

function Infection_AddBoomTime(ply, seconds)
    if not IsValid(ply) then return end
    local id           = ply:UserID()
    local expiry       = ply:GetNWFloat("inf_boom_expiry", CurTime())
    local remaining    = math.max(0, expiry - CurTime())
    local newRemaining = math.min(remaining + seconds, MAX_BOOM_TIME)
    local newExpiry    = CurTime() + newRemaining

    ply:SetNWFloat("inf_boom_expiry", newExpiry)
    timer.Create("Infection_HeadBoom_" .. id, newRemaining, 1, function()
        Infection_DoHeadExplosion(ply)
    end)

    net.Start("Infection_BoomKillAdd")
        net.WriteFloat(seconds)
    net.Send(ply)
end

function Infection_DoHeadExplosion(ply)
    if not IsValid(ply) then return end
    if not ply:Alive() then return end
    if (ply.infection_phase or 0) ~= 5 then return end

    local pos     = ply:GetPos() + Vector(0, 0, 64)
    local ragdoll = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    local attID   = ragdoll:LookupAttachment("eyes")
    if attID and attID > 0 then
        local att = ragdoll:GetAttachment(attID)
        if att then pos = att.Pos end
    end

    net.Start("Infection_HeadExplosion")
        net.WriteVector(pos)
    net.Broadcast()

    ply:EmitSound("physics/flesh/flesh_bloody_break.wav", 100, 80)
    ply:Kill()
    Infection_Clear(ply)
end

local function DoInfected(ply)
    if not IsValid(ply) then return end
    local org = ply.organism
    if org then org.superfighter = true end

    net.Start("Infection_Activated")
    net.Send(ply)

    ply:Notify("KILL THEM ALL....", nil, nil, 5, nil, Color(220, 0, 0))

    if not IsValid(ply.FakeRagdoll) and ply:Alive() then
        hg.Fake(ply, nil, false, true)
    end

    local char = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    char:EmitSound("infection/infected_ragdoll.wav", 75, 100, 1, CHAN_AUTO)

    Infection_ResetBoomTimer(ply)
end

function Infection_Begin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply.infection_phase = 1
    SendPhase(ply, 1)

    timer.Create("Infection_Phase2_" .. ply:UserID(), PHASE_DURATION[1], 1, function()
        if not IsValid(ply) or ply.infection_phase ~= 1 then return end
        ply.infection_phase = 2
        SendPhase(ply, 2)

        timer.Create("Infection_Cough_" .. ply:UserID(), 4, 0, function()
            if not IsValid(ply) or ply.infection_phase ~= 2 then
                timer.Remove("Infection_Cough_" .. ply:UserID()) return
            end
            DoCough(ply)
        end)
        DoCough(ply)

        timer.Create("Infection_Phase3_" .. ply:UserID(), PHASE_DURATION[2], 1, function()
            if not IsValid(ply) then return end
            timer.Remove("Infection_Cough_" .. ply:UserID())
            ply.infection_phase = 3
            SendPhase(ply, 3)

            timer.Create("Infection_Phase4_" .. ply:UserID(), PHASE_DURATION[3], 1, function()
                if not IsValid(ply) then return end
                ply.infection_phase = 4
                SendPhase(ply, 4)

                timer.Create("Infection_Final_" .. ply:UserID(), PHASE_DURATION[4], 1, function()
                    if not IsValid(ply) then return end
                    ply.infection_phase = 5
                    SendPhase(ply, 5)
                    SendPhase(ply, 5)
                    DoInfected(ply)
                end)
            end)
        end)
    end)
end

function Infection_Clear(ply)
    if not IsValid(ply) then return end
    local id = ply:UserID()
    ply.infection_phase = 0

    timer.Remove("Infection_Phase2_"   .. id)
    timer.Remove("Infection_Phase3_"   .. id)
    timer.Remove("Infection_Phase4_"   .. id)
    timer.Remove("Infection_Final_"    .. id)
    timer.Remove("Infection_Cough_"    .. id)
    timer.Remove("Infection_HeadBoom_" .. id)

    ply:SetNWFloat("inf_boom_expiry", 0)

    local org = ply.organism
    if org then org.superfighter = false end

    ply:SetNWBool("inf_eyes", false)

    net.Start("Infection_Cleared")
    net.Send(ply)
end

hook.Add("HomigradDamage", "Infection_TrackPlayerAttacker", function(victim_ent, dmgInfo)
    local attacker = ResolvePlayer(dmgInfo:GetAttacker())
    if not IsValid(attacker) or (attacker.infection_phase or 0) ~= 5 then return end

    local victim_ply = ResolvePlayer(victim_ent)
    if not IsValid(victim_ply) then return end
    if attacker == victim_ply then return end

    victim_ply.inf_last_attacker      = attacker
    victim_ply.inf_last_attacker_time = CurTime()
end)

hook.Add("EntityTakeDamage", "Infection_TrackNPCAttacker", function(npc, dmgInfo)
    if not npc:IsNPC() then return end
    local attacker = ResolvePlayer(dmgInfo:GetAttacker())
    if not IsValid(attacker) or (attacker.infection_phase or 0) ~= 5 then return end

    npc.inf_last_attacker      = attacker
    npc.inf_last_attacker_time = CurTime()
end)

hook.Add("PlayerDeath", "Infection_KillPlayerAdd", function(victim, inflictor, attacker_arg)
    local attacker = ResolvePlayer(attacker_arg)
    
    if not IsValid(attacker) then
        if IsValid(victim.inf_last_attacker)
        and victim.inf_last_attacker_time
        and (CurTime() - victim.inf_last_attacker_time) < 30 then
            attacker = victim.inf_last_attacker
        end
    end

    if not IsValid(attacker) or (attacker.infection_phase or 0) ~= 5 then return end
    if attacker == victim then return end

    Infection_AddBoomTime(attacker, KILL_ADD)
end)

hook.Add("OnNPCKilled", "Infection_KillNPCAdd", function(npc, attacker_arg, inflictor)
    local attacker = ResolvePlayer(attacker_arg)
    
    if not IsValid(attacker) then
        if IsValid(npc.inf_last_attacker)
        and npc.inf_last_attacker_time
        and (CurTime() - npc.inf_last_attacker_time) < 30 then
            attacker = npc.inf_last_attacker
        end
    end

    if not IsValid(attacker) or (attacker.infection_phase or 0) ~= 5 then return end

    Infection_AddBoomTime(attacker, KILL_ADD)
end)

hook.Add("PlayerDeath", "Infection_OnDeath", function(ply)
    if (ply.infection_phase or 0) > 0 then
        Infection_Clear(ply)
    end
end)

hook.Add("Org Clear", "Infection_OnOrgClear", function(org)
    local ply = org and org.owner
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.infection_phase or 0) > 0 then
        Infection_Clear(ply)
    end
end)

util.AddNetworkString("Infection_EyeGlow")
net.Receive("Infection_EyeGlow", function(len, ply)
    if not IsValid(ply) then return end
    ply:SetNWBool("inf_eyes", true)
end)