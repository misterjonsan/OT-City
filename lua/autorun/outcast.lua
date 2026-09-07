player_manager.AddValidModel( "Outcast Adam", "models/Outcasts/a/Outcast_Adam.mdl" )
list.Set( "PlayerOptionsModel", "Outcast Adam", "models/Outcasts/a/Outcast_Adam.mdl" )
player_manager.AddValidHands( "Outcast Adam", "models/Outcasts/carms/otc_carms.mdl", 0, "00000000" )

player_manager.AddValidModel( "Outcast B", "models/Outcasts/b/Outcast_Ceasar.mdl" )
list.Set( "PlayerOptionsModel", "Outcast B", "models/Outcasts/b/Outcast_Ceasar.mdl" )
player_manager.AddValidHands( "Outcast B", "models/Outcasts/carms/otc_carms.mdl", 0, "00000000" ) 

player_manager.AddValidModel( "Outcast C", "models/Outcasts/c/Outcast_Victor.mdl" )
list.Set( "PlayerOptionsModel", "Outcast C", "models/Outcasts/c/Outcast_Victor.mdl" )
player_manager.AddValidHands( "Outcast C", "models/Outcasts/carms/otc_carms.mdl", 0, "00000000" ) 

--Add NPC
local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Adam Friendly", 
				Class = "npc_citizen",
				Model = "models/Outcasts/a/Outcast_Adam.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Outcasts Adam Friendly", NPC )

local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Adam Angry", 
				Class = "npc_combine",
				Model = "models/Outcasts/a/Outcast_Adam.mdl",
				Health = "100",
                                Category = Category    }

list.Set( "NPC", "Outcasts Adam Angry", NPC )

--Add NPC
local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Ceasar Friendly", 
				Class = "npc_citizen",
				Model = "models/Outcasts/b/Outcast_Ceasar.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Outcasts Ceasar Friendly", NPC )

local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Ceasar Angry", 
				Class = "npc_combine",
				Model = "models/Outcasts/b/Outcast_Ceasar.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Outcasts Ceasar Angry", NPC )

--Add NPC
local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Victor Friendly", 
				Class = "npc_citizen",
				Model = "models/Outcasts/c/Outcast_Victor.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Outcasts Victor Friendly", NPC )

local Category = "Outcasts NPC`s"

local NPC = { 	Name = "Outcasts Victor Angry", 
				Class = "npc_combine",
				Model = "models/Outcasts/c/Outcast_Victor.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "Outcasts Victor Angry", NPC )