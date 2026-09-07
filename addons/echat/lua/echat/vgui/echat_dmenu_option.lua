local PANEL = {}

AccessorFunc( PANEL, "description", "Description" )
AccessorFunc( PANEL, "args", "Args" )
AccessorFunc( PANEL, "m_pMenu", "Menu" )
AccessorFunc( PANEL, "m_bChecked", "Checked" )
AccessorFunc( PANEL, "m_bCheckable", "IsCheckable" )

function PANEL:Init()
	self.clr = echat.addon:GetColors()
	
	self:SetContentAlignment( 4 )
	self:SetTextInset( 10, 0 ) -- Room for icon on left
	self:SetChecked( false )
	self:SetDescription("")
	self:SetArgs({})

	self.icon = nil
	self.text_width = ""
	self.internal_text = ""
	self.icon_color = Color(255,255,255)

	self:SetText("") --disable drawing of dlabel
	function self:SetText(text) --replace
		self.internal_text = text
		local tw, th = esclib.util:TextSize(self:GetText(),self:GetFont())
		self.text_width = tw
	end

	local old_setfont = self.SetFont
	function self:SetFont(font)
		old_setfont(self,font)
		local tw, th = esclib.util:TextSize(self:GetText(),self:GetFont())
		self.text_width = tw
	end
end

function PANEL:GetFullWide()
	local offset = 10
	if self:HasIcon() then
		offset = 25
	end
	local tw, th = esclib.util:TextSize(self:GetDescription() or "",self:GetFont())
	return self.text_width + offset + tw
end

function PANEL:GetText()
	return self.internal_text
end

function PANEL:SetSubMenu( menu )
	self.SubMenu = menu

	if ( not IsValid( self.SubMenuArrow ) ) then
		self.SubMenuArrow = vgui.Create( "DPanel", self )
		self.SubMenuArrow.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "MenuRightArrow", panel, w, h ) end

	end
end

function PANEL:AddSubMenu()
	local SubMenu = DermaMenu( true, self )
	SubMenu:SetVisible( false )
	SubMenu:SetParent( self )

	self:SetSubMenu( SubMenu )

	return SubMenu
end

function PANEL:OnCursorEntered()
	if ( IsValid( self.ParentMenu ) ) then
		self.ParentMenu:OpenSubMenu( self, self.SubMenu )
		return
	end

	self:GetParent():OpenSubMenu( self, self.SubMenu )

end

function PANEL:SetIcon(material, clr)
	self.icon = material
	if clr and IsColor(clr) then self.icon_color = clr end
end
function PANEL:SetIconColor(clr)
	self.icon_color = clr
end

function PANEL:OnCursorExited()

end

function PANEL:HasIcon()
	return self.icon ~= nil
end

function PANEL:Paint( w, h )
	local parent = self:GetMenu()
	local scroll = parent:GetVBar():GetScroll()
	local y = self:GetY()

	if y-parent:GetTall() > scroll then return end

	local offset_x = 10
	if self.Highlight || self:IsHovered() then
		draw.RoundedBox(8,0,0,w,h,self.clr.main.button_hover)
	end
	if self:HasIcon() then
		offset_x = 35
		esclib.draw:MaterialCentered(h*0.6, h*0.5,h*0.3, self.icon_color, self.icon)
	end

	local font = self:GetFont()
	local text = self:GetText()
	draw.SimpleText(text, font, offset_x, h*0.5, self.clr.main.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	local args = self:GetArgs()
	if args then
		local off_x, _ = esclib.util:TextSize(text, font)
		offset_x = offset_x + off_x + 5
		for _, v in ipairs(args) do
			draw.SimpleText(v, font, offset_x, h*0.5, self.clr.main.text_gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local tw, _ = esclib.util:TextSize(v, font)
			offset_x = offset_x + tw + 5
		
		end
	end

	local desc = esclib.util:TextCut(self:GetDescription(),font,w-(offset_x+self.text_width)-25,"...")
	draw.SimpleText(desc,font, w-5, h*0.5, self.clr.main.text_gray, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function PANEL:OnMousePressed( mousecode )
	self.m_MenuClicking = true
	DButton.OnMousePressed( self, mousecode )
end

function PANEL:OnMouseReleased( mousecode )
	DButton.OnMouseReleased( self, mousecode )
	if ( self.m_MenuClicking && mousecode == MOUSE_LEFT ) then
		self.m_MenuClicking = false
		CloseDermaMenus()
	end
end

function PANEL:DoRightClick()
	if ( self:GetIsCheckable() ) then
		self:ToggleCheck()
	end
end

function PANEL:DoClickInternal()
	if ( self:GetIsCheckable() ) then
		self:ToggleCheck()
	end

	if ( self.m_pMenu ) then
		self.m_pMenu:OptionSelectedInternal( self )
	end
end

function PANEL:ToggleCheck()
	self:SetChecked( not self:GetChecked() )
	self:OnChecked( self:GetChecked() )
end

function PANEL:OnChecked( b )
	
end

function PANEL:PerformLayout( w, h )
	self:SizeToContents()
	local adasize_30 = echat:AdaptiveSize(30)
	local adasize_15 = echat:AdaptiveSize(15)
	self:SetWide( self:GetWide() + adasize_30 )

	local w = math.max( self:GetParent():GetWide(), self:GetWide() )

	self:SetSize( w, adasize_30 )

	if ( IsValid( self.SubMenuArrow ) ) then

		self.SubMenuArrow:SetSize( adasize_15, adasize_15 )
		self.SubMenuArrow:CenterVertical()
		self.SubMenuArrow:AlignRight( 4 )

	end

	DButton.PerformLayout( self, w, h )
end

vgui.Register("echat.menu.option", PANEL, "DButton")