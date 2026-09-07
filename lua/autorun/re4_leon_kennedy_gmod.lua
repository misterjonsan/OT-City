player_manager.AddValidModel( "RE4 Leon Kennedy (2005)", "models/re4/leon/leon_pm.mdl" )
list.Set("PlayerOptionsModel", "", "models/re4/leon/leon_pm.mdl" )
player_manager.AddValidHands( "RE4 Leon Kennedy (2005)", "models/re4/leon/leon_c.mdl", 0, "0" )

hook.Add("PreDrawPlayerHands", "leon_arm", function(hands, vm, ply, wpn)
    if IsValid(hands) and hands:GetModel() == "models/re4/leon/leon_c.mdl" then
        hands:SetBodygroup(1,(ply:GetBodygroup(1)) )
		hands:SetBodygroup(2,(ply:GetBodygroup(3)) )
    end
end)

local Category = "Resident Evil 4"

local NPC =
{
	Name = "Leon S. Kennedy",
	Class = "npc_citizen",
	Health = "50",
	Weapons = { "weapon_pistol" },
	KeyValues = { citizentype = 4 },
	Model = "models/re4/leon/leon_npc.mdl",
	Category = Category
}

list.Set( "NPC", "npc_leon_friendly", NPC )

local NPC =
{
	Name = "Leon S. Kennedy (Enemy)",
	Class = "npc_combine_s",
	Health = "50",
	Model = "models/re4/leon/leon_enemy.mdl",
	Weapons = { "weapon_pistol" },
	Category = Category
}

list.Set( "NPC", "npc_leon_enemy", NPC )