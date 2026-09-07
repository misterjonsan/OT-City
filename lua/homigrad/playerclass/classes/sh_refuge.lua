local CLASS = player.RegClass("Refugee")

local combines = {
    "npc_combine_s",
    "npc_metropolice",
    "npc_helicopter",
    "npc_combinegunship",
    "npc_combine",
    "npc_stalker",
    "npc_hunter",
    "npc_strider",
    "npc_turret_floor",
    "npc_manhack",
    "npc_cscanner",
    "npc_clawscanner"
}

local rebels = {
    "npc_barney",
    "npc_citizen",
    "npc_dog",
    "npc_eli",
    "npc_kleiner",
    "npc_magnusson",
    "npc_monk",
    "npc_mossman",
    "npc_odessa",
    "npc_rollermine_hacked",
    "npc_turret_floor_resistance",
    "npc_vortigaunt",
    "npc_alyx"
}

local rebel_models = {
    "models/player/Group03/male_01.mdl",
    "models/player/Group03/male_02.mdl",
    "models/player/Group03/male_03.mdl",
    "models/player/Group03/male_04.mdl",
    "models/player/Group03/male_05.mdl",
    "models/player/Group03/male_06.mdl",
    "models/player/Group03/male_07.mdl",
    "models/player/Group03/male_08.mdl",
    "models/player/Group03/male_09.mdl",
    "models/player/Group03/female_01.mdl",
    "models/player/Group03/female_02.mdl",
    "models/player/Group03/female_03.mdl",
    "models/player/Group03/female_04.mdl",
    "models/player/Group03/female_05.mdl",
    "models/player/Group03/female_06.mdl"
}

local medic_models = {
    "models/player/Group03m/male_01.mdl",
    "models/player/Group03m/male_02.mdl",
    "models/player/Group03m/male_03.mdl",
    "models/player/Group03m/male_04.mdl",
    "models/player/Group03m/male_05.mdl",
    "models/player/Group03m/male_06.mdl",
    "models/player/Group03m/male_07.mdl",
    "models/player/Group03m/male_08.mdl",
    "models/player/Group03m/male_09.mdl",
    "models/player/Group03m/female_01.mdl",
    "models/player/Group03m/female_02.mdl",
    "models/player/Group03m/female_03.mdl",
    "models/player/Group03m/female_04.mdl",
    "models/player/Group03m/female_05.mdl",
    "models/player/Group03m/female_06.mdl"
}

local helmet = {
    "helmet5",
    "",
    ""
}

local face = {
    "",
    "",
    "",
    "",
    ""
}

local vest = {
    "vest2",
    "",
    ""
}

local primary = {
    "weapon_doublebarrel",
    "weapon_mp5",
    "weapon_mp7",
    "weapon_sks",
    "weapon_vpo136",
    "weapon_winchester"
}

local secondary = {
    "weapon_m9beretta",
    "weapon_browninghp",
    "weapon_revolver357",
    "weapon_revolver2",
    "weapon_hk_usp",
    "weapon_glock17"
}

local function IsFemaleModel(mdl)
    mdl = string.lower(mdl or "")
    return string.find(mdl, "female", 1, true) ~= nil
end

function CLASS.Off(self)
    if CLIENT then return end

    for _, v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(rebels, v:GetClass()) then
            v:AddEntityRelationship(self, D_HT, 99)
        elseif table.HasValue(combines, v:GetClass()) then
            v:AddEntityRelationship(self, D_LI, 0)
        end
    end

    hook.Remove("OnEntityCreated", "refugee_relation_ship" .. self:EntIndex())
end

CLASS.CanUseDefaultPhrase = true

function CLASS.GiveEquipment(self, class)
    local currentRound = CurrentRound and CurrentRound()
    if currentRound and currentRound.name == "defense" then
        return
    end

    self:StripWeapons()
    self:StripAmmo()

    local wep1 = self:Give(primary[math.random(#primary)])
    if IsValid(wep1) and wep1.GetMaxClip1 then
        self:GiveAmmo(wep1:GetMaxClip1() * 2, wep1:GetPrimaryAmmoType(), true)
    end

    local wep2 = self:Give(secondary[math.random(#secondary)])
    if IsValid(wep2) and wep2.GetMaxClip1 then
        self:GiveAmmo(wep2:GetMaxClip1() * 2, wep2:GetPrimaryAmmoType(), true)
    end

    self.armors = self.armors or {}
    self.armors["torso"] = nil
    self.armors["head"] = nil
    self.armors["face"] = nil

    local vesta = vest[math.random(#vest)]
    local facea = face[math.random(#face)]
    local helmeta = helmet[math.random(#helmet)]

    if vesta ~= "" then self.armors["torso"] = vesta end
    if helmeta ~= "" then self.armors["head"] = helmeta end
    if facea ~= "" then self.armors["face"] = facea end

    self:SyncArmor()

    self:Give("weapon_melee")
    self:Give("weapon_walkie_talkie")
    self:Give("weapon_hands_sh")

    if class == "medic" then
        self:Give("weapon_bandage_sh")
        self:Give("weapon_medkit_sh")
        self:Give("weapon_painkillers")
        self:Give("weapon_tourniquet")
    end
end

function CLASS.On(self, data)
    if CLIENT then return end

    local mdl
    if self.subClass == "medic" then
        mdl = medic_models[math.random(#medic_models)]
    else
        mdl = rebel_models[math.random(#rebel_models)]
    end

    self.CurAppearance = nil
    self:SetNetVar("Accessories", "")
    self:SetSubMaterial()
    self:SetSkin(0)

    if mdl and mdl ~= "" then
        self:SetModel(mdl)
    end

    local slots = self:GetSubMaterialSlots() or {}
    local mat = IsFemaleModel(self:GetModel()) and "models/humans/female/group02/citizen_sheet" or "models/humans/male/group02/citizen_sheet"

    for _, v in ipairs(slots) do
        self:SetSubMaterial(v, mat)
    end

    self:SetPlayerColor(Color(0, 60, 10):ToVector())

    for _, v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(rebels, v:GetClass()) then
            v:AddEntityRelationship(self, D_LI, 0)
            v:ClearEnemyMemory()
        elseif table.HasValue(combines, v:GetClass()) then
            v:AddEntityRelationship(self, D_HT, 99)
            v:ClearEnemyMemory()
        end
    end

    local index = self:EntIndex()
    hook.Remove("OnEntityCreated", "refugee_relation_ship" .. index)
    hook.Add("OnEntityCreated", "refugee_relation_ship" .. index, function(ent)
        if not IsValid(self) then
            hook.Remove("OnEntityCreated", "refugee_relation_ship" .. index)
            return
        end

        if ent:IsNPC() then
            if table.HasValue(rebels, ent:GetClass()) then
                ent:AddEntityRelationship(self, D_LI, 0)
            end

            if table.HasValue(combines, ent:GetClass()) then
                ent:AddEntityRelationship(self, D_HT, 99)
            end
        end
    end)

    self.subClass = nil
end

function CLASS.Guilt(self, victim)
    if CLIENT then return end
    if victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end
end

return CLASS