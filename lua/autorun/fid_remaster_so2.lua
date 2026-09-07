player_manager.AddValidModel( "F.I.D. Archie", "models/fidremaster/a/fid_archie.mdl" )
list.Set( "PlayerOptionsModel", "F.I.D. Archie", "models/fidremaster/a/fid_archie.mdl" )
player_manager.AddValidHands( "F.I.D. Archie", "models/fidremaster/carms/FID_remastered_carms.mdl", 0, "00000000" )

player_manager.AddValidModel( "F.I.D. Lincoln", "models/fidremaster/l/fid_lincoln.mdl" )
list.Set( "PlayerOptionsModel", "F.I.D. Lincoln", "models/fidremaster/l/fid_lincoln.mdl" )
player_manager.AddValidHands( "F.I.D. Lincoln", "models/fid_remaster/carms/FID_lncln_carms.mdl", 0, "00000000" ) 

player_manager.AddValidModel( "F.I.D. Michael", "models/fidremaster/b/fid_michael.mdl" )
list.Set( "PlayerOptionsModel", "F.I.D. Michael", "models/fidremaster/b/fid_michael.mdl" )
player_manager.AddValidHands( "F.I.D. Michael", "models/fidremaster/carms/FID_remastered_carms.mdl", 0, "00000000" ) 

player_manager.AddValidModel( "F.I.D. Jacob", "models/fidremaster/c/fid_lincoln.mdl" )
list.Set( "PlayerOptionsModel", "F.I.D. Jacob", "models/fidremaster/c/fid_lincoln.mdl" )
player_manager.AddValidHands( "F.I.D. Jacob", "models/fidremaster/carms/FID_remastered_carms.mdl", 0, "00000000" ) 

--Add NPC
local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Archie Friendly", 
				Class = "npc_citizen",
				Model = "models/fidremaster/a/fid_archie.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Archie Friendly", NPC )

local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Archie Angry", 
				Class = "npc_combine",
				Model = "models/fidremaster/a/fid_archie.mdl",
				Health = "100",
                                Category = Category    }

list.Set( "NPC", "F.I.D. Archie Angry", NPC )

--Add NPC
local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Michael Friendly", 
				Class = "npc_citizen",
				Model = "models/fidremaster/b/fid_michael.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Michael Friendly", NPC )

local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Michael Angry", 
				Class = "npc_combine",
				Model = "models/fidremaster/b/fid_michael.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Michael Angry", NPC )

--Add NPC
local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Jacob Friendly", 
				Class = "npc_citizen",
				Model = "models/fidremaster/c/fid_lincoln.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Jacob Friendly", NPC )

local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Jacob Angry", 
				Class = "npc_combine",
				Model = "models/fidremaster/c/fid_lincoln.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Jacob Angry", NPC )

local NPC = { 	Name = "F.I.D. Lincoln Friendly", 
				Class = "npc_citizen",
				Model = "models/fidremaster/l/fid_lincoln.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Lincoln Friendly", NPC )

local Category = "F.I.D."

local NPC = { 	Name = "F.I.D. Lincoln Angry", 
				Class = "npc_combine",
				Model = "models/fidremaster/l/fid_lincoln.mdl",
				Health = "100",
				KeyValues = { citizentype = 4 },
                                Category = Category    }

list.Set( "NPC", "F.I.D. Lincoln Angry", NPC )