local MODE = MODE

MODE.name = "as"
MODE.PrintName = "Кибербуллер"

MODE.LootSpawn = true
MODE.ForBigMaps = false
MODE.Chance = 0.04
MODE.AdminOnly = false
MODE.GuiltDisabled = true

MODE.ROUND_TIME = 1700

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

MODE.LootTable = {
	{100, {
		{10,"weapon_ducttape"},
		{10,"weapon_matches"},
		{10,"weapon_zippo_tpik"},
		{10,"weapon_bigconsumable"},
		{10,"weapon_smallconsumable"},
		{8,"weapon_painkillers"},
		{8,"weapon_bandage_sh"},
		{5,"weapon_medkit_sh"},
		{5,"weapon_sogknife"},
		{5,"weapon_pocketknife"},
		{5,"weapon_bat"},
		{5,"weapon_hammer"},
		{3,"weapon_glock26"},
		{5,"weapon_hg_bottle"},
	}}
}


local swatSpawned = false

local swat_weps = {
	{ "weapon_m4a1", { "holo15", "grip3", "laser4" } },
	{ "weapon_hk416", { "holo15", "grip3", "laser4" } },
	{ "weapon_p90", {} },
	{ "weapon_mp7", { "holo14" } },
	{ "weapon_m4a1", { "optic2", "grip3", "supressor7" } }
}

local swat_otheritems = {
	"weapon_medkit_sh",
	"weapon_tourniquet",
	"weapon_walkie_talkie",
	"weapon_melee",
	"weapon_handcuffs",
	"weapon_hg_flashbang_tpik"
}

local swat_armors = {
	{ "ent_armor_vest8", "ent_armor_helmet6" }
}

function MODE:GetActivePlayerCount()
	local count = 0

	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			count = count + 1
		end
	end

	return count
end

function MODE:GetShooterCount(playerCount)
	playerCount = playerCount or self:GetActivePlayerCount()
	return math.Clamp(math.Round(playerCount / 7), 1, 4)
end

function MODE:AssignTeams()
	local players = {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		table.insert(players, ply)
	end

	table.Shuffle(players)

	self.Shooters = {}

	local shooterCount = self:GetShooterCount(#players)

	for i, ply in ipairs(players) do
		if i <= shooterCount then
			ply:SetTeam(0)
			table.insert(self.Shooters, ply)
		else
			ply:SetTeam(1)
		end
	end

	self.Shooter = self.Shooters[1]
end

util.AddNetworkString("as_start")
util.AddNetworkString("as_roundend")
util.AddNetworkString("as_swat_spawn")

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()

	self:AssignTeams()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or ply:Team() == 0 then
			ply:KillSilent()
			continue
		end

		ply:SetupTeam(ply:Team())
	end

	net.Start("as_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	local activeShooters = {}
	local civilians = {}

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		if ply:Team() == 0 then
			table.insert(activeShooters, ply)
		elseif ply:Team() == 1 then
			table.insert(civilians, ply)
		end
	end

	return { activeShooters, civilians }
end

function MODE:ShouldRoundEnd()
	if zb.ROUND_START + 56 > CurTime() then return end

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	return endround
end

function MODE:EndRound()
	for _, ply in player.Iterator() do
		if timer.Exists("AS_ShooterSpawn" .. ply:EntIndex()) then
			timer.Remove("AS_ShooterSpawn" .. ply:EntIndex())
		end
	end

	local endround, winnerIndex = zb:CheckWinner(self:CheckAlivePlayers())

	local winningTeam = 2
	if winnerIndex == 1 then
		winningTeam = 0
	elseif winnerIndex == 2 then
		winningTeam = 1
	end

	timer.Simple(2, function()
		net.Start("as_roundend")
		net.WriteUInt(winningTeam, 8)
		net.Broadcast()
	end)
end

function MODE:RoundStart()
	swatSpawned = false

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:Freeze(false)
	end
end

function MODE:GetTeamSpawn()
	self.ShooterSpawns = self.ShooterSpawns or zb.TranslatePointsToVectors(zb.GetMapPoints("AS_SHOOTER_SPAWN"))

	local defaultSpawn = zb:GetRandomSpawn()

	return self.ShooterSpawns, { defaultSpawn }
end

function MODE:GiveEquipment()
	timer.Simple(0.5, function()
		self.ShooterSpawned = false

		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			if ply:Team() == 0 then
				local entIndex = ply:EntIndex()

				timer.Create("AS_ShooterSpawn" .. entIndex, 55, 1, function()
					if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then return end

					ply:Spawn()
					ply:SetSuppressPickupNotices(true)
					ply.noSound = true

					ply:SetupTeam(0)
					zb.GiveRole(ply, "Active Shooter", Color(200, 40, 40))
					ply:SetModel("models/gang_ballas_boss/gang_ballas_boss.mdl")

					ply.organism.stamina.range = 220

					hg.AddArmor(ply, "ent_armor_vest1")
					hg.AddArmor(ply, "ent_armor_helmet5")

					local inv = ply:GetNetVar("Inventory", {})
					inv["Weapons"] = inv["Weapons"] or {}
					inv["Weapons"]["hg_flashlight"] = true
					inv["Weapons"]["hg_sling"] = true
					ply:SetNetVar("Inventory", inv)

					ply:Give("weapon_hands_sh")
					ply:Give("hg_flashlight")

					local pistol = ply:Give("weapon_ruger")
					if IsValid(pistol) and pistol.GetMaxClip1 then
						ply:GiveAmmo(pistol:GetMaxClip1() * 5, pistol:GetPrimaryAmmoType(), true)
					end

					local shotgun = ply:Give("weapon_ithaca37")
					if IsValid(shotgun) and shotgun.GetMaxClip1 then
						ply:GiveAmmo(shotgun:GetMaxClip1() * 3, shotgun:GetPrimaryAmmoType(), true)
						ply:SelectWeapon(shotgun:GetClass())
					else
						ply:SelectWeapon("weapon_hands_sh")
					end

					ply:Give("weapon_hg_molotov_tpik")
					ply:Give("weapon_hg_pipebomb_tpik")
					ply:Give("weapon_bandage_sh")
					ply:Give("weapon_medkit_sh")
					ply:Give("weapon_melee")

					ply:SetSuppressPickupNotices(false)
					ply.noSound = false

					self.ShooterSpawned = true
				end)
			else
				ply:SetSuppressPickupNotices(true)
				ply.noSound = true

				ply:SetupTeam(1)
				zb.GiveRole(ply, "Civilian", Color(40, 160, 40))

				local inv = ply:GetNetVar("Inventory", {})
				inv["Weapons"] = inv["Weapons"] or {}
				inv["Weapons"]["hg_flashlight"] = true
				ply:SetNetVar("Inventory", inv)

				ply:Give("weapon_hands_sh")
				ply:SelectWeapon("weapon_hands_sh")
				ply:Give("weapon_bigconsumable")
				ply:Give("weapon_bandage_sh")

				ply:SetSuppressPickupNotices(false)
				ply.noSound = false
			end

			timer.Simple(0.5, function()
				if IsValid(ply) then
					ply.noSound = false
					ply:SetSuppressPickupNotices(false)
				end
			end)
		end
	end)
end

function MODE:RoundThink()
	if not swatSpawned and (CurTime() - (zb.ROUND_BEGIN or CurTime())) >= 240 then
		local deadPlayers = {}

		for _, ply in player.Iterator() do
			if not ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
				table.insert(deadPlayers, ply)
			end
		end

		local spawnVectors = self.ShooterSpawns or zb.TranslatePointsToVectors(zb.GetMapPoints("AS_SHOOTER_SPAWN"))
		local startpos = (spawnVectors and spawnVectors[1]) or zb:GetRandomSpawn()

		for i = 1, math.min(4, #deadPlayers) do
			local ply = deadPlayers[i]

			ply:Spawn()
			ply:SetTeam(2)

			if not startpos then
				startpos = ply:GetPos()
			else
				hg.tpPlayer(startpos, ply, i, 0)
			end

			ply:SetPlayerClass("swat")

			local inv = ply:GetNetVar("Inventory") or {}
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_sling"] = true
			ply:SetNetVar("Inventory", inv)

			local armor = swat_armors[math.random(#swat_armors)]
			hg.AddArmor(ply, armor)

			zb.GiveRole(ply, "SWAT", Color(0, 0, 190))

			local wep = swat_weps[math.random(#swat_weps)]
			local gun = ply:Give(wep[1])
			if IsValid(gun) and gun.GetMaxClip1 then
				hg.AddAttachmentForce(ply, gun, wep[2])
				ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
			end

			local pistol = ply:Give("weapon_glock17")
			if IsValid(pistol) and pistol.GetMaxClip1 then
				ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
			end

			for _, item in ipairs(swat_otheritems) do
				ply:Give(item)
			end

			ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")
		end

		net.Start("as_swat_spawn")
		net.Broadcast()

		swatSpawned = true
	end
end