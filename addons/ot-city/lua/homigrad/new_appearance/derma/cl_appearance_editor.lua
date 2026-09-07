hg.Appearance = hg.Appearance or {}

local AP = hg.Appearance
local PANEL = {}

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_dim = Color(150, 190, 220)
local clr_bg = Color(3, 5, 9, 235)
local clr_card = Color(6, 12, 20, 168)
local clr_card_hover = Color(12, 22, 36, 205)
local clr_panel = Color(5, 10, 18, 240)
local clr_danger = Color(255, 90, 90)
local clr_locked = Color(112, 126, 140)
local clr_coin_ok = Color(140, 255, 155)
local clr_coin_no = Color(255, 150, 150)
local clr_donate = Color(220, 170, 255)
local clr_vip = Color(255, 220, 120)

local function FormatCoinAmount(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    return string.Comma(amount)
end

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
end

local function DrawRound(rad, x, y, w, h, col)
    if w <= 0 or h <= 0 then return end
    rad = math.min(rad, math.floor(math.min(w, h) / 2))

    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if w <= 0 or h <= 0 then return end
    rad = math.min(rad, math.floor(math.min(w, h) / 2))

    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
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

local function DrawCross(cx, cy, size, col, thick)
    local half = size * 0.5
    local t = math.max(1, math.floor((thick or 2) + 0.5))
    local x = math.floor(cx + 0.5)
    local y = math.floor(cy + 0.5)

    surface.SetDrawColor(col.r, col.g, col.b, col.a)

    for i = 0, t - 1 do
        surface.DrawLine(x - half, y - half + i, x + half, y + half + i)
        surface.DrawLine(x - half, y + half - i, x + half, y - half - i)
    end
end

local function UILerp(speed, from, to)
    return Lerp(math.Clamp(FrameTime() * speed, 0, 1), from, to)
end

local function DrawUIText(text, font, x, y, col, ax, ay)
    local shadowAlpha = (col.a or 255) * 0.7
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, shadowAlpha), ax, ay)
    draw.SimpleText(text, font, x, y, col, ax, ay)
end

local function TrimToWidth(text, fontName, maxW)
    text = tostring(text or "")
    surface.SetFont(fontName)

    if surface.GetTextSize(text) <= maxW then
        return text
    end

    local dots = ".."
    local len = utf8.len(text) or #text

    while len > 0 do
        local part = utf8.sub(text, 1, len)
        if surface.GetTextSize(part .. dots) <= maxW then
            return part .. dots
        end
        len = len - 1
    end

    return dots
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("HGAppearanceTitle", {
        font = "Montserrat SemiBold",
        extended = true,
        size = math.floor(24 * s + 0.5),
        weight = 600,
        antialias = true
    })

    surface.CreateFont("HGAppearanceText", {
        font = "Montserrat Medium",
        extended = true,
        size = math.floor(18 * s + 0.5),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("HGAppearanceSmall", {
        font = "Montserrat Medium",
        extended = true,
        size = math.floor(16 * s + 0.5),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("HGAppearanceTiny", {
        font = "Montserrat Medium",
        extended = true,
        size = math.floor(14 * s + 0.5),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("HGAppearanceBrand", {
        font = "Montserrat SemiBold",
        extended = true,
        size = math.floor(40 * s + 0.5),
        weight = 800,
        italic = true,
        antialias = true
    })

    surface.CreateFont("HGAppearanceClose", {
        font = "Montserrat SemiBold",
        extended = true,
        size = math.floor(34 * s + 0.5),
        weight = 800,
        antialias = true
    })
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_AppearanceFonts", CreateFonts)

local function NormalizePresetName(name)
    name = string.Trim(tostring(name or ""))
    if name == "" or not utf8.len(name) then return "" end
    return utf8.sub(name, 1, 32)
end

local function GetPresetCache()
    AP.PresetsCache = AP.PresetsCache or {}
    return AP.PresetsCache
end

local function SavePreset(name, tblAppearance)
    if not isstring(name) or name == "" or not istable(tblAppearance) then return end

    local copy = table.Copy(tblAppearance)
    copy.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(copy.AAttachments or {}, LocalPlayer()) or (copy.AAttachments or {})

    net.Start("hg_appearance_preset_save")
        net.WriteString(name)
        net.WriteTable(copy)
    net.SendToServer()
end

local function LoadPreset(name)
    local preset = GetPresetCache()[name]
    if not istable(preset) then return nil end

    local copy = table.Copy(preset)
    copy.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(copy.AAttachments or {}, LocalPlayer()) or (copy.AAttachments or {})
    return copy
end

local function GetPresetList()
    local list = {}
    for name in pairs(GetPresetCache()) do
        list[#list + 1] = name
    end
    table.sort(list, function(a, b)
        return tostring(a) < tostring(b)
    end)
    return list
end

local function DeletePreset(name)
    if not isstring(name) or name == "" then return false end

    net.Start("hg_appearance_preset_delete")
        net.WriteString(name)
    net.SendToServer()

    return true
end

AP.SavePreset = SavePreset
AP.LoadPreset = LoadPreset
AP.GetPresetList = GetPresetList
AP.DeletePreset = DeletePreset

local modelsPrecached = false
local function PrecacheAccessoryModels()
    if modelsPrecached then return end
    modelsPrecached = true

    timer.Simple(0.1, function()
        if AP.PlayerModels then
            for _, sexModels in pairs(AP.PlayerModels) do
                for _, modelData in pairs(sexModels) do
                    if modelData.mdl then
                        util.PrecacheModel(modelData.mdl)
                    end
                end
            end
        end

        if hg.Accessories then
            for _, accessory in pairs(hg.Accessories) do
                if accessory.model then
                    util.PrecacheModel(accessory.model)
                end
                if accessory.femmodel then
                    util.PrecacheModel(accessory.femmodel)
                end
            end
        end
    end)
end

local clothesPreviewCard = nil

local function CloseClothesPreviewCard()
    if IsValid(clothesPreviewCard) then
        clothesPreviewCard:Remove()
    end

    clothesPreviewCard = nil
end

local function OpenClothesPreviewCard(appearanceTable, slotName, clothesKey)
    CloseClothesPreviewCard()

    if not istable(appearanceTable) then return end

    local modelData = AP.PlayerModels[1][appearanceTable.AModel] or AP.PlayerModels[2][appearanceTable.AModel]
    if not istable(modelData) then return end
    if not util.IsValidModel(tostring(modelData.mdl or "")) then return end

    local sexIndex = modelData.sex and 2 or 1
    local card = vgui.Create("DPanel")
    clothesPreviewCard = card

    card:SetSize(SX(196), SX(312))
    card:SetDrawOnTop(true)
    card:SetMouseInputEnabled(false)
    card:SetKeyboardInputEnabled(false)
    card:SetPos(math.Clamp(gui.MouseX() + SX(24), SX(6), ScrW() - SX(204)), math.Clamp(gui.MouseY() - SX(80), SX(6), ScrH() - SX(320)))
    card:SetAlpha(0)
    card:AlphaTo(255, 0.12, 0)

    function card:Paint(w, h)
        local rad = math.max(6, SX(12))
        DrawRound(rad, 0, 0, w, h, clr_panel)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60), math.max(2, SX(4)))
        DrawUIText(TrimToWidth(tostring(clothesKey), "HGAppearanceSmall", w - SX(18)), "HGAppearanceSmall", w * 0.5, h - SX(24), clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local preview = vgui.Create("DModelPanel", card)
    preview:Dock(FILL)
    preview:DockMargin(SX(8), SX(8), SX(8), SX(38))
    preview:SetModel(modelData.mdl)
    preview:SetFOV(36)
    preview:SetCamPos(Vector(78, 0, 58))
    preview:SetLookAt(Vector(0, 0, 38))
    preview:SetMouseInputEnabled(false)
    preview:SetKeyboardInputEnabled(false)

    function preview:LayoutEntity(ent)
        if not IsValid(ent) then return end

        ent:SetAngles(Angle(0, 30 + math.sin(RealTime() * 0.6) * 18, 0))

        local seq = ent:LookupSequence("idle_all_01")
        if seq and seq > 0 then
            ent:ResetSequence(seq)
        end

        ent:FrameAdvance(FrameTime())

        local clr = appearanceTable.AColor or Color(255, 255, 255)
        ent:SetNWVector("PlayerColor", Vector((clr.r or 255) / 255, (clr.g or 255) / 255, (clr.b or 255) / 255))
        ent:SetSubMaterial()

        local mats = ent:GetMaterials() or {}

        for slot, originalMaterial in pairs(modelData.submatSlots or {}) do
            local index = nil

            for i = 1, #mats do
                if mats[i] == originalMaterial then
                    index = i - 1
                    break
                end
            end

            if index ~= nil then
                local key = (slot == slotName) and clothesKey or ((appearanceTable.AClothes or {})[slot] or "normal")
                local material = (AP.Clothes[sexIndex] and AP.Clothes[sexIndex][key]) or (AP.Clothes[sexIndex] and AP.Clothes[sexIndex].normal) or nil

                if material then
                    ent:SetSubMaterial(index, material)
                end
            end
        end

        if AP.ApplyFacemap then
            AP.ApplyFacemap(ent, ent:GetModel(), appearanceTable.AFacemap, mats)
        end

        ent:SetBodyGroups("00000000000000000000")

        local bodygroups = ent:GetBodyGroups() or {}
        local wantedList = appearanceTable.ABodygroups or {}

        for k, v in ipairs(bodygroups) do
            local wantedName = wantedList[v.name]
            if not wantedName then continue end
            if not AP.Bodygroups[v.name] or not AP.Bodygroups[v.name][sexIndex] then continue end

            local wanted = AP.Bodygroups[v.name][sexIndex][wantedName]
            if not wanted then continue end

            for i = 0, #v.submodels do
                if wanted[1] == v.submodels[i] then
                    ent:SetBodygroup(k - 1, i)
                    break
                end
            end
        end
    end
end

hook.Add("InitPostEntity", "HG_PrecacheAppearanceModels", function()
    timer.Simple(5, PrecacheAccessoryModels)
end)

AP.PrecacheModels = PrecacheAccessoryModels

local ACC_SORT_COOKIE = "otcity_appearance_accessory_sort"

local ACC_SORT_MODES = {
    {
        id = "default",
        label = "По умолчанию",
        hint = "Сначала доступные, затем А-Я",
        key = function(r) return r.locked and 1 or 0 end
    },
    {
        id = "alpha",
        label = "По алфавиту",
        hint = "Только А-Я, без групп",
        key = function(r) return 0 end
    },
    {
        id = "locked_first",
        label = "Сначала заблокированные",
        hint = "Видно, что ещё не открыто",
        key = function(r) return r.locked and 0 or 1 end
    },
    {
        id = "donate_first",
        label = "Сначала донатные",
        hint = "Донат-предметы выше",
        key = function(r) return r.donate and 0 or 1 end
    },
    {
        id = "coins_first",
        label = "Сначала за OT-коины",
        hint = "Покупаемое за коины выше",
        key = function(r) return r.coin and 0 or 1 end
    },
    {
        id = "price_asc",
        label = "Сначала дешёвые",
        hint = "Цена по возрастанию",
        key = function(r) return r.price end
    },
    {
        id = "price_desc",
        label = "Сначала дорогие",
        hint = "Цена по убыванию",
        key = function(r) return -r.price end
    }
}

local function GetAccessorySortMode()
    local wanted = tostring(hg.AppearanceAccessorySort or cookie.GetString(ACC_SORT_COOKIE, "default") or "default")

    for i, mode in ipairs(ACC_SORT_MODES) do
        if mode.id == wanted then return i, mode end
    end

    return 1, ACC_SORT_MODES[1]
end

local function SetAccessorySortMode(id)
    hg.AppearanceAccessorySort = tostring(id or "default")
    cookie.Set(ACC_SORT_COOKIE, hg.AppearanceAccessorySort)
end

local function GetAccessoryState(id, data)
    local lply = LocalPlayer()
    local donate = (AP.IsAccessoryDonateRestricted and AP.IsAccessoryDonateRestricted(data)) or (istable(data) and data.donateOnly == true) or false
    local coin = (AP.IsAccessoryCoinRestricted and AP.IsAccessoryCoinRestricted(data)) or false
    local vip = (istable(data) and data.isvip == true) or false
    local rawPrice = (AP.GetAccessoryCoinPrice and AP.GetAccessoryCoinPrice(data, 0)) or (istable(data) and (data.coinPrice or data.price)) or 0
    local hasAccess = true

    if AP.ClientHasAccessoryAccess and IsValid(lply) then
        hasAccess = AP.ClientHasAccessoryAccess(id, data, lply) == true
    end

    local locked = not hasAccess
    local price = math.max(0, math.floor(tonumber(rawPrice) or 0))
    local requiresVIP = (vip and locked and IsValid(lply) and lply.GetUserGroup and lply:GetUserGroup() == "user") or false
    local canPurchase = (locked and coin and not donate and not requiresVIP and price > 0) or false
    local balance = (AP.GetClientOTCoins and AP.GetClientOTCoins()) or 0

    return {
        id = id,
        data = data,
        locked = locked,
        hasAccess = hasAccess,
        donate = donate,
        coin = coin,
        vip = vip,
        requiresVIP = requiresVIP,
        canPurchase = canPurchase,
        canAfford = balance >= price,
        price = price,
        name = string.lower(tostring((istable(data) and data.name) or id))
    }
end

local function CreateStyledScrollPanel(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    local sbar = scroll:GetVBar()
    sbar:SetWide(SX(9))
    sbar:SetHideButtons(true)

    function sbar:Paint(w, h)
        surface.SetDrawColor(168, 212, 245, 16)
        surface.DrawRect(w * 0.5 - 1, 0, 1, h)
    end

    function sbar.btnGrip:Paint(w, h)
        DrawRound(math.max(2, SX(4)), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 215))
    end

    return scroll
end

local function MakeStyledClose(parent, onClose)
    local close = vgui.Create("DButton", parent)
    close:SetText("")
    close:SetCursor("hand")
    close.HoverFrac = 0
    close.DoClick = function()
        if onClose then onClose() end
    end
    close.Paint = function(btn, w, h)
        btn.HoverFrac = UILerp(12, btn.HoverFrac or 0, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverFrac, 8, 16),
            Lerp(btn.HoverFrac, 18, 60),
            Lerp(btn.HoverFrac, 30, 96),
            Lerp(btn.HoverFrac, 155, 225)
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + btn.HoverFrac * 150), 1)
        DrawCross(w * 0.5, h * 0.5, SX(13), Color(Lerp(btn.HoverFrac, 235, clr_accent.r), Lerp(btn.HoverFrac, 235, clr_accent.g), Lerp(btn.HoverFrac, 235, clr_accent.b), 245), math.max(2, SX(2)))
    end

    return close
end

local function CreateStyledAccessoryMenu(parent, title, onClosed, side)
    local menuW = math.min(SX(560), ScrW() - SX(96))
    local menuH = math.min(SX(640), ScrH() - SX(140))
    local menuX = (side == "right") and (ScrW() - menuW - SX(48)) or SX(48)

    local menu = vgui.Create("EditablePanel", parent)
    menu:SetSize(menuW, menuH)
    menu:SetPos(math.floor(menuX), math.floor((ScrH() - menuH) * 0.5))
    menu:MakePopup()
    menu:SetKeyboardInputEnabled(false)
    menu.PopupTitle = tostring(title or "")
    menu.HoverFrac = 0
    menu.SelectedAccessor = nil

    function menu:Close()
        self:Remove()
    end

    function menu:Paint(w, h)
        DrawRound(SX(12), 0, 0, w, h, clr_panel)
        DrawRoundOutlined(SX(12), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 90), 1)

        DrawRound(SX(12), 0, 0, w, SX(64), Color(8, 18, 30, 200))
        DrawRound(1, SX(24), SX(63), w - SX(48), math.max(1, SX(1)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 60))

        DrawUIText(self.PopupTitle, "HGAppearanceTitle", SX(24), SX(32), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawRound(SX(3), SX(24), SX(58), SX(120), math.max(2, SX(3)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190))
    end

    menu.CloseButton = MakeStyledClose(menu, function()
        menu:Close()
    end)

    function menu:CloseSortDropdown()
        if IsValid(self.SortDropdown) then
            self.SortDropdown:Remove()
        end

        self.SortDropdown = nil
    end

    function menu:OpenSortDropdown()
        if IsValid(self.SortDropdown) then
            self:CloseSortDropdown()
            return
        end

        local activeIndex = GetAccessorySortMode()
        local pad = SX(6)
        local rowH = SX(38)
        local ddW = math.min(SX(268), self:GetWide() - SX(28))
        local ddH = pad * 2 + rowH * #ACC_SORT_MODES

        local dd = vgui.Create("DPanel", self)
        dd:SetSize(ddW, ddH)
        dd:SetZPos(1000)

        local bx, by = SX(14), SX(64)

        if IsValid(self.SortButton) then
            bx = math.max(SX(10), self.SortButton:GetX() + self.SortButton:GetWide() - ddW)
            by = self.SortButton:GetY() + self.SortButton:GetTall() + SX(6)
        end

        dd:SetPos(bx, by)

        function dd:Paint(w, h)
            DrawRound(SX(10), 0, 0, w, h, Color(6, 13, 22, 248))
            DrawRoundOutlined(SX(10), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 110), 1)
        end

        for i, mode in ipairs(ACC_SORT_MODES) do
            local opt = vgui.Create("DButton", dd)
            opt:SetText("")
            opt:SetCursor("hand")
            opt:SetSize(ddW - pad * 2, rowH)
            opt:SetPos(pad, pad + (i - 1) * rowH)
            opt.HoverFrac = 0
            opt.Active = i == activeIndex

            function opt:Paint(w, h)
                self.HoverFrac = UILerp(14, self.HoverFrac or 0, (self:IsHovered() or self.Active) and 1 or 0)

                local rad = math.max(3, SX(6))

                if self.HoverFrac > 0.01 then
                    DrawRound(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, math.floor(12 + self.HoverFrac * 44)))
                end

                if self.Active then
                    DrawRound(rad, 0, SX(6), math.max(2, SX(3)), h - SX(12), Color(clr_accent.r, clr_accent.g, clr_accent.b, 235))
                end

                local textX = SX(13)

                DrawUIText(TrimToWidth(mode.label, "HGAppearanceTiny", w - textX - SX(8)), "HGAppearanceTiny", textX, h * 0.5 - SX(8), self.Active and clr_cyan or clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                DrawUIText(TrimToWidth(mode.hint or "", "HGAppearanceTiny", w - textX - SX(8)), "HGAppearanceTiny", textX, h * 0.5 + SX(9), clr_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            function opt:DoClick()
                SetAccessorySortMode(mode.id)
                surface.PlaySound("ui/buttonclick.wav")
                menu:CloseSortDropdown()
                menu:RebuildChoices()
            end
        end

        self.SortDropdown = dd
        dd:MoveToFront()
    end

    menu.SortButton = vgui.Create("DButton", menu)
    menu.SortButton:SetText("")
    menu.SortButton:SetCursor("hand")
    menu.SortButton.HoverFrac = 0

    function menu.SortButton:Paint(w, h)
        self.HoverFrac = UILerp(12, self.HoverFrac or 0, (self:IsHovered() or IsValid(menu.SortDropdown)) and 1 or 0)

        local rad = math.max(4, SX(8))
        local bg = Color(
            Lerp(self.HoverFrac, 8, 16),
            Lerp(self.HoverFrac, 18, 52),
            Lerp(self.HoverFrac, 30, 84),
            Lerp(self.HoverFrac, 200, 240)
        )

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60 + self.HoverFrac * 150), 1)

        local _, mode = GetAccessorySortMode()
        local label = (mode and mode.label) or "По умолчанию"
        local arrowW = SX(18)
        local textCol = Color(
            Lerp(self.HoverFrac, clr_dim.r, clr_text.r),
            Lerp(self.HoverFrac, clr_dim.g, clr_text.g),
            Lerp(self.HoverFrac, clr_dim.b, clr_text.b)
        )

        DrawUIText(TrimToWidth(label, "HGAppearanceTiny", w - SX(18) - arrowW), "HGAppearanceTiny", SX(10), h * 0.5, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local cx = w - arrowW * 0.5 - SX(6)
        local cy = h * 0.5 + SX(1)
        local a = SX(4)

        surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 200 + self.HoverFrac * 55)
        surface.DrawLine(cx - a, cy - a * 0.5, cx, cy + a * 0.5)
        surface.DrawLine(cx + a, cy - a * 0.5, cx, cy + a * 0.5)
        surface.DrawLine(cx - a, cy - a * 0.5 + 1, cx, cy + a * 0.5 + 1)
        surface.DrawLine(cx + a, cy - a * 0.5 + 1, cx, cy + a * 0.5 + 1)
    end

    function menu.SortButton:DoClick()
        surface.PlaySound("ui/buttonclickrelease.wav")
        menu:OpenSortDropdown()
    end

    function menu.SortButton:DoRightClick()
        local index = GetAccessorySortMode()
        local nextMode = ACC_SORT_MODES[(index % #ACC_SORT_MODES) + 1]
        if not nextMode then return end

        SetAccessorySortMode(nextMode.id)
        surface.PlaySound("ui/buttonclick.wav")
        menu:CloseSortDropdown()
        menu:RebuildChoices()
    end

    function menu:OnMousePressed()
        self:CloseSortDropdown()
    end

    local scroll = CreateStyledScrollPanel(menu)
    scroll:Dock(FILL)
    scroll:DockMargin(SX(16), SX(64) + SX(12), SX(16), SX(16))

    local canvas = scroll:GetCanvas()
    menu.ScrollPanel = scroll

    function menu:RefreshCardLayout()
        if not IsValid(self.ScrollPanel) then return end

        local canvas = self.ScrollPanel:GetCanvas()
        local kids = {}

        for _, child in ipairs(canvas:GetChildren()) do
            if IsValid(child) and not child.PendingRemoval then
                kids[#kids + 1] = child
            end
        end

        if #kids == 0 then return end

        local innerW = self.ScrollPanel:GetWide() - SX(10)
        local gap = SX(12)
        local cols = math.max(2, math.floor(innerW / SX(200)))
        local cardW = math.floor((innerW - (cols - 1) * gap) / cols)
        local cardH = cardW + SX(52)

        for i, card in ipairs(kids) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            card:SetPos(col * (cardW + gap), row * (cardH + gap))
            card:SetSize(cardW, cardH)
        end

        local rows = math.ceil(#kids / cols)
        canvas:SetSize(innerW, rows * (cardH + gap))
    end

    function menu:PerformLayout(w, h)
        if IsValid(self.CloseButton) then
            local s = SX(40)
            self.CloseButton:SetSize(s, s)
            self.CloseButton:SetPos(w - s - SX(14), SX(12))
        end

        if IsValid(self.SortButton) then
            local bh = SX(32)
            local bw = math.Clamp(w - SX(250), SX(120), SX(224))
            self.SortButton:SetSize(bw, bh)
            self.SortButton:SetPos(w - SX(64) - SX(10) - bw, SX(16))
        end

        if IsValid(self.SortDropdown) and IsValid(self.SortButton) then
            local ddW = self.SortDropdown:GetWide()
            self.SortDropdown:SetPos(math.max(SX(10), self.SortButton:GetX() + self.SortButton:GetWide() - ddW), self.SortButton:GetY() + self.SortButton:GetTall() + SX(6))
        end

        self:RefreshCardLayout()
    end

    function menu:OnFocusChanged(gained)
        if not gained then
            self:Close()
        end
    end

    function menu:OnRemove()
        if onClosed then onClosed() end
    end

    function menu:AddAccessoryIcon(model, accessorKey, accessoryData, onSelect, onPreview)
        local card = vgui.Create("DButton", self.ScrollPanel:GetCanvas())
        card:SetText("")
        card:SetCursor("hand")
        card.Accessor = accessorKey
        card.LabelText = string.NiceName(accessoryData and accessoryData.name or accessorKey)
        card.HoverFrac = 0
        card.State = GetAccessoryState(accessorKey, accessoryData)
        card.Selected = self.SelectedAccessor == accessorKey

        local menuRef = self

        function card:Think()
            self.Selected = menuRef.SelectedAccessor == accessorKey

            if (self.NextStateRefresh or 0) <= RealTime() then
                self.NextStateRefresh = RealTime() + 0.25
                self.State = GetAccessoryState(accessorKey, accessoryData)
            end
        end

        local preview = vgui.Create("DModelPanel", card)
        preview:Dock(FILL)
        preview:DockMargin(SX(10), SX(10), SX(10), SX(52))
        preview:SetModel(model or "models/error.mdl")
        preview:SetTooltip(card.LabelText)
        preview:SetFOV(15)
        preview:SetLookAt(accessoryData.vpos or Vector(0, 0, 0))
        preview:SetMouseInputEnabled(false)
        preview:SetKeyboardInputEnabled(false)

        function preview:LayoutEntity(ent)
            if not IsValid(ent) then return end
            ent:SetAngles(Angle(0, RealTime() * 25 % 360, 0))
            ent:FrameAdvance(FrameTime())

            if accessoryData.bSetColor then
                local clr = accessoryData.color or accessoryData.col or Color(255, 255, 255)
                render.SetColorModulation(clr.r / 255, clr.g / 255, clr.b / 255)
            end
        end

        function preview:PostDrawModel()
            if accessoryData.bSetColor then
                render.SetColorModulation(1, 1, 1)
            end
        end

        timer.Simple(0, function()
            if not IsValid(preview) or not IsValid(preview.Entity) then return end
            preview.Entity:SetSkin((isfunction(accessoryData.skin) and accessoryData.skin()) or (accessoryData.skin or 0))
            preview.Entity:SetBodyGroups(accessoryData.bodygroups or "0000000")
            if accessoryData.SubMat then
                preview.Entity:SetSubMaterial(0, accessoryData.SubMat)
            end
        end)

        function card:Paint(w, h)
            self.HoverFrac = UILerp(12, self.HoverFrac or 0, (self:IsHovered() or self:IsDown()) and 1 or 0)

            local bg = Color(
                Lerp(self.HoverFrac, clr_card.r, clr_card_hover.r),
                Lerp(self.HoverFrac, clr_card.g, clr_card_hover.g),
                Lerp(self.HoverFrac, clr_card.b, clr_card_hover.b),
                Lerp(self.HoverFrac, clr_card.a, clr_card_hover.a)
            )

            local rad = math.max(5, SX(10))

            DrawRound(rad, 0, 0, w, h, bg)

            if self.Selected then
                DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60), math.max(3, SX(6)))
                DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 220), math.max(1, SX(2)))
            else
                DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 14 + self.HoverFrac * 60), 1)
            end

            local state = self.State or {}
            local statusText, statusColor = "Доступно", clr_dim
            local barColor = clr_accent

            if state.canPurchase then
                statusText = FormatCoinAmount(state.price) .. " OT-Coin"
                statusColor = state.canAfford and clr_coin_ok or clr_coin_no
                barColor = statusColor
            elseif state.donate and state.locked then
                statusText, statusColor, barColor = "Донат", clr_donate, clr_donate
            elseif state.requiresVIP then
                statusText, statusColor, barColor = "Нужен VIP", clr_vip, clr_vip
            elseif state.locked then
                statusText, statusColor, barColor = "Недоступно", clr_locked, clr_locked
            elseif state.coin and state.price > 0 then
                statusText, statusColor = "Куплено", clr_coin_ok
            end

            if self.Selected then
                statusText, statusColor, barColor = "Выбрано", clr_accent, clr_accent
            end

            DrawRound(SX(3), SX(14), SX(14), w - SX(28), math.max(2, SX(3)), Color(barColor.r, barColor.g, barColor.b, 90 + self.HoverFrac * 100))

            DrawUIText(TrimToWidth(self.LabelText, "HGAppearanceTiny", w - SX(20)), "HGAppearanceTiny", w / 2, h - SX(36), state.locked and clr_locked or clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawUIText(statusText, "HGAppearanceTiny", w / 2, h - SX(16), statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local badge = state.vip and "VIP" or (state.donate and "ДОНАТ" or nil)

            if badge then
                local badgeCol = state.vip and clr_vip or clr_donate
                local bw = SX(badge == "ДОНАТ" and 58 or 40)
                local bh = SX(17)
                local bx, by = SX(14), SX(24)
                local brad = math.max(3, SX(6))

                DrawRound(brad, bx, by, bw, bh, Color(badgeCol.r, badgeCol.g, badgeCol.b, state.locked and 90 or 45))
                DrawRoundOutlined(brad, bx, by, bw, bh, Color(badgeCol.r, badgeCol.g, badgeCol.b, 150), 1)
                DrawUIText(badge, "HGAppearanceTiny", bx + bw * 0.5, by + bh * 0.5, badgeCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if state.locked and not state.canPurchase then
                DrawRound(rad, 0, 0, w, h, Color(0, 0, 0, 96))
            end
        end

        function card:DoClick()
            local state = self.State or {}

            if state.canPurchase then
                if AP.RequestBuyAccessory then
                    AP.RequestBuyAccessory(accessorKey)
                end

                surface.PlaySound(state.canAfford and "buttons/button14.wav" or "buttons/button10.wav")
                self.NextStateRefresh = 0
                return
            end

            if state.locked then
                surface.PlaySound("buttons/button10.wav")
                return
            end

            if onSelect then
                onSelect(accessorKey)
            end

            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
            menuRef:Close()
        end

        function card:OnCursorEntered()
            menuRef.CurrentPreviewIcon = self
            if onPreview then
                onPreview(accessorKey, true)
            end
        end

        function card:OnCursorExited()
            if menuRef.CurrentPreviewIcon == self then
                menuRef.CurrentPreviewIcon = nil
            end
            if onPreview then
                onPreview(accessorKey, false)
            end
        end

        self:RefreshCardLayout()
        return card
    end

    function menu:AddNoneOption(onSelect)
        local card = vgui.Create("DButton", self.ScrollPanel:GetCanvas())
        card:SetText("")
        card:SetCursor("hand")
        card.HoverFrac = 0

        local menuRef = self

        function card:Paint(w, h)
            self.HoverFrac = UILerp(12, self.HoverFrac or 0, (self:IsHovered() or self:IsDown()) and 1 or 0)

            local rad = math.max(5, SX(10))

            DrawRound(rad, 0, 0, w, h, Color(clr_card.r, clr_card.g, clr_card.b, 235))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 20 + self.HoverFrac * 80), 1)

            local cx, cy = w * 0.5, (h - SX(52)) * 0.5
            local arm = math.min(w, h) * 0.14

            surface.SetDrawColor(clr_dim.r, clr_dim.g, clr_dim.b, 200 + self.HoverFrac * 55)
            surface.DrawLine(cx - arm, cy - arm, cx + arm, cy + arm)
            surface.DrawLine(cx - arm, cy - arm + 1, cx + arm, cy + arm + 1)
            surface.DrawLine(cx - arm, cy + arm, cx + arm, cy - arm)
            surface.DrawLine(cx - arm, cy + arm - 1, cx + arm, cy - arm - 1)

            DrawUIText("СНЯТЬ", "HGAppearanceText", w / 2, h - SX(36), clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawUIText("Очистить слот", "HGAppearanceTiny", w / 2, h - SX(16), clr_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        function card:DoClick()
            if onSelect then
                onSelect("none")
            end
            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
            menuRef:Close()
        end

        self:RefreshCardLayout()
        return card
    end

    function menu:SetChoiceBuilder(builder)
        self.ChoiceBuilder = builder
    end

    function menu:RebuildChoices()
        if not IsValid(self.ScrollPanel) then return end

        local canvas = self.ScrollPanel:GetCanvas()

        for _, child in ipairs(canvas:GetChildren()) do
            if IsValid(child) then
                child.PendingRemoval = true
                child:Remove()
            end
        end

        local bar = self.ScrollPanel:GetVBar()
        if IsValid(bar) then
            bar:SetScroll(0)
        end

        if self.ChoiceBuilder then
            self.ChoiceBuilder(self)
        end

        self:RefreshCardLayout()
    end

    return menu
end

local function GetFilteredAccessories(placements)
    local out = {}

    for id, data in pairs(hg.Accessories or {}) do
        if placements[data.placement] and not data.disallowinappearance then
            out[#out + 1] = GetAccessoryState(id, data)
        end
    end

    local _, mode = GetAccessorySortMode()
    local keyFn = mode and mode.key

    table.sort(out, function(a, b)
        if keyFn then
            local ka = tonumber(keyFn(a)) or 0
            local kb = tonumber(keyFn(b)) or 0
            if ka ~= kb then return ka < kb end
        end

        if a.name ~= b.name then return a.name < b.name end
        return tostring(a.id) < tostring(b.id)
    end)

    return out
end

local function AddAccessoryChoices(menu, placements, onSelect, onPreview)
    menu:SetChoiceBuilder(function(target)
        target:AddNoneOption(function()
            onSelect("none")
        end)

        for _, row in ipairs(GetFilteredAccessories(placements)) do
            local data = row.data
            target:AddAccessoryIcon(data.model or data.femmodel, row.id, data, onSelect, onPreview)
        end
    end)

    menu:RebuildChoices()
end

local function NormalizeAppearanceForEditor(tbl)
    tbl = istable(tbl) and table.Copy(tbl) or table.Copy(AP.SkeletonAppearanceTable or {})
    tbl.AClothes = istable(tbl.AClothes) and tbl.AClothes or {}
    tbl.AAttachments = istable(tbl.AAttachments) and tbl.AAttachments or {}
    tbl.ABodygroups = istable(tbl.ABodygroups) and tbl.ABodygroups or {}
    tbl.AFacemap = tostring(tbl.AFacemap or "По умолчанию")
    tbl.AName = tostring(tbl.AName or "")
    tbl.AColor = IsColor(tbl.AColor) and tbl.AColor or Color((tbl.AColor and tbl.AColor.r) or 255, (tbl.AColor and tbl.AColor.g) or 255, (tbl.AColor and tbl.AColor.b) or 255)
    tbl.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(tbl.AAttachments, LocalPlayer()) or tbl.AAttachments
    return tbl
end

local function GetRenderedAttachments(baseAttachments, previewAttachments)
    local attachments = table.Copy(baseAttachments or {})
    local hasPreview = false

    if istable(previewAttachments) then
        for slot, accessorKey in pairs(previewAttachments) do
            if accessorKey ~= nil then
                hasPreview = true
                attachments[slot] = accessorKey == "none" and "" or accessorKey
            end
        end
    end

    if AP.ClientSanitizeAttachments then
        attachments = AP.ClientSanitizeAttachments(attachments, LocalPlayer(), hasPreview) or attachments
    end

    return attachments
end

local function GetEditorManagedModel()
    local lply = LocalPlayer()
    if not IsValid(lply) then return "" end
    local model = string.Trim(tostring(lply:GetNWString("OTC_DonateModel", "") or ""))
    if model ~= "" and util.IsValidModel(model) then return model end
    return ""
end

local function HasBodygroupAccess(row, name)
    return true
end

function PANEL:SetAppearance(tAppearance)
    self.AppearanceTable = NormalizeAppearanceForEditor(tAppearance)
end

function PANEL:CallbackAppearance()
end

function PANEL:First()
    self:SetY(self:GetY() + self:GetTall())
    self:MoveTo(self:GetX(), self:GetY() - self:GetTall(), 0.4, 0, 0.2)
    self:AlphaTo(255, 0.2, 0.1)

    if self.PostInit then
        self:PostInit()
    end
end

function PANEL:Paint(w, h)
    local mat = self.BGMaterial

    if mat and not mat:IsError() and mat:Width() > 0 and mat:Height() > 0 then
        local iw, ih = mat:Width(), mat:Height()
        local elapsed = RealTime() - (self.BGStartTime or RealTime())
        local zoomWave = math.sin(elapsed * 0.040) * 0.5 + 0.5
        local zoom = 1.20 + zoomWave * 0.16
        local baseScale = math.max(w / iw, h / ih)
        local drawW = iw * baseScale * zoom
        local drawH = ih * baseScale * zoom
        local safeX = math.max((drawW - w) * 0.5, 0)
        local safeY = math.max((drawH - h) * 0.5, 0)
        local panX = math.sin(elapsed * 0.032)
        local panY = math.sin(elapsed * 0.024 + 1.7)
        local x = (w - drawW) * 0.5 + panX * safeX * 0.80
        local y = (h - drawH) * 0.5 + panY * safeY * 0.80

        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, drawW, drawH)
    else
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
    end

    surface.SetDrawColor(1, 4, 8, 132)
    surface.DrawRect(0, 0, w, h)

    local headerX = SX(48)
    local headerY = SX(36)

    surface.SetFont("HGAppearanceBrand")
    local xW = surface.GetTextSize("OT-")
    local brandW = xW + surface.GetTextSize("CITY")

    draw.SimpleText("OT-", "HGAppearanceBrand", headerX + 1, headerY + 2, Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "HGAppearanceBrand", headerX + xW + 1, headerY + 2, Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "HGAppearanceBrand", headerX, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "HGAppearanceBrand", headerX + xW, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local sub = "РЕДАКТОР ВНЕШНОСТИ"
    surface.SetFont("HGAppearanceSmall")

    draw.SimpleText(sub, "HGAppearanceSmall", headerX + SX(2), headerY + SX(52), Color(200, 225, 245, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local stripeY = headerY + SX(52) + SX(18)

    DrawSlant(headerX + SX(2), stripeY, SX(120), math.max(2, SX(3)), SX(8), clr_accent)
    DrawSlant(headerX + SX(134), stripeY, SX(24), math.max(2, SX(3)), SX(8), clr_cyan)
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.CloseButton) then
        local s = SX(46)
        self.CloseButton:SetSize(s, s)
        self.CloseButton:SetPos(w - s - SX(48), SX(40))
    end

    if IsValid(self.ModelSelector) then
        self.ModelSelector:SetSize(SX(420), SX(44))
        self.ModelSelector:SetPos(math.floor((w - SX(420)) * 0.5), SX(36))
    end

    local btnW = SX(300)
    local btnH = SX(44)
    local step = SX(54)
    local leftX = SX(48)
    local rightX = w - SX(48) - btnW
    local startY = math.max(h * 0.30, SX(160))
    local maxY = h - SX(140)

    if self.LeftButtons then
        local needY = startY + (#self.LeftButtons - 1) * step
        if needY > maxY then
            step = math.max(SX(40), (maxY - startY) / math.max(#self.LeftButtons - 1, 1))
        end

        for i, btn in ipairs(self.LeftButtons) do
            btn:SetSize(btnW, btnH)
            btn:SetPos(leftX, math.floor(startY + (i - 1) * step))
        end
    end

    if self.RightButtons then
        local stepR = SX(54)
        local needY = startY + (#self.RightButtons - 1) * stepR
        if needY > maxY then
            stepR = math.max(SX(40), (maxY - startY) / math.max(#self.RightButtons - 1, 1))
        end

        for i, btn in ipairs(self.RightButtons) do
            btn:SetSize(btnW, btnH)
            btn:SetPos(rightX, math.floor(startY + (i - 1) * stepR))
        end
    end
end

function PANEL:PostInit()
    local main = self
    self:SetBorder(false)
    self:SetDraggable(false)
    self.modelPosID = "Все"

    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()

    if IsValid(self.btnClose) then
        self.btnClose:SetVisible(false)
        self.btnClose:SetEnabled(false)
    end

    self.CloseButton = MakeStyledClose(self, function()
        if IsValid(main) then
            main:Close()
        end
        //surface.PlaySound("buttons/button19.wav")
    end)

    self.AppearanceTable = NormalizeAppearanceForEditor(self.AppearanceTable or AP.LoadAppearanceFile() or AP.GetRandomAppearance())
    self.PreviewAttachments = {}

    local viewer = vgui.Create("DModelPanel", self)
    viewer:Dock(FILL)

    local tMdl = AP.PlayerModels[1][self.AppearanceTable.AModel] or AP.PlayerModels[2][self.AppearanceTable.AModel]
    local managedPreviewModel = GetEditorManagedModel()
    viewer:SetModel(util.IsValidModel(managedPreviewModel) and managedPreviewModel or (util.IsValidModel(tostring(tMdl and tMdl.mdl or "")) and tostring(tMdl.mdl) or "models/player/group01/female_01.mdl"))
    viewer:SetFOV(75)
    viewer:SetLookAng(Angle(11, 180, 0))
    viewer:SetCamPos(Vector(100, 0, 55))
    viewer:SetDirectionalLight(BOX_RIGHT, Color(31, 182, 255))
    viewer:SetDirectionalLight(BOX_LEFT, Color(127, 230, 255))
    viewer:SetDirectionalLight(BOX_FRONT, Color(160, 160, 160))
    viewer:SetDirectionalLight(BOX_BACK, Color(0, 0, 0))
    viewer:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
    viewer:SetDirectionalLight(BOX_BOTTOM, Color(0, 0, 0))
    viewer:SetAmbientLight(Color(120, 200, 235, 255))
    viewer:SetMouseInputEnabled(true)

    function viewer:OnMouseWheeled(delta)
        self.SmoothFOVDelta = self:GetFOV() - delta * 5
    end

    local offsets = {
        ["Все"] = 1,
        ["Голова"] = 1.15,
        ["Лицо"] = 1.1,
        ["Торс"] = 0.9,
        ["Ноги"] = 0.4,
        ["Ботинки"] = 0.1,
        ["Руки"] = 0.5
    }

    function viewer:Think()
        self.SmoothFOV = LerpFT(0.05, self.SmoothFOV or self:GetFOV(), main.modelPosID == "Все" and 75 or 35)
        self.LookAngles = LerpFT(0.05, self.LookAngles or 11, main.modelPosID == "Все" and 11 or 0)
        self:SetFOV(self.SmoothFOV)
        self:SetLookAng(Angle(self.LookAngles, 180, 0))
        self.OffsetY = LerpFT(0.1, self.OffsetY or 0, offsets[main.modelPosID] or 1)

        local slideTarget = 0
        if IsValid(main.ActiveAccessoryMenu) then
            slideTarget = (main.ActiveAccessoryMenuSide == "right") and -12 or 12
        end
        self.SideOffset = LerpFT(0.08, self.SideOffset or 0, slideTarget)
    end

    function viewer:LayoutEntity(ent)
        local sw2, sh2 = ScrW(), ScrH()
        local lookX, lookY = input.GetCursorPos()
        lookX = lookX / sw2 - 0.5
        lookY = lookY / sh2 - 0.5

        ent.Angles = ent.Angles or Angle(0, 0, 0)
        ent.Angles = LerpAngle(FrameTime() * 5, ent.Angles, Angle(lookY * 2, (self.Rotate and -179 or 0) - lookX * 75, 0))

        local tbl = main.AppearanceTable
        local modelData = AP.PlayerModels[1][tbl.AModel] or AP.PlayerModels[2][tbl.AModel]
        if not modelData then return end
        local managedPreviewModel = GetEditorManagedModel()
        local renderModel = util.IsValidModel(managedPreviewModel) and managedPreviewModel or modelData.mdl

        ent:SetNWVector("PlayerColor", Vector(tbl.AColor.r / 255, tbl.AColor.g / 255, tbl.AColor.b / 255))
        ent:SetAngles(ent.Angles)
        ent:SetPos(Vector(0, self.SideOffset or 0, 0))
        ent:SetSequence(ent:LookupSequence("idle_suitcase"))
        ent:SetSubMaterial()
        self:SetCamPos(Vector(100, 0, 55 * (self.OffsetY or 1)))

        if ent:GetModel() ~= renderModel then
            ent:SetModel(renderModel)
            self:SetModel(renderModel)
            if renderModel == modelData.mdl then
                tbl.AFacemap = "По умолчанию"
            end
        end

        local mats = ent:GetMaterials()

        for slotName, originalMaterial in pairs(modelData.submatSlots or {}) do
            local slot = 0
            for i = 1, #mats do
                if mats[i] == originalMaterial then
                    slot = i - 1
                    break
                end
            end

            local sexIndex = modelData.sex and 2 or 1
            local clothing = AP.Clothes[sexIndex] and AP.Clothes[sexIndex][tbl.AClothes[slotName]] or nil
            ent:SetSubMaterial(slot, clothing or (AP.Clothes[sexIndex] and AP.Clothes[sexIndex].normal) or nil)
            ent:SetNWString("Colthes" .. slotName, tbl.AClothes[slotName] or "normal")
        end

        if AP.ApplyFacemap then
            AP.ApplyFacemap(ent, ent:GetModel(), tbl.AFacemap, mats)
        else
            for i = 1, #mats do
                if AP.FacemapsSlots[mats[i]] and AP.FacemapsSlots[mats[i]][tbl.AFacemap] ~= nil then
                    ent:SetSubMaterial(i - 1, AP.FacemapsSlots[mats[i]][tbl.AFacemap])
                end
            end
        end

        ent:SetBodyGroups("00000000000000000000")
        local bodygroups = ent:GetBodyGroups()
        tbl.ABodygroups = tbl.ABodygroups or {}

        for k, v in ipairs(bodygroups) do
            local wantedName = tbl.ABodygroups[v.name]
            if not wantedName then continue end
            if not AP.Bodygroups[v.name] or not AP.Bodygroups[v.name][modelData.sex and 2 or 1] then continue end

            local wanted = AP.Bodygroups[v.name][modelData.sex and 2 or 1][wantedName]
            if not wanted then continue end

            for i = 0, #v.submodels do
                if wanted[1] == v.submodels[i] then
                    ent:SetBodygroup(k - 1, i)
                    break
                end
            end
        end
    end

    function viewer:PostDrawModel(ent)
        local tbl = main.AppearanceTable
        local accessories = GetRenderedAttachments(tbl.AAttachments or {}, main.PreviewAttachments)
        local previewAttachments = main.PreviewAttachments or {}

        for slot = 1, 5 do
            local attach = accessories[slot]
            local previewAttach = previewAttachments[slot]
            local isPreviewAttach = previewAttach ~= nil and ((previewAttach == "none" and (attach == "" or attach == "none")) or previewAttach == attach)

            if attach ~= "" and attach ~= "none" and hg.Accessories and hg.Accessories[attach] then
                if isPreviewAttach or not AP.ClientHasAccessoryAccess or AP.ClientHasAccessoryAccess(attach, hg.Accessories[attach], LocalPlayer()) then
                    DrawAccesories(ent, ent, attach, hg.Accessories[attach], false, true)
                end
            end
        end

        ent:SetupBones()
    end

    function viewer.Entity:GetPlayerColor()
        return
    end

    self.Viewer = viewer

    viewer:MoveToBack()

    local modelSelector = vgui.Create("DComboBox", self)
    modelSelector:SetFont("HGAppearanceSmall")
    modelSelector:SetText(main.AppearanceTable.AModel)
    modelSelector:SetContentAlignment(5)
    modelSelector:SetTextColor(clr_text)
    self.ModelSelector = modelSelector

    function modelSelector:Paint(w, h)
        local rad = math.max(4, SX(8))
        DrawRound(rad, 0, 0, w, h, Color(8, 18, 30, 220))
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self:IsHovered() and 150 or 70), 1)
    end

    function modelSelector:OnSelect(_, str)
        main.AppearanceTable.AModel = str
        main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments or {}, LocalPlayer()) or (main.AppearanceTable.AAttachments or {})
        main.AppearanceTable.AFacemap = "По умолчанию"
    end

    for k in pairs(AP.PlayerModels[1] or {}) do
        modelSelector:AddChoice(k)
    end
    for k in pairs(AP.PlayerModels[2] or {}) do
        modelSelector:AddChoice(k)
    end

    local previewAccessory = {}
    local originalAccessory = {}
    local accessoryMenus = {}

    local function CloseAllAccessoryMenus()
        for _, menu in ipairs(accessoryMenus) do
            if IsValid(menu) then
                menu:Close()
            end
        end
        accessoryMenus = {}
    end

    self.CloseAccessoryMenus = CloseAllAccessoryMenus

    local function SetAttachmentInSlot(slot, accessorKey, allowPreview)
        main.AppearanceTable.AAttachments = main.AppearanceTable.AAttachments or {}
        main.PreviewAttachments = main.PreviewAttachments or {}
        main.PreviewAttachments[slot] = nil
        main.AppearanceTable.AAttachments[slot] = accessorKey == "none" and "" or accessorKey

        if allowPreview ~= true then
            main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments, LocalPlayer()) or main.AppearanceTable.AAttachments
        end
    end

    local function MakeSideButton(text, side, focusID, onClick)
        local btn = vgui.Create("DButton", self)
        btn:SetText("")
        btn:SetCursor("hand")
        btn.LabelText = text
        btn.FocusID = focusID
        btn.HoverFrac = 0

        function btn:Paint(w, h)
            local active = main.ActiveButton == self
            self.HoverFrac = UILerp(12, self.HoverFrac or 0, (self:IsHovered() or self:IsDown() or active) and 1 or 0)

            local bg = Color(
                Lerp(self.HoverFrac, clr_card.r, clr_card_hover.r),
                Lerp(self.HoverFrac, clr_card.g, clr_card_hover.g),
                Lerp(self.HoverFrac, clr_card.b, clr_card_hover.b),
                Lerp(self.HoverFrac, clr_card.a, clr_card_hover.a)
            )

            local rad = math.max(4, SX(9))

            DrawRound(rad, 0, 0, w, h, bg)
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 20 + self.HoverFrac * 90), active and math.max(1, SX(2)) or 1)
            DrawRound(1, SX(10), SX(12), math.max(2, SX(3)), h - SX(24), Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + self.HoverFrac * 150))
            DrawUIText(self.LabelText, "HGAppearanceSmall", SX(24), h / 2, active and clr_accent or clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        function btn:DoClick()
            main.ActiveButton = self
            if onClick then
                onClick(self)
            end
        end

        return btn
    end

    local function OpenAccessoryMenu(slot, title, placements, posName, side)
        main.modelPosID = posName
        CloseAllAccessoryMenus()

        side = side or "left"

        local hiddenColumn = (side == "left") and main.RightButtons or main.LeftButtons
        if hiddenColumn then
            for _, b in ipairs(hiddenColumn) do
                if IsValid(b) then b:SetVisible(false) end
            end
        end

        main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments or {}, LocalPlayer()) or (main.AppearanceTable.AAttachments or {})
        originalAccessory[slot] = main.AppearanceTable.AAttachments[slot]

        local menu = CreateStyledAccessoryMenu(nil, title, function()
            main.PreviewAttachments = main.PreviewAttachments or {}
            main.PreviewAttachments[slot] = nil
            if previewAccessory[slot] then
                previewAccessory[slot] = nil
            end
            main.modelPosID = "Все"
            main.ActiveButton = nil
            main.ActiveAccessoryMenu = nil
            main.ActiveAccessoryMenuSide = nil

            if hiddenColumn then
                for _, b in ipairs(hiddenColumn) do
                    if IsValid(b) then b:SetVisible(true) end
                end
            end
        end, side)
        main.ActiveAccessoryMenu = menu
        main.ActiveAccessoryMenuSide = side
        menu.SelectedAccessor = originalAccessory[slot] or ""
        accessoryMenus[#accessoryMenus + 1] = menu

        AddAccessoryChoices(menu, placements,
            function(accessorKey)
                SetAttachmentInSlot(slot, accessorKey)
                previewAccessory[slot] = nil
            end,
            function(accessorKey, isPreviewing)
                main.PreviewAttachments = main.PreviewAttachments or {}
                if isPreviewing then
                    previewAccessory[slot] = accessorKey
                    main.PreviewAttachments[slot] = accessorKey
                else
                    previewAccessory[slot] = nil
                    main.PreviewAttachments[slot] = nil
                end
            end
        )
    end

    self.LeftButtons = {}
    self.RightButtons = {}

    local function AddSide(text, side, focusID, onClick)
        local btn = MakeSideButton(text, side, focusID, onClick)
        if side == "left" then
            self.LeftButtons[#self.LeftButtons + 1] = btn
        else
            self.RightButtons[#self.RightButtons + 1] = btn
        end
        return btn
    end

    AddSide("Головные уборы", "left", "Голова", function()
        OpenAccessoryMenu(1, "Выбор головного убора", {head = true, ears = true}, "Голова", "left")
    end)

    AddSide("Аксессуары лица", "left", "Лицо", function()
        OpenAccessoryMenu(2, "Выбор аксессуара на лицо", {face = true}, "Лицо", "left")
    end)

    AddSide("Аксессуары тела", "left", "Торс", function()
        OpenAccessoryMenu(3, "Выбор аксессуара на тело", {torso = true, spine = true}, "Торс", "left")
    end)

    AddSide("Наушники", "left", "Доп1", function()
        OpenAccessoryMenu(4, "Выбор доп.аксессуара", {headpones = true}, "Доп1", "left")
    end)

    AddSide("Банданы", "left", "Доп2", function()
        OpenAccessoryMenu(5, "Выбор доп.аксессуара", {bandanes = true}, "Доп2", "left")
    end)

    AddSide("Торс", "left", "Торс", function()
        main.modelPosID = "Торс"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1
        local sexTable, torsoGroup = AP.GetBodygroupGroup("sheet", "TORSO", sexIndex)

        if sexTable then
            for name, row in SortedPairs(sexTable) do
                local hasAccess = HasBodygroupAccess(row, name)
                menu:AddOption(hasAccess and name or ("🔒 " .. name), function()
                    if not hasAccess then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end

                    surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                    main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                    main.AppearanceTable.ABodygroups[torsoGroup] = name
                end)
            end
        end

        if #menu:GetCanvas():GetChildren() == 0 then
            menu:AddOption("Нет вариантов торса", function() end):SetEnabled(false)
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Ноги и обувь", "left", "Ноги", function()
        main.modelPosID = "Ноги"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1
        local sexTable, legsGroup = AP.GetBodygroupGroup("pants", "LEGS", sexIndex)
        local shoesTable, shoesGroup = AP.GetBodygroupGroup("shoes", "SHOES", sexIndex)

        local function ExoSanitize()
            main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments or {}, LocalPlayer()) or (main.AppearanceTable.AAttachments or {})
        end

        local function ExoSlot()
            local list = main.AppearanceTable.AAttachments or {}

            for i = 1, 5 do
                if tostring(list[i] or "") == "exojump" then
                    return i
                end
            end
        end

        local function ExoRemove()
            local slot = ExoSlot()
            if not slot then return false end

            main.AppearanceTable.AAttachments = main.AppearanceTable.AAttachments or {}
            main.PreviewAttachments = main.PreviewAttachments or {}

            for i = 1, 5 do
                if tostring(main.AppearanceTable.AAttachments[i] or "") == "exojump" then
                    main.AppearanceTable.AAttachments[i] = ""
                    main.PreviewAttachments[i] = nil
                end
            end

            if originalAccessory then
                for i = 1, 5 do
                    if tostring(originalAccessory[i] or "") == "exojump" then
                        originalAccessory[i] = ""
                    end
                end
            end

            if previewAccessory then
                for i = 1, 5 do
                    if tostring(previewAccessory[i] or "") == "exojump" then
                        previewAccessory[i] = nil
                    end
                end
            end

            ExoSanitize()

            return true
        end

        local function ExoEquip()
            main.AppearanceTable.AAttachments = main.AppearanceTable.AAttachments or {}
            main.PreviewAttachments = main.PreviewAttachments or {}

            local slot = ExoSlot()

            if not slot then
                for i = 5, 1, -1 do
                    local cur = tostring(main.AppearanceTable.AAttachments[i] or "")

                    if cur == "" or cur == "none" then
                        slot = i
                        break
                    end
                end
            end

            slot = slot or 5
            main.PreviewAttachments[slot] = nil
            main.AppearanceTable.AAttachments[slot] = "exojump"
            ExoSanitize()
        end

        if sexTable then
            for name, row in SortedPairs(sexTable) do
                local hasAccess = HasBodygroupAccess(row, name)
                menu:AddOption(hasAccess and name or ("🔒 " .. name), function()
                    if not hasAccess then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end

                    surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                    ExoRemove()
                    main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                    main.AppearanceTable.ABodygroups[legsGroup] = name
                end)
            end
        end

        if shoesTable then
            menu:AddSpacer()

            for name, row in SortedPairs(shoesTable) do
                local hasAccess = HasBodygroupAccess(row, name)
                menu:AddOption(hasAccess and ("Обувь: " .. name) or ("🔒 Обувь: " .. name), function()
                    if not hasAccess then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end

                    surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                    main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                    main.AppearanceTable.ABodygroups[shoesGroup] = name
                end)
            end
        end

        menu:AddSpacer()

        local exoEquipped = ExoSlot() ~= nil

        menu:AddOption(exoEquipped and "Экзо-Ботинки [надеты]" or "Экзо-Ботинки", function()
            if ExoSlot() then
                ExoRemove()
            else
                ExoEquip()
            end

            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
        end)

        menu:AddOption("Снять Экзо-Ботинки", function()
            if not ExoRemove() then
                surface.PlaySound("buttons/button10.wav")
                return
            end

            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
        end):SetEnabled(exoEquipped)

        if #menu:GetCanvas():GetChildren() == 0 then
            menu:AddOption("Нет вариантов ног и обуви", function() end):SetEnabled(false)
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Куртка", "right", "Торс", function()
        main.modelPosID = "Торс"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1

        for k in SortedPairs(AP.Clothes[sexIndex] or {}) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.main = k
            end)

            function mater:OnCursorEntered()
                OpenClothesPreviewCard(main.AppearanceTable, "main", k)
            end

            function mater:OnCursorExited()
                CloseClothesPreviewCard()
            end

            if AP.ClothesDesc and AP.ClothesDesc[k] then
                mater:SetTooltip(AP.ClothesDesc[k].desc or "")
                if AP.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(AP.ClothesDesc[k].link)
                    end
                end
            end
        end

        local colorSelector = vgui.Create("DColorCombo", menu)
        function colorSelector:OnValueChanged(clr)
            main.AppearanceTable.AColor = clr
        end
        colorSelector:SetColor(main.AppearanceTable.AColor)
        menu:AddPanel(colorSelector)
        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Штаны", "right", "Ноги", function()
        main.modelPosID = "Ноги"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1

        for k in SortedPairs(AP.Clothes[sexIndex] or {}) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.pants = k
            end)

            function mater:OnCursorEntered()
                OpenClothesPreviewCard(main.AppearanceTable, "pants", k)
            end

            function mater:OnCursorExited()
                CloseClothesPreviewCard()
            end

            if AP.ClothesDesc and AP.ClothesDesc[k] then
                mater:SetTooltip(AP.ClothesDesc[k].desc or "")
                if AP.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(AP.ClothesDesc[k].link)
                    end
                end
            end
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Ботинки", "right", "Ботинки", function()
        main.modelPosID = "Ботинки"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1

        for k in SortedPairs(AP.Clothes[sexIndex] or {}) do
            local mater = menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AClothes.boots = k
            end)

            function mater:OnCursorEntered()
                OpenClothesPreviewCard(main.AppearanceTable, "boots", k)
            end

            function mater:OnCursorExited()
                CloseClothesPreviewCard()
            end

            if AP.ClothesDesc and AP.ClothesDesc[k] then
                mater:SetTooltip(AP.ClothesDesc[k].desc or "")
                if AP.ClothesDesc[k].link then
                    function mater:DoRightClick()
                        gui.OpenURL(AP.ClothesDesc[k].link)
                    end
                end
            end
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Перчатки", "right", "Руки", function()
        main.modelPosID = "Руки"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local sexIndex = currentModel and (currentModel.sex and 2 or 1) or 1

        for k, v in SortedPairs(AP.Bodygroups.HANDS[sexIndex] or {}) do
            local hasAccess = HasBodygroupAccess(v, k)
            menu:AddOption(hasAccess and k or ("🔒 " .. k), function()
                if not hasAccess then
                    surface.PlaySound("buttons/button10.wav")
                    return
                end

                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
                main.AppearanceTable.ABodygroups.HANDS = k
            end)
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    AddSide("Лицо", "right", "Лицо", function()
        main.modelPosID = "Лицо"
        local currentModel = AP.PlayerModels[1][main.AppearanceTable.AModel] or AP.PlayerModels[2][main.AppearanceTable.AModel]
        local menu = DermaMenu()
        local facemaps = (currentModel and AP.GetModelFacemaps and AP.GetModelFacemaps(currentModel.mdl)) or (AP.FacemapsSlots and AP.FacemapsModels and currentModel and AP.FacemapsSlots[AP.FacemapsModels[currentModel.mdl]]) or {}

        for k in SortedPairs(facemaps or {}) do
            menu:AddOption(k, function()
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
                main.AppearanceTable.AFacemap = k
            end)
        end

        menu:Open()

        function menu:OnRemove()
            main.modelPosID = "Все"
            main.ActiveButton = nil
            CloseClothesPreviewCard()
        end
    end)

    local function MakeBottomButton(text, w, onClick, danger)
        local btn = vgui.Create("DButton", self.CurrentBar)
        btn:SetText("")
        btn:SetCursor("hand")
        btn:SetWide(w)
        btn:Dock(LEFT)
        btn:DockMargin(0, 0, SX(12), 0)
        btn.LabelText = text
        btn.Danger = danger == true
        btn.HoverFrac = 0

        function btn:Paint(pw, ph)
            self.HoverFrac = UILerp(12, self.HoverFrac or 0, (self:IsHovered() or self:IsDown()) and 1 or 0)

            local accent = self.Danger and clr_danger or clr_accent
            local bg = Color(
                Lerp(self.HoverFrac, 10, self.Danger and 40 or 14),
                Lerp(self.HoverFrac, 30, self.Danger and 18 or 60),
                Lerp(self.HoverFrac, 48, self.Danger and 20 or 96),
                200 + self.HoverFrac * 55
            )

            local rad = math.max(5, SX(10))

            DrawRound(rad, 0, 0, pw, ph, bg)

            if self.HoverFrac > 0.01 then
                DrawRoundOutlined(rad, 0, 0, pw, ph, Color(accent.r, accent.g, accent.b, self.HoverFrac * 45), math.max(3, SX(6)))
            end

            DrawRoundOutlined(rad, 0, 0, pw, ph, Color(accent.r, accent.g, accent.b, 90 + self.HoverFrac * 130), 1)
            DrawUIText(self.LabelText, "HGAppearanceSmall", pw / 2, ph / 2, clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        function btn:DoClick()
            if onClick then onClick() end
        end

        return btn
    end

    local function MakeBottomEntry(placeholder, w, onChange)
        local entry = vgui.Create("DTextEntry", self.CurrentBar)
        entry:SetWide(w)
        entry:Dock(LEFT)
        entry:DockMargin(0, 0, SX(12), 0)
        entry:SetFont("HGAppearanceSmall")
        entry:SetTextColor(clr_text)
        entry:SetPlaceholderText(placeholder)
        entry:SetContentAlignment(5)
        entry:SetCursorColor(clr_accent)

        function entry:Paint(pw, ph)
            local rad = math.max(5, SX(10))
            DrawRound(rad, 0, 0, pw, ph, Color(6, 12, 20, 220))
            DrawRoundOutlined(rad, 0, 0, pw, ph, Color(clr_accent.r, clr_accent.g, clr_accent.b, self:HasFocus() and 150 or 50), 1)
            self:DrawTextEntryText(clr_text, clr_accent, clr_text)
        end

        function entry:OnChange()
            if onChange then onChange(self:GetValue()) end
        end

        return entry
    end

    self.BottomBar1 = vgui.Create("DPanel", self)
    self.BottomBar1.Paint = nil

    self.BottomBar2 = vgui.Create("DPanel", self)
    self.BottomBar2.Paint = nil

    local bar1 = self.BottomBar1
    local bar2 = self.BottomBar2

    bar1:SetTall(SX(52))
    bar2:SetTall(SX(44))

    self.CurrentBar = self.BottomBar1

    local oldPerform = self.PerformLayout

    function self:PerformLayout(w, h)
        oldPerform(self, w, h)

        if IsValid(bar1) and IsValid(bar2) then
            bar2:SizeToChildren(true, false)
            bar2:SetWide(math.min(bar2:GetWide(), w - SX(96)))
            bar2:SetPos(math.floor((w - bar2:GetWide()) * 0.5), h - SX(44) - SX(14))

            bar1:SizeToChildren(true, false)
            bar1:SetWide(math.min(bar1:GetWide(), w - SX(96)))
            bar1:SetPos(math.floor((w - bar1:GetWide()) * 0.5), h - SX(44) - SX(14) - SX(52) - SX(10))
        end
    end

    MakeBottomButton("Повернуть", SX(180), function()
        viewer.Rotate = not viewer.Rotate
        surface.PlaySound("pwb2/weapons/iron.wav")
    end)

    MakeBottomEntry("Имя персонажа...", SX(360), function(val)
        main.AppearanceTable.AName = val
    end):SetText(main.AppearanceTable.AName)

    MakeBottomButton("Применить", SX(220), function()
        main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments or {}, LocalPlayer()) or (main.AppearanceTable.AAttachments or {})
        AP.CreateAppearanceFile(nil, main.AppearanceTable)

        net.Start("OnlyGet_Appearance")
            net.WriteTable(main.AppearanceTable)
        net.SendToServer()

        surface.PlaySound("pwb2/weapons/iron.wav")
    end)

    self.CurrentBar = self.BottomBar2

    local presetNameEntry

    MakeBottomButton("Сохранить", SX(170), function()
        local presetName = presetNameEntry:GetValue()
        if presetName == "" or #presetName < 2 then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Введите имя пресета минимум из 2 символов", NOTIFY_ERROR, 3)
            return
        end

        presetName = NormalizePresetName(presetName)
        if presetName == "" then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Некорректное имя пресета", NOTIFY_ERROR, 3)
            return
        end

        main.AppearanceTable.AAttachments = AP.ClientSanitizeAttachments and AP.ClientSanitizeAttachments(main.AppearanceTable.AAttachments or {}, LocalPlayer()) or (main.AppearanceTable.AAttachments or {})
        SavePreset(presetName, main.AppearanceTable)
        surface.PlaySound("buttons/button14.wav")
        notification.AddLegacy("Пресет '" .. presetName .. "' сохранён", NOTIFY_GENERIC, 3)
    end)

    MakeBottomButton("Загрузить", SX(170), function()
        local presetList = GetPresetList()
        if #presetList == 0 then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Сохранённых пресетов пока нет", NOTIFY_ERROR, 3)
            return
        end

        local menuW = math.min(SX(440), ScrW() - SX(96))
        local menuH = math.min(SX(420), ScrH() - SX(140))

        local presetMenu = vgui.Create("EditablePanel")
        presetMenu:SetSize(menuW, menuH)
        presetMenu:SetPos(math.floor((ScrW() - menuW) * 0.5), math.floor((ScrH() - menuH) * 0.5))
        presetMenu:MakePopup()

        function presetMenu:Paint(w, h)
            DrawRound(SX(12), 0, 0, w, h, clr_panel)
            DrawRoundOutlined(SX(12), 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 90), 1)

            DrawRound(SX(12), 0, 0, w, SX(56), Color(8, 18, 30, 200))
            DrawUIText("Загрузка пресета", "HGAppearanceTitle", SX(24), SX(28), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawRound(SX(3), SX(24), SX(50), SX(120), math.max(2, SX(3)), Color(clr_accent.r, clr_accent.g, clr_accent.b, 190))
        end

        presetMenu.CloseButton = MakeStyledClose(presetMenu, function()
            presetMenu:Remove()
        end)

        function presetMenu:PerformLayout(w, h)
            if IsValid(self.CloseButton) then
                local s = SX(40)
                self.CloseButton:SetSize(s, s)
                self.CloseButton:SetPos(w - s - SX(12), SX(8))
            end
        end

        local scroll = CreateStyledScrollPanel(presetMenu)
        scroll:Dock(FILL)
        scroll:DockMargin(SX(16), SX(56) + SX(10), SX(16), SX(16))

        for _, presetName in ipairs(presetList) do
            local presetBtn = vgui.Create("DButton", scroll)
            presetBtn:Dock(TOP)
            presetBtn:DockMargin(0, 0, SX(6), SX(8))
            presetBtn:SetTall(SX(40))
            presetBtn:SetText("")
            presetBtn:SetCursor("hand")
            presetBtn.HoverFrac = 0
            presetBtn.PresetName = presetName

            function presetBtn:Paint(w, h)
                self.HoverFrac = UILerp(12, self.HoverFrac or 0, self:IsHovered() and 1 or 0)

                local rad = math.max(4, SX(8))

                DrawRound(rad, 0, 0, w, h, Color(
                    Lerp(self.HoverFrac, clr_card.r, clr_card_hover.r),
                    Lerp(self.HoverFrac, clr_card.g, clr_card_hover.g),
                    Lerp(self.HoverFrac, clr_card.b, clr_card_hover.b),
                    230
                ))
                DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 20 + self.HoverFrac * 80), 1)
                DrawRound(1, SX(8), SX(10), math.max(2, SX(2)), h - SX(20), Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + self.HoverFrac * 120))
                DrawUIText(self.PresetName, "HGAppearanceSmall", SX(20), h / 2, clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            function presetBtn:DoClick()
                local loadedPreset = LoadPreset(presetName)
                if loadedPreset then
                    main.AppearanceTable = NormalizeAppearanceForEditor(loadedPreset)
                    modelSelector:SetText(main.AppearanceTable.AModel or "Мужчина 01")
                    presetNameEntry:SetText(presetName)
                    surface.PlaySound("buttons/button14.wav")
                    notification.AddLegacy("Пресет '" .. presetName .. "' загружен", NOTIFY_GENERIC, 3)
                else
                    surface.PlaySound("buttons/button10.wav")
                    notification.AddLegacy("Не удалось загрузить пресет", NOTIFY_ERROR, 3)
                end
                presetMenu:Remove()
            end

            function presetBtn:DoRightClick()
                local confirmMenu = DermaMenu()
                confirmMenu:AddOption("Удалить '" .. presetName .. "'", function()
                    DeletePreset(presetName)
                    surface.PlaySound("buttons/button15.wav")
                    notification.AddLegacy("Пресет удалён", NOTIFY_HINT, 2)
                    presetBtn:Remove()
                end):SetIcon("icon16/cross.png")
                confirmMenu:Open()
            end
        end
    end)

    MakeBottomButton("Удалить", SX(150), function()
        local presetName = presetNameEntry:GetValue()
        if presetName == "" then
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Введите имя пресета для удаления", NOTIFY_ERROR, 3)
            return
        end

        if DeletePreset(presetName) then
            surface.PlaySound("buttons/button15.wav")
            notification.AddLegacy("Запрос на удаление пресета отправлен", NOTIFY_HINT, 3)
            presetNameEntry:SetText("")
        else
            surface.PlaySound("buttons/button10.wav")
            notification.AddLegacy("Не удалось удалить пресет", NOTIFY_ERROR, 3)
        end
    end, true)

    presetNameEntry = MakeBottomEntry("Имя пресета...", SX(260))

    bar1:SizeToChildren(true, false)
    bar2:SizeToChildren(true, false)

    local oldClose = self.Close
    function self:Close()
        CloseAllAccessoryMenus()
        if oldClose then
            oldClose(self)
        end
    end

    if IsValid(self.CloseButton) then
        self.CloseButton:MoveToFront()
    end

    self:InvalidateLayout(true)

    self:CallbackAppearance()
end

vgui.Register("HG_AppearanceMenu", PANEL, "ZFrame")

function hg.CreateApperanceMenu(parentPanel)
    if AP.PrecacheModels then
        AP.PrecacheModels()
    end

    if IsValid(zpan) then
        zpan:Close()
    end

    zpan = vgui.Create("HG_AppearanceMenu", parentPanel)
    zpan:SetSize(parentPanel:GetWide(), parentPanel:GetTall())
    zpan:SetPos(0, 0)
end

concommand.Add("hg_appearance_menu", function()
    if AP.PrecacheModels then
        AP.PrecacheModels()
    end

    net.Start("hg_appearance_presets_request")
    net.SendToServer()

    if IsValid(zpan) then
        zpan:Close()
    end

    zpan = vgui.Create("HG_AppearanceMenu")
    zpan:SetSize(ScrW(), ScrH())
    zpan:SetPos(0, 0)
    zpan:MakePopup()
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "appearance editor loaded\n")
