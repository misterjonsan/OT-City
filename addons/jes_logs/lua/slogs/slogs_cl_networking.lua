function SLogs:DecompressTable( Data )

	local Data = util.Decompress( Data ) -- local ??
	Data = util.JSONToTable( Data )

	return Data

end

local epoe_timestamps = GetConVar( "epoe_timestamps" )
if epoe then
	hook.Add( "Initialize", "SLogs EPOE", function()
		epoe_timestamps = GetConVar( "epoe_timestamps" )
		hook.Remove( "Initialize", "SLogs EPOE" )
	end )
end
function SLogs:ValidateLogs( logs )

	local setting_epoe, OLD_epoe_timestamps

	// EPOE support
	if epoe then
		setting_epoe = self:Setting( "EPOE" )
		OLD_epoe_timestamps = epoe_timestamps:GetBool( )
		if OLD_epoe_timestamps then
			epoe_timestamps:SetBool( false )
		end
	end

	for _, log in pairs( logs ) do

		local btn = SLogs.Menu.Buttons[ log.T ]
		if IsValid( btn ) then
			btn:Flash( )
		end
		
		local categories = SLogs.LogsByTypes[ log.T or 0 ]

		if !categories then

			SLogs.LogsByTypes[ log.T or 0 ] = {}
			categories = SLogs.LogsByTypes[ log.T or 0 ]
			--continue

		end

		if epoe then
			if setting_epoe and setting_epoe[ log.T ] then
				epoe.MsgC( unpack( self:Translate( "Logs", log.T, log.I, log.E, true, Color(255,255,255), log.t ) ) )
				epoe.Msg("\n")
			end
		end

		table.insert( categories, _ )

	end

	if OLD_epoe_timestamps then
		epoe_timestamps:SetBool( true )
	end

	table.Merge( SLogs.Logs, logs )

end

local Modes = {

	[ 0 or Logs_Table ] = function( len )

		local len = net.ReadUInt( 32 )
		local tbl = SLogs:DecompressTable( net.ReadData( len ) )
		SLogs:ValidateLogs( tbl )
		SLogs.Syncing = false
		--[[ if SLogs.OpenOnSync then
			SLogs.OpenOnSync = false
			SLogs:Open( )
		end--]] 

	end,

	[ 1 ] = function( )
		local mode = net.ReadUInt( 2 )
		if mode == 0 then
			SLogs.Syncing = true
			
			SLogs.IsDownloading = 2
			local count = net.ReadUInt( 32 )
			SLogs.DownloadingTotalLength = count
			--SLogs.Notify.Add( "SLogs_download", ("Downloading gay porno\n%s left..."):format( SLogs.DownloadingTotalLength ) )
		else
			SLogs.Syncing = false
			SLogs.LastSync = CurTime( )

			--SLogs.Notify.Kill( "SLogs_download" )
			SLogs.DownloadingTotalLength = nil
			SLogs.IsDownloading = 0
			--[[ if SLogs.OpenOnSync then
				SLogs.OpenOnSync = false
				SLogs:Open( )
			end--]] 
		end
	end,
	[ 2 ] = function( )
		local len = net.ReadUInt( 32 )
		local tbl = SLogs:DecompressTable( net.ReadData( len ) )
		SLogs.LastSync = CurTime( )
		SLogs:ValidateLogs( tbl )

		if SLogs.DownloadingTotalLength then
			SLogs.DownloadingTotalLength = SLogs.DownloadingTotalLength - table.Count( tbl )
			--SLogs.Notify.Add( "SLogs_download", ("Downloading gay porno\n%s left..."):format( SLogs.DownloadingTotalLength ) )
 		else
			SLogs.Syncing = false
		end
	end,
	[ 3 ] = function()
		SLogs.LastSync = CurTime( )
		SLogs.Syncing = false
		--[[ if SLogs.OpenOnSync then
			SLogs.OpenOnSync = false
			SLogs:Open( )
		end--]] 
	end,
	[ 4 ] = function( )
		SLogs.Cleaner:Clean( net.ReadUInt( 32 ) )
	end

}

SLogs.LastSync = 0
SLogs.OpenOnSync = false
SLogs.IsDownloading = 0
local CurTime = CurTime
function SLogs:Sync( --[[ openMenu--]]  )
	if SLogs.Syncing then return end
	SLogs.Syncing = true
	//if SLogs.LastSync > CurTime() - 1 then return false end
	//if SLogs.IsDownloading != 0 then return true end
	//SLogs.LastSync = CurTime( )

	--[[ if openMenu then
		SLogs.OpenOnSync = true
	end--]] 

	net.Start( "SLogs" )

	local count = table.Count( self.Logs )

	if count == 0 then
		net.WriteUInt( 1, 5 )
		self.Logs = {}
		self.LogsByTypes = {}
	else
		net.WriteUInt( 2, 5 )
		net.WriteUInt( count + 1, 32 )
	end

	net.SendToServer( )

	return true

end

net.Receive( "SLogs", function( len )

	local mode = net.ReadUInt( 3 )

	local ok,_ = true
	
	if !Modes[ mode ] then

		
		ok = false

	else

		ok,_ = pcall( Modes[ mode ], len )

	end

	if not ok then

		SLogs:Msg( "Something went wrong!!" )
		SLogs:Msg( _ or "unknown error" )

	end

end )
