local Category = "FSB"

local NPC = {
    Name = "FSB Phoenix Friendly",
    Class = "npc_citizen",
    Model = "models/fsb/a/phoenix_fsb.mdl",
    Health = 100,
    Weapons = { "weapon_smg1" }, 
    Category = Category
}
list.Set("NPC", "npc_fsb_a_friendly", NPC)

local NPC = {
    Name = "FSB Character B Friendly",
    Class = "npc_citizen",
    Model = "models/fsb/b/fsb_character_b.mdl",
    Health = 100,
    Weapons = { "weapon_smg1" },
    Category = Category
}
list.Set("NPC", "npc_fsb_b_friendly", NPC)

local NPC = {
    Name = "FSB Character C Friendly",
    Class = "npc_citizen",
    Model = "models/fsb/c/fsb_character_c.mdl",
    Health = 100,
    Weapons = { "weapon_smg1" },
    Category = Category
}
list.Set("NPC", "npc_fsb_c_friendly", NPC)
