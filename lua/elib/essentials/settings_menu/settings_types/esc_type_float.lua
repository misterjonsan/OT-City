local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick

-------------
--# FLOAT #--
-------------
local stype = esclib:RegisterSettingsType("float")
stype:Require("value")
stype:SoftRequire("min")
stype:SoftRequire("max")
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

	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 16, 500)
	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide*0.8, "...")
	-- local desc_text = esclib.util:TextCutAccurate(desc or "", font2, button_wide*0.8, "...")

	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	if desc then
		local added = ""
		if varc.max or varc.min then
			added = "("..(varc.min or "∞").." - "..(varc.max or "∞")..")\n"
		end
		button:eAddHint(added.." "..desc,font,TEXT_ALIGN_CENTER,settab)
	end

	function button:DoClick()
		local text_input = esclib:TextInputWindow(esclib.addon:Translate("window_ValueEdit"), (addon:Translate(varc.name_tr) or varc.name).." ("..varc.value..")",false,true,function(res)
			if not res then return end
			if res == 0 then return end
			if varc.max and varc.min then
				res = math.Clamp(res, varc.min, varc.max)
			elseif varc.max then
				res = math.Clamp(res, -math.huge, varc.max)
			elseif varc.min then
				res = math.Clamp(res, varc.min, math.huge)
			end
				
			varc.value = res
			callback(varid,varc.value)
		end)
		text_input:SetValue(varc.value)
	end

	button.DoRightClick = function(self) SharedDoRightClick(self, settab, name_tr, addon, varid, varc, def_val, callback) end

	local wrench_mat = esclib:GetMaterial("wrench.png")
	local target_offset_x = esclib:AdaptiveSize(20)
	local offset_x = 0
	function button:Paint(w,h)
		local hovered = self:IsHovered()
		local is_changed = varc.value ~= varc_copy[varid]
		draw_bg(w,h,hovered,clr, is_changed)

		if hovered then
			offset_x = Lerp(0.1, offset_x, h)
			esclib.draw:MaterialCentered(offset_x-h*0.5, h*0.5, h*0.25, clr.button.text, wrench_mat)
		else
			offset_x = Lerp(0.1, offset_x, target_offset_x)
		end

		if desc then
			draw.SimpleText(name,font,offset_x,h*0.2,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			local desc_text = esclib.util:TextCut(desc or "", font2, w*0.8-offset_x, "...")
			draw.SimpleText(desc_text,font2,offset_x,h*0.85,clr.button.text_gray,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		else
			draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		end
		draw.SimpleText(varc.value,font,w-target_offset_x,h*0.5,clr.button.accent,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER,1)
	end
end