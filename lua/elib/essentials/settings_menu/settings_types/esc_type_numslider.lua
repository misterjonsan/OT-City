local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick


-----------------
--# NUMSLIDER #--
-----------------
local stype = esclib:RegisterSettingsType("numslider")
stype:Require("value")
stype:Require("min")
stype:Require("max")
stype:SoftRequire("decimals")
stype:SoftRequire("step")
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
	local font2 = esclib:AdaptiveFont("esclib", 22, 500)
	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide-5, "...")
	local offset_x = esclib:AdaptiveSize(20)

	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	button:SetCursor("arrow")
	button.DoClick = function() end
	if desc then
		button:eAddHint(desc,font2,TEXT_ALIGN_TOP,settab)
	end

	local slider = button:Add("esclib.numslider")
	slider:SetSize(button:GetWide()-offset_x*2,button:GetTall()*0.3)
	slider:CenterHorizontal()
	slider:SetY(button:GetTall()*0.5+slider:GetTall()*0.25)
	slider:SetBG(settab)

	slider:SetMin(varc.min or 0)
	slider:SetMax(varc.max or 1)
	slider:SetValue(varc.value)
	slider:SetDecimals(varc.decimals or 0)
	slider:SetStep(varc.step or 1)

	button.DoRightClick = function(self) 
		local context = SharedDoRightClick(self, settab, name_tr, addon, varid, varc, nil, callback)

		local set_default = esclib.addon:Translate("phrase_ReturnDefault", addon:GetLanguage())
		context:AddButton(set_default, function()
			slider:SetValue(def_val)
			varc.value = def_val
		end, esclib:GetMaterial("revert.png"))
	end

	function slider:DoRightClick()
		button:DoRightClick()
	end

	function button:Paint(w,h)
		local is_changed = varc.value ~= init_vals[varid]
		draw_bg(w,h,false,clr, is_changed)

		draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
	end


	slider.OnValueChanged = function(self,x)
		varc.value = x
		callback(varid,varc.value)
	end
end