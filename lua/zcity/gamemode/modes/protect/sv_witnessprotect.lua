MODE.name = "witnessprotect"
MODE.PrintName = "Программа защиты свидетелей"
MODE.start_time = 6
MODE.end_time = 6
MODE.ROUND_TIME = 420
MODE.LootSpawn = false
MODE.OverideSpawnPos = true
MODE.ForBigMaps = false
MODE.Chance = 0.06

local MAFIA_ARRIVAL_DELAY = 35
local WITNESS_COUNT = 2

local ROLE_COLORS = {
	police = Color(40, 120, 255),
	witness = Color(255, 210, 70),
	mafia = Color(180, 40, 40)
}

local WITNESS_ROLES = {
	{ name = "Главный свидетель", desc = "Знает слишком много и теперь обязан дышать до конца раунда." },
	{ name = "Свидетель подшофе", desc = "Видел всю грязь, но до сих пор в ахуе от того, во что влез." },
	{ name = "Бухгалтер схем", desc = "Считал чужие деньги, а теперь считает, сколько до тебя осталось метров." },
	{ name = "Случайный очевидец", desc = "Просто оказался не в том месте и теперь за ним едет весь криминальный отдел ада." },
}

local POLICE_ROLES = {
	{ name = "Опер прикрытия", desc = "Твоя работа — держать периметр и не дать свидетелю стать памятником." },
	{ name = "Грязный участковый", desc = "Бумажки потом, сейчас надо ломать лица тем, кто приехал за свидетелем." },
	{ name = "Щит правосудия", desc = "Если в тебя не летит свинец, значит ты стоишь недостаточно близко." },
	{ name = "Переговорщик без переговоров", desc = "Сначала орёшь “Стоять”, потом объясняешь всё пулями." },
	{ name = "Старый опер", desc = "Видел всякое дерьмо, но и сегодня не собирается умирать первым." },
}

local MAFIA_ROLES = {
	{ name = "Чистильщик", desc = "Приехал не болтать — твоя задача убрать свидетелей и закрыть вопрос навсегда." },
	{ name = "Мокрушник", desc = "Работает тихо только на бумаге, по факту начинается мясо и ор выше крыши." },
	{ name = "Водила налёта", desc = "Подвёз братву, достал ствол и тоже пошёл делать грязь." },
	{ name = "Коллектор мафии", desc = "Сегодня забираешь не долги, а чужие жизни." },
	{ name = "Отбитый бандос", desc = "Плана нет, дисциплины нет, зато желание устроить пиздец максимальное." },
}

local COP_MODELS = {
    ["male 01"] = "models/monolithservers/mpd/male_01.mdl",
    ["male 03"] = "models/monolithservers/mpd/male_03.mdl",
    ["male 04"] = "models/monolithservers/mpd/male_04_2.mdl",
    ["male 05"] = "models/monolithservers/mpd/male_05.mdl",
    ["male 07"] = "models/monolithservers/mpd/male_07_2.mdl",
    ["male 08"] = "models/monolithservers/mpd/male_08.mdl",
    ["male 09"] = "models/monolithservers/mpd/male_09_2.mdl",
}

local WITNESS_MODELS = {
	"models/player/Group01/male_04.mdl",
	"models/player/Group01/male_06.mdl",
	"models/player/Group01/male_08.mdl",
	"models/player/Group01/female_02.mdl",
	"models/player/Group01/female_04.mdl",
}

local MAFIA_MODELS = {
    "models/gang_groove/gang_1.mdl",
    "models/gang_groove/gang_2.mdl",
    "models/gang_chem/gang_groove_chem.mdl"
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

util.AddNetworkString("WITPROTECT_start")
util.AddNetworkString("WITPROTECT_status")
util.AddNetworkString("WITPROTECT_mafia_arrival")
util.AddNetworkString("WITPROTECT_witness_down")
util.AddNetworkString("WITPROTECT_roundend")

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

local function pickRole(list)
	return list[math.random(#list)]
end

local function getPlayerDisplayName(ply)
	return ply:GetPlayerName() or ply:Name() or "Неизвестный"
end

function MODE:ApplyRoleData(ply, roleData, roleType)
	self.PlayerRoleData = self.PlayerRoleData or {}
	self.PlayerRoleData[ply] = {
		name = roleData.name,
		desc = roleData.desc,
		type = roleType,
	}

	ply:SetNWString("WitnessProtectRoleName", roleData.name or "")
	ply:SetNWString("WitnessProtectRoleDesc", roleData.desc or "")
	ply:SetNWString("WitnessProtectRoleType", roleType or "")
end

function MODE:AssignTeams()
	local players = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR then
			table.insert(players, ply)
		end
	end

	shuffle(players)
	if #players <= 0 then return end

	self.PlayerRoleData = {}
	self.WitnessPlayers = {}

	local witnessCount = math.min(WITNESS_COUNT, #players)
	local remaining = math.max(0, #players - witnessCount)
	local policeCount = math.ceil(remaining / 2)
	local mafiaCount = remaining - policeCount

	if remaining >= 2 then
		if mafiaCount < 1 then
			mafiaCount = 1
			policeCount = remaining - mafiaCount
		end
		if policeCount < 1 then
			policeCount = 1
			mafiaCount = remaining - policeCount
		end
	end

	for i, ply in ipairs(players) do
		if i <= witnessCount then
			ply:SetTeam(1)
			table.insert(self.WitnessPlayers, ply)
			self:ApplyRoleData(ply, pickRole(WITNESS_ROLES), "witness")
		elseif i <= witnessCount + policeCount then
			ply:SetTeam(0)
			self:ApplyRoleData(ply, pickRole(POLICE_ROLES), "police")
		else
			ply:SetTeam(2)
			self:ApplyRoleData(ply, pickRole(MAFIA_ROLES), "mafia")
		end
	end
end

function MODE:CountAliveWitnesses()
	local alive = 0
	for _, ply in ipairs(team.GetPlayers(1)) do
		if IsValid(ply) and ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			alive = alive + 1
		end
	end
	return alive
end

function MODE:CountAliveMafia()
	local alive = 0
	for _, ply in ipairs(team.GetPlayers(2)) do
		if IsValid(ply) and ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			alive = alive + 1
		end
	end
	return alive
end

function MODE:GetArrivalTimeLeft()
	local roundBegin = zb.ROUND_BEGIN or CurTime()
	return math.max(0, MAFIA_ARRIVAL_DELAY - (CurTime() - roundBegin))
end

function MODE:BroadcastStatus(target)
	local aliveWitnesses = self:CountAliveWitnesses()
	local mafiaArrived = self.MafiaArrived or false
	local arrivalTimeLeft = self:GetArrivalTimeLeft()

	net.Start("WITPROTECT_status")
		net.WriteUInt(aliveWitnesses, 4)
		net.WriteBool(mafiaArrived)
		net.WriteFloat(arrivalTimeLeft)
	if target then
		net.Send(target)
	else
		net.Broadcast()
	end
end

local function giveAmmoIfNeeded(ply, wep, mult)
	if IsValid(wep) and wep.GetMaxClip1 and wep:GetMaxClip1() > 0 then
		ply:GiveAmmo(wep:GetMaxClip1() * (mult or 2), wep:GetPrimaryAmmoType(), true)
	end
end

function MODE:EquipWitness(ply)
	local roleData = (self.PlayerRoleData and self.PlayerRoleData[ply]) or pickRole(WITNESS_ROLES)
	self:ApplyRoleData(ply, roleData, "witness")

	ply:StripWeapons()
	ply:StripAmmo()
	ply:SetPlayerClass()
	ply:SetModel(table.Random(WITNESS_MODELS))
	zb.GiveRole(ply, roleData.name, ROLE_COLORS.witness)

	ply:Give("weapon_hands_sh")
	ply:Give("weapon_walkie_talkie")
	ply:Give("weapon_bandage_sh")

	if math.random(100) <= 50 then
		local sidearm = ply:Give("weapon_revolver2")
		giveAmmoIfNeeded(ply, sidearm, 2)
	end
end

function MODE:EquipPolice(ply)
	local roleData = (self.PlayerRoleData and self.PlayerRoleData[ply]) or pickRole(POLICE_ROLES)
	self:ApplyRoleData(ply, roleData, "police")

	ply:StripWeapons()
	ply:StripAmmo()
	ply:SetPlayerClass("police")
	ply:SetModel(table.Random(COP_MODELS))
	zb.GiveRole(ply, roleData.name, ROLE_COLORS.police)

	hg.AddArmor(ply, "ent_armor_helmet3")
	hg.AddArmor(ply, "ent_armor_vest2")

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	ply:Give("weapon_hands_sh")
	ply:Give("weapon_walkie_talkie")
	ply:Give("weapon_handcuffs")
	ply:Give("weapon_handcuffs_key")
	ply:Give("weapon_hg_tonfa")

	local pistol = ply:Give(math.random(100) <= 50 and "weapon_hk_usp" or "weapon_glock17")
	giveAmmoIfNeeded(ply, pistol, 3)

	if math.random(100) <= 40 then
		local long = ply:Give("weapon_remington870")
		giveAmmoIfNeeded(ply, long, 2)
	else
		local long = ply:Give("weapon_mp5")
		giveAmmoIfNeeded(ply, long, 3)
	end
end

function MODE:EquipMafia(ply)
	local roleData = (self.PlayerRoleData and self.PlayerRoleData[ply]) or pickRole(MAFIA_ROLES)
	self:ApplyRoleData(ply, roleData, "mafia")

	ply:StripWeapons()
	ply:StripAmmo()
	ply:SetPlayerClass()
	ply:SetModel(table.Random(MAFIA_MODELS))
	zb.GiveRole(ply, roleData.name, ROLE_COLORS.mafia)

	if math.random(100) <= 35 then
		hg.AddArmor(ply, "ent_armor_helmet2")
	end

	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	ply:Give("weapon_hands_sh")
	ply:Give("weapon_melee")

	local pistol = ply:Give(math.random(100) <= 50 and "weapon_glock17" or "weapon_browninghp")
	giveAmmoIfNeeded(ply, pistol, 3)

	local mainPool = {"weapon_doublebarrel", "weapon_handmadesmg", "weapon_tec9", "weapon_mp-80"}
	local main = ply:Give(table.Random(mainPool))
	giveAmmoIfNeeded(ply, main, 2)

	if math.random(100) <= 40 then
		ply:Give("weapon_hg_molotov_tpik")
	end
end

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()
	self:AssignTeams()
	self.MafiaArrived = false
	self.RoundWinner = nil
	self.NextStateBroadcast = 0
	self.WitnessDeaths = 0

	self.POLICEPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_POLICE"), self.POLICEPoints)
	self.WITNESSPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_WITNESS"), self.WITNESSPoints)
	self.MAFIAPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_MAFIA"), self.MAFIAPoints)

	local policePos
	local witnessPos

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end

		if ply:Team() == 2 then
			ply:KillSilent()
			continue
		end

		local pos
		if ply:Team() == 0 then
			if not policePos then
				policePos = (#self.POLICEPoints > 0 and self.POLICEPoints[1].pos) or zb:GetRandomSpawn()
				pos = policePos
			else
				pos = hg.tpPlayer(policePos, ply, i, 0)
			end
		elseif ply:Team() == 1 then
			if not witnessPos then
				witnessPos = (#self.WITNESSPoints > 0 and self.WITNESSPoints[1].pos) or zb:GetRandomSpawn()
				pos = witnessPos
			else
				pos = hg.tpPlayer(witnessPos, ply, i, 0)
			end
		end

		ply:SetupTeam(ply:Team())
		ply.Lives = 1
		ply.timeDeath = nil
		if pos then ply:SetPos(pos) end
	end

	net.Start("WITPROTECT_start")
		net.WriteUInt(math.min(WITNESS_COUNT, #team.GetPlayers(1)), 4)
	net.Broadcast()

	self:BroadcastStatus()
end

function MODE:GetPlySpawn(ply)
	if ply:Team() == 0 then
		if self.POLICEPoints and #self.POLICEPoints > 0 then
			ply:SetPos(self.POLICEPoints[#self.POLICEPoints].pos)
			if #self.POLICEPoints > 1 then table.remove(self.POLICEPoints) end
		end
	elseif ply:Team() == 1 then
		if self.WITNESSPoints and #self.WITNESSPoints > 0 then
			ply:SetPos(self.WITNESSPoints[#self.WITNESSPoints].pos)
			if #self.WITNESSPoints > 1 then table.remove(self.WITNESSPoints) end
		end
	elseif ply:Team() == 2 then
		if self.MAFIAPoints and #self.MAFIAPoints > 0 then
			ply:SetPos(self.MAFIAPoints[#self.MAFIAPoints].pos)
			if #self.MAFIAPoints > 1 then table.remove(self.MAFIAPoints) end
		end
	end
end

function MODE:GiveEquipment()
	self.POLICEPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_POLICE"), self.POLICEPoints)
	self.WITNESSPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_WITNESS"), self.WITNESSPoints)
	self.MAFIAPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_WITPROTECT_MAFIA"), self.MAFIAPoints)

	timer.Simple(0.1, function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 0 then
				self:EquipPolice(ply)
			elseif ply:Team() == 1 then
				self:EquipWitness(ply)
			end

			ply.Lives = 1
			ply.timeDeath = nil

			timer.Simple(0.1, function()
				if IsValid(ply) then ply.noSound = false end
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:SpawnMafiaWave()
	local mafiaSpawn = (#self.MAFIAPoints > 0 and self.MAFIAPoints[1].pos) or zb:GetRandomSpawn()
	local idx = 0

	for _, ply in ipairs(team.GetPlayers(2)) do
		if not IsValid(ply) then continue end
		idx = idx + 1
		ply:Spawn()
		ply:SetupTeam(2)
		ply.Lives = 1
		ply.timeDeath = nil

		if mafiaSpawn then
			if idx == 1 then
				ply:SetPos(mafiaSpawn)
			else
				local pos = hg.tpPlayer(mafiaSpawn, ply, idx, 0)
				if pos then ply:SetPos(pos) end
			end
		end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		self:EquipMafia(ply)

		timer.Simple(0.1, function()
			if IsValid(ply) then
				ply.noSound = false
				ply:SetSuppressPickupNotices(false)
			end
		end)
	end

	self.MafiaArrived = true
	net.Start("WITPROTECT_mafia_arrival")
	net.Broadcast()
	self:BroadcastStatus()
end

function MODE:RoundStart()
	self.MafiaArrived = false
	self.RoundWinner = nil
	self.NextStateBroadcast = 0
	self:BroadcastStatus()
end

function MODE:RoundThink()
	if CurTime() >= (self.NextStateBroadcast or 0) then
		self.NextStateBroadcast = CurTime() + 1
		self:BroadcastStatus()
	end

	if not self.MafiaArrived and (CurTime() - (zb.ROUND_BEGIN or CurTime())) >= MAFIA_ARRIVAL_DELAY then
		self:SpawnMafiaWave()
	end
end

function MODE:ShouldRoundEnd()
	if self:CountAliveWitnesses() <= 0 then
		self.RoundWinner = 2
		return true
	end

	if self.MafiaArrived and self:CountAliveMafia() <= 0 then
		self.RoundWinner = 0
		return true
	end

	if CurTime() >= ((zb.ROUND_BEGIN or CurTime()) + self.ROUND_TIME) then
		self.RoundWinner = self:CountAliveWitnesses() > 0 and 0 or 2
		return true
	end

	return false
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_WITPROTECT_POLICE")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_WITPROTECT_MAFIA"))
end

function MODE:CanSpawn()
end

function MODE:PlayerDeath(ply)
	if not IsValid(ply) then return end
	ply.Lives = 0
	ply.timeDeath = nil

	if ply:Team() == 1 then
		local aliveLeft = math.max(0, self:CountAliveWitnesses() - 1)
		net.Start("WITPROTECT_witness_down")
			net.WriteString(getPlayerDisplayName(ply))
			net.WriteUInt(aliveLeft, 4)
		net.Broadcast()
	end
end

function MODE:EndRound()
	local winner = self.RoundWinner or (self:CountAliveWitnesses() > 0 and 0 or 2)

	timer.Simple(0.5, function()
		net.Start("WITPROTECT_roundend")
			net.WriteUInt(winner, 3)
		net.Broadcast()
	end)

	for _, ply in player.Iterator() do
		local isWinner = (winner == 2 and ply:Team() == 2) or (winner == 0 and ply:Team() ~= 2)
		if isWinner then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end
