local settings_img = Material( "materials/icon16/cog.png" )
local search_img = Material( "materials/icon16/magnifier.png" )
surface.CreateFont("SLogs_Logo",{font = "Tahoma",size = 30,weight = 1700, antialias = true})
surface.CreateFont("SLogs_Button",{font = "Tahoma",size = 15,weight = 1700, antialias = false})
surface.CreateFont("SLogs_Category",{font = "Tahoma",size = 20,weight = 1700,shadow = true, antialias = true})
surface.CreateFont("SLogs_LineText",{font = "Tahoma",size = 25,weight = 1700, antialias = true})

SLogs.Menu = {
	Buttons = {},
	Categories = {},
	OpenedButton = nil
}
local function RemoveIfValid( pnl )
	if pnl and IsValid( pnl ) then
		pnl:Remove()
	end
end
function SLogs:Open( )
	if not LocalPlayer():IsAdmin() and not table.HasValue( SLogs.Allowed, LocalPlayer():GetUserGroup() ) then return end
	--[[ if SLogs:Sync( true ) then
		return
	end--]]
	SLogs:Sync( ) 
	local frame = slogs_frame
	if frame and IsValid( slogs_frame ) then
		RemoveIfValid( frame._NavigationPanel )
		RemoveIfValid( frame._RightPanel )

		local sett_button = frame._SettingsButton
		if sett_button and IsValid( sett_button ) then
			sett_button:MoveColorTo( "idle", Color( 100, 100, 100 ) )
			sett_button:MoveColorTo( "hovered", Color( 150, 150, 150 ) )
			sett_button:MoveColorTo( "down", Color( 200, 200, 200 ) )
		end
	else
		frame = vgui.Create( "SLogs_frame" )
		slogs_frame = frame
		frame:SetSize( ScrW()/1.2, ScrH()/1.2 )
		frame:Center( )
	end

	frame._NavigationPanel = vgui.Create( "DScrollPanel", frame )
	frame._NavigationPanel:Dock( LEFT )
	frame._NavigationPanel:SetWide( (ScrW()/1.2)/6 )
	frame._NavigationPanel.Paint = function( self, w, h )
		draw.RoundedBox( 0,  0, 0, w, h, Color( 50, 50, 50 ) )
	end

	frame._RightPanel = vgui.Create( "EditablePanel", frame )
	frame._RightPanel:Dock( FILL )

	if !frame._SettingsButton then
		frame._SettingsButton = vgui.Create( "SLogs_button", frame._TopPanel ):SetType( "Image" )
		frame._SettingsButton:DockMargin( 0, 0, 1, 0 )
		frame._SettingsButton:Dock( RIGHT )
		frame._SettingsButton:SetWide( 30 )
		frame._SettingsButton:SetImage( settings_img )
	end
	frame._SettingsButton.DoClick = SLogs.OpenSettings

	local result = {}
	for v, k in pairs( SLogs.Types ) do

		if !result [ k.Category ] then
			
			result[ k.Category ] = { v }

		else

			table.insert( result[ k.Category ], v )

		end

	end

	local search_id = SLogs:GetID "Search"
	for category, types in pairs( result ) do

		local cat = vgui.Create( "SLogs_Label", frame._NavigationPanel )
		cat:SetText( SLogs:Translate( "LogCategories", category ) )
		cat:SetFont( SLogs:Setting "f_Category" )
		cat:Dock( TOP )

		for _, type in pairs( types ) do
			local btn = vgui.Create( "SLogs_button", frame._NavigationPanel ):SetType( "Default" )
			btn:Dock( TOP )
			btn:DockMargin( 5, 0, 5, 5 )
			local _,h = draw.SimpleText( "1",SLogs:Setting "f_Category" )
			btn:SetTall( h + ( 2 * ( (tonumber( SLogs:Setting "ButtonTall" ) or "0") - 1 ) ) )
			btn:SetText( SLogs:Translate( "LogTypes", type ) )
			btn:SetFont( SLogs:Setting "f_Button" )
			btn:SetLerp( true )
			if type != search_id then
				btn.type = type
				btn.DoClick = function( self )
					if IsValid( frame._RightPanel ) then
						frame._RightPanel:Clear( )
					else return end
					local tbl = {}
					local logs = SLogs.LogsByTypes[ self.type ]
					SLogs.Menu.OpenedButton = self
					if !logs then return end
					for _, ID in pairs( logs ) do

						table.insert( tbl, ID )

					end
					local LogsList = vgui.Create( "SLogs_LogsList", frame._RightPanel )
					LogsList:Dock( FILL )
					LogsList:SetTable( tbl )
					LogsList:Open( 1 )
				end
			else
				btn.DoClick = function( self )
					if IsValid( frame._RightPanel ) then
						frame._RightPanel:Clear( )
					else return end
					SLogs:OpenSearch( frame._RightPanel )
					SLogs.Menu.OpenedButton = self
				end
			end

			SLogs.Menu.Buttons[ type ] = btn

		end
		SLogs.Menu.Categories[ category ] = cat

	end

end

concommand.Add( "logs", function()
	SLogs:Open( )
end )