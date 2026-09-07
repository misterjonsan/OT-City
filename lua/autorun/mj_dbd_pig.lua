player_manager.AddValidModel( "Amanda Young (The Pig)", 				"models/players/mj_dbd_pig.mdl" )
list.Set( "PlayerOptionsModel",  "Amanda Young (The Pig)",				"models/players/mj_dbd_pig.mdl" )
player_manager.AddValidHands( "Amanda Young (The Pig)", "models/players/dbd_pig_arms.mdl", 0, "00000000" )

player_manager.AddValidModel( "Amanda Young (The Pig) 1", 				"models/players/mj_dbd_pig_1.mdl" )
list.Set( "PlayerOptionsModel",  "Amanda Young (The Pig) 1",				"models/players/mj_dbd_pig_1.mdl" )
player_manager.AddValidHands( "Amanda Young (The Pig) 1", "models/players/dbd_pig_1_arms.mdl", 0, "00000000" )

player_manager.AddValidModel( "Amanda Young (The Pig) 2", 				"models/players/mj_dbd_pig_2.mdl" )
list.Set( "PlayerOptionsModel",  "Amanda Young (The Pig) 2",				"models/players/mj_dbd_pig_2.mdl" )
player_manager.AddValidHands( "Amanda Young (The Pig) 2", "models/players/dbd_pig_2_arms.mdl", 0, "00000000" )

local Category = "Dead by Daylight" 

local NPC = { Name = "Amanda Young (The Pig) - Friendly", 
	      Class = "npc_citizen", 
	      Model = "models/players/mj_dbd_pig_npc.mdl", 
	      Health = "100", 
	      KeyValues = { citizentype = 4 }, 
	      Category = Category
} 

list.Set( "NPC", "mj_dbd_pig_npc", NPC )
 
local NPC = {   Name = "Amanda Young (The Pig) - Hostile", 
                Class = "npc_combine",
                Model = "models/players/mj_dbd_pig_enemy.mdl",
                Health = "100", 
                Category = Category 
}
                               
list.Set( "NPC", "mj_dbd_pig_enemy", NPC )

local NPC = { Name = "Amanda Young (The Pig) 1 - Friendly", 
	      Class = "npc_citizen", 
	      Model = "models/players/mj_dbd_pig_1_npc.mdl", 
	      Health = "100", 
	      KeyValues = { citizentype = 4 }, 
	      Category = Category
} 

list.Set( "NPC", "mj_dbd_pig_1_npc", NPC )
 
local NPC = {   Name = "Amanda Young (The Pig) 1 - Hostile", 
                Class = "npc_combine",
                Model = "models/players/mj_dbd_pig_1_enemy.mdl",
                Health = "100", 
                Category = Category 
}
                               
list.Set( "NPC", "mj_dbd_pig_1_enemy", NPC )


local NPC = { Name = "Amanda Young (The Pig) 2 - Friendly", 
	      Class = "npc_citizen", 
	      Model = "models/players/mj_dbd_pig_2_npc.mdl", 
	      Health = "100", 
	      KeyValues = { citizentype = 4 }, 
	      Category = Category
} 

list.Set( "NPC", "mj_dbd_pig_2_npc", NPC )
 
local NPC = {   Name = "Amanda Young (The Pig) 2 - Hostile", 
                Class = "npc_combine",
                Model = "models/players/mj_dbd_pig_2_enemy.mdl",
                Health = "100", 
                Category = Category 
}
                               
list.Set( "NPC", "mj_dbd_pig_2_enemy", NPC )
