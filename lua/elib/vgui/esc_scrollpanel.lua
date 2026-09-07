local min = math.min
local max = math.max
local PANEL = {}

AccessorFunc( PANEL, "Padding", "Padding" )
AccessorFunc( PANEL, "ScrollSpeed", "ScrollSpeed", FORCE_NUMBER)
AccessorFunc( PANEL, "pnlCanvas", "Canvas" )

function PANEL:Init()
	self.pnlCanvas = vgui.Create( "Panel", self )
	self.pnlCanvas.OnMousePressed = function( self, code ) self:GetParent():OnMousePressed( code ) end
	self.pnlCanvas:SetMouseInputEnabled( true )
	self.pnlCanvas.PerformLayout = function( pnl )
		self:PerformLayoutInternal()
		self:InvalidateParent()
	end

	self.VBar = vgui.Create( "esclib.scrollbar", self )
	self.VBar:Dock( RIGHT )

	self:SetPadding( 0 )
	self:SetMouseInputEnabled( true )
	self:SetScrollSpeed(12)

	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )
	self:SetPaintBackground( false )
end

function PANEL:ScrollToBottom()
	self:GetVBar():ScrollToBottom()
end

function PANEL:SetScrollSpeed(val)
	self.ScrollSpeed = val
	self:GetVBar():SetSpeed(val)
end

function PANEL:AddItem( pnl )
	pnl:SetParent( self:GetCanvas() )
end

function PANEL:OnChildAdded( child )
	self:AddItem( child )
end

function PANEL:SizeToContents()
	self:SetSize( self.pnlCanvas:GetSize() )
end

function PANEL:GetVBar()
	return self.VBar
end

function PANEL:SetScroll(scroll)
	self.VBar:SetScroll(scroll)
end

function PANEL:GetScroll()
	return self.VBar:GetScroll()
end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:InnerWidth()
	return self:GetCanvas():GetWide()
end

function PANEL:Rebuild()
	self:GetCanvas():SizeToChildren( false, true )
	if ( self.m_bNoSizing && self:GetCanvas():GetTall() < self:GetTall() ) then
		self:GetCanvas():SetPos( 0, ( self:GetTall() - self:GetCanvas():GetTall() ) * 0.5 )
	end
end

function PANEL:OnMouseWheeled( dlta )
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:OnVScroll( iOffset )
	self.pnlCanvas:SetPos( 0, iOffset )
end

function PANEL:ScrollToChild( panel, animate )
	self:InvalidateLayout( true )
	local x, y = self.pnlCanvas:GetChildPosition( panel )
	local w, h = panel:GetSize()
	y = max(y - h, 0)
	if animate then
		self.VBar:AnimateTo( min(y, self.VBar.CanvasSize), 0.2, 0, 0.1 )
	else 
		self.VBar:SetScroll( min(y, self.VBar.CanvasSize) )
	end
end

function PANEL:PerformLayoutInternal()
	local Tall = self.pnlCanvas:GetTall()
	local Wide = self:GetWide()
	local padding = self.VBar:IsVisible() and self.Padding or 0
	local YPos = 0

	self:Rebuild()

	self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
	YPos = self.VBar:GetOffset()

	if ( self.VBar.Enabled ) then Wide = Wide - self.VBar:GetWide() end

	self.pnlCanvas:SetPos( 0, YPos )
	self.pnlCanvas:SetWide( Wide-padding )

	self:Rebuild()

	if ( Tall ~= self.pnlCanvas:GetTall() ) then
		self.VBar:SetScroll( self.VBar:GetScroll() )
	end

end

function PANEL:PerformLayout()
	self:PerformLayoutInternal()
end

function PANEL:Clear()
	return self.pnlCanvas:Clear()
end

derma.DefineControl( "esclib.scrollpanel", "", PANEL, "DPanel" )