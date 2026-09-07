local function Capitalize(str)
	return (str:gsub("^%l", string.upper))
end

-----------------
--# VARS META #--
-----------------
local VarsMeta = {}
VarsMeta.__index = VarsMeta
function VarsMeta:Set(param, value)
	if param == nil or value == nil then return end
	self[param] = value
	return self
end

function VarsMeta:SetName(value)
	self:Set("name", value)
	return self
end

function VarsMeta:SetDesc(value)
	self:Set("desc", value)
	return self
end

function VarsMeta:SetNameTranslateKey(value)
	self:Set("name_tr", value)
	return self
end

function VarsMeta:SetDescTranslateKey(value)
	self:Set("desc_tr", value)
	return self
end

function VarsMeta:SetPosition(value)
	self:Set("sortOrder", value)
	return self
end

function VarsMeta:SetShared(value)
	if CLIENT then return self end --do nothing on client
	self:Set("shared", value)
	return self
end

--Do nothing, just for support
function VarsMeta:RestartAddon(value)
	self:Set("restart_addon", value)
	return self
end

function VarsMeta:CustomCheck(fun)
	self:Set("customCheck", fun)
	return self
end

function VarsMeta:CanChange(change_type, change_who)
	local fun

	if type(change_type) == "boolean" then
		fun = function() return change_type or esclib:HasAdminAccess(LocalPlayer()) end
		self:Set("change_type",'boolean')
		self:Set("who_can_change",change_type)
	elseif (change_type == "steamid") then
		if type(change_who) ~= "table" then change_who = {change_who} end
		fun = function()
			return change_who[LocalPlayer():SteamID()] or esclib:HasAdminAccess(LocalPlayer())
		end
		self:Set("change_type",'steamid')
		self:Set("who_can_change",change_who)
	elseif (change_type == "usergroup") then
		if type(change_who) ~= "table" then change_who = {change_who} end
		fun = function()
			return change_who[LocalPlayer():GetUserGroup()] or esclib:HasAdminAccess(LocalPlayer())
		end
		self:Set("change_type",'usergroup')
		self:Set("who_can_change",change_who)
	end

	self:Set("customCheck", fun)
	return self
end

esclib.VARS_META = VarsMeta

-----------------
--# TABS META #--
-----------------
local TabMeta = {}
TabMeta["__index"] = TabMeta
function TabMeta:Set(param, value)
	if param == nil or value == nil then return end
	self[param] = value
	return self
end

function TabMeta:SetName(value)
	self:Set("name", value)
	return self
end

function TabMeta:SetNameTranslateKey(value)
	self:Set("name_tr", value)
	return self
end

function TabMeta:SetPosition(value)
	self:Set("sortOrder", value)
	return self
end

function TabMeta:AddVar(var_uid, vtype)

	if self["vars"][var_uid] then
		print("[ESCLIB] [ERROR HELPER] This name is already exists, please take another one. Busy names:\n")
		for k,v in ipairs(table.GetKeys(vars)) do
			print(k,v)
		end
		print("\nStack trace: ")
		error("Not valid var name ("..tostring(var_uid)..")")
	end

	local stype = esclib.allowed_settings_types[vtype]
	if not stype then
		print("[ESCLIB] [ERROR HELPER] Valid types are:\n")
		for k,v in pairs(table.GetKeys(esclib.allowed_settings_types)) do
			print(k,v)
		end
		print("\nStack trace: ")
		error("Not valid var type ("..tostring(vtype)..")")
	end

	setmetatable(stype, VarsMeta)

	-- esclib:SafeMerge(stype, VarsMeta, true)

	self["vars"][var_uid] = {}
	self["vars"][var_uid]["type"] = vtype

	stype["__index"] = stype
	setmetatable(self["vars"][var_uid], stype)

	return self["vars"][var_uid]
end

function TabMeta:CustomCheck(fun)
	self:Set("customCheck", fun)
	return self
end

esclib.TAB_META = TabMeta


---------------------
--# SETTINGS META #--
---------------------
local settings_meta = {}
settings_meta["__index"] = settings_meta
function settings_meta:AddTab(uid)
	local uid = string.lower(uid)

	if self[uid] then
		print("[ESCLIB] [ERROR HELPER] This name is already exists, please take another one. Busy names:\n")
		for k,v in ipairs(table.GetKeys(self)) do
			print(k,v)
		end
		print("\nStack trace: ")
		error("Not valid tab name ("..tostring(uid)..")")
	end

	self[uid] = {
		["vars"] = {},
		["__realm"] = self.__realm
	}
	setmetatable(self[uid], TabMeta)

	return self[uid]
end

function settings_meta:Print()
	PrintTable(self)
end

function settings_meta:End()
	local add_name = self.__addon
	local addon = esclib:GetAddon(add_name)
	if not addon then return end
	local realm = self.__realm

	--check all
	for tab,tab_val in pairs(self) do
		local vars = tab_val["vars"]
		for varid,varc in pairs(vars) do
			for id,need in ipairs(esclib.allowed_settings_types[varc.type]["important_vars"]) do
				if varc[need] == nil then
					print("[ESCLIB] [ERROR HELPER] No important keys for "..varid.."! Needed keys:\n")
					for k,v in ipairs(esclib.allowed_settings_types[varc.type]["important_vars"]) do
						print(k,v)
					end
					print("\nStack trace: ")
					error(varid.." - not contains key ["..tostring(need).."]")
				end
			end
		end
	end

	if realm == "client" and CLIENT then --ONLY on client
		-- Init settings and load from file
		addon:RegisterSettings(self)
	elseif realm == "server" then --can be both
		addon:RegisterServerSettings(self)
	end
	
	if (CLIENT) then
		hook.Add("InitPostEntity",add_name.."_request_settings",function()
			addon:RequestSettings()
			hook.Remove("InitPostEntity",add_name.."_request_settings")
		end)
	end
end

---------------
--# WRAPPER #--
---------------
local all_realms = {
	["client"] = true,
	["server"] = true
}
function esclib:InitSettings(addon_uid, realm)
	realm = realm or "client"
	if not all_realms[realm] then
		print("[ESCLIB] [ERROR HELPER] invalid addon realm (Must be client or server)\n")
		error("Invalid addon realm ("..tostring(addon_uid)..")")
	end
	
	local addons = esclib:GetAddons()
	if not addons[addon_uid] then
		print("[ESCLIB] [ERROR HELPER] Addon uid not found. Available addons:\n")
		for k,v in ipairs(table.GetKeys(addons)) do
			print(k,v)
		end
		print("\nStack trace: ")
		error("Not valid addon uid ("..tostring(addon_uid)..")")
	end

	local addon_settings_meta = {}
	settings_meta["__addon"] = addon_uid
	settings_meta["__realm"] = realm

	setmetatable(addon_settings_meta,settings_meta)

	return addon_settings_meta
end