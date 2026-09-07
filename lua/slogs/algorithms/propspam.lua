local MaxCounter = 5 // Max props before 'spam' violation
local Time = 1 // Seconds to reset counter

// {MaxCounter} пропов в {Time} секунду
// 5 пропов в 1 секунду

SLogs:RegisterAlgorithm( "PlayerSpawnedProp", function( args )
	local ply = args[ 1 ]
	if !IsValid( ply ) or ply:IsBot( ) then return end

	if !ply.propspam_Time or (CurTime( ) - ply.propspam_Time) > Time then
		ply.propspam_Time = CurTime( )
		ply.propspam_Counter = 0
	end

	ply.propspam_Counter = ply.propspam_Counter + 1

	if ply.propspam_Counter >= MaxCounter then
		ply.propspam_Counter = 0
		SLogs:Violation( 0, {ply, int1 = MaxCounter, int2 = Time} )
	end

end, true )

return "PropSpam", true