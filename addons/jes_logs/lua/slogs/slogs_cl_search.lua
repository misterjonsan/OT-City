local function MakePlayersList( pnl )

	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "Area-12" )
	frame:SetSize( 400, 400 )
	frame:Center( )
	frame:SetSkin("DarkRP")
	frame:MakePopup( )

	local SteamIDInput = vgui.Create( "DTextEntry", frame )
	SteamIDInput:Dock( TOP )
	SteamIDInput:SetTall( 32 )
	SteamIDInput:SetText( "SteamID" )

	local scroll = vgui.Create( "DScrollPanel", frame )
	scroll:Dock( FILL )
	scroll:DockMargin( 0, 2, 0, 0 )

	local btn = vgui.Create( "SLogs_button", scroll ):SetType( "Player" )
	btn:Dock( TOP )
	btn:SetTall( 32 )
	btn:DockMargin( 1, 1, 1, 0 )
	btn:SetPlayer( SteamIDInput:GetValue( ) )
	SteamIDInput.OnTextChanged = function( self )
		btn:SetPlayer( self:GetValue( ) )
	end
	btn.DoClick = function( self )
		pnl:Insert( SteamIDInput:GetValue( ) )
	end

	for _, ply in pairs( player.GetAll( ) ) do

		local steamid = ply:SteamID( )

		if table.HasValue( pnl.List or {}, steamid ) then continue end
		
		local btn = vgui.Create( "SLogs_button", scroll ):SetType( "Player" )
		btn:Dock( TOP )
		btn:SetTall( 32 )
		btn:DockMargin( 1, 1, 1, 0 )
		btn:SetPlayer( steamid )
		btn.DoClick = function( self )
			pnl:Insert( self:GetPlayer( ) )
			self:Remove()
		end

	end

end

local function MakeLogTypesList( pnl )

	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "JeluxRP" )
	frame:SetSize( 400, 400 )
	frame:Center( )
	frame:SetSkin("DarkRP")
	frame:MakePopup( )

	local scroll = vgui.Create( "DScrollPanel", frame )
	scroll:Dock( FILL )
	scroll:DockMargin( 0, 2, 0, 0 )

	for type, _ in pairs( SLogs.Types ) do
		if table.HasValue( pnl.List or {}, type ) then continue end
		
		local btn = vgui.Create( "SLogs_button", scroll ):SetType( "Default" )
		btn:Dock( TOP )
		btn:SetTall( 32 )
		btn:DockMargin( 1, 1, 1, 0 )
		btn.type = type
		btn.Paint2 = function( self, w, h )
			draw.SimpleText( SLogs:Translate( "LogTypes", self.type ), SLogs:Setting "f_Button", 2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		btn.DoClick = function( self )
			pnl:Insert( self.type )
			self:Remove()
		end

	end

end

function SLogs:OpenSearch( pnl )
	local Players_List, Logs_List = {}, {}

	local wide = pnl:GetWide( )

	local frame = vgui.Create( "EditablePanel", pnl )
	frame:Dock( FILL )
	frame:DockPadding( 100, 100, 100, 100 )

	local btn = vgui.Create( "SLogs_button", frame ):SetType( "Default" )
	btn:Dock( BOTTOM )
	btn:DockMargin( 5, 5, 5, 5 )
	btn:SetText( SLogs:Translate( "Search", "Search" ) )
	btn:SetTall( 20 )
	btn:SetFont( SLogs:Setting "f_Button" )
	btn.DoClick = function( self )
		frame:Clear( )

		local result = {}
		local Logs_List = Logs_List
		if table.Count( Logs_List ) == 0 then
			for type, _ in pairs( SLogs.Types ) do
				table.insert( Logs_List, type )
			end
		end
		for _, type in pairs( Logs_List ) do

			local logs = SLogs.LogsByTypes[ type ]
			if !logs then continue end

			for _, log in pairs( logs ) do
				local log_ExtraInfo = SLogs.Logs[ log ]
				if !log_ExtraInfo then continue end
				log_ExtraInfo = log_ExtraInfo.E
				if (log_ExtraInfo.sid1 and table.HasValue( Players_List, log_ExtraInfo.sid1 )) or (log_ExtraInfo.sid2 and table.HasValue( Players_List, log_ExtraInfo.sid2 )) then
					
					table.insert( result, log )

				end

			end

		end

		local LogsList = vgui.Create( "SLogs_LogsList", pnl )
		LogsList:Dock( FILL )
		LogsList:SetTable( result )
		LogsList:Open( 1 )
	end

	local wide = ( wide - 200 - 4 * 2 ) / 2
	

	local LogTypes = vgui.Create("EditablePanel",frame)
	LogTypes:DockMargin( 2, 2, 2, 2 )
	LogTypes:SetWide( wide )
	LogTypes:Dock( LEFT )
	LogTypes.text = SLogs:Translate( "Search", "Categories" )
	LogTypes.Paint = function(self,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50 ) )
		DisableClipping( true )
			draw.SimpleText( self.text, SLogs:Setting "f_Category", w/2, -5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		DisableClipping( false )
	end
	LogTypes.List = {}
	LogTypes.Insert = function( self, type )
		if table.HasValue( self.List, type ) then return end
		table.insert( self.List, type )
		Logs_List = self.List

		local btn = vgui.Create( "SLogs_button", self.scroll ):SetType( "Default" )
		btn:Dock( TOP )
		btn:SetTall( 32 )
		btn:DockMargin( 1, 1, 1, 0 )
		btn.type = type
		btn.Paint2 = function( self, w, h )
			draw.SimpleText( SLogs:Translate( "LogTypes", self.type ), SLogs:Setting "f_Button", 2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		btn.DoClick = function( self2 )
			table.RemoveByValue( self.List, self2.type )
			self2:Remove( )
		end
	end

	local btn = vgui.Create( "SLogs_button", LogTypes ):SetType( "Default" )
	btn:Dock( BOTTOM )
	btn:DockMargin( 5, 5, 5, 5 )
	btn:SetText( "Добавить" )
	btn:SetTall( 20 )
	btn:SetFont( SLogs:Setting "f_Button" )
	btn.DoClick = function()MakeLogTypesList( LogTypes )end

	LogTypes.scroll = vgui.Create( "DScrollPanel", LogTypes )
	LogTypes.scroll:Dock( FILL )




	local Players = vgui.Create("EditablePanel",frame)
	Players:DockMargin( 2, 2, 2, 2 )
	Players:SetWide( wide )
	Players:Dock( LEFT )
	Players.text = SLogs:Translate( "Search", "Players" )
	Players.Paint = function(self,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50 ) )
		DisableClipping( true )
			draw.SimpleText( self.text, SLogs:Setting "f_Category", w/2, -5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		DisableClipping( false )
	end
	Players.List = {}
	Players.Insert = function( self, steamid )
		if table.HasValue( self.List, steamid ) then return end
		table.insert( self.List, steamid )
		Players_List = self.List

		local btn = vgui.Create( "SLogs_button", self.scroll ):SetType( "Player" )
		btn:Dock( TOP )
		btn:SetTall( 32 )
		btn:DockMargin( 1, 1, 1, 0 )
		btn:SetPlayer( steamid )
		btn.DoClick = function( self2 )
			local steamid = self2:GetPlayer( )

			table.RemoveByValue( self.List, steamid )
			self2:Remove( )
		end
	end

	local btn = vgui.Create( "SLogs_button", Players ):SetType( "Default" )
	btn:Dock( BOTTOM )
	btn:DockMargin( 5, 5, 5, 5 )
	btn:SetText( "Добавить" )
	btn:SetTall( 20 )
	btn:SetFont( SLogs:Setting "f_Button" )
	btn.DoClick = function()MakePlayersList( Players )end

	Players.scroll = vgui.Create( "DScrollPanel", Players )
	Players.scroll:Dock( FILL )

end

--PrintTable(SH_REPORTS.ActiveReports) admin_id