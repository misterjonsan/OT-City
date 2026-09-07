local function Translate( ID, ID2 )
	return SLogs:Translate( "Settings", ID, ID2 )
end
SLogs.Settings = {

	{
		type = "Category",
		name = Translate( "Categories", "Visual" )
	},
	{
		type = "ComboBox",
		name = Translate( "BackGR", "n" ),
		--desc = Translate( "BackGR", "d" ),
		key = "Background",
		contents = {
			{
				name = Translate( "BackGR", "c1" )
			},
			{
				name = Translate( "BackGR", "c2" ),
				--desc = Translate( "BackGR", "c2d" )
			},
			{
				name = Translate( "BackGR", "c3" ),
				desc = Translate( "BackGR", "c3d" )
			},
		},
		onChange = function( value )
			if value == 3 then
				hook.Add("RenderScene","SLogsBackground",function()return true end)
			else
				hook.Remove("RenderScene", "SLogsBackground")
			end
		end
	},
	{
		type = "ComboBox",
		name = Translate( "MLines", "n" ),
		desc = Translate( "MLines", "d" ),
		key = "MaxLines",
		contents = {
			{name = "25"},
			{name = "50"},
			{name = "100"},
			{name = "200"},
			{name = "400"},
			{name = "800"},
			{name = "1600"}
		},
		default = 3
	},
	{
		type = "ComboBox",
		name = Translate( "BTall", "n" ),
		desc = Translate( "BTall", "d" ),
		key = "ButtonTall",
		contents = {
			{name = "0"},
			{name = "2"},
			{name = "4"},
			{name = "6"},
			{name = "8"},
			{name = "10"},
			{name = "12"},
			{name = "14"},
			{name = "16"},
			{name = "18"},
			{name = "20"},
		},
		default = 4
	},
	{
		type = "Category",
		name = Translate( "Categories", "Net" )
	},
	{
		type = "ComboBox",
		name = Translate( "Sync", "n" ),
		desc = Translate( "Sync", "d" ),
		key = "Sync",
		contents = {
			{
				name = Translate( "Sync", "c1" ),
				desc = Translate( "Sync", "c1d" )
			},
			{
				name = Translate( "Sync", "c2" ),
			},
			{
				name = Translate( "Sync", "c3" ),
			},
			{
				name = Translate( "Sync", "c4" ),
			},
			{
				name = Translate( "Sync", "c5" ),
			},
		},
		default = 1
	},

	{
		type = "Category",
		name = Translate( "Categories", "Fonts" )
	},
	{
		type = "Font",
		name = Translate( "F_Log" ),
		key = "f_Log",
		default = "15"
	},
	{
		type = "Font",
		name = Translate( "F_Category" ),
		key = "f_Category",
		default = "20"
	},
	{
		type = "Font",
		name = Translate( "F_Button" ),
		key = "f_Button",
		default = "15"
	},


	{
		type = "Category",
		name = Translate( "Categories", "Colors" )
	},
	--[[ {
		type = "ColorPicker",
		name = Translate( "C_Background" ),
		key = "c_Background",
	},--]] 
	{
		type = "ColorPicker",
		name = Translate( "C_TextLog", "n" ),
		desc = Translate( "C_TextLog", "d" ),
		key = "c_TextLog",
		default = Color( 255, 255, 255 )
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Player" ),
		key = "c_Player",
		default = Color( 100, 255, 100 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.ply = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Weapon" ),
		key = "c_Weapon",
		default = Color( 0, 150, 255 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.wep = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Int" ),
		key = "c_Int",
		default = Color( 255, 102, 000 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.int = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Str", "n" ),
		desc = Translate( "C_Str", "d" ),
		key = "c_Str",
		default = Color( 255, 100, 100 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.str = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Fine" ),
		key = "c_Fine",
		default = Color( 255, 100, 100 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.fine = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},
	{
		type = "ColorPicker",
		name = Translate( "C_Time" ),
		key = "c_Time",
		default = Color( 100, 100, 255 ),
		onChange = function( clr )
			SLogs.Colors.LogMarkup.time = Color( clr.r, clr.g, clr.b, clr.a )
		end
	},

}

SLogs._Settings = SLogs._Settings or {}

SLogs.Fonts = {}
for i = 5, 30 do

	table.insert( SLogs.Fonts, tostring( i ) )
	surface.CreateFont( "SLogs_" .. tostring( i ), {

		font = "Tahoma",
		size = i,
		weight = 1700,
		antialias = false

	} )

end

function SLogs:Setting( key )

	local value = SLogs._Settings[ key ]
	if !value then
		for _, tbl in pairs( SLogs.Settings ) do
			
			if tbl.key == key then
				value = tbl.default
				break
			end

		end
		if !value then
			return false
		end
		SLogs._Settings[ key ] = value
	end
	if key:StartWith( "f_" ) then

		return "SLogs_" .. value

	end

	--[[if isstring( value ) then
		return "SLogs_" .. value
	end]]

	return value

end

function SLogs:SaveSettings( )

	local json = util.TableToJSON( self._Settings )

	file.CreateDir( "slogs" )
	file.Write( "slogs/settings.txt", json )

end

local function DetourComboBox( pnl, count, func )
	local old_open = pnl.OpenMenu

	pnl.OpenMenu = function( self, ... )
		old_open( self, ... )

		local menu = self.Menu
		if !IsValid( menu ) then return end

		for i = 1, count do
			local child = menu:GetChild( i )

			if child then
				local old_paint = child.Paint

				child.Paint = function( self, w, h )

					old_paint( self, w, h )

					func( self, i, w, h )

				end

			end

		end

	end

end

local function DetourCheckedComboBox( pnl, count, func, onChecked, default )
	local old_open = pnl.OpenMenu

	local OnMouseReleased = function( self, mousecode ) 
		DButton.OnMouseReleased( self, mousecode )
		if ( self.m_MenuClicking && mousecode == MOUSE_LEFT ) then
			self.m_MenuClicking = false
		end
	end

	pnl.OpenMenu = function( self, ... )
		old_open( self, ... )

		local menu = self.Menu
		if !IsValid( menu ) then return end

		for i = 1, count do
			local child = menu:GetChild( i )

			if child then
				local old_paint = child.Paint

				child:SetIsCheckable( true )
				if default[ i ] then
					child:SetChecked( true )
				end
				child.DoClick = function()end
				child.OnMouseReleased = OnMouseReleased
				if onChecked then
					child.OnChecked = function( self, bool )
						onChecked( i, bool )
					end
				end

				child.Paint = function( self, w, h )

					old_paint( self, w, h )

					func( self, i, w, h )

				end

			end

		end

	end

end

function SLogs:InitDefaultSettings( )

	local result = {}

	for _, setting in pairs( self.Settings ) do

		local key = setting.key

		if !key then continue end

		local type = setting.type

		if type == "ComboBox" then
			
			result[ key ] = setting.default or 1

		elseif type == "CheckableComboBox" then
			
			result[ key ] = setting.default or {}

		elseif type == "ColorPicker" then

			result[ key ] = setting.default or Color( 80, 80, 80 )
			if setting.onChange then
				setting.onChange( result[ key ] )
			end

		end

	end
	file.Delete( "slogs/settings.txt" )

	SLogs._Settings = result

end

local tag = "SLogs_Sync"
local current = -1
local times = {
	[ 1 ] = 4,
	[ 2 ] = 2,
	[ 3 ] = 5,
	[ 4 ] = 10,
	[ 5 ] = 30,
}
local timer_Adjust = timer.Adjust
timer.Create( tag, 2, 0, function()
	local type = SLogs._Settings[ "Sync" ]
	if type == current then
		timer_Adjust( tag, times[ type ], 0 )
		current = type
	end
	if type == 1 then
		return
	end
	SLogs:Sync( )
end )

function SLogs:LoadSettings( )
	local self = self or SLogs

	if !file.Exists( "slogs/settings.txt", "DATA" ) then
		self:InitDefaultSettings( )
		return
	end

	local tbl = util.JSONToTable( file.Read( "slogs/settings.txt" ) )
	if table.Count( tbl ) == 0 then
		self:InitDefaultSettings( )
		return
	end

	self._Settings = tbl
	for k,v in pairs( self.Settings ) do
		if v.type == "ColorPicker" then
			if v.onChange then
				local value = self:Setting( v.key ) or Color( 80, 80, 80 )
				v.onChange( value )
			end
		end
	end

end

hook.Add( "InitPostEntity", "SLogs.Settings", SLogs.LoadSettings )
SLogs:LoadSettings( )

local function DrawTooltip( w, h, text, font )

	if !text then return end

	font = font or "Default"

	surface.SetFont( font )
	local sizew, _ = surface.GetTextSize( text )

	DisableClipping( true )

	draw.RoundedBox( 0, w + 2, 0, sizew + 4, math.max( h, _ + 2 ), Color( 50, 50, 50 ) )


	draw.DrawText( text, font, w + 4, _ < h and h/2 - _/2 or 0, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )

	DisableClipping( false )

end

local function CreateType( list, tbl )

	local type = tbl.type

	local frame = vgui.Create("EditablePanel", list )
	frame:Dock( TOP )
	frame:DockMargin( 5, 5, 5, 5 )
	frame:DockPadding( 0, 0, 0, 2 )
	frame:SetTall( 9 )
	frame.tooltip = tbl.desc
	frame.Saved = function( self )
		self.stop = CurTime() + 1
		self.stop_tbl = {}
		self.last_save = CurTime()

		SLogs:SaveSettings( )
	end
	frame.Paint = function( self, w, h )

		if self:IsHovered( ) then
			
			draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50 ) )

			DrawTooltip( w + 12, h, self.tooltip )

		end

		if self.last_save and self.last_save < CurTime( ) then
			
			if self.stop > CurTime() then
				surface.SetDrawColor( 255, 0, 0, 255 )
			else
				surface.SetDrawColor( 0, 255, 0, 255 )
			end
			surface.Loading( "Circle", {
				x			= w - 200 - 15,
				y			= h/2,
				scale		= 15,
				radius		= 1,
				circles		= 21,
				speed		= 10,
				dist		= 40,
				stop 		= self.stop,
				stop_tbl	= self.stop_tbl
			} )

		end

		draw.RoundedBox( 0, 0, h-1, w, 1, Color( 100, 100, 100 ) )


	end

	local pnl

	if type == "ComboBox" then

		if tbl.name then
			local label = vgui.Create( "DLabel", frame )
			label:Dock( LEFT )
			label:SetText( tbl.name )
			label:SetTooltip( tbl.desc or "" )
			label:SizeToContents()
		end
		
		pnl = vgui.Create( "DComboBox", frame )
		pnl:Dock( RIGHT )
		pnl:SetWide( 200 )
		pnl:SetSortItems( false )

		for _, k in pairs( tbl.contents ) do

			pnl:AddChoice( k.name )

		end
		pnl:ChooseOptionID( SLogs._Settings[ tbl.key or "error" ] or tbl.default or 1 )
		pnl.key = tbl.key or "error"

		DetourComboBox( pnl, table.Count( tbl.contents ), function( self, i, w, h )
			local desc = tbl.contents[ i ]
			if !desc then return end
			desc = desc.desc

			if self:IsHovered() then
				DrawTooltip( w, h, desc )
			end
		end )

		pnl.OnSelect = function( self, index )

			if tbl.onChange then
				tbl.onChange( index )
			end

			frame.key = tbl.key or "error"
			SLogs._Settings[ self.key ] = index

			frame:Saved()

		end

		frame:SetTall( pnl:GetTall() )

	elseif type == "CheckableComboBox" then

		if tbl.name then
			local label = vgui.Create( "DLabel", frame )
			label:Dock( LEFT )
			label:SetText( tbl.name )
			label:SetTooltip( tbl.desc or "" )
			label:SizeToContents()
		end
		
		pnl = vgui.Create( "DComboBox", frame )
		pnl:Dock( RIGHT )
		pnl:SetWide( 200 )
		pnl:SetSortItems( false )

		local choises = {}
		for _, k in pairs( tbl.contents ) do
			choises[ pnl:AddChoice( k.name ) ] = _
		end

		pnl.key = tbl.key or "error"

		local selected = {}
		for k,v in pairs( choises ) do
			if SLogs._Settings[ tbl.key ][ v ] then
				selected[ k ] = true
			end
		end

		DetourCheckedComboBox( pnl, table.Count( tbl.contents ), function( self, i, w, h )
			local desc = tbl.contents[ i ]
			if !desc then return end
			desc = desc.desc

			if self:IsHovered() then
				DrawTooltip( w, h, desc )
			end
		end, function( index, bool )
			pnl:OnChecked( index, bool )
		end, selected )

		pnl.OnChecked = function( self, index, bool )
			
			if tbl.onChecked then
				tbl.onChecked( choises[ index ], bool )
			end

			frame.key = tbl.key or "error"
			SLogs._Settings[ self.key ] = SLogs._Settings[ self.key ] or {}
			SLogs._Settings[ self.key ][ choises[ index ] ] = bool

			frame:Saved()

		end

		frame:SetTall( pnl:GetTall() )

	elseif type == "Category" then

		frame:Remove()

		pnl = vgui.Create( "DLabel", list )
		pnl:SetTall( 30 )
		pnl:Dock( TOP )
		pnl:SetText( tbl.name )
		pnl:SetContentAlignment( 4 )
		pnl:SetFont( "DermaLarge" )
		pnl:SetColor( Color( 100, 100, 255 ) )

	elseif type == "Font" then

		if tbl.name then
			local label = vgui.Create( "DLabel", frame )
			label:Dock( LEFT )
			label:SetText( tbl.name )
			label:SetTooltip( tbl.desc or "" )
			label:SizeToContents()
		end
		
		pnl = vgui.Create( "DComboBox", frame )
		pnl:Dock( RIGHT )
		pnl:SetWide( 200 )
		pnl:SetSortItems( false )

		for _, k in pairs( SLogs.Fonts ) do

			pnl:AddChoice( k )

		end
		pnl:ChooseOptionID( tonumber( SLogs._Settings[ tbl.key or "error" ] or tbl.default or 1 ) - 4 )
		pnl.key = tbl.key or "error"

		DetourComboBox( pnl, table.Count( SLogs.Fonts ), function( self, i, w, h )
			if self:IsHovered() then
				DrawTooltip( w, h, "Example"..(i+4), "SLogs_" .. i + 4 )
			end
		end )

		pnl.OnSelect = function( self, index, value )

			frame.key = tbl.key or "error"
			SLogs._Settings[ self.key ] = value

			frame:Saved()

		end

		frame:SetTall( pnl:GetTall() )

	elseif type == "ColorPicker" then
		
		if tbl.name then
			local label = vgui.Create( "DLabel", frame )
			label:Dock( LEFT )
			label:SetText( tbl.name )
			label:SetTooltip( tbl.desc or "" )
			label:SizeToContents( )
		end
		
		pnl = vgui.Create( "DButton", frame )
		pnl:Dock( RIGHT )
		pnl:SetWide( 200 )
		pnl:SetText ""
		pnl.Color = SLogs:Setting( tbl.key ) or Color( 100, 0, 0 )
		pnl.DoClick = function( self )
			local frame = vgui.Create( "DFrame" )
			frame:SetSize( 300, 300 )
			frame:SetTitle("Nevermore")
			frame:Center( )
			frame:MakePopup( )
			frame:SetSkin("DarkRP")
		
			local color_picker = vgui.Create("DColorMixer", frame)
			color_picker:Dock( FILL )
			color_picker.ValueChanged = function( picker, clr )
				frame.Color = clr
				self:ValueChanged( clr )
			end
		end
		pnl.ValueChanged = function( self, clr )

			self.Color = clr

			local key = tbl.key or "error"
			frame.key = key
			SLogs._Settings[ key ] = Color( clr.r, clr.g, clr.b )
			frame:Saved()

			if tbl.onChange then
				tbl.onChange( clr )
			end

		end
		pnl.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self.Color )
		end

		frame:SetTall( pnl:GetTall() )

	else

		frame:Remove()

	end

end

local function Create( frame )

	if IsValid( frame._List ) then
		frame._List:Remove()
	end

	frame._List = vgui.Create( "DScrollPanel", frame )

	frame._List:Dock( FILL )
	local vbar = frame._List:GetVBar( )
	vbar:SetWide( 10 )
	vbar:SetHideButtons( true )
	//vbar:SetVisible( false )
	vbar.btnGrip:SetAlpha( 50 )
	vbar.Paint = function()end


	frame._List:DockMargin( ( ScrW()/1.2 )/4, 10, ( ScrW()/1.2 )/4, 10 )
	frame._List:InvalidateParent( true )

	frame._List:Dock( NODOCK )
	local x,y = frame._List:GetPos()
	frame._List:SetPos( x, y - frame._List:GetTall( ) )

	frame._List:MoveTo( x, y, 1, 0 )

	for _, tbl in pairs( SLogs.Settings ) do

		if !tbl.type then continue end

		local pnl = CreateType( frame._List, tbl )

	end
end

local function Remove( pnl )
	if IsValid( pnl ) then
		pnl:Remove( )
	end
end
local function MovePnl( pnl )
	if !IsValid( pnl ) then return end
	local x, y = pnl:GetPos()
	pnl:Dock( NODOCK )
	pnl.DoClick = nil
	pnl:MoveTo( x, y - 40, 1, 0, nil, function()
		Remove( pnl )
	end)
end

local RestoreToDefaults = Material( "icon16/cog_delete.png" )
function SLogs.OpenSettings()

	local frame = slogs_frame
	if IsValid( frame ) then

		--MovePnl( frame._SettingsButton )
		if IsValid( frame._SettingsButton ) then
			frame._SettingsButton:MoveColorTo( "idle", Color(20,20,100) )
			frame._SettingsButton:MoveColorTo( "hovered", Color(20,20,150) )
			frame._SettingsButton:MoveColorTo( "down", Color(0,0,255) )

			local Defaults = vgui.Create( "SLogs_button", frame._TopPanel ):SetType( "Image" )
			Defaults:DockMargin( 0, 0, 1, 0 )
			Defaults:Dock( RIGHT )
			Defaults:SetWide( 30 )
			Defaults:SetImage( RestoreToDefaults )

			Defaults:MoveColorTo( "idle", Color(100,20,20) )
			Defaults:MoveColorTo( "hovered", Color(150,20,20) )
			Defaults:MoveColorTo( "down", Color(255,0,0) )

			Defaults.DoClick = function( )
				Derma_Query( "Вы действительно хотите сбросить настройки?", "Сброс настроек",
				"Да", function( )
					if slogs_frame and IsValid( slogs_frame ) then
						slogs_frame:Remove( )
					end
					SLogs:InitDefaultSettings( )
				end, "Нет")
			end
			
			frame._SettingsButton.DoClick = function( self, w, h )
				Defaults:Remove( )
				SLogs:Open( )
				if slogs_frame and IsValid( slogs_frame._List ) then
					frame._List:Remove()
				end
			end
		end

		Remove( frame._RightPanel )
		Remove( frame._NavigationPanel )

		Create( frame )
		
	else
		return
	end

end