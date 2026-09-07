MODE.name = "standoff_2"
MODE.PrintName = "Standoff 2"
MODE.start_time = 30
MODE.end_time = 6
MODE.ROUND_TIME = 580
MODE.LootSpawn = false
MODE.OverideSpawnPos = true
MODE.PointsProgress = {}
MODE.ForBigMaps = true
MODE.Chance = 0.21
MODE.KillMoney = 1000
MODE.StartMoney = 1000
MODE.BuyTime = 30
MODE.buymenu = true

local pointsName = {
	"Alpha",
	"Bravo",
	"Charlie",
	"Delta",
	"Echo",
	"Foxtrot",
	"Sigma",
	"Omega",
	"Site A",
	"Site B",
	"Mid",
	"Base"
}

local size = 1000
local grtSpawned = false

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

function MODE:CanLaunch()
	local tPoints = zb.GetMapPoints("HMCD_SO2_T")
	local ctPoints = zb.GetMapPoints("HMCD_SO2_CT")
	local capPoints = zb.GetMapPoints("HMCD_SO2_CAPPOINT")
	return (#tPoints > 0) and (#ctPoints > 0) and (#capPoints > 0)
end

util.AddNetworkString("s2_start")
util.AddNetworkString("s2_respawn")
util.AddNetworkString("S2_PointsUpdate")
util.AddNetworkString("s2_roundend")
util.AddNetworkString("s2_grt_spawn")
util.AddNetworkString("s2_open_buymenu")
util.AddNetworkString("s2_buyitem")

hg = hg or {}

function MODE:Intermission()
	game.CleanUpMap()
	self.PointsProgress = {}

	self.TerroristPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_T"), self.TerroristPoints)

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_CT"), self.CTPoints)

	self.GRTPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_GRT"), self.GRTPoints)

	if #self.GRTPoints <= 0 then
		table.CopyFromTo(self.CTPoints, self.GRTPoints)
	end

	self.CapPoints = zb.GetMapPoints("HMCD_SO2_CAPPOINT")
	hg.standoff_2 = {}

	for i, point in pairs(self.CapPoints) do
		local max = Vector(point.pos.x + size, point.pos.y + size, point.pos.z + size)
		local min = Vector(point.pos.x - size, point.pos.y - size, point.pos.z - size)
		local capPointPos = max - ((max - min) / 2)

		local capEnt = ents.Create("swo_point")
		capEnt:SetPos(capPointPos)
		capEnt.min = max
		capEnt.max = min
		capEnt.PointName = pointsName[i] or ("Point " .. i)
		capEnt:Spawn()

		self.PointsProgress[capEnt.PointName] = {0, capPointPos}
	end

	net.Start("S2_PointsUpdate")
		net.WriteTable(self.PointsProgress)
	net.Broadcast()

	local tPos
	local ctPos

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local pos

		if ply:Team() == 1 then
			if not ctPos then
				ctPos = #self.CTPoints > 0 and self.CTPoints[1].pos or zb:GetRandomSpawn()
				pos = ctPos
			else
				pos = hg.tpPlayer(ctPos, ply, i, 0)
			end
		else
			if not tPos then
				tPos = #self.TerroristPoints > 0 and self.TerroristPoints[1].pos or zb:GetRandomSpawn()
				pos = tPos
			else
				pos = hg.tpPlayer(tPos, ply, i, 0)
			end

			ply:SetTeam(0)
		end

		ply:SetupTeam(ply:Team())
		ply.Lives = 1

		if ply:GetNWInt("TDM_Money", 0) <= 0 then
			ply:SetNWInt("TDM_Money", self.StartMoney)
		end

		if pos then
			ply:SetPos(pos)
		end
	end

	net.Start("s2_start")
	net.Broadcast()
end

local player_GetAll = player.GetAll

function MODE:CheckAlivePlayers()
	local terrorists = {}
	local lawSide = {}

	for _, ply in ipairs(player_GetAll()) do
		if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		if ply:Team() == 0 then
			table.insert(terrorists, ply)
		elseif ply:Team() == 1 or ply:Team() == 2 then
			table.insert(lawSide, ply)
		end
	end

	return {terrorists, lawSide}
end

function MODE:ShouldRoundEnd()
	local endround = zb:CheckWinner(self:CheckAlivePlayers())

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
	grtSpawned = false

	for _, ply in player.Iterator() do
		ply:Freeze(false)
	end
end

local TerroristEquipment = {
	["default"] = {
		Primary = "weapon_ak74",
		Secondary = "weapon_glock18",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_hg_rgd_tpik", "weapon_bandage_sh", "weapon_medkit_sh", "weapon_tourniquet"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo6", "optic11", "holo12", "holo2"},
				Barell = {"supressor8"}
			}
		},
		Armor = {"vest5", "helmet1", "headphones1"}
	},
	["support"] = {
		Primary = "weapon_pkm",
		Secondary = "weapon_glock18",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_hg_rgd_tpik", "weapon_bandage_sh", "weapon_medkit_sh"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo6", "optic11"}
			}
		},
		Armor = {"vest5", "helmet1", "headphones1"}
	},
	["sniper"] = {
		Primary = "weapon_svd",
		Secondary = "weapon_glock18",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_bandage_sh", "weapon_medkit_sh"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic11", "optic3"}
			}
		},
		Armor = {"vest5", "helmet1", "headphones1"}
	}
}

local CTEquipment = {
	["default"] = {
		Primary = "weapon_m4a1",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_sogknife", "weapon_hg_flashbang_tpik", "weapon_bandage_sh", "weapon_medkit_sh", "weapon_tourniquet"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo17", "holo14", "holo11", "holo4"},
				Barell = {"supressor2"}
			}
		},
		Armor = {"vest1", "helmet1", "headphones1"}
	},
	["support"] = {
		Primary = "weapon_m249",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_sogknife", "weapon_hg_flashbang_tpik", "weapon_bandage_sh", "weapon_medkit_sh", "weapon_tourniquet"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo17", "holo14", "holo11", "holo4"}
			}
		},
		Armor = {"vest1", "helmet1", "headphones1"}
	},
	["sniper"] = {
		Primary = "weapon_sr25",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_sogknife", "weapon_medkit_sh"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic6", "optic2"}
			}
		},
		Armor = {"vest3", "helmet1", "headphones1"}
	}
}

local GRTEquipment = {
	["default"] = {
		Primary = "weapon_hk416",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_medkit_sh", "weapon_tourniquet", "weapon_hg_flashbang_tpik", "weapon_handcuffs", "weapon_handcuffs_key"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo15", "holo14"},
				Barell = {"supressor7"}
			}
		},
		Armor = {"vest8", "helmet6", "headphones1"}
	},
	["breacher"] = {
		Primary = "weapon_mp7",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_medkit_sh", "weapon_tourniquet", "weapon_hg_flashbang_tpik", "weapon_handcuffs", "weapon_handcuffs_key"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"holo14", "holo15"}
			}
		},
		Armor = {"vest8", "helmet6", "headphones1"}
	},
	["marksman"] = {
		Primary = "weapon_sr25",
		Secondary = "weapon_glock17",
		Other = {"weapon_hands_sh", "weapon_melee", "weapon_medkit_sh", "weapon_tourniquet", "weapon_hg_flashbang_tpik"},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic2", "optic6"}
			}
		},
		Armor = {"vest8", "helmet6", "headphones1"}
	}
}

local function GiveEquipmentByTable(ply, equipTable, freq)
	local classequip = table.Random(equipTable)

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	local Primary = ply:Give(classequip.Primary)
	if IsValid(Primary) and Primary.GetMaxClip1 then
		ply:GiveAmmo(Primary:GetMaxClip1() * 2, Primary:GetPrimaryAmmoType(), true)

		local scopeorno = (classequip.Attachments and classequip.Attachments.Primary and classequip.Attachments.Primary.Allways and 1)
			or (classequip.Attachments and classequip.Attachments.Primary and classequip.Attachments.Primary.Scopes and math.random(0, 1))
			or 0

		if scopeorno > 0 and classequip.Attachments.Primary.Scopes then
			hg.AddAttachmentForce(ply, Primary, classequip.Attachments.Primary.Scopes[math.random(#classequip.Attachments.Primary.Scopes)])
		end

		local barrelorno = (classequip.Attachments and classequip.Attachments.Primary and classequip.Attachments.Primary.Allways and 1)
			or (classequip.Attachments and classequip.Attachments.Primary and classequip.Attachments.Primary.Barell and math.random(0, 1))
			or 0

		if barrelorno > 0 and classequip.Attachments.Primary.Barell then
			hg.AddAttachmentForce(ply, Primary, classequip.Attachments.Primary.Barell[math.random(#classequip.Attachments.Primary.Barell)])
		end
	end

	local Secondary = ply:Give(classequip.Secondary)
	if IsValid(Secondary) and Secondary.GetMaxClip1 then
		ply:GiveAmmo(Secondary:GetMaxClip1() * 2, Secondary:GetPrimaryAmmoType(), true)
	end

	hg.AddArmor(ply, classequip.Armor)

	for _, v in ipairs(classequip.Other or {}) do
		ply:Give(v)
	end

	local walkietalkie = ply:Give("weapon_walkie_talkie")
	if IsValid(walkietalkie) then
		walkietalkie.Frequency = freq or 1
	end

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	timer.Simple(0.2, function()
		if IsValid(ply) then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)
end

local function GiveBuySpawnLoadout(ply, freq)
	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	local walkietalkie = ply:Give("weapon_walkie_talkie")
	if IsValid(walkietalkie) then
		walkietalkie.Frequency = freq or 1
	end

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	timer.Simple(0.2, function()
		if IsValid(ply) then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)
end

function MODE:GetPlySpawn(ply)
	if ply:Team() == 0 then
		if self.TerroristPoints and #self.TerroristPoints > 0 then
			ply:SetPos(self.TerroristPoints[#self.TerroristPoints].pos)
			if #self.TerroristPoints > 1 then
				table.remove(self.TerroristPoints)
			end
		end
	elseif ply:Team() == 1 then
		if self.CTPoints and #self.CTPoints > 0 then
			ply:SetPos(self.CTPoints[#self.CTPoints].pos)
			if #self.CTPoints > 1 then
				table.remove(self.CTPoints)
			end
		end
	elseif ply:Team() == 2 then
		if self.GRTPoints and #self.GRTPoints > 0 then
			ply:SetPos(self.GRTPoints[#self.GRTPoints].pos)
			if #self.GRTPoints > 1 then
				table.remove(self.GRTPoints)
			end
		end
	end
end

function MODE:GiveEquipment()
	self.TerroristPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_T"), self.TerroristPoints)

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_CT"), self.CTPoints)

	self.GRTPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_SO2_GRT"), self.GRTPoints)

	if #self.GRTPoints <= 0 then
		table.CopyFromTo(self.CTPoints, self.GRTPoints)
	end

	timer.Simple(0.1, function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end

			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("counter_terrorist")
				zb.GiveRole(ply, "Спецназ", Color(60, 140, 255))
				GiveBuySpawnLoadout(ply, 3)
			elseif ply:Team() == 2 then
				ply:SetPlayerClass("grt")
				zb.GiveRole(ply, "ГРТ", Color(120, 120, 255))
				GiveEquipmentByTable(ply, GRTEquipment, 9)
				ply:SetRunSpeed((ply:GetRunSpeed() or 250) + 45)
			else
				ply:SetTeam(0)
				ply:SetupTeam(0)
				ply:SetPlayerClass("terroristss")
				zb.GiveRole(ply, "Террорист", Color(185, 60, 60))
				GiveBuySpawnLoadout(ply, 7)
			end

			if ply:Team() ~= 2 then
				ply:SetRunSpeed((ply:GetRunSpeed() or 250) + 35)
			end

			timer.Simple(0.1, function()
				if IsValid(ply) then
					ply.noSound = false
				end
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

local pointTick = 0

function MODE:RoundThink()
	if pointTick < CurTime() then
		local needSend = false

		for name, Point in pairs(hg.standoff_2 or {}) do
			for _, ply in pairs(Point) do
				if not IsValid(ply) or not ply:Alive() then
					table.RemoveByValue(Point, ply)
					continue
				end

				if ply:Team() == 0 then
					self.PointsProgress[name][1] = math.min((self.PointsProgress[name][1] or 0) + 1, 100)
				else
					self.PointsProgress[name][1] = math.max((self.PointsProgress[name][1] or 0) - 1, -100)
				end

				needSend = true
			end
		end

		if needSend then
			net.Start("S2_PointsUpdate")
				net.WriteTable(self.PointsProgress)
			net.Broadcast()
		end

		pointTick = CurTime() + 0.5
	end

	if grtSpawned then return end
	if (CurTime() - (zb.ROUND_BEGIN or CurTime())) < 180 then return end

	local deadPlayers = {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply:Alive() then continue end
		table.insert(deadPlayers, ply)
	end

	if #deadPlayers <= 0 then
		grtSpawned = true
		return
	end

	local spawnPoints = self.GRTPoints or zb.GetMapPoints("HMCD_SO2_GRT")
	if not spawnPoints or #spawnPoints <= 0 then
		spawnPoints = self.CTPoints or zb.GetMapPoints("HMCD_SO2_CT")
	end

	local startPos = spawnPoints and spawnPoints[1] and spawnPoints[1].pos or zb:GetRandomSpawn()

	for i = 1, math.min(4, #deadPlayers) do
		local ply = deadPlayers[i]
		if not IsValid(ply) then continue end

		ply:Spawn()
		ply:SetTeam(2)
		ply:SetupTeam(2)
		ply:SetPlayerClass("grt")

		if startPos then
			if i == 1 then
				ply:SetPos(startPos)
			else
				hg.tpPlayer(startPos, ply, i, 0)
			end
		end

		zb.GiveRole(ply, "ГРТ", Color(120, 120, 255))
		GiveEquipmentByTable(ply, GRTEquipment, 9)

		ply:SetRunSpeed((ply:GetRunSpeed() or 250) + 45)
	end

	net.Start("s2_grt_spawn")
	net.Broadcast()

	grtSpawned = true
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_SO2_T")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_SO2_CT"))
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Simple(2, function()
		net.Start("s2_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	for _, ply in player.Iterator() do
		if winner == 1 then
			if ply:Team() == 1 or ply:Team() == 2 then
				ply:GiveExp(math.random(15, 30))
				ply:GiveSkill(math.Rand(0.1, 0.15))
				ply:SetNWInt("TDM_Money", math.max(ply:GetNWInt("TDM_Money", 0) + 2500, 0))
			else
				ply:GiveSkill(-math.Rand(0.05, 0.1))
				ply:SetNWInt("TDM_Money", math.max(ply:GetNWInt("TDM_Money", 0) + 1750, 0))
			end
		else
			if ply:Team() == winner then
				ply:GiveExp(math.random(15, 30))
				ply:GiveSkill(math.Rand(0.1, 0.15))
				ply:SetNWInt("TDM_Money", math.max(ply:GetNWInt("TDM_Money", 0) + 2500, 0))
			else
				ply:GiveSkill(-math.Rand(0.05, 0.1))
				ply:SetNWInt("TDM_Money", math.max(ply:GetNWInt("TDM_Money", 0) + 1750, 0))
			end
		end
	end
end

function MODE:PlayerDeath(ply)
	if not IsValid(ply) then return end
	ply.Lives = 1
end

hook.Add("HarmDone", "Standoff2MoneyGive", function(ply, victim, amt)
	if not CurrentRound() or CurrentRound().name ~= "standoff_2" then return end
	if not CurrentRound().KillMoney then return end
	if not IsValid(ply) or not IsValid(victim) then return end
	if not victim:IsPlayer() then return end
	if ply == victim then return end

	local add = amt * MODE.KillMoney * ((ply:Team() == victim:Team()) and -1 or 1)
	add = math.Round(add, 0)

	ply:SetNWInt("TDM_Money", math.max(ply:GetNWInt("TDM_Money", 0) + add, 0))

	if (ply:Team() == victim:Team()) and add <= 0 then
		victim:SetNWInt("TDM_Money", math.max(victim:GetNWInt("TDM_Money", 0) - add, 0))
	end
end)

function MODE:ShowSpare1(ply)
	if not IsValid(ply) then return end
	if not ply:Alive() then return end
	if ply:Team() == 2 then return end
	if (zb.ROUND_START or 0) + self.BuyTime < CurTime() then return end

	net.Start("s2_open_buymenu")
	net.Send(ply)
end

local AttachmentPrice = 50

net.Receive("s2_buyitem", function(_, ply)
	local round = CurrentRound()
	if not round or round.name ~= "standoff_2" then return end
	if not round.buymenu then return end
	if not IsValid(ply) or not ply:Alive() then return end
	if ply:Team() == 2 then return end
	if ((zb.ROUND_START or 0) + round.BuyTime < CurTime()) then
		ply:ChatPrint("Time's up!")
		return
	end

	local tItem = net.ReadTable()
	if not istable(tItem) then return end

	local category = tItem[1]
	local index = tItem[2]
	if not category or not index then return end

	local buyItems = round.BuyItems
	if not buyItems or not buyItems[category] or not buyItems[category][index] then return end
	local item = buyItems[category][index]
	if not item then return end

	if item.TeamBased ~= nil and item.TeamBased ~= ply:Team() then
		ply:ChatPrint("You can't buy this.")
		return
	end

	if tItem[3] then
		if not ply:HasWeapon(item.ItemClass) then
			ply:ChatPrint("You can't buy this attachment without a weapon.")
			return
		end

		if ((ply:GetNWInt("TDM_Money", 0) - AttachmentPrice) < 0) then
			ply:ChatPrint("Not enough money.")
			return
		end

		local wep = ply:GetWeapon(item.ItemClass)
		if not IsValid(wep) then return end

		hg.AddAttachmentForce(ply, wep, tItem[3])
		ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) - AttachmentPrice)
		ply:EmitSound("items/itempickup.wav")
		return
	end

	if ((ply:GetNWInt("TDM_Money", 0) - item.Price) < 0) then
		ply:ChatPrint("Not enough money.")
		return
	end

	local ent = ply:Give(item.ItemClass)

	if ent and ent.Use and IsValid(ent) then
		ent:Use(ply)
	end

	if IsValid(ent) and ent:GetClass() == "weapon_bloodbag" then
		ent.bloodtype = "o-"
		ent.modeValues[1] = 1
	end

	if IsValid(ent) and item.Amount then
		ent.AmmoCount = item.Amount
	end

	if IsValid(ent) and ent.GetPrimaryAmmoType and ent.GetMaxClip1 then
		ply:GiveAmmo(ent:GetMaxClip1() * 1, ent:GetPrimaryAmmoType(), true)
	end

	ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) - item.Price)
	ply:EmitSound("items/itempickup.wav")
end)

return MODE