local PANEL = {}

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_bg = Color(3, 5, 9, 235)
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local RNDX = gSims_RNDX or {
    Draw = function(_, x, y, w, h, col)
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawRect(x, y, w, h)
    end,
    DrawOutlined = function(_, x, y, w, h, col)
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h)
    end
}

local MENU_MUSIC_URL = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/Danny_Elfman_Alice_In_Wonderland_-_Alice_s_Theme_(SkySound.cc).mp3"

ZMM_MusicVol = ZMM_MusicVol or 0
ZMM_MusicState = ZMM_MusicState or "stopped"

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
end

local function TrimToWidth(str, font, maxW)
    surface.SetFont(font)

    if surface.GetTextSize(str) <= maxW then
        return str
    end

    local out = str

    while #out > 1 do
        out = string.sub(out, 1, #out - 1)

        if surface.GetTextSize(out .. "...") <= maxW then
            return out .. "..."
        end
    end

    return out
end

local function SmoothNoise(t, f1, f2, f3, phase)
    local a = math.sin((t + phase) * f1 * math.pi * 2)
    local b = math.sin((t + phase * 1.7) * f2 * math.pi * 2 + 2.399)
    local c = math.sin((t + phase * 2.3) * f3 * math.pi * 2 + 5.131)

    return math.Clamp(a * 0.55 + b * 0.30 + c * 0.15, -1, 1)
end

local function DrawSlant(x, y, w, h, skew, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w + skew, y = y},
        {x = x + w, y = y + h},
        {x = x, y = y + h}
    })
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("ZC_MM_Title", {
        font = "Montserrat SemiBold",
        size = math.floor(112 * s + 0.5),
        weight = 800,
        italic = true,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_SubTitle", {
        font = "Montserrat SemiBold",
        size = math.floor(46 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Team", {
        font = "Montserrat Medium",
        size = math.floor(21 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Button", {
        font = "Montserrat Medium",
        size = math.floor(27 * s + 0.5),
        weight = 600,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Head", {
        font = "Montserrat SemiBold",
        size = math.floor(24 * s + 0.5),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Card", {
        font = "Montserrat SemiBold",
        size = math.floor(20 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Small", {
        font = "Montserrat Medium",
        size = math.floor(16 * s + 0.5),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_MM_Badge", {
        font = "Montserrat SemiBold",
        size = math.floor(14 * s + 0.5),
        weight = 800,
        antialias = true,
        extended = true
    })
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_MM_Fonts", CreateFonts)

local STATUS_URL = ""
local STATUS_FILE = "otcity_status.json"
local STATUS_DIR = "otcity_status"

local clr_ok = Color(90, 230, 145)
local clr_warn = Color(255, 195, 80)
local clr_bad = Color(255, 100, 100)
local clr_dim = Color(150, 170, 190)

ZMM_Status = ZMM_Status or {data = nil, at = 0, ttl = 30, busy = false, fail = 0, nextTry = 0, lastForce = 0, stamp = 0, err = nil}
ZMM_StatusImages = ZMM_StatusImages or {}
ZMM_StatusImageBusy = ZMM_StatusImageBusy or {}

file.CreateDir(STATUS_DIR)

local function StatusTTL()
    return math.Clamp(math.floor(tonumber(ZMM_Status.ttl) or 30), 15, 300)
end

local function StatusApply(raw)
    if not isstring(raw) or raw == "" then return false end

    local ok, tbl = pcall(util.JSONToTable, raw)
    if not ok or not istable(tbl) or not istable(tbl.servers) then return false end

    ZMM_Status.data = tbl
    ZMM_Status.ttl = tonumber(tbl.cache_ttl) or 30
    ZMM_Status.stamp = (ZMM_Status.stamp or 0) + 1

    return true
end

local function StatusLoadDisk()
    if not file.Exists(STATUS_FILE, "DATA") then return end

    local raw = file.Read(STATUS_FILE, "DATA")

    if StatusApply(raw) then
        ZMM_Status.at = math.floor(tonumber(file.Time(STATUS_FILE, "DATA")) or 0)
        ZMM_Status.err = nil
    end
end

local function StatusFetch(force)
    local now = os.time()

    if ZMM_Status.busy then return false end

    if force then
        if now - (ZMM_Status.lastForce or 0) < 10 then return false end
        ZMM_Status.lastForce = now
    else
        if ZMM_Status.data and now - (ZMM_Status.at or 0) < StatusTTL() then return false end
        if now < (ZMM_Status.nextTry or 0) then return false end
    end

    ZMM_Status.busy = true
    ZMM_Status.nextTry = now + math.max(10, StatusTTL())

    local function fail(reason)
        ZMM_Status.busy = false
        ZMM_Status.fail = math.min((ZMM_Status.fail or 0) + 1, 6)
        ZMM_Status.nextTry = os.time() + math.Clamp(15 * math.pow(2, ZMM_Status.fail), 15, 300)
        ZMM_Status.err = tostring(reason or "")
        ZMM_Status.stamp = (ZMM_Status.stamp or 0) + 1
    end

    http.Fetch(STATUS_URL, function(body, size, headers, code)
        if isnumber(code) and code >= 400 then return fail("HTTP " .. code) end
        if not StatusApply(body) then return fail("bad json") end

        ZMM_Status.busy = false
        ZMM_Status.at = os.time()
        ZMM_Status.fail = 0
        ZMM_Status.err = nil
        ZMM_Status.nextTry = ZMM_Status.at + math.max(10, StatusTTL())

        file.Write(STATUS_FILE, body)
    end, function(err)
        fail(err)
    end)

    return true
end

local function ImagePath(url)
    local ext = string.lower(tostring(string.match(url, "%.(%a%a%a%a?)$") or "png"))

    if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" then ext = "png" end
    if ext == "jpeg" then ext = "jpg" end

    return STATUS_DIR .. "/" .. util.CRC(url) .. "." .. ext
end

local function ServerImage(url)
    url = tostring(url or "")
    if url == "" then return nil end

    local cached = ZMM_StatusImages[url]
    if cached then return cached end

    local path = ImagePath(url)

    if file.Exists(path, "DATA") then
        local mat = Material("../data/" .. path, "smooth mips")

        if mat and not mat:IsError() then
            ZMM_StatusImages[url] = mat

            return mat
        end
    end

    if ZMM_StatusImageBusy[url] then return nil end

    ZMM_StatusImageBusy[url] = true

    http.Fetch(url, function(body, size, headers, code)
        ZMM_StatusImageBusy[url] = nil

        if not isstring(body) or body == "" then return end
        if isnumber(code) and code >= 400 then return end

        file.Write(path, body)

        local mat = Material("../data/" .. path, "smooth mips")

        if mat and not mat:IsError() then ZMM_StatusImages[url] = mat end
    end, function()
        ZMM_StatusImageBusy[url] = nil
    end)

    return nil
end

local function DrawMat(rad, x, y, w, h, col, mat)
    if RNDX.DrawMaterial then
        RNDX.DrawMaterial(rad, x, y, w, h, col, mat)

        return
    end

    surface.SetDrawColor(col)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, w, h)
end

local function IsOTCity(sv)
    local id = string.lower(tostring(sv.id or ""))
    local name = string.upper(tostring(sv.name or ""))

    if string.find(id, "otcity", 1, true) or string.find(id, "ot_city", 1, true) then return true end

    return string.find(name, "OT-CITY", 1, true) ~= nil or string.find(name, "OT CITY", 1, true) ~= nil
end

local function ServerAddress(sv)
    local connect = tostring(sv.connect or "")
    local ip = string.match(connect, "connect/([%d%.]+:%d+)") or string.match(connect, "connect/([%d%.]+)") or string.match(connect, "([%d%.]+:%d+)") or ""

    if ip == "" then ip = tostring(sv.ip or sv.address or "") end
    if ip == "" then return "" end
    if not string.find(ip, ":", 1, true) then ip = ip .. ":27015" end

    return ip
end

local function LocalAddress()
    local addr = ""

    if game.GetIPAddress then
        local ok, value = pcall(game.GetIPAddress)
        if ok and value then addr = tostring(value) end
    end

    if addr == "" then return "" end
    if not string.find(addr, ":", 1, true) then addr = addr .. ":27015" end

    return addr
end

local function ServerFlags(sv)
    local base = string.lower(tostring(sv.status or ""))
    local real = string.lower(tostring(sv.realStatus or sv.real_status or ""))
    local online = math.max(0, math.floor(tonumber(sv.online) or 0))
    local slots = math.max(0, math.floor(tonumber(sv.maxPlayers) or tonumber(sv.max_players) or 0))
    local locked = sv.password == true or sv.locked == true or sv.private == true or sv.hasPassword == true

    if not locked then
        local raw = string.lower(tostring(sv.password or sv.locked or ""))
        locked = raw == "1" or raw == "true" or raw == "yes"
    end

    local state = "online"

    if base ~= "" and base ~= "active" and base ~= "online" then
        state = (base == "maintenance" or base == "work" or base == "update") and "work" or "off"
    end

    if real ~= "" and real ~= "online" then state = "off" end
    if state == "online" and slots <= 0 then state = "off" end
    if state == "online" and locked then state = "locked" end
    if state == "online" and slots > 0 and online >= slots then state = "full" end

    return state, locked, online, slots
end

local function StateLabel(state)
    if state == "off" then return "ОФФЛАЙН", clr_bad end
    if state == "work" then return "ТЕХРАБОТЫ", clr_warn end
    if state == "locked" then return "НА ПАРОЛЕ", clr_warn end
    if state == "full" then return "ЗАПОЛНЕН", clr_warn end

    return "ОНЛАЙН", clr_ok
end

local function StatusNotify(text)
    if chat and chat.AddText then
        chat.AddText(clr_accent, "[OT-CITY] ", clr_text, tostring(text or ""))

        return
    end

    MsgN("[OT-CITY] " .. tostring(text or ""))
end

local function ConnectTo(sv)
    local ip = ServerAddress(sv)
    local state = ServerFlags(sv)
    local name = tostring(sv.name or ip)

    if ip == "" then
        StatusNotify("Адрес сервера неизвестен.")

        return
    end

    if state == "off" then
        StatusNotify(name .. " сейчас недоступен.")

        return
    end

    if ip == LocalAddress() then
        StatusNotify("Ты уже играешь на этом сервере.")

        return
    end

    local hint = state == "locked" and "Сервер закрыт паролем, вход только для тех, у кого он есть." or (state == "full" and "Сервер заполнен, вход возможен только по резервному слоту." or "")
    local text = "Перейти на " .. name .. "?\n" .. ip

    if hint ~= "" then text = text .. "\n" .. hint end

    Derma_Query(text, "OT-CITY", "Подключиться", function()
        if IsValid(MainMenu) and MainMenu.Close then MainMenu:Close() end

        timer.Simple(0.15, function()
            RunConsoleCommand("connect", ip)
        end)
    end, "Отмена", function() end)
end

local Selects = {
    {Title = "Вернуться", Func = function(luaMenu) luaMenu:Close() end},
    {Title = "Роли Т"},
    {Title = "Профессии", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_professions") end},
    {Title = "Игровой рынок", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_market") end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/PEjPGmBaF3") end},
    {Title = "Настройки биндов (клавиш)", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_keybinds") end},
    {Title = "Достижения", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_achievements") end},
    {Title = "Одежда", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_appearance_menu") end},
    {Title = "Форум", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://forum-monteract.ru/") end},
    {Title = "Говорилка", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("aw_tts_menu") end},
    {Title = "Донат", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("rk_donate_menu") end},
    {Title = "Настройки", Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_settings") end},
    {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Отключиться", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
}

hook.Add("Think", "ZMM_MusicFade", function()
    local menuOpen = (MainMenu and IsValid(MainMenu)) or (hg_options and IsValid(hg_options))

    if not menuOpen then
        ZMM_MusicState = "out"
    end

    if not IsValid(ZMM_MusicChannel) then
        return
    end

    local ft = FrameTime()

    if ZMM_MusicState == "in" then
        ZMM_MusicVol = Lerp(ft * 1.1, ZMM_MusicVol, 1)
    elseif ZMM_MusicState == "out" then
        ZMM_MusicVol = Lerp(ft * 3.0, ZMM_MusicVol, 0)

        if ZMM_MusicVol <= 0.01 then
            ZMM_MusicChannel:Stop()
            ZMM_MusicChannel = nil
            ZMM_MusicVol = 0
            ZMM_MusicState = "stopped"
            ZMM_PlayingURL = nil

            return
        end
    end

    ZMM_MusicChannel:SetVolume(math.Clamp(ZMM_MusicVol, 0, 1))
end)

function PANEL:StartMusic()
    ZMM_DesiredURL = MENU_MUSIC_URL
    ZMM_MusicState = "in"

    if IsValid(ZMM_MusicChannel) and ZMM_PlayingURL == MENU_MUSIC_URL then
        return
    end

    if IsValid(ZMM_MusicChannel) then
        ZMM_MusicChannel:Stop()
        ZMM_MusicChannel = nil
    end

    ZMM_MusicVol = 0
    ZMM_PlayingURL = MENU_MUSIC_URL

    local url = MENU_MUSIC_URL

    sound.PlayURL(url, "noplay noblock", function(channel, errID, errName)
        if not IsValid(channel) then
            return
        end

        if ZMM_DesiredURL ~= url then
            channel:Stop()

            return
        end

        ZMM_MusicChannel = channel
        channel:SetVolume(0)
        channel:EnableLooping(true)
        channel:Play()
    end)
end

function PANEL:GetServerText()
    local mapname = game.GetMap()
    local prefix = string.find(mapname, "%*")

    if prefix then
        mapname = string.sub(mapname, prefix + 1)
    end

    local roundName = mapname

    if zb and zb.GetRoundName then
        roundName = zb.GetRoundName()
    end

    return gmod.GetGamemode().Name .. " | " .. string.NiceName(roundName)
end

function PANEL:GetLayoutData(w, h)
    local s = Sc()

    local headerX = math.floor(216 * s)
    local headerY = math.floor(36 * s)
    local lineX = headerX - math.floor(21 * s)
    local lineY = headerY + math.floor(200 * s)
    local menuX = lineX + math.floor(81 * s)
    local menuY = lineY + math.floor(26 * s)

    return headerX, headerY, lineX, lineY, menuX, menuY
end

function PANEL:GetListMetrics()
    local pitch = self.ItemPitch or SX(54)
    local count = math.max(#self.Buttons, 1)
    local btnH = math.max(pitch - SX(8), SX(18))
    local listH = (count - 1) * pitch + btnH

    return pitch, btnH, listH
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("OT-CITY")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_bg)
    self:ShowCloseButton(false)

    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()

    self.Buttons = {}
    self.RoleButtons = {}
    self.RoleListOpened = false
    self.ServerText = self:GetServerText()

    self:StartMusic()

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)

    self.Content.Paint = function(_, w, h)
        local headerX, headerY, lineX, _, _, menuY = self:GetLayoutData(w, h)
        local s = Sc()

        surface.SetFont("ZC_MM_Title")
        local xW = surface.GetTextSize("OT-")
        local shadow = Color(2, 8, 14, 190)

        draw.SimpleText("OT-", "ZC_MM_Title", headerX + SX(2), headerY + SX(3), shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("CITY", "ZC_MM_Title", headerX + xW + SX(2), headerY + SX(3), shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("OT-", "ZC_MM_Title", headerX, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("CITY", "ZC_MM_Title", headerX + xW, headerY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local stripeY = headerY + math.floor(122 * s)
        local stripeH = math.max(2, math.floor(4 * s))

        DrawSlant(headerX + math.floor(4 * s), stripeY, math.floor(150 * s), stripeH, math.floor(10 * s), clr_accent)
        DrawSlant(headerX + math.floor(168 * s), stripeY, math.floor(30 * s), stripeH, math.floor(10 * s), clr_cyan)

        local serverLine = TrimToWidth(self.ServerText or "", "ZC_MM_SubTitle", math.floor(760 * s))

        draw.SimpleText(serverLine, "ZC_MM_SubTitle", headerX, headerY + math.floor(140 * s), Color(240, 248, 255, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local _, _, listH = self:GetListMetrics()
        local lineW = math.max(2, SX(2))
        local lineTop = menuY + SX(2)

        RNDX.Draw(lineW, lineX - lineW, lineTop, lineW * 3, listH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 26))
        RNDX.Draw(lineW * 0.5, lineX, lineTop, lineW, listH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 235))
    end

    self.ButtonWrap = vgui.Create("DPanel", self.Content)
    self.ButtonWrap.Paint = nil

    for _, v in ipairs(Selects) do
        local btn = self:AddSelect(self.ButtonWrap, v.Title, v)

        if v.Title == "Роли Т" then
            self.RoleMainButton = btn
        end
    end

    self.RolePanel = vgui.Create("DPanel", self.Content)
    self.RolePanel:SetSize(SX(285), SX(108))
    self.RolePanel:SetVisible(false)
    self.RolePanel:SetMouseInputEnabled(false)
    self.RolePanel.Paint = nil

    self:AddRoleSelect(self.RolePanel, "SOE", "soe", 0)
    self:AddRoleSelect(self.RolePanel, "STD", "standard", 1)

    self:BuildServerPanel()

    self:InvalidateLayout(true)
end

function PANEL:BuildServerPanel()
    local luaMenu = self

    self.ServerCards = {}
    self.ServerRows = {}
    self.ServerSig = nil

    self.ServerPanel = vgui.Create("DPanel", self.Content)

    self.ServerPanel.Paint = function(pnl, w, h)
        local s = Sc()

        draw.SimpleText("НАШИ", "ZC_MM_Head", 0, SX(2), clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetFont("ZC_MM_Head")

        local headW = surface.GetTextSize("НАШИ ")

        draw.SimpleText("СЕРВЕРА", "ZC_MM_Head", headW, SX(2), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local stripeY = SX(32)

        DrawSlant(0, stripeY, math.floor(64 * s), math.max(2, math.floor(3 * s)), math.floor(7 * s), clr_accent)
        DrawSlant(math.floor(74 * s), stripeY, math.floor(16 * s), math.max(2, math.floor(3 * s)), math.floor(7 * s), clr_cyan)

        local total = 0
        local live = 0

        for _, sv in ipairs(luaMenu.ServerList or {}) do
            local state, _, online = ServerFlags(sv)

            total = total + online

            if state ~= "off" then live = live + 1 end
        end

        local sub = "Игроков сейчас " .. total .. "  ·  доступно " .. live
        local stamp = tonumber(ZMM_Status.at) or 0

        if stamp > 0 then sub = sub .. "  ·  " .. os.date("%H:%M:%S", stamp) end
        if ZMM_Status.busy then sub = sub .. "  ·  обновление" end

        draw.SimpleText(TrimToWidth(sub, "ZC_MM_Small", w - SX(130)), "ZC_MM_Small", 0, SX(44), clr_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if #(luaMenu.ServerCards or {}) > 0 then return end

        local message = ZMM_Status.busy and "Загружаем список серверов" or "Серверы OT-CITY не найдены"

        if ZMM_Status.err and not ZMM_Status.data then message = "Статус серверов недоступен" end

        draw.SimpleText(message, "ZC_MM_Small", w * 0.5, h * 0.5, clr_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.ServerPanel.Think = function(pnl)
        StatusFetch(false)

        if (ZMM_Status.stamp or 0) ~= (pnl.Stamp or -1) then
            pnl.Stamp = ZMM_Status.stamp or 0

            luaMenu:RefreshServerList()
        end
    end

    self.ServerPanel.PerformLayout = function(pnl, w, h)
        if IsValid(luaMenu.ServerScroll) then
            luaMenu.ServerScroll:SetPos(0, SX(70))
            luaMenu.ServerScroll:SetSize(w, h - SX(74))
        end

        if IsValid(luaMenu.ServerRefresh) then
            luaMenu.ServerRefresh:SetSize(SX(112), SX(32))
            luaMenu.ServerRefresh:SetPos(w - SX(112), SX(6))
        end
    end

    self.ServerRefresh = vgui.Create("DButton", self.ServerPanel)
    self.ServerRefresh:SetText("")
    self.ServerRefresh:SetCursor("hand")
    self.ServerRefresh.HoverLerp = 0

    self.ServerRefresh.Paint = function(pnl, w, h)
        local hover = pnl.HoverLerp or 0
        local rad = math.max(4, SX(9))

        RNDX.Draw(rad, 0, 0, w, h, Color(8, 18, 30, 120 + hover * 70))

        if hover > 0.01 then
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 45), math.max(2, SX(5)))
        end

        RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + hover * 165), math.max(1, SX(1)))
        draw.SimpleText("ОБНОВИТЬ", "ZC_MM_Badge", w * 0.5, h * 0.5, clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.ServerRefresh.Think = function(pnl)
        pnl.HoverLerp = LerpFT(0.18, pnl.HoverLerp or 0, pnl:IsHovered() and 1 or 0)
    end

    self.ServerRefresh.DoClick = function()
        if StatusFetch(true) then return end

        StatusNotify("Статус обновляется не чаще раза в 10 секунд.")
    end

    self.ServerScroll = vgui.Create("DScrollPanel", self.ServerPanel)
    self.ServerScroll.Paint = nil

    local bar = self.ServerScroll:GetVBar()

    bar:SetWide(SX(5))
    bar:SetHideButtons(true)

    bar.Paint = function(_, w, h)
        RNDX.Draw(math.max(2, SX(3)), 0, 0, w, h, Color(255, 255, 255, 16))
    end

    bar.btnGrip.Paint = function(_, w, h)
        RNDX.Draw(math.max(2, SX(3)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 175))
    end

    self:RefreshServerList()
end

function PANEL:CollectServers()
    local out = {}
    local data = ZMM_Status.data

    if not istable(data) or not istable(data.servers) then return out end

    for _, sv in ipairs(data.servers) do
        if istable(sv) and IsOTCity(sv) then out[#out + 1] = sv end
    end

    table.sort(out, function(a, b)
        return tostring(a.id or a.name or "") < tostring(b.id or b.name or "")
    end)

    return out
end

function PANEL:RefreshServerList()
    if not IsValid(self.ServerScroll) then return end

    local list = self:CollectServers()
    local sig = ""

    for _, sv in ipairs(list) do
        sig = sig .. tostring(sv.id or sv.name or "?") .. "|"
    end

    self.ServerList = list

    if self.ServerSig == sig and istable(self.ServerCards) then
        for i, sv in ipairs(list) do
            local card = self.ServerCards[i]

            if IsValid(card) then card.Data = sv end
        end

        return
    end

    self.ServerSig = sig
    self.ServerScroll:Clear()
    self.ServerCards = {}
    self.ServerRows = {}

    local row

    for i, sv in ipairs(list) do
        if (i - 1) % 2 == 0 then
            row = self:AddServerRow(self.ServerScroll)
            self.ServerRows[#self.ServerRows + 1] = row
        end

        local card = self:AddServerCard(row, sv, i - 1)

        row.Cards[#row.Cards + 1] = card
        self.ServerCards[i] = card
    end

    self.ServerScroll:InvalidateLayout(true)
end

function PANEL:AddServerRow(parent)
    local row = vgui.Create("DPanel", parent)

    row.Cards = {}
    row.Paint = nil

    row:Dock(TOP)
    row:DockMargin(0, 0, SX(10), SX(12))
    row:SetTall(SX(228))

    row.PerformLayout = function(pnl, w, h)
        local gap = SX(12)
        local cw = math.floor((w - gap) * 0.5)

        for i, card in ipairs(pnl.Cards) do
            if IsValid(card) then
                card:SetSize(cw, h)
                card:SetPos((i - 1) * (cw + gap), 0)
            end
        end
    end

    return row
end

function PANEL:AddServerCard(parent, sv, index)
    local luaMenu = self
    local card = vgui.Create("DPanel", parent)

    card.Data = sv
    card.HoverLerp = 0
    card.Appear = 0
    card.Delay = index * 0.045

    card.Paint = function(pnl, w, h)
        local data = istable(pnl.Data) and pnl.Data or {}
        local appear = math.Clamp(pnl.Appear or 1, 0, 1)
        local hover = pnl.HoverLerp or 0
        local alpha = 255 * appear
        local rad = math.max(4, SX(14))
        local pad = SX(12)
        local state, _, online, slots = ServerFlags(data)
        local label, scol = StateLabel(state)
        local ip = ServerAddress(data)
        local local_ip = LocalAddress()
        local here = ip ~= "" and ip == local_ip

        RNDX.Draw(rad, 0, 0, w, h, Color(8, 18, 30, (118 + hover * 62) * appear))

        if hover > 0.01 then
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 42 * appear), math.max(2, SX(5)))
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 185 * appear), math.max(1, SX(1)))
        else
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 34 * appear), math.max(1, SX(1)))
        end

        local icon = SX(78)
        local iconRad = math.max(3, SX(11))
        local mat = ServerImage(data.image)

        RNDX.Draw(iconRad, pad, pad, icon, icon, Color(4, 10, 18, 210 * appear))

        if mat then
            DrawMat(iconRad, pad, pad, icon, icon, Color(255, 255, 255, alpha), mat)

            if state == "off" then
                RNDX.Draw(iconRad, pad, pad, icon, icon, Color(3, 9, 16, 140 * appear))
            end
        else
            draw.SimpleText("OT", "ZC_MM_Card", pad + icon * 0.5, pad + icon * 0.5, Color(clr_accent.r, clr_accent.g, clr_accent.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        RNDX.DrawOutlined(iconRad, pad, pad, icon, icon, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 * appear), math.max(1, SX(1)))

        local tx = pad + icon + SX(12)
        local tw = w - tx - pad

        draw.SimpleText(TrimToWidth(tostring(data.name or "OT-CITY"), "ZC_MM_Card", tw), "ZC_MM_Card", tx, pad + SX(2), Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetFont("ZC_MM_Badge")

        local badge = here and "ТЫ ЗДЕСЬ" or label
        local bcol = here and clr_accent or scol
        local bw = surface.GetTextSize(badge) + SX(18)
        local by = pad + SX(30)

        RNDX.Draw(math.max(3, SX(6)), tx, by, math.min(bw, tw), SX(22), Color(bcol.r * 0.22, bcol.g * 0.22, bcol.b * 0.22, 235 * appear))
        draw.SimpleText(badge, "ZC_MM_Badge", tx + math.min(bw, tw) * 0.5, by + SX(11), Color(bcol.r, bcol.g, bcol.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText(TrimToWidth(ip ~= "" and ip or "адрес неизвестен", "ZC_MM_Small", tw), "ZC_MM_Small", tx, pad + SX(58), Color(clr_cyan.r, clr_cyan.g, clr_cyan.b, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local y = pad + icon + SX(12)
        local mapName = tostring(data.map or "")

        if mapName == "" or mapName == "nil" then mapName = "карта неизвестна" end

        draw.SimpleText(TrimToWidth(mapName, "ZC_MM_Small", w - pad * 2 - SX(70)), "ZC_MM_Small", pad, y, Color(clr_dim.r, clr_dim.g, clr_dim.b, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local ping = tonumber(data.ping)

        if ping and ping > 0 and state ~= "off" then
            draw.SimpleText(math.floor(ping) .. " ms", "ZC_MM_Small", w - pad, y, Color(clr_dim.r, clr_dim.g, clr_dim.b, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        y = y + SX(22)

        draw.SimpleText("Игроки", "ZC_MM_Small", pad, y, Color(clr_dim.r, clr_dim.g, clr_dim.b, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(state == "off" and "нет связи" or (online .. " / " .. (slots > 0 and slots or "?")), "ZC_MM_Small", w - pad, y, Color(255, 255, 255, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        y = y + SX(23)

        local barW = w - pad * 2
        local barH = math.max(3, SX(6))
        local frac = (slots > 0 and state ~= "off") and math.Clamp(online / slots, 0, 1) or 0

        RNDX.Draw(math.max(2, SX(3)), pad, y, barW, barH, Color(255, 255, 255, 22 * appear))

        if frac > 0 then
            RNDX.Draw(math.max(2, SX(3)), pad, y, math.max(barH, barW * frac), barH, Color(bcol.r, bcol.g, bcol.b, 225 * appear))
        end
    end

    card.Think = function(pnl)
        local hovered = pnl:IsHovered() or (IsValid(pnl.Connect) and pnl.Connect:IsHovered()) or (IsValid(pnl.Discord) and pnl.Discord:IsHovered())

        pnl.HoverLerp = LerpFT(0.18, pnl.HoverLerp or 0, hovered and 1 or 0)

        local target = CurTime() >= (luaMenu.OpenTime or 0) + (pnl.Delay or 0) and 1 or 0

        pnl.Appear = LerpFT(0.16, pnl.Appear or 0, target)
        pnl:SetAlpha(255 * pnl.Appear)
    end

    card.PerformLayout = function(pnl, w, h)
        local pad = SX(12)
        local bh = SX(34)
        local dw = SX(84)

        if IsValid(pnl.Connect) then
            pnl.Connect:SetPos(pad, h - bh - pad)
            pnl.Connect:SetSize(math.max(SX(60), w - pad * 2 - dw - SX(8)), bh)
        end

        if IsValid(pnl.Discord) then
            pnl.Discord:SetPos(w - pad - dw, h - bh - pad)
            pnl.Discord:SetSize(dw, bh)
        end
    end

    card.Connect = vgui.Create("DButton", card)
    card.Connect:SetText("")
    card.Connect:SetCursor("hand")
    card.Connect.HoverLerp = 0

    card.Connect.Paint = function(pnl, w, h)
        local data = istable(card.Data) and card.Data or {}
        local state = ServerFlags(data)
        local hover = pnl.HoverLerp or 0
        local rad = math.max(3, SX(9))
        local col = clr_accent
        local text = "ПОДКЛЮЧИТЬСЯ"

        if state == "off" then
            col = Color(90, 100, 115)
            text = "НЕДОСТУПЕН"
        elseif state == "work" then
            col = clr_warn
            text = "ТЕХРАБОТЫ"
        elseif state == "locked" then
            col = clr_warn
            text = "ВХОД ПО ПАРОЛЮ"
        elseif state == "full" then
            col = clr_warn
            text = "ЗАНЯТО, ПОПРОБОВАТЬ"
        end

        local local_ip = LocalAddress()

        if local_ip ~= "" and ServerAddress(data) == local_ip then text = "ТЫ УЖЕ ТУТ" end

        RNDX.Draw(rad, 0, 0, w, h, Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 205 + hover * 45))

        if hover > 0.01 then
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(col.r, col.g, col.b, hover * 45), math.max(2, SX(5)))
        end

        RNDX.DrawOutlined(rad, 0, 0, w, h, Color(col.r, col.g, col.b, 85 + hover * 155), math.max(1, SX(1)))
        draw.SimpleText(TrimToWidth(text, "ZC_MM_Badge", w - SX(12)), "ZC_MM_Badge", w * 0.5, h * 0.5, Color(255, 255, 255, 242), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    card.Connect.Think = function(pnl)
        pnl.HoverLerp = LerpFT(0.18, pnl.HoverLerp or 0, pnl:IsHovered() and 1 or 0)
    end

    card.Connect.DoClick = function()
        ConnectTo(istable(card.Data) and card.Data or {})
    end

    card.Connect.DoRightClick = function()
        local ip = ServerAddress(istable(card.Data) and card.Data or {})

        if ip == "" then return end

        SetClipboardText(ip)
        StatusNotify("IP скопирован: " .. ip)
    end

    card.Discord = vgui.Create("DButton", card)
    card.Discord:SetText("")
    card.Discord:SetCursor("hand")
    card.Discord.HoverLerp = 0

    card.Discord.Paint = function(pnl, w, h)
        local hover = pnl.HoverLerp or 0
        local rad = math.max(3, SX(9))

        RNDX.Draw(rad, 0, 0, w, h, Color(24, 27, 50, 205 + hover * 45))
        RNDX.DrawOutlined(rad, 0, 0, w, h, Color(114, 137, 218, 85 + hover * 155), math.max(1, SX(1)))
        draw.SimpleText("DISCORD", "ZC_MM_Badge", w * 0.5, h * 0.5, Color(205, 214, 255, 242), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    card.Discord.Think = function(pnl)
        pnl.HoverLerp = LerpFT(0.18, pnl.HoverLerp or 0, pnl:IsHovered() and 1 or 0)
    end

    card.Discord.DoClick = function()
        local data = istable(card.Data) and card.Data or {}
        local link = tostring(data.discord or "")

        if link == "" then
            StatusNotify("Ссылка на Discord не указана.")

            return
        end

        gui.OpenURL(link)
    end

    return card
end

function PANEL:PerformLayout(w, h)
    local _, _, _, _, menuX, menuY = self:GetLayoutData(w, h)

    if IsValid(self.ButtonWrap) then
        local count = math.max(#self.Buttons, 1)
        local avail = h - menuY - SX(22)

        self.ItemPitch = math.max(SX(24), math.min(SX(54), math.floor(avail / count)))

        self.ButtonWrap:SetWide(SX(735))
        self.ButtonWrap:SetTall(h - menuY - SX(22))
        self.ButtonWrap:SetPos(menuX, menuY)
    end

    if IsValid(self.ServerPanel) then
        local pw = math.Clamp(math.floor(w * 0.36), SX(520), SX(760))
        local py = SX(104)
        local ph = math.max(SX(260), h - py - SX(70))

        if pw > w - SX(120) then pw = w - SX(120) end

        self.ServerPanel:SetSize(pw, ph)
        self.ServerPanel:SetPos(w - pw - SX(60), py)
    end

    if IsValid(self.RolePanel) and IsValid(self.RoleMainButton) and IsValid(self.ButtonWrap) then
        self.RolePanel:SetPos(
            self.ButtonWrap:GetX() + self.RoleMainButton:GetX() + SX(452),
            self.ButtonWrap:GetY() + self.RoleMainButton:GetY() + SX(2)
        )
    end
end

function PANEL:PaintBackground(w, h)
    local mat = self.BGMaterial

    if not mat or mat:IsError() then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local now = RealTime()

    self.BGStartTime = self.BGStartTime or now
    self.BGLastTime = self.BGLastTime or now

    local elapsed = now - self.BGStartTime
    local dt = math.Clamp(now - self.BGLastTime, 0, 0.1)

    self.BGLastTime = now

    local zoomTarget = 1.18 + (SmoothNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
    local panTargetX = SmoothNoise(elapsed, 0.0131, 0.0223, 0.0367, 1.3)
    local panTargetY = SmoothNoise(elapsed, 0.0117, 0.0196, 0.0341, 4.9)

    self.BGZoom = self.BGZoom or zoomTarget
    self.BGPanX = self.BGPanX or panTargetX
    self.BGPanY = self.BGPanY or panTargetY

    local blend = 1 - math.exp(-dt * 1.35)

    self.BGZoom = self.BGZoom + (zoomTarget - self.BGZoom) * blend
    self.BGPanX = self.BGPanX + (panTargetX - self.BGPanX) * blend
    self.BGPanY = self.BGPanY + (panTargetY - self.BGPanY) * blend

    local baseScale = math.max(w / iw, h / ih)
    local scale = baseScale * self.BGZoom
    local drawW = iw * scale
    local drawH = ih * scale

    local safeX = (drawW - w) * 0.5
    local safeY = (drawH - h) * 0.5

    if safeX < 0 then safeX = 0 end
    if safeY < 0 then safeY = 0 end

    local x = (w - drawW) * 0.5 + self.BGPanX * safeX * 0.72
    local y = (h - drawH) * 0.5 + self.BGPanY * safeY * 0.72

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Paint(w, h)
    self:PaintBackground(w, h)

    draw.NoTexture()

    surface.SetDrawColor(1, 4, 8, 118)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(2, 7, 14, 225)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(1095), h)

    surface.SetDrawColor(2, 7, 14, 90)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(1665), h)
end

function PANEL:CreateTextButton(parent, title)
    local btn = vgui.Create("DButton", parent)

    btn:SetText("")
    btn:SetMouseInputEnabled(true)
    btn:SetKeyboardInputEnabled(false)
    btn:SetCursor("hand")

    btn:SetSize(SX(430), SX(44))
    btn.ButtonText = title
    btn.HoverLerp = 0
    btn.AppearLerp = 0
    btn.AppearDelay = 0

    function btn:Paint(w, h)
        local hover = self.HoverLerp or 0
        local appear = self.AppearLerp or 1
        local s = Sc()
        local rad = math.max(4, SX(8))

        RNDX.Draw(rad, 0, 0, w, h, Color(8, 18, 30, (110 + hover * 55) * appear))

        if hover > 0.01 then
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 42 * appear), math.max(2, SX(5)))
            RNDX.DrawOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 185 * appear), math.max(1, SX(1)))
        end

        local textX = 16 * s + hover * 8 * s

        local col = Color(
            Lerp(hover, clr_text.r, 255),
            Lerp(hover, clr_text.g, 255),
            Lerp(hover, clr_text.b, 255),
            245 * appear
        )

        draw.SimpleText(
            self.ButtonText,
            "ZC_MM_Button",
            textX,
            h * 0.5,
            col,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    return btn
end

function PANEL:AddSelect(pParent, strTitle, tbl)
    local id = #self.Buttons + 1
    local btn = self:CreateTextButton(pParent, strTitle)

    btn.Func = tbl.Func
    btn.ItemIndex = id - 1
    btn.AppearDelay = (id - 1) * 0.035
    btn:SetAlpha(0)

    local luaMenu = self

    function btn:DoClick()
        if strTitle == "Роли Т" then
            luaMenu.RoleListOpened = not luaMenu.RoleListOpened

            if IsValid(luaMenu.RolePanel) then
                luaMenu.RolePanel:SetVisible(luaMenu.RoleListOpened)
                luaMenu.RolePanel:SetMouseInputEnabled(luaMenu.RoleListOpened)
                luaMenu.RolePanel:MoveToFront()
            end

            return
        end

        if self.Func then
            self.Func(luaMenu)
        end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)

        local targetAppear = CurTime() >= (luaMenu.OpenTime or 0) + self.AppearDelay and 1 or 0

        self.AppearLerp = LerpFT(0.16, self.AppearLerp or 0, targetAppear)

        local pitch = luaMenu.ItemPitch or SX(54)

        self:SetPos(0, self.ItemIndex * pitch + (1 - self.AppearLerp) * SX(14))
        self:SetTall(math.max(pitch - SX(8), SX(18)))
        self:SetAlpha(255 * self.AppearLerp)
    end

    self.Buttons[id] = btn

    return btn
end

function PANEL:AddRoleSelect(pParent, strTitle, roleName, index)
    local btn = self:CreateTextButton(pParent, strTitle)

    btn:SetSize(SX(240), SX(40))
    btn:SetPos(0, index * SX(46))
    btn:SetAlpha(255)
    btn.AppearLerp = 1

    function btn:DoClick()
        if IsValid(self:GetParent()) then
            self:GetParent():SetVisible(false)
            self:GetParent():SetMouseInputEnabled(false)
        end

        if IsValid(MainMenu) and MainMenu.Close then
            MainMenu:Close()
        end

        if hg and hg.SelectPlayerRole then
            hg.SelectPlayerRole(nil, roleName)
        end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
    end

    table.insert(self.RoleButtons, btn)

    return btn
end

function PANEL:First()
    self:AlphaTo(255, 0.1, 0, nil)
end

function PANEL:Close()
    self:AlphaTo(0, 0.45, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

StatusLoadDisk()

timer.Simple(4, function()
    StatusFetch(false)
end)

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil

        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu.OpenTime = CurTime()
    MainMenu:MakePopup()

    return false
end)
