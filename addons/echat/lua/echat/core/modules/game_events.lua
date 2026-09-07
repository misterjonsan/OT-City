if SERVER then --only on server

local cfg = echat.config.game_events

----------------------
--# Player connect #--
----------------------
if cfg["player_connect"] and cfg["player_connect"].enable then
    hook.Add("player_connect", "echat.game_event.player_connect", function(data)
        if not data then return end

        local msg = cfg["player_connect"]["format"]
        local formatted_msg = esclib.text:KeyFormat(msg, {
            ["username"] = echat:EscapeParsed(data.name or "Unknown"),
            ["steamid"] = data.networkid or "STEAM_0:0:0",
        })

        local players = player.GetAll()
        local parsed = echat:ParseText(echat:FinalParse(formatted_msg))
        echat:SendParsedMessageToPlayer(nil, players, parsed)

    end)
    gameevent.Listen( "player_connect" )
end

-------------------------
--# Player disconnect #--
-------------------------
if cfg["player_disconnect"] and cfg["player_disconnect"].enable then
    hook.Add("player_disconnect", "echat.game_event.player_disconnect", function(data)
        if not data then return end

        local msg = cfg["player_disconnect"]["format"]
        local formatted_msg = esclib.text:KeyFormat(msg, {
            ["username"] = echat:EscapeParsed(data.name or "Unknown"),
            ["steamid"] = data.networkid or "STEAM_0:0:0",
            ["reason"] = data.reason or "Unknown"
        })

        local players = player.GetAll()
        local parsed = echat:ParseText(echat:FinalParse(formatted_msg))
        echat:SendParsedMessageToPlayer(nil, players, parsed)

    end)
    gameevent.Listen( "player_disconnect" )
end

if cfg["server_say"] and cfg["server_say"].enable then
    hook.Add( "player_say", "echat.game_event.player_say", function( data )
        if (not data.userid) or (data.userid != 0) then return end --check if server
        if (not data.text) or (data.text == "") then return end

        local msg = data.text or "???"
        local fmt = cfg["server_say"]["format"]
        local formatted_msg = esclib.text:KeyFormat(fmt, {
            ["text"] = msg,
        })

        local players = player.GetAll()
        local parsed = echat:ParseText(echat:FinalParse(formatted_msg))
        echat:SendParsedMessageToPlayer(nil, players, parsed)
    end )

    gameevent.Listen( "player_say" )
end


end --IF SERVER



if CLIENT then --ON CLIENT
    
    --Support for say console command
    hook.Add( "player_say", "echat.game_event.player_say", function( data )
        if (not data.userid) then return end
        if (LocalPlayer():UserID() ~= data.userid) then return end
        if (not data.text) or (data.text == "") then return end

        echat:SendMessageToServer(data.text)
    end )
    gameevent.Listen( "player_say" )

end --IF CLIENT
