
------------------------------
--# PLAYER NICKNAME HELPER #--
------------------------------
--use: @player_nickname
echat:AddAutoComplete("PlayerHelper", function(text, word)
	if not string.find(word, "@", 1, true) then return end

	word = string.sub(string.lower(word),2,-1)
	local checking = word:len() > 0

	local suggestions = {}
	for k, ply in ipairs(player.GetAll()) do
		local new_text = (ply:Nick() or "unknown")
		if checking then
			if not string.find(string.lower(new_text), word, 1, "true") then continue end
		end

		table.insert(suggestions, {type = "player", offset=-1, text=new_text})
	end
	return suggestions
end)



-------------
--# EMOJI #--
-------------
echat:AddAutoComplete("EmojiHelper", function(text, word)
	if not echat.config.emojies then return end
	if word[1] then
		if word[1] ~= ":" then return nil end
	end

	local suggestions = {}
	
	for i, name in ipairs(echat:GetEmojiList()) do
		
		local command_text = string.Trim(":"..name..":") --example
		if (string.find(command_text, word, 1, true) ~= nil) then
			table.insert(suggestions, {type="command", icon=echat:GetEmoji(name), offset=0, text=command_text})
		end

	end

	return suggestions
end)



---------------
--# PARSERS #--
---------------
echat:AddAutoComplete("ParserHelper", function(text, word)
	if word[1] then
		if word[1] ~= echat.COMMAND_BRACKET_1 then return nil end
	end

	local suggestions = {}
	local ply = LocalPlayer()

	for i, name in ipairs(echat:GetParserList()) do
		local parser = echat:GetParser(name)

		if isfunction(parser.custom_check) then
			if not parser.custom_check(ply, parser) then --custom check definition
				continue
			end
		end
		
		local example = parser.example or name
		if istable(example) and table.IsSequential(example) then
			for k,v in ipairs(example) do
				local ex = example[k] or name
				local command_text = string.Trim(echat.COMMAND_BRACKET_1..(ex)..echat.COMMAND_BRACKET_2) --example
				if (string.find(command_text, word, 1, true) ~= nil) then
					table.insert(suggestions, {type="command", icon=parser.icon, offset=0, text=command_text, description = parser.description})
				end
			end
		else
			local command_text = string.Trim(echat.COMMAND_BRACKET_1..(example)..echat.COMMAND_BRACKET_2) --example
			if (string.find(command_text, word, 1, true) ~= nil) then
				table.insert(suggestions, {type="command", offset=0, text=command_text, description = parser.description})
			end
		end

	end

	return suggestions
end)


echat:AddAutoComplete("CustomCommands",function(text, word)
	local suggestions = {}
	for cmd_name, values in pairs(echat.config.custom_commands) do
		local command_text = string.Trim(cmd_name)
		if (string.find(command_text, text, 1, true) ~= nil) then
			table.insert(suggestions, {
				type="command", 
				offset=0, 
				text=command_text, 
				args=values["args"],
				description=values["description"]
			})
		end
	end
	return suggestions
end)



-------------------------------
--# DARKRP DEFAULT COMMANDS #--
-------------------------------
-- /command
if DarkRP then
	echat:AddAutoComplete("DarkRP_Commands",function(text, word)
		if not string.StartsWith(text or "", "/") then return end

		local suggestions = {}
		for k,v in pairs(DarkRP.chatCommands) do
			local command_text = string.Trim("/"..v.command)
	    	if (string.find(command_text, text, 1, true) ~= nil) then
				table.insert(suggestions, {type="command", offset=0, text=command_text,description=v.description})
			end
		end
		return suggestions
	end)
end


-------------------
--# SAM SUPPORT #--
-------------------
if sam and sam.command then
	local commands = sam.command.get_commands()

    local function getSamCommandsAutoComplete(text, word)
		if not string.StartsWith(text or "", "!") then return end

        local ply = LocalPlayer()
        local suggestions = {}

        for _, v in ipairs(commands) do

            if not v.name or not sam.ranks.has_permission(ply:GetUserGroup(), v.permission) then
                continue
            end

            local commandText = string.Trim("!" .. v.name)

            if string.find(commandText, text, 1, true) then
                local args

                if v.args then
                    args = {}

                    for _, arg in ipairs(v.args) do
                        table.insert(args, string.format("<%s>", arg.hint or arg.name))
                    end
                end

                table.insert(suggestions, {
                    type = "command",
                    offset = 0,
                    text = commandText,
                    args = args,
                    description = v.help
                })
            end
        end

        return suggestions
    end

    echat:AddAutoComplete("SAM_Commands", getSamCommandsAutoComplete)
end

----------------------
--# sAdmin support #--
----------------------
if sAdmin then
	local sadmin_prefixes = {"!", "/"}
	local commands = sAdmin.commands

	local function getsAdminAutoComplete(text, word)
		local cont = false
		local cmd_pref = "!"

		for _, pref in ipairs(sadmin_prefixes) do
			if string.StartsWith(text or "", pref) then 
				cont = true
				cmd_pref = pref
				break
			end
		end
		if not cont then return end

        local ply = LocalPlayer()
        local suggestions = {}

        for _, v in pairs(commands) do

            if not v.name then
                continue
            end

            local commandText = cmd_pref..v.name

            if string.find(commandText, text, 1, true) then
                local args

                if v.inputs then
                    args = {}

                    for _, arg in ipairs(v.inputs) do
						if not arg[2] then continue end
                        table.insert(args, string.format("<%s>", arg[2]))
                    end
                end

                table.insert(suggestions, {
                    type = "command",
                    offset = 0,
                    text = commandText,
                    args = args,
                    description = v.help
                })
            end
        end

        return suggestions
    end

	echat:AddAutoComplete("sAdmin_Commands", getsAdminAutoComplete)
end

-------------------
--# ULX SUPPORT #--
-------------------
if ulx then
	local cmds = {}
	local prefix = "!"

	for _,category in pairs(ulx.cmdsByCategory) do
		for _,cmd in ipairs(category) do
			local desc = cmd.helpStr

			local args = {}
			for _, v in ipairs(cmd.args or {}) do
				if not v.hint then continue end
				table.insert(args,  "<"..tostring(v.hint)..">")
			end

			for _, v in ipairs(cmd.say_cmd or {}) do
				if string.len(v) < 2 then continue end
				if v[1] ~= prefix then continue end
				table.insert(cmds, {
					["desc"] = desc, 
					["cmd"] = v,
					["args"] = args,
				})
			end
		end
	end

	local function getsULXAutoComplete(text, word)
		if text[1] ~= prefix then return end

        local ply = LocalPlayer()
        local suggestions = {}

        for _, v in pairs(cmds) do

            local commandText = v.cmd

            if string.find(commandText, text, 1, true) then
                table.insert(suggestions, {
                    type = "command",
                    offset = 0,
                    text = commandText,
                    args = v.args,
                    description = v.desc
                })
            end
        end

        return suggestions
    end

	echat:AddAutoComplete("ULX_Commands", getsULXAutoComplete)
end