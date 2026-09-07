local PLAYER_META = FindMetaTable("Player")

local clr_white = Color(255,255,255)
function PLAYER_META:ChatPrint(text)
    msg = echat:FinalParse(clr_white, text)

	if SERVER then
		echat:SendMessageToPlayer(nil, self, msg)
	else
		echat:AddParsedText( echat:ParseText(msg) )
	end
end

echat.old_print_msg = echat.old_print_msg or PLAYER_META.PrintMessage
function PLAYER_META:PrintMessage(mtype, msg)
	if mtype == HUD_PRINTTALK then
		if SERVER then
			echat:SendMessageToPlayer(nil, self, msg)
		else
			echat:AddParsedText( echat:ParseText(msg) )
		end
	end

	if isfunction(echat.old_print_msg) then echat.old_print_msg(self, mtype, msg) end
end

function PLAYER_META:IsTyping()
	return self:GetNWBool("echat.IsTyping", false)
end

if CLIENT then
	hook.Add("StartChat", "echat.start_istyping", function()
		net.Start("echat.toggle_chat")
			net.WriteBool(true)
		net.SendToServer()
	end)

	hook.Add("FinishChat", "echat.finish_istyping", function()
		net.Start("echat.toggle_chat")
			net.WriteBool(false)
		net.SendToServer()
	end)
end


if SERVER then
	echat.old_print_msg_all = echat.old_print_msg_all or PrintMessage
	function PrintMessage(mtype, msg)
		if mtype == HUD_PRINTTALK then
			echat:SendMessageToPlayer(nil, player.GetAll(), msg)
		end

		if isfunction(echat.old_print_msg_all) then echat.old_print_msg_all(mtype, msg) end
	end
end

local max = math.max
local min = math.min
local getkeys = table.GetKeys
local format = string.format

--------------------------
--# Parsers definition #--
--------------------------
echat.parsers = echat.parsers or {}
--if parser return None then command will not work
function echat:AddParser(
	uid, 
	encode_fn, 
	decode_fn, 
	example, 
	description, 
	custom_check, 
	icon
)
	echat.parsers[uid] = {uid=uid, encode_fn=encode_fn, decode_fn=decode_fn, example=example, description=description, custom_check=custom_check, icon=icon}
end

function echat:GetParser(uid)
	return echat.parsers[uid]
end

function echat:GetParsers()
	return echat.parsers
end

function echat:GetParserList()
	return getkeys(echat.parsers)
end


--------------------------
--# EMOJI USEFUL FUNCS #--
--------------------------
local errormat = Material("error")
function echat:GetEmoji(uid)
	return echat.EmojiMaterials[uid] or errormat
end

function echat:GetEmojiList()
	return getkeys(echat.EmojiMaterials)
end

function echat:GetEmojiTable()
	return echat.EmojiMaterials
end


echat.COMMAND_BRACKET_1 = "<"
echat.COMMAND_BRACKET_2 = ">"
echat.ESCAPE_CHAR = "\\"


--------------------
--# TEXT PARSERS #--
--------------------

--converts usual chat.AddText to string
function echat:ParseVararg(...)
	local args = {...}
	local parsed_str = ""

	local rgb_ref = echat.COMMAND_BRACKET_1.."rgb:%d,%d,%d,%d"..echat.COMMAND_BRACKET_2

	for k, v in ipairs(args) do
		if type(v) == "table" then --if color
			if not (isnumber(v.r) and isnumber(v.g) and isnumber(v.b) and isnumber(v.a)) then
				continue 
			end
			parsed_str = parsed_str..(format(rgb_ref, v.r, v.g, v.b, v.a))
		elseif type(v) == "string" then --if text
			if v == "" then continue end
			parsed_str = parsed_str..v
		elseif IsValid(v) and v:IsPlayer() then

			local team_clr = team.GetColor(v:Team()) or color_white
			local rank = v:GetUserGroup() or "???"
			local format_str = echat.config.rank_formats["__default__"]
			
			--format by rank
			if echat.config.rank_formats[rank] then format_str = echat.config.rank_formats[rank] end

			--format by steamid
			local steam64 = v:SteamID64() or "???"
			if echat.config.rank_formats[steam64] then format_str = echat.config.rank_formats[steam64] end

			

			local nick = v:Nick()
			nick = nick ~= "" and nick or v:SteamName()
			nick = echat:EscapeParsed(nick)

			format_str = esclib.text:KeyFormat(format_str, {
				["rank"] = rank,
				["nick"] = nick,
				["job_color"] = format(rgb_ref, team_clr.r, team_clr.g, team_clr.b, team_clr.a),
				["steamid"] = v:SteamID(),
				["steamid64"] = v:SteamID64(),
			})

			parsed_str = parsed_str..format_str
		else
			parsed_str = parsed_str..tostring(v)
		end 
	end

	return parsed_str or ""
end

function echat:FinalParse(...)
	local vararg_parsed = echat:ParseVararg(...)

	local final_str = esclib.text:KeyFormat(echat.config.message_format, {
		["message"] = vararg_parsed,
	})

	return final_str
end


function echat:ParseCmd(txt, ply)
	if txt == "" then 
		return {type="text", value=echat.COMMAND_BRACKET_1..txt..echat.COMMAND_BRACKET_2}
	end 

	local delimiter = ":"
	local cmd_args = {}
	

	for substring in txt:gmatch("[^" .. delimiter .. "]+") do
		table.insert(cmd_args, substring)
	end

	--first cmd always should be command
	if #cmd_args < 1 then
		return {type="text", value=echat.COMMAND_BRACKET_1..txt..echat.COMMAND_BRACKET_2}
	else
		local command = cmd_args[1]
		local parser = echat:GetParser(command)
		if istable(parser) then
			if isfunction(parser.custom_check) and SERVER then
				if not parser.custom_check(ply, parser) then --custom check definition
					return {type="text", value=echat.COMMAND_BRACKET_1..txt..echat.COMMAND_BRACKET_2}
				end
			end

			local result = parser.encode_fn(cmd_args)

			if not result or result == "" then --if no finded
				return {type="text", value=echat.COMMAND_BRACKET_1..txt..echat.COMMAND_BRACKET_2}
			end
			
			return result
		else
			return {type="text", value=echat.COMMAND_BRACKET_1..txt..echat.COMMAND_BRACKET_2}
		end
	end

	--if nothing found return none
	return
end


function echat:ParseText(txt, ply)
	if not txt then return end

	if echat.config.multiline then
        txt = string.Replace(txt, "\\n", "\n")
    else
        txt = string.Replace(txt, "\n", "")
        txt = string.Replace(txt, "\\n", "")
    end

	local result = {}

	local prev_ind = -1
	local prev_char = ""
	local bracket_match = esclib.text:MatchSplit(txt, "<(.-)>")
	for k,v in ipairs(bracket_match) do
		if v.matched then
			if prev_char == echat.ESCAPE_CHAR then
				local val = result[prev_ind+1]
				if val and val.type == "text" then
					val.value = string.TrimRight(val.value, "\\")
				end
				table.insert(result, {type = "text", value = v.value})
			else
				local parsed_result = self:ParseCmd(string.gsub(v.value, "["..echat.COMMAND_BRACKET_1..echat.COMMAND_BRACKET_2.."]", ""), ply)
				table.insert(result, parsed_result)
				prev_char = ""
				prev_ind = -1
			end
		else
			local emoji_match = esclib.text:MatchSplit(v.value, ":([%w_]+):")

			for k,v in ipairs(emoji_match) do
				if v.matched then
					if prev_char == echat.ESCAPE_CHAR then
						local val = result[prev_ind+1]
						if val and val.type == "text" then
							val.value = string.TrimRight(val.value, "\\")
						end
						table.insert(result, {type = "text", value = v.value})
					else
						table.insert(result, {type = "emoji", value = string.Replace(v.value, ":", "")})
						prev_char = ""
						prev_ind = -1
					end
				else
					local text = v.value
					prev_char = string.sub(text, -1)
					prev_ind = #result
					table.insert(result, {type = "text", value = text})
				end
			end
		end
	end

	return result
end

function echat:ParsedToText(parsed)
	local text = ""

	for _, item in ipairs(parsed) do
		local _type = item.type
		local parser = self:GetParser(_type)

		local value = tostring(item.value or "")
		if parser then 
			value = format("%s%s%s", echat.COMMAND_BRACKET_1, parser.decode_fn(item), echat.COMMAND_BRACKET_2)
		end
		
		text = text .. value
	end

	return text
end

function echat:EscapeParsed(text)
	--command brackets
	local text = string.Replace(text, echat.COMMAND_BRACKET_1, echat.ESCAPE_CHAR..echat.COMMAND_BRACKET_1)

	--emojies
	for _,emoj_name in ipairs(echat:GetEmojiList()) do
		text = string.Replace(text, format(":%s:", emoj_name), format("\\:%s:", emoj_name))
	end
	return text
end

-----------------------
--# VARIABLE PARSER #--
-----------------------
local VARIABLE_PARSE_META = {}

function VARIABLE_PARSE_META:Init()
	self.data = {}
	self:AddText(nil, echat:FinalParse("")) --add time, and fonts to message
end

function VARIABLE_PARSE_META:AddText(ply, text)
    table.insert(self.data, {["text"] = text, ["ply"] = ply})
    return self
end

function VARIABLE_PARSE_META:AddVararg(ply, ...)
	self:AddText(ply, echat:ParseVararg(...))
    return self
end

function VARIABLE_PARSE_META:AddNonParsedText(text)
	table.insert(self.data, {["text"] = text, ["noparse"] = true})
end

function VARIABLE_PARSE_META:AddNonParsedVararg(...)
	self:AddNonParsedText(echat:ParseVararg(...))
    return self
end

VARIABLE_PARSE_META.__index = VARIABLE_PARSE_META

--returns parsed info
function VARIABLE_PARSE_META:Parse()
    local result = {}
    for k,v in ipairs(self.data) do
		if v.noparse then
			table.Add(result, {["type"] = "text", ["value"] = v.text})
		else
        	table.Add(result, echat:ParseText(v.text, v.ply))
		end
    end
    return result
end

-- === EXAMPLE ===
-- local parser = echat:NewVariableParser()
-- parser:AddVararg(nil, "<clr:green>[OOC] ", ply, color_white, ":") --no check for player (nil)
-- parser:AddVararg(ply, text) --protected (uses RBAC)
-- local parsed_data = parser:Parse()
-- ===============
function echat:NewVariableParser()
    local parse_meta = {}
    setmetatable(parse_meta, VARIABLE_PARSE_META)
	parse_meta:Init()
    return parse_meta
end