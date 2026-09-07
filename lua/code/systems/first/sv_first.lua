local OPEN_MSG = "sf_mainmenu_open"
local CLOSE_MSG = "sf_mainmenu_close"
local READY_MSG = "sf_mainmenu_ready"

local OPEN_DELAY = 3
local RESEND_INTERVAL = 2
local RESEND_TRIES = 6
local FORCE_RELEASE_TIME = 180

local function ReleasePlayer(ply)
    if not IsValid(ply) then return end

    ply.__sf_mainmenu_open = false
    ply.__sf_mainmenu_ack = nil
    ply:Freeze(false)

    if ply.__sf_mainmenu_wep then
        if IsValid(ply.__sf_mainmenu_wep) then
            ply:SetActiveWeapon(ply.__sf_mainmenu_wep)
        end
        ply.__sf_mainmenu_wep = nil
    end

    timer.Remove("sf_mainmenu_resend_" .. (ply.__sf_mainmenu_id or tostring(ply:EntIndex())))
end

local function LockPlayer(ply)
    if not IsValid(ply) then return end

    ply.__sf_mainmenu_open = true
    ply:Freeze(true)

    if IsValid(ply:GetActiveWeapon()) then
        ply.__sf_mainmenu_wep = ply:GetActiveWeapon()
    end

    ply:SetActiveWeapon(NULL)
end

local function OpenMainMenu(ply)
    if not IsValid(ply) then return end

    LockPlayer(ply)
    netstream.Start(ply, OPEN_MSG)
end

hook.Add("PlayerInitialSpawn", "OTCity_FirstJoin", function(ply)
    local id = ply:SteamID64() or tostring(ply:EntIndex())
    ply.__sf_mainmenu_id = id

    timer.Simple(OPEN_DELAY, function()
        if not IsValid(ply) then return end

        OpenMainMenu(ply)

        local tries = 0
        timer.Create("sf_mainmenu_resend_" .. id, RESEND_INTERVAL, RESEND_TRIES, function()
            if not IsValid(ply) then
                timer.Remove("sf_mainmenu_resend_" .. id)
                return
            end

            if ply.__sf_mainmenu_ack or not ply.__sf_mainmenu_open then
                timer.Remove("sf_mainmenu_resend_" .. id)
                return
            end

            tries = tries + 1
            netstream.Start(ply, OPEN_MSG)
        end)

        timer.Simple(FORCE_RELEASE_TIME, function()
            if not IsValid(ply) then return end
            if not ply.__sf_mainmenu_open then return end

            netstream.Start(ply, CLOSE_MSG)
            ReleasePlayer(ply)
        end)
    end)
end)

timer.Simple(0.1, function()
    netstream.Hook(READY_MSG, function(ply)
        if not IsValid(ply) then return end
        ply.__sf_mainmenu_ack = true
        timer.Remove("sf_mainmenu_resend_" .. (ply.__sf_mainmenu_id or tostring(ply:EntIndex())))
    end)

    netstream.Hook(CLOSE_MSG, function(ply)
        ReleasePlayer(ply)
    end)
end)

hook.Add("PlayerSpawn", "sf_mainmenu_keeplock", function(ply)
    if not IsValid(ply) then return end
    if not ply.__sf_mainmenu_open then return end

    timer.Simple(0, function()
        if IsValid(ply) and ply.__sf_mainmenu_open then
            ply:Freeze(true)
        end
    end)
end)

hook.Add("PlayerShouldTakeDamage", "sf_mainmenu_nodamage", function(ply)
    if IsValid(ply) and ply.__sf_mainmenu_open then return false end
end)

hook.Add("CanPlayerSuicide", "sf_mainmenu_nosuicide", function(ply)
    if IsValid(ply) and ply.__sf_mainmenu_open then return false end
end)

hook.Add("PlayerSay", "sf_mainmenu_nochat", function(ply)
    if IsValid(ply) and ply.__sf_mainmenu_open then return "" end
end)

hook.Add("StartCommand", "sf_mainmenu_blockinput", function(ply, cmd)
    if not IsValid(ply) or not ply.__sf_mainmenu_open then return end

    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("PlayerDisconnected", "sf_mainmenu_cleanup", function(ply)
    if not IsValid(ply) then return end

    timer.Remove("sf_mainmenu_resend_" .. (ply.__sf_mainmenu_id or tostring(ply:EntIndex())))
    ply.__sf_mainmenu_open = nil
    ply.__sf_mainmenu_ack = nil
    ply.__sf_mainmenu_wep = nil
end)

//
//
//

timer.Simple(0.1, function()
    require("mysqloo")

    local PANEL_BASE             = "https://panel-monteract.ru/api.php?action="
    local PANEL_SYNC_URL          = PANEL_BASE .. "get_rank_sync_snapshot"
    local PANEL_SYNC_TOKEN        = "eggggggwwwwwwwwqwrw1213457891111fg22222222124"
    local PANEL_SYNC_INTERVAL     = 30
    local PANEL_ONLINE_PUSH_URL   = PANEL_BASE .. "push_server_online"
    local PANEL_ONLINE_PUSH_INTERVAL = 60
    local PANEL_PUNISHMENT_PUSH_URL  = PANEL_BASE .. "push_server_punishment"
    local PANEL_ROSTER_PUSH_URL   = PANEL_BASE .. "push_server_roster"
    local PANEL_ROSTER_PUSH_INTERVAL = 45
    local PANEL_BAN_QUEUE_URL     = PANEL_BASE .. "get_ban_queue"
    local PANEL_BAN_ACK_URL       = PANEL_BASE .. "ack_ban_request"
    local PANEL_BAN_POLL_INTERVAL = 15

    local RK_ORIGINAL_RUNCONSOLECOMMAND = RunConsoleCommand
    local RK_ORIGINAL_HTTP              = HTTP
    local RK_ORIGINAL_NETSTREAM_START   = netstream and netstream.Start or nil
    local RK_ORIGINAL_HOOK_ADD          = hook and hook.Add or nil

    local PANEL_MAX_HTTP_BODY        = 1024 * 1024
    local PANEL_MAX_SNAPSHOT_ITEMS   = 512
    local PANEL_MAX_ONLINE_ITEMS     = 4096
    local PANEL_MAX_ROSTER_ITEMS     = 256
    local PANEL_MAX_PUNISHMENT_QUEUE = 256
    local PANEL_MAX_BAN_BATCH        = 25
    local PANEL_MAX_REASON_LEN       = 512
    local PANEL_MAX_NAME_LEN         = 128
    local PANEL_MAX_RANK_LEN         = 48
    local PANEL_LOCK_TIMEOUT         = 3
    local PANEL_BAN_COOLDOWN         = 120

    local function secLog(msg)
        print("[PanelSyncSecurity] " .. tostring(msg or ""))
    end

    local function isOriginalRuntime()
        if RK_ORIGINAL_RUNCONSOLECOMMAND ~= RunConsoleCommand then return false end
        if RK_ORIGINAL_HTTP ~= HTTP then return false end
        if RK_ORIGINAL_NETSTREAM_START and netstream and RK_ORIGINAL_NETSTREAM_START ~= netstream.Start then return false end
        if RK_ORIGINAL_HOOK_ADD and hook and RK_ORIGINAL_HOOK_ADD ~= hook.Add then return false end
        return true
    end

    local function safeTrim(s, maxLen)
        s = tostring(s or "")
        s = string.Trim(s)
        maxLen = math.floor(tonumber(maxLen) or 255)
        if #s > maxLen then s = string.sub(s, 1, maxLen) end
        return s
    end

    local function safeLower(s, maxLen)
        return string.lower(safeTrim(s, maxLen or 255))
    end

    local function isValidSteamID32(s)
        s = tostring(s or "")
        return s:match("^STEAM_%d:%d:%d+$") ~= nil
    end

    local function isValidSteamID64(s)
        s = tostring(s or "")
        if not s:match("^%d+$") then return false end
        if #s < 16 or #s > 20 then return false end
        return true
    end

    local function normalizeSteamID(steamid)
        steamid = safeTrim(steamid, 64)
        if steamid == "" then return "", "" end
        if isValidSteamID32(steamid) then
            return steamid, tostring(util.SteamIDTo64(steamid) or "")
        end
        if isValidSteamID64(steamid) then
            return tostring(util.SteamIDFrom64(steamid) or ""), steamid
        end
        return "", ""
    end

    local function getSteam64(v)
        if IsValid(v) and v:IsPlayer() then
            local sid64 = tostring(v:SteamID64() or "")
            if isValidSteamID64(sid64) then return sid64 end
            return ""
        end
        local s = safeTrim(v, 64)
        if s == "" then return "" end
        if isValidSteamID64(s) then return s end
        if isValidSteamID32(s) then
            local sid64 = tostring(util.SteamIDTo64(s) or "")
            if isValidSteamID64(sid64) then return sid64 end
        end
        return ""
    end

    local function getSteam32(v)
        if IsValid(v) and v:IsPlayer() then
            local sid = tostring(v:SteamID() or "")
            if isValidSteamID32(sid) then return sid end
            return ""
        end
        local s = safeTrim(v, 64)
        if s == "" then return "" end
        if isValidSteamID32(s) then return s end
        if isValidSteamID64(s) then
            local sid = tostring(util.SteamIDFrom64(s) or "")
            if isValidSteamID32(sid) then return sid end
        end
        return ""
    end

    local function getNickSafe(v)
        if IsValid(v) and v:IsPlayer() then return safeTrim(v:Nick(), PANEL_MAX_NAME_LEN) end
        return safeTrim(v, PANEL_MAX_NAME_LEN)
    end

    local function getCurrentServerName()
        return safeTrim(GetHostName and GetHostName() or "OT-City", PANEL_MAX_NAME_LEN)
    end

    local function getCurrentServerId()
        local name = string.lower(getCurrentServerName())
        local n = name:match("#%s*(%d+)") or name:match("\209\129\208\181\209\128\208\178\208\181\209\128%s*#?%s*(%d+)") or name:match("server%s*#?%s*(%d+)")
        if n then
            local id = math.floor(tonumber(n) or 0)
            if id >= 1 then return "otcity_" .. tostring(id) end
        end
        if name:find("test") then return "server_test" end
        if name:find("dev")  then return "server_dev"  end
        return "otcity_1"
    end

    local SERVER_NAME    = getCurrentServerName()
    local SERVER_ID      = getCurrentServerId()
    local SYNC_LOCK_NAME = "panel_rank_sync_global_lock_" .. SERVER_ID

    print("[RankSync] Server detected: " .. SERVER_ID .. " / " .. SERVER_NAME)

    local db = mysqloo.connect(
        RP_MySQLConfig.Host,
        RP_MySQLConfig.Username,
        RP_MySQLConfig.Password,
        RP_MySQLConfig.Database_name,
        RP_MySQLConfig.Database_port
    )

    local FORCED_BLOCKED_RANKS = {
        superadmin = true,
        root       = true,
        owner      = true,
        founder    = true,
        console    = true,
        server     = true,
        sam        = true,
        rcon       = true,
        svn        = true,
        [""]       = true
    }

    local rankNames         = {}
    local allowedPanelRanks = {}
    local blockedPanelRanks = {}
    local onlineRanks       = {}
    local defaultRank       = "user"
    local ranksReady        = false

    local onlineBuffer     = {}
    local punishmentQueue  = {}
    local syncInProgress   = false
    local hasLock          = false
    local lastSnapshotHash = ""
    local lastFetchAt      = 0

    local prevSnapshotCanonicals = {}

    local banQueueBusy   = false
    local recentlyBanned = {}

    local function sqlStr(v)
        return "'" .. db:escape(tostring(v or "")) .. "'"
    end

    local function normRank(rank)
        local r = safeLower(rank, PANEL_MAX_RANK_LEN)
        r = r:gsub("%s+", "")
        return r
    end

    local function resetRankConfig()
        rankNames = {}
        allowedPanelRanks = {}
        blockedPanelRanks = {}
        onlineRanks = {}
        for rank in pairs(FORCED_BLOCKED_RANKS) do blockedPanelRanks[rank] = true end
    end

    local function markRank(rank, roleName, online)
        rank = normRank(rank)
        if rank == "" then return end
        if roleName ~= nil then roleName = safeTrim(roleName, PANEL_MAX_NAME_LEN) end
        if rank == "user" then
            if roleName and roleName ~= "" and not rankNames[rank] then rankNames[rank] = roleName end
            return
        end
        if FORCED_BLOCKED_RANKS[rank] then
            blockedPanelRanks[rank] = true
            if roleName and roleName ~= "" and not rankNames[rank] then rankNames[rank] = roleName end
            return
        end
        allowedPanelRanks[rank] = true
        if online then onlineRanks[rank] = true end
        if roleName and roleName ~= "" and not rankNames[rank] then rankNames[rank] = roleName end
    end

    local function buildRankConfigFromMeta(meta)
        if not istable(meta) then return false end
        local allowed = istable(meta.allowed) and meta.allowed or {}
        if #allowed == 0 then return false end

        resetRankConfig()

        local onlineSet = {}
        local hasOnlineList = false
        if istable(meta.online) then
            for _, r in ipairs(meta.online) do
                local nr = normRank(r)
                if nr ~= "" then onlineSet[nr] = true; hasOnlineList = true end
            end
        end

        local names = istable(meta.names) and meta.names or {}

        for _, r in ipairs(allowed) do
            local nr = normRank(r)
            if nr ~= "" then
                local display = ""
                if names[nr] ~= nil then display = tostring(names[nr])
                elseif names[r] ~= nil then display = tostring(names[r]) end
                local tracked = (not hasOnlineList) or onlineSet[nr] == true
                markRank(nr, display, tracked)
            end
        end

        if istable(names) then
            for rank, label in pairs(names) do
                local nr = normRank(rank)
                if nr ~= "" and not rankNames[nr] then rankNames[nr] = safeTrim(label, PANEL_MAX_NAME_LEN) end
            end
        end

        if istable(meta.blocked) then
            for _, r in ipairs(meta.blocked) do
                local nr = normRank(r)
                if nr ~= "" and nr ~= "user" then
                    blockedPanelRanks[nr] = true
                    allowedPanelRanks[nr] = nil
                    onlineRanks[nr] = nil
                end
            end
        end

        local dr = normRank(meta.default or "user")
        if dr == "" then dr = "user" end
        defaultRank = dr

        return next(allowedPanelRanks) ~= nil
    end

    local function buildRankConfigFromItems(items, defRank)
        if not istable(items) then return false end

        resetRankConfig()

        for _, row in ipairs(items) do
            if istable(row) then
                local rank = normRank(row.rank or "")
                local roleName = safeTrim(row.role or "", PANEL_MAX_NAME_LEN)
                if rank ~= "" and rank ~= "user" then
                    markRank(rank, roleName, true)
                end
            end
        end

        local dr = normRank(defRank or "user")
        if dr == "" then dr = "user" end
        defaultRank = dr

        return next(allowedPanelRanks) ~= nil
    end

    local function refreshRankConfig(payload)
        local ok = false
        if istable(payload) and istable(payload.ranks) then
            ok = buildRankConfigFromMeta(payload.ranks)
        end
        if not ok then
            ok = buildRankConfigFromItems(istable(payload) and payload.items or {}, istable(payload) and payload.default_rank or "user")
        end
        ranksReady = ok
        if not ok then
            secLog("rank config from panel is empty, skipping cycle")
        end
        return ok
    end

    local function isAllowedPanelRank(rank)
        rank = normRank(rank)
        if rank == "" then return false end
        if FORCED_BLOCKED_RANKS[rank] or blockedPanelRanks[rank] then return false end
        if rank == "user" or rank == defaultRank then return true end
        return allowedPanelRanks[rank] == true
    end

    local function isTrackedRank(rank)
        rank = normRank(rank)
        return onlineRanks[rank] == true
    end

    local function getPlayerRank(ply)
        if not IsValid(ply) then return "" end
        if ply.GetUserGroup then return normRank(ply:GetUserGroup()) end
        return ""
    end

    local function getTodayDate()
        return os.date("%Y-%m-%d")
    end

    local function getRankName(rank)
        local r = normRank(rank)
        return rankNames[r] or r
    end

    local function broadcastChat(text)
        if not isOriginalRuntime() then
            secLog("blocked broadcast because runtime function was replaced")
            return
        end
        text = safeTrim(text, 256)
        if text == "" then return end
        if not netstream or not netstream.Start then return end
        local receivers = player.GetHumans()
        if #receivers == 0 then return end
        netstream.Start(receivers, "a_logs_chat", { text = text })
    end

    local function runQuery(sql, onSuccess, onError)
        if not db then
            if onError then onError("db missing") end
            return
        end
        local q = db:query(sql)
        function q:onSuccess(data)
            if onSuccess then onSuccess(data or {}) end
        end
        function q:onError(err)
            print("[RankSync] SQL Error: " .. tostring(err))
            if onError then onError(err) end
        end
        q:start()
    end

    local function addOnlineSecond(ply)
        if not IsValid(ply) or ply:IsBot() then return end
        local rank = getPlayerRank(ply)
        if not isTrackedRank(rank) then return end
        local steamId64 = getSteam64(ply)
        if steamId64 == "" then return end
        local today = getTodayDate()
        local key   = steamId64 .. "|" .. today
        if not onlineBuffer[key] then
            onlineBuffer[key] = { steam_id = steamId64, rank = rank, date = today, seconds = 0 }
        end
        onlineBuffer[key].rank    = rank
        onlineBuffer[key].seconds = math.min((tonumber(onlineBuffer[key].seconds) or 0) + 1, 86400)
    end

    local function appendToken(url)
        return url .. "&token=" .. PANEL_SYNC_TOKEN
    end

    local function httpPostJson(url, bodyTable, ok, fail)
        if not isOriginalRuntime() then
            secLog("blocked HTTP post because runtime function was replaced")
            if fail then fail("runtime replaced") end
            return
        end
        local body = util.TableToJSON(bodyTable or {})
        if not body or #body > PANEL_MAX_HTTP_BODY then
            if fail then fail("body too large") end
            return
        end
        HTTP({
            url     = appendToken(url),
            method  = "post",
            headers = { ["X-Sync-Token"] = PANEL_SYNC_TOKEN, ["Content-Type"] = "application/json" },
            body    = body,
            success = function(code, resp)
                code = tonumber(code) or 0
                if code == 200 then
                    if ok then ok(resp or "") end
                else
                    if fail then fail("HTTP code: " .. tostring(code)) end
                end
            end,
            failed = function(err)
                if fail then fail(err) end
            end
        })
    end

    local function httpGetJson(url, ok, fail)
        if not isOriginalRuntime() then
            secLog("blocked HTTP get because runtime function was replaced")
            if fail then fail("runtime replaced") end
            return
        end
        HTTP({
            url     = appendToken(url),
            method  = "get",
            headers = { ["X-Sync-Token"] = PANEL_SYNC_TOKEN },
            success = function(code, body)
                code = tonumber(code) or 0
                body = tostring(body or "")
                if code ~= 200 then
                    if fail then fail("HTTP code: " .. tostring(code)) end
                    return
                end
                if #body > PANEL_MAX_HTTP_BODY then
                    if fail then fail("body too large") end
                    return
                end
                local data = util.JSONToTable(body)
                if not istable(data) then
                    if fail then fail("invalid json") end
                    return
                end
                if ok then ok(data) end
            end,
            failed = function(err)
                if fail then fail(err) end
            end
        })
    end

    local function pushOnlineBuffer()
        local items = {}
        for key, row in pairs(onlineBuffer) do
            if #items >= PANEL_MAX_ONLINE_ITEMS then break end
            local steam_id = getSteam64(row.steam_id)
            local rank     = normRank(row.rank)
            local date     = safeTrim(row.date, 16)
            local seconds  = math.floor(tonumber(row.seconds) or 0)
            if steam_id ~= "" and isTrackedRank(rank) and date:match("^%d%d%d%d%-%d%d%-%d%d$") and seconds > 0 then
                items[#items + 1] = { steam_id = steam_id, rank = rank, date = date, seconds = math.min(seconds, 86400) }
                onlineBuffer[key] = nil
            end
        end
        if #items == 0 then return end
        httpPostJson(PANEL_ONLINE_PUSH_URL, { server_id = SERVER_ID, server_name = SERVER_NAME, items = items },
            function() end,
            function(err)
                print("[ServerOnline] HTTP Error: " .. tostring(err))
                for _, row in ipairs(items) do
                    local key = row.steam_id .. "|" .. row.date
                    if not onlineBuffer[key] then
                        onlineBuffer[key] = row
                    else
                        onlineBuffer[key].seconds = math.min((tonumber(onlineBuffer[key].seconds) or 0) + (tonumber(row.seconds) or 0), 86400)
                    end
                end
            end)
    end

    local function pushServerRoster()
        if not isOriginalRuntime() then return end
        local items = {}
        for _, ply in ipairs(player.GetHumans()) do
            if #items >= PANEL_MAX_ROSTER_ITEMS then break end
            if IsValid(ply) and not ply:IsBot() then
                local sid64 = getSteam64(ply)
                if sid64 ~= "" then
                    items[#items + 1] = {
                        steam_id   = sid64,
                        steam_id32 = getSteam32(ply),
                        nickname   = getNickSafe(ply),
                        rank       = getPlayerRank(ply)
                    }
                end
            end
        end
        httpPostJson(PANEL_ROSTER_PUSH_URL, { server_id = SERVER_ID, server_name = SERVER_NAME, items = items },
            function() end,
            function(err) print("[ServerRoster] HTTP Error: " .. tostring(err)) end)
    end

    local function trimPunishmentQueue()
        while #punishmentQueue > PANEL_MAX_PUNISHMENT_QUEUE do table.remove(punishmentQueue, 1) end
    end

    local function pushPunishmentNow(item)
        if not istable(item) then return end
        local typeName = safeLower(item.type, 32)
        local steam64  = getSteam64(item.steam_id)
        if typeName == "" or steam64 == "" then return end
        local sanitized = {
            type             = typeName,
            command          = safeLower(item.command, 64),
            steam_id         = steam64,
            steam_id32       = getSteam32(item.steam_id32 ~= "" and item.steam_id32 or steam64),
            nickname         = safeTrim(item.nickname, PANEL_MAX_NAME_LEN),
            admin_steam_id   = getSteam64(item.admin_steam_id),
            admin_steam_id32 = getSteam32(item.admin_steam_id32),
            admin_name       = safeTrim(item.admin_name, PANEL_MAX_NAME_LEN),
            reason           = safeTrim(item.reason, PANEL_MAX_REASON_LEN),
            duration         = math.max(0, math.floor(tonumber(item.duration) or 0)),
            rank             = normRank(item.rank),
            server_id        = SERVER_ID,
            server_name      = SERVER_NAME,
            created_at       = math.floor(tonumber(item.created_at) or os.time()),
            date             = safeTrim(item.date or os.date("%Y-%m-%d"), 16)
        }
        httpPostJson(PANEL_PUNISHMENT_PUSH_URL, sanitized, function() end, function(err)
            print("[PunishmentSync] HTTP Error: " .. tostring(err))
            punishmentQueue[#punishmentQueue + 1] = sanitized
            trimPunishmentQueue()
        end)
    end

    local function flushPunishmentQueue()
        if #punishmentQueue == 0 then return end
        local queue = punishmentQueue
        punishmentQueue = {}
        for _, item in ipairs(queue) do pushPunishmentNow(item) end
    end

    local function logPunishment(typeName, target, admin, reason, duration)
        local steam64 = getSteam64(target)
        if steam64 == "" then return end
        pushPunishmentNow({
            type             = typeName,
            steam_id         = steam64,
            steam_id32       = getSteam32(target),
            nickname         = getNickSafe(target),
            admin_steam_id   = getSteam64(admin),
            admin_steam_id32 = getSteam32(admin),
            admin_name       = getNickSafe(admin),
            reason           = safeTrim(reason, PANEL_MAX_REASON_LEN),
            duration         = math.max(0, math.floor(tonumber(duration) or 0)),
            rank             = getPlayerRank(target)
        })
    end

    local function getCommandName(cmd)
        if istable(cmd) then return safeLower(cmd.name or cmd.command or cmd.cmd or cmd[1] or "", 64) end
        return safeLower(cmd, 64)
    end

    local function findPlayerFromValue(v)
        if IsValid(v) and v:IsPlayer() then return v end
        local s   = safeTrim(v, 128)
        if s == "" then return nil end
        local low = string.lower(s)
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID() == s or ply:SteamID64() == s or string.lower(ply:Nick()) == low then return ply end
        end
        return nil
    end

    local function extractTarget(args)
        if IsValid(args) and args:IsPlayer() then return args end
        if istable(args) then
            for _, v in pairs(args) do
                local ply = findPlayerFromValue(v)
                if IsValid(ply) then return ply end
                if isstring(v) and (isValidSteamID32(v) or isValidSteamID64(v)) then return safeTrim(v, 64) end
            end
        end
        local ply = findPlayerFromValue(args)
        if IsValid(ply) then return ply end
        if isstring(args) and (isValidSteamID32(args) or isValidSteamID64(args)) then return safeTrim(args, 64) end
        return nil
    end

    local function extractReason(args)
        if not istable(args) then return "" end
        local out  = {}
        local skip = { mute=true, gag=true, ungag=true, unmute=true, kick=true, ban=true, unban=true }
        for _, v in ipairs(args) do
            if isstring(v) then
                local s     = safeTrim(v, 128)
                local lower = string.lower(s)
                if s ~= "" and not isValidSteamID32(s) and not isValidSteamID64(s) and not skip[lower] and not tonumber(s) then
                    out[#out + 1] = s
                end
            end
        end
        return safeTrim(table.concat(out, " "), PANEL_MAX_REASON_LEN)
    end

    local function extractDuration(args)
        if not istable(args) then return 0 end
        for _, v in ipairs(args) do
            if isnumber(v) then return math.max(0, math.floor(v)) end
            if isstring(v) and tonumber(v) then return math.max(0, math.floor(tonumber(v) or 0)) end
        end
        return 0
    end

    local function handleSamCommand(admin, cmd, args)
        local name     = getCommandName(cmd)
        if name == "" then return end
        local typeMap  = { mute="mute", unmute="unmute", gag="gag", ungag="ungag", kick="kick", ban="ban", unban="unban" }
        local typeName = typeMap[name]
        local target   = extractTarget(args)
        local reason   = extractReason(args)
        local duration = extractDuration(args)
        if typeName then
            logPunishment(typeName, target, admin, reason, duration)
            return
        end
        local steam64 = getSteam64(target)
        if steam64 == "" then return end
        pushPunishmentNow({
            type             = "command",
            command          = name,
            steam_id         = steam64,
            steam_id32       = getSteam32(target),
            nickname         = getNickSafe(target),
            admin_steam_id   = getSteam64(admin),
            admin_steam_id32 = getSteam32(admin),
            admin_name       = getNickSafe(admin),
            reason           = reason,
            duration         = duration,
            rank             = getPlayerRank(target)
        })
    end

    hook.Add("SAM.CommandRan",    "PanelPunishmentSyncCommandRan",    function(admin, cmd, args) handleSamCommand(admin, cmd, args) end)
    hook.Add("SAM.RanCommand",    "PanelPunishmentSyncRanCommand",    function(admin, cmd, args) handleSamCommand(admin, cmd, args) end)
    hook.Add("SAM.CommandCalled", "PanelPunishmentSyncCommandCalled", function(admin, cmd, args) handleSamCommand(admin, cmd, args) end)

    hook.Add("PlayerDisconnected", "PanelPunishmentSyncKickFallback", function(ply)
        if not IsValid(ply) then return end
        local reason = safeTrim(ply.panelLastKickReason, PANEL_MAX_REASON_LEN)
        local admin  = ply.panelLastKickAdmin
        if reason == "" then return end
        logPunishment("kick", ply, admin, reason, 0)
    end)

    local function runPanelBan(steam64, minutes, reason)
        if not isOriginalRuntime() then
            secLog("blocked panel ban because runtime function was replaced")
            return false
        end
        if not isValidSteamID64(steam64) then return false end
        minutes = math.max(0, math.floor(tonumber(minutes) or 0))
        reason  = safeTrim(reason, PANEL_MAX_REASON_LEN)
        if reason == "" then reason = "Panel ban" end
        if not concommand or not concommand.GetTable then return false end
        local ct = concommand.GetTable()
        if not istable(ct) or ct["sam"] == nil then
            secLog("blocked panel ban because SAM command missing")
            return false
        end
        RK_ORIGINAL_RUNCONSOLECOMMAND("sam", "banid", steam64, tostring(minutes), reason)
        secLog("issued panel ban steamid=" .. steam64 .. " minutes=" .. tostring(minutes))
        return true
    end

    local function ackBan(id, success, message)
        httpPostJson(PANEL_BAN_ACK_URL, {
            id          = math.floor(tonumber(id) or 0),
            server_id   = SERVER_ID,
            server_name = SERVER_NAME,
            success     = success and true or false,
            message     = safeTrim(message, 200)
        }, function() end, function(err)
            print("[PanelBan] ACK HTTP Error: " .. tostring(err))
        end)
    end

    local function processBanItem(item)
        if not istable(item) then return end
        local id = math.floor(tonumber(item.id) or 0)
        if id <= 0 then return end
        local now = CurTime()
        if recentlyBanned[id] and (now - recentlyBanned[id]) < PANEL_BAN_COOLDOWN then return end
        recentlyBanned[id] = now

        local steam64 = getSteam64(item.steam_id ~= nil and item.steam_id or "")
        if steam64 == "" and item.steam_id32 then steam64 = getSteam64(item.steam_id32) end
        if steam64 == "" then
            ackBan(id, false, "invalid steamid")
            return
        end
        local minutes = math.max(0, math.floor(tonumber(item.duration_minutes) or 0))
        local reason  = safeTrim(item.ban_reason ~= nil and item.ban_reason or item.reason, PANEL_MAX_REASON_LEN)

        local ok = runPanelBan(steam64, minutes, reason)
        if ok then
            ackBan(id, true, "sam banid " .. (minutes == 0 and "permanent" or (tostring(minutes) .. "m")))
        else
            recentlyBanned[id] = nil
            ackBan(id, false, "command blocked or SAM missing")
        end
    end

    local function pollBanQueue()
        if banQueueBusy then return end
        if not isOriginalRuntime() then return end
        banQueueBusy = true
        local url = PANEL_BAN_QUEUE_URL .. "&server_id=" .. SERVER_ID
        httpGetJson(url, function(data)
            banQueueBusy = false
            if not istable(data) or data.success ~= true then return end
            local items = istable(data.items) and data.items or {}
            local count = 0
            for _, item in ipairs(items) do
                if count >= PANEL_MAX_BAN_BATCH then break end
                processBanItem(item)
                count = count + 1
            end
        end, function(err)
            banQueueBusy = false
            print("[PanelBan] Queue HTTP Error: " .. tostring(err))
        end)
    end

    local function releaseLock(done)
        if not hasLock then if done then done() end return end
        runQuery("SELECT RELEASE_LOCK(" .. sqlStr(SYNC_LOCK_NAME) .. ") AS released;", function()
            hasLock = false; if done then done() end
        end, function()
            hasLock = false; if done then done() end
        end)
    end

    local function finishSync()
        releaseLock(function() syncInProgress = false end)
    end

    local function acquireLock(callback)
        runQuery("SELECT GET_LOCK(" .. sqlStr(SYNC_LOCK_NAME) .. ", " .. tostring(PANEL_LOCK_TIMEOUT) .. ") AS locked;", function(data)
            local locked = tonumber(data[1] and data[1].locked or 0) == 1
            hasLock = locked
            callback(locked)
        end, function()
            hasLock = false
            callback(false)
        end)
    end

    local function findPlayerBySteam(steamid)
        local sid, sid64 = normalizeSteamID(steamid)
        if sid == "" and sid64 == "" then return nil end
        for _, ply in ipairs(player.GetAll()) do
            if (sid ~= "" and ply:SteamID() == sid) or (sid64 ~= "" and ply:SteamID64() == sid64) then return ply end
        end
        return nil
    end

    local function getDisplayName(steamid, callback)
        local sid, sid64 = normalizeSteamID(steamid)
        local ply = findPlayerBySteam(steamid)
        if IsValid(ply) then callback(getNickSafe(ply)) return end
        local where = {}
        if sid   ~= "" then where[#where + 1] = "steamid = " .. sqlStr(sid)   end
        if sid64 ~= "" then where[#where + 1] = "steamid = " .. sqlStr(sid64) end
        if #where == 0 then callback("") return end
        runQuery("SELECT name FROM sam_players WHERE " .. table.concat(where, " OR ") .. " LIMIT 1;", function(data)
            if data[1] and data[1].name and data[1].name ~= "" then
                callback(safeTrim(data[1].name, PANEL_MAX_NAME_LEN))
            else
                callback(sid ~= "" and sid or sid64)
            end
        end, function()
            callback(sid ~= "" and sid or sid64)
        end)
    end

    local function notifyRankChange(steamid, oldRank, newRank)
        getDisplayName(steamid, function(name)
            oldRank = normRank(oldRank)
            newRank = normRank(newRank)
            local oldRankName = getRankName(oldRank ~= "" and oldRank or defaultRank)
            local newRankName = getRankName(newRank)
            if newRank == defaultRank or newRank == "user" then
                broadcastChat("\208\152\208\179\209\128\208\190\208\186 " .. tostring(name) .. " \208\177\209\139\208\187 \209\129\208\189\209\143\209\130 \209\129 \208\191\208\190\209\129\209\130\208\176: " .. oldRankName)
                return
            end
            if oldRank == "" or oldRank == defaultRank or oldRank == "user" then
                broadcastChat("\208\152\208\179\209\128\208\190\208\186 " .. tostring(name) .. " \208\177\209\139\208\187 \208\191\208\181\209\128\208\181\208\178\208\181\208\180\208\181\208\189 \208\189\208\176 \208\191\208\190\209\129\209\130: " .. newRankName)
            else
                broadcastChat("\208\152\208\179\209\128\208\190\208\186 " .. tostring(name) .. " \209\129\208\188\208\181\208\189\208\184\208\187 \208\191\208\190\209\129\209\130: " .. oldRankName .. " -> " .. newRankName)
            end
        end)
    end

    local function safeSamSetRank(steamid, newRank)
        if not isOriginalRuntime() then
            secLog("blocked setrank because runtime function was replaced")
            return false
        end
        local sid, sid64 = normalizeSteamID(steamid)
        newRank = normRank(newRank)
        if sid == "" and sid64 == "" then
            secLog("blocked setrank invalid steamid: " .. tostring(steamid))
            return false
        end
        if not isAllowedPanelRank(newRank) then
            secLog("blocked setrank forbidden rank=" .. tostring(newRank) .. " steamid=" .. tostring(steamid))
            return false
        end
        local targetId = sid64 ~= "" and sid64 or sid
        if not concommand or not concommand.GetTable then
            secLog("blocked setrank no concommand table")
            return false
        end
        local ct = concommand.GetTable()
        if not istable(ct) then
            secLog("blocked setrank bad concommand table")
            return false
        end
        if newRank == defaultRank or newRank == "user" then
            if ct["sam"] ~= nil then
                RK_ORIGINAL_RUNCONSOLECOMMAND("sam", "setrankid", targetId, "user")
            elseif ct["setrankid"] ~= nil then
                RK_ORIGINAL_RUNCONSOLECOMMAND("setrankid", targetId, "user")
            else
                secLog("blocked demote to user because SAM command missing")
                return false
            end
            local where = {}
            if sid   ~= "" then where[#where + 1] = "steamid = " .. sqlStr(sid)   end
            if sid64 ~= "" then where[#where + 1] = "steamid = " .. sqlStr(sid64) end
            if #where > 0 then
                runQuery(
                    "UPDATE sam_players SET rank = " .. sqlStr("user") .. " WHERE " .. table.concat(where, " OR ") .. ";",
                    function() secLog("forced demote to user in sam_players steamid=" .. tostring(targetId)) end,
                    function(err) secLog("failed forced demote sql: " .. tostring(err)) end
                )
            end
            local ply = findPlayerBySteam(targetId)
            if IsValid(ply) and ply.SetUserGroup then ply:SetUserGroup("user") end
            secLog("issued safe panel demote steamid=" .. targetId .. " rank=user")
            return true
        end
        if ct["sam"] ~= nil then
            RK_ORIGINAL_RUNCONSOLECOMMAND("sam", "setrankid", targetId, newRank)
            secLog("issued safe panel rank steamid=" .. targetId .. " rank=" .. newRank)
            return true
        end
        if ct["setrankid"] ~= nil then
            RK_ORIGINAL_RUNCONSOLECOMMAND("setrankid", targetId, newRank)
            secLog("issued safe legacy panel rank steamid=" .. targetId .. " rank=" .. newRank)
            return true
        end
        secLog("blocked setrank because SAM command missing")
        return false
    end

    local function setRankIfNeeded(steamid, oldRank, newRank, shouldNotify)
        oldRank = normRank(oldRank)
        newRank = normRank(newRank)
        if steamid == "" or newRank == "" then return false end
        if oldRank == newRank then return false end
        if not isAllowedPanelRank(newRank) then
            secLog("blocked panel rank sync forbidden newRank=" .. tostring(newRank) .. " steamid=" .. tostring(steamid))
            return false
        end
        local ok = safeSamSetRank(steamid, newRank)
        if ok and shouldNotify then notifyRankChange(steamid, oldRank, newRank) end
        return ok
    end

    local function fetchCurrentRanks(identifiers, callback)
        if #identifiers == 0 then callback({}) return end
        local inList = {}
        local used   = {}
        for _, steamid in ipairs(identifiers) do
            local sid, sid64 = normalizeSteamID(steamid)
            if sid   ~= "" and not used[sid]   then used[sid]   = true; inList[#inList + 1] = sqlStr(sid)   end
            if sid64 ~= "" and not used[sid64] then used[sid64] = true; inList[#inList + 1] = sqlStr(sid64) end
        end
        if #inList == 0 then callback({}) return end
        runQuery(
            "SELECT steamid, rank FROM sam_players WHERE steamid IN (" .. table.concat(inList, ",") .. ");",
            function(data) callback(data or {}) end,
            function() callback({}) end
        )
    end

    local function validateSnapshotPayload(payload)
        if not istable(payload) then return false, "payload not table" end
        if payload.success ~= true then return false, "api success false" end
        local items = istable(payload.items) and payload.items or {}
        if #items > PANEL_MAX_SNAPSHOT_ITEMS then return false, "too many items" end
        return true, ""
    end

    local function applySnapshot(payload)
        local okPayload, payloadErr = validateSnapshotPayload(payload)
        if not okPayload then
            secLog("blocked snapshot: " .. tostring(payloadErr))
            finishSync()
            return
        end

        if not refreshRankConfig(payload) then
            secLog("blocked snapshot: no ranks received from panel")
            finishSync()
            return
        end

        local items = istable(payload.items) and payload.items or {}

        local desiredByCanonical = {}
        local identifiersMap     = {}

        for _, row in ipairs(items) do
            if istable(row) then
                local rawSteamID = safeTrim(row.steam_id, 64)
                local rank       = normRank(row.rank or "")
                local sid, sid64 = normalizeSteamID(rawSteamID)
                local canonical  = sid64 ~= "" and sid64 or sid
                if canonical ~= "" and rank ~= "" then
                    if isAllowedPanelRank(rank) then
                        desiredByCanonical[canonical] = { rank = rank, steamid = sid64 ~= "" and sid64 or sid }
                        if sid   ~= "" then identifiersMap[sid]   = true end
                        if sid64 ~= "" then identifiersMap[sid64] = true end
                    else
                        secLog("blocked snapshot row forbidden rank=" .. tostring(rank) .. " steamid=" .. tostring(rawSteamID))
                    end
                end
            end
        end

        local demoteCanonicals = {}
        for canonical in pairs(prevSnapshotCanonicals) do
            if not desiredByCanonical[canonical] then
                demoteCanonicals[#demoteCanonicals + 1] = canonical
                if isValidSteamID64(canonical) then identifiersMap[canonical] = true end
            end
        end

        prevSnapshotCanonicals = {}
        for canonical in pairs(desiredByCanonical) do
            prevSnapshotCanonicals[canonical] = true
        end

        local identifiers = {}
        for steamid in pairs(identifiersMap) do identifiers[#identifiers + 1] = steamid end

        fetchCurrentRanks(identifiers, function(rows)
            local currentByCanonical = {}
            for _, row in ipairs(rows) do
                local rowSteamID = tostring(row.steamid or "")
                local curRank    = normRank(row.rank or "")
                local sid, sid64 = normalizeSteamID(rowSteamID)
                local canonical  = sid64 ~= "" and sid64 or sid
                if canonical ~= "" and not currentByCanonical[canonical] then
                    currentByCanonical[canonical] = curRank
                end
            end

            for canonical, desired in pairs(desiredByCanonical) do
                local currentRank = normRank(currentByCanonical[canonical] or "")
                if currentRank ~= desired.rank then
                    setRankIfNeeded(desired.steamid, currentRank, desired.rank, true)
                end
            end

            for _, canonical in ipairs(demoteCanonicals) do
                local currentRank = normRank(currentByCanonical[canonical] or "")
                if currentRank ~= "" and currentRank ~= "user" and currentRank ~= defaultRank and isAllowedPanelRank(currentRank) then
                    setRankIfNeeded(canonical, currentRank, "user", true)
                end
            end

            finishSync()
        end)
    end

    local function fetchSnapshot()
        if syncInProgress then return end
        if CurTime() - lastFetchAt < math.max(5, PANEL_SYNC_INTERVAL * 0.5) then return end
        lastFetchAt    = CurTime()
        syncInProgress = true

        acquireLock(function(locked)
            if not locked then syncInProgress = false return end
            if not isOriginalRuntime() then
                secLog("blocked fetchSnapshot because runtime function was replaced")
                finishSync()
                return
            end
            HTTP({
                url     = appendToken(PANEL_SYNC_URL) .. "&server_id=" .. SERVER_ID,
                method  = "get",
                headers = { ["X-Sync-Token"] = PANEL_SYNC_TOKEN },
                success = function(code, body)
                    code = tonumber(code) or 0
                    body = tostring(body or "")
                    if code ~= 200 then
                        print("[RankSync] HTTP code: " .. tostring(code))
                        finishSync()
                        return
                    end
                    if #body > PANEL_MAX_HTTP_BODY then
                        secLog("blocked snapshot body too large")
                        finishSync()
                        return
                    end
                    local data = util.JSONToTable(body)
                    if not istable(data) then
                        print("[RankSync] Invalid JSON")
                        finishSync()
                        return
                    end
                    local snapshotHash = util.CRC(body or "")
                    if snapshotHash == lastSnapshotHash then
                        finishSync()
                        return
                    end
                    lastSnapshotHash = snapshotHash
                    applySnapshot(data)
                end,
                failed = function(err)
                    print("[RankSync] HTTP Error: " .. tostring(err))
                    finishSync()
                end
            })
        end)
    end

    function db:onConnected()
        print("[RankSync] MySQL \208\191\208\190\208\180\208\186\208\187\209\142\209\135\208\181\208\189")
        if timer.Exists("PanelRankSyncTimer")       then timer.Remove("PanelRankSyncTimer")       end
        if timer.Exists("PanelServerOnlineTick")    then timer.Remove("PanelServerOnlineTick")    end
        if timer.Exists("PanelServerOnlinePush")    then timer.Remove("PanelServerOnlinePush")    end
        if timer.Exists("PanelPunishmentQueuePush") then timer.Remove("PanelPunishmentQueuePush") end
        if timer.Exists("PanelServerRosterPush")    then timer.Remove("PanelServerRosterPush")    end
        if timer.Exists("PanelBanQueuePoll")        then timer.Remove("PanelBanQueuePoll")        end
        timer.Create("PanelRankSyncTimer",       PANEL_SYNC_INTERVAL,        0, function() fetchSnapshot()       end)
        timer.Create("PanelServerOnlineTick",    1,                          0, function()
            for _, ply in ipairs(player.GetHumans()) do addOnlineSecond(ply) end
        end)
        timer.Create("PanelServerOnlinePush",    PANEL_ONLINE_PUSH_INTERVAL, 0, function() pushOnlineBuffer()   end)
        timer.Create("PanelPunishmentQueuePush", 20,                         0, function() flushPunishmentQueue() end)
        timer.Create("PanelServerRosterPush",    PANEL_ROSTER_PUSH_INTERVAL, 0, function() pushServerRoster()   end)
        timer.Create("PanelBanQueuePoll",        PANEL_BAN_POLL_INTERVAL,    0, function() pollBanQueue()       end)
        fetchSnapshot()
        timer.Simple(5, function() pushServerRoster() end)
        timer.Simple(8, function() pollBanQueue() end)
    end

    function db:onConnectionFailed(err)
        print("[RankSync] \208\158\209\136\208\184\208\177\208\186\208\176 MySQL: " .. tostring(err))
    end

    db:connect()

    concommand.Remove("panel_rank_sync_reload")
    concommand.Add("panel_rank_sync_reload", function(ply)
        if IsValid(ply) then return end
        fetchSnapshot()
    end)

    concommand.Remove("panel_online_push")
    concommand.Add("panel_online_push", function(ply)
        if IsValid(ply) then return end
        pushOnlineBuffer()
    end)

    concommand.Remove("panel_roster_push")
    concommand.Add("panel_roster_push", function(ply)
        if IsValid(ply) then return end
        pushServerRoster()
    end)

    concommand.Remove("panel_ban_poll")
    concommand.Add("panel_ban_poll", function(ply)
        if IsValid(ply) then return end
        pollBanQueue()
    end)

    concommand.Remove("panel_punishment_test")
    concommand.Add("panel_punishment_test", function(ply)
        if IsValid(ply) then return end
        local target = player.GetHumans()[1]
        if not IsValid(target) then return end
        logPunishment("test", target, nil, "test", 0)
    end)
end)




timer.Simple(0.1, function()
if not SERVER then return end

OTAP = OTAP or {}
OTAP.Config = OTAP.Config or {}

OTAP.Config.Enabled = true
OTAP.Config.PanelProtocolPushURL = "https://monteract.myarena.site/mlogs/admin_protocol.php"
OTAP.Config.PanelSyncToken = "eggggggwwwwwwwwqwrw1213457891111fg22222222124"
OTAP.Config.CheckInterval = 120
OTAP.Config.PlayerPerAdmin = 20
OTAP.Config.MinPlayersForAdmin = 7
OTAP.Config.MinPlayersForEveryone = 7
OTAP.Config.AfkSeconds = 420
OTAP.Config.NoAdminCooldown = 1800
OTAP.Config.NotEnoughCooldown = 2400
OTAP.Config.BorderlineCooldown = 3600
OTAP.Config.RecoveryCooldown = 900
OTAP.Config.StartDelay = 30
OTAP.Config.SendStartupReport = false
OTAP.Config.UseEveryoneOnNoAdmins = true
OTAP.Config.UseHereOnNotEnough = false
OTAP.Config.IncludeServerIP = true
OTAP.Config.IncludeMap = true
OTAP.Config.MaxListedPlayers = 18
OTAP.Config.MaxListedAdmins = 12
OTAP.Config.MovementActivityDistance = 70
OTAP.Config.PrintResponse = false
OTAP.Config.PrintStatusEveryCheck = false
OTAP.Config.UseEngineAdmin = false
OTAP.Config.ProblemHoldSeconds = 180
OTAP.Config.NotEnoughHoldSeconds = 240
OTAP.Config.RecoveryHoldSeconds = 120
OTAP.Config.MinPlayersChangeForFastSend = 8
OTAP.Config.MinDeficitChangeForFastSend = 2
OTAP.Config.IgnoreBorderline = true
OTAP.Config.EventStateResetSeconds = 900

OTAP.Config.RequireDynamicRanks = true
OTAP.Config.AdminGroups = {}
OTAP.Config.HighRankGroups = {}

OTAP.State = OTAP.State or {}
OTAP.State.LastActivity = OTAP.State.LastActivity or {}
OTAP.State.LastPositions = OTAP.State.LastPositions or {}
OTAP.State.LastSent = OTAP.State.LastSent or {}
OTAP.State.LastProtocol = OTAP.State.LastProtocol or "boot"
OTAP.State.LastFingerprint = OTAP.State.LastFingerprint or ""
OTAP.State.LastRecoverySent = OTAP.State.LastRecoverySent or 0
OTAP.State.ProblemStarted = OTAP.State.ProblemStarted or {}
OTAP.State.ProblemLastSeen = OTAP.State.ProblemLastSeen or {}
OTAP.State.ProblemFirstFingerprint = OTAP.State.ProblemFirstFingerprint or {}
OTAP.State.LastSentSnapshot = OTAP.State.LastSentSnapshot or {}

local function safeTrim(value, maxLen)
    value = tostring(value or "")
    value = string.Trim(value)
    maxLen = math.floor(tonumber(maxLen) or 255)
    if #value > maxLen then value = string.sub(value, 1, maxLen) end
    return value
end

local function safeLower(value, maxLen)
    return string.lower(safeTrim(value, maxLen or 255))
end

local function getCurrentServerName()
    local name = ""
    if GetHostName then name = tostring(GetHostName() or "") end
    if name == "" and game.GetIPAddress then name = tostring(game.GetIPAddress() or "") end
    if name == "" then name = "OT-City" end
    return safeTrim(name, 128)
end

local function getCurrentServerId()
    local name = getCurrentServerName()
    local low = string.lower(name)
    local n = name:match("Сервер%s*#(%d+)") or name:match("сервер%s*#(%d+)") or name:match("#(%d+)")

    if n then
        local id = math.floor(tonumber(n) or 0)
        if id >= 1 and id <= 5 then return "otcity_" .. tostring(id) end
    end

    if low:find("ot%-city%s*#?1") or low:find("otcity%s*#?1") or low:find("от%-сити%s*#?1") then return "otcity_1" end
    if low:find("ot%-city%s*#?2") or low:find("otcity%s*#?2") or low:find("от%-сити%s*#?2") then return "otcity_2" end
    if low:find("ot%-city%s*#?3") or low:find("otcity%s*#?3") or low:find("от%-сити%s*#?3") then return "otcity_3" end
    if low:find("ot%-city%s*#?4") or low:find("otcity%s*#?4") or low:find("от%-сити%s*#?4") or low:find("test", 1, true) then return "otcity_4" end

    return "otcity_1"
end

local function getReadableServerName()
    local id = getCurrentServerId()
    local host = getCurrentServerName()

    local names = {
        otcity_1 = "OT-City #1",
        otcity_2 = "OT-City #2",
        otcity_3 = "OT-City #3",
        otcity_4 = "OT-City #4"
    }

    local pretty = names[id] or "OT-City"

    if host ~= "" and host ~= "OT-City" and host ~= pretty then
        return pretty .. " · " .. host
    end

    return pretty
end

local SERVER_ID = getCurrentServerId()
local SERVER_NAME = getReadableServerName()

local function log(text)
    print("[OTAP] " .. tostring(text or ""))
end

local function safeName(ply)
    if not IsValid(ply) then return "Unknown" end
    local name = safeTrim(ply:Nick(), 128)
    if name == "" then return "Unknown" end
    return name
end

local function steamId(ply)
    if not IsValid(ply) then return "UNKNOWN" end
    local sid64 = tostring(ply:SteamID64() or "")
    if sid64 ~= "" then return sid64 end
    local sid = tostring(ply:SteamID() or "")
    if sid ~= "" then return sid end
    return "UNKNOWN"
end

local function playerGroup(ply)
    if not IsValid(ply) then return "user" end
    if ply.GetUserGroup then
        local group = safeLower(ply:GetUserGroup(), 64)
        if group ~= "" then return group end
    end
    return "user"
end

local function getDynamicRankState()
    local state = _G.PanelSyncDynamicRanks
    if istable(state) and tonumber(state.updated_at or 0) and tonumber(state.updated_at or 0) > 0 then
        return state
    end
    if OTAP and OTAP.State and istable(OTAP.State.DynamicRanks) then
        return OTAP.State.DynamicRanks
    end
    return nil
end

local function dynamicRanksReady()
    return getDynamicRankState() ~= nil
end

local function isAdminGroup(group)
    group = safeLower(group, 64)
    if group == "" or group == "user" or group == "moderator" then return false end

    local state = getDynamicRankState()
    if istable(state) and istable(state.online) then
        return state.online[group] == true
    end

    return OTAP.Config.RequireDynamicRanks ~= true and OTAP.Config.AdminGroups[group] == true
end

local function isHighGroup(group)
    group = safeLower(group, 64)
    if group == "" or group == "user" or group == "moderator" then return false end

    local state = getDynamicRankState()
    if istable(state) and istable(state.high) then
        return state.high[group] == true
    end

    return OTAP.Config.RequireDynamicRanks ~= true and OTAP.Config.HighRankGroups[group] == true
end

local function isAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return false end

    local group = playerGroup(ply)

    if isAdminGroup(group) then return true end
    if OTAP.Config.UseEngineAdmin and ply.IsAdmin and ply:IsAdmin() then return true end
    if OTAP.Config.UseEngineAdmin and ply.IsSuperAdmin and ply:IsSuperAdmin() then return true end

    return false
end

local function touch(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

    local id = steamId(ply)

    OTAP.State.LastActivity[id] = CurTime()
    OTAP.State.LastPositions[id] = ply:GetPos()
end

local function isAfk(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end

    local id = steamId(ply)
    local last = tonumber(OTAP.State.LastActivity[id] or 0) or 0

    if last <= 0 then
        touch(ply)
        return false
    end

    return CurTime() - last >= tonumber(OTAP.Config.AfkSeconds or 420)
end

local function updateMovementActivity()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
            local id = steamId(ply)
            local pos = ply:GetPos()
            local old = OTAP.State.LastPositions[id]

            if not old then
                OTAP.State.LastPositions[id] = pos
                OTAP.State.LastActivity[id] = OTAP.State.LastActivity[id] or CurTime()
            else
                local need = tonumber(OTAP.Config.MovementActivityDistance or 70) or 70
                if pos:DistToSqr(old) >= need * need then
                    OTAP.State.LastPositions[id] = pos
                    OTAP.State.LastActivity[id] = CurTime()
                end
            end
        end
    end
end

local function requiredAdmins(playersCount)
    playersCount = math.floor(tonumber(playersCount) or 0)
    local minPlayers = tonumber(OTAP.Config.MinPlayersForAdmin or 1) or 1
    local ratio = math.max(1, tonumber(OTAP.Config.PlayerPerAdmin or 20) or 20)

    if playersCount < minPlayers then return 0 end

    return math.max(1, math.ceil(playersCount / ratio))
end

local function serverAddress()
    local hostip = GetConVar("hostip")
    local hostport = GetConVar("hostport")

    if not hostip or not hostport then return "—" end

    local ip = tonumber(hostip:GetString() or "0") or 0
    local a = bit.rshift(bit.band(ip, 0xFF000000), 24)
    local b = bit.rshift(bit.band(ip, 0x00FF0000), 16)
    local c = bit.rshift(bit.band(ip, 0x0000FF00), 8)
    local d = bit.band(ip, 0x000000FF)

    if a == 0 and b == 0 and c == 0 and d == 0 then return "—" end

    return tostring(a) .. "." .. tostring(b) .. "." .. tostring(c) .. "." .. tostring(d) .. ":" .. hostport:GetString()
end

local function formatAdmin(ply, active)
    local status = active and "активен" or "AFK"
    return safeName(ply) .. " [" .. playerGroup(ply) .. "] [" .. status .. "]"
end

local function formatPlayer(ply)
    return safeName(ply) .. " [" .. steamId(ply) .. "]"
end

local function buildProtocolList(list, formatter, limit)
    local out = {}
    local max = math.max(1, tonumber(limit or 15) or 15)

    for i = 1, math.min(#list, max) do
        out[#out + 1] = formatter(list[i])
    end

    if #list > max then
        out[#out + 1] = "ещё " .. tostring(#list - max)
    end

    return out
end

local function collect()
    updateMovementActivity()

    local humans = {}
    local adminsOnline = {}
    local adminsActive = {}
    local adminsAfk = {}
    local highRanksOnline = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
            humans[#humans + 1] = ply

            if isAdmin(ply) then
                local active = not isAfk(ply)

                adminsOnline[#adminsOnline + 1] = ply

                if active then
                    adminsActive[#adminsActive + 1] = ply
                else
                    adminsAfk[#adminsAfk + 1] = ply
                end

                if isHighGroup(playerGroup(ply)) then
                    highRanksOnline[#highRanksOnline + 1] = ply
                end
            end
        end
    end

    local playersCount = #humans
    local required = requiredAdmins(playersCount)
    local activeAdmins = #adminsActive
    local onlineAdmins = #adminsOnline
    local deficit = math.max(0, required - activeAdmins)
    local protocol = "ok"
    local severity = 0
    local reason = "Норма"

    if playersCount >= tonumber(OTAP.Config.MinPlayersForEveryone or 1) and activeAdmins <= 0 and required > 0 then
        protocol = "no_admins"
        severity = 3
        reason = "На " .. SERVER_NAME .. " нет активных администраторов"
    elseif activeAdmins < required and required > 0 then
        protocol = "not_enough_admins"
        severity = 2
        reason = "На " .. SERVER_NAME .. " не хватает администраторов: нужно ещё " .. tostring(deficit)
    elseif OTAP.Config.IgnoreBorderline ~= true and playersCount >= math.max(40, (tonumber(OTAP.Config.PlayerPerAdmin or 20) or 20) * 2) and activeAdmins == required then
        protocol = "borderline"
        severity = 1
        reason = "На " .. SERVER_NAME .. " нагрузка на администраторов близка к лимиту"
    end

    return {
        humans = humans,
        adminsOnline = adminsOnline,
        adminsActive = adminsActive,
        adminsAfk = adminsAfk,
        highRanksOnline = highRanksOnline,
        playersCount = playersCount,
        requiredAdmins = required,
        activeAdminsCount = activeAdmins,
        onlineAdminsCount = onlineAdmins,
        afkAdminsCount = #adminsAfk,
        deficit = deficit,
        protocol = protocol,
        severity = severity,
        reason = reason
    }
end

local function eventKey(protocol)
    return SERVER_ID .. ":" .. tostring(protocol or "ok")
end

local function fingerprint(data, protocol)
    return table.concat({
        SERVER_ID,
        protocol,
        tostring(data.playersCount),
        tostring(data.requiredAdmins),
        tostring(data.activeAdminsCount),
        tostring(data.onlineAdminsCount),
        tostring(data.afkAdminsCount),
        tostring(data.deficit)
    }, ":")
end

local function softFingerprint(data, protocol)
    return table.concat({
        SERVER_ID,
        protocol,
        tostring(data.requiredAdmins),
        tostring(data.activeAdminsCount),
        tostring(data.deficit)
    }, ":")
end

local function eventHold(protocol)
    if protocol == "not_enough_admins" then return tonumber(OTAP.Config.NotEnoughHoldSeconds or 240) or 240 end
    if protocol == "recovery" then return tonumber(OTAP.Config.RecoveryHoldSeconds or 120) or 120 end
    return tonumber(OTAP.Config.ProblemHoldSeconds or 180) or 180
end

local function cleanupEventState()
    local now = os.time()
    local maxAge = tonumber(OTAP.Config.EventStateResetSeconds or 900) or 900

    for key, lastSeen in pairs(OTAP.State.ProblemLastSeen or {}) do
        lastSeen = tonumber(lastSeen or 0) or 0
        if now - lastSeen >= maxAge then
            OTAP.State.ProblemStarted[key] = nil
            OTAP.State.ProblemLastSeen[key] = nil
            OTAP.State.ProblemFirstFingerprint[key] = nil
        end
    end
end

local function updateEventState(data, protocol)
    cleanupEventState()

    local now = os.time()
    local key = eventKey(protocol)
    local fp = softFingerprint(data, protocol)

    if protocol == "ok" or protocol == "startup" then
        return 0
    end

    if not OTAP.State.ProblemStarted[key] or OTAP.State.ProblemFirstFingerprint[key] ~= fp then
        OTAP.State.ProblemStarted[key] = now
        OTAP.State.ProblemFirstFingerprint[key] = fp
    end

    OTAP.State.ProblemLastSeen[key] = now

    return math.max(0, now - (tonumber(OTAP.State.ProblemStarted[key] or now) or now))
end

local function snapshotChangedEnough(data, protocol)
    local old = OTAP.State.LastSentSnapshot[protocol]
    if not istable(old) then return true end

    local playersDiff = math.abs((tonumber(data.playersCount) or 0) - (tonumber(old.playersCount) or 0))
    local deficitDiff = math.abs((tonumber(data.deficit) or 0) - (tonumber(old.deficit) or 0))
    local requiredDiff = math.abs((tonumber(data.requiredAdmins) or 0) - (tonumber(old.requiredAdmins) or 0))
    local activeDiff = math.abs((tonumber(data.activeAdminsCount) or 0) - (tonumber(old.activeAdminsCount) or 0))

    if playersDiff >= (tonumber(OTAP.Config.MinPlayersChangeForFastSend or 8) or 8) then return true end
    if deficitDiff >= (tonumber(OTAP.Config.MinDeficitChangeForFastSend or 2) or 2) then return true end
    if requiredDiff >= 2 then return true end
    if activeDiff >= 2 then return true end

    return false
end

local function postProtocolToPanel(data, protocol, persistSeconds)
    local url = safeTrim(OTAP.Config.PanelProtocolPushURL, 512)
    local token = safeTrim(OTAP.Config.PanelSyncToken, 256)

    if url == "" then
        log("panel protocol url is empty")
        return false
    end

    if token == "" or token == "PUT_PANEL_SYNC_TOKEN_HERE" then
        log("panel sync token is empty")
        return false
    end

    local payload = {
        server_id = SERVER_ID,
        server_name = SERVER_NAME,
        protocol = protocol,
        reason = data.reason,
        players = data.playersCount,
        max_players = game.MaxPlayers() or 0,
        required_admins = data.requiredAdmins,
        active_admins = data.activeAdminsCount,
        online_admins = data.onlineAdminsCount,
        afk_admins = data.afkAdminsCount,
        deficit = data.deficit,
        ratio = OTAP.Config.PlayerPerAdmin,
        map = game.GetMap() or "unknown",
        address = serverAddress(),
        mention_everyone = protocol == "no_admins" and OTAP.Config.UseEveryoneOnNoAdmins == true,
        mention_here = protocol == "not_enough_admins" and OTAP.Config.UseHereOnNotEnough == true,
        persist_seconds = math.floor(tonumber(persistSeconds or 0) or 0),
        active_admin_list = buildProtocolList(data.adminsActive or {}, function(ply)
            return formatAdmin(ply, true)
        end, OTAP.Config.MaxListedAdmins),
        afk_admin_list = buildProtocolList(data.adminsAfk or {}, function(ply)
            return formatAdmin(ply, false)
        end, OTAP.Config.MaxListedAdmins),
        high_rank_list = buildProtocolList(data.highRanksOnline or {}, function(ply)
            return formatAdmin(ply, not isAfk(ply))
        end, OTAP.Config.MaxListedAdmins),
        player_list = buildProtocolList(data.humans or {}, function(ply)
            return formatPlayer(ply)
        end, OTAP.Config.MaxListedPlayers)
    }

    local body = util.TableToJSON(payload, false)

    if not body or body == "" then
        log("failed to build panel json")
        return false
    end

    HTTP({
        url = url,
        method = "post",
        headers = {
            ["X-Sync-Token"] = token,
            ["Content-Type"] = "application/json"
        },
        body = body,
        success = function(code, response)
            code = tonumber(code) or 0
            response = tostring(response or "")

            if code >= 200 and code < 300 then
                if OTAP.Config.PrintResponse then
                    log("panel protocol sent code=" .. tostring(code) .. " body=" .. response)
                end
            else
                log("panel protocol failed code=" .. tostring(code) .. " body=" .. response)
            end
        end,
        failed = function(err)
            log("panel protocol http failed=" .. tostring(err))
        end
    })

    return true
end

local function cooldown(protocol)
    if protocol == "no_admins" then return tonumber(OTAP.Config.NoAdminCooldown or 1800) or 1800 end
    if protocol == "not_enough_admins" then return tonumber(OTAP.Config.NotEnoughCooldown or 2400) or 2400 end
    if protocol == "borderline" then return tonumber(OTAP.Config.BorderlineCooldown or 3600) or 3600 end
    if protocol == "recovery" then return tonumber(OTAP.Config.RecoveryCooldown or 900) or 900 end
    return 1800
end

local function shouldSend(data, protocol, persistSeconds, force)
    local t = os.time()
    local cd = cooldown(protocol)
    local last = tonumber(OTAP.State.LastSent[protocol] or 0) or 0
    local fp = fingerprint(data, protocol)

    if protocol == "startup" then return force == true end

    if protocol == "recovery" then
        if persistSeconds < eventHold(protocol) and not force then return false end
        return t - tonumber(OTAP.State.LastRecoverySent or 0) >= cd
    end

    if persistSeconds < eventHold(protocol) and not force then return false end

    if last <= 0 then return true end
    if OTAP.State.LastProtocol ~= protocol and t - last >= math.max(300, math.floor(cd / 3)) then return true end
    if snapshotChangedEnough(data, protocol) and t - last >= math.max(600, math.floor(cd / 2)) then return true end
    if fp ~= OTAP.State.LastFingerprint and t - last >= cd then return true end
    if t - last >= cd then return true end

    return false
end

local function rememberSend(data, protocol)
    local t = os.time()

    OTAP.State.LastSent[protocol] = t
    OTAP.State.LastFingerprint = fingerprint(data, protocol)
    OTAP.State.LastSentSnapshot[protocol] = {
        playersCount = data.playersCount,
        requiredAdmins = data.requiredAdmins,
        activeAdminsCount = data.activeAdminsCount,
        onlineAdminsCount = data.onlineAdminsCount,
        afkAdminsCount = data.afkAdminsCount,
        deficit = data.deficit
    }

    if protocol == "recovery" then
        OTAP.State.LastRecoverySent = t
    end
end

local function resetResolvedProblems(data)
    if data.protocol ~= "ok" then return end

    for key in pairs(OTAP.State.ProblemStarted or {}) do
        if key ~= eventKey("recovery") then
            OTAP.State.ProblemStarted[key] = nil
            OTAP.State.ProblemLastSeen[key] = nil
            OTAP.State.ProblemFirstFingerprint[key] = nil
        end
    end
end

local function process(protocolOverride, force)
    if not OTAP.Config.Enabled then return end

    if OTAP.Config.RequireDynamicRanks == true and not dynamicRanksReady() then
        if OTAP.Config.PrintStatusEveryCheck then
            log("waiting dynamic panel ranks")
        end
        return
    end

    local data = collect()
    local protocol = protocolOverride or data.protocol

    if protocolOverride == "startup" then
        data.reason = "Система мониторинга администраторов активирована на " .. SERVER_NAME
    end

    local wasProblem = OTAP.State.LastProtocol == "no_admins" or OTAP.State.LastProtocol == "not_enough_admins" or OTAP.State.LastProtocol == "borderline"
    local nowOk = data.protocol == "ok"

    if not protocolOverride and wasProblem and nowOk then
        protocol = "recovery"
        data.reason = "Норма по администраторам восстановлена на " .. SERVER_NAME
    end

    local persistSeconds = updateEventState(data, protocol)

    if OTAP.Config.PrintStatusEveryCheck then
        log("check server=" .. SERVER_ID .. " players=" .. tostring(data.playersCount) .. " active_admins=" .. tostring(data.activeAdminsCount) .. " online_admins=" .. tostring(data.onlineAdminsCount) .. " required=" .. tostring(data.requiredAdmins) .. " deficit=" .. tostring(data.deficit) .. " protocol=" .. tostring(data.protocol) .. " persist=" .. tostring(persistSeconds))
    end

    if protocol == "ok" and not force then
        resetResolvedProblems(data)
        OTAP.State.LastProtocol = data.protocol
        return
    end

    if shouldSend(data, protocol, persistSeconds, force) then
        postProtocolToPanel(data, protocol, persistSeconds)
        rememberSend(data, protocol)
    end

    if protocol ~= "startup" then
        OTAP.State.LastProtocol = data.protocol
    end
end

local function delayedCheck(delay)
    timer.Simple(delay or 10, function()
        if not OTAP or not OTAP.Config or not OTAP.Config.Enabled then return end
        process()
    end)
end

hook.Add("PlayerInitialSpawn", "OTAP_PlayerInitialSpawn", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then touch(ply) end
        delayedCheck(15)
    end)
end)

hook.Add("PlayerDisconnected", "OTAP_PlayerDisconnected", function(ply)
    if IsValid(ply) then
        local id = steamId(ply)
        OTAP.State.LastActivity[id] = nil
        OTAP.State.LastPositions[id] = nil
    end

    delayedCheck(15)
end)

hook.Add("KeyPress", "OTAP_KeyPress", function(ply)
    touch(ply)
end)

hook.Add("PlayerSay", "OTAP_PlayerSay", function(ply)
    touch(ply)
end)

hook.Add("PlayerSpawn", "OTAP_PlayerSpawn", function(ply)
    touch(ply)
end)

hook.Add("PlayerDeath", "OTAP_PlayerDeath", function(ply)
    touch(ply)
end)

hook.Add("CanPlayerSuicide", "OTAP_CanPlayerSuicide", function(ply)
    touch(ply)
end)

if timer.Exists("OTAP_MainThink") then timer.Remove("OTAP_MainThink") end

timer.Create("OTAP_MainThink", math.max(60, tonumber(OTAP.Config.CheckInterval or 120) or 120), 0, function()
    process()
end)

timer.Simple(math.max(1, tonumber(OTAP.Config.StartDelay or 30) or 30), function()
    if OTAP.Config.SendStartupReport then
        process("startup", true)
    end

    process()
end)

concommand.Remove("otap_status")
concommand.Add("otap_status", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local data = collect()

    print("OTAP status")
    print("server_id=" .. SERVER_ID)
    print("server_name=" .. SERVER_NAME)
    print("panel_url=" .. safeTrim(OTAP.Config.PanelProtocolPushURL, 512))
    print("token_set=" .. tostring(safeTrim(OTAP.Config.PanelSyncToken, 256) ~= "" and safeTrim(OTAP.Config.PanelSyncToken, 256) ~= "PUT_PANEL_SYNC_TOKEN_HERE"))
    print("dynamic_ranks_ready=" .. tostring(dynamicRanksReady()))
    print("players=" .. tostring(data.playersCount))
    print("required_admins=" .. tostring(data.requiredAdmins))
    print("active_admins=" .. tostring(data.activeAdminsCount))
    print("online_admins=" .. tostring(data.onlineAdminsCount))
    print("afk_admins=" .. tostring(data.afkAdminsCount))
    print("deficit=" .. tostring(data.deficit))
    print("protocol=" .. tostring(data.protocol))
    print("reason=" .. tostring(data.reason))

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsPlayer() and not p:IsBot() then
            print("player=" .. safeName(p) .. " group=" .. playerGroup(p) .. " is_admin=" .. tostring(isAdmin(p)) .. " afk=" .. tostring(isAfk(p)))
        end
    end
end)

concommand.Remove("otap_force_check")
concommand.Add("otap_force_check", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    process(nil, true)
end)

concommand.Remove("otap_test_red")
concommand.Add("otap_test_red", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local data = collect()
    data.requiredAdmins = math.max(1, data.requiredAdmins)
    data.activeAdminsCount = 0
    data.onlineAdminsCount = 0
    data.afkAdminsCount = 0
    data.deficit = data.requiredAdmins
    data.protocol = "no_admins"
    data.reason = "Тест красного протокола на " .. SERVER_NAME

    postProtocolToPanel(data, "no_admins", 9999)
end)

concommand.Remove("otap_test_startup")
concommand.Add("otap_test_startup", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local data = collect()
    data.reason = "Тестовое сообщение мониторинга на " .. SERVER_NAME

    postProtocolToPanel(data, "startup", 0)
end)

concommand.Remove("otap_enable")
concommand.Add("otap_enable", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    OTAP.Config.Enabled = tostring(args[1] or "1") ~= "0"
    print("OTAP enabled: " .. tostring(OTAP.Config.Enabled))
end)

log("loaded server_id=" .. SERVER_ID .. " server_name=" .. SERVER_NAME)
end)
