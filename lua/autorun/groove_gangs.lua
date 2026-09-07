
local function AddPlayerModel( name, model )

    list.Set( "PlayerOptionsModel", name, model )
    player_manager.AddValidModel( name, model )
	
	player_manager.AddValidHands( "gang_1", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_2", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_groove_chem", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
	player_manager.AddValidHands( "gang_groove_boss", "models/weapons/c_arms_citizen.mdl", 1, "00000000" )
    
end

AddPlayerModel( "gang_1", "models/gang_groove/gang_1.mdl" )
AddPlayerModel( "gang_2", "models/gang_groove/gang_2.mdl" )
AddPlayerModel( "gang_groove_chem", "models/gang_chem/gang_groove_chem.mdl" )
AddPlayerModel( "gang_groove_boss", "models/gang_groove_boss/gang_groove_boss.mdl" )