local PANEL={}

AccessorFunc( PANEL, "m_bDraggable",		"Draggable",		FORCE_BOOL )
AccessorFunc( PANEL, "m_bScreenLock",		"ScreenLock",		FORCE_BOOL )
AccessorFunc( PANEL, "m_bSizable",			"Sizable",			FORCE_BOOL )

AccessorFunc( PANEL, "m_iMinWidth",			"MinWidth",			FORCE_NUMBER )
AccessorFunc( PANEL, "m_iMinHeight",		"MinHeight",		FORCE_NUMBER )

function PANEL:Init()
	self:SetSize(400,400)
	self.dragarea = { x=0, y=0, w=self:GetWide(), h=self:GetTall()}

	self:SetDraggable( true )
	self:SetSizable( false )
	self:SetMinWidth( 100 )
	self:SetMinHeight( 50 )
	self:SetScreenLock( false )
end

function PANEL:IsMouseInDragArea()
    local x, y = self:LocalToScreen(0, 0)
    local mx, my = gui.MousePos()

    return mx >= x + self.dragarea.x 
    and my >= y + self.dragarea.y 
    and mx < x + self.dragarea.x + self.dragarea.w 
    and my < y + self.dragarea.y + self.dragarea.h
end

function PANEL:IsMouseInSizeArea()
	local screenX, screenY = self:LocalToScreen( 0, 0 )
	return gui.MouseX() > ( screenX + self:GetWide() - 20 ) && gui.MouseY() > ( screenY + self:GetTall() - 20 )
end

--MOUSE DRAGGING
function PANEL:OnMousePressed()
	self:OnPress()
	local screenX, screenY = self:LocalToScreen( 0, 0 )
	if ( self.m_bSizable && self:IsMouseInSizeArea() ) then
		self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
		self:MouseCapture( true )
		return
	end

	--if ( self:GetDraggable() && gui.MouseY() < ( screenY + 24 ) ) then
	if ( self:GetDraggable() && self:IsMouseInDragArea()) then
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		self:OnStartDragging(self:GetX(),self:GetY())
		return
	end
end

function PANEL:OnMouseReleased()
	self:OnUnpress()
	if self.Dragging then
		self.Dragging = nil
		self:OnEndDragging(self:GetX(),self:GetY())
	end
	if self.Sizing then
		self.Sizing = nil
		self:InvalidateChildren(true)
		self:OnEndSizing(self:GetWide(),self:GetTall())
	end
	self:MouseCapture( false )
end

function PANEL:SetDragArea(x,y,w,h)
	self.dragarea.x = x
	self.dragarea.y = y
	self.dragarea.w = w
	self.dragarea.h = h
end

function PANEL:OnDragging(newx,newy)
	--for override
end

function PANEL:OnSizing(neww,newh)
	--for override
end

function PANEL:OnStartDragging(x,y)
	--for override
end

function PANEL:OnEndDragging(newx,newy)
	--for override
end

function PANEL:UpdateDragArea()
	self.dragarea = { x=0, y=0, w=self:GetWide(), h=self:GetTall()}
end

function PANEL:OnEndSizing(neww, newh)
	--for override
	self:UpdateDragArea()
end

function PANEL:OnPress()
	--for override
end

function PANEL:OnUnpress()
	--for override
end

function PANEL:Think()

	local mousex = math.Clamp( gui.MouseX(), 1, esclib.scrw - 1 )
	local mousey = math.Clamp( gui.MouseY(), 1, esclib.scrh - 1 )

	if ( self.Dragging ) then

		local x = mousex - self.Dragging[1]
		local y = mousey - self.Dragging[2]

		-- Lock to screen bounds if screenlock is enabled
		if ( self:GetScreenLock() ) then

			x = math.Clamp( x, 0, esclib.scrw - self:GetWide() )
			y = math.Clamp( y, 0, esclib.scrh - self:GetTall() )

		end

		self:OnDragging(newx,newy)
		self:SetPos( x, y )

	end

	if ( self.Sizing ) then

		local x = mousex - self.Sizing[1]
		local y = mousey - self.Sizing[2]
		local px, py = self:GetPos()

		if ( x < self.m_iMinWidth ) then x = self.m_iMinWidth elseif ( x > esclib.scrw - px && self:GetScreenLock() ) then x = esclib.scrw - px end
		if ( y < self.m_iMinHeight ) then y = self.m_iMinHeight elseif ( y > esclib.scrh - py && self:GetScreenLock() ) then y = esclib.scrh - py end

		self:OnSizing(x,y)
		self:SetSize( x, y )
		return

	end

	local screenX, screenY = self:LocalToScreen( 0, 0 )
	if ( self.Hovered && self.m_bSizable && mousex > ( screenX + self:GetWide() - 20 ) && mousey > ( screenY + self:GetTall() - 20 ) ) then
		self:SetCursor( "sizenwse" )
		return
	end

	--if ( self.Hovered && self:GetDraggable() && mousey < ( screenY + 24 ) ) then
	if ( self.Hovered && self:GetDraggable() && self:IsMouseInDragArea() ) then
		self:SetCursor( "sizeall" )
		return
	end

	self:SetCursor( "arrow" )

	if ( self.y < 0 ) then
		self:SetPos( self.x, 0 )
	end

end

function PANEL:Paint(w,h)
	--for rewrite
end

vgui.Register( "esclib.dragbase", PANEL, "EditablePanel" );