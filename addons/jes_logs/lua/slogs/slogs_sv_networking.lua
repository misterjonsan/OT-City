util.AddNetworkString( "SLogs" )

function SLogs:CompressTable( Table )

	local result = util.TableToJSON( Table )
	result = util.Compress( result )

	return result

end

function SLogs:Transmit( ply, tbl )

	tbl = tbl or self.Logs

	if !istable( tbl ) then return end

	local count = table.Count( tbl )
	if count <= 0 then
		net.Start( "SLogs" )
			net.WriteUInt( 3, 3 )
		net.Send( ply )
		return
	end

 -- 1778169 without compress, 65529 with compress

	local max_count = 5000--1000000
	if count > max_count then
		net.Start( "SLogs" )net.WriteUInt( 1, 3 )net.WriteUInt( 0, 2 )net.WriteUInt( count, 32 )net.Send( ply )

		local c = 0
		local sorted_tbl = {[0]={}}
		local order = 0

		for id, v in pairs( tbl ) do
			
			if c > max_count then
				order = order + 1
				sorted_tbl[ order ] = sorted_tbl[ order ] or {}
				c = 0
			end

			sorted_tbl[ order ][ id ] = v
			c = c + 1

		end

		for _, t in pairs( sorted_tbl ) do
			local compressed = self:CompressTable( t )
			local len = compressed:len( )

			timer.Simple( _ + 1, function()
				if !IsValid( ply ) then return end
				net.Start( "SLogs" )
					net.WriteUInt( 2, 3 )
					net.WriteUInt( len, 32 )
					net.WriteData( compressed, len )
				net.Send( ply )
			end )
		end


		timer.Simple( table.Count( sorted_tbl ) + 1 + 0.5, function()
			if !IsValid( ply ) then return end
			net.Start( "SLogs" )net.WriteUInt( 1, 3 )net.WriteUInt( 1, 2 )net.Send( ply )
		end )

	else

		local compressed = self:CompressTable( tbl )
		local len = compressed:len()

		net.Start( "SLogs" )
			net.WriteUInt( 0, 3 )

			net.WriteUInt( len, 32 )
			net.WriteData( compressed, len )
		net.Send( ply )
		
	end
	return true

end

function SLogs:Log( tbl )

	if !tbl.t then
		tbl.t = os.time( ) - self.Time
	end
	local key = table.insert( SLogs.Logs, tbl )

	if !SLogs.LogsByTypes[ tbl.T or 0 ] then

		return

	end

	table.insert( SLogs.LogsByTypes[ tbl.T or 0 ], key )

	if SLogs.Cleaner then
		local shouldClean, rows = SLogs.Cleaner:ShouldClean( )
		if shouldClean then
			SLogs.Cleaner:Clean( rows )
		end
	end

	return key

end


function SLogs:GetLogsInPeriod( from, to )
	local tbl = {}
	local logs = SLogs.Logs
	local count = table.Count( logs )

	from = from or 1
	to = math.Clamp( to or count, 1, count )

	if from > count then return {} end

	for i = from, to do
		tbl[ i ] = logs[ i ]
	end

	return tbl
end
SLogs.Options = {
	[ 0 or Error ] = function( ply )
		--SLogs:Log( SLogs:GetID( "Violations" ), { ply, "" } )
		ply:Kick( "[SLogs] Something went wrong, check your connection and retry." )
	end,

	[ 1 or RequestAll ] = function( ply )
		SLogs:Transmit( ply, SLogs.Logs )
	end,

	[ 2 or RequestFrom ] = function( ply )
		local tbl = SLogs:GetLogsInPeriod( net.ReadUInt( 32 ) )
		SLogs:Transmit( ply, tbl )
	end,

	[ 3 or RequestFromTo ] = function( ply )
		local tbl = SLogs:GetLogsInPeriod( net.ReadUInt( 32 ), net.ReadUInt( 32 ) )
		SLogs:Transmit( ply, tbl )
	end,
}
net.Receive( "SLogs", function( len, ply )
	if not IsValid(ply) then return end

	-- проверка: либо в списке групп, либо админ
	if not ply:IsAdmin() and not table.HasValue( SLogs.Allowed, ply:GetUserGroup() ) then return end

	local id = net.ReadUInt( 5 )
	local option = SLogs.Options[ id ]

	if not option then
		option = SLogs.Options[ 0 ] or function(ply)
			error("[SLogs] Something went wrong!")
		end 
	end

	option( ply )
end )