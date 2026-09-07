SLogs.Eye = SLogs.Eye or { Compressor = {}, Cases = {} }
local function DotCheck( ent, pos )

	local aimvec = ent:GetAimVector()
	local eyepos = ent:EyePos()

	local dot = aimvec:Dot( ( pos - eyepos ):GetNormalized() )

	return dot > 0.6

end

local function WindowTrace( startpos, endpos, filter, try )
	
	--[[ if try == 3 then
		return {Hit = false}
	end--]] 
	local trace = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		filter = filter,
		mask = MASK_ALL,
	} )
	--[[ if trace.MatType == MAT_GLASS then

		local dir = (startpos - endpos):Angle():Forward()
		startpos = trace.HitPos - dir * 10

		return WindowTrace( startpos, endpos, filter, (try or 0) + 1 )

	end--]] 

	return trace

end

function SLogs.Eye:CanSee( ent, pos )

	if not DotCheck( ent, pos ) then return false end

	--[[ local trace = WindowTrace( ent:EyePos( ), pos, function( self )
		if self == ent then return false end
		if self:IsPlayer( ) then return false end
		if self:IsVehicle( ) then return false end
		return true
	end )--]] // untrust this shit. 

	return true//not trace.Hit

end

function SLogs.Eye:CanHear( ent, pos )

	return ent:GetPos( ):Distance( pos ) < 700

end

function SLogs.Eye:GetWitnesses( pos, targets, pvs )
	targets = targets or pos
	if type( pos ) == "Player" then
		if !IsValid( pos ) then return end
		local wep = pos:GetActiveWeapon( )
		if IsValid( wep ) then
			pos = wep:GetPos( )
		else
			pos = pos:GetPos( )
		end
	end
	if istable( pos ) then
		targets = pos
		pos = (targets.ply2 or targets.ply1):GetPos( )
	end

	local result = {}

	if targets.ply1 and IsValid( targets.ply1 ) then
		result.ply1 = targets.ply1
	end
	if targets.ply2 and IsValid( targets.ply2 ) then
		result.ply2 = targets.ply2
	end
	for _, ent in pairs( pvs and ents.FindInPVS( pos ) or ents.GetAll( ) ) do

		--if table.HasValue( targets, ent ) then continue end
		if targets.ply1 == ent then continue end
		if targets.ply2 == ent then continue end
		if !IsValid( ent ) or ( !ent:IsPlayer( )  ) then continue end

		if ent.Alive and !ent:Alive( ) then continue end
		if ent:GetPos( ):Distance( pos ) > 2200 then continue end

		
		local see = self:CanSee( ent, pos )
		local hear = self:CanHear( ent, pos )
		if see then

			--print( "[SLogs] " .. (ent.Name and ent:Name() or "") .. " witness ( eye )." )
			table.insert( result, ent )

		elseif hear then
			
			--print( "[SLogs] " .. (ent.Name and ent:Name() or "") .. " witness ( ear )." )
			table.insert( result, ent )

		end

	end

	return result

end

function SLogs.Eye.Compressor:Number( int )
	if !int then return end
	return math.floor( int )
end
function SLogs.Eye.Compressor:Vector( pos )
	if !pos then return end
	return Vector( self:Number( pos.x ), self:Number( pos.y ), self:Number( pos.z ) )
end
function SLogs.Eye.Compressor:Angle( ang )
	if !ang then return end
	return Angle( self:Number( ang.p ),self:Number( ang.y ),self:Number( ang.r ) )
end

setmetatable( SLogs.Eye.Compressor, {
	__call = function( self, value )

		local type = type( value )
		if type == "number" then
			return self:Number( value )
		elseif type == "Vector" then
			return self:Vector( value )
		elseif type == "Angle" then
			return self:Angle( value )
		end

	end
})

local function GetWeaponName( ent )

	if !ent:IsPlayer( ) then return end

	local wep = ent:GetActiveWeapon( )
	if !IsValid( wep ) then return end

	return wep:GetClass( )

end

function SLogs.Eye:RegisterCase( tbl )
	if !tbl or table.Count( tbl ) == 1 then return end
	local result = {}

	for _, ent in pairs( tbl ) do
		
		result[ _ or ( #result + 1 ) ] = {

			// Position
			pos 	= SLogs.Eye.Compressor( ent:GetPos( ) ),
			// Angle ( Eyes )
			ang 	= SLogs.Eye.Compressor( ent.EyeAngles and ent:EyeAngles( ) or ent:GetAngles( ) ),
			// Weapon
			wep		= GetWeaponName( ent ),
			// Job
			job		= ent.Team and ent:Team( ),
			// Mask
			mask	= tobool( ent.InMask ) == true and (function()
				local hats = ent.Hats
				if !hats or !hats.Mask or !hats.Mask.mdl then return nil end
				return hats.Mask.mdl
			end)( ),
			// Sequence
			sec = ent.GetSequence and ent:GetSequence( ) != 0 and ent:GetSequence( ) or nil,
			// Model
			mdl = ent.GetModel and ent:GetModel() or nil,
			// Name
			name 	= ent.Name and ent:Name(),
			// SteamID
			stid 	= ent.SteamID and ent:SteamID( )

		}
		
	end
	local alreadyCalculated = {}
	for _, ent in pairs( tbl ) do
		
		if !ent:IsPlayer( ) then continue end
		if !ent:InVehicle( ) then continue end
		
		local veh = ent:GetVehicle( )
		if !IsValid( veh ) then continue end
		if IsValid( veh:GetParent( ) ) and !alreadyCalculated[ veh:GetParent( ) ] then
			veh = veh:GetParent( )
			alreadyCalculated[ veh ] = true
		end

		table.insert( result, {
			mdl = veh:GetModel( ),
			pos = veh:GetPos( ),
			ang = veh:GetAngles( )
		} )
		
	end
	return table.insert( SLogs.Eye.Cases, result )

end

util.AddNetworkString( "SLogs.Eye" )
net.Receive( "SLogs.Eye", function( len, ply )

	local ID = net.ReadUInt( 32 )
	local case = SLogs.Eye.Cases[ ID ]

	local compressed = SLogs:CompressTable( case or {} )
	local len = compressed:len()
		
	net.Start( "SLogs.Eye" )
		net.WriteUInt( ID, 32 )
		net.WriteUInt( len, 32 )
		net.WriteData( compressed, len )
	net.Send( ply )

end )

--PrintTable( SLogs.Eye.Cases[ SLogs.Eye:RegisterCase( SLogs.Eye:GetWitnesses( here ) ) ] )