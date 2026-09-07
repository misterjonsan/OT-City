local esclib = esclib

--LUA REFRESH
if not table.IsEmpty(esclib.addons or {}) then 
	esclib.loader:LoadAllAddons() 
end


function esclib:SafeMerge(table1, table2, forceOverride)
    local visited = {}

    local function mergeRecursive(t1, t2, visited)
        if visited[t1] or visited[t2] then
            error("Cycle detected during merge")
        end

        visited[t1] = true
        visited[t2] = true

        for key, value in pairs(t2) do
            if type(value) == "table" then
                if not t1[key] then
                    t1[key] = {}
                end
                mergeRecursive(t1[key], value, visited)
            else
                t1[key] = value
            end
        end
    end

    return mergeRecursive(table1, table2, visited)
end

esclib.addons = esclib.addons or {}

------------------------
--# SHARED FUNCTIONS #--
------------------------
--Just for ability to change usergroup function
function esclib:GetUserGroup(ply)
	return ply:GetUserGroup()
end

function esclib:GetAddons()
	return self.addons
end

function esclib:GetAddon(uid)
	return self.addons[uid]
end

function esclib:HasAddon(uid)
	return self.addons[uid] ~= nil
end

function esclib:IsTTT()
	return engine.ActiveGamemode() == 'terrortown'
end

function esclib:NetWriteCompressedTable(to_send, bits)
	local bits = bits or 16
	local c_json = util.Compress( util.TableToJSON(to_send) )
	local jsbytes = #c_json
	net.WriteUInt( jsbytes, bits )
	net.WriteData( c_json, jsbytes )
end

function esclib:NetReadCompressedTable(bits,pretty)
	local bits = bits or 16
	local bytes = net.ReadUInt(bits)
	local c_json = net.ReadData(bytes)
	c_json = util.Decompress(c_json) or "{}"
	c_json = util.JSONToTable(c_json, pretty)
	return c_json
end

function esclib:GetServerHash()
	if SERVER then return "" end
	return GetGlobalString("esclib.serveruid", "")
end


-----------------
--# SKIN BASE #--
-----------------
local skin_base = {}
skin_base["default"] = {}
skin_base["default"].roundsize = 8
skin_base["default"].colors = {}
skin_base["default"].colors.default = {
	red = Color(252, 29, 59),
	green = Color(30, 215, 96),
	blue = Color(30,33,250),
	white = Color(255,255,255),
	black = Color(13,13,13),
	orange = Color(255, 117, 23),
	shadow = Color(0,0,0,255),
}

------------------
--# ADDON META #--
------------------
local ADDON_META = {}
ADDON_META.__index = ADDON_META

function ADDON_META:GetName()
    return self.info.name
end

function ADDON_META:GetDescription()
    return self.info.description
end

function ADDON_META:GetSortOrder()
    return self.info.sort_order
end

function ADDON_META:GetColor()
    return self.info.color
end

function ADDON_META:GetVar(varid)
    return self.data.shared_vars[varid] or self.data.vars[varid]
end

function ADDON_META:SetVar(varid, value)
    self.data.vars[varid] = value
    self:SyncVars(-1) -- vars -> settings
    self:SaveSettings()
    return true
end

function ADDON_META:GetBranch()
    return self.info.branch
end

function ADDON_META:GetVersion()
    return self.info.version
end

function ADDON_META:GetWrappedVar(tab, var) -- just safe function
    if not self.data.settings[tab] then return end
    return self.data.settings[tab][var]
end

function ADDON_META:SetName(newname)
    self.info.name = newname
end

function ADDON_META:SetBranch(branch)
    self.info.branch = branch
end

function ADDON_META:SetVersion(newversion)
    self.info.version = newversion
end

function ADDON_META:SetDescription(newdesc)
    self.info.description = newdesc
end

function ADDON_META:SetSortOrder(order)
    self.info.sort_order = order
end

function ADDON_META:SetColor(newclr)
    if not IsColor(newclr) then return end
    self.info.color = newclr
end
local function formatMessage(self, ...)
	local t_clr = color_white
	return {t_clr, "[", self:GetColor(), self:GetName(), t_clr, "]: ", ...}
end

function ADDON_META:Print(...)
	local msg = formatMessage(self, ...)
	MsgC(unpack(msg))
	MsgC("\n")
end

function ADDON_META:ChatPrint(recievers, ...)
    local args = {...}
    
    if CLIENT and recievers then
        table.insert(args, 1, recievers)
    end

    local msg = formatMessage(self, unpack(args))
    
    if CLIENT then
        chat.AddText(unpack(msg))
    else
        if not istable(recievers) then
            recievers = {recievers}
        end

        for _, receiver in ipairs(recievers) do
            if IsValid(receiver) and receiver:IsPlayer() then
                receiver:EsclibChatPrint(unpack(msg))
            end
        end
    end
end

function ADDON_META:GetFilePath()
    return self.prefix..self.info.uid..self["sv_hash"]
end

-------------------
--# CLIENT META #--
-------------------
if (CLIENT) then
	ADDON_META.SetThumbnail = function(self, newmat)
		if type(newclr or "") == "IMaterial" then return end
		self.info.thumbnail = newmat
	end
	ADDON_META.GetThumbnail = function(self) return self.info.thumbnail end

	ADDON_META.RegisterSkin = function(self, skin_name, skin_data)
		if not isstring(skin_name) then error("Invalid Skin Name (Name must be a string) - "..tostring(skin_name)) end
		if not istable(skin_data) then error("Invalid Skin Data (Must be a table) - "..tostring(skin_name)) end
		local skin_name = string.lower(skin_name)
		
		local skin_data = table.Copy(skin_data or {})
		local base_skin = table.Copy(skin_base["default"])

		skin_data["roundsize"] = base_skin.roundsize or 8
		for clr_name, clr in pairs(base_skin["colors"] or {}) do
			skin_data["colors"][clr_name] = clr
		end

		--if exist
		if self.data.skins[skin_name] then
			self.data.skins[skin_name] = skin_data
			hook.Run(self.info.uid.."_skin_changed",skin_name)
			return
		end

		self.data.skins[skin_name] = skin_data
	end
	ADDON_META.SetSkin = function(self, skin_name)
		if not skin_name then return false end
		if not isstring(skin_name) then tostring(skin_name) end
		local skin_name = string.lower(skin_name)

		if self.data.skins[skin_name] then
			self.info.active_skin = skin_name

			hook.Run(self.info.uid.."_skin_changed",skin_name)

			return true
		else
			return false
		end
	end
	ADDON_META.SetDefaultSkin = function(self,skin_name)
		if not skin_name then return false end
		if not isstring(skin_name) then tostring(skin_name) end
		if self.data.skins[skin_name] then
			self.info.default_skin = skin_name
			if not self.info.active_skin then 
				self.info.active_skin = self.info.default_skin 
				self:LoadCustomSkin()
				self:LoadCurrentSkin()
			end
		end
	end
	ADDON_META.GetSkinByName = function(self,skin_name)
		if not skin_name then return false end
		if not isstring(skin_name) then tostring(skin_name) end 
		return self.data.skins[skin_name]
	end
	ADDON_META.GetCurrentSkin = function(self)
		return self.data.skins[self.info.active_skin]
	end
	ADDON_META.GetColors = function(self)
		return self:GetCurrentSkin()["colors"]
	end

	ADDON_META.SaveCurrentSkin = function(self)
		local dir_path = self:GetFilePath()
		local file_name = dir_path.."/"..self.other_settings_filename
		esclib.file:SaveVar(file_name,{["skin"] = self.info.active_skin})
		end

	ADDON_META.LoadCurrentSkin = function(self)
		local dir_path = self:GetFilePath()
		local file_name = dir_path.."/"..self.other_settings_filename
		local skin = esclib.file:ReadVar(file_name,"skin")
		if skin then
			self:SetSkin(skin)
		end
	end

	function ADDON_META:SaveCustomSkin()
		local dir_path = self:GetFilePath()
		local file_name = dir_path.."/"..self.custom_skin_filename
		local custom_skin = self:GetSkinByName("skin_custom")

		if custom_skin then
			esclib.file:SaveVar(file_name,{["skin"] = self:GetSkinByName("skin_custom")})
		else
			custom_skin = table.Copy(self.data.skins[self.info.default_skin])

			esclib.file:SaveVar(file_name,{["skin"] = custom_skin})
			self.data.skins["skin_custom"] = custom_skin
		end
	end

	function ADDON_META:ReturnCustomSkinToDefault()
		local dir_path = self:GetFilePath()
		local file_name = dir_path.."/"..self.custom_skin_filename

		file.Delete(file_name)
		local custom_skin = table.Copy(self.data.skins[self.info.default_skin])

		-- esclib.file:SaveVar(file_name,{["skin"] = custom_skin})
		self.data.skins["skin_custom"] = custom_skin
		self:SetSkin("skin_custom")
	end

	function ADDON_META:LoadCustomSkin()
		local dir_path = self:GetFilePath()
		local file_name = dir_path.."/"..self.custom_skin_filename
		local custom_skin = esclib.file:ReadVar(file_name,"skin")
		if custom_skin then
			self.data.skins["skin_custom"] = self.data.skins["skin_custom"] or {}
			esclib:SafeMerge(self.data.skins["skin_custom"],custom_skin, true)
		else
			custom_skin = table.Copy(self.data.skins[self.info.default_skin])
			self.data.skins["skin_custom"] = custom_skin
		end
	end

	function ADDON_META:DownloadMaterial(url, on_succ, on_err, retry_count, additional_path)
		if not url then error("URL is empty") end
		local path = self.info.uid
		if additional_path then
			path = path .. "/" .. additional_path
		end
		local filename = util.SHA1(url)..".png"
		esclib:DownloadMaterial(url, path, filename, on_succ, on_err, retry_count)
	end

	function ADDON_META:ClearDownloadCache(additional_path)
		local path = self.info.uid
		if additional_path then
			path = path .. "/" .. additional_path
		end
		esclib:ClearDownloadCache(path)
	end

	local function recurse_print_skin(add,tbl)
		if not tbl then 
			tbl = add
			add = ""
		end
		local add = add or ""
		for k,v in pairs(tbl) do
			if istable(v) then
				if ((v["r"]) and (v["g"]) and (v["b"]) and (v["a"])) then --iscolor dont work with tables
					MsgC((string.len(add) < 1) and "skin." or "" )
					MsgC(add..''..k..' = ')
					MsgC(Color(v.r,v.g,v.b,v.a), string.format('Color(%d, %d, %d', v.r,v.g,v.b)..(v.a ~= 255 and (","..v.a) or '')..")" )
					MsgC((string.len(add) < 1) and "" or ",")
				else
					MsgC(add..'["'..k..'"] = {\n')
					recurse_print_skin("\t"..add,v)
					MsgC(add.."}"..((string.len(add) < 1) and "" or "," ))
				end
			else
				MsgC("skin.")
				if type(v) == "string" then
					MsgC(add..''..k..' = "'..v..'"')
				else
					MsgC(add..''..k..' = '..tostring(v).."")
				end
				MsgC((string.len(add) < 1) and "" or "," )
			end
			MsgC("\n")
		end
	end

	function ADDON_META:PrintSkin(skin_name)
		local skin_name = skin_name or ""

		local skin = self.data.skins[skin_name]
		if not skin then return end
		MsgC("local skin = {}\n")
		MsgC("skin")
		recurse_print_skin(skin)

		MsgC('\nesclib.addon:RegisterSkin("'..string.lower(skin.name)..'_new", skin) --Or any other addon\n')
	end

	function ADDON_META:GetAllCustomTabs()
		return self.data["settings_tabs"]
	end

	--Add tab to addon settings
	--func parameters: addon, combo_panel, callback
	function ADDON_META:AddSettingsTab(uid, realm, sort_order, func)
	    local func = func or sort_order
	    if not realm or not sort_order or not func then return end

	    local allowed_realms = {
	        ["realm_Client"] = true,
	        ["realm_Server"] = true,
	    }

	    if not allowed_realms[realm] then
	        MsgC(Color(255, 100, 100), "[esclib] Warning: Invalid realm [" .. tostring(realm) .. "] (Must be realm_Client or realm_Server)\n")
	        return -- просто не добавляем таб, без error()
	    end

	    self.data["settings_tabs"][uid] = {
	        name = uid,
	        realm = realm,
	        func = func,
	        sortOrder = sort_order or 0,
	    }
	end

	function ADDON_META:RemoveSettingsTab(uid)
		self.data["settings_tabs"][uid] = nil
	end

	function ADDON_META:RequestSettings()
		print("["..self.info.uid.."] - ".."Requesting settings from server")
		net.Start("esclib.RequestConfig")
			net.WriteString(self.info.uid)
		net.SendToServer()
	end

	--RECIEVE CONFIG FROM SERVER
	net.Receive("esclib.SendConfig", function(len)

		local rewrite = false --respect server settings first

		local addon_name = net.ReadString()
		local all_addons = esclib:GetAddons()
		if not all_addons[addon_name] then return end
		local addon = all_addons[addon_name]

		local bytes = net.ReadUInt(16)
		local c_json = net.ReadData(bytes)

		local c_json = util.Decompress(c_json)
		if isstring(c_json) then 
			print(string.format("[ESCLIB] [%s] Recieved config from server",addon_name or ""))
			c_json = util.JSONToTable(c_json)

			local vars = c_json["vars"]
			local lang = c_json["lang"]
			local skin = c_json["skin"]
			local custom_skin = c_json["cst_skin"]
			local shared_vars = c_json["shared_vars"]

			local changed_vars = {}

			--settings
			if vars then
				for var_name,var_value in pairs(vars) do
					if addon.data.vars[var_name] ~= var_value then
						addon.data.vars[var_name] = var_value
						changed_vars[var_name] = var_value
					end
				end
				addon:SyncVars(-1) --vars -> settings
				--set as default
				esclib:SafeMerge(addon.data["default_settings"], addon.data.vars, true)

				if not rewrite then
					addon:LoadSettings() --load from file (file has more priority)
				end
			end

			--language
			if lang then 
				addon:SetLanguage(lang) 
				addon.info.default_language = addon.info.language
				if not rewrite then
					addon:LoadLanguage()
				end
			end

			--skin
			if skin then 
				if addon:SetSkin(skin) then
					addon.info.default_skin = skin
				end
				if not rewrite then
					addon:LoadCurrentSkin()
				end
			end

			--custom skin
			if custom_skin then
				addon.data.skins["skin_custom"] = addon.data.skins["skin_custom"] or {}
				esclib:SafeMerge(addon.data.skins["skin_custom"], custom_skin, true)
				if not rewrite then
					addon:LoadCustomSkin()
				end
			end

			--Shared settings (from server)
			if shared_vars then
				for var_name,var_value in pairs(shared_vars) do
					local orig_val = addon.data.shared_vars[var_name]
					if orig_val ~= var_value then 
						if orig_val ~= nil then changed_vars[var_name] = var_value end --only invoke changed if not first
						addon.data.shared_vars[var_name] = var_value
					end
				end
			end

			if rewrite then
				self:SaveSettings()
			end

			hook.Run(addon.info.uid.."_settings_changed",true, changed_vars)
		end

	end)

	function ADDON_META:CurrentSettingsToGlobal()
		local to_write = {}
	
		to_write["vars"] = self.data.vars
		to_write["lang"] = self:GetLanguage()
		to_write["skin"] = self.info.active_skin
		to_write["cst_skin"] = self.data.skins["skin_custom"]
	
		
		local c_json = util.TableToJSON(to_write)
		c_json = util.Compress(c_json)
		local bytes = #c_json
		
		local MAX_BYTES = 65535 --64k
		if bytes > MAX_BYTES then
			print("Error: Data size exceeds the maximum allowed limit.")
			return
		end
	
		net.Start("esclib.SendConfig")
			net.WriteString(self.info.uid)
			net.WriteUInt(bytes, 16) --64k
			net.WriteData(c_json, bytes)
		net.SendToServer()
	end

	function ADDON_META:ClearGlobalConfig()
		net.Start("esclib.ClearConfig")
			net.WriteString(self.info.uid)
		net.SendToServer()
	end

	function ADDON_META:RequestServerSettings(callback)
		if not esclib:HasAdminAccess(LocalPlayer()) then return end

		net.Start("esclib.RequestServerConfig")
			net.WriteString(self.info.uid)
		net.SendToServer()

		if callback and isfunction(callback) then
			local hook_name = self.info.name.."_request_callback"
			hook.Remove("esclib.ServerConfigRecieved",hook_name)
			hook.Add("esclib.ServerConfigRecieved", hook_name, function()
				hook.Remove("esclib.ServerConfigRecieved", hook_name)
				callback(self)
			end)
		end
	end

	net.Receive("esclib.SendServerConfig", function(len)
		local addon_name = net.ReadString()
		local addon = esclib:GetAddon(addon_name or "")
		if addon == nil then return end

		local bytes = net.ReadUInt(16)
		local c_json = net.ReadData(bytes)
		c_json = util.Decompress(c_json)

		if not isstring(c_json) then return end

		c_json = util.JSONToTable(c_json)
		if istable(c_json) and not table.IsEmpty(c_json) then
			table.Empty(addon.data["server_vars"])
			addon.data["server_vars"] = c_json
		end
		hook.Run("esclib.ServerConfigRecieved")
	end)

end

---------------------
--# SETTINGS META #--
---------------------
ADDON_META["settings_filename"] = "settings.json"
ADDON_META["custom_skin_filename"] = "custom_skin.json"
ADDON_META["other_settings_filename"] = "other_settings.json"
ADDON_META["prefix"] = CLIENT and "cl_" or "sv_"
ADDON_META["sv_hash"] = esclib:GetServerHash()

-- Direction:
-- >= 0  => settings -> vars
-- < 0 => var -> settings
function ADDON_META:SyncVars(direction)
	local direction = direction or 0

	for tabname,tab_content in pairs(self.data.settings) do
		local vars = tab_content["vars"]
		for varid,var in pairs(vars) do
			if direction >= 0 then
				--vars
				self.data.vars[varid] = var.value
			else
				--settings
				tab_content["vars"][varid]["value"] = self.data.vars[varid]
			end
		end
	end
end

--Save settings to disk
function ADDON_META:SaveSettings()
	local dir_path = self.prefix..self.info.uid..self["sv_hash"]
	local file_name = dir_path.."/"..self.settings_filename
	local json_str = util.TableToJSON(self.data.vars or {})
	if not file.Exists(dir_path, "DATA") then
		file.CreateDir(dir_path)
	end
	if json_str then
		file.Write(file_name, json_str)
	end
end

--Load settings (without languages / skin data)
function ADDON_META:LoadSettings()
	local dir_path = self.prefix..self.info.uid..self["sv_hash"]
	local file_name = dir_path.."/"..self.settings_filename

	local content = file.Read(file_name, "DATA")
	if content then
		local vars = util.JSONToTable(content)

		if istable(vars) and not table.IsEmpty(vars) then

			--changable check
			for name,val in pairs(vars) do
				for tab_name,content in pairs(self.data.settings) do
					local var = self:GetWrappedVar(tab_name,name)
					if not var then continue end

					local result = true
					if var.customCheck then 
						result = var.customCheck(var,self)
					end

					if not result then
						vars[name] = nil
					end
				end
			end

			table.Merge(self.data.vars, vars) --merge vars from file and current with overwrite
			self:SyncVars(-1) --sync vars from vars to wrapped settings(used for settings menu and custom checks)
			hook.Run(self.info.uid.."_settings_changed",true, {})
		end

	end
end

function ADDON_META:LoadAll()
	self:LoadSettings()
	self:LoadLanguage()
	self:LoadCustomSkin()
	self:LoadCurrentSkin()
end

--Init settings and load from file
function ADDON_META:RegisterSettings(settings)
	--we have already registered settings. Why change it?
	if not table.IsEmpty(self.data["settings"]) then return end

	--On first function launch
	self.data["settings"] = table.Copy(settings)
	self:SyncVars(1) -- Settings -> vars
	self.data["default_settings"] = table.Copy(self.data.vars) --copy default vars

	--attemp to load settings from file
	self:LoadSettings()
end

--Used on client to 
function ADDON_META:RegisterServerSettings(settings)
	if SERVER then
		self:RegisterSettings(settings) --register settings on server
	end
	
	if CLIENT then
		--we have already registered settings. Why change it?
		if not table.IsEmpty(self.data["server_settings"]) then return end

		--On first function launch
		self.data["server_settings"] = table.Copy(settings)

		--Save defaults
		for tab_name,tab_value in pairs(self.data["server_settings"]) do
			for var_name, var in pairs(tab_value["vars"] or {}) do
				self.data["server_default_settings"][var_name] = var.value
			end
		end
	end
end

--Replace current settings and write to file
function ADDON_META:ReplaceSettings(settings,dont_save)
	--esclib:SafeMerge(self.data["settings"], settings, true)
	table.Merge(self.data["settings"], settings)
	self:SyncVars(1)
	if not dont_save then
		self:SaveSettings()
	end
end

--Return settings to default and delete settings from file
function ADDON_META:ReturnSettingsToDefault()

	--Settings
	local dir_path = self.prefix..self.info.uid..self["sv_hash"]
	local file_name = dir_path.."/"..self.settings_filename
	if file.Exists(file_name, "DATA") then --clear from file
		file.Delete(file_name)
	end
	self.data.vars = table.Copy(self.data["default_settings"])
	self:SyncVars(-1) --vars -> settings

	if (CLIENT) then
		--Language
		file_name = dir_path.."/"..self.other_settings_filename
		
		if file.Exists(file_name, "DATA") then --clear from file
			file.Delete(file_name)
		end

		self:LoadLanguage()
		self:SetSkin(self.info.default_skin)
	end

	hook.Run(self.info.uid.."_settings_changed",true, {})

end


----------------------
--# LANGUAGES META #--
----------------------
function ADDON_META:RegisterLanguages(langs)
	if not langs then return end
	if not istable(langs) then return end
	esclib:SafeMerge(self.data.languages, langs, true)
end

function ADDON_META:GetLanguage()
	return self.info.language
end

function ADDON_META:GetDefaultLanguage()
	return self.info.default_language
end

function ADDON_META:GetLanguages()
	return self.data.languages
end

function ADDON_META:HasLanguage(lang)
	return self.data.languages[lang] ~= nil
end

function ADDON_META:SaveLanguage()
	local dir_path = self.prefix..self.info.uid..self["sv_hash"]
	local file_name = dir_path.."/"..self.other_settings_filename
	esclib.file:SaveVar(file_name,{["language"] = self.info.language})
end

function ADDON_META:LoadLanguage()
	local dir_path = self.prefix..self.info.uid..self["sv_hash"]
	local file_name = dir_path.."/"..self.other_settings_filename
	local language = esclib.file:ReadVar(file_name, "language")

	if language and string.len(tostring(language)) > 0 then 
		self:SetLanguage(language)
	else
		local game_language = GetConVar("gmod_language"):GetString()
		if self:HasLanguage(game_language) then
			self:SetLanguage(game_language)
		else
			self:SetLanguage(self:GetDefaultLanguage())
		end
	end
end

function ADDON_META:SetLanguage(lang)
	if not lang then return end
	if not isstring(lang) then return end
	lang = string.lower(lang)
	if self:HasLanguage(lang) then
		self.info.language = lang
	else
		return false
	end
	return true
end

function ADDON_META:SetDefaultLanguage(lang, dont_load)
	if self:HasLanguage(lang) then
		self.info.default_language = lang
	end

	if not dont_load then
		self:LoadLanguage()
	end
end

function ADDON_META:Translate(var, lang)
    if not var or var == "" then return end
	
	local def_lang = self:GetDefaultLanguage()
	local cLang = lang or (self:GetLanguage() or def_lang)
	local languages = self:GetLanguages()

    if languages[cLang] then
        if not languages[cLang][var] then
            return "#" .. var
        end
        return languages[cLang][var]
    else
        if cLang == def_lang then --prevent recursion
            return "#" .. var
        end
        return self:Translate(var, def_lang)
    end
end

--translate if there is # before str
function ADDON_META:TranslateIf(var, lang)
	if string.StartsWith(var, "#") then
		local var = string.TrimLeft(var, "#")
		return self:Translate(var, lang)
	else
		return var
	end
end

function ADDON_META:CanTranslate(var,lang)
	if not var then return false end
	local lang = lang or (self.info.language or (self.info.default_language or "en"))
	local lv = self:GetLanguages()[lang]

	if lv then
		return lv[var] ~= nil
	else
		return false
	end
end

function esclib:Addon(str_addon)
	if not isstring(str_addon) then return end
	local str_addon = string.lower( str_addon )
	-- if exists
	if self.addons[str_addon] then
		if not table.IsEmpty(self.addons[str_addon]) then
			-- self.addons[str_addon] = nil
			setmetatable(self.addons[str_addon], ADDON_META)
			return self.addons[str_addon]
		end
	end

	--if not exists
	local addon = {}
	addon.info = {
		["uid"] = str_addon,
		["name"] = str_addon,
		["version"] = "1.0",
		["color"] = Color(255,255,255),
		["description"] = "No description.",
		["sort_order"] = 0,
	}
	addon.data = {
		settings = {},
		settings_tabs = {},
		vars = {}, --Similar to settings, but with more convenient access to variables
		languages = {},
		shared_vars = {},
	}
	if CLIENT then --only client data
		addon.data.skins = {}
		addon.data.server_settings = {} --Server interface.
		addon.data.server_default_settings = {}
		addon.data.server_vars = {} --real data. Recieved when requested by player
	end

	setmetatable(addon, ADDON_META)

	self.addons[str_addon] = addon
	return addon
end






























