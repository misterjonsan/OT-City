
local function AddPlayerModel( name, model )

    list.Set( "PlayerOptionsModel", name, model )
    player_manager.AddValidModel( name, model )
	player_manager.AddValidHands( "Gopnik", "models/half-dead/gopniks/extra/arms.mdl", 0, "00000000" )
    
end

AddPlayerModel( "Gopnik", "models/half-dead/Gopniks/extra/playermodelonly.mdl" )

