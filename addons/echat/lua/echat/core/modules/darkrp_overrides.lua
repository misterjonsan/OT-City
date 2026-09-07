local format = string.format

--------------------------------
--# REWRITE DARKRP FUNCTIONS #--
--------------------------------
--If you are using a different game mode, don't worry - this code won't cause any errors
local function RewriteDarkRP(bg)
    if not DarkRP then return end

    if echat.config.advert_command["enabled"] then
        DarkRP.declareChatCommand({
            command = "advert",
            description = "Displays an advertisement to everyone in chat.",
            delay = 1.5
        })

        if CLIENT then DarkRP.addChatReceiver("/advert", "advertise", function(ply) return true end) end
    end

    if SERVER then

        --part1: text without access check
        --part2: text with check
        --example of usage:
        -- HalfParse(ply, "[OOC] (superadmin) onexev: ", "text from onexev <clr:blue> text")
        local function HalfParse(ply, part1, part2, inverse)            
            local parsed_tags = echat:ParseText(echat:FinalParse(part1), inverse and ply or nil)
            local parsed_text = echat:ParseText(part2, (not inverse) and ply or nil)
            return table.Add(parsed_tags, parsed_text)
        end

        --https://github.com/FPtje/DarkRP/blob/a3bb21aad0a885b8d87ac5c7da00f772c4e2021f/gamemode/modules/base/sv_util.lua
        function DarkRP.talkToRange(ply, PlayerName, Message, size, default_parse)
            local ents = player.GetHumans()
            local col = team.GetColor(ply:Team())
            local filter = {}

            local plyPos = ply:EyePos()
            local sizeSqr = size * size
        
            for _, v in ipairs(ents) do
                if (v:EyePos():DistToSqr(plyPos) <= sizeSqr) and (v == ply or hook.Run("PlayerCanSeePlayersChat", PlayerName .. ": " .. Message, false, v, ply) ~= false) then
                    table.insert(filter, v)
                end
            end

            if default_parse then
                if Message ~= "" and PlayerName ~= "" then 
                    Message = ": "..Message
                end
                
                local str_without_msg = echat:FinalParse(color_white, PlayerName, Message)
                -- esclib.print("Player " .. ply:Nick() .. " sent message: " .. str_without_msg)
                echat:SendParsedMessageToPlayer(ply, filter, echat:ParseText(str_without_msg), Message)
            else
                local prefix_text = ""
                if PlayerName ~= "" then
                    local expl = string.Explode(" ", PlayerName) --we dont need name, only prefix (ooc / pm etc)
                    prefix_text = expl[1] or ""
                end

                if prefix_text ~= "" and string.StartsWith(ply:Nick() or "", prefix_text) then
                    prefix_text = ""
                else
                    prefix_text = prefix_text.." "
                end

                local str_without_msg = echat:FinalParse(col, prefix_text, ply, color_white, ": ")
                local parsed_tags = echat:ParseText(str_without_msg) --we dont need to parse tags with checks from server
                local parsed_message = echat:ParseText(Message, ply) --parse message with checks
                local result = table.Add(parsed_tags, parsed_message)

                -- esclib.print("Player " .. ply:Nick() .. " sent message: " .. Message)
                echat:SendParsedMessageToPlayer(ply, filter, result, Message)
            end
        end
        
        function DarkRP.talkToPerson(receiver, col1, prefixText, col2, text2, sender)
            if not IsValid(receiver) then return end
            if receiver:IsBot() then return end

            local concatenatedText = (prefixText or "") .. ": " .. (text2 or "")
            
            if sender == receiver or hook.Run("PlayerCanSeePlayersChat", concatenatedText, false, receiver, sender) ~= false then
                sender = sender or Entity(0)
                
                local str_without_msg = echat:FinalParse(col1, prefixText, prefixText != "" and ": " or "", col2 or color_black, text2)
                local result = echat:ParseText(str_without_msg)

                -- esclib.print("Player " .. sender:Nick() .. " sent message to " .. receiver:Nick() .. ": " .. text2)
                echat:SendParsedMessageToPlayer(sender, receiver, result, text2)
            end
        end


        ----------
        --# ME #--
        ----------
        --override default me function
        local function Me(ply, args)
            if args == "" then
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
                return ""
            end
        
            local DoSay = function(text)
                if text == "" then
                    DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
                    return ""
                end
                if GAMEMODE.Config.alltalk then
                    local col = team.GetColor(ply:Team())
                    local name = ply:Nick()
                    for _, target in ipairs(player.GetAll()) do
                        DarkRP.talkToPerson(target, col, name .. " " .. text)
                    end
                else
                    local format_str = echat.config.me_command["format"]
                    local text = esclib.text:KeyFormat(format_str, {
                        ["nick"] = ply:Nick() or "???",
                        ["text"] = text or "",
                    })
                    DarkRP.talkToRange(ply, "", text, GAMEMODE.Config.meDistance, true)
                end
            end
            return args, DoSay
        end
        if echat.config.me_command["enabled"] then
            DarkRP.defineChatCommand("me", Me, 1.5)
        end

        ----------
        --# PM #--
        ----------
        --override default PM function
        local function PM(ply, args)
            local namepos = string.find(args, " ")
            if not namepos then
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
                return ""
            end
        
            local name = string.sub(args, 1, namepos - 1)
            local msg = string.sub(args, namepos + 1)
        
            if msg == "" then
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
                return ""
            end
        
            local target = DarkRP.findPlayer(name)
            if target == ply then return "" end
        
            if target then
                local col = team.GetColor(ply:Team())
                local pname = ply:Nick()
                local col2 = color_white

                local out_format = echat.config.pm_command["sender"]["format"]
                local in_format = echat.config.pm_command["reciever"]["format"]

                local to_parse = {
                    ["from"] = echat:ParseVararg(ply) or "???",
                    ["to"] = echat:ParseVararg(target) or "???",
                    ["from_nick"] = ply:Nick(),
                    ["to_nick"] = target:Nick(),
                }

                local out_text = esclib.text:KeyFormat(out_format, to_parse)
                local in_text = esclib.text:KeyFormat(in_format, to_parse)

                local recievers = player.GetAll()
                echat:SendParsedMessageToPlayer(ply, target, HalfParse(ply, in_text, msg), msg)
                echat:SendParsedMessageToPlayer(ply, ply, HalfParse(ply, out_text, msg), msg)
            else
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("could_not_find", tostring(name)))
            end
        
            return ""
        end
        if echat.config.pm_command["enabled"] then
            DarkRP.defineChatCommand("pm", PM, 1.5)
        end

        -----------
        --# OOC #--
        -----------
        local function OOC(ply, args)
            if not GAMEMODE.Config.ooc then
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("disabled", DarkRP.getPhrase("ooc"), ""))
                return ""
            end

            local rgb_ref = echat.COMMAND_BRACKET_1.."rgb:%d,%d,%d,%d"..echat.COMMAND_BRACKET_2
        
            local DoSay = function(text)
                if text == "" then
                    DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
                    return ""
                end

                local col = team.GetColor(ply:Team())
                team_clr = format(rgb_ref, col.r, col.g, col.b, col.a)

                local tags = esclib.text:KeyFormat(echat.config.ooc_command["format"], {
                    ["jobclr"] = team_clr,
                    ["ply"] = echat:ParseVararg(ply) or "???",
                    ["ply_nick"] = ply:Nick(),
                    ["steamid"] = ply:SteamID(),
                    ["steamid64"] = ply:SteamID64()
                })

                local recievers = player.GetAll()
                echat:SendParsedMessageToPlayer(ply, recievers, HalfParse(ply, tags, text), text)
            end
            return args, DoSay
        end

        if echat.config.ooc_command["enabled"] then
            DarkRP.defineChatCommand("/", OOC, true, 1.5)
            DarkRP.defineChatCommand("a", OOC, true, 1.5)
            DarkRP.defineChatCommand("ooc", OOC, true, 1.5)
        end


        --------------
        --# ADVERT #--
        --------------
        local function Advert(ply, args)
            if args == "" then
                DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", "argument", ""))
                return ""
            end

            local rgb_ref = echat.COMMAND_BRACKET_1.."rgb:%d,%d,%d,%d"..echat.COMMAND_BRACKET_2

            local DoSay = function(text)
                if text == "" then
                    DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", "argument", ""))
                    return ""
                end

                local col = team.GetColor(ply:Team())
                team_clr = format(rgb_ref, col.r, col.g, col.b, col.a)

                local tags = esclib.text:KeyFormat(echat.config.advert_command["format"], {
                    ["jobclr"] = team_clr,
                    ["ply"] = echat:ParseVararg(ply) or "???",
                    ["ply_nick"] = ply:Nick(),
                    ["steamid"] = ply:SteamID(),
                    ["steamid64"] = ply:SteamID64()
                })

                local recievers = player.GetAll()
                echat:SendParsedMessageToPlayer(ply, recievers, HalfParse(ply, tags, text), text)
            end
            hook.Call("playerAdverted", nil, ply, args)
            return args, DoSay
        end

        if echat.config.advert_command["enabled"] then
            DarkRP.defineChatCommand("advert", Advert, true, 1.5)
        end
    
    end
end

RewriteDarkRP()