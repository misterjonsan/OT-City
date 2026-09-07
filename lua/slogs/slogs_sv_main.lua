local pairs = pairs
local pcall = pcall

SLogs.Hooks = {}

function SLogs:Hook( hook_name, func )

	hook.Add( hook_name, "SLogs", function( ... )

		SLogs:CallAlgorithm( hook_name, true, {...} )
		
		local suc, result = pcall( func, ... )

		if !suc then ErrorNoHalt( result ) return end

		if result then
			
			local key = self:Log( result )
			SLogs:CallAlgorithm( hook_name, false, result, key )

		end

	end )

	table.insert( SLogs.Hooks, hook_name )

end

function SLogs:InitFiles(  )

	local _, _ = file.Find( "slogs/types/*.lua", "LUA" )

	for _, _ in pairs( _ ) do

		self:LoadFile( _ )

	end

end

function SLogs:ValidCall( ent, str )
	
	if !ent or !IsValid( ent ) then return end

	if ent[ str ] then
		return ent[ str ]( ent )
	end

end



local files, _ = file.Find( "slogs/types/*.lua", "LUA" )
for _, file in pairs( files ) do
	
	include( ("slogs/types/%s"):format( file ) )

end


// SteamID to Player ( player.GetBySteamID but better )
local seeds = {}
local function insertPlayer( ply )
	if ply:IsBot( ) then return end

	seeds[ ply:SteamID( ) ] = ply
end
local function deletePlayer( ply )
	if ply:IsBot( ) then return end

	seeds[ ply:SteamID( ) ] = nil
end
hook.Add( "PlayerInitialSpawn", "SLogs sid_to_ply", insertPlayer )
hook.Add( "PlayerDisconnected", "SLogs sid_to_ply", deletePlayer )

for k, v in pairs( player.GetAll( ) ) do insertPlayer( v ) end

function SLogs:SteamIDToPlayer( sid )
	return sid and seeds[ sid ]
end



SLogs.AlgorithmsBefore = {}
SLogs.AlgorithmsAfter = {}
function SLogs:CallAlgorithm( name, before, result, key )
	local tbl = (before and SLogs.AlgorithmsBefore or SLogs.AlgorithmsAfter)[ name ]
	if !tbl then return end

	for _, algorithm in pairs( tbl ) do
		if algorithm.before == before then
			algorithm.func( result, key )
		else
			algorithm.func( result )
		end
	end

end
function SLogs:RegisterAlgorithm( name, func, before )
	local targetTable = before and SLogs.AlgorithmsBefore or SLogs.AlgorithmsAfter

	targetTable[ name ] = targetTable[ name ] or {}
	table.insert( targetTable[ name ], {func=func,before=before} )
end


local is_reloading = tobool( SLogs.Violation )
function SLogs:Violation( id, info, key )

	local Type = SLogs:GetID( "Violations" )

	local tbl = info

	if key then
		tbl.key = key
	end

	do
		local i = 1
		for k, v in pairs( tbl ) do
			if isentity( v ) then
				if !IsValid( v ) then return end

				tbl[ "ply" .. i ] = SLogs:ValidCall( v, "GetName" )
				tbl[ "sid" .. i ] = SLogs:ValidCall( v, "SteamID" )

				tbl[ k ] = nil
				i = i + 1
			end
		end
	end

	self:Log( {
		T = Type,
		I = id,
		E = tbl
	} )

end

SLogs:Msg( is_reloading and "Reloading all" or "Loading", Color( 255, 50, 50 ), " algorithms." )

local files, _ = file.Find( "slogs/algorithms/*.lua", "LUA" )
SLogs:Msg( "Founded: ", Color( 255, 50, 50 ), table.Count( files ) )

for _, file in pairs( files ) do
	
	local name, status = include( ("slogs/algorithms/%s"):format( file ) )
	SLogs:Msg( "[", Color( 255, 50, 50 ), name, Color( 255, 255, 255 ), "]:", "\n", Color(0,0,0), "|", Color(255,255,255), "\tStatus: ", status and Color( 150, 255, 150 ) or Color( 255, 150, 150 ), status and "Enabled" or "Disabled" )

end

SLogs:Msg( Color( 255, 50, 50 ), "Algorithms ", Color( 255, 255, 255 ), "fully loaded." )

--[[
T - Type
t - Time
I - Index ( translation index )
E - ExtraInfo ( enemy, innocent, key for watch library )
	{
		N1 - Player Name ( 1 )
		N2 - Player Name ( 2 )

		S1 - SteamID ( 1 )
		S2 - SteamID ( 2 )

		
	}
]]