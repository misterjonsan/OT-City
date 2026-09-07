if not SERVER then return end

local cfg = {
    webhook = "https://discord.com/api/webhooks/1493741976632430663/mX0cs2pOPQGo5WFc_NvVovHDUnrz4YkoefDiBq0MX2iPT0HTtV7xln5VrEWcEj4MLkr3",
    threshold = 3,
    window = 45,
    punish_reason = "Слив (Нейро-Агент)",
    watch_ranks = {
        ["moderator"] = true,
        ["operator"] = true,
        ["sponsor"] = true,
        ["admin"] = true,
        ["st_admin"] = true,
        ["d_head_admin"] = true
    },
    ping_roles = {
        "1469359082531066193",
        "1469359082531066190",
        "1469359082531066188",
        "1469359082514284765"
    }
}

local state = {}
local internal_action = false
local hook_name = "NKP_SAM_AntiLeak"

local function log(...)
    print("[NKP_SAM_AntiLeak]", ...)
end

local function post_webhook(title, description)
    if not cfg.webhook or cfg.webhook == "" then
        log("webhook empty")
        return
    end

    local mentions = {}
    for _, role_id in ipairs(cfg.ping_roles) do
        mentions[#mentions + 1] = "<@&" .. tostring(role_id) .. ">"
    end

    local data = {
        username = "MGuard AntiLeak",
        content = table.concat(mentions, " "),
        embeds = {{
            title = tostring(title or "Слив админки"),
            color = 15158332,
            description = tostring(description or ""),
            fields = {
                {
                    name = "Статус",
                    value = "Обнаружен массовый бан",
                    inline = false
                }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local body = util.TableToJSON(data)
    log("sending webhook...", tostring(cfg.webhook))
    log("payload:", tostring(body))

    HTTP({
        method = "POST",
        url = cfg.webhook,
        body = body,
        headers = {
            ["Content-Type"] = "application/json"
        },
        success = function(code, body, headers)
            log("webhook response code:", tostring(code))
            log("webhook response body:", tostring(body or ""))
        end,
        failed = function(err)
            log("webhook failed:", tostring(err))
        end
    })
end

local function is_watched_rank(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local rank = string.lower(tostring(ply:GetUserGroup() or ""))
    return cfg.watch_ranks[rank] == true
end

local function resolve_hash_target(num)
    num = tonumber(num)
    if not num then return nil end

    local by_index = Entity(num)
    if IsValid(by_index) and by_index:IsPlayer() then
        return by_index
    end

    for _, v in ipairs(player.GetAll()) do
        if v:UserID() == num then
            return v
        end
    end

    return nil
end

local function normalize_id(raw)
    raw = string.Trim(tostring(raw or ""))
    if raw == "" then return nil, nil, nil end

    local hash_id = raw:match("^#(%d+)$")
    if hash_id then
        local ent = resolve_hash_target(hash_id)
        if IsValid(ent) and ent:IsPlayer() then
            if ent:IsBot() then
                return "BOT_" .. ent:EntIndex(), nil, ent:Nick()
            end
            return ent:SteamID(), ent:SteamID64(), ent:Nick()
        end
        return "HASH_" .. tostring(hash_id), nil, "#" .. tostring(hash_id)
    end

    if raw:match("^STEAM_%d:%d:%d+$") then
        return raw, nil, raw
    end

    if raw:match("^7656119%d+$") then
        local sid = util.SteamIDFrom64(raw)
        return sid or raw, raw, raw
    end

    return nil, nil, nil
end

local function collect_targets(value, out, seen)
    if value == nil then return end

    if IsEntity(value) and IsValid(value) and value:IsPlayer() then
        local sid = value:IsBot() and ("BOT_" .. value:EntIndex()) or value:SteamID()
        local sid64 = value:IsBot() and nil or value:SteamID64()
        local nick = value:Nick()

        if sid and sid ~= "" and not seen[sid] then
            seen[sid] = true
            out[#out + 1] = {
                sid = sid,
                sid64 = sid64,
                nick = nick,
                is_bot = value:IsBot()
            }
        end
        return
    end

    if istable(value) then
        for k, v in pairs(value) do
            collect_targets(v, out, seen)
        end
        return
    end

    local sid, sid64, nick = normalize_id(value)
    if sid and sid ~= "" and not seen[sid] then
        seen[sid] = true
        out[#out + 1] = {
            sid = sid,
            sid64 = sid64,
            nick = nick or sid,
            is_bot = string.StartWith(sid, "BOT_") or string.StartWith(sid, "HASH_")
        }
    end
end

local function get_bucket(ply)
    local sid = ply:SteamID()
    state[sid] = state[sid] or {
        started = 0,
        targets = {},
        targets_map = {},
        flagged = false
    }
    return state[sid]
end

local function reset_bucket(bucket)
    bucket.started = 0
    bucket.targets = {}
    bucket.targets_map = {}
    bucket.flagged = false
end

local function punish_initiator(initiator, bucket)
    if not IsValid(initiator) or not initiator:IsPlayer() then
        log("punish_initiator invalid initiator")
        return
    end

    if bucket.flagged then
        log("bucket already flagged")
        return
    end

    bucket.flagged = true

    local initiator_sid = initiator:SteamID()

    local lines = {}
    lines[#lines + 1] = "Инициатор: " .. initiator:Nick() .. " (" .. initiator_sid .. ")"
    lines[#lines + 1] = "Ранг: " .. tostring(initiator:GetUserGroup() or "unknown")
    lines[#lines + 1] = "Окно: " .. tostring(cfg.window) .. " сек."
    lines[#lines + 1] = "Порог: " .. tostring(cfg.threshold)
    lines[#lines + 1] = "Целей: " .. tostring(#bucket.targets)
    lines[#lines + 1] = ""

    for i, target in ipairs(bucket.targets) do
        lines[#lines + 1] = i .. ". " .. tostring(target.nick or "unknown") .. " | " .. tostring(target.sid or "unknown")
    end

    log("threshold reached by", initiator:Nick(), initiator_sid, "targets:", #bucket.targets)
    post_webhook("Слив админки", table.concat(lines, "\n"))

    internal_action = true

    for _, target in ipairs(bucket.targets) do
        if target.sid and target.sid ~= "" and not string.StartWith(target.sid, "BOT_") and not string.StartWith(target.sid, "HASH_") then
            log("unban sid", target.sid)
            game.ConsoleCommand(string.format("sam unban \"%s\"\n", target.sid))
        end
        if target.sid64 and target.sid64 ~= "" then
            log("unban sid64", target.sid64)
            game.ConsoleCommand(string.format("sam unban \"%s\"\n", target.sid64))
        end
    end

    if initiator_sid and initiator_sid ~= "" then
        log("ban initiator", initiator_sid)
        game.ConsoleCommand(string.format("sam banid \"%s\" 0 \"%s\"\n", initiator_sid, cfg.punish_reason))
    end

    internal_action = false

    timer.Simple(1, function()
        state[initiator_sid] = nil
    end)
end

hook.Add("SAM.RanCommand", hook_name, function(ply, cmd_name, args, cmd)
    log("hook fired", tostring(ply), tostring(cmd_name))

    if internal_action then
        log("internal_action skip")
        return
    end

    if not IsValid(ply) or not ply:IsPlayer() then
        log("invalid player")
        return
    end

    if not is_watched_rank(ply) then
        log("rank not watched:", tostring(ply:GetUserGroup()))
        return
    end

    cmd_name = string.lower(tostring(cmd_name or ""))
    if cmd_name ~= "ban" and cmd_name ~= "banid" then
        log("not ban command:", cmd_name)
        return
    end

    local found = {}
    local seen = {}

    if istable(args) then
        for k, v in pairs(args) do
            log("arg", tostring(k), tostring(v))
            collect_targets(v, found, seen)
        end
    else
        log("args scalar", tostring(args))
        collect_targets(args, found, seen)
    end

    log("found targets:", #found)

    if #found == 0 then
        log("no targets resolved")
        return
    end

    local now = CurTime()
    local bucket = get_bucket(ply)

    if bucket.started == 0 or (now - bucket.started) > cfg.window then
        reset_bucket(bucket)
        bucket.started = now
        log("bucket reset/start")
    end

    for _, target in ipairs(found) do
        if target.sid and target.sid ~= ply:SteamID() and not bucket.targets_map[target.sid] then
            bucket.targets_map[target.sid] = true
            bucket.targets[#bucket.targets + 1] = target
            log("added target", tostring(target.nick), tostring(target.sid))
        end
    end

    log("bucket size:", #bucket.targets, "threshold:", cfg.threshold)

    if #bucket.targets >= cfg.threshold then
        punish_initiator(ply, bucket)
    end
end)

concommand.Add("nkp_antileak_test", function(ply)
    local lines = {
        "Инициатор: TEST (STEAM_0:0:0)",
        "Ранг: test",
        "Окно: " .. tostring(cfg.window) .. " сек.",
        "Порог: " .. tostring(cfg.threshold),
        "Целей: 3",
        "",
        "1. Test1 | STEAM_0:1:11111111",
        "2. Test2 | STEAM_0:1:22222222",
        "3. Test3 | STEAM_0:1:33333333"
    }

    log("manual test command fired")
    post_webhook("Слив админки", table.concat(lines, "\n"))
end)


//
//
//

hook.Add("OnEntityCreated","NoRagdollCollision",function(ent)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "prop_ragdoll" then return end

    timer.Simple(0,function()
        if not IsValid(ent) then return end
        ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end)
end)

//
//
//
//

TTSKey = TTSKey or ""

local AW_TTS_USER = "milky"
local AW_TTS_PASS = "JLKDFGJKSslakf32"

local TTS_FILE_PRIMARY = "otcity_tts_subs.json"
local TTS_FILE_LEGACY = "aw_tts_subs.json"
local TTS_CAP = 21 * 24 * 60 * 60

TTSSubs = TTSSubs or {}

local SyncCooldown = {}
local KeyCooldown = {}

TTSKeyTime = TTSKeyTime or 0
local LastForcedRefresh = 0

util.AddNetworkString("AW_TTS_Key")
util.AddNetworkString("AW_TTS_RequestKey")

function AW_TTS_SendKeyTo(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local key = tostring(TTSKey or "")
    ply:SetNWString("TTSKey", string.len(key) <= 190 and key or "")
    net.Start("AW_TTS_Key")
    net.WriteString(key)
    net.Send(ply)
end

local function ReadSubFile(path)
    if not file.Exists(path, "DATA") then return {} end
    local raw = file.Read(path, "DATA")
    local t = util.JSONToTable(raw or "")
    return istable(t) and t or {}
end

local function NormalizeSteamID(sid)
    sid = tostring(sid or "")
    if sid == "" then return "" end
    return sid
end

local function MergeInto(dst, src)
    for sid, exp in pairs(src or {}) do
        local key = NormalizeSteamID(sid)
        local e = tonumber(exp or 0) or 0
        if key ~= "" and e > 0 and e > (tonumber(dst[key] or 0) or 0) then
            dst[key] = e
        end
    end
    return dst
end

local function LoadTTSSubs()
    local merged = {}
    MergeInto(merged, ReadSubFile(TTS_FILE_PRIMARY))
    MergeInto(merged, ReadSubFile(TTS_FILE_LEGACY))
    TTSSubs = merged
    return TTSSubs
end

local function SaveTTSSubs()
    local json = util.TableToJSON(TTSSubs or {}, true)
    file.Write(TTS_FILE_PRIMARY, json)
    file.Write(TTS_FILE_LEGACY, json)
end

local function GetExpire(sid)
    sid = NormalizeSteamID(sid)
    if sid == "" then return 0 end
    return tonumber(TTSSubs[sid] or 0) or 0
end

local function ApplyState(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local sid = ply:SteamID()
    local exp = GetExpire(sid)
    local now = os.time()

    if exp <= 0 then
        ply:SetNWBool("TTSActive", false)
        ply:SetNWFloat("TTSExpire", 0)
        return false
    end

    if now >= exp then
        TTSSubs[sid] = nil
        SaveTTSSubs()
        ply:SetNWBool("TTSActive", false)
        ply:SetNWFloat("TTSExpire", 0)
        return false
    end

    ply:SetNWBool("TTSActive", true)
    ply:SetNWFloat("TTSExpire", exp)
    return true
end

local function ApplyStateAll()
    for _, ply in ipairs(player.GetAll()) do
        ApplyState(ply)
    end
end

function AW_TTS_Reload()
    LoadTTSSubs()
    ApplyStateAll()
    return TTSSubs
end

function AW_TTS_GetAll()
    LoadTTSSubs()
    return table.Copy(TTSSubs)
end

function AW_TTS_GetSubExpire(ply)
    LoadTTSSubs()
    if isstring(ply) then return GetExpire(ply) end
    if not IsValid(ply) then return 0 end
    return GetExpire(ply:SteamID())
end

function AW_TTS_HasSub(ply)
    return AW_TTS_GetSubExpire(ply) > os.time()
end

function AW_TTS_AddSubTimeBySteamID(sid, addSeconds)
    sid = NormalizeSteamID(sid)
    addSeconds = math.floor(tonumber(addSeconds or 0) or 0)
    if sid == "" or addSeconds <= 0 then return false, 0 end

    LoadTTSSubs()

    local now = os.time()
    local cur = GetExpire(sid)
    if cur < now then cur = now end

    local newExp = cur + addSeconds
    local capExp = now + TTS_CAP
    if newExp > capExp then newExp = capExp end

    TTSSubs[sid] = newExp
    SaveTTSSubs()

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID() == sid then
            ApplyState(p)
            break
        end
    end

    return true, newExp
end

function AW_TTS_AddSubTime(ply, addSeconds)
    if isstring(ply) then return AW_TTS_AddSubTimeBySteamID(ply, addSeconds) end
    if not IsValid(ply) then return false, 0 end
    return AW_TTS_AddSubTimeBySteamID(ply:SteamID(), addSeconds)
end

function AW_TTS_TakeSub(sid)
    sid = NormalizeSteamID(sid)
    if sid == "" then return false end
    LoadTTSSubs()
    TTSSubs[sid] = nil
    SaveTTSSubs()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID() == sid then
            ApplyState(p)
            break
        end
    end
    return true
end

local function AW_TTS_BroadcastKey()
    for _, ply in ipairs(player.GetAll()) do
        AW_TTS_SendKeyTo(ply)
    end
end

local function AW_TTS_RequestKey(url, fallbackUrl)
    http.Post(url, {
        user = AW_TTS_USER,
        pass = AW_TTS_PASS
    }, function(body)
        local data = util.JSONToTable(body or "")
        if data and data.apikey then
            TTSKey = tostring(data.apikey)
            TTSKeyTime = CurTime()
            AW_TTS_BroadcastKey()
            print("[AW_TTS] Key updated & broadcasted (" .. url .. ")")
            return
        end

        print("[AW_TTS] Key update failed:", body)
        if fallbackUrl then AW_TTS_RequestKey(fallbackUrl, nil) end
    end, function(err)
        print("[AW_TTS] HTTP error:", err)
        if fallbackUrl then AW_TTS_RequestKey(fallbackUrl, nil) end
    end)
end

local function AW_TTS_UpdateKey()
    AW_TTS_RequestKey("https://api.animeworld.space/get_apikey", "http://api.animeworld.space/get_apikey")
end

function AW_TTS_RefreshKey()
    AW_TTS_UpdateKey()
end

net.Receive("AW_TTS_RequestKey", function(len, ply)
    if not IsValid(ply) then return end

    local force = net.ReadBool()
    local sid = ply:SteamID()
    local now = CurTime()

    if (KeyCooldown[sid] or 0) > now then
        AW_TTS_SendKeyTo(ply)
        return
    end

    KeyCooldown[sid] = now + (force and 4 or 3)

    local key = tostring(TTSKey or "")
    local age = now - (TTSKeyTime or 0)

    if not force or (key ~= "" and age < 90) then
        AW_TTS_SendKeyTo(ply)
        return
    end

    if now - LastForcedRefresh < 45 then
        AW_TTS_SendKeyTo(ply)
        return
    end

    LastForcedRefresh = now
    AW_TTS_UpdateKey()

    timer.Simple(1.5, function()
        if IsValid(ply) then AW_TTS_SendKeyTo(ply) end
    end)

    timer.Simple(4, function()
        if IsValid(ply) then AW_TTS_SendKeyTo(ply) end
    end)
end)

hook.Add("Initialize", "AW_TTS_Load", function()
    LoadTTSSubs()
end)

hook.Add("InitPostEntity", "AW_TTS_Init", function()
    LoadTTSSubs()
    AW_TTS_UpdateKey()
    ApplyStateAll()
end)

LoadTTSSubs()

timer.Remove("TTSKeyUpdate")
timer.Create("TTSKeyUpdate", 240, 0, function()
    AW_TTS_UpdateKey()
end)

hook.Add("PlayerInitialSpawn", "AW_TTS_PlayerInit", function(ply)
    if not IsValid(ply) then return end

    LoadTTSSubs()
    ply:SetNWString("TTSModel", tostring(ply:GetInfo("TTSModel") or ""))
    AW_TTS_SendKeyTo(ply)
    ApplyState(ply)

    for _, delay in ipairs({ 1, 3, 6, 12 }) do
        timer.Simple(delay, function()
            if not IsValid(ply) then return end
            LoadTTSSubs()
            AW_TTS_SendKeyTo(ply)
            ApplyState(ply)
        end)
    end
end)

hook.Add("PlayerSpawn", "AW_TTS_PlayerSpawn", function(ply)
    if not IsValid(ply) then return end
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        LoadTTSSubs()
        ApplyState(ply)
    end)
end)

hook.Add("PlayerDisconnected", "AW_TTS_PlayerLeave", function(ply)
    if IsValid(ply) then
        SyncCooldown[ply:SteamID()] = nil
    end
end)

concommand.Add("ChangeTTSVoice", function(ply, cmd, args)
    if not IsValid(ply) then return end
    LoadTTSSubs()
    if not ApplyState(ply) then return end
    local model = args and args[1]
    if not model then return end
    ply:SetNWString("TTSModel", tostring(model))
end)

concommand.Add("aw_tts_sync", function(ply)
    if not IsValid(ply) then
        AW_TTS_Reload()
        return
    end

    local sid = ply:SteamID()
    local now = CurTime()
    if (SyncCooldown[sid] or 0) > now then return end
    SyncCooldown[sid] = now + 2

    LoadTTSSubs()
    AW_TTS_SendKeyTo(ply)
    ApplyState(ply)
end)

timer.Remove("AW_TTS_SubExpireTick")
timer.Create("AW_TTS_SubExpireTick", 30, 0, function()
    LoadTTSSubs()

    local now = os.time()
    local changed = false
    for sid, exp in pairs(TTSSubs) do
        local e = tonumber(exp or 0) or 0
        if e <= 0 or now >= e then
            TTSSubs[sid] = nil
            changed = true
        end
    end
    if changed then SaveTTSSubs() end

    ApplyStateAll()
end)

concommand.Add("aw_tts_refresh", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    AW_TTS_UpdateKey()
end)

concommand.Add("aw_tts_resend", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    AW_TTS_BroadcastKey()
    AW_TTS_Reload()
end)

concommand.Add("aw_tts_give", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local sid = tostring(args and args[1] or "")
    local days = tonumber(args and args[2] or 0) or 0
    if sid == "" or days <= 0 then return end

    local ok, exp = AW_TTS_AddSubTimeBySteamID(sid, days * 24 * 60 * 60)
    if ok then
        print("[AW_TTS] Given " .. days .. "d to " .. sid .. " until " .. os.date("%d.%m.%Y %H:%M", exp))
    end
end)

concommand.Add("aw_tts_take", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local sid = tostring(args and args[1] or "")
    if sid == "" then return end
    AW_TTS_TakeSub(sid)
end)

concommand.Add("aw_tts_key", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local key = tostring(TTSKey or "")
    print("[AW_TTS] key length: " .. string.len(key))
    print("[AW_TTS] key: " .. (key == "" and "<empty>" or key))
end)

concommand.Add("aw_tts_checkkey", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local key = tostring(TTSKey or "")
    if key == "" then
        print("[AW_TTS] key is empty, run aw_tts_refresh")
        return
    end

    local model = tostring(args and args[1] or "1")
    local url = "http://api.animeworld.space/tts?key=" .. key .. "&model=" .. model .. "&text=test"

    http.Fetch(url, function(body, size, headers, code)
        print("[AW_TTS] check code: " .. tostring(code) .. ", size: " .. tostring(size))
        print("[AW_TTS] check head: " .. string.sub(tostring(body or ""), 1, 200))
    end, function(err)
        print("[AW_TTS] check error: " .. tostring(err))
    end)
end)

concommand.Add("aw_tts_status", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    LoadTTSSubs()
    local now = os.time()
    for sid, exp in pairs(TTSSubs) do
        print("[AW_TTS] " .. sid .. " -> " .. os.date("%d.%m.%Y %H:%M", tonumber(exp) or 0) .. ((tonumber(exp) or 0) > now and " (active)" or " (expired)"))
    end
end)


//
//
//
//
//

RP_MySQLConfig = RP_MySQLConfig or {}

RP_MySQLConfig.Host          = "46.174.50.7"
RP_MySQLConfig.Username      = "u39635_necoder"
RP_MySQLConfig.Password      = "0T8d8A6f8A!!!!!!!"
RP_MySQLConfig.Database_name = "u39635_zcity2"
RP_MySQLConfig.Database_port = 3306

//
//
//
//
//

if STEAMID_WHITELIST == nil then STEAMID_WHITELIST = {} end

local function KickAllBots()
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:IsBot() then
            v:Kick("Вы были кикнуты администратором.")
        end
    end
end

concommand.Add("kick_all_bots", function(ply)
    if not IsValid(ply) then
        KickAllBots()
        print("[Console] Все боты были кикнуты.")
        return
    end

    if ply:IsSuperAdmin() then
        KickAllBots()
        ply:ChatPrint("Все боты были кикнуты.")
    else
        ply:ChatPrint("У вас недостаточно прав для выполнения этой команды.")
    end
end)

local IP_LIMIT = 2
local CHECK_INTERVAL = 30

local function GetIP(ply)
    if not IsValid(ply) then return nil end
    if ply:IsBot() then return nil end
    local ip = ply:IPAddress() or ""
    ip = tostring(ip):match("^([^:]+)")
    if not ip or ip == "" or ip == "0.0.0.0" then return nil end
    return ip
end

local function IsFamilySharing(ply)
    if not IsValid(ply) then return false end
    if ply:IsBot() then return false end
    if not ply.OwnerSteamID64 then return false end
    local owner64 = tostring(ply:OwnerSteamID64() or "")
    local self64 = tostring(ply:SteamID64() or "")
    if owner64 == "" or self64 == "" then return false end
    if owner64 == "0" or self64 == "0" then return false end
    return owner64 ~= self64
end

local function SafeReport(ply, reason)
    if not IsValid(ply) then return end
    if type(MilkyAC_Report) ~= "function" then return end
    MilkyAC_Report(ply, "kick", 0, tostring(reason or "Kicked"), "iplimit/familyshare")
end

local function Kick(ply, reason)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end
    local sid = ply:SteamID()
    if sid and STEAMID_WHITELIST[sid] then return end
    SafeReport(ply, reason)
    ply:Kick(reason or "Kicked")
end

local function EnforceNow()
    local byIP = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and not ply:IsBot() then
            if IsFamilySharing(ply) then
                Kick(ply, "Family Sharing запрещён")
            end
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and not ply:IsBot() then
            local ip = GetIP(ply)
            if ip then
                byIP[ip] = byIP[ip] or {}
                table.insert(byIP[ip], ply)
            end
        end
    end

    for _, list in pairs(byIP) do
        if #list > IP_LIMIT then
            table.sort(list, function(a, b)
                return (a:TimeConnected() or 0) > (b:TimeConnected() or 0)
            end)

            for i = IP_LIMIT + 1, #list do
                Kick(list[i], "С одного IP разрешено не более 2 аккаунтов")
            end
        end
    end
end

hook.Add("PlayerInitialSpawn", "pekarna_antishare_iplimit_spawncheck", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        if not ply:IsBot() then
            if IsFamilySharing(ply) then
                Kick(ply, "Family Sharing запрещён")
                return
            end
            EnforceNow()
        end
    end)
end)

hook.Add("PlayerDisconnected", "pekarna_antishare_iplimit_disconnectcheck", function()
    timer.Simple(1, EnforceNow)
end)

timer.Create("pekarna_antishare_iplimit_periodic", CHECK_INTERVAL, 0, function()
    EnforceNow()
end)

hook.Add("Initialize", "pekarna_antishare_iplimit_boot", function()
    timer.Simple(10, EnforceNow)
end)

local CLASSES_TO_REMOVE = {
    env_sprite = true,
    spotlight_end = true,
    beam = true,
    point_spotlight = true
}

local function CleanupVisualEdicts(reason)
    local removed = {}
    local total = 0

    for class in pairs(CLASSES_TO_REMOVE) do
        local n = 0
        for _, ent in ipairs(ents.FindByClass(class)) do
            if IsValid(ent) then
                ent:Remove()
                n = n + 1
            end
        end
        removed[class] = n
        total = total + n
    end

    print("[EDICT CLEANUP] Reason:", reason, "| removed:", total, "| ents:", #ents.GetAll())
    for class, count in pairs(removed) do
        if count > 0 then
            print(string.format("  %s: %d", class, count))
        end
    end
end

local function ScheduleStartupSweeps()
    local delays = { 1, 5, 15, 30, 60 }
    for _, d in ipairs(delays) do
        timer.Simple(d, function()
            CleanupVisualEdicts("startup+" .. d .. "s")
        end)
    end
end

hook.Add("InitPostEntity", "EdictCleanup_OnMapLoad", function()
    ScheduleStartupSweeps()
end)

hook.Add("PlayerInitialSpawn", "EdictCleanup_OnFirstJoin", function()
    if GetGlobalBool("EdictCleanup_FirstJoinDone", false) then return end
    SetGlobalBool("EdictCleanup_FirstJoinDone", true)

    timer.Simple(2, function()
        CleanupVisualEdicts("first player joined")
    end)

    timer.Simple(10, function()
        CleanupVisualEdicts("first player joined +10s")
    end)
end)

hook.Add("PostCleanupMap", "EdictCleanup_OnCleanup", function()
    timer.Simple(1, function()
        CleanupVisualEdicts("map cleanup")
    end)
end)

hook.Add("OnEntityCreated", "EdictCleanup_BlockCreate", function(ent)
    if not IsValid(ent) then return end
    local cls = ent:GetClass()
    if not CLASSES_TO_REMOVE[cls] then return end
    timer.Simple(0, function()
        if IsValid(ent) then ent:Remove() end
    end)
end)

//
//
//