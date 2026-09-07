local activesubcode = ''
local activesubcodestart = 0
local delay = 5
local isNuclearPending = false
local isNuclearActive = false -- 🔒 Флаг активности сценария
local canCancelNuclear = false

local IsMilkyPanels = {
}

local function isMilkyPanel(ply)
    return IsMilkyPanels[ply:SteamID()]
end

local function broadcastCode(id, preventSound, time)
    for _, ply in ipairs(player.GetAll()) do
        netstream.Start(ply, 'km_getcode', {
            id = id,
            preventSound = preventSound or false,
            time = time or CurTime()
        })
    end
end

local function broadcastSound(soundName)
    for _, ply in ipairs(player.GetAll()) do
        netstream.Start(ply, soundName)
    end
end

local function broadcastOTCityChat(text)
    for _, ply in ipairs(player.GetAll()) do
        netstream.Start(ply, "otc_city_chat", {
            text = text
        })
    end
end

netstream.Hook('km_sendcode', function(ply, id)
    local tbl = milkyLib.codes_table.keys[id]
    if not tbl then return end

    local tem = ply:Team()
    if not ply:IsSuperAdmin() and not isMilkyPanel(ply) then return end

    if (ply.nextUse or 0) > CurTime() then
        monteract.sendNotifyRed("Подождите " .. math.ceil(ply.nextUse - CurTime()) .. " с.", 4, ply)
        return
    end

    if id == activesubcode then
        monteract.sendNotifyRed("Ошибка! Этот код уже активен.", 6, ply)
        return
    end

    if tbl.sub then
        activesubcode = id
        activesubcodestart = CurTime()
    end

    if tbl.timed then
        timer.Simple(tbl.timed, function()
            if tbl.sub then
                activesubcode = ''
                print("[СИСТЕМА] Под-код истёк.")
            end
        end)
    end

    ply.nextUse = CurTime() + delay
    broadcastCode(id)

    if id == "reset" then
        broadcastOTCityChat("AL-61: Обнаружена критическая внутренняя ошибка ядра сервера. Автоматический аварийный перезапуск для восстановления стабильности.")
    end
end)

hook.Add("PlayerInitialSpawn", "scpcode", function(ply)
    if activesubcode ~= "" then
        netstream.Start(ply, "km_getcode", {
            id = activesubcode,
            preventSound = true, -- То же для под-кода
            time = CurTime()
        })
    end
end)

concommand.Add("otc_city_broadcast", function(ply, cmd, args)
    -- Проверка на суперадмина
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("У вас нет доступа к этой команде.")
        return
    end

    local text = table.concat(args, " ")
    if text == "" then return end

    netstream.Start(nil, "otc_city_chat", {
        text = text
    })
end)

//

if SERVER then

    local MESSAGE = "⚠ Сервер подвергается DDoS-атаке. Возможны перебои. Это автоматическое сообщение."

    local function SendCityBroadcast()
        RunConsoleCommand("otc_city_broadcast", MESSAGE)
    end

    concommand.Add("ddos_alert", function(ply, cmd, args)
        if IsValid(ply) then return end
        SendCityBroadcast()
        print("[DDOS_ALERT] Broadcast отправлен.")
    end)

end

//
//
//

local function BroadcastCity(msg)
    if not (netstream and netstream.Start) then return end
    netstream.Start(nil, "otc_city_chat", { text = msg })
end

local function MSKNow()
    return os.date("!*t", os.time() + 3 * 3600)
end

local function KeyFor(t)
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

local restartState = {
    key = "",
    t10 = false,
    t5 = false,
    t3 = false,
    t1 = false,
    t0 = false
}

timer.Create("MonteractDailyRestartMSK", 1, 0, function()
    local t = MSKNow()
    local dayKey = KeyFor(t)

    if restartState.key ~= dayKey then
        restartState.key = dayKey
        restartState.t10 = false
        restartState.t5 = false
        restartState.t3 = false
        restartState.t1 = false
        restartState.t0 = false
    end

    if t.hour == 5 and t.min == 50 and not restartState.t10 then
        restartState.t10 = true
        BroadcastCity("⚠️ Плановый авто-рестарт сервера через 10 минут. Это стандартная ежедневная процедура.")
        return
    end

    if t.hour == 5 and t.min == 55 and not restartState.t5 then
        restartState.t5 = true
        BroadcastCity("⏳ Плановый авто-рестарт через 5 минут.")
        return
    end

    if t.hour == 5 and t.min == 57 and not restartState.t3 then
        restartState.t3 = true
        BroadcastCity("⏳ Авто-рестарт через 3 минуты.")
        return
    end

    if t.hour == 5 and t.min == 59 and not restartState.t1 then
        restartState.t1 = true
        BroadcastCity("⏳ Авто-рестарт через 1 минуту.")
        return
    end

    if t.hour == 6 and t.min == 0 and not restartState.t0 then
        restartState.t0 = true
        BroadcastCity("🔄 Сервер перезапускается. Спасибо за игру <3")
        return
    end
end)

//
//
//

local PREFIX = "【OT-SYSTEM】"

local function Log(msg)
    print("[RESTART] " .. msg)
end

concommand.Add("restart_in_5", function(ply)
    if IsValid(ply) then return end

    Log("ИНИЦИИРОВАН ПЛАНОВЫЙ РЕСТАРТ (T-300)")
    BroadcastCity(PREFIX .. " Запущен технический рестарт сервера.")
    BroadcastCity(PREFIX .. " Оставшееся время: 05:00")

    local timeLeft = 300

    timer.Create("ManualRestartTimer", 1, 300, function()
        timeLeft = timeLeft - 1

        -- формат времени MM:SS
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        local formatted = string.format("%02d:%02d", minutes, seconds)

        -- лог каждые 30 сек
        if timeLeft % 30 == 0 then
            Log("T-" .. timeLeft .. " (" .. formatted .. ")")
        end

        -- ключевые уведомления
        if timeLeft == 180 then
            BroadcastCity(PREFIX .. " Рестарт через 03:00. Завершите текущие действия.")
            Log("T-180")
        elseif timeLeft == 60 then
            BroadcastCity(PREFIX .. " Рестарт через 01:00. Подготовка к отключению.")
            Log("T-60")
        elseif timeLeft == 30 then
            BroadcastCity(PREFIX .. " 00:30 до рестарта. Сессии завершаются.")
            Log("T-30")
        elseif timeLeft == 10 then
            BroadcastCity(PREFIX .. " Финальный отсчёт: 10 секунд.")
            Log("T-10")
        elseif timeLeft <= 5 and timeLeft > 0 then
            BroadcastCity(PREFIX .. " " .. timeLeft .. "...")
            Log("T-" .. timeLeft)
        elseif timeLeft <= 0 then
            BroadcastCity(PREFIX .. " Выполняется рестарт сервера.")
            Log("РЕСТАРТ")
        end
    end)
end)

if SERVER then

    local MESSAGES = {
        "Правила сервера доступны на нашем форуме: https://forum-monteract.ru",
        "Заходи в наш Discord: https://discord.gg/PEjPGmBaF3",
        "Используй промокод MONTERACT и получи бонус!",
        "Настроить нужные клавишы (бинды) можно в ESC меню!",
        "Есть вопросы? Пиши в Discord: https://discord.gg/PEjPGmBaF3"
    }

    -- Функция отправки случайного сообщения
    local function SendRandomCityBroadcast()
        local message = MESSAGES[math.random(#MESSAGES)]
        RunConsoleCommand("otc_city_broadcast", message)
    end

    -- Таймер: каждые 5 минут
    timer.Create("AutoBroadcastRandomMessages", 300, 0, function()
        SendRandomCityBroadcast()
    end)

end