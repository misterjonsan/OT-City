player_manager.AddValidModel("Ani", "models/sheepylord/grok/ani.mdl");
player_manager.AddValidHands("Ani", "models/sheepylord/grok/ani_arms.mdl" , 0, "000000")

local Category = "Grok 4"

local NPC = {
    Name = "Ani (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/grok/ani.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "ani_sheepylord_F", NPC)

local NPC = {
    Name = "Ani (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/grok/ani.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "ani_sheepylord_E", NPC)

