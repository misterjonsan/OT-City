list.Set( "PlayerOptionsModel", "Plague Doctor", "models/player/doktor_haus/plague_doctor.mdl" )
list.Set( "PlayerOptionsAnimations", "Plague Doctor", { "pose_standing_02", "menu_walk", "pose_ducking_01" } )	-- Randomly picks from these sequences when viewing player model select menu. See full sequence list in HLMV by loading models/player/kleiner.mdl.
player_manager.AddValidModel( "Plague Doctor", "models/player/doktor_haus/plague_doctor.mdl" )
player_manager.AddValidHands( "Plague Doctor", "models/player/doktor_haus/plague_doctor_arms.mdl", 0, "00000000" )

local Category = "Doktor haus' NPCs"
local NPC = { 	Name = "Plague Doctor (Enemy)",
				Class = "npc_combine_s",
				Model = "models/npc/doktor_haus/plague_doctor_combine.mdl",
				Weapons = { "weapon_ar2", "weapon_pistol", "weapon_shotgun", "weapon_smg1", "weapon_stunstick" },
				Health = "100",
				Squadname = "PLAGUE",
				Numgrenades = "2",
                                Category = Category    }
list.Set( "NPC", "npc_plague_doctor_e", NPC )
local NPC = { 	Name = "Plague Doctor (Ally)",
				Class = "npc_citizen",
				Model = "models/npc/doktor_haus/plague_doctor_rebel.mdl",
				Weapons = { "weapon_pistol", "weapon_ar2", "weapon_smg1", "weapon_ar2", "weapon_shotgun" },
				Health = "300",			
				KeyValues = { citizentype = CT_UNIQUE },
                                Category = Category    }       
list.Set( "NPC", "npc_plague_doctor_a", NPC )