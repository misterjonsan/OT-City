if SERVER then return end

local PATCH_NAME = "ZCity_Keybind_Menu_V2"
local SAVE_FILE = "zcity_keybinds_v3.txt"
local MENU_MUSIC_URL = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/Danny_Elfman_-_Main_Titles_OST_Charlie_and_the_Chocolate_Factory_(SkySound.cc).mp3"

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_dim = Color(140, 180, 215)
local clr_verygray = Color(3, 5, 9, 235)
local clr_danger = Color(255, 90, 90)
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local function SmoothNoise(t, f1, f2, f3, phase)
    local a = math.sin((t + phase) * f1 * math.pi * 2)
    local b = math.sin((t + phase * 1.7) * f2 * math.pi * 2 + 2.399)
    local c = math.sin((t + phase * 2.3) * f3 * math.pi * 2 + 5.131)

    return math.Clamp(a * 0.55 + b * 0.30 + c * 0.15, -1, 1)
end

ZCB_MusicVol = ZCB_MusicVol or 0
ZCB_MusicState = ZCB_MusicState or "stopped"

local TEXT = {
    title = "Привязки клавиш",
    subtitle = "Настройка управления",
    intro_title = "Управление действиями",
    button_reset = "Сбросить",
    button_clear = "Очистить",
    button_help = "Подсказки",
    button_close = "Закрыть",
    status_installed = "Системная привязка",
    status_custom = "Локальная привязка",
    status_empty = "Не назначено",
    status_hold = "Удержание",
    status_combo = "SHIFT + клавиша",
    bind_ability = "Способность профессии",
    bind_ability_desc = "Зажмите SHIFT и нажмите выбранную клавишу. Строитель заколачивает дверь, врач осматривает организм человека, повар кормит союзников рядом. По умолчанию SHIFT + E.",
    status_press = "Одно нажатие",
    capture = "Нажмите клавишу",
    capture_empty = "НЕ НАЗНАЧЕНО",
    help_title = "Подсказки по управлению",
    help_intro = "Здесь собраны быстрые пояснения по привязкам и полезные сочетания для игры.",
    help_text = "Своя привязка — это клавиша, которую вы назначаете в этом меню. Системная привязка — это клавиша, уже установленная через настройки Garry's Mod или команду bind.\n\nПолезные сочетания:\nAlt + E — свернуть шею со спины\nAlt + R — замаскироваться под одежду трупа\nE + ЛКМ — ударить прикладом\nПКМ + E — обыскать предметы\nВ рэгдолле + E — управлять головой\nВ рэгдолле + Shift — захват левой рукой\nВ рэгдолле + Alt — захват правой рукой",
    notify_synced = "Текущие системные привязки подтянуты.",
    notify_reset = "Привязки сброшены к значениям по умолчанию.",
    notify_reloaded = "Привязки перезагружены из файла.",
    notify_local_saved = "Локальная привязка обновлена.",
    notify_local_cleared = "Локальная привязка очищена.",
    notify_same_system = "Эта клавиша уже используется как системная для этого действия.",
    notify_conflict = "Эта клавиша уже занята системной привязкой другого действия.",
    section_gameplay = "Основные действия",
    section_tips = "Справка",
    bind_kick = "Пинок",
    bind_kick_desc = "Быстрый удар ногой.",
    bind_fake = "Рэгдолл",
    bind_fake_desc = "Перевод персонажа в состояние рэгдолла.",
    bind_laser = "Лазерное крепление",
    bind_laser_desc = "Включение и выключение лазерного модуля оружия. Работает и на тазерах.",
    bind_leanleft = "Наклон влево",
    bind_leanleft_desc = "Удерживайте для аккуратного пика влево.",
    bind_leanright = "Наклон вправо",
    bind_leanright_desc = "Удерживайте для аккуратного пика вправо.",
    bind_breath = "Задержка дыхания",
    bind_breath_desc = "Удерживайте для более точной стрельбы, а также против угарного газа и цианида.",
    bind_look = "Осмотреться",
    bind_look_desc = "Удерживайте, чтобы осмотреться без поворота тела.",
    bind_zoom = "Приближение",
    bind_zoom_desc = "Удерживайте для приближения камеры в стиле DayZ.",
    bind_posture_cycle = "Стойка: следующая",
    bind_posture_cycle_desc = "Пролистывает все стойки по очереди. Список доступных стоек выводится в консоль.",
    bind_posture_2 = "Стойка №2",
    bind_posture_2_desc = "Мгновенно включает конкретную стойку (hg_change_posture 2).",
    bind_drop = "Выбросить оружие",
    bind_drop_desc = "Выбрасывает оружие, которое сейчас в руках.",
    bind_suicide = "Суицид",
    bind_suicide_desc = "Персонаж убивает себя. Действие необратимо.",
    console_dump_header = "========== OT-CITY: привязки клавиш =========="
}

local DEFAULT_BINDS = {
    hg_prof_ability = KEY_E,
    hg_kick = KEY_G,
    fake = KEY_F,
    hmcd_togglelaser = KEY_NONE,
    ["+alt1"] = KEY_NONE,
    ["+alt2"] = KEY_NONE,
    ["+hmcd_holdbreath"] = KEY_NONE,
    ["+altlook"] = KEY_NONE,
    ["+hg_zoom"] = KEY_LALT,
    hg_change_posture = KEY_NONE,
    ["hg_change_posture 2"] = KEY_NONE,
    ["say *drop"] = KEY_NONE,
    suicide = KEY_NONE
}

local CONFIG_PATHS = {
    { path = "cfg/config.cfg", realm = "GAME" },
    { path = "cfg/autoexec.cfg", realm = "GAME" },
    { path = "cfg/config.cfg", realm = "MOD" },
    { path = "cfg/autoexec.cfg", realm = "MOD" }
}

local BINDS = {
    {
        command = "hg_prof_ability",
        hold = false,
        shift = true,
        virtual = true,
        title = TEXT.bind_ability,
        description = TEXT.bind_ability_desc
    },
    {
        command = "hg_kick",
        hold = false,
        title = TEXT.bind_kick,
        description = TEXT.bind_kick_desc
    },
    {
        command = "fake",
        hold = false,
        title = TEXT.bind_fake,
        description = TEXT.bind_fake_desc
    },
    {
        command = "hmcd_togglelaser",
        hold = false,
        title = TEXT.bind_laser,
        description = TEXT.bind_laser_desc
    },
    {
        command = "+alt1",
        hold = true,
        title = TEXT.bind_leanleft,
        description = TEXT.bind_leanleft_desc
    },
    {
        command = "+alt2",
        hold = true,
        title = TEXT.bind_leanright,
        description = TEXT.bind_leanright_desc
    },
    {
        command = "+hmcd_holdbreath",
        hold = true,
        title = TEXT.bind_breath,
        description = TEXT.bind_breath_desc
    },
    {
        command = "+altlook",
        hold = true,
        title = TEXT.bind_look,
        description = TEXT.bind_look_desc
    },
    {
        command = "+hg_zoom",
        hold = true,
        title = TEXT.bind_zoom,
        description = TEXT.bind_zoom_desc
    },
    {
        command = "hg_change_posture",
        hold = false,
        title = TEXT.bind_posture_cycle,
        description = TEXT.bind_posture_cycle_desc
    },
    {
        command = "hg_change_posture 2",
        hold = false,
        title = TEXT.bind_posture_2,
        description = TEXT.bind_posture_2_desc
    },
    {
        command = "say *drop",
        hold = false,
        title = TEXT.bind_drop,
        description = TEXT.bind_drop_desc
    },
    {
        command = "suicide",
        hold = false,
        title = TEXT.bind_suicide,
        description = TEXT.bind_suicide_desc
    }
}

local function DrawRound(rad, x, y, w, h, col)
    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
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

    surface.CreateFont("ZC_MM_Close", {
        font = "Montserrat SemiBold",
        size = math.floor(34 * s + 0.5),
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_KB_Section", {
        font = "Montserrat SemiBold",
        size = math.floor(30 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_KB_RowTitle", {
        font = "Montserrat SemiBold",
        size = math.floor(24 * s + 0.5),
        weight = 700,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_KB_RowText", {
        font = "Montserrat Medium",
        size = math.floor(18 * s + 0.5),
        weight = 500,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_KB_Button", {
        font = "Montserrat Medium",
        size = math.floor(18 * s + 0.5),
        weight = 600,
        antialias = true,
        extended = true
    })

    surface.CreateFont("ZC_KB_HelpText", {
        font = "Montserrat Medium",
        size = math.floor(21 * s + 0.5),
        weight = 500,
        antialias = true,
        extended = true
    })
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_MM_FontsBinds", CreateFonts)

hook.Add("Think", "ZCB_KeybindMusicFade", function()
    local menuOpen = (MainMenu and IsValid(MainMenu)) or (hg_options and IsValid(hg_options)) or (hg_keybinds_menu and IsValid(hg_keybinds_menu)) or (ZCityKeybindHelpFrame and IsValid(ZCityKeybindHelpFrame))

    if not menuOpen then
        ZCB_MusicState = "out"
    end

    if not IsValid(ZCB_MusicChannel) then
        return
    end

    local ft = FrameTime()

    if ZCB_MusicState == "in" then
        ZCB_MusicVol = Lerp(ft * 1.1, ZCB_MusicVol, 1)
    elseif ZCB_MusicState == "out" then
        ZCB_MusicVol = Lerp(ft * 3.0, ZCB_MusicVol, 0)

        if ZCB_MusicVol <= 0.01 then
            ZCB_MusicChannel:Stop()
            ZCB_MusicChannel = nil
            ZCB_MusicVol = 0
            ZCB_MusicState = "stopped"
            ZCB_PlayingURL = nil
            return
        end
    end

    ZCB_MusicChannel:SetVolume(math.Clamp(ZCB_MusicVol, 0, 1))
end)

local function StartMenuMusic()
    ZCB_DesiredURL = MENU_MUSIC_URL
    ZCB_MusicState = "in"

    if IsValid(ZCB_MusicChannel) and ZCB_PlayingURL == MENU_MUSIC_URL then
        return
    end

    if IsValid(ZCB_MusicChannel) then
        ZCB_MusicChannel:Stop()
        ZCB_MusicChannel = nil
    end

    ZCB_MusicVol = 0
    ZCB_PlayingURL = MENU_MUSIC_URL

    local url = MENU_MUSIC_URL

    sound.PlayURL(url, "noplay noblock", function(channel)
        if not IsValid(channel) then
            return
        end

        if ZCB_DesiredURL ~= url then
            channel:Stop()
            return
        end

        ZCB_MusicChannel = channel
        channel:SetVolume(0)
        channel:EnableLooping(true)
        channel:Play()
    end)
end

local function NormalizeKeyCode(key)
    key = tonumber(key) or KEY_NONE

    if key < 0 then
        return KEY_NONE
    end

    return key
end

local ApplyDefaults

local function SplitCommand(command)
    local parts = {}

    for chunk in string.gmatch(tostring(command or ""), "%S+") do
        parts[#parts + 1] = chunk
    end

    return parts
end

local function RunBindCommand(command)
    local parts = SplitCommand(command)

    if #parts == 0 then return end

    RunConsoleCommand(parts[1], unpack(parts, 2))
end

local function GetBindingName(command)
    if string.find(tostring(command or ""), "%s") then
        return nil
    end

    local binding = input.LookupBinding(command, true) or input.LookupBinding(command)

    if not binding or binding == "" then
        return nil
    end

    return string.upper(binding)
end

local function GetKeyCodeFromBinding(command)
    local binding = GetBindingName(command)

    if not binding then
        return nil, nil
    end

    local keyCode = input.GetKeyCode(binding)

    if not keyCode or keyCode < 0 or keyCode == KEY_NONE then
        return nil, binding
    end

    return keyCode, binding
end

local function RefreshSystemBindings()
    for _, bind in ipairs(BINDS) do
        if bind.virtual then
            bind.bindings = {}
            bind.systemBinding = nil
            bind.engineKey = KEY_NONE
            continue
        end

        local keyCode, bindingName = GetKeyCodeFromBinding(bind.command)
        bind.bindings = bindingName and { bindingName } or {}
        bind.systemBinding = bindingName
        bind.engineKey = NormalizeKeyCode(keyCode or KEY_NONE)
    end
end

local function SyncBindsFromEngine()
    local cache = {}

    for _, source in ipairs(CONFIG_PATHS) do
        local content = file.Read(source.path, source.realm)

        if content and content ~= "" then
            cache[source.path .. "|" .. source.realm] = content
        end
    end

    for _, bind in ipairs(BINDS) do
        if bind.virtual then
            bind.bindings = {}
            bind.systemBinding = nil
            bind.engineKey = KEY_NONE
            continue
        end

        local found = {}
        local seen = {}

        for _, content in pairs(cache) do
            for line in string.gmatch(content, "[^\r\n]+") do
                local keyName, cmd = string.match(line, '^bind%s+"([^"]+)"%s+"([^"]+)"')

                if not keyName then
                    keyName, cmd = string.match(line, "^bind%s+([^%s]+)%s+\"([^\"]+)\"")
                end

                if cmd == bind.command then
                    local normalized = string.upper(keyName)

                    if normalized ~= "" and not seen[normalized] then
                        seen[normalized] = true
                        table.insert(found, normalized)
                    end
                end
            end
        end

        local engineName = GetBindingName(bind.command)
        if engineName and not seen[engineName] then
            table.insert(found, engineName)
        end

        table.sort(found, function(a, b)
            return a < b
        end)

        bind.bindings = found
        bind.systemBinding = #found > 0 and table.concat(found, ", ") or nil

        local primary = found[1]
        local keyCode = primary and input.GetKeyCode(primary) or KEY_NONE
        bind.engineKey = NormalizeKeyCode(keyCode or KEY_NONE)
    end
end

local function PushAbilityKey()
    for _, bind in ipairs(BINDS) do
        if bind.command == "hg_prof_ability" then
            local key = NormalizeKeyCode(bind.customKey or KEY_NONE)

            if key == KEY_NONE then
                key = NormalizeKeyCode(DEFAULT_BINDS[bind.command] or KEY_E)
            end

            RunConsoleCommand("hg_prof_ability_key", tostring(key))
            return
        end
    end
end

local function SaveCustomBinds()
    local data = {}

    for _, bind in ipairs(BINDS) do
        if bind.customKey and bind.customKey ~= KEY_NONE then
            data[bind.command] = NormalizeKeyCode(bind.customKey)
        end
    end

    file.Write(SAVE_FILE, util.TableToJSON(data, true))
    PushAbilityKey()
end

local function LoadCustomBinds()
    for _, bind in ipairs(BINDS) do
        if bind.virtual then
            bind.customKey = NormalizeKeyCode(DEFAULT_BINDS[bind.command] or KEY_NONE)
        else
            bind.customKey = KEY_NONE
        end
    end

    if not file.Exists(SAVE_FILE, "DATA") then
        return
    end

    local raw = file.Read(SAVE_FILE, "DATA")
    if not raw or raw == "" then
        return
    end

    local decoded = util.JSONToTable(raw)
    if not istable(decoded) then
        return
    end

    for _, bind in ipairs(BINDS) do
        if decoded[bind.command] ~= nil then
            bind.customKey = NormalizeKeyCode(decoded[bind.command])
        end
    end
end

local function SanitizeCustomBinds(preferredCommand)
    SyncBindsFromEngine()

    local systemOwners = {}
    for _, bind in ipairs(BINDS) do
        for _, keyName in ipairs(bind.bindings or {}) do
            local upper = string.upper(keyName)

            if not systemOwners[upper] then
                systemOwners[upper] = bind.command
            end
        end
    end

    local customOwners = {}
    local changed = false

    local function processBind(bind)
        local customKey = NormalizeKeyCode(bind.customKey or KEY_NONE)

        if customKey == KEY_NONE then
            bind.customKey = KEY_NONE
            return
        end

        local keyName = input.GetKeyName(customKey)
        if not keyName or keyName == "" then
            bind.customKey = KEY_NONE
            changed = true
            return
        end

        local keyUpper = string.upper(keyName)
        local systemOwner = systemOwners[keyUpper]

        if systemOwner and systemOwner ~= bind.command then
            bind.customKey = KEY_NONE
            changed = true
            return
        end

        local customOwner = customOwners[keyUpper]
        if customOwner and customOwner ~= bind.command then
            bind.customKey = KEY_NONE
            changed = true
            return
        end

        customOwners[keyUpper] = bind.command
    end

    if preferredCommand then
        for _, bind in ipairs(BINDS) do
            if bind.command == preferredCommand then
                processBind(bind)
                break
            end
        end
    end

    for _, bind in ipairs(BINDS) do
        if bind.command ~= preferredCommand then
            processBind(bind)
        end
    end

    if changed then
        SaveCustomBinds()
    end

    return changed
end

local function GetActiveKey(bind)
    local custom = NormalizeKeyCode(bind.customKey or KEY_NONE)
    if custom ~= KEY_NONE then
        return custom
    end

    return NormalizeKeyCode(bind.engineKey or KEY_NONE)
end

local function IsKeyInBindings(bind, keyNameUpper)
    for _, existing in ipairs(bind.bindings or {}) do
        if string.upper(existing) == keyNameUpper then
            return true
        end
    end

    return false
end

local function SetSmartBind(bind, keyCode)
    keyCode = NormalizeKeyCode(keyCode)
    SyncBindsFromEngine()

    if keyCode == KEY_NONE then
        bind.customKey = KEY_NONE
        SaveCustomBinds()
        Notify(TEXT.notify_local_cleared, Color(255, 200, 0))
        return true
    end

    local keyName = input.GetKeyName(keyCode)
    if not keyName or keyName == "" then
        return false
    end

    local keyUpper = string.upper(keyName)

    if IsKeyInBindings(bind, keyUpper) then
        bind.customKey = KEY_NONE
        SaveCustomBinds()
        Notify(TEXT.notify_same_system, Color(0, 255, 0))
        return true
    end

    for _, otherBind in ipairs(BINDS) do
        if otherBind ~= bind and IsKeyInBindings(otherBind, keyUpper) then
            Notify(TEXT.notify_conflict .. " [" .. otherBind.title .. "]", Color(255, 120, 120))
            return false
        end
    end

    for _, otherBind in ipairs(BINDS) do
        if otherBind ~= bind and NormalizeKeyCode(otherBind.customKey or KEY_NONE) == keyCode then
            otherBind.customKey = KEY_NONE
        end
    end

    bind.customKey = keyCode
    SanitizeCustomBinds(bind.command)
    SaveCustomBinds()
    Notify(TEXT.notify_local_saved, Color(0, 255, 0))
    return true
end

ApplyDefaults = function()
    for _, bind in ipairs(BINDS) do
        if bind.virtual then
            bind.customKey = NormalizeKeyCode(DEFAULT_BINDS[bind.command] or KEY_NONE)
        else
            bind.customKey = KEY_NONE
        end
    end

    SaveCustomBinds()
end

local function GetKeyDisplayName(key)
    key = NormalizeKeyCode(key)

    if key == KEY_NONE then
        return TEXT.capture_empty
    end

    local keyName = input.GetKeyName(key)

    if not keyName or keyName == "" then
        return TEXT.capture_empty
    end

    return string.upper(keyName)
end

local function Notify(text, color)
    chat.AddText(color or Color(0, 255, 0), text)
end

local function HideFancyTooltip()
    if IsValid(ZCityFancyTooltip) then
        ZCityFancyTooltip:Remove()
        ZCityFancyTooltip = nil
    end
end

local function ShowFancyTooltip(data)
    if not data then return end

    HideFancyTooltip()

    local panel = vgui.Create("DPanel")
    panel:SetDrawOnTop(true)
    panel:SetMouseInputEnabled(false)
    panel.Data = data

    local width = math.min(SX(340), math.floor(ScrW() * 0.22))
    local padX = SX(16)
    local contentW = width - padX * 2

    surface.SetFont("ZC_KB_HelpText")

    local bodyLines = {}
    local current = ""

    for word in string.gmatch(data.description or "", "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        local candidateW = surface.GetTextSize(candidate)

        if candidateW > contentW and current ~= "" then
            table.insert(bodyLines, current)
            current = word
        else
            current = candidate
        end
    end

    if current ~= "" then
        table.insert(bodyLines, current)
    end

    local lineHeight = SX(21)
    local height = SX(16) + SX(24) + SX(10) + (#bodyLines * lineHeight) + SX(14)

    panel:SetSize(width, height)

    panel.Think = function(self)
        local mx, my = gui.MousePos()

        if mx <= 0 and my <= 0 then
            return
        end

        self:SetPos(
            math.min(mx + SX(18), ScrW() - self:GetWide() - SX(12)),
            math.min(my + SX(18), ScrH() - self:GetTall() - SX(12))
        )
    end

    panel.Paint = function(self, w, h)
        local rad = math.max(4, SX(10))

        DrawRound(rad, 0, 0, w, h, Color(4, 8, 15, 242))
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 165), 1)

        surface.SetFont("ZC_KB_RowTitle")
        local titleW = surface.GetTextSize(self.Data.title)

        draw.SimpleText(self.Data.title, "ZC_KB_RowTitle", padX, SX(14), Color(255, 255, 255, 245), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        DrawRound(1, padX, SX(14) + SX(28), math.min(titleW, contentW), math.max(1, SX(2)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190))

        local y = SX(14) + SX(38)

        for _, line in ipairs(bodyLines) do
            draw.DrawText(line, "ZC_KB_HelpText", padX, y, Color(215, 232, 245, 228), TEXT_ALIGN_LEFT)
            y = y + lineHeight
        end
    end

    ZCityFancyTooltip = panel
end

local function AttachFancyTooltip(panel, dataBuilder)
    panel.OnCursorEntered = function(self)
        ShowFancyTooltip(dataBuilder(self))
    end

    panel.OnCursorExited = function()
        HideFancyTooltip()
    end

    panel.OnRemove = function()
        HideFancyTooltip()
    end
end

SyncBindsFromEngine()
LoadCustomBinds()
SanitizeCustomBinds()
timer.Simple(2, PushAbilityKey)

hook.Add("PlayerButtonDown", PATCH_NAME .. "_Down", function(ply, button)
    if ply ~= LocalPlayer() then return end
    if gui.IsGameUIVisible() then return end

    local focus = vgui.GetKeyboardFocus()
    if IsValid(focus) then return end

    for _, bind in ipairs(BINDS) do
        local activeKey = GetActiveKey(bind)

        if activeKey == KEY_NONE or activeKey ~= button then
            continue
        end

        if bind.shift and not (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) then
            continue
        end

        if NormalizeKeyCode(bind.customKey or KEY_NONE) == KEY_NONE then
            return
        end

        RunBindCommand(bind.command)

        return
    end
end)

hook.Add("PlayerButtonUp", PATCH_NAME .. "_Up", function(ply, button)
    if ply ~= LocalPlayer() then return end

    for _, bind in ipairs(BINDS) do
        local activeKey = GetActiveKey(bind)

        if NormalizeKeyCode(bind.customKey or KEY_NONE) == KEY_NONE then
            continue
        end

        if not bind.hold or activeKey == KEY_NONE or activeKey ~= button then
            continue
        end

        if string.StartWith(bind.command, "+") then
            RunBindCommand("-" .. string.sub(bind.command, 2))
        end
    end
end)

local function CreateActionButton(parent, text, dockMarginRight, onClick)
    local button = vgui.Create("DButton", parent)

    button:Dock(RIGHT)
    button:DockMargin(0, 0, dockMarginRight or 0, 0)
    button:SetWide(SX(230))
    button:SetText("")
    button:SetCursor("hand")
    button.Label = text
    button.HoverLerp = 0
    button.DoClick = onClick

    button.Paint = function(self, w, h)
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, Color(8, 18, 30, 90 + self.HoverLerp * 60))

        if self.HoverLerp > 0.01 then
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self.HoverLerp * 40), math.max(2, SX(4)))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self.HoverLerp * 170), math.max(1, SX(1)))
        end

        local textCol = Color(
            Lerp(self.HoverLerp, 200, 255),
            Lerp(self.HoverLerp, 225, 255),
            Lerp(self.HoverLerp, 245, 255),
            245
        )

        draw.SimpleText(self.Label, "ZC_KB_Button", w * 0.5, h * 0.5, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return button
end

local function OpenHelpWindow()
    if IsValid(ZCityKeybindHelpFrame) then
        ZCityKeybindHelpFrame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(math.min(ScrW() * 0.44, SX(820)), math.min(ScrH() * 0.56, SX(560)))
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDraggable(false)
    frame.Paint = function(self, w, h)
        local rad = math.max(5, SX(12))

        DrawRound(rad, 0, 0, w, h, Color(5, 9, 16, 238))
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 170), 1)
        draw.SimpleText(TEXT.help_title, "ZC_KB_Section", SX(36), SX(28), Color(255, 255, 255, 245), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(TEXT.help_intro, "ZC_KB_RowText", SX(36), SX(72), Color(215, 230, 245, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 160)
        surface.DrawRect(SX(36), SX(118), w - SX(72), math.max(1, SX(1)))
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(SX(52), SX(52))
    close:SetPos(frame:GetWide() - SX(52) - SX(24), SX(24))
    close:SetText("")
    close:SetCursor("hand")
    close.DoClick = function()
        if IsValid(frame) then
            frame:Remove()
        end
    end
    close.Paint = function(self, w, h)
        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, Color(8, 18, 30, 120))
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self:IsHovered() and 175 or 70), 1)
        draw.SimpleText("×", "ZC_MM_Close", w * 0.5, h * 0.48, Color(255, 255, 255, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(SX(36), SX(146))
    scroll:SetSize(frame:GetWide() - SX(72), frame:GetTall() - SX(182))
    scroll.Paint = nil

    local vbar = scroll:GetVBar()
    vbar:SetWide(SX(9))
    function vbar:Paint(w, h)
        surface.SetDrawColor(168, 212, 245, 16)
        surface.DrawRect(w * 0.5 - 1, 0, 1, h)
    end
    function vbar.btnGrip:Paint(w, h)
        DrawRound(math.max(2, SX(4)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 215))
    end
    function vbar.btnUp:Paint() end
    function vbar.btnDown:Paint() end

    local body = vgui.Create("DPanel", scroll)
    body:Dock(TOP)
    body:SetTall(SX(517))
    body:DockMargin(0, 0, SX(18), 0)
    body.Paint = function(_, w, h)
        local rad = math.max(4, SX(10))

        DrawRound(rad, 0, 0, w, h, Color(2, 6, 12, 105))
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 14), 1)
        DrawRound(1, SX(30), SX(30), math.max(2, SX(2)), h - SX(60), Color(clr_accent.r, clr_accent.g, clr_accent.b, 150))
    end

    local helpLabel = vgui.Create("DLabel", body)
    helpLabel:Dock(FILL)
    helpLabel:DockMargin(SX(54), SX(36), SX(54), SX(36))
    helpLabel:SetFont("ZC_KB_HelpText")
    helpLabel:SetText(TEXT.help_text)
    helpLabel:SetWrap(true)
    helpLabel:SetAutoStretchVertical(true)
    helpLabel:SetTextColor(Color(225, 238, 248, 235))

    ZCityKeybindHelpFrame = frame
end

local PANEL = {}

function PANEL:StartMusic()
    StartMenuMusic()
end

function PANEL:GetLayoutData(w, h)
    local s = Sc()

    local headerX = math.floor(216 * s)
    local headerY = math.floor(36 * s)
    local lineX = headerX - math.floor(21 * s)
    local lineY = headerY + math.floor(200 * s)
    local contentX = lineX + math.floor(81 * s)
    local contentY = lineY + math.floor(26 * s)
    local contentW = math.min(SX(1395), w - contentX - SX(165))
    local contentH = h - contentY - SX(40)

    return headerX, headerY, lineX, lineY, contentX, contentY, contentW, contentH
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:SetY(ScrH())
    self:SetX(0)
    self:SetTitle("")
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetBlurStrengh(0)
    self:SetDraggable(false)
    self:ShowCloseButton(false)

    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()
    self.Rows = {}

    self:StartMusic()

    self.Scroll = vgui.Create("DScrollPanel", self)
    self.Scroll.Paint = nil

    local vbar = self.Scroll:GetVBar()
    vbar:SetWide(SX(9))

    function vbar:Paint(w, h)
        surface.SetDrawColor(168, 212, 245, 16)
        surface.DrawRect(w * 0.5 - 1, 0, 1, h)
    end

    function vbar.btnGrip:Paint(w, h)
        DrawRound(math.max(2, SX(4)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 215))
    end

    function vbar.btnUp:Paint()
    end

    function vbar.btnDown:Paint()
    end

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("")
    self.CloseButton:SetCursor("hand")
    self.CloseButton.HoverLerp = 0
    self.CloseButton.DoClick = function()
        if IsValid(self) then
            self:Close()
        end
    end
    self.CloseButton.Paint = function(btn, w, h)
        btn.HoverLerp = LerpFT(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverLerp, 8, 16),
            Lerp(btn.HoverLerp, 18, 60),
            Lerp(btn.HoverLerp, 30, 96),
            Lerp(btn.HoverLerp, 155, 225)
        )

        local outline = Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + btn.HoverLerp * 150)
        local txt = Color(
            Lerp(btn.HoverLerp, 235, clr_accent.r),
            Lerp(btn.HoverLerp, 235, clr_accent.g),
            Lerp(btn.HoverLerp, 235, clr_accent.b),
            245
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, outline, 1)
        draw.SimpleText("×", "ZC_MM_Close", w * 0.5, h * 0.48, txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self:BuildContent()

    timer.Simple(0, function()
        if IsValid(self) then
            self:First()
        end
    end)
end

function PANEL:First()
    self:MoveTo(self:GetX(), 0, 0.32, 0, 0.2, function() end)
    self:AlphaTo(255, 0.18, 0.08, nil)
end

function PANEL:PerformLayout(w, h)
    local _, _, _, _, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)

    if IsValid(self.Scroll) then
        self.Scroll:SetPos(contentX, contentY)
        self.Scroll:SetSize(contentW, contentH)
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
        surface.SetDrawColor(clr_verygray)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(clr_verygray)
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
    local safeX = math.max((drawW - w) * 0.5, 0)
    local safeY = math.max((drawH - h) * 0.5, 0)
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

    surface.SetDrawColor(1, 4, 8, 125)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(2, 7, 14, 230)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(1560), h)

    surface.SetDrawColor(2, 7, 14, 115)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, SX(2280), h)

    draw.NoTexture()

    local headerX, headerY, lineX, lineY, contentX, contentY, contentW, contentH = self:GetLayoutData(w, h)
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

    draw.SimpleText(TEXT.title, "ZC_MM_SubTitle", headerX, headerY + math.floor(140 * s), Color(240, 248, 255, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local lineW = math.max(2, SX(2))

    DrawRound(lineW, lineX - lineW, contentY, lineW * 3, contentH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 26))
    DrawRound(lineW * 0.5, lineX, contentY, lineW, contentH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 235))
end

function PANEL:BuildIntro(parent)
    local actionBar = vgui.Create("DPanel", parent)
    actionBar:Dock(TOP)
    actionBar:SetTall(SX(48))
    actionBar:DockMargin(0, 0, SX(30), SX(18))
    actionBar.Paint = nil

    CreateActionButton(actionBar, TEXT.button_help, 0, function()
        OpenHelpWindow()
    end)

    CreateActionButton(actionBar, TEXT.button_reset, SX(14), function()
        ApplyDefaults()

        timer.Simple(0, function()
            SyncBindsFromEngine()

            if IsValid(self) then
                self:BuildContent()
            end
        end)

        Notify(TEXT.notify_reset, Color(255, 200, 0))
    end)
end

function PANEL:BuildSectionLabel(parent, text)
    local category = vgui.Create("DLabel", parent)
    category:Dock(TOP)
    category:SetTall(SX(56))
    category:SetText(text)
    category:SetFont("ZC_KB_Section")
    category:SetTextColor(Color(200, 232, 255, 235))
    category:DockMargin(0, SX(4), SX(30), SX(6))
    category:SetContentAlignment(4)
    category.Paint = function(_, w, h)
        DrawRound(1, 0, h - math.max(1, SX(2)), SX(114), math.max(1, SX(2)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190))
    end
end

function PANEL:CreateKeyCapture(row, bind)
    local button = vgui.Create("DButton", row)
    button:Dock(RIGHT)
    button:DockMargin(SX(10), SX(10), SX(10), SX(10))
    button:SetWide(SX(210))
    button:SetText("")
    button:SetCursor("hand")
    button.BindData = bind
    button.Capturing = false
    button.HoverLerp = 0

    function button:GetDisplayText()
        if self.Capturing and input.IsKeyTrapping() then
            return TEXT.capture
        end

        local keyText = GetKeyDisplayName(GetActiveKey(self.BindData))

        if self.BindData.shift and keyText ~= TEXT.capture_empty then
            return "SHIFT + " .. keyText
        end

        return keyText
    end

    AttachFancyTooltip(button, function()
        return { title = bind.title, description = bind.description }
    end)

    function button:DoClick()
        self.Capturing = true
        input.StartKeyTrapping()
    end

    function button:Think()
        if not self.Capturing then
            return
        end

        local code = input.CheckKeyTrapping()

        if code == nil then
            return
        end

        self.Capturing = false
        code = NormalizeKeyCode(code)

        if code == KEY_ESCAPE then
            code = KEY_NONE
        end

        HideFancyTooltip()

        if SetSmartBind(self.BindData, code) and hg_keybinds_menu and IsValid(hg_keybinds_menu) then
            timer.Simple(0, function()
                if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
                    hg_keybinds_menu:BuildContent()
                end
            end)
        end
    end

    function button:Paint(w, h)
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, (self:IsHovered() or self.Capturing) and 1 or 0)

        local bg = Color(
            Lerp(self.HoverLerp, 6, 12),
            Lerp(self.HoverLerp, 14, 26),
            Lerp(self.HoverLerp, 24, 42),
            Lerp(self.HoverLerp, 145, 205)
        )

        local rad = math.max(3, SX(6))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60 + self.HoverLerp * 155), 1)

        draw.SimpleText(self:GetDisplayText(), "ZC_KB_Button", w * 0.5, h * 0.5, Color(255, 255, 255, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return button
end

function PANEL:CreateClearButton(row, bind)
    local button = vgui.Create("DButton", row)
    button:Dock(RIGHT)
    button:DockMargin(0, SX(10), 0, SX(10))
    button:SetWide(SX(36))
    button:SetText("")
    button:SetCursor("hand")
    button.HoverLerp = 0

    AttachFancyTooltip(button, function()
        return { title = bind.title, description = "Полностью убирает текущий bind для этого действия." }
    end)

    button.DoClick = function()
        HideFancyTooltip()

        if SetSmartBind(bind, KEY_NONE) and hg_keybinds_menu and IsValid(hg_keybinds_menu) then
            timer.Simple(0, function()
                if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
                    hg_keybinds_menu:BuildContent()
                end
            end)
        end
    end

    button.Paint = function(self, w, h)
        self.HoverLerp = LerpFT(0.18, self.HoverLerp or 0, self:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(self.HoverLerp, 18, 45),
            Lerp(self.HoverLerp, 6, 12),
            Lerp(self.HoverLerp, 8, 12),
            Lerp(self.HoverLerp, 110, 160)
        )

        local rad = math.max(3, SX(6))
        local outline = Color(clr_danger.r, clr_danger.g, clr_danger.b, 40 + self.HoverLerp * 165)

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, outline, 1)
        draw.SimpleText("×", "ZC_MM_Close", w * 0.5, h * 0.46, Color(255, 225, 225, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return button
end

function PANEL:CreateBindRow(parent, bind)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(SX(56))
    row:DockMargin(0, 0, SX(30), SX(8))
    row.HoverLerp = 0

    row.Paint = function(selfRow, w, h)
        selfRow.HoverLerp = LerpFT(0.18, selfRow.HoverLerp or 0, selfRow:IsHovered() and 1 or 0)

        local hover = selfRow.HoverLerp
        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, Color(8, 18, 30, 90 + hover * 55))

        if hover > 0.01 then
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 42), math.max(2, SX(5)))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, hover * 185), math.max(1, SX(1)))
        end

        local modeText = bind.shift and TEXT.status_combo or (bind.hold and TEXT.status_hold or TEXT.status_press)
        local titleCol = Color(
            Lerp(hover, clr_text.r, 255),
            Lerp(hover, clr_text.g, 255),
            Lerp(hover, clr_text.b, 255),
            242
        )

        surface.SetFont("ZC_KB_RowTitle")
        local titleW = surface.GetTextSize(bind.title)

        draw.SimpleText(bind.title, "ZC_KB_RowTitle", SX(16), h * 0.5, titleCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(bind.command .. " • " .. modeText, "ZC_KB_RowText", SX(16) + titleW + SX(14), h * 0.5, Color(clr_dim.r, clr_dim.g, clr_dim.b, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    AttachFancyTooltip(row, function()
        return { title = bind.title, description = bind.description }
    end)

    self:CreateKeyCapture(row, bind)
    self:CreateClearButton(row, bind)

    return row
end

function PANEL:BuildContent()
    if not IsValid(self.Scroll) then
        return
    end

    self.Scroll:Clear()
    self.Rows = {}
    SyncBindsFromEngine()

    local canvas = self.Scroll:GetCanvas()

    self:BuildIntro(canvas)
    self:BuildSectionLabel(canvas, TEXT.section_gameplay)

    for _, bind in ipairs(BINDS) do
        table.insert(self.Rows, self:CreateBindRow(canvas, bind))
    end
end

function PANEL:Close()
    if self.Closing then
        return
    end

    self.Closing = true
    HideFancyTooltip()

    self:AlphaTo(0, 0.12, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZCityKeybindMenu", PANEL, "ZFrame")

local function OpenKeybindMenu()
    if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
        hg_keybinds_menu:Close()
        hg_keybinds_menu = nil
        return
    end

    SyncBindsFromEngine()

    local panel = vgui.Create("ZCityKeybindMenu")
    panel:MakePopup()
    hg_keybinds_menu = panel
end

concommand.Add("hg_keybinds", function()
    OpenKeybindMenu()
end)

concommand.Add("zcity_keybind_reload", function()
    SyncBindsFromEngine()

    if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
        hg_keybinds_menu:BuildContent()
    end

    Notify(TEXT.notify_reloaded, Color(0, 255, 0))
end)

concommand.Add("zcity_keybind_reset", function()
    ApplyDefaults()

    timer.Simple(0, function()
        SyncBindsFromEngine()

        if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
            hg_keybinds_menu:BuildContent()
        end
    end)

    Notify(TEXT.notify_reset, Color(255, 200, 0))
end)

concommand.Add("zcity_keybind_sync", function()
    SyncBindsFromEngine()

    if hg_keybinds_menu and IsValid(hg_keybinds_menu) then
        hg_keybinds_menu:BuildContent()
    end

    Notify(TEXT.notify_synced, Color(0, 255, 0))
end)

concommand.Add("zcity_keybind_dump", function()
    print(TEXT.console_dump_header)

    for _, bind in ipairs(BINDS) do
        print(bind.title, bind.command, bind.systemBinding or TEXT.status_empty)
    end

    print(string.rep("=", 44))
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "keybinds menu loaded\n")
