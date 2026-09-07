hg = hg or {}
hg.Abnormalties = hg.Abnormalties or {}
local PLUGIN = hg.Abnormalties

PLUGIN.Invisibility = PLUGIN.Invisibility or {}
PLUGIN.Invisibility.ToInvis = PLUGIN.Invisibility.ToInvis or {}

local function recursive_set_prevent_transmit(ent, ply, stop_transmitting)
    if IsValid(ent) then
        ent:SetPreventTransmit(ply, stop_transmitting)
        local tab = ent:GetChildren()
        for i = 1, #tab do
            recursive_set_prevent_transmit(tab[i], ply, stop_transmitting)
        end
    end
end

function PLUGIN.Invisibility.Invis(owner, time)
    PLUGIN.Invisibility.ToInvis[owner] = {
        Owner = owner,
        Time = CurTime() + time,
    }
end

local function TryInvis(zone, ply)
    local consumption = 50

    if PLUGIN.GetZoneOrPlyEqualizers(zone, ply) >= consumption then
        local owner = PLUGIN.FindPlyInZone(zone, ply, 2, function(ent)
            return not ent.Abnormalties_InvisibleNextFadeTime
        end)

        if owner and not PLUGIN.Invisibility.ToInvis[owner] then
            PLUGIN.ShowMessageInSphere("Disabling cogito communication for " .. owner:GetNWString("PlayerName") .. "...", zone.Pos, zone.Radius)
            PLUGIN.Invisibility.Invis(owner, 5)
            PLUGIN.RemoveZoneOrPlyEqualizers(zone, ply, consumption)
            PLUGIN.AddConsequencesToZoneChanters(zone, 2)
            PLUGIN.AddConsequences(ply, 20)
        else
            PLUGIN.ShowMessage(ply, "There are no players within the zone")
        end
    else
        PLUGIN.ShowMessage(ply, "There is not enough equalizers in order to make someone invisible")
    end
end

function PLUGIN.Invisibility.UpdateInvisiblity(ply)
    ply.Abnormalties_InvisibleVisors = ply.Abnormalties_InvisibleVisors or {}
    local recipients = RecipientFilter()

    for other_ply in pairs(ply.Abnormalties_InvisibleVisors) do
        if IsValid(other_ply) then
            recipients:AddPlayer(other_ply)
        end
    end

    if IsValid(ply.FakeRagdoll) then
        recursive_set_prevent_transmit(ply.FakeRagdoll, recipients, false)

        local recipients_2 = RecipientFilter()
        recipients_2:AddAllPlayers()
        recipients_2:RemovePlayer(ply)

        for other_ply in pairs(ply.Abnormalties_InvisibleVisors) do
            if IsValid(other_ply) then
                recipients_2:RemovePlayer(other_ply)
            end
        end

        recursive_set_prevent_transmit(ply.FakeRagdoll, recipients_2, true)
    end

    recursive_set_prevent_transmit(ply, recipients, false)
end

function PLUGIN.Invisibility.SetInvisible(ply, state)
    ply.Abnormalties_InvisibleVisors = ply.Abnormalties_InvisibleVisors or {}
    local recipients = RecipientFilter()
    recipients:AddAllPlayers()

    if state then
        ply.Abnormalties_InvisibleVisors = {}
        recipients:RemovePlayer(ply)

        for other_ply in pairs(ply.Abnormalties_InvisibleVisors) do
            if IsValid(other_ply) then
                recipients:RemovePlayer(other_ply)
            end
        end
    else
        ply.Abnormalties_InvisibleNextFadeTime = nil
    end

    if IsValid(ply.FakeRagdoll) then
        recursive_set_prevent_transmit(ply.FakeRagdoll, recipients, state)
    end

    recursive_set_prevent_transmit(ply, recipients, state)
    ply.Abnormalties_Invisible = state
end

hook.Add("Abnormalties_HotZoneAbnormaltyAdded", "Abnormalties_Invisibility", function(zone_id, abnormalty_name, amt, ply)
    local zone = PLUGIN.Zones[zone_id]
    if not zone then return end

    if PLUGIN.GetZoneAbnormalty(zone, "shield") >= 10 and PLUGIN.GetZoneAbnormalty(zone, "help") >= 20 and amt > 0 then
        local clear_cd = 10

        if not zone.Vars.RitualPhrasesAmtClearTime then
            zone.Vars.RitualPhrasesAmtClearTime = CurTime() + clear_cd
        end

        if zone.Vars.RitualPhrasesAmtClearTime <= CurTime() then
            PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
            zone.Vars.RitualPhrasesAmtClearTime = nil
        end

        if PLUGIN.CompareZonePhrasesToPattern(zone, { { "shield", 10 } }, 5) then
            TryInvis(zone, ply)
            PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
            zone.Vars.RitualPhrasesAmtClearTime = nil
        end
    end
end)

hook.Add("Think", "Abnormalties_Invisibility", function()
    for ply, info in pairs(PLUGIN.Invisibility.ToInvis) do
        if info.Time <= CurTime() then
            local owner = info.Owner

            if IsValid(owner) and owner:Alive() then
                PLUGIN.Invisibility.SetInvisible(owner, true)
                owner.Abnormalties_InvisibleNextFadeTime = CurTime() + 45
                PLUGIN.ShowMessageToAllExcept("You forgot about someone... (for 45 seconds)", owner)
            else
                PLUGIN.ShowMessageToAll("Nothing happened")
            end

            PLUGIN.Invisibility.ToInvis[ply] = nil
        end
    end
end)

hook.Add("PlayerPostThink", "Abnormalties_Invisibility", function(ply)
    if ply.Abnormalties_InvisibleNextFadeTime and ply.Abnormalties_InvisibleNextFadeTime <= CurTime() then
        ply.Abnormalties_InvisibleNextFadeTime = nil
        PLUGIN.Invisibility.SetInvisible(ply, false)
        PLUGIN.ShowMessage(ply, "Your invisibility fades")
    end
end)

hook.Add("HomigradDamage", "Abnormalties_Invisibility", function(ply, dmg, hitgroup, ent, harm)
    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) then attacker = nil end

    if ply:IsPlayer() and dmg:GetDamage() > 5 and attacker and ply ~= attacker then
        if ply.Abnormalties_Invisible then
            PLUGIN.Invisibility.SetInvisible(ply, false)
            PLUGIN.ShowMessage(ply, "Your invisibility fades")
        end

        if attacker and attacker.Abnormalties_Invisible then
            PLUGIN.Invisibility.SetInvisible(attacker, false)
            PLUGIN.ShowMessage(attacker, "Your invisibility fades")
        end
    end
end)

hook.Add("Fake", "Abnormalties_Invisibility", function(ply, ragdoll, list_armor)
    if ply:IsPlayer() and ply.Abnormalties_Invisible then
        PLUGIN.Invisibility.UpdateInvisiblity(ply)
    end
end)

hook.Add("PlayerDeath", "Abnormalties_Invisibility", function(ply)
    if ply.Abnormalties_Invisible then
        PLUGIN.Invisibility.SetInvisible(ply, false)
    end
end)

hook.Add("Player Spawn", "Abnormalties_Invisibility", function(ply)
    PLUGIN.Invisibility.SetInvisible(ply, false)
end)

hook.Add("PostCleanupMap", "Abnormalties_Invisibility", function()
    PLUGIN.Invisibility.ToInvis = {}

    for _, ply in ipairs(player.GetAll()) do
        if ply.Abnormalties_Invisible then
            PLUGIN.Invisibility.SetInvisible(ply, false)
        end
    end
end)

if SERVER and sam then
    sam.command.new("abn_invis")
        :SetPermission("abnormalties.invis", "admin")
        :AddArg("player", { single_target = true })
        :AddArg("number", { optional = true, default = 45, min = 1, max = 600 })
        :Help("Make a player invisible for N seconds")
        :OnExecute(function(ply, target, secs)
            if not IsValid(target) then return end
            PLUGIN.Invisibility.SetInvisible(target, true)
            target.Abnormalties_InvisibleNextFadeTime = CurTime() + secs
            sam.player.send_message(nil, "{A} made {T} invisible for {V} seconds", { A = ply, T = target, V = secs })
        end)
    :End()

    sam.command.new("abn_uninvis")
        :SetPermission("abnormalties.invis", "admin")
        :AddArg("player", { single_target = true })
        :Help("Remove invisibility from a player")
        :OnExecute(function(ply, target)
            if not IsValid(target) then return end
            if target.Abnormalties_Invisible then
                PLUGIN.Invisibility.SetInvisible(target, false)
            end
            target.Abnormalties_InvisibleNextFadeTime = nil
            sam.player.send_message(nil, "{A} removed invisibility from {T}", { A = ply, T = target })
        end)
    :End()
end