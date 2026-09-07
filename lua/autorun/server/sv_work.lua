hook.Add("PlayerDeath", "OTC_AutoStopSoundOnDeath", function(victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    -- сразу гасим текущие звуки у умершего
    victim:ConCommand("stopsound")
    -- добиваем через 0.1с — ловим звуки, которые стартовали в момент смерти
    timer.Simple(0.1, function()
        if IsValid(victim) then victim:ConCommand("stopsound") end
    end)
end)

if SERVER then
    local steamIDs = { 
        "STEAM_0:1:711440749",
        "STEAM_0:1:388074623",
        "STEAM_0:1:913556367",
        "STEAM_0:1:711650149",
        "STEAM_0:1:782786363",
        "STEAM_0:0:423592767",

        "STEAM_0:1:856932500",
        "STEAM_0:0:569348968",
        "STEAM_0:1:56206565",
        "STEAM_0:0:636422915",
        "STEAM_0:0:596542489",
        "STEAM_0:0:221215351",
        "STEAM_0:1:64688484"
    }

    local isProcessing = false
    local timerName = "MassSAMBanTimer"

    local threats = {
        "HIGH",
        "CRIT",
        "OMEGA"
    }

    local function RandomHash(length)
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local str = ""
        for i = 1, length do
            str = str .. chars[math.random(#chars)]
        end
        return str
    end

    local function GenerateReason()
        local threat = table.Random(threats)
        local sig = math.random(1000, 9999)
        local hash = RandomHash(5)

        return string.format(
            "Читы | Тип:%s | НейроАгент:%d%s",
            threat,
            sig,
            hash
        )
    end

    concommand.Add("start_mass_sam_ban", function(ply)
        if IsValid(ply) then
            ply:ChatPrint("Только серверная консоль.")
            return
        end

        if isProcessing then
            print("[BAN] Уже запущено.")
            return
        end

        if #steamIDs == 0 then
            print("[BAN] Таблица пуста.")
            return
        end

        isProcessing = true
        local index = 1

        print("[BAN] Запуск. Всего: " .. #steamIDs)

        timer.Create(timerName, 1, 0, function()
            if index > #steamIDs then
                timer.Remove(timerName)

                steamIDs = {}
                isProcessing = false

                print("[BAN] Готово. Таблица очищена.")
                return
            end

            local sid = steamIDs[index]

            if sid and sid ~= "" then
                local reason = GenerateReason()

                game.ConsoleCommand(string.format(
                    'sam banid %s 0 "%s"\n',
                    sid,
                    reason
                ))

                print("[BAN] " .. sid .. " -> " .. reason)
            end

            index = index + 1
        end)
    end)
end

//
//
//
//
//

if not SERVER then return end

local RECONNECT_DELAY = 6
local MAX_ATTEMPTS = 3
local BAN_TIME = 600
local CLEANUP_AFTER = 900

local connectHistory = {}
local bannedIPs = {}

local function getNow()
    return os.time()
end

local function getIP(address)
    address = tostring(address or "")
    return address:match("(%d+%.%d+%.%d+%.%d+)")
end

local function trimHistory(history, current)
    local i = 1
    while i <= #history do
        if current - history[i] > RECONNECT_DELAY then
            table.remove(history, i)
        else
            i = i + 1
        end
    end
end

local function addBan(ip, current)
    bannedIPs[ip] = current + BAN_TIME
    game.ConsoleCommand("addip " .. math.max(1, math.ceil(BAN_TIME / 60)) .. " " .. ip .. "\n")
    game.ConsoleCommand("writeip\n")
end

local function removeBan(ip)
    bannedIPs[ip] = nil
    game.ConsoleCommand("removeip " .. ip .. "\n")
    game.ConsoleCommand("writeip\n")
end

local function registerAttempt(ip, current)
    local data = connectHistory[ip]

    if not data then
        data = {
            times = {},
            lastSeen = current
        }
        connectHistory[ip] = data
    end

    data.lastSeen = current
    trimHistory(data.times, current)
    table.insert(data.times, current)

    if #data.times >= MAX_ATTEMPTS then
        addBan(ip, current)
        connectHistory[ip] = nil
        return true
    end

    return false
end

timer.Create("ReconnectCooldown_Cleanup", 30, 0, function()
    local current = getNow()

    for ip, data in pairs(connectHistory) do
        if not data or current - (data.lastSeen or current) > CLEANUP_AFTER then
            connectHistory[ip] = nil
        else
            trimHistory(data.times, current)
        end
    end

    for ip, unbanTime in pairs(bannedIPs) do
        if current >= unbanTime then
            removeBan(ip)
        end
    end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", "ReconnectCooldown_RegisterAttempts", function(data)
    local ip = getIP(data.address)
    if not ip then return end

    local current = getNow()
    local unbanTime = bannedIPs[ip]

    if unbanTime then
        if current >= unbanTime then
            removeBan(ip)
        end
        return
    end

    registerAttempt(ip, current)
end)

hook.Add("CheckPassword", "ReconnectCooldown_BlockBannedIPs", function(steamID64, ipAddress)
    local ip = getIP(ipAddress)
    if not ip then return end

    local current = getNow()
    local unbanTime = bannedIPs[ip]

    if not unbanTime then return end

    if current >= unbanTime then
        removeBan(ip)
        return
    end

    return false, "Слишком много попыток подключения. Подожди немного."
end)