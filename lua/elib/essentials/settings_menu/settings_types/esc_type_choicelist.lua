local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick


------------------
--# CHOICELIST #--
------------------
local stype = esclib:RegisterSettingsType("choicelist")
stype:Require("values")
stype:Require("value")
stype:Require("SelectableCount")
stype:SoftRequire("TranslateValues")
stype:SoftRequire("SearchEnabled")
function stype:Build( parent )
	local addon     = parent.addon
	local varid     = parent.var_uid
	local varc      = parent.var
	local callback  = parent.ApplyValue
	local init_vals = parent.initial_values
	local settab    = parent.bg
	local def_val   = parent.default_value

	local button_wide = parent:GetWide()
	local button_tall = parent:GetTall()

	local clr = esclib.addon:GetColors()
	local name_tr  = varc.name or addon:Translate(varc.name_tr)
	local desc = varc.desc or addon:Translate(varc.desc_tr)
	
	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 18, 500)
	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide-5, "...")

	local selected = istable(varc.value) and varc.value or {varc.value}
	varc.value = selected --convert to table or do nothing

	local button = parent:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	if desc then
		button:eAddHint(desc,font,TEXT_ALIGN_TOP,settab)
	end
	button.DoRightClick = function(self) SharedDoRightClick(self, settab, name, addon, varid, varc, def_val, callback) end
	

	function button:DoClick()

		local clr = esclib.addon:GetColors()

		if varc.SelectableCount == 1 then
			local mx, my = input.GetCursorPos()
			local context = settab:Add("esclib.contextmenu")
			context:SetPosClamped(mx+5,my+5)
			context:AddHeader(name)

			context:AddSeparator()

			local selected = {}
			for _,name in ipairs(varc.value) do
				selected[name] = true
			end

			for k,name in ipairs(varc.values) do
				local btn_name = name
				if varc.TranslateValues then
					btn_name = addon:Translate(btn_name)
				end

				local mat = nil
				if selected[name] then
					mat = esclib:GetMaterial("true.png")
				end

				local btn = context:AddButton(btn_name, function()
					varc.value = {name}
					callback()
				end, mat)

				btn.Color = clr.frame.bg

				if selected[name] then
					btn.TextColor = clr.button.accent
				end
			end
		else
			local value_paint = function(self,w,h,val,active)
				local hovered = self:IsHovered()
				if varc.TranslateValues then
					val = addon:Translate(val)
				end
				
				draw_bg(w,h,hovered,clr)
				if active then
					draw.RoundedBox(0,0,0,5,h,clr.button.accent)
				end
				
				draw.SimpleText(val,font,15,h*0.5,hovered and clr.button.text_hover or clr.button.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
			end

			local return_result = function(result)
				local val = result and (istable(result) and result or {result}) or {}
				if not table.IsEmpty(val) then
					varc.value = val
					callback(varid,varc.value)
				end
			end

			esclib:ChoiceMenu(name, varc.values, varc.SelectableCount, value_paint, return_result, nil, varc.SearchEnabled ~= false, varc.value[1], button_wide)
		end
	end

	local wrench_mat = esclib:GetMaterial("wrench.png")
	local offset_x = esclib:AdaptiveSize(20)
	local target_offset_x = offset_x
	function button:Paint(w,h)
		local hovered = self:IsHovered()

		local value = ""
		if istable(varc.value) then
			for _, v in pairs(varc.value) do
				if varc.TranslateValues then v = addon:Translate(v) end
				value = value .. v .. " "
			end
		else
			if varc.TranslateValues then 
				value = addon:Translate(varc.value)
			else
				value = varc.value
			end
		end
		local copied_name = ""
		if istable(init_vals[varid]) then
			for _, v in pairs(init_vals[varid]) do
				if varc.TranslateValues then v = addon:Translate(v) end
				copied_name = copied_name .. v .. " "
			end
		else
			if varc.TranslateValues then 
				copied_name = addon:Translate(init_vals[varid])
			else
				copied_name = init_vals[varid]
			end
		end

		local is_changed = value ~= copied_name
		draw_bg(w,h,hovered,clr,is_changed)

		if hovered then
			offset_x = Lerp(0.1, offset_x, h)
			esclib.draw:MaterialCentered(offset_x-h*0.5, h*0.5, h*0.25, clr.button.text, wrench_mat)
		else
			offset_x = Lerp(0.1, offset_x, target_offset_x)
		end

		draw.SimpleText(name,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		draw.SimpleText("["..value:TrimRight().."]",font2,offset_x,h*0.52,clr.button.accent,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		draw.SimpleText("p","Marlett",w-4,h-4,clr.button.text,TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
	end
end