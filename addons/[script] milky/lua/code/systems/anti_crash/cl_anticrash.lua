//
//
//

timer.Simple(0.1, function()
    hook.Add("ChatText", "HideJoinLeaveRU", function(index, name, text, msgType)
    return true
    end)


netstream.Hook("AntiCrash_Notify", function(data)
    local msgType = data.type or "info"
    local msg = data.text or ""
    local color = Color(255, 255, 255)

    if msgType == "warning" then
        color = Color(255, 200, 50)
        surface.PlaySound("buttons/blip1.wav")
    elseif msgType == "cleanup" then
        color = Color(255, 80, 80)
        surface.PlaySound("buttons/button10.wav")
    elseif msgType == "ok" then
        color = Color(100, 255, 100)
        surface.PlaySound("buttons/button14.wav")
    elseif msgType == "admin" then
        color = Color(150, 200, 255)
    end

    chat.AddText(color, "[Эгида] ", Color(255, 255, 255), msg)
end)
end)

//
//
//

local sounds = {}
sounds[ "ammo" ] = true
sounds[ "behind you" ] = true
sounds[ "better reload" ] = true
sounds[ "bullshit" ] = true
sounds[ "bull shit"] = true
sounds[ "cheese" ] = true
sounds[ "combine" ] = true
sounds[ "coming" ] = true
sounds[ "cops" ] = true
sounds[ "cp" ] = true
sounds[ "cps" ] = true
sounds[ "cut it" ] = true
sounds[ "dont tell me" ] = true
sounds[ "de ja vu" ] = true
sounds[ "dejavu" ] = true
sounds[ "excuse me" ] = true
sounds[ "fantastic" ] = true
sounds[ "figures" ] = true
sounds[ "finally" ] = true
sounds[ "follow" ] = true
sounds[ "focus" ] = true
sounds[ "freeman" ] = true
sounds[ "get down" ] = true
sounds[ "get in" ] = true
sounds[ "get out" ] = true
sounds[ "good god" ] = true
sounds[ "gosh" ] = true
sounds[ "got one" ] = true
sounds[ "gotta reload" ] = true
sounds[ "gtfo" ] = true
sounds[ "hacks" ] = true
sounds[ "hax" ] = true
sounds[ "haxx" ] = true
sounds[ "help" ] = true
sounds[ "here they come" ] = true
sounds[ "hello" ] = true
sounds[ "hey" ] = true
sounds[ "hi" ] = true
sounds[ "heads up" ] = true
sounds[ "he's dead" ] = true
sounds[ "he is dead" ] = true
sounds[ "how about that" ] = true
sounds[ "i know" ] = true
sounds[ "ill stay here" ] = true
sounds[ "i'll stay here" ] = true
sounds[ "i will stay here" ] = true
sounds[ "im busy" ] = true
sounds[ "i'm busy" ] = true
sounds[ "im with you" ] = true
sounds[ "i'm with you" ] = true
sounds[ "isnt good" ] = true
sounds[ "isn't good" ] = true
sounds[ "incoming" ] = true
sounds[ "it cant be" ] = true
sounds[ "it can't be" ] = true
sounds[ "it is okay" ] = true
sounds[ "it's okay" ] = true
sounds[ "kay" ] = true
sounds[ "kk" ] = true
sounds[ "lead the way" ] = true
sounds[ "lead on" ] = true
sounds[ "lets go" ] = true
sounds[ "let's go" ] = true
sounds[ "never" ] = true
sounds[ "never can tell" ] = true
sounds[ "nice" ] = true
sounds[ "no" ] = true
sounds[ "not good" ] = true
sounds[ "not sure" ] = true
sounds[ "now what" ] = true
sounds[ "oh no" ] = true
sounds[ "oh my god" ] = true
sounds[ "omg" ] = true
sounds[ "omfg" ] = true
sounds[ "ok" ] = true
sounds[ "okay" ] = true
sounds[ "oops" ] = true
sounds[ "over here" ] = true
sounds[ "over there" ] = true
sounds[ "pardon me" ] = true
sounds[ "please no" ] = true
sounds[ "right on" ] = true
sounds[ "run" ] = true
sounds[ "same here" ] = true
sounds[ "shut up" ] = true
sounds[ "spread the word" ] = true
sounds[ "stop it" ] = true
sounds[ "stop that" ] = true
sounds[ "stop looking at me" ] = true
sounds[ "sorry" ] = true
sounds[ "sry" ] = true
sounds[ "take cover" ] = true
sounds[ "take this medkit" ] = true
sounds[ "task at hand" ] = true
sounds[ "talking to me" ] = true
sounds[ "thats you" ] = true
sounds[ "this cant be" ] = true
sounds[ "this can't be" ] = true
sounds[ "this is bad" ] = true
sounds[ "too much info" ] = true
sounds[ "too much information" ] = true
sounds[ "uhoh" ] = true
sounds[ "uh oh" ] = true
sounds[ "wait" ] = true
sounds[ "wait for me" ] = true
sounds[ "wait for us" ] = true
sounds[ "wanna bet" ] = true
sounds[ "watch out" ] = true
sounds[ "we are done for" ] = true
sounds[ "we're done for" ] = true
sounds[ "what now" ] = true
sounds[ "whatever you say" ] = true
sounds[ "whats the use" ] = true
sounds[ "what's the use" ] = true
sounds[ "whats the point" ] = true
sounds[ "what's the point" ] = true
sounds[ "whoops" ] = true
sounds[ "why go on" ] = true
sounds[ "why telling me" ] = true
sounds[ "yeah" ] = true
sounds[ "yes" ] = true
sounds[ "you and me both" ] = true
sounds[ "you never know" ] = true
sounds[ "you sure" ] = true

local znak_blacklist = {
    ["@"] = true,
    ["!"] = true,
    ["]"] = true,
    ["/"] = true
}

local function httpUrlEncode(text)
    return (string.gsub(tostring(text or ""), "[^%w%-%.%_]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local stations = {}
local playSnd = true
local lastSync = 0

CreateClientConVar("TTSModel", "", true, true)

local netKey = ""
local lastKeyReq = 0

local keyWaiters = {}

net.Receive("AW_TTS_Key", function()
    netKey = tostring(net.ReadString() or "")

    local waiters = keyWaiters
    keyWaiters = {}

    for _, fn in ipairs(waiters) do
        if isfunction(fn) then fn(netKey) end
    end
end)

local function getKey()
    if netKey ~= "" then return netKey end
    local lp = LocalPlayer()
    if not IsValid(lp) then return "" end
    return tostring(lp:GetNWString("TTSKey", "") or "")
end

local function requestKey(force)
    local wait = force and 6 or 3
    if CurTime() - lastKeyReq < wait then return false end
    lastKeyReq = CurTime()
    net.Start("AW_TTS_RequestKey")
    net.WriteBool(force and true or false)
    net.SendToServer()
    return true
end

local function awEnsureKey(force, cb)
    local cur = getKey()

    if not force and cur ~= "" then
        cb(cur)
        return
    end

    local done = false

    local function finish()
        if done then return end
        done = true
        cb(getKey())
    end

    keyWaiters[#keyWaiters + 1] = finish
    requestKey(force)
    timer.Simple(4, finish)
end

local function hasSub(ply)
    if not IsValid(ply) then return false end
    if ply:GetNWBool("TTSActive", false) then return true end
    local exp = tonumber(ply:GetNWFloat("TTSExpire", 0) or 0) or 0
    return exp > os.time()
end

local function requestSync()
    if CurTime() - lastSync < 3 then return end
    lastSync = CurTime()
    RunConsoleCommand("aw_tts_sync")
end

CreateClientConVar("aw_tts_volume", "1", true, false)
CreateClientConVar("aw_tts_debug", "0", true, false)

local function ttsVolume()
    return math.Clamp(tonumber(GetConVarString("aw_tts_volume")) or 1, 0, 2)
end

local function ttsDebug(...)
    if (tonumber(GetConVarString("aw_tts_debug")) or 0) <= 0 then return end
    print("[AW_TTS]", ...)
end

local function ttsURL(scheme, key, model, text)
    return scheme .. "://api.animeworld.space/tts?key=" .. httpUrlEncode(key) .. "&model=" .. httpUrlEncode(model) .. "&text=" .. text
end

local function isInvalidKeyAnswer(body)
    body = tostring(body or "")
    return string.find(string.lower(body), "invalid key", 1, true) ~= nil
end

hook.Add("InitPostEntity", "AW_TTS_ClientSync", function()
    timer.Simple(3, function() requestSync() requestKey(false) end)
    timer.Simple(10, function() requestSync() requestKey(false) end)
end)

timer.Remove("AW_TTS_ClientSyncTick")
timer.Create("AW_TTS_ClientSyncTick", 60, 0, function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if hasSub(lp) then return end
    requestSync()
end)

local function stopFor(ply)
    local sid = IsValid(ply) and ply:SteamID() or nil
    if sid then
        timer.Remove("tts_" .. sid)
    end
    if IsValid(ply) and IsValid(stations[ply]) then
        stations[ply]:Stop()
    end
    if IsValid(ply) then
        stations[ply] = nil
    end
end

local function attachStation(ply, station)
    if not IsValid(station) then return end
    if not IsValid(ply) then station:Stop() return end

    station:SetPos(ply:GetPos())
    station:SetVolume(ttsVolume())
    station:Play()
    stations[ply] = station

    local sid = ply:SteamID()
    timer.Remove("tts_" .. sid)
    timer.Create("tts_" .. sid, 0.2, 0, function()
        if not IsValid(ply) or not IsValid(station) then
            timer.Remove("tts_" .. sid)
            return
        end
        station:SetPos(ply:GetPos())
    end)
end

local fetchSlot = 0

local function nextCacheFile()
    fetchSlot = (fetchSlot % 4) + 1
    return "aw_tts_cache_" .. fetchSlot .. ".dat"
end

local function playStandalone(station)
    station:SetVolume(ttsVolume())
    station:Play()
    timer.Simple(15, function() if IsValid(station) then station:Stop() end end)
end

local function playViaFetch(ply, url, flags, onDone)
    http.Fetch(url, function(body, size, headers, code)
        if code and code ~= 200 then
            ttsDebug("fetch bad code", code, string.sub(tostring(body or ""), 1, 200))
            if isInvalidKeyAnswer(body) then
                netKey = ""
                requestKey(true)
            end
            if onDone then onDone(false, code, tostring(body or "")) end
            return
        end

        if not body or body == "" then
            ttsDebug("fetch empty body", code)
            if onDone then onDone(false, code, "empty") end
            return
        end

        local head = string.sub(body, 1, 1)
        if head == "{" or head == "<" then
            ttsDebug("api returned text", string.sub(body, 1, 200))
            if onDone then onDone(false, code, string.sub(body, 1, 200)) end
            return
        end

        local name = nextCacheFile()
        file.Write(name, body)

        sound.PlayFile("data/" .. name, flags, function(st, errCode, errStr)
            if IsValid(st) then
                if IsValid(ply) then
                    attachStation(ply, st)
                else
                    playStandalone(st)
                end
                if onDone then onDone(true) end
                return
            end

            ttsDebug("playfile failed", errCode, errStr)
            if onDone then onDone(false, errCode, errStr) end
        end)
    end, function(err)
        ttsDebug("fetch failed", err)
        if onDone then onDone(false, -1, tostring(err)) end
    end)
end

local function playTTS(ply, url_http, url_https)
    sound.PlayURL(url_http, "3d noblock", function(station, errCode, errStr)
        if IsValid(station) then
            attachStation(ply, station)
            return
        end

        ttsDebug("playurl http failed", errCode, errStr, url_http)

        sound.PlayURL(url_https, "3d noblock", function(station2, errCode2, errStr2)
            if IsValid(station2) then
                attachStation(ply, station2)
                return
            end

            ttsDebug("playurl https failed", errCode2, errStr2, url_https)
            playViaFetch(ply, url_http, "3d noblock")
        end)
    end)
end

hook.Add("OnPlayerChat", "AW_TTS_OnChat", function(ply, strText)
    if not playSnd then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not hasSub(ply) then return end
    if not ply:Alive() then return end
    if ply ~= LocalPlayer() and ply:IsMuted() then return true end

    local text = tostring(strText or "")
    if text == "" then return end

    local znak = text:sub(1, 1)
    if znak_blacklist[znak] then return end

    local model = tostring(ply:GetNWString("TTSModel", "") or "")
    if model == "" or model == "off" then return end

    local key = getKey()
    if key == "" then
        requestSync()
        ttsDebug("no key")
        return
    end

    stopFor(ply)

    local txt = httpUrlEncode(text)
    playTTS(ply, ttsURL("http", key, model, txt), ttsURL("https", key, model, txt))
end)

hook.Add("EntityRemoved", "AW_TTS_Cleanup", function(ent)
    if IsValid(ent) and ent:IsPlayer() then
        stopFor(ent)
    end
end)

local RNDX = _G.gSims_RNDX

local aw_accent = Color(31, 182, 255)
local aw_cyan = Color(127, 230, 255)
local aw_text = Color(240, 248, 255)
local aw_dim = Color(150, 190, 220)
local aw_bg = Color(3, 5, 9, 235)
local aw_card = Color(6, 12, 20, 168)
local aw_card_hover = Color(12, 22, 36, 205)
local aw_good = Color(70, 200, 120)
local aw_bad = Color(200, 55, 65)

local AW_TTS_CAP = 21 * 24 * 60 * 60

local function awScale()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(awScale() * n + 0.5)
end

local function awSmooth(speed, cur, target)
    cur = cur or 0
    if isfunction(LerpFT) then return LerpFT(speed, cur, target) end
    return Lerp(math.Clamp(FrameTime() / math.max(speed, 0.001), 0, 1), cur, target)
end

local function awDraw(rad, x, y, w, h, col)
    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function awOutline(rad, x, y, w, h, col, th)
    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, th or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, th or 1)
    end
end

local function awSlant(x, y, w, h, skew, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w + skew, y = y},
        {x = x + w, y = y + h},
        {x = x, y = y + h}
    })
end

local function awFonts()
    local s = awScale()
    surface.CreateFont("AWTTS_Brand", {font = "Montserrat SemiBold", size = math.floor(44 * s + 0.5), weight = 800, italic = true, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Sub", {font = "Montserrat Medium", size = math.floor(20 * s + 0.5), weight = 600, antialias = true, extended = true})
    surface.CreateFont("AWTTS_CardTitle", {font = "Montserrat SemiBold", size = math.floor(26 * s + 0.5), weight = 800, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Row", {font = "Montserrat SemiBold", size = math.floor(20 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Small", {font = "Montserrat Medium", size = math.floor(16 * s + 0.5), weight = 500, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Status", {font = "Montserrat SemiBold", size = math.floor(16 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Btn", {font = "Montserrat SemiBold", size = math.floor(22 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Close", {font = "Montserrat SemiBold", size = math.floor(34 * s + 0.5), weight = 800, antialias = true, extended = true})
    surface.CreateFont("AWTTS_Credit", {font = "Montserrat Medium", size = math.floor(18 * s + 0.5), weight = 600, antialias = true, extended = true})
end

awFonts()
hook.Add("OnScreenSizeChanged", "AW_TTS_Fonts", awFonts)

local function awSubLeft()
    local lp = LocalPlayer()
    if not IsValid(lp) then return 0 end
    local exp = tonumber(lp:GetNWFloat("TTSExpire", 0)) or 0
    if exp <= 0 then return 0 end
    return math.max(0, exp - os.time())
end

local function awFormatLeft(sec)
    sec = math.floor(sec or 0)
    if sec <= 0 then return "НЕТ АКТИВНОЙ ПОДПИСКИ" end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return d .. " Д " .. h .. " Ч" end
    if h > 0 then return h .. " Ч " .. m .. " МИН" end
    return m .. " МИН"
end

local function awExpireText()
    local lp = LocalPlayer()
    if not IsValid(lp) then return "" end
    local exp = tonumber(lp:GetNWFloat("TTSExpire", 0)) or 0
    if exp <= 0 then return "подписка не активирована" end
    return "активна до " .. os.date("%d.%m.%Y %H:%M", exp)
end

local awPreviewStation = nil
local awPreviewToken = 0
local AW_PREVIEW_TRIES = 4

local function awStopPreview()
    if IsValid(awPreviewStation) then awPreviewStation:Stop() end
    awPreviewStation = nil
end

local function awHoldStation(st, token)
    awStopPreview()
    awPreviewStation = st
    st:SetVolume(ttsVolume())
    st:Play()
    timer.Simple(20, function()
        if IsValid(st) and awPreviewStation == st and awPreviewToken == token then awStopPreview() end
    end)
end

local awPlayPreview

awPlayPreview = function(model, token, attempt, onErr)
    if awPreviewToken ~= token then return end

    local force = attempt > 1

    awEnsureKey(force, function(key)
        if awPreviewToken ~= token then return end

        local function retry(reason)
            if awPreviewToken ~= token then return end

            ttsDebug("preview attempt", attempt, "failed:", reason)

            if attempt >= AW_PREVIEW_TRIES then
                if onErr then onErr("Не удалось прослушать: " .. tostring(reason)) end
                return
            end

            netKey = ""

            timer.Simple(0.6 * attempt, function()
                awPlayPreview(model, token, attempt + 1, onErr)
            end)
        end

        if key == "" then
            requestSync()
            retry("сервер не выдал ключ")
            return
        end

        local txt = httpUrlEncode("Привет, это тест голоса.")
        local url_http = ttsURL("http", key, model, txt)
        local url_https = ttsURL("https", key, model, txt)

        local function tryFetch(lastErr)
            playViaFetch(nil, url_http, "mono noblock", function(ok, code, info)
                if ok then return end
                retry("BASS " .. tostring(lastErr) .. " / HTTP " .. tostring(code) .. " " .. tostring(info or ""))
            end)
        end

        sound.PlayURL(url_http, "mono noblock", function(st, errCode, errStr)
            if awPreviewToken ~= token then
                if IsValid(st) then st:Stop() end
                return
            end

            if IsValid(st) then
                awHoldStation(st, token)
                return
            end

            ttsDebug("preview http failed", errCode, errStr)

            sound.PlayURL(url_https, "mono noblock", function(st2, errCode2, errStr2)
                if awPreviewToken ~= token then
                    if IsValid(st2) then st2:Stop() end
                    return
                end

                if IsValid(st2) then
                    awHoldStation(st2, token)
                    return
                end

                ttsDebug("preview https failed", errCode2, errStr2)
                tryFetch(errCode2 or errCode)
            end)
        end)
    end)
end

local function awPreview(model, onErr)
    model = tostring(model or "")
    if model == "" then return end

    awPreviewToken = awPreviewToken + 1
    awStopPreview()
    awPlayPreview(model, awPreviewToken, 1, onErr)
end

local awModels = {}
local awModelsTime = 0

local function awFetchModels(onDone, onFail)
    if #awModels > 0 and (CurTime() - awModelsTime) < 300 then
        onDone(awModels)
        return
    end

    local function parse(body)
        local data = util.JSONToTable(body or "")
        if not data or not istable(data.models) then return false end

        local out = {}
        for _, v in ipairs(data.models) do
            if istable(v) and v.id and v.name then
                out[#out + 1] = {id = tostring(v.id), name = tostring(v.name), category = tostring(v.category or "")}
            end
        end

        if #out == 0 then return false end

        table.sort(out, function(a, b)
            if a.category == b.category then return a.name < b.name end
            return a.category < b.category
        end)

        awModels = out
        awModelsTime = CurTime()
        return true
    end

    local function tryHttps()
        http.Fetch("https://api.animeworld.space/get_models", function(body)
            if parse(body) then onDone(awModels) return end
            onFail("пустой ответ API")
        end, function(err)
            ttsDebug("get_models https failed", err)
            onFail(tostring(err))
        end)
    end

    http.Fetch("http://api.animeworld.space/get_models", function(body)
        if parse(body) then onDone(awModels) return end
        tryHttps()
    end, function(err)
        ttsDebug("get_models http failed", err)
        tryHttps()
    end)
end

local PANEL = {}

function PANEL:SetNotice(text, col)
    self.Notice = tostring(text or "")
    self.NoticeColor = col or aw_dim
    self.NoticeTime = RealTime()
end

function PANEL:Init()
    local base = self.BaseClass
    if base and isfunction(base.Init) then base.Init(self) end

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetAlpha(0)

    if isfunction(self.SetTitle) then self:SetTitle("") end
    if isfunction(self.SetBorder) then self:SetBorder(false) end
    if isfunction(self.SetColorBG) then self:SetColorBG(aw_bg) end
    if isfunction(self.SetBlurStrengh) then self:SetBlurStrengh(0) end
    if isfunction(self.SetDraggable) then self:SetDraggable(false) end
    if isfunction(self.ShowCloseButton) then self:ShowCloseButton(false) end
    if isfunction(self.SetSizable) then self:SetSizable(false) end

    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()
    self.Rows = {}
    self.Notice = ""
    self.NoticeColor = aw_dim
    self.NoticeTime = 0
    self.Loading = true
    self.LoadError = nil
    self.Selected = nil

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("")
    self.CloseButton:SetCursor("hand")
    self.CloseButton.HoverLerp = 0
    self.CloseButton.DoClick = function()
        if IsValid(self) then self:Close() end
    end
    self.CloseButton.Paint = function(btn, w, h)
        btn.HoverLerp = awSmooth(0.18, btn.HoverLerp, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverLerp, 8, 16),
            Lerp(btn.HoverLerp, 18, 60),
            Lerp(btn.HoverLerp, 30, 96),
            Lerp(btn.HoverLerp, 155, 225)
        )

        local rad = math.max(4, SX(8))

        awDraw(rad, 0, 0, w, h, bg)
        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 70 + btn.HoverLerp * 150), 1)
        draw.SimpleText("×", "AWTTS_Close", w * 0.5, h * 0.46, Color(Lerp(btn.HoverLerp, 235, aw_accent.r), Lerp(btn.HoverLerp, 235, aw_accent.g), Lerp(btn.HoverLerp, 235, aw_accent.b), 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.Search = vgui.Create("DTextEntry", self)
    self.Search:SetFont("AWTTS_Row")
    self.Search:SetPaintBackground(false)
    self.Search:SetTextColor(aw_text)
    self.Search:SetCursorColor(aw_accent)
    self.Search:SetUpdateOnType(true)
    self.Search.Paint = function(pnl, w, h)
        local rad = math.max(4, SX(8))
        awDraw(rad, 0, 0, w, h, Color(6, 12, 20, 215))
        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 90), 1)

        if pnl:GetValue() == "" then
            draw.SimpleText("Поиск голоса...", "AWTTS_Small", SX(14), h * 0.5, Color(aw_dim.r, aw_dim.g, aw_dim.b, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        pnl:DrawTextEntryText(aw_text, Color(aw_accent.r, aw_accent.g, aw_accent.b, 120), aw_accent)
    end
    self.Search.OnChange = function(pnl)
        self:Refill(pnl:GetValue())
    end

    self.List = vgui.Create("DScrollPanel", self)
    self.List.Paint = function(pnl, w, h)
        local rad = math.max(5, SX(12))
        awDraw(rad, 0, 0, w, h, aw_card)
        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 40), 1)

        if #self.Rows > 0 then return end

        local msg = self.Loading and "Загружаю список голосов..." or (self.LoadError and "Не удалось загрузить голоса" or "Ничего не найдено")
        draw.SimpleText(msg, "AWTTS_Row", w * 0.5, h * 0.5, Color(aw_dim.r, aw_dim.g, aw_dim.b, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local bar = self.List:GetVBar()
    bar:SetHideButtons(true)
    bar.Paint = function(pnl, w, h)
        awDraw(w * 0.5, 0, 0, w, h, Color(255, 255, 255, 16))
    end
    bar.btnGrip.Paint = function(pnl, w, h)
        awDraw(w * 0.5, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 190))
    end

    self.Card = vgui.Create("DPanel", self)
    self.Card.Paint = function(pnl, w, h)
        local rad = math.max(5, SX(12))
        awDraw(rad, 0, 0, w, h, aw_card)
        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 45), 1)
        awDraw(SX(3), SX(20), SX(20), w - SX(40), math.max(2, SX(4)), Color(aw_accent.r, aw_accent.g, aw_accent.b, 210))

        draw.SimpleText("ТЕКУЩИЙ ГОЛОС", "AWTTS_Status", SX(22), SX(40), Color(aw_dim.r, aw_dim.g, aw_dim.b, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local sel = self.Selected
        local name = sel and sel.name or "не выбран"
        local info = sel and (sel.category ~= "" and (sel.category .. "  •  ID " .. sel.id) or ("ID " .. sel.id)) or "выбери голос слева"

        draw.SimpleText(name, "AWTTS_CardTitle", SX(22), SX(66), sel and aw_text or aw_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(info, "AWTTS_Small", SX(22), SX(102), Color(aw_dim.r, aw_dim.g, aw_dim.b, 215), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        draw.SimpleText("Голос применяется сразу при выборе", "AWTTS_Small", SX(22), SX(136), Color(aw_cyan.r, aw_cyan.g, aw_cyan.b, 215), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(awExpireText(), "AWTTS_Small", SX(22), SX(160), Color(aw_good.r, aw_good.g, aw_good.b, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if self.Notice ~= "" and RealTime() - self.NoticeTime < 8 then
            draw.SimpleText(self.Notice, "AWTTS_Small", SX(22), SX(190), self.NoticeColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        draw.SimpleText("ГРОМКОСТЬ: " .. math.floor(ttsVolume() * 100 + 0.5) .. "%", "AWTTS_Status", SX(22), h - SX(178), Color(aw_text.r, aw_text.g, aw_text.b, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.Card.Slider = vgui.Create("DPanel", self.Card)
    self.Card.Slider.Dragging = false
    self.Card.Slider.Apply = function(pnl)
        local lx = pnl:ScreenToLocal(gui.MouseX(), gui.MouseY())
        local frac = math.Clamp(lx / math.max(1, pnl:GetWide()), 0, 1)
        RunConsoleCommand("aw_tts_volume", string.format("%.2f", frac * 2))
    end
    self.Card.Slider.OnMousePressed = function(pnl)
        pnl.Dragging = true
        pnl:Apply()
    end
    self.Card.Slider.OnMouseReleased = function(pnl)
        pnl.Dragging = false
    end
    self.Card.Slider.Think = function(pnl)
        if not pnl.Dragging then return end
        if not input.IsMouseDown(MOUSE_LEFT) then
            pnl.Dragging = false
            return
        end
        pnl:Apply()
    end
    self.Card.Slider.Paint = function(pnl, w, h)
        local frac = math.Clamp(ttsVolume() / 2, 0, 1)
        local rad = h * 0.5

        awDraw(rad, 0, 0, w, h, Color(4, 10, 18, 225))
        awDraw(rad, 0, 0, math.max(h, w * frac), h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 235))
        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 130), 1)
    end

    self.Card.TestBtn = vgui.Create("DButton", self.Card)
    self.Card.TestBtn:SetText("")
    self.Card.TestBtn:SetCursor("hand")
    self.Card.TestBtn.HoverLerp = 0
    self.Card.TestBtn.DoClick = function()
        local sel = self.Selected
        if not sel or sel.id == "" then
            self:SetNotice("Сначала выбери голос", aw_bad)
            return
        end

        self:SetNotice("Проигрываю пример...", aw_cyan)
        awPreview(sel.id, function(err) self:SetNotice(err, aw_bad) end)
    end
    self.Card.TestBtn.Paint = function(btn, w, h)
        btn.HoverLerp = awSmooth(0.18, btn.HoverLerp, btn:IsHovered() and 1 or 0)

        local rad = math.max(5, SX(10))

        awDraw(rad, 0, 0, w, h, Color(10, 30, 48, 200 + btn.HoverLerp * 55))

        if btn.HoverLerp > 0.01 then
            awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, btn.HoverLerp * 45), math.max(3, SX(6)))
        end

        awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 120 + btn.HoverLerp * 135), math.max(1, SX(1)))
        draw.SimpleText("ПРОСЛУШАТЬ ЗАНОВО", "AWTTS_Btn", w * 0.5, h * 0.5, Color(240, 248, 255, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.Card.PerformLayout = function(pnl, w, h)
        if IsValid(pnl.TestBtn) then
            pnl.TestBtn:SetSize(w - SX(44), SX(56))
            pnl.TestBtn:SetPos(SX(22), h - SX(80))
        end

        if IsValid(pnl.Slider) then
            pnl.Slider:SetSize(w - SX(44), math.max(6, SX(14)))
            pnl.Slider:SetPos(SX(22), h - SX(148))
        end
    end

    awFetchModels(function()
        if not IsValid(self) then return end
        self.Loading = false
        self:Refill(IsValid(self.Search) and self.Search:GetValue() or "")
    end, function(err)
        if not IsValid(self) then return end
        self.Loading = false
        self.LoadError = tostring(err)
        self:SetNotice("Не удалось загрузить голоса: " .. tostring(err), aw_bad)
    end)

    if #awModels > 0 then
        self.Loading = false
        self:Refill("")
    end
end

function PANEL:Apply(model)
    self.Selected = model

    RunConsoleCommand("TTSModel", model.id)
    RunConsoleCommand("ChangeTTSVoice", model.id)
    surface.PlaySound("ui/buttonrollover.wav")

    if model.id == "" then
        awStopPreview()
        self:SetNotice("Голос отключён", aw_dim)
        return
    end

    self:SetNotice("Проигрываю пример...", aw_cyan)
    awPreview(model.id, function(err)
        if IsValid(self) then self:SetNotice(err, aw_bad) end
    end)
end

function PANEL:AddRow(model)
    local row = vgui.Create("DButton", self.List)
    row:SetText("")
    row:SetCursor("hand")
    row:Dock(TOP)
    row:DockMargin(SX(12), SX(9), SX(12), 0)
    row:SetTall(SX(54))
    row.HoverLerp = 0
    row.Model = model
    row.Think = function(pnl)
        pnl.HoverLerp = awSmooth(0.16, pnl.HoverLerp, pnl:IsHovered() and 1 or 0)
    end
    row.DoClick = function()
        self:Apply(model)
    end
    row.Paint = function(pnl, w, h)
        local hover = pnl.HoverLerp or 0
        local sel = self.Selected and self.Selected.id == model.id
        local rad = math.max(4, SX(10))

        awDraw(rad, 0, 0, w, h, Color(
            Lerp(hover, aw_card.r, aw_card_hover.r),
            Lerp(hover, aw_card.g, aw_card_hover.g),
            Lerp(hover, aw_card.b, aw_card_hover.b),
            Lerp(hover, 150, 225)
        ))

        if sel then
            awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 60), math.max(3, SX(5)))
            awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 220), math.max(1, SX(2)))
        else
            awOutline(rad, 0, 0, w, h, Color(aw_accent.r, aw_accent.g, aw_accent.b, 14 + hover * 60), 1)
        end

        awDraw(SX(2), SX(12), h * 0.5 - SX(13), math.max(2, SX(3)), SX(26), Color(aw_accent.r, aw_accent.g, aw_accent.b, sel and 240 or (110 + hover * 100)))
        draw.SimpleText(model.name, "AWTTS_Row", SX(26), h * 0.35, sel and aw_accent or aw_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local info = model.id == "" and "озвучка твоего чата отключится" or (model.category ~= "" and (model.category .. "  •  ID " .. model.id) or ("ID " .. model.id))
        draw.SimpleText(info, "AWTTS_Small", SX(26), h * 0.72, Color(aw_dim.r, aw_dim.g, aw_dim.b, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if sel then
            draw.SimpleText("ВЫБРАН", "AWTTS_Status", w - SX(18), h * 0.5, Color(aw_accent.r, aw_accent.g, aw_accent.b, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    self.Rows[#self.Rows + 1] = row

    return row
end

function PANEL:Refill(filter)
    if not IsValid(self.List) then return end

    self.List:Clear()
    self.Rows = {}

    filter = string.lower(string.Trim(tostring(filter or "")))

    local current = tostring(GetConVarString("TTSModel") or "")

    self:AddRow({id = "", name = "Без голоса", category = ""})

    for _, m in ipairs(awModels) do
        local hay = string.lower(m.name .. " " .. m.category .. " " .. m.id)

        if filter == "" or string.find(hay, filter, 1, true) then
            self:AddRow(m)
        end

        if not self.Selected and m.id == current and current ~= "" then
            self.Selected = m
        end
    end
end

function PANEL:PerformLayout(w, h)
    local top = SX(212)
    local bottom = SX(92)
    local contW = math.min(SX(1280), w - SX(120))
    local contX = math.floor((w - contW) * 0.5)
    local contH = math.max(SX(200), h - top - bottom)
    local gap = SX(18)
    local leftW = math.floor(contW * 0.58)
    local rightW = contW - leftW - gap

    if IsValid(self.Search) then
        self.Search:SetSize(leftW, SX(44))
        self.Search:SetPos(contX, top)
    end

    if IsValid(self.List) then
        self.List:SetSize(leftW, contH - SX(56))
        self.List:SetPos(contX, top + SX(56))
    end

    if IsValid(self.Card) then
        self.Card:SetSize(rightW, contH)
        self.Card:SetPos(contX + leftW + gap, top)
    end

    if IsValid(self.CloseButton) then
        local s = SX(46)
        self.CloseButton:SetSize(s, s)
        self.CloseButton:SetPos(w - s - SX(48), SX(40))
    end
end

function PANEL:PaintBackground(w, h)
    local mat = self.BGMaterial

    if not mat or mat:IsError() then
        surface.SetDrawColor(aw_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(aw_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local elapsed = RealTime() - (self.BGStartTime or RealTime())
    local zoomTime = elapsed * 0.040
    local panTime = elapsed * 0.040
    local zoomWave = math.sin(zoomTime) * 0.5 + 0.5
    local zoom = 1.20 + zoomWave * 0.16
    local baseScale = math.max(w / iw, h / ih)
    local scale = baseScale * zoom
    local drawW = iw * scale
    local drawH = ih * scale
    local safeX = (drawW - w) * 0.5
    local safeY = (drawH - h) * 0.5

    if safeX < 0 then safeX = 0 end
    if safeY < 0 then safeY = 0 end

    local panX = math.sin(panTime * 0.80)
    local panY = math.sin(panTime * 0.61 + 1.7)
    local x = (w - drawW) * 0.5 + panX * safeX * 0.80
    local y = (h - drawH) * 0.5 + panY * safeY * 0.80

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Paint(w, h)
    self:PaintBackground(w, h)

    draw.NoTexture()

    surface.SetDrawColor(1, 4, 8, 132)
    surface.DrawRect(0, 0, w, h)

    local headerY = SX(36)
    local cx = w * 0.5

    surface.SetFont("AWTTS_Brand")
    local xW = surface.GetTextSize("OT-")
    local brandW = xW + surface.GetTextSize("CITY")

    draw.SimpleText("OT-", "AWTTS_Brand", cx - brandW * 0.5 + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "AWTTS_Brand", cx - brandW * 0.5 + xW + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "AWTTS_Brand", cx - brandW * 0.5, headerY, aw_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "AWTTS_Brand", cx - brandW * 0.5 + xW, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local sub = "НАСТРОЙКИ ГОВОРИЛКИ"
    surface.SetFont("AWTTS_Sub")
    local subW = surface.GetTextSize(sub)

    draw.SimpleText(sub, "AWTTS_Sub", cx, headerY + SX(58), Color(200, 225, 245, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local stripeY = headerY + SX(58) + SX(11)
    local stripeW = SX(48)

    awSlant(cx - subW * 0.5 - SX(18) - stripeW, stripeY, stripeW, math.max(2, SX(3)), -SX(6), aw_accent)
    awSlant(cx + subW * 0.5 + SX(18), stripeY, stripeW, math.max(2, SX(3)), SX(6), aw_accent)

    local left = awSubLeft()
    local target = math.Clamp(left / AW_TTS_CAP, 0, 1)

    self.SubFill = awSmooth(0.2, self.SubFill, target)

    local fill = math.Clamp(self.SubFill or 0, 0, 1)
    local fillCol = left > 0 and aw_cyan or aw_bad
    local barW = math.min(SX(560), w * 0.44)
    local barH = math.max(6, SX(14))
    local barX = cx - barW * 0.5
    local barY = headerY + SX(98)
    local barRad = barH * 0.5

    awDraw(barRad, barX, barY, barW, barH, Color(4, 10, 18, 225))

    if fill > 0.001 then
        awDraw(barRad, barX, barY, math.max(barH, barW * fill), barH, Color(fillCol.r, fillCol.g, fillCol.b, 235))
    end

    awOutline(barRad, barX, barY, barW, barH, Color(aw_accent.r, aw_accent.g, aw_accent.b, 130), 1)

    draw.SimpleText("ТВОЯ ПОДПИСКА", "AWTTS_Status", barX, barY - SX(8), Color(aw_text.r, aw_text.g, aw_text.b, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText("ОСТАЛОСЬ: " .. awFormatLeft(left), "AWTTS_Status", barX + barW, barY - SX(8), Color(fillCol.r, fillCol.g, fillCol.b, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(awExpireText(), "AWTTS_Status", cx, barY + barH + SX(7), Color(162, 190, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local credit = "спасибо за говорилку AnimeWorld и отдельно Феромону <3"

    draw.SimpleText(credit, "AWTTS_Credit", cx + SX(1), h - SX(44) + SX(1), Color(2, 8, 14, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(credit, "AWTTS_Credit", cx, h - SX(44), Color(aw_cyan.r, aw_cyan.g, aw_cyan.b, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function PANEL:First()
    self:AlphaTo(255, 0.18, 0, nil)
end

function PANEL:Think()
    if self.Closing then return end
    if not self:IsKeyboardInputEnabled() then return end
    if input.IsKeyDown(KEY_ESCAPE) then self:Close() end
end

function PANEL:Close()
    if self.Closing then return end

    self.Closing = true
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
    self:AlphaTo(0, 0.12, 0, function()
        if IsValid(self) then self:Remove() end
    end)
end

vgui.Register("AWTTSMenu", PANEL, vgui.GetControlTable("ZFrame") and "ZFrame" or "DFrame")

AW_TTS_Menu = AW_TTS_Menu or nil

local function awOpenMenu(retry)
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    if IsValid(AW_TTS_Menu) then
        AW_TTS_Menu:Close()
        AW_TTS_Menu = nil
        return
    end

    if not hasSub(lp) then
        if retry then
            chat.AddText(Color(255, 80, 80), "[TTS] У тебя нет активной подписки на говорилку.")
            return
        end

        requestSync()
        requestKey(false)
        chat.AddText(Color(255, 200, 80), "[TTS] Проверяю подписку...")
        timer.Simple(1.5, function() awOpenMenu(true) end)
        return
    end

    requestKey(false)

    local frame = vgui.Create("AWTTSMenu")
    if not IsValid(frame) then return end

    frame:MakePopup()
    frame:First()

    AW_TTS_Menu = frame
end

function AW_TTS_OpenMenu()
    awOpenMenu(false)
end

concommand.Add("aw_tts_menu", function() awOpenMenu(false) end)
concommand.Add("aw_tts_voices", function() awOpenMenu(false) end)

concommand.Add("aw_tts_diag", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    print("[AW_TTS] active:", lp:GetNWBool("TTSActive", false))
    print("[AW_TTS] expire:", lp:GetNWFloat("TTSExpire", 0))
    print("[AW_TTS] key:", getKey())
    print("[AW_TTS] key length:", string.len(getKey()))
    print("[AW_TTS] key source:", netKey ~= "" and "net" or "nwstring")
    print("[AW_TTS] model:", lp:GetNWString("TTSModel",""))
    print("[AW_TTS] steamid:", lp:SteamID())
    print("[AW_TTS] volume:", GetConVarString("aw_tts_volume"))
end)

concommand.Add("aw_tts_test", function(ply, cmd, args)
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local key = getKey()
    if key == "" then
        requestSync()
        print("[AW_TTS] нет ключа от сервера")
        return
    end

    local model = tostring(args and args[1] or lp:GetNWString("TTSModel", "") or "")
    if model == "" then
        print("[AW_TTS] модель не выбрана")
        return
    end

    local url = ttsURL("http", key, model, httpUrlEncode("Тест голоса"))
    print("[AW_TTS] url:", url)

    sound.PlayURL(url, "mono noblock", function(st, errCode, errStr)
        if IsValid(st) then
            st:SetVolume(ttsVolume())
            st:Play()
            timer.Simple(10, function() if IsValid(st) then st:Stop() end end)
            print("[AW_TTS] ok")
            return
        end
        print("[AW_TTS] fail:", errCode, errStr)
        playViaFetch(nil, url, "mono noblock", function(ok, code, info)
            print("[AW_TTS] fetch fallback:", ok, code, info)
        end)
    end)
end)

concommand.Add("aw_tts_probe", function(ply, cmd, args)
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local key = getKey()
    if key == "" then
        print("[AW_TTS] нет ключа от сервера")
        return
    end

    local model = tostring(args and args[1] or lp:GetNWString("TTSModel", "") or "")
    if model == "" then
        print("[AW_TTS] модель не выбрана")
        return
    end

    local url = ttsURL("http", key, model, httpUrlEncode("Тест голоса"))
    print("[AW_TTS] probe url:", url)

    http.Fetch(url, function(body, size, headers, code)
        print("[AW_TTS] http code:", code)
        print("[AW_TTS] size:", size)
        if istable(headers) then
            for k, v in pairs(headers) do
                print("[AW_TTS] header:", k, v)
            end
        end
        print("[AW_TTS] head:", string.sub(tostring(body or ""), 1, 300))
    end, function(err)
        print("[AW_TTS] probe error:", err)
    end)
end)