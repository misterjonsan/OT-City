function SLogs:StartLoading( id ) end
function SLogs:StopLoading( id ) end
local PANEL = {}
function PANEL:Init( )
	if SLogs:Setting "Background" == 3 then
		hook.Add("RenderScene","SLogsBackground",function()return true end)
	end
	self:MakePopup()
	self.startTime = SysTime()

	self._TopPanel = vgui.Create( "EditablePanel", self )
	self._TopPanel:Dock( TOP )
	self._TopPanel:SetTall( 30 )

	self._CloseButton = vgui.Create( "SLogs_button", self._TopPanel ):SetType( "Close" )
	self._CloseButton:Dock( RIGHT )
	self._CloseButton:SetWide( 30 )
	self._CloseButton.DoClick = function( )
		self:Remove( )
	end
end
function PANEL:Paint( w, h )
	if SLogs:Setting "Background" == 2 then
		Derma_DrawBackgroundBlur( self, self.startTime )
	end

	draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30 ) )

	DisableClipping( true )
	draw.SimpleText( "Логи | OT-City | Monteract Project", "SLogs_Logo", 0, 30, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
	DisableClipping( false )
end
function PANEL:OnRemove()
	hook.Remove("RenderScene", "SLogsBackground")
end
vgui.Register( "SLogs_frame", PANEL, "EditablePanel" )

PANEL = {}
local Types = {
	["Close"] = function( self )
		self.Colors = {
			idle = Color( 255, 100, 100 ),
			down = Color( 255, 0, 0 ),
			hovered = Color( 255, 50, 50 )
		}
		self.Paint2 = function( self, w, h )
			draw.SimpleText( "X", "DermaLarge", w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end,
	["Default"] = function( self )
		self.Colors = {
		    idle    = Color( 34, 139, 34 ),
		    down    = Color( 50, 205, 50 ),
		    hovered = Color( 0, 255, 127 )
		}
		self.text = "#001"
		self.font = "Default"
		self.SetText = function( self, str )
			if !isstring( str ) then return end
			self.text = str
		end
		self.SetFont = function( self, str )
			self.font = str
		end
		self.Flash = function( self )
			self.LastFlash = CurTime( )
		end
		self.Paint2 = function( self, w, h )
			draw.SimpleText( self.text, self.font, w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			if self.LastFlash then
				local alpha = ( self.LastFlash - CurTime( ) + 1 ) * 255
				if alpha <= 0 then
					self.LastFlash = false
					return
				end
				surface.SetDrawColor( 255, 255, 255, alpha )
				surface.DrawOutlinedRect( 0, 0, w, h )
			end
		end
		self.SetColor = function( self, colors )
			self.Colors = colors
		end
	end,
	["Image"] = function( self )
		self.Colors = {
			idle = Color( 100, 100, 100 ),
			down = Color( 200, 200, 200 ),
			hovered = Color( 150, 150, 150 )
		}
		self.SetImage = function( self, str )
			self.image = str
		end
		self.Paint2 = function( self, w, h )
			if !self.image then return end
			surface.SetDrawColor( 255, 255, 255 )
			surface.SetMaterial( self.image )
			surface.DrawTexturedRect( w/12, h/12, w/1.2, h/1.2 )
		end
		self.SetColor = function( self, col )
			self.Colors = col
		end
	end,
	[ "Player" ] = function( self )
		self.Player = nil
		self.PlayerName = nil

		self.SetPlayer = function( self, steamid )
			self.Player = steamid
			local ply = player.GetBySteamID( steamid )

			if self.Avatar and IsValid( self.Avatar ) then
				self.Avatar:Remove( )
				self.Avatar = nil
			end

			if !IsValid( ply ) then
				self.text = steamid
				return
			end
			
			self.text = ply:GetName( )

			self.Avatar = vgui.Create( "AvatarImage", self )
			self.Avatar:Dock( LEFT )
			self.Avatar:SetWide( self:GetTall( ) )
			self.Avatar:SetPlayer( ply, self:GetTall( ) )
		end
		self.GetPlayer = function( self )
			return self.Player
		end
		self.Paint2 = function( self, w, h )
			draw.SimpleText( self.text, SLogs:Setting "f_Button", (self.Avatar and h or 0) + 2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
	end
}
function PANEL:Init()
	self.down = false
	self:SetCursor( "hand" )
	self.type = "Default"
	self.Lerp = false
	self.LerpSpeed = 10
	Types[ self.type ]( self )
end
function PANEL:SetType( str )
	if !Types[ str ] then return self end
	Types[ str ]( self )
	self.type = str
	return self
end
function PANEL:SetLerp( bool )
	self.Lerp = bool
end
function PANEL:SetLerpSpeed( num )
	self.LerpSpeed = num
end
function PANEL:MoveColorTo( id, color )
	if !self.Colors[ id ] then return end
	self._ColorMove = true
	self.ToMove = self.ToMove or {}
	self.ToMove[ id ] = color
end
function PANEL:Think( )
	if !self._ColorMove then return end
	if table.Count( self.ToMove ) == 0 then self.ToMove = {}self._ColorMove = nil return end
	for id, color2 in pairs( self.ToMove ) do
		local color1 = self.Colors[ id ]
		if color2 == color1 then self.ToMove[ id ] = nil continue end
		color1.r = Lerp( 0.005, color1.r, color2.r )
		color1.g = Lerp( 0.005, color1.g, color2.g )
		color1.b = Lerp( 0.005, color1.b, color2.b )
	end
end
function PANEL:Paint( w, h )
	local color = self.Colors.idle
	if self.down then
		color = self.Colors.down
	elseif self:IsHovered() then
		color = self.Colors.hovered
	end
	if self.Lerp then
		local color2 = Color(color.r,color.g,color.b)
		color2.a = 50
		draw.RoundedBox( 4, 0, 0, w, h, color2 )
		self.width = Lerp( FrameTime()*self.LerpSpeed, self.width or 2, ( self:IsHovered() or (SLogs and SLogs.Menu and SLogs.Menu.OpenedButton == self) ) and w or 2 )
		draw.RoundedBox( 4, 0, 0, self.width, h, color )
	else
		draw.RoundedBox( 4, 0, 0, w, h, color )
	end
	if !self.Paint2 then return end
	self:Paint2( w, h )
end
function PANEL:OnMousePressed( )
	self.down = true
	self:MouseCapture( true )
end
function PANEL:OnMouseReleased( )
	self.down = false
	self:MouseCapture( false )
	if self.DoClick then
		self:DoClick( )
	end
end
vgui.Register( "SLogs_button", PANEL, "EditablePanel" )

PANEL = {}
function PANEL:Init()self.text=""self.font=""self:SetTall(30)end
function PANEL:SetText(s)self.text=s end
function PANEL:SetFont(s)self.font=s end
function PANEL:Paint( w, h )
	draw.SimpleText( self.text, self.font, w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end
vgui.Register( "SLogs_Label", PANEL, "EditablePanel" )

PANEL = {}

--[=====[
	hax to RichText ( .OnMouseReleased doesn't work )
]=====]
hook.Add( "VGUIMousePressed", "SLogs_RichText", function( pnl, code )
	if pnl.SLogs_RichText then
		if code == 108 then --right
			if pnl.DoRightClick then
				pnl:DoRightClick( )
			end
		elseif code == 107 then --left
			if pnl.DoClick then
				pnl:DoClick( )
			end
		elseif code == 109 then --middle
			if pnl.DoMiddleClick then
				pnl:DoMiddleClick()
			end
		end
	end
end )

local function Translate( id )
	return SLogs:Translate( "LogActions", id )
end
local options = {
	[ "copy" ] = function( info )
		if !info.ply1 and !info.ply2 then return end
		return {
			name = Translate "copy",
			click = info.text,
			image = "paste_plain"
		}
	end,
	[ "copy_ply1" ] = function( info )
		if !info.ply1 then return end
		return {
			name = ( Translate "ply" ) .. " 1",
			parent = "copy",
			click = ("%s (%s)"):format( info.ply1 or "nil", info.sid1 or "nil" ),
			image = "user_green"
		}
	end,
	[ "copy_ply1.SteamID"] = function( info )
		return {
			name = Translate "sid",
			parent = "copy_ply1",
			click = info.sid1,
			image = "tag"
		}
	end,
	[ "copy_ply1.Name"] = function( info )
		return {
			name = Translate "name",
			parent = "copy_ply1",
			click = info.ply1,
			image = "tag_green"
		}
	end,


	[ "copy_ply2" ] = function( info )
		if !info.ply2 then return end
		return {
			name = ( Translate "ply" ) .. " 2",
			parent = "copy",
			click = ("%s (%s)"):format( info.ply2 or "nil", info.sid2 or "nil" ),
			image = "user_red"
		}
	end,
	[ "copy_ply2.SteamID"] = function( info )
		return {
			name = Translate "sid",
			parent = "copy_ply2",
			click = info.sid2,
			image = "tag"
		}
	end,
	[ "copy_ply2.Name"] = function( info )
		return {
			name = Translate "name",
			parent = "copy_ply2",
			click = info.ply2,
			image = "tag_red"
		}
	end,

	[ "watch" ] = function( info )
		if !info.eye then return end
		return {
			name = Translate "watch",
			click = function( )
				SLogs.Eye:Load( info.eye )
			end,
			image = "eye"
		}
	end,

	[ "say" ] = function( info )
		return {
			name = Translate "say",
			click = function()
				RunConsoleCommand( "say", info.text )
			end,
			image = "pencil_go"
		}
	end,
	[ "say_ply1" ] = function( info )
		if !info.ply1 then return end
		return {
			name = ( Translate "ply" ) .. " 1",
			click = function()
				RunConsoleCommand( "say", ("%s (%s)"):format( info.ply1 or "nil", info.sid1 or "nil" ) )
			end,
			parent = "say",
			image = "user_green"
		}
	end,
	[ "say_ply2" ] = function( info )
		if !info.ply2 then return end
		return {
			name = ( Translate "ply" ) .. " 2",
			click = function()
				RunConsoleCommand( "say", ("%s (%s)"):format( info.ply2 or "nil", info.sid2 or "nil" ) )
			end,
			parent = "say",
			image = "user_red"
		}
	end,
	[ "log" ] = function( info )
		if !info.key then return end

		return {
			name = Translate "log",
			click = function()
				
			end,
			image = "tag"
		}
	end
}

local function InitDMenu( dmenu, info )

	local opts = {}

	for k, v in SortedPairs( options ) do
		local result = v( info )
		if !result then continue end
		local parent = dmenu

		if result.parent then

			parent = opts[ result.parent .. "_sub" ]
			if !parent then

				local option = opts[ result.parent ]
				if !option then continue end
				local sub = option:AddSubMenu( )
				opts[ result.parent .. "_sub" ] = sub
				parent = sub

			end

			if !parent then continue end
		end

		local option = parent:AddOption( result.name, result.click and
			( isfunction( result.click ) and result.click
			or function()
				SetClipboardText( result.click )
			end )
			or nil )
		opts[ k ] = option
		if result.image then
			option:SetImage( ("icon16/%s.png"):format( result.image ) )
		end
		if k == "log" then
			InitDMenu( option:AddSubMenu( ), SLogs.Logs[ info.key ].E )
		end
	end

end

function PANEL:Init()
	self.Font = "Default"

	self.Text = vgui.Create( "RichText", self )
	self.Text:Dock( FILL )
	self.Text:SetWrap( true )
	self.Text.Text = ""
	self.Text:SetVerticalScrollbarEnabled( true )
	self.Text.PerformLayout = function( s )
		s:SetFontInternal( self.Font )
	end
	self.Text.DoRightClick = function( text_pnl )
		local x,y = gui.MousePos( )
		timer.Simple(0.01,function()
			local tall = 0
			for v,k in pairs( text_pnl:GetChildren() ) do
				for v,k2 in pairs( k:GetChildren() ) do
					if k2:GetName() != "C&opy" then continue end
					tall = k2:GetTall()
					k2:SetText( SLogs:Translate( "LogActions", "copy_selected" ) )
					k2:SetCursor( "hand" )
				end
			end
			if !self.info then return end
			local menu = DermaMenu( text_pnl )

			local info = table.Copy( self.info )
			info.text = text_pnl.Text
			InitDMenu( menu, info )

			menu:Open( x or nil, (y or gui.MouseY()) + tall  )
		end)
	end
	self.Text.DoMiddleClick = function()end
	self.Text.SLogs_RichText = true
	self.Text:SetToFullHeight()
end
function PANEL:SetFont( str )
	self.Font = str
	self.Text:SetFontInternal( str )
end
function PANEL:Paint( w, h )
	draw.RoundedBox( 5, 0, 0, w, h, Color( 255, 255, 255, --[[ self.Selected and 10 or --]] 2 ) )
end
function PANEL:SetText( tbl )
	if !tbl or !istable( tbl ) then self:SetText( { Color( 255, 0, 0 ), "Something went wrong with translation ID. Let the administration know about it." } ) return end
	self.Text:SetText "" -- idk why :3
	self.Text.Text = "" -- idk why :3
	for _, k in pairs( tbl ) do
		if istable( k ) then
			self.Text:InsertColorChange( k.r or 255, k.g or 100, k.b or 100, k.a or 255 )
		else
			self.Text:AppendText( k )
			self.Text.Text = self.Text.Text .. k
		end
	end
	self.Text:SetToFullHeight()
	timer.Simple(0.001,function()
		if !IsValid( self ) or !IsValid( self.Text ) then return end
		local num = self.Text:GetNumLines( )
		if num <= 1 then self.Text:SetVerticalScrollbarEnabled( false ) return end
		if num <= 5 then self.Text:SetVerticalScrollbarEnabled( false ) end

		num = math.Clamp( num, 1, 5 )
		self:SetTall( (self:GetTall( ) - 2) * num + num + 1 )
	end)
end
function PANEL:SetInfo( info )
	self.info = info
end
vgui.Register( "SLogs_LogsLine", PANEL, "EditablePanel" )

PANEL = {}
function PANEL:Init( )
	self.page = 0
	self.lines = 0
	self.max_lines = 25 * 2 ^ (( tonumber( SLogs:Setting "MaxLines" ) or 3 ) - 1 )

	self.Navigation = vgui.Create( "EditablePanel", self )
	self.Navigation:Dock( BOTTOM )
	self.Navigation:SetTall( 20 )
	self.Navigation.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
	end

	local left = vgui.Create( "SLogs_button", self.Navigation ):SetType( "Default" )
	left:Dock( LEFT )
	left:DockMargin( 5, 0, 5, 5 )
	left:SetWide( 40 )
	left:SetText( "<" )
	left:SetFont( SLogs:Setting "f_Button" )
	left.DoClick = function()
		self:PreviousPage()
	end

	local right = vgui.Create( "SLogs_button", self.Navigation ):SetType( "Default" )
	right:Dock( RIGHT )
	right:SetWide( 40 )
	right:DockMargin( 5, 0, 5, 5 )
	right:SetText( ">" )
	right:SetFont( SLogs:Setting "f_Button" )
	right.DoClick = function()
		self:NextPage()
	end

	self.Scroll = vgui.Create( "DScrollPanel", self ) 
	self.Scroll:Dock( FILL )
end
function PANEL:AddLine( id )
	self.lines = self.lines + 1

	local line = vgui.Create( "SLogs_LogsLine", self.Scroll )
	line:Dock( TOP )
	line:SetFont( SLogs:Setting "f_Log" )
	local tbl = SLogs.Logs[ id ]
	if !tbl then
		line:Remove()
		return
	end
	local extrainfo = tbl.E
	line:SetInfo( extrainfo )
	line:SetText( SLogs:Translate( "Logs", tbl.T, tbl.I, extrainfo, true, SLogs:Setting "c_TextLog" or Color( 255, 255, 255 ), tbl.t ) )
	surface.SetFont( SLogs:Setting "f_Log" )
	local _, h = surface.GetTextSize( "1" )
	line:SetTall( h + 2 )
	line:DockMargin( 4, 4, 4, 0 )
end
function PANEL:Open( page )
	local tbl = self.Table
	if !istable( tbl ) then return end
	page = page or 1
	if page <= 0 then return end
	local count = table.Count( tbl )
	local start_value = self.max_lines * ( page - 1 ) + 1
	local end_value = start_value + self.max_lines

	if count < start_value then return end

	self.page = page
	self.lines = 0
	self.Scroll:Clear()

	local start_value = self.max_lines * ( page - 1 ) + 1
	local end_value = start_value + self.max_lines
	for i = start_value, math.Clamp( end_value, start_value, count ) do
		self:AddLine( tbl[ i ] )
	end
end
function PANEL:SetTable( tbl )
	if !istable( tbl ) then return end
	table.sort( tbl, function(a,b)
		return a > b
	end)
	self.Table = tbl
end
function PANEL:AddToTable( value, addline )
	table.insert( self.Table, value )
end
function PANEL:NextPage( )
	self:Open( self.page == 0 and 1 or self.page + 1 )
end
function PANEL:PreviousPage( )
	self:Open( self.page == 0 and 1 or self.page - 1 )
end
function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30 ) )
end
vgui.Register( "SLogs_LogsList", PANEL, "EditablePanel" )