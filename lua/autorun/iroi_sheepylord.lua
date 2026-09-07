player_manager.AddValidModel("Iroi", "models/sheepylord/neverness_to_everness/iroi_pm.mdl");
player_manager.AddValidHands("Iroi", "models/sheepylord/neverness_to_everness/iroi_arms.mdl" , 0, "000000")

local Category = "Neverness to Everness"

local NPC = {
    Name = "Iroi (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/neverness_to_everness/iroi.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "iroi_sheepylord_F", NPC)

local NPC = {
    Name = "Iroi (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/neverness_to_everness/iroi.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "iroi_sheepylord_E", NPC)
