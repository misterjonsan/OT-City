-----------------
/// CHATMODES ///
-----------------
echat.chat_modes = echat.chat_modes or {}

function echat:AddChatMode(name, prefix)
	echat.chat_modes[name] = prefix
end
--echat:AddChatMode("Admin", "@")



---------------
/// MODULES ///
---------------
echat.Modules = echat.Modules or {}
function echat:Module(uid,enable_func,close_func,custom_check,refresh_once)
	local restart = false
	if self.Modules[uid] then restart = true end 
	self.Modules[uid] = {
		["enable"] = enable_func,
		["close"] = close_func,
		["custom_check"] = custom_check,
		["enabled"] = false,
		["refresh_once"] = refresh_once
	}
	if restart then self:Restart() end
end

function echat:GetModules()
	return self.Modules
end

function echat:LoadModule(uid,...)
	local v = self.Modules[uid]
	if not v then return end

	local new_enabled = true
	if v["custom_check"] then
		new_enabled = v["custom_check"]()
	end

	local is_enabled = v["enabled"]
	if is_enabled == new_enabled then
		if not v["refresh_once"] and new_enabled then v["enable"](...) end
		return
	else
		if new_enabled then
			v["enable"](...)
		else
			v["close"](...)
		end
	end

	v["enabled"] = new_enabled
end

function echat:LoadModules(...)
	for uid,_ in pairs(self.Modules) do
		self:LoadModule(uid,...)
	end
end