MODE.name = "detroit_robots"
MODE.PrintName = "Война роботов: Детройт"
MODE.start_time = 6
MODE.end_time = 6
MODE.ROUND_TIME = 500
MODE.LootSpawn = false
MODE.OverideSpawnPos = true
MODE.PointsProgress = {}
MODE.ForBigMaps = true
MODE.Chance = 0.28

local pointsName = {
	"Assembly",
	"Core",
	"Junction",
	"Foundry",
	"Sector",
	"Vault",
	"Nexus",
	"Relay",
	"Grid",
	"Forge",
	"Node",
	"Tower"
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

function MODE:CanLaunch()
	do return false end
	local points = zb.GetMapPoints("HMCD_DR_CHAPPIE")
	local points2 = zb.GetMapPoints("HMCD_DR_INVADERS")
	local points3 = zb.GetMapPoints("HMCD_DR_CAPPOINT")
	return (#points > 0) and (#points2 > 0) and (#points3 > 0)
end

util.AddNetworkString("dr_start")
util.AddNetworkString("DR_PointsUpdate")
util.AddNetworkString("dr_roundend")

local size = 1000
hg = hg or {}

function MODE:Intermission()
	game.CleanUpMap()
	self.PointsProgress = {}

	self.InvaderPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_DR_INVADERS"), self.InvaderPoints)
	self.ChappiePoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_DR_CHAPPIE"), self.ChappiePoints)

	self.CapPoints = zb.GetMapPoints("HMCD_DR_CAPPOINT")
	hg.detroit_robots = {}

	for i, point in pairs(self.CapPoints) do
		local max = Vector(point.pos.x + size, point.pos.y + size, point.pos.z + size)
		local min = Vector(point.pos.x - size, point.pos.y - size, point.pos.z - size)
		local capPointPos = max - ((max - min) / 2)
		local tdml = ents.Create("swo_point")
		tdml:SetPos(capPointPos)
		tdml.min = max
		tdml.max = min
		tdml.PointName = pointsName[i]
		tdml:Spawn()
		self.PointsProgress[pointsName[i]] = {0, capPointPos}
	end

	net.Start("DR_PointsUpdate")
		net.WriteTable(self.PointsProgress)
	net.Broadcast()

	local team1pos
	local team0pos

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local pos

		if ply:Team() == 1 then
			if not team1pos then
				team1pos = #self.InvaderPoints > 0 and self.InvaderPoints[1].pos or zb:GetRandomSpawn()
				pos = team1pos
			else
				pos = hg.tpPlayer(team1pos, ply, i, 0)
			end
		end

		if ply:Team() == 0 then
			if not team0pos then
				team0pos = #self.ChappiePoints > 0 and self.ChappiePoints[1].pos or zb:GetRandomSpawn()
				pos = team0pos
			else
				pos = hg.tpPlayer(team0pos, ply, i, 0)
			end
		end

		ply:SetupTeam(ply:Team())
		ply.Lives = 1

		if pos then
			ply:SetPos(pos)
		end
	end

	net.Start("dr_start")
	net.Broadcast()
end

local player_GetAll = player.GetAll
local team_GetAllTeams = team.GetAllTeams

function MODE:CheckAlivePlayers()
	local tbl = {}

	for i, info in pairs(team_GetAllTeams()) do
		if i == TEAM_UNASSIGNED or i == TEAM_SPECTATOR then continue end
		tbl[i] = {}
	end

	for _, ply in ipairs(player_GetAll()) do
		if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		tbl[ply:Team() or 0] = tbl[ply:Team() or 0] or {}
		tbl[ply:Team()][(#tbl[ply:Team() or 0] or 0) + 1] = ply
	end

	return tbl
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	if not self.CapPoints or #self.CapPoints <= 0 then
		return endround
	end

	local needed = #self.CapPoints * 100
	local allPoints = 0

	for _, points in pairs(self.PointsProgress) do
		allPoints = allPoints + (points[1] or 0)
	end

	if allPoints >= needed or allPoints <= -needed then
		return true
	end

	return endround
end

function MODE:RoundStart()
end

local InvaderEquipment = {
	["default"] = {
		Primary = "weapon_ak74",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo6","optic11","holo12","holo2"},
				Barell = {"supressor8"}
			}
		},
		Armor = {"vest5","helmet1","headphones1"}
	},
	["machinegunner"] = {
		Primary = "weapon_pkm",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo6","optic11"}
			}
		},
		Armor = {"vest5","helmet1","headphones1"}
	},
	["sniper1"] = {
		Primary = "weapon_svd",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic11","optic3"}
			}
		},
		Armor = {"vest5","helmet1","headphones1"}
	},
	["sniper2"] = {
		Primary = "weapon_asval",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic3","optic4"}
			}
		},
		Armor = {"vest5","helmet1","headphones1"}
	},
}

local ChappieEquipment = {
	["default"] = {
		Primary = "weapon_m4a1",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_hg_grenade_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo17","holo14","holo11","holo4"},
				Barell = {"supressor2"}
			}
		},
		Armor = {"vest1","helmet1","headphones1"}
	},
	["machinegunner"] = {
		Primary = "weapon_m249",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_hg_grenade_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo17","holo14","holo11","holo4"}
			}
		},
		Armor = {"vest1","helmet1","headphones1"}
	},
	["sniper1"] = {
		Primary = "weapon_sr25",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_medkit_sh"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic6","optic2"}
			}
		},
		Armor = {"vest3","helmet1","headphones1"}
	}
}

local function GiveEquip(ply, teamid)
	local teamequip = (teamid == 1 and InvaderEquipment) or ChappieEquipment
	local classequip = table.Random(teamequip)

	local inv = ply:GetNetVar("Inventory")
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	local Primary = ply:Give(classequip.Primary)
	ply:GiveAmmo(Primary:GetMaxClip1() * 2, Primary:GetPrimaryAmmoType(), true)

	local scopeorno = (classequip.Attachments.Primary.Allways and 1) or (classequip.Attachments.Primary.Scopes and math.random(0,1)) or 0
	if scopeorno > 0 then
		hg.AddAttachmentForce(ply, Primary, classequip.Attachments.Primary.Scopes[math.random(#classequip.Attachments.Primary.Scopes)])
	end

	local barrelorno = (classequip.Attachments.Primary.Allways and 1) or (classequip.Attachments.Primary.Barell and math.random(0,1)) or 0
	if barrelorno > 0 and classequip.Attachments.Primary.Barell then
		hg.AddAttachmentForce(ply, Primary, classequip.Attachments.Primary.Barell[math.random(#classequip.Attachments.Primary.Barell)])
	end

	local Secondary = ply:Give(classequip.Secondary)
	ply:GiveAmmo(Secondary:GetMaxClip1() * 2, Secondary:GetPrimaryAmmoType(), true)

	hg.AddArmor(ply, classequip.Armor)

	for k, v in ipairs(classequip.Other) do
		ply:Give(v)
	end

	local walkietalkie = ply:Give("weapon_walkie_talkie")
	walkietalkie.Frequency = (teamid == 1 and 7) or 3

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	timer.Simple(0.2, function()
		if IsValid(ply) then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)
end

function MODE:GetPlySpawn(ply)
	if ply:Team() == 1 then
		if self.InvaderPoints and #self.InvaderPoints > 0 then
			ply:SetPos(self.InvaderPoints[#self.InvaderPoints].pos)
			if #self.InvaderPoints > 1 then
				table.remove(self.InvaderPoints)
			end
		end
	else
		if self.ChappiePoints and #self.ChappiePoints > 0 then
			ply:SetPos(self.ChappiePoints[#self.ChappiePoints].pos)
			if #self.ChappiePoints > 1 then
				table.remove(self.ChappiePoints)
			end
		end
	end
end

function MODE:GiveEquipment()
	self.InvaderPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_DR_INVADERS"), self.InvaderPoints)
	self.ChappiePoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_DR_CHAPPIE"), self.ChappiePoints)

	timer.Simple(0.1, function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("invader_robot")
				zb.GiveRole(ply, "Робот-захватчик", Color(170, 50, 50))
			else
				ply:SetPlayerClass("chappie_robot")
				zb.GiveRole(ply, "Робот Чаппи", Color(50, 140, 255))
			end

			GiveEquip(ply, ply:Team())

			ply:SetRunSpeed((ply:GetRunSpeed() or 250) + 55)

			timer.Simple(0.1, function()
				if IsValid(ply) then
					ply.noSound = false
				end
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

hg = hg or {}
hg.detroit_robots = hg.detroit_robots or {}

local cd = 0

function MODE:RoundThink()
	if cd < CurTime() then
		local needSend = false

		for name, Point in pairs(hg.detroit_robots) do
			for i, ply in pairs(Point) do
				if not ply:Alive() then
					table.RemoveByValue(Point, ply)
					continue
				end

				if ply:Team() == 1 then
					self.PointsProgress[name][1] = math.min((self.PointsProgress[name][1] or 0) + 1, 100)
				else
					self.PointsProgress[name][1] = math.max((self.PointsProgress[name][1] or 0) - 1, -100)
				end

				needSend = true
			end
		end

		if needSend then
			net.Start("DR_PointsUpdate")
				net.WriteTable(self.PointsProgress)
			net.Broadcast()
		end

		cd = CurTime() + 0.5
	end
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Simple(2, function()
		net.Start("dr_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	for k, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
		else
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
	if not IsValid(ply) then return end
	ply.Lives = 1
end