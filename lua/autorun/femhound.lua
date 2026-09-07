player_manager.AddValidModel( "Female Hell Hound", "models/player/femhound.mdl" )
player_manager.AddValidHands( "Female Hell Hound", "models/weapons/arms/c_arms_femhound.mdl", 0, "0000000" )

local Category = "Female HellHound"

local NPC = 
{
	Name = "Friendly HellHound",
	Class = "npc_femhound",
	Category = Category,
}

list.Set( "NPC", NPC.Class, NPC )

local NPC = 
{
	Name = "Hostile HellHound",
	Class = "npc_hostile_femhound",
	Category = Category,
}

list.Set( "NPC", NPC.Class, NPC )