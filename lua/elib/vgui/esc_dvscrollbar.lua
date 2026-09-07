local PANEL = {}

AccessorFunc( PANEL, "m_HideButtons", "HideButtons" )
AccessorFunc( PANEL, "color", "Color", FORCE_COLOR )

function PANEL:Init()

	self.skin = esclib.addon:GetCurrentSkin()

	self.Offset = 0
	self.Scroll = 0
	self.CanvasSize = 1
	self.BarSize = 1

	self.scroll_speed = 0.5
	self.scrollspeed = 20
	self.scrollsoftness = 0.15 --the smaller the softer

	self.btnUp = vgui.Create( "DButton", self )
	self.btnUp:SetText( "" )
	self.btnUp.DoClick = function( self ) self:GetParent():AddScroll( -1 ) end
	self.btnUp.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonUp", panel, w, h ) end

	self.btnDown = vgui.Create( "DButton", self )
	self.btnDown:SetText( "" )
	self.btnDown.DoClick = function( self ) self:GetParent():AddScroll( 1 ) end
	self.btnDown.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonDown", panel, w, h ) end

	self.btnGrip = vgui.Create( "DScrollBarGrip", self )
	self:SetColor(self.skin.colors.button.hover)
    self.btnGrip.Paint = function( pnl, w, h ) 
    	draw.RoundedBox(0,0,0,w,h, self.color)
    end

	self:SetSize( 5, 15 )
	self:SetHideButtons( true )
end

function PANEL:SetSpeed(num)
	self.scrollspeed = num
end

function PANEL:GetSpeed()
	return self.scrollspeed
end

function PANEL:SetSoftness(num)
	self.scrollsoftness = num
end

function PANEL:GetSoftness()
	return self.scrollsoftness
end


function PANEL:SetEnabled( b )
	if not ( b ) then
		self.Offset = 0
		self:SetScroll( 0 )
		self.HasChanged = true
	end

	self:SetMouseInputEnabled( b )
	self:SetVisible( b )

	if ( self.Enabled ~= b ) then
		self:GetParent():InvalidateLayout()
		if ( self:GetParent().OnScrollbarAppear ) then
			self:GetParent():OnScrollbarAppear()
		end
	end

	self.Enabled = b
end

function PANEL:Value()
	return self.Pos
end

function PANEL:BarScale()
	if ( self.BarSize == 0 ) then return 1 end
	return self.BarSize / ( self.CanvasSize + self.BarSize )
end

function PANEL:SetUp( _barsize_, _canvassize_ )
	self.BarSize = _barsize_
	self.CanvasSize = math.max( _canvassize_ - _barsize_, 1 )
	self:SetEnabled( _canvassize_ > _barsize_ )
	self:InvalidateLayout()
end

function PANEL:SetScroll( scrll )
	-- if ( not self.Enabled ) then self.Scroll = 0 return end
	self.Scroll = math.Clamp( scrll, 0, self.CanvasSize )
	self:InvalidateLayout()

	local func = self:GetParent().OnVScroll
	if ( func ) then
		func( self:GetParent(), self:GetOffset() )
	else
		self:GetParent():InvalidateLayout()
	end
end

function PANEL:OnMouseWheeled( dlta )
	if ( not self:IsVisible() ) then return false end

	self.scroll_speed = self.scroll_speed + (6 * RealFrameTime()) --gain

	return self:AddScroll( dlta * -self.scroll_speed )
end

function PANEL:AddScroll( dlta )
	local OldScroll = self:GetScroll()
	dlta = dlta * (self.scrollspeed)
	self.Scroll2Add = dlta

	return OldScroll ~= self:GetScroll()
end

function PANEL:Think()

	if self.Scroll2Add then
		local oldscroll = self:GetScroll()
		local newscroll = self:GetScroll() + self.Scroll2Add

		-- print(newscroll)
		self:SetScroll( newscroll )
		self.Scroll2Add = self.Scroll2Add - self.Scroll2Add*self.scrollsoftness

		if math.floor(self:GetScroll()) == math.floor(oldscroll) then self.Scroll2Add = nil end
	end

	-- if (self.Scroll > self.CanvasSize) then
	-- 	self:SetScroll( self:GetScroll() - (self.Scroll-self.CanvasSize)*0.08)
	-- end

	if (self.Scroll < 0) then
		self:SetScroll( self:GetScroll() + 5 )
	end

	self.scroll_speed = Lerp(RealFrameTime(), self.scroll_speed, 0.2)
end

function PANEL:AnimateTo( scrll, length, delay, ease )

	local anim = self:NewAnimation( length, delay, ease )
	anim.StartPos = self.Scroll
	anim.TargetPos = scrll
	anim.Think = function( anim, pnl, fraction )
		pnl:SetScroll( Lerp( fraction, anim.StartPos, anim.TargetPos ) )
	end

end

function PANEL:GetScroll()
	if ( not self.Enabled ) then self.Scroll = 0 end
	return self.Scroll

end

function PANEL:GetOffset()

	if ( not self.Enabled ) then return 0 end
	return self.Scroll * -1

end

function PANEL:ScrollToBottom()
	self:InvalidateParent(true)
	self.Scroll = self.CanvasSize
end


function PANEL:Paint( w, h )
end

function PANEL:OnMousePressed()
	local x, y = self:CursorPos()
	local PageSize = self.BarSize
	if ( y > self.btnGrip.y ) then
		self:SetScroll( self:GetScroll() + PageSize )
	else
		self:SetScroll( self:GetScroll() - PageSize )
	end
end

function PANEL:OnMouseReleased()
	self.Dragging = false
	self.DraggingCanvas = nil
	self:MouseCapture( false )

	self.btnGrip.Depressed = false
end

function PANEL:OnCursorMoved( x, y )
	if ( not self.Enabled ) then return end
	if ( not self.Dragging ) then return end

	local x, y = self:ScreenToLocal( 0, gui.MouseY() )

	-- Uck.
	y = y - self.btnUp:GetTall()
	y = y - self.HoldPos

	local BtnHeight = self:GetWide()
	if ( self:GetHideButtons() ) then BtnHeight = 0 end

	local TrackSize = self:GetTall() - BtnHeight * 2 - self.btnGrip:GetTall()

	y = y / TrackSize

	self:SetScroll( y * self.CanvasSize )
end

function PANEL:Grip()

	if ( not self.Enabled ) then return end
	if ( self.BarSize == 0 ) then return end

	self:MouseCapture( true )
	self.Dragging = true

	local x, y = self.btnGrip:ScreenToLocal( 0, gui.MouseY() )
	self.HoldPos = y

	self.btnGrip.Depressed = true

end

function PANEL:PerformLayout()

	local Wide = self:GetWide()
	local BtnHeight = Wide
	if ( self:GetHideButtons() ) then BtnHeight = 0 end
	local Scroll = self:GetScroll() / self.CanvasSize
	local BarSize = math.max( self:BarScale() * ( self:GetTall() - ( BtnHeight * 2 ) ), 10 )
	local Track = self:GetTall() - ( BtnHeight * 2 ) - BarSize
	Track = Track + 1

	Scroll = Scroll * Track

	self.btnGrip:SetPos( 0, BtnHeight + Scroll )
	self.btnGrip:SetSize( Wide, BarSize )

	if ( BtnHeight > 0 ) then
		self.btnUp:SetPos( 0, 0, Wide, Wide )
		self.btnUp:SetSize( Wide, BtnHeight )

		self.btnDown:SetPos( 0, self:GetTall() - BtnHeight )
		self.btnDown:SetSize( Wide, BtnHeight )
		
		self.btnUp:SetVisible( true )
		self.btnDown:SetVisible( true )
	else
		self.btnUp:SetVisible( false )
		self.btnDown:SetVisible( false )
		self.btnDown:SetSize( Wide, BtnHeight )
		self.btnUp:SetSize( Wide, BtnHeight )
	end

end

derma.DefineControl( "esclib.scrollbar", "A Scrollbar for esclib", PANEL, "Panel" )