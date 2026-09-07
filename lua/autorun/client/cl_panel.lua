-- Кеш для активных звуков
local activeSounds = {}

local function playSafeSound(url, volume)
    if IsValid(activeSounds[url]) then
        activeSounds[url]:Stop()
        activeSounds[url] = nil
    end

    sound.PlayURL(url, "", function(s)
        if IsValid(s) then
            s:SetVolume(volume or 1.5)
            s:Play()
            activeSounds[url] = s
        end
    end)
end

local function stopAllActiveSounds()
    for url, snd in pairs(activeSounds) do
        if IsValid(snd) then
            snd:Stop()
        end
    end
    activeSounds = {}
end

hook.Add( "OnPlayerChat", "codesdcommand", function( ply, strText, bTeam, bDead )

    if ( ply != LocalPlayer() ) then return end
    
    if ( strText == "/tablet" ) then
        RunConsoleCommand("m_panel")
    end

end )
 
/*-------------------------------------------
				Шрифты
-------------------------------------------*/

surface.CreateFont("cms", { font = "Montserrat", size = 23, weight = 500, antialias = true })

surface.CreateFont( "FontPanel", {
	font = "Arial", 
	size = 23,
	weight = 500,
} )

surface.CreateFont( "FontPanel13", {
	font = "Arial", 
	size = 13,
	weight = 300,
} )
  
local menu_BackGround = Color(30, 0, 60, 200)         -- Dark purple background
local menu_Black = Color(0, 0, 0, 250)                -- Black background for certain areas
local button_BackGround = Color(70, 0, 130, 150)      -- Dark purple button background
local button_BackGround_noA = Color(90, 70, 120, 200) -- Slightly lighter for inactive buttons
local upBar_Color = Color(30, 0, 60, 150)             -- Dark purple with less opacity for the bar
local color_White = Color(255, 255, 255, 255)         -- White text
local color_White150 = Color(255, 255, 255, 120)      -- Semi-transparent white for certain text
local color_Red = Color(255, 75, 75, 200)             -- Red for highlights

local IsMilkyPanels = {
    ["STEAM_0:0:456105773"]    = true,
    ["STEAM_0:1:529805869"]    = true,
}

local function isMilkyPanel()
    return IsMilkyPanels[LocalPlayer():SteamID()]
end

local dialog_dir = vgui.RegisterTable({
    Init = function(self)
        local X, Y = 850, 500

        self:SetSize(X, Y)
        self:SetPos(ScrW() * 0.5 - X * 0.5, ScrH() * 0.5 - Y * 0.5)
        self:MakePopup()
        self:SetTitle("")
        self:SetDraggable(false)
        self:ShowCloseButton(false)
        self:SetVisible(true)

        self.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, Color(30, 0, 60, 255)) -- Dark purple frame
        end

        -- Заголовок
        self.Title = self:Add("DPanel")
        self.Title:SetPos(0, 0)
        self.Title:SetSize(X, 50)
        self.Title:SetPaintBackground(false)
        self.Title.Paint = function(s, w, h)
            draw.SimpleText("ADMIN PANEL", "MilkyTablerPanel2", w * 0.5, h * 0.5, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Кнопка закрытия (кастомный крестик)
        self.CloseBtn = self:Add("DButton")
        self.CloseBtn:SetSize(20, 20)
        self.CloseBtn:SetText("")
        self.CloseBtn:SetPos(X - 30, 15)

        self.CloseBtn.Paint = function(s, w, h)
            local clr = s:IsHovered() and Color(255, 100, 100) or Color(255, 255, 255)
            surface.SetDrawColor(clr)

            for i = -1, 1 do
                surface.DrawLine(4 + i, 4, w - 4 + i, h - 4) -- линия по диагонали \
                surface.DrawLine(4, 4 + i, w - 4, h - 4 + i)

                surface.DrawLine(w - 4 + i, 4, 4 + i, h - 4) -- линия по диагонали /
                surface.DrawLine(w - 4, 4 + i, 4, h - 4 + i)
            end
        end

        self.CloseBtn.DoClick = function()
            self:Remove()
        end

        -- Основная панель
        local main = self:Add("DPanel")
        main:SetPos(0, 50)
        main:SetSize(X, Y - 50)
        main:SetPaintBackground(false)

        local catList = main:Add("DScrollPanel")
        catList:Dock(LEFT)
        catList:SetWide(180)
        catList:DockMargin(10, 0, 10, 0)
        catList:GetVBar():SetWide(0)

        local codeContainer = main:Add("DScrollPanel")
        codeContainer:Dock(FILL)
        codeContainer:GetVBar():SetWide(6)
        codeContainer:GetVBar().Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 0, 80)) -- Dark purple for the scroll bar
        end
        codeContainer:GetVBar().btnGrip.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(100, 50, 150)) -- Lighter purple grip
        end

        local function displayCodes(codes)
            codeContainer:Clear()

            for i, v in ipairs(codes) do
                timer.Simple(0.03 * i, function()
                    if not IsValid(codeContainer) then return end

                    local codeBtn = codeContainer:Add("DButton")
                    codeBtn:Dock(TOP)
                    codeBtn:DockMargin(5, 5, 5, 0)
                    codeBtn:SetTall(40)
                    codeBtn:SetText("")
                    codeBtn.text = v.code
                    codeBtn.col = v.col or Color(130, 90, 190)
                    codeBtn.gradient = 0
                    codeBtn.alpha = 0
                    codeBtn.yOffset = 10

                    codeBtn.Paint = function(s, w, h)
                        s.alpha = Lerp(FrameTime() * 8, s.alpha, 255)
                        s.yOffset = Lerp(FrameTime() * 8, s.yOffset, 0)

                        surface.SetAlphaMultiplier(s.alpha / 255)

                        if s:IsHovered() then
                            s.gradient = math.min(s.gradient + FrameTime() * 400, w)
                        else
                            s.gradient = math.max(s.gradient - FrameTime() * 400, 0)
                        end

                        draw.RoundedBox(8, 0, s.yOffset, w, h, Color(40, 0, 80, 240)) -- Darker purple button
                        draw.RoundedBox(0, 0, h - 3 + s.yOffset, s.gradient, 3, s.col)
                        draw.SimpleText(s.text, "MilkyTablerPanel", w / 2, h / 2 + s.yOffset, Color(220, 255, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                        surface.SetAlphaMultiplier(1)
                    end

                    codeBtn.DoClick = function()
                        netstream.Start("km_sendcode", v.id)
                    end
                end)
            end
        end

        local catButtons = {}
        local selectedIndex = 0

        for i, category in ipairs(milkyLib.codes_table or {}) do
            if category.banned and not LocalPlayer():IsSuperAdmin() and not isMilkyPanel(ply) then continue end

            local catName = category.cat_name or "Категория"
            local codes = {}

            for k, v in ipairs(category) do
                if istable(v) and v.code then
                    table.insert(codes, v)
                end
            end

            if #codes > 0 then
                local catBtn = catList:Add("DButton")
                catBtn:Dock(TOP)
                catBtn:DockMargin(0, 0, 0, 5)
                catBtn:SetTall(36)
                catBtn:SetText("")
                catBtn.active = false

                table.insert(catButtons, catBtn)

                catBtn.Paint = function(s, w, h)
                    local bg = s.active and Color(60, 0, 100) or Color(40, 0, 60) -- Darker shades of purple
                    draw.RoundedBox(8, 0, 0, w, h, bg)
                    draw.SimpleText(catName, "MilkyTablerPanel", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                catBtn.DoClick = function()
                    for _, b in ipairs(catButtons) do
                        b.active = false
                    end
                    catBtn.active = true
                    displayCodes(codes)
                end

                -- Если это первая категория — активируем
                if selectedIndex == 0 then
                    selectedIndex = i
                    timer.Simple(0, function()
                        catBtn:DoClick()
                    end)
                end
            end
        end
    end
}, "DFrame")

concommand.Add("m_panel",function()
	local ply = LocalPlayer()
	local tem = LocalPlayer():Team()
	if ply:IsSuperAdmin() or isMilkyPanel(ply) then
		if IsValid(sukaRepGayPanel) then return end
		sukaRepGayPanel = vgui.CreateFromTable(dialog_dir)
	end
end)



local X, Y = 42, 150
local codes_frame = vgui.RegisterTable(
{
    Init = function(self)
        self.x = X
        self.y = Y
        self.size_y = 30
        self:DockPadding(0, 0, 0, 0)
        self:SetTitle("")
        self:SetVisible(true)
        self:SetDraggable(false)
        self:ShowCloseButton(false)
        self.textsize = 150
        self.text = "error"
        self.color = Color(255, 255, 255) -- Убедитесь, что цвет по умолчанию установлен

        -- Установка фона с градиентом снизу вверх, переходящий в прозрачность
        self.Paint = function(self, w, h)
            -- Здесь используется градиент от нижнего цвета (полный) до верхнего (прозрачность)
            local bottomColor = Color(50, 50, 50, 255)  -- Цвет низа (полный цвет)
            local topColor = Color(50, 50, 50, 0)  -- Цвет верха (прозрачность)

            -- Рисуем градиент с нижнего цвета к прозрачному вверху
            for i = 0, h do
                local lerpedColor = Color(
                    bottomColor.r + (topColor.r - bottomColor.r) * (1 - i / h),
                    bottomColor.g + (topColor.g - bottomColor.g) * (1 - i / h),
                    bottomColor.b + (topColor.b - bottomColor.b) * (1 - i / h),
                    bottomColor.a + (topColor.a - bottomColor.a) * (1 - i / h)
                )
                surface.SetDrawColor(lerpedColor)
                surface.DrawLine(0, i, w, i)
            end

            draw.SimpleText(self.text, "MilkySCPPanel2", w * 0.5, h * 0.45, self.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end,

    _SetText = function(self, code)
        if not code then return end
        local txt = code.code or ""
        self.color = code.col or Color(255, 255, 255) -- Убедитесь, что цвет корректно установлен
        surface.SetFont("MilkySCPPanel2")
        self.textsize = select(1, surface.GetTextSize(txt)) + 25
        self.text = txt
        self:SetSize(self.textsize, self.size_y)

        -- Центрируем по X, а по Y ставим ниже экрана
        self:SetPos((ScrW() - self.textsize) / 2, ScrH() + self.size_y) -- Начальное положение ниже экрана
    end,

    _SetTimer = function(self, time, curtime)
        if not time then return end

        self.timeline = self:Add("DPanel")
        local timeline = self.timeline

        timeline:SetSize(self.textsize, 2)
        timeline.start = curtime
        timeline.step = self.textsize / time
        timeline.color = Color(self.color.r, self.color.g, self.color.b, self.color.a)
        timeline:SetPos(0, self.size_y - 2)
        timeline:SetAlpha(255)

        timeline.Paint = function(pnl, w, h)
            local tick = CurTime() - pnl.start
            if tick < time then
                draw.RoundedBox(6, 0, 0, w - pnl.step * tick, h, pnl.color)
            else
                pnl:AlphaTo(0, 0.4, 0, function()
                    local parent = pnl:GetParent()
                    if IsValid(parent) then
                        parent:_Close()
                    end
                end)
                pnl.Paint = nil -- Отключаем дальнейшую отрисовку после завершения
            end
        end
    end,

    _Close = function(self)
        if IsValid(self.timeline) then
            self.timeline:Remove()
        end

        stopAllActiveSounds() -- очистка всех активных звуков

        -- Анимация закрытия (выезжает вниз)
        self:MoveTo(self:GetX(), ScrH() + self.size_y, 1.0, 0.4, -1, function()
            self:Remove()
        end)
    end,

    _Open = function(self)
        -- Анимация открытия (выезжает снизу вверх)
        self:MoveTo(self:GetX(), ScrH() - self.size_y - 10, 1.0, 0.4, -1, function()  -- Установите y на "ScrH() - self.size_y - 10"
            self:SetAlpha(255) -- Яркость после открытия
        end)
    end,

}, "DFrame")

local function setSubCode(code, timer)
    local code = milkyLib.codes_table.keys[code]

    if IsValid(sub_code_frame) then
        -- Убираем старую панель, но только после того, как новая откроется
        sub_code_frame._Close(sub_code_frame)
    end

    -- Создаем новую панель
    sub_code_frame = vgui.CreateFromTable(codes_frame)
    sub_code_frame.y = ScrH() - 50  -- Установить y в 50 пикселей от нижнего края экрана

    -- Устанавливаем текст и таймер
    sub_code_frame._SetText(sub_code_frame, code)

    if timer then
        sub_code_frame._SetTimer(sub_code_frame, code.timed, timer != 0 and timer or CurTime())
    end

    -- Плавно открываем новую панель
    sub_code_frame._Open(sub_code_frame)
end

local black = Color(10,10,10,200) -- iam not resist
local sub_code = ""
local setcodeinfo = function(code_tab, preventsound, start)
    if not code_tab then return end

    surface.SetFont("FontPanel")

    -- Проигрываем звук, если он разрешён
    if not preventsound and code_tab.sound then
        playSafeSound(code_tab.sound, 1.7)
    end

    -- Установка кода в зависимости от типа
    if code_tab.sub then
        setSubCode(code_tab.id or "UNKNOWN", start or CurTime())
    end
end

netstream.Hook("km_getcode", function(data)
    local code = data.id
    local code_tab = milkyLib.codes_table.keys[code]
    
    if code_tab then 
        sub_code = code 
        setcodeinfo(code_tab, data.preventSound, data.time)
    end
end)

netstream.Hook("udar_sound_test", function() 
    sound.PlayURL("https://raw.githubusercontent.com/Milky182828/MILKY/master/sound/intercom_area/10s_joJtaDqi.mp3", "", function(s)
        if IsValid(s) then 
            s:SetVolume(1.8)
            s:Play()
        end
    end)
end)

netstream.Hook("otc_city_chat", function(data)
    if not data or not data.text then return end

    chat.AddText(Color(255, 90, 90), "━━━━━━━━━━━━━━━━━━━━")
    chat.AddText(Color(255, 90, 90), "[OT-City] ", Color(255, 255, 255), data.text)
    chat.AddText(Color(255, 90, 90), "━━━━━━━━━━━━━━━━━━━━")
end)

netstream.Hook("a_logs_chat", function(data)
    if not istable(data) or not data.text or data.text == "" then return end

    local red = Color(220, 20, 60)

    chat.AddText(red, "━━━━━━━━━━━━━━━━━━━━")
    chat.AddText(red, "[M-Logs] ", Color(255, 255, 255), tostring(data.text))
    chat.AddText(red, "━━━━━━━━━━━━━━━━━━━━")
end)

local TAG_NAME = "ДОЗОР"

netstream.Hook("zb_dozor_chat", function(data)
    if not data or not data.text then return end
    local txt = tostring(data.text)
    if txt == "" then return end

    chat.AddText(Color(255, 90, 90), "━━━━━━━━━━━━━━━━━━━━")
    chat.AddText(Color(255, 90, 90), "[" .. TAG_NAME .. "] ", Color(255, 255, 255), txt)
    chat.AddText(Color(255, 90, 90), "━━━━━━━━━━━━━━━━━━━━")
end)