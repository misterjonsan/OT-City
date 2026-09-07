if SAM_LOADED then return end

local sam, command, language = sam, sam.command, sam.language

command.set_category("Chat")

local function now()
	return os.time()
end

local function get_time_left(until_time)
	until_time = tonumber(until_time)

	if not until_time then
		return nil
	end

	if until_time == 0 then
		return 0
	end

	return math.max(until_time - now(), 0)
end

local function run_console_on_player(cmd, steamid64)
	local target = player.GetBySteamID64(steamid64)
	if not IsValid(target) then return end

	RunConsoleCommand("sam", cmd, "#" .. target:EntIndex())
end

local function remove_mute_timer(ply)
	if not IsValid(ply) then return end

	timer.Remove("SAM.UnMute" .. ply:SteamID64())
end

local function remove_gag_timer(ply)
	if not IsValid(ply) then return end

	timer.Remove("SAM.UnGag" .. ply:SteamID64())
end

local function create_mute_timer(ply, unmute_time)
	if not IsValid(ply) then return end

	remove_mute_timer(ply)

	local left = get_time_left(unmute_time)
	if not left or left == 0 then return end

	local steamid64 = ply:SteamID64()

	timer.Create("SAM.UnMute" .. steamid64, left, 1, function()
		run_console_on_player("unmute", steamid64)
	end)
end

local function create_gag_timer(ply, ungag_time)
	if not IsValid(ply) then return end

	remove_gag_timer(ply)

	local left = get_time_left(ungag_time)
	if not left or left == 0 then return end

	local steamid64 = ply:SteamID64()

	timer.Create("SAM.UnGag" .. steamid64, left, 1, function()
		run_console_on_player("ungag", steamid64)
	end)
end

local function is_muted(ply)
	if not IsValid(ply) then return false end

	local unmute_time = ply:sam_get_pdata("unmute_time")
	if not unmute_time then return false end

	unmute_time = tonumber(unmute_time)
	if not unmute_time then
		ply:sam_set_pdata("unmute_time", nil)
		remove_mute_timer(ply)
		return false
	end

	if unmute_time == 0 then
		return true
	end

	if unmute_time > now() then
		return true
	end

	RunConsoleCommand("sam", "unmute", "#" .. ply:EntIndex())
	return false
end

local function is_gagged(ply)
	if not IsValid(ply) then return false end

	local gag_time = ply:sam_get_pdata("gagged")
	if not gag_time then return false end

	gag_time = tonumber(gag_time)
	if not gag_time then
		ply:sam_set_pdata("gagged", nil)
		ply.sam_gagged = nil
		remove_gag_timer(ply)
		return false
	end

	if gag_time == 0 then
		return true
	end

	if gag_time > now() then
		return true
	end

	RunConsoleCommand("sam", "ungag", "#" .. ply:EntIndex())
	return false
end

command.new("pm")
	:SetPermission("pm", "user")

	:AddArg("player", {allow_higher_target = true, single_target = true, cant_target_self = true})
	:AddArg("text", {hint = "message", check = function(str)
		return str:match("%S") ~= nil
	end})

	:GetRestArgs()

	:Help("pm_help")

	:OnExecute(function(ply, targets, message)
		if is_muted(ply) then
			return ply:sam_send_message("you_muted")
		end

		local target = targets[1]

		ply:sam_send_message("pm_to", {
			T = targets, V = message
		})

		if ply ~= target then
			target:sam_send_message("pm_from", {
				A = ply, V = message
			})
		end
	end)
:End()

do
	sam.permissions.add("see_admin_chat", nil, "admin")

	local reports_enabled = sam.config.get_updated("Reports", true)
	command.new("asay")
		:SetPermission("asay", "user")

		:AddArg("text", {hint = "message"})
		:GetRestArgs()

		:Help("asay_help")

		:OnExecute(function(ply, message)
			if reports_enabled.value and not ply:HasPermission("see_admin_chat") then
				local success, time = sam.player.report(ply, message)
				if success == false then
					ply:sam_send_message("You need to wait {S Red} seconds.", {
						S = time
					})
				else
					ply:sam_send_message("to_admins", {
						A = ply, V = message
					})
				end
				return
			end

			local targets = {ply}

			local players = player.GetHumans()
			for i = 1, #players do
				local v = players[i]
				if v:HasPermission("see_admin_chat") and v ~= ply then
					table.insert(targets, v)
				end
			end

			sam.player.send_message(targets, "to_admins", {
				A = ply, V = message
			})
		end)
	:End()

	if SERVER then
		sam.hook_last("PlayerSay", "SAM.Chat.Asay", function(ply, text)
			if text:sub(1, 1) == "@" then
				ply:Say("!asay " .. text:sub(2))
				return ""
			end
		end)
	end
end

do
	command.new("mute")
		:SetPermission("mute", "admin")

		:AddArg("player")
		:AddArg("length", {optional = true, default = 0, min = 0})
		:AddArg("text", {hint = "reason", optional = true, default = sam.language.get("default_reason")})

		:GetRestArgs()

		:Help("mute_help")

		:OnExecute(function(ply, targets, length, reason)
			local unmute_time = length ~= 0 and (now() + length * 60) or 0

			for i = 1, #targets do
				local target = targets[i]
				target:sam_set_pdata("unmute_time", unmute_time)
				create_mute_timer(target, unmute_time)
			end

			sam.player.send_message(nil, "mute", {
				A = ply, T = targets, V = sam.format_length(length), V_2 = reason
			})
		end)
	:End()

	command.new("unmute")
		:SetPermission("unmute", "admin")
		:AddArg("player", {optional = true})
		:Help("unmute_help")

		:OnExecute(function(ply, targets)
			for i = 1, #targets do
				local target = targets[i]
				target:sam_set_pdata("unmute_time", nil)
				remove_mute_timer(target)
			end

			sam.player.send_message(nil, "unmute", {
				A = ply, T = targets
			})
		end)
	:End()

	if SERVER then
		sam.hook_first("PlayerSay", "SAM.Chat.Mute", function(ply, text)
			if not is_muted(ply) then return end

			if text:sub(1, 1) == "!" and text:sub(2, 2):match("%S") ~= nil then
				local args = sam.parse_args(text:sub(2))

				local cmd_name = args[1]
				if not cmd_name then return end

				local cmd = command.get_command(cmd_name)
				if cmd then
					return
				end
			end

			return ""
		end)

		hook.Add("PlayerInitialSpawn", "SAM.Chat.MuteRestore", function(ply)
			timer.Simple(1, function()
				if not IsValid(ply) then return end

				local unmute_time = ply:sam_get_pdata("unmute_time")
				if not unmute_time then return end

				unmute_time = tonumber(unmute_time)
				if not unmute_time then
					ply:sam_set_pdata("unmute_time", nil)
					remove_mute_timer(ply)
					return
				end

				if unmute_time ~= 0 and unmute_time <= now() then
					RunConsoleCommand("sam", "unmute", "#" .. ply:EntIndex())
					return
				end

				create_mute_timer(ply, unmute_time)
			end)
		end)

		hook.Add("PlayerDisconnected", "SAM.Chat.MuteCleanup", function(ply)
			remove_mute_timer(ply)
		end)
	end
end

do
	command.new("gag")
		:SetPermission("gag", "admin")

		:AddArg("player")
		:AddArg("length", {optional = true, default = 0, min = 0})
		:AddArg("text", {hint = "reason", optional = true, default = sam.language.get("default_reason")})

		:GetRestArgs()

		:Help("gag_help")

		:OnExecute(function(ply, targets, length, reason)
			local gag_time = length ~= 0 and (now() + length * 60) or 0

			for i = 1, #targets do
				local target = targets[i]
				target.sam_gagged = true
				target:sam_set_pdata("gagged", gag_time)
				create_gag_timer(target, gag_time)
			end

			sam.player.send_message(nil, "gag", {
				A = ply, T = targets, V = sam.format_length(length), V_2 = reason
			})
		end)
	:End()

	command.new("ungag")
		:SetPermission("ungag", "admin")

		:AddArg("player", {optional = true})
		:Help("ungag_help")

		:OnExecute(function(ply, targets)
			for i = 1, #targets do
				local target = targets[i]
				target.sam_gagged = nil
				target:sam_set_pdata("gagged", nil)
				remove_gag_timer(target)
			end

			sam.player.send_message(nil, "ungag", {
				A = ply, T = targets
			})
		end)
	:End()

	if SERVER then
		hook.Add("PlayerCanHearPlayersVoice", "SAM.Chat.Gag", function(_, ply)
			if is_gagged(ply) then
				return false
			end
		end)

		hook.Add("PlayerInitialSpawn", "SAM.Gag", function(ply)
			timer.Simple(1, function()
				if not IsValid(ply) then return end

				local gag_time = ply:sam_get_pdata("gagged")
				if not gag_time then return end

				gag_time = tonumber(gag_time)
				if not gag_time then
					ply:sam_set_pdata("gagged", nil)
					ply.sam_gagged = nil
					remove_gag_timer(ply)
					return
				end

				if gag_time ~= 0 and gag_time <= now() then
					RunConsoleCommand("sam", "ungag", "#" .. ply:EntIndex())
					return
				end

				ply.sam_gagged = true
				create_gag_timer(ply, gag_time)
			end)
		end)

		hook.Add("PlayerDisconnected", "SAM.Gag", function(ply)
			remove_gag_timer(ply)
		end)
	end
end