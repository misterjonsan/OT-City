local MaxCounter = 3 // Max props before 'spam' violation
local Time = 30 // Seconds to reset counter

// {MaxCounter} убийств в {Time} секунду
// 3 убийств в 60 секунд

SLogs:RegisterAlgorithm( "DoPlayerDeath", function( args )

	local ply = args[ 2 ]
	if !IsValid( ply ) then return end

	if !ply.rdm_Time or (CurTime( ) - ply.rdm_Time) > Time then
		ply.rdm_Time = CurTime( )
		ply.rdm_Counter = 0
	end

	ply.rdm_Counter = ply.rdm_Counter + 1

	if ply.rdm_Counter > MaxCounter then
		ply.rdm_Counter = 0
		SLogs:Violation( 1, {ply, int1 = MaxCounter, int2 = Time} )
	end

end, true )

return "RDM", true