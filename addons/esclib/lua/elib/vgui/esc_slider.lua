local PANEL = {}

AccessorFunc(PANEL, "iDecimals", "Decimals", FORCE_NUMBER)
AccessorFunc(PANEL, "iScrollStep", "ScrollStep", FORCE_NUMBER)

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetCursor("hand")

	local clr = esclib.addon:GetColors()
	self.clr = clr
	self.min = 0
	self.max = 1
	self.iDecimals = 2
	self.iScrollStep = 1
	self.fraction = 0

	self.Font = esclib:AdaptiveFont("esclib", 10, 500)

	local knob = self.Knob
	knob:SetHeight(self:GetTall())
	function knob:Paint(w,h) end

	self.OnCursorMoved = function( panel, x, y )
		if ( not self.Dragging and not self.Knob.Depressed ) then return end

		local oldx, oldy = x,y

		local w, h = self:GetSize()
		local iw, ih = self.Knob:GetSize()

		if ( self.m_bTrappedInside ) then

			w = w - iw
			h = h - ih

			x = x - iw * 0.5
			y = y - ih * 0.5

		end

		x = math.Clamp( x, 0, w ) / w
		y = math.Clamp( y, 0, h ) / h

		if ( self.m_iLockX ) then x = self.m_iLockX end
		if ( self.m_iLockY ) then y = self.m_iLockY end

		x, y = self:TranslateValues( x, y )

		self:SetSlideX( x )
		self:SetSlideY( y )

		if (oldx ~= x) or (oldy ~= y) then
			panel:OnValueChanged(panel:GetValue())
		end
	end
end

--Value manipulation
function PANEL:SetMin(num)
	self.min = math.Clamp(num or 0, -math.huge, self.max)
end

function PANEL:GetMin()
	return self.min
end

function PANEL:SetMax(num)
	self.max = math.Clamp(num or 0, self.min, math.huge)
end

function PANEL:GetMax()
	return self.max
end

function PANEL:SetValue(num)
	self:SetSlideX( math.Clamp( (num - self.min) / (self.max - self.min), 0, 1) )
end

function PANEL:GetValue()
	local val = self:GetSlideX() * (self.max - self.min) + self.min
	return val - val%(1 / math.pow(10, self.iDecimals))
end

function PANEL:OnValueChanged(x)
	-- rewrite me pls
end



function PANEL:Paint(w,h)
	local hovered = self:IsHovered() or self.Knob:IsHovered()
	local editing = self:IsEditing()


	local offy = h*0.2
	draw.RoundedBox(4,0,0,w,h,self.clr.button.hover)

	if hovered then
		local mx, my = input.GetCursorPos()
		mx, my = self:ScreenToLocal(mx,my)

		draw.RoundedBox(0,0,offy,mx,h-offy*2, self.clr.button.main)
	end

	self.fraction = Lerp(0.2, self.fraction, self:GetSlideX())
	draw.RoundedBox(8,0,offy,w*self.fraction,h-offy*2, (hovered or editingww) and self.clr.button.accent_hover or self.clr.button.accent)

	local val = self:GetValue() or 0
	local textw,texth = esclib.util:TextSize(val, self.Font)

	if editing then
		local x = w*self.fraction
		if ((x + textw + 10) > w) then
			draw.RoundedBox(0,x-15-textw,0, textw+10, h, self.clr.frame.bg)
			esclib.draw:ShadowText(val, self.Font, x-10, h*0.5, self.clr.button.text,  TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER,1)
		else
			draw.RoundedBox(0,x+5,0, textw+10, h, self.clr.frame.bg)
			esclib.draw:ShadowText(val, self.Font, x+10, h*0.5, self.clr.button.text,  TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,1)
		end
	end
end

function PANEL:OnMouseWheeled( delta )
	self:SetSlideX(math.Clamp(self:GetSlideX()+(delta*self.iScrollStep / (self.max-self.min)),0,1))
	self:OnValueChanged(self:GetValue())
end

function PANEL:OnSizeChanged(w,h)
	self.Knob:SetHeight(h)
end

derma.DefineControl("esclib.slider", "just a slider", PANEL, "DSlider")