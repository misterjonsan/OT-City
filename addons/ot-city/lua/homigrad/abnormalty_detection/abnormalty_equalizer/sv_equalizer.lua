hg = hg or {}
hg.Abnormalties = hg.Abnormalties or {}
local PLUGIN = hg.Abnormalties

PLUGIN.ConjureEqualizer = PLUGIN.ConjureEqualizer or {}
PLUGIN.ConjureEqualizer.ToConjure = PLUGIN.ConjureEqualizer.ToConjure or {}

function PLUGIN.ConjureEqualizer.Do(ent, time, zone)
    PLUGIN.ConjureEqualizer.ToConjure[#PLUGIN.ConjureEqualizer.ToConjure + 1] = {
        Time = CurTime() + time,
        Zone = zone,
    }
end

local function TryConjureEqualizer(zone, ply)
    local equalizers_consumption = 400

    if PLUGIN.GetZoneOrPlyEqualizers(zone, ply) >= equalizers_consumption then
        PLUGIN.ShowMessageInSphere("Conjuring Equalizer...", zone.Pos, zone.Radius)
        PLUGIN.ConjureEqualizer.Do(ent, 5, zone)
        PLUGIN.RemoveZoneOrPlyEqualizers(zone, ply, equalizers_consumption)
        PLUGIN.AddConsequencesToZoneChanters(zone, 3)
        PLUGIN.AddConsequences(ply, 50)
    else
        PLUGIN.ShowMessage(ply, "There is not enough equalizers in order to conjure Equalizer")
    end
end

hook.Add("Abnormalties_HotZoneAbnormaltyAdded", "Abnormalties_ConjureEqualizer", function(zone_id, abnormalty_name, amt, ply)
    local zone = PLUGIN.Zones[zone_id]
    if not zone then return end

    if PLUGIN.GetZoneAbnormalty(zone, "shield") >= 20 and PLUGIN.GetZoneAbnormalty(zone, "ritual") >= 10 and PLUGIN.GetZoneAbnormalty(zone, "help") >= 10 and amt > 0 then
        local clear_cd = 10

        if not zone.Vars.RitualPhrasesAmtClearTime then
            zone.Vars.RitualPhrasesAmtClearTime = CurTime() + clear_cd
        end

        if zone.Vars.RitualPhrasesAmtClearTime <= CurTime() then
            PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
            zone.Vars.RitualPhrasesAmtClearTime = nil
        end

        if PLUGIN.CompareZonePhrasesToPattern(zone, { { "shield", 5 }, { "help", 2 }, { "sacrifice", 2 } }, 5) then
            TryConjureEqualizer(zone, ply)
            PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
            zone.Vars.RitualPhrasesAmtClearTime = nil
        end
    end
end)

hook.Add("Think", "Abnormalties_ConjureEqualizer", function()
    for id, info in pairs(PLUGIN.ConjureEqualizer.ToConjure) do
        if info.Time <= CurTime() then
            if info.Zone then
                local new_ent = ents.Create("ent_armor_ego_equalizer")
                if IsValid(new_ent) then
                    new_ent:SetPos(info.Zone.Pos + Vector(0, 0, 30))
                    new_ent:Spawn()
                    new_ent:Activate()
                end
            end
            PLUGIN.ConjureEqualizer.ToConjure[id] = nil
        end
    end
end)

hook.Add("PostCleanupMap", "Abnormalties_ConjureEqualizer", function()
    PLUGIN.ConjureEqualizer.ToConjure = {}
end)

hook.Add("PlayerPostThink", "Abnormalties_ConjureEqualizer", function(ply)
    if PLUGIN.FunMode then return end
    if ply.armors and ply:Alive() then
        if ply.armors["torso"] == "ego_equalizer" then
            if ply.Karma and ply.Karma < zb.MaxKarma then
                ply:Kill()
                PLUGIN.ShowMessage(ply, "You received your punishment")
            end
        end
    end
end)

hook.Add("CanEquipArmor", "Abnormalties_ConjureEqualizer", function(ply, armor_name)
    if PLUGIN.FunMode then return end
    if armor_name == "ego_equalizer" then
        if ply.Karma and ply.Karma < zb.MaxKarma then
            PLUGIN.ShowMessage(ply, "It seems that I'm unworthy")
            return false
        end
    end
end)

if SERVER and sam then
    sam.command.new("abn_funmode")
        :SetPermission("abnormalties.funmode", "admin")
        :AddArg("bool")
        :Help("Toggle Abnormalties FunMode")
        :OnExecute(function(ply, state)
            PLUGIN.FunMode = state and true or false
            sam.player.send_message(nil, "{A} set FunMode to {V}", { A = ply, V = tostring(PLUGIN.FunMode) })
        end)
    :End()

    sam.command.new("abn_give_equalizer_all")
        :SetPermission("abnormalties.giveequalizer", "admin")
        :Help("Give ego_equalizer to all players (FunMode enabled automatically)")
        :OnExecute(function(ply)
            PLUGIN.FunMode = true
            for _, v in ipairs(player.GetAll()) do
                if IsValid(v) then
                    if hg.AddArmor then
                        hg.AddArmor(v, "ego_equalizer")
                    end
                end
            end
            sam.player.send_message(nil, "{A} gave ego_equalizer to everyone", { A = ply })
        end)
    :End()

    sam.command.new("abn_give_musket_all")
        :SetPermission("abnormalties.givemusket", "admin")
        :Help("Give weapon_bleeding_musket to all players and set Abnormalties_Blood (FunMode enabled automatically)")
        :OnExecute(function(ply)
            PLUGIN.FunMode = true
            for _, v in ipairs(player.GetAll()) do
                if IsValid(v) then
                    v:Give("weapon_bleeding_musket")
                    v.Abnormalties_Blood = 1000000
                end
            end
            sam.player.send_message(nil, "{A} gave bleeding musket to everyone", { A = ply })
        end)
    :End()
end