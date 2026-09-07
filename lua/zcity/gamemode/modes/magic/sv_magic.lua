MODE.name = "magic"
MODE.PrintName = "Магическая битва"
MODE.start_time = 6
MODE.end_time = 6

MODE.ROUND_TIME = 450

MODE.LootSpawn = false

MODE.OverideSpawnPos = true
MODE.PointsProgress = {}

MODE.ForBigMaps = true

MODE.Chance = 0.05

local pointsName = {
	"Альфа",
	"Браво",
	"Чарли",
	"Дельта",
	"Эхо",
	"Фокстрот",
	"Гольф",
	"Хотел",
	"Индиа",
	"Ноябрь",
	"Василёк",
	"Дубок"
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

function MODE:CanLaunch()
	do return false end
	local pointsA = zb.GetMapPoints("HMCD_MAGIC_ARCHMAGES")
	local pointsB = zb.GetMapPoints("HMCD_MAGIC_WARLOCKS")
	local pointsC = zb.GetMapPoints("HMCD_MAGIC_CAPPOINT")
	return (#pointsA > 0) and (#pointsB > 0) and (#pointsC > 0)
end

util.AddNetworkString("MAGIC_start")
util.AddNetworkString("MAGIC_PointsUpdate")
util.AddNetworkString("MAGIC_roundend")
util.AddNetworkString("MAGIC_ministry_spawn")

local size = 1000
hg = hg or {}

function MODE:Intermission()
	game.CleanUpMap()
	self.PointsProgress = {}

	self.WARLOCKSPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_MAGIC_WARLOCKS"), self.WARLOCKSPoints)

	self.ARCHMAGESPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_MAGIC_ARCHMAGES"), self.ARCHMAGESPoints)

	self.CapPoints = zb.GetMapPoints("HMCD_MAGIC_CAPPOINT")
	self.MinistryPoints = {}

	for _, point in ipairs(self.WARLOCKSPoints) do
		table.insert(self.MinistryPoints, point)
	end

	for _, point in ipairs(self.ARCHMAGESPoints) do
		table.insert(self.MinistryPoints, point)
	end

	hg.magic = {}
	for i, point in pairs(self.CapPoints) do
		local max = Vector(point.pos.x + size, point.pos.y + size, point.pos.z + size)
		local min = Vector(point.pos.x - size, point.pos.y - size, point.pos.z - size)
		local capPointPos = max - ((max - min) / 2)

		local ent = ents.Create("magic_point")
		ent:SetPos(capPointPos)
		ent.min = max
		ent.max = min
		ent.PointName = pointsName[i]
		ent:Spawn()

		self.PointsProgress[pointsName[i]] = {0, capPointPos}
	end

	net.Start("MAGIC_PointsUpdate")
		net.WriteTable(self.PointsProgress)
	net.Broadcast()

	local warlockPos
	local archmagePos

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local pos
		if ply:Team() == 1 then
			if not warlockPos then
				warlockPos = (#self.WARLOCKSPoints > 0 and self.WARLOCKSPoints[1].pos) or zb:GetRandomSpawn()
				pos = warlockPos
			else
				pos = hg.tpPlayer(warlockPos, ply, i, 0)
			end
		end

		if ply:Team() == 0 then
			if not archmagePos then
				archmagePos = (#self.ARCHMAGESPoints > 0 and self.ARCHMAGESPoints[1].pos) or zb:GetRandomSpawn()
				pos = archmagePos
			else
				pos = hg.tpPlayer(archmagePos, ply, i, 0)
			end
		end

		ply:SetupTeam(ply:Team())
		ply.Lives = 1
		ply.timeDeath = nil

		if pos then
			ply:SetPos(pos)
		end
	end

	net.Start("MAGIC_start")
	net.Broadcast()
end

local player_GetAll = player.GetAll
local team_GetAllTeams = team.GetAllTeams

function MODE:CheckAlivePlayers()
	local tbl = {}

	for i in pairs(team_GetAllTeams()) do
		if i == TEAM_UNASSIGNED or i == TEAM_SPECTATOR then continue end
		tbl[i] = {}
	end

	for _, ply in ipairs(player_GetAll()) do
		if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then continue end
		if ply:GetNetVar("handcuffed", false) then continue end
		if (not ply:Alive()) and ply.Lives and ply.Lives < 1 then continue end
		if ply.organism and ply.organism.incapacitated and ply.Lives and ply.Lives < 1 then continue end

		tbl[ply:Team() or 0] = tbl[ply:Team() or 0] or {}
		tbl[ply:Team()][(#tbl[ply:Team() or 0] or 0) + 1] = ply
	end

	return tbl
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

local WarlockEquipment = {
	["default"] = {
		Primary = nil,
		Secondary = nil,
		Other = {"weapon_hg_flamberge","weapon_hands_sh","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = nil,
		Armor = nil
	}
}

local ArchmageEquipment = {
	["default"] = {
		Primary = nil,
		Secondary = nil,
		Other = {"weapon_hg_longsword","weapon_hands_sh","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = nil,
		Armor = nil
	}
}

local MinistryWeapons = {
	{"weapon_m4a1", {"holo15", "grip3", "laser4"}},
	{"weapon_hk416", {"holo15", "grip3", "laser4"}},
	{"weapon_mp7", {"holo14"}},
	{"weapon_m4a1", {"optic2", "grip3", "supressor7"}}
}

local MinistryOtherItems = {
	"weapon_medkit_sh",
	"weapon_tourniquet",
	"weapon_walkie_talkie",
	"weapon_handcuffs",
	"weapon_handcuffs_key",
	"weapon_hg_flashbang_tpik"
}

local MinistryArmor = {
	{"ent_armor_vest8", "ent_armor_helmet6"}
}

local function GiveEquip(ply, teamId)
	local classequip = (teamId == 1) and WarlockEquipment["default"] or ArchmageEquipment["default"]
	if not classequip then return end

	local inv = ply:GetNetVar("Inventory") or {}
	inv.Weapons = inv.Weapons or {}
	inv.Weapons["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	local mainWep
	if istable(classequip.Other) then
		for i, wep in ipairs(classequip.Other) do
			if isstring(wep) and wep ~= "" then
				local w = ply:Give(wep)
				if i == 1 and IsValid(w) then
					mainWep = w
				end
			end
		end
	end

	local walkietalkie = ply:Give("weapon_walkie_talkie")
	if IsValid(walkietalkie) then
		walkietalkie.Frequency = (teamId == 1 and 1) or 5
	end

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		if IsValid(mainWep) then
			ply:SelectWeapon(mainWep:GetClass())
		else
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)
end

local function GiveMinistryEquip(ply)
	local inv = ply:GetNetVar("Inventory") or {}
	inv.Weapons = inv.Weapons or {}
	inv.Weapons["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	local armor = MinistryArmor[math.random(#MinistryArmor)]
	for _, armorEnt in ipairs(armor) do
		hg.AddArmor(ply, armorEnt)
	end

	local primary = MinistryWeapons[math.random(#MinistryWeapons)]
	local gun = ply:Give(primary[1])
	if IsValid(gun) and gun.GetMaxClip1 then
		hg.AddAttachmentForce(ply, gun, primary[2])
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	end

	local pistol = ply:Give("weapon_glock17")
	if IsValid(pistol) and pistol.GetMaxClip1 then
		ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
	end

	local hands = ply:Give("weapon_hands_sh")
	local walkietalkie

	for _, wepName in ipairs(MinistryOtherItems) do
		local wep = ply:Give(wepName)
		if wepName == "weapon_walkie_talkie" then
			walkietalkie = wep
		end
	end

	if IsValid(walkietalkie) then
		walkietalkie.Frequency = 7
	end

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		if IsValid(gun) then
			ply:SelectWeapon(gun:GetClass())
		elseif IsValid(hands) then
			ply:SelectWeapon(hands:GetClass())
		end
	end)
end

local function spawnmagicplayer(ply)
	if not ply:Alive() then ply:Spawn() end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	if ply:Team() == 1 then
		ply:SetPlayerClass("warlock")
		zb.GiveRole(ply, "Чернокнижник", Color(190,80,255))
	else
		ply:SetPlayerClass("archmage")
		zb.GiveRole(ply, "Верховный маг", Color(120,190,255))
	end

	GiveEquip(ply, ply:Team())

	timer.Simple(0.1,function()
		if IsValid(ply) then ply.noSound = false end
	end)

	ply:SetSuppressPickupNotices(false)
end

local function SpawnMinistry(self)
	local candidates = {}
	local aliveFallback = {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then
			table.insert(candidates, ply)
		else
			table.insert(aliveFallback, ply)
		end
	end

	if #candidates <= 0 then
		table.Shuffle(aliveFallback)
		candidates = aliveFallback
	end

	if #candidates <= 0 then return end

	local startPos = ((self.MinistryPoints or {})[1] and self.MinistryPoints[1].pos) or zb:GetRandomSpawn()

	for i = 1, math.min(4, #candidates) do
		local ply = candidates[i]
		if not IsValid(ply) then continue end
		if not ply:Alive() then ply:Spawn() end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:SetTeam(2)
		ply:SetupTeam(2)
		ply:SetPlayerClass("ministrylight")
		zb.GiveRole(ply, "Министерство света", Color(255,230,120))
		ply.Lives = 1
		ply.timeDeath = nil

		if startPos then
			if i == 1 then
				ply:SetPos(startPos)
			else
				local pos = hg.tpPlayer(startPos, ply, i, 0)
				if pos then
					ply:SetPos(pos)
				end
			end
		end

		GiveMinistryEquip(ply)

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end
			ply.noSound = false
			ply:SetSuppressPickupNotices(false)
		end)
	end

	net.Start("MAGIC_ministry_spawn")
	net.Broadcast()
end

function MODE:GetPlySpawn(ply)
	if ply:Team() == 1 then
		if self.WARLOCKSPoints and #self.WARLOCKSPoints > 0 then
			ply:SetPos(self.WARLOCKSPoints[#self.WARLOCKSPoints].pos)
			if #self.WARLOCKSPoints > 1 then
				table.remove(self.WARLOCKSPoints)
			end
		end
	elseif ply:Team() == 2 then
		if self.MinistryPoints and #self.MinistryPoints > 0 then
			ply:SetPos(self.MinistryPoints[#self.MinistryPoints].pos)
			if #self.MinistryPoints > 1 then
				table.remove(self.MinistryPoints)
			end
		end
	else
		if self.ARCHMAGESPoints and #self.ARCHMAGESPoints > 0 then
			ply:SetPos(self.ARCHMAGESPoints[#self.ARCHMAGESPoints].pos)
			if #self.ARCHMAGESPoints > 1 then
				table.remove(self.ARCHMAGESPoints)
			end
		end
	end
end

function MODE:GiveEquipment()
	self.WARLOCKSPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_MAGIC_WARLOCKS"), self.WARLOCKSPoints)

	self.ARCHMAGESPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_MAGIC_ARCHMAGES"), self.ARCHMAGESPoints)

	self.MinistryPoints = {}
	for _, point in ipairs(self.WARLOCKSPoints) do
		table.insert(self.MinistryPoints, point)
	end
	for _, point in ipairs(self.ARCHMAGESPoints) do
		table.insert(self.MinistryPoints, point)
	end

	timer.Simple(0.1,function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("warlock")
				zb.GiveRole(ply, "Чернокнижник", Color(190,80,255))
			else
				ply:SetPlayerClass("archmage")
				zb.GiveRole(ply, "Верховный маг", Color(120,190,255))
			end

			GiveEquip(ply, ply:Team())
			ply.Lives = 1
			ply.timeDeath = nil

			timer.Simple(0.1,function()
				if IsValid(ply) then ply.noSound = false end
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

hg = hg or {}
hg.magic = hg.magic or {}

local cd = 0
local ministrySpawned = false

function MODE:RoundThink()
	if cd < CurTime() then
		local needSend = false

		for name, Point in pairs(hg.magic) do
			for _, ply in pairs(Point) do
				if not ply:Alive() then table.RemoveByValue(Point, ply) continue end

				if ply:Team() == 1 then
					self.PointsProgress[name][1] = math.min((self.PointsProgress[name][1] or 0) + 1, 100)
				elseif ply:Team() == 0 then
					self.PointsProgress[name][1] = math.max((self.PointsProgress[name][1] or 0) - 1, -100)
				end

				needSend = true
			end
		end

		if needSend then
			net.Start("MAGIC_PointsUpdate")
				net.WriteTable(self.PointsProgress)
			net.Broadcast()
		end

		cd = CurTime() + 0.5
	end

	if ministrySpawned then return end
	if (CurTime() - (zb.ROUND_BEGIN or CurTime())) < 120 then return end

	SpawnMinistry(self)
	ministrySpawned = true
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("MAGIC_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for _, ply in player.Iterator() do
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
	ply.Lives = ply.Lives or 1
	ply.Lives = 0
	ply.timeDeath = nil
end

function MODE:RoundStart()
	ministrySpawned = false
end
