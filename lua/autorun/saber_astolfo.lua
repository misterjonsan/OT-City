player_manager.AddValidModel( "Astolfo Saber", "models/cyanblue/fate_arcade/astolfo_saber/astolfo_saber.mdl" );
player_manager.AddValidHands( "Astolfo Saber", "models/cyanblue/fate_arcade/astolfo_saber/arms/astolfo_saber.mdl", 0, "00000000" )

local Category = "Fate Arcade"

local NPC =
{
	Name = "Astolfo Saber",
	Class = "npc_citizen",
	Health = "100",
	KeyValues = { citizentype = 4 },
	Model = "models/cyanblue/fate_arcade/astolfo_saber/npc/astolfo_saber.mdl",
	Category = Category
}

list.Set( "NPC", "npc_astolfo_saber_fgoa", NPC )

