local PANEL = {}

function PANEL:Init()

	self.parent = self:GetParent()
	local clr = esclib.addon:GetColors()
	self:SetMouseInputEnabled(true)

	local textentry = self:Add("DTextEntry")
	self.textentry = textentry
	textentry:SetWidth(60)
	textentry:Dock(RIGHT)
	textentry:SetNumeric(true)
	textentry:SetFont(esclib:AdaptiveFont("esclib", 16, 500))

	local slider = self:Add("esclib.slider")
	self.slider = slider
	slider:Dock(FILL)
	slider:DockMargin(0,0,5,0)

	slider.OnValueChanged = function(pnl,new)
		textentry:SetValue(new)
		self:OnValueChanged(new)
	end
	textentry:SetValue(slider:GetValue())

	function textentry:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,clr.button.hover)
		self:DrawTextEntryText(clr.button.text,clr.button.apply,clr.button.text_hover)
	end

	textentry.OnChange = function(pnl)
		local new = pnl:GetFloat() or 0
		slider:SetValue(new)

		self:OnValueChanged(slider:GetValue())
	end

	function textentry:OnGetFocus()
		local pnl = self:GetParent()
		if IsValid(pnl.parent) then
			pnl.parent:SetKeyBoardInputEnabled(true)
		end
	end

	function textentry:OnLoseFocus()
		timer.Simple(0, function()
			if not IsValid(textentry) then return end 
			textentry:SetValue(slider:GetValue())
		end)
		local pnl = self:GetParent()
		if IsValid(pnl.parent) then
			pnl.parent:SetKeyBoardInputEnabled(false)
		end
	end

	self:InvalidateParent(true)

end

function PANEL:SetBG(panel)
	if ispanel(panel) then
		self.parent = panel
	end
end

function PANEL:SetValue(num)
	self.slider:SetValue(num)
	self.textentry:SetValue(num)
end

function PANEL:GetValue()
	return self.slider:GetValue()
end

--# SET GET #--
function PANEL:SetMin(num)
	self.slider:SetMin(num)
end

function PANEL:GetMin()
	return self.slider:GetMin()
end

function PANEL:SetMax(num)
	self.slider:SetMax(num)
end

function PANEL:GetMax()
	return self.slider:GetMin()
end

function PANEL:SetDecimals(num)
	self.slider:SetDecimals(num)
end

function PANEL:SetStep(num)
	self.slider:SetScrollStep(num)
end



function PANEL:OnValueChanged(new)
	--override me pls
end

function PANEL:OnSizeChanged( w,h )
	self:InvalidateParent(true)
end


derma.DefineControl("esclib.numslider", "ESClib numslider", PANEL, "EditablePanel")