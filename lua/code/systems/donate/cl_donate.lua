if SERVER then AddCSLuaFile() return end
timer.Simple(0.1, function()
monteractF4 = monteractF4 or {}
monteractF4.menus = monteractF4.menus or {}
monteractF4.lastchoisedid = 1
monteractF4.cache_name_id = {}
if not file.IsDir("monteract/cache", "DATA") then
    file.CreateDir("monteract/cache")
end
monteract_materials = monteract_materials or {}
monteract_materials.getByIDFromCeche = function(id)
    if monteract_materials[id] then return monteract_materials[id] end
    local _file = "monteract/cache/" .. id .. ".png"
    if file.Exists(_file, "DATA") then
        print("INIT", id, "ICON")
        monteract_materials[id] = Material("data/" .. _file, "nocull")
    else
        return Default
    end
    return monteract_materials[id] or Default
end
monteract_materials.getByID = monteract_materials.getByID or function(id)
    id = tostring(id or "")
    if id == "" then return nil end
    if monteract_materials[id] and not monteract_materials[id]:IsError() then return monteract_materials[id] end
    local data_png = "monteract/cache/" .. id .. ".png"
    if file.Exists(data_png, "DATA") then
        monteract_materials[id] = Material("../data/" .. data_png, "smooth noclamp")
        if monteract_materials[id] and not monteract_materials[id]:IsError() then return monteract_materials[id] end
    end
    local mat = Material(id, "smooth noclamp")
    if mat and not mat:IsError() then
        monteract_materials[id] = mat
        return mat
    end
    return nil
end
local adress = "https://monteract.ru/api"
monteractF4.adress = adress
monteractF4.getData = function(id, cb)
    id = tostring(id or "")
    if string.StartWith(id, "/") then
        id = string.sub(id, 2)
    end
    local url = adress .. "/" .. id
    http.Fetch(url, function(body, len, headers, code)
        if code and code >= 400 then
            print("[F4 API] HTTP error:", code, url)
            if isfunction(cb) then cb(nil, true) end
            return
        end
        local tab = util.JSONToTable(body or "")
        if not istable(tab) or tab.error then
            print("[F4 API] Bad JSON:", url, body)
            if isfunction(cb) then cb(nil, true) end
            return
        end
        if isfunction(cb) then cb(tab, false) end
    end, function(err)
        print("[F4 API] Fetch failed:", url, err)
        if isfunction(cb) then cb(nil, true) end
    end)
end
monteractF4.initImage = function(image, cb)
    http.Fetch("https://monteract.ru" .. image, function(body)
        local filename_arr = string.Split(image, "/")
        local name = filename_arr[#filename_arr]
        local abs_name = string.Split(name, ".")[1]
        local path = "monteract/cache/" .. name
        if file.Exists(path, "DATA") then
            cb(abs_name)
        else
            file.Write(path, body)
            cb(abs_name)
        end
    end)
end
local recorseveDelete
recorseveDelete = function(path)
    local files, directories = file.Find(path .. "/*", "DATA")
    for index, file_path in ipairs(files) do
        file.Delete(path .. "/" .. file_path)
    end
    for index, directory_path in ipairs(directories) do
        recorseveDelete(path .. "/" .. directory_path)
    end
    file.Delete(path)
end
local cleanDataCesheDirectory = function()
    recorseveDelete("monteract/cache")
    file.CreateDir("monteract/cache")
end
cleanDataCesheDirectory()
monteractF4.addmenu = function(data)
    if not istable(data) then return end
    data.name = tostring(data.name or "Меню")
    data.num = tonumber(data.num) or data.num
    local oldid = monteractF4.cache_name_id[data.name]
    if oldid and istable(monteractF4.menus[oldid]) then
        data.num = tonumber(data.num) or oldid
        monteractF4.menus[oldid] = data
        monteractF4.cache_name_id[data.name] = oldid
        return
    end
    local pasteid = data.num
    if isnumber(pasteid) then
        monteractF4.menus[pasteid] = data
        monteractF4.cache_name_id[data.name] = pasteid
        return
    end
    local i = 1
    while istable(monteractF4.menus[i]) do
        i = i + 1
    end
    data.num = i
    monteractF4.menus[i] = data
    monteractF4.cache_name_id[data.name] = i
end
monteractF4.getMenuByName = function(name)
    local id = monteractF4.cache_name_id[name] or 1
    return monteractF4.menus[id]
end
local function DrawOTCRound(radius, x, y, w, h, col)
    radius = tonumber(radius) or 0
    col = col or color_white
    local drawn = false
    if RNDX then
        pcall(function()
            if isfunction(RNDX.Draw) then
                RNDX.Draw(radius, x, y, w, h, col)
                drawn = true
                return
            end
            local r = isfunction(RNDX) and RNDX() or nil
            if not r or not isfunction(r.Rect) then return end
            r = r:Rect(x, y, w, h) or r
            if r and isfunction(r.Radius) then r = r:Radius(radius) or r end
            if r and isfunction(r.Rad) then r = r:Rad(radius) or r end
            if r and isfunction(r.Color) then r = r:Color(col) or r end
            if r and isfunction(r.Colour) then r = r:Colour(col) or r end
            if r and isfunction(r.Draw) then r:Draw() drawn = true return end
            if r and isfunction(r.Paint) then r:Paint() drawn = true return end
        end)
    end
    if not drawn then draw.RoundedBox(radius, x, y, w, h, col) end
end
local ot_bg_material = Material("otcity/fone.png", "smooth")
local function OTNoise(t, f1, f2, f3, phase)
    phase = phase or 0
    return math.sin(t * f1 * math.pi * 2 + phase) * 0.55
        + math.sin(t * f2 * math.pi * 2 + phase + 2.399) * 0.30
        + math.sin(t * f3 * math.pi * 2 + phase + 5.131) * 0.15
end
local function DrawOTBackground(pnl, w, h, radius, dim)
    radius = radius or 16
    DrawOTCRound(radius, 0, 0, w, h, Color(3, 5, 9, 252))
    local mat = ot_bg_material
    local iw = mat and mat:Width() or 0
    local ih = mat and mat:Height() or 0
    if not mat or mat:IsError() or iw <= 0 or ih <= 0 or w <= 0 or h <= 0 then return end
    pnl.OTBGStart = pnl.OTBGStart or RealTime()
    local elapsed = RealTime() - pnl.OTBGStart
    local dt = math.Clamp(FrameTime(), 0, 0.1)
    local blend = 1 - math.exp(-dt * 1.35)
    local zoomTarget = 1.18 + (OTNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
    local panXTarget = OTNoise(elapsed, 0.0131, 0.0207, 0.0331, 1.3)
    local panYTarget = OTNoise(elapsed, 0.0113, 0.0181, 0.0293, 4.9)
    pnl.OTBGZoom = (pnl.OTBGZoom or zoomTarget) + (zoomTarget - (pnl.OTBGZoom or zoomTarget)) * blend
    pnl.OTBGPanX = (pnl.OTBGPanX or panXTarget) + (panXTarget - (pnl.OTBGPanX or panXTarget)) * blend
    pnl.OTBGPanY = (pnl.OTBGPanY or panYTarget) + (panYTarget - (pnl.OTBGPanY or panYTarget)) * blend
    local panelAspect = w / h
    local imgAspect = iw / ih
    local uw, vh = 1, 1
    if imgAspect > panelAspect then uw = panelAspect / imgAspect else vh = imgAspect / panelAspect end
    uw = math.Clamp(uw / pnl.OTBGZoom, 0.05, 1)
    vh = math.Clamp(vh / pnl.OTBGZoom, 0.05, 1)
    local u0 = math.Clamp((1 - uw) * 0.5 + pnl.OTBGPanX * (1 - uw) * 0.42, 0, 1 - uw)
    local v0 = math.Clamp((1 - vh) * 0.5 + pnl.OTBGPanY * (1 - vh) * 0.42, 0, 1 - vh)
    local clipped = false
    if render and render.SetStencilEnable and STENCIL_ALWAYS and STENCIL_EQUAL then
        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(255)
        render.SetStencilTestMask(255)
        render.SetStencilReferenceValue(1)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        DrawOTCRound(radius, 0, 0, w, h, Color(255, 255, 255))
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_KEEP)
        clipped = true
    end
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRectUV(0, 0, w, h, u0, v0, u0 + uw, v0 + vh)
    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(1, 4, 8, dim or 178)
    surface.DrawRect(0, 0, w, h)
    if clipped then render.SetStencilEnable(false) end
end
local unif4
local DrawItemIcon
local IsModelPreviewItem
local CreateModelPreview
local FindItemByPurchase
local FitTextToWidth
local DonateValue
local GetPurchaseAmount
local GetPurchaseRawAmount
local GetPurchaseDisplayPrice
local doMenu = function()
    if IsValid(unif4) then
        unif4:Remove()
        return
    end
    local size_x, size_y = math.min(ScrW(), 1600), math.min(ScrH(), 900)
    local title_background = Color(8, 18, 30)
    local main_background = Color(3, 5, 9, 252)
    local button_background = Color(9, 18, 30)
    local hover_color = Color(31, 182, 255)
    local ticket_color = hover_color
    local text_box_color = Color(6, 12, 20)
    local text_box_hover_color = Color(12, 22, 36)
    local scroll_grib_color = Color(31, 182, 255)
    local button_hover_border_size = 2
    local choised_menu_button
    unif4 = vgui.Create("drusher_gui")
    monteractF4.panel = unif4
    unif4.Title:SetHeight(44)
    unif4.Title.Paint = function(self, w, h)
        DrawOTCRound(10, 0, 0, w, h, title_background)
        local icon = monteract_materials.getByID("nuclear_gui")
        if icon then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(icon)
            surface.DrawTexturedRect(10, 7, 30, 30)
        end
        surface.SetFont("ticket_ui_title")
        local otW = select(1, surface.GetTextSize("OT-"))
        local brandW = otW + select(1, surface.GetTextSize("CITY"))
        draw.SimpleText("OT-", "ticket_ui_title", 46, h * 0.5, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("CITY", "ticket_ui_title", 46 + otW, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local sx = 46 + brandW + 16
        local sy = h * 0.5 - 1
        draw.NoTexture()
        surface.SetDrawColor(hover_color.r, hover_color.g, hover_color.b, 175)
        surface.DrawPoly({{x = sx + 6, y = sy}, {x = sx + 48, y = sy}, {x = sx + 42, y = sy + 3}, {x = sx, y = sy + 3}})
    end
    unif4.Title.CloseBtn:Remove()
    unif4.Title.CloseBtn = unif4.Title:Add("DButton")
    unif4.Title.CloseBtn:Dock(RIGHT)
    unif4.Title.CloseBtn:SetSize(30, 30)
    unif4.Title.CloseBtn:SetText("")
    unif4.Title.CloseBtn:SetCursor("hand")
    unif4.Title.CloseBtn:DockMargin(5, 7, 12, 7)
    unif4.Title.CloseBtn.HoverLerp = 0
    unif4.Title.CloseBtn.Paint = function(self, w, h)
        self.HoverLerp = Lerp(FrameTime() * 12, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        DrawOTCRound(10, 0, 0, w, h, Color(6 + self.HoverLerp * 6, 12 + self.HoverLerp * 10, 20 + self.HoverLerp * 16, 200 + self.HoverLerp * 45))
        if RNDX and isfunction(RNDX.DrawOutlined) then
            pcall(RNDX.DrawOutlined, 10, 0, 0, w, h, Color(hover_color.r, hover_color.g, hover_color.b, 110 + self.HoverLerp * 125), 2)
        end
        local col = Color(Lerp(self.HoverLerp, 235, hover_color.r), Lerp(self.HoverLerp, 240, hover_color.g), Lerp(self.HoverLerp, 248, hover_color.b), 245)
        draw.SimpleText("×", "donates_category_title", w * 0.5, h * 0.46, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    unif4.Title.CloseBtn.DoClick = function()
        unif4:Remove()
    end
    unif4:SizeCenter(size_x, size_y)
    unif4:SetBlur(true, 2)
    unif4.Paint = function(self, w, h)
        DrawOTBackground(self, w, h, 16, 182)
    end
    unif4.pages_button_list_panel = unif4:Add("DPanel")
    unif4.pages_button_list_panel:Dock(LEFT)
    unif4.pages_button_list_panel:SetWide(270)
    unif4.pages_button_list_panel.Paint = nil
    unif4.pages_button_list = unif4.pages_button_list_panel:Add("DScrollPanel")
    unif4.pages_button_list:Dock(FILL)
    unif4.pages_button_list:DockMargin(10, 10, 10, 0)
    unif4.pages_button_list:SetWide(270)
    unif4.promocodes = unif4.pages_button_list_panel:Add("DPanel")
    unif4.promocodes:Dock(BOTTOM)
    unif4.promocodes:SetHeight(50)
    unif4.promocodes:DockMargin(10, 5, 10, 5)
    unif4.promocodes.Paint = nil
    unif4.promocodes.text = unif4.promocodes:Add("DPanel")
    unif4.promocodes.text:Dock(TOP)
    unif4.promocodes.text:SetHeight(15)
    unif4.promocodes.text.Paint = function(self, w, h)
        draw.SimpleText("Промокоды:", "ticket_ui_title_little", 10, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    unif4.promocodes.TextEntry = unif4.promocodes:Add("DTextEntry")
    unif4.promocodes.TextEntry:Dock(FILL)
    unif4.promocodes.TextEntry:SetFont("ticket_ui_title_little")
    unif4.promocodes.TextEntry:SetDrawLanguageID(false)
    unif4.promocodes.TextEntry:SetMultiline(false)
    unif4.promocodes.TextEntry:DockMargin(5, 5, 5, 5)
    unif4.promocodes.TextEntry:SetValue("")
    unif4.promocodes.TextEntry:SetTextColor(Color(0, 0, 0))
    unif4.promocodes.TextEntry.OnEnter = function(self)
        netstream.Start("rk_promo_redeem", { code = self:GetText() })
    end
    unif4.promocodes.TextEntry.Paint = function(self, w, h)
        DrawOTCRound(4, 0, 0, w, h, title_background)
        if not self:IsEditing() and self:GetText() == "" then
            draw.SimpleText("Введите код", "ticket_ui_title_little", 5, h * 0.5, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 100), Color(255, 255, 255))
    end
    unif4.promocodes.enterbutton = unif4.promocodes:Add("DButton")
    unif4.promocodes.enterbutton:Dock(RIGHT)
    unif4.promocodes.enterbutton:DockMargin(0, 5, 5, 5)
    unif4.promocodes.enterbutton:SetText("")
    unif4.promocodes.enterbutton.Paint = function(self, w, h)
        DrawOTCRound(4, 0, 0, w, h, self:GetParent().TextEntry:GetText() == "" and title_background or hover_color)
        draw.SimpleText("Принять", "ticket_ui_title_little", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    unif4.promocodes.enterbutton.DoClick = function(self)
        netstream.Start("rk_promo_redeem", { code = self:GetParent().TextEntry:GetText() })
    end
    unif4.left_purchases = unif4.pages_button_list_panel:Add("DPanel")
    unif4.left_purchases:Dock(BOTTOM)
    unif4.left_purchases:SetHeight(math.Clamp(ScrH() * 0.30, 245, 310))
    unif4.left_purchases:DockMargin(10, 5, 10, 6)
    unif4.left_purchases.Paint = function(self, w, h)
        DrawOTCRound(10, 0, 0, w, h, Color(20, 28, 32, 238))
        draw.SimpleText("Последние покупки", "otc_donate_semibold_20", 10, 14, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("игроков OT-City", "otc_donate_medium_16", 10, 38, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    unif4.left_purchases.list = unif4.left_purchases:Add("DScrollPanel")
    unif4.left_purchases.list:Dock(FILL)
    unif4.left_purchases.list:DockMargin(8, 58, 8, 8)
    local lpbar = unif4.left_purchases.list:GetVBar()
    if IsValid(lpbar) then
        lpbar:SetWide(2)
        lpbar.Paint = nil
        lpbar.btnUp.Paint = nil
        lpbar.btnDown.Paint = nil
        lpbar.btnGrip.Paint = function(self, w, h) DrawOTCRound(4, 0, 0, w, h, hover_color) end
    end
    function unif4:RefreshLeftPurchases()
        if not IsValid(self.left_purchases) or not IsValid(self.left_purchases.list) then return end
        local list = self.left_purchases.list
        list:Clear()
        local purchases = RG_DonateMenu.Purchases or {}
        if #purchases < 1 then
            local empty = list:Add("DPanel")
            empty:Dock(TOP)
            empty:SetTall(34)
            empty.Paint = function(_, w, h)
                draw.SimpleText("Пока пусто", "ticket_ui_title_little", 6, h * 0.5, Color(190, 200, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return
        end
        local shown = 0
        for i = #purchases, 1, -1 do
            local e = purchases[i]
            if istable(e) then
                shown = shown + 1
                local row = list:Add("DPanel")
                row:Dock(TOP)
                row:SetTall(52)
                row:DockMargin(0, 0, 0, 6)
                local purchaseItem = BuildPurchaseVisualItem(e)
                local pic = row:Add("DPanel")
                pic:SetPos(7, 8)
                pic:SetSize(36, 36)
                pic.Paint = function(self, w, h)
                    DrawOTCRound(9, 0, 0, w, h, Color(18, 25, 28, 245))
                    if not (purchaseItem and IsModelPreviewItem(purchaseItem)) then
                        DrawItemIcon(purchaseItem or e, 4, 4, w - 8, h - 8, "✦")
                    end
                end
                if purchaseItem and IsModelPreviewItem(purchaseItem) then
                    local m = CreateModelPreview(pic, purchaseItem, false, false)
                    m:SetPos(1, 1)
                    m:SetSize(34, 34)
                    m:SetFOV(38)
                end
                row.Paint = function(self, w, h)
                    DrawOTCRound(10, 0, 0, w, h, self:IsHovered() and Color(28, 55, 68, 245) or Color(28, 35, 39, 235))
                    local price = GetPurchaseDisplayPrice(e)
                    local ts = tonumber(e.ts or e.time or 0) or 0
                    local dateText = ts > 0 and os.date("%d.%m", ts) or ""
                    surface.SetFont("otc_donate_medium_14")
                    local priceW = select(1, surface.GetTextSize(price)) + 10
                    local textMax = math.max(88, w - 54 - priceW)
                    local name = FitTextToWidth(tostring(e.name or e.buyer or "Игрок"), "otc_donate_medium_14", textMax)
                    local titleRaw = tostring(e.title or (purchaseItem and purchaseItem.title) or "Товар")
                    local title = FitTextToWidth(titleRaw, "otc_donate_medium_14", textMax)
                    draw.SimpleText(name, "otc_donate_medium_14", 52, 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(title, "otc_donate_medium_14", 52, 35, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(price, "otc_donate_medium_14", w - 8, 16, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    if dateText ~= "" then
                        draw.SimpleText(dateText, "otc_donate_medium_14", w - 8, 35, Color(175, 195, 205), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
    end
    unif4:RefreshLeftPurchases()
    local Scroll = unif4.pages_button_list:GetVBar()
    Scroll:SetSize(0, 0)
    Scroll.Paint = nil
    Scroll.btnUp.Paint = nil
    Scroll.btnDown.Paint = nil
    Scroll.btnGrip.Paint = nil
    unif4.menu = unif4:Add("EditablePanel")
    unif4.menu:Dock(FILL)
    unif4.menu:DockMargin(15, 10, 15, 15)
    unif4.add_menu = function(data)
        if not istable(data) then return end
        local menu_buttton = unif4.pages_button_list:Add("DButton")
        menu_buttton:SetText("")
        menu_buttton:Dock(TOP)
        menu_buttton:DockMargin(0, 0, 0, 15)
        menu_buttton:SetHeight(60)
        menu_buttton.DoClick = function(self)
            choised_menu_button = self
            if isfunction(self.func) then
                monteractF4.lastchoisedid = data.num
                local parent = self:GetParent()
                if not IsValid(parent) then return end
                local m_menu = unif4.menu
                if IsValid(m_menu) then
                    m_menu:Clear()
                    self.func(m_menu)
                end
            end
        end
        menu_buttton.name = data.name or "name"
        menu_buttton.desc = tostring(data.desc or "")
        menu_buttton.icon = data.icon or "monteract_logo"
        menu_buttton.func = data.func or function() end
        menu_buttton.custompaint = data.paint
        if not choised_menu_button and (data.num == monteractF4.lastchoisedid or (not monteractF4.menus[monteractF4.lastchoisedid] and data.num == 8)) then
            choised_menu_button = menu_buttton
            timer.Simple(0.1, function()
                if not IsValid(unif4) or not IsValid(menu_buttton) then return end
                unif4.menu:Clear()
                menu_buttton.func(unif4.menu)
            end)
        end
        menu_buttton.Paint = function(self, w, h)
            local choised = choised_menu_button == self
            local hover = self:IsHovered()
            local xx, yy = 0, 0
            local ww, hh = w, h
            if hover or choised then
                xx = 1
                yy = xx
                ww = ww - 2
                hh = hh - 2
                DrawOTCRound(5, 0, 0, w, h, hover_color)
            end
            DrawOTCRound(5, xx, yy, ww, hh, choised and Color(18, 45, 58) or button_background)
            local icon = monteract_materials.getByID(self.icon)
            if icon then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(12, h * 0.5 - 12, 24, 24)
            end
            local hasDesc = tostring(self.desc or "") ~= ""
            draw.SimpleText(self.name, "otc_donate_semibold_20", 48, hasDesc and 20 or h * 0.5, choised and hover_color or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if hasDesc then
                draw.SimpleText(self.desc, "otc_donate_medium_18", 48, h - 20, choised and hover_color or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            if isfunction(self.custompaint) then
                self.custompaint(self, w, h)
            end
        end
    end
    for k = 1, 30 do
        if istable(monteractF4.menus[k]) then
            unif4.add_menu(monteractF4.menus[k])
        end
    end
    timer.Simple(0.15, function()
        if not IsValid(unif4) or choised_menu_button then return end
        local first = monteractF4.menus[8]
        if istable(first) and isfunction(first.func) and IsValid(unif4.menu) then
            monteractF4.lastchoisedid = first.num
            first.func(unif4.menu)
        end
    end)
    return unif4
end
local function CloseDonateF4()
    local closed = false
    if IsValid(unif4) then
        unif4:Remove()
        closed = true
    end
    if IsValid(monteractF4.panel) then
        monteractF4.panel:Remove()
        closed = true
    end
    unif4 = nil
    monteractF4.panel = nil
    return closed
end
local function OpenDonateF4()
    if IsValid(unif4) then return unif4 end
    return doMenu()
end
local f4NextToggle = 0
local function ToggleDonateF4()
    local now = CurTime()
    if f4NextToggle > now then return end
    f4NextToggle = now + 0.2
    if IsValid(unif4) or IsValid(monteractF4.panel) then
        CloseDonateF4()
        return
    end
    OpenDonateF4()
end
monteractF4.openF4 = OpenDonateF4
monteractF4.closeF4 = CloseDonateF4
monteractF4.toggleF4 = ToggleDonateF4
hook.Remove("ShowSpare2", "monteract_custom_f4_toggle")
hook.Remove("PlayerButtonDown", "RG_DonateMenu_OpenF6")
hook.Remove("PlayerButtonDown", "monteract_custom_f4_key_toggle")
hook.Add("ShowSpare2", "monteract_custom_f4_toggle", function()
    ToggleDonateF4()
    return false
end)
hook.Add("PlayerButtonDown", "monteract_custom_f4_key_toggle", function(ply, button)
    if ply ~= LocalPlayer() then return end
    if button ~= KEY_F4 then return end
    ToggleDonateF4()
    return true
end)
hook.Add("ClientNetWorkReady", "loadf4", function(ply)
    timer.Simple(5, function()
        monteractF4.menus = {}
        timer.Simple(0, function()
            hook.Run("InitF4Menus")
        end)
    end)
end)
local doLoadMenu = function(panel, name, cb)
    if not IsValid(panel) then return end
    local the_menu = monteractF4.getMenuByName(name)
    if not istable(the_menu) then return end
    timer.Simple(0.2, function()
        if not IsValid(panel) then return end
        if not IsValid(panel.menu) then return end
        panel.menu:Clear()
        monteractF4.lastchoisedid = the_menu.num or monteractF4.lastchoisedid
        if isfunction(the_menu.func) then
            the_menu.func(panel.menu)
        end
        if isfunction(cb) then
            cb(panel.menu)
        end
    end)
end
monteractF4.openMenu = OpenDonateF4
monteractF4.loadMenu = doLoadMenu
concommand.Add("rk_donate_menu", function()
    ToggleDonateF4()
end)
concommand.Add("f4menu", function()
    ToggleDonateF4()
end)
RG_DonateMenu = RG_DonateMenu or {}
RG_DonateMenu.Balance = RG_DonateMenu.Balance or 0
RG_DonateMenu.TotalDonated = RG_DonateMenu.TotalDonated or 0
RG_DonateMenu.MemeRank = RG_DonateMenu.MemeRank or nil
RG_DonateMenu.Ranks = RG_DonateMenu.Ranks or {}
RG_DonateMenu.Items = RG_DonateMenu.Items or {}
RG_DonateMenu.Purchases = RG_DonateMenu.Purchases or {}
RG_DonateMenu.MyPurchases = RG_DonateMenu.MyPurchases or {}
RG_DonateMenu.Inventory = RG_DonateMenu.Inventory or {}
RG_DonateMenu.ActiveModel = RG_DonateMenu.ActiveModel or ""
RG_DonateMenu.CurrentCategory = RG_DonateMenu.CurrentCategory or nil
RG_DonateMenu.DonateURL = "https://monteract.ru/donate.html?server_id=otcity&steamid="
RG_DonateMenu.OTCoinAmount = RG_DonateMenu.OTCoinAmount or 1000
RG_DonateMenu.Discount = RG_DonateMenu.Discount or 0
local title_background = Color(8, 18, 30)
local main_background = Color(3, 5, 9, 252)
local button_background = Color(9, 18, 30)
local hover_color = Color(31, 182, 255)
local ticket_color = hover_color
local text_box_color = Color(6, 12, 20)
local text_box_hover_color = Color(8, 18, 30)
local scroll_grib_color = Color(31, 182, 255)
local button_hover_border_size = 2
local green_color = Color(31, 182, 255)
local red_color = Color(210, 72, 72)
local row_border = Color(18, 38, 60)
local color_white = Color(255, 255, 255)
local color_black = Color(0, 0, 0)
local OTC_DONATE_OTCOIN_SHOP = {
    minAmount = 100,
    maxAmount = 10000,
    step = 50,
    baseRate = 3,
    bonusStepCoins = 500,
    bonusPercentPerStep = 2,
    maxBonusPercent = 20
}
local function NormalizeOTCoinPurchaseAmount(amount)
    local cfg = OTC_DONATE_OTCOIN_SHOP
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then amount = cfg.minAmount end
    if amount < cfg.minAmount then amount = cfg.minAmount end
    if amount > cfg.maxAmount then amount = cfg.maxAmount end
    amount = math.floor(amount / cfg.step) * cfg.step
    if amount < cfg.minAmount then amount = cfg.minAmount end
    return amount
end
local function CalculateOTCoinPrice(amount)
    local cfg = OTC_DONATE_OTCOIN_SHOP
    amount = NormalizeOTCoinPurchaseAmount(amount)
    local bonusSteps = math.floor(amount / cfg.bonusStepCoins)
    local bonusPercent = math.min(cfg.maxBonusPercent, bonusSteps * cfg.bonusPercentPerStep)
    local effectiveRate = cfg.baseRate * (1 + bonusPercent / 100)
    local price = math.max(1, math.ceil(amount / effectiveRate))
    return price, bonusPercent, effectiveRate
end
local function GetClientOTCoinBalance()
    if AP and isfunction(AP.GetClientOTCoins) then
        local ok, bal = pcall(AP.GetClientOTCoins)
        if ok then return math.max(0, math.floor(tonumber(bal) or 0)) end
    end
    local lply = LocalPlayer()
    if IsValid(lply) and lply.GetMData then
        return math.max(0, math.floor(tonumber(lply:GetMData("hg_otcoins_balance", 0)) or 0))
    end
    return 0
end
local current_choise_menu
local nextpress = 0
surface.CreateFont("donates_category_title", {
    font = "Montserrat SemiBold",
    size = 34,
    weight = 600,
    extended = true
})
surface.CreateFont("donates_item_name", {
    font = "Montserrat SemiBold",
    size = 25,
    weight = 600,
    extended = true
})
surface.CreateFont("donates_balance", {
    font = "Montserrat Medium",
    size = 23,
    weight = 500,
    extended = true
})
surface.CreateFont("donates_item_desc", {
    font = "Montserrat Medium",
    size = 23,
    weight = 500,
    extended = true
})
surface.CreateFont("ticket_ui_title", {
    font = "Montserrat SemiBold",
    size = 21,
    weight = 600,
    extended = true
})
surface.CreateFont("ticket_ui_title_little", {
    font = "Montserrat Medium",
    size = 19,
    weight = 500,
    extended = true
})
surface.CreateFont("otc_donate_medium_18", {
    font = "Montserrat Medium",
    size = 20,
    weight = 500,
    extended = true
})
surface.CreateFont("otc_donate_medium_16", {
    font = "Montserrat Medium",
    size = 17,
    weight = 500,
    extended = true
})
surface.CreateFont("otc_donate_medium_14", {
    font = "Montserrat Medium",
    size = 14,
    weight = 500,
    extended = true
})
surface.CreateFont("otc_donate_medium_22", {
    font = "Montserrat Medium",
    size = 23,
    weight = 500,
    extended = true
})
surface.CreateFont("otc_donate_semibold_20", {
    font = "Montserrat SemiBold",
    size = 21,
    weight = 600,
    extended = true
})
surface.CreateFont("otc_donate_semibold_24", {
    font = "Montserrat SemiBold",
    size = 25,
    weight = 600,
    extended = true
})
surface.CreateFont("otc_donate_semibold_34", {
    font = "Montserrat SemiBold",
    size = 34,
    weight = 600,
    extended = true
})
local function DonateFormatMoney(n)
    if not n then return 0 end
    n = tonumber(n) or 0
    n = math.floor(n)
    if n >= 1e14 then return tostring(n) end
    n = tostring(n)
    local sep = ","
    local dp = string.find(n, "%.") or #n + 1
    for i = dp - 4, 1, -3 do
        n = n:sub(1, i) .. sep .. n:sub(i + 1)
    end
    return n
end
local function GetDonateDiscountPercent()
    local d = math.floor(tonumber(RG_DonateMenu and RG_DonateMenu.Discount or 0) or 0)
    if d < 0 then d = 0 end
    if d > 99 then d = 99 end
    return d
end
local function GetDonateDiscountedAmount(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local d = GetDonateDiscountPercent()
    if d <= 0 then return amount end
    return math.max(0, math.floor(amount * (100 - d) / 100 + 0.5))
end
local function DrawStrikeText(text, font, x, y, col, xalign, yalign)
    text = tostring(text)
    draw.SimpleText(text, font, x, y, col, xalign, yalign)
    surface.SetFont(font)
    local tw = select(1, surface.GetTextSize(text))
    local lx = x
    if xalign == TEXT_ALIGN_CENTER then lx = x - tw * 0.5
    elseif xalign == TEXT_ALIGN_RIGHT then lx = x - tw end
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.DrawRect(lx, math.floor(y) - 1, math.max(2, math.floor(tw)), 2)
    return tw
end
DonateValue = function(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            local raw = tostring(v or "")
            raw = string.Trim(raw)
            if raw ~= "" and raw ~= "nil" and raw ~= "NULL" and raw ~= "null" then
                raw = string.Replace(raw, "₽", "")
                raw = string.Replace(raw, "рублей", "")
                raw = string.Replace(raw, "рубля", "")
                raw = string.Replace(raw, "руб", "")
                raw = string.Replace(raw, "р.", "")
                raw = string.Replace(raw, " ", "")
                raw = string.Replace(raw, ",", ".")
                local n = tonumber(raw) or tonumber(string.match(raw, "%d+%.?%d*"))
                if n then return n end
            end
        end
    end
    return 0
end
GetPurchaseRawAmount = function(entry)
    if not istable(entry) then return 0 end
    return DonateValue(entry.amount, entry.cost, entry.price, entry.sum, entry.total, entry.rub, entry.value, entry.package_amount, entry.donate_amount, entry.money, entry.balance, entry.donate, entry.cost_text, entry.price_text, entry.amount_text, entry.payment, entry.paid, entry.pack_amount, entry.pack_price, entry.order_amount, entry.payment_amount, entry.purchase_amount, entry.paid_amount, entry.price_rub, entry.amount_rub, entry.cost_rub, entry.sum_rub, entry.sum_real, entry.sum_money, entry.item_price, entry.product_price, entry.product_amount, entry.item_amount, entry.pack_sum, entry.package_sum)
end
GetPurchaseAmount = function(entry)
    if not istable(entry) then return 0 end
    local amount = GetPurchaseRawAmount(entry)
    if amount > 0 then return amount end
    local item = FindItemByPurchase and FindItemByPurchase(entry) or nil
    if istable(item) then
        amount = DonateValue(item.amount, item.cost, item.price, item.sum, item.total, item.rub, item.value, item.package_amount, item.pack_amount, item.price_rub, item.amount_rub)
        if amount > 0 then return amount end
    end
    return 0
end
GetPurchaseDisplayPrice = function(entry)
    local amount = GetPurchaseAmount(entry)
    if amount <= 0 and istable(entry) then
        local item = BuildPurchaseVisualItem and BuildPurchaseVisualItem(entry) or nil
        if istable(item) then
            amount = DonateValue(item.amount, item.cost, item.price, item.sum, item.total, item.rub, item.value)
        end
    end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    return DonateFormatMoney(amount) .. " ₽"
end
local function DonateField(default, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            local raw = string.Trim(tostring(v or ""))
            local low = string.lower(raw)
            if raw ~= "" and low ~= "nil" and low ~= "null" and low ~= "none" then
                return raw
            end
        end
    end
    return default or ""
end
NormalizePurchaseEntry = function(entry)
    if not istable(entry) then return nil end
    local out = table.Copy(entry)
    local amount = math.max(0, math.floor(GetPurchaseAmount(out)))
    out.id = tonumber(out.id or out.purchase_id or 0) or out.id
    out.steamid64 = DonateField("", out.steamid64, out.steamid, out.sid64)
    out.amount = amount
    out.cost = amount
    out.price = amount
    out.title = DonateField("Товар", out.title, out.product, out.item, out.item_title, out.name_item, out.package_title, out.product_title, out.pack_title)
    out.name = DonateField("Игрок", out.name, out.buyer, out.nick, out.player, out.player_name)
    out.uid = DonateField("", out.uid, out.itemid, out.item_id, out.package_id, out.packageid)
    out.kind = DonateField("", out.kind, out.type, out.category)
    out.icon = DonateField("", out.icon, out.image, out.img, out.material)
    out.model = DonateField("", out.model, out.preview_model)
    out.preview_model = DonateField("", out.preview_model, out.model)
    out.ts = tonumber(out.ts or out.time or out.created or out.created_at_ts or out.date_ts or 0) or 0
    return out
end
local function DonatePurchaseKeys(entry)
    if not istable(entry) then return {} end
    local keys = {}
    local id = string.lower(string.Trim(tostring(entry.id or entry.purchase_id or entry.order_id or "")))
    local sid = string.lower(string.Trim(tostring(entry.steamid64 or entry.steamid or entry.sid64 or "")))
    local name = string.lower(string.Trim(tostring(entry.name or entry.buyer or entry.nick or entry.player or "")))
    local uid = string.lower(string.Trim(tostring(entry.uid or entry.itemid or entry.item_id or entry.package_id or entry.packageid or "")))
    local model = string.lower(string.Trim(tostring(entry.model or entry.preview_model or "")))
    local title = string.lower(string.Trim(tostring(entry.title or entry.product or entry.item or entry.name_item or "")))
    local amount = tostring(math.max(0, math.floor(GetPurchaseAmount(entry))))
    local ts = tostring(tonumber(entry.ts or entry.time or entry.created or entry.created_at_ts or entry.date_ts or 0) or 0)
    if id ~= "" and id ~= "nil" and id ~= "null" then keys[#keys + 1] = "id:" .. tostring(entry.source or "purchase") .. ":" .. id end
    if sid ~= "" and uid ~= "" and uid ~= "nil" and uid ~= "null" then keys[#keys + 1] = "siduid:" .. sid .. ":" .. uid .. ":" .. amount .. ":" .. ts end
    if sid ~= "" and model ~= "" and model ~= "nil" and model ~= "null" then keys[#keys + 1] = "sidmodel:" .. sid .. ":" .. model .. ":" .. amount .. ":" .. ts end
    if title ~= "" and title ~= "nil" and title ~= "null" then keys[#keys + 1] = "title:" .. sid .. ":" .. name .. ":" .. title .. ":" .. amount .. ":" .. ts end
    if #keys < 1 then keys[#keys + 1] = "raw:" .. sid .. ":" .. name .. ":" .. amount .. ":" .. ts .. ":" .. tostring(entry.source or "") end
    return keys
end
local function DonatePurchaseSeen(seen, entry)
    for _, k in ipairs(DonatePurchaseKeys(entry)) do
        if seen[k] then return true end
    end
    return false
end
local function DonateMarkPurchase(seen, entry)
    for _, k in ipairs(DonatePurchaseKeys(entry)) do
        seen[k] = true
    end
end
NormalizePurchaseList = function(items)
    local out = {}
    local seen = {}
    for _, entry in ipairs(items or {}) do
        local normalized = NormalizePurchaseEntry(entry)
        if normalized and not DonatePurchaseSeen(seen, normalized) then
            DonateMarkPurchase(seen, normalized)
            out[#out + 1] = normalized
        end
    end
    return out
end
local function DonateNotify(msg, typ, len)
    msg = tostring(msg or "")
    if msg == "" then return end
    typ = tonumber(typ or 0) or 0
    len = tonumber(len or 4) or 4
    if notification and isfunction(notification.AddLegacy) then
        notification.AddLegacy("[Донат] " .. msg, typ, len)
    else
        chat.AddText(typ == 1 and green_color or typ == 2 and red_color or hover_color, "[Донат] ", color_white, msg)
    end
    if surface and isfunction(surface.PlaySound) then
        surface.PlaySound(typ == 2 and "buttons/button10.wav" or "buttons/button15.wav")
    end
end
local function SafeDonateText(s)
    s = tostring(s or "")
    s = string.gsub(s, "[\n\r\t]", " ")
    return s
end
local function DonateAnnounce(data)
    if not istable(data) then return end
    local name = SafeDonateText(data.name or "Игрок")
    local amount = DonateFormatMoney(data.amount or 0)
    local rankName = SafeDonateText(data.rankName or "")
    local total = math.max(0, math.floor(tonumber(data.total or 0) or 0))
    chat.AddText(hover_color, "◤ OT-CITY ◢ ", Color(200, 237, 255), "┃ ", color_white, name, Color(200, 237, 255), " пополнил баланс на ", green_color, amount, Color(200, 237, 255), " ₽ ✦")
    if rankName ~= "" then
        chat.AddText(Color(200, 237, 255), "  У него теперь титул: ", green_color, rankName, Color(200, 237, 255), total > 0 and ("  •  всего " .. DonateFormatMoney(total) .. " ₽") or "")
    end
    chat.AddText(Color(90, 151, 180), "┌────────────────────────────────────────┐")
    chat.AddText(Color(200, 237, 255), "  Поддержи сервер — ", green_color, "/donate", Color(200, 237, 255), " или открой меню доната")
    chat.AddText(Color(90, 151, 180), "└────────────────────────────────────────┘")
    if data.isRecord then
        chat.AddText(green_color, "★ НОВЫЙ РЕКОРД МЕСЯЦА ★ ", color_white, amount, " ₽ — ", SafeDonateText(data.recordHolder or name))
    end
end
local function DonatePurchaseAnnounce(data)
    if not istable(data) then return end
    local name = SafeDonateText(data.name or "Игрок")
    local title = SafeDonateText(data.title or "Привилегия")
    local amount = DonateFormatMoney(data.amount or 0)
    chat.AddText(hover_color, "◤ OT-CITY ◢ ", Color(200, 237, 255), "┃ ", color_white, name, Color(200, 237, 255), " купил ", green_color, title, Color(200, 237, 255), " за ", green_color, amount, Color(200, 237, 255), " ₽ ✦")
    chat.AddText(Color(90, 151, 180), "┌────────────────────────────────────────┐")
    chat.AddText(Color(200, 237, 255), "  Будь таким же крутым — ", green_color, "/donate", Color(200, 237, 255), " или нажми ", green_color, "F4")
    chat.AddText(Color(90, 151, 180), "└────────────────────────────────────────┘")
end
FitTextToWidth = function(text, font, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(0, tonumber(maxWidth) or 0)
    surface.SetFont(font or "DermaDefault")
    if surface.GetTextSize(text) <= maxWidth then return text end
    local out = text
    while #out > 0 and surface.GetTextSize(out .. "...") > maxWidth do
        out = string.sub(out, 1, #out - 1)
    end
    if out == "" then return "..." end
    return out .. "..."
end
local function WrapTextLines(text, font, maxWidth, maxLines)
    text = tostring(text or "")
    maxWidth = math.max(1, tonumber(maxWidth) or 1)
    maxLines = math.max(1, math.floor(tonumber(maxLines) or 1))
    surface.SetFont(font or "DermaDefault")
    local words = string.Explode(" ", string.Trim(text), false)
    local lines = {}
    local line = ""
    for _, word in ipairs(words) do
        word = tostring(word or "")
        if word ~= "" then
            local test = line == "" and word or (line .. " " .. word)
            if surface.GetTextSize(test) <= maxWidth then
                line = test
            else
                if line ~= "" then
                    lines[#lines + 1] = line
                    line = word
                else
                    lines[#lines + 1] = FitTextToWidth(word, font, maxWidth)
                    line = ""
                end
                if #lines >= maxLines then break end
            end
        end
    end
    if line ~= "" and #lines < maxLines then
        lines[#lines + 1] = line
    end
    if #lines < 1 then lines[1] = "" end
    if #lines > maxLines then
        while #lines > maxLines do table.remove(lines) end
    end
    if #lines == maxLines then
        local joined = table.concat(words, " ")
        local visible = table.concat(lines, " ")
        if #visible < #joined then
            lines[#lines] = FitTextToWidth(lines[#lines], font, maxWidth)
        end
    end
    for i = 1, #lines do
        lines[i] = FitTextToWidth(lines[i], font, maxWidth)
    end
    return lines
end
local function FormatDuration(sec)
    sec = tonumber(sec) or 0
    sec = math.max(0, math.floor(sec))
    local days = math.floor(sec / 86400)
    if days >= 30 then
        local months = math.floor(days / 30)
        local left = days % 30
        if left > 0 then return months .. " мес. " .. left .. " д." end
        return months .. " мес."
    end
    if days > 0 then return days .. " д." end
    local hours = math.floor((sec % 86400) / 3600)
    if hours > 0 then return hours .. " ч." end
    return "навсегда"
end
local RankPackageIcons = {
    [149] = "https://monteract.ru/img/don2/vip.png",
    [349] = "https://monteract.ru/img/don2/vip.png",
    [549] = "https://monteract.ru/img/don2/dmod.png",
    [1299] = "https://monteract.ru/img/don2/dmod.png",
    [229] = "https://monteract.ru/img/don2/ss.png",
    [599] = "https://monteract.ru/img/don2/ss.png",
    [45] = "https://monteract.ru/img/don2/rtv.png",
    [899] = "https://monteract.ru/img/don2/oper.png",
    [1999] = "https://monteract.ru/img/don2/oper.png",
    [3499] = "https://monteract.ru/img/don2/sponsor.png",
    [4799] = "https://monteract.ru/img/don2/sponsor.png",
    [1800] = "https://monteract.ru/img/don2/model.png"
}
local url_icon_cache = url_icon_cache or {}
local url_icon_downloading = url_icon_downloading or {}
local url_icon_waiting = url_icon_waiting or {}
local function IsURL(str)
    str = tostring(str or "")
    return string.StartWith(str, "http://") or string.StartWith(str, "https://")
end
local function GetURLExt(body, url)
    body = tostring(body or "")
    url = tostring(url or "")
    if body:sub(1, 8) == "\137PNG\r\n\26\n" then return "png" end
    if body:sub(1, 3) == "\255\216\255" then return "jpg" end
    if body:sub(1, 4) == "RIFF" and body:sub(9, 12) == "WEBP" then return "webp" end
    local ext = string.match(url:lower(), "%.([%w]+)%??[^/]*$")
    if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then return ext end
    return "png"
end
local function URLToFileName(url, ext)
    ext = ext or "png"
    return "rg_donate_icons/" .. util.CRC(tostring(url or "")) .. "." .. ext
end
local function DataMaterial(path)
    if not path or path == "" then return nil end
    local mat = Material("../data/" .. path, "smooth noclamp")
    if not mat or mat:IsError() then return nil end
    return mat
end
local function RebuildDonateCatalog()
    timer.Simple(0, function()
        if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RebuildCatalog) then
            RG_DonateMenu.ActivePanel:RebuildCatalog()
        end
        if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RefreshProfileList) then
            RG_DonateMenu.ActivePanel:RefreshProfileList()
        end
    end)
end
local function SaveURLIcon(url, body)
    if not body or body == "" then return nil end
    if body:find("<html", 1, true) or body:find("<!DOCTYPE", 1, true) then return nil end
    file.CreateDir("rg_donate_icons")
    local ext = GetURLExt(body, url)
    local path = URLToFileName(url, ext)
    file.Write(path, body)
    local mat = DataMaterial(path)
    if not mat then
        file.Delete(path)
        return nil
    end
    return mat, path
end
local function FetchURLIcon(url)
    if url_icon_downloading[url] then return end
    url_icon_downloading[url] = true
    local urls = {url}
    if string.StartWith(url, "https://") then
        urls[#urls + 1] = "http://" .. string.sub(url, 9)
    end
    local index = 1
    local success
    local function fail(err)
        index = index + 1
        if urls[index] then
            http.Fetch(urls[index], success, fail)
            return
        end
        print("[RG Donate] Не удалось загрузить иконку:", url, err or "unknown")
        url_icon_downloading[url] = nil
    end
    success = function(body, len, headers, code)
        code = tonumber(code) or 200
        if code < 200 or code >= 300 then
            fail("HTTP " .. code)
            return
        end
        local mat = SaveURLIcon(url, body)
        if mat then
            url_icon_cache[url] = mat
            url_icon_downloading[url] = nil
            RebuildDonateCatalog()
            return
        end
        fail("bad image body")
    end
    http.Fetch(urls[index], success, fail)
end
local function GetMaterialByID(id)
    id = tostring(id or "")
    if id == "" then return nil end
    if IsURL(id) then
        if url_icon_cache[id] and not url_icon_cache[id]:IsError() then
            return url_icon_cache[id]
        end
        local exts = {"png", "jpg", "jpeg", "webp"}
        for _, ext in ipairs(exts) do
            local path = URLToFileName(id, ext)
            if file.Exists(path, "DATA") then
                local mat = DataMaterial(path)
                if mat then
                    url_icon_cache[id] = mat
                    return mat
                end
                file.Delete(path)
            end
        end
        FetchURLIcon(id)
        return nil
    end
    if monteract_materials and isfunction(monteract_materials.getByID) then
        local mat = monteract_materials.getByID(id)
        if mat and not mat:IsError() then return mat end
    end
    local mat = Material(id, "smooth noclamp")
    if not mat or mat:IsError() then return nil end
    return mat
end
RG_DonateMenu.GetIconMaterial = function(id)
    return GetMaterialByID(id)
end

local function DrawIcon(id, x, y, w, h, col)
    local icon = GetMaterialByID(id)
    if not icon then return false end
    surface.SetDrawColor(col or color_white)
    surface.SetMaterial(icon)
    local filtered = render and render.PushFilterMag and render.PushFilterMin and render.PopFilterMag and render.PopFilterMin and TEXFILTER and TEXFILTER.LINEAR
    if filtered then
        render.PushFilterMag(TEXFILTER.LINEAR)
        render.PushFilterMin(TEXFILTER.LINEAR)
    end
    surface.DrawTexturedRect(x, y, w, h)
    if filtered then
        render.PopFilterMin()
        render.PopFilterMag()
    end
    return true
end
local function BeginRoundedClip(radius, x, y, w, h)
    if not render or not render.SetStencilEnable or not STENCIL_ALWAYS or not STENCIL_EQUAL then return false end
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    DrawOTCRound(radius, x, y, w, h, color_white)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    return true
end
local function EndRoundedClip(active)
    if active and render and render.SetStencilEnable then
        render.SetStencilEnable(false)
    end
end
local function DrawRoundedItemPicture(item, radius, x, y, w, h, fallbackSymbol)
    DrawOTCRound(radius, x, y, w, h, Color(12, 17, 20, 245))
    local clipped = BeginRoundedClip(radius, x, y, w, h)
    DrawItemIcon(item, x, y, w, h, fallbackSymbol or "✦")
    EndRoundedClip(clipped)
end
local DrawSymbol
local GetItemAmount
DrawItemIcon = function(item, x, y, w, h, fallbackSymbol)
    local iconID = ""
    if istable(item) then
        iconID = tostring(item.icon or item.material or item.image or item.img or "")
        if iconID == "" then
            local amount = GetItemAmount(item)
            iconID = tostring(RankPackageIcons[amount] or "")
        end
    end
    if iconID ~= "" and DrawIcon(iconID, x, y, w, h, color_white) then return end
    DrawSymbol(fallbackSymbol or "✦", x, y, w, h, "donates_category_title", hover_color)
end
IsModelPreviewItem = function(item)
    if not istable(item) then return false end
    local kind = tostring(item.kind or "")
    return kind == "model" or kind == "accs" or tostring(item.model or item.preview_model or "") ~= ""
end
local function GetPlayerPreviewModel()
    local ply = LocalPlayer()
    if IsValid(ply) then
        local model = tostring(ply:GetModel() or "")
        if model ~= "" then return model end
    end
    return "models/player/group01/male_07.mdl"
end
local AccessoryPreviewModels = {}
local AccessorySearchCache = AccessorySearchCache or {}
local function TokenizeAccessory(item)
    local raw = string.lower(tostring(item and (item.uid or item.title or "") or ""))
    raw = string.Replace(raw, "armor", "armor vest rig plate бронежилет разгрузка")
    raw = string.Replace(raw, "mask", "mask helmet facecover маска")
    raw = string.Replace(raw, "knight", "knight")
    raw = string.Replace(raw, "tagilla", "tagilla")
    raw = string.Replace(raw, "zryachii", "zryachiy zryachii")
    raw = string.Replace(raw, "killa", "killa")
    raw = string.Replace(raw, "bigpipe", "bigpipe big_pipe")
    raw = string.Replace(raw, "black", "black")
    raw = string.Replace(raw, "exojump", "exo jump boots")
    local tokens = {}
    for token in string.gmatch(raw, "[%w_]+") do
        if #token >= 3 then tokens[#tokens + 1] = token end
    end
    return tokens
end
local function ModelLooksValid(path)
    path = tostring(path or "")
    if path == "" or not string.EndsWith(string.lower(path), ".mdl") then return false end
    if file and file.Exists and file.Exists(path, "GAME") then return true end
    if file and file.Exists and file.Exists(path, "MOD") then return true end
    if util and isfunction(util.IsValidModel) then return util.IsValidModel(path) end
    return true
end
local function ScoreModelPath(path, tokens)
    local lower = string.lower(tostring(path or ""))
    local score = 0
    for _, token in ipairs(tokens or {}) do
        if string.find(lower, token, 1, true) then score = score + 1 end
    end
    if string.find(lower, "models/player", 1, true) then score = score - 3 end
    if string.find(lower, "prop", 1, true) then score = score + 1 end
    if string.find(lower, "access", 1, true) or string.find(lower, "acc", 1, true) then score = score + 1 end
    if string.find(lower, "gear", 1, true) or string.find(lower, "clothes", 1, true) or string.find(lower, "armor", 1, true) then score = score + 1 end
    return score
end
local function ResolveClientAccessoryModel(item)
    if not istable(item) then return "" end
    local uid = tostring(item.uid or "")
    if uid == "" then return "" end
    if hg and hg.Accessories and istable(hg.Accessories[uid]) then
        local acc = hg.Accessories[uid]
        local values = {acc.model, acc.Model, acc.mdl, acc.MDL, acc.path, acc.Path, acc.WorldModel, acc.worldmodel, acc.modelPath, acc.ModelPath}
        for _, v in ipairs(values) do
            local mdl = tostring(v or "")
            if mdl ~= "" then return mdl end
        end
        if istable(acc.data) then
            local mdl = tostring(acc.data.model or acc.data.Model or acc.data.mdl or acc.data.path or "")
            if mdl ~= "" then return mdl end
        end
        if istable(acc.visual) then
            local mdl = tostring(acc.visual.model or acc.visual.Model or acc.visual.mdl or acc.visual.path or "")
            if mdl ~= "" then return mdl end
        end
    end
    return ""
end
local function RecursiveFindAccessoryModel(base, tokens, depth, state)
    if depth > 5 or state.checked > 7000 then return end
    local files, dirs = file.Find(base .. "*", "GAME")
    for _, name in ipairs(files or {}) do
        state.checked = state.checked + 1
        local path = base .. name
        if string.EndsWith(string.lower(path), ".mdl") then
            local score = ScoreModelPath(path, tokens)
            if score > state.score and ModelLooksValid(path) then
                state.score = score
                state.path = path
            end
        end
        if state.checked > 7000 then return end
    end
    table.sort(dirs or {}, function(a, b)
        local la = string.lower(a)
        local lb = string.lower(b)
        return ScoreModelPath(la, tokens) > ScoreModelPath(lb, tokens)
    end)
    for _, dir in ipairs(dirs or {}) do
        local dirLower = string.lower(dir)
        local worth = ScoreModelPath(dirLower, tokens) > 0 or depth < 2
        if worth then RecursiveFindAccessoryModel(base .. dir .. "/", tokens, depth + 1, state) end
        if state.checked > 7000 then return end
    end
end
local function FindAccessoryModel(item)
    if not istable(item) then return "" end
    local uid = tostring(item.uid or item.title or "")
    if AccessorySearchCache[uid] and AccessorySearchCache[uid] ~= "" then return AccessorySearchCache[uid] end
    local explicit = tostring(item.model or item.preview_model or AccessoryPreviewModels[uid] or "")
    if explicit ~= "" and not string.find(string.lower(explicit), "models/player", 1, true) then
        AccessorySearchCache[uid] = explicit
        return explicit
    end
    local hgModel = ResolveClientAccessoryModel(item)
    if hgModel ~= "" and not string.find(string.lower(hgModel), "models/player", 1, true) then
        AccessorySearchCache[uid] = hgModel
        return hgModel
    end
    local tokens = TokenizeAccessory(item)
    local state = { checked = 0, score = 1, path = "" }
    RecursiveFindAccessoryModel("models/", tokens, 0, state)
    if state.path and state.path ~= "" then
        AccessorySearchCache[uid] = state.path
        return state.path
    end
    return ""
end
local function GetPreviewModel(item)
    if not istable(item) then return GetPlayerPreviewModel() end
    local kind = tostring(item.kind or "")
    if kind == "accs" then
        local accModel = FindAccessoryModel(item)
        if accModel ~= "" then return accModel end
        local explicit = tostring(item.model or item.preview_model or "")
        if explicit ~= "" and not string.find(string.lower(explicit), "models/player", 1, true) then return explicit end
        return "models/error.mdl"
    end
    local model = tostring(item.model or item.preview_model or "")
    if model == "" then model = GetPlayerPreviewModel() end
    return model
end
local function ConfigurePreviewEntity(ent, item)
    if not IsValid(ent) or not istable(item) then return end
    ent:SetSkin(tonumber(item.skin or 0) or 0)
    if istable(item.bodygroups) then
        for k, v in pairs(item.bodygroups) do
            local id = tonumber(k)
            if not id and isstring(k) then id = ent:FindBodygroupByName(k) end
            if id and id >= 0 then ent:SetBodygroup(id, tonumber(v) or 0) end
        end
    elseif tostring(item.kind or "") == "accs" then
        local uid = string.lower(tostring(item.uid or ""))
        for _, bg in ipairs(ent:GetBodyGroups() or {}) do
            local name = string.lower(tostring(bg.name or ""))
            if name ~= "" and (string.find(uid, name, 1, true) or string.find(name, uid, 1, true)) then
                ent:SetBodygroup(bg.id or 0, math.max(1, tonumber(bg.num or 1) - 1))
            end
        end
    end
end
local function SetupModelPreview(panel, item, interactive, big)
    if not IsValid(panel) then return end
    local model = GetPreviewModel(item)
    panel:SetModel(model)
    panel.previewYaw = 25
    panel.previewZoom = big and 0.82 or 1
    panel.previewDrag = false
    panel:SetFOV(big and 26 or 36)
    panel:SetMouseInputEnabled(interactive == true)
    panel.itemData = item
    local function fit()
        if not IsValid(panel) or not IsValid(panel.Entity) then return end
        local ent = panel.Entity
        ConfigurePreviewEntity(ent, panel.itemData)
        local mn, mx = ent:GetRenderBounds()
        local center = (mn + mx) * 0.5
        local height = math.max(math.abs(mx.z - mn.z), 1)
        local width = math.max(math.abs(mx.x - mn.x), math.abs(mx.y - mn.y), 1)
        local size = math.max(height, width * 1.35, 24)
        local isAcc = istable(panel.itemData) and tostring(panel.itemData.kind or "") == "accs"
        panel.previewCenter = Vector(center.x, center.y, center.z + height * (isAcc and 0 or (big and 0.02 or 0.04)))
        panel.previewSize = size
        panel:SetLookAt(panel.previewCenter)
        panel:SetCamPos(panel.previewCenter + Vector(size * (isAcc and 1.6 or 1.35) * panel.previewZoom, size * 0.08 * panel.previewZoom, size * 0.08 * panel.previewZoom))
    end
    timer.Simple(0, fit)
    timer.Simple(0.15, fit)
    panel.LayoutEntity = function(self, ent)
        ConfigurePreviewEntity(ent, self.itemData)
        ent:SetAngles(Angle(0, self.previewYaw or 0, 0))
        if not self.previewCenter then fit() end
    end
    panel.OnMousePressed = function(self, key)
        if not interactive or key ~= MOUSE_LEFT then return end
        self.previewDrag = true
        self.previewMouseX = gui.MouseX()
        self:MouseCapture(true)
    end
    panel.OnMouseReleased = function(self)
        self.previewDrag = false
        self:MouseCapture(false)
    end
    panel.Think = function(self)
        if not interactive or not self.previewDrag then return end
        local mx = gui.MouseX()
        self.previewYaw = (self.previewYaw or 0) + (mx - (self.previewMouseX or mx)) * 0.5
        self.previewMouseX = mx
    end
    panel.OnMouseWheeled = function(self, delta)
        if not interactive then return end
        self.previewZoom = math.Clamp((self.previewZoom or 1) - delta * 0.08, 0.38, 2.4)
        fit()
    end
end
CreateModelPreview = function(parent, item, interactive, big)
    local mdl = parent:Add("DModelPanel")
    SetupModelPreview(mdl, item, interactive, big)
    return mdl
end
FindItemByPurchase = function(entry)
    if not istable(entry) then return nil end
    local ids = {entry.uid, entry.itemid, entry.item_id, entry.package_id, entry.packageid, entry.product_id, entry.pack_id}
    local entryTitle = string.lower(string.Trim(tostring(entry.title or entry.product or entry.item or entry.name_item or "")))
    local entryAmount = GetPurchaseRawAmount and GetPurchaseRawAmount(entry) or DonateValue(entry.amount, entry.cost, entry.price)
    for _, item in ipairs(RG_DonateMenu.Items or {}) do
        if istable(item) then
            for _, id in ipairs(ids) do
                local rawid = tostring(id or "")
                if rawid ~= "" and rawid ~= "nil" and rawid ~= "null" then
                    if tostring(item.uid or "") == rawid or tostring(item.itemid or "") == rawid or tostring(item.id or "") == rawid or tostring(item.package_id or "") == rawid then
                        return item
                    end
                end
            end
            local itemTitle = string.lower(string.Trim(tostring(item.title or item.name or "")))
            if itemTitle ~= "" and entryTitle ~= "" and itemTitle == entryTitle then return item end
        end
    end
    if entryAmount > 0 then
        for _, item in ipairs(RG_DonateMenu.Items or {}) do
            if istable(item) and math.floor(DonateValue(item.amount, item.cost, item.price, item.sum, item.total, item.rub, item.value)) == math.floor(entryAmount) then
                return item
            end
        end
    end
    return nil
end
BuildPurchaseVisualItem = function(entry)
    local item = FindItemByPurchase(entry)
    if item then return item end
    local amount = math.floor(GetPurchaseAmount(entry))
    local icon = tostring(RankPackageIcons[amount] or "")
    local model = tostring(entry and (entry.model or entry.preview_model) or "")
    local kind = tostring(entry and (entry.kind or entry.type or entry.category) or "")
    return {
        title = tostring(entry and (entry.title or entry.product or entry.item or entry.name) or "Товар"),
        name = tostring(entry and (entry.title or entry.product or entry.item or entry.name) or "Товар"),
        subtitle = tostring(entry and (entry.subtitle or entry.desc) or ""),
        amount = amount,
        cost = amount,
        price = amount,
        uid = tostring(entry and (entry.uid or entry.itemid or entry.item_id or entry.package_id) or ""),
        icon = icon,
        model = model,
        preview_model = model,
        kind = kind
    }
end
local function FindItemByInventory(entry)
    if not istable(entry) then return nil end
    local uid = tostring(entry.uid or "")
    local title = tostring(entry.title or "")
    local amount = tostring(entry.amount or "")
    for _, item in ipairs(RG_DonateMenu.Items or {}) do
        if istable(item) then
            if uid ~= "" and tostring(item.uid or item.itemid or item.id or item.package_id or item.amount or "") == uid then return item end
            if title ~= "" and tostring(item.title or item.name or "") == title then return item end
            if amount ~= "" and amount ~= "0" and tostring(item.amount or item.cost or "") == amount then return item end
        end
    end
    return entry
end
local function DrawDonatePreview(parent, item, x, y, w, h, fallbackSymbol, fov)
    if not IsValid(parent) then return nil end
    item = istable(item) and item or {}
    if IsModelPreviewItem(item) then
        local holder = parent:Add("DPanel")
        holder:SetPos(x, y)
        holder:SetSize(w, h)
        holder.Paint = function(self, pw, ph)
            DrawOTCRound(math.max(6, math.floor(math.min(pw, ph) * 0.18)), 0, 0, pw, ph, Color(12, 17, 20, 245))
        end
        local mdl = CreateModelPreview(holder, item, false, false)
        mdl:SetPos(1, 1)
        mdl:SetSize(math.max(1, w - 2), math.max(1, h - 2))
        mdl:SetFOV(fov or 34)
        return holder
    end
    local holder = parent:Add("DPanel")
    holder:SetPos(x, y)
    holder:SetSize(w, h)
    holder.Paint = function(self, pw, ph)
        DrawRoundedItemPicture(item, math.max(6, math.floor(math.min(pw, ph) * 0.18)), 0, 0, pw, ph, fallbackSymbol or "✦")
    end
    return holder
end
local function GetInventoryTitle(item)
    return tostring(item and (item.title or item.name) or "Предмет")
end
local function GetInventoryKind(item)
    return tostring(item and item.kind or "")
end
local function GetInventoryStatus(item)
    local status = tostring(item and item.status or "owned")
    local kind = GetInventoryKind(item)
    if kind == "model" and status == "active" then return "Включена" end
    if status == "active" then return "Активировано" end
    if status == "used" then return "Использовано" end
    return "В инвентаре"
end
local function CanActivateInventoryItem(item)
    if not istable(item) then return false end
    local kind = tostring(item.kind or "")
    local status = tostring(item.status or "owned")
    if status == "used" then return false end
    return kind == "model" or kind == "rank" or kind == "tts" or kind == "rtv_boost"
end
function DrawSymbol(symbol, x, y, w, h, font, col)
    draw.SimpleText(symbol or "✦", font or "donates_category_title", x + w * 0.5, y + h * 0.5, col or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
local function GetPlayedSeconds(ply)
    if not IsValid(ply) then return 0 end
    if isfunction(ply.GetUTimeTotalTime) then return tonumber(ply:GetUTimeTotalTime()) or 0 end
    if isfunction(ply.GetUTime) then return tonumber(ply:GetUTime()) or 0 end
    local keys = {"playtime", "played_time", "timeplayed", "total_time", "utime"}
    for _, key in ipairs(keys) do
        local value = tonumber(ply:GetNWInt(key, 0)) or 0
        if value > 0 then return value end
    end
    return 0
end
local function FormatPlayedTime(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local days = math.floor(sec / 86400)
    local hours = math.floor((sec % 86400) / 3600)
    local minutes = math.floor((sec % 3600) / 60)
    if days > 0 then return days .. " д. " .. hours .. " ч." end
    if hours > 0 then return hours .. " ч. " .. minutes .. " мин." end
    return minutes .. " мин."
end
local function OpenPersonalModelRewardWindow(data)
    if not istable(data) then return end
    RG_DonateMenu = RG_DonateMenu or {}
    if IsValid(RG_DonateMenu.PersonalModelWindow) then RG_DonateMenu.PersonalModelWindow:Remove() end
    local frame = vgui.Create("DFrame")
    RG_DonateMenu.PersonalModelWindow = frame
    frame:SetSize(620, 720)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:SetSizable(false)
    frame.Paint = function(self, w, h)
        if akychLib and akychLib.draw and akychLib.draw.drawBlur then akychLib.draw.drawBlur(self, 6) end
        DrawOTCRound(18, 0, 0, w, h, Color(18, 22, 24, 248))
        DrawOTCRound(16, 10, 10, w - 20, h - 20, Color(24, 32, 36, 245))
        draw.SimpleText("Личная модель получена", "otc_donate_semibold_34", w * 0.5, 28, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Для тебя выдали отдельную личную модель", "otc_donate_medium_18", w * 0.5, 74, Color(205, 218, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    local close = frame:Add("DButton")
    close:SetSize(34, 34)
    close:SetPos(frame:GetWide() - 50, 16)
    close:SetText("")
    close.Paint = function(self, w, h)
        DrawOTCRound(8, 0, 0, w, h, self:IsHovered() and Color(255, 120, 120) or Color(210, 82, 82))
        draw.SimpleText("×", "otc_donate_semibold_24", w * 0.5, h * 0.5 - 1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function()
        if IsValid(frame) then frame:Close() end
    end
    local previewWrap = frame:Add("DPanel")
    previewWrap:SetPos(24, 116)
    previewWrap:SetSize(572, 360)
    previewWrap.Paint = function(self, w, h)
        DrawOTCRound(16, 0, 0, w, h, Color(14, 19, 22, 245))
    end
    local preview = CreateModelPreview(previewWrap, data, true, true)
    preview:SetPos(8, 8)
    preview:SetSize(556, 344)
    preview:SetFOV(26)
    local title = frame:Add("DLabel")
    title:SetPos(28, 492)
    title:SetSize(564, 34)
    title:SetFont("otc_donate_semibold_24")
    title:SetTextColor(color_white)
    title:SetText(tostring(data.title or "Личная модель"))
    local subtitle = frame:Add("DLabel")
    subtitle:SetPos(28, 530)
    subtitle:SetSize(564, 52)
    subtitle:SetWrap(true)
    subtitle:SetAutoStretchVertical(true)
    subtitle:SetFont("otc_donate_medium_18")
    subtitle:SetTextColor(Color(205, 218, 225))
    subtitle:SetText(tostring(data.subtitle or "Личная модель добавлена в инвентарь."))
    local pathPanel = frame:Add("DPanel")
    pathPanel:SetPos(24, 588)
    pathPanel:SetSize(572, 54)
    pathPanel.Paint = function(self, w, h)
        DrawOTCRound(12, 0, 0, w, h, Color(12, 17, 20, 240))
        draw.SimpleText("Путь модели", "ticket_ui_title_little", 14, 10, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(FitTextToWidth(tostring(data.model or data.preview_model or ""), "otc_donate_medium_16", w - 28), "otc_donate_medium_16", 14, 30, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    local activate = frame:Add("DButton")
    activate:SetPos(24, 656)
    activate:SetSize(276, 42)
    activate:SetText("")
    activate.Paint = function(self, w, h)
        local active = tostring(data.status or "") == "active"
        local canUse = tonumber(data.id or 0) > 0 and not active
        local bg = active and hover_color or canUse and green_color or red_color
        DrawUnisonoButton(w, h, self:IsHovered() and canUse, bg, 8)
        draw.SimpleText(active and "Модель уже активна" or canUse and "Активировать" or "Предмет ещё обновляется", "ticket_ui_title_little", w * 0.5, h * 0.5, active and color_black or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    activate.DoClick = function(self)
        if self.lock then return end
        local id = tonumber(data.id or 0) or 0
        if id <= 0 then
            DonateNotify("Подожди пару секунд и попробуй снова.", 1, 4)
            netstream.Start("otc_donate_inventory_request", {})
            return
        end
        if tostring(data.status or "") == "active" then return end
        self.lock = true
        netstream.Start("otc_donate_activate", { id = id })
        timer.Simple(0.6, function()
            if IsValid(self) then self.lock = false end
            netstream.Start("otc_donate_inventory_request", {})
        end)
        if IsValid(frame) then frame:Close() end
    end
    local later = frame:Add("DButton")
    later:SetPos(320, 656)
    later:SetSize(276, 42)
    later:SetText("")
    later.Paint = function(self, w, h)
        DrawUnisonoButton(w, h, self:IsHovered(), Color(18, 38, 60), 8)
        draw.SimpleText("Закрыть", "ticket_ui_title_little", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    later.DoClick = function()
        if IsValid(frame) then frame:Close() end
    end
end
netstream.Hook("otc_donate_personal_model_popup", function(data)
    if not istable(data) then return end
    OpenPersonalModelRewardWindow(data)
end)
local DonateMemeRanks = {
    { amount = 0, name = "Без портфеля", color = Color(145, 152, 155) },
    { amount = 5, name = "Монетка под ковриком", color = Color(147, 154, 157) },
    { amount = 10, name = "Плюнул копейкой", color = Color(149, 156, 159) },
    { amount = 15, name = "Кассовый разведчик", color = Color(151, 158, 161) },
    { amount = 25, name = "Инвестор сухариков", color = Color(153, 160, 163) },
    { amount = 35, name = "Пакетик ликвидности", color = Color(155, 162, 165) },
    { amount = 50, name = "Дошик-инвестор", color = Color(157, 164, 167) },
    { amount = 75, name = "Чайный вкладчик", color = Color(159, 166, 170) },
    { amount = 100, name = "Купил себе уважение", color = Color(161, 168, 172) },
    { amount = 125, name = "Миноритарий шаурмы", color = Color(163, 170, 174) },
    { amount = 150, name = "Пивной акционер", color = Color(165, 172, 176) },
    { amount = 200, name = "Микро-меценат", color = Color(167, 174, 178) },
    { amount = 250, name = "Мамкин трейдер", color = Color(169, 176, 180) },
    { amount = 300, name = "Кэшбековый рыцарь", color = Color(171, 178, 182) },
    { amount = 400, name = "Бизнесмен с рынка", color = Color(173, 180, 184) },
    { amount = 500, name = "Хранитель ценных бумаг", color = Color(175, 182, 186) },
    { amount = 600, name = "Донатный скуф", color = Color(177, 184, 188) },
    { amount = 750, name = "Скупщик акций OT-City", color = Color(179, 186, 190) },
    { amount = 900, name = "Кошелёк проснулся", color = Color(181, 188, 192) },
    { amount = 1000, name = "Акционер подъезда", color = Color(183, 191, 195) },
    { amount = 1250, name = "Держатель зелёного пакета", color = Color(185, 193, 197) },
    { amount = 1500, name = "Спонсор парковки", color = Color(186, 195, 199) },
    { amount = 1750, name = "Шаурма-меценат", color = Color(188, 197, 201) },
    { amount = 2000, name = "Олигарх на минималках", color = Color(190, 199, 203) },
    { amount = 2250, name = "Биржевой хомяк", color = Color(192, 201, 205) },
    { amount = 2500, name = "Барон баланса", color = Color(194, 203, 207) },
    { amount = 2750, name = "Купонный аристократ", color = Color(196, 205, 209) },
    { amount = 3000, name = "Донатный магнат", color = Color(198, 207, 211) },
    { amount = 3500, name = "Купец зелёной кнопки", color = Color(200, 209, 213) },
    { amount = 4000, name = "Граф пополнений", color = Color(202, 211, 215) },
    { amount = 4500, name = "Лорд терминала", color = Color(204, 213, 217) },
    { amount = 5000, name = "Шейх с Авито", color = Color(206, 215, 219) },
    { amount = 5500, name = "Портфельный боярин", color = Color(208, 217, 222) },
    { amount = 6000, name = "Министр кошелька", color = Color(210, 219, 224) },
    { amount = 6500, name = "Дивидендный колдун", color = Color(212, 221, 226) },
    { amount = 7000, name = "Князь монетизации", color = Color(214, 223, 228) },
    { amount = 7500, name = "Фондовый шаман", color = Color(216, 225, 230) },
    { amount = 8000, name = "Повелитель кассы", color = Color(218, 227, 232) },
    { amount = 8500, name = "Серый кардинал банка", color = Color(220, 229, 234) },
    { amount = 9000, name = "Султан транзакций", color = Color(222, 231, 236) },
    { amount = 9500, name = "Директор банкомата", color = Color(224, 233, 238) },
    { amount = 10000, name = "Батя сервера", color = Color(226, 235, 240) },
    { amount = 11000, name = "Биржевой волк OT-City", color = Color(228, 237, 242) },
    { amount = 12000, name = "Донатный патриарх", color = Color(230, 239, 244) },
    { amount = 13000, name = "Контролёр пакета акций", color = Color(232, 241, 246) },
    { amount = 14000, name = "Легенда терминала", color = Color(234, 244, 249) },
    { amount = 15000, name = "Крупный акционер", color = Color(236, 246, 251) },
    { amount = 16000, name = "Император доната", color = Color(238, 248, 253) },
    { amount = 17000, name = "Золотой держатель", color = Color(240, 250, 255) },
    { amount = 18000, name = "Кибер-меценат", color = Color(241, 250, 254) },
    { amount = 19000, name = "Покупатель контрольного дошика", color = Color(238, 248, 253) },
    { amount = 20000, name = "Монетный архангел", color = Color(234, 246, 252) },
    { amount = 22500, name = "Владелец маленькой свечки", color = Color(231, 244, 250) },
    { amount = 25000, name = "Верховный акционер", color = Color(227, 242, 249) },
    { amount = 27500, name = "Дивидендный бармалей", color = Color(223, 240, 248) },
    { amount = 30000, name = "Главный акционер OT-City", color = Color(220, 238, 247) },
    { amount = 35000, name = "Капиталист на районе", color = Color(245, 246, 216) },
    { amount = 40000, name = "Казначей вселенной", color = Color(245, 245, 212) },
    { amount = 45000, name = "Нефтяной магнат без нефти", color = Color(246, 244, 209) },
    { amount = 50000, name = "Банкомат на максималках", color = Color(246, 242, 205) },
    { amount = 60000, name = "Король ликвидности", color = Color(247, 241, 201) },
    { amount = 70000, name = "Держатель контрольного пакета", color = Color(247, 240, 198) },
    { amount = 75000, name = "Денежный дракон", color = Color(248, 239, 194) },
    { amount = 85000, name = "Председатель совета доната", color = Color(249, 238, 190) },
    { amount = 100000, name = "Абсолютный донат-император", color = Color(249, 237, 187) },
    { amount = 125000, name = "Великий приватизатор OT-City", color = Color(250, 235, 183) },
    { amount = 150000, name = "Финансовый титан", color = Color(250, 234, 179) },
    { amount = 175000, name = "Генерал дивидендов", color = Color(251, 233, 176) },
    { amount = 200000, name = "Человек-IPO", color = Color(252, 232, 172) },
    { amount = 250000, name = "Хозяин биржевого стакана", color = Color(252, 231, 168) },
    { amount = 300000, name = "Легендарный держатель капитала", color = Color(253, 230, 165) },
    { amount = 400000, name = "Архонт зелёной свечи", color = Color(253, 228, 161) },
    { amount = 500000, name = "Монополист OT-City", color = Color(254, 227, 157) },
    { amount = 750000, name = "Владыка всех транзакций", color = Color(254, 226, 154) },
    { amount = 1000000, name = "Живой Центральный Банк", color = Color(255, 225, 150) }
}
RG_DonateMenu.FallbackRanks = DonateMemeRanks
RG_DonateMenu.Ranks = istable(RG_DonateMenu.Ranks) and #RG_DonateMenu.Ranks > 0 and RG_DonateMenu.Ranks or DonateMemeRanks
DonateMemeRanks = RG_DonateMenu.Ranks
local function NormalizeDonateRanks(items)
    local out = {}
    for _, data in ipairs(items or {}) do
        if istable(data) then
            local amount = math.max(0, math.floor(tonumber(data.amount) or 0))
            local name = tostring(data.name or data.title or "Титул")
            local c = data.color
            local col = hover_color
            if istable(c) then
                col = Color(math.Clamp(tonumber(c.r) or 255, 0, 255), math.Clamp(tonumber(c.g) or 255, 0, 255), math.Clamp(tonumber(c.b) or 255, 0, 255), math.Clamp(tonumber(c.a) or 255, 0, 255))
            end
            out[#out + 1] = { amount = amount, name = name, color = col }
        end
    end
    table.sort(out, function(a, b) return (a.amount or 0) < (b.amount or 0) end)
    if #out < 1 then out = RG_DonateMenu.FallbackRanks or {} end
    return out
end
local GetDonateMemeRank
local function ApplyDonateRanks(items)
    DonateMemeRanks = NormalizeDonateRanks(items)
    RG_DonateMenu.Ranks = DonateMemeRanks
    RG_DonateMenu.MemeRank = GetDonateMemeRank(RG_DonateMenu.TotalDonated or 0)
    if IsValid(RG_DonateMenu.ActivePanel) then
        RG_DonateMenu.ActivePanel:InvalidateLayout(true)
        if RG_DonateMenu.ActivePanel.RanksMode and isfunction(RG_DonateMenu.ActivePanel.LoadRanksPage) then RG_DonateMenu.ActivePanel:LoadRanksPage() end
    end
end
GetDonateMemeRank = function(total)
    total = math.max(0, math.floor(tonumber(total) or 0))
    local rank = DonateMemeRanks[1]
    for _, data in ipairs(DonateMemeRanks) do
        if total >= data.amount then rank = data end
    end
    return rank
end
local function GetNextDonateMemeRank(total)
    total = math.max(0, math.floor(tonumber(total) or 0))
    for _, data in ipairs(DonateMemeRanks) do
        if total < data.amount then return data end
    end
    return nil
end
local function PaintScroll(scroll)
    if not IsValid(scroll) then return end
    local sb = scroll:GetVBar()
    sb:SetWidth(2)
    sb.Paint = nil
    sb.btnUp.Paint = nil
    sb.btnDown.Paint = nil
    sb.btnGrip.Paint = function(self, w, h)
        DrawOTCRound(5, 0, 0, w, h, scroll_grib_color)
    end
end
local function DrawUnisonoButton(w, h, hover, background, radius)
    local xx, yy = 0, 0
    local ww, hh = w, h
    if hover then
        xx = button_hover_border_size * 0.5
        yy = xx
        ww = ww - button_hover_border_size
        hh = hh - button_hover_border_size
        DrawOTCRound(radius or 5, 0, 0, w, h, hover_color)
    end
    DrawOTCRound(radius or 5, xx, yy, ww, hh, background or button_background)
end
local function GetItemTitle(item)
    return tostring(item.title or item.name or "Товар")
end
local function GetItemDesc(item)
    return tostring(item.subtitle or item.desc or "Описание отсутствует...")
end
local DonateCategoryNames = {
    rank = "Привилегии",
    model = "Модели",
    accs = "Аксессуары",
    tts = "Говорилка",
    rtv_boost = "Голосование",
    otcoin = "OT-Coin"
}
local function GetItemCategory(item)
    local kind = tostring(item and item.kind or "")
    local category = tostring(item and item.category or "")
    if category ~= "" then return category end
    return DonateCategoryNames[kind] or "Прочее"
end
GetItemAmount = function(item)
    return math.max(0, math.floor(DonateValue(item.amount, item.cost, item.price, item.sum, item.total, item.rub, item.value)))
end
local function GroupItems(items)
    local groups = {}
    local order = {}
    for _, item in ipairs(items or {}) do
        if istable(item) then
            local category = GetItemCategory(item)
            if not groups[category] then
                groups[category] = {}
                order[#order + 1] = category
            end
            groups[category][#groups[category] + 1] = item
        end
    end
    table.sort(order, function(a, b)
        if a == "Привилегии" then return true end
        if b == "Привилегии" then return false end
        return tostring(a) < tostring(b)
    end)
    for _, category in ipairs(order) do
        table.sort(groups[category], function(a, b)
            return GetItemAmount(a) < GetItemAmount(b)
        end)
    end
    return order, groups
end
local function RequestDonateData()
    netstream.Start("otc_donate_ranks_request", {})
    netstream.Start("rk_balance_request")
    netstream.Start("rk_last_purchases_request")
    netstream.Start("otc_donate_my_purchases_request", {})
    netstream.Start("otc_donate_inventory_request", {})
end
timer.Simple(0.1, function()
hook.Add("InitPostEntity", "rg_donate_initial_data_request", function()
    timer.Simple(1, function() RequestDonateData() end)
end)
netstream.Hook("otc_donate_ranks_sync", function(data)
    if not istable(data) then return end
    ApplyDonateRanks(istable(data.items) and data.items or {})
end)
netstream.Hook("rk_balance_sync", function(data)
    if not istable(data) then return end
    RG_DonateMenu.Balance = math.max(0, math.floor(tonumber(data.balance) or 0))
    if data.total ~= nil then
        RG_DonateMenu.TotalDonated = math.max(0, math.floor(tonumber(data.total) or 0))
        RG_DonateMenu.MemeRank = GetDonateMemeRank(RG_DonateMenu.TotalDonated)
    end
    if IsValid(RG_DonateMenu.ActivePanel) then
        RG_DonateMenu.ActivePanel:InvalidateLayout(true)
        if RG_DonateMenu.ActivePanel.RanksMode and isfunction(RG_DonateMenu.ActivePanel.LoadRanksPage) then RG_DonateMenu.ActivePanel:LoadRanksPage() end
    end
end)
netstream.Hook("otc_donate_total_sync", function(data)
    if not istable(data) then return end
    RG_DonateMenu.TotalDonated = math.max(0, math.floor(tonumber(data.total) or 0))
    RG_DonateMenu.MemeRank = GetDonateMemeRank(RG_DonateMenu.TotalDonated)
    if IsValid(RG_DonateMenu.ActivePanel) then
        RG_DonateMenu.ActivePanel:InvalidateLayout(true)
        if RG_DonateMenu.ActivePanel.RanksMode and isfunction(RG_DonateMenu.ActivePanel.LoadRanksPage) then RG_DonateMenu.ActivePanel:LoadRanksPage() end
    end
end)
netstream.Hook("rk_donate_discount_sync", function(data)
    local p = math.floor(tonumber(istable(data) and data.percent or 0) or 0)
    if p < 0 then p = 0 end
    if p > 99 then p = 99 end
    RG_DonateMenu.Discount = p
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RebuildCatalog) and not RG_DonateMenu.ActivePanel.ProfileMode then
        RG_DonateMenu.ActivePanel:RebuildCatalog()
    end
    if IsValid(monteractF4.panel) and isfunction(monteractF4.panel.RefreshLeftPurchases) then monteractF4.panel:RefreshLeftPurchases() end
end)
netstream.Hook("rk_items_sync", function(data)
    if not istable(data) then return end
    RG_DonateMenu.Items = istable(data.items) and data.items or {}
    if not RG_DonateMenu.CurrentCategory then
        local order = GroupItems(RG_DonateMenu.Items)
        RG_DonateMenu.CurrentCategory = order[1]
        current_choise_menu = order[1]
    end
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RebuildCatalog) and not RG_DonateMenu.ActivePanel.ProfileMode then
        RG_DonateMenu.ActivePanel:RebuildCatalog()
    end
    if IsValid(monteractF4.panel) and isfunction(monteractF4.panel.RefreshLeftPurchases) then monteractF4.panel:RefreshLeftPurchases() end
end)
netstream.Hook("rk_last_purchases_sync", function(data)
    if not istable(data) then return end
    local incoming = NormalizePurchaseList(istable(data.items) and data.items or {})
    if #incoming > 0 or #RG_DonateMenu.Purchases < 1 then
        RG_DonateMenu.Purchases = incoming
    end
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RefreshProfileList) then
        RG_DonateMenu.ActivePanel:RefreshProfileList()
    end
    if IsValid(monteractF4.panel) and isfunction(monteractF4.panel.RefreshLeftPurchases) then monteractF4.panel:RefreshLeftPurchases() end
end)
netstream.Hook("rk_last_purchases_push", function(data)
    if not istable(data) then return end
    local normalized = NormalizePurchaseEntry(data)
    if not normalized then return end
    local seen = {}
    for _, entry in ipairs(RG_DonateMenu.Purchases or {}) do
        DonateMarkPurchase(seen, entry)
    end
    if not DonatePurchaseSeen(seen, normalized) then
        RG_DonateMenu.Purchases[#RG_DonateMenu.Purchases + 1] = normalized
    end
    while #RG_DonateMenu.Purchases > 25 do table.remove(RG_DonateMenu.Purchases, 1) end
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RefreshProfileList) then
        RG_DonateMenu.ActivePanel:RefreshProfileList()
    end
    if IsValid(monteractF4.panel) and isfunction(monteractF4.panel.RefreshLeftPurchases) then monteractF4.panel:RefreshLeftPurchases() end
end)
netstream.Hook("otc_donate_my_purchases_sync", function(data)
    if not istable(data) then return end
    RG_DonateMenu.MyPurchases = NormalizePurchaseList(istable(data.items) and data.items or {})
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RefreshProfileList) then
        RG_DonateMenu.ActivePanel:RefreshProfileList()
    end
end)
netstream.Hook("otc_donate_inventory_sync", function(data)
    if not istable(data) then return end
    RG_DonateMenu.Inventory = istable(data.items) and data.items or {}
    RG_DonateMenu.ActiveModel = tostring(data.activeModel or "")
    if IsValid(RG_DonateMenu.ActivePanel) and isfunction(RG_DonateMenu.ActivePanel.RefreshProfileList) then
        RG_DonateMenu.ActivePanel:RefreshProfileList()
    end
end)
netstream.Hook("rk_promo_result", function(data)
    if not istable(data) then return end
    if data.balance ~= nil then
        RG_DonateMenu.Balance = math.max(0, math.floor(tonumber(data.balance) or 0))
    end
    DonateNotify(tostring(data.msg or ""), data.ok and 0 or 1, 4)
    if IsValid(RG_DonateMenu.ActivePanel) then RG_DonateMenu.ActivePanel:InvalidateLayout(true) end
end)
netstream.Hook("otc_donate_notify", function(data)
    if not istable(data) then return end
    DonateNotify(data.msg or "", data.type or 0, data.len or 4)
end)
netstream.Hook("rk_donate_announce", DonateAnnounce)
netstream.Hook("rk_donate_purchase_announce", DonatePurchaseAnnounce)
end)
local DonateMenuButtons = {
    {num = 8, name = "Привилегии", desc = "", icon = "f4_donate"},
    {num = 9, name = "Модели", desc = "", icon = "f4_donate"},
    {num = 10, name = "Аксессуары", desc = "", icon = "f4_donate"},
    {num = 12, name = "Говорилка", desc = "", icon = "f4_donate"},
    {num = 13, name = "Голосование", desc = "", icon = "f4_donate"},
    {num = 14, name = "OT-Coin", desc = "", icon = "f4_donate"}
}
local function OpenDonateOTCoin(unif4)
    timer.Simple(0.05, function()
        RequestDonateData()
        if AP and isfunction(AP.RefreshOTCoinCache) then AP.RefreshOTCoinCache() end
    end)
    local main = unif4:Add("DPanel")
    main:Dock(FILL)
    main.Paint = nil
    RG_DonateMenu.ActivePanel = main
    main.OnRemove = function()
        if RG_DonateMenu.ActivePanel == main then RG_DonateMenu.ActivePanel = nil end
    end
    local selectedAmount = NormalizeOTCoinPurchaseAmount(RG_DonateMenu.OTCoinAmount or 1000)
    local function SetSelectedAmount(value)
        selectedAmount = NormalizeOTCoinPurchaseAmount(value)
        RG_DonateMenu.OTCoinAmount = selectedAmount
        if IsValid(main.amountSlider) then
            main.amountSlider:SetValue(selectedAmount)
        end
        if IsValid(main.amountEntry) then
            main.amountEntry:SetValue(selectedAmount)
        end
        main:InvalidateLayout(true)
    end
    main.header = main:Add("DPanel")
    main.header:Dock(TOP)
    main.header:SetTall(110)
    main.header:DockMargin(10, 10, 10, 10)
    main.header.Paint = function(self, w, h)
        DrawOTCRound(16, 0, 0, w, h, Color(20, 28, 32, 238))
        draw.SimpleText("Покупка OT-Coin", "otc_donate_semibold_34", 18, 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Выбирай сумму монет — цена считается автоматически по объёму пакета.", "otc_donate_medium_18", 18, 58, Color(205, 218, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Баланс доната: " .. DonateFormatMoney(RG_DonateMenu.Balance) .. " ₽", "ticket_ui_title_little", w - 18, 20, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("Баланс OT-Coin: " .. DonateFormatMoney(GetClientOTCoinBalance()), "ticket_ui_title_little", w - 18, 54, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
    main.body = main:Add("DScrollPanel")
    main.body:Dock(FILL)
    main.body:DockMargin(10, 0, 10, 10)
    PaintScroll(main.body)
    local info = main.body:Add("DPanel")
    info:Dock(TOP)
    info:SetTall(56)
    info:DockMargin(0, 0, 0, 10)
    info.Paint = function(self, w, h)
        DrawOTCRound(12, 0, 0, w, h, Color(24, 37, 44, 235))
        draw.SimpleText("Чем больше пакет, тем выгоднее курс. Малые пакеты без диких скидок, крупные — с умеренным бонусом.", "otc_donate_medium_16", 16, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local controls = main.body:Add("DPanel")
    controls:Dock(TOP)
    controls:SetTall(150)
    controls:DockMargin(0, 0, 0, 12)
    controls.Paint = function(self, w, h)
        DrawOTCRound(14, 0, 0, w, h, button_background)
        draw.SimpleText("Количество OT-Coin", "otc_donate_semibold_24", 16, 12, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("От 100 до 10 000 монет, шаг 50", "otc_donate_medium_16", 16, 48, Color(205, 218, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    main.amountSlider = controls:Add("DNumSlider")
    main.amountSlider:SetPos(14, 70)
    main.amountSlider:SetSize(700, 32)
    main.amountSlider:SetText("")
    main.amountSlider:SetMin(OTC_DONATE_OTCOIN_SHOP.minAmount)
    main.amountSlider:SetMax(OTC_DONATE_OTCOIN_SHOP.maxAmount)
    main.amountSlider:SetDecimals(0)
    main.amountSlider:SetValue(selectedAmount)
    main.amountSlider.OnValueChanged = function(_, val)
        local normalized = NormalizeOTCoinPurchaseAmount(val)
        if normalized ~= selectedAmount then
            selectedAmount = normalized
            RG_DonateMenu.OTCoinAmount = normalized
            if IsValid(main.amountEntry) and tonumber(main.amountEntry:GetValue()) ~= normalized then
                main.amountEntry:SetValue(normalized)
            end
            main:InvalidateLayout(true)
        end
    end
    if IsValid(main.amountSlider.Slider) and IsValid(main.amountSlider.Slider.Knob) then
        main.amountSlider.Slider.Paint = function(self, w, h)
            DrawOTCRound(6, 0, h * 0.5 - 4, w, 8, Color(45, 73, 86, 210))
        end
        main.amountSlider.Slider.Knob.Paint = function(self, w, h)
            DrawOTCRound(8, 0, 0, w, h, hover_color)
        end
    end
    if IsValid(main.amountSlider.TextArea) then
        main.amountSlider.TextArea:SetVisible(false)
    end
    main.amountEntry = controls:Add("DNumberWang")
    main.amountEntry:SetPos(730, 70)
    main.amountEntry:SetSize(130, 34)
    main.amountEntry:SetMinMax(OTC_DONATE_OTCOIN_SHOP.minAmount, OTC_DONATE_OTCOIN_SHOP.maxAmount)
    main.amountEntry:SetDecimals(0)
    main.amountEntry:SetValue(selectedAmount)
    main.amountEntry.OnValueChanged = function(_, val)
        local normalized = NormalizeOTCoinPurchaseAmount(val)
        if normalized ~= selectedAmount then
            selectedAmount = normalized
            RG_DonateMenu.OTCoinAmount = normalized
            if IsValid(main.amountSlider) then
                main.amountSlider:SetValue(normalized)
            end
            main:InvalidateLayout(true)
        end
    end
    local presets = {250, 500, 1000, 2500, 5000}
    local presetWrap = controls:Add("DPanel")
    presetWrap:SetPos(14, 108)
    presetWrap:SetSize(860, 32)
    presetWrap.Paint = nil
    for i, preset in ipairs(presets) do
        local btn = presetWrap:Add("DButton")
        btn:SetPos((i - 1) * 148, 0)
        btn:SetSize(138, 32)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local active = selectedAmount == preset
            DrawUnisonoButton(w, h, self:IsHovered() and not active, active and hover_color or green_color, 6)
            draw.SimpleText(tostring(preset), "ticket_ui_title_little", w * 0.5, h * 0.5, active and color_black or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            SetSelectedAmount(preset)
        end
    end
    local summary = main.body:Add("DPanel")
    summary:Dock(TOP)
    summary:SetTall(178)
    summary:DockMargin(0, 0, 0, 12)
    summary.Paint = function(self, w, h)
        local price, bonusPercent, effectiveRate = CalculateOTCoinPrice(selectedAmount)
        local balanceAfter = GetClientOTCoinBalance() + selectedAmount
        DrawOTCRound(14, 0, 0, w, h, Color(18, 25, 28, 245))
        draw.SimpleText("Итог покупки", "otc_donate_semibold_24", 16, 14, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Вы получите", "otc_donate_medium_18", 20, 58, Color(205, 218, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(DonateFormatMoney(selectedAmount) .. " OT-Coin", "otc_donate_semibold_24", 210, 58, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Цена", "otc_donate_medium_18", 20, 92, Color(205, 218, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(DonateFormatMoney(price) .. " ₽", "otc_donate_semibold_24", 210, 92, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Бонус к курсу", "otc_donate_medium_18", 20, 126, Color(205, 218, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("+" .. tostring(bonusPercent) .. "%", "otc_donate_semibold_24", 210, 126, bonusPercent > 0 and hover_color or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Эффективный курс: 1 ₽ ≈ " .. string.format("%.2f", effectiveRate) .. " OT-Coin", "ticket_ui_title_little", w - 16, 58, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText("После покупки будет: " .. DonateFormatMoney(balanceAfter) .. " OT-Coin", "ticket_ui_title_little", w - 16, 92, Color(205, 218, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Чем больше пакет, тем выше бонус, но без жёсткого демпинга.", "ticket_ui_title_little", w - 16, 126, Color(175, 195, 205), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    local buyButton = main.body:Add("DButton")
    buyButton:Dock(TOP)
    buyButton:SetTall(48)
    buyButton:DockMargin(0, 0, 0, 12)
    buyButton:SetText("")
    buyButton.Paint = function(self, w, h)
        local price = CalculateOTCoinPrice(selectedAmount)
        local canBuy = RG_DonateMenu.Balance >= price
        DrawUnisonoButton(w, h, self:IsHovered() and canBuy, canBuy and green_color or red_color, 8)
        draw.SimpleText(canBuy and ("Купить " .. DonateFormatMoney(selectedAmount) .. " OT-Coin за " .. DonateFormatMoney(price) .. " ₽") or ("Недостаточно средств • нужно " .. DonateFormatMoney(price) .. " ₽"), canBuy and "otc_donate_medium_22" or "ticket_ui_title_little", w * 0.5, h * 0.5, canBuy and color_black or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    buyButton.DoClick = function(self)
        if self.lock then return end
        local price = CalculateOTCoinPrice(selectedAmount)
        if RG_DonateMenu.Balance < price then
            DonateNotify("Недостаточно средств на балансе доната.", 1, 4)
            return
        end
        self.lock = true
        netstream.Start("otc_donate_buy_otcoins", { amount = selectedAmount })
        timer.Simple(0.8, function()
            if IsValid(self) then self.lock = false end
            if AP and isfunction(AP.RefreshOTCoinCache) then AP.RefreshOTCoinCache() end
            RequestDonateData()
        end)
    end
    local donateMore = main.body:Add("DButton")
    donateMore:Dock(TOP)
    donateMore:SetTall(42)
    donateMore:DockMargin(0, 0, 0, 12)
    donateMore:SetText("")
    donateMore.Paint = function(self, w, h)
        DrawUnisonoButton(w, h, self:IsHovered(), Color(18, 38, 60), 8)
        draw.SimpleText("Пополнить баланс доната", "ticket_ui_title_little", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    donateMore.DoClick = function()
        gui.OpenURL(RG_DonateMenu.DonateURL .. LocalPlayer():SteamID64())
    end
    SetSelectedAmount(selectedAmount)
end
local function OpenDonateCategory(unif4, forcedCategory)
    if forcedCategory and forcedCategory ~= "" then
        RG_DonateMenu.CurrentCategory = forcedCategory
        current_choise_menu = forcedCategory
    end
            timer.Simple(0.1, function()
            RequestDonateData()
            end)
            local main = unif4:Add("DPanel")
            main:Dock(FILL)
            main.Paint = nil
            RG_DonateMenu.ActivePanel = main
            local profile_choise
            local profile_mode = false
            main.ProfileMode = false
            local profile_list_panel
            local active_profile_loader
            main.OnRemove = function()
                if RG_DonateMenu.ActivePanel == main then RG_DonateMenu.ActivePanel = nil end
            end
            function main:CreateEmpty(panel, text)
                if not IsValid(panel) then return end
                panel:Clear()
                local noitems = panel:Add("DPanel")
                noitems:SetPos(10, 10)
                noitems:SetSize(350, 30)
                noitems.Paint = function(self, w, h)
                    draw.SimpleText(text, "donates_item_name", 0, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            function main:LoadMyPurchasesList(panel)
                if not IsValid(panel) then return end
                panel:Clear()
                local list = RG_DonateMenu.MyPurchases or {}
                if #list < 1 then
                    self:CreateEmpty(panel, "Покупок за всё время пока нет.")
                    return
                end
                local scroll = panel:Add("DScrollPanel")
                scroll:Dock(FILL)
                PaintScroll(scroll)
                for i = 1, #list do
                    local inv = list[i]
                    if not istable(inv) then continue end
                    local visualItem = BuildPurchaseVisualItem(inv)
                    local row = scroll:Add("DPanel")
                    row:Dock(TOP)
                    row:SetHeight(68)
                    row:DockMargin(5, 0, 5, 7)
                    row.Paint = function(self, w, h)
                        local hover = self:IsHovered()
                        DrawOTCRound(10, 0, 0, w, h, hover and Color(38, 151, 205, 230) or Color(45, 73, 86, 210))
                        DrawOTCRound(10, 1, 1, w - 2, h - 2, hover and Color(24, 44, 54, 245) or Color(24, 37, 44, 245))
                        local amount = GetPurchaseDisplayPrice(inv)
                        local ts = tonumber(inv.ts or inv.time or 0) or 0
                        local dateText = ts > 0 and os.date("%d.%m.%Y  %H:%M", ts) or "дата неизвестна"
                        draw.SimpleText(amount, "ticket_ui_title_little", w - 14, 18, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(dateText, "otc_donate_medium_14", w - 14, h - 18, Color(185, 202, 210), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                    local iconpanel = row:Add("DPanel")
                    iconpanel:SetPos(8, 8)
                    iconpanel:SetSize(52, 52)
                    iconpanel.Paint = function(self, w, h)
                        DrawOTCRound(9, 0, 0, w, h, Color(12, 17, 20, 245))
                        if not (visualItem and IsModelPreviewItem(visualItem)) then
                            DrawItemIcon(visualItem or inv, 5, 5, w - 10, h - 10, "✦")
                        end
                    end
                    if visualItem and IsModelPreviewItem(visualItem) then
                        local m = CreateModelPreview(iconpanel, visualItem, false, false)
                        m:SetPos(1, 1)
                        m:SetSize(50, 50)
                        m:SetFOV(34)
                    end
                    local datapanel = row:Add("DPanel")
                    datapanel:Dock(FILL)
                    datapanel:DockMargin(70, 8, 205, 8)
                    datapanel.Paint = function(self, w, h)
                        local title = FitTextToWidth(tostring(inv.title or (visualItem and visualItem.title) or "Товар"), "otc_donate_semibold_20", w)
                        local kind = tostring(inv.kind or (visualItem and visualItem.kind) or "")
                        local status = kind ~= "" and kind or "покупка"
                        draw.SimpleText(title, "otc_donate_semibold_20", 0, 4, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("Ваш товар • " .. status, "otc_donate_medium_14", 0, h - 2, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                    end
                end
            end
            function main:LoadInventory(panel)
                if not IsValid(panel) then return end
                panel:Clear()
                local list = RG_DonateMenu.Inventory or {}
                if #list < 1 then
                    self:CreateEmpty(panel, "У вас нет предметов.")
                    return
                end
                local scroll = panel:Add("DScrollPanel")
                scroll:Dock(FILL)
                PaintScroll(scroll)
                for _, inv in ipairs(list) do
                    if not istable(inv) then continue end
                    local row = scroll:Add("DPanel")
                    row:Dock(TOP)
                    row:SetHeight(70)
                    row:DockMargin(5, 5, 5, 5)
                    row.Paint = function(self, w, h)
                        local hover = self:IsHovered()
                        local xx = button_hover_border_size * 0.5
                        local yy = xx
                        DrawOTCRound(5, 0, 0, w, h, hover and hover_color or row_border)
                        DrawOTCRound(5, xx, yy, w - button_hover_border_size, h - button_hover_border_size, button_background)
                    end
                    local invVisual = FindItemByInventory(inv) or inv
                    local iconwrap = row:Add("DPanel")
                    iconwrap:Dock(LEFT)
                    iconwrap:SetWide(60)
                    iconwrap:DockMargin(5, 5, 5, 5)
                    iconwrap.Paint = nil
                    timer.Simple(0, function()
                        if IsValid(iconwrap) then
                            DrawDonatePreview(iconwrap, invVisual, 0, 0, 60, 60, "✦", 34)
                        end
                    end)
                    local datapanel = row:Add("DPanel")
                    datapanel:Dock(FILL)
                    datapanel:DockMargin(5, 5, 5, 5)
                    datapanel.Paint = function(self, w, h)
                        draw.SimpleText(GetInventoryTitle(inv), "donates_item_name", 0, 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText(GetInventoryStatus(inv), "ticket_ui_title_little", 0, h - 3, tostring(inv.status or "") == "active" and hover_color or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                    end
                    local kind = tostring(inv.kind or "")
                    local status = tostring(inv.status or "owned")
                    if CanActivateInventoryItem(inv) then
                        local btn = row:Add("DButton")
                        btn:Dock(RIGHT)
                        btn:SetWide(150)
                        btn:DockMargin(5, 14, 5, 14)
                        btn:SetText("")
                        btn.Paint = function(self, w, h)
                            local active = status == "active" and kind == "model"
                            local text = active and "Выключить" or "Активировать"
                            local bg = active and red_color or green_color
                            DrawUnisonoButton(w, h, self:IsHovered(), bg, 5)
                            draw.SimpleText(text, "ticket_ui_title_little", w * 0.5, h * 0.5, active and color_white or color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                        btn.DoClick = function()
                            if kind == "model" and status == "active" then
                                netstream.Start("otc_donate_model_disable", {})
                            else
                                netstream.Start("otc_donate_activate", { id = tonumber(inv.id) or 0 })
                            end
                        end
                    end
                end
            end
            function main:LoadBuyList(panel)
                if not IsValid(panel) then return end
                panel:Clear()
                local list = RG_DonateMenu.Purchases or {}
                if #list < 1 then
                    self:CreateEmpty(panel, "Последних покупок пока нет.")
                    return
                end
                local scroll = panel:Add("DScrollPanel")
                scroll:Dock(FILL)
                PaintScroll(scroll)
                for i = #list, 1, -1 do
                    local list_item = list[i]
                    if not istable(list_item) then continue end
                    local buyitem = scroll:Add("DPanel")
                    buyitem:Dock(TOP)
                    buyitem:SetHeight(58)
                    buyitem:DockMargin(5, 0, 5, 7)
                    buyitem.Paint = function(self, w, h)
                        local hover = self:IsHovered()
                        DrawOTCRound(10, 0, 0, w, h, hover and Color(38, 151, 205, 230) or Color(45, 73, 86, 210))
                        DrawOTCRound(10, 1, 1, w - 2, h - 2, hover and Color(24, 44, 54, 245) or Color(24, 37, 44, 245))
                        local price = GetPurchaseDisplayPrice(list_item)
                        local ts = tonumber(list_item.ts or list_item.time or 0) or 0
                        local dateText = ts > 0 and os.date("%d.%m.%Y", ts) or ""
                        draw.SimpleText(price, "ticket_ui_title_little", w - 14, 16, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        draw.SimpleText(dateText, "otc_donate_medium_14", w - 14, h - 16, Color(185, 202, 210), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                    local itemdata = BuildPurchaseVisualItem(list_item)
                    DrawDonatePreview(buyitem, itemdata or list_item, 8, 7, 44, 44, "✦", 36)
                    local datapanel = buyitem:Add("DPanel")
                    datapanel:Dock(FILL)
                    datapanel:DockMargin(62, 6, 155, 6)
                    datapanel.Paint = function(self, w, h)
                        local title = FitTextToWidth(tostring(list_item.title or "Товар"), "otc_donate_semibold_20", w)
                        local buyer = FitTextToWidth(tostring(list_item.name or list_item.buyer or "Игрок"), "otc_donate_medium_14", w)
                        draw.SimpleText(title, "otc_donate_semibold_20", 0, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText(buyer, "otc_donate_medium_14", 0, h - 4, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                    end
                end
            end
            function main:RefreshProfileList()
                if IsValid(profile_list_panel) and isfunction(active_profile_loader) then
                    active_profile_loader(profile_list_panel)
                end
            end
            main.control_panel = main:Add("DPanel")
            main.control_panel:Dock(TOP)
            main.control_panel:SetHeight(40)
            main.control_panel.Paint = nil
            main.menu_panel = main:Add("DPanel")
            main.menu_panel:Dock(FILL)
            main.menu_panel.Paint = nil
            function main:SetupDescriptionPanel()
                if IsValid(self.menu_panel.description_panel) then self.menu_panel.description_panel:Remove() end
                self.menu_panel.description_panel = self.menu_panel:Add("DPanel")
                self.menu_panel.description_panel:SetSize(0, 0)
                self.menu_panel.description_panel:SetZPos(32767)
                self.menu_panel.description_panel.opened = false
                self.menu_panel.description_panel.moved = false
                timer.Simple(0, function()
                    if not IsValid(main) or not IsValid(main.menu_panel) or not IsValid(main.menu_panel.description_panel) then return end
                    local x, y = main.menu_panel:GetSize()
                    local del_size_x = x * 0.5
                    local panel = main.menu_panel.description_panel
                    panel:SetSize(0, y)
                    panel:SetPos(x, 40)
                    panel.close = function(self, cb)
                        self.opened = false
                        self.moved = true
                        self:SizeTo(0, y, 0.2, 0, -1, cb)
                        self:MoveTo(x, 40, 0.2, 0, -1, function()
                            if IsValid(self) then self.moved = false end
                        end)
                    end
                    panel.open = function(self, cb)
                        self.opened = true
                        self.moved = true
                        self:SizeTo(del_size_x, y, 0.2, 0, -1, cb)
                        self:MoveTo(del_size_x, 40, 0.2, 0, -1, function()
                            if IsValid(self) then self.moved = false end
                        end)
                    end
                    panel.Initalize = function(self, data, itempanel)
                        self:Clear()
                        self.data = data
                        self.name = GetItemTitle(data)
                        self.desc = GetItemDesc(data)
                        self.icon_id = tostring(data.icon or "donate_no_icon")
                        self.closebutton = self:Add("DButton")
                        self.closebutton:SetZPos(10)
                        self.closebutton:SetPos(del_size_x - 30, 5)
                        self.closebutton:SetSize(25, 25)
                        self.closebutton:SetText("")
                        self.closebutton.DoClick = function()
                            main.menu_panel.description_panel:close()
                        end
                        self.closebutton.Paint = function(btn, w, h)
                            DrawOTCRound(4, 0, 0, w, h, Color(255, 99, 93))
                            draw.SimpleText("X", "ticket_ui_title", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                        local modelPreview = IsModelPreviewItem(data)
                        if modelPreview then
                            self.icon = CreateModelPreview(self, data, true, true)
                            self.icon:SetPos(12, 96)
                            self.icon:SetSize(math.max(220, del_size_x - 24), math.max(205, y - 385))
                            self.descbox = self:Add("DScrollPanel")
                            self.descbox:SetPos(16, math.max(300, y - 250))
                            self.descbox:SetSize(math.max(200, del_size_x - 32), 134)
                            PaintScroll(self.descbox)
                            local descText = self.descbox:Add("DLabel")
                            descText:Dock(TOP)
                            descText:DockMargin(0, 0, 10, 0)
                            descText:SetWrap(true)
                            descText:SetAutoStretchVertical(true)
                            descText:SetFont("donates_item_desc")
                            descText:SetTextColor(color_white)
                            descText:SetText(self.desc or "Описание отсутствует...")
                        else
                            self.icon = self:Add("DPanel")
                            self.icon:SetPos(20, 20)
                            self.icon:SetSize(170, 170)
                            self.icon.Paint = function(icon, w, h)
                                DrawRoundedItemPicture(data, 16, 0, 0, w, h, "✦")
                            end
                        end
                        local amount = GetItemAmount(data)
                        self.costs = self:Add("DPanel")
                        self.costs:SetPos(modelPreview and 24 or 200, modelPreview and 48 or 70)
                        self.costs:SetSize(modelPreview and (del_size_x - 80) or 280, 25)
                        self.costs.text = "Цена:  " .. DonateFormatMoney(amount) .. " ₽"
                        surface.SetFont("donates_item_name")
                        self.costs.text_size_w = select(1, surface.GetTextSize(self.costs.text)) + 10
                        self.costs.Paint = function(costs, w, h)
                            local disc = GetDonateDiscountPercent()
                            if disc > 0 and amount > 0 then
                                local x = 5
                                draw.SimpleText("Цена:  ", "donates_item_name", x, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                surface.SetFont("donates_item_name")
                                x = x + select(1, surface.GetTextSize("Цена:  "))
                                local newText = DonateFormatMoney(GetDonateDiscountedAmount(amount)) .. " ₽"
                                draw.SimpleText(newText, "donates_item_name", x, h * 0.5, Color(120, 194, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                surface.SetFont("donates_item_name")
                                x = x + select(1, surface.GetTextSize(newText)) + 12
                                local oldText = DonateFormatMoney(amount) .. " ₽"
                                DrawStrikeText(oldText, "otc_donate_medium_16", x, h * 0.5, Color(170, 178, 182), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                surface.SetFont("otc_donate_medium_16")
                                x = x + select(1, surface.GetTextSize(oldText)) + 10
                                draw.SimpleText("-" .. disc .. "%", "otc_donate_medium_16", x, h * 0.5, Color(120, 194, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            else
                                draw.SimpleText(costs.text, "donates_item_name", 5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            end
                        end
                        local duration = tonumber(data.duration) or 0
                        if duration > 0 then
                            self.timepanel = self:Add("DPanel")
                            self.timepanel:SetPos(modelPreview and 24 or 200, modelPreview and 72 or 100)
                            self.timepanel:SetSize(modelPreview and (del_size_x - 80) or 320, 25)
                            self.timepanel.Paint = function(timepanel, w, h)
                                draw.SimpleText("Срок: " .. FormatDuration(duration), "donates_item_name", 5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            end
                        end
                        self.buybutton = self:Add("DButton")
                        self.buybutton:Dock(BOTTOM)
                        self.buybutton:SetText("")
                        self.buybutton:DockMargin(12, 12, 12, 46)
                        self.buybutton:SetHeight(44)
                        self.buybutton.text = "Купить"
                        self.buybutton.backgroundcolor = green_color
                        self.buybutton.Paint = function(btn, w, h)
                            local payAmount = GetDonateDiscountedAmount(amount)
                            local canBuy = amount > 0 and RG_DonateMenu.Balance >= payAmount
                            btn.text = canBuy and ("Купить за " .. DonateFormatMoney(payAmount) .. " ₽") or "Недостаточно средств"
                            btn.backgroundcolor = canBuy and green_color or red_color
                            DrawUnisonoButton(w, h, btn:IsHovered() and canBuy, btn.backgroundcolor, 5)
                            draw.SimpleText(btn.text, canBuy and "donates_item_desc" or "ticket_ui_title_little", w * 0.5, h * 0.5, canBuy and color_black or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                        self.buybutton.DoClick = function(btn)
                            if btn.lock then return end
                            if amount <= 0 then return end
                            if RG_DonateMenu.Balance < GetDonateDiscountedAmount(amount) then
                                DonateNotify("Недостаточно средств.", 1, 4)
                                return
                            end
                            netstream.Start("rk_buy_package", { amount = amount })
                        end
                    end
                    local desc, descw
                    panel.Paint = function(self, w, h)
                        if akychLib and akychLib.draw and akychLib.draw.drawBlur then akychLib.draw.drawBlur(self, 5) end
                        DrawOTCRound(16, 0, 0, w, h, Color(21, 25, 32, 245))
                        if not self.name then return end
                        if IsModelPreviewItem(self.data) then
                            draw.SimpleText(self.name, "otc_donate_semibold_34", 24, 24, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText("ЛКМ — крутить, колесо — масштаб", "ticket_ui_title_little", 24, 94, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText("Описание", "ticket_ui_title_little", 24, h - 262, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        else
                            draw.SimpleText(self.name, "otc_donate_semibold_34", 200, 35, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            if not descw or descw ~= w or self.lastdesc ~= self.desc then
                                descw = w
                                self.lastdesc = self.desc
                                desc = markup.Parse("<font=donates_item_desc>" .. (self.desc or "Описание отсутствует...") .. "</font>", del_size_x - 55)
                            end
                            if desc then desc:Draw(35, 210, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
                        end
                    end
                end)
            end
            function main:LoadRanksPage()
                self.menu_panel:Clear()
                profile_list_panel = nil
                active_profile_loader = nil
                local total = math.max(0, math.floor(tonumber(RG_DonateMenu.TotalDonated or 0) or 0))
                local current = RG_DonateMenu.MemeRank or GetDonateMemeRank(total)
                local nextRank = GetNextDonateMemeRank(total)
                local header = self.menu_panel:Add("DPanel")
                header:Dock(TOP)
                header:SetHeight(118)
                header:DockMargin(10, 15, 10, 10)
                header.Paint = function(_, w, h)
                    DrawOTCRound(12, 0, 0, w, h, Color(20, 28, 32, 238))
                    draw.SimpleText("Донат-титулы", "otc_donate_semibold_34", 18, 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("Текущий титул: " .. tostring(current.name or "Без титула"), "otc_donate_semibold_24", 18, 58, current.color or hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("Всего закинуто: " .. DonateFormatMoney(total) .. " ₽", "ticket_ui_title_little", w - 18, 26, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    if nextRank then
                        local left = math.max(0, math.floor((nextRank.amount or 0) - total))
                        draw.SimpleText("До следующего: " .. DonateFormatMoney(left) .. " ₽", "ticket_ui_title_little", w - 18, 62, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    else
                        draw.SimpleText("Ты уже на максимальном титуле", "ticket_ui_title_little", w - 18, 62, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    end
                end
                local info = self.menu_panel:Add("DPanel")
                info:Dock(TOP)
                info:SetHeight(54)
                info:DockMargin(10, 0, 10, 10)
                info.Paint = function(_, w, h)
                    DrawOTCRound(10, 0, 0, w, h, Color(24, 37, 44, 235))
                    draw.SimpleText("Как получить: пополняй баланс через платёжку. Прогресс берётся учитывая только реальные пополнения, покупки из баланса его не накручивают.", "otc_donate_medium_16", 14, h * 0.5, Color(210, 223, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                local scroll = self.menu_panel:Add("DScrollPanel")
                scroll:Dock(FILL)
                scroll:DockMargin(10, 0, 10, 10)
                PaintScroll(scroll)
                for _, rank in ipairs(DonateMemeRanks) do
                    local row = scroll:Add("DPanel")
                    row:Dock(TOP)
                    row:SetHeight(74)
                    row:DockMargin(0, 0, 0, 8)
                    row.Paint = function(self, w, h)
                        local unlocked = total >= (rank.amount or 0)
                        local isCurrent = current == rank or tostring(current.name or "") == tostring(rank.name or "")
                        local hover = self:IsHovered()
                        DrawOTCRound(10, 0, 0, w, h, isCurrent and hover_color or hover and row_border or Color(45, 73, 86, 180))
                        DrawOTCRound(10, 1, 1, w - 2, h - 2, unlocked and Color(24, 37, 44, 245) or Color(18, 25, 28, 245))
                        draw.SimpleText(tostring(rank.name or "Титул"), "otc_donate_semibold_20", 16, 14, rank.color or hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("Нужно: " .. DonateFormatMoney(rank.amount or 0) .. " ₽", "otc_donate_medium_16", 16, 44, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        if isCurrent then
                            draw.SimpleText("Текущий", "ticket_ui_title_little", w - 18, h * 0.5, hover_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        elseif unlocked then
                            draw.SimpleText("Получен", "ticket_ui_title_little", w - 18, h * 0.5, Color(190, 214, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        else
                            draw.SimpleText("Осталось: " .. DonateFormatMoney(math.max(0, (rank.amount or 0) - total)) .. " ₽", "ticket_ui_title_little", w - 18, h * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        end
                    end
                end
            end
            function main:LoadProfilePage()
                profile_choise = nil
                self.RanksMode = false
                self.menu_panel:Clear()
                local control_panel = self.menu_panel:Add("DPanel")
                control_panel:Dock(TOP)
                control_panel:SetHeight(40)
                control_panel:DockMargin(5, 20, 5, 0)
                control_panel.Paint = nil
                local menu_panel = self.menu_panel:Add("DPanel")
                menu_panel:Dock(FILL)
                menu_panel:DockMargin(5, 20, 5, 0)
                menu_panel.Paint = nil
                profile_list_panel = menu_panel
                local buttons = {
                    {"Последние", function(panel) active_profile_loader = function(p) main:LoadBuyList(p) end netstream.Start("rk_last_purchases_request") main:LoadBuyList(panel) end},
                    {"Инвентарь", function(panel) active_profile_loader = function(p) main:LoadInventory(p) end netstream.Start("otc_donate_inventory_request", {}) main:LoadInventory(panel) end},
                    {"Ваши товары", function(panel) active_profile_loader = function(p) main:LoadMyPurchasesList(p) end netstream.Start("otc_donate_my_purchases_request", {}) main:LoadMyPurchasesList(panel) end}
                }
                for index, data in ipairs(buttons) do
                    local button = control_panel:Add("DButton")
                    button:Dock(LEFT)
                    button:SetWide(index == 3 and 170 or 135)
                    button:SetText("")
                    if index > 1 then button:DockMargin(8, 0, 0, 0) end
                    button.text = data[1]
                    button.Paint = function(self, w, h)
                        local hover = self:IsHovered()
                        local xx = button_hover_border_size * 0.5
                        local yy = xx
                        DrawOTCRound(5, 0, 0, w, h, profile_choise == self and hover_color or hover and hover_color or green_color)
                        DrawOTCRound(5, xx, yy, w - button_hover_border_size, h - button_hover_border_size, button_background)
                        draw.SimpleText(self.text, "ticket_ui_title_little", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    button.DoClick = function(self)
                        profile_choise = self
                        data[2](menu_panel)
                    end
                    if not profile_choise then
                        profile_choise = button
                        data[2](menu_panel)
                    end
                end
            end
            local profile_button = main.control_panel:Add("DButton")
            profile_button:Dock(LEFT)
            profile_button:SetWide(150)
            profile_button:SetText("")
            profile_button.text = "Профиль"
            profile_button.toggle = false
            profile_button.Paint = function(self, w, h)
                local hover = self:IsHovered()
                local xx = button_hover_border_size * 0.5
                local yy = xx
                DrawOTCRound(5, 0, 0, w, h, hover and hover_color or green_color)
                DrawOTCRound(5, xx, yy, w - button_hover_border_size, h - button_hover_border_size, button_background)
                draw.SimpleText(self.text, "ticket_ui_title_little", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            profile_button.DoClick = function(self)
                if IsValid(main.menu_panel.description_panel) and main.menu_panel.description_panel.close then main.menu_panel.description_panel:close() end
                if main.RanksMode then
                    self.toggle = true
                else
                    self.toggle = not self.toggle
                end
                main.RanksMode = false
                profile_mode = self.toggle
                main.ProfileMode = profile_mode
                self.text = self.toggle and "Каталог" or "Профиль"
                if not self.toggle then
                    main:RebuildCatalog()
                    return
                end
                main:LoadProfilePage()
            end
            local ranks_button = main.control_panel:Add("DButton")
            ranks_button:Dock(LEFT)
            ranks_button:SetWide(120)
            ranks_button:DockMargin(8, 0, 0, 0)
            ranks_button:SetText("")
            ranks_button.text = "Титулы"
            ranks_button.Paint = function(self, w, h)
                local hover = self:IsHovered()
                local active = main.RanksMode == true
                local xx = button_hover_border_size * 0.5
                local yy = xx
                DrawOTCRound(5, 0, 0, w, h, active and hover_color or hover and hover_color or green_color)
                DrawOTCRound(5, xx, yy, w - button_hover_border_size, h - button_hover_border_size, button_background)
                draw.SimpleText(self.text, "ticket_ui_title_little", w * 0.5, h * 0.5, active and hover_color or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            ranks_button.DoClick = function()
                if IsValid(main.menu_panel.description_panel) and main.menu_panel.description_panel.close then main.menu_panel.description_panel:close() end
                netstream.Start("rk_balance_request")
                main.RanksMode = true
                profile_mode = true
                main.ProfileMode = true
                profile_button.toggle = false
                profile_button.text = "Профиль"
                main:LoadRanksPage()
            end
            if vgui.GetControlTable("AvatarMask") then
                main.control_panel.avatar = main.control_panel:Add("AvatarMask")
                main.control_panel.avatar:SetSteamID(LocalPlayer():SteamID64(), 40)
            else
                main.control_panel.avatar = main.control_panel:Add("AvatarImage")
                main.control_panel.avatar:SetSteamID(LocalPlayer():SteamID64(), 40)
            end
            main.control_panel.avatar:SetHeight(40)
            main.control_panel.avatar:SetWide(40)
            main.control_panel.avatar:Dock(LEFT)
            main.control_panel.avatar:DockMargin(10, 0, 0, 0)
            main.control_panel.user_data = main.control_panel:Add("DPanel")
            main.control_panel.user_data:SetHeight(40)
            main.control_panel.user_data:SetWide(245)
            main.control_panel.user_data:Dock(LEFT)
            main.control_panel.user_data:DockMargin(10, 0, 0, 0)
            main.control_panel.user_data.name = LocalPlayer():GetName()
            main.control_panel.user_data.sid = LocalPlayer():SteamID()
            main.control_panel.user_data.Paint = function(self, w, h)
                local name = FitTextToWidth(self.name, "ticket_ui_title_little", w - 10)
                local sid = FitTextToWidth(self.sid, "otc_donate_medium_16", w - 10)
                draw.SimpleText(name, "ticket_ui_title_little", 5, h * 0.5, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                draw.SimpleText(sid, "otc_donate_medium_16", 5, h * 0.5 + 1, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            main.control_panel.user_money_playtime = main.control_panel:Add("DPanel")
            main.control_panel.user_money_playtime:SetHeight(40)
            main.control_panel.user_money_playtime:SetWide(560)
            main.control_panel.user_money_playtime:Dock(LEFT)
            main.control_panel.user_money_playtime:DockMargin(10, 0, 0, 0)
            main.control_panel.user_money_playtime.Paint = function(self, w, h)
                local played = FormatPlayedTime(GetPlayedSeconds(LocalPlayer()))
                local rank = RG_DonateMenu.MemeRank or GetDonateMemeRank(RG_DonateMenu.TotalDonated or 0)
                local rankX = 310
                draw.SimpleText("Наиграно", "ticket_ui_title_little", 5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                draw.SimpleText(FitTextToWidth(played, "ticket_ui_title_little", rankX - 24), "ticket_ui_title_little", 5, h * 0.5, hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("Ваш титул", "ticket_ui_title_little", rankX, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                draw.SimpleText(FitTextToWidth(rank.name, "ticket_ui_title_little", w - rankX - 5), "ticket_ui_title_little", rankX, h * 0.5, rank.color or hover_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            local balance_add = main.control_panel:Add("DButton")
            balance_add:Dock(RIGHT)
            balance_add:SetWide(42)
            balance_add:SetText("")
            balance_add:DockMargin(8, 0, 0, 0)
            balance_add.Paint = function(self, w, h)
                local hover = self:IsHovered()
                local xx = button_hover_border_size * 0.5
                local yy = xx
                DrawOTCRound(9, 0, 0, w, h, hover and hover_color or green_color)
                DrawOTCRound(9, xx, yy, w - button_hover_border_size, h - button_hover_border_size, button_background)
                draw.SimpleText("+", "otc_donate_semibold_24", w * 0.5, h * 0.5 - 1, hover and hover_color or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            balance_add.DoClick = function()
                gui.OpenURL(RG_DonateMenu.DonateURL .. LocalPlayer():SteamID64())
            end
            local balance_panel = main.control_panel:Add("DPanel")
            balance_panel:Dock(RIGHT)
            balance_panel.Paint = function(self, w, h)
                surface.SetFont("donates_balance")
                local balancetext = "Баланс: " .. DonateFormatMoney(RG_DonateMenu.Balance) .. " ₽"
                local textsize = select(1, surface.GetTextSize(balancetext)) + 10
                self:SetWide(textsize + 10)
                draw.SimpleText(balancetext, "donates_balance", 5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            function main:RebuildCatalog()
                profile_mode = false
                self.ProfileMode = false
                self.RanksMode = false
                profile_button.toggle = false
                profile_button.text = "Профиль"
                self.menu_panel:Clear()
                self:SetupDescriptionPanel()
                local order, groups = GroupItems(RG_DonateMenu.Items)
                if not RG_DonateMenu.CurrentCategory or not groups[RG_DonateMenu.CurrentCategory] then
                    RG_DonateMenu.CurrentCategory = order[1]
                    current_choise_menu = order[1]
                end
                self.menu_panel.scroll = self.menu_panel:Add("DScrollPanel")
                local scroll = self.menu_panel.scroll
                scroll:Dock(FILL)
                scroll:DockMargin(10, 10, 10, 5)
                PaintScroll(scroll)
                local salelist = scroll:Add("DIconLayout")
                salelist:Dock(FILL)
                salelist:SetSpaceY(25)
                salelist:SetSpaceX(25)
                salelist:DockMargin(25, 0, 0, 0)
                if #order < 1 then
                    local noitems = salelist:Add("DLabel")
                    noitems.OwnLine = true
                    noitems:SetWide(500)
                    noitems:SetHeight(35)
                    noitems:SetText("Загрузка...")
                    noitems:SetFont("donates_category_title")
                    noitems:SetTextColor(color_white)
                    return
                end
                local current = RG_DonateMenu.CurrentCategory or current_choise_menu or order[1]
                local items = groups[current] or {}
                local categoryname = salelist:Add("DPanel")
                categoryname.OwnLine = true
                categoryname:SetWide(900)
                categoryname:SetHeight(48)
                categoryname.Paint = function(self, w, h)
                    draw.SimpleText(current or "Каталог", "otc_donate_semibold_34", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                if #items < 1 then
                    local empty = salelist:Add("DLabel")
                    empty.OwnLine = true
                    empty:SetWide(500)
                    empty:SetHeight(35)
                    empty:SetText("Товары не найдены")
                    empty:SetFont("donates_item_name")
                    empty:SetTextColor(color_white)
                    return
                end
                for _, v in ipairs(items) do
                    local item = salelist:Add("DPanel")
                    local sw = ScrW()
                    local mp_w = math.Clamp(math.floor(sw * 0.155), 210, 245)
                    local mp_h = math.Clamp(math.floor(mp_w * 1.36), 292, 332)
                    local itemname = GetItemTitle(v)
                    local amount = GetItemAmount(v)
                    local duration = tonumber(v.duration) or 0
                    item:SetSize(mp_w, mp_h)
                    item.Paint = function(self, w, h)
                        DrawOTCRound(18, 0, 0, w, h, self:IsHovered() and Color(30, 65, 82, 246) or button_background)
                        DrawOTCRound(16, 8, h - 102, w - 16, 94, Color(13, 19, 22, 242))
                        local disc = GetDonateDiscountPercent()
                        local title = FitTextToWidth(itemname, "otc_donate_semibold_20", w - 24)
                        if disc > 0 and amount > 0 then
                            draw.SimpleText(title, "otc_donate_semibold_20", w * 0.5, h - 86, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            surface.SetFont("otc_donate_medium_14")
                            local oldText = DonateFormatMoney(amount) .. " ₽"
                            local oldW = select(1, surface.GetTextSize(oldText))
                            local tagText = "-" .. disc .. "%"
                            local tagW = select(1, surface.GetTextSize(tagText))
                            local gap = 8
                            local totalW = oldW + gap + tagW
                            local startX = w * 0.5 - totalW * 0.5
                            DrawStrikeText(oldText, "otc_donate_medium_14", startX, h - 64, Color(170, 178, 182), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText(tagText, "otc_donate_medium_14", startX + oldW + gap, h - 64, Color(120, 194, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            local price = DonateFormatMoney(GetDonateDiscountedAmount(amount)) .. " ₽"
                            draw.SimpleText(price, "otc_donate_semibold_24", w * 0.5, h - 44, hover_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        else
                            draw.SimpleText(title, "otc_donate_semibold_20", w * 0.5, h - 78, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            local price = DonateFormatMoney(amount) .. " ₽"
                            draw.SimpleText(price, "otc_donate_semibold_24", w * 0.5, h - 48, hover_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                        local bottomText = duration > 0 and FormatDuration(duration) or tostring(v.tag or "")
                        bottomText = FitTextToWidth(bottomText, "otc_donate_medium_18", w - 24)
                        draw.SimpleText(bottomText, "otc_donate_medium_18", w * 0.5, h - 21, Color(205, 218, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    local previewH = mp_h - 104
                    if IsModelPreviewItem(v) then
                        item.icon = CreateModelPreview(item, v, false, false)
                        item.icon:SetPos(8, 8)
                        item.icon:SetSize(mp_w - 16, previewH - 8)
                        item.icon.PaintOver = function(self, w, h)
                        end
                    else
                        item.icon = item:Add("DPanel")
                        item.icon:SetPos(8, 8)
                        item.icon:SetSize(mp_w - 16, previewH - 8)
                        item.icon.Paint = function(self, w, h)
                            DrawRoundedItemPicture(v, 18, 0, 0, w, h, "✦")
                        end
                    end
                    item.descbutton = item:Add("DButton")
                    item.descbutton:SetPos(0, 0)
                    item.descbutton:SetSize(mp_w, mp_h)
                    item.descbutton:SetText("")
                    item.descbutton.Paint = nil
                    item.descbutton.DoClick = function(self)
                        if not IsValid(main.menu_panel.description_panel) or not main.menu_panel.description_panel.Initalize then return end
                        if main.menu_panel.description_panel.moved then return end
                        if main.menu_panel.description_panel.opened then
                            main.menu_panel.description_panel:close(function()
                                if not IsValid(main.menu_panel.description_panel) then return end
                                if main.menu_panel.description_panel.name == itemname then return end
                                main.menu_panel.description_panel:Initalize(v, item)
                                main.menu_panel.description_panel:open()
                            end)
                        else
                            main.menu_panel.description_panel:Initalize(v, item)
                            main.menu_panel.description_panel:open()
                        end
                    end
                    item.IsHovered = function(self)
                        return vgui.GetHoveredPanel() == self or (IsValid(self.icon) and self.icon:IsHovered()) or (IsValid(self.descbutton) and self.descbutton:IsHovered())
                    end
                end
                salelist:Layout()
            end
            main:RebuildCatalog()
end
hook.Add("InitF4Menus", "rg_donate_menu", function()
    monteractF4.lastchoisedid = DonateMenuButtons[1].num
    RG_DonateMenu.CurrentCategory = RG_DonateMenu.CurrentCategory or DonateMenuButtons[1].name
    current_choise_menu = current_choise_menu or DonateMenuButtons[1].name
    for _, info in ipairs(DonateMenuButtons) do
        local categoryName = info.name
        monteractF4.addmenu({
            num = info.num,
            name = categoryName,
            desc = info.desc,
            icon = info.icon,
            func = function(unif4)
                if categoryName == "OT-Coin" then
                    OpenDonateOTCoin(unif4)
                    return
                end
                OpenDonateCategory(unif4, categoryName)
            end
        })
    end
end)
timer.Simple(0, function()
    if monteractF4 and monteractF4.addmenu then hook.Run("InitF4Menus") end
end)
timer.Simple(2, function()
    if monteractF4 and monteractF4.addmenu and not monteractF4.cache_name_id["Привилегии"] then hook.Run("InitF4Menus") end
end)
hook.Add("PlayerSay", "RK_DonateChatCommands", function(ply, text, teamChat)
    local cmd = string.lower(string.Trim(text))
    if cmd == "/donate" or cmd == "/донат" then
        LocalPlayer():ConCommand("rk_donate_menu")
        return ""
    end
end)
end)

hook.Add("InitF4Menus", "hg_cases_tab", function()
    if not (monteractF4 and monteractF4.addmenu) then return end
    monteractF4.addmenu({
        num = 11,
        name = "КЕЙСЫ",
        desc = "",
        icon = "monteract_logo",
        paint = function(self, w, h)
            local pulse = 0.5 + 0.5 * math.abs(math.sin(RealTime() * 2.2))
            local a = math.floor(28 + pulse * 46)
            draw.RoundedBox(6, 2, 2, w - 4, h - 4, Color(255, 176, 32, a))
            surface.SetDrawColor(255, 176, 32, math.floor(150 + pulse * 105))
            surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 2)
            draw.RoundedBox(2, 5, h * 0.5 - 15, 4, 30, Color(255, 200, 60, 255))
        end,
        func = function(panel)
            monteractF4.lastchoisedid = 8
            timer.Simple(0, function()
                if monteractF4 and isfunction(monteractF4.closeF4) then monteractF4.closeF4() end
                RunConsoleCommand("hg_cases")
            end)
        end
    })
end)
