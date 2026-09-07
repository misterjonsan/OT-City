local Category = "STALKER"

local NPC = {	Name = "Trenchcoat Bandit (Face) (Ally)",
Class = "npc_citizen",
Model = "models/npc/stalker/TrenchBandit.mdl",
Health = "100",
KeyValues = { citizentype = 4 },
Category = Category	}


list.Set( "NPC", "npc_TrenchBandit_ally", NPC )

local NPC = {	Name = "Trenchcoat Bandit (Face) (Hostile)",
Class = "npc_combine_s",
Model = "models/npc/stalker/TrenchBandit.mdl",
Health = "100",
Numgrenades = "4",
Category = Category	}


list.Set( "NPC", "npc_TrenchBandit_hostile", NPC )