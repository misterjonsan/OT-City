local gsub = string.gsub

esclib.allowed_settings_types = esclib.allowed_settings_types or {}
esclib.settings_shared_funcs = esclib.settings_shared_funcs or {}

local function Capitalize(str)
	return (gsub(str, "^%l", string.upper))
end


local TYPE_META = {}
-- TYPE_META["__index"] = TYPE_META

function TYPE_META:Require(var, is_soft)

	if isfunction(is_soft) then
		self[var] = function(var_meta, ...)
			esclib:SafeMerge(self, var_meta, true)
			var_meta[var] = is_soft(self, ...)
			return var_meta
		end
	else
		local var_name = tostring(var)
		local func_name = string.format("Set%s",Capitalize(var_name))
		self[func_name] = function(var_meta, var)
			var_meta[var_name] = var
			return var_meta
		end

		if is_soft then
			table.insert(self["secondary_vars"], var_name)
		else
			table.insert(self["important_vars"], var_name)
		end
	end
end

function TYPE_META:SoftRequire(var)
	self:Require(var, true)
end

function esclib:RegisterSettingsType(name)
	local new_type = {}
	new_type["important_vars"] = {}
	new_type["secondary_vars"] = {}

	esclib:SafeMerge(new_type, TYPE_META, true)

	self.allowed_settings_types[name] = new_type
	return new_type
end

------------------------
--# SHARED FUNCTIONS #--
------------------------
local function tablesAreEqual(table1, table2)
	for k, v in pairs(table1) do
		if type(v) ~= type(table2[k]) then return false end
		if istable(v) and istable(table2[k]) then
			if not tablesAreEqual(v, table2[k]) then
				return false
			end
		elseif table2[k] ~= v then
			return false
		end
	end

	for k, _ in pairs(table2) do
		if table1[k] == nil then
			return false
		end
	end

	return true
end

function esclib.settings_shared_funcs.VarsIsEqual(var1, var2)
	if type(var1) ~= type(var2) then return false end
	if istable(var1) and istable(var2) then return tablesAreEqual(var1, var2) end
	return var1 == var2
end
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual

function esclib.settings_shared_funcs.SharedDoRightClick(self, settab, name, addon, varid, varc, def_val, callback)
	local clr = esclib.addon:GetColors()
	local context = settab:Add("esclib.contextmenu")
	local mx, my = input.GetCursorPos()
	context:SetPosClamped(mx+5,my+5)
	context:AddHeader(name)

	context:AddSeparator()

	local edit_text = esclib.addon:Translate("button_Edit", addon:GetLanguage())
	context:AddButton(edit_text, function()
		self:DoClick()
	end, esclib:GetMaterial("wrench.png"))

	if def_val ~= nil then
		local set_default = esclib.addon:Translate("phrase_ReturnDefault", addon:GetLanguage())
		local vars_equal = VarsIsEqual(def_val, varc.value)

		local btn = context:AddButton(set_default, function()
			if istable(def_val) then
				varc.value = table.Copy(def_val)
			else
				varc.value = def_val
			end
			callback(varid,varc.value)
		end, esclib:GetMaterial("revert.png"))

		if vars_equal then
			btn:SetMouseInputEnabled(false)
			btn:SetTextColor(clr.button.text_gray)
		end
	end

	context:SetZPos(10)
	return context
end

function esclib.settings_shared_funcs.draw_bg(w,h,hovered,clr, is_changed)
	if is_changed then
		draw.RoundedBox(8,0,0,w,h, clr.button.discard)
		draw.RoundedBox(6,2,2,w-4,h-4,hovered and clr.button.hover or clr.button.main)
	else
		draw.RoundedBox(8,0,0,w,h,clr.button.hover)
		draw.RoundedBox(6,2,2,w-4,h-4,hovered and clr.button.hover or clr.button.main)
	end
end