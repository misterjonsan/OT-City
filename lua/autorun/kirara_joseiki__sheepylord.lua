player_manager.AddValidModel("Kirara Joseiki", "models/sheepylord/Torch_Down_Genesis/Kirara_Joseiki__pm.mdl");
player_manager.AddValidHands("Kirara Joseiki", "models/sheepylord/Torch_Down_Genesis/Kirara_Joseiki__arms.mdl" , 0, "000000")

local Category = "Torch Down: Genesis"

local NPC = {
    Name = "Kirara Joseiki (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/Torch_Down_Genesis/Kirara_Joseiki_.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "Kirara_Joseiki__sheepylord_F", NPC)

local NPC = {
    Name = "Kirara Joseiki (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/Torch_Down_Genesis/Kirara_Joseiki_.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "Kirara_Joseiki__sheepylord_E", NPC)
