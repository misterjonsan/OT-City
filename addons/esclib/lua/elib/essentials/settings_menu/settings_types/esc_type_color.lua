local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick

-------------
--# CLR #--
-------------
local matGrid = Material( "gui/alpha_grid.png", "nocull" )

local stype = esclib:RegisterSettingsType("clr")
stype:Require("value")
function stype:Build( parent )
	local addon     = parent.addon
	local varid     = parent.var_uid
	local varc      = parent.var
	local callback  = parent.ApplyValue
	local varc_copy = parent.initial_values
	local settab    = parent.bg
	local def_val   = parent.default_value

	local button_wide = parent:GetWide()
	local button_tall = parent:GetTall()

	local clr = esclib.addon:GetColors()
	local name_tr  = varc.name or addon:Translate(varc.name_tr)
	local desc = varc.desc or addon:Translate(varc.desc_tr)
	local offset_x = esclib:AdaptiveSize(20)
	local target_offset_x = offset_x

	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 22, 500)
	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide-15-90, "...")

	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	button.DoRightClick = function(self) SharedDoRightClick(self, settab, name_tr, addon, varid, varc, def_val, callback) end
	if desc then
		local added = ""
		if varc.max or varc.min then
			added = "("..(varc.min or "∞").." - "..(varc.max or "∞")..")\n"
		end
		button:eAddHint(added.." "..desc,font2,TEXT_ALIGN_CENTER,settab)
	end

	local quad_size = button:GetTall()*0.6
	local inv_size  = (button:GetTall()-quad_size)*0.5

	local clr_pnl = button:Add("DPanel")
	clr_pnl:SetSize(quad_size, quad_size)
	clr_pnl:SetPos(button:GetWide() - clr_pnl:GetWide() - offset_x, button:GetTall()*0.5 - clr_pnl:GetTall()*0.5)
	clr_pnl:SetMouseInputEnabled(false)
	function clr_pnl:Paint(w,h)
		esclib.draw:Material(0,0,w,h,color_white,matGrid)

		draw.RoundedBox(0, 0,0,w,h, varc.value)
	end
	
	local wrench_mat = esclib:GetMaterial("wrench.png")
	function button:Paint(w,h)
		local hovered = self:IsHovered()
		local is_changed = not esclib.util:IsValuesEqual(varc.value, varc_copy[varid])
		draw_bg(w,h,hovered,clr,is_changed)

		if hovered then
			offset_x = Lerp(0.1, offset_x, h)
			esclib.draw:MaterialCentered(offset_x-h*0.5, h*0.5, h*0.25, clr.button.text, wrench_mat)
		else
			offset_x = Lerp(0.1, offset_x, target_offset_x)
		end

		draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	end

	function button:DoClick()
		local bg = esclib:GenerateBGClicker(true)
		-- bg.Paint = nil

		local mx, my = input.GetCursorPos()

		local pnl = bg:Add("DPanel")
		pnl:SetSize(self:GetWide(), bg:GetTall()*0.2)
		local x, y = self:LocalToScreen(self:GetWide()*0.5, self:GetTall())
		pnl:SetPos(x - pnl:GetWide()*0.5, y + 5)
		function pnl:Paint(w,h)
			draw.RoundedBox(8,0,0,w,h,clr.frame.bg)
		end

		local colorpicker = pnl:Add("esclib.colorpicker")
		colorpicker:Dock(FILL)
		colorpicker:DockMargin(15,15,15,15)
		colorpicker:SetColor(varc.value)

		function colorpicker:ValueChanged(new_col)
			varc.value = Color(new_col.r, new_col.g, new_col.b, new_col.a)
		end

		function bg:OnClose()
			callback()
		end
	end
end