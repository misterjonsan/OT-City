MODE.name = "riot"
MODE.PrintName = "Пизделка фанатов навального"

MODE.OverideSpawnPos = true
MODE.LootSpawn = false
MODE.ForBigMaps = false
MODE.Chance = 0.08

local riotWeapons = {
    "weapon_leadpipe",
    "weapon_brick",
    "weapon_hammer",
    "weapon_pocketknife",
    "weapon_pan",
    "weapon_hg_shovel",
    "weapon_bat"
}

local riotConsumables = {
    "weapon_bigconsumable",
    "weapon_smallconsumable",
    "weapon_ducttape",
    "weapon_matches",
    "weapon_bandage_sh",
    "weapon_hg_smokenade_tpik",
    "weapon_hg_shuriken"
}

local riotArmorChance = 40

local lawWeapons = {
    "weapon_hg_tonfa",
    "weapon_taser",
    "weapon_walkie_talkie",
    "weapon_handcuffs",
    "weapon_handcuffs_key"
}

local lawArmor = {
    "ent_armor_vest2",
    "ent_armor_helmet3"
}

local sledcomWeapons = {
    { "weapon_m4a1", { "holo15", "grip3", "laser4" } },
    { "weapon_hk416", { "holo15", "grip3", "laser4" } },
    { "weapon_mp7", { "holo14" } },
    { "weapon_m4a1", { "optic2", "grip3", "supressor7" } }
}

local sledcomOtherItems = {
    "weapon_medkit_sh",
    "weapon_tourniquet",
    "weapon_walkie_talkie",
    "weapon_melee",
    "weapon_handcuffs",
    "weapon_handcuffs_key",
    "weapon_hg_flashbang_tpik"
}

local sledcomArmor = {
    { "ent_armor_vest8", "ent_armor_helmet6" }
}

local sledcomSpawned = false

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

util.AddNetworkString("riot_start")
util.AddNetworkString("riot_roundend")
util.AddNetworkString("riot_swat_spawn")

function MODE:Intermission()
    game.CleanUpMap()

    self.RiotPoints = {}
    table.CopyFromTo(zb.GetMapPoints("RIOT_TDM_RIOTERS"), self.RiotPoints)

    self.LawPoints = {}
    table.CopyFromTo(zb.GetMapPoints("RIOT_TDM_LAW"), self.LawPoints)

    local lawPos
    local riotPos

    for i, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        local pos

        if ply:Team() == 1 then
            if not lawPos then
                lawPos = #self.LawPoints > 0 and self.LawPoints[1].pos or zb:GetRandomSpawn()
                pos = lawPos
            else
                pos = hg.tpPlayer(lawPos, ply, i, 0)
            end
        end

        if ply:Team() == 0 then
            if not riotPos then
                riotPos = #self.RiotPoints > 0 and self.RiotPoints[1].pos or zb:GetRandomSpawn()
                pos = riotPos
            else
                pos = hg.tpPlayer(riotPos, ply, i, 0)
            end
        end

        ply:SetupTeam(ply:Team())

        if pos then
            ply:SetPos(pos)
        end
    end

    net.Start("riot_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    local lawSide = {}
    local rioters = {}

    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end
        if ply:GetNetVar("handcuffed", false) then continue end
        if ply.organism and ply.organism.incapacitated then continue end

        if ply:Team() == 0 then
            table.insert(rioters, ply)
        elseif ply:Team() == 1 or ply:Team() == 2 then
            table.insert(lawSide, ply)
        end
    end

    return { rioters, lawSide }
end

function MODE:EndRound()
    timer.Simple(2, function()
        net.Start("riot_roundend")
        net.Broadcast()
    end)
end

function MODE:ShouldRoundEnd()
    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end

function MODE:RoundStart()
    sledcomSpawned = false
end

function MODE:GiveEquipment()
    local players = {}

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        table.insert(players, ply)
    end

    table.Shuffle(players)

    local numPlayers = #players
    local numLawEnforcers = math.max(math.floor(numPlayers / 2) - 1, 1)
    local numRioters = numPlayers - numLawEnforcers

    local molotovCount = 0
    local hasMp80 = false

    for i = 1, numRioters do
        local ply = players[i]
        if not IsValid(ply) then continue end

        ply:SetTeam(0)
        ply:SetupTeam(0)
        ply:SetPlayerClass("terrorist")

        zb.GiveRole(ply, "Протестующий", Color(190, 0, 0))

        ply:Give("weapon_hands_sh")

        if molotovCount < 1 then
            ply:Give("weapon_hg_molotov_tpik")
            molotovCount = molotovCount + 1
        elseif not hasMp80 then
            ply:Give("weapon_mp-80")
            hasMp80 = true
        end

        ply:SetNetVar("CurPluv", "pluvmajima")
        ply:Give(riotConsumables[math.random(#riotConsumables)])

        if math.random(100) <= riotArmorChance then
            hg.AddArmor(ply, "ent_armor_helmet2")
        end

        local riotWeapon = riotWeapons[math.random(#riotWeapons)]
        local wep = ply:Give(riotWeapon)

        if IsValid(wep) then
            ply:SelectWeapon(wep:GetClass())
        end
    end

    for i = numRioters + 1, numPlayers do
        local ply = players[i]
        if not IsValid(ply) then continue end

        ply:SetTeam(1)
        ply:SetupTeam(1)
        ply:SetPlayerClass("police")

        zb.GiveRole(ply, "Вершитель правосудия", Color(0, 0, 190))

        local inv = ply:GetNetVar("Inventory", {})
        inv["Weapons"] = inv["Weapons"] or {}
        inv["Weapons"]["hg_sling"] = true
        ply:SetNetVar("Inventory", inv)

        local hands = ply:Give("weapon_hands_sh")
        if IsValid(hands) then
            ply:SelectWeapon(hands:GetClass())
        end

        for _, wepName in ipairs(lawWeapons) do
            ply:Give(wepName)
        end

        ply:SetNetVar("CurPluv", "pluvberet")

        hg.AddArmor(ply, "ent_armor_helmet3")
        hg.AddArmor(ply, "ent_armor_vest2")

        if i == numRioters + 1 then
            ply:Give("weapon_ram")
        elseif i == numRioters + 2 then
            local wep = ply:Give("weapon_remington870")

            timer.Simple(1, function()
                if IsValid(wep) then
                    wep:SetRandomBodygroups("000010302")
                    wep:ApplyAmmoChanges(2)
                end
            end)
        end

        ply:SelectWeapon("weapon_hg_tonfa")
    end
end

function MODE:GetTeamSpawn()
    return zb.TranslatePointsToVectors(zb.GetMapPoints("RIOT_TDM_RIOTERS")), zb.TranslatePointsToVectors(zb.GetMapPoints("RIOT_TDM_LAW"))
end

function MODE:RoundThink()
    if sledcomSpawned then return end
    if (CurTime() - (zb.ROUND_BEGIN or CurTime())) < 240 then return end

    local deadPlayers = {}

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply:Alive() then continue end
        table.insert(deadPlayers, ply)
    end

    if #deadPlayers <= 0 then
        sledcomSpawned = true
        return
    end

    local spawnPoints = self.LawPoints or zb.GetMapPoints("RIOT_TDM_LAW")
    local startPos = spawnPoints and spawnPoints[1] and spawnPoints[1].pos or zb:GetRandomSpawn()

    for i = 1, math.min(4, #deadPlayers) do
        local ply = deadPlayers[i]
        if not IsValid(ply) then continue end

        ply:Spawn()
        ply:SetTeam(2)
        ply:SetupTeam(2)
        ply:SetPlayerClass("sledcom")

        if startPos then
            if i == 1 then
                ply:SetPos(startPos)
            else
                hg.tpPlayer(startPos, ply, i, 0)
            end
        end

        local inv = ply:GetNetVar("Inventory", {})
        inv["Weapons"] = inv["Weapons"] or {}
        inv["Weapons"]["hg_sling"] = true
        ply:SetNetVar("Inventory", inv)

        zb.GiveRole(ply, "Следственный комитет", Color(120, 120, 255))

        local armor = sledcomArmor[math.random(#sledcomArmor)]
        for _, armorEnt in ipairs(armor) do
            hg.AddArmor(ply, armorEnt)
        end

        local primary = sledcomWeapons[math.random(#sledcomWeapons)]
        local gun = ply:Give(primary[1])
        if IsValid(gun) and gun.GetMaxClip1 then
            hg.AddAttachmentForce(ply, gun, primary[2])
            ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
        end

        local pistol = ply:Give("weapon_glock17")
        if IsValid(pistol) and pistol.GetMaxClip1 then
            ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
        end

        for _, item in ipairs(sledcomOtherItems) do
            ply:Give(item)
        end

        local hands = ply:Give("weapon_hands_sh")
        if IsValid(hands) then
            ply:SelectWeapon(hands:GetClass())
        end
    end

    net.Start("riot_swat_spawn")
    net.Broadcast()

    sledcomSpawned = true
end

function MODE:CanLaunch()
    local activePlayers = 0

    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            activePlayers = activePlayers + 1
        end
    end

    if activePlayers < 5 then
        return false
    end

    local pointsRioters = zb.GetMapPoints("RIOT_TDM_RIOTERS")
    local pointsLaw = zb.GetMapPoints("RIOT_TDM_LAW")
    return (#pointsRioters > 0) and (#pointsLaw > 0)
end

return MODE