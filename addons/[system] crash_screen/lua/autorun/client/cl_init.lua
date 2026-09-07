local M_ANTICRASH

local HEARTBEAT_TIMEOUT = 15
local RECONNECT_TIMEOUT = 20
local PROBE_INTERVAL = 3
local RECONNECT_DELAY = 5
local MAX_RESTART_CONFIRMATIONS = 2

local last_heartbeat = RealTime()
local last_probe = 0
local probe_in_progress = false
local restart_confirmations = 0
local to_reconnect = false
local reconnect_time = 0
local alpha = 0

local function reset_state(remove_panel)
    last_heartbeat = RealTime()
    last_probe = 0
    probe_in_progress = false
    restart_confirmations = 0
    to_reconnect = false
    reconnect_time = 0
    alpha = 0

    if remove_panel and IsValid(M_ANTICRASH) then
        M_ANTICRASH:Remove()
        M_ANTICRASH = nil
    end
end

local function DrawMovingTape(y, w, h, speed, color1, color2)
    local stripe_width = 80
    local offset = (RealTime() * speed) % stripe_width

    surface.SetDrawColor(color2.r * 0.1, color2.g * 0.1, color2.b * 0.1, 220)
    surface.DrawRect(0, y, w, h)

    for x = -stripe_width, w + stripe_width, stripe_width do
        local x1 = x + offset
        local x2 = x1 + stripe_width / 2

        surface.SetDrawColor(color1)
        surface.DrawPoly({
            { x = x1,     y = y },
            { x = x2,     y = y },
            { x = x2 - h, y = y + h },
            { x = x1 - h, y = y + h }
        })
    end
end

local function close_anticrash_screen()
    if IsValid(M_ANTICRASH) then
        M_ANTICRASH:Remove()
        M_ANTICRASH = nil
    end

    alpha = 0
end

local function open_anticrash_screen()
    if IsValid(M_ANTICRASH) then return end

    local pnl = vgui.Create("DPanel")
    if not IsValid(pnl) then return end

    M_ANTICRASH = pnl
    pnl:SetSize(ScrW(), ScrH())
    pnl:SetPos(0, 0)
    pnl:SetZPos(32767)
    pnl:SetAlpha(255)
    pnl:SetMouseInputEnabled(false)
    pnl:SetKeyboardInputEnabled(false)

    function pnl:Think()
        if self:GetWide() ~= ScrW() or self:GetTall() ~= ScrH() then
            self:SetSize(ScrW(), ScrH())
            self:SetPos(0, 0)
        end
        self:MoveToFront()
    end

    function pnl:Paint(w, h)
        alpha = math.min(alpha + FrameTime() * 700, 255)

        local text_color = Color(255, 255, 255, alpha)
        local main_color = Color(99, 0, 7)
        local dark_color = Color(41, 0, 4)
        local lost_for = RealTime() - last_heartbeat

        surface.SetDrawColor(0, 0, 0, 210)
        surface.DrawRect(0, 0, w, h)

        DrawMovingTape(0, w, 60, 100, main_color, dark_color)
        DrawMovingTape(h - 60, w, 60, 100, main_color, dark_color)

        if to_reconnect then
            draw.DrawText("Сервер недоступен", "DermaLarge", 15, 15, text_color, TEXT_ALIGN_LEFT)
            draw.DrawText("Переподключение...", "DermaLarge", 15, h - 60, text_color, TEXT_ALIGN_LEFT)
            draw.DrawText("Через " .. math.max(0, math.ceil(reconnect_time - RealTime())) .. " сек.", "DermaLarge", 300, h - 30, text_color, TEXT_ALIGN_LEFT)
        else
            draw.DrawText("Потеряно соединение с сервером", "DermaLarge", 15, 15, text_color, TEXT_ALIGN_LEFT)
            draw.DrawText("Ожидаем ответ...", "DermaLarge", 15, h - 60, text_color, TEXT_ALIGN_LEFT)
            draw.DrawText(math.floor(lost_for) .. " сек. без heartbeat", "DermaLarge", 300, h - 30, text_color, TEXT_ALIGN_LEFT)
        end
    end
end

local function handle_server_alive()
    restart_confirmations = 0
    to_reconnect = false
    last_probe = RealTime()
end

hook.Add("Think", "server_upwatch", function()
    local now = RealTime()
    local lost_for = now - last_heartbeat

    if lost_for >= HEARTBEAT_TIMEOUT then
        open_anticrash_screen()
    else
        close_anticrash_screen()
        restart_confirmations = 0
        to_reconnect = false
    end

    if to_reconnect and now >= reconnect_time then
        to_reconnect = false

        if IsValid(LocalPlayer()) then
            LocalPlayer():ConCommand("retry")
        else
            RunConsoleCommand("retry")
        end

        return
    end

    if lost_for < HEARTBEAT_TIMEOUT then return end
    if probe_in_progress then return end
    if now - last_probe < PROBE_INTERVAL then return end

    local ip = game.GetIPAddress()
    if not ip or ip == "" or ip == "loopback" then return end

    probe_in_progress = true
    last_probe = now

    http.Fetch(
        "http://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=" .. string.Trim(ip),
        function(body)
            probe_in_progress = false

            local data = util.JSONToTable(body)
            local servers = data and data.response and data.response.servers

            if istable(servers) and #servers > 0 then
                handle_server_alive()
                return
            end

            restart_confirmations = restart_confirmations + 1

            if lost_for >= RECONNECT_TIMEOUT and restart_confirmations >= MAX_RESTART_CONFIRMATIONS then
                to_reconnect = true
                reconnect_time = RealTime() + RECONNECT_DELAY
                open_anticrash_screen()
            end
        end,
        function()
            probe_in_progress = false
            restart_confirmations = restart_confirmations + 1

            if lost_for >= RECONNECT_TIMEOUT and restart_confirmations >= MAX_RESTART_CONFIRMATIONS then
                to_reconnect = true
                reconnect_time = RealTime() + RECONNECT_DELAY
                open_anticrash_screen()
            end
        end
    )
end)

net.Receive("server_upwatch", function()
    reset_state(true)
end)

reset_state(true)