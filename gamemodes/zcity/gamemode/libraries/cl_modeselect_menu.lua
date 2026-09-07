if CLIENT then
    local isMenuOpen = nil
    zb.availableModes = zb.availableModes or {}
    local availableModes = zb.availableModes

    zb.RoundList = zb.RoundList or {}
    zb.nextround = zb.nextround or nil
    local queuePanelInstance = nil
    local selectedModes = {}

    local function IsMod()
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end
        if ply:IsAdmin() then return false end
        local group = ply:GetUserGroup()
        return group == "operator" or group == "sponsor"
    end

    local function HasMenuAccess()
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end
        if ply:GetUserGroup() == "admin" then return false end
        local group = ply:GetUserGroup()
        return ply:IsAdmin() or group == "operator" or group == "sponsor"
    end

    local function ScaryConfirm(text, fn)
        if not IsMod() then
            fn()
            return
        end
        Derma_Query(
            text .. "\n\nМы следим за вами. Это действие будет записано и отправлено администрации.",
            "Вы уверены?",
            "Да",
            fn,
            "Нет"
        )
    end

    net.Receive("ZB_SendModesInfo", function()
        zb.availableModes = net.ReadTable()
    end)

    net.Receive("ZB_StaffLimits", function()
        local active = net.ReadBool()
        if not active then
            zb.StaffLimits = { active = false }
            return
        end
        local modesMax = net.ReadInt(16)
        local modesLeft = net.ReadInt(16)
        local endsMax = net.ReadInt(16)
        local endsLeft = net.ReadInt(16)
        local cooldown = net.ReadInt(32)
        local minRoundTime = net.ReadInt(16)
        zb.StaffLimits = {
            active = true,
            modesMax = modesMax,
            modesLeft = modesLeft,
            endsMax = endsMax,
            endsLeft = endsLeft,
            cooldown = cooldown,
            minRoundTime = minRoundTime,
            received = CurTime()
        }
    end)

    net.Receive("ZB_SendRoundList", function()
        zb.RoundList = net.ReadTable()
        zb.nextround = net.ReadString()
        table.insert(zb.RoundList, 1, zb.nextround)
        zb.nextround = nil
        if IsValid(queuePanelInstance) then
            queuePanelInstance:QueueUpdate()
        end
    end)

    net.Receive("ZB_NotifyRoundListChange", function()
        local playerName = net.ReadString()

        chat.AddText(Color(180, 180, 255), playerName, Color(255, 255, 255), " изменил очередь игровых режимов")

        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end)

    local function StyleElement(element, bgColor)
        bgColor = bgColor or Color(40, 40, 40, 200)

        element.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, bgColor)

            if self:IsHovered() and self.Selectable then
                draw.RoundedBox(6, 1, 1, w-2, h-2, Color(60, 60, 60, 100))
                surface.SetDrawColor(255, 165, 0, 150)
                surface.DrawOutlinedRect(1, 1, w-2, h-2, 1)
            end

            if self.Selected then
                surface.SetDrawColor(0, 255, 0, 150)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        end
    end

    local function CreateModeItem(parent, mode, queue, index)
        local modePanel = vgui.Create("DPanel", parent)
        modePanel:SetTall(40)
        modePanel:Dock(TOP)
        modePanel:DockMargin(5, 2, 5, 2)
        modePanel.Mode = mode
        modePanel.Index = index
        modePanel.Selectable = true
        modePanel.Selected = selectedModes[mode.key] or false

        StyleElement(modePanel, Color(50, 50, 50, 200))

        local title = vgui.Create("DLabel", modePanel)
        title:SetFont("DermaDefaultBold")
        title:SetText(mode.name)
        title:SetTextColor(Color(255, 255, 255))
        title:Dock(LEFT)
        title:DockMargin(10, 0, 0, 0)
        title:SizeToContents()

        if queue then
            local posLabel = vgui.Create("DLabel", modePanel)
            posLabel:SetFont("DermaDefault")
            posLabel:SetText("#" .. index)
            posLabel:SetTextColor(Color(180, 180, 180))
            posLabel:Dock(LEFT)
            posLabel:DockMargin(5, 0, 0, 0)
            posLabel:SizeToContents()

            if not IsMod() then
                local upBtn = vgui.Create("DButton", modePanel)
                upBtn:SetSize(24, 24)
                upBtn:Dock(RIGHT)
                upBtn:DockMargin(2, 8, 5, 8)
                upBtn:SetText("▲")
                upBtn.DoClick = function()
                    if index > 1 then
                        local item = table.remove(zb.RoundList, index)
                        table.insert(zb.RoundList, index - 1, item)
                        queue:QueueUpdate()
                    end
                end

                local downBtn = vgui.Create("DButton", modePanel)
                downBtn:SetSize(24, 24)
                downBtn:Dock(RIGHT)
                downBtn:DockMargin(2, 8, 2, 8)
                downBtn:SetText("▼")
                downBtn.DoClick = function()
                    if index < #zb.RoundList then
                        local item = table.remove(zb.RoundList, index)
                        table.insert(zb.RoundList, index + 1, item)
                        queue:QueueUpdate()
                    end
                end

                local removeBtn = vgui.Create("DButton", modePanel)
                removeBtn:SetSize(24, 24)
                removeBtn:Dock(RIGHT)
                removeBtn:DockMargin(2, 8, 2, 8)
                removeBtn:SetText("✕")
                removeBtn.DoClick = function()
                    table.remove(zb.RoundList, index)
                    queue:QueueUpdate()
                end
            end
        else
            modePanel.OnMousePressed = function()
                if IsMod() then return end
                modePanel.Selected = not modePanel.Selected
                selectedModes[mode.key] = modePanel.Selected

                if modePanel.Selected then
                    surface.PlaySound("buttons/button9.wav")
                else
                    surface.PlaySound("buttons/button17.wav")
                end
            end
        end

        return modePanel
    end

    local function CreateQueuePanel(frame)
        local queuePanel = vgui.Create("DPanel", frame)
        queuePanel:SetSize(frame:GetWide() / 2 - 10, frame:GetTall())
        queuePanel:Dock(RIGHT)
        queuePanel:DockMargin(5, 5, 5, 5)
        StyleElement(queuePanel, Color(30, 30, 30, 200))

        queuePanelInstance = queuePanel

        local titleLabel = vgui.Create("DLabel", queuePanel)
        titleLabel:SetText("Очередь игровых режимов")
        titleLabel:SetFont("DermaLarge")
        titleLabel:SetTextColor(Color(255, 200, 0))
        titleLabel:Dock(TOP)
        titleLabel:DockMargin(0, 5, 0, 5)
        titleLabel:SetContentAlignment(5)

        local queueScroll = vgui.Create("DScrollPanel", queuePanel)
        queueScroll:Dock(FILL)
        queueScroll:DockMargin(5, 5, 5, 5)

        if not IsMod() then
            local saveBtn = vgui.Create("DButton", queuePanel)
            saveBtn:SetText("Применить очередь")
            saveBtn:Dock(BOTTOM)
            saveBtn:DockMargin(5, 5, 5, 5)
            saveBtn:SetTall(30)
            saveBtn.DoClick = function()
                local tbl = table.Copy(zb.RoundList)
                net.Start("ZB_UpdateRoundList")
                net.WriteTable(tbl)
                net.WriteBool(true)
                net.SendToServer()

                chat.AddText(Color(0, 255, 0), "Очередь игровых режимов установлена!")
            end

            local clearBtn = vgui.Create("DButton", queuePanel)
            clearBtn:SetText("Очистить очередь")
            clearBtn:Dock(BOTTOM)
            clearBtn:DockMargin(5, 5, 5, 5)
            clearBtn:SetTall(30)
            clearBtn.DoClick = function()
                zb.RoundList = {}
                queuePanel:QueueUpdate()

                chat.AddText(Color(255, 165, 0), "Очередь игровых режимов очищена!")
            end
        end

        function queuePanel:QueueUpdate()
            queueScroll:Clear()

            if zb.nextround and zb.nextround ~= "" then
                local nextRoundLabel = vgui.Create("DLabel", queueScroll)
                nextRoundLabel:SetText("Следующий режим: " .. zb.nextround)
                nextRoundLabel:SetFont("DermaDefaultBold")
                nextRoundLabel:SetTextColor(Color(100, 255, 100))
                nextRoundLabel:Dock(TOP)
                nextRoundLabel:DockMargin(5, 0, 0, 10)
                nextRoundLabel:SizeToContents()
            end

            for idx, modeKey in ipairs(zb.RoundList) do
                local mode = nil

                for _, availableMode in ipairs(zb.availableModes) do
                    if availableMode.key == modeKey then
                        mode = availableMode
                        break
                    end
                end

                if not mode then
                    mode = {key = modeKey, name = modeKey}
                end

                CreateModeItem(queueScroll, mode, queuePanel, idx)
            end
        end

        queuePanel:QueueUpdate()
        return queuePanel
    end

    local function OpenModeSelection(command)
        local frame = vgui.Create("ZFrame")
        frame:SetSize(700, 500)
        frame:Center()
        frame:SetTitle("Менеджер игровых режимов")
        frame:MakePopup()

        selectedModes = {}

        local queuePanel = CreateQueuePanel(frame)

        local leftPanel = vgui.Create("DPanel", frame)
        leftPanel:SetSize(frame:GetWide() / 2 - 10, frame:GetTall())
        leftPanel:Dock(LEFT)
        leftPanel:DockMargin(5, 5, 5, 5)
        StyleElement(leftPanel, Color(30, 30, 30, 200))

        local titleLabel = vgui.Create("DLabel", leftPanel)
        titleLabel:SetText("Доступные игровые режимы")
        titleLabel:SetFont("DermaLarge")
        titleLabel:SetTextColor(Color(255, 200, 0))
        titleLabel:Dock(TOP)
        titleLabel:DockMargin(0, 5, 0, 5)
        titleLabel:SetContentAlignment(5)

        local searchBar = vgui.Create("DTextEntry", leftPanel)
        searchBar:SetPlaceholderText("Поиск игровых режимов...")
        searchBar:Dock(TOP)
        searchBar:DockMargin(5, 5, 5, 5)
        searchBar:SetTall(25)

        local dscroll = vgui.Create("DScrollPanel", leftPanel)
        dscroll:Dock(FILL)
        dscroll:DockMargin(5, 5, 5, 5)

        local modeItems = {}

        local function UpdateSearch(filter)
            filter = filter:lower()

            for _, item in ipairs(modeItems) do
                local visible = filter == "" or string.find(item.Mode.name:lower(), filter)
                item:SetVisible(visible)
            end

            dscroll:InvalidateLayout()
        end

        searchBar.OnChange = function(self)
            UpdateSearch(self:GetValue())
        end

        for i, mode in SortedPairsByMemberValue(zb.availableModes, "canlaunch", true) do

            local modeBtn = CreateModeItem(dscroll, mode)
            table.insert(modeItems, modeBtn)

            modeBtn:SetCursor("hand")
            modeBtn:SetTooltip("Нажми, чтобы выбрать/снять выбор режима")

            local inQueue = false
            for _, queuedModeKey in ipairs(zb.RoundList) do
                if queuedModeKey == mode.key then
                    inQueue = true
                    break
                end
            end

            local indicator = vgui.Create("DPanel", modeBtn)
            indicator:SetSize(16, 7)
            indicator:SetPos(8, 4)
            indicator.IndiColor = Color(0, 0, 0, 0)
            indicator.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, indicator.IndiColor)
            end

            if mode.canlaunch == 1 then
                indicator.IndiColor = Color(0,255,34)
                indicator:SetTooltip("Этот режим можно запустить")
            end

            if inQueue then
                indicator.IndiColor = Color(255, 155, 0, 255)
                indicator:SetTooltip("Этот режим уже в очереди")
            end

            if mode.canlaunch == 0 then
                indicator.IndiColor = Color(255,0,0,255)
                indicator:SetTooltip("Этот режим нельзя запустить")
            end

            if command == "setmode" or command == "setforcemode" then
                local selectBtn = vgui.Create("DButton", modeBtn)
                selectBtn:SetSize(80, 26)
                selectBtn:Dock(RIGHT)
                selectBtn:DockMargin(5, 7, 5, 7)
                selectBtn:SetText("Выбрать")
                selectBtn.DoClick = function()
                    ScaryConfirm("Следующим режимом будет установлен: " .. mode.name, function()
                        net.Start("AdminSetGameMode")
                        net.WriteString(command)
                        net.WriteString(mode.key)
                        net.WriteBool(false)
                        net.SendToServer()
                        frame:Close()
                    end)
                end
            end
        end

        if not IsMod() then
            local batchPanel = vgui.Create("DPanel", leftPanel)
            batchPanel:Dock(BOTTOM)
            batchPanel:DockMargin(5, 5, 5, 5)
            batchPanel:SetTall(80)
            StyleElement(batchPanel, Color(40, 40, 40, 200))

            local batchTitle = vgui.Create("DLabel", batchPanel)
            batchTitle:SetText("Групповые операции")
            batchTitle:SetFont("DermaDefaultBold")
            batchTitle:SetTextColor(Color(255, 255, 255))
            batchTitle:Dock(TOP)
            batchTitle:DockMargin(0, 5, 0, 5)
            batchTitle:SetContentAlignment(5)

            local addToQueueBtn = vgui.Create("DButton", batchPanel)
            addToQueueBtn:SetText("Добавить выбранные в начало очереди")
            addToQueueBtn:Dock(TOP)
            addToQueueBtn:DockMargin(5, 0, 5, 5)
            addToQueueBtn:SetTall(26)
            addToQueueBtn.DoClick = function()
                local selectedCount = 0

                local selectedKeys = {}
                for key, selected in pairs(selectedModes) do
                    if selected then
                        table.insert(selectedKeys, 1, key)
                        selectedCount = selectedCount + 1
                    end
                end

                for i = 1, #selectedKeys do
                    table.insert(zb.RoundList, 1, selectedKeys[i])
                end

                if selectedCount > 0 then
                    queuePanel:QueueUpdate()

                    chat.AddText(Color(0, 255, 0), "Добавлено режимов в начало очереди: " .. selectedCount .. "!")

                    selectedModes = {}
                    for _, item in ipairs(modeItems) do
                        item.Selected = false
                    end
                else
                    chat.AddText(Color(255, 0, 0), "Режимы не выбраны!")
                end
            end

            local addToEndBtn = vgui.Create("DButton", batchPanel)
            addToEndBtn:SetText("Добавить выбранные в конец очереди")
            addToEndBtn:Dock(TOP)
            addToEndBtn:DockMargin(5, 0, 5, 0)
            addToEndBtn:SetTall(26)
            addToEndBtn.DoClick = function()
                local selectedCount = 0

                for key, selected in pairs(selectedModes) do
                    if selected then
                        table.insert(zb.RoundList, key)
                        selectedCount = selectedCount + 1
                    end
                end

                if selectedCount > 0 then
                    queuePanel:QueueUpdate()

                    chat.AddText(Color(0, 255, 0), "Добавлено режимов в конец очереди: " .. selectedCount .. "!")

                    selectedModes = {}
                    for _, item in ipairs(modeItems) do
                        item.Selected = false
                    end
                else
                    chat.AddText(Color(255, 0, 0), "Режимы не выбраны!")
                end
            end
        end

        local refreshBtn = vgui.Create("DButton", leftPanel)
        refreshBtn:SetText("Обновить данные")
        refreshBtn:Dock(BOTTOM)
        refreshBtn:DockMargin(5, 5, 5, 5)
        refreshBtn:SetTall(30)
        refreshBtn.DoClick = function()
            net.Start("ZB_RequestRoundList")
            net.SendToServer()
        end

        timer.Create("QueueAutoRefresh", 5, 0, function()
            if IsValid(frame) then
            else
                timer.Remove("QueueAutoRefresh")
            end
        end)

        frame.OnClose = function()
            timer.Remove("QueueAutoRefresh")
            queuePanelInstance = nil
        end

        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end

    local function OpenAdminMenu()
        if not HasMenuAccess() then return end
        if IsValid(isMenuOpen) then return end

        isMenuOpen = vgui.Create("ZFrame")
        local frame = isMenuOpen
        frame:SetSize(300, 210)
        frame:Center()
        frame:SetTitle(IsMod() and "Модер-панель" or "Админ-панель")
        frame:MakePopup()

        if IsMod() then
            local limitsLabel = vgui.Create("DLabel", frame)
            limitsLabel:Dock(TOP)
            limitsLabel:DockMargin(5, 8, 5, 0)
            limitsLabel:SetTall(38)
            limitsLabel:SetWrap(true)
            limitsLabel:SetFont("DermaDefaultBold")
            limitsLabel:SetTextColor(Color(255, 215, 140))
            limitsLabel:SetContentAlignment(5)
            limitsLabel:SetText("Загрузка суточных лимитов...")
            limitsLabel.Think = function(self)
                local data = zb.StaffLimits
                if not data or not data.active then return end
                local left = math.max(0, (data.cooldown or 0) - (CurTime() - (data.received or 0)))
                local text = "Смены режима: " .. data.modesLeft .. " из " .. data.modesMax .. " | Завершения раунда: " .. data.endsLeft .. " из " .. data.endsMax
                if left > 0 then
                    text = text .. "\nОткат завершения: " .. math.ceil(left / 60) .. " мин."
                end
                self:SetText(text)
            end

            net.Start("ZB_RequestRoundList")
            net.SendToServer()
        end

        local setModeBtn = vgui.Create("DButton", frame)
        setModeBtn:SetText("Установить следующий режим")
        setModeBtn:Dock(TOP)
        setModeBtn:DockMargin(5, 10, 5, 2)
        setModeBtn:SetSize(300, 40)
        StyleElement(setModeBtn)
        setModeBtn.DoClick = function()
            OpenModeSelection("setmode")
        end

        if not IsMod() then
            local setForceModeBtn = vgui.Create("DButton", frame)
            setForceModeBtn:SetText("Установить автоследующий режим")
            setForceModeBtn:Dock(TOP)
            setForceModeBtn:DockMargin(5, 2, 5, 2)
            setForceModeBtn:SetSize(300, 40)
            StyleElement(setForceModeBtn)
            setForceModeBtn.DoClick = function()
                OpenModeSelection("setforcemode")
            end

            local queueModeBtn = vgui.Create("DButton", frame)
            queueModeBtn:SetText("Управление очередью режимов")
            queueModeBtn:Dock(TOP)
            queueModeBtn:DockMargin(5, 2, 5, 2)
            queueModeBtn:SetSize(300, 40)
            StyleElement(queueModeBtn)
            queueModeBtn.DoClick = function()
                OpenModeSelection("queue")
            end
        end

        local endRoundBtn = vgui.Create("DButton", frame)
        endRoundBtn:SetText("Завершить раунд")
        endRoundBtn:Dock(TOP)
        endRoundBtn:DockMargin(5, 2, 5, 2)
        endRoundBtn:SetSize(300, 40)
        StyleElement(endRoundBtn)
        endRoundBtn.DoClick = function()
            ScaryConfirm("Текущий раунд будет немедленно завершён.", function()
                net.Start("AdminEndRound")
                net.SendToServer()
                frame:Close()
            end)
        end

        frame.OnClose = function()
            isMenuOpen = false
        end
        frame:InvalidateLayout(true)
        frame:SizeToChildren(false, true)
    end

    hook.Add("InitPostEntity", "RequestModeData", function()
        if HasMenuAccess() then
            timer.Simple(2, function()
                net.Start("ZB_RequestRoundList")
                net.SendToServer()
            end)
        end
    end)

    local f6Key = KEY_F6

    hook.Add("PlayerButtonDown", "OpenAdminMenuF6", function(ply, key)
        if key == f6Key and HasMenuAccess() and not IsValid(isMenuOpen) then
            OpenAdminMenu()
        end
    end)
end
