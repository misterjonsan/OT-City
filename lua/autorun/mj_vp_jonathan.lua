player_manager.AddValidModel( "Jonathan Reid", 				"models/players/mj_vp_jonathan.mdl" )
list.Set( "PlayerOptionsModel",  "Jonathan Reid",				"models/players/mj_vp_jonathan.mdl" )
player_manager.AddValidHands(	"Jonathan Reid", "models/players/vp_jonathan_arms.mdl", 0, "00000000" )

local Category = "Vampyr" 

local NPC = { Name = "Jonathan Reid - Friendly", 
	      Class = "npc_citizen", 
	      Model = "models/players/mj_vp_jonathan_npc.mdl", 
	      Health = "100", 
	      KeyValues = { citizentype = 4 }, 
	      Category = Category
} 

list.Set( "NPC", "mj_vp_jonathan_npc", NPC )
 
local NPC = {   Name = "Jonathan Reid - Hostile", 
                Class = "npc_combine",
                Model = "models/players/mj_vp_jonathan_enemy.mdl",
                Health = "100", 
                Category = Category 
}
                               
list.Set( "NPC", "mj_vp_jonathan_enemy", NPC )


