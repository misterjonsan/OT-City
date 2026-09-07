local lines = {
    [[ ]],
    [[ ]],
    [[═══ 🛡️ Д.Ж.А.Р.В.И.С - К вашим услугам 🛡️ ═══]]
}

for i = 1, #lines do MsgC(Color(3, 169, 244), lines[i] .. "\n") end

if not SERVER then return end

MilkyAC = MilkyAC or {}
MilkyAC.Version = "2026-07-22-stable"
MilkyAC.EnableExpensiveAimChecks = false
MilkyAC.EnableGlobalNetWritePatch = false
MilkyAC.DisableNetKicks = true
MilkyAC.DisableReliableOverflowPunish = true

local STEAMID_WHITELIST = {
}

util.AddNetworkString("milkyac_change")
util.AddNetworkString("milkyac_caught")

local AC_REPORT_URL = ""
local AC_REPORT_SECRET = ""

local function _sid(ply)
    if not IsValid(ply) then return "invalid" end
    return ply:SteamID64() or ply:SteamID() or tostring(ply)
end

local function _isWL(ply)
    return IsValid(ply) and STEAMID_WHITELIST[ply:SteamID()] == true
end

local function _ipOnly(ply)
    if not IsValid(ply) then return "" end
    local ip = tostring(ply:IPAddress() or "")
    ip = ip:match("^([^:]+)") or ip
    return ip
end

local function _trim(s)
    s = tostring(s or "")
    s = s:gsub("[%c]", " ")
    s = s:gsub("%s+", " ")
    if s.Trim then s = s:Trim() end
    return s
end

local function _clampReason(s, n)
    s = _trim(s)
    n = tonumber(n or 160) or 160
    if #s > n then s = s:sub(1, n) end
    return s
end

local function _normReason(s)
    s = _trim(s)
    if #s > 220 then s = s:sub(1, 220) end
    return s
end

local MILKY_REPORT_DEDUP = MILKY_REPORT_DEDUP or {}

local function _reportKey(ply, action, reason)
    local sid = IsValid(ply) and (ply:SteamID64() or ply:SteamID() or "0") or "0"
    local r = tostring(reason or ""):lower()
    r = r:gsub("[%c]", " ")
    r = r:gsub("%s+", " ")
    r = r:gsub("0x%x+", "0x*")
    r = r:gsub("%d%d%d%d%d+", "*")
    if #r > 120 then r = r:sub(1, 120) end
    return sid .. "|" .. tostring(action or "") .. "|" .. r
end

local function _reportAllow(ply, action, reason)
    local key = _reportKey(ply, action, reason)
    local now = CurTime()
    local rec = MILKY_REPORT_DEDUP[key]
    if rec and rec > now then return false end
    MILKY_REPORT_DEDUP[key] = now + 12
    return true
end

local function MilkyAC_Report(ply, action, length, reason, extra)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    reason = _clampReason(reason, 180)
    extra = _clampReason(extra, 180)
    if not _reportAllow(ply, action, reason) then return end
    local hostname = GetConVar("hostname") and GetConVar("hostname"):GetString() or "unknown"
    local serverip = GetConVar("ip") and GetConVar("ip"):GetString() or ""
    local serverport = GetConVar("hostport") and GetConVar("hostport"):GetString() or ""
    pcall(function()
        http.Post(AC_REPORT_URL, {
            secret = AC_REPORT_SECRET,
            ts = tostring(os.time()),
            hostname = hostname,
            map = game.GetMap() or "",
            server_ip = serverip,
            server_port = serverport,
            action = tostring(action or ""),
            length = tostring(tonumber(length or 0) or 0),
            reason = reason,
            extra = extra,
            nick = ply:Nick() or "",
            steamid = ply:SteamID() or "",
            steamid64 = ply:SteamID64() or "",
            ip = _ipOnly(ply),
        }, function() end, function() end)
    end)
end

function MilkyAC_Punish(ply, length, pMessage)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    if ply.isAlreadyBanned or ply.MilkyACAlreadyPunished then return end
    ply.isAlreadyBanned = true
    ply.MilkyACAlreadyPunished = true
    length = tonumber(length or 0) or 0
    pMessage = _clampReason(pMessage or "unknown", 180)
    MilkyAC_Report(ply, "ban", length, pMessage, "")
    if ulx and ULib and ULib.ban then
        ULib.ban(ply, length, pMessage)
        if IsValid(ply) then ply:Kick(pMessage) end
    elseif xAdmin then
        xAdmin.RegisterNewBan(ply, "CONSOLE", pMessage, length)
        if IsValid(ply) then ply:Kick(pMessage) end
    elseif SAM then
        SAM.AddBan(ply:SteamID(), nil, length * 60, pMessage)
        if IsValid(ply) then ply:Kick(pMessage) end
    else
        ply:Ban(length, false)
        if IsValid(ply) then ply:Kick(pMessage) end
    end
    PrintMessage(HUD_PRINTTALK, "[K.A.S.П.E.R.S.K.Y] " .. (ply:Nick() or "Игрок") .. " был забанен за '" .. pMessage .. "'!")
    hook.Run("MilkyAC", ply:Nick(), ply:SteamID(), length, pMessage)
end

local function _isNoKickReason(reason)
    local r = string.lower(tostring(reason or ""))
    if string.find(r, "overflow", 1, true) then return true end
    if string.find(r, "reliable channel", 1, true) then return true end
    if string.find(r, "net flood", 1, true) then return true end
    if string.find(r, "client net", 1, true) then return true end
    if string.find(r, "bad net", 1, true) then return true end
    if string.find(r, "payload", 1, true) then return true end
    if string.find(r, "unknown net", 1, true) then return true end
    if string.find(r, "net exploit", 1, true) then return true end
    if string.find(r, "эксплойт", 1, true) then return true end
    if string.find(r, "эксплоит", 1, true) then return true end
    return false
end

local function MilkyAC_Kick(ply, pMessage)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    pMessage = _clampReason(pMessage or "Отключите читы!", 180)
    if MilkyAC.DisableNetKicks and _isNoKickReason(pMessage) then
        MilkyAC_Report(ply, "kick_suppressed", 0, pMessage, "net_kicks_disabled=1")
        hook.Run("MilkyACKickSuppressed", ply:Nick(), ply:SteamID(), pMessage)
        return
    end
    if ply.isAlreadyKicked or ply.MilkyACAlreadyKicked or ply.MilkyACAlreadyPunished then return end
    ply.isAlreadyKicked = true
    ply.MilkyACAlreadyKicked = true
    MilkyAC_Report(ply, "kick", 0, pMessage, "")
    hook.Run("MilkyACKick", ply:Nick(), ply:SteamID(), pMessage)
    ply:Kick(pMessage)
end

local NOISE_PATTERNS = {
    "cookiegetstring / zov_def_cfg",
    "cookiegetstring / zovgame_friends",
    "increasing buffer size for snapshot payload",
    "senddata reliable data too big",
    "overflowed reliable channel",
    "reliable channel",
    "client overflow",
    "client 1 overflowed reliable channel",
    "client_net_error",
    "client net error",
    "net overflow",
    "net flood",
    "bad net payload",
}

local function _isNoise(reason)
    local r = string.lower(tostring(reason or ""))
    for i = 1, #NOISE_PATTERNS do
        if string.find(r, NOISE_PATTERNS[i], 1, true) then return true end
    end
    return false
end

local function _containsAny(r, arr)
    for i = 1, #arr do
        if string.find(r, arr[i], 1, true) then return true end
    end
    return false
end

local HOOK_EVENT_SIGS = {
    "createmove","startcommand","setupmove","inputmouseapply","calcview","calcviewmodelview","renderscene","postrenderscene",
    "hudpaint","postdrawhud","drawoverlay","postdrawopaque","postdrawtranslucentrenderables","preplayerdraw","postplayerdraw",
    "think","tick","predrawhalos","renderhalos","getrendertarget","rendercapture","playerbindpress","preprocesschat","onplayerchat",
    "guimousepressed","guimousereleased","keypress","keyrelease","entityemitsound","addentityrelationship","netreceive",
    "predrawskybox","postdraw2dskybox","renderscreenspaceeffects","shoulddrawlocalplayer","prerender","postrender",
}

local CONCOMMAND_SIGS = {
    "aim","aimbot","trigger","trig","wall","wallhack","esp","chams","bhop","bunny","lua_run","lua_openscript",
    "lua_run_cl","lua_run_sv","bind","alias","connect","retry","disconnect","host_timescale",
}

local VGUI_SIGS = {
    "dhtml","html","web","frame","menu","derma","panel","propertysheet","canvas",
}

local HARD_BAN_PATTERNS = {
    "lua_openscript_cl silkware.lua","sw_aimbot","sw_antiaim","sw_aa_mouse","silkwarecfgs","createmove_aimbot",
    "think_aimbotcache","aimbot_fov_circle","runstring","compilestring",".dll",
}

local INSTANT_SUS_PATTERNS = {
    "hookadd / aimbot","hookadd / aimbot_","hookadd / wallhack","concommandadd / aimbot","concommandadd / wallhack",
    "vguicreate / aimbot","vguicreate / wallhack","/ aimbot_","/ wallhack"," / loki"," / spiritwalk"," / lowkey",
    "aimbot_think","silkware","sw_aimbot","sw_antiaim","wallhack","silentaim","triggerbot",
}

local SILKWARE_PATTERNS = {
    "silkware","lua_openscript_cl silkware.lua","silkwarecfgs","sw_title","sw_tab","sw_group","sw_elem","sw_small",
    "sw_btn","sw_esp_name","sw_esp_info","sw_esp_small","sw_esp_tiny","createmove_aimbot","createmove_antiaim",
    "think_aimbotcache","inputmouseapply / sw_aa_mouse","renderscreenspaceeffects / sw_worldcolor","predrawskybox / sw",
    "postdraw2dskybox / sw","sw_calcview_fallback","homigrad-view","renderhelmetthingy","unload silkware",
    "aimbot_fov_circle","no recoil","no spread","no sway","fast zoom",
}

local function _isHookAdd(reason)
    local r = string.lower(tostring(reason or ""))
    return string.find(r, "hookadd", 1, true) ~= nil or string.find(r, "hook.add", 1, true) ~= nil
end

local function _isHookRandBypass(reasonLower)
    local r = reasonLower or ""
    if not _isHookAdd(r) then return false end
    for i = 1, #HOOK_EVENT_SIGS do
        if string.find(r, HOOK_EVENT_SIGS[i], 1, true) then return true end
    end
    return true
end

local function _isConcommandRandBypass(reasonLower)
    local r = reasonLower or ""
    if not (string.find(r, "concommandadd", 1, true) or string.find(r, "concommand.add", 1, true)) then return false end
    for i = 1, #CONCOMMAND_SIGS do
        if string.find(r, CONCOMMAND_SIGS[i], 1, true) then return true end
    end
    return false
end

local function _isVguiRandBypass(reasonLower)
    local r = reasonLower or ""
    if not (string.find(r, "vguicreate", 1, true) or string.find(r, "vgui.create", 1, true)) then return false end
    for i = 1, #VGUI_SIGS do
        if string.find(r, VGUI_SIGS[i], 1, true) then return true end
    end
    return false
end

local function _isSilkWare(reason)
    local r = string.lower(tostring(reason or ""))
    return _containsAny(r, SILKWARE_PATTERNS)
end

local function _isHardBan(reason)
    local r = string.lower(tostring(reason or ""))
    if _isHookAdd(r) then return true end
    if _containsAny(r, HARD_BAN_PATTERNS) then return true end
    if string.find(r, "require", 1, true) and string.find(r, ".dll", 1, true) then return true end
    if string.find(r, "runstring", 1, true) then return true end
    if string.find(r, "compilestring", 1, true) then return true end
    return false
end

local function _isInstantSus(reason)
    local r = string.lower(tostring(reason or ""))
    if _isHookAdd(r) then return true end
    if _containsAny(r, INSTANT_SUS_PATTERNS) then return true end
    if _isSilkWare(r) then return true end
    if _isHookRandBypass(r) then return true end
    if _isConcommandRandBypass(r) and (string.find(r, "aim", 1, true) or string.find(r, "esp", 1, true) or string.find(r, "wall", 1, true) or string.find(r, "chams", 1, true) or string.find(r, "trigger", 1, true)) then return true end
    if _isVguiRandBypass(r) and (string.find(r, "dhtml", 1, true) or string.find(r, "html", 1, true) or string.find(r, "menu", 1, true)) then return true end
    return false
end

local function _isIncludeExploit(reason)
    local r = string.lower(tostring(reason or ""))
    if not (string.find(r, "include", 1, true) or string.find(r, "couldn't include", 1, true)) then return false end
    if string.find(r, "not a .lua file", 1, true) then return true end
    if string.find(r, "couldn't include file", 1, true) then return true end
    if string.find(r, "lua\\", 1, true) or string.find(r, "lua/", 1, true) then
        if string.find(r, "%.lua%p", 1, false) then return true end
        if string.find(r, "%.lua/", 1, false) or string.find(r, "%.lua\\", 1, false) then return true end
        if string.find(r, "%.lua%s*['\"]%s*[%/%\\]", 1, false) then return true end
    end
    if string.find(r, "%.lua%\\", 1, false) or string.find(r, "%.lua%/", 1, false) then return true end
    if string.find(r, "%.lua[%c%s]*[%/%\\]", 1, false) then return true end
    if string.find(r, "compilestring", 1, true) then return true end
    if string.find(r, "runstring", 1, true) then return true end
    return false
end

local function _sigFamily(reason)
    local r = string.lower(tostring(reason or ""))
    if string.find(r, "client_net_error", 1, true) then return "clientnet" end
    if _isHookAdd(r) then return "hooks" end
    if _isSilkWare(r) then return "silkware" end
    if _isHardBan(r) then return "hard" end
    if _isInstantSus(r) then return "cheat_sig" end
    if _isIncludeExploit(r) then return "include" end
    if string.find(r, "integrity:", 1, true) then return "integrity" end
    if string.find(r, "integrity/", 1, true) then return "integrity" end
    if string.find(r, "scan:", 1, true) then return "scan" end
    if string.find(r, "net=", 1, true) then return "net" end
    if string.find(r, "convar", 1, true) then return "convar" end
    if string.find(r, "zovgame_menu", 1, true) then return "ui" end
    if string.find(r, "ac_detect", 1, true) then return "meta" end
    if string.find(r, "concommandadd", 1, true) or string.find(r, "concommand.add", 1, true) then return "concmd" end
    if string.find(r, "vguicreate", 1, true) or string.find(r, "vgui.create", 1, true) then return "vgui" end
    return "other"
end

local function _extractNetName(reason)
    local r = string.lower(tostring(reason or ""))
    local n = r:match("net=([^%s]+)")
    if not n then return "unknown" end
    n = n:gsub("[^%w_%-/%.]", ""):sub(1, 64)
    return n ~= "" and n or "unknown"
end

local MILKY_SUS = MILKY_SUS or {}
local MILKY_DETECT_FILTER = MILKY_DETECT_FILTER or {}
local MILKY_CLIENTNET = MILKY_CLIENTNET or {}
local MILKY_CLIENTNET_ESC = MILKY_CLIENTNET_ESC or {}
local MILKY_AIMWATCH = MILKY_AIMWATCH or {}

local function _sus(ply)
    local id = _sid(ply)
    MILKY_SUS[id] = MILKY_SUS[id] or {
        score = 0,
        strikes = 0,
        last = 0,
        lastReason = "",
        caughtBurst = 0,
        caughtNext = CurTime() + 1,
        fam = {},
        spamWarnNext = 0,
        reasons = {},
        highMarks = 0,
    }
    return MILKY_SUS[id], id
end

local function _df(ply)
    local id = _sid(ply)
    MILKY_DETECT_FILTER[id] = MILKY_DETECT_FILTER[id] or {
        w10_t = CurTime(),
        w10_n = 0,
        w60_t = CurTime(),
        w60_n = 0,
        uniq_t = CurTime(),
        uniq_map = {},
        key = {},
        api_t = SysTime(),
        api_tok = 3,
        api_key_t = {},
        print_t = 0,
    }
    return MILKY_DETECT_FILTER[id], id
end

local function _cn(ply)
    local id = _sid(ply)
    MILKY_CLIENTNET[id] = MILKY_CLIENTNET[id] or {
        w10_t = CurTime(),
        w10_n = 0,
        w60_t = CurTime(),
        w60_n = 0,
        nets_t = CurTime(),
        nets = {},
        hard_t = CurTime(),
        hard_n = 0,
    }
    return MILKY_CLIENTNET[id], id
end

local function _cnEsc(ply)
    local id = _sid(ply)
    MILKY_CLIENTNET_ESC[id] = MILKY_CLIENTNET_ESC[id] or { t = CurTime(), k = 0, w = 0 }
    return MILKY_CLIENTNET_ESC[id], id
end

local function _aw(ply)
    local id = _sid(ply)
    MILKY_AIMWATCH[id] = MILKY_AIMWATCH[id] or {
        nextScan = 0,
        lastAng = nil,
        snapScore = 0,
        wallHead = 0,
        directHead = 0,
        occludedLock = 0,
        visibleLock = 0,
        shotBursts = 0,
        headshots = 0,
        totalHits = 0,
        totalShots = 0,
        lastShot = 0,
        lastTarget = nil,
        lastSeen = 0,
        punishCd = 0,
        aimTime = 0,
        scanHits = 0,
        stableLock = 0,
        snapEvents = 0,
    }
    return MILKY_AIMWATCH[id], id
end

local function _cnEscFlag(ply)
    local st = _cnEsc(ply)
    local now = CurTime()
    if now - (st.t or now) >= 1800 then
        st.t = now
        st.k = 0
        st.w = 0
    end
    st.k = (st.k or 0) + 1
    if st.k >= 4 then
        st.w = (st.w or 0) + 1
        if st.w >= 3 then return "ban", "clientnet_repeat" end
        return "kick", "clientnet_repeat_warn"
    end
    return "none"
end

local function _cn_allow(ply, reason)
    local st = _cn(ply)
    local now = CurTime()
    if now - (st.w10_t or now) >= 10 then
        st.w10_t = now
        st.w10_n = 0
    end
    if now - (st.w60_t or now) >= 60 then
        st.w60_t = now
        st.w60_n = 0
    end
    st.w10_n = (st.w10_n or 0) + 1
    st.w60_n = (st.w60_n or 0) + 1
    local netname = _extractNetName(reason)
    if now - (st.nets_t or now) >= 25 then
        st.nets_t = now
        st.nets = {}
    end
    st.nets[netname] = true
    local uniq = 0
    for _ in pairs(st.nets) do uniq = uniq + 1 end
    local lr = string.lower(tostring(reason or ""))
    local hard = (string.find(lr, "couldn't read type", 1, true) ~= nil) or (string.find(lr, "readtype", 1, true) ~= nil)
    if hard then
        if now - (st.hard_t or now) >= 20 then
            st.hard_t = now
            st.hard_n = 0
        end
        st.hard_n = (st.hard_n or 0) + 1
    end
    if (st.w10_n or 0) >= 12 or (st.w60_n or 0) >= 32 or uniq >= 8 or (st.hard_n or 0) >= 6 then
        MilkyAC_Report(ply, "clientnet_suppressed", 0, "client net error ignored", "net=" .. tostring(netname) .. ";uniq=" .. tostring(uniq) .. ";w10=" .. tostring(st.w10_n) .. ";w60=" .. tostring(st.w60_n))
    end
    return false, netname, uniq, st.w10_n, st.w60_n
end

local function _df_norm(reason)
    reason = tostring(reason or "")
    if #reason > 300 then reason = reason:sub(1, 300) end
    reason = reason:gsub("[%c]", " "):gsub("%s+", " ")
    if reason.Trim then reason = reason:Trim() end
    reason = reason:gsub("\\", "/")
    reason = reason:gsub("['\"]", "")
    reason = reason:gsub("/+", "/")
    reason = reason:gsub("0x%x+", "0x*")
    reason = reason:gsub("%d%d%d%d%d+", "*")
    reason = reason:gsub("addons/[^%s]+", "addons/*")
    reason = reason:gsub("lua/[^%s]+", "lua/*")
    reason = reason:gsub("%.lua/+", ".lua/")
    reason = reason:gsub("%.lua%p+", ".lua*")
    reason = reason:gsub("%f[%w][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-]+%f[^%w]", "*")
    return string.lower(reason)
end

local function _df_key(fam, reason)
    local r = _df_norm(reason)
    if #r > 140 then r = r:sub(1, 140) end
    return fam .. "|" .. r
end

local function _df_api_allow(st, key, fam)
    local now = SysTime()
    local dt = now - (st.api_t or now)
    st.api_t = now
    st.api_tok = math.min(2, (st.api_tok or 0) + dt * 0.35)
    if (st.api_tok or 0) < 1 then return false end
    local kt = st.api_key_t[key]
    local cd = fam == "hard" and 12 or 25
    if kt and (now - kt) < cd then return false end
    st.api_tok = st.api_tok - 1
    st.api_key_t[key] = now
    return true
end

local function _df_allow(ply, reason, fam)
    local st = _df(ply)
    local now = CurTime()
    local key = _df_key(fam, reason)
    if now - (st.w10_t or now) >= 10 then
        st.w10_t = now
        st.w10_n = 0
    end
    if now - (st.w60_t or now) >= 60 then
        st.w60_t = now
        st.w60_n = 0
    end
    st.w10_n = (st.w10_n or 0) + 1
    st.w60_n = (st.w60_n or 0) + 1
    if now - (st.uniq_t or now) >= 25 then
        st.uniq_t = now
        st.uniq_map = {}
    end
    st.uniq_map[key] = true
    local uniq = 0
    for _ in pairs(st.uniq_map) do uniq = uniq + 1 end
    if (st.w60_n or 0) >= 90 then return "kick", key, st, "flood60" end
    if (st.w10_n or 0) >= 18 then return "kick", key, st, "flood10" end
    if uniq >= 22 then return "kick", key, st, "uniq25" end
    st.key = st.key or {}
    local ks = st.key[key]
    if not ks then
        ks = { next = 0, last = 0, cd = 8 }
        st.key[key] = ks
    end
    if now < (ks.next or 0) then return false, key, st end
    local dt = now - (ks.last or 0)
    ks.last = now
    local cd
    if dt < 2.0 then
        cd = math.min(120, math.max(8, (ks.cd or 8) * 2))
    else
        cd = math.max(8, math.floor((ks.cd or 8) * 0.9))
    end
    ks.cd = cd
    ks.next = now + cd
    return true, key, st
end

local function _famCount(st)
    local n = 0
    for _, v in pairs(st.fam or {}) do
        if v and v > 0 then n = n + 1 end
    end
    return n
end

local function _addSus(ply, pts, reason)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    local st = _sus(ply)
    local now = CurTime()
    if now >= (st.caughtNext or 0) then
        st.caughtNext = now + 1
        st.caughtBurst = 0
    end
    st.caughtBurst = (st.caughtBurst or 0) + 1
    if st.caughtBurst > 4 then
        if (st.spamWarnNext or 0) <= now then
            st.spamWarnNext = now + 30
            MilkyAC_Report(ply, "rate_limit", 0, "milkyac_caught burst limited", "")
        end
        return
    end
    pts = tonumber(pts or 0) or 0
    if pts <= 0 then return end
    reason = _clampReason(reason, 160)
    st.score = (st.score or 0) + pts
    st.last = now
    st.lastReason = tostring(reason or "")
    st.fam = st.fam or {}
    local fam = _sigFamily(reason)
    st.fam[fam] = (st.fam[fam] or 0) + 1
    st.reasons[#st.reasons + 1] = reason
    if #st.reasons > 6 then table.remove(st.reasons, 1) end
    if pts >= 24 then st.highMarks = (st.highMarks or 0) + 1 end
    local famCount = _famCount(st)
    if st.score >= 140 and famCount >= 3 then
        st.strikes = (st.strikes or 0) + 1
        local msg = "AC detect (" .. tostring(math.floor(st.score)) .. ") " .. tostring(st.lastReason or "")
        MilkyAC_Report(ply, "detect", 0, msg, "score=" .. tostring(st.score) .. ";fam=" .. tostring(famCount))
        if st.strikes >= 2 or st.highMarks >= 3 then
            return MilkyAC_Punish(ply, 0, msg)
        else
            return MilkyAC_Kick(ply, msg)
        end
    end
    if st.score >= 95 and famCount >= 2 and st.highMarks >= 2 then
        st.strikes = (st.strikes or 0) + 1
        local msg = "AC high confidence (" .. tostring(math.floor(st.score)) .. ") " .. tostring(st.lastReason or "")
        MilkyAC_Report(ply, "detect", 0, msg, "score=" .. tostring(st.score) .. ";fam=" .. tostring(famCount))
        if st.strikes >= 2 then return MilkyAC_Punish(ply, 0, msg) else return MilkyAC_Kick(ply, msg) end
    end
end

local function _scoreReason(reason)
    local r = string.lower(tostring(reason or ""))
    if _isHardBan(r) then return 999 end
    local pts = 0
    if _isIncludeExploit(r) then pts = pts + 70 end
    if string.find(r, "couldn't include", 1, true) then pts = pts + 16 end
    if string.find(r, "not a .lua file", 1, true) then pts = pts + 22 end
    if string.find(r, "aimbot", 1, true) then pts = pts + 20 end
    if string.find(r, "wallhack", 1, true) then pts = pts + 18 end
    if string.find(r, "esp", 1, true) then pts = pts + 12 end
    if string.find(r, "chams", 1, true) then pts = pts + 12 end
    if string.find(r, "trigger", 1, true) then pts = pts + 14 end
    if string.find(r, "silentaim", 1, true) then pts = pts + 20 end
    if string.find(r, "triggerbot", 1, true) then pts = pts + 18 end
    if string.find(r, "antiaim", 1, true) then pts = pts + 16 end
    if string.find(r, "loki", 1, true) then pts = pts + 16 end
    if string.find(r, "spiritwalk", 1, true) then pts = pts + 16 end
    if string.find(r, "lowkey", 1, true) then pts = pts + 16 end
    if _isSilkWare(r) then pts = pts + 30 end
    if _isHookRandBypass(r) then pts = pts + 12 end
    if _isConcommandRandBypass(r) then pts = pts + 10 end
    if _isVguiRandBypass(r) then pts = pts + 8 end
    if string.find(r, "integrity:openinv", 1, true) then pts = pts + 6 end
    if string.find(r, "integrity/openinv", 1, true) then pts = pts + 6 end
    if string.find(r, "integrity:vp", 1, true) then pts = pts + 4 end
    if string.find(r, "integrity:viewpunch", 1, true) then pts = pts + 4 end
    if string.find(r, "integrity:renderscene", 1, true) then pts = pts + 4 end
    if string.find(r, "zovgame_menu", 1, true) then pts = pts + 4 end
    if string.find(r, "net=bscreengrabstart", 1, true) then pts = pts + 3 end
    if string.find(r, "net=should_open_inv", 1, true) then pts = pts + 2 end
    if string.find(r, "net=ply_take_item", 1, true) then pts = pts + 2 end
    if string.find(r, "ac_detect", 1, true) then pts = pts + 2 end
    if string.find(r, "runstring", 1, true) then pts = pts + 999 end
    if string.find(r, "compilestring", 1, true) then pts = pts + 999 end
    if string.find(r, "require", 1, true) and string.find(r, ".dll", 1, true) then pts = pts + 999 end
    return pts
end

local BAD_NET_VALUE_TYPES = {
    ["function"] = true,
    ["thread"] = true,
    ["userdata"] = true,
}

local function _safeScalar(v)
    local tv = type(v)
    if BAD_NET_VALUE_TYPES[tv] then return nil, true, tv end
    if tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return 0, true, "bad_number" end
        return v, false
    end
    if tv == "string" then
        if #v > 8192 then return v:sub(1, 8192), true, "long_string" end
        return v, false
    end
    return v, false
end

local function _sanitizeForNet(value, depth, seen, path, removed)
    depth = depth or 0
    seen = seen or {}
    path = path or "root"
    removed = removed or {}
    if depth > 8 then
        removed[#removed + 1] = path .. "=max_depth"
        return nil, removed
    end
    local tv = type(value)
    if tv ~= "table" then
        local nv, bad, why = _safeScalar(value)
        if bad then removed[#removed + 1] = path .. "=" .. tostring(why or tv) end
        return nv, removed
    end
    if seen[value] then
        removed[#removed + 1] = path .. "=recursive"
        return nil, removed
    end
    seen[value] = true
    local out = {}
    local count = 0
    for k, v in pairs(value) do
        count = count + 1
        if count > 512 then
            removed[#removed + 1] = path .. "=too_many_keys"
            break
        end
        local nk
        nk, removed = _sanitizeForNet(k, depth + 1, seen, path .. ".key", removed)
        if nk ~= nil then
            local keyText = tostring(nk)
            if #keyText > 48 then keyText = keyText:sub(1, 48) end
            local nv
            nv, removed = _sanitizeForNet(v, depth + 1, seen, path .. "." .. keyText, removed)
            if nv ~= nil then out[nk] = nv end
        end
    end
    seen[value] = nil
    return out, removed
end

function MilkyAC.SanitizeForNet(value)
    return _sanitizeForNet(value, 0, {}, "root", {})
end

function MilkyAC.SafeNetVar(value)
    local safe, removed = MilkyAC.SanitizeForNet(value)
    return safe, removed
end

if MilkyAC.EnableGlobalNetWritePatch and not MilkyAC.NetWritePatched then
    MilkyAC.NetWritePatched = true
    local oldWriteTable = net.WriteTable
    local oldWriteType = net.WriteType
    function net.WriteTable(tab, seq)
        local safe, removed = MilkyAC.SanitizeForNet(tab)
        if removed and #removed > 0 then
            MsgC(Color(255, 193, 7), "[MilkyAC] net.WriteTable sanitized: " .. table.concat(removed, "; "):sub(1, 500) .. "\n")
        end
        return oldWriteTable(safe or {}, seq)
    end
    function net.WriteType(v)
        local tv = type(v)
        if BAD_NET_VALUE_TYPES[tv] then
            MsgC(Color(255, 87, 34), "[MilkyAC] blocked net.WriteType bad value: " .. tv .. "\n")
            return oldWriteType(nil)
        end
        if tv == "table" then
            local safe, removed = MilkyAC.SanitizeForNet(v)
            if removed and #removed > 0 then
                MsgC(Color(255, 193, 7), "[MilkyAC] net.WriteType table sanitized: " .. table.concat(removed, "; "):sub(1, 500) .. "\n")
            end
            return oldWriteType(safe or {})
        end
        if tv == "number" and (v ~= v or v == math.huge or v == -math.huge) then return oldWriteType(0) end
        return oldWriteType(v)
    end
end

MilkyAC_StreamLimiter = MilkyAC_StreamLimiter or {}
MilkyAC_StreamLimiter.State = MilkyAC_StreamLimiter.State or {}
MilkyAC_StreamLimiter.Default = { rate = 12, burst = 24, maxBytes = 4096 }

local function _tok(ply, key, cfg)
    cfg = cfg or MilkyAC_StreamLimiter.Default
    local id = _sid(ply)
    MilkyAC_StreamLimiter.State[id] = MilkyAC_StreamLimiter.State[id] or {}
    local st = MilkyAC_StreamLimiter.State[id][key]
    local now = SysTime()
    if not st then
        st = { t = cfg.burst, last = now }
        MilkyAC_StreamLimiter.State[id][key] = st
    end
    local dt = now - st.last
    st.last = now
    st.t = math.min(cfg.burst, st.t + dt * cfg.rate)
    if st.t >= 1 then
        st.t = st.t - 1
        return true
    end
    return false
end

local MILKY_GLOBAL_NET = MILKY_GLOBAL_NET or {}
local MILKY_NET_NAME_STATE = MILKY_NET_NAME_STATE or {}
local MILKY_NET_UNKNOWN = MILKY_NET_UNKNOWN or {}
local MILKY_NET_READERR = MILKY_NET_READERR or {}

local BLOCKED_NET_NAMES = {
    ["update_store_freebodygroupr"] = true,
    ["announcementadmin"] = true,
    ["standpose_server"] = true,
}

local STRICT_NET_NAMES = {
    ["zbnetvarset"] = { rate = 12, burst = 24, maxBytes = 16384, action = "drop" },
    ["hmcd_updatetraitorassistants"] = { rate = 12, burst = 24, maxBytes = 16384, action = "drop" },
    ["milkyac_change"] = { rate = 8, burst = 16, maxBytes = 1024, action = "drop" },
    ["milkyac_caught"] = { rate = 6, burst = 12, maxBytes = 2048, action = "drop" },
}

local function _gstate(ply)
    if not IsValid(ply) then return nil end
    local id = _sid(ply)
    MILKY_GLOBAL_NET[id] = MILKY_GLOBAL_NET[id] or {
        next = CurTime() + 1,
        msgs = 0,
        bytes = 0,
        strikes = 0,
        blockedUntil = 0,
        tenNext = CurTime() + 10,
        tenMsgs = 0,
        tenBytes = 0,
    }
    return MILKY_GLOBAL_NET[id], id
end

local function _nameState(ply, name)
    local id = _sid(ply)
    MILKY_NET_NAME_STATE[id] = MILKY_NET_NAME_STATE[id] or {}
    name = tostring(name or "unknown"):lower()
    MILKY_NET_NAME_STATE[id][name] = MILKY_NET_NAME_STATE[id][name] or { t = SysTime(), tok = 16, strikes = 0, last = CurTime() }
    return MILKY_NET_NAME_STATE[id][name]
end

local function _netToken(st, rate, burst)
    local now = SysTime()
    local dt = now - (st.t or now)
    st.t = now
    st.tok = math.min(burst, (st.tok or burst) + dt * rate)
    if st.tok >= 1 then
        st.tok = st.tok - 1
        return true
    end
    return false
end

local function _globalAllow(ply, lenBits)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if ply:IsBot() then return true end
    if _isWL(ply) then return true end
    local st = _gstate(ply)
    if not st then return true end
    local now = CurTime()
    if st.blockedUntil and st.blockedUntil > now then return false end
    if now >= (st.next or 0) then
        local maxMsgs = 900
        local maxBytes = 512 * 1024
        local over = ((st.msgs or 0) > maxMsgs) or ((st.bytes or 0) > maxBytes)
        if over then
            st.strikes = (st.strikes or 0) + 1
            MilkyAC_Report(ply, "net_flood", 0, "global net flood", "msgs=" .. tostring(st.msgs) .. ";bytes=" .. tostring(st.bytes))
            if st.strikes >= 2 then
                st.blockedUntil = now + 12
                return false
            else
                st.blockedUntil = now + 3
                return false
            end
        else
            st.strikes = math.max(0, (st.strikes or 0) - 1)
        end
        st.msgs = 0
        st.bytes = 0
        st.next = now + 1
    end
    if now >= (st.tenNext or 0) then
        if (st.tenMsgs or 0) > 4000 or (st.tenBytes or 0) > 2048 * 1024 then
            MilkyAC_Report(ply, "net_flood", 0, "10s net flood", "msgs=" .. tostring(st.tenMsgs) .. ";bytes=" .. tostring(st.tenBytes))
            st.blockedUntil = now + 12
            return false
        end
        st.tenMsgs = 0
        st.tenBytes = 0
        st.tenNext = now + 10
    end
    local bytes = math.floor((lenBits or 0) / 8)
    st.msgs = (st.msgs or 0) + 1
    st.bytes = (st.bytes or 0) + bytes
    st.tenMsgs = (st.tenMsgs or 0) + 1
    st.tenBytes = (st.tenBytes or 0) + bytes
    return true
end

local function _nameAllow(ply, name, lenBits)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if ply:IsBot() then return true end
    if _isWL(ply) then return true end
    name = tostring(name or "unknown"):lower()
    local bytes = math.floor((lenBits or 0) / 8)
    if BLOCKED_NET_NAMES[name] then
        MilkyAC_Report(ply, "net_blocked_suppressed", 0, "blocked net message", name)
        return false
    end
    local cfg = STRICT_NET_NAMES[name]
    local rate = cfg and cfg.rate or 64
    local burst = cfg and cfg.burst or 128
    local maxBytes = cfg and cfg.maxBytes or 128 * 1024
    if bytes > maxBytes then
        MilkyAC_Report(ply, "net_overflow", 0, "net message too large", "name=" .. name .. ";bytes=" .. tostring(bytes))
        return false
    end
    local st = _nameState(ply, name)
    st.last = CurTime()
    if not _netToken(st, rate, burst) then
        st.strikes = (st.strikes or 0) + 1
        MilkyAC_Report(ply, "net_name_flood", 0, "net name flood", "name=" .. name .. ";strikes=" .. tostring(st.strikes))
        if cfg and cfg.action == "kick" and st.strikes >= 4 then
            MilkyAC_Report(ply, "net_name_kick_suppressed", 0, "net flood", "name=" .. name .. ";strikes=" .. tostring(st.strikes))
            return false
        end
        return false
    end
    return true
end

local function _unknownState(ply)
    local id = _sid(ply)
    MILKY_NET_UNKNOWN[id] = MILKY_NET_UNKNOWN[id] or { t = CurTime(), n = 0, strikes = 0 }
    return MILKY_NET_UNKNOWN[id]
end

local function _readErrState(ply)
    local id = _sid(ply)
    MILKY_NET_READERR[id] = MILKY_NET_READERR[id] or { t = CurTime(), n = 0, strikes = 0 }
    return MILKY_NET_READERR[id]
end

local function _flagUnknownNet(ply, len)
    if not IsValid(ply) or _isWL(ply) then return end
    local st = _unknownState(ply)
    local now = CurTime()
    if now - (st.t or now) >= 5 then
        st.t = now
        st.n = 0
    end
    st.n = (st.n or 0) + 1
    if st.n >= 8 then
        st.strikes = (st.strikes or 0) + 1
        MilkyAC_Report(ply, "net_unknown", 0, "unknown net id flood", "n=" .. tostring(st.n) .. ";len=" .. tostring(len or 0))
        if st.strikes >= 3 then MilkyAC_Report(ply, "net_unknown_softblock", 0, "unknown net softblock", "n=" .. tostring(st.n) .. ";len=" .. tostring(len or 0)) end
    end
end

local function _flagReadError(ply, name, err)
    if not IsValid(ply) or _isWL(ply) then return end
    local st = _readErrState(ply)
    local now = CurTime()
    if now - (st.t or now) >= 12 then
        st.t = now
        st.n = 0
    end
    st.n = (st.n or 0) + 1
    local low = tostring(err or ""):lower()
    local hard = string.find(low, "net.read", 1, true) or string.find(low, "couldn't read", 1, true) or string.find(low, "readtype", 1, true) or string.find(low, "overflow", 1, true) or string.find(low, "bad argument", 1, true)
    if hard or st.n >= 3 then
        st.strikes = (st.strikes or 0) + 1
        MilkyAC_Report(ply, "net_read_error", 0, "malformed net payload", "name=" .. tostring(name) .. ";err=" .. _clampReason(err, 120))
        if st.strikes >= 3 or st.n >= 5 then MilkyAC_Report(ply, "net_read_softblock", 0, "bad net payload softblock", "name=" .. tostring(name)) end
    end
end

if not MilkyAC.NetIncomingPatched then
    MilkyAC.NetIncomingPatched = true
    function net.Incoming(len, ply)
        if IsValid(ply) and ply:IsPlayer() and not _isWL(ply) then
            if not _globalAllow(ply, len) then return end
        end
        local okHeader, netid = pcall(net.ReadHeader)
        if not okHeader then
            _flagReadError(ply, "header", netid)
            return
        end
        local name = util.NetworkIDToString(netid)
        if not name or name == "" then
            _flagUnknownNet(ply, len)
            return
        end
        local lname = string.lower(name)
        local payloadLen = math.max(0, (tonumber(len or 0) or 0) - 16)
        if not _nameAllow(ply, lname, payloadLen) then return end
        local receiver = net.Receivers and (net.Receivers[name] or net.Receivers[lname])
        if not receiver then
            _flagUnknownNet(ply, payloadLen)
            return
        end
        local ok, err = pcall(receiver, payloadLen, ply)
        if not ok then
            ErrorNoHalt("[MilkyAC] net receiver error [" .. tostring(name) .. "] from " .. (IsValid(ply) and ply:SteamID() or "nil") .. ": " .. tostring(err) .. "\n")
            _flagReadError(ply, lname, err)
            return
        end
    end
end

local function _vecAngleDelta(a, b)
    local d = math.deg(math.acos(math.Clamp(a:Dot(b), -1, 1)))
    if d ~= d then return 180 end
    return d
end

local function _getHeadPos(ent)
    if not IsValid(ent) then return nil end
    local bone = ent.LookupBone and ent:LookupBone("ValveBiped.Bip01_Head1")
    if bone then
        local pos = nil
        if ent.GetBonePosition then
            local p = select(1, ent:GetBonePosition(bone))
            if p and p ~= vector_origin then pos = p end
        end
        if not pos and ent.GetBoneMatrix then
            local m = ent:GetBoneMatrix(bone)
            if m then
                local p = m:GetTranslation()
                if p and p ~= vector_origin then pos = p end
            end
        end
        if pos then return pos end
    end
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    return ent:LocalToWorld(Vector((mins.x + maxs.x) * 0.5, (mins.y + maxs.y) * 0.5, maxs.z * 0.9))
end

local function _getBestTargetEnt(ply)
    local ent = nil
    local rag = ply.GetNWEntity and ply:GetNWEntity("FakeRagdoll")
    if IsValid(rag) then
        ent = rag
    elseif ply.GetRagdollEntity and IsValid(ply:GetRagdollEntity()) then
        ent = ply:GetRagdollEntity()
    else
        ent = ply
    end
    return IsValid(ent) and ent or nil
end

local function _sameTeam(p1, p2)
    if not IsValid(p1) or not IsValid(p2) then return false end
    if not p1:IsPlayer() or not p2:IsPlayer() then return false end
    if p1:Team() == TEAM_UNASSIGNED or p2:Team() == TEAM_UNASSIGNED then return false end
    if p1:Team() == TEAM_SPECTATOR or p2:Team() == TEAM_SPECTATOR then return false end
    return p1:Team() == p2:Team()
end

local function _isValidAimVictim(shooter, target)
    if not IsValid(shooter) or not IsValid(target) then return false end
    if shooter == target then return false end
    if not shooter:IsPlayer() or not target:IsPlayer() then return false end
    if not shooter:Alive() or not target:Alive() then return false end
    if _sameTeam(shooter, target) then return false end
    if target:GetMoveType() == MOVETYPE_OBSERVER then return false end
    if target:IsFlagSet(FL_NOTARGET) then return false end
    return true
end

local function _canShootWeapon(ply)
    if not IsValid(ply) then return false end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return false end
    if wep:IsWeapon() == false and not wep.GetClass then return false end
    local cls = string.lower(wep:GetClass() or "")
    if cls == "weapon_physgun" or cls == "gmod_tool" or cls == "weapon_crowbar" or cls == "weapon_physcannon" then return false end
    return true
end

local function _traceHead(shooter, target, fromPos, headPos)
    return util.TraceLine({
        start = fromPos,
        endpos = headPos,
        filter = { shooter, shooter:GetActiveWeapon() },
        mask = MASK_SHOT,
    })
end

local function _flagAimHeuristic(ply, code, text, pts)
    local msg = "aim heuristic: " .. tostring(text or code or "unknown")
    MilkyAC_Report(ply, "detect", 0, msg, "code=" .. tostring(code or "unknown") .. ";pts=" .. tostring(pts or 0))
    _addSus(ply, math.min(pts or 0, 24), msg)
    local st = _aw(ply)
    st.punishCd = CurTime() + 18
end

hook.Add("SetupMove", "milkyac_aimwatch", function(ply, mv, cmd)
    if not MilkyAC.EnableExpensiveAimChecks then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if _isWL(ply) then return end
    if not ply:Alive() then return end
    if ply:IsBot() then return end
    if not _canShootWeapon(ply) then return end
    local now = CurTime()
    local st = _aw(ply)
    st.lastSeen = now
    if (st.nextScan or 0) > now then return end
    st.nextScan = now + 0.12
    local shootPos = ply:GetShootPos()
    local aimDir = mv:GetMoveAngles():Forward()
    if aimDir == vector_origin then aimDir = ply:EyeAngles():Forward() end
    aimDir = aimDir:GetNormalized()
    if st.lastAng then
        local delta = _vecAngleDelta(st.lastAng, aimDir)
        if delta >= 34 then
            st.snapScore = (st.snapScore or 0) + 0.4
            st.snapEvents = (st.snapEvents or 0) + 1
        elseif delta <= 0.9 then
            st.snapScore = math.max(0, (st.snapScore or 0) - 0.2)
        end
    end
    st.lastAng = Vector(aimDir)
    local bestTarget, bestDelta, bestOccluded = nil, 180, false
    for _, target in ipairs(player.GetAll()) do
        if not _isValidAimVictim(ply, target) then continue end
        local ent = _getBestTargetEnt(target)
        if not IsValid(ent) then continue end
        if ent.SetupBones then ent:SetupBones() end
        local headPos = _getHeadPos(ent)
        if not headPos then continue end
        local dir = (headPos - shootPos):GetNormalized()
        local delta = _vecAngleDelta(aimDir, dir)
        if delta > 2.0 then continue end
        local tr = _traceHead(ply, ent, shootPos, headPos)
        local occ = false
        if tr.Hit and tr.Entity ~= ent then
            local linked = IsValid(tr.Entity) and tr.Entity.GetNWEntity and tr.Entity:GetNWEntity("Player") or nil
            if linked ~= target then occ = true end
        elseif tr.Entity ~= ent and tr.Fraction < 0.985 then
            occ = true
        end
        if delta < bestDelta then
            bestDelta = delta
            bestTarget = target
            bestOccluded = occ
        end
    end
    if bestTarget then
        st.scanHits = (st.scanHits or 0) + 1
        if st.lastTarget == bestTarget then st.stableLock = (st.stableLock or 0) + 0.12 else st.stableLock = 0.12 end
        if bestOccluded then
            st.wallHead = (st.wallHead or 0) + 0.45
            st.occludedLock = (st.occludedLock or 0) + 0.45
            st.visibleLock = math.max(0, (st.visibleLock or 0) - 0.2)
        else
            st.directHead = (st.directHead or 0) + 0.3
            st.visibleLock = (st.visibleLock or 0) + 0.3
            st.occludedLock = math.max(0, (st.occludedLock or 0) - 0.2)
        end
        st.lastTarget = bestTarget
        st.aimTime = (st.aimTime or 0) + 0.12
    else
        st.lastTarget = nil
        st.stableLock = math.max(0, (st.stableLock or 0) - 0.25)
        st.occludedLock = math.max(0, (st.occludedLock or 0) - 0.5)
        st.visibleLock = math.max(0, (st.visibleLock or 0) - 0.25)
        st.aimTime = math.max(0, (st.aimTime or 0) - 0.12)
    end
    if (st.punishCd or 0) > now then return end
    if (st.wallHead or 0) >= 20 and (st.occludedLock or 0) >= 14 and (st.snapScore or 0) >= 8 and (st.stableLock or 0) >= 1.0 and (st.aimTime or 0) >= 4.0 then
        return _flagAimHeuristic(ply, "wall_head_lock", "сквозь стену ведет голову", 20)
    end
    if (st.wallHead or 0) >= 30 and (st.occludedLock or 0) >= 22 and (st.snapScore or 0) >= 12 and (st.stableLock or 0) >= 1.6 and (st.aimTime or 0) >= 6.0 then
        return _flagAimHeuristic(ply, "wall_head_lock_hard", "долгий лок головы через стену", 28)
    end
    if (st.directHead or 0) >= 26 and (st.snapScore or 0) >= 10 and (st.snapEvents or 0) >= 5 and (st.stableLock or 0) >= 2.0 and (st.aimTime or 0) >= 6.0 then
        return _flagAimHeuristic(ply, "snap_head_lock", "резкие снапы в голову", 16)
    end
end)

hook.Add("EntityFireBullets", "milkyac_aimwatch_shots", function(ent, data)
    if not MilkyAC.EnableExpensiveAimChecks then return end
    if not IsValid(ent) or not ent:IsPlayer() then return end
    local ply = ent
    if _isWL(ply) then return end
    local st = _aw(ply)
    local now = CurTime()
    st.lastSeen = now
    st.lastShot = now
    st.shotBursts = (st.shotBursts or 0) + 1
    st.totalShots = (st.totalShots or 0) + 1
    local aimDir = data.Dir or ply:EyeAngles():Forward()
    aimDir = aimDir:GetNormalized()
    local shootPos = data.Src or ply:GetShootPos()
    local headAligned = false
    local headOccluded = false
    for _, target in ipairs(player.GetAll()) do
        if not _isValidAimVictim(ply, target) then continue end
        local tent = _getBestTargetEnt(target)
        if not IsValid(tent) then continue end
        if tent.SetupBones then tent:SetupBones() end
        local head = _getHeadPos(tent)
        if not head then continue end
        local d = _vecAngleDelta(aimDir, (head - shootPos):GetNormalized())
        if d <= 1.5 then
            local tr = _traceHead(ply, tent, shootPos, head)
            local occ = false
            if tr.Hit and tr.Entity ~= tent then
                local linked = IsValid(tr.Entity) and tr.Entity.GetNWEntity and tr.Entity:GetNWEntity("Player") or nil
                if linked ~= target then occ = true end
            elseif tr.Entity ~= tent and tr.Fraction < 0.985 then
                occ = true
            end
            headAligned = true
            headOccluded = occ
            st.lastTarget = target
            break
        end
    end
    if headAligned then
        if headOccluded then
            st.wallHead = (st.wallHead or 0) + 0.8
            st.occludedLock = (st.occludedLock or 0) + 0.8
        else
            st.directHead = (st.directHead or 0) + 0.45
            st.visibleLock = (st.visibleLock or 0) + 0.45
        end
    end
    if (st.punishCd or 0) <= now then
        if (st.wallHead or 0) >= 28 and (st.shotBursts or 0) >= 10 and (st.occludedLock or 0) >= 16 then
            return _flagAimHeuristic(ply, "wall_head_shots", "стрельба в голову через стену", 24)
        end
        if (st.directHead or 0) >= 30 and (st.snapScore or 0) >= 12 and (st.shotBursts or 0) >= 12 and (st.totalShots or 0) >= 18 then
            return _flagAimHeuristic(ply, "head_snap_shots", "сери�� снапов по голове", 18)
        end
    end
end)

hook.Add("PlayerHurt", "milkyac_aimwatch_hurt", function(victim, attacker, healthRemaining, damageTaken)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if _isWL(attacker) then return end
    local st = _aw(attacker)
    st.lastSeen = CurTime()
    st.totalHits = (st.totalHits or 0) + 1
    local hg = victim:LastHitGroup() or 0
    if hg == HITGROUP_HEAD then
        st.headshots = (st.headshots or 0) + 1
        st.directHead = (st.directHead or 0) + 0.8
        if (st.headshots or 0) >= 8 and (st.snapScore or 0) >= 10 and (st.directHead or 0) >= 16 and (st.totalHits or 0) >= 10 then
            _flagAimHeuristic(attacker, "headshot_chain", "цепочка хедов с резкими доводками", 16)
        end
        if (st.headshots or 0) >= 10 and ((st.wallHead or 0) >= 12 or (st.occludedLock or 0) >= 10) and (st.totalHits or 0) >= 12 then
            _flagAimHeuristic(attacker, "wall_headshot_chain", "серия хедов с прострелом/локом", 24)
        end
    end
end)

net.Receive("milkyac_change", function(len, ply)
    if not IsValid(ply) then return end
    if _isWL(ply) then
        local conname = tostring(net.ReadString() or "")
        local convalue = tostring(net.ReadString() or "")
        if conname == "" then return end
        local cvar = GetConVar(conname)
        if not cvar then return end
        local real = tostring(cvar:GetString() or "")
        if convalue ~= real then
            print("[K.A.S.P.E.R.S.K.Y] Convar ", ply:Nick(), ply:SteamID(), "->", conname, ":", convalue, "(real:", real .. ")")
        end
        return
    end
    local cfg = { rate = 8, burst = 16, maxBytes = 1024 }
    local bytes = math.floor((len or 0) / 8)
    if cfg.maxBytes and bytes > cfg.maxBytes then
        MilkyAC_Report(ply, "overflow", 0, "net overflow milkyac_change", "")
        return
    end
    if not _tok(ply, "milkyac_change", cfg) then return end
    local conname = tostring(net.ReadString() or "")
    local convalue = tostring(net.ReadString() or "")
    if conname == "" then return end
    local cvar = GetConVar(conname)
    if not cvar then return MilkyAC_Punish(ply, 0, "подмена/инъекция convar " .. _clampReason(conname)) end
    local real = tostring(cvar:GetString() or "")
    if convalue ~= real then
        return MilkyAC_Punish(ply, 0, "смена конвара " .. _clampReason(conname) .. " на " .. _clampReason(convalue))
    end
end)

net.Receive("milkyac_caught", function(len, ply)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    local cfg = { rate = 6, burst = 12, maxBytes = 2048 }
    local bytes = math.floor((len or 0) / 8)
    if cfg.maxBytes and bytes > cfg.maxBytes then
        MilkyAC_Report(ply, "overflow", 0, "net overflow milkyac_caught", "")
        return
    end
    if not _tok(ply, "milkyac_caught", cfg) then return end
    local reasonRaw = net.ReadString() or ""
    local reason = _normReason(reasonRaw)
    if reason == "" then reason = "unknown" end
    if _isNoise(reason) then return end
    if _isHookAdd(reason) then
        local msg = "AC hookadd ban: " .. _clampReason(reason)
        MilkyAC_Report(ply, "ban", 0, msg, "family=hooks")
        return MilkyAC_Punish(ply, 0, msg)
    end
    if _isHardBan(reason) then
        local msg = "AC hard ban: " .. _clampReason(reason)
        MilkyAC_Report(ply, "ban", 0, msg, "hard=1")
        return MilkyAC_Punish(ply, 0, msg)
    end
    if _isIncludeExploit(reason) then
        local msg = "include exploit: " .. _clampReason(reason)
        MilkyAC_Report(ply, "ban", 0, msg, "family=include")
        return MilkyAC_Punish(ply, 0, "exploit include")
    end
    local fam = _sigFamily(reason)
    if fam == "clientnet" then
        local kick, why, netname = _cn_allow(ply, reason)
        if kick == "kick" then
            MilkyAC_Report(ply, "clientnet_softblock", 0, "client net error flood", "why=" .. tostring(why) .. ";net=" .. tostring(netname))
        end
        return
    end
    local allow, key, st, why = _df_allow(ply, reason, fam)
    if allow == "kick" then
        MilkyAC_Report(ply, "detect_softblock", 0, "milkyac detect flood", "why=" .. tostring(why) .. ";fam=" .. tostring(fam))
        return
    end
    if allow ~= true then return end
    local pts = _scoreReason(reason)
    if _df_api_allow(st, key, fam) then
        MilkyAC_Report(ply, "detect", 0, reason, "pts=" .. tostring(pts) .. ";fam=" .. tostring(fam))
    end
    if pts >= 999 then return end
    if pts >= 8 then
        _addSus(ply, pts, reason)
        return
    end
end)

local function netKick(msg, ply)
    if not IsValid(ply) then return end
    if _isWL(ply) then return end
    MilkyAC_Report(ply, "net_kick_suppressed", 0, "exploit net message", tostring(msg or ""))
    hook.Run("MilkyACNetDetected", ply, msg)
end

local net_msg_list = {
    "update_store_freebodygroupr",
    "announcementadmin",
    "StandPose_Server",
}

for _, msg in ipairs(net_msg_list) do
    util.AddNetworkString(msg)
    net.Receive(msg, function(_, ply)
        netKick(msg, ply)
    end)
end

timer.Simple(0, function()
    if isfunction(_G.SetNetVar) and not MilkyAC.SetNetVarPatched then
        MilkyAC.SetNetVarPatched = true
        local old = _G.SetNetVar
        _G.SetNetVar = function(ent, key, value, ...)
            local safe = value
            if type(value) == "table" then
                safe = MilkyAC.SafeNetVar(value)
            elseif type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
                safe = nil
                MsgC(Color(255, 87, 34), "[MilkyAC] blocked bad SetNetVar value: " .. tostring(key) .. " type=" .. type(value) .. "\n")
            end
            return old(ent, key, safe, ...)
        end
    end
end)

hook.Add("PostGamemodeLoaded", "milky_disable_cslua", function()
    RunConsoleCommand("sv_allowcslua", "0")
    if GAMEMODE and GAMEMODE.Config then GAMEMODE.Config.disallowClientsideScripts = true end
    timer.Simple(30, function()
        RunConsoleCommand("sv_allowcslua", "0")
        if GAMEMODE and GAMEMODE.Config then GAMEMODE.Config.disallowClientsideScripts = true end
    end)
end)

timer.Create("milky_sus_decay", 30, 0, function()
    local now = CurTime()
    for id, st in pairs(MILKY_SUS) do
        if not st then continue end
        local dt = now - (st.last or now)
        if dt >= 45 then
            st.score = math.max(0, (st.score or 0) - 4)
            st.highMarks = math.max(0, (st.highMarks or 0) - 1)
        end
        if dt >= 240 then MILKY_SUS[id] = nil end
    end
    for id, st in pairs(MILKY_DETECT_FILTER) do
        if not st then continue end
        if (now - (st.w60_t or now)) >= 120 then MILKY_DETECT_FILTER[id] = nil end
    end
    for id, st in pairs(MILKY_CLIENTNET) do
        if not st then continue end
        if (now - (st.w60_t or now)) >= 120 then MILKY_CLIENTNET[id] = nil end
    end
    for id, st in pairs(MILKY_CLIENTNET_ESC) do
        if not st then continue end
        if (now - (st.t or now)) >= 1800 then MILKY_CLIENTNET_ESC[id] = nil end
    end
    for id, st in pairs(MILKY_GLOBAL_NET) do
        if not st then continue end
        if (now - (st.next or now)) >= 120 then MILKY_GLOBAL_NET[id] = nil end
    end
    for id, per in pairs(MILKY_NET_NAME_STATE) do
        if not per then continue end
        for name, st in pairs(per) do
            if not st or (now - (st.last or now)) >= 180 then per[name] = nil end
        end
        if next(per) == nil then MILKY_NET_NAME_STATE[id] = nil end
    end
    for id, st in pairs(MILKY_NET_UNKNOWN) do
        if not st or (now - (st.t or now)) >= 60 then MILKY_NET_UNKNOWN[id] = nil end
    end
    for id, st in pairs(MILKY_NET_READERR) do
        if not st or (now - (st.t or now)) >= 120 then MILKY_NET_READERR[id] = nil end
    end
    for key, t in pairs(MILKY_REPORT_DEDUP) do
        if t <= now then MILKY_REPORT_DEDUP[key] = nil end
    end
    for id, st in pairs(MILKY_AIMWATCH) do
        if not st then continue end
        st.snapScore = math.max(0, (st.snapScore or 0) - 1.5)
        st.wallHead = math.max(0, (st.wallHead or 0) - 2)
        st.directHead = math.max(0, (st.directHead or 0) - 1.5)
        st.occludedLock = math.max(0, (st.occludedLock or 0) - 2)
        st.visibleLock = math.max(0, (st.visibleLock or 0) - 1)
        st.headshots = math.max(0, (st.headshots or 0) - 1)
        st.totalHits = math.max(0, (st.totalHits or 0) - 1)
        st.totalShots = math.max(0, (st.totalShots or 0) - 2)
        st.scanHits = math.max(0, (st.scanHits or 0) - 2)
        st.shotBursts = math.max(0, (st.shotBursts or 0) - 1)
        st.aimTime = math.max(0, (st.aimTime or 0) - 0.8)
        st.stableLock = math.max(0, (st.stableLock or 0) - 0.8)
        st.snapEvents = math.max(0, (st.snapEvents or 0) - 1)
        st.aimBan = math.max(0, (st.aimBan or 0) - 6)
        st.silentAim = math.max(0, (st.silentAim or 0) - 1)
        st.wallShots = math.max(0, (st.wallShots or 0) - 1)
        st.plusTrack = math.max(0, (st.plusTrack or 0) - 3)
        st.trigger = math.max(0, (st.trigger or 0) - 1)
        st.moveSpeedStrikes = math.max(0, (st.moveSpeedStrikes or 0) - 1)
        if (st.lastSeen or 0) > 0 and (now - (st.lastSeen or now)) >= 180 then MILKY_AIMWATCH[id] = nil end
    end
end)

hook.Add("PlayerDisconnected", "milky_ac_cleanup", function(ply)
    local id = _sid(ply)
    MilkyAC_StreamLimiter.State[id] = nil
    MILKY_GLOBAL_NET[id] = nil
    MILKY_NET_NAME_STATE[id] = nil
    MILKY_NET_UNKNOWN[id] = nil
    MILKY_NET_READERR[id] = nil
    MILKY_SUS[id] = nil
    MILKY_DETECT_FILTER[id] = nil
    MILKY_CLIENTNET[id] = nil
    MILKY_CLIENTNET_ESC[id] = nil
    MILKY_AIMWATCH[id] = nil
end)

MilkyAC.Plus = MilkyAC.Plus or {}
MilkyAC.Plus.Version = "server-hardened-2"

local PLUS_CFG = {
    scanInterval = 0.22,
    combatWindow = 4,
    silentAngle = 7,
    silentNeed = 3,
    wallNeed = 7,
    trackNeed = 18,
    speedSlack = 1.75,
}

local function _plusSignalCount(st, code)
    st.plusSignals = st.plusSignals or {}
    st.plusSignals[code] = true
    local n = 0
    for _ in pairs(st.plusSignals) do n = n + 1 end
    return n
end

local function _plusFeed(ply, points, code, text)
    if not IsValid(ply) or _isWL(ply) then return end
    local st = _aw(ply)
    local now = CurTime()
    if now < (st.plusReportNext or 0) then return end
    st.plusReportNext = now + 5
    local signals = _plusSignalCount(st, code)
    local msg = "aim heuristic: " .. tostring(text)
    MilkyAC_Report(ply, "detect", 0, msg, "code=" .. tostring(code) .. ";signals=" .. tostring(signals) .. ";points=" .. tostring(points))
    _addSus(ply, math.min(points, 24), msg)
end

local function _plusTarget(ply, dir, origin, limit, trace)
    local best, bestDelta, bestBlocked = nil, limit or 2, false
    for _, target in ipairs(player.GetAll()) do
        if _isValidAimVictim(ply, target) then
            local ent = _getBestTargetEnt(target)
            if IsValid(ent) then
                local head = _getHeadPos(ent)
                if head then
                    local delta = _vecAngleDelta(dir, (head - origin):GetNormalized())
                    if delta <= bestDelta then
                        local blocked = false
                        if trace then
                            local tr = _traceHead(ply, ent, origin, head)
                            blocked = tr.Hit and tr.Entity ~= ent and tr.Fraction < 0.985
                            if blocked and IsValid(tr.Entity) and tr.Entity.GetNWEntity then
                                blocked = tr.Entity:GetNWEntity("Player") ~= target
                            end
                        end
                        best, bestDelta, bestBlocked = target, delta, blocked
                    end
                end
            end
        end
    end
    return best, bestDelta, bestBlocked
end

hook.Add("EntityFireBullets", "milkyac_server_shotcheck", function(ply, data)
    if not MilkyAC.EnableExpensiveAimChecks then return end
    if not IsValid(ply) or not ply:IsPlayer() or _isWL(ply) or ply:IsBot() then return end
    if not _canShootWeapon(ply) then return end
    local st = _aw(ply)
    local now = CurTime()
    st.lastSeen = now
    st.lastCombat = now
    st.totalShots = (st.totalShots or 0) + 1
    local view = ply:EyeAngles():Forward():GetNormalized()
    local shot = data.Dir or view
    if shot == vector_origin then return end
    shot = shot:GetNormalized()
    local source = data.Src or ply:GetShootPos()
    local target, delta, blocked = _plusTarget(ply, shot, source, 1.25, true)
    if not target then return end
    local divergence = _vecAngleDelta(view, shot)
    if divergence >= PLUS_CFG.silentAngle then
        st.silentAim = (st.silentAim or 0) + 1
        if st.silentAim >= PLUS_CFG.silentNeed then
            st.silentAim = 0
            _plusFeed(ply, 28, "silent", "shot direction diverges from view")
        end
    else
        st.silentAim = math.max(0, (st.silentAim or 0) - 0.25)
    end
    if blocked then
        st.wallShots = (st.wallShots or 0) + 1
        if st.wallShots >= PLUS_CFG.wallNeed then
            st.wallShots = 0
            _plusFeed(ply, 18, "wall", "repeated head alignment through solid geometry")
        end
    else
        st.wallShots = math.max(0, (st.wallShots or 0) - 0.3)
    end
end)

hook.Add("PlayerHurt", "milkyac_server_hitcheck", function(victim, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or not IsValid(victim) or not victim:IsPlayer() then return end
    if _isWL(attacker) or attacker:IsBot() then return end
    local st = _aw(attacker)
    st.lastSeen = CurTime()
    st.lastCombat = CurTime()
    st.totalHits = (st.totalHits or 0) + 1
    if victim:LastHitGroup() == HITGROUP_HEAD then
        st.headshots = (st.headshots or 0) + 1
        if st.headshots >= 12 and st.totalHits >= 16 and (st.snapScore or 0) >= 7 then
            st.headshots = 5
            _plusFeed(attacker, 16, "headchain", "high headshot rate with snap evidence")
        end
    end
end)

hook.Add("SetupMove", "milkyac_server_tracking", function(ply, mv)
    if not MilkyAC.EnableExpensiveAimChecks then return end
    if not IsValid(ply) or not ply:IsPlayer() or _isWL(ply) or ply:IsBot() or not ply:Alive() then return end
    if not _canShootWeapon(ply) then return end
    local st = _aw(ply)
    local now = CurTime()
    if now - (st.lastCombat or 0) > PLUS_CFG.combatWindow then return end
    if now < (st.plusScanNext or 0) then return end
    st.plusScanNext = now + PLUS_CFG.scanInterval
    local dir = mv:GetMoveAngles():Forward():GetNormalized()
    local target, delta, blocked = _plusTarget(ply, dir, ply:GetShootPos(), 0.65, true)
    if st.plusLastDir then
        local turn = _vecAngleDelta(st.plusLastDir, dir)
        if turn >= 24 and target and not blocked and delta <= 0.65 then
            st.snapScore = (st.snapScore or 0) + 1
        else
            st.snapScore = math.max(0, (st.snapScore or 0) - 0.2)
        end
    end
    st.plusLastDir = Vector(dir)
    if target and not blocked and delta <= 0.35 and target:GetVelocity():Length2D() >= 80 then
        if st.trackTarget == target then
            st.trackTicks = (st.trackTicks or 0) + 1
        else
            st.trackTarget = target
            st.trackTicks = 1
        end
        if st.trackTicks >= PLUS_CFG.trackNeed and (st.snapScore or 0) >= 5 then
            st.trackTicks = 0
            _plusFeed(ply, 20, "tracking", "sustained sub-degree tracking after snaps")
        end
    else
        st.trackTarget = nil
        st.trackTicks = math.max(0, (st.trackTicks or 0) - 1)
    end
end)

hook.Add("StartCommand", "milkyac_server_antiaim", function(ply, cmd)
    if not IsValid(ply) or not ply:IsPlayer() or _isWL(ply) or ply:IsBot() or cmd:IsForced() then return end
    local st = _aw(ply)
    local ang = cmd:GetViewAngles()
    if not ang then return end
    local pitch = ang.p
    if pitch > 180 then pitch = pitch - 360 end
    if pitch > 91 or pitch < -91 then
        st.aaPitch = (st.aaPitch or 0) + 1
        if st.aaPitch >= 24 then
            st.aaPitch = 0
            _plusFeed(ply, 18, "antiaim_pitch", "invalid command pitch")
        end
    else
        st.aaPitch = math.max(0, (st.aaPitch or 0) - 0.2)
    end
end)

hook.Add("Move", "milkyac_server_speed", function(ply, mv)
    if not IsValid(ply) or not ply:IsPlayer() or _isWL(ply) or ply:IsBot() or not ply:Alive() then return end
    if IsValid(ply:GetVehicle()) then return end
    local mt = ply:GetMoveType()
    if mt == MOVETYPE_NOCLIP or mt == MOVETYPE_LADDER or mt == MOVETYPE_OBSERVER then return end
    local st = _aw(ply)
    local base = math.max(ply:GetRunSpeed() or 0, ply:GetWalkSpeed() or 0, ply:GetMaxSpeed() or 0, 250)
    local limit = base * PLUS_CFG.speedSlack + 180
    if mv:GetVelocity():Length2D() > limit then
        st.moveSpeedStrikes = (st.moveSpeedStrikes or 0) + 1
        if st.moveSpeedStrikes >= 36 then
            st.moveSpeedStrikes = 0
            _plusFeed(ply, 10, "speed", "persistent abnormal movement speed")
        end
    else
        st.moveSpeedStrikes = math.max(0, (st.moveSpeedStrikes or 0) - 1)
    end
end)

MsgC(Color(76, 175, 80), "[MilkyAC] Loaded " .. MilkyAC.Version .. "\n")
