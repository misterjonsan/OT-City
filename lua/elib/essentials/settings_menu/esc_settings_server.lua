--Config net strings
util.AddNetworkString("esclib.RequestConfig")
util.AddNetworkString("esclib.RequestServerConfig")
util.AddNetworkString("esclib.SendConfig")
util.AddNetworkString("esclib.SendServerConfig")
util.AddNetworkString("esclib.ClearConfig")
util.AddNetworkString("esclib.ClearServerConfig")

esclib.default_cl_settings = esclib.default_cl_settings or {}
esclib.server_uid = nil

local sv_tab = "sv_esclib"
local settings_file_name = sv_tab.."/default_settings.json"
local uid_file_name = sv_tab.."/server_uid.json"

----------------------------------
--# DEFAULT CONFIG FOR PLAYERS #--
----------------------------------
--Load settings from file
esclib:SafeMerge(esclib.default_cl_settings, esclib.file:ReadVar(settings_file_name,"settings") or {}, true)


-------------------------------
--# GENERATE UID FOR SERVER #--
-------------------------------
local function GenerateUIDOnce()
	if file.Exists( uid_file_name, "DATA" ) then return end

	local uid = math.Rand(1, 51200)
	uid = tostring(uid)
	uid = string.gsub(uid, "%.", "0")

	esclib.server_uid = uid
	esclib.file:SaveVar(uid_file_name,{["uid"] = uid})
end

if not esclib.server_uid then
	esclib.server_uid = esclib.file:ReadVar(uid_file_name,"uid")

	if not esclib.server_uid then
		GenerateUIDOnce()
	end

	SetGlobalString("esclib.serveruid",esclib.server_uid)
end



-------------------
--# SEND CONFIG #--
-------------------
local function OnRequestConfig(len,ply,addon)
	local addon_name = net.ReadString() or (addon_name or "")
	local addon = esclib:GetAddon(addon_name or "")
	if not addon then return end

	--esclib:AddCooldownFunc(net_name,ply,cooldown,func,dont_use_timer)
	esclib:AddCooldownFunc(addon_name.."_".."RequestConfig", ply, 0.1, function()
		if not IsValid(ply) then return end
		print(string.format("[ESCLIB][INFO] Player: %s SteamID: %s requested CLIENT config for %s addon", ply:Nick(), ply:SteamID(), addon_name))

		local to_send = esclib.default_cl_settings[addon_name] or {}
		to_send["shared_vars"] = {}
		for _, tab in pairs(addon.data.settings or {}) do
			for var_name, var in pairs(tab.vars or {}) do
				if not var.shared then continue end
				to_send["shared_vars"][var_name] = var.value
			end
		end
		if table.IsEmpty(to_send["shared_vars"]) then
			to_send["shared_vars"] = nil --no need to send if empty
		end

		local c_json = util.Compress(util.TableToJSON(to_send))
		local bytes = #c_json

		net.Start("esclib.SendConfig")
			net.WriteString( addon_name )
			net.WriteUInt( bytes, 16 )
			net.WriteData( c_json, bytes )
		net.Send(ply)
	end)
end
net.Receive("esclib.RequestConfig", OnRequestConfig)

-----------------------------
--# SAVE CONFIG ON SERVER #--
-----------------------------
local function OnGetClientConfig(len,ply,addon)
	if not esclib:HasAdminAccess(ply) then return end

	local net_name = "SendConfig"
	local cooldown = 0.1

	local addon_name = net.ReadString() or (addon or "")
	if not esclib:HasAddon(addon_name or "") then return end

	esclib:AddCooldownFunc(addon_name.."_"..net_name, ply, cooldown, function()
		if not IsValid(ply) then return end
		print(string.format("[ESCLIB][INFO] Player: %s SteamID: %s requested SAVE CLIENT config", ply:Nick(), ply:SteamID()))

		local all_addons = esclib:GetAddons()
		if not all_addons[addon_name] then return end

		local bytes = net.ReadUInt(16)
		local c_json = net.ReadData(bytes)

		local c_json = util.Decompress(c_json) or "{}"
		local json_string = c_json
		c_json = util.JSONToTable(c_json)

		if not esclib.default_cl_settings[addon_name] then esclib.default_cl_settings[addon_name] = {} end
		esclib:SafeMerge(esclib.default_cl_settings[addon_name], c_json, true)

		esclib.file:SaveVar(settings_file_name,{settings=esclib.default_cl_settings})


		--Send config to all connected players
		c_json = util.Compress( json_string )
		local bytes = #c_json

		net.Start("esclib.SendConfig")
			net.WriteString( addon_name )
			net.WriteUInt( bytes, 16 )
			net.WriteData( c_json, bytes )
		net.Broadcast()
	end)
end
net.Receive("esclib.SendConfig", OnGetClientConfig)

------------------------------
--# CLEAR CONFIG ON SERVER #--
------------------------------
local function OnClearConfig(len,ply,addon)
	if not esclib:HasAdminAccess(ply) then return end

	local net_name = "ClearConfig"
	local cooldown = 0.1

	local addon_name = net.ReadString() or (addon or "")
	if not esclib:HasAddon(addon_name or "") then return end

	esclib:AddCooldownFunc(addon_name.."_"..net_name, ply, cooldown, function()
		if not IsValid(ply) then return end
		print(string.format("[ESCLIB][INFO] [%s] Player: %s SteamID: %s requested CLEAR CLIENT config", addon_name, ply:Nick(), ply:SteamID()))
		esclib.default_cl_settings[addon_name] = nil
		esclib.file:Remove(settings_file_name)
		esclib.file:SaveVar(settings_file_name,{settings=esclib.default_cl_settings})
	end)
end
net.Receive("esclib.ClearConfig", OnClearConfig)





-------------------------------
--# REQUEST SERVER SETTINGS #--
-------------------------------
local function OnRequestServerConfig(len,ply,addon)
	if not esclib:HasAdminAccess(ply) then return end

	local net_name = "RequestSvConfig"
	local cooldown = 0.1

	local addon_name = net.ReadString() or (addon or "")
	if not esclib:HasAddon(addon_name or "") then return end

	esclib:AddCooldownFunc(addon_name.."_"..net_name, ply, cooldown, function()
		if not IsValid(ply) then return end

		local to_send = esclib:GetAddon(addon_name)["data"]["vars"]
		if table.IsEmpty(to_send or {}) then return end

		local c_json = util.Compress( util.TableToJSON(to_send) )
		local bytes = #c_json

		net.Start("esclib.SendServerConfig")
			net.WriteString( addon_name )
			net.WriteUInt( bytes, 16 )
			net.WriteData( c_json, bytes )
		net.Send(ply)

	end)
end
net.Receive("esclib.RequestServerConfig", OnRequestServerConfig)


------------------------------------
--# REQUEST SAVE SERVER SETTINGS #--
------------------------------------
local function OnRequestSaveServerConfig(len,ply,addon)
	if not esclib:HasAdminAccess(ply) then return end

	local net_name = "RequestSaveSvConfig"
	local cooldown = 0.1

	local addon_name = net.ReadString() or (addon or "")
	if not esclib:HasAddon(addon_name or "") then return end

	esclib:AddCooldownFunc(addon_name.."_"..net_name, ply, cooldown, function()
		if not IsValid(ply) then return end
		print(string.format("[ESCLIB][INFO] Player: %s SteamID: %s requested SAVE SERVER config", ply:Nick(), ply:SteamID()))

		local c_json = esclib:NetReadCompressedTable()
		if not istable(c_json) then return end

		local addon = esclib:GetAddon(addon_name)
		if not addon then return end

		--merge current settings with override
		table.Merge(addon.data.vars, c_json, true)
		addon:SyncVars(-1)
		addon:SaveSettings()

		--send shared data to clients
		local to_send = {}
		for _, tab in pairs(addon.data.settings or {}) do
			for var_name, var in pairs(tab.vars or {}) do
				if c_json[var_name] == nil then continue end
				if not var.shared then continue end
				to_send[var_name] = var.value
			end
		end

		if table.IsEmpty(to_send) then return end

		local c_json = util.Compress(util.TableToJSON({["shared_vars"] = to_send}))
		local bytes = #c_json

		net.Start("esclib.SendConfig")
			net.WriteString( addon_name )
			net.WriteUInt( bytes, 16 )
			net.WriteData( c_json, bytes )
		net.Broadcast()
			
	end)
end
net.Receive("esclib.SendServerConfig", OnRequestSaveServerConfig)

-------------------------------------
--# REQUEST CLEAR SERVER SETTINGS #--
-------------------------------------
local function OnRequestClearServerConfig(len,ply,addon)
	if not esclib:HasAdminAccess(ply) then return end

	local net_name = "RequestClearSvConfig"
	local cooldown = 0.1

	local addon_name = net.ReadString() or (addon or "")
	if not esclib:HasAddon(addon_name or "") then return end

	esclib:AddCooldownFunc(addon_name.."_"..net_name, ply, cooldown, function()
		local addon = esclib:GetAddon(addon_name)
		addon:ReturnSettingsToDefault()

		--send shared data to clients
		local to_send = {}
		for _, tab in pairs(addon.data.settings or {}) do
			for var_name, var in pairs(tab.vars or {}) do
				if not var.shared then continue end
				to_send[var_name] = var.value
			end
		end

		if table.IsEmpty(to_send) then return end

		local c_json = util.Compress(util.TableToJSON({["shared_vars"] = to_send}))
		local bytes = #c_json

		net.Start("esclib.SendConfig")
			net.WriteString( addon_name )
			net.WriteUInt( bytes, 16 )
			net.WriteData( c_json, bytes )
		net.Broadcast()
	end)
end
net.Receive("esclib.ClearServerConfig", OnRequestClearServerConfig)