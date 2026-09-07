local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick

------------
--# BOOL #--
------------
local stype = esclib:RegisterSettingsType("bool")
stype:Require("value")
function stype:Build( parent ) --not used on serverside
	local addon     = parent.addon
	local varid     = parent.var_uid
	local varc      = parent.var
	local callback  = parent.ApplyValue
	local vars_copy = parent.initial_values
	local settab    = parent.bg
	local def_val   = parent.default_value

	--other: button_wide / button_tall / current_vars_copy
	local button_wide = parent:GetWide()
	local button_tall = parent:GetTall()

	local clr = esclib.addon:GetColors()

	local name_tr  = varc.name or addon:Translate(varc.name_tr)
	local desc = varc.desc or addon:Translate(varc.desc_tr)
	if (varc.change_type == "usergroup") or (varc.change_type == "steamid") then
		if varc.who_can_change and istable(varc.who_can_change) then
			if not desc then desc = "" end
			desc = desc.." "..esclib.addon:Translate("phrase_WhoCanChange")..": [ "
			for k,v in pairs(varc.who_can_change) do
				desc = desc..tostring(k).." "
			end
			desc = desc.." ]"
		end
	end

	if (varc.change_type == "boolean") then
		if not varc.who_can_change then
			if not desc then desc = "" end
			desc = desc.." "..esclib.addon:Translate("phrase_WhoCanChange")..": [ "..esclib.addon:Translate("phrase_NoOne").." ]"
		end
	end

	local offset_x = esclib:AdaptiveSize(20)
	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 16, 500)
	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide*0.8, "...")
	local desc_text = esclib.util:TextCutAccurate(desc or "", font2, button_wide*0.8, "...")

	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	button.DoRightClick = function(self) SharedDoRightClick(self, settab, name_tr, addon, varid, varc, def_val, callback) end
	if desc then
		button:eAddHint(desc,esclib:AdaptiveFont("esclib", 20, 500),TEXT_ALIGN_TOP,settab)
	end

	function button:DoClick()
		varc.value = not varc.value
		callback(varid,varc.value)
	end

	local box_mat = esclib:GetMaterial("box.png")
	local true_mat = esclib:GetMaterial("true.png")
	function button:Paint(w,h)
		local hovered = self:IsHovered()
		local is_changed = varc.value ~= vars_copy[varid]

		draw_bg(w,h,hovered,clr,is_changed)

		if desc then
			draw.SimpleText(name,font,offset_x,h*0.2,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			draw.SimpleText(desc_text,font2,offset_x,h*0.82,clr.button.text_gray,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		else
			draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		end

		local checkbox_size = h*0.25
		esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size,  hovered and clr.button.main or clr.button.hover , box_mat)
		if varc.value then
			esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size*0.6, hovered and clr.button.accent_hover or clr.button.accent, true_mat)
		end
	end
end