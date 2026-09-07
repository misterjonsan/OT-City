if not SERVER then return end

hg = hg or {}
hg.Market = hg.Market or {}
hg.MarketConfig = hg.MarketConfig or {}

local MK = hg.Market
local CFG = hg.MarketConfig

pcall(require, "mysqloo")

local T_LIST = "hg_market_listings"
local T_OWNED = "hg_market_owned"
local T_ESCROW = "hg_market_escrow"
local T_PAYOUT = "hg_market_payouts"
local T_STATS = "hg_market_stats"
local T_META = "hg_market_meta"
local T_LOG = "hg_market_log"
local T_INV = "otc_donate_inventory"
local T_ACTIVE = "otc_donate_active_models"
local T_GRANT = "hg_market_grants"
local T_ACCS = "rk_owned_accessories"
local T_REVOKED = "hg_market_revoked"

MK.Owned = MK.Owned or {}
MK.Escrow = MK.Escrow or {}
MK.Revoked = MK.Revoked or {}
MK.Stats = MK.Stats or {}
MK.Listings = MK.Listings or {}
MK.History = MK.History or {}
MK.Viewers = MK.Viewers or {}
MK.Cooldowns = MK.Cooldowns or {}
MK.SellCache = MK.SellCache or {}
MK.NextPush = MK.NextPush or {}
MK.Signature = MK.Signature or {}
MK.Base = MK.Base or {}
MK.Loaded = MK.Loaded or {}
MK.Revision = MK.Revision or -1
MK.Models = MK.Models or {}
MK.ModelStamp = MK.ModelStamp or {}
MK.ModelPull = MK.ModelPull or {}

local DB
local Ready = false
local Queue = {}
local Refreshing = false
local RefreshQueued = false
local LastRefresh = 0
local LastStats = 0
local LastPlayers = 0
local TradableCache
local Depth = 0
local ModelReady = false

MK.Panel = MK.Panel or {
    enabled = true,
    url = "",
    token = "",
    serverId = "",
    serverName = "",
    snapshotEvery = 120,
    backlog = 400,
    fallbackUrl = "https://panel-monteract.ru/api.php",
    fallbackToken = "MILKY22938918391839",
    debug = true
}

local function N(value)
    return math.floor(tonumber(value) or 0)
end

local function ServerID()
    return string.sub(tostring(game.GetIPAddress() or "unknown"), 1, 48)
end

local function Esc(value)
    if DB then return DB:escape(tostring(value or "")) end

    return string.gsub(tostring(value or ""), "['\"\\;]", "")
end

local function S(value)
    return "'" .. Esc(value) .. "'"
end

local function Log(text)
    print("[HG Market] " .. tostring(text or ""))
end

local function Raw(sql, ok, fail)
    if not DB then
        if fail then fail("no database") end
        return
    end

    local query = DB:query(sql)

    if not query then
        if fail then fail("query failed") end
        return
    end

    function query:onSuccess(data)
        if ok then ok(istable(data) and data or {}, query) end
    end

    function query:onError(err)
        local text = string.lower(tostring(err or ""))

        if not string.find(text, "duplicate column", 1, true) and not string.find(text, "duplicate key name", 1, true) then
            Log("SQL: " .. tostring(err) .. " | " .. string.sub(tostring(sql), 1, 180))
        end

        if fail then fail(err) end
    end

    query:start()
end

local function Query(sql, ok, fail)
    if not Ready then
        Queue[#Queue + 1] = {sql = sql, ok = ok, fail = fail}
        if #Queue > 300 then table.remove(Queue, 1) end
        return
    end

    Raw(sql, ok, fail)
end

local function RunSequence(list, done, index)
    index = index or 1

    if index > #list then
        if done then done() end
        return
    end

    Raw(list[index], function()
        RunSequence(list, done, index + 1)
    end, function()
        RunSequence(list, done, index + 1)
    end)
end

local function Flush()
    local pending = Queue
    Queue = {}

    for _, item in ipairs(pending) do
        Raw(item.sql, item.ok, item.fail)
    end
end

local function SteamOf(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "" end
    if ply:IsBot() then return "BOT_" .. ply:EntIndex() end

    local sid = tostring(ply:SteamID64() or "")
    if sid == "" or sid == "NULL" then return "" end

    return sid
end

local function PlayerBySteam(sid)
    sid = tostring(sid or "")
    if sid == "" then return nil end

    for _, ply in ipairs(player.GetAll()) do
        if SteamOf(ply) == sid then return ply end
    end

    return nil
end

local function Notify(ply, text, isError)
    if not IsValid(ply) then return end

    MK.Send(ply, "Notice", {t = tostring(text or ""), b = isError == true})
end

local function Cooldown(ply, key, delay)
    local sid = SteamOf(ply)
    if sid == "" then return false end

    MK.Cooldowns[sid] = MK.Cooldowns[sid] or {}

    local now = CurTime()

    if (MK.Cooldowns[sid][key] or 0) > now then return false end

    MK.Cooldowns[sid][key] = now + (tonumber(delay) or 1)

    return true
end

local function AP()
    return istable(hg.Appearance) and hg.Appearance or nil
end

local function DonateAPI()
    return istable(OTCDonate) and OTCDonate or nil
end

local function RefreshAppearance(ply)
    if not IsValid(ply) then return end

    local ap = AP()
    if not ap or not isfunction(ap.ApplyAppearanceAccessoriesOnly) then return end

    pcall(ap.ApplyAppearanceAccessoriesOnly, ply)
end

local function GetCoins(ply)
    if not IsValid(ply) then return 0 end

    if istable(OTCDonate) and isfunction(OTCDonate.GetOTCoins) then
        local ok, value = pcall(OTCDonate.GetOTCoins, ply)
        if ok and isnumber(value) then return math.max(0, math.floor(value)) end
    end

    local ap = AP()

    if ap and isfunction(ap.GetOTCoinBalance) then
        local ok, value = pcall(ap.GetOTCoinBalance, ply)
        if ok and isnumber(value) then return math.max(0, math.floor(value)) end
    end

    return 0
end

local function TakeCoins(ply, amount)
    amount = N(amount)
    if amount <= 0 then return true end
    if not IsValid(ply) then return false end

    if istable(OTCDonate) and isfunction(OTCDonate.TrySpendOTCoins) then
        local ok, result = pcall(OTCDonate.TrySpendOTCoins, ply, amount, "Рынок")
        if ok and result == true then return true end
        if ok and result == false then return false end
    end

    if GetCoins(ply) < amount then return false end

    local ap = AP()

    if ap and isfunction(ap.AddOTCoins) then
        local ok = pcall(ap.AddOTCoins, ply, -amount, "market_purchase", true)
        if ok then return true end
    end

    return false
end

local function GiveCoins(ply, amount, reason)
    amount = N(amount)
    if amount <= 0 or not IsValid(ply) then return false end

    if istable(OTCDonate) and isfunction(OTCDonate.AddOTCoins) then
        local ok = pcall(OTCDonate.AddOTCoins, ply, amount, tostring(reason or "market"))
        if ok then return true end
    end

    local ap = AP()

    if ap and isfunction(ap.AddOTCoins) then
        local ok = pcall(ap.AddOTCoins, ply, amount, tostring(reason or "market"), true)
        if ok then return true end
    end

    return false
end

local function BaseHasCoin(ply, uid)
    if Depth > 3 then return false end

    Depth = Depth + 1

    local result = false

    if isfunction(MK.Base.coin) then
        local ok, value = pcall(MK.Base.coin, ply, uid)
        if ok then result = value == true end
    else
        local ap = AP()

        if ap and isfunction(ap.PlayerOwnsCoinAccessory) then
            local ok, value = pcall(ap.PlayerOwnsCoinAccessory, ply, uid)
            if ok then result = value == true end
        end
    end

    Depth = Depth - 1

    return result
end

local function BaseHasDonate(ply, uid)
    if Depth > 3 then return false end

    Depth = Depth + 1

    local result = false

    if isfunction(MK.Base.donate) then
        local ok, value = pcall(MK.Base.donate, ply, uid)
        if ok then result = value == true end
    elseif istable(OTCDonate) and isfunction(OTCDonate.HasAccessory) then
        local ok, value = pcall(OTCDonate.HasAccessory, ply, uid)
        if ok then result = value == true end
    end

    Depth = Depth - 1

    return result
end

local function MarketSource(sid, uid)
    local owned = MK.Owned[sid]
    if not istable(owned) then return nil end

    return owned[uid]
end

local function Escrowed(sid, uid)
    local held = MK.Escrow[sid]
    if not istable(held) then return false end

    return held[uid] ~= nil
end

local function RevokedSource(sid, uid)
    local held = MK.Revoked[sid]
    if not istable(held) then return nil end

    return held[uid]
end

local function SyncBase()
    if isfunction(MK.WrappedCoin) and _G.RK_HasCoinAccessory == MK.WrappedCoin and isfunction(MK.Base.coin) then
        _G.RK_HasCoinAccessory = MK.Base.coin
    end

    if isfunction(MK.WrappedDonate) and _G.RK_HasDonateAccessory == MK.WrappedDonate and isfunction(MK.Base.donate) then
        _G.RK_HasDonateAccessory = MK.Base.donate
    end

    MK.WrappedCoin = nil
    MK.WrappedDonate = nil

    if isfunction(_G.RK_HasCoinAccessory) then MK.Base.coin = _G.RK_HasCoinAccessory end
    if isfunction(_G.RK_HasDonateAccessory) then MK.Base.donate = _G.RK_HasDonateAccessory end
    if isfunction(_G.RK_GiveCoinAccessory) then MK.Base.give = _G.RK_GiveCoinAccessory end
end

local function ShopUIDs(uid)
    uid = tostring(uid or "")

    local out = {}
    local seen = {}

    local function add(value)
        value = tostring(value or "")
        if value == "" or value == "none" or seen[value] then return end

        seen[value] = true
        out[#out + 1] = value
    end

    local acc = MK.GetAccessory(uid)

    if istable(acc) and acc.donateOnly == true then
        add(acc.DonateID)
        add(acc.ID)
        add(uid)
    else
        add(uid)

        if istable(acc) then
            add(acc.DonateID)
            add(acc.ID)
        end
    end

    return out
end

local function ShopUID(uid)
    local list = ShopUIDs(uid)

    return list[1] or tostring(uid or "")
end

local function HasDonateAny(ply, uid)
    for _, shop in ipairs(ShopUIDs(uid)) do
        if BaseHasDonate(ply, shop) then return true end
    end

    return false
end

local function DonateAccs(sid)
    _G.RK_DonateAccessories = _G.RK_DonateAccessories or {}
    _G.RK_DonateAccessories[sid] = _G.RK_DonateAccessories[sid] or {}
    _G.OTC_DonateAccessories = _G.OTC_DonateAccessories or _G.RK_DonateAccessories
    _G.OTC_DonateAccessories[sid] = _G.RK_DonateAccessories[sid]

    return _G.RK_DonateAccessories[sid]
end

local function CoinKey()
    local ap = AP()

    if ap and istable(ap.OTCoin) and isstring(ap.OTCoin.OwnedAccessoriesKey) then
        return ap.OTCoin.OwnedAccessoriesKey
    end

    return "hg_otcoins_owned_accessories"
end

local function CoinOwned(ply)
    if not IsValid(ply) or not isfunction(ply.GetMData) or not isfunction(ply.SetMData) then return nil end

    local decoded = util.JSONToTable(tostring(ply:GetMData(CoinKey(), "{}") or "{}"))
    if not istable(decoded) then return {} end

    local out = {}

    for uid, has in pairs(decoded) do
        if has == true then out[tostring(uid)] = true end
    end

    return out
end

local function DonateItem(uid)
    local acc = MK.GetAccessory(uid)

    return istable(acc) and acc.donateOnly == true
end

local function GrantDonate(ply, sid, uid)
    local list = ShopUIDs(uid)
    local shop = list[1] or ""

    if sid == "" or shop == "" then return false end

    local api = DonateAPI()
    local accs = DonateAccs(sid)

    for _, alias in ipairs(list) do
        accs[alias] = true
    end

    Query("INSERT IGNORE INTO " .. T_ACCS .. " (steamid64, uid) VALUES (" .. S(sid) .. ", " .. S(shop) .. ");")
    Query("DELETE FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND kind = 'accs' AND uid = " .. S(shop) .. ";")

    MK.Revoked[sid] = MK.Revoked[sid] or {}

    for _, alias in ipairs(list) do
        Query("DELETE FROM " .. T_REVOKED .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(alias) .. " LIMIT 1;")

        MK.Revoked[sid][alias] = nil
    end

    MK.Signature[sid] = nil
    MK.SellCache[sid] = nil

    if IsValid(ply) then
        if api and isfunction(api.GiveAccessory) then
            pcall(api.GiveAccessory, ply, shop)
        end

        if api and isfunction(api.RefreshAccessories) then
            pcall(api.RefreshAccessories, ply)
        end

        RefreshAppearance(ply)
    elseif api and isfunction(api.GiveAccessoryOffline) then
        pcall(api.GiveAccessoryOffline, sid, shop)
    end

    return true
end

local function RevokeDonate(ply, sid, uid)
    local list = ShopUIDs(uid)
    if sid == "" or #list == 0 then return false end

    local api = DonateAPI()
    local accs = DonateAccs(sid)

    for _, alias in ipairs(list) do
        Query("DELETE FROM " .. T_ACCS .. " WHERE steamid64 = " .. S(sid) .. " AND uid = " .. S(alias) .. " LIMIT 1;")
        Query("DELETE FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND kind = 'accs' AND uid = " .. S(alias) .. ";")

        accs[alias] = nil

        if IsValid(ply) and api and isfunction(api.TakeAccessory) then
            pcall(api.TakeAccessory, ply, alias)
        elseif api and isfunction(api.TakeAccessoryOffline) then
            pcall(api.TakeAccessoryOffline, sid, alias)
        end
    end

    MK.SellCache[sid] = nil

    if IsValid(ply) then
        if api and isfunction(api.RefreshAccessories) then
            pcall(api.RefreshAccessories, ply)
        end

        RefreshAppearance(ply)

        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            if not Escrowed(sid, uid) then return end

            local held = DonateAccs(sid)

            for _, alias in ipairs(list) do
                held[alias] = nil
            end

            RefreshAppearance(ply)
        end)
    end

    return true
end

local function GrantCoin(ply, uid)
    if not IsValid(ply) then return false end

    uid = tostring(uid or "")
    if uid == "" then return false end

    if isfunction(MK.Base.give) then
        local ok = pcall(MK.Base.give, ply, uid)

        if ok then
            MK.SellCache[SteamOf(ply)] = nil
            RefreshAppearance(ply)
            return true
        end
    end

    local owned = CoinOwned(ply)
    if not istable(owned) then return false end

    owned[uid] = true
    ply:SetMData(CoinKey(), util.TableToJSON(owned))
    MK.SellCache[SteamOf(ply)] = nil
    RefreshAppearance(ply)

    return true
end

local function RevokeCoin(ply, uid)
    if not IsValid(ply) then return false end

    uid = tostring(uid or "")
    if uid == "" then return false end

    local owned = CoinOwned(ply)
    if not istable(owned) then return false end

    owned[uid] = nil
    ply:SetMData(CoinKey(), util.TableToJSON(owned))
    MK.SellCache[SteamOf(ply)] = nil
    RefreshAppearance(ply)

    return true
end

local function MarkRevoked(sid, uid, source)
    sid = tostring(sid or "")
    uid = tostring(uid or "")

    if sid == "" or uid == "" then return end

    source = tostring(source or "donate")

    MK.Revoked[sid] = MK.Revoked[sid] or {}
    MK.Revoked[sid][uid] = source
    MK.SellCache[sid] = nil
    MK.Signature[sid] = nil

    Query("INSERT INTO " .. T_REVOKED .. " (steamid, uid, source, created) VALUES (" .. S(sid) .. ", " .. S(uid) .. ", " .. S(source) .. ", " .. os.time() ..
        ") ON DUPLICATE KEY UPDATE source = VALUES(source), created = VALUES(created);")
end

local function ClearRevoked(sid, uid)
    sid = tostring(sid or "")
    uid = tostring(uid or "")

    if sid == "" or uid == "" then return end

    if istable(MK.Revoked[sid]) then MK.Revoked[sid][uid] = nil end

    MK.SellCache[sid] = nil
    MK.Signature[sid] = nil

    Query("DELETE FROM " .. T_REVOKED .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " LIMIT 1;")
end

function MK.ReleaseBlock(sid, uid)
    sid = tostring(sid or "")
    uid = tostring(uid or "")

    if sid == "" or uid == "" then return false end
    if Escrowed(sid, uid) then return false end

    ClearRevoked(sid, uid)

    for _, alias in ipairs(ShopUIDs(uid)) do
        ClearRevoked(sid, alias)
    end

    local ply = PlayerBySteam(sid)

    if IsValid(ply) then RefreshAppearance(ply) end

    return true
end

_G.HG_Market_ClearRevoked = function(sid, uid)
    return MK.ReleaseBlock(sid, uid)
end

local function ApplyOwnership(ply, sid, uid, source, action)
    if source == "model" then return true end

    if DonateItem(uid) then source = "donate" end

    if action == "grant" then
        ClearRevoked(sid, uid)

        if source == "donate" then return GrantDonate(ply, sid, uid) end

        return GrantCoin(ply, uid)
    end

    MarkRevoked(sid, uid, source)

    Query("DELETE FROM " .. T_OWNED .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " LIMIT 1;")

    if istable(MK.Owned[sid]) then MK.Owned[sid][uid] = nil end

    local stripped = RevokeDonate(ply, sid, uid)

    if IsValid(ply) then
        RevokeCoin(ply, uid)

        return true
    end

    if source == "donate" then return stripped end

    return false
end

local function QueueOwnership(sid, uid, source, action)
    Query("INSERT INTO " .. T_GRANT .. " (steamid, uid, source, action, created) VALUES (" ..
        S(sid) .. ", " .. S(uid) .. ", " .. S(source) .. ", " .. S(action) .. ", " .. os.time() .. ");")
end

local function TransferOwnership(sid, uid, source, action)
    sid = tostring(sid or "")
    uid = tostring(uid or "")
    source = tostring(source or "coin")

    if sid == "" or uid == "" or source == "model" then return end

    local ply = PlayerBySteam(sid)

    if source == "donate" then
        ApplyOwnership(ply, sid, uid, source, action)
        QueueOwnership(sid, uid, source, action)
        return
    end

    if IsValid(ply) and ApplyOwnership(ply, sid, uid, source, action) then return end

    QueueOwnership(sid, uid, source, action)
end

local function ClaimGrants()
    if not Ready then return end

    local list = {}

    for _, ply in ipairs(player.GetAll()) do
        local sid = SteamOf(ply)
        if sid ~= "" then list[#list + 1] = S(sid) end
    end

    if #list == 0 then return end

    Query("SELECT id, steamid, uid, source, action FROM " .. T_GRANT .. " WHERE steamid IN (" .. table.concat(list, ", ") .. ") ORDER BY id ASC LIMIT 40;", function(rows)
        for _, row in ipairs(rows) do
            local id = N(row.id)
            local sid = tostring(row.steamid or "")
            local uid = tostring(row.uid or "")
            local source = tostring(row.source or "coin")
            local action = tostring(row.action or "grant")

            if id > 0 and sid ~= "" and uid ~= "" then
                Query("DELETE FROM " .. T_GRANT .. " WHERE id = " .. id .. " LIMIT 1;", function(_, query)
                    if query:affectedRows() ~= 1 then return end

                    local ply = PlayerBySteam(sid)

                    if not ApplyOwnership(ply, sid, uid, source, action) then
                        QueueOwnership(sid, uid, source, action)
                    end
                end)
            end
        end
    end)
end

local BlacklistWords = {"админ", "admin", "staff", "стафф", "модер", "moder", "куратор", "owner", "helper", "хелпер", "следователь", "гл.адм"}

local function Blacklisted(uid, acc)
    uid = string.lower(tostring(uid or ""))
    if uid == "" or uid == "none" then return true end

    if istable(CFG.Blacklist) then
        for key, value in pairs(CFG.Blacklist) do
            if value == true and string.lower(tostring(key)) == uid then return true end
            if isstring(value) and string.lower(value) == uid then return true end
        end
    end

    if not istable(acc) then return true end
    if acc.disallowinappearance == true then return true end

    local name = string.lower(tostring(acc.name or ""))
    local shop = string.lower(tostring(acc.DonateID or ""))

    for _, word in ipairs(BlacklistWords) do
        if string.find(uid, word, 1, true) then return true end
        if string.find(shop, word, 1, true) then return true end
        if name ~= "" and string.find(name, word, 1, true) then return true end
    end

    return false
end

local ModelUidWords = {"admin", "админ", "costume", "костюм", "staff", "стафф", "moder", "модер", "curator", "куратор", "owner", "helper", "хелпер", "vip_", "operator", "sponsor"}
local ModelTitleWords = {"админ костюм", "админ-костюм", "admin costume", "admin • default"}
local ModelBlockedModels = {
    ["models/kerry/red_cit/male_02.mdl"] = true,
    ["models/squidgame/guard/pacho_black_cit.mdl"] = true
}

local function ModelBlocked(uid, title, model)
    uid = string.lower(tostring(uid or ""))
    if uid == "" or uid == "none" then return true end
    if string.sub(uid, 1, 9) ~= "personal_" then return true end

    if istable(CFG.Blacklist) then
        for key, value in pairs(CFG.Blacklist) do
            if value == true and string.lower(tostring(key)) == uid then return true end
            if isstring(value) and string.lower(value) == uid then return true end
        end
    end

    for _, word in ipairs(ModelUidWords) do
        if string.find(uid, word, 1, true) then return true end
    end

    local name = string.lower(tostring(title or ""))

    for _, word in ipairs(ModelTitleWords) do
        if name ~= "" and string.find(name, word, 1, true) then return true end
    end

    local path = string.lower(string.gsub(tostring(model or ""), "\\", "/"))

    if path ~= "" then
        if ModelBlockedModels[path] then return true end

        for _, word in ipairs(ModelTitleWords) do
            if string.find(path, word, 1, true) then return true end
        end
    end

    return false
end

local function IsTradable(uid)
    uid = tostring(uid or "")
    if uid == "" or uid == "none" then return false end

    local acc = MK.GetAccessory(uid)
    if not acc then return false end
    if Blacklisted(uid, acc) then return false end

    if acc.donateOnly == true then return true end

    local ap = AP()

    if ap and isfunction(ap.IsAccessoryCoinRestricted) then
        local ok, result = pcall(ap.IsAccessoryCoinRestricted, acc)
        if ok then return result == true end
    end

    return MK.CoinPrice(acc) > 0
end

local function TradableList()
    if istable(TradableCache) then return TradableCache end

    TradableCache = {}

    if not istable(hg.Accessories) then
        local empty = TradableCache
        TradableCache = nil
        return empty
    end

    for uid, acc in pairs(hg.Accessories) do
        if istable(acc) and IsTradable(uid) then
            TradableCache[#TradableCache + 1] = uid
        end
    end

    table.sort(TradableCache, function(a, b)
        return MK.AccessoryName(a) < MK.AccessoryName(b)
    end)

    return TradableCache
end

local function OwnsAccessory(ply, uid)
    local sid = SteamOf(ply)

    uid = tostring(uid or "")

    if sid ~= "" and Escrowed(sid, uid) then return false end

    if sid ~= "" and RevokedSource(sid, uid) then
        if not MK.Loaded[sid] then return false end

        ClearRevoked(sid, uid)
    end

    local acc = MK.GetAccessory(uid)

    if istable(acc) and acc.donateOnly == true then
        return HasDonateAny(ply, uid)
    end

    if HasDonateAny(ply, uid) then return true end

    return BaseHasCoin(ply, uid)
end

local function ResolveSource(ply, uid)
    if DonateItem(uid) then return "donate" end
    if HasDonateAny(ply, uid) then return "donate" end

    return "coin"
end

local function ItemName(uid, title)
    title = tostring(title or "")
    if title ~= "" then return title end

    return MK.AccessoryName(uid)
end

local function BuildListings(sid)
    local out = {}
    local uids = {}

    for index, row in ipairs(MK.Listings) do
        local uid = tostring(row.uid or "")

        uids[uid] = true

        out[index] = {
            i = N(row.id),
            u = uid,
            p = N(row.price),
            y = N(row.payout),
            d = tostring(row.description or ""),
            s = tostring(row.seller_name or "Игрок"),
            c = N(row.created),
            o = tostring(row.source or "market"),
            n = tostring(row.title or ""),
            w = tostring(row.model or ""),
            m = tostring(row.seller or "") == sid and 1 or 0
        }
    end

    return out, uids
end

local function SellableFor(ply, force)
    local sid = SteamOf(ply)
    if sid == "" then return {} end

    local cache = MK.SellCache[sid]

    if not force and istable(cache) and (cache.at or 0) > CurTime() - 10 then
        return cache.list
    end

    local list = {}

    for _, uid in ipairs(TradableList()) do
        if OwnsAccessory(ply, uid) then
            list[#list + 1] = {u = uid, o = ResolveSource(ply, uid)}
        end
    end

    MK.SellCache[sid] = {at = CurTime(), list = list}

    return list
end

local function RefreshModels(ply, cb)
    local sid = SteamOf(ply)

    if sid == "" or not ModelReady then
        if cb then cb() end
        return
    end

    MK.ModelStamp[sid] = CurTime()

    Query("SELECT uid, title, model, status FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) ..
        " AND kind = 'model' AND status IN ('owned', 'active') AND model <> '' LIMIT 60;", function(rows)
        local list = {}

        for _, row in ipairs(rows) do
            local uid = tostring(row.uid or "")
            local model = tostring(row.model or "")

            if uid ~= "" and model ~= "" and not ModelBlocked(uid, row.title, model) and not Escrowed(sid, uid) then
                list[#list + 1] = {u = uid, o = "model", n = ItemName(uid, row.title), w = model}
            end
        end

        MK.Models[sid] = list

        if cb then cb() end
    end, function()
        if cb then cb() end
    end)
end

local function BuildStats(uids)
    local out = {}

    for uid in pairs(uids) do
        local stat = MK.Stats[uid]
        if istable(stat) then out[uid] = {n = stat.n, a = stat.a} end
    end

    return out
end

local function PushSync(ply, force)
    if not IsValid(ply) then return end

    local sid = SteamOf(ply)
    if sid == "" then return end

    local now = CurTime()

    if force ~= true and (MK.NextPush[sid] or 0) > now then return end

    MK.NextPush[sid] = now + 1.2

    local listings, uids = BuildListings(sid)
    local sellable = SellableFor(ply, false)
    local models = MK.Models[sid]

    if ModelReady and (not istable(models) or (MK.ModelStamp[sid] or 0) < now - 20) and (MK.ModelPull[sid] or 0) < now then
        MK.ModelPull[sid] = now + 3

        RefreshModels(ply, function()
            if IsValid(ply) then PushSync(ply, true) end
        end)
    end

    if not istable(models) then models = {} end

    for _, entry in ipairs(sellable) do
        uids[entry.u] = true
    end

    MK.Send(ply, "Sync", {
        revision = MK.Revision,
        balance = GetCoins(ply),
        fee = CFG.Fee,
        minPrice = CFG.MinPrice,
        maxPrice = CFG.MaxPrice,
        maxListings = CFG.MaxListingsPerPlayer,
        maxDescription = CFG.MaxDescription,
        expireDays = CFG.ExpireDays,
        listings = listings,
        sellable = sellable,
        models = models,
        history = MK.History[sid] or {},
        stats = BuildStats(uids)
    })
end

local function PushViewers(force)
    local now = CurTime()

    for sid, data in pairs(MK.Viewers) do
        if not istable(data) or not IsValid(data.ply) or (data.expire or 0) < now then
            MK.Viewers[sid] = nil
        else
            PushSync(data.ply, force == true)
        end
    end
end

local function TouchViewer(ply)
    local sid = SteamOf(ply)
    if sid == "" then return end

    MK.Viewers[sid] = {ply = ply, expire = CurTime() + 120}
end

local function LoadHistory(ply, cb)
    local sid = SteamOf(ply)

    if sid == "" then
        if cb then cb() end
        return
    end

    Query("SELECT uid, price, payout, status, seller, seller_name, buyer_name, created, closed FROM " .. T_LIST ..
        " WHERE (seller = " .. S(sid) .. " OR buyer = " .. S(sid) .. ") AND status <> 0 ORDER BY closed DESC LIMIT " .. N(CFG.HistoryLimit) .. ";", function(rows)
        local out = {}

        for index, row in ipairs(rows) do
            local status = N(row.status)
            local isSeller = tostring(row.seller or "") == sid
            local kind = "bought"

            if isSeller then
                if status == 1 then
                    kind = "sold"
                elseif status == 2 then
                    kind = "cancelled"
                else
                    kind = "expired"
                end
            end

            out[index] = {
                k = kind,
                u = tostring(row.uid or ""),
                p = N(row.price),
                y = N(row.payout),
                t = N(row.closed) > 0 and N(row.closed) or N(row.created),
                o = isSeller and tostring(row.buyer_name or "") or tostring(row.seller_name or "")
            }
        end

        MK.History[sid] = out

        if cb then cb() end
    end, function()
        if cb then cb() end
    end)
end

local function RefreshListings(cb)
    local extra = ModelReady and ", title, model" or ""

    Query("SELECT id, uid, seller, seller_name, price, payout, description, source" .. extra .. ", created FROM " .. T_LIST ..
        " WHERE status = 0 ORDER BY created DESC LIMIT " .. N(CFG.MaxListingsSent) .. ";", function(rows)
        MK.Listings = rows
        if cb then cb() end
    end, function()
        if cb then cb() end
    end)
end

local function RefreshStats(cb)
    LastStats = CurTime()

    Query("SELECT uid, sales, total FROM " .. T_STATS .. " WHERE sales > 0 LIMIT 3000;", function(rows)
        local stats = {}

        for _, row in ipairs(rows) do
            local sales = N(row.sales)
            local total = N(row.total)

            if sales > 0 and total > 0 then
                stats[tostring(row.uid or "")] = {n = sales, a = math.floor(total / sales)}
            end
        end

        MK.Stats = stats

        if cb then cb() end
    end, function()
        if cb then cb() end
    end)
end

local function Signature(owned, escrow, revoked)
    local parts = {}

    for uid in pairs(owned or {}) do
        parts[#parts + 1] = "o" .. uid
    end

    for uid in pairs(escrow or {}) do
        parts[#parts + 1] = "e" .. uid
    end

    for uid in pairs(revoked or {}) do
        parts[#parts + 1] = "r" .. uid
    end

    table.sort(parts)

    return table.concat(parts, "|")
end

local function RefreshPlayers(cb, force)
    local now = CurTime()

    if force ~= true and now - LastPlayers < 4 then
        if cb then cb() end
        return
    end

    LastPlayers = now

    local ids = {}
    local players = {}

    for _, ply in ipairs(player.GetAll()) do
        local sid = SteamOf(ply)

        if sid ~= "" then
            ids[#ids + 1] = S(sid)
            players[sid] = ply
        end
    end

    if #ids <= 0 then
        if cb then cb() end
        return
    end

    local list = table.concat(ids, ", ")

    Query("SELECT steamid, uid, source FROM " .. T_OWNED .. " WHERE steamid IN (" .. list .. ");", function(ownedRows)
        Query("SELECT steamid, uid, listing FROM " .. T_ESCROW .. " WHERE steamid IN (" .. list .. ");", function(escrowRows)
            Query("SELECT steamid, uid, source FROM " .. T_REVOKED .. " WHERE steamid IN (" .. list .. ");", function(revokedRows)
                local owned = {}
                local escrow = {}
                local revoked = {}

                for _, row in ipairs(ownedRows) do
                    local sid = tostring(row.steamid or "")
                    owned[sid] = owned[sid] or {}
                    owned[sid][tostring(row.uid or "")] = tostring(row.source or "market")
                end

                for _, row in ipairs(escrowRows) do
                    local sid = tostring(row.steamid or "")
                    escrow[sid] = escrow[sid] or {}
                    escrow[sid][tostring(row.uid or "")] = N(row.listing)
                end

                for _, row in ipairs(revokedRows or {}) do
                    local sid = tostring(row.steamid or "")
                    revoked[sid] = revoked[sid] or {}
                    revoked[sid][tostring(row.uid or "")] = tostring(row.source or "donate")
                end

                for sid, ply in pairs(players) do
                    MK.Owned[sid] = owned[sid] or {}
                    MK.Escrow[sid] = escrow[sid] or {}
                    MK.Revoked[sid] = revoked[sid] or {}
                    MK.Loaded[sid] = true

                    local signature = Signature(MK.Owned[sid], MK.Escrow[sid], MK.Revoked[sid])

                    if MK.Signature[sid] ~= signature then
                        MK.Signature[sid] = signature
                        MK.SellCache[sid] = nil
                        RefreshAppearance(ply)
                    end
                end

                if cb then cb() end
            end, function()
                if cb then cb() end
            end)
        end, function()
            if cb then cb() end
        end)
    end, function()
        if cb then cb() end
    end)
end

local function RefreshAll(push, force)
    if Refreshing then
        RefreshQueued = true
        return
    end

    local now = CurTime()

    if force ~= true and now - LastRefresh < 1.5 then
        RefreshQueued = true
        return
    end

    Refreshing = true
    LastRefresh = now

    RefreshListings(function()
        RefreshPlayers(function()
            local function finish()
                Refreshing = false

                if push ~= false then PushViewers() end

                if RefreshQueued then
                    RefreshQueued = false
                    timer.Simple(2, function() RefreshAll(true) end)
                end
            end

            if CurTime() - LastStats >= 30 then
                RefreshStats(finish)
            else
                finish()
            end
        end)
    end)
end

local function SyncNow()
    RefreshListings(function()
        RefreshPlayers(function()
            PushViewers(true)
        end, true)
    end)
end

local function PullRevision(force)
    if not Ready then return end

    Query("SELECT revision FROM " .. T_META .. " WHERE k = 'market' LIMIT 1;", function(rows)
        local revision = istable(rows[1]) and N(rows[1].revision) or 0

        if force == true or revision ~= MK.Revision then
            MK.Revision = revision
            RefreshAll(true, true)
        end
    end)
end

local function Bump()
    Query("UPDATE " .. T_META .. " SET revision = revision + 1, updated = " .. os.time() .. " WHERE k = 'market';", function()
        PullRevision(true)
    end)
end

local function LogTrade(kind, listing, seller, buyer, uid, price)
    Query("INSERT INTO " .. T_LOG .. " (kind, listing, seller, buyer, uid, price, server_id, created) VALUES (" ..
        S(kind) .. ", " .. N(listing) .. ", " .. S(seller) .. ", " .. S(buyer) .. ", " .. S(uid) .. ", " .. N(price) .. ", " .. S(ServerID()) .. ", " .. os.time() .. ");")

    MK.PanelEvent(kind, listing, seller, buyer, uid, price)
end

function MK.PanelSource()
    if istable(Cases) and istable(Cases.Panel) then return Cases.Panel end
    if istable(HG) and istable(HG.Cases) and istable(HG.Cases.Panel) then return HG.Cases.Panel end

    return nil
end

function MK.PanelConfig()
    local shared = MK.PanelSource()
    local url = string.Trim(tostring(MK.Panel.url or ""))
    local token = string.Trim(tostring(MK.Panel.token or ""))

    if shared then
        if url == "" then url = string.Trim(tostring(shared.url or "")) end
        if token == "" then token = string.Trim(tostring(shared.token or "")) end
    end

    if url == "" then url = string.Trim(tostring(MK.Panel.fallbackUrl or "")) end
    if token == "" then token = string.Trim(tostring(MK.Panel.fallbackToken or "")) end

    return url, token
end

function MK.PanelServerID()
    local shared = MK.PanelSource()
    local configured = string.Trim(tostring(MK.Panel.serverId or ""))

    if configured == "" and shared then configured = string.Trim(tostring(shared.serverId or "")) end
    if configured ~= "" and configured ~= "auto" then return configured end

    local address = game.GetIPAddress and tostring(game.GetIPAddress() or "") or ""
    address = string.lower(string.gsub(address, "[^%w]+", "_"))

    if address ~= "" and address ~= "0_0_0_0_0" then return "otcity_" .. address end

    return "otcity_shared"
end

function MK.PanelServerName()
    local shared = MK.PanelSource()
    local configured = string.Trim(tostring(MK.Panel.serverName or ""))

    if configured == "" and shared then configured = string.Trim(tostring(shared.serverName or "")) end
    if configured ~= "" then return configured end

    local hostname = GetConVar("hostname")
    local value = hostname and string.Trim(hostname:GetString() or "") or ""

    return value ~= "" and value or MK.PanelServerID()
end

function MK.PanelReady()
    if not MK.Panel.enabled then return false end

    local url = MK.PanelConfig()

    return url ~= ""
end

function MK.PanelPost(action, payload)
    if not MK.PanelReady() then return end
    if not istable(payload) then return end

    local url, token = MK.PanelConfig()

    payload.server_id = MK.PanelServerID()
    payload.server_name = string.sub(MK.PanelServerName(), 1, 120)
    payload.at = os.time()
    payload.sync_token = token
    payload.token = token

    local body = util.TableToJSON(payload)
    if not body then return end

    local target = url .. (string.find(url, "?", 1, true) and "&" or "?") .. "action=" .. action

    if token ~= "" then
        target = target .. "&sync_token=" .. token
    end

    HTTP({
        method = "POST",
        url = target,
        type = "application/json",
        body = body,
        headers = {
            ["X-Sync-Token"] = token,
            ["X-Panel-Sync-Token"] = token,
            ["Authorization"] = "Bearer " .. token,
            ["Accept"] = "application/json"
        },
        success = function(code, response)
            if N(code) < 400 then return end

            Log("panel " .. action .. " code " .. N(code) .. " " .. string.sub(string.gsub(tostring(response or ""), "[\r\n]", " "), 1, 220))
        end,
        failed = function(err)
            Log("panel " .. action .. " fail " .. tostring(err))
        end
    })
end

function MK.PanelDiag()
    local url, token = MK.PanelConfig()
    local shared = MK.PanelSource()

    Log("panel url = " .. (url ~= "" and url or "none"))
    Log("panel token length = " .. string.len(token) .. " source = " .. (string.Trim(tostring(MK.Panel.token or "")) ~= "" and "market" or (shared and "cases" or "fallback")))
    Log("panel server_id = " .. MK.PanelServerID() .. " | " .. MK.PanelServerName())
    Log("panel cases config = " .. (shared and "found" or "missing"))
end

function MK.PanelEvent(kind, listing, seller, buyer, uid, price)
    if not MK.PanelReady() then return end

    local stamp = os.time()
    local payload = {
        kind = tostring(kind or ""),
        listing = N(listing),
        uid = tostring(uid or ""),
        price = N(price),
        seller = tostring(seller or ""),
        buyer = tostring(buyer or ""),
        created = stamp,
        event_key = tostring(kind or "") .. ":" .. N(listing) .. ":" .. stamp .. ":" .. N(price)
    }

    if payload.listing <= 0 then
        return MK.PanelPost("push_market_event", payload)
    end

    local extra = ModelReady and ", title" or ""

    Query("SELECT id, uid, seller, seller_name, buyer, buyer_name, price, fee, payout, description, source, status, created, closed" .. extra ..
        " FROM " .. T_LIST .. " WHERE id = " .. payload.listing .. " LIMIT 1;", function(rows)
        local row = rows and rows[1]

        if row then
            payload.uid = tostring(row.uid or payload.uid)
            payload.item_name = tostring(row.title or "")
            payload.source = tostring(row.source or "")
            payload.fee = N(row.fee)
            payload.payout = N(row.payout)
            payload.seller = payload.seller ~= "" and payload.seller or tostring(row.seller or "")
            payload.seller_name = tostring(row.seller_name or "")
            payload.buyer = payload.buyer ~= "" and payload.buyer or tostring(row.buyer or "")
            payload.buyer_name = tostring(row.buyer_name or "")
            payload.listed_at = N(row.created)
            payload.closed_at = N(row.closed)
            payload.listing_row = {
                listing = N(row.id),
                uid = tostring(row.uid or ""),
                item_name = tostring(row.title or ""),
                source = tostring(row.source or ""),
                price = N(row.price),
                fee = N(row.fee),
                payout = N(row.payout),
                seller = tostring(row.seller or ""),
                seller_name = tostring(row.seller_name or ""),
                buyer = tostring(row.buyer or ""),
                buyer_name = tostring(row.buyer_name or ""),
                status = N(row.status),
                description = string.sub(tostring(row.description or ""), 1, 190),
                listed_at = N(row.created),
                closed_at = N(row.closed)
            }
        end

        MK.PanelPost("push_market_event", payload)
    end, function()
        MK.PanelPost("push_market_event", payload)
    end)
end

function MK.PanelHealth(payload, done)
    Query("SELECT (SELECT COUNT(*) FROM " .. T_ESCROW .. ") AS escrow, (SELECT COUNT(*) FROM " .. T_OWNED .. ") AS owned, " ..
        "(SELECT COUNT(*) FROM " .. T_REVOKED .. ") AS revoked, " ..
        "(SELECT COUNT(*) FROM " .. T_ESCROW .. " e LEFT JOIN " .. T_LIST .. " l ON l.id = e.listing AND l.status = 0 WHERE l.id IS NULL) AS orphan, " ..
        "(SELECT COUNT(*) FROM " .. T_LIST .. " WHERE status = 0) AS active, " ..
        "(SELECT COUNT(*) FROM " .. T_LIST .. " WHERE status = 0 AND created > 0 AND created < " .. (os.time() - (21 * 86400)) .. ") AS stuck, " ..
        "(SELECT COUNT(*) FROM " .. T_PAYOUT .. ") AS queued, (SELECT COALESCE(SUM(amount), 0) FROM " .. T_PAYOUT .. ") AS queued_amount;", function(rows)
        local row = rows and rows[1]

        if row then
            payload.health = {
                escrow = N(row.escrow),
                owned = N(row.owned),
                revoked = N(row.revoked),
                orphan_escrow = N(row.orphan),
                active_listings = N(row.active),
                stuck_listings = N(row.stuck),
                pending_payouts = N(row.queued),
                pending_amount = N(row.queued_amount)
            }
        end

        done()
    end, done)
end

function MK.PanelSnapshot()
    if not Ready or not MK.PanelReady() then return end

    local payload = {full = true, listings = {}, items = {}, payouts = {}, health = {}}
    local extra = ModelReady and ", title" or ""
    local fresh = os.time() - (45 * 86400)

    local function send()
        MK.PanelPost("push_market_snapshot", payload)
    end

    Query("SELECT id, uid, seller, seller_name, buyer, buyer_name, price, fee, payout, description, source, status, created, closed" .. extra ..
        " FROM " .. T_LIST .. " WHERE status = 0 OR closed >= " .. fresh .. " ORDER BY id DESC LIMIT 2000;", function(rows)
        for _, row in ipairs(rows or {}) do
            payload.listings[#payload.listings + 1] = {
                listing = N(row.id),
                uid = tostring(row.uid or ""),
                item_name = tostring(row.title or ""),
                source = tostring(row.source or ""),
                price = N(row.price),
                fee = N(row.fee),
                payout = N(row.payout),
                seller = tostring(row.seller or ""),
                seller_name = tostring(row.seller_name or ""),
                buyer = tostring(row.buyer or ""),
                buyer_name = tostring(row.buyer_name or ""),
                status = N(row.status),
                description = string.sub(tostring(row.description or ""), 1, 190),
                listed_at = N(row.created),
                closed_at = N(row.closed)
            }
        end

        Query("SELECT uid, sales, total, last_price, last_sold FROM " .. T_STATS .. " ORDER BY sales DESC LIMIT 1200;", function(stats)
            for _, row in ipairs(stats or {}) do
                local uid = tostring(row.uid or "")

                if uid ~= "" then
                    payload.items[#payload.items + 1] = {
                        uid = uid,
                        sales = N(row.sales),
                        total = N(row.total),
                        last_price = N(row.last_price),
                        last_sold = N(row.last_sold)
                    }
                end
            end

            Query("SELECT steamid, COUNT(*) AS items, COALESCE(SUM(amount), 0) AS amount FROM " .. T_PAYOUT .. " GROUP BY steamid ORDER BY amount DESC LIMIT 150;", function(queue)
                for _, row in ipairs(queue or {}) do
                    local sid = tostring(row.steamid or "")

                    if sid ~= "" then
                        local holder = PlayerBySteam(sid)

                        payload.payouts[#payload.payouts + 1] = {
                            steam_id = sid,
                            nick = IsValid(holder) and string.sub(holder:Nick(), 1, 120) or "",
                            items = N(row.items),
                            amount = N(row.amount)
                        }
                    end
                end

                MK.PanelHealth(payload, send)
            end, function() MK.PanelHealth(payload, send) end)
        end, function() MK.PanelHealth(payload, send) end)
    end, send)
end

function MK.PanelBacklog()
    if not Ready or not MK.PanelReady() then return end

    Query("SELECT id, kind, listing, seller, buyer, uid, price, created FROM " .. T_LOG .. " ORDER BY id DESC LIMIT " .. math.max(50, math.min(2000, tonumber(MK.Panel.backlog) or 400)) .. ";", function(rows)
        for _, row in ipairs(rows or {}) do
            local stamp = N(row.created)

            MK.PanelPost("push_market_event", {
                kind = tostring(row.kind or ""),
                listing = N(row.listing),
                uid = tostring(row.uid or ""),
                price = N(row.price),
                seller = tostring(row.seller or ""),
                buyer = tostring(row.buyer or ""),
                created = stamp,
                event_key = "log:" .. N(row.id)
            })
        end
    end)
end

local function ClaimPayouts(ply)
    local sid = SteamOf(ply)
    if sid == "" then return end

    Query("SELECT id, amount FROM " .. T_PAYOUT .. " WHERE steamid = " .. S(sid) .. " ORDER BY id ASC LIMIT 25;", function(rows)
        for _, row in ipairs(rows) do
            local id = N(row.id)
            local amount = N(row.amount)

            if id > 0 and amount > 0 then
                Query("DELETE FROM " .. T_PAYOUT .. " WHERE id = " .. id .. " LIMIT 1;", function(_, query)
                    if query:affectedRows() ~= 1 then return end

                    if not IsValid(ply) or not GiveCoins(ply, amount, "market_sale") then
                        Query("INSERT INTO " .. T_PAYOUT .. " (steamid, amount, listing, created) VALUES (" .. S(sid) .. ", " .. amount .. ", 0, " .. os.time() .. ");")
                        return
                    end

                    Notify(ply, "Начислено с продажи: " .. MK.FormatNumber(amount) .. " OT-Coin")
                    PushSync(ply, true)
                end)
            end
        end
    end)
end

local function PayoutSeller(sellerSid, amount, listing, uid, title)
    amount = N(amount)
    if amount <= 0 or sellerSid == "" then return end

    local seller = PlayerBySteam(sellerSid)

    if IsValid(seller) and GiveCoins(seller, amount, "market_sale") then
        Notify(seller, "Продано: " .. ItemName(uid, title) .. " — " .. MK.FormatNumber(amount) .. " OT-Coin")
        MK.SellCache[sellerSid] = nil
        LoadHistory(seller, function() PushSync(seller, true) end)
        return
    end

    Query("INSERT INTO " .. T_PAYOUT .. " (steamid, amount, listing, created) VALUES (" .. S(sellerSid) .. ", " .. amount .. ", " .. N(listing) .. ", " .. os.time() .. ");")
end

local function ModelSellable(ply, uid, cb)
    local sid = SteamOf(ply)

    if sid == "" or not ModelReady then
        cb(nil)
        return
    end

    Query("SELECT uid, title, model, status FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND uid = " .. S(uid) ..
        " AND kind = 'model' AND status IN ('owned', 'active') AND model <> '' LIMIT 1;", function(rows)
        local row = rows[1]

        if not istable(row) then
            cb(nil)
            return
        end

        if ModelBlocked(row.uid, row.title, row.model) then
            cb(nil)
            return
        end

        cb({
            uid = tostring(row.uid or ""),
            title = ItemName(uid, row.title),
            model = tostring(row.model or ""),
            status = tostring(row.status or "owned")
        })
    end, function()
        cb(nil)
    end)
end

local function HoldModel(sid, uid, model)
    sid = tostring(sid or "")
    uid = tostring(uid or "")
    model = tostring(model or "")

    if sid == "" or uid == "" then return end

    local api = DonateAPI()
    local ply = PlayerBySteam(sid)

    if IsValid(ply) and api and isfunction(api.DropModelIfActive) then
        pcall(api.DropModelIfActive, ply, model)
    end

    if api and isfunction(api.TakePersonalModel) then
        pcall(api.TakePersonalModel, sid, uid, model)
    else
        Query("DELETE FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND uid = " .. S(uid) .. " AND kind = 'model' LIMIT 1;")

        if model ~= "" then
            Query("DELETE FROM " .. T_ACTIVE .. " WHERE steamid64 = " .. S(sid) .. " AND model = " .. S(model) .. " LIMIT 1;")
        end
    end

    MK.Models[sid] = nil
    MK.ModelStamp[sid] = 0

    if not api or not isfunction(api.SyncInventory) then return end

    timer.Simple(0.6, function()
        local target = PlayerBySteam(sid)
        if IsValid(target) then pcall(api.SyncInventory, target) end
    end)
end

local function RestoreModel(sid, uid, title, model)
    sid = tostring(sid or "")
    uid = tostring(uid or "")
    title = tostring(title or "")
    model = tostring(model or "")

    if sid == "" or uid == "" then return end

    local api = DonateAPI()

    if api and isfunction(api.GivePersonalModelTo) then
        pcall(api.GivePersonalModelTo, sid, model, uid, title)
    else
        Query("SELECT id FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND uid = " .. S(uid) .. " AND kind = 'model' LIMIT 1;", function(rows)
            if istable(rows) and istable(rows[1]) then
                Query("UPDATE " .. T_INV .. " SET status = 'owned', title = " .. S(title) .. ", model = " .. S(model) ..
                    " WHERE steamid64 = " .. S(sid) .. " AND uid = " .. S(uid) .. " AND kind = 'model' LIMIT 1;")
                return
            end

            if model == "" then return end

            Query("INSERT INTO " .. T_INV .. " (steamid64, uid, amount, title, subtitle, tag, kind, model, duration, status) VALUES (" ..
                S(sid) .. ", " .. S(uid) .. ", 0, " .. S(title) .. ", 'Личная модель', 'PERSONAL • ЛИЧНАЯ', 'model', " .. S(model) .. ", 0, 'owned');")
        end)
    end

    MK.Models[sid] = nil
    MK.ModelStamp[sid] = 0

    if not api or not isfunction(api.SyncInventory) then return end

    for _, delay in ipairs({0.6, 2}) do
        timer.Simple(delay, function()
            local target = PlayerBySteam(sid)
            if IsValid(target) then pcall(api.SyncInventory, target) end
        end)
    end
end

local function ReconcileModels(sellers)
    if not Ready or not ModelReady then return end

    local filter = ""

    if istable(sellers) and #sellers > 0 then
        filter = " AND l.seller IN (" .. table.concat(sellers, ", ") .. ")"
    end

    local function pull(row)
        local sid = tostring(row.seller or "")
        local uid = tostring(row.uid or "")
        local model = tostring(row.model or "")

        if sid == "" or uid == "" then return end

        HoldModel(sid, uid, model)
        MK.SellCache[sid] = nil
    end

    Query("SELECT DISTINCT l.seller AS seller, l.uid AS uid, l.model AS model FROM " .. T_LIST .. " l JOIN " .. T_INV ..
        " i ON i.steamid64 = l.seller AND i.kind = 'model' AND (i.uid = l.uid OR (l.model <> '' AND i.model = l.model))" ..
        " WHERE l.status = 0 AND l.source = 'model'" .. filter .. " LIMIT 100;", function(rows)
        for _, row in ipairs(rows) do
            pull(row)
        end
    end)

    Query("SELECT DISTINCT l.seller AS seller, l.uid AS uid, l.model AS model FROM " .. T_LIST .. " l JOIN " .. T_ACTIVE ..
        " a ON a.steamid64 = l.seller AND a.model = l.model" ..
        " WHERE l.status = 0 AND l.source = 'model' AND l.model <> ''" .. filter .. " LIMIT 100;", function(rows)
        for _, row in ipairs(rows) do
            pull(row)
        end
    end)
end

local function ReconcileAccessories(sellers)
    if not Ready then return end

    local lots = {}
    local ids = {}
    local seen = {}
    local scope = ""
    local ledger = ""

    if istable(sellers) and #sellers > 0 then
        scope = " AND seller IN (" .. table.concat(sellers, ", ") .. ")"
        ledger = " WHERE steamid IN (" .. table.concat(sellers, ", ") .. ")"
    end

    local function collect(sid, uid, live)
        sid = tostring(sid or "")
        uid = tostring(uid or "")

        if sid == "" or uid == "" then return end

        lots[#lots + 1] = {sid = sid, uid = uid, live = live == true}

        if seen[sid] then return end

        seen[sid] = true
        ids[#ids + 1] = S(sid)
    end

    local function apply()
        if #lots == 0 then return end

        Query("SELECT steamid64, uid FROM " .. T_ACCS .. " WHERE steamid64 IN (" .. table.concat(ids, ", ") .. ");", function(accRows)
            local owned = {}

            for _, row in ipairs(accRows) do
                local sid = tostring(row.steamid64 or "")

                if sid ~= "" then
                    owned[sid] = owned[sid] or {}
                    owned[sid][tostring(row.uid or "")] = true
                end
            end

            for _, lot in ipairs(lots) do
                local ply = PlayerBySteam(lot.sid)
                local held = owned[lot.sid] or {}
                local cached = DonateAccs(lot.sid)
                local donated = false

                for _, alias in ipairs(ShopUIDs(lot.uid)) do
                    if held[alias] == true or cached[alias] == true then donated = true end
                end

                if lot.live then
                    if donated then RevokeDonate(ply, lot.sid, lot.uid) end

                    if IsValid(ply) then
                        local coins = CoinOwned(ply)

                        if istable(coins) and coins[lot.uid] == true then
                            RevokeCoin(ply, lot.uid)
                        end
                    end
                else
                    ClearRevoked(lot.sid, lot.uid)

                    for _, alias in ipairs(ShopUIDs(lot.uid)) do
                        ClearRevoked(lot.sid, alias)
                    end

                    if donated and IsValid(ply) then
                        local api = DonateAPI()

                        if api and isfunction(api.RefreshAccessories) then pcall(api.RefreshAccessories, ply) end

                        RefreshAppearance(ply)
                    end
                end

                MK.SellCache[lot.sid] = nil
            end
        end)
    end

    local function pullLedger()
        Query("SELECT steamid, uid FROM " .. T_REVOKED .. ledger .. " LIMIT 300;", function(rows)
            for _, row in ipairs(rows or {}) do
                collect(row.steamid, row.uid, false)
            end

            apply()
        end, function()
            apply()
        end)
    end

    Query("SELECT DISTINCT seller, uid FROM " .. T_LIST .. " WHERE status = 0 AND source <> 'model'" .. scope .. " LIMIT 300;", function(rows)
        for _, row in ipairs(rows or {}) do
            collect(row.seller, row.uid, true)
        end

        pullLedger()
    end, function()
        pullLedger()
    end)
end

local function ReconcileEscrow(sellers)
    if not Ready then return end

    ReconcileModels(sellers)
    ReconcileAccessories(sellers)
end

local function PlayerBySid(sid)
    sid = tostring(sid or "")
    if sid == "" then return nil end

    for _, ply in ipairs(player.GetAll()) do
        if SteamOf(ply) == sid then return ply end
    end

    return nil
end

local function PurgeStale(ply)
    if not IsValid(ply) then return end

    local sid = SteamOf(ply)
    if sid == "" then return end

    local dirty = false
    local owned = MK.Owned[sid]
    local coin = CoinOwned(ply)

    if istable(owned) then
        for uid in pairs(owned) do
            if not IsTradable(uid) then
                owned[uid] = nil
                dirty = true

                Query("DELETE FROM " .. T_OWNED .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " LIMIT 1;")
            elseif DonateItem(uid) and not Escrowed(sid, uid) and not RevokedSource(sid, uid) and not HasDonateAny(ply, uid) then
                GrantDonate(ply, sid, uid)
                dirty = true
            end
        end
    end

    if istable(coin) then
        local changed = false

        for uid in pairs(coin) do
            if DonateItem(uid) then
                coin[uid] = nil
                changed = true
                dirty = true

                if istable(owned) and owned[uid] and not Escrowed(sid, uid) and not RevokedSource(sid, uid) and not HasDonateAny(ply, uid) then
                    GrantDonate(ply, sid, uid)
                end
            end
        end

        if changed and isfunction(ply.SetMData) then
            ply:SetMData(CoinKey(), util.TableToJSON(coin))
        end
    end

    Query("DELETE r FROM " .. T_REVOKED .. " r LEFT JOIN " .. T_LIST .. " l ON l.seller = r.steamid AND l.uid = r.uid AND l.status = 0 " ..
        "WHERE r.steamid = " .. S(sid) .. " AND l.id IS NULL;", function()
        MK.Revoked[sid] = nil
        MK.Signature[sid] = nil
        MK.SellCache[sid] = nil
    end)

    if dirty then
        MK.SellCache[sid] = nil
        MK.Signature[sid] = nil

        local api = DonateAPI()

        if api then
            if isfunction(api.RefreshAccessories) then pcall(api.RefreshAccessories, ply) end
            if isfunction(api.RefreshAppearance) then pcall(api.RefreshAppearance, ply) end
        end

        RefreshAppearance(ply)
    end
end

local function ReconcileFor(sid)
    sid = tostring(sid or "")
    if sid == "" then return end

    PurgeStale(PlayerBySid(sid))
    ReconcileEscrow({S(sid)})
end

local function ReconcileAll()
    for _, ply in ipairs(player.GetAll()) do
        PurgeStale(ply)
    end

    ReconcileEscrow(nil)
end

local function InsertListing(ply, sid, uid, clean, desc, source, title, model, hold)
    local payout = MK.Payout(clean)
    local stamp = os.time()
    local nick = ply:Nick()

    Query("SELECT COUNT(*) AS total FROM " .. T_LIST .. " WHERE seller = " .. S(sid) .. " AND status = 0;", function(rows)
        local count = istable(rows[1]) and N(rows[1].total) or 0

        if count >= N(CFG.MaxListingsPerPlayer) then
            return Notify(ply, "Лимит лотов: " .. N(CFG.MaxListingsPerPlayer), true)
        end

        Query("INSERT INTO " .. T_ESCROW .. " (steamid, uid, listing, created) VALUES (" .. S(sid) .. ", " .. S(uid) .. ", 0, " .. stamp .. ");", function()
            MK.Escrow[sid] = MK.Escrow[sid] or {}
            MK.Escrow[sid][uid] = 0
            MK.SellCache[sid] = nil

            local columns = "uid, seller, seller_name, price, fee, payout, description, source, status, server_id, created"
            local values = S(uid) .. ", " .. S(sid) .. ", " .. S(nick) .. ", " .. clean .. ", " .. MK.Fee(clean) .. ", " .. payout ..
                ", " .. S(desc) .. ", " .. S(source) .. ", 0, " .. S(ServerID()) .. ", " .. stamp

            if ModelReady then
                columns = columns .. ", title, model"
                values = values .. ", " .. S(title) .. ", " .. S(model)
            end

            Query("INSERT INTO " .. T_LIST .. " (" .. columns .. ") VALUES (" .. values .. ");", function(_, query)
                local id = N(query:lastInsert())

                if id <= 0 then
                    Query("DELETE FROM " .. T_ESCROW .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " LIMIT 1;")

                    if MK.Escrow[sid] then MK.Escrow[sid][uid] = nil end

                    return Notify(ply, "Не удалось выставить лот", true)
                end

                Query("UPDATE " .. T_ESCROW .. " SET listing = " .. id .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " LIMIT 1;")

                MK.Escrow[sid][uid] = id

                if hold then hold(id) end

                LogTrade("list", id, sid, "", uid, clean)
                RefreshAppearance(ply)
                Notify(ply, "Лот выставлен: " .. ItemName(uid, title) .. " — " .. MK.FormatNumber(clean) .. " OT-Coin")

                if IsValid(ply) then
                    LoadHistory(ply, function() PushSync(ply, true) end)
                end

                Bump()
                SyncNow()
            end, function()
                Query("DELETE FROM " .. T_ESCROW .. " WHERE steamid = " .. S(sid) .. " AND uid = " .. S(uid) .. " AND listing = 0 LIMIT 1;")

                if MK.Escrow[sid] then MK.Escrow[sid][uid] = nil end

                Notify(ply, "Не удалось выставить лот", true)
            end)
        end, function()
            Notify(ply, "Этот предмет уже выставлен на рынок", true)
        end)
    end, function()
        Notify(ply, "База недоступна, повтори позже", true)
    end)
end

local function CreateListing(ply, uid, price, description)
    if not IsValid(ply) then return end

    local sid = SteamOf(ply)
    if sid == "" then return end

    uid = tostring(uid or "")
    if uid == "" or #uid > 128 then return end

    if not Cooldown(ply, "list", CFG.ListCooldown) then
        return Notify(ply, "Подожди немного", true)
    end

    if not MK.Loaded[sid] then
        return Notify(ply, "Данные ещё загружаются, повтори через пару секунд", true)
    end

    local clean = MK.NormalizePrice(price)

    if not clean then
        return Notify(ply, "Цена от " .. MK.FormatNumber(CFG.MinPrice) .. " до " .. MK.FormatNumber(CFG.MaxPrice), true)
    end

    if Escrowed(sid, uid) then
        return Notify(ply, "Этот предмет уже выставлен на рынок", true)
    end

    local desc = MK.SanitizeDescription(description)

    if MK.GetAccessory(uid) then
        if not IsTradable(uid) then
            return Notify(ply, "Этот аксессуар нельзя продавать", true)
        end

        if not OwnsAccessory(ply, uid) then
            return Notify(ply, "У тебя нет этого аксессуара", true)
        end

        local source = ResolveSource(ply, uid)

        return InsertListing(ply, sid, uid, clean, desc, source, "", "", function()
            TransferOwnership(sid, uid, source, "revoke")
        end)
    end

    if ModelBlocked(uid, "", "") then
        return Notify(ply, "Эту модель нельзя продавать", true)
    end

    if not ModelReady then
        return Notify(ply, "Продажа личных моделек пока недоступна", true)
    end

    ModelSellable(ply, uid, function(info)
        if not IsValid(ply) then return end

        if not istable(info) or info.model == "" then
            return Notify(ply, "У тебя нет этой модельки", true)
        end

        InsertListing(ply, sid, uid, clean, desc, "model", info.title, info.model, function()
            HoldModel(sid, uid, info.model)
        end)
    end)
end

local function CancelListing(ply, id)
    if not IsValid(ply) then return end

    local sid = SteamOf(ply)
    if sid == "" then return end

    id = N(id)
    if id <= 0 then return end

    if not Cooldown(ply, "cancel", CFG.CancelCooldown) then
        return Notify(ply, "Подожди немного", true)
    end

    local extra = ModelReady and ", title, model" or ""

    Query("SELECT uid, source" .. extra .. " FROM " .. T_LIST .. " WHERE id = " .. id .. " AND seller = " .. S(sid) .. " AND status = 0 LIMIT 1;", function(rows)
        local row = rows[1]
        local uid = istable(row) and tostring(row.uid or "") or ""

        if uid == "" then
            return Notify(ply, "Лот уже закрыт", true)
        end

        local source = tostring(row.source or "market")
        local title = tostring(row.title or "")
        local model = tostring(row.model or "")

        Query("UPDATE " .. T_LIST .. " SET status = 2, closed = " .. os.time() .. " WHERE id = " .. id .. " AND seller = " .. S(sid) .. " AND status = 0 LIMIT 1;", function(_, query)
            if query:affectedRows() ~= 1 then
                return Notify(ply, "Лот уже закрыт", true)
            end

            Query("DELETE FROM " .. T_ESCROW .. " WHERE listing = " .. id .. " LIMIT 1;", function()
                if MK.Escrow[sid] then MK.Escrow[sid][uid] = nil end

                MK.SellCache[sid] = nil

                if source == "model" then
                    RestoreModel(sid, uid, ItemName(uid, title), model)
                else
                    TransferOwnership(sid, uid, source, "grant")
                end

                LogTrade("cancel", id, sid, "", uid, 0)
                RefreshAppearance(ply)
                Notify(ply, "Лот снят с продажи")

                if IsValid(ply) then
                    LoadHistory(ply, function() PushSync(ply, true) end)
                end

                Bump()
                SyncNow()
            end)
        end)
    end)
end

local function BuyListing(ply, id)
    if not IsValid(ply) then return end

    local sid = SteamOf(ply)
    if sid == "" then return end

    id = N(id)
    if id <= 0 then return end

    if not Cooldown(ply, "buy", CFG.BuyCooldown) then
        return Notify(ply, "Подожди немного", true)
    end

    local extra = ModelReady and ", title, model" or ""

    Query("SELECT uid, seller, price, payout, source" .. extra .. " FROM " .. T_LIST .. " WHERE id = " .. id .. " AND status = 0 LIMIT 1;", function(rows)
        local row = rows[1]

        if not istable(row) then
            return Notify(ply, "Лот больше недоступен", true)
        end

        if not IsValid(ply) then return end

        local uid = tostring(row.uid or "")
        local sellerSid = tostring(row.seller or "")
        local price = N(row.price)
        local payout = N(row.payout)
        local source = tostring(row.source or "market")
        local title = tostring(row.title or "")
        local model = tostring(row.model or "")
        local isModel = source == "model"

        if payout <= 0 then payout = MK.Payout(price) end

        if isModel and not ModelReady then
            return Notify(ply, "Личные модельки сейчас недоступны", true)
        end

        if isModel and model == "" then
            return Notify(ply, "У этого лота потерян путь модели", true)
        end

        if sellerSid == sid then
            return Notify(ply, "Это твой лот", true)
        end

        if not isModel and not IsTradable(uid) then
            return Notify(ply, "Этот предмет больше нельзя продавать", true)
        end

        if isModel and ModelBlocked(uid, title, model) then
            return Notify(ply, "Этот лот заблокирован и будет снят", true)
        end

        if not isModel and OwnsAccessory(ply, uid) then
            return Notify(ply, "Этот аксессуар уже у тебя есть", true)
        end

        if GetCoins(ply) < price then
            return Notify(ply, "Не хватает OT-Coin", true)
        end

        local function proceed()
            if not IsValid(ply) then return end

            local stamp = os.time()

            Query("UPDATE " .. T_LIST .. " SET status = 1, buyer = " .. S(sid) .. ", buyer_name = " .. S(ply:Nick()) .. ", closed = " .. stamp ..
                " WHERE id = " .. id .. " AND status = 0 LIMIT 1;", function(_, query)
                if query:affectedRows() ~= 1 then
                    return Notify(ply, "Лот уже купили", true)
                end

                local function rollback(reason)
                    Query("UPDATE " .. T_LIST .. " SET status = 0, buyer = '', buyer_name = '', closed = 0 WHERE id = " .. id ..
                        " AND status = 1 AND buyer = " .. S(sid) .. " LIMIT 1;", function()
                        Bump()
                    end)

                    if reason then Notify(ply, reason, true) end
                end

                if not IsValid(ply) then return rollback(nil) end
                if not TakeCoins(ply, price) then return rollback("Не хватает OT-Coin") end

                Query("DELETE FROM " .. T_ESCROW .. " WHERE listing = " .. id .. " LIMIT 1;")

                if isModel then
                    HoldModel(sellerSid, uid, model)
                    RestoreModel(sid, uid, ItemName(uid, title), model)

                    MK.Models[sid] = nil
                    MK.Models[sellerSid] = nil
                    MK.ModelStamp[sid] = 0
                    MK.ModelStamp[sellerSid] = 0
                else
                    Query("INSERT IGNORE INTO " .. T_OWNED .. " (steamid, uid, source, created) VALUES (" .. S(sid) .. ", " .. S(uid) .. ", 'market', " .. stamp .. ");")

                    MK.Owned[sid] = MK.Owned[sid] or {}
                    MK.Owned[sid][uid] = "market"

                    TransferOwnership(sellerSid, uid, source, "revoke")
                    TransferOwnership(sid, uid, source, "grant")
                end

                Query("INSERT INTO " .. T_STATS .. " (uid, sales, total, last_price, last_sold) VALUES (" .. S(uid) .. ", 1, " .. price .. ", " .. price .. ", " .. stamp ..
                    ") ON DUPLICATE KEY UPDATE sales = sales + 1, total = total + " .. price .. ", last_price = " .. price .. ", last_sold = " .. stamp .. ";")

                MK.SellCache[sid] = nil

                if MK.Escrow[sellerSid] then MK.Escrow[sellerSid][uid] = nil end

                MK.SellCache[sellerSid] = nil

                LogTrade("buy", id, sellerSid, sid, uid, price)
                RefreshAppearance(ply)

                local seller = PlayerBySteam(sellerSid)
                if IsValid(seller) then RefreshAppearance(seller) end

                Notify(ply, "Куплено: " .. ItemName(uid, title) .. " — " .. MK.FormatNumber(price) .. " OT-Coin")

                if isModel then
                    Notify(ply, "Моделька появится в донат-меню, раздел Модели")

                    if IsValid(seller) then
                        Notify(seller, "Твоя личная моделька продана: " .. ItemName(uid, title))
                    end
                end

                PayoutSeller(sellerSid, payout, id, uid, title)
                LoadHistory(ply, function() PushSync(ply, true) end)

                Bump()
                SyncNow()
            end)
        end

        if not isModel then return proceed() end

        local dupe = "uid = " .. S(uid)

        if model ~= "" then dupe = "(" .. dupe .. " OR model = " .. S(model) .. ")" end

        Query("SELECT id FROM " .. T_INV .. " WHERE steamid64 = " .. S(sid) .. " AND kind = 'model' AND " .. dupe .. " LIMIT 1;", function(owned)
            if not IsValid(ply) then return end

            if istable(owned[1]) then
                return Notify(ply, "Эта моделька уже у тебя есть", true)
            end

            proceed()
        end, function()
            Notify(ply, "База недоступна, повтори позже", true)
        end)
    end)
end

local function ReturnListing(id, sid, uid, source, title, model)
    Query("DELETE FROM " .. T_ESCROW .. " WHERE listing = " .. N(id) .. " LIMIT 1;")

    if MK.Escrow[sid] then MK.Escrow[sid][uid] = nil end

    MK.SellCache[sid] = nil

    if source == "model" then
        RestoreModel(sid, uid, ItemName(uid, title), model)
    else
        TransferOwnership(sid, uid, source, "grant")
    end

    local ply = PlayerBySteam(sid)

    if IsValid(ply) then
        Notify(ply, "Лот вернулся в инвентарь: " .. ItemName(uid, title))
    end
end

local function CloseListings(rows, kind)
    local closed = false

    for _, row in ipairs(rows or {}) do
        local id = N(row.id)
        local sid = tostring(row.seller or "")
        local uid = tostring(row.uid or "")
        local source = tostring(row.source or "market")
        local title = tostring(row.title or "")
        local model = tostring(row.model or "")

        if id > 0 and sid ~= "" and uid ~= "" then
            closed = true

            Query("UPDATE " .. T_LIST .. " SET status = " .. N(kind) .. ", closed = " .. os.time() .. " WHERE id = " .. id .. " AND status = 0 LIMIT 1;", function(_, query)
                if query:affectedRows() ~= 1 then return end

                ReturnListing(id, sid, uid, source, title, model)
                LogTrade(kind == 4 and "expire" or "purge", id, sid, "", uid, 0)
            end)
        end
    end

    if closed then
        timer.Simple(2, function()
            Bump()
            SyncNow()
        end)
    end
end

local function ExpireSweep()
    local stamp = os.time()
    local threshold = stamp - math.max(1, N(CFG.ExpireDays)) * 86400
    local lockAge = stamp - math.max(60, N(CFG.ExpireInterval))
    local extra = ModelReady and ", title, model" or ""

    Query("INSERT INTO " .. T_META .. " (k, revision, updated) VALUES ('expire', 0, " .. stamp .. ") ON DUPLICATE KEY UPDATE updated = IF(updated < " .. lockAge .. ", " .. stamp .. ", updated);", function(_, query)
        if query:affectedRows() == 0 then return end

        Query("SELECT id, uid, seller, source" .. extra .. " FROM " .. T_LIST .. " WHERE status = 0 AND created < " .. threshold .. " LIMIT 100;", function(rows)
            CloseListings(rows, 4)

            Query("DELETE e FROM " .. T_ESCROW .. " e LEFT JOIN " .. T_LIST .. " l ON l.id = e.listing WHERE e.listing > 0 AND (l.id IS NULL OR l.status <> 0);", function(_, cleaned)
                if cleaned:affectedRows() > 0 then Bump() end
            end)

            Query("DELETE r FROM " .. T_REVOKED .. " r LEFT JOIN " .. T_LIST .. " l ON l.seller = r.steamid AND l.uid = r.uid AND l.status = 0 " ..
                "WHERE l.id IS NULL LIMIT 500;", function(_, purged)
                if purged:affectedRows() > 0 then
                    MK.Revoked = {}
                    MK.Signature = {}
                    MK.SellCache = {}

                    Bump()
                end
            end)
        end)
    end)
end

local function PurgeBlacklisted()
    if not Ready then return end

    local extra = ModelReady and ", title, model" or ""

    Query("SELECT id, uid, seller, source" .. extra .. " FROM " .. T_LIST .. " WHERE status = 0 LIMIT 300;", function(rows)
        local bad = {}

        for _, row in ipairs(rows) do
            local uid = tostring(row.uid or "")
            local source = tostring(row.source or "market")

            local blocked

            if source == "model" then
                blocked = ModelBlocked(uid, row.title, row.model)
            else
                blocked = not IsTradable(uid)
            end

            if blocked then
                bad[#bad + 1] = row
            end
        end

        if #bad == 0 then return end

        Log("purge blacklisted listings: " .. #bad)
        CloseListings(bad, 2)
    end)
end

local function EnsureColumns(done)
    Raw("SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = " .. S(T_LIST) .. ";", function(rows)
        local have = {}

        for _, row in ipairs(rows) do
            have[string.lower(tostring(row.name or row.NAME or row.COLUMN_NAME or ""))] = true
        end

        local pending = {}

        if not have.title then
            pending[#pending + 1] = "ALTER TABLE " .. T_LIST .. " ADD COLUMN title VARCHAR(96) NOT NULL DEFAULT '';"
        end

        if not have.model then
            pending[#pending + 1] = "ALTER TABLE " .. T_LIST .. " ADD COLUMN model VARCHAR(255) NOT NULL DEFAULT '';"
        end

        if #pending == 0 then
            if done then done() end
            return
        end

        RunSequence(pending, done)
    end, function()
        RunSequence({
            "ALTER TABLE " .. T_LIST .. " ADD COLUMN title VARCHAR(96) NOT NULL DEFAULT '';",
            "ALTER TABLE " .. T_LIST .. " ADD COLUMN model VARCHAR(255) NOT NULL DEFAULT '';"
        }, done)
    end)
end

local function BuildSchema(done)
    RunSequence({
        "CREATE TABLE IF NOT EXISTS " .. T_LIST .. " (" ..
            "id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT," ..
            "uid VARCHAR(128) NOT NULL," ..
            "seller VARCHAR(32) NOT NULL," ..
            "seller_name VARCHAR(64) NOT NULL DEFAULT ''," ..
            "buyer VARCHAR(32) NOT NULL DEFAULT ''," ..
            "buyer_name VARCHAR(64) NOT NULL DEFAULT ''," ..
            "price INT UNSIGNED NOT NULL DEFAULT 0," ..
            "fee INT UNSIGNED NOT NULL DEFAULT 0," ..
            "payout INT UNSIGNED NOT NULL DEFAULT 0," ..
            "description VARCHAR(255) NOT NULL DEFAULT ''," ..
            "source VARCHAR(16) NOT NULL DEFAULT 'market'," ..
            "status TINYINT UNSIGNED NOT NULL DEFAULT 0," ..
            "server_id VARCHAR(48) NOT NULL DEFAULT ''," ..
            "created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "closed INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (id), KEY status_created (status, created), KEY seller_status (seller, status), KEY buyer_status (buyer, status), KEY uid_status (uid, status)" ..
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_OWNED .. " (" ..
            "steamid VARCHAR(32) NOT NULL, uid VARCHAR(128) NOT NULL, source VARCHAR(16) NOT NULL DEFAULT 'market', created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (steamid, uid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_ESCROW .. " (" ..
            "steamid VARCHAR(32) NOT NULL, uid VARCHAR(128) NOT NULL, listing BIGINT UNSIGNED NOT NULL DEFAULT 0, created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (steamid, uid), KEY listing_idx (listing)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_PAYOUT .. " (" ..
            "id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, steamid VARCHAR(32) NOT NULL, amount INT UNSIGNED NOT NULL DEFAULT 0, listing BIGINT UNSIGNED NOT NULL DEFAULT 0, created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (id), KEY steamid_idx (steamid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_STATS .. " (" ..
            "uid VARCHAR(128) NOT NULL, sales INT UNSIGNED NOT NULL DEFAULT 0, total BIGINT UNSIGNED NOT NULL DEFAULT 0, last_price INT UNSIGNED NOT NULL DEFAULT 0, last_sold INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (uid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_META .. " (" ..
            "k VARCHAR(32) NOT NULL, revision BIGINT UNSIGNED NOT NULL DEFAULT 0, updated INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (k)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_LOG .. " (" ..
            "id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, kind VARCHAR(16) NOT NULL DEFAULT '', listing BIGINT UNSIGNED NOT NULL DEFAULT 0, seller VARCHAR(32) NOT NULL DEFAULT '', buyer VARCHAR(32) NOT NULL DEFAULT '', uid VARCHAR(128) NOT NULL DEFAULT '', price INT UNSIGNED NOT NULL DEFAULT 0, server_id VARCHAR(48) NOT NULL DEFAULT '', created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (id), KEY created_idx (created)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_REVOKED .. " (" ..
            "steamid VARCHAR(32) NOT NULL, uid VARCHAR(128) NOT NULL, source VARCHAR(16) NOT NULL DEFAULT 'donate', created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (steamid, uid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "CREATE TABLE IF NOT EXISTS " .. T_GRANT .. " (" ..
            "id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, steamid VARCHAR(32) NOT NULL, uid VARCHAR(128) NOT NULL, source VARCHAR(16) NOT NULL DEFAULT 'coin', action VARCHAR(8) NOT NULL DEFAULT 'grant', created INT UNSIGNED NOT NULL DEFAULT 0," ..
            "PRIMARY KEY (id), KEY steamid_idx (steamid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
        "INSERT INTO " .. T_META .. " (k, revision, updated) VALUES ('market', 1, " .. os.time() .. ") ON DUPLICATE KEY UPDATE k = k;"
    }, function()
        EnsureColumns(done)
    end)
end

local function ResolveMySQL()
    if istable(CFG.MySQL) then return CFG.MySQL end

    if istable(OTCDonate) and istable(OTCDonate.Config) and istable(OTCDonate.Config.mysql) then
        CFG.MySQL = table.Copy(OTCDonate.Config.mysql)
        return CFG.MySQL
    end

    return nil
end

local Connect

function Connect()
    if not istable(mysqloo) then
        Log("mysqloo не найден")
        return
    end

    local cfg = ResolveMySQL()

    if not cfg then
        timer.Simple(3, Connect)
        return
    end

    DB = mysqloo.connect(cfg.host, cfg.username, cfg.password, cfg.database, tonumber(cfg.port) or 3306, cfg.socket)

    function DB:onConnected()
        Log("MySQL подключен")

        BuildSchema(function()
            Ready = true
            Flush()

            ModelReady = true

            Raw("SHOW COLUMNS FROM " .. T_LIST .. " LIKE 'model';", function(rows)
                if istable(rows) and istable(rows[1]) then ModelReady = true end
            end)

            RefreshStats(function()
                PullRevision(true)
            end)

            timer.Simple(10, function()
                if Ready then ReconcileAll() end
            end)

            for _, ply in ipairs(player.GetAll()) do
                ClaimPayouts(ply)
            end
        end)
    end

    function DB:onConnectionFailed(err)
        Log("MySQL ошибка: " .. tostring(err))
        Ready = false
        timer.Simple(5, Connect)
    end

    DB:connect()
end

local function KeepAlive()
    if not DB then return end

    local status = DB:status()

    if status == mysqloo.DATABASE_NOT_CONNECTED then
        Ready = false
        pcall(function() DB:connect() end)
    elseif status == mysqloo.DATABASE_CONNECTED then
        Query("SELECT 1;")
    end
end

MK.Hook("Request", function(ply, payload)
    if not IsValid(ply) then return end
    if not Cooldown(ply, "sync", CFG.SyncCooldown) then return end

    TouchViewer(ply)

    local sid = SteamOf(ply)
    local full = payload.full == true

    if full then RefreshModels(ply) end

    if full or not istable(MK.History[sid]) then
        LoadHistory(ply, function()
            if IsValid(ply) then PushSync(ply, true) end
        end)
    else
        PushSync(ply, false)
    end
end)

MK.Hook("Close", function(ply)
    local sid = SteamOf(ply)
    if sid == "" then return end

    MK.Viewers[sid] = nil
end)

MK.Hook("List", function(ply, payload)
    CreateListing(ply, payload.uid, payload.price, payload.desc)
end)

MK.Hook("Cancel", function(ply, payload)
    CancelListing(ply, payload.id)
end)

MK.Hook("Buy", function(ply, payload)
    BuyListing(ply, payload.id)
end)

function MK.OpenForPlayer(ply)
    if not IsValid(ply) then return end

    if not Ready then
        return Notify(ply, "Рынок ещё загружается, повтори через пару секунд", true)
    end

    if not Cooldown(ply, "open", 1) then return end

    TouchViewer(ply)

    MK.Send(ply, "Open", {})

    RefreshModels(ply)

    LoadHistory(ply, function()
        if IsValid(ply) then PushSync(ply, true) end
    end)
end

concommand.Add("hg_market_open", function(ply)
    MK.OpenForPlayer(ply)
end)

concommand.Add("hg_market_flush_payouts", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for _, target in ipairs(player.GetAll()) do
        ClaimPayouts(target)
    end
end)

concommand.Add("hg_market_wipe_listing", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local id = N(args and args[1])
    if id <= 0 then return end

    Query("UPDATE " .. T_LIST .. " SET status = 2, closed = " .. os.time() .. " WHERE id = " .. id .. " AND status = 0 LIMIT 1;", function()
        Query("DELETE FROM " .. T_ESCROW .. " WHERE listing = " .. id .. " LIMIT 1;", function()
            Bump()
        end)
    end)
end)

concommand.Add("hg_market_unrevoke", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not Ready then return end

    local sid = tostring((args or {})[1] or "")
    local uid = tostring((args or {})[2] or "")

    if sid == "" or uid == "" then
        Log("hg_market_unrevoke <steamid64> <uid>")
        return
    end

    ClearRevoked(sid, uid)

    local target = PlayerBySteam(sid)

    if IsValid(target) then
        GrantDonate(target, sid, uid)
        RefreshAppearance(target)
    end

    Log("снята блокировка владения: " .. sid .. " / " .. uid)
end)

concommand.Add("hg_market_reconcile", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not Ready then return end

    ReconcileAll()
    Log("сверка escrow запущена")
end)

concommand.Add("hg_market_rebuild_cache", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    TradableCache = nil
    MK.SellCache = {}
    MK.Models = {}
    MK.ModelStamp = {}
    MK.ModelPull = {}
    TradableList()
    RefreshAll(true, true)
end)

hook.Add("PlayerSay", "hg.Market.ChatCommand", function(ply, text)
    local command = string.lower(string.Trim(tostring(text or "")))

    if CFG.ChatCommands[command] then
        MK.OpenForPlayer(ply)
        return ""
    end
end)

hook.Add("PlayerInitialSpawn", "hg.Market.Join", function(ply)
    timer.Simple(8, function()
        if not IsValid(ply) then return end

        SyncBase()
        ClaimGrants()
        ReconcileFor(SteamOf(ply))
        RefreshPlayers(function()
            if IsValid(ply) then RefreshAppearance(ply) end
        end, true)
        ClaimPayouts(ply)
    end)

    timer.Simple(30, function()
        if not IsValid(ply) then return end

        ClaimPayouts(ply)
        ClaimGrants()
        ReconcileFor(SteamOf(ply))
        RefreshPlayers(function()
            if IsValid(ply) then RefreshAppearance(ply) end
        end, true)
    end)
end)

hook.Add("PlayerDisconnected", "hg.Market.Leave", function(ply)
    local sid = SteamOf(ply)
    if sid == "" then return end

    MK.Viewers[sid] = nil
    MK.Cooldowns[sid] = nil
    MK.History[sid] = nil
    MK.Owned[sid] = nil
    MK.Escrow[sid] = nil
    MK.Revoked[sid] = nil
    MK.Loaded[sid] = nil
    MK.SellCache[sid] = nil
    MK.NextPush[sid] = nil
    MK.Signature[sid] = nil
    MK.Models[sid] = nil
    MK.ModelStamp[sid] = nil
    MK.ModelPull[sid] = nil
end)

hook.Add("InitPostEntity", "hg.Market.Overrides", function()
    SyncBase()

    timer.Simple(10, function()
        TradableCache = nil
        TradableList()
    end)

    timer.Simple(25, PurgeBlacklisted)
end)

SyncBase()

timer.Create("hg.Market.Overrides", 30, 0, SyncBase)

timer.Create("hg.Market.Grants", 5, 0, ClaimGrants)

timer.Create("hg.Market.Poll", math.max(2, tonumber(CFG.PollInterval) or 3), 0, function()
    if not Ready then return end
    if table.IsEmpty(MK.Viewers) and player.GetCount() <= 0 then return end

    PullRevision(false)
end)

timer.Create("hg.Market.Listings", math.max(15, tonumber(CFG.ListingsInterval) or 30), 0, function()
    if not Ready then return end
    if table.IsEmpty(MK.Viewers) then return end

    RefreshAll(true)
end)

timer.Create("hg.Market.Stats", math.max(60, tonumber(CFG.StatsInterval) or 120), 0, function()
    if not Ready then return end

    RefreshStats(function()
        if not table.IsEmpty(MK.Viewers) then PushViewers() end
    end)
end)

timer.Create("hg.Market.Expire", math.max(120, tonumber(CFG.ExpireInterval) or 600), 0, function()
    if not Ready then return end

    ExpireSweep()
end)

timer.Create("hg.Market.Payouts", math.max(30, tonumber(CFG.PayoutInterval) or 60), 0, function()
    if not Ready then return end

    for _, ply in ipairs(player.GetAll()) do
        ClaimPayouts(ply)
    end
end)

timer.Create("hg.Market.Reconcile", 180, 0, function()
    if not Ready then return end

    ReconcileAll()
end)

timer.Create("hg.Market.KeepAlive", 120, 0, KeepAlive)

timer.Create("hg.Market.Panel", math.max(30, tonumber(MK.Panel.snapshotEvery) or 120), 0, function()
    if not Ready then return end

    MK.PanelSnapshot()
end)

timer.Simple(20, function()
    MK.PanelBacklog()
    MK.PanelSnapshot()
end)

concommand.Add("hg_market_panel_push", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    MK.PanelDiag()
    MK.PanelBacklog()
    MK.PanelSnapshot()

    Log("panel push forced")
end)

concommand.Add("hg_market_panel_diag", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    MK.PanelDiag()

    MK.PanelPost("push_market_event", {
        kind = "ping",
        listing = 0,
        uid = "",
        price = 0,
        seller = "",
        buyer = "",
        created = os.time(),
        event_key = "ping:" .. os.time()
    })
end)

timer.Simple(2, Connect)
