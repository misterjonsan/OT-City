
local function AddPlayerModel( name, model )

    list.Set( "PlayerOptionsModel", name, model )
    player_manager.AddValidModel( name, model )
	
	player_manager.AddValidHands( "gang_ballas_1", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_ballas_2", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_ballas_chem", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_ballas_boss", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
    
end

AddPlayerModel( "gang_ballas_1", "models/gang_ballas/gang_ballas_1.mdl" )
AddPlayerModel( "gang_ballas_2", "models/gang_ballas/gang_ballas_2.mdl" )
AddPlayerModel( "gang_ballas_chem", "models/gang_ballas_chem/gang_ballas_chem.mdl" )
AddPlayerModel( "gang_ballas_boss", "models/gang_ballas_boss/gang_ballas_boss.mdl" )