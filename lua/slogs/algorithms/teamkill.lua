SLogs.TeamKill = SLogs.TeamKill or {}

local function compileConfig( )
	local cfg = {
		{ TEAM_CB, TEAM_MOG, TEAM_RAZVED }
	}
	

	for _, pair in pairs( cfg ) do
		for _, target_team in pairs( pair ) do
			local tbl = {}
			for _, second_team in pairs( pair ) do
				if second_team != target_team then tbl[ second_team ] = true end
			end
			SLogs.TeamKill[ target_team ] = tbl
		end
	end
end
if DarkRP then
	compileConfig( )
end
hook.Add("PostGamemodeLoaded", "TeamKill", compileConfig )

local function GetHMCDSide(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return nil end
	if ply.isTraitor then return "traitor" end
	if zb and zb.IsForce and zb.IsForce(ply) then return "force" end
	return "innocent"
end

local function AreConfiguredAllies(team1, team2)
	local cfg = SLogs.TeamKill[ team1 ]
	return cfg and cfg[ team2 ] or false
end

local function AreTeammates(ply1, ply2)
	if not IsValid(ply1) or not IsValid(ply2) then return false end
	if not ply1:IsPlayer() or not ply2:IsPlayer() then return false end

	local rnd = CurrentRound and CurrentRound()
	if rnd and rnd.name == "hmcd" then
		local side1 = GetHMCDSide(ply1)
		local side2 = GetHMCDSide(ply2)
		return side1 ~= nil and side1 == side2
	end

	local team1 = ply1:Team()
	local team2 = ply2:Team()

	if team1 == team2 then
		return true
	end

	return AreConfiguredAllies(team1, team2) or AreConfiguredAllies(team2, team1)
end

SLogs:RegisterAlgorithm( "DoPlayerDeath", function( result, key )

	if !istable( result ) then return end
	if !result.E.sid1 then return end
	if !result.E.sid2 then return end

	local ply1 = SLogs:SteamIDToPlayer( result.E.sid1 )
	local ply2 = SLogs:SteamIDToPlayer( result.E.sid2 )

	if !IsValid( ply2 ) or !IsValid( ply1 ) then return end
	if not AreTeammates( ply1, ply2 ) then return end

	SLogs:Violation( 2, {ply1, ply2}, key )

end, false )

return "TeamKill", true
