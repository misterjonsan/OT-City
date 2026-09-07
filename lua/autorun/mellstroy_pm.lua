player_manager.AddValidModel( "Mellstroy", "models/mellstroy/mellstroy.mdl" )
list.Set( "PlayerOptionsModel", "Mellstroy", "models/mellstroy/mellstroy.mdl" )
player_manager.AddValidHands( "Mellstroy", "models/mellstroy/mellstroy_carms.mdl", 0, "00000000" )

--Add NPC
local Category = "Mellstroy"

local NPC = { 	Name = "Mellstroy Friendly", 
				Class = "npc_citizen",
				Model = "models/mellstroy/mellstroy.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Mellstroy Friendly", NPC )

local Category = "Mellstroy"

local NPC = { 	Name = "Mellstroy Angry", 
				Class = "npc_combine",
				Model = "models/mellstroy/mellstroy.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Mellstroy Angry", NPC )