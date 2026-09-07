-- util.AddNetworkString("echat.Message")
util.AddNetworkString("echat.toggle_chat")

--if from = nil then message from server
--to can be {ply, ply2, ply3 ...}
local netstream = esclib.netstream

function echat:SendParsedMessageToPlayer(from, to, parsed_text, actual_text)
    local from_player = (IsValid(from) and from.IsPlayer) and from:IsPlayer()
    from_player = from_player and from:EntIndex() or nil

    -- esclib.print({to, "echat.Message", parsed_text, actual_text, from_player})
    netstream.Start(to, "echat.Message", parsed_text, actual_text, from_player)--from_player and from)
end

function echat:SendMessageToPlayer(from, to, string_to_send)
    if not string_to_send or not isstring(string_to_send) then return end --nothing to send
    local parsed = echat:ParseText(string_to_send, from) --we need to parse it on server because there is checks for different parsers
    if not parsed or not istable(parsed) then return end --nothing to send

    echat:SendParsedMessageToPlayer(from, to, parsed, string_to_send)
end

function echat:AddText(to, ...)
	local final_str = echat:FinalParse(...)
    echat:SendMessageToPlayer(nil, to, final_str)
end

local function limitStringLength(input, maxLength)
    if #input > maxLength then
        return string.sub(input, 1, maxLength).."..."
    end
    return input
end

netstream.Hook("echat.Message", function(ply, is_team, text)
    if not text then 
        esclib.print("Player " .. ply:Nick() .. " tried to send empty message")
        return
    end

    esclib:AddCooldownFunc("echat.Message", ply, 0.5, function()
        text=limitStringLength(text, echat.config.max_message_len)

        local hook_text = hook.Run("PlayerSay", ply, text, is_team)

        --If it is overriden by gamemode or other addon:
        if hook_text == "" then return end

        --If it is not overriden
        text = hook_text
        local players = player.GetHumans()
        local recievers = {}
        for _, v in ipairs(players) do
            if not IsValid(v) then
                esclib.print("Invalid player for message send")
                continue 
            end
            if is_team then
                if (v:Team() == ply:Team()) then
                    if hook.Run("PlayerCanSeePlayersChat", text, true, v, ply) ~= false then
                        table.insert(recievers, v)
                    end
                end
            else
                if hook.Run("PlayerCanSeePlayersChat", text, false, v, ply) ~= false then
                    table.insert(recievers, v)
                end
            end
        end


        local tags = ""
        if is_team then
            tags = echat:FinalParse( team.GetColor(ply:Team()), "[TEAM] ", ply, color_white, ": ")
        else
            tags = echat:FinalParse(ply, color_white, ": ")
        end


        local parsed_tags = echat:ParseText(tags) --we dont need to parse tags from server
        local parsed_message = echat:ParseText(text, ply) --parse message with checks
        local result = table.Add(parsed_tags, parsed_message)

        -- ply:Say(text, is_team)
        echat:SendParsedMessageToPlayer(ply, recievers, result, text)
    end)
end)


net.Receive("echat.toggle_chat", function(len, ply) --fix IsTyping
	ply:SetNWBool("echat.IsTyping", net.ReadBool())
end)