SLogs:Msg( Color( 255, 100, 100 ), "Sandbox", Color( 255, 255, 255 ), " module loaded." )

local PropsID = SLogs:GetID( "Props" )

SLogs:Hook( "PlayerSpawnedProp", function( ply, mdl )

	return {
		T = PropsID,
		I = 0,
		E = {
			ply1 = SLogs:ValidCall( ply, "GetName" ),

			sid1 = SLogs:ValidCall( ply, "SteamID" ),

			str = mdl
		}
	}

end )