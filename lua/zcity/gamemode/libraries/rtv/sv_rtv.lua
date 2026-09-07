if SERVER then
    util.AddNetworkString("ZB_RockTheVote_start")
    util.AddNetworkString("ZB_RockTheVote_vote")
    util.AddNetworkString("ZB_RockTheVote_voteCLreg")
    util.AddNetworkString("ZB_RockTheVote_end")
    util.AddNetworkString("RTVMenu")
end

zb = zb or {}

local cooldown = {}
local votes = {}
zb.votestarted = zb.votestarted or false
zb.rtvDisabled = zb.rtvDisabled or false
zb.forceRTVNextRound = zb.forceRTVNextRound or false
local playervote = {}
local mappull = {}
local playerVoteWeight = {}

local function GetMapFamily(map)
    if string.find(string.lower(map), "smalltown", 1, true) then
        return "smalltown"
    end
    return nil
end

local function GetFamilyMaps(family)
    local familyMaps = {}
    for _, map in ipairs(mappull) do
        if GetMapFamily(map) == family then
            familyMaps[#familyMaps + 1] = map
        end
    end
    return familyMaps
end

local blacklist = {
    ["gm_construct"] = true,
    ["gm_flatgrass"] = true,
    ["gm_altarskforest"] = true,
    ["gm_renostruct_v2"] = true,
    ["gm_renostruct_v2_night"] = true,
    ["gm_city_of_silence"] = true,
    ["ttt_hogwarts"] = true
}

local allowedPrefix = {
    ["ttt"] = true,
    ["hmcd"] = true,
    ["mu"] = true,
    ["ze"] = false,
    ["zs"] = true,
    ["tdm"] = true,
    ["zb"] = false,
    ["zbattle"] = false,
    ["gm"] = true,
    ["ph"] = true,
    ["cs"] = true,
    ["de"] = true
}

local prefixWeights = {
    ["ttt"] = 18,
    ["hmcd"] = 19,
    ["mu"] = 18,
    ["ze"] = 0,
    ["zs"] = 9,
    ["tdm"] = 5,
    ["zb"] = 0,
    ["zbattle"] = 0,
    ["gm"] = 20,
    ["ph"] = 11,
    ["cs"] = 1,
    ["de"] = 1
}

local function GetSafeServerName()
    local hostname = GetConVar("hostname") and GetConVar("hostname"):GetString() or "unknown"
    hostname = hostname:gsub("[^%w_-]", "_"):sub(1, 20)
    return hostname
end

local function GetDataPath(fileName)
    local serverName = GetSafeServerName()
    return "zbattle/" .. serverName .. "/" .. fileName
end

local function EnsureDataDirectory()
    local serverName = GetSafeServerName()
    if not file.Exists("zbattle", "DATA") then
        file.CreateDir("zbattle")
    end
    if not file.Exists("zbattle/" .. serverName, "DATA") then
        file.CreateDir("zbattle/" .. serverName)
    end
end

EnsureDataDirectory()

local mapPopularity = {}
local popularityPath = GetDataPath("MapPopularity.json")
if file.Exists(popularityPath, "DATA") then
    local data = file.Read(popularityPath, "DATA")
    mapPopularity = util.JSONToTable(data) or {}
end

local function getmaps()
    table.Empty(mappull)
    local maps = file.Find("maps/*.bsp", "GAME")
    for _, map in ipairs(maps) do
        map = map:sub(1, -5)
        local mapstr = map:Split("_")
        if allowedPrefix[mapstr[1]] and not blacklist[map] then
            mappull[#mappull + 1] = map
        end
    end
end

local function getWeightedRandomMapPrefix()
    local totalWeight = 0
    for _, weight in pairs(prefixWeights) do
        totalWeight = totalWeight + weight
    end
    local randomWeight = math.random() * totalWeight
    for prefix, weight in pairs(prefixWeights) do
        if randomWeight < weight then
            return prefix
        end
        randomWeight = randomWeight - weight
    end
end

local function getMapsByPrefix(prefix)
    local prefixMaps = {}
    for _, map in ipairs(mappull) do
        if map:StartWith(prefix) then
            prefixMaps[#prefixMaps + 1] = map
        end
    end
    return prefixMaps
end

hook.Add("InitPostEntity", "zb_GetMaps", function()
    zb.votestarted = false
    getmaps()
end)

if SERVER then
    net.Receive("ZB_RockTheVote_vote", function(_, ply)
        if not zb.votestarted or zb.rtvDisabled then return end
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local idx = ply:EntIndex()
        if cooldown[idx] and cooldown[idx] > CurTime() then return end
        cooldown[idx] = CurTime() + 1

        if playervote[idx] and votes[playervote[idx]] then
            votes[playervote[idx]] = votes[playervote[idx]] - (playerVoteWeight[idx] or 1)
        end

        local map = net.ReadString()
        if not map or map == "" then return end
        if map ~= "random" and not table.HasValue(mappull, map) then return end

        playervote[idx] = map
        playerVoteWeight[idx] = 1
        votes[map] = (votes[map] or 0) + playerVoteWeight[idx]

        net.Start("ZB_RockTheVote_voteCLreg")
            net.WriteTable(votes)
        net.Broadcast()
    end)
end

local endStarted = false
local rtvtime = 0

function zb.EndRTV()
    if endStarted then return end

    local winmap = table.GetWinningKey(votes)
    if not winmap then return end

    if winmap == "random" then
        winmap = mappull[math.random(#mappull)]
    end

    local mapFamily = GetMapFamily(winmap)
    mapPopularity[winmap] = math.min((mapPopularity[winmap] or 0) + 5, 100)

    local PlayedMaps = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA")) or {}
    end

    if not table.HasValue(PlayedMaps, winmap) then
        table.insert(PlayedMaps, 1, winmap)

        if mapFamily then
            local familyMaps = GetFamilyMaps(mapFamily)
            for _, familyMap in ipairs(familyMaps) do
                if familyMap ~= winmap and not table.HasValue(PlayedMaps, familyMap) then
                    table.insert(PlayedMaps, 1, familyMap)
                    mapPopularity[familyMap] = math.min((mapPopularity[familyMap] or 0) + 5, 100)
                end
            end
        end

        if #PlayedMaps > 20 then
            local lastFiveMaps = {}
            for i = math.max(1, #PlayedMaps - 5 + 1), #PlayedMaps do
                if i > 1 then
                    lastFiveMaps[#lastFiveMaps + 1] = PlayedMaps[i]
                end
            end
            local rebuilt = { winmap }
            for _, m in ipairs(lastFiveMaps) do
                rebuilt[#rebuilt + 1] = m
            end
            PlayedMaps = rebuilt
        end

        file.Write(playedMapsPath, util.TableToJSON(PlayedMaps))
    end

    for map, pop in pairs(mapPopularity) do
        if map ~= winmap and not table.HasValue(PlayedMaps, map) then
            mapPopularity[map] = math.max((pop or 0) - 2, 0)
        end
    end

    file.Write(popularityPath, util.TableToJSON(mapPopularity))

    if SERVER then
        net.Start("ZB_RockTheVote_end")
            net.WriteString(winmap)
        net.Broadcast()
    end

    endStarted = true

    timer.Simple(3, function()
        table.Empty(votes)
        table.Empty(playervote)
        table.Empty(playerVoteWeight)
        zb.votestarted = false
        endStarted = false
        hook.Remove("Think", "RTVThink")
        RunConsoleCommand("changelevel", winmap)
    end)
end

function zb.ThinkRTV()
    if not zb.votestarted or zb.rtvDisabled then return end
    if rtvtime < CurTime() then
        zb.EndRTV()
    end
end

local function getUniquePrefixes(playedMaps)
    local chosen = {}
    local attempts = 0

    while #chosen < 3 do
        local prefix = getWeightedRandomMapPrefix()
        if prefix and not table.HasValue(chosen, prefix) then
            local prefixMaps = getMapsByPrefix(prefix)
            local validCount = 0
            for _, m in ipairs(prefixMaps) do
                if not table.HasValue(playedMaps, m) then
                    validCount = validCount + 1
                end
            end
            if validCount >= 4 then
                chosen[#chosen + 1] = prefix
            end
        end

        attempts = attempts + 1
        if attempts > 300 then
            break
        end
    end

    return chosen
end

local function getMapWeight(map)
    local pop = mapPopularity[map] or 0
    return 1 - (pop / 100)
end

function zb.StartRTV(time)
    if zb.votestarted or zb.rtvDisabled then return end

    zb.forceRTVNextRound = false
    getmaps()
    rtvtime = CurTime() + (time or 45)

    local PlayedMaps = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA"))
    end
    if not PlayedMaps then
        PlayedMaps = {}
    end

    local selectedPrefixes = getUniquePrefixes(PlayedMaps)

    if #selectedPrefixes < 3 then
        local possible = {}
        for prefix, weight in pairs(prefixWeights) do
            if weight > 0 then
                local prefixMaps = getMapsByPrefix(prefix)
                local validCount = 0
                for _, m in ipairs(prefixMaps) do
                    if not table.HasValue(PlayedMaps, m) then
                        validCount = validCount + 1
                    end
                end
                if validCount >= 4 then
                    possible[#possible + 1] = prefix
                end
            end
        end

        selectedPrefixes = {}
        table.sort(possible)
        for i = 1, 3 do
            if possible[i] then
                selectedPrefixes[#selectedPrefixes + 1] = possible[i]
            end
        end
    end

    if #selectedPrefixes < 3 then
        selectedPrefixes = { "gm", "ttt", "cs" }
    end

    local finalmaps = {}
    for _, prefix in ipairs(selectedPrefixes) do
        local prefixMaps = getMapsByPrefix(prefix)
        local validMaps = {}
        for _, m in ipairs(prefixMaps) do
            if not table.HasValue(PlayedMaps, m) then
                validMaps[#validMaps + 1] = m
            end
        end

        for _ = 1, 4 do
            if #validMaps == 0 then break end

            local totalWeight = 0
            for _, m in ipairs(validMaps) do
                totalWeight = totalWeight + getMapWeight(m)
            end

            local rnd = math.random() * totalWeight
            local selectedIndex

            for idx, m in ipairs(validMaps) do
                local weight = getMapWeight(m)
                if rnd < weight then
                    selectedIndex = idx
                    break
                end
                rnd = rnd - weight
            end

            if selectedIndex then
                finalmaps[#finalmaps + 1] = validMaps[selectedIndex]
                table.remove(validMaps, selectedIndex)
            end
        end
    end

    if #finalmaps < 12 then
        local fallbackPrefix = "gm"
        local fallbackMaps = getMapsByPrefix(fallbackPrefix)
        local filteredFallback = {}

        for _, m in ipairs(fallbackMaps) do
            if not table.HasValue(PlayedMaps, m) then
                filteredFallback[#filteredFallback + 1] = m
            end
        end

        local attempts = 0
        while #finalmaps < 12 and #filteredFallback > 0 do
            attempts = attempts + 1
            if attempts > 300 then
                break
            end

            local totalWeight = 0
            for _, m in ipairs(filteredFallback) do
                totalWeight = totalWeight + getMapWeight(m)
            end

            local rnd = math.random() * totalWeight
            local selectedIndex

            for idx, m in ipairs(filteredFallback) do
                local weight = getMapWeight(m)
                if rnd < weight then
                    selectedIndex = idx
                    break
                end
                rnd = rnd - weight
            end

            if selectedIndex then
                finalmaps[#finalmaps + 1] = filteredFallback[selectedIndex]
                table.remove(filteredFallback, selectedIndex)
            end
        end
    end

    if #finalmaps == 0 then
        local rndMap = mappull[math.random(#mappull)]
        finalmaps[#finalmaps + 1] = rndMap
    end

    finalmaps[#finalmaps + 1] = "random"

    if SERVER then
        net.Start("ZB_RockTheVote_start")
            net.WriteTable(finalmaps)
            net.WriteFloat(rtvtime)
        net.Broadcast()
    end

    zb.votestarted = true
    endStarted = false
    hook.Add("Think", "RTVThink", zb.ThinkRTV)
end

function zb.RTVMenu(ply)
    if not SERVER then return end
    if not IsValid(ply) then return end
    if zb.rtvDisabled then
        ply:ChatPrint("RTV отключен администратором.")
        return
    end
    net.Start("RTVMenu")
    net.Send(ply)
end

local rtvVotes = {}
local rtvTimeout = nil
local skipVotes = {}

local function GetSkipPlayersCount()
    local count = 0
    for _, v in ipairs(player.GetHumans()) do
        if IsValid(v) and v:Team() ~= TEAM_SPECTATOR then
            count = count + 1
        end
    end
    return math.max(count, 1)
end

function zb.ClearSkipVotes()
    skipVotes = {}
end

function zb.CheckSkipVotes(needPrint)
    if zb.ROUND_STATE ~= 1 then
        return false
    end

    local votesNeeded = math.ceil(GetSkipPlayersCount() / 2)
    local votesCount = table.Count(skipVotes)

    if votesCount >= votesNeeded then
        if needPrint then
            for _, v in ipairs(player.GetAll()) do
                v:ChatPrint("Достаточно голосов для пропуска раунда. Раунд завершается.")
            end
        end

        zb.ClearSkipVotes()

        if zb.EndRound then
            zb:EndRound()
        end

        return true
    end

    return false
end

function zb.ToggleSkipVote(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if zb.ROUND_STATE ~= 1 then
        ply:ChatPrint("Сейчас нельзя пропустить раунд.")
        return
    end

    if ply:Team() == TEAM_SPECTATOR then
        ply:ChatPrint("Наблюдатели не могут голосовать за пропуск раунда.")
        return
    end

    local steamID = ply:SteamID()

    if skipVotes[steamID] then
        skipVotes[steamID] = nil
        ply:ChatPrint("Вы отменили свой голос за пропуск раунда.")
        return
    end

    skipVotes[steamID] = true

    local votesNeeded = math.ceil(GetSkipPlayersCount() / 2)
    local votesCount = table.Count(skipVotes)
    local remaining = votesNeeded - votesCount

    if remaining > 0 then
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint(ply:Nick() .. " проголосовал за пропуск раунда. Нужно ещё " .. remaining .. " голосов. Напишите !skip ещё раз, чтобы отменить.")
        end
    end

    zb.CheckSkipVotes(true)
end


function zb.ClearRTVVotes()
    rtvVotes = {}
    if rtvTimeout then
        timer.Remove("RTVTimeout")
        rtvTimeout = nil
    end
end

function zb.StopRTV()
    table.Empty(votes)
    table.Empty(playervote)
    table.Empty(playerVoteWeight)
    zb.votestarted = false
    endStarted = false
    hook.Remove("Think", "RTVThink")
    zb.ClearRTVVotes()
end

function zb.ToggleRTV(admin)
    local name = IsValid(admin) and admin:Nick() or "Console"
    if zb.rtvDisabled then
        zb.rtvDisabled = false
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint("Администратор " .. name .. " включил rtv.")
        end
    else
        zb.rtvDisabled = true
        zb.StopRTV()
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint("Администратор " .. name .. " отключил rtv.")
        end
    end
end

function zb.CheckRTVVotes(needPrint)
    if zb.rtvDisabled then return false end

    if zb.forceRTVNextRound then
        if needPrint then
            for _, v in ipairs(player.GetAll()) do
                v:ChatPrint("Досрочное голосование активировано. RTV будет в следующем раунде.")
            end
        end
        return true
    end

    local votesNeeded = math.ceil(#player.GetAll() / 2)
    local votesCount = table.Count(rtvVotes)

    if votesCount >= votesNeeded then
        if needPrint then
            for _, v in ipairs(player.GetAll()) do
                v:ChatPrint("Достаточно голосов для смены карты. Голосование будет в следующем раунде.")
            end
        end
        return true
    end
    return false
end

function zb.ToggleRTVVote(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if zb.rtvDisabled then
        ply:ChatPrint("RTV отключен администратором.")
        return
    end

    if zb.votestarted then
        zb.RTVMenu(ply)
        return
    end

    local steamID = ply:SteamID()

    if rtvVotes[steamID] then
        rtvVotes[steamID] = nil
        ply:ChatPrint("Вы отменили свой голос за смену карты.")
        return
    end

    rtvVotes[steamID] = true

    local votesNeeded = math.ceil(#player.GetAll() / 2)
    local votesCount = table.Count(rtvVotes)
    local remaining = votesNeeded - votesCount

    for _, v in ipairs(player.GetAll()) do
        if remaining ~= 0 then
            v:ChatPrint(ply:Nick() .. " проголосовал за смену карты. Нужно ещё " .. remaining .. " голосов. Напишите !rtv ещё раз, чтобы отменить.")
        end
    end

    zb.CheckRTVVotes(true)
end

function zb.ForceRTVNextRound(ply)
    if zb.rtvDisabled then
        return false, "RTV отключен"
    end

    zb.forceRTVNextRound = true

    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint((IsValid(ply) and ply:Nick() or "Игрок") .. " купил досрочное голосование. RTV будет в следующем раунде.")
    end

    return true, "RTV будет в следующем раунде"
end

if SERVER then
    hook.Add("PlayerSay", "ZB_RTV_ChatHook", function(ply, text)
        if not IsValid(ply) then return end
        local t = string.Trim(string.lower(text or ""))

        if t == "!rtv" or t == "/rtv" then
            zb.ToggleRTVVote(ply)
            return ""
        end

        if t == "!skip" or t == "/skip" then
            zb.ToggleSkipVote(ply)
            return ""
        end

        if t == "!forcertv" or t == "/forcertv" then
            if not ply:IsAdmin() then
                ply:ChatPrint("У вас нет доступа.")
                return ""
            end
            if zb.rtvDisabled then
                ply:ChatPrint("RTV отключен администратором.")
                return ""
            end
            zb.StartRTV(20)
            return ""
        end

        if t == "!nortv" or t == "/nortv" then
            if not ply:IsSuperAdmin() then
                ply:ChatPrint("У вас нет доступа.")
                return ""
            end
            zb.ToggleRTV(ply)
            return ""
        end
    end)

    hook.Add("ShutDown", "ResetRTVVotesOnMapChange", function()
        zb.ClearRTVVotes()
        zb.ClearSkipVotes()
    end)

    hook.Add("PostGamemodeLoaded", "InitializeRTVSystem", function()
        zb.ClearRTVVotes()
        zb.ClearSkipVotes()
    end)

    hook.Add("ZB_StartRound", "ZB_ClearSkipVotesOnRoundStart", zb.ClearSkipVotes)
    hook.Add("ZB_EndRound", "ZB_ClearSkipVotesOnRoundEnd", zb.ClearSkipVotes)

    hook.Add("PlayerDisconnected", "CheckRTVAfterDisconnect", function(ply)
        local sid = ply:SteamID()
        if rtvVotes[sid] then
            rtvVotes[sid] = nil
            timer.Simple(0.1, function() zb.CheckRTVVotes(false) end)
        end
        if skipVotes[sid] then
            skipVotes[sid] = nil
            timer.Simple(0.1, function() zb.CheckSkipVotes(false) end)
        end
    end)
end