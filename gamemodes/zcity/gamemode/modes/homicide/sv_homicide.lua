local MODE = MODE
MODE.start_time = 1
MODE.end_time = 7
MODE.ROUND_TIME = 600
MODE.randomSpawns = true
MODE.shouldfreeze = true
MODE.PoliceAllowed = false
MODE.OverrideSpawn = true
MODE.LootSpawn = true
MODE.LootOnTime = true
MODE.Chance = 0.28
MODE.LootDivTime = 500
local function GiveFlashlightDelayed(ply, delay)
	delay = delay or 0.15
	timer.Simple(delay, function()
		if not IsValid(ply) then return end
		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory", inv)
		ply:SetNetVar("flashlight", false)
	end)
end
MODE.LootTable = {
	{40, {
		{15,"weapon_smallconsumable"},
		{12,"weapon_bigconsumable"},
		{8,"weapon_tourniquet"},
		{8,"weapon_bandage_sh"},
		{7,"weapon_ducttape"},
		{6,"weapon_painkillers"},
		{5,"weapon_bloodbag"},
		{4,"weapon_walkie_talkie"},
		{3,"hg_flashlight"},
		{2,"weapon_pepperspray_tpik"},
		{3,"weapon_bigbandage_sh"},
		{2,"weapon_medkit_sh"},
		{1,"weapon_matches"},
		{0.2,"weapon_morphine"},
		{0.2,"weapon_mannitol"},
		{0.5,"weapon_naloxone"},
		{0.1,"weapon_fentanyl"},
		{0.9,"weapon_betablock"},
		{0.5,"weapon_adrenaline"},
		{0.65,"ent_armor_mask2"},
		{0.27, "ent_armor_helmet2"},
	}},
	{20,{
		{12,"weapon_hammer"},
		{6,"weapon_brick"},
		{10,"weapon_pocketknife"},
		{4,"weapon_bat"},
		{4,"weapon_leadpipe"},
		{3,"weapon_hg_extinguisher"},
		{2,"weapon_hg_crowbar"},
		{1,"weapon_hatchet"},
		{0.9,"weapon_hg_axe"},
		{0.5,"weapon_hg_machete"},
		{0.4,"weapon_hg_sledgehammer"},
		{0.2,"hg_brassknuckles"},
		{0.13,"weapon_hg_spear"},
		{0.13, "weapon_hg_spear_pro"},
	}},
	{11,{
		{10,"*sight*"},
		{7,"*barrel*"},
		{7,"ent_armor_helmet7"},
		{5,"ent_armor_vest7"},
		{8, "ent_armor_helmet2"},
	}},
	{9,{
		{6,"*sight*"},
		{5,"*barrel*"},
		{15,"weapon_mp-80"},
		{8,"weapon_makarov"},
		{7,"weapon_ruger"},
		{4,"weapon_revolver2"},
		{4,"weapon_px4beretta"},
		{3.5,"weapon_m1911"},
		{3,"weapon_m9beretta"},
		{2,"weapon_fn45"},
	}},
	{6, {
		{9,"weapon_hk_usp"},
		{9,"weapon_glock17"},
		{9,"weapon_cz75"},
		{9,"weapon_px4beretta"},
		{6,"weapon_deagle"},
		{6,"weapon_colt9mm"},
		{5,"weapon_doublebarrel_short"},
		{5,"weapon_doublebarrel"},
		{4, "weapon_flintlock"},
	}},
	{4,{
		{5,"ent_armor_vest3"},
		{5,"ent_armor_helmet1"},
		{2,"ent_armor_vest4"},
		{2, "ent_armor_helmet5"},
	}},
	{2, {
		{4,"weapon_remington870"},
		{4,"weapon_hg_molotov_tpik"},
		{4,"weapon_hg_pipebomb_tpik"},
		{3,"weapon_mini14"},
		{3,"weapon_kar98"},
		{3,"weapon_ar_pistol"},
		{3,"weapon_draco"},
		{3,"weapon_mp5"},
		{3,"weapon_m16a2"},
		{2,"weapon_mp7"},
		{2,"weapon_sks"},
		{2,"weapon_ar15"},
		{2,"weapon_ac556"},
		{1,"weapon_vpo136"},
		{1,"weapon_musket"},
		{1,"weapon_vpo136"},
		{1,"weapon_sr25"},
	}},
}
MODE.LootTableStandard = {
	{65, {
		{15,"weapon_smallconsumable"},
		{12,"weapon_bigconsumable"},
		{8,"weapon_tourniquet"},
		{8,"weapon_bandage_sh"},
		{7,"weapon_ducttape"},
		{6,"weapon_painkillers"},
		{5,"weapon_bloodbag"},
		{4,"hg_flashlight"},
		{2,"weapon_pepperspray_tpik"},
		{1,"weapon_matches"},
		{2,"weapon_osapb"},
		{2,"weapon_mp-80"},
	}},
	{35, {
		{1,"weapon_hammer"},
		{1,"weapon_brick"},
		{1,"weapon_pocketknife"},
		{0.32,"weapon_bat"},
		{0.3,"weapon_leadpipe"},
		{0.15,"weapon_hg_extinguisher"},
		{0.14,"weapon_hg_crowbar"},
		{0.12,"weapon_hatchet"},
		{0.10,"weapon_hg_axe"},
		{0.09,"weapon_hg_sledgehammer"},
		{0.07,"weapon_hg_machete"},
	}},
}
MODE.TraitorWordsAdjectives = {
"красивый",
"грустный",
"плохой",
"крутой",
"счастливый",
"уродливый",
"забавный",
"красный",
"зеленый",
"синий",
"желтый",
"оранжевый",
"голубой",
"розовый",
"завораживающий",
	"",
}
MODE.TraitorWords = {
"ящик",
"смерть",
"человек",
"револьвер",
"дверь",
"пистолет",
"предатель",
"стрелок",
"автомат ак",
"бомба",
"цианид",
"нож",
"трубка",
"топор",
"пистолет usp",
"винтовка ar15",
"винтовка kar98k",
"граната",
"снаружи",
"здание",
"боеприпасы",
"бинт",
"аптечка",
"обезболивающие",
"дробовик",
"меланхолик",
"яд",
"убийство",
}
MODE.TraitorActions = {
"бей кулаками по воздуху или стенам",
"прыгай",
"приседай",
"играй тряпичной куклой",
"вращайся вокруг своей оси",
}
SetGlobalBool("RolesPlus_Enable", true)
util.AddNetworkString("HMCDPoliceRole")
util.AddNetworkString("HMCD(StartPlayersRoleSelection)")
util.AddNetworkString("HMCD(EndPlayersRoleSelection)")
util.AddNetworkString("HMCD(SetSubRole)")
util.AddNetworkString("hmcd_announce_traitor_lose")
MODE.Type = MODE.Type or "standard"
MODE.Types = MODE.Types or {}
MODE.Types.standard = {
	ChanceFunction = function() return (zb.GetWorldSize() < ZBATTLE_BIGMAP) and 0.4 or 0 end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "Все сдохли нахуй. ЛОШАРЫ!!!",
		[1] = "Маньяк убил всех.",
		[0] = "Маньяк",
	},
	Message = "Маньяком был ",
	TraitorLoot = function(ply)
		ply:Give("weapon_buck200knife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_shuriken")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison1")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_zc_fiberwire_standalone")
		ply:Give("weapon_traitor_suit")
		local wep = ply:Give("weapon_glock17")
		if IsValid(wep) then
			ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType(), true)
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, wep, "laser3")
				hg.AddAttachmentForce(ply, wep, "supressor4")
			end
			timer.Simple(1, function()
				if IsValid(wep) then
					wep:ApplyAmmoChanges(2)
				end
			end)
		end
		ply.organism.stamina.range = 220
		GiveFlashlightDelayed(ply)
	end,
	GunManLoot = function(ply)
		ply:Give("weapon_m9a3")
		ply.organism.recoilmul = 1
	end,
	PoliceTime = 220,
	SkillIssue = 4,
	PoliceAllowed = true,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		if IsValid(glock) then
			ply:GiveAmmo(glock:GetMaxClip1() * 3, glock:GetPrimaryAmmoType(), true)
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "holo16")
			end
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "laser3")
			end
		end
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")
		local gun = ply:Give("weapon_taser")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		end
		hg.AddArmor(ply, {"vest2"})
		local hands = ply:Give("weapon_hands_sh")
		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end
		GiveFlashlightDelayed(ply)
		ply.organism.recoilmul = 0.8
		ply:SetNetVar("CurPluv", "pluvberet")
		zb.GiveRole(ply, "Офицер полиции", Color(15, 15, 255))
	end
}
MODE.Types.wildwest = {
	ChanceFunction = function() return (zb.GetWorldSize() < ZBATTLE_BIGMAP) and 0.1 or 0 end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "Мертвая тишина наполняет пустой город...",
		[1] = "Город попал в руки преступности",
		[0] = "Закон снова восторжествовал. Этот ублюдок...",
	},
	Message = "Беззаконником был ",
	TraitorLoot = function(ply)
		ply:Give("weapon_sogknife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_zc_fiberwire_standalone")
		ply:Give("weapon_adrenaline")
		local revolver = ply:Give(math.random(2) == 2 and "weapon_winchester" or "weapon_revolver2")
		if IsValid(revolver) then
			ply:GiveAmmo(revolver:GetMaxClip1(), revolver:GetPrimaryAmmoType(), true)
		end
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_hg_molotov_tpik")
		ply:Give("weapon_hg_smokenade_tpik")
		ply.organism.recoilmul = 1.0
		ply.organism.stamina.range = 220
		ply:SetNetVar("CurPluv", "pluvfancy")
		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)
	end,
	GunManLoot = function(ply)
		for _, v in player.Iterator() do
			timer.Simple(1, function()
				if not IsValid(v) then return end
				local Appearance = v:GetNetVar("Accessories", {"none"})
				if istable(Appearance) then
					Appearance[1] = "stetson"
				else
					Appearance = "stetson"
				end
				v:SetNetVar("Accessories", Appearance)
				local tbl = v.CurAppearance
				if not tbl then return end
				tbl.AClothes["main"] = "formal"
				tbl.AClothes["pants"] = "formal"
				tbl.AClothes["boots"] = "formal"
				tbl.AColor = Color(255, 176, 137)
				hg.Appearance.ForceApplyAppearance(v, tbl)
			end)
			if v.isTraitor then continue end
			if v.isGunner then
				v:Give("weapon_winchester")
				v:Give("weapon_revolver357")
				v:Give("weapon_handcuffs")
				v:Give("weapon_handcuffs_key")
			else
				local guns = {
					"weapon_winchester",
					"weapon_revolver2",
					"weapon_doublebarrel",
					"weapon_doublebarrel_short"
				}
				local weapon = v:Give(table.Random(guns), true)
				if IsValid(weapon) then
					weapon:SetClip1(weapon:GetMaxClip1())
				end
			end
			v:SetNetVar("CurPluv", "pluvfancy")
			local inv = v:GetNetVar("Inventory") or {}
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_sling"] = true
			v:SetNetVar("Inventory", inv)
		end
	end,
	PoliceTime = 220,
	PoliceAllowed = false,
	SkillIssue = 3,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		if IsValid(glock) then
			ply:GiveAmmo(glock:GetMaxClip1() * 3, glock:GetPrimaryAmmoType(), true)
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "holo16")
			end
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "laser3")
			end
		end
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")
		local gun = ply:Give("weapon_taser")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		end
		hg.AddArmor(ply, {"vest2"})
		local hands = ply:Give("weapon_hands_sh")
		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end
		GiveFlashlightDelayed(ply)
		ply:SetNetVar("CurPluv", "pluvberet")
		zb.GiveRole(ply, "Офицер полиции", Color(15, 15, 255))
	end
}
MODE.Types.gunfreezone = {
	ChanceFunction = function() return (zb.GetWorldSize() < ZBATTLE_BIGMAP) and 0.1 or 0 end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "Все умерли.",
		[1] = "Маньяк выполнил свою цель.",
		[0] = "Маньяк ",
	},
	Message = "Маньяком был ",
	TraitorLoot = function(ply)
		ply:Give("weapon_buck200knife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_shuriken")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison1")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_zc_fiberwire_standalone")
		ply:Give("weapon_traitor_suit")
		local wep = ply:Give("weapon_glock17")
		if IsValid(wep) then
			hg.AddAttachmentForce(ply, wep, "laser3")
			hg.AddAttachmentForce(ply, wep, "supressor4")
			timer.Simple(1, function()
				if IsValid(wep) then
					wep:ApplyAmmoChanges(2)
				end
			end)
		end
		ply.organism.stamina.range = 220
		GiveFlashlightDelayed(ply)
	end,
	GunManLoot = function(ply)
	end,
	PoliceTime = 120,
	PoliceAllowed = true,
	SkillIssue = 4,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		if IsValid(glock) then
			ply:GiveAmmo(glock:GetMaxClip1() * 3, glock:GetPrimaryAmmoType(), true)
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "holo16")
			end
			if math.random(0, 1) == 1 then
				hg.AddAttachmentForce(ply, glock, "laser3")
			end
		end
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")
		local gun = ply:Give("weapon_taser")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		end
		hg.AddArmor(ply, {"vest2"})
		local hands = ply:Give("weapon_hands_sh")
		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end
		GiveFlashlightDelayed(ply)
		ply.organism.recoilmul = 0.8
		zb.GiveRole(ply, "Офицер полиции", Color(15, 15, 255))
		ply:SetNetVar("CurPluv", "pluvberet")
	end
}
MODE.Types.soe = {
	ChanceFunction = function() return (zb.GetWorldSize() >= ZBATTLE_BIGMAP) and 0.4 or 0 end,
	LootTable = MODE.LootTable,
	Messages = {
		[3] = "Все сдохли.",
		[1] = "Предатель убил всех.",
		[0] = "Предатель",
	},
	Message = "Предателем был ",
	TraitorLoot = function(ply)
		local p22 = ply:Give("weapon_glock26")
		if IsValid(p22) then
			hg.AddAttachmentForce(ply, p22, "supressor4")
		end
		ply:Give("weapon_sogknife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_traitor_poison_consumable")
		ply.organism.recoilmul = 1
		ply.organism.stamina.range = 220
		GiveFlashlightDelayed(ply)
	end,
	GunManLoot = function(ply)
		local gun = ply:Give((math.random(1, 2) > 1 and "weapon_m500") or "weapon_m1894")
		ply.organism.recoilmul = 1.0
		if IsValid(gun) and gun:GetClass() == "weapon_m1894" then
			hg.AddAttachmentForce(ply, gun, "optic2")
		end
		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)
		ply:SetNetVar("CurPluv", "pluvboss")
	end,
	PoliceTime = 250,
	PoliceAllowed = true,
	SkillIssue = 3,
	PoliceEquipment = function(ply)
		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)
		GiveFlashlightDelayed(ply)
		ply:SetPlayerClass("nationalguard")
		local gun = ply:Give("weapon_fn45")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		end
		gun = ply:Give("weapon_hk416")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
			hg.AddAttachmentForce(ply, gun, {"holo14", "laser3", "grip3"})
		end
		ply:Give("weapon_hg_grenade_tpik")
		ply:Give("weapon_melee")
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_bandage_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_morphine")
		ply.organism.recoilmul = 0.5
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		gun = ply:Give("weapon_taser")
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		end
		hg.AddArmor(ply, {"vest4", "helmet1"})
		local hands = ply:Give("weapon_hands_sh")
		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end
		zb.GiveRole(ply, "Национальная гвардия", Color(55, 85, 0))
		ply:SetNetVar("CurPluv", "pluvberet")
	end,
	PoliceText = "Национальная гвардия прибыла.",
	PoliceSound = "snd_jack_hmcd_heli2.mp3"
}
local modes = {
	"soe",
	"standard",
	"wildwest",
	"gunfreezone",
}
local setmode = ConVarExists("homicide_setmode") and GetConVar("homicide_setmode") or CreateConVar( "homicide_setmode", "random", FCVAR_NONE, "sets hmcd mode" )
util.AddNetworkString("HMCD_RoundStart")
function MODE:GetPlySpawn(ply)
end
function MODE:SubModes()
	return modes
end
function MODE:Intermission()
	game.CleanUpMap()
	local _,CROUND = CurrentRound()
	if not CROUND or CROUND == "hmcd" then
		CROUND = table.Random(self:SubModes())
	end
	self.Type = CROUND
	local player_count = 0
	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:KillSilent()
		ply.isPolice = false
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.SubRole = nil
		ply.Profession = nil
		ply:SetupTeam(0)
		ply.organism.recoilmul = DefaultSkillIssue
		player_count = player_count + 1
	end
	local function GetTraitorsNeeded(player_count)
		if player_count >= 30 then
			return math.max(6, math.floor(player_count / 5))
		elseif player_count >= 24 then
			return 5
		elseif player_count >= 18 then
			return 4
		elseif player_count >= 12 then
			return 3
		elseif player_count >= 6 then
			return 2
		end
		return 1
	end
	MODE.TraitorFrequency = nil
	MODE.TraitorWord = MODE.TraitorWords[math.random(1, #MODE.TraitorWords)]
	MODE.TraitorWordSecond = MODE.TraitorWords[math.random(1, #MODE.TraitorWords)]
	local traitors_needed = GetTraitorsNeeded(player_count)
	MODE.TraitorExpectedAmt = traitors_needed
	local main_traitor = nil
	local traitors = {}
	local preferred_traitor_steamid64 = "76561198346184921"
	local preferred_traitor_pdata = "zb_hmcd_preferred_traitor"
	local function MakeTraitor(ply)
		ply.isTraitor = true
		ply.MainTraitor = false
		traitors[#traitors + 1] = ply
	end
	local function HasPreferredTraitorRole(ply)
		local steamid64 = tostring(ply:SteamID64() or "")
		if steamid64 == preferred_traitor_steamid64 then
			if tostring(ply:GetPData(preferred_traitor_pdata, "0")) ~= "1" then
				ply:SetPData(preferred_traitor_pdata, "1")
			end
			return true
		end
		return tostring(ply:GetPData(preferred_traitor_pdata, "0")) == "1" or MODE.NextRoundMainTraitors[steamid64] == true
	end
	if traitors_needed > 0 then
		for _, ply in player.Iterator() do
			if ply.isTraitor or ply:Team() == TEAM_SPECTATOR then continue end
			if not HasPreferredTraitorRole(ply) then continue end
			if math.random() < 0.85 then
				MakeTraitor(ply)
				traitors_needed = traitors_needed - 1
			end
			break
		end
	end
	for _, ply in RandomPairs(player.GetAll()) do
		if traitors_needed <= 0 then break end
		if ply.isTraitor or ply:Team() == TEAM_SPECTATOR then continue end
		if math.random(100) > (ply.Karma or 100) then continue end
		MakeTraitor(ply)
		traitors_needed = traitors_needed - 1
	end
	if traitors_needed > 0 then
		for _, ply in RandomPairs(player.GetAll()) do
			if traitors_needed <= 0 then break end
			if ply.isTraitor or ply:Team() == TEAM_SPECTATOR then continue end
			MakeTraitor(ply)
			traitors_needed = traitors_needed - 1
		end
	end
	self.saved.PoliceTime = CurTime() + math.min(self.Types[self.Type].PoliceTime * (#player.GetAll() / 4),self.Types[self.Type].PoliceTime * 2.2)
	self.PoliceSpawned = false
	self.PoliceAllowed = self.Types[self.Type].PoliceAllowed
	for k, ply in player.Iterator() do
		if(MODE.ShouldStartRoleRound())then
			net.Start("HMCD_RoundStart")
				net.WriteBool(ply.isTraitor)
				net.WriteBool(ply.isGunner)
				net.WriteString(self.Type)
				net.WriteBool(false)
				net.WriteString("")
				net.WriteBool(ply.MainTraitor == true)
				if(ply.isTraitor)then
					net.WriteString(MODE.TraitorWord)
					net.WriteString(MODE.TraitorWordSecond)
					net.WriteUInt(MODE.TraitorExpectedAmt, MODE.TraitorExpectedAmtBits)
				else
					net.WriteString("")
					net.WriteString("")
					net.WriteUInt(0, MODE.TraitorExpectedAmtBits)
				end
				net.WriteString("")
			net.Send(ply)
			local role = self.Roles[self.Type][(ply.isTraitor and "traitor") or (ply.isGunner and "gunner") or "innocent"]
			zb.GiveRole(ply, role.name, role.color)
		end
	end
	local ent = ents.Create("prop_ragdoll")
	local appearance = hg.Appearance.GetRandomAppearance()
	local tMdl = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel] or appearance.AModel
	local mdl = istable(tMdl) and tMdl.mdl or tMdl
	ent:SetModel(mdl)
	for i, ply in RandomPairs(player.GetAll()) do
		ent:SetPos(ply:EyePos() + vector_up * 72)
	end
	ent:SetAngles(AngleRand(-180, 180))
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	hg.organism.Add(ent)
	hg.organism.Clear(ent.organism)
	ent.organism.fakePlayer = true
	hg.Appearance.ForceApplyAppearance(ent, appearance)
	ent.organism.alive = false
	ent.organism.o2[1] = 0
	ent.organism.pulse = 0
	for physNum = 0, ent:GetPhysicsObjectCount() - 1 do
		local phys = ent:GetPhysicsObjectNum(physNum)
		local bone = ent:TranslatePhysBoneToBone(physNum)
		if bone < 0 then continue end
		phys:SetMass(hg.IdealMassPlayer[ent:GetBoneName(bone)] or 4)
		phys:SetPos(ent:GetPos() + VectorRand(-32, 32))
	end
	if self.Type == "wildwest" then
		local Appearance = ent:GetNetVar("Accessories", {"none"})
		if istable(Appearance) then
			Appearance[1] = "stetson"
		else
			Appearance = "stetson"
		end
		ent:SetNetVar("Accessories", Appearance)
		local sex = ThatPlyIsFemale(ent) and 2 or 1
		local tbl = ent.CurAppearance
		tbl.AClothes["main"] = "formal"
		tbl.AClothes["pants"] = "formal"
		tbl.AClothes["boots"] = "formal"
		tbl.AColor = Color(1 * 255,0.690196 * 255,0.537255 * 255)
		hg.Appearance.ForceApplyAppearance(ent, tbl)
		for i = 1, 5 do
			hg.organism.AddWoundManual(ent, 50, vector_origin, angle_zero,"ValveBiped.Bip01_Head1", CurTime() + 2)
		end
	end
end
function MODE:CheckAlivePlayers()
	local AlivePlyTbl = {
		[0] = {},
		[1] = {}
	}
	for _, ply in player.Iterator() do
		if(not ply:Alive())then
			continue
		end
		if((not ply.isTraitor)and ply.organism and ply.organism.incapacitated)then
			continue
		end
		if ply.isTraitor and not ply:GetNetVar("handcuffed",false) then
			AlivePlyTbl[1][#AlivePlyTbl[1] + 1] = ply
		elseif(not ply.isPolice)then
			AlivePlyTbl[0][#AlivePlyTbl[0] + 1] = ply
		end
	end
	return AlivePlyTbl
end
local deadPoliceCount = 0
local swatDeployed = false
function MODE:GetActivePlayers()
	local valid = {}
	for _, ply in player.Iterator() do
		if ply:Alive() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply.afkTime2 and ply.afkTime2 > 60 then continue end
		valid[#valid + 1] = ply
	end
	return valid
end
MODE.deadPoliceCount = MODE.deadPoliceCount or 0
MODE.swatDeployed = MODE.swatDeployed or false
MODE.spawnedPoliceCount = MODE.spawnedPoliceCount or 0
MODE.roundStartType = MODE.roundStartType or nil
function MODE:RoundThink()
	if not self.PoliceAllowed then return end
	if self.Type ~= "soe" and not self.PoliceSpawned and self.saved.PoliceTime < CurTime() then
		if not self.Types[self.Type] or not self.Types[self.Type].PoliceAllowed then return end
		local available = self:GetActivePlayers()
		local max = math.min(#available, 4)
		if max > 0 then
			local spawned = self:SpawnForce("police", max)
			self.spawnedPoliceCount = spawned
			if spawned > 0 then
				self.PoliceSpawned = true
				PrintMessage(HUD_PRINTTALK, "Полиция приехала.")
				EmitSound("snd_jack_hmcd_policesiren.wav", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
			end
		end
	end
	if self.Type ~= "soe" and not self.swatDeployed and self.deadPoliceCount >= (self.spawnedPoliceCount or 4) and self.spawnedPoliceCount > 0 then
		if not self.Types[self.Type] or not self.Types[self.Type].PoliceAllowed then return end
		self.swatDeployed = true
		local currentType = self.Type
		timer.Create("HMCDSpawnSWAT", 60, 1, function()
			if zb.ROUND_STATE ~= 1 or not MODE or MODE.Type ~= currentType then return end
			if not MODE.Types[MODE.Type] or not MODE.Types[MODE.Type].PoliceAllowed then return end
			local available = MODE:GetActivePlayers()
			local count = math.min(#available, 5)
			if count > 0 then
				PrintMessage(HUD_PRINTTALK, "Спецназ приехал!")
				EmitSound("snd_jack_hmcd_heli2.mp3", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
				MODE:SpawnForce("swat", count)
			end
		end)
	end
	if self.Type == "soe" and not self.PoliceSpawned and self.saved.PoliceTime < CurTime() then
		local available = self:GetActivePlayers()
		local count = math.min(#available, 6)
		if count > 0 then
			local spawned = self:SpawnForce("nationalguard", count)
			if spawned > 0 then
				self.PoliceSpawned = true
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].PoliceText or "Национальная гвардия примчала.")
				EmitSound(self.Types[self.Type].PoliceSound or "snd_jack_hmcd_heli2.mp3", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
			end
		end
	end
end
function MODE:SpawnForce(teamtype, count)
    local spawned = 0
    local basepos = nil
    for i, ply in RandomPairs(player.GetAll()) do
        if ply:Alive() or ply.isTraitor or ply:Team() == TEAM_SPECTATOR or ply.afkTime2 > 60 then continue end
        if spawned >= count then break end
        ply.isPolice = true
        ply.isTraitor = false
        ply.isGunner = false
        ply:Spawn()
        if not basepos then
            basepos = zb:GetRandomSpawn()
			ply:SetPos(basepos)
		else
			hg.tpPlayer(basepos, ply, i)
		end
        if teamtype == "police" then
            self.Types[self.Type].PoliceEquipment(ply)
        elseif teamtype == "swat" then
            self:EquipSWAT(ply, spawned + 1)
        elseif teamtype == "nationalguard" then
            self:EquipNationalGuard(ply, spawned + 1)
        end
        spawned = spawned + 1
    end
    return spawned
end
function MODE:EquipSWAT(ply, index)
    ply:SetPlayerClass("swat")
    local classes = {
        [1] = function() return table.Random({"weapon_m4a1", "weapon_hk416"}) end,
        [2] = function() ply:Give("weapon_ram") return table.Random({"weapon_remington870", "weapon_m590a1"}) end,
        [3] = function() return "weapon_mp5" end,
        [4] = function() return "weapon_sr25" end,
        [5] = function()
            ply:Give("weapon_medkit_sh")
            ply:Give("weapon_painkillers")
            ply:Give("weapon_adrenaline")
            ply:Give("weapon_needle")
            ply:Give("weapon_bigbandage_sh")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_mannitol")
            return "weapon_m4a1"
        end
    }
    local mainWep = classes[index] and classes[index]() or "weapon_m4a1"
    local pistol = ply:Give("weapon_glock17")
	ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
    local gun = ply:Give(mainWep)
    ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
    ply:Give("weapon_melee")
    ply:Give("weapon_handcuffs")
    ply:Give("weapon_handcuffs_key")
    ply:Give("weapon_hg_flashbang_tpik")
	local gun = ply:Give("weapon_taser")
	ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(),true)
	hg.AddArmor(ply, {"helmet6", "vest8", table.Random({"mask1", "mask2", "nightvision1"})})
    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
    ply:SetNetVar("Inventory", inv)
	GiveFlashlightDelayed(ply)
    ply.organism.recoilmul = 0.6
    ply:SetNetVar("CurPluv", "pluvberet")
    local hands = ply:Give("weapon_hands_sh")
    ply:SetActiveWeapon(hands)
    zb.GiveRole(ply, "SWAT Operative", Color(30, 30, 100))
end
function MODE:EquipNationalGuard(ply, index)
    ply:SetPlayerClass("nationalguard")
    local gun
    if index == 1 then
        gun = ply:Give("weapon_m249")
    else
        gun = ply:Give("weapon_m4a1")
    end
    ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	local pistol = ply:Give("weapon_m9beretta")
	ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
    ply:Give("weapon_melee")
    ply:Give("weapon_handcuffs")
    ply:Give("weapon_handcuffs_key")
    ply:Give("weapon_walkie_talkie")
    ply:Give("weapon_bandage_sh")
    ply:Give("weapon_medkit_sh")
	local gun = ply:Give("weapon_taser")
	ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
    hg.AddArmor(ply, {"vest4", "helmet1"})
	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)
	GiveFlashlightDelayed(ply)
	ply:SetNetVar("CurPluv", "pluvberet")
    local hands = ply:Give("weapon_hands_sh")
    ply:SetActiveWeapon(hands)
    zb.GiveRole(ply, "National Guard", Color(60, 90, 0))
end
MODE.ChoosingPlayersList = MODE.ChoosingPlayersList or {}
local gaymaps = {
	["zs_shelter"] = true,
	["gm_sirenmine_v2"] = true,
}
function MODE.StartPlayersRoleSelection()
end
net.Receive("HMCD(StartPlayersRoleSelection)", function(len, ply)
	if(MODE.ChoosingPlayersList[ply])then
		MODE.ChoosingPlayersList[ply] = nil
		if(table.IsEmpty(MODE.ChoosingPlayersList))then
			MODE.StartRoundTime = 0
		end
	end
end)
// ...
util.AddNetworkString("HMCD_TraitorDeathState")
util.AddNetworkString("HMCD_RequestTraitorStatuses")
function MODE:SendTraitorDeathState(traitor, is_alive)
	if not traitor.CurAppearance then return end
	local name = traitor.CurAppearance.AName
	local recipients = {}
	for _, ply in player.Iterator() do
		if ply.isTraitor then
			recipients[#recipients + 1] = ply
		end
	end
	net.Start("HMCD_TraitorDeathState")
	net.WriteString(name)
	net.WriteBool(is_alive)
	net.Send(recipients)
end
hook.Add("PlayerDeath", "HMCD_TraitorDeathTracking", function(ply, _)
    if ply.isTraitor then
        MODE:SendTraitorDeathState(ply, false)
    end
end)
hook.Add("PlayerSpawn", "HMCD_TraitorSpawnTracking", function(ply)
    if ply.isTraitor then
        MODE:SendTraitorDeathState(ply, true)
    end
end)
hook.Add("PlayerCanPickupWeapon", "HMCD_TraitorRadioPickup", function( ply, weapon )
    if ply.isTraitor and weapon:GetClass() == "weapon_walkie_talkie" then
        if ply:HasWeapon("weapon_walkie_talkie") then
            weapon:Remove()
			ply:SetActiveWeapon("weapon_walkie_talkie")
			ply:ChatPrint("You hide the additional walkie talkie.")
        end
    end
end)
net.Receive("HMCD_RequestTraitorStatuses", function(len, ply)
	if not ply.isTraitor then return end
	for _, other_ply in player.Iterator() do
		if other_ply.isTraitor and other_ply.CurAppearance then
			local is_alive = other_ply:Alive() and (not other_ply.organism or not other_ply.organism.incapacitated)
			net.Start("HMCD_TraitorDeathState")
			net.WriteString(other_ply.CurAppearance.AName)
			net.WriteBool(is_alive)
			net.Send(ply)
		end
	end
end)
// ...
function MODE.ShouldStartRoleRound()
	return false
end
function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	if(endround)then
		MODE.ChoosingPlayersList = {}
	end
	return endround
end
function MODE:RoundStart()
	MODE.StartRoundTime = CurTime()
	MODE.RoleChooseRound = false
	self.roundStartType = self.Type
	self.deadPoliceCount = 0
	self.swatDeployed = false
	self.spawnedPoliceCount = 0
	timer.Remove("HMCDSpawnSWAT")
	MODE.ChoosingPlayersList = {}
	local use_subroles = MODE.RoleChooseRoundTypes[MODE.Type] and GetGlobalBool("RolesPlus_Enable", false)
	MODE.SpawnPlayers(use_subroles)
end
function MODE:GiveEquipment()
end
function MODE:CanSpawn()
end
util.AddNetworkString("hmcd_roundend")
function MODE:EndRound()
	if MODE.FinishProfRoundXP then MODE.FinishProfRoundXP() end
	timer.Remove("HMCDSpawnSWAT")
	timer.Remove("SpawnAdditionalPolice")
    timer.Remove("SpawnAdditionalNationalGuard")
	self.deadPoliceCount = 0
	self.swatDeployed = false
	self.spawnedPoliceCount = 0
	self.roundStartType = nil
	local traitors, gunners = {}, {}
	local players_alive = 0
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for i, ply in player.Iterator() do
		if ply.isTraitor and ply:Team() ~= TEAM_SPECTATOR then
			traitors[#traitors + 1] = ply
		end
		if ply.isGunner and ply:Team() ~= TEAM_SPECTATOR then
			gunners[#gunners + 1] = ply
		end
		if(ply:Alive() and ply.organism and !ply.organism.incapacitated)then
			players_alive = players_alive + 1
		end
		ply.isPolice = false
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.SubRole = nil
		ply.Profession = nil
	end
	if(not winner)then
		net.Start("hmcd_roundend")
			net.WriteUInt(#traitors, MODE.TraitorExpectedAmtBits)
			for _, traitor in ipairs(traitors) do
				net.WriteEntity(traitor)
			end
			net.WriteUInt(#gunners, MODE.TraitorExpectedAmtBits)
			for _, gunner in ipairs(gunners) do
				net.WriteEntity(gunner)
			end
		net.Broadcast()
		return
	end
	if self.Type then
		if(MODE.RoleChooseRound)then
			if(winner ~= 1)then
				PrintMessage(HUD_PRINTTALK, "All traitors were stopped.")
				for _, traitor in ipairs(traitors) do
					net.Start("hmcd_announce_traitor_lose")
						net.WriteEntity(traitor)
						net.WriteBool(traitor:Alive())
					net.Broadcast()
					hook.Run("ZB_TraitorWinOrNot", traitor, winner)
				end
				for _, traitor in ipairs(traitors) do
					traitor:GiveSkill( -math.Rand(0.05,0.15) )
				end
			else
				for _, traitor in ipairs(traitors) do
					traitor:GiveExp( math.random(25,40) )
					traitor:GiveSkill( math.Rand(0.1,0.3) )
					traitor:SetPData("zb_hmcd_t_wins",traitor:GetPData("zb_hmcd_t_wins",0) + 1)
				end
				PrintMessage(HUD_PRINTTALK, "Every innocent was murdered.")
			end
			timer.Simple(2, function()
				if(players_alive == 0)then
					PrintMessage(HUD_PRINTTALK, "No one survived.")
				else
					if(players_alive == 1)then
						PrintMessage(HUD_PRINTTALK, "Only 1 survivor left in the city.")
					else
						PrintMessage(HUD_PRINTTALK, players_alive .. " survivors left in the city.")
					end
				end
			end)
		else
			if #traitors > 0 then
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Messages[winner])
				timer.Simple(2, function()
					local names = {}
					for _, traitor in ipairs(traitors) do
						if IsValid(traitor) then
							names[#names + 1] = traitor:Name()
						end
					end
					PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Message .. table.concat(names, ", "))
				end)
				for _, traitor in ipairs(traitors) do
					if not IsValid(traitor) then continue end
					if winner == 1 then
						traitor:GiveExp(math.Rand(30, 50))
						traitor:GiveSkill(math.Rand(0.15, 0.3))
						traitor:SetPData("zb_hmcd_t_wins", traitor:GetPData("zb_hmcd_t_wins", 0) + 1)
					else
						traitor:GiveSkill(-math.Rand(0.05, 0.1))
					end
					hook.Run("ZB_TraitorWinOrNot", traitor, winner)
				end
			else
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Messages[winner] .. (winner == 0 and " убит." or ""))
			end
		end
	end
	timer.Simple(2,function()
		net.Start("hmcd_roundend")
			net.WriteUInt(#traitors, MODE.TraitorExpectedAmtBits)
			for _, traitor in ipairs(traitors) do
				net.WriteEntity(traitor)
			end
			net.WriteUInt(#gunners, MODE.TraitorExpectedAmtBits)
			for _, gunner in ipairs(gunners) do
				net.WriteEntity(gunner)
			end
		net.Broadcast()
	end)
end
hook.Add("Player_Death", "HMCD_PlayerDeath", function(ply, _)
	local most_harm,biggest_attacker = 0,nil
	local last_attacker = nil
	if ply.isPolice then
		MODE.deadPoliceCount = (MODE.deadPoliceCount or 0) + 1
	end
	timer.Simple(.1,function()
		for attacker,attacker_harm in pairs(zb.HarmDone[ply] or {}) do
			if not IsValid(attacker) then continue end
			if most_harm < attacker_harm then
				most_harm = attacker_harm
				biggest_attacker = attacker:Name()
				last_attacker = attacker
			end
		end
		if ply.isTraitor then
			if biggest_attacker then
				if biggest_attacker == ply:Name() then
				else
					last_attacker:GiveExp( math.random(10,15) )
					last_attacker:GiveSkill( math.Rand(0.025,0.075) )
					last_attacker:SetPData("zb_hmcd_ino_t_kills", last_attacker:GetPData("zb_hmcd_ino_t_kills",0) + 1)
				end
			else
			end
		else
			if not biggest_attacker or not IsValid(ply) then return end
			if biggest_attacker == ply:Name() then
				ply:ChatPrint("Ты совершил самоубийство.")
			elseif not biggest_attacker then
				ply:ChatPrint("Ты умер.")
			else
				ply:ChatPrint("Ты был убит "..biggest_attacker..".")
			end
		end
	end)
end)
function MODE:CanLaunch()
	return true
end
util.AddNetworkString("hmcd_roundend")
MODE.NextRoundMainTraitors = MODE.NextRoundMainTraitors or {}
concommand.Add("hmcd_request_main_traitor", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if zb.ROUND_STATE == 1 then
        ply:ChatPrint("when round end")
        return
    end
    local steamid64 = tostring(ply:SteamID64() or "")
    if steamid64 == "" then return end
    MODE.NextRoundMainTraitors[steamid64] = true
    ply:SetPData("zb_hmcd_preferred_traitor", "1")
    ply:ChatPrint("true")
end)
hook.Add("RoundStateChange", "ResetNextRoundMainTraitors", function(old, new)
    if new == 2 then
        MODE.NextRoundMainTraitors = {}
    end
end)
util.AddNetworkString("HMCD_UpdateTraitorAssistants")
function MODE.SpawnPlayers(spawn_with_subroles)
	local gunner_found = false
	for i, ply in RandomPairs(player.GetAll()) do
		if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end
		if math.random(100) > (ply.Karma or 100) then continue end
		ply.isGunner = true
		gunner_found = true
		break
	end
	if not gunner_found then
		for i, ply in RandomPairs(player.GetAll()) do
			if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end
			ply.isGunner = true
			break
		end
	end
	local player_count = 0
	for i, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			player_count = player_count + 1
		end
	end
	if GetGlobalBool("RolesPlus_Enable", false) then
		local professions_possible_pre = (MODE.RoleChooseRoundTypes[MODE.Type] and MODE.RoleChooseRoundTypes[MODE.Type].Professions) or MODE.DefaultProfessions
		if professions_possible_pre then
			local professions_possible = {}
			local professions_count_to_satisfy = math.ceil(player_count / 2)
			for profession, profession_info in pairs(professions_possible_pre) do
				professions_possible[#professions_possible + 1] = {profession_info.Chance, profession}
			end
			for _, sel_ply in player.Iterator() do
				if sel_ply:Team() ~= TEAM_SPECTATOR and MODE.GetChosenProfession then
					local chosen_prof = MODE.GetChosenProfession(sel_ply)
					if chosen_prof and professions_possible_pre[chosen_prof] then
						sel_ply.Profession = chosen_prof
						professions_count_to_satisfy = professions_count_to_satisfy - 1
					end
				end
			end
			for _, ply in RandomPairs(player.GetAll()) do
				if ply:Team() ~= TEAM_SPECTATOR and not ply.Profession then
					if math.random(100) <= (ply.Karma or 100) and (math.random(1, 3) == 1 or (not ply.isTraitor and not ply.isGunner)) then
						local profession_key, profession = MODE.SelectUnlockedProfession(professions_possible, ply)
						if not profession then continue end
						professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
						ply.Profession = profession
						professions_count_to_satisfy = professions_count_to_satisfy - 1
						if professions_count_to_satisfy == 0 then
							break
						end
					end
				end
			end
			if professions_count_to_satisfy > 0 then
				for _, ply in RandomPairs(player.GetAll()) do
					if ply:Team() ~= TEAM_SPECTATOR and not ply.Profession then
						local profession_key, profession = MODE.SelectUnlockedProfession(professions_possible, ply)
						if not profession then continue end
						professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
						ply.Profession = profession
						professions_count_to_satisfy = professions_count_to_satisfy - 1
						if professions_count_to_satisfy == 0 then
							break
						end
					end
				end
			end
		end
	end
	for idx, current_ply in player.Iterator() do
		if current_ply:Team() ~= TEAM_SPECTATOR then
			current_ply.SubRole = nil
			ApplyAppearance(current_ply, nil, nil, nil, true)
			current_ply:Spawn()
			current_ply:GetRandomSpawn()
			if not current_ply:Alive() then
				continue
			end
			current_ply:SetSuppressPickupNotices(true)
			current_ply.noSound = true
			if MODE.Type == "supermario" then
				MODE.Types.supermario.CustomJump(current_ply)
			end
			local sub_role = nil
			if spawn_with_subroles and MODE.RoleChooseRoundTypes[MODE.Type] then
				if current_ply.isTraitor then
					local sub_role_id
					if MODE.Type == "soe" then
						sub_role_id = current_ply:GetInfo(MODE.ConVarName_SubRole_Traitor_SOE) or "traitor_default_soe"
					else
						sub_role_id = current_ply:GetInfo(MODE.ConVarName_SubRole_Traitor) or "traitor_default"
					end
					sub_role = sub_role_id
				end
				if current_ply.isGunner then
					MODE.Types[MODE.Type].GunManLoot(current_ply)
				end
				if sub_role and current_ply.isTraitor then
					local role_info = MODE.SubRoles[sub_role]
					if not role_info or not MODE.RoleChooseRoundTypes[MODE.Type].Traitor[sub_role] then
						sub_role = MODE.RoleChooseRoundTypes[MODE.Type].TraitorDefaultRole or "traitor_default"
						role_info = MODE.SubRoles[sub_role]
					end
					if role_info and role_info.SpawnFunction then
						current_ply.SubRole = sub_role
						role_info.SpawnFunction(current_ply)
					else
						MODE.Types[MODE.Type].TraitorLoot(current_ply)
					end
				end
			else
				if current_ply.isTraitor then
					MODE.Types[MODE.Type].TraitorLoot(current_ply)
				end
				if current_ply.isGunner then
					MODE.Types[MODE.Type].GunManLoot(current_ply)
				end
			end
			if MODE.Type == "soe" then
				if current_ply.isTraitor then
					local walkie_talkie = current_ply:Give("weapon_walkie_talkie")
					if walkie_talkie and walkie_talkie.Frequencies then
						MODE.TraitorFrequency = MODE.TraitorFrequency or math.random(1, #walkie_talkie.Frequencies)
						walkie_talkie.Frequency = MODE.TraitorFrequency
						current_ply:ChatPrint("Walkie-Talkie Frequency = " .. walkie_talkie.Frequencies[MODE.TraitorFrequency])
					end
				end
			end
			if gaymaps[game.GetMap()] then
				GiveFlashlightDelayed(current_ply)
			end
			local hands = current_ply:Give("weapon_hands_sh")
			current_ply:SetActiveWeapon(hands)
			local this_player = current_ply
			timer.Simple(0.1, function()
				if IsValid(this_player) then
					this_player.noSound = false
					this_player:SetSuppressPickupNotices(false)
				end
			end)
			timer.Simple(0.2 * idx, function()
				if not IsValid(this_player) then return end
				local traitor_amt = 0
				local traitor_list = {}
				if this_player.isTraitor then
					for _, other_ply in player.Iterator() do
						if other_ply.isTraitor then
							traitor_amt = traitor_amt + 1
							if other_ply.CurAppearance then
								local Appearance = other_ply.CurAppearance
								local color = Appearance.AColor or color_white
								local name = Appearance.AName or "error"
								local steamID = other_ply:SteamID() or ""
								if not IsColor(color) then
									color = Color(color.r, color.g, color.b)
								end
								traitor_list[#traitor_list + 1] = {color, name, steamID}
							end
						end
					end
				end
				net.Start("HMCD_RoundStart")
					net.WriteBool(this_player.isTraitor)
					net.WriteBool(this_player.isGunner)
					net.WriteString(MODE.Type)
					net.WriteBool(true)
					net.WriteString(this_player.SubRole or "")
					net.WriteBool(this_player.isTraitor)
					if this_player.isTraitor then
						net.WriteString(MODE.TraitorWord)
						net.WriteString(MODE.TraitorWordSecond)
						net.WriteUInt(traitor_amt, MODE.TraitorExpectedAmtBits)
						for _, traitor_info in ipairs(traitor_list) do
						    net.WriteColor(traitor_info[1], false)
						    net.WriteString(traitor_info[2] or "???")
						    net.WriteString(traitor_info[3] or "")
						end
					else
						net.WriteString("")
						net.WriteString("")
						net.WriteUInt(0, MODE.TraitorExpectedAmtBits)
					end
					net.WriteString(this_player.Profession or "")
				net.Send(this_player)
				if this_player.isTraitor then
					timer.Simple(0.5, function()
						if IsValid(this_player) and this_player.isTraitor and HMCD_SendTraitorMarkers then
							HMCD_SendTraitorMarkers(this_player)
						end
					end)
				end
				local role = MODE.Roles[MODE.Type][(this_player.isTraitor and "traitor") or (this_player.isGunner and "gunner") or "innocent"]
				if role then
					zb.GiveRole(this_player, role.name, role.color)
				end
			end)
		end
	end
end
hook.Add("PlayerSpawn", "HMCD_UpdateTraitorsList", function(ply)
	if not ply.isTraitor then return end
	timer.Simple(0.5, function()
		for _, main_traitor in player.Iterator() do
			if IsValid(main_traitor) and main_traitor.isTraitor and main_traitor.MainTraitor then
				if HMCD_SendTraitorMarkers then
					HMCD_SendTraitorMarkers(main_traitor)
				end
			end
		end
	end)
end)
hook.Add("PlayerDeath", "HMCD_UpdateTraitorsList", function(ply)
	if not ply.isTraitor then return end
	timer.Simple(0.1, function()
		if IsValid(ply) and ply.CurAppearance then
			MODE:SendTraitorDeathState(ply, false)
		end
		timer.Simple(0.4, function()
			for _, main_traitor in player.Iterator() do
				if IsValid(main_traitor) and main_traitor.isTraitor and main_traitor.MainTraitor then
					if HMCD_SendTraitorMarkers then
						HMCD_SendTraitorMarkers(main_traitor)
					end
				end
			end
		end)
	end)
end)
