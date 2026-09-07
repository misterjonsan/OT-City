hg = hg or {}
hg.Market = hg.Market or {}
hg.MarketConfig = hg.MarketConfig or {}

local CFG = hg.MarketConfig

CFG.MinPrice = CFG.MinPrice or 50
CFG.MaxPrice = CFG.MaxPrice or 5000000
CFG.MaxDescription = CFG.MaxDescription or 180
CFG.MaxListingsPerPlayer = CFG.MaxListingsPerPlayer or 8
CFG.Fee = CFG.Fee or 0.05
CFG.ExpireDays = CFG.ExpireDays or 21
CFG.HistoryLimit = CFG.HistoryLimit or 40
CFG.PerPage = CFG.PerPage or 40
CFG.MaxListingsSent = CFG.MaxListingsSent or 150
CFG.ListCooldown = CFG.ListCooldown or 4
CFG.CancelCooldown = CFG.CancelCooldown or 2
CFG.BuyCooldown = CFG.BuyCooldown or 1.5
CFG.SyncCooldown = CFG.SyncCooldown or 1.5
CFG.PollInterval = CFG.PollInterval or 3
CFG.StatsInterval = CFG.StatsInterval or 120
CFG.ListingsInterval = CFG.ListingsInterval or 30
CFG.ExpireInterval = CFG.ExpireInterval or 300
CFG.PayoutInterval = CFG.PayoutInterval or 45
CFG.ChatCommands = CFG.ChatCommands or {
    ["!market"] = true,
    ["/market"] = true,
    ["!рынок"] = true,
    ["/рынок"] = true,
    ["!маркет"] = true,
    ["/маркет"] = true
}

local MK = hg.Market

MK.PlacementLabels = {
    ["all"] = "Все слоты",
    ["head"] = "Голова",
    ["face"] = "Лицо",
    ["torso"] = "Торс",
    ["spine"] = "Спина",
    ["headpones"] = "Наушники",
    ["bandanes"] = "Бандана",
    ["boots"] = "Обувь",
    ["ears"] = "Уши",
    ["model"] = "Личные модельки",
    [""] = "Прочее"
}

MK.SourceLabels = {
    coin = "OT-Coin",
    donate = "Донат",
    market = "Рынок",
    model = "Личная моделька"
}

MK.PlacementOrder = {"all", "model", "head", "face", "torso", "spine", "headpones", "bandanes", "boots", "ears", ""}

function MK.PlacementLabel(placement)
    return MK.PlacementLabels[tostring(placement or "")] or MK.PlacementLabels[""]
end

function MK.SourceLabel(source)
    return MK.SourceLabels[tostring(source or "")] or MK.SourceLabels.market
end

function MK.GetAccessory(uid)
    uid = tostring(uid or "")
    if uid == "" or uid == "none" then return nil end
    if not istable(hg.Accessories) then return nil end

    local acc = hg.Accessories[uid]
    if not istable(acc) then return nil end

    return acc
end

function MK.AccessoryName(uid)
    local acc = MK.GetAccessory(uid)
    if not acc then return tostring(uid or "?") end

    return tostring(acc.name or uid)
end

function MK.AccessoryModel(uid)
    local acc = MK.GetAccessory(uid)
    if not acc then return "models/error.mdl" end

    local mdl = tostring(acc.model or "")
    if mdl == "" then return "models/error.mdl" end

    return mdl
end

function MK.CoinPrice(acc)
    if not istable(acc) then return 0 end

    return math.max(0, math.floor(tonumber(acc.coinPrice or acc.price) or 0))
end

function MK.ShopUID(uid)
    local acc = MK.GetAccessory(uid)
    if not istable(acc) or acc.donateOnly ~= true then return tostring(uid or "") end

    local shop = tostring(acc.DonateID or acc.ID or uid or "")
    if shop == "" then return tostring(uid or "") end

    return shop
end

function MK.AccessoryPlacement(uid)
    local acc = MK.GetAccessory(uid)
    if not acc then return "" end

    return tostring(acc.placement or "")
end

function MK.NormalizePrice(price)
    price = math.floor(tonumber(price) or 0)

    if price < CFG.MinPrice then return nil end
    if price > CFG.MaxPrice then return nil end

    return price
end

function MK.Fee(price)
    price = math.floor(tonumber(price) or 0)
    local fee = math.floor(price * math.Clamp(tonumber(CFG.Fee) or 0, 0, 0.5))
    if fee < 0 then fee = 0 end
    if fee >= price then fee = math.max(0, price - 1) end

    return fee
end

function MK.Payout(price)
    price = math.floor(tonumber(price) or 0)

    return math.max(0, price - MK.Fee(price))
end

function MK.SanitizeDescription(text)
    text = tostring(text or "")
    text = string.gsub(text, "[\r\n\t]", " ")
    text = string.gsub(text, "%s%s+", " ")
    text = string.Trim(text)

    if text == "" then return "" end

    local out = {}
    local count = 0
    local ok = pcall(function()
        for _, code in utf8.codes(text) do
            local allowed = false

            if code >= 32 and code <= 126 then allowed = true end
            if code >= 1040 and code <= 1103 then allowed = true end
            if code == 1025 or code == 1105 then allowed = true end
            if code == 8470 or code == 8212 or code == 8211 then allowed = true end
            if code >= 171 and code <= 187 then allowed = true end
            if code >= 8220 and code <= 8221 then allowed = true end

            if allowed then
                count = count + 1
                out[count] = utf8.char(code)
            end

            if count >= CFG.MaxDescription then break end
        end
    end)

    if not ok then return "" end

    return string.Trim(table.concat(out, ""))
end

function MK.FormatNumber(value)
    value = math.floor(tonumber(value) or 0)

    local sign = value < 0 and "-" or ""
    local text = tostring(math.abs(value))
    local out = text

    while true do
        local replaced
        out, replaced = string.gsub(out, "^(%-?%d+)(%d%d%d)", "%1 %2")
        if replaced == 0 then break end
    end

    return sign .. out
end

function MK.AverageText(stat)
    if not istable(stat) then return "Неизвестно" end

    local sales = math.floor(tonumber(stat.n) or 0)
    local avg = math.floor(tonumber(stat.a) or 0)

    if sales <= 0 or avg <= 0 then return "Неизвестно" end

    return MK.FormatNumber(avg)
end

function MK.PriceVerdict(price, stat)
    price = math.floor(tonumber(price) or 0)

    if not istable(stat) then return "unknown", 0 end

    local sales = math.floor(tonumber(stat.n) or 0)
    local avg = math.floor(tonumber(stat.a) or 0)

    if sales <= 0 or avg <= 0 or price <= 0 then return "unknown", 0 end

    local ratio = price / avg

    if ratio <= 0.75 then return "cheap", ratio end
    if ratio >= 1.35 then return "expensive", ratio end

    return "fair", ratio
end

local TAG = "hg_market_stream"
local MAX_CLIENT_PAYLOAD = 32768
local MAX_SERVER_PAYLOAD = 8388608

if SERVER then util.AddNetworkString(TAG) end

MK.Handlers = MK.Handlers or {}

function MK.Hook(name, callback)
    if not isfunction(callback) then return end
    MK.Handlers[tostring(name or "")] = callback
end

local function Encode(name, payload)
    local json = util.TableToJSON({n = tostring(name or ""), d = istable(payload) and payload or {}})
    if not isstring(json) or json == "" then return nil end

    local data = util.Compress(json)
    if not isstring(data) or #data <= 0 then return nil end

    return data
end

function MK.Send(target, name, payload)
    local data = Encode(name, payload)
    if not data then return end

    if SERVER and #data > MAX_SERVER_PAYLOAD then return end
    if CLIENT and #data > MAX_CLIENT_PAYLOAD then return end

    net.Start(TAG)
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)

    if SERVER then
        if target == nil then
            net.Broadcast()
        elseif IsValid(target) then
            net.Send(target)
        else
            return
        end
    else
        net.SendToServer()
    end
end

function MK.Emit(name, payload)
    MK.Send(nil, name, payload)
end

net.Receive(TAG, function(_, ply)
    local size = net.ReadUInt(32)
    if not isnumber(size) or size <= 0 then return end

    if SERVER then
        if not IsValid(ply) then return end
        if size > MAX_CLIENT_PAYLOAD then return end
    elseif size > MAX_SERVER_PAYLOAD then
        return
    end

    local raw = net.ReadData(size)
    if not isstring(raw) or #raw <= 0 then return end

    local json = util.Decompress(raw, MAX_SERVER_PAYLOAD)
    if not isstring(json) or json == "" then return end

    local packet = util.JSONToTable(json)
    if not istable(packet) then return end

    local handler = MK.Handlers[tostring(packet.n or "")]
    if not isfunction(handler) then return end

    local payload = istable(packet.d) and packet.d or {}

    if SERVER then
        handler(ply, payload)
    else
        handler(payload)
    end
end)
