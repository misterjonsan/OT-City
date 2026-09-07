local function CleanServerName(name)
    name = string.Trim(tostring(name or ""))
    name = string.gsub(name, "%^%d", "")
    name = string.gsub(name, "<.->", "")
    return name ~= "" and name or "Monteract"
end

local function GetServerName()
    if game.GetIPAddress() == "loopback" then
        return "Локальный сервер"
    end

    return CleanServerName(GetHostName and GetHostName() or "")
end

local function GetMapName()
    local mapName = game.GetMap() or "unknown"
    local prefix = string.find(mapName, "_")

    if prefix then
        mapName = string.sub(mapName, prefix + 1)
    end

    return string.NiceName(mapName)
end

local function GetPlayerProgress(ply)
    return tostring(ply.exp or 0) .. " XP · " .. math.Round(ply.skill or 0, 3) .. " Skill"
end

function StartDiscordPresence()
    if not util.IsBinaryModuleInstalled("gdiscord") then return end
    require("gdiscord")

    local discordId = "1342982709626142912"
    local refreshTime = 30
    local startTime = -1

    local function UpdateDiscordPresence()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local serverName = GetServerName()
        local ip = game.GetIPAddress()
        local rpcData = {
            details = serverName .. " · " .. GetMapName(),
            state = player.GetCount() .. "/" .. game.MaxPlayers() .. " игроков · " .. GetPlayerProgress(ply),
            partySize = player.GetCount(),
            partyMax = game.MaxPlayers(),
            startTimestamp = startTime,
            largeImageKey = "default",
            largeImageText = serverName
        }

        if ip ~= "loopback" and ip ~= "" then
            rpcData.buttonPrimaryLabel = "Подключиться"
            rpcData.buttonPrimaryUrl = "steam://connect/" .. ip
        end

        DiscordUpdateRPC(rpcData)
    end

    timer.Simple(5, function()
        startTime = os.time()
        DiscordRPCInitialize(discordId)
        UpdateDiscordPresence()

        timer.Remove("UpdateDiscordRichPresence")
        timer.Create("UpdateDiscordRichPresence", refreshTime, 0, UpdateDiscordPresence)
    end)
end

function StartSteamPresence()
    if not util.IsBinaryModuleInstalled("steamrichpresencer") then return end
    require("steamrichpresencer")

    local richText = ""
    local refreshTime = 30

    local function UpdateSteamPresence()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local updatedText = GetServerName() .. " | " .. GetMapName() .. " | " .. player.GetCount() .. "/" .. game.MaxPlayers() .. " игроков | " .. GetPlayerProgress(ply)

        if richText ~= updatedText then
            richText = updatedText
            steamworks.SetRichPresence("generic", richText)
        end
    end

    timer.Simple(5, function()
        UpdateSteamPresence()
        timer.Remove("UpdateSteamRichPresence")
        timer.Create("UpdateSteamRichPresence", refreshTime, 0, UpdateSteamPresence)
    end)
end

hook.Add("PostGamemodeLoaded", "UpdateRichPresence", function()
    StartDiscordPresence()
    StartSteamPresence()
end)
