local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick

-----------
--# STR #--
-----------
local stype = esclib:RegisterSettingsType("str")
stype:Require("value")
stype:SoftRequire("MaximumCharCount")
stype:SoftRequire("MinimumCharCount")
stype:SoftRequire("HintTranslateKey")
stype:SoftRequire("Multiline")
function stype:Build( parent )
	local addon     = parent.addon
	local varid     = parent.var_uid
	local varc      = parent.var
	local callback  = parent.ApplyValue
	local init_vals = parent.initial_values
	local settab    = parent.bg
	local def_val   = parent.default_value

	local button_wide= parent:GetWide()
	local button_tall = parent:GetTall()

	local clr = esclib.addon:GetColors()
	local name_tr  = varc.name or addon:Translate(varc.name_tr)
	local desc = varc.desc or addon:Translate(varc.desc_tr)

	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 18, 500)
	
	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	button.DoRightClick = function(self) SharedDoRightClick(self, settab, name_tr, addon, varid, varc, def_val, callback) end
	if desc then
		button:eAddHint(desc,font2,TEXT_ALIGN_TOP,settab)
	end

	local wrench_mat = esclib:GetMaterial("wrench.png")
	local offset_x = esclib:AdaptiveSize(20)
	local target_offset_x = offset_x
	function button:Paint(w,h)
		local hovered = self:IsHovered()
		local is_changed = varc.value ~= init_vals[varid]
		draw_bg(w,h,hovered,clr,is_changed)

		if hovered then
			offset_x = Lerp(0.1, offset_x, h)
			esclib.draw:MaterialCentered(offset_x-h*0.5, h*0.5, h*0.25, clr.button.text, wrench_mat)
		else
			offset_x = Lerp(0.1, offset_x, target_offset_x)
		end

		local name = esclib.util:TextCut(name_tr, font, button_wide-offset_x-25, "...")
		local value_text = esclib.util:TextCut(varc.value, font2, button_wide-offset_x-25, "...")

		draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		draw.SimpleText(value_text,font2,offset_x,h*0.52,clr.button.accent,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
	end

	function button:DoClick()
		local hint = varc.HintTranslateKey and addon:Translate(varc.HintTranslateKey) or esclib.addon:Translate("window_ValueEdit", addon.info.language)
		local text_input = esclib:TextInputWindow(name_tr, hint, varc.Multiline, false, 
			function(result)
				varc.value = result
				callback(varid,varc.value)
			end,
			function(val)
				local slen = string.len(string.Trim(val) or "")
				local maxv = varc.MaximumCharCount or math.huge
				local minv = varc.MinimumCharCount or -math.huge

				if not ((slen >= minv) and (slen <= maxv)) then
					return string.format("%s <= #str <= %s", minv, maxv)
				end
				return not ((slen >= minv) and (slen <= maxv))
			end,
			addon.info.language
		)
		text_input:SetText(varc.value)
	end

end