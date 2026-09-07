timer.Simple(0.1, function()
if not SERVER then return end
require("mysqloo")
local OTC_ORIGINAL_RUNCONSOLECOMMAND = RunConsoleCommand
local OTC_ORIGINAL_NETSTREAM_HOOK = netstream and netstream.Hook or nil
local OTC_SECURITY_PREFIX = "[OTC_SECURITY] "
local function OTCLogSecurity(msg)
    print(OTC_SECURITY_PREFIX .. tostring(msg or ""))
end
local function EnsureNetstream()
    if not istable(netstream) or not isfunction(netstream.Start) or not isfunction(netstream.Hook) then
        error("[OTC Donate] netstream not found")
    end
end
EnsureNetstream()
OTCDonate = OTCDonate or {}
OTCDonate.Config = OTCDonate.Config or {
    mysql = {
        host = "46.174.50.7",
        port = 3306,
        username = "u39635_willyw",
        password = "3D9p7Y9o9H!!!",
        database = "u39635_donatem",
        socket = nil
    },
    apiKey = "",
    apiURL = "",
    discordWebhook = "",
    rubToBalance = 1,
    monthlyFile = "otcity_donate_monthly.json",
    ttsFile = "otcity_tts_subs.json",
    activeModelsFile = "otcity_active_models.json",
    modelStoreFile = "rk_models_store.json",
    adminCostumePanelURL = "",
    otcCoinShop = {
        minAmount = 100,
        maxAmount = 10000,
        step = 50,
        baseRate = 3,
        bonusStepCoins = 500,
        bonusPercentPerStep = 2,
        maxBonusPercent = 20
    }
}
local Cfg = OTCDonate.Config
local DB
local PurchasesCache = {}
local ProcessingOrders = {}
local RequestCooldown = {}
local BuyCooldown = {}
local ActivateCooldown = {}
local ActiveModelsCache = {}
local SyncMyPurchases
local SyncExojumpState
local RecalculateBalanceFromLedger
local SyncBalance
local SyncInventory
local AuditDonateRank
local CanReceiveDonateRank
local Chat
local Money
local PURCHASES_MAX = 60
local DonateDiscountFile = "rk_donate_discount.txt"
local DonateDiscount = 0
local function ClampDonateDiscount(v)
    v = math.floor(tonumber(v) or 0)
    if v < 0 then v = 0 end
    if v > 99 then v = 99 end
    return v
end
local function ApplyDonateDiscount(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local d = DonateDiscount or 0
    if d <= 0 then return amount end
    if d >= 100 then return 0 end
    return math.max(0, math.floor(amount * (100 - d) / 100 + 0.5))
end
local function LoadDonateDiscount()
    DonateDiscount = ClampDonateDiscount(file.Read(DonateDiscountFile, "DATA"))
end
local function SaveDonateDiscount()
    file.Write(DonateDiscountFile, tostring(DonateDiscount))
end
local function BroadcastDonateDiscount(target)
    if not istable(netstream) or not isfunction(netstream.Start) then return end
    netstream.Start(target or player.GetAll(), "rk_donate_discount_sync", { percent = DonateDiscount })
end
LoadDonateDiscount()
local Packages = {
    [149] = { uid = "vip_30", kind = "rank", group = "vip", duration = 30 * 86400, title = "VIP на месяц", subtitle = "VIP-статус на 30 дней: дополнительные удобства в минииграх, приоритетный вход, повышенный комфорт игры, увеличенные награды и доступ к косметическим возможностям без опасных админ-прав.", tag = "VIP • 30 дней" },
    [349] = { uid = "vip_90", kind = "rank", group = "vip", duration = 90 * 86400, title = "VIP на сезон", subtitle = "VIP-статус на 90 дней для тех, кто играет постоянно: все месячные преимущества на длительный срок, стабильный приоритет, бонусы и расширенные косметические возможности.", tag = "VIP • 90 дней" },
    [549] = { uid = "moderator_30", kind = "rank", group = "moderator", duration = 30 * 86400, title = "Модератор на месяц", subtitle = "Модератор на 30 дней: самый базовый staff-ранг с полным набором VIP-привилегий. Может кикать, мутить, гагать и выдавать мягкие наказания для поддержания порядка, но не получает доступ к банам и смене игровых режимов.", tag = "MODERATOR • 30 дней" },
    [1299] = { uid = "moderator_90", kind = "rank", group = "moderator", duration = 90 * 86400, title = "Модератор на сезон", subtitle = "Модератор на 90 дней: все преимущества VIP плюс базовая модерация на долгий срок. Подходит для помощи игрокам и наведения порядка без доступа к банам и инструментам смены режимов.", tag = "MODERATOR • 90 дней" },
    [899] = { uid = "operator_30", kind = "rank", group = "operator", duration = 30 * 86400, title = "Оператор на месяц", subtitle = "Оператор на 30 дней: всё, что доступно модератору, плюс возможность банить с лимитами, управлять игровыми режимами и использовать расширенные инструменты контроля в безопасных рамках.", tag = "OPERATOR • 30 дней" },
    [1999] = { uid = "operator_90", kind = "rank", group = "operator", duration = 90 * 86400, title = "Оператор на сезон", subtitle = "Оператор на 90 дней: длительный доступ к возможностям модератора и усиленным staff-функциям. Позволяет банить с лимитами, менять режимы и эффективнее следить за порядком на сервере.", tag = "OPERATOR • 90 дней" },
    [3499] = { uid = "sponsor_30", kind = "rank", group = "sponsor", duration = 30 * 86400, title = "Спонсор на месяц", subtitle = "Спонсор на 30 дней: расширенный ранг с доступом ко всем возможностям оператора и более крупным лимитам. Даёт максимум удобства, высокий приоритет и усиленные инструменты поддержки сервера без пересечения с высшей администрацией.", tag = "SPONSOR • 30 дней" },
    [4799] = { uid = "sponsor_90", kind = "rank", group = "sponsor", duration = 90 * 86400, title = "Спонсор на сезон", subtitle = "Спонсор на 90 дней: старший донат-ранг с полным набором прошлых возможностей, увеличенными лимитами и самым широким набором функций среди покупаемых привилегий.", tag = "SPONSOR • 90 дней" },
    [229] = { uid = "tts_7", kind = "tts", duration = 7 * 86400, title = "Говорилка на неделю", subtitle = "TTS-подписка на 7 дней: сообщения в чате могут озвучиваться на сервере, чтобы выделяться среди игроков и оживлять общение.", tag = "TTS • 7 дней" },
    [599] = { uid = "tts_21", kind = "tts", duration = 21 * 86400, title = "Говорилка на 3 недели", subtitle = "TTS-подписка на 21 день: длительная озвучка сообщений в чате для активных игроков, стримеров и тех, кто хочет быть заметнее.", tag = "TTS • 21 день" },
    [1800] = { uid = "personal_model", kind = "personal_model", category = "Модели", title = "Личная моделька", subtitle = "Любая личная моделька на выбор из мастерской и с сервера. После покупки напишите milky_code в Discord и отправьте скриншот окна покупки, чтобы получить вашу личную модельку.", tag = "PERSONAL • DISCORD" },
    [45] = { uid = "rtv_boost", kind = "rtv_boost", title = "Досрочное голосование", subtitle = "Разовый RTV-буст: позволяет досрочно запустить голосование за смену карты через серверную RTV-систему, если она доступна.", tag = "RTV • NEXT ROUND" },
    [239] = { uid = "tagilla_mask", kind = "accs", title = "Маска Тагиллы", subtitle = "Постоянный аксессуар/bodygroup: тяжёлая маска Тагиллы для агрессивного и боссового внешнего вида персонажа.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [219] = { uid = "knight_mask", kind = "accs", title = "Маска Кнайта", subtitle = "Постоянный аксессуар/bodygroup: мрачная маска Кнайта для строгого тактического образа и более жёсткого визуала.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [249] = { uid = "zryachii_mask", kind = "accs", title = "Маска Зрячего", subtitle = "Постоянный аксессуар/bodygroup: необычная маска Зрячего с редким визуалом для выделяющегося образа.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [289] = { uid = "armor_tagilla", kind = "accs", title = "Слик-Разгрузка Тагиллы", subtitle = "Постоянный аксессуар/bodygroup: массивная слик-разгрузка Тагиллы, добавляющая тяжёлый боевой силуэт и броневой вайб.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [319] = { uid = "armor_killa_plate", kind = "accs", title = "Бронеплитник Киллы", subtitle = "Постоянный аксессуар/bodygroup: яркий бронеплитник Киллы, заметный тактический элемент для внешнего вида персонажа.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [269] = { uid = "armor_bigpipe", kind = "accs", title = "Бронеплитник Биг Пайпа", subtitle = "Постоянный аксессуар/bodygroup: тяжёлый тактический бронеплитник Биг Пайпа для военного и силового образа.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [259] = { uid = "armor_black_knight", kind = "accs", title = "Бронежилет Кнайта", subtitle = "Постоянный аксессуар/bodygroup: строгий чёрный бронежилет Кнайта для тёмного тактического внешнего вида.", tag = "CLOTHING • PERMANENT", isBodygroup = true },
    [649] = { uid = "exojump", kind = "accs", title = "Экзо-Ботинки", subtitle = "Постоянный аксессуар с эффектом: запрещает толкнуть владельца на пол и убирает расход стамины при беге, поддерживая запас выносливости полным.", tag = "ACCESSORY • PERMANENT" }
}
OTCDonate.Packages = Packages
local ModelToPackage = {}
local ManagedDonateModels = {}
local function NormalizeModelPath(model)
    return string.lower(string.Trim(tostring(model or "")))
end
local function RegisterManagedModel(model)
    model = NormalizeModelPath(model)
    if model == "" then return end
    ManagedDonateModels[model] = true
end
local function RebuildModelPackageIndex()
    ModelToPackage = {}
    for amount, p in pairs(Packages) do
        if istable(p) and tostring(p.kind or "") == "model" then
            local mdl = NormalizeModelPath(p.model)
            if mdl ~= "" then
                ModelToPackage[mdl] = { amount = amount, pack = p }
                RegisterManagedModel(mdl)
            end
        end
    end
end
RebuildModelPackageIndex()
local AdminCostumes = {
    ["admin"] = { uid = "admin_costume", model = "models/kerry/red_cit/male_02.mdl", bodygroup = 1 },
    ["admin+"] = { uid = "admin_plus_costume", model = "models/kerry/red_cit/male_02.mdl", bodygroup = 2 },
    ["st_admin"] = { uid = "st_admin_costume", model = "models/kerry/red_cit/male_02.mdl", bodygroup = 0 },
    --["superadmin"] = { uid = "superadmin_costume", model = "models/squidgame/guard/pacho_black_cit.mdl", bodygroup = 0 }
}
local AdminCostumeByUID = {}
local AdminCostumeModels = {}
for _, costume in pairs(AdminCostumes) do
    AdminCostumeByUID[costume.uid] = costume
    AdminCostumeModels[NormalizeModelPath(costume.model)] = true
    RegisterManagedModel(costume.model)
end
local function GetAdminCostume(ply)
    if not IsValid(ply) then return nil end
    local group = string.lower(string.Trim(tostring(ply:GetUserGroup() or "")))
    return AdminCostumes[group], group
end
local function PackageByModel(model)
    model = NormalizeModelPath(model)
    local data = ModelToPackage[model]
    if data then return data.amount, data.pack end
    return 0, nil
end
local function ImportedModelUID(model)
    model = NormalizeModelPath(model)
    local uid = string.gsub(model, "[^%w_]+", "_")
    uid = string.gsub(uid, "_+", "_")
    uid = string.Trim(uid, "_")
    if uid == "" then uid = util.CRC(model) end
    return string.sub("model_import_" .. uid, 1, 128)
end
local function ImportedModelTitle(model)
    model = tostring(model or "")
    local name = string.GetFileFromFilename(model) or model
    name = string.gsub(name, "%.mdl$", "")
    name = string.gsub(name, "_", " ")
    if name == "" then name = "Импортированная модель" end
    return name
end
local KindOrder = { rank = 1, model = 2, accs = 3, tts = 4, rtv_boost = 5 }
local SafeRanks = { vip = true, moderator = true, operator = true, sponsor = true }
local SmartRankProtocols = {}
local BlockedRanks = { superadmin = true, owner = true, root = true, founder = true, admin = true, manager = true, headadmin = true, deputy = true, curator = true }
local SafeRankPackages = {
    [149] = { rank = "vip", duration = 30 * 86400 },
    [349] = { rank = "vip", duration = 90 * 86400 },
    [549] = { rank = "moderator", duration = 30 * 86400 },
    [1299] = { rank = "moderator", duration = 90 * 86400 },
    [899] = { rank = "operator", duration = 30 * 86400 },
    [1999] = { rank = "operator", duration = 90 * 86400 },
    [3499] = { rank = "sponsor", duration = 30 * 86400 },
    [4799] = { rank = "sponsor", duration = 90 * 86400 }
}
local function GetSafeRankPackage(amount)
    amount = math.floor(tonumber(amount) or 0)
    local safe = SafeRankPackages[amount]
    local pack = Packages[amount]
    if not safe or not istable(pack) then return nil end
    local rank = string.lower(string.Trim(tostring(pack.group or "")))
    local duration = math.floor(tonumber(pack.duration) or 0)
    if tostring(pack.kind or "") ~= "rank" then return nil end
    if rank ~= tostring(safe.rank or "") then return nil end
    if duration ~= tonumber(safe.duration or 0) then return nil end
    if not SafeRanks[rank] or BlockedRanks[rank] then return nil end
    return { amount = amount, rank = rank, duration = duration, title = tostring(pack.title or "Ранг") }
end
local function ValidateRankPackages()
    for amount, safe in pairs(SafeRankPackages) do
        local pack = Packages[amount]
        if not istable(pack) or tostring(pack.kind or "") ~= "rank" or string.lower(tostring(pack.group or "")) ~= tostring(safe.rank or "") or math.floor(tonumber(pack.duration) or 0) ~= math.floor(tonumber(safe.duration) or 0) then
            error("[OTC_SECURITY] unsafe rank package config: " .. tostring(amount))
        end
    end
end
ValidateRankPackages()
local function GetOTCoinShopConfig()
    local cfg = istable(Cfg.otcCoinShop) and Cfg.otcCoinShop or {}
    return {
        minAmount = math.max(50, math.floor(tonumber(cfg.minAmount) or 100)),
        maxAmount = math.max(500, math.floor(tonumber(cfg.maxAmount) or 10000)),
        step = math.max(1, math.floor(tonumber(cfg.step) or 50)),
        baseRate = math.max(0.1, tonumber(cfg.baseRate) or 3),
        bonusStepCoins = math.max(1, math.floor(tonumber(cfg.bonusStepCoins) or 500)),
        bonusPercentPerStep = math.max(0, math.floor(tonumber(cfg.bonusPercentPerStep) or 2)),
        maxBonusPercent = math.max(0, math.floor(tonumber(cfg.maxBonusPercent) or 20))
    }
end
local function NormalizeOTCoinPurchaseAmount(amount)
    local cfg = GetOTCoinShopConfig()
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return cfg.minAmount end
    if amount < cfg.minAmount then amount = cfg.minAmount end
    if amount > cfg.maxAmount then amount = cfg.maxAmount end
    amount = math.floor(amount / cfg.step) * cfg.step
    if amount < cfg.minAmount then amount = cfg.minAmount end
    return amount
end
local function CalculateOTCoinPrice(amount)
    local cfg = GetOTCoinShopConfig()
    amount = NormalizeOTCoinPurchaseAmount(amount)
    local bonusSteps = math.floor(amount / cfg.bonusStepCoins)
    local bonusPercent = math.min(cfg.maxBonusPercent, bonusSteps * cfg.bonusPercentPerStep)
    local effectiveRate = cfg.baseRate * (1 + bonusPercent / 100)
    local price = math.max(1, math.ceil(amount / effectiveRate))
    return price, bonusPercent, effectiveRate, cfg
end
local function CanUseOTCoinMData(ply)
    return IsValid(ply) and mdata and isfunction(mdata.IsLoaded) and mdata:IsLoaded(ply) and isfunction(ply.SetMData) and isfunction(ply.GetMData)
end
local function GetOTCoinBalanceKey()
    return AP and AP.OTCoin and tostring(AP.OTCoin.BalanceKey or "") ~= "" and tostring(AP.OTCoin.BalanceKey) or "hg_otcoins_balance"
end
local function GetCurrentOTCoinBalance(ply)
    if AP and isfunction(AP.GetOTCoinBalance) then
        local ok, balance = pcall(AP.GetOTCoinBalance, ply)
        if ok then return math.max(0, math.floor(tonumber(balance) or 0)) end
    end
    if CanUseOTCoinMData(ply) then
        return math.max(0, math.floor(tonumber(ply:GetMData(GetOTCoinBalanceKey(), 0)) or 0))
    end
    return 0
end
local function GrantPurchasedOTCoins(ply, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not IsValid(ply) then return false, GetCurrentOTCoinBalance(ply) end
    if AP and isfunction(AP.AddOTCoins) then
        local ok, success, balance = pcall(AP.AddOTCoins, ply, amount, "за донат-покупку", true)
        if ok and success then
            return true, math.max(0, math.floor(tonumber(balance) or 0))
        end
    end
    if not CanUseOTCoinMData(ply) then return false, GetCurrentOTCoinBalance(ply) end
    local balance = GetCurrentOTCoinBalance(ply) + amount
    ply:SetMData(GetOTCoinBalanceKey(), balance)
    return true, balance
end
local AccessoryPreviewModels = {}
local function ResolveAccessoryModel(uid)
    uid = tostring(uid or "")
    if uid == "" then return "" end
    if AccessoryPreviewModels[uid] and AccessoryPreviewModels[uid] ~= "" then return tostring(AccessoryPreviewModels[uid]) end
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
local function ResolvePackageModel(p)
    if not istable(p) then return "" end
    local mdl = tostring(p.model or "")
    if mdl ~= "" then return mdl end
    if tostring(p.kind or "") == "accs" then return ResolveAccessoryModel(p.uid) end
    return tostring(p.preview_model or "")
end
local function NSStart(target, name, data)
    if not istable(netstream) or not isfunction(netstream.Start) then return end
    if target == nil then netstream.Start(name, data or {}) return end
    netstream.Start(target, name, data or {})
end
local function NSHook(name, fn)
    if not istable(netstream) or not isfunction(netstream.Hook) then error("[OTC Donate] netstream not found") end
    netstream.Hook(name, fn)
end
local function Clean(s, maxLen)
    s = string.Trim(tostring(s or ""))
    maxLen = tonumber(maxLen) or 128
    if #s > maxLen then s = string.sub(s, 1, maxLen) end
    return s
end
local function IsSteamID64(sid64)
    sid64 = tostring(sid64 or "")
    return sid64:match("^%d+$") and #sid64 >= 16 and #sid64 <= 20
end
local function ToSteamID64(id)
    id = string.Trim(tostring(id or ""))
    if id == "" then return "" end
    if IsSteamID64(id) then return id end
    if id:match("^STEAM_%d:%d:%d+$") and util and isfunction(util.SteamIDTo64) then
        local sid64 = tostring(util.SteamIDTo64(id) or "")
        if IsSteamID64(sid64) then return sid64 end
    end
    return ""
end
local function Esc(s)
    if DB then return DB:escape(tostring(s or "")) end
    return tostring(s or "")
end
local function SQLString(s)
    return "'" .. Esc(s) .. "'"
end
local function Query(sql, ok, fail)
    if not DB then if fail then fail("no db") end return end
    local q = DB:query(sql)
    function q:onSuccess(data) if ok then ok(data, q) end end
    function q:onError(err) print("[OTC Donate] SQL error: " .. tostring(err) .. " | " .. tostring(sql)) if fail then fail(err) end end
    q:start()
end
local SchemaReady = false
local SchemaCallbacks = {}
local function AfterSchemaReady(fn)
    if not isfunction(fn) then return end
    if SchemaReady then fn() return end
    SchemaCallbacks[#SchemaCallbacks + 1] = fn
end
local function MarkSchemaReady()
    if SchemaReady then return end
    SchemaReady = true
    local callbacks = SchemaCallbacks
    SchemaCallbacks = {}
    for _, fn in ipairs(callbacks) do fn() end
end
local function ChargeTitleKey(title)
    title = string.lower(string.Trim(tostring(title or "")))
    if title == "" then title = "purchase" end
    if util and isfunction(util.CRC) then return tostring(util.CRC(title)) end
    return string.sub(string.gsub(title, "[^%w_]+", "_"), 1, 48)
end
local function MakeChargeKey(source, sid64, amount, title, ts)
    source = string.sub(string.gsub(string.lower(tostring(source or "src")), "[^%w_]+", "_"), 1, 32)
    sid64 = tostring(sid64 or "")
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    ts = math.max(0, math.floor(tonumber(ts) or 0))
    return string.sub(source .. ":" .. sid64 .. ":" .. tostring(amount) .. ":" .. ChargeTitleKey(title) .. ":" .. tostring(ts), 1, 190)
end
local function RegisterDonationCharge(sid64, amount, title, source, ts, paid, cb)
    sid64 = tostring(sid64 or "")
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    title = tostring(title or "")
    source = tostring(source or "")
    ts = math.max(0, math.floor(tonumber(ts) or 0))
    if not IsSteamID64(sid64) or amount <= 0 or amount > 1000000 then if cb then cb(false) end return end
    if not SchemaReady then AfterSchemaReady(function() RegisterDonationCharge(sid64, amount, title, source, ts, paid, cb) end) return end
    local key = MakeChargeKey(source, sid64, amount, title, ts)
    local charged = paid and amount or 0
    Query("INSERT INTO otc_donate_charges (charge_key, steamid64, amount, charged, title, source, ts, created_at, updated_at) VALUES (" .. SQLString(key) .. ", " .. SQLString(sid64) .. ", " .. tostring(amount) .. ", " .. tostring(charged) .. ", " .. SQLString(title) .. ", " .. SQLString(source) .. ", " .. tostring(ts) .. ", NOW(), NOW()) ON DUPLICATE KEY UPDATE steamid64=VALUES(steamid64), amount=GREATEST(amount, VALUES(amount)), title=VALUES(title), source=VALUES(source), ts=VALUES(ts), charged=GREATEST(charged, VALUES(charged)), updated_at=NOW();", function()
        if cb then cb(true, key) end
    end, function()
        if cb then cb(false, key) end
    end)
end
local function ApplyPendingDonationCharges(sid64, name, cb)
    sid64 = tostring(sid64 or "")
    name = tostring(name or "")
    if not IsSteamID64(sid64) then if cb then cb(false, 0, 0) end return end
    if not SchemaReady then AfterSchemaReady(function() ApplyPendingDonationCharges(sid64, name, cb) end) return end
    Query("INSERT INTO otc_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", 0) ON DUPLICATE KEY UPDATE name=VALUES(name);", function()
        Query("START TRANSACTION;", function()
            Query("SELECT balance FROM otc_donate_balance WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1 FOR UPDATE;", function(balanceRows)
                local balance = istable(balanceRows) and balanceRows[1] and math.max(0, math.floor(tonumber(balanceRows[1].balance) or 0)) or 0
                Query("SELECT charge_key, amount, charged FROM otc_donate_charges WHERE steamid64=" .. SQLString(sid64) .. " AND charged<amount ORDER BY ts ASC, created_at ASC FOR UPDATE;", function(rows)
                    local takeLeft = balance
                    local totalTaken = 0
                    local updates = {}
                    for _, row in ipairs(rows or {}) do
                        local due = math.max(0, math.floor(tonumber(row.amount) or 0) - math.floor(tonumber(row.charged) or 0))
                        if due > 0 and takeLeft > 0 then
                            local take = math.min(due, takeLeft)
                            takeLeft = takeLeft - take
                            totalTaken = totalTaken + take
                            updates[#updates + 1] = { key = tostring(row.charge_key or ""), take = take }
                        end
                    end
                    local function commitDone()
                        local newBalance = math.max(0, balance - totalTaken)
                        Query("UPDATE otc_donate_balance SET balance=" .. tostring(newBalance) .. ", name=" .. SQLString(name) .. " WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function()
                            Query("INSERT INTO rk_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(newBalance) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), balance=VALUES(balance);")
                            Query("COMMIT;", function()
                                local ply = player.GetBySteamID64(sid64)
                                if IsValid(ply) then ply.OTC_DonateBalance = newBalance SyncBalance(ply) end
                                if cb then cb(true, totalTaken, newBalance) end
                            end, function()
                                if cb then cb(false, totalTaken, newBalance) end
                            end)
                        end, function()
                            Query("ROLLBACK;")
                            if cb then cb(false, 0, balance) end
                        end)
                    end
                    local i = 0
                    local function nextUpdate()
                        i = i + 1
                        local u = updates[i]
                        if not u then commitDone() return end
                        Query("UPDATE otc_donate_charges SET updated_at=NOW(), charged=LEAST(amount, charged+" .. tostring(u.take) .. ") WHERE charge_key=" .. SQLString(u.key) .. " LIMIT 1;", function() nextUpdate() end, function()
                            Query("ROLLBACK;")
                            if cb then cb(false, totalTaken, balance) end
                        end)
                    end
                    nextUpdate()
                end, function()
                    Query("ROLLBACK;")
                    if cb then cb(false, 0, balance) end
                end)
            end, function()
                Query("ROLLBACK;")
                if cb then cb(false, 0, 0) end
            end)
        end, function()
            if cb then cb(false, 0, 0) end
        end)
    end, function()
        if cb then cb(false, 0, 0) end
    end)
end
local function IsPurchaseRowChargeable(row)
    if not istable(row) then return false end
    local amount = math.max(0, math.floor(tonumber(row.amount) or 0))
    if amount <= 0 or amount > 1000000 then return false end
    local title = string.lower(tostring(row.title or ""))
    if Packages[amount] then return true end
    if string.find(title, "vip", 1, true) or string.find(title, "вип", 1, true) then return true end
    if string.find(title, "moderator", 1, true) or string.find(title, "модератор", 1, true) or string.find(title, "модер", 1, true) then return true end
    if string.find(title, "operator", 1, true) or string.find(title, "оператор", 1, true) then return true end
    if string.find(title, "sponsor", 1, true) or string.find(title, "спонсор", 1, true) then return true end
    if string.find(title, "tts", 1, true) or string.find(title, "говор", 1, true) then return true end
    if string.find(title, "модель", 1, true) or string.find(title, "model", 1, true) then return true end
    return false
end
local function RegisterLegacyPurchaseCharges(sid64, cb)
    sid64 = tostring(sid64 or "")
    if not IsSteamID64(sid64) then if cb then cb(false, 0) end return end
    if not SchemaReady then AfterSchemaReady(function() RegisterLegacyPurchaseCharges(sid64, cb) end) return end
    Query("SELECT id, steamid64, title, amount, COALESCE(NULLIF(ts, 0), UNIX_TIMESTAMP(created_at)) AS ts FROM rk_last_purchases WHERE steamid64=" .. SQLString(sid64) .. " AND amount>0 ORDER BY id ASC;", function(rows)
        local list = {}
        for _, row in ipairs(rows or {}) do
            if IsPurchaseRowChargeable(row) then list[#list + 1] = row end
        end
        local done = 0
        local function finishOne()
            done = done + 1
            if done >= #list then if cb then cb(true, #list) end end
        end
        if #list <= 0 then if cb then cb(true, 0) end return end
        for _, row in ipairs(list) do
            local ts = math.max(0, math.floor(tonumber(row.ts) or 0))
            RegisterDonationCharge(sid64, Money(row.amount), tostring(row.title or "Покупка"), "rk_last_purchases", ts, false, finishOne)
        end
    end, function()
        if cb then cb(false, 0) end
    end)
end
local function EnforceLedgerBalanceCap(sid64, name, cb)
    sid64 = tostring(sid64 or "")
    name = tostring(name or "")
    if not IsSteamID64(sid64) then if cb then cb(false, 0, 0, 0) end return end
    if not SchemaReady then AfterSchemaReady(function() EnforceLedgerBalanceCap(sid64, name, cb) end) return end
    Query("SELECT COALESCE(SUM(amount), 0) AS total FROM rk_processed_orders WHERE steamid64=" .. SQLString(sid64) .. ";", function(orderRows)
        local totalIn = istable(orderRows) and orderRows[1] and Money(orderRows[1].total) or 0
        totalIn = math.floor(totalIn * (tonumber(Cfg.rubToBalance) or 1))
        Query("SELECT COALESCE(SUM(amount), 0) AS spent FROM otc_donate_charges WHERE steamid64=" .. SQLString(sid64) .. ";", function(chargeRows)
            local spent = istable(chargeRows) and chargeRows[1] and Money(chargeRows[1].spent) or 0
            local function finish(promo, ingameSpent)
                local maxBalance = math.max(0, totalIn + promo - spent - ingameSpent)
                Query("INSERT INTO otc_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", 0) ON DUPLICATE KEY UPDATE name=VALUES(name);", function()
                    Query("UPDATE otc_donate_balance SET balance=LEAST(balance, " .. tostring(maxBalance) .. "), name=" .. SQLString(name) .. " WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function()
                        Query("SELECT balance FROM otc_donate_balance WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
                            local bal = istable(rows) and rows[1] and Money(rows[1].balance) or 0
                            Query("INSERT INTO rk_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(bal) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), balance=VALUES(balance);")
                            local ply = player.GetBySteamID64(sid64)
                            if IsValid(ply) then ply.OTC_DonateBalance = bal SyncBalance(ply) end
                            if cb then cb(true, bal, maxBalance, spent) end
                        end, function()
                            if cb then cb(false, 0, maxBalance, spent) end
                        end)
                    end, function()
                        if cb then cb(false, 0, maxBalance, spent) end
                    end)
                end, function()
                    if cb then cb(false, 0, maxBalance, spent) end
                end)
            end
            Query("SELECT COALESCE(SUM(p.amount), 0) AS promo FROM rk_promocode_uses u INNER JOIN rk_promocodes p ON p.code=u.code WHERE u.steamid64=" .. SQLString(sid64) .. ";", function(promoRows)
                local promo = istable(promoRows) and promoRows[1] and Money(promoRows[1].promo) or 0
                Query("SELECT COALESCE(SUM(amount), 0) AS ingame FROM otc_donate_spends WHERE steamid64=" .. SQLString(sid64) .. ";", function(spendRows)
                    local ingameSpent = istable(spendRows) and spendRows[1] and math.floor(tonumber(spendRows[1].ingame) or 0) or 0
                    finish(promo, ingameSpent)
                end, function()
                    finish(promo, 0)
                end)
            end, function()
                Query("SELECT COALESCE(SUM(amount), 0) AS ingame FROM otc_donate_spends WHERE steamid64=" .. SQLString(sid64) .. ";", function(spendRows)
                    local ingameSpent = istable(spendRows) and spendRows[1] and math.floor(tonumber(spendRows[1].ingame) or 0) or 0
                    finish(0, ingameSpent)
                end, function()
                    finish(0, 0)
                end)
            end)
        end, function()
            if cb then cb(false, 0, 0, 0) end
        end)
    end, function()
        if cb then cb(false, 0, 0, 0) end
    end)
end
local function SyncPlayerChargeState(ply, cb)
    if not IsValid(ply) then if cb then cb(false) end return end
    local sid64 = tostring(ply:SteamID64() or "")
    local nick = ply:Nick()
    RegisterLegacyPurchaseCharges(sid64, function()
        ApplyPendingDonationCharges(sid64, nick, function(ok, taken, balance)
            EnforceLedgerBalanceCap(sid64, nick, function(ok2, finalBalance, maxBalance, spent)
                if IsValid(ply) then
                    local before = Money(balance)
                    local final = Money(finalBalance)
                    ply.OTC_DonateBalance = final
                    SyncBalance(ply)
                    local totalAuto = Money(taken) + math.max(0, before - final)
                    if totalAuto > 0 then Chat(ply, "Автоматически списано за ранее активированные покупки: " .. tostring(totalAuto) .. " ₽") end
                end
                if cb then cb(ok or ok2, taken, finalBalance) end
            end)
        end)
    end)
end
Chat = function(ply, msg, typ, len)
    if not IsValid(ply) then return end
    msg = tostring(msg or "")
    if typ == nil then
        local low = string.lower(msg)
        if string.find(low, "ошибка", 1, true) or string.find(low, "не ", 1, true) or string.find(low, "нет", 1, true) or string.find(low, "недостаточно", 1, true) or string.find(low, "заблок", 1, true) or string.find(low, "невалид", 1, true) then
            typ = 1
        else
            typ = 0
        end
    end
    NSStart(ply, "otc_donate_notify", { msg = msg, type = tonumber(typ or 0) or 0, len = tonumber(len or 4) or 4 })
end
Money = function(v)
    return math.max(0, math.floor(tonumber(v) or 0))
end
local function PackagePayload()
    local items = {}
    for amount, p in pairs(Packages) do
        if tostring(p.kind or "") == "rank" and not GetSafeRankPackage(amount) then continue end
        local resolvedModel = ResolvePackageModel(p)
        items[#items + 1] = {
            amount = amount,
            uid = tostring(p.uid or "pack_" .. tostring(amount)),
            kind = tostring(p.kind or "other"),
            category = tostring(p.category or ""),
            title = tostring(p.title or "Товар"),
            subtitle = tostring(p.subtitle or ""),
            tag = tostring(p.tag or ""),
            model = resolvedModel,
            preview_model = resolvedModel,
            icon = tostring(p.icon or ""),
            duration = tonumber(p.duration or 0) or 0,
            isBodygroup = p.isBodygroup == true
        }
    end
    table.sort(items, function(a, b)
        local ka = KindOrder[a.kind] or 99
        local kb = KindOrder[b.kind] or 99
        if ka ~= kb then return ka < kb end
        return (a.amount or 0) < (b.amount or 0)
    end)
    return items
end
local function LoadActiveModels()
    if not file.Exists(Cfg.activeModelsFile, "DATA") then return {} end
    local t = util.JSONToTable(file.Read(Cfg.activeModelsFile, "DATA") or "")
    return istable(t) and t or {}
end
local function SaveActiveModels(t)
    file.Write(Cfg.activeModelsFile, util.TableToJSON(t or {}, true))
end
local function LoadModelStore()
    local fn = tostring(Cfg.modelStoreFile or "rk_models_store.json")
    if fn == "" or not file.Exists(fn, "DATA") then return {} end
    local t = util.JSONToTable(file.Read(fn, "DATA") or "")
    return istable(t) and t or {}
end
local function IsStoreModelActive(raw)
    if not istable(raw) then return false end
    return raw.active == true or raw.enabled == true or raw.selected == true or raw.status == "active"
end
local function IsStoreModelExpired(raw)
    if not istable(raw) then return false end
    local exp = tonumber(raw.exp or raw.expires or raw.expire or 0) or 0
    return exp > 0 and exp < os.time()
end
local function ExtractModelEntries(raw)
    local out = {}
    local seen = {}
    local function add(model, active)
        model = tostring(model or "")
        if model == "" or not string.EndsWith(string.lower(model), ".mdl") then return end
        local key = string.lower(model)
        if seen[key] then
            if active then seen[key].active = true end
            return
        end
        local entry = { model = model, active = active == true }
        seen[key] = entry
        out[#out + 1] = entry
    end
    local function scan(v, active)
        if isstring(v) then
            add(v, active)
            return
        end
        if not istable(v) then return end
        local direct = v.model or v.Model or v.mdl or v.MDL or v.path or v.Path or v.preview_model or v.previewModel
        if direct then add(direct, active or v.active == true or v.status == "active" or v.enabled == true or v.selected == true) end
        for k, val in pairs(v) do
            if isstring(k) and string.EndsWith(string.lower(k), ".mdl") and (val == true or val == 1 or val == "1" or val == "true" or istable(val)) then
                add(k, active or (istable(val) and (val.active == true or val.status == "active" or val.enabled == true or val.selected == true)))
            elseif isstring(val) or istable(val) then
                scan(val, active)
            end
        end
    end
    scan(raw, true)
    return out
end
function OTCDonate.IsManagedModel(model)
    return ManagedDonateModels[NormalizeModelPath(model)] == true
end
local function CanRestoreDonateModelNow(ply, model)
    if not IsValid(ply) then return false end
    model = NormalizeModelPath(model)
    if model == "" then return false end
    local current = NormalizeModelPath(ply:GetModel())
    if current == "" or current == model then return true end
    local base = NormalizeModelPath(ply.RK_AppearanceBaseModel)
    if base == "" and hg and hg.Appearance and isfunction(hg.Appearance.GetModelPathFromAppearance) then
        local appearance = ply.CachedAppearance or ply.CurAppearance
        if istable(appearance) then
            base = NormalizeModelPath(hg.Appearance.GetModelPathFromAppearance(appearance))
            if base ~= "" then ply.RK_AppearanceBaseModel = base end
        end
    end
    if base ~= "" then return current == base end
    return false
end
local function SetActiveModel(sid64, model)
    sid64 = ToSteamID64(sid64)
    model = string.Trim(tostring(model or ""))
    if not IsSteamID64(sid64) then return end
    local t = LoadActiveModels()
    if model ~= "" then
        RegisterManagedModel(model)
        ActiveModelsCache[sid64] = model
        t[sid64] = { model = model, active = true, exp = 2147483647 }
    else
        ActiveModelsCache[sid64] = nil
        t[sid64] = nil
    end
    SaveActiveModels(t)
    if not DB then return end
    if model ~= "" then
        Query("INSERT INTO otc_donate_active_models (steamid64, model) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(model) .. ") ON DUPLICATE KEY UPDATE model=VALUES(model), updated_at=CURRENT_TIMESTAMP;")
        Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
            Query("UPDATE otc_donate_inventory SET status='active' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model' AND model=" .. SQLString(model) .. " LIMIT 1;")
        end)
    else
        Query("DELETE FROM otc_donate_active_models WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;")
        Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';")
    end
end
local function GetActiveModel(sid64)
    sid64 = ToSteamID64(sid64)
    local cached = tostring(ActiveModelsCache[sid64] or "")
    if cached ~= "" then return cached end
    local t = LoadActiveModels()
    local entries = ExtractModelEntries(t[sid64])
    if entries[1] and entries[1].model ~= "" then return tostring(entries[1].model or "") end
    for rawSid, raw in pairs(t) do
        if ToSteamID64(rawSid) == sid64 then
            entries = ExtractModelEntries(raw)
            if entries[1] and entries[1].model ~= "" then return tostring(entries[1].model or "") end
        end
    end
    return ""
end
local function LoadActiveModelDB(ply, cb)
    if not IsValid(ply) then if cb then cb("") end return end
    local sid64 = ToSteamID64(ply:SteamID64())
    if not DB then if cb then cb(GetActiveModel(sid64)) end return end
    Query("SELECT model FROM otc_donate_active_models WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
        local model = istable(rows) and rows[1] and tostring(rows[1].model or "") or ""
        if model ~= "" then RegisterManagedModel(model) end
        if model == "" then
            model = GetActiveModel(sid64)
            if model ~= "" then
                ActiveModelsCache[sid64] = model
                Query("INSERT INTO otc_donate_active_models (steamid64, model) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(model) .. ") ON DUPLICATE KEY UPDATE model=VALUES(model), updated_at=CURRENT_TIMESTAMP;")
                Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
                    Query("UPDATE otc_donate_inventory SET status='active' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model' AND model=" .. SQLString(model) .. " LIMIT 1;")
                end)
            else
                ActiveModelsCache[sid64] = nil
            end
        else
            ActiveModelsCache[sid64] = model
        end
        if cb then cb(model) end
    end, function()
        if cb then cb(GetActiveModel(sid64)) end
    end)
end
local function ClearAppearanceVisuals(ply)
    if not IsValid(ply) then return end
    ply:SetSubMaterial()
    for i = 1, #(ply:GetMaterials() or {}) do ply:SetSubMaterial(i - 1, nil) end
    ply:SetBodyGroups("00000000000000000000")
    for _, bg in ipairs(ply:GetBodyGroups() or {}) do ply:SetBodygroup((bg.id or 1), 0) end
    ply:SetNWString("Colthesmain", "normal")
    ply:SetNWString("Colthespants", "normal")
    ply:SetNWString("Colthesboots", "normal")
    ply:SetNWString("Coltheshands", "normal")
end
local function RefreshAppearance(ply)
    if not IsValid(ply) or not hg or not hg.Appearance then return end
    timer.Simple(0, function()
        if not IsValid(ply) or not hg or not hg.Appearance then return end
        local currentModel = NormalizeModelPath(ply:GetModel())
        local baseModel = NormalizeModelPath(ply.RK_AppearanceBaseModel)
        if baseModel == "" and isfunction(hg.Appearance.GetModelPathFromAppearance) then
            local appearance = ply.CachedAppearance or ply.CurAppearance
            if istable(appearance) then
                baseModel = NormalizeModelPath(hg.Appearance.GetModelPathFromAppearance(appearance))
                if baseModel ~= "" then ply.RK_AppearanceBaseModel = baseModel end
            end
        end
        if currentModel ~= "" and baseModel ~= "" and currentModel ~= baseModel then
            if isfunction(hg.Appearance.ApplyAppearanceAccessoriesOnly) then hg.Appearance.ApplyAppearanceAccessoriesOnly(ply) end
            return
        end
        if isfunction(hg.Appearance.ApplyAppearance) then hg.Appearance.ApplyAppearance(ply, nil, nil, nil, true) end
    end)
end
local function ApplyModel(ply, model)
    if not IsValid(ply) then return false end
    model = tostring(model or "")
    if model == "" then return false end
    if util.IsValidModel and not util.IsValidModel(model) then Chat(ply, "Модель не найдена на сервере: " .. model) return false end
    util.PrecacheModel(model)
    ClearAppearanceVisuals(ply)
    ply.OTC_DonateModelDisabled = nil
    ply.OTC_DonateModel = model
    ply.OTC_DonateModelLockUntil = CurTime() + 12
    ply:SetNWString("OTC_DonateModel", model)
    ply:SetModel(model)
    return true
end
local function ApplyAdminCostume(ply, costume)
    if not istable(costume) then return false end
    if not ApplyModel(ply, costume.model) then return false end
    ply:SetBodygroup(1, tonumber(costume.bodygroup) or 0)
    ply.OTC_AdminCostumeModel = NormalizeModelPath(costume.model)
    return true
end
local function DisableModel(ply)
    if not IsValid(ply) then return end
    local tid = "otc_donate_model_apply_" .. ply:SteamID64()
    if timer.Exists(tid) then timer.Remove(tid) end
    ply.OTC_DonateModelDisabled = true
    ply.OTC_DonateModel = nil
    ply.OTC_DonateModelLockUntil = nil
    ply.OTC_AdminCostumeGroup = nil
    ply.OTC_AdminCostumeModel = nil
    ply:SetNWString("OTC_DonateModel", "")
    SetActiveModel(ply:SteamID64(), "")
    local baseModel = NormalizeModelPath(ply.RK_AppearanceBaseModel)
    if baseModel == "" and hg and hg.Appearance and isfunction(hg.Appearance.GetModelPathFromAppearance) then
        local appearance = ply.CachedAppearance or ply.CurAppearance
        if istable(appearance) then baseModel = NormalizeModelPath(hg.Appearance.GetModelPathFromAppearance(appearance)) end
    end
    if baseModel ~= "" and NormalizeModelPath(ply:GetModel()) ~= baseModel then
        util.PrecacheModel(baseModel)
        ClearAppearanceVisuals(ply)
        ply:SetModel(baseModel)
    end
    RefreshAppearance(ply)
end
function OTCDonate.TryRestoreManagedModel(ply, force)
    if not IsValid(ply) or ply.OTC_DonateModelDisabled then return false end
    local model = tostring(ply.OTC_DonateModel or ply:GetNWString("OTC_DonateModel", "") or "")
    if model == "" then model = GetActiveModel(ply:SteamID64()) end
    if model == "" then return false end
    if not force and not CanRestoreDonateModelNow(ply, model) then return false end
    if ply:GetModel() == model then return true end
    return ApplyModel(ply, model) == true
end
local ResolveAdminCostumePreference
local function ApplySavedModel(ply)
    if not IsValid(ply) or ply.OTC_DonateModelDisabled then return end
    LoadActiveModelDB(ply, function(model)
        if not IsValid(ply) or ply.OTC_DonateModelDisabled then return end
        model = tostring(model or "")
        if model == "" then return end
        ResolveAdminCostumePreference(ply, function(costumeEnabled)
            if not IsValid(ply) or ply.OTC_DonateModelDisabled then return end
            if not costumeEnabled and AdminCostumeModels[NormalizeModelPath(model)] then return end
            ply.OTC_DonateModel = model
            ply:SetNWString("OTC_DonateModel", model)
            local tid = "otc_donate_model_apply_" .. ply:SteamID64()
            if timer.Exists(tid) then timer.Remove(tid) end
            timer.Create(tid, 0.25, 8, function()
                if not IsValid(ply) then timer.Remove(tid) return end
                if ply.OTC_DonateModelDisabled then timer.Remove(tid) return end
                if not costumeEnabled and AdminCostumeModels[NormalizeModelPath(model)] then timer.Remove(tid) return end
                if OTCDonate.TryRestoreManagedModel(ply, false) then timer.Remove(tid) return end
            end)
        end)
    end)
end
local function PersistAdminCostumePreference(sid64, enabled)
    if not DB or not IsSteamID64(sid64) then return end
    Query("INSERT INTO otc_admin_costume_settings (steamid64, enabled) VALUES (" .. SQLString(sid64) .. ", " .. (enabled and 1 or 0) .. ") ON DUPLICATE KEY UPDATE enabled=VALUES(enabled), updated_at=CURRENT_TIMESTAMP;")
end
local function ResolveAdminCostumeFromLocal(sid64, cached, finish)
    if not DB then finish(cached == nil or cached.enabled == true) return end
    Query("SELECT enabled FROM otc_admin_costume_settings WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
        if istable(rows) and rows[1] and rows[1].enabled ~= nil then
            finish(tonumber(rows[1].enabled) ~= 0)
        else
            finish(cached == nil or cached.enabled == true)
        end
    end, function()
        finish(cached == nil or cached.enabled == true)
    end)
end
local AdminCostumePreferences = {}
ResolveAdminCostumePreference = function(ply, callback)
    if not IsValid(ply) then return end
    local sid64 = ToSteamID64(ply:SteamID64())
    if not IsSteamID64(sid64) then if callback then callback(true) end return end
    local cached = AdminCostumePreferences[sid64]
    if cached and cached.pending then
        if callback then
            cached.callbacks = cached.callbacks or {}
            cached.callbacks[#cached.callbacks + 1] = callback
        end
        return
    end
    if cached and cached.checkedAt and cached.checkedAt + 1.5 > CurTime() then
        if callback then callback(cached.enabled ~= false) end
        return
    end
    local callbacks = {}
    if callback then callbacks[1] = callback end
    local function finish(enabled)
        enabled = enabled == true
        AdminCostumePreferences[sid64] = { enabled = enabled, checkedAt = CurTime() }
        for _, fn in ipairs(callbacks) do fn(enabled) end
    end
    local panelURL = string.Trim(tostring(Cfg.adminCostumePanelURL or ""))
    if panelURL ~= "" then
        AdminCostumePreferences[sid64] = { enabled = cached ~= nil and cached.enabled == true, checkedAt = cached and cached.checkedAt or 0, pending = true, callbacks = callbacks }
        local requestURL = panelURL .. (string.find(panelURL, "?", 1, true) and "&" or "?") .. "action=get_admin_costume_state&steam_id=" .. sid64
        local syncToken = string.Trim(tostring(Cfg.adminCostumeSyncToken or ""))
        if syncToken ~= "" then
            requestURL = requestURL .. "&token=" .. syncToken
        end
        local reqHeaders = { ["User-Agent"] = "OTCDonate" }
        if syncToken ~= "" then reqHeaders["X-Sync-Token"] = syncToken end
        HTTP({
            url = requestURL,
            method = "get",
            timeout = 5,
            headers = reqHeaders,
            success = function(code, body)
                local data = tonumber(code) == 200 and util.JSONToTable(body or "") or nil
                local pending = AdminCostumePreferences[sid64]
                callbacks = pending and pending.callbacks or callbacks
                if istable(data) and data.success == true then
                    local value = data.enabled
                    local resolved = value == true or value == 1 or value == "1" or string.lower(tostring(value or "")) == "true"
                    PersistAdminCostumePreference(sid64, resolved)
                    finish(resolved)
                    return
                end
                ResolveAdminCostumeFromLocal(sid64, cached, finish)
            end,
            failed = function()
                local pending = AdminCostumePreferences[sid64]
                callbacks = pending and pending.callbacks or callbacks
                ResolveAdminCostumeFromLocal(sid64, cached, finish)
            end
        })
        return
    end
    Query("SELECT enabled FROM otc_admin_costume_settings WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
        finish(not (istable(rows) and rows[1] and tonumber(rows[1].enabled) == 0))
    end, function()
        finish(true)
    end)
end
local function SyncAdminCostumeResolved(ply, enabled)
    if not IsValid(ply) or not DB then return end
    local costume, group = GetAdminCostume(ply)
    local sid64 = ToSteamID64(ply:SteamID64())
    if not IsSteamID64(sid64) then return end
    if not enabled then costume, group = nil, nil end
    if costume then
        local changed = ply.OTC_AdminCostumeGroup ~= group
        ply.OTC_AdminCostumeGroup = group
        ply.OTC_AdminCostumeModel = NormalizeModelPath(costume.model)
        Query("SELECT id FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(costume.uid) .. " ORDER BY id DESC LIMIT 1;", function(rows)
            if not IsValid(ply) then return end
            local row = istable(rows) and rows[1] or nil
            local sql
            if row then
                sql = "UPDATE otc_donate_inventory SET amount=0, title=" .. SQLString("АДМИН КОСТЮМ") .. ", subtitle=" .. SQLString("Автоматическая модель для ранга " .. group) .. ", tag=" .. SQLString("ADMIN • DEFAULT") .. ", kind='model', model=" .. SQLString(costume.model) .. ", duration=0, status=CASE WHEN status='used' THEN 'owned' ELSE status END WHERE id=" .. tostring(Money(row.id)) .. " LIMIT 1;"
            else
                sql = "INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(costume.uid) .. ", 0, " .. SQLString("АДМИН КОСТЮМ") .. ", " .. SQLString("Автоматическая модель для ранга " .. group) .. ", " .. SQLString("ADMIN • DEFAULT") .. ", 'model', " .. SQLString(costume.model) .. ", 0, 'owned');"
            end
            Query(sql, function()
                if not IsValid(ply) then return end
                Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid IN ('admin_costume', 'admin_plus_costume', 'st_admin_costume', 'superadmin_costume') AND uid<>" .. SQLString(costume.uid) .. ";")
                if changed then SetActiveModel(sid64, costume.model) end
                ply.OTC_DonateModelDisabled = nil
                ply.OTC_DonateModel = costume.model
                ply:SetNWString("OTC_DonateModel", costume.model)
                if NormalizeModelPath(ply:GetModel()) == NormalizeModelPath(costume.model) then
                    ply:SetBodygroup(1, tonumber(costume.bodygroup) or 0)
                elseif CanRestoreDonateModelNow(ply, costume.model) then
                    ApplyAdminCostume(ply, costume)
                end
                SyncInventory(ply)
            end)
        end)
        return
    end
    local previousModel = NormalizeModelPath(ply.OTC_AdminCostumeModel)
    local currentModel = NormalizeModelPath(ply:GetModel())
    local selectedModel = NormalizeModelPath(ply.OTC_DonateModel or ply:GetNWString("OTC_DonateModel", ""))
    local activeModel = NormalizeModelPath(GetActiveModel(sid64))
    local isAdminCostumeActive = AdminCostumeModels[currentModel] == true or AdminCostumeModels[selectedModel] == true or AdminCostumeModels[activeModel] == true

    if previousModel ~= "" and (currentModel == previousModel or selectedModel == previousModel or activeModel == previousModel) then
        isAdminCostumeActive = true
    end

    ply.OTC_AdminCostumeGroup = nil
    ply.OTC_AdminCostumeModel = nil
    Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid IN ('admin_costume', 'admin_plus_costume', 'st_admin_costume', 'superadmin_costume');", function()
        if not IsValid(ply) then return end
        if isAdminCostumeActive then
            DisableModel(ply)
        end
        SyncInventory(ply)
    end)
end
local function SyncAdminCostume(ply)
    if not IsValid(ply) or not DB then return end
    if not GetAdminCostume(ply) then
        SyncAdminCostumeResolved(ply, true)
        return
    end
    ResolveAdminCostumePreference(ply, function(enabled)
        if IsValid(ply) then SyncAdminCostumeResolved(ply, enabled) end
    end)
end
local function EnsureModelInventoryForSteamID(sid64, model, active)
    sid64 = ToSteamID64(sid64)
    model = tostring(model or "")
    if not IsSteamID64(sid64) or model == "" then return end
    local amount, pack = PackageByModel(model)
    local uid = pack and Clean(pack.uid, 128) or ImportedModelUID(model)
    local title = pack and tostring(pack.title or "Модель") or ImportedModelTitle(model)
    local subtitle = pack and tostring(pack.subtitle or "Импортировано из JSON") or "Импортировано из JSON"
    local tag = pack and tostring(pack.tag or "PERMANENT") or "PERMANENT • IMPORTED"
    local status = active and "active" or "owned"
    Query("SELECT id FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;", function(rows)
        if istable(rows) and rows[1] then
            if active then
                Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
                    Query("UPDATE otc_donate_inventory SET model=" .. SQLString(model) .. ", status='active' WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;")
                end)
            else
                Query("UPDATE otc_donate_inventory SET model=" .. SQLString(model) .. " WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;")
            end
            return
        end
        if active then
            Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
                Query("INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ", " .. tostring(Money(amount)) .. ", " .. SQLString(title) .. ", " .. SQLString(subtitle) .. ", " .. SQLString(tag) .. ", 'model', " .. SQLString(model) .. ", 0, " .. SQLString(status) .. ");")
            end)
        else
            Query("INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ", " .. tostring(Money(amount)) .. ", " .. SQLString(title) .. ", " .. SQLString(subtitle) .. ", " .. SQLString(tag) .. ", 'model', " .. SQLString(model) .. ", 0, 'owned');")
        end
    end)
end
local function GivePersonalModel(sid64, model, cb)
    sid64 = ToSteamID64(sid64)
    model = string.Trim(tostring(model or ""))
    if not IsSteamID64(sid64) or model == "" then if cb then cb(false, "bad_args") end return end
    if not string.EndsWith(string.lower(model), ".mdl") then if cb then cb(false, "bad_model") end return end
    if util.IsValidModel and not util.IsValidModel(model) then if cb then cb(false, "invalid_model") end return end
    RegisterManagedModel(model)
    local uid = Clean("personal_" .. ImportedModelUID(model), 128)
    local title = ImportedModelTitle(model) .. " (Личная модель)"
    local subtitle = "Личная модель"
    local tag = "PERSONAL • ЛИЧНАЯ"
    Query("SELECT id FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;", function(rows)
        if istable(rows) and rows[1] then
            Query("UPDATE otc_donate_inventory SET model=" .. SQLString(model) .. ", title=" .. SQLString(title) .. ", subtitle=" .. SQLString(subtitle) .. ", tag=" .. SQLString(tag) .. ", kind='model', duration=0, status=CASE WHEN status='used' THEN 'owned' ELSE status END WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;", function()
                local target = player.GetBySteamID64(sid64)
                if IsValid(target) then SyncInventory(target) end
                if cb then cb(true, "updated") end
            end, function()
                if cb then cb(false, "sql_error") end
            end)
            return
        end
        Query("INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ", 0, " .. SQLString(title) .. ", " .. SQLString(subtitle) .. ", " .. SQLString(tag) .. ", 'model', " .. SQLString(model) .. ", 0, 'owned');", function()
            local target = player.GetBySteamID64(sid64)
            if IsValid(target) then SyncInventory(target) end
            if cb then cb(true, "created") end
        end, function()
            if cb then cb(false, "sql_error") end
        end)
    end, function()
        if cb then cb(false, "sql_error") end
    end)
end
local function ImportActiveModelsJSONToDB()
    if not DB then return end
    local active = LoadActiveModels()
    local store = LoadModelStore()
    if istable(active) then
        for rawSid, raw in pairs(active) do
            local sid64 = ToSteamID64(rawSid)
            if IsSteamID64(sid64) then
                local entries = ExtractModelEntries(raw)
                local activeModel = ""
                for _, entry in ipairs(entries) do
                    EnsureModelInventoryForSteamID(sid64, entry.model, entry.active == true)
                    if entry.active == true and activeModel == "" then activeModel = entry.model end
                end
                if activeModel == "" and entries[1] and entries[1].model ~= "" then activeModel = entries[1].model end
                if activeModel ~= "" then
                    ActiveModelsCache[sid64] = activeModel
                    Query("INSERT INTO otc_donate_active_models (steamid64, model) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(activeModel) .. ") ON DUPLICATE KEY UPDATE model=VALUES(model), updated_at=CURRENT_TIMESTAMP;")
                    EnsureModelInventoryForSteamID(sid64, activeModel, true)
                end
            end
        end
    end
    if istable(store) then
        for rawSid, raw in pairs(store) do
            local sid64 = ToSteamID64(rawSid)
            if IsSteamID64(sid64) and not IsStoreModelExpired(raw) then
                local entries = ExtractModelEntries(raw)
                local forceActive = IsStoreModelActive(raw)
                for _, entry in ipairs(entries) do
                    EnsureModelInventoryForSteamID(sid64, entry.model, forceActive or entry.active == true)
                    if forceActive or entry.active == true then
                        ActiveModelsCache[sid64] = entry.model
                        Query("INSERT INTO otc_donate_active_models (steamid64, model) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(entry.model) .. ") ON DUPLICATE KEY UPDATE model=VALUES(model), updated_at=CURRENT_TIMESTAMP;")
                    end
                end
            end
        end
    end
end
local TTS_LEGACY_FILE = "aw_tts_subs.json"
local function LoadTTS()
    if isfunction(AW_TTS_GetAll) then
        local shared = AW_TTS_GetAll()
        if istable(shared) then return shared end
    end
    local out = {}
    if file.Exists(Cfg.ttsFile, "DATA") then
        local t = util.JSONToTable(file.Read(Cfg.ttsFile, "DATA") or "")
        if istable(t) then
            for sid, exp in pairs(t) do
                local e = tonumber(exp or 0) or 0
                if e > 0 then out[tostring(sid)] = e end
            end
        end
    end
    if file.Exists(TTS_LEGACY_FILE, "DATA") then
        local t2 = util.JSONToTable(file.Read(TTS_LEGACY_FILE, "DATA") or "")
        if istable(t2) then
            for sid, exp in pairs(t2) do
                local e = tonumber(exp or 0) or 0
                if e > (tonumber(out[tostring(sid)] or 0) or 0) then out[tostring(sid)] = e end
            end
        end
    end
    return out
end
local function SaveTTS(t)
    local json = util.TableToJSON(t or {}, true)
    file.Write(Cfg.ttsFile, json)
    file.Write(TTS_LEGACY_FILE, json)
    if isfunction(AW_TTS_Reload) then AW_TTS_Reload() end
end
local function GiveTTS(ply, duration)
    if not IsValid(ply) then return false end
    duration = math.floor(tonumber(duration) or 0)
    if duration <= 0 then return false end
    if isfunction(AW_TTS_AddSubTime) then
        local ok, exp = AW_TTS_AddSubTime(ply, duration)
        if ok then
            Chat(ply, "TTS активен до " .. os.date("%d.%m.%Y %H:%M", tonumber(exp) or os.time()))
            return true
        end
    end
    local now = os.time()
    local sid = ply:SteamID()
    local t = LoadTTS()
    local cur = tonumber(t[sid] or 0) or 0
    if cur < now then cur = now end
    local cap = 21 * 86400
    local exp = math.min(cur + duration, now + cap)
    t[sid] = exp
    SaveTTS(t)
    ply:SetNWBool("TTSActive", true)
    ply:SetNWFloat("TTSExpire", exp)
    Chat(ply, "TTS активен до " .. os.date("%d.%m.%Y %H:%M", exp))
    return true
end
local function SAMCommandExists()
    if not concommand or not concommand.GetTable then return false end
    local t = concommand.GetTable()
    return istable(t) and (t.sam ~= nil or t.setrankid ~= nil)
end
local function SAMDurationMinutes(sec)
    sec = math.floor(tonumber(sec) or 0)
    if sec <= 0 or sec > 90 * 86400 then return 0 end
    return math.Clamp(math.floor(sec / 60 + 0.5), 1, 129600)
end
local function SetRankSafe(sid64, group, duration)
    sid64 = tostring(sid64 or "")
    group = string.lower(string.Trim(tostring(group or "")))
    duration = math.floor(tonumber(duration) or 0)
    if not IsSteamID64(sid64) then OTCLogSecurity("blocked invalid steamid64 for rank") return false end
    if group == "" or not SafeRanks[group] or BlockedRanks[group] then OTCLogSecurity("blocked unsafe rank " .. tostring(group) .. " for " .. sid64) return false end
    if duration <= 0 or duration > 90 * 86400 then OTCLogSecurity("blocked unsafe duration " .. tostring(duration) .. " for " .. sid64) return false end
    if OTC_ORIGINAL_RUNCONSOLECOMMAND ~= RunConsoleCommand then OTCLogSecurity("blocked rank because RunConsoleCommand was replaced") return false end
    if OTC_ORIGINAL_NETSTREAM_HOOK and OTC_ORIGINAL_NETSTREAM_HOOK ~= netstream.Hook then OTCLogSecurity("blocked rank because netstream.Hook was replaced") return false end
    if not SAMCommandExists() then OTCLogSecurity("blocked rank because SAM command not found") return false end
    local minutes = SAMDurationMinutes(duration)
    if minutes <= 0 then OTCLogSecurity("blocked invalid rank minutes for " .. sid64) return false end
    local ct = concommand.GetTable()
    if istable(ct) and ct.sam then
        OTC_ORIGINAL_RUNCONSOLECOMMAND("sam", "setrankid", sid64, group, tostring(minutes))
        return true
    end
    if istable(ct) and ct.setrankid then
        OTC_ORIGINAL_RUNCONSOLECOMMAND("setrankid", sid64, group, tostring(minutes))
        return true
    end
    return false
end
local function GiveRank(ply, group, duration)
    if not IsValid(ply) then return false end
    if not CanReceiveDonateRank(ply) then
        Chat(ply, "Донат-ранг не выдан: у тебя уже есть staff-ранг.")
        return false
    end
    local sid64 = tostring(ply:SteamID64() or "")
    if not SetRankSafe(sid64, group, duration) then
        Chat(ply, "Не удалось выдать ранг безопасно.")
        return false
    end
    return true
end
RK_DonateAccessories = RK_DonateAccessories or {}
OTC_DonateAccessories = RK_DonateAccessories
local function GetAccsTable(sid64)
    sid64 = tostring(sid64 or "")
    RK_DonateAccessories[sid64] = RK_DonateAccessories[sid64] or {}
    OTC_DonateAccessories[sid64] = RK_DonateAccessories[sid64]
    return RK_DonateAccessories[sid64]
end
function OTC_ReleaseMarketBlock(sid64, uid)
    sid64 = tostring(sid64 or "")
    uid = tostring(uid or "")
    if sid64 == "" or uid == "" then return end
    if isfunction(_G.HG_Market_ClearRevoked) then pcall(_G.HG_Market_ClearRevoked, sid64, uid) end
    if hg and istable(hg.Market) and isfunction(hg.Market.ReleaseBlock) then pcall(hg.Market.ReleaseBlock, sid64, uid) end
end
function RK_HasDonateAccessory(ply, uid)
    if not IsValid(ply) then return false end
    return GetAccsTable(ply:SteamID64())[tostring(uid or "")] == true
end
function RK_HasDonateBodygroup(ply, uid)
    return RK_HasDonateAccessory(ply, uid)
end
function OTC_HasDonateAccessory(ply, uid)
    return RK_HasDonateAccessory(ply, uid)
end
function OTC_HasDonateBodygroup(ply, uid)
    return RK_HasDonateBodygroup(ply, uid)
end
local function SendPointshopVars(ply)
    if not IsValid(ply) then return end
    if hg and hg.Pointshop and isfunction(hg.Pointshop.NET_SendPointShopVars) then hg.Pointshop:NET_SendPointShopVars(ply) return end
    if hg and hg.PointShop and isfunction(hg.PointShop.NET_SendPointShopVars) then hg.PointShop:NET_SendPointShopVars(ply) return end
    if hg and hg.PointShop and isfunction(hg.PointShop.SendNET) then hg.PointShop:SendNET("SendPointShopVars", ply) return end
end
local function SyncAccessories(ply)
    if not IsValid(ply) then return end
    local data = { items = GetAccsTable(ply:SteamID64()) }
    NSStart(ply, "rk_donate_accs_sync", data)
    NSStart(ply, "otc_donate_accs_sync", data)
end
local function RefreshDonateAccessoryState(ply)
    if not IsValid(ply) then return end
    SyncAccessories(ply)
    if SyncExojumpState then SyncExojumpState(ply) end
    SendPointshopVars(ply)
    RefreshAppearance(ply)
end
local function GiveAccessory(ply, uid, cb)
    if not IsValid(ply) then if cb then cb(false) end return end
    uid = Clean(uid, 128)
    if uid == "" then if cb then cb(false) end return end
    local sid64 = tostring(ply:SteamID64() or "")
    if not IsSteamID64(sid64) then if cb then cb(false) end return end
    local cached = RK_HasDonateAccessory(ply, uid)
    OTC_ReleaseMarketBlock(sid64, uid)
    Query("INSERT IGNORE INTO rk_owned_accessories (steamid64, uid) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ");", function(_, query)
        GetAccsTable(sid64)[uid] = true
        Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='accs' AND uid=" .. SQLString(uid) .. ";")
        OTC_ReleaseMarketBlock(sid64, uid)
        RefreshDonateAccessoryState(ply)
        local existed = cached
        if query and isfunction(query.affectedRows) then existed = query:affectedRows() == 0 end
        if cb then cb(true, existed) end
    end, function()
        if cached then
            GetAccsTable(sid64)[uid] = true
            RefreshDonateAccessoryState(ply)
            if cb then cb(true, true) end
            return
        end
        if cb then cb(false) end
    end)
end
local function LoadAccessories(ply)
    if not IsValid(ply) then return end
    local sid64 = tostring(ply:SteamID64() or "")
    local preload = {}
    local function addOwned(uid)
        uid = Clean(uid, 128)
        if uid == "" then return end
        preload[uid] = true
        Query("INSERT IGNORE INTO rk_owned_accessories (steamid64, uid) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ");")
    end
    local function finish()
        Query("SELECT uid FROM rk_owned_accessories WHERE steamid64=" .. SQLString(sid64) .. ";", function(rows)
            local owned = {}
            for uid in pairs(preload) do owned[uid] = true end
            for _, row in ipairs(rows or {}) do
                local uid = Clean(row.uid, 128)
                if uid ~= "" then owned[uid] = true end
            end
            RK_DonateAccessories[sid64] = owned
            OTC_DonateAccessories[sid64] = owned
            Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='accs';")
            for uid in pairs(owned) do OTC_ReleaseMarketBlock(sid64, uid) end
            RefreshDonateAccessoryState(ply)
        end, function()
            RK_DonateAccessories[sid64] = preload
            OTC_DonateAccessories[sid64] = preload
            RefreshDonateAccessoryState(ply)
        end)
    end
    Query("SELECT uid FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='accs' AND uid<>'' AND status<>'used';", function(rows)
        for _, row in ipairs(rows or {}) do addOwned(row.uid) end
        finish()
    end, function()
        finish()
    end)
end
local function HasExojump(ply)
    return IsValid(ply) and GetAccsTable(ply:SteamID64())["exojump"] == true
end
local function RefillExojumpStamina(ply)
    if not IsValid(ply) then return end
    if isfunction(ply.SetStamina) then pcall(ply.SetStamina, ply, 100) end
    if isfunction(ply.SetRunStamina) then pcall(ply.SetRunStamina, ply, 100) end
    if isfunction(ply.SetSprintStamina) then pcall(ply.SetSprintStamina, ply, 100) end
    if isfunction(ply.SetLocalVar) then
        pcall(ply.SetLocalVar, ply, "stamina", 100)
        pcall(ply.SetLocalVar, ply, "stm", 100)
        pcall(ply.SetLocalVar, ply, "run_stamina", 100)
    end
    if isfunction(ply.SetNetVar) then
        pcall(ply.SetNetVar, ply, "stamina", 100)
        pcall(ply.SetNetVar, ply, "stm", 100)
        pcall(ply.SetNetVar, ply, "run_stamina", 100)
    end
    ply:SetNWFloat("Stamina", 100)
    ply:SetNWFloat("stamina", 100)
    ply:SetNWFloat("stm", 100)
    ply:SetNWFloat("RunStamina", 100)
    ply:SetNWFloat("SprintStamina", 100)
    if isnumber(ply.Stamina) then ply.Stamina = 100 end
    if isnumber(ply.stamina) then ply.stamina = 100 end
    if isnumber(ply.RunStamina) then ply.RunStamina = 100 end
    if isnumber(ply.SprintStamina) then ply.SprintStamina = 100 end
end
SyncExojumpState = function(ply)
    if not IsValid(ply) then return end
    local enabled = HasExojump(ply)
    ply:SetNWBool("OTC_ExoJump", enabled)
    ply:SetNWBool("OTC_DonateNoKnockdown", enabled)
    ply:SetNWBool("NoKnockDown", enabled)
    ply:SetNWBool("NoRagdoll", enabled)
    if enabled then RefillExojumpStamina(ply) end
end
local function ExojumpBlockHook(ply)
    if HasExojump(ply) then return false end
end
hook.Add("CanPlayerRagdoll", "otc_donate_exojump_block_ragdoll", ExojumpBlockHook)
hook.Add("CanPlayerBeRagdolled", "otc_donate_exojump_block_ragdolled", ExojumpBlockHook)
hook.Add("PlayerCanRagdoll", "otc_donate_exojump_player_ragdoll", ExojumpBlockHook)
hook.Add("CanRagdoll", "otc_donate_exojump_can_ragdoll", ExojumpBlockHook)
hook.Add("CanPlayerKnockDown", "otc_donate_exojump_knockdown", ExojumpBlockHook)
hook.Add("CanPlayerBeKnockedDown", "otc_donate_exojump_be_knockdown", ExojumpBlockHook)
hook.Add("CanKnockDown", "otc_donate_exojump_can_knockdown", ExojumpBlockHook)
hook.Add("CanPushPlayer", "otc_donate_exojump_push", ExojumpBlockHook)
hook.Add("CanPlayerBePushed", "otc_donate_exojump_be_pushed", ExojumpBlockHook)
hook.Add("SetupMove", "otc_donate_exojump_stamina", function(ply)
    if not HasExojump(ply) then return end
    local now = CurTime()
    if ply.OTCNextExojumpStamina and ply.OTCNextExojumpStamina > now then return end
    ply.OTCNextExojumpStamina = now + 0.15
    RefillExojumpStamina(ply)
end)
hook.Add("PlayerSpawn", "otc_donate_exojump_spawn", function(ply)
    timer.Simple(0.2, function() if IsValid(ply) and SyncExojumpState then SyncExojumpState(ply) end end)
end)

OTCDonate.HasAccessory = function(ply, uid) return RK_HasDonateAccessory(ply, uid) end
OTCDonate.GiveAccessory = function(ply, uid, cb) return GiveAccessory(ply, uid, cb) end
OTCDonate.GiveDonateRank = function(ply, group, duration) return GiveRank(ply, group, duration) end
OTCDonate.TakeAccessoryOffline = function(sid64, uid, cb)
    sid64 = ToSteamID64(sid64)
    uid = Clean(uid, 128)
    if not IsSteamID64(sid64) or uid == "" then if cb then cb(false) end return end
    GetAccsTable(sid64)[uid] = nil
    local ply = player.GetBySteamID64(sid64)
    if IsValid(ply) then RefreshDonateAccessoryState(ply) end
    Query("DELETE FROM rk_owned_accessories WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " LIMIT 1;", function()
        Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='accs' AND uid=" .. SQLString(uid) .. ";")
        GetAccsTable(sid64)[uid] = nil
        local target = player.GetBySteamID64(sid64)
        if IsValid(target) then RefreshDonateAccessoryState(target) end
        if cb then cb(true) end
    end, function()
        if cb then cb(false) end
    end)
end
OTCDonate.GiveAccessoryOffline = function(sid64, uid, cb)
    sid64 = ToSteamID64(sid64)
    uid = Clean(uid, 128)
    if not IsSteamID64(sid64) or uid == "" then if cb then cb(false) end return end
    local ply = player.GetBySteamID64(sid64)
    if IsValid(ply) then GiveAccessory(ply, uid, cb) return end
    GetAccsTable(sid64)[uid] = true
    OTC_ReleaseMarketBlock(sid64, uid)
    Query("INSERT IGNORE INTO rk_owned_accessories (steamid64, uid) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ");", function()
        Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='accs' AND uid=" .. SQLString(uid) .. ";")
        OTC_ReleaseMarketBlock(sid64, uid)
        if cb then cb(true) end
    end, function()
        if cb then cb(false) end
    end)
end
OTCDonate.TakeAccessory = function(ply, uid, cb)
    if not IsValid(ply) then return OTCDonate.TakeAccessoryOffline(ply, uid, cb) end
    return OTCDonate.TakeAccessoryOffline(ply:SteamID64(), uid, cb)
end
OTCDonate.RefreshAccessories = function(ply)
    if not IsValid(ply) then return false end
    RefreshDonateAccessoryState(ply)
    return true
end
OTCDonate.ReloadAccessories = function(ply)
    if not IsValid(ply) then return false end
    LoadAccessories(ply)
    return true
end
local function GiveCaseAccessory(ply, uid)
    uid = tostring(uid or "")
    if uid == "" then return false end
    local acc = (hg and hg.Accessories) and hg.Accessories[uid] or nil
    if istable(acc) and acc.donateOnly == true then
        local shopUID = tostring(acc.DonateID or uid)
        GiveAccessory(ply, shopUID)
        if shopUID ~= uid then GiveAccessory(ply, uid) end
        return true
    end
    if isfunction(_G.RK_GiveCoinAccessory) then
        local ok = pcall(_G.RK_GiveCoinAccessory, ply, uid)
        if ok then
            if isfunction(RefreshAppearance) then RefreshAppearance(ply) end
            return true
        end
    end
    GiveAccessory(ply, uid)
    return true
end
local function ResolveAccessoryUID(query)
    query = string.lower(string.Trim(tostring(query or "")))
    if query == "" then return nil end
    if hg and istable(hg.Accessories) then
        for uid, accessory in pairs(hg.Accessories) do
            if string.lower(tostring(uid)) == query then return tostring(uid) end
            if istable(accessory) and string.lower(tostring(accessory.name or "")) == query then return tostring(uid) end
        end
    end
    return nil
end

concommand.Add("hg_give_accessory", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:IsSuperAdmin() then return end
    local uid = ResolveAccessoryUID(table.concat(args or {}, " "))
    if not uid or uid == "none" then
        Chat(ply, "Аксессуар не найден. Использование: hg_give_accessory <id или название>", 1)
        return
    end
    local accessory = hg and hg.Accessories and hg.Accessories[uid] or nil
    if not istable(accessory) then
        Chat(ply, "Аксессуар не найден.", 1)
        return
    end
    if GiveCaseAccessory(ply, uid) then
        Chat(ply, "Навсегда выдан аксессуар: " .. tostring(accessory.name or uid))
    else
        Chat(ply, "Не удалось выдать аксессуар.", 1)
    end
end)

hook.Add("HG.Cases.GiveReward", "OTC.Cases.DonateRewards", function(ply, reward)
    if not IsValid(ply) or not istable(reward) then return end
    if reward.kind == "accessory" and reward.accId then
        return GiveCaseAccessory(ply, tostring(reward.accId))
    end
    if reward.kind == "rank" and reward.rankGroup then
        GiveRank(ply, tostring(reward.rankGroup), tonumber(reward.rankDuration))
        return true
    end
end)
local Monthly = { month = os.date("%Y-%m"), record = 0, holder = "" }
local function LoadMonthly()
    if not file.Exists(Cfg.monthlyFile, "DATA") then return end
    local t = util.JSONToTable(file.Read(Cfg.monthlyFile, "DATA") or "")
    if istable(t) then Monthly = t end
end
local function SaveMonthly()
    file.Write(Cfg.monthlyFile, util.TableToJSON(Monthly, true))
end
local function FreshMonth()
    local m = os.date("%Y-%m")
    if Monthly.month ~= m then Monthly = { month = m, record = 0, holder = "" } SaveMonthly() end
end
local DonateMemeRanks = {
    { amount = 0, name = "Без портфеля" },
    { amount = 5, name = "Монетка под ковриком" },
    { amount = 10, name = "Плюнул копейкой" },
    { amount = 15, name = "Кассовый разведчик" },
    { amount = 25, name = "Инвестор сухариков" },
    { amount = 35, name = "Пакетик ликвидности" },
    { amount = 50, name = "Дошик-инвестор" },
    { amount = 75, name = "Чайный вкладчик" },
    { amount = 100, name = "Купил себе уважение" },
    { amount = 125, name = "Миноритарий шаурмы" },
    { amount = 150, name = "Пивной акционер" },
    { amount = 200, name = "Микро-меценат" },
    { amount = 250, name = "Мамкин трейдер" },
    { amount = 300, name = "Кэшбековый рыцарь" },
    { amount = 400, name = "Бизнесмен с рынка" },
    { amount = 500, name = "Хранитель ценных бумаг" },
    { amount = 600, name = "Донатный скуф" },
    { amount = 750, name = "Скупщик акций OT-City" },
    { amount = 900, name = "Кошелёк проснулся" },
    { amount = 1000, name = "Акционер подъезда" },
    { amount = 1250, name = "Держатель зелёного пакета" },
    { amount = 1500, name = "Спонсор парковки" },
    { amount = 1750, name = "Шаурма-меценат" },
    { amount = 2000, name = "Олигарх на минималках" },
    { amount = 2250, name = "Биржевой хомяк" },
    { amount = 2500, name = "Барон баланса" },
    { amount = 2750, name = "Купонный аристократ" },
    { amount = 3000, name = "Донатный магнат" },
    { amount = 3500, name = "Купец зелёной кнопки" },
    { amount = 4000, name = "Граф пополнений" },
    { amount = 4500, name = "Лорд терминала" },
    { amount = 5000, name = "Шейх с Авито" },
    { amount = 5500, name = "Портфельный боярин" },
    { amount = 6000, name = "Министр кошелька" },
    { amount = 6500, name = "Дивидендный колдун" },
    { amount = 7000, name = "Князь монетизации" },
    { amount = 7500, name = "Фондовый шаман" },
    { amount = 8000, name = "Повелитель кассы" },
    { amount = 8500, name = "Серый кардинал банка" },
    { amount = 9000, name = "Султан транзакций" },
    { amount = 9500, name = "Директор банкомата" },
    { amount = 10000, name = "Батя сервера" },
    { amount = 11000, name = "Биржевой волк OT-City" },
    { amount = 12000, name = "Донатный патриарх" },
    { amount = 13000, name = "Контролёр пакета акций" },
    { amount = 14000, name = "Легенда терминала" },
    { amount = 15000, name = "Крупный акционер" },
    { amount = 16000, name = "Император доната" },
    { amount = 17000, name = "Золотой держатель" },
    { amount = 18000, name = "Кибер-меценат" },
    { amount = 19000, name = "Покупатель контрольного дошика" },
    { amount = 20000, name = "Монетный архангел" },
    { amount = 22500, name = "Владелец маленькой свечки" },
    { amount = 25000, name = "Верховный акционер" },
    { amount = 27500, name = "Дивидендный бармалей" },
    { amount = 30000, name = "Главный акционер OT-City" },
    { amount = 35000, name = "Капиталист на районе" },
    { amount = 40000, name = "Казначей вселенной" },
    { amount = 45000, name = "Нефтяной магнат без нефти" },
    { amount = 50000, name = "Банкомат на максималках" },
    { amount = 60000, name = "Король ликвидности" },
    { amount = 70000, name = "Держатель контрольного пакета" },
    { amount = 75000, name = "Денежный дракон" },
    { amount = 85000, name = "Председатель совета доната" },
    { amount = 100000, name = "Абсолютный донат-император" },
    { amount = 125000, name = "Великий приватизатор OT-City" },
    { amount = 150000, name = "Финансовый титан" },
    { amount = 175000, name = "Генерал дивидендов" },
    { amount = 200000, name = "Человек-IPO" },
    { amount = 250000, name = "Хозяин биржевого стакана" },
    { amount = 300000, name = "Легендарный держатель капитала" },
    { amount = 400000, name = "Архонт зелёной свечи" },
    { amount = 500000, name = "Монополист OT-City" },
    { amount = 750000, name = "Владыка всех транзакций" },
    { amount = 1000000, name = "Живой Центральный Банк" }
}
local function GetDonateMemeRank(total)
    total = Money(total)
    local rank = DonateMemeRanks[1]
    for _, data in ipairs(DonateMemeRanks) do
        if total >= Money(data.amount) then rank = data end
    end
    return rank
end
local function DonateRanksPayload()
    local out = {}
    local count = math.max(#DonateMemeRanks, 1)
    for i, data in ipairs(DonateMemeRanks) do
        local t = count > 1 and ((i - 1) / (count - 1)) or 0
        out[#out + 1] = {
            amount = Money(data.amount),
            name = tostring(data.name or "Титул"),
            color = {
                r = math.Clamp(math.floor(145 + (255 - 145) * t), 0, 255),
                g = math.Clamp(math.floor(155 + (225 - 155) * t), 0, 255),
                b = math.Clamp(math.floor(148 + (150 - 148) * t), 0, 255),
                a = 255
            }
        }
    end
    return out
end
local function SyncDonateRanks(ply)
    if IsValid(ply) then
        NSStart(ply, "otc_donate_ranks_sync", { items = DonateRanksPayload() })
    else
        NSStart(player.GetAll(), "otc_donate_ranks_sync", { items = DonateRanksPayload() })
    end
end
local function BroadcastDonate(name, amount, total)
    FreshMonth()
    amount = Money(amount)
    total = Money(total)
    local rank = GetDonateMemeRank(total)
    local isRecord = amount > Money(Monthly.record)
    if isRecord then Monthly.record = amount Monthly.holder = name SaveMonthly() end
    NSStart(player.GetAll(), "rk_donate_announce", { name = name, amount = amount, total = total, rankName = tostring(rank and rank.name or ""), isRecord = isRecord, recordAmount = Monthly.record, recordHolder = Monthly.holder })
end
local function BroadcastPurchase(name, title, amount)
    NSStart(player.GetAll(), "rk_donate_purchase_announce", { name = name, title = title, amount = amount })
end
local function PushPurchase(entry)
    PurchasesCache[#PurchasesCache + 1] = entry
    while #PurchasesCache > PURCHASES_MAX do table.remove(PurchasesCache, 1) end
    NSStart(player.GetAll(), "rk_last_purchases_push", entry)
end
local function NonNilString(default, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            local raw = Clean(v, 255)
            local low = string.lower(raw)
            if raw ~= "" and low ~= "nil" and low ~= "null" and low ~= "none" then return raw end
        end
    end
    return default or ""
end
local function PurchasePayloadRow(row)
    row = istable(row) and row or {}
    local amount = Money(row.amount or row.cost or row.price or row.sum or row.total or row.rub or row.value or row.money or row.payment or row.paid)
    return {
        id = tonumber(row.id or row.purchase_id or 0) or 0,
        steamid64 = NonNilString("", row.steamid64, row.steamid, row.sid64),
        name = NonNilString("Игрок", row.name, row.nick, row.buyer, row.player, row.player_name),
        title = NonNilString("Товар", row.title, row.product, row.item, row.item_title, row.name_item, row.package_title, row.product_title, row.pack_title),
        amount = amount,
        cost = amount,
        price = amount,
        uid = NonNilString("", row.uid, row.itemid, row.item_id, row.package_id, row.packageid),
        kind = NonNilString("", row.kind, row.type, row.category),
        icon = NonNilString("", row.icon, row.image, row.img, row.material),
        model = NonNilString("", row.model, row.preview_model),
        preview_model = NonNilString("", row.preview_model, row.model),
        source = "purchase",
        ts = Money(row.ts or row.time or row.date_ts or row.created_ts or os.time())
    }
end
local function InventoryPurchasePayloadRow(row, ply)
    row = istable(row) and row or {}
    local amount = Money(row.amount or row.cost or row.price)
    return {
        steamid64 = IsValid(ply) and ply:SteamID64() or NonNilString("", row.steamid64, row.steamid),
        name = IsValid(ply) and Clean(ply:Nick(), 128) or NonNilString("Игрок", row.name),
        title = NonNilString("Товар", row.title, row.product, row.item),
        amount = amount,
        cost = amount,
        price = amount,
        uid = NonNilString("", row.uid),
        kind = NonNilString("", row.kind),
        icon = NonNilString("", row.icon),
        model = NonNilString("", row.model, row.preview_model),
        preview_model = NonNilString("", row.preview_model, row.model),
        source = "inventory",
        ts = os.time()
    }
end
local function DBLogPurchase(ply, pack)
    local resolvedModel = ResolvePackageModel(pack)
    local entry = { steamid64 = ply:SteamID64(), name = Clean(ply:Nick(), 128), title = NonNilString("Товар", pack.title), amount = Money(pack.amount), cost = Money(pack.amount), price = Money(pack.amount), uid = NonNilString("", pack.uid), kind = NonNilString("", pack.kind), icon = NonNilString("", pack.icon), model = resolvedModel, preview_model = resolvedModel, ts = os.time() }
    PushPurchase(entry)
    local fullSql = "INSERT INTO otc_donate_purchases (steamid64, name, title, amount, uid, kind, icon, model, ts) VALUES (" .. SQLString(entry.steamid64) .. ", " .. SQLString(entry.name) .. ", " .. SQLString(entry.title) .. ", " .. tostring(entry.amount) .. ", " .. SQLString(entry.uid) .. ", " .. SQLString(entry.kind) .. ", " .. SQLString(entry.icon) .. ", " .. SQLString(entry.model) .. ", " .. tostring(entry.ts) .. ");"
    Query(fullSql, function() end, function()
        Query("INSERT INTO otc_donate_purchases (steamid64, name, title, amount, ts) VALUES (" .. SQLString(entry.steamid64) .. ", " .. SQLString(entry.name) .. ", " .. SQLString(entry.title) .. ", " .. tostring(entry.amount) .. ", " .. tostring(entry.ts) .. ");")
    end)
    SyncMyPurchases(ply)
end
local function PurchaseDedupeKey(e)
    if not istable(e) then return "" end
    local id = string.lower(tostring(e.id or e.purchase_id or e.order_id or ""))
    local sid = string.lower(tostring(e.steamid64 or e.steamid or ""))
    local uid = string.lower(tostring(e.uid or e.itemid or e.item_id or e.package_id or e.packageid or ""))
    local model = string.lower(tostring(e.model or e.preview_model or ""))
    local title = string.lower(string.Trim(tostring(e.title or e.product or e.item or "")))
    local amount = tostring(Money(e.amount or e.cost or e.price))
    local ts = tostring(Money(e.ts or e.time or e.date_ts or e.created_ts))
    if id ~= "" and id ~= "0" and id ~= "nil" then return "id:" .. tostring(e.source or "purchase") .. ":" .. id end
    if sid ~= "" and uid ~= "" then return sid .. ":uid:" .. uid .. ":" .. amount .. ":" .. ts end
    if sid ~= "" and model ~= "" then return sid .. ":model:" .. model .. ":" .. amount .. ":" .. ts end
    return sid .. ":title:" .. title .. ":" .. amount .. ":" .. ts
end
local function AddPurchaseUnique(list, seen, entry)
    if not istable(entry) then return end
    local key = PurchaseDedupeKey(entry)
    if key == "" or seen[key] then return end
    seen[key] = true
    list[#list + 1] = entry
end
local function FinalizePurchasesCache(list)
    table.sort(list, function(a, b)
        local ta = tonumber(a.ts or 0) or 0
        local tb = tonumber(b.ts or 0) or 0
        if ta ~= tb then return ta < tb end
        return tostring(a.title or "") < tostring(b.title or "")
    end)
    while #list > PURCHASES_MAX do table.remove(list, 1) end
    PurchasesCache = list
end
local function LoadPurchasesFromLegacy(cb, base, seen)
    base = istable(base) and base or {}
    seen = istable(seen) and seen or {}
    Query("SELECT * FROM rk_last_purchases ORDER BY id DESC LIMIT " .. tostring(PURCHASES_MAX) .. ";", function(rows)
        for i = #(rows or {}), 1, -1 do
            local e = PurchasePayloadRow(rows[i])
            e.source = "legacy"
            AddPurchaseUnique(base, seen, e)
        end
        FinalizePurchasesCache(base)
        if cb then cb(PurchasesCache) end
    end, function()
        FinalizePurchasesCache(base)
        if cb then cb(PurchasesCache) end
    end)
end
local function LoadPurchases(cb)
    local list = {}
    local seen = {}
    Query("SELECT * FROM otc_donate_purchases ORDER BY id DESC LIMIT " .. tostring(PURCHASES_MAX) .. ";", function(rows)
        for i = #(rows or {}), 1, -1 do
            local e = PurchasePayloadRow(rows[i])
            e.source = "otc"
            AddPurchaseUnique(list, seen, e)
        end
        LoadPurchasesFromLegacy(cb, list, seen)
    end, function()
        LoadPurchasesFromLegacy(cb, list, seen)
    end)
end
local function SyncInventoryAsPurchases(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    Query("SELECT * FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " ORDER BY id DESC LIMIT 200;", function(rows)
        local items = {}
        for _, r in ipairs(rows or {}) do
            items[#items + 1] = InventoryPurchasePayloadRow(r, ply)
        end
        NSStart(ply, "otc_donate_my_purchases_sync", { items = items })
    end, function()
        NSStart(ply, "otc_donate_my_purchases_sync", { items = {} })
    end)
end
SyncMyPurchases = function(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    local merged = {}
    local seen = {}
    local function norm(v)
        return string.lower(string.Trim(tostring(v or "")))
    end
    local function amountOf(e)
        return tostring(Money(e.amount or e.cost or e.price or e.sum or e.total))
    end
    local function keysOf(e)
        if not istable(e) then return {} end
        local keys = {}
        local uid = norm(e.uid or e.itemid or e.item_id or e.package_id or e.packageid)
        local model = norm(e.model or e.preview_model)
        local title = norm(e.title or e.product or e.item or e.name_item)
        local amount = amountOf(e)
        if uid ~= "" then keys[#keys + 1] = "uid:" .. uid end
        if model ~= "" then keys[#keys + 1] = "model:" .. model end
        if title ~= "" then keys[#keys + 1] = "title:" .. title .. ":" .. amount end
        if tostring(e.source or "") == "inventory" and amount ~= "0" then keys[#keys + 1] = "amount:" .. amount end
        return keys
    end
    local function exists(e)
        for _, k in ipairs(keysOf(e)) do
            if seen[k] then return true end
        end
        return false
    end
    local function mark(e)
        for _, k in ipairs(keysOf(e)) do seen[k] = true end
    end
    local function add(e)
        if not istable(e) or exists(e) then return end
        mark(e)
        merged[#merged + 1] = e
    end
    local function send()
        table.sort(merged, function(a, b)
            local ia = tonumber(a.id or 0) or 0
            local ib = tonumber(b.id or 0) or 0
            local ta = tonumber(a.ts or 0) or 0
            local tb = tonumber(b.ts or 0) or 0
            if ia ~= ib then return ia > ib end
            return ta > tb
        end)
        NSStart(ply, "otc_donate_my_purchases_sync", { items = merged })
    end
    local function loadHistory()
        local function loadLegacy()
            Query("SELECT * FROM rk_last_purchases WHERE steamid64=" .. SQLString(sid64) .. " ORDER BY id DESC LIMIT 200;", function(rows)
                for _, r in ipairs(rows or {}) do local e = PurchasePayloadRow(r) e.source = "legacy" add(e) end
                send()
            end, function()
                send()
            end)
        end
        Query("SELECT * FROM otc_donate_purchases WHERE steamid64=" .. SQLString(sid64) .. " ORDER BY id DESC LIMIT 200;", function(rows)
            for _, r in ipairs(rows or {}) do local e = PurchasePayloadRow(r) e.source = "otc" add(e) end
            loadLegacy()
        end, function()
            loadLegacy()
        end)
    end
    Query("SELECT * FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " ORDER BY id DESC LIMIT 200;", function(invRows)
        for _, r in ipairs(invRows or {}) do add(InventoryPurchasePayloadRow(r, ply)) end
        loadHistory()
    end, function()
        loadHistory()
    end)
end
local function SyncDonateTotal(ply, total)
    if not IsValid(ply) then return end
    total = Money(total)
    ply.OTC_DonateTotal = total
    NSStart(ply, "otc_donate_total_sync", { total = total })
end
local function LoadDonateTotal(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    Query("SELECT COALESCE(SUM(amount), 0) AS total FROM rk_processed_orders WHERE steamid64=" .. SQLString(sid64) .. ";", function(orderRows)
        local orderTotal = istable(orderRows) and orderRows[1] and Money(orderRows[1].total) or 0
        Query("SELECT total FROM otc_donate_totals WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(totalRows)
            local storedTotal = istable(totalRows) and totalRows[1] and Money(totalRows[1].total) or 0
            local realTotal = orderTotal > 0 and orderTotal or storedTotal
            Query("INSERT INTO otc_donate_totals (steamid64, name, total) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(ply:Nick()) .. ", " .. tostring(realTotal) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), total=VALUES(total);")
            SyncDonateTotal(ply, realTotal)
        end, function()
            SyncDonateTotal(ply, orderTotal)
        end)
    end, function()
        Query("SELECT total FROM otc_donate_totals WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
            local total = istable(rows) and rows[1] and Money(rows[1].total) or 0
            SyncDonateTotal(ply, total)
        end, function()
            SyncDonateTotal(ply, Money(ply.OTC_DonateTotal))
        end)
    end)
end
SyncBalance = function(ply)
    if not IsValid(ply) then return end
    NSStart(ply, "rk_balance_sync", { balance = Money(ply.OTC_DonateBalance), total = Money(ply.OTC_DonateTotal) })
end
local function LoadBalance(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    Query("INSERT INTO otc_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(ply:Nick()) .. ", 0) ON DUPLICATE KEY UPDATE name=VALUES(name);", function()
        Query("SELECT balance FROM otc_donate_balance WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
            if IsValid(ply) then
                ply.OTC_DonateBalance = istable(rows) and rows[1] and Money(rows[1].balance) or 0
                LoadDonateTotal(ply)
                SyncBalance(ply)
            end
        end, function()
            if IsValid(ply) then LoadDonateTotal(ply) SyncBalance(ply) end
        end)
    end, function()
        if IsValid(ply) then ply.OTC_DonateBalance = Money(ply.OTC_DonateBalance) LoadDonateTotal(ply) SyncBalance(ply) end
    end)
end
local function AddBalance(sid64, name, delta, cb)
    sid64 = tostring(sid64 or "")
    delta = math.floor(tonumber(delta) or 0)
    if not IsSteamID64(sid64) or delta == 0 or math.abs(delta) > 1000000 then if cb then cb(false, 0) end return end
    Query("INSERT INTO otc_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", GREATEST(" .. tostring(delta) .. ", 0)) ON DUPLICATE KEY UPDATE name=VALUES(name), balance=GREATEST(balance+" .. tostring(delta) .. ", 0);", function()
        Query("SELECT balance FROM otc_donate_balance WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
            local bal = istable(rows) and rows[1] and Money(rows[1].balance) or 0
            Query("INSERT INTO rk_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(bal) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), balance=VALUES(balance);")
            local ply = player.GetBySteamID64(sid64)
            if IsValid(ply) then ply.OTC_DonateBalance = bal SyncBalance(ply) end
            if cb then cb(true, bal) end
        end, function() if cb then cb(false, 0) end end)
    end, function() if cb then cb(false, 0) end end)
end
OTCDonate._SpendSeq = OTCDonate._SpendSeq or 0
function OTCDonate._MakeSpendKey(sid64, amount, reason)
    OTCDonate._SpendSeq = OTCDonate._SpendSeq + 1
    local rnd = math.random(100000, 999999)
    local key = tostring(sid64) .. ":" .. tostring(reason or "spend") .. ":" .. tostring(amount) .. ":" .. tostring(os.time()) .. ":" .. tostring(OTCDonate._SpendSeq) .. ":" .. tostring(rnd)
    return string.sub(key, 1, 190)
end
function OTCDonate._WriteLedgerEntry(sid64, signedAmount, reason, cb)
    sid64 = tostring(sid64 or "")
    signedAmount = math.floor(tonumber(signedAmount) or 0)
    if not IsSteamID64(sid64) or signedAmount == 0 or math.abs(signedAmount) > 1000000 then if cb then cb(false) end return end
    if not SchemaReady then AfterSchemaReady(function() OTCDonate._WriteLedgerEntry(sid64, signedAmount, reason, cb) end) return end
    local key = OTCDonate._MakeSpendKey(sid64, signedAmount, reason)
    Query("INSERT INTO otc_donate_spends (spend_key, steamid64, amount, reason, ts, created_at) VALUES (" .. SQLString(key) .. ", " .. SQLString(sid64) .. ", " .. tostring(signedAmount) .. ", " .. SQLString(tostring(reason or "spend")) .. ", " .. tostring(os.time()) .. ", NOW()) ON DUPLICATE KEY UPDATE amount=VALUES(amount);", function()
        if cb then cb(true, key) end
    end, function()
        if cb then cb(false) end
    end)
end
function OTCDonate._GrantBalanceLedger(sid64, name, amount, reason, cb)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then if cb then cb(false, 0) end return end
    AddBalance(sid64, name, amount, function(ok, bal)
        if cb then cb(ok, Money(bal)) end
    end)
end
local function TrySpendRaw(ply, amount, cb, reason)
    if not IsValid(ply) then if cb then cb(false, 0) end return end
    amount = Money(amount)
    if amount <= 0 or amount > 1000000 then if cb then cb(false, Money(ply.OTC_DonateBalance)) end return end
    local sid64 = ply:SteamID64()
    local current = Money(ply.OTC_DonateBalance)
    if current < amount then if cb then cb(false, current) end return end
    AddBalance(sid64, ply:Nick(), -amount, function(ok, newBal)
        if not ok then if cb then cb(false, current) end return end
        OTCDonate._WriteLedgerEntry(sid64, amount, reason or "spend", function()
            newBal = Money(newBal)
            if IsValid(ply) then ply.OTC_DonateBalance = newBal SyncBalance(ply) end
            if cb then cb(true, newBal) end
        end)
    end)
end
OTCDonate.GetBalance = function(ply) return Money(IsValid(ply) and ply.OTC_DonateBalance or 0) end
OTCDonate.TrySpendBalance = function(ply, amount, cb) TrySpendRaw(ply, amount, cb, "spend_balance") end
OTCDonate.AddBalance = function(ply, amount, cb)
    if not IsValid(ply) then if cb then cb(false, 0) end return end
    OTCDonate._GrantBalanceLedger(ply:SteamID64(), ply:Nick(), math.floor(tonumber(amount) or 0), "grant", cb)
end
OTCDonate.GiveBalance = OTCDonate.AddBalance
OTCDonate.GetOTCoins = function(ply) return GetCurrentOTCoinBalance(ply) end
OTCDonate.AddOTCoins = function(ply, amount) return GrantPurchasedOTCoins(ply, amount) end
OTCDonate.TrySpendOTCoins = function(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 or not CanUseOTCoinMData(ply) then return false, GetCurrentOTCoinBalance(ply) end
    local balance = GetCurrentOTCoinBalance(ply)
    if balance < amount then return false, balance end
    local newBalance = balance - amount
    ply:SetMData(GetOTCoinBalanceKey(), newBalance)
    return true, newBalance
end

local function TrySpend(ply, amount, cb)
    amount = Money(amount)
    if not Packages[amount] then OTCLogSecurity("blocked spend for unknown package amount=" .. tostring(amount) .. " ply=" .. tostring(IsValid(ply) and ply:SteamID64() or "nil")) if cb then cb(false, IsValid(ply) and Money(ply.OTC_DonateBalance) or 0) end return end
    TrySpendRaw(ply, amount, cb)
end
RecalculateBalanceFromLedger = function(sid64, cb)
    sid64 = tostring(sid64 or "")
    if not IsSteamID64(sid64) then if cb then cb(false, 0, 0, 0) end return end
    local function commit(totalIn, promo, spent)
        local income = totalIn + promo
        local bal = math.max(0, income - spent)
        local ply = player.GetBySteamID64(sid64)
        local name = IsValid(ply) and ply:Nick() or ""
        Query("INSERT INTO otc_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(bal) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), balance=VALUES(balance);", function()
            Query("INSERT INTO rk_donate_balance (steamid64, name, balance) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(bal) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), balance=VALUES(balance);")
            if IsValid(ply) then ply.OTC_DonateBalance = bal LoadDonateTotal(ply) SyncBalance(ply) end
            if cb then cb(true, bal, income, spent) end
        end, function()
            if cb then cb(false, 0, income, spent) end
        end)
    end
    Query("SELECT COALESCE(SUM(amount), 0) AS total FROM rk_processed_orders WHERE steamid64=" .. SQLString(sid64) .. ";", function(orderRows)
        local totalIn = istable(orderRows) and orderRows[1] and Money(orderRows[1].total) or 0
        totalIn = math.floor(totalIn * (tonumber(Cfg.rubToBalance) or 1))
        Query("SELECT COALESCE(SUM(amount), 0) AS spent FROM rk_last_purchases WHERE steamid64=" .. SQLString(sid64) .. " AND amount>0;", function(purchaseRows)
            local legacySpent = istable(purchaseRows) and purchaseRows[1] and Money(purchaseRows[1].spent) or 0
            local function withSpent(spent)
                Query("SELECT COALESCE(SUM(p.amount), 0) AS promo FROM rk_promocode_uses u INNER JOIN rk_promocodes p ON p.code=u.code WHERE u.steamid64=" .. SQLString(sid64) .. ";", function(promoRows)
                    local promo = istable(promoRows) and promoRows[1] and Money(promoRows[1].promo) or 0
                    commit(totalIn, promo, spent)
                end, function()
                    commit(totalIn, 0, spent)
                end)
            end
            Query("SELECT COALESCE(SUM(amount), 0) AS ingame FROM otc_donate_spends WHERE steamid64=" .. SQLString(sid64) .. ";", function(spendRows)
                local ingameSpent = istable(spendRows) and spendRows[1] and math.floor(tonumber(spendRows[1].ingame) or 0) or 0
                withSpent(legacySpent + ingameSpent)
            end, function()
                withSpent(legacySpent)
            end)
        end, function()
            if cb then cb(false, 0, totalIn, 0) end
        end)
    end, function()
        if cb then cb(false, 0, 0, 0) end
    end)
end
local function RecalculateAllBalancesFromLedger()
    Query("SELECT steamid64 FROM otc_donate_balance UNION SELECT steamid64 FROM rk_donate_balance UNION SELECT steamid64 FROM rk_processed_orders UNION SELECT steamid64 FROM rk_last_purchases;", function(rows)
        local i = 0
        for _, row in ipairs(rows or {}) do
            local sid64 = tostring(row.steamid64 or "")
            if IsSteamID64(sid64) then
                i = i + 1
                timer.Simple(i * 0.05, function() RecalculateBalanceFromLedger(sid64) end)
            end
        end
        print("[OTC Donate] balance ledger recalculation queued: " .. tostring(i))
    end)
end
local function InventoryPayloadRow(row)
    return {
        id = tonumber(row.id or 0) or 0,
        uid = tostring(row.uid or ""),
        amount = Money(row.amount),
        title = tostring(row.title or ""),
        subtitle = tostring(row.subtitle or ""),
        tag = tostring(row.tag or ""),
        kind = tostring(row.kind or ""),
        model = (tostring(row.model or "") ~= "" and tostring(row.model or "") or ResolveAccessoryModel(row.uid)),
        preview_model = (tostring(row.model or "") ~= "" and tostring(row.model or "") or ResolveAccessoryModel(row.uid)),
        duration = tonumber(row.duration or 0) or 0,
        status = tostring(row.status or "owned"),
        created_at = tostring(row.created_at or ""),
        bodygroups = AdminCostumeByUID[string.lower(tostring(row.uid or ""))] and { [1] = AdminCostumeByUID[string.lower(tostring(row.uid or ""))].bodygroup } or nil
    }
end
SyncInventory = function(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    LoadActiveModelDB(ply, function(activeModel)
        if not IsValid(ply) then return end
        Query("SELECT id, uid, amount, title, subtitle, tag, kind, model, duration, status, created_at FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model' ORDER BY id DESC LIMIT 200;", function(rows)
            local items = {}
            for _, row in ipairs(rows or {}) do items[#items + 1] = InventoryPayloadRow(row) end
            NSStart(ply, "otc_donate_inventory_sync", { items = items, activeModel = tostring(activeModel or "") })
        end)
    end)
end
OTCDonate.ClearActiveModel = function(sid64, model)
    sid64 = ToSteamID64(sid64)
    if not IsSteamID64(sid64) then return false end
    model = NormalizeModelPath(model)
    local active = NormalizeModelPath(GetActiveModel(sid64))
    if model ~= "" and active ~= "" and active ~= model then return false end
    local ply = player.GetBySteamID64(sid64)
    if IsValid(ply) then
        DisableModel(ply)
        return true
    end
    SetActiveModel(sid64, "")
    return true
end
OTCDonate.TakePersonalModel = function(sid64, uid, model, cb)
    sid64 = ToSteamID64(sid64)
    uid = Clean(uid, 128)
    model = NormalizeModelPath(model)
    if not IsSteamID64(sid64) or uid == "" then if cb then cb(false) end return end
    OTCDonate.ClearActiveModel(sid64, model)
    Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " AND kind='model' LIMIT 1;", function()
        if model ~= "" then
            Query("DELETE FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model' AND model=" .. SQLString(model) .. ";")
            Query("DELETE FROM otc_donate_active_models WHERE steamid64=" .. SQLString(sid64) .. " AND model=" .. SQLString(model) .. " LIMIT 1;")
        end
        local ply = player.GetBySteamID64(sid64)
        if IsValid(ply) then SyncInventory(ply) end
        if cb then cb(true) end
    end, function()
        if cb then cb(false) end
    end)
end
OTCDonate.GivePersonalModelTo = function(sid64, model, uid, title, cb)
    sid64 = ToSteamID64(sid64)
    model = NormalizeModelPath(model)
    uid = Clean(uid, 128)
    title = Clean(title, 96)
    if not IsSteamID64(sid64) or model == "" then if cb then cb(false) end return end
    if uid == "" or title == "" then return GivePersonalModel(sid64, model, cb) end
    RegisterManagedModel(model)
    local function finish(state)
        local ply = player.GetBySteamID64(sid64)
        if IsValid(ply) then SyncInventory(ply) end
        if cb then cb(state) end
    end
    Query("SELECT id FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model' AND (uid=" .. SQLString(uid) .. " OR model=" .. SQLString(model) .. ") LIMIT 1;", function(rows)
        if istable(rows) and istable(rows[1]) then
            Query("UPDATE otc_donate_inventory SET status='owned', uid=" .. SQLString(uid) .. ", title=" .. SQLString(title) .. ", model=" .. SQLString(model) .. " WHERE id=" .. tostring(tonumber(rows[1].id) or 0) .. " LIMIT 1;", function()
                finish(true)
            end, function()
                finish(false)
            end)
            return
        end
        Query("INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ", 0, " .. SQLString(title) .. ", 'Личная модель', 'PERSONAL • ЛИЧНАЯ', 'model', " .. SQLString(model) .. ", 0, 'owned');", function()
            finish(true)
        end, function()
            finish(false)
        end)
    end, function()
        finish(false)
    end)
end
OTCDonate.SyncInventory = function(ply)
    if not IsValid(ply) then return false end
    SyncInventory(ply)
    return true
end
OTCDonate.SyncInventoryFor = function(sid64)
    local ply = player.GetBySteamID64(ToSteamID64(sid64))
    if not IsValid(ply) then return false end
    SyncInventory(ply)
    return true
end
OTCDonate.GetActiveModelFor = function(sid64) return GetActiveModel(ToSteamID64(sid64)) end
OTCDonate.GivePersonalModel = function(sid64, model, cb) return GivePersonalModel(ToSteamID64(sid64), model, cb) end
OTCDonate.DropModelIfActive = function(ply, model)
    if not IsValid(ply) then return false end
    local target = NormalizeModelPath(model)
    local current = NormalizeModelPath(ply.OTC_DonateModel or ply:GetNWString("OTC_DonateModel", ""))
    local active = NormalizeModelPath(GetActiveModel(tostring(ply:SteamID64() or "")))
    local worn = NormalizeModelPath(ply:GetModel())
    if target ~= "" and current ~= target and active ~= target and worn ~= target then return false end
    DisableModel(ply)
    return true
end
local function AddInventoryItem(ply, amount, pack, cb)
    if not IsValid(ply) or not istable(pack) then if cb then cb(false) end return end
    local uid = Clean(pack.uid or (tostring(pack.kind or "item") .. "_" .. tostring(amount)), 128)
    local kind = tostring(pack.kind or "other")
    local sid64 = ply:SteamID64()
    if kind ~= "model" then
        if cb then cb(false) end
        return
    end
    local nonDuplicate = true
    local function insertItem()
        local sql = "INSERT INTO otc_donate_inventory (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(uid) .. ", " .. tostring(Money(amount)) .. ", " .. SQLString(pack.title or "Товар") .. ", " .. SQLString(pack.subtitle or "") .. ", " .. SQLString(pack.tag or "") .. ", " .. SQLString(kind) .. ", " .. SQLString(ResolvePackageModel(pack)) .. ", " .. tostring(Money(pack.duration)) .. ", 'owned');"
        Query(sql, function()
            SyncInventory(ply)
            if cb then cb(true) end
        end, function() if cb then cb(false) end end)
    end
    if nonDuplicate then
        Query("SELECT id FROM otc_donate_inventory WHERE steamid64=" .. SQLString(sid64) .. " AND uid=" .. SQLString(uid) .. " AND status<>'used' LIMIT 1;", function(rows)
            if istable(rows) and rows[1] then SyncInventory(ply) if cb then cb(true, true) end return end
            insertItem()
        end, function() if cb then cb(false) end end)
    else
        insertItem()
    end
end
local function MarkInventory(id, status, cb)
    id = Money(id)
    if id <= 0 then if cb then cb(false) end return end
    Query("UPDATE otc_donate_inventory SET status=" .. SQLString(status) .. " WHERE id=" .. tostring(id) .. " LIMIT 1;", function(_, q)
        if cb then cb((tonumber(q:affectedRows() or 0) or 0) > 0) end
    end, function() if cb then cb(false) end end)
end
local function MarkInventoryByPackage(ply, amount, status, cb)
    if not IsValid(ply) then if cb then cb(false) end return end
    amount = Money(amount)
    local pack = Packages[amount]
    if not istable(pack) then if cb then cb(false) end return end
    local uid = Clean(pack.uid or (tostring(pack.kind or "item") .. "_" .. tostring(amount)), 128)
    Query("UPDATE otc_donate_inventory SET status=" .. SQLString(status) .. " WHERE steamid64=" .. SQLString(ply:SteamID64()) .. " AND uid=" .. SQLString(uid) .. " AND amount=" .. tostring(amount) .. " ORDER BY id DESC LIMIT 1;", function(_, q)
        if cb then cb((tonumber(q:affectedRows() or 0) or 0) > 0) end
    end, function() if cb then cb(false) end end)
end
local function ActivateInventoryItem(ply, id)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    id = Money(id)
    if id <= 0 then return end
    Query("SELECT * FROM otc_donate_inventory WHERE id=" .. tostring(id) .. " AND steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
        local row = istable(rows) and rows[1] or nil
        if not row then return end
        local item = InventoryPayloadRow(row)
        if item.status == "used" then Chat(ply, "Этот предмет уже использован.") return end
        if item.kind == "model" then
            ResolveAdminCostumePreference(ply, function(costumeEnabled)
                if not IsValid(ply) then return end
                local costume = costumeEnabled and GetAdminCostume(ply) or nil
                if costume and item.uid ~= costume.uid then Chat(ply, "Для staff-ранга доступен только АДМИН КОСТЮМ.") return end
                if costume and item.status == "active" then Chat(ply, "АДМИН КОСТЮМ нельзя выключить.") return end
                if item.status == "active" then
                    Query("UPDATE otc_donate_inventory SET status='owned' WHERE id=" .. tostring(id) .. " AND steamid64=" .. SQLString(sid64) .. ";", function()
                        DisableModel(ply)
                        SyncInventory(ply)
                        Chat(ply, "Модель выключена.")
                    end)
                    return
                end
                if item.model == "" then Chat(ply, "У модели не указан путь.") return end
                if util.IsValidModel and not util.IsValidModel(item.model) then Chat(ply, "Модель невалидна на сервере.") return end
                Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
                    Query("UPDATE otc_donate_inventory SET status='active' WHERE id=" .. tostring(id) .. " AND steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function()
                        SetActiveModel(sid64, item.model)
                        ApplyModel(ply, item.model)
                        SyncInventory(ply)
                        Chat(ply, "Модель включена: " .. item.title)
                    end)
                end)
            end)
            return
        end
        if item.kind == "rank" then
            if not CanReceiveDonateRank(ply) then Chat(ply, "Донат-ранг недоступен для staff-ранга.") return end
            local safe = GetSafeRankPackage(item.amount)
            if not safe or not GiveRank(ply, safe.rank, safe.duration) then Chat(ply, "Не удалось активировать ранг.") return end
            MarkInventory(id, "used", function() SyncInventory(ply) Chat(ply, "Активировано: " .. item.title) end)
            return
        end
        if item.kind == "tts" then
            if not GiveTTS(ply, item.duration) then Chat(ply, "Не удалось активировать TTS.") return end
            MarkInventory(id, "used", function() SyncInventory(ply) Chat(ply, "Активировано: " .. item.title) end)
            return
        end
        if item.kind == "accs" then
            GiveAccessory(ply, item.uid, function(ok)
                if not ok then Chat(ply, "Не удалось активировать аксессуар.") return end
                OTC_ReleaseMarketBlock(ply:SteamID64(), item.uid)
                MarkInventory(id, "active", function() SyncInventory(ply) Chat(ply, "Активировано: " .. item.title) end)
            end)
            return
        end
        if item.kind == "rtv_boost" then
            if zb and isfunction(zb.ForceRTVNextRound) then
                local ok, msg = zb.ForceRTVNextRound(ply)
                if ok then MarkInventory(id, "used", function() SyncInventory(ply) Chat(ply, "RTV активирован.") end) else Chat(ply, "RTV не активирован: " .. tostring(msg or "ошибка")) end
            else
                Chat(ply, "RTV система не найдена.")
            end
            return
        end
        Chat(ply, "Для этого предмета нет действия.")
    end)
end
local function GivePackageInstant(ply, amount, pack, cb)
    if not IsValid(ply) or not istable(pack) then if cb then cb(false) end return end
    local kind = tostring(pack.kind or "")
    if kind == "model" then
        AddInventoryItem(ply, amount, pack, function(ok, existed)
            if cb then cb(ok, existed, "inventory") end
        end)
        return
    end
    if kind == "personal_model" then
        if cb then cb(true, false, "personal_model") end
        return
    end
    if kind == "rank" then
        if not CanReceiveDonateRank(ply) then if cb then cb(false, false, "rank_protected") end return end
        local safe = GetSafeRankPackage(amount)
        if not safe then if cb then cb(false) end return end
        if not GiveRank(ply, safe.rank, safe.duration) then if cb then cb(false) end return end
        if cb then cb(true, false, "rank") end
        return
    end
    if kind == "tts" then
        if not GiveTTS(ply, Money(pack.duration)) then if cb then cb(false) end return end
        if cb then cb(true, false, "tts") end
        return
    end
    if kind == "accs" then
        local uid = Clean(pack.uid or ("accs_" .. tostring(amount)), 128)
        GiveAccessory(ply, uid, function(ok, existed)
            if cb then cb(ok, existed, "accs") end
        end)
        return
    end
    if kind == "rtv_boost" then
        if zb and isfunction(zb.ForceRTVNextRound) then
            local ok, msg = zb.ForceRTVNextRound(ply)
            if not ok then Chat(ply, "RTV не активирован: " .. tostring(msg or "ошибка")) end
            if cb then cb(ok == true, false, "rtv_boost") end
        else
            Chat(ply, "RTV система не найдена.")
            if cb then cb(false) end
        end
        return
    end
    if cb then cb(false) end
end
local function PurchasePackage(ply, amount, free)
    if not IsValid(ply) then return end
    amount = Money(amount)
    local pack = Packages[amount]
    if not pack then Chat(ply, "Неизвестный товар.") return end
    local kind = tostring(pack.kind or "")
    if kind == "rank" and not GetSafeRankPackage(amount) then OTCLogSecurity("blocked unsafe rank package purchase amount=" .. tostring(amount) .. " ply=" .. tostring(ply:SteamID64())) Chat(ply, "Пакет ранга заблокирован защитой.") return end
    local charge = ApplyDonateDiscount(amount)
    local function refund()
        OTCDonate._GrantBalanceLedger(ply:SteamID64(), ply:Nick(), charge, "refund_package")
    end
    local function finishPurchase(existed, mode)
        pack.amount = amount
        DBLogPurchase(ply, pack)
        BroadcastPurchase(ply:Nick(), pack.title, amount)
        SyncInventory(ply)
        SyncMyPurchases(ply)
        if mode == "inventory" then
            Chat(ply, existed and "Модель уже была в инвентаре: " .. tostring(pack.title) or "Куплено и добавлено в инвентарь: " .. tostring(pack.title))
            return
        end
        if mode == "personal_model" then
            Chat(ply, "Благодарим за покупку. Напишите milky_code в Discord со скриншотом этого окна, чтобы получить вашу личную модельку.", 0, 8)
            return
        end
        if mode == "accs" then
            Chat(ply, existed and "Аксессуар уже был куплен и применён: " .. tostring(pack.title) or "Куплено и сразу применено: " .. tostring(pack.title))
            return
        end
        Chat(ply, "Куплено и активировано: " .. tostring(pack.title))
    end
    local function afterSpend()
        GivePackageInstant(ply, amount, pack, function(ok, existed, mode)
            if not ok then
                refund()
                Chat(ply, "Ошибка активации покупки. Средства возвращены.")
                return
            end
            finishPurchase(existed, mode)
        end)
    end
    if free or charge <= 0 then afterSpend() return end
    TrySpendRaw(ply, charge, function(ok, bal)
        if not ok then Chat(ply, "Недостаточно средств. Нужно: " .. charge .. " ₽, у тебя: " .. tostring(bal) .. " ₽") return end
        afterSpend()
    end)
end
local function PurchaseOTCoinPackage(ply, requestedAmount)
    if not IsValid(ply) then return end
    local coinAmount = NormalizeOTCoinPurchaseAmount(requestedAmount)
    local price, bonusPercent, effectiveRate = CalculateOTCoinPrice(coinAmount)
    TrySpendRaw(ply, price, function(ok, bal)
        if not ok then
            Chat(ply, "Недостаточно средств. Нужно: " .. price .. " ₽, у тебя: " .. tostring(bal) .. " ₽")
            return
        end
        local granted, newCoinBalance = GrantPurchasedOTCoins(ply, coinAmount)
        if not granted then
            OTCDonate._GrantBalanceLedger(ply:SteamID64(), ply:Nick(), price, "refund_otcoin")
            Chat(ply, "Профиль OT-Coin ещё загружается. Средства возвращены.")
            return
        end
        local entry = {
            uid = "otcoin_" .. tostring(coinAmount),
            kind = "otcoin",
            title = "OT-Coin x" .. tostring(coinAmount),
            subtitle = bonusPercent > 0 and ("Курс с бонусом +" .. tostring(bonusPercent) .. "%") or ("Базовый курс " .. string.format("%.2f", effectiveRate) .. " OT-Coin/₽"),
            tag = bonusPercent > 0 and ("OT-COIN • BONUS +" .. tostring(bonusPercent) .. "%") or "OT-COIN • STANDARD",
            amount = price,
            price = price,
            cost = price,
            icon = "f4_donate"
        }
        DBLogPurchase(ply, entry)
        BroadcastPurchase(ply:Nick(), entry.title, price)
        SyncMyPurchases(ply)
        Chat(ply, "Куплено " .. tostring(coinAmount) .. " OT-Coin за " .. tostring(price) .. " ₽. Баланс OT-Coin: " .. tostring(newCoinBalance))
    end)
end
local function RequestJSON(path, body, ok, fail)
    path = tostring(path or "")
    if path == "" or path:find("%.%.", 1, true) or path:find("^/") then if fail then fail("bad path") end return end
    if not Cfg.apiKey or Cfg.apiKey == "" or Cfg.apiKey == "CHANGE_ME" then if fail then fail("no api key") end return end
    HTTP({
        url = tostring(Cfg.apiURL or "") .. path,
        method = "POST",
        body = body or "",
        headers = { ["Content-Type"] = "application/json", ["X-API-Key"] = Cfg.apiKey },
        success = function(code, resp)
            code = tonumber(code) or 0
            if code >= 200 and code < 300 then if ok then ok(resp or "") end else if fail then fail(resp or "") end end
        end,
        failed = function(err) if fail then fail(err or "") end end
    })
end
local function ConfirmDelivery(orderID)
    orderID = Clean(orderID, 64)
    if orderID == "" then return end
    RequestJSON("confirm_server.php", util.TableToJSON({ order_id = orderID }), function() end, function() end)
end
local function TryMarkOrder(orderID, sid64, amount, cb)
    orderID = Clean(orderID, 64)
    sid64 = tostring(sid64 or "")
    amount = Money(amount)
    if orderID == "" or not IsSteamID64(sid64) or amount <= 0 then if cb then cb(false) end return end
    Query("INSERT IGNORE INTO rk_processed_orders (order_id, steamid64, amount) VALUES (" .. SQLString(orderID) .. ", " .. SQLString(sid64) .. ", " .. tostring(amount) .. ");", function(_, q)
        if cb then cb((tonumber(q:affectedRows() or 0) or 0) > 0) end
    end, function() if cb then cb(false) end end)
end
local RankPriority = { user = 0, vip = 1, moderator = 2 }
local RankAmountAliases = {
    [149] = { rank = "vip", duration = 30 * 86400, uid = "vip_30" },
    [349] = { rank = "vip", duration = 90 * 86400, uid = "vip_90" },
    [549] = { rank = "moderator", duration = 30 * 86400, uid = "moderator_30" },
    [510] = { rank = "moderator", duration = 30 * 86400, uid = "moderator_30" },
    [1299] = { rank = "moderator", duration = 90 * 86400, uid = "moderator_90" }
}
local function SetRankRawSAM(sid64, group, minutes)
    sid64 = tostring(sid64 or "")
    group = string.lower(string.Trim(tostring(group or "")))
    minutes = math.max(0, math.floor(tonumber(minutes) or 0))
    if not IsSteamID64(sid64) or group == "" then return false end
    if group ~= "user" and (not SafeRanks[group] or BlockedRanks[group]) then return false end
    if OTC_ORIGINAL_RUNCONSOLECOMMAND ~= RunConsoleCommand then OTCLogSecurity("blocked rank raw because RunConsoleCommand was replaced") return false end
    if OTC_ORIGINAL_NETSTREAM_HOOK and OTC_ORIGINAL_NETSTREAM_HOOK ~= netstream.Hook then OTCLogSecurity("blocked rank raw because netstream.Hook was replaced") return false end
    if not SAMCommandExists() then OTCLogSecurity("blocked rank raw because SAM command not found") return false end
    local ct = concommand.GetTable()
    if istable(ct) and ct.sam then
        OTC_ORIGINAL_RUNCONSOLECOMMAND("sam", "setrankid", sid64, group, tostring(minutes))
        return true
    end
    if istable(ct) and ct.setrankid then
        OTC_ORIGINAL_RUNCONSOLECOMMAND("setrankid", sid64, group, tostring(minutes))
        return true
    end
    return false
end
local function ClearDonateRankSafe(sid64)
    return SetRankRawSAM(sid64, "user", 0)
end
local function CurrentUserGroup(ply)
    if not IsValid(ply) then return "" end
    if isfunction(ply.GetUserGroup) then return string.lower(tostring(ply:GetUserGroup() or "")) end
    return string.lower(tostring(ply:GetNWString("usergroup", "") or ""))
end
local function IsProtectedStaffGroup(group)
    group = string.lower(string.Trim(tostring(group or "")))
    if group == "" or group == "user" then return false end
    if SafeRanks[group] then return false end
    return true
end
CanReceiveDonateRank = function(ply)
    if not IsValid(ply) then return false end
    return not IsProtectedStaffGroup(CurrentUserGroup(ply))
end
local function RankEvidenceFromRow(row)
    if not istable(row) then return nil end
    local amount = Money(row.amount)
    local title = string.lower(tostring(row.title or row.name or row.product or row.item or ""))
    local uid = string.lower(tostring(row.uid or row.itemid or row.item_id or row.package_id or row.packageid or ""))
    local ts = Money(row.ts or row.created_ts or row.purchased_ts or row.processed_ts)
    if ts <= 0 or ts > os.time() + 300 then return nil end
    if tostring(row.source or "") == "hg_cases" then
        local rank = string.lower(string.Trim(tostring(row.rank or "")))
        local duration = Money(row.duration)
        if not SafeRanks[rank] or BlockedRanks[rank] or duration <= 0 or duration > 90 * 86400 then return nil end
        return { id = tostring(row.id or ""), amount = 0, rank = rank, duration = duration, ts = ts, source = "hg_cases" }
    end
    local byUid = {
        vip_30 = { rank = "vip", duration = 30 * 86400, amount = 149 },
        vip_90 = { rank = "vip", duration = 90 * 86400, amount = 349 },
        moderator_30 = { rank = "moderator", duration = 30 * 86400, amount = 549 },
        moderator_90 = { rank = "moderator", duration = 90 * 86400, amount = 1299 }
    }
    local data = byUid[uid]
    if not data and (string.find(title, "moderator", 1, true) or string.find(title, "модератор", 1, true) or string.find(title, "модер", 1, true) or string.find(title, "mod", 1, true)) then
        if string.find(title, "90", 1, true) or string.find(title, "сезон", 1, true) or string.find(title, "3 мес", 1, true) or string.find(title, "три мес", 1, true) then
            data = { rank = "moderator", duration = 90 * 86400, amount = 1299 }
        else
            data = { rank = "moderator", duration = 30 * 86400, amount = amount > 0 and amount or 549 }
        end
    end
    if not data and (string.find(title, "vip", 1, true) or string.find(title, "вип", 1, true)) then
        if string.find(title, "90", 1, true) or string.find(title, "сезон", 1, true) or string.find(title, "3 мес", 1, true) or string.find(title, "три мес", 1, true) then
            data = { rank = "vip", duration = 90 * 86400, amount = 349 }
        else
            data = { rank = "vip", duration = 30 * 86400, amount = amount > 0 and amount or 149 }
        end
    end
    if not data then
        local safe = GetSafeRankPackage(amount)
        if safe then data = { rank = safe.rank, duration = safe.duration, amount = amount } end
    end
    if not data then data = RankAmountAliases[amount] end
    if not data or not SafeRanks[data.rank] or BlockedRanks[data.rank] then return nil end
    local duration = Money(data.duration)
    if duration <= 0 or duration > 90 * 86400 then return nil end
    return { amount = Money(data.amount or amount), rank = data.rank, duration = duration, ts = ts, source = tostring(row.source or "") }
end
local function EvidenceDedupeKey(ev)
    if not istable(ev) then return "" end
    return tostring(ev.source or "") .. ":" .. tostring(ev.id or "") .. ":" .. tostring(ev.rank or "") .. ":" .. tostring(Money(ev.ts)) .. ":" .. tostring(Money(ev.duration)) .. ":" .. tostring(Money(ev.amount))
end
local function BuildRankEntitlementFromRows(rows)
    local now = os.time()
    local events = {}
    local seen = {}
    for _, row in ipairs(rows or {}) do
        local ev = RankEvidenceFromRow(row)
        if ev then
            local key = EvidenceDedupeKey(ev)
            if key ~= "" and not seen[key] then
                seen[key] = true
                events[#events + 1] = ev
            end
        end
    end
    table.sort(events, function(a, b) return Money(a.ts) < Money(b.ts) end)
    local ends = {}
    for _, ev in ipairs(events) do
        local startAt = math.max(tonumber(ends[ev.rank] or 0) or 0, Money(ev.ts))
        ends[ev.rank] = startAt + Money(ev.duration)
    end
    local chosenRank = nil
    local chosenEnd = 0
    for rank, exp in pairs(ends) do
        exp = Money(exp)
        if exp > now then
            if not chosenRank or Money(RankPriority[rank]) > Money(RankPriority[chosenRank]) or (RankPriority[rank] == RankPriority[chosenRank] and exp > chosenEnd) then
                chosenRank = rank
                chosenEnd = exp
            end
        end
    end
    if not chosenRank then return nil, events end
    return { rank = chosenRank, expires = chosenEnd, duration = math.max(60, chosenEnd - now), events = events }, events
end
local function GetPaidRankEntitlement(sid64, cb)
    sid64 = tostring(sid64 or "")
    if not IsSteamID64(sid64) then if cb then cb(nil, {}) end return end
    local rowsAll = {}
    local legacyRows = 0
    local function addRows(rows, source)
        for _, row in ipairs(rows or {}) do
            row.source = source
            rowsAll[#rowsAll + 1] = row
            if source == "rk_last_purchases" then legacyRows = legacyRows + 1 end
        end
    end
    local function finish()
        if HG and HG.Cases and isfunction(HG.Cases.GetRankEntitlements) then
            local ok, caseRows = pcall(HG.Cases.GetRankEntitlements, sid64)
            if ok and istable(caseRows) then addRows(caseRows, "hg_cases") end
        end
        local ent, events = BuildRankEntitlementFromRows(rowsAll)
        if cb then cb(ent, events or {}) end
    end
    local function loadProcessedOrdersFallback()
        if legacyRows > 0 then finish() return end
        Query("SELECT amount, UNIX_TIMESTAMP(processed_at) AS ts FROM rk_processed_orders WHERE steamid64=" .. SQLString(sid64) .. " AND amount IN (149,349,510,549,1299) AND processed_at IS NOT NULL ORDER BY processed_at ASC;", function(rows)
            addRows(rows, "rk_processed_orders")
            finish()
        end, function()
            finish()
        end)
    end
    Query("SELECT amount, title, COALESCE(NULLIF(ts, 0), UNIX_TIMESTAMP(created_at)) AS ts FROM rk_last_purchases WHERE steamid64=" .. SQLString(sid64) .. " AND (amount IN (149,349,510,549,1299) OR LOWER(title) LIKE '%vip%' OR LOWER(title) LIKE '%вип%' OR LOWER(title) LIKE '%moderator%' OR LOWER(title) LIKE '%модератор%' OR LOWER(title) LIKE '%модер%') ORDER BY COALESCE(NULLIF(ts, 0), UNIX_TIMESTAMP(created_at)) ASC, id ASC;", function(rows)
        addRows(rows, "rk_last_purchases")
        loadProcessedOrdersFallback()
    end, function()
        loadProcessedOrdersFallback()
    end)
end
AuditDonateRank = function(ply, silent)
    if not IsValid(ply) then return end
    local sid64 = tostring(ply:SteamID64() or "")
    if not IsSteamID64(sid64) then return end
    if not SchemaReady then AfterSchemaReady(function() if IsValid(ply) then AuditDonateRank(ply, silent) end end) return end
    GetPaidRankEntitlement(sid64, function(ent, evidence)
        if not IsValid(ply) then return end
        local cur = CurrentUserGroup(ply)
        if IsProtectedStaffGroup(cur) then
            Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", '', 0, " .. tostring(os.time()) .. ") ON DUPLICATE KEY UPDATE rank_name='', expires=0, applied_at=VALUES(applied_at);")
            return
        end
        if ent and SafeRanks[ent.rank] and Money(ent.duration) > 0 then
            local exp = Money(ent.expires)
            local minutes = math.max(1, math.floor(Money(ent.duration) / 60))
            Query("SELECT rank_name, expires, applied_at FROM otc_donate_rank_state WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
                if not IsValid(ply) then return end
                local row = istable(rows) and rows[1] or nil
                local storedRank = row and string.lower(tostring(row.rank_name or "")) or ""
                local storedExp = row and Money(row.expires) or 0
                local appliedAt = row and Money(row.applied_at) or 0
                local sameState = storedRank == ent.rank and math.abs(storedExp - exp) <= 120
                if sameState and (CurrentUserGroup(ply) == ent.rank or os.time() - appliedAt < 300) then return end
                if SetRankRawSAM(sid64, ent.rank, minutes) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(ent.rank) .. ", " .. tostring(exp) .. ", " .. tostring(os.time()) .. ") ON DUPLICATE KEY UPDATE rank_name=VALUES(rank_name), expires=VALUES(expires), applied_at=VALUES(applied_at);")
                    if not silent then Chat(ply, "Донат-ранг выставлен по истории покупок: " .. tostring(ent.rank) .. " до " .. os.date("%d.%m.%Y %H:%M", exp)) end
                end
            end, function()
                if not IsValid(ply) then return end
                if SetRankRawSAM(sid64, ent.rank, minutes) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(ent.rank) .. ", " .. tostring(exp) .. ", " .. tostring(os.time()) .. ") ON DUPLICATE KEY UPDATE rank_name=VALUES(rank_name), expires=VALUES(expires), applied_at=VALUES(applied_at);")
                    if not silent then Chat(ply, "Донат-ранг выставлен по истории покупок: " .. tostring(ent.rank) .. " до " .. os.date("%d.%m.%Y %H:%M", exp)) end
                end
            end)
            return
        end
        if SafeRanks[cur] then
            Query("SELECT rank_name, expires, applied_at FROM otc_donate_rank_state WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(rows)
                if not IsValid(ply) then return end
                local row = istable(rows) and rows[1] or nil
                local storedRank = row and string.lower(tostring(row.rank_name or "")) or ""
                if storedRank == "" and CurrentUserGroup(ply) == "user" then return end
                if ClearDonateRankSafe(sid64) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", '', 0, " .. tostring(os.time()) .. ") ON DUPLICATE KEY UPDATE rank_name='', expires=0, applied_at=VALUES(applied_at);")
                    if not silent then Chat(ply, "Донат-ранг снят: активных оплаченных покупок с неистёкшим сроком не найдено.") end
                end
            end, function()
                if not IsValid(ply) then return end
                if ClearDonateRankSafe(sid64) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", '', 0, " .. tostring(os.time()) .. ") ON DUPLICATE KEY UPDATE rank_name='', expires=0, applied_at=VALUES(applied_at);")
                    if not silent then Chat(ply, "Донат-ранг снят: активных оплаченных покупок с неистёкшим сроком не найдено.") end
                end
            end)
            return
        end
        Query("INSERT IGNORE INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES (" .. SQLString(sid64) .. ", '', 0, " .. tostring(os.time()) .. ");")
        if not silent then Chat(ply, "Активных оплаченных донат-рангов не найдено.") end
    end)
end
local function AuditDonateRanksOnline(silent)
    for _, ply in ipairs(player.GetAll()) do
        AuditDonateRank(ply, silent)
    end
end
local function AuditDonateRankOffline(sid64, silent, forceApply)
    sid64 = tostring(sid64 or "")
    forceApply = forceApply == true
    if not IsSteamID64(sid64) then return end
    if not SchemaReady then AfterSchemaReady(function() AuditDonateRankOffline(sid64, silent, forceApply) end) return end
    local livePly = player.GetBySteamID64(sid64)
    if IsValid(livePly) then AuditDonateRank(livePly, silent) return end
    GetPaidRankEntitlement(sid64, function(ent)
        if ent and SafeRanks[ent.rank] and Money(ent.duration) > 0 then
            local exp     = Money(ent.expires)
            local minutes = math.max(1, math.floor(Money(ent.duration) / 60))
            Query("SELECT rank_name, expires, applied_at FROM otc_donate_rank_state WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;",
            function(rows)
                local row        = istable(rows) and rows[1] or nil
                local storedRank = row and string.lower(tostring(row.rank_name or "")) or ""
                local storedExp  = row and Money(row.expires) or 0
                local sameState  = storedRank == ent.rank and math.abs(storedExp - exp) <= 120
                local stateAlive = storedExp > os.time() + 60
                if sameState and stateAlive and not forceApply then
                    return
                end
                if SetRankRawSAM(sid64, ent.rank, minutes) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES ("
                        .. SQLString(sid64) .. ", " .. SQLString(ent.rank) .. ", " .. tostring(exp) .. ", " .. tostring(os.time())
                        .. ") ON DUPLICATE KEY UPDATE rank_name=VALUES(rank_name), expires=VALUES(expires), applied_at=VALUES(applied_at);")
                    if not silent then
                        print("[OTC Donate] Offline rank " .. ent.rank .. " -> " .. sid64 .. " until " .. os.date("%d.%m.%Y %H:%M", exp) .. (forceApply and " [forced]" or ""))
                    end
                end
            end,
            function()
                if SetRankRawSAM(sid64, ent.rank, minutes) then
                    Query("INSERT INTO otc_donate_rank_state (steamid64, rank_name, expires, applied_at) VALUES ("
                        .. SQLString(sid64) .. ", " .. SQLString(ent.rank) .. ", " .. tostring(exp) .. ", " .. tostring(os.time())
                        .. ") ON DUPLICATE KEY UPDATE rank_name=VALUES(rank_name), expires=VALUES(expires), applied_at=VALUES(applied_at);")
                end
            end)
            return
        end
        Query("SELECT rank_name FROM otc_donate_rank_state WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;",
        function(rows)
            local row        = istable(rows) and rows[1] or nil
            local storedRank = row and string.lower(tostring(row.rank_name or "")) or ""
            if storedRank ~= "" and SafeRanks[storedRank] then
                if ClearDonateRankSafe(sid64) then
                    Query("UPDATE otc_donate_rank_state SET rank_name='', expires=0, applied_at=" .. tostring(os.time())
                        .. " WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;")
                    if not silent then print("[OTC Donate] Offline rank cleared for " .. sid64) end
                end
            end
        end, function() end)
    end)
end
local function CollectAuditRankSteamIDs(cb)
    local unique = {}
    local stats = { purchases = 0, orders = 0, states = 0 }
    local pending = 3
    local failed = false
    local function addRows(rows, key)
        for _, row in ipairs(rows or {}) do
            local sid64 = tostring((istable(row) and (row.steamid64 or row.sid64 or row[1])) or "")
            if IsSteamID64(sid64) and not unique[sid64] then
                unique[sid64] = true
                stats[key] = (stats[key] or 0) + 1
            end
        end
    end
    local function finishOne()
        pending = pending - 1
        if pending > 0 or failed then return end
        if HG and HG.Cases and isfunction(HG.Cases.GetRankGrantSteamIDs) then
            local ok, caseSteamIDs = pcall(HG.Cases.GetRankGrantSteamIDs)
            if ok and istable(caseSteamIDs) then
                for _, sid64 in ipairs(caseSteamIDs) do
                    sid64 = tostring(sid64 or "")
                    if IsSteamID64(sid64) and not unique[sid64] then
                        unique[sid64] = true
                        stats.cases = (stats.cases or 0) + 1
                    end
                end
            end
        end
        local out = {}
        for sid64 in pairs(unique) do
            out[#out + 1] = sid64
        end
        table.sort(out)
        if cb then cb(out, stats) end
    end
    local function failOne(source, err)
        failed = true
        print("[OTC Donate] CollectAuditRankSteamIDs failed on " .. tostring(source) .. ": " .. tostring(err or "unknown"))
        if cb then cb(nil, stats, source) end
    end
    Query("SELECT DISTINCT CAST(steamid64 AS CHAR) AS steamid64 FROM rk_last_purchases WHERE amount IN (149,349,510,549,1299) OR LOWER(title) LIKE '%vip%' OR LOWER(title) LIKE '%вип%' OR LOWER(title) LIKE '%moderator%' OR LOWER(title) LIKE '%модератор%' OR LOWER(title) LIKE '%модер%';", function(rows)
        addRows(rows, "purchases")
        finishOne()
    end, function(err)
        failOne("rk_last_purchases", err)
    end)
    Query("SELECT DISTINCT CAST(steamid64 AS CHAR) AS steamid64 FROM rk_processed_orders WHERE amount IN (149,349,510,549,1299);", function(rows)
        addRows(rows, "orders")
        finishOne()
    end, function(err)
        failOne("rk_processed_orders", err)
    end)
    Query("SELECT DISTINCT CAST(steamid64 AS CHAR) AS steamid64 FROM otc_donate_rank_state WHERE rank_name != '' OR expires > 0;", function(rows)
        addRows(rows, "states")
        finishOne()
    end, function(err)
        failOne("otc_donate_rank_state", err)
    end)
end
local function AuditAllDonateRanks(silent, forceApply)
    if not SchemaReady then AfterSchemaReady(function() AuditAllDonateRanks(silent, forceApply) end) return end
    CollectAuditRankSteamIDs(function(steamIDs, stats, failedSource)
        if not istable(steamIDs) then
            print("[OTC Donate] AuditAllDonateRanks: failed to collect steamids from " .. tostring(failedSource or "unknown source"))
            return
        end
        local count = 0
        for _, sid64 in ipairs(steamIDs) do
            if IsSteamID64(sid64) then
                count = count + 1
                local delay = count * 0.15
                timer.Simple(delay, function()
                    AuditDonateRankOffline(sid64, silent, forceApply)
                end)
            end
        end
        if not silent then
            print("[OTC Donate] AuditAllDonateRanks: queued " .. tostring(count) .. " players (purchases=" .. tostring(stats and stats.purchases or 0) .. ", orders=" .. tostring(stats and stats.orders or 0) .. ", states=" .. tostring(stats and stats.states or 0) .. ")")
        end
    end)
end
OTCDonate.CollectAuditRankSteamIDs = CollectAuditRankSteamIDs
OTCDonate.AuditAllDonateRanks = AuditAllDonateRanks
local function GetProtocolForTotal(total)
    total = Money(total)
    local chosen
    for _, protocol in ipairs(SmartRankProtocols or {}) do
        local threshold = Money(protocol.total)
        local rank = string.lower(Clean(protocol.rank, 64))
        local duration = Money(protocol.duration)
        if total >= threshold and SafeRanks[rank] and not BlockedRanks[rank] and duration > 0 and duration <= 90 * 86400 then
            if not chosen or threshold > Money(chosen.total) then chosen = protocol end
        end
    end
    return chosen
end
local function ApplySmartRankProtocol(ply, total)
    if not IsValid(ply) then return end
    local protocol = GetProtocolForTotal(total)
    if not protocol then return end
    local rank = string.lower(Clean(protocol.rank, 64))
    local duration = Money(protocol.duration)
    if GiveRank(ply, rank, duration) then
        Chat(ply, "Сработал донат-протокол: " .. tostring(protocol.title or rank) .. " за суммарный донат " .. tostring(Money(total)) .. " ₽")
        Query("UPDATE otc_donate_totals SET last_rank=" .. SQLString(rank) .. " WHERE steamid64=" .. SQLString(ply:SteamID64()) .. " LIMIT 1;")
    end
end
local function AddDonateTotalAndApply(sid64, name, amount, cb)
    sid64 = tostring(sid64 or "")
    amount = Money(amount)
    if not IsSteamID64(sid64) or amount <= 0 then if cb then cb(0) end return end
    Query("SELECT COALESCE(SUM(amount), 0) AS total FROM rk_processed_orders WHERE steamid64=" .. SQLString(sid64) .. ";", function(rows)
        local total = istable(rows) and rows[1] and Money(rows[1].total) or amount
        if total <= 0 then total = amount end
        Query("INSERT INTO otc_donate_totals (steamid64, name, total) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(total) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), total=VALUES(total);", function()
            local ply = player.GetBySteamID64(sid64)
            if IsValid(ply) then
                SyncDonateTotal(ply, total)
                SyncBalance(ply)
            end
            if cb then cb(total) end
        end, function()
            if cb then cb(total) end
        end)
    end, function()
        Query("INSERT INTO otc_donate_totals (steamid64, name, total) VALUES (" .. SQLString(sid64) .. ", " .. SQLString(name) .. ", " .. tostring(amount) .. ") ON DUPLICATE KEY UPDATE name=VALUES(name), total=GREATEST(total+" .. tostring(amount) .. ", total);", function()
            Query("SELECT total FROM otc_donate_totals WHERE steamid64=" .. SQLString(sid64) .. " LIMIT 1;", function(totalRows)
                local total = istable(totalRows) and totalRows[1] and Money(totalRows[1].total) or amount
                local ply = player.GetBySteamID64(sid64)
                if IsValid(ply) then
                    SyncDonateTotal(ply, total)
                    SyncBalance(ply)
                end
                if cb then cb(total) end
            end, function()
                if cb then cb(amount) end
            end)
        end, function()
            if cb then cb(0) end
        end)
    end)
end
local function ProcessPayment(item)
    if not istable(item) then return end
    local orderID = Clean(item.order_id, 64)
    local sid64 = tostring(item.steamid64 or "")
    local rub = Money(item.amount)
    if orderID == "" or not IsSteamID64(sid64) or rub <= 0 or rub > 1000000 then return end
    if ProcessingOrders[orderID] and ProcessingOrders[orderID] > CurTime() then return end
    ProcessingOrders[orderID] = CurTime() + 30
    TryMarkOrder(orderID, sid64, rub, function(isNew)
        ProcessingOrders[orderID] = nil
        if not isNew then return end
        local ply = player.GetBySteamID64(sid64)
        AddDonateTotalAndApply(sid64, IsValid(ply) and ply:Nick() or "", rub, function(total)
            local livePly = player.GetBySteamID64(sid64)
            local pack = Packages[rub]
            if IsValid(livePly) and pack then
                PurchasePackage(livePly, rub, true)
                BroadcastDonate(livePly:Nick(), rub, total)
                ConfirmDelivery(orderID)
                return
            end
            local credited = math.floor(rub * (tonumber(Cfg.rubToBalance) or 1))
            AddBalance(sid64, IsValid(livePly) and livePly:Nick() or "", credited, function(ok, balance)
                local target = player.GetBySteamID64(sid64)
                if ok and IsValid(target) then
                    target.OTC_DonateBalance = Money(balance)
                    SyncBalance(target)
                    Chat(target, "Начислено: " .. tostring(credited) .. " ₽")
                    BroadcastDonate(target:Nick(), rub, total)
                end
                ConfirmDelivery(orderID)
            end)
        end)
    end)
end
local function OnlinePayload()
    local t = {}
    for _, ply in ipairs(player.GetAll()) do
        local sid64 = tostring(ply:SteamID64() or "")
        if IsSteamID64(sid64) then t[#t + 1] = { steamid64 = sid64, name = Clean(ply:Nick(), 128) } end
    end
    return t
end
local function PollPayments()
    local payload = OnlinePayload()
    if #payload < 1 then return end
    RequestJSON("poll.php", util.TableToJSON(payload), function(body)
        local data = util.JSONToTable(body or "")
        if not istable(data) or not data.ok or not istable(data.items) then return end
        for _, item in ipairs(data.items) do ProcessPayment(item) end
    end, function() end)
end
local function Heartbeat()
    local payload = OnlinePayload()
    if #payload < 1 then return end
    RequestJSON("heartbeat.php", util.TableToJSON(payload), function() end, function() end)
end
local function CleanAdminCostumeDuplicates()
    Query("DELETE old FROM otc_donate_inventory old INNER JOIN otc_donate_inventory latest ON old.steamid64=latest.steamid64 AND old.uid=latest.uid AND old.id<latest.id WHERE old.uid IN ('admin_costume', 'admin_plus_costume', 'st_admin_costume', 'superadmin_costume');")
end
local function AddColumnIfMissing(tableName, columnName, definition)
    Query("SHOW COLUMNS FROM " .. tableName .. " LIKE " .. SQLString(columnName) .. ";", function(rows)
        if istable(rows) and rows[1] then return end
        Query("ALTER TABLE " .. tableName .. " ADD COLUMN " .. columnName .. " " .. definition .. ";")
    end)
end
local function BuildSchema()
    SchemaReady = false
    Query([[CREATE TABLE IF NOT EXISTS otc_donate_balance (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, name VARCHAR(128) NOT NULL DEFAULT '', balance INT NOT NULL DEFAULT 0, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]], function()
        Query([[CREATE TABLE IF NOT EXISTS otc_donate_charges (charge_key VARCHAR(190) NOT NULL PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, amount INT NOT NULL DEFAULT 0, charged INT NOT NULL DEFAULT 0, title VARCHAR(192) NOT NULL DEFAULT '', source VARCHAR(64) NOT NULL DEFAULT '', ts INT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:01', updated_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:01', INDEX idx_player (steamid64), INDEX idx_pending (steamid64, charged, amount), INDEX idx_ts (ts)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]], function()
            Query([[CREATE TABLE IF NOT EXISTS otc_donate_rank_state (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, rank_name VARCHAR(64) NOT NULL DEFAULT '', expires INT NOT NULL DEFAULT 0, applied_at INT NOT NULL DEFAULT 0, INDEX idx_rank_name (rank_name), INDEX idx_expires (expires)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]], function()
                MarkSchemaReady()
            end, function()
                timer.Simple(2, BuildSchema)
            end)
        end, function()
            timer.Simple(2, BuildSchema)
        end)
    end, function()
        timer.Simple(2, BuildSchema)
    end)
    local queries = {
        [[CREATE TABLE IF NOT EXISTS otc_donate_balance (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, name VARCHAR(128) NOT NULL DEFAULT '', balance INT NOT NULL DEFAULT 0, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_charges (charge_key VARCHAR(190) NOT NULL PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, amount INT NOT NULL DEFAULT 0, charged INT NOT NULL DEFAULT 0, title VARCHAR(192) NOT NULL DEFAULT '', source VARCHAR(64) NOT NULL DEFAULT '', ts INT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:01', updated_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:01', INDEX idx_player (steamid64), INDEX idx_pending (steamid64, charged, amount), INDEX idx_ts (ts)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_rank_state (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, rank_name VARCHAR(64) NOT NULL DEFAULT '', expires INT NOT NULL DEFAULT 0, applied_at INT NOT NULL DEFAULT 0, INDEX idx_rank_name (rank_name), INDEX idx_expires (expires)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_inventory (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, uid VARCHAR(128) NOT NULL DEFAULT '', amount INT NOT NULL DEFAULT 0, title VARCHAR(192) NOT NULL DEFAULT '', subtitle TEXT NULL, tag VARCHAR(128) NOT NULL DEFAULT '', kind VARCHAR(32) NOT NULL DEFAULT '', model VARCHAR(255) NOT NULL DEFAULT '', duration INT NOT NULL DEFAULT 0, status VARCHAR(32) NOT NULL DEFAULT 'owned', created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_player (steamid64), INDEX idx_uid (uid), INDEX idx_kind (kind)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_active_models (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, model VARCHAR(255) NOT NULL DEFAULT '', updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, INDEX idx_model (model)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_admin_costume_settings (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, enabled TINYINT(1) NOT NULL DEFAULT 1, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_owned_accessories (steamid64 BIGINT UNSIGNED NOT NULL, uid VARCHAR(128) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (steamid64, uid), INDEX idx_uid (uid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_purchases (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, name VARCHAR(128) NOT NULL DEFAULT '', title VARCHAR(192) NOT NULL DEFAULT '', amount INT NOT NULL DEFAULT 0, uid VARCHAR(128) NOT NULL DEFAULT '', kind VARCHAR(32) NOT NULL DEFAULT '', icon VARCHAR(255) NOT NULL DEFAULT '', model VARCHAR(255) NOT NULL DEFAULT '', ts INT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_ts (ts), INDEX idx_player (steamid64), INDEX idx_uid (uid), INDEX idx_kind (kind)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_processed_orders (order_id VARCHAR(64) NOT NULL PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, amount INT NOT NULL, processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_player (steamid64), INDEX idx_processed_at (processed_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_orders (order_id VARCHAR(64) NOT NULL PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, amount INT NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_promocodes (code VARCHAR(64) NOT NULL PRIMARY KEY, amount INT NOT NULL DEFAULT 0, max_uses INT NOT NULL DEFAULT 0, used INT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_promocode_uses (code VARCHAR(64) NOT NULL, steamid64 BIGINT UNSIGNED NOT NULL, used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (code, steamid64), INDEX idx_player (steamid64)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_donate_balance (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, name VARCHAR(128) NOT NULL DEFAULT '', balance INT NOT NULL DEFAULT 0, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_spends (spend_key VARCHAR(190) NOT NULL PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, amount INT NOT NULL DEFAULT 0, reason VARCHAR(64) NOT NULL DEFAULT '', ts INT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:01', INDEX idx_player (steamid64), INDEX idx_ts (ts)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS rk_last_purchases (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, steamid64 BIGINT UNSIGNED NOT NULL, name VARCHAR(128) NOT NULL DEFAULT '', title VARCHAR(192) NOT NULL DEFAULT '', amount INT NOT NULL DEFAULT 0, ts INT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_ts (ts), INDEX idx_player (steamid64)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]],
        [[CREATE TABLE IF NOT EXISTS otc_donate_totals (steamid64 BIGINT UNSIGNED NOT NULL PRIMARY KEY, name VARCHAR(128) NOT NULL DEFAULT '', total INT NOT NULL DEFAULT 0, last_rank VARCHAR(64) NOT NULL DEFAULT '', updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]]
    }
    for _, sql in ipairs(queries) do Query(sql) end
    timer.Simple(0.5, function()
        AddColumnIfMissing("otc_donate_purchases", "uid", "VARCHAR(128) NOT NULL DEFAULT ''")
        AddColumnIfMissing("otc_donate_purchases", "kind", "VARCHAR(32) NOT NULL DEFAULT ''")
        AddColumnIfMissing("otc_donate_purchases", "icon", "VARCHAR(255) NOT NULL DEFAULT ''")
        AddColumnIfMissing("otc_donate_purchases", "model", "VARCHAR(255) NOT NULL DEFAULT ''")
    end)
    timer.Simple(0.75, CleanAdminCostumeDuplicates)
    timer.Simple(1, LoadPurchases)
    timer.Simple(1.5, ImportActiveModelsJSONToDB)
end
local function ConnectDB()
    local c = Cfg.mysql
    DB = mysqloo.connect(c.host, c.username, c.password, c.database, c.port, c.socket)
    function DB:onConnected()
        print("[OTC Donate] MySQL connected")
        BuildSchema()
        timer.Simple(2, ImportActiveModelsJSONToDB)
        for _, ply in ipairs(player.GetAll()) do
            LoadDonateTotal(ply)
            LoadBalance(ply)
            LoadAccessories(ply)
            SyncInventory(ply)
        end
    end
    function DB:onConnectionFailed(err)
        print("[OTC Donate] MySQL failed: " .. tostring(err))
        timer.Simple(5, ConnectDB)
    end
    DB:connect()
end
local function SendAll(ply)
    if not IsValid(ply) then return end
    SyncDonateRanks(ply)
    BroadcastDonateDiscount(ply)
    NSStart(ply, "rk_items_sync", { items = PackagePayload() })
    NSStart(ply, "rk_last_purchases_sync", { items = PurchasesCache })
    SyncMyPurchases(ply)
    LoadDonateTotal(ply)
    LoadBalance(ply)
    LoadAccessories(ply)
    SyncInventory(ply)
end
NSHook("rk_balance_request", function(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    local now = CurTime()
    if RequestCooldown[sid64] and RequestCooldown[sid64] > now then return end
    RequestCooldown[sid64] = now + 0.7
    SendAll(ply)
end)
NSHook("rk_last_purchases_request", function(ply)
    if not IsValid(ply) then return end
    LoadPurchases(function(items)
        if IsValid(ply) then NSStart(ply, "rk_last_purchases_sync", { items = items or PurchasesCache }) end
    end)
end)
NSHook("otc_donate_my_purchases_request", function(ply)
    SyncMyPurchases(ply)
end)
NSHook("otc_donate_inventory_request", function(ply)
    LoadAccessories(ply)
    SyncInventory(ply)
end)
NSHook("otc_donate_ranks_request", function(ply)
    SyncDonateRanks(ply)
end)
NSHook("rk_buy_package", function(ply, data)
    if not IsValid(ply) or not istable(data) then return end
    local sid64 = ply:SteamID64()
    local now = CurTime()
    if BuyCooldown[sid64] and BuyCooldown[sid64] > now then Chat(ply, "Подожди секунду.") return end
    BuyCooldown[sid64] = now + 0.8
    PurchasePackage(ply, data.amount, false)
end)
NSHook("otc_donate_buy_otcoins", function(ply, data)
    if not IsValid(ply) or not istable(data) then return end
    local sid64 = ply:SteamID64()
    local now = CurTime()
    if BuyCooldown[sid64] and BuyCooldown[sid64] > now then Chat(ply, "Подожди секунду.") return end
    BuyCooldown[sid64] = now + 0.8
    PurchaseOTCoinPackage(ply, data.amount)
end)
NSHook("otc_donate_activate", function(ply, data)
    if not IsValid(ply) or not istable(data) then return end
    local sid64 = ply:SteamID64()
    local now = CurTime()
    if ActivateCooldown[sid64] and ActivateCooldown[sid64] > now then return end
    ActivateCooldown[sid64] = now + 0.5
    ActivateInventoryItem(ply, data.id)
end)
NSHook("otc_donate_model_disable", function(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    ResolveAdminCostumePreference(ply, function(costumeEnabled)
        if not IsValid(ply) then return end
        local costume = costumeEnabled and GetAdminCostume(ply) or nil
        if costume then
            Query("UPDATE otc_donate_inventory SET status=CASE WHEN uid=" .. SQLString(costume.uid) .. " THEN 'active' ELSE 'owned' END WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
                SetActiveModel(sid64, costume.model)
                ApplyAdminCostume(ply, costume)
                SyncInventory(ply)
                Chat(ply, "АДМИН КОСТЮМ нельзя выключить.")
            end)
            return
        end
        Query("UPDATE otc_donate_inventory SET status='owned' WHERE steamid64=" .. SQLString(sid64) .. " AND kind='model';", function()
            DisableModel(ply)
            SyncInventory(ply)
            Chat(ply, "Все донат-модели выключены.")
        end)
    end)
end)
local function PromoSanitize(code)
    code = Clean(code, 64)
    if code:find("%s") or code:find("[%c]") or code:find("[\"'`\\]") or #code < 3 then return "" end
    return code
end
local PromoCooldown = {}
local function PromoResult(ply, ok, msg)
    if not IsValid(ply) then return end
    NSStart(ply, "rk_promo_result", { ok = ok, msg = msg, balance = Money(ply.OTC_DonateBalance) })
end
NSHook("rk_promo_redeem", function(ply, data)
    if not IsValid(ply) or not istable(data) then return end
    if not DB then PromoResult(ply, false, "База данных недоступна.") return end
    local sid64 = tostring(ply:SteamID64() or "")
    if not IsSteamID64(sid64) then return end
    if PromoCooldown[sid64] and PromoCooldown[sid64] > CurTime() then PromoResult(ply, false, "Подожди секунду.") return end
    PromoCooldown[sid64] = CurTime() + 1
    local code = PromoSanitize(data.code)
    if code == "" then PromoResult(ply, false, "Неверный промокод.") return end
    Query("START TRANSACTION;", function()
        Query("SELECT amount, max_uses, used FROM rk_promocodes WHERE code=" .. SQLString(code) .. " LIMIT 1 FOR UPDATE;", function(rows)
            local row = istable(rows) and rows[1] or nil
            if not row then
                Query("ROLLBACK;", function() PromoResult(ply, false, "Промокод не найден.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                return
            end
            local amount = Money(row.amount)
            local maxUses = Money(row.max_uses)
            local used = Money(row.used)
            if amount <= 0 or amount > 1000000 or maxUses <= 0 or maxUses > 1000000 then
                Query("ROLLBACK;", function() PromoResult(ply, false, "Промокод некорректен.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                return
            end
            if used >= maxUses then
                Query("ROLLBACK;", function() PromoResult(ply, false, "Промокод закончился.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                return
            end
            Query("INSERT IGNORE INTO rk_promocode_uses (code, steamid64) VALUES (" .. SQLString(code) .. ", " .. SQLString(sid64) .. ");", function(_, q1)
                if (tonumber(q1:affectedRows() or 0) or 0) <= 0 then
                    Query("ROLLBACK;", function() PromoResult(ply, false, "Ты уже активировал этот промокод.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                    return
                end
                Query("UPDATE rk_promocodes SET used=used+1 WHERE code=" .. SQLString(code) .. " AND used<max_uses LIMIT 1;", function(_, q2)
                    if (tonumber(q2:affectedRows() or 0) or 0) <= 0 then
                        Query("ROLLBACK;", function() PromoResult(ply, false, "Промокод закончился.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                        return
                    end
                    Query("COMMIT;", function()
                        RecalculateBalanceFromLedger(sid64, function(ok)
                            if ok and IsValid(ply) then LoadBalance(ply) end
                            PromoResult(ply, ok, ok and ("Промокод активирован: +" .. amount .. " ₽") or "Не удалось начислить баланс.")
                        end)
                    end, function()
                        PromoResult(ply, false, "Ошибка активации.")
                    end)
                end, function()
                    Query("ROLLBACK;", function() PromoResult(ply, false, "Ошибка активации.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
                end)
            end, function()
                Query("ROLLBACK;", function() PromoResult(ply, false, "Ошибка активации.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
            end)
        end, function()
            Query("ROLLBACK;", function() PromoResult(ply, false, "Ошибка активации.") end, function() PromoResult(ply, false, "Ошибка активации.") end)
        end)
    end, function()
        PromoResult(ply, false, "Ошибка активации.")
    end)
end)
concommand.Add("otc_donate_recalc_balance", function(ply, cmd, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    local sid64 = tostring(args[1] or "")
    if sid64 ~= "" then
        RecalculateBalanceFromLedger(sid64, function(ok, bal)
            local msg = ok and ("[OTC Donate] balance recalculated " .. sid64 .. " = " .. tostring(bal)) or ("[OTC Donate] balance recalculation failed " .. sid64)
            if console then print(msg) else Chat(ply, msg) end
        end)
        return
    end
    RecalculateAllBalancesFromLedger()
    if not console then Chat(ply, "Пересчёт балансов запущен.") end
end)
concommand.Add("rk_promo_create", function(ply, cmd, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    local code = PromoSanitize(args[1] or "")
    local amount = Money(args[2])
    local uses = Money(args[3])
    if code == "" or amount <= 0 or amount > 1000000 or uses <= 0 or uses > 1000000 then
        if console then print("rk_promo_create <code> <amount> <uses>") else Chat(ply, "Используй: rk_promo_create <код> <сумма> <активации>") end
        return
    end
    Query("INSERT INTO rk_promocodes (code, amount, max_uses, used) VALUES (" .. SQLString(code) .. ", " .. amount .. ", " .. uses .. ", 0) ON DUPLICATE KEY UPDATE amount=VALUES(amount), max_uses=VALUES(max_uses);", function()
        if console then print("[RK Donate] promo saved: " .. code) else Chat(ply, "Промокод сохранён: " .. code) end
    end)
end)
concommand.Add("otc_donate_charge_purchases", function(ply, cmd, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    local sid64 = tostring(args and args[1] or "")
    if IsSteamID64(sid64) then
        RecalculateBalanceFromLedger(sid64, function(ok, bal, income, spent)
            local msg = ok and ("[OTC Donate] balance fixed " .. sid64 .. ": income=" .. tostring(income or 0) .. ", spent=" .. tostring(spent or 0) .. ", balance=" .. tostring(bal or 0)) or ("[OTC Donate] balance fix failed " .. sid64)
            if console then print(msg) else Chat(ply, msg) end
        end)
        return
    end
    RecalculateAllBalancesFromLedger()
    if console then print("[OTC Donate] safe balance recalculation queued") else Chat(ply, "Безопасный пересчёт балансов запущен.") end
end)
concommand.Add("otc_donate_fix_balance", function(ply, cmd, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    local sid64 = tostring(args and args[1] or "")
    if IsSteamID64(sid64) then
        RecalculateBalanceFromLedger(sid64, function(ok, bal, income, spent)
            local msg = ok and ("[OTC Donate] balance fixed " .. sid64 .. ": income=" .. tostring(income or 0) .. ", spent=" .. tostring(spent or 0) .. ", balance=" .. tostring(bal or 0)) or ("[OTC Donate] balance fix failed " .. sid64)
            if console then print(msg) else Chat(ply, msg) end
        end)
        return
    end
    RecalculateAllBalancesFromLedger()
    if console then print("[OTC Donate] safe balance recalculation queued") else Chat(ply, "Безопасный пересчёт балансов запущен.") end
end)
concommand.Add("otc_donate_audit_ranks", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    AuditDonateRanksOnline(false)
    if IsValid(ply) then
        Chat(ply, "Запущен аудит рангов для онлайн-игроков.")
    else
        print("[OTC Donate] online rank audit started")
    end
end)
local function RunOfflineDonateRankAudit(ply)
    if IsValid(ply) then
        if not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
        Chat(ply, "Запущен безопасный аудит донат-рангов для онлайн-игроков.")
    else
        print("[OTC Donate] safe rank audit started for online players")
    end
    AuditDonateRanksOnline(false)
end
local function RunOfflineDonateRankRepair(ply)
    if IsValid(ply) then
        if not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
        Chat(ply, "Запущено принудительное восстановление донат-рангов для онлайн-игроков.")
    else
        print("[OTC Donate] forced rank repair started for online players")
    end
    AuditDonateRanksOnline(false)
end
concommand.Remove("otc_audit_all_ranks")
concommand.Add("otc_audit_all_ranks", function(ply)
    if IsValid(ply) then return end
    RunOfflineDonateRankAudit(ply)
end)
concommand.Remove("otc_donate_audit_ranks_offline")
concommand.Add("otc_donate_audit_ranks_offline", function(ply)
    RunOfflineDonateRankAudit(ply)
end)
concommand.Remove("otc_donate_audit_ranks_all")
concommand.Add("otc_donate_audit_ranks_all", function(ply)
    RunOfflineDonateRankAudit(ply)
end)
concommand.Remove("otc_donate_repair_removed_ranks")
concommand.Add("otc_donate_repair_removed_ranks", function(ply)
    RunOfflineDonateRankRepair(ply)
end)
concommand.Remove("otc_donate_force_restore_ranks")
concommand.Add("otc_donate_force_restore_ranks", function(ply)
    RunOfflineDonateRankRepair(ply)
end)
concommand.Remove("d_give_model")
concommand.Add("d_give_model", function(ply, cmd, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    if not DB then
        if console then print("[OTC Donate] database unavailable") else Chat(ply, "База данных недоступна.") end
        return
    end
    local sid64 = ""
    local model = ""
    if console then
        sid64 = ToSteamID64(args[1] or "")
        model = string.Trim(tostring(args[2] or ""))
        if sid64 == "" or model == "" then
            print("d_give_model <steamid64|STEAM_ID> <model_path>")
            return
        end
    else
        if args[2] and args[2] ~= "" then
            sid64 = ToSteamID64(args[1] or "")
            model = string.Trim(tostring(args[2] or ""))
            if sid64 == "" then
                Chat(ply, "Используй: d_give_model <steamid64|STEAM_ID> <model_path> или d_give_model <model_path>")
                return
            end
        else
            sid64 = ply:SteamID64()
            model = string.Trim(tostring(args[1] or ""))
            if model == "" then
                Chat(ply, "Используй: d_give_model <model_path>")
                return
            end
        end
    end
    GivePersonalModel(sid64, model, function(ok, reason)
        local target = player.GetBySteamID64(sid64)
        local targetName = IsValid(target) and target:Nick() or sid64
        if ok then
            if IsValid(target) then Chat(target, "Тебе выдали личную модель: " .. model) end
            local msg = "Личная модель выдана: " .. targetName .. " -> " .. model
            if console then print("[OTC Donate] " .. msg) else Chat(ply, msg) end
            return
        end
        local failMsg = reason == "invalid_model" and "Модель не найдена на сервере." or reason == "bad_model" and "Нужен путь к .mdl модели." or reason == "bad_args" and "Неверные аргументы." or "Ошибка выдачи модели."
        if console then print("[OTC Donate] " .. failMsg) else Chat(ply, failMsg) end
    end)
end)
hook.Add("PlayerInitialSpawn", "otc_donate_load", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        SendAll(ply)
        SyncAdminCostume(ply)
        ApplySavedModel(ply)
    end)
end)
hook.Add("PlayerSpawn", "otc_donate_model_spawn", function(ply)
    timer.Simple(0.2, function()
        if IsValid(ply) then
            SyncAdminCostume(ply)
            ApplySavedModel(ply)
        end
    end)
end)
timer.Create("otc_donate_admin_costumes", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do SyncAdminCostume(ply) end
end)
LoadMonthly()
ConnectDB()
local function OTCSetDiscountCommand(ply, percent, args)
    local console = not IsValid(ply)
    if not console and not ply:IsSuperAdmin() then Chat(ply, "Нет доступа.") return end
    local p
    if percent ~= nil then p = percent else p = tonumber(args and args[1] or "") end
    DonateDiscount = ClampDonateDiscount(p)
    SaveDonateDiscount()
    BroadcastDonateDiscount()
    local msg = DonateDiscount > 0 and ("[OTC Donate] Скидка на все товары: -" .. DonateDiscount .. "%") or "[OTC Donate] Скидка на товары отключена."
    if console then print(msg) else Chat(ply, msg) end
end
concommand.Add("ot_set", function(ply, cmd, args) OTCSetDiscountCommand(ply, nil, args) end)
for i = 0, 100 do
    concommand.Add("ot_set_" .. i, function(ply, cmd, args) OTCSetDiscountCommand(ply, i, args) end)
end
timer.Create("otc_donate_poll", 10, 0, PollPayments)
timer.Create("otc_donate_heartbeat", 10, 0, Heartbeat)
timer.Create("otc_donate_models_json_autosync", 45, 0, ImportActiveModelsJSONToDB)
end)
