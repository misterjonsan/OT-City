if SERVER then return end

timer.Simple(0.1, function()

local RNDX = _G.RNDX or _G.gSims_RNDX or include("libnyx/lib/rndx.lua")

hg = hg or {}
hg.Market = hg.Market or {}
hg.MarketConfig = hg.MarketConfig or {}

local MK = hg.Market
local CFG = hg.MarketConfig

local state = {
    raw = nil,
    listings = {},
    mine = {},
    sellable = {},
    history = {},
    stats = {},
    frame = nil,
    tab = "market",
    search = "",
    placement = "all",
    sort = "new",
    sellUID = nil,
    confirm = nil,
    lastRequest = 0,
    signature = ""
}

local palette = {
    bg = Color(3, 5, 9, 250),
    panel = Color(6, 11, 19, 246),
    card = Color(8, 14, 24, 245),
    cardHover = Color(14, 26, 42, 250),
    line = Color(28, 48, 72, 190),
    text = Color(238, 246, 255),
    muted = Color(146, 184, 216),
    dim = Color(96, 126, 152),
    accent = Color(31, 182, 255),
    cyan = Color(127, 230, 255),
    gold = Color(255, 196, 84),
    good = Color(72, 226, 158),
    bad = Color(255, 92, 104),
    shadow = Color(0, 0, 0, 220)
}

local fontScale = math.Clamp(ScrH() / 900, 0.82, 1.15)

local function FontSize(size)
    return math.max(10, math.floor(size * fontScale))
end

surface.CreateFont("HGMarket.Brand", {font = "Bahnschrift", size = FontSize(38), weight = 800, italic = true, antialias = true, extended = true})
surface.CreateFont("HGMarket.Title", {font = "Montserrat SemiBold", size = FontSize(28), weight = 700, extended = true})
surface.CreateFont("HGMarket.Heading", {font = "Montserrat SemiBold", size = FontSize(22), weight = 700, extended = true})
surface.CreateFont("HGMarket.Medium", {font = "Montserrat Medium", size = FontSize(18), weight = 500, extended = true})
surface.CreateFont("HGMarket.Small", {font = "Montserrat Medium", size = FontSize(15), weight = 500, extended = true})
surface.CreateFont("HGMarket.Tiny", {font = "Montserrat SemiBold", size = FontSize(13), weight = 600, extended = true})
surface.CreateFont("HGMarket.Price", {font = "Montserrat SemiBold", size = FontSize(23), weight = 700, extended = true})
surface.CreateFont("HGMarket.Close", {font = "Montserrat SemiBold", size = FontSize(30), weight = 800, antialias = true, extended = true})

local function Scale(value)
    return math.floor(value * math.min(ScrW() / 1600, ScrH() / 900))
end

local function C(col, alpha)
    return Color(col.r, col.g, col.b, alpha == nil and col.a or alpha)
end

local function Mix(fraction, a, b)
    return Color(Lerp(fraction, a.r, b.r), Lerp(fraction, a.g, b.g), Lerp(fraction, a.b, b.b), Lerp(fraction, a.a or 255, b.a or 255))
end

local function Box(radius, x, y, w, h, col)
    RNDX.Draw(math.min(radius, math.floor(math.min(w, h) * 0.5)), x, y, w, h, col)
end

local function Outline(radius, x, y, w, h, col, thickness)
    RNDX.DrawOutlined(math.min(radius, math.floor(math.min(w, h) * 0.5)), x, y, w, h, col, thickness or 1)
end

local function Line(x, y, w, h, col)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.DrawRect(math.floor(x), math.floor(y), math.max(1, math.floor(w)), math.max(1, math.floor(h)))
end

local function Strip(panel, radius, x, y, w, thickness, col)
    if not IsValid(panel) then return end

    local sx, sy = panel:LocalToScreen(math.floor(x), math.floor(y))

    render.SetScissorRect(sx, sy, sx + math.floor(w), sy + math.floor(thickness), true)
    Box(radius, x, y, w, radius * 2 + thickness * 2, col)
    render.SetScissorRect(0, 0, 0, 0, false)
end

local function Shadow(radius, x, y, w, h, col, spread, intensity)
    RNDX.DrawShadows(radius, x, y, w, h, col, spread or 12, intensity or 18)
end

local function Text(text, font, x, y, col, ax, ay)
    local value = tostring(text or "")
    draw.SimpleText(value, font, x + 1, y + 1, Color(0, 0, 0, math.min(190, col.a or 255)), ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
    draw.SimpleText(value, font, x, y, col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

local function Clip(text, font, width)
    surface.SetFont(font)

    local value = tostring(text or "")
    if surface.GetTextSize(value) <= width then return value end

    while #value > 1 and surface.GetTextSize(value .. "...") > width do
        value = string.sub(value, 1, #value - 1)
    end

    return value .. "..."
end

local function Wrapped(text, font, width)
    surface.SetFont(font)

    local lines, line = {}, ""

    for _, word in ipairs(string.Explode(" ", tostring(text or ""))) do
        local test = line == "" and word or line .. " " .. word

        if surface.GetTextSize(test) > width and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end

    if line ~= "" then lines[#lines + 1] = line end

    return lines
end

local function TextWrap(text, font, x, y, width, col, maxLines)
    local lines = Wrapped(text, font, width)

    surface.SetFont(font)
    local _, lineHeight = surface.GetTextSize("Wg")

    for i, line in ipairs(lines) do
        if maxLines and i > maxLines then break end
        if maxLines and i == maxLines and #lines > maxLines then line = line .. "..." end

        Text(line, font, x, y + (i - 1) * (lineHeight + Scale(3)), col)
    end
end

local function Coin(x, y, size, col)
    local radius = math.max(4, math.floor(size * 0.5))

    RNDX.DrawCircle(x, y, radius, col or palette.accent)
    RNDX.DrawCircleOutlined(x, y, radius, Color(210, 240, 255, 140), 1)
end

local function Money(value)
    return MK.FormatNumber(value)
end

local function TierColor(price)
    price = tonumber(price) or 0

    if price >= 100000 then return palette.gold end
    if price >= 25000 then return Color(196, 130, 255) end
    if price >= 8000 then return palette.cyan end

    return palette.accent
end

local function TimeAgo(stamp)
    stamp = tonumber(stamp) or 0
    if stamp <= 0 then return "недавно" end

    local diff = math.max(0, os.time() - stamp)

    if diff < 60 then return "только что" end
    if diff < 3600 then return math.floor(diff / 60) .. " мин назад" end
    if diff < 86400 then return math.floor(diff / 3600) .. " ч назад" end

    return math.floor(diff / 86400) .. " дн назад"
end

local function Notify(text, isError)
    notification.AddLegacy(tostring(text or ""), isError and NOTIFY_ERROR or NOTIFY_GENERIC, 5)
    surface.PlaySound(isError and "buttons/button10.wav" or "buttons/button14.wav")
end

local function Request(full)
    if not full and RealTime() - state.lastRequest < 1.6 then return end

    state.lastRequest = RealTime()
    MK.Emit("Request", {full = full == true})
end

local function Balance()
    return state.raw and math.floor(tonumber(state.raw.balance) or 0) or 0
end

local function Limits()
    local data = state.raw or {}

    return {
        maxListings = math.floor(tonumber(data.maxListings) or tonumber(CFG.MaxListingsPerPlayer) or 8),
        fee = tonumber(data.fee) or tonumber(CFG.Fee) or 0.05,
        maxDescription = math.floor(tonumber(data.maxDescription) or tonumber(CFG.MaxDescription) or 180),
        expireDays = math.floor(tonumber(data.expireDays) or tonumber(CFG.ExpireDays) or 21),
        minPrice = math.floor(tonumber(data.minPrice) or tonumber(CFG.MinPrice) or 50),
        maxPrice = math.floor(tonumber(data.maxPrice) or tonumber(CFG.MaxPrice) or 5000000)
    }
end

local function StatOf(uid)
    return state.stats[tostring(uid or "")]
end

local function Average(uid)
    local stat = StatOf(uid)
    if not istable(stat) then return 0 end

    local sales = math.floor(tonumber(stat.n) or 0)
    local avg = math.floor(tonumber(stat.a) or 0)

    if sales <= 0 or avg <= 0 then return 0 end

    return avg
end

local function AverageText(uid)
    return MK.AverageText(StatOf(uid))
end

local function Verdict(price, uid)
    local result = MK.PriceVerdict(price, StatOf(uid))

    if result == "cheap" then return "Ниже средней", palette.good end
    if result == "expensive" then return "Выше средней", palette.bad end
    if result == "fair" then return "Цена в рынке", palette.cyan end

    return "Средняя неизвестна", palette.dim
end

local function Adapt(payload)
    state.raw = istable(payload) and payload or {}
    state.stats = istable(state.raw.stats) and state.raw.stats or {}
    state.listings = {}
    state.mine = {}
    state.sellable = {}
    state.history = {}

    for _, row in ipairs(state.raw.listings or {}) do
        local uid = tostring(row.u or "")
        local source = tostring(row.o or "market")
        local isModel = source == "model"
        local title = tostring(row.n or "")
        local model = tostring(row.w or "")

        local entry = {
            id = math.floor(tonumber(row.i) or 0),
            uid = uid,
            name = (isModel and title ~= "") and title or MK.AccessoryName(uid),
            model = (isModel and model ~= "") and model or MK.AccessoryModel(uid),
            placement = isModel and "model" or MK.AccessoryPlacement(uid),
            source = source,
            price = math.floor(tonumber(row.p) or 0),
            payout = math.floor(tonumber(row.y) or 0),
            descr = tostring(row.d or ""),
            seller = tostring(row.s or "Игрок"),
            created = math.floor(tonumber(row.c) or 0),
            mine = math.floor(tonumber(row.m) or 0) == 1
        }

        state.listings[#state.listings + 1] = entry

        if entry.mine then state.mine[#state.mine + 1] = entry end
    end

    for _, row in ipairs(state.raw.sellable or {}) do
        local uid = tostring(row.u or "")

        state.sellable[#state.sellable + 1] = {
            uid = uid,
            name = MK.AccessoryName(uid),
            model = MK.AccessoryModel(uid),
            placement = MK.AccessoryPlacement(uid),
            source = tostring(row.o or "coin")
        }
    end

    for _, row in ipairs(state.raw.models or {}) do
        local uid = tostring(row.u or "")
        local title = tostring(row.n or "")
        local model = tostring(row.w or "")

        if uid ~= "" then
            state.sellable[#state.sellable + 1] = {
                uid = uid,
                name = title ~= "" and title or "Личная моделька",
                model = model ~= "" and model or "models/error.mdl",
                placement = "model",
                source = "model"
            }
        end
    end

    table.sort(state.sellable, function(a, b)
        if a.placement ~= b.placement then return a.placement == "model" end

        return a.name < b.name
    end)

    for _, row in ipairs(state.raw.history or {}) do
        local uid = tostring(row.u or "")

        state.history[#state.history + 1] = {
            kind = tostring(row.k or "bought"),
            uid = uid,
            name = MK.AccessoryName(uid),
            model = MK.AccessoryModel(uid),
            price = math.floor(tonumber(row.p) or 0),
            payout = math.floor(tonumber(row.y) or 0),
            time = math.floor(tonumber(row.t) or 0),
            other = tostring(row.o or "")
        }
    end

    if state.sellUID then
        local found = false

        for _, entry in ipairs(state.sellable) do
            if entry.uid == state.sellUID then
                found = true
                break
            end
        end

        if not found then state.sellUID = nil end
    end

    local parts = {}

    for _, entry in ipairs(state.listings) do
        parts[#parts + 1] = entry.id .. ":" .. entry.price
    end

    for _, entry in ipairs(state.sellable) do
        parts[#parts + 1] = "s" .. entry.uid
    end

    parts[#parts + 1] = "h" .. #state.history
    parts[#parts + 1] = "b" .. Balance()

    local signature = table.concat(parts, ",")
    local changed = signature ~= state.signature

    state.signature = signature

    return changed
end

local function StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(Scale(6))
    bar:SetHideButtons(true)

    bar.Paint = function(_, w, h)
        Box(Scale(4), 0, 0, w, h, Color(255, 255, 255, 8))
    end

    bar.btnGrip.Paint = function(_, w, h)
        Box(Scale(4), 0, 0, w, h, C(palette.accent, 170))
    end
end

local iconFrame = -1
local iconBudget = 0

local function MakeIcon(parent, model, size)
    local holder = vgui.Create("DPanel", parent)
    holder:SetSize(size, size)
    holder:SetMouseInputEnabled(false)
    holder.Model = tostring(model or "models/error.mdl")
    holder.Spin = 0

    holder.Paint = function(self, w, h)
        if IsValid(self.Icon) then return end

        self.Spin = self.Spin + FrameTime() * 2

        Box(Scale(8), 0, 0, w, h, Color(255, 255, 255, 8))
        Coin(w * 0.5 + math.cos(self.Spin) * Scale(10), h * 0.5 + math.sin(self.Spin) * Scale(10), Scale(8), C(palette.accent, 200))
    end

    holder.Think = function(self)
        if IsValid(self.Icon) then return end
        if not self:IsVisible() then return end

        local _, y = self:LocalToScreen(0, 0)

        if y + size < -size or y > ScrH() + size then return end

        local frameNumber = FrameNumber()

        if iconFrame ~= frameNumber then
            iconFrame = frameNumber
            iconBudget = 0
        end

        if iconBudget >= 2 then return end

        iconBudget = iconBudget + 1

        local icon = vgui.Create("SpawnIcon", self)
        icon:SetSize(size, size)
        icon:SetPos(0, 0)
        icon:SetModel(self.Model)
        icon:SetMouseInputEnabled(false)
        icon:SetTooltip(nil)
        icon.PaintOver = function() end

        self.Icon = icon
    end

    holder.SetIconModel = function(self, value)
        value = tostring(value or "models/error.mdl")

        if self.Model == value then return end

        self.Model = value

        if IsValid(self.Icon) then
            self.Icon:SetModel(value)
        end
    end

    return holder
end

local function MakeButton(parent, label, col, callback)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button.Alpha = 0
    button.Label = label
    button.Color = col

    button.Paint = function(self, w, h)
        local target = self:IsHovered() and 255 or 165
        self.Alpha = Lerp(FrameTime() * 12, self.Alpha, target)

        Box(Scale(8), 0, 0, w, h, C(self.Color, self.Alpha * 0.16))
        Outline(Scale(8), 0, 0, w, h, C(self.Color, self.Alpha))
        Text(self.Label, "HGMarket.Tiny", w * 0.5, h * 0.5, C(self.Color, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    button.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        callback()
    end

    return button
end

local function MakeEntry(parent, placeholder, numeric)
    local entry = vgui.Create("DTextEntry", parent)
    entry:SetFont("HGMarket.Small")
    entry:SetDrawBackground(false)
    entry:SetTextColor(palette.text)
    entry:SetCursorColor(palette.accent)
    entry:SetPaintBackground(false)
    entry:SetNumeric(numeric == true)
    entry:SetUpdateOnType(true)

    entry.Paint = function(self, w, h)
        Box(Scale(8), 0, 0, w, h, Color(255, 255, 255, 10))
        Outline(Scale(8), 0, 0, w, h, self:HasFocus() and C(palette.accent, 190) or C(palette.line, 160))

        if self:GetText() == "" and not self:HasFocus() then
            Text(placeholder, "HGMarket.Small", Scale(10), h * 0.5 - Scale(8), C(palette.dim, 220))
        end

        self:DrawTextEntryText(palette.text, C(palette.accent, 120), palette.text)
    end

    return entry
end

local function Confirm(entry)
    state.confirm = entry

    if IsValid(state.frame) and isfunction(state.frame.BuildConfirm) then
        state.frame:BuildConfirm()
    end
end

local function FilteredListings(source)
    local out = {}
    local search = string.lower(string.Trim(state.search or ""))

    for _, entry in ipairs(source or {}) do
        local matchPlacement = state.placement == "all" or tostring(entry.placement or "") == state.placement
        local haystack = string.lower(tostring(entry.name or "") .. " " .. tostring(entry.seller or "") .. " " .. tostring(entry.uid or "") .. " " .. tostring(entry.descr or ""))
        local matchSearch = search == "" or string.find(haystack, search, 1, true) ~= nil

        if matchPlacement and matchSearch then
            out[#out + 1] = entry
        end
    end

    if state.sort == "cheap" then
        table.sort(out, function(a, b) return (a.price or 0) < (b.price or 0) end)
    elseif state.sort == "expensive" then
        table.sort(out, function(a, b) return (a.price or 0) > (b.price or 0) end)
    elseif state.sort == "name" then
        table.sort(out, function(a, b) return tostring(a.name or "") < tostring(b.name or "") end)
    elseif state.sort == "deal" then
        table.sort(out, function(a, b)
            local avgA = Average(a.uid)
            local avgB = Average(b.uid)
            local ratioA = avgA > 0 and (a.price / avgA) or 9999
            local ratioB = avgB > 0 and (b.price / avgB) or 9999

            if math.abs(ratioA - ratioB) > 0.0001 then return ratioA < ratioB end

            return (a.price or 0) < (b.price or 0)
        end)
    else
        table.sort(out, function(a, b) return (a.id or 0) > (b.id or 0) end)
    end

    return out
end

local function Stream(layout, entries, builder, perFrame)
    layout.Pending = entries
    layout.Cursor = 1
    layout.PerFrame = perFrame or 6

    layout.Think = function(self)
        if not istable(self.Pending) then return end

        local added = 0

        while self.Cursor <= #self.Pending and added < self.PerFrame do
            builder(self.Pending[self.Cursor], self.Cursor)
            self.Cursor = self.Cursor + 1
            added = added + 1
        end

        if self.Cursor > #self.Pending then
            self.Pending = nil
            self:InvalidateLayout(true)
        end
    end
end

local function BuildListingCard(parent, entry, cardW, cardH, mineMode)
    local card = vgui.Create("DPanel", parent)
    card:SetSize(cardW, cardH)
    card.Hover = 0

    if tostring(entry.descr or "") ~= "" then
        card:SetTooltip(entry.descr)
    end

    local accent = TierColor(entry.price)
    local radius = Scale(10)
    local iconSize = math.floor(cardH * 0.44)
    local icon = MakeIcon(card, entry.model, iconSize)
    icon:SetPos(math.floor((cardW - iconSize) * 0.5), Scale(8))

    card.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 10, self.Hover, self:IsHovered() and 1 or 0)

        Shadow(radius, 0, 0, w, h, C(palette.shadow, 160), 10, 12)
        Box(radius, 0, 0, w, h, Mix(self.Hover, palette.card, palette.cardHover))
        Strip(self, radius, 0, 0, w, Scale(3), C(accent, 210))
        Outline(radius, 0, 0, w, h, C(accent, 55 + self.Hover * 125))

        local top = iconSize + Scale(12)
        local label, color = Verdict(entry.price, entry.uid)

        Text(Clip(entry.name, "HGMarket.Small", w - Scale(16)), "HGMarket.Small", w * 0.5, top, palette.text, TEXT_ALIGN_CENTER)
        Text(MK.PlacementLabel(entry.placement) .. " • " .. MK.SourceLabel(entry.source), "HGMarket.Tiny", w * 0.5, top + Scale(19), C(palette.dim, 235), TEXT_ALIGN_CENTER)
        Text("средняя " .. AverageText(entry.uid), "HGMarket.Tiny", w * 0.5, top + Scale(36), C(palette.cyan, 235), TEXT_ALIGN_CENTER)
        Text(label, "HGMarket.Tiny", w * 0.5, top + Scale(53), C(color, 235), TEXT_ALIGN_CENTER)

        Line(Scale(10), h - Scale(48), w - Scale(20), 1, C(palette.line, 120))
        Text(Clip(entry.seller, "HGMarket.Tiny", w * 0.55), "HGMarket.Tiny", Scale(10), h - Scale(42), C(palette.muted, 235))
        Text(TimeAgo(entry.created), "HGMarket.Tiny", w - Scale(10), h - Scale(42), C(palette.dim, 205), TEXT_ALIGN_RIGHT)

        Coin(Scale(16), h - Scale(18), Scale(11), accent)
        Text(Money(entry.price), "HGMarket.Medium", Scale(26), h - Scale(18), accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local buttonW = math.floor(cardW * 0.36)
    local button

    if mineMode or entry.mine then
        button = MakeButton(card, mineMode and "СНЯТЬ" or "ВАШ", mineMode and palette.bad or palette.dim, function()
            if not mineMode then return end

            Confirm({
                kind = "cancel",
                id = entry.id,
                uid = entry.uid,
                title = "Снять лот с продажи?",
                name = entry.name,
                model = entry.model,
                price = entry.price,
                descr = entry.descr,
                seller = entry.seller,
                accept = "Снять"
            })
        end)
    else
        button = MakeButton(card, "КУПИТЬ", palette.good, function()
            Confirm({
                kind = "buy",
                id = entry.id,
                uid = entry.uid,
                title = "Подтвердите покупку",
                name = entry.name,
                model = entry.model,
                price = entry.price,
                descr = entry.descr,
                seller = entry.seller,
                accept = "Купить"
            })
        end)
    end

    button:SetSize(buttonW, Scale(22))
    button:SetPos(cardW - buttonW - Scale(10), cardH - Scale(29))

    return card
end

local function BuildSellCard(parent, entry, cardW, cardH, onClick)
    local card = vgui.Create("DButton", parent)
    card:SetSize(cardW, cardH)
    card:SetText("")
    card.Hover = 0

    local radius = Scale(10)
    local iconSize = math.floor(cardH * 0.5)
    local icon = MakeIcon(card, entry.model, iconSize)
    icon:SetPos(math.floor((cardW - iconSize) * 0.5), Scale(10))

    card.Paint = function(self, w, h)
        local selected = state.sellUID == entry.uid

        self.Hover = Lerp(FrameTime() * 10, self.Hover, (self:IsHovered() or selected) and 1 or 0)

        local accent = selected and palette.good or (entry.source == "model" and palette.gold or TierColor(Average(entry.uid)))

        Box(radius, 0, 0, w, h, C(palette.card, 240))
        Strip(self, radius, 0, 0, w, Scale(3), C(accent, 200))
        Outline(radius, 0, 0, w, h, C(accent, 50 + self.Hover * 150), selected and 2 or 1)
        Text(Clip(entry.name, "HGMarket.Small", w - Scale(16)), "HGMarket.Small", w * 0.5, h - Scale(58), palette.text, TEXT_ALIGN_CENTER)
        Text("Средняя: " .. AverageText(entry.uid), "HGMarket.Tiny", w * 0.5, h - Scale(38), C(palette.cyan, 235), TEXT_ALIGN_CENTER)
        Text(MK.SourceLabel(entry.source), "HGMarket.Tiny", w * 0.5, h - Scale(20), C(accent, 235), TEXT_ALIGN_CENTER)
    end

    card.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        onClick(entry)
    end

    return card
end

local function BuildHistoryRow(parent, entry, width)
    local row = vgui.Create("DPanel", parent)
    row:SetSize(width, Scale(58))
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, Scale(8))

    local iconSize = Scale(42)
    local icon = MakeIcon(row, entry.model, iconSize)
    icon:SetPos(Scale(8), Scale(8))

    row.Paint = function(_, w, h)
        local accent = entry.kind == "sold" and palette.good or (entry.kind == "bought" and palette.accent or palette.dim)
        local label = entry.kind == "sold" and "Продано" or (entry.kind == "bought" and "Куплено" or (entry.kind == "expired" and "Истекло" or "Снято"))
        local amount = entry.kind == "sold" and ("+" .. Money(entry.payout)) or (entry.kind == "bought" and ("-" .. Money(entry.price)) or Money(entry.price))

        Box(Scale(10), 0, 0, w, h, C(palette.card, 235))
        Outline(Scale(10), 0, 0, w, h, C(accent, 80))
        Text(entry.name, "HGMarket.Small", Scale(60), Scale(10), palette.text)
        Text(label .. "  •  " .. (tostring(entry.other or "") ~= "" and entry.other or "—") .. "  •  " .. TimeAgo(entry.time), "HGMarket.Tiny", Scale(60), Scale(32), C(palette.dim, 235))
        Text(amount, "HGMarket.Price", w - Scale(14), h * 0.5, accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    return row
end

local function OpenMarket()
    if IsValid(state.frame) then
        state.frame:Remove()
    end

    local frameW = ScrW()
    local frameH = ScrH()

    local frame = vgui.Create("DFrame")
    frame:SetSize(frameW, frameH)
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.18, 0)

    state.frame = frame

    frame.Paint = function(self, w, h)
        RNDX.DrawBlur(0, 0, w, h, nil, 0, 0, 0, 0)
        Box(0, 0, 0, w, h, palette.bg)
        Box(0, 0, 0, w, Scale(78), C(palette.panel, 250))
        Line(0, Scale(78), w, 1, C(palette.line, 200))

        Text("РЫНОК", "HGMarket.Brand", Scale(34), Scale(20), palette.text)
        Text("торговля аксессуарами и личными модельками за OT-Coin", "HGMarket.Tiny", Scale(36), Scale(52), C(palette.dim, 240))

        local balanceW = Scale(210)
        local balanceX = w - balanceW - Scale(84)

        Box(Scale(10), balanceX, Scale(20), balanceW, Scale(40), C(palette.card, 245))
        Outline(Scale(10), balanceX, Scale(20), balanceW, Scale(40), C(palette.accent, 150))
        Coin(balanceX + Scale(22), Scale(40), Scale(18), palette.accent)
        Text(Money(Balance()) .. " OT-Coin", "HGMarket.Medium", balanceX + Scale(40), Scale(40), palette.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if not state.raw then
            Text("Загрузка данных...", "HGMarket.Small", w * 0.5, Scale(34), C(palette.accent, 240), TEXT_ALIGN_CENTER)
        end
    end

    local close = MakeButton(frame, "✕", palette.bad, function()
        frame:Remove()
    end)
    close:SetSize(Scale(40), Scale(40))
    close:SetPos(frameW - Scale(62), Scale(20))

    frame.OnRemove = function()
        MK.Emit("Close", {})

        if timer.Exists("hg.Market.AutoRefresh") then timer.Remove("hg.Market.AutoRefresh") end
        if state.frame == frame then state.frame = nil end
    end

    local sidebar = vgui.Create("DPanel", frame)
    sidebar:SetPos(Scale(18), Scale(94))
    sidebar:SetSize(Scale(250), frameH - Scale(112))

    sidebar.Paint = function(_, w, h)
        Box(Scale(12), 0, 0, w, h, C(palette.panel, 240))
        Outline(Scale(12), 0, 0, w, h, C(palette.line, 170))
    end

    local content = vgui.Create("DPanel", frame)
    content:SetPos(Scale(280), Scale(94))
    content:SetSize(frameW - Scale(298), frameH - Scale(112))
    content.Paint = function() end

    local contentW = content:GetWide()
    local contentH = content:GetTall()

    local BuildSidebar

    local function Rebuild(keepScroll)
        local previous = keepScroll and content.Scroll or nil
        local offset = 0

        if IsValid(previous) then offset = previous:GetVBar():GetScroll() end

        content:Clear()
        content.Scroll = nil

        local header = vgui.Create("DPanel", content)
        header:SetSize(contentW, Scale(52))
        header.Paint = function(_, w, h)
            Box(Scale(10), 0, 0, w, h, C(palette.panel, 235))
            Outline(Scale(10), 0, 0, w, h, C(palette.line, 160))
        end

        local search = MakeEntry(header, "Поиск по названию или продавцу", false)
        search:SetPos(Scale(10), Scale(10))
        search:SetSize(Scale(320), Scale(32))
        search:SetText(state.search or "")
        search.OnValueChange = function(_, value)
            state.search = tostring(value or "")

            if timer.Exists("hg.Market.SearchDelay") then timer.Remove("hg.Market.SearchDelay") end

            timer.Create("hg.Market.SearchDelay", 0.3, 1, function()
                if IsValid(frame) then Rebuild(false) end
            end)
        end

        local sorts = {
            {id = "new", label = "НОВЫЕ"},
            {id = "deal", label = "ВЫГОДНЫЕ"},
            {id = "cheap", label = "ДЕШЕВЛЕ"},
            {id = "expensive", label = "ДОРОЖЕ"},
            {id = "name", label = "А-Я"}
        }

        local sortW = Scale(96)
        local sortX = contentW - Scale(10) - #sorts * (sortW + Scale(6)) + Scale(6)

        for index, sort in ipairs(sorts) do
            local active = state.sort == sort.id
            local button = MakeButton(header, sort.label, active and palette.accent or palette.dim, function()
                state.sort = sort.id
                Rebuild(false)
            end)

            button:SetSize(sortW, Scale(32))
            button:SetPos(sortX + (index - 1) * (sortW + Scale(6)), Scale(10))
        end

        local body = vgui.Create("DPanel", content)
        body:SetPos(0, Scale(62))
        body:SetSize(contentW, contentH - Scale(62))
        body.Paint = function() end

        if state.tab == "history" then
            local scroll = vgui.Create("DScrollPanel", body)
            scroll:Dock(FILL)
            StyleScroll(scroll)

            content.Scroll = scroll

            if #state.history == 0 then
                local empty = vgui.Create("DPanel", scroll)
                empty:SetSize(contentW, Scale(80))
                empty:Dock(TOP)
                empty.Paint = function(_, w, h)
                    Text("Здесь появятся ваши сделки", "HGMarket.Medium", w * 0.5, h * 0.5, C(palette.dim, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            Stream(scroll, state.history, function(entry)
                BuildHistoryRow(scroll, entry, contentW - Scale(12))
            end, 8)

            if offset > 0 then scroll:GetVBar():SetScroll(offset) end

            return
        end

        if state.tab == "sell" then
            local listW = math.floor(contentW * 0.58)

            local left = vgui.Create("DScrollPanel", body)
            left:SetPos(0, 0)
            left:SetSize(listW, body:GetTall())
            StyleScroll(left)

            content.Scroll = left

            local layout = vgui.Create("DIconLayout", left)
            layout:Dock(FILL)
            layout:SetSpaceX(Scale(10))
            layout:SetSpaceY(Scale(10))

            local columns = math.Clamp(math.floor((listW - Scale(24)) / Scale(180)), 3, 5)
            local cardW = math.floor((listW - Scale(24) - (columns - 1) * Scale(10)) / columns)
            local cardH = math.floor(cardW * 1.16)

            local needle = string.lower(string.Trim(state.search or ""))
            local list = {}

            for _, entry in ipairs(state.sellable) do
                local matchPlacement = state.placement == "all" or tostring(entry.placement or "") == state.placement
                local matchSearch = needle == "" or string.find(string.lower(entry.name .. " " .. entry.uid), needle, 1, true) ~= nil

                if matchPlacement and matchSearch then
                    list[#list + 1] = entry
                end
            end

            local panel = vgui.Create("DPanel", body)
            panel:SetPos(listW + Scale(12), 0)
            panel:SetSize(contentW - listW - Scale(12), body:GetTall())

            local panelW = panel:GetWide()
            local limits = Limits()

            local price = MakeEntry(panel, "Цена в OT-Coin", true)
            price:SetPos(Scale(16), Scale(212))
            price:SetSize(panelW - Scale(32), Scale(36))

            local descr = MakeEntry(panel, "Описание лота (необязательно)", false)
            descr:SetPos(Scale(16), Scale(258))
            descr:SetSize(panelW - Scale(32), Scale(96))
            descr:SetMultiline(true)

            local icon = MakeIcon(panel, "models/error.mdl", Scale(96))
            icon:SetPos(panelW - Scale(112), Scale(40))

            local function Selected()
                if not state.sellUID then return nil end

                for _, entry in ipairs(state.sellable) do
                    if entry.uid == state.sellUID then return entry end
                end

                return nil
            end

            local function Visible(visible)
                price:SetVisible(visible)
                descr:SetVisible(visible)
                icon:SetVisible(visible)
            end

            Visible(Selected() ~= nil)

            local hint = vgui.Create("DPanel", panel)
            hint:SetPos(Scale(16), Scale(364))
            hint:SetSize(panelW - Scale(32), Scale(64))
            hint.Paint = function(_, w, h)
                local entry = Selected()
                if not entry then return end

                local value = math.floor(tonumber(price:GetText()) or 0)
                local net = MK.Payout(value)
                local valid = value >= limits.minPrice and value <= limits.maxPrice
                local label, color = Verdict(value, entry.uid)

                Box(Scale(10), 0, 0, w, h, Color(255, 255, 255, 8))
                Outline(Scale(10), 0, 0, w, h, C(valid and palette.good or palette.bad, 150))
                Text("На руки после комиссии: " .. Money(net) .. " OT-Coin", "HGMarket.Small", Scale(12), Scale(10), palette.text)
                Text(valid and label or ("Допустимо: " .. Money(limits.minPrice) .. " — " .. Money(limits.maxPrice)), "HGMarket.Tiny", Scale(12), Scale(36), C(valid and color or palette.bad, 240))
            end

            local submit = MakeButton(panel, "ВЫСТАВИТЬ НА РЫНОК", palette.good, function()
                local entry = Selected()

                if not entry then
                    Notify("Выберите предмет слева", true)
                    return
                end

                local value = math.floor(tonumber(price:GetText()) or 0)

                if value < limits.minPrice or value > limits.maxPrice then
                    Notify("Цена должна быть от " .. Money(limits.minPrice) .. " до " .. Money(limits.maxPrice), true)
                    return
                end

                MK.Emit("List", {uid = entry.uid, price = value, desc = descr:GetText()})

                price:SetText("")
                descr:SetText("")
                state.sellUID = nil
                Visible(false)

                timer.Simple(0.6, function()
                    if IsValid(frame) then Request(true) end
                end)
            end)

            submit:SetPos(Scale(16), Scale(438))
            submit:SetSize(panelW - Scale(32), Scale(44))

            panel.Paint = function(_, w, h)
                Box(Scale(12), 0, 0, w, h, C(palette.panel, 242))
                Outline(Scale(12), 0, 0, w, h, C(palette.line, 170))
                Text("ВЫСТАВИТЬ ЛОТ", "HGMarket.Heading", Scale(16), Scale(16), palette.text)

                local entry = Selected()

                if not entry then
                    Text("Выберите предмет слева", "HGMarket.Small", Scale(16), Scale(52), C(palette.dim, 240))
                    return
                end

                Text(Clip(entry.name, "HGMarket.Medium", w - Scale(140)), "HGMarket.Medium", Scale(16), Scale(52), palette.accent)
                Text(MK.PlacementLabel(entry.placement) .. "  •  " .. MK.SourceLabel(entry.source), "HGMarket.Tiny", Scale(16), Scale(78), C(palette.muted, 240))
                Text("Средняя цена: " .. AverageText(entry.uid), "HGMarket.Small", Scale(16), Scale(102), palette.cyan)
                Text("Комиссия рынка: " .. math.floor((limits.fee or 0) * 100) .. "%", "HGMarket.Tiny", Scale(16), Scale(132), C(palette.dim, 240))

                if entry.source == "model" then
                    Text("Личная моделька уйдёт покупателю полностью", "HGMarket.Tiny", Scale(16), Scale(154), C(palette.gold, 235))
                else
                    Text("Лот живёт " .. limits.expireDays .. " дней, предмет блокируется до продажи", "HGMarket.Tiny", Scale(16), Scale(154), C(palette.dim, 220))
                end

                Text("Лимит лотов: " .. #state.mine .. "/" .. limits.maxListings, "HGMarket.Tiny", Scale(16), Scale(176), C(palette.dim, 220))
            end

            local function Select(entry)
                state.sellUID = entry.uid

                icon:SetIconModel(entry.model)
                Visible(true)

                local average = Average(entry.uid)
                local current = price:GetText()

                if average > 0 and (current == "" or current == price.Suggested) then
                    price:SetText(tostring(average))
                    price.Suggested = tostring(average)
                end
            end

            local current = Selected()
            if current then Select(current) end

            if #list == 0 then
                local empty = vgui.Create("DPanel", layout)
                empty:SetSize(listW - Scale(24), Scale(90))
                empty.Paint = function(_, w, h)
                    Text("Нет предметов для продажи", "HGMarket.Medium", w * 0.5, h * 0.5, C(palette.dim, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                layout:Add(empty)
            end

            Stream(layout, list, function(entry)
                layout:Add(BuildSellCard(layout, entry, cardW, cardH, Select))
            end, 6)

            if offset > 0 then left:GetVBar():SetScroll(offset) end

            return
        end

        local scroll = vgui.Create("DScrollPanel", body)
        scroll:Dock(FILL)
        StyleScroll(scroll)

        content.Scroll = scroll

        local layout = vgui.Create("DIconLayout", scroll)
        layout:Dock(FILL)
        layout:SetSpaceX(Scale(10))
        layout:SetSpaceY(Scale(10))

        local mineMode = state.tab == "mine"
        local entries = FilteredListings(mineMode and state.mine or state.listings)

        local columns = math.Clamp(math.floor((contentW - Scale(26)) / Scale(215)), 4, 7)
        local cardW = math.floor((contentW - Scale(26) - (columns - 1) * Scale(10)) / columns)
        local cardH = math.floor(cardW * 1.16)

        if #entries == 0 then
            local empty = vgui.Create("DPanel", layout)
            empty:SetSize(contentW - Scale(26), Scale(110))
            empty.Paint = function(_, w, h)
                Text(mineMode and "Вы ещё ничего не выставили" or (state.raw and "Лотов не найдено" or "Загрузка..."), "HGMarket.Heading", w * 0.5, h * 0.5 - Scale(12), C(palette.dim, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                Text(mineMode and "Откройте вкладку 'Продать'" or "Попробуйте другой фильтр или поиск", "HGMarket.Small", w * 0.5, h * 0.5 + Scale(16), C(palette.dim, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            layout:Add(empty)
        end

        Stream(layout, entries, function(entry)
            layout:Add(BuildListingCard(layout, entry, cardW, cardH, mineMode))
        end, 6)

        if offset > 0 then scroll:GetVBar():SetScroll(offset) end
    end

    BuildSidebar = function()
        sidebar:Clear()

        local tabs = {
            {id = "market", label = "РЫНОК"},
            {id = "mine", label = "МОИ ЛОТЫ"},
            {id = "sell", label = "ПРОДАТЬ"},
            {id = "history", label = "ИСТОРИЯ"}
        }

        local y = Scale(14)

        for _, tab in ipairs(tabs) do
            local button = vgui.Create("DButton", sidebar)
            button:SetText("")
            button:SetPos(Scale(12), y)
            button:SetSize(sidebar:GetWide() - Scale(24), Scale(44))
            button.Hover = 0

            button.Paint = function(self, w, h)
                local active = state.tab == tab.id

                self.Hover = Lerp(FrameTime() * 12, self.Hover, (self:IsHovered() or active) and 1 or 0)

                Box(Scale(9), 0, 0, w, h, C(palette.card, 200 + self.Hover * 45))
                Outline(Scale(9), 0, 0, w, h, C(active and palette.accent or palette.line, 90 + self.Hover * 130))

                if active then
                    Line(Scale(7), Scale(11), Scale(3), h - Scale(22), C(palette.accent, 235))
                end

                Text(tab.label, "HGMarket.Small", Scale(22), h * 0.5, active and palette.text or C(palette.muted, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                if tab.id == "mine" then
                    Text(#state.mine .. "/" .. Limits().maxListings, "HGMarket.Tiny", w - Scale(14), h * 0.5, C(palette.dim, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                elseif tab.id == "market" then
                    Text(#state.listings, "HGMarket.Tiny", w - Scale(14), h * 0.5, C(palette.dim, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                elseif tab.id == "sell" then
                    Text(#state.sellable, "HGMarket.Tiny", w - Scale(14), h * 0.5, C(palette.dim, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end

            button.DoClick = function()
                if state.tab == tab.id then return end

                surface.PlaySound("ui/buttonclick.wav")
                state.tab = tab.id
                Rebuild(false)
            end

            y = y + Scale(50)
        end

        y = y + Scale(10)

        local title = vgui.Create("DPanel", sidebar)
        title:SetPos(Scale(12), y)
        title:SetSize(sidebar:GetWide() - Scale(24), Scale(26))
        title.Paint = function(_, w, h)
            Text("СЛОТЫ", "HGMarket.Tiny", Scale(10), h * 0.5, C(palette.dim, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            Line(Scale(10), h - Scale(2), w - Scale(20), 1, C(palette.line, 150))
        end

        y = y + Scale(30)

        local scroll = vgui.Create("DScrollPanel", sidebar)
        scroll:SetPos(Scale(12), y)
        scroll:SetSize(sidebar:GetWide() - Scale(24), sidebar:GetTall() - y - Scale(14))
        StyleScroll(scroll)

        for _, placement in ipairs(MK.PlacementOrder) do
            local button = vgui.Create("DButton", scroll)
            button:SetText("")
            button:Dock(TOP)
            button:DockMargin(0, 0, 0, Scale(6))
            button:SetTall(Scale(34))
            button.Hover = 0

            button.Paint = function(self, w, h)
                local active = state.placement == placement
                local accent = placement == "model" and palette.gold or palette.cyan

                self.Hover = Lerp(FrameTime() * 12, self.Hover, (self:IsHovered() or active) and 1 or 0)

                Box(Scale(8), 0, 0, w, h, C(palette.card, 150 + self.Hover * 80))
                Outline(Scale(8), 0, 0, w, h, C(active and accent or palette.line, 70 + self.Hover * 130))
                Text(MK.PlacementLabel(placement), "HGMarket.Tiny", Scale(14), h * 0.5, active and accent or C(palette.muted, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            button.DoClick = function()
                if state.placement == placement then return end

                surface.PlaySound("ui/buttonclick.wav")
                state.placement = placement
                Rebuild(false)
            end
        end
    end

    frame.BuildConfirm = function(self)
        if IsValid(self.ConfirmPanel) then
            self.ConfirmPanel:Remove()
        end

        local entry = state.confirm
        if not istable(entry) then return end

        local overlay = vgui.Create("DPanel", self)
        overlay:SetSize(frameW, frameH)
        overlay:SetPos(0, 0)
        overlay:MakePopup()
        self.ConfirmPanel = overlay

        overlay.Paint = function(_, w, h)
            Box(0, 0, 0, w, h, Color(2, 5, 9, 210))
        end

        local panelW = Scale(460)
        local panelH = Scale(420)

        local panel = vgui.Create("DPanel", overlay)
        panel:SetSize(panelW, panelH)
        panel:Center()

        local iconSize = Scale(120)
        local icon = MakeIcon(panel, entry.model, iconSize)
        icon:SetPos(math.floor((panelW - iconSize) * 0.5), Scale(52))

        local accent = entry.kind == "buy" and palette.good or palette.bad

        panel.Paint = function(self, w, h)
            local enough = Balance() >= (tonumber(entry.price) or 0)
            local label, color = Verdict(entry.price, entry.uid)

            Shadow(Scale(14), 0, 0, w, h, C(palette.shadow, 220), 18, 22)
            Box(Scale(14), 0, 0, w, h, C(palette.panel, 252))
            Strip(self, Scale(14), 0, 0, w, Scale(4), C(accent, 220))
            Outline(Scale(14), 0, 0, w, h, C(accent, 170))
            Text(entry.title, "HGMarket.Heading", w * 0.5, Scale(18), palette.text, TEXT_ALIGN_CENTER)
            Text(Clip(entry.name, "HGMarket.Medium", w - Scale(40)), "HGMarket.Medium", w * 0.5, Scale(184), palette.text, TEXT_ALIGN_CENTER)
            Text("Продавец: " .. tostring(entry.seller or "—"), "HGMarket.Small", w * 0.5, Scale(210), C(palette.muted, 240), TEXT_ALIGN_CENTER)
            Text("Средняя цена: " .. AverageText(entry.uid) .. "  •  " .. label, "HGMarket.Tiny", w * 0.5, Scale(234), C(color, 240), TEXT_ALIGN_CENTER)

            if tostring(entry.descr or "") ~= "" then
                TextWrap(entry.descr, "HGMarket.Tiny", Scale(24), Scale(258), w - Scale(48), C(palette.dim, 240), 3)
            end

            Coin(Scale(38), Scale(326), Scale(18), accent)
            Text(Money(entry.price) .. " OT-Coin", "HGMarket.Price", Scale(56), Scale(326), accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if entry.kind == "buy" then
                Text(enough and ("Останется: " .. Money(Balance() - (tonumber(entry.price) or 0))) or "Недостаточно OT-Coin", "HGMarket.Tiny", w - Scale(24), Scale(326), C(enough and palette.muted or palette.bad, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        local accept = MakeButton(panel, string.upper(tostring(entry.accept or "ОК")), accent, function()
            if entry.kind == "buy" then
                MK.Emit("Buy", {id = entry.id})
            else
                MK.Emit("Cancel", {id = entry.id})
            end

            state.confirm = nil
            overlay:Remove()

            timer.Simple(0.6, function()
                if IsValid(frame) then Request(true) end
            end)
        end)
        accept:SetSize(Scale(200), Scale(42))
        accept:SetPos(Scale(24), panelH - Scale(58))

        local cancel = MakeButton(panel, "ОТМЕНА", palette.dim, function()
            state.confirm = nil
            overlay:Remove()
        end)
        cancel:SetSize(Scale(200), Scale(42))
        cancel:SetPos(panelW - Scale(224), panelH - Scale(58))

        overlay.OnKeyCodePressed = function(_, key)
            if key == KEY_ESCAPE then
                state.confirm = nil
                overlay:Remove()
            end
        end
    end

    frame.RefreshAll = function(changed)
        if not IsValid(frame) then return end
        if changed == false then return end

        BuildSidebar()
        Rebuild(true)
    end

    BuildSidebar()
    Rebuild(false)

    timer.Create("hg.Market.AutoRefresh", 10, 0, function()
        if not IsValid(state.frame) then
            timer.Remove("hg.Market.AutoRefresh")
            return
        end

        Request(false)
    end)
end

MK.Hook("Open", function(payload)
    if istable(payload) and payload.listings then Adapt(payload) end

    OpenMarket()
    Request(true)
end)

MK.Hook("Sync", function(payload)
    local changed = Adapt(payload)

    if IsValid(state.frame) and isfunction(state.frame.RefreshAll) then
        state.frame.RefreshAll(changed)
    end
end)

MK.Hook("Notice", function(payload)
    if not istable(payload) then return end

    Notify(payload.t or payload.text, payload.b == true or payload.error == true)
end)

concommand.Add("hg_market", function()
    RunConsoleCommand("hg_market_open")
end)

MK.Open = function()
    RunConsoleCommand("hg_market_open")
end

end)
