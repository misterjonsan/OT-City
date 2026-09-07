SLogs = SLogs or {}

SLogs.MaxLogs = 20000
SLogs.ShouldClean = 2000 -- min clean, suppress spam

SLogs.Cleaner = {}

local function cleanRows( tbl, count, byKey )
	local cleaned = 0
	local finished
	local prev

	local result = {}

	repeat
		local key, value = next( tbl, prev )
		if not key then finished = true break end
		prev = key

		local should = false
		if byKey then
			should = key <= count
		else
			should = value <= count
		end

		if should then
			cleaned = cleaned + 1
			if istable( value ) and value.E and value.E.eye then
				SLogs.Eye.Cases[ value.E.eye ] = nil
			end
			tbl[ key ] = nil
		else
			tbl[ key ] = nil
			if byKey then
				tbl[ key - cleaned ] = value
			else
				tbl[ key - cleaned ] = value - count
			end
		end
	until( finished )

	return cleaned
end

function SLogs.Cleaner:ShouldClean( )
	if table.Count( SLogs.Logs ) > SLogs.MaxLogs then
		return true, math.Max( SLogs.ShouldClean, math.abs( SLogs.MaxLogs - table.Count( SLogs.Logs ) ) )
	else
		return false
	end
end

function SLogs.Cleaner:Clean( shouldClean )

	SLogs:Msg( "Cleaner started!" )



	local cleaned = cleanRows( SLogs.Logs, shouldClean, true )

	local cleanedFromTypes = 0
	for logType, tbl in pairs( SLogs.LogsByTypes ) do
		cleanedFromTypes = cleanedFromTypes + cleanRows( SLogs.LogsByTypes[ logType ], shouldClean, false )
	end

	if cleanedFromTypes ~= cleaned then
		ErrorNoHalt( "SLogs: Cleaner error! " .. tostring( cleanedFromTypes ) .. " ~= " .. tostring( cleaned ) .. "\n" )
		if CLIENT then
			ErrorNoHalt( "Redownloading all logs!\n" )
			SLogs.Logs = {}
			SLogs.LogsByTypes = {}
			SLogs:Sync( )
		end
	end



	SLogs:Msg( "Finished!\nCleaned: ", Color( 100, 255, 100 ), cleaned, " logs!" )

	if SERVER then
		net.Start( "SLogs" )
			net.WriteUInt( 4, 3 )
			net.WriteUInt( cleaned, 32 )
		net.Broadcast( )
	end

	return cleaned

end