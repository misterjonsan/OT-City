if CLIENT then return end

HG = HG or {}
HG.Cases = HG.Cases or {}

local Cases = HG.Cases

Cases.Rarities = {
    common = {name = "COMMON", color = Color(150, 178, 200), chance = 46},
    uncommon = {name = "UNCOMMON", color = Color(90, 210, 255), chance = 28},
    rare = {name = "RARE", color = Color(31, 182, 255), chance = 15},
    epic = {name = "EPIC", color = Color(168, 132, 255), chance = 8},
    legendary = {name = "LEGENDARY", color = Color(255, 190, 75), chance = 3}
}

local RARITY_ORDER = {common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5}
local function RarityRank(key) return RARITY_ORDER[key] or 1 end
local function IsGoodRarity(key) return RarityRank(key) >= 4 end

Cases.Economy = Cases.Economy or {
    default = {targetMargin = 0.12, hardFloorMargin = 0.02, maxPayoutMult = 30, generosityCap = 1.3, stinginessFloor = 0.10},
    otcoin = {targetMargin = 0.12, hardFloorMargin = 0.02, maxPayoutMult = 30, generosityCap = 1.3, stinginessFloor = 0.10},
    rub = {targetMargin = 0.09, hardFloorMargin = 0.0, maxPayoutMult = 45, generosityCap = 1.55, stinginessFloor = 0.16}
}

local function EconomyFor(currency)
    return Cases.Economy[currency] or Cases.Economy.default
end

Cases.Luck = Cases.Luck or {
    softStart = 8,
    hardPity = 35,
    lull = 0,
    maxLuck = 0.9
}

Cases.Crowd = Cases.Crowd or {
    perOpen = 1.0,
    threshold = 90,
    firstSpinBias = 0.7,
    decayPerMin = 2
}

Cases.AllowStaffRankDrops = Cases.AllowStaffRankDrops == true

Cases.Duplicates = Cases.Duplicates or {
    fraction = {otcoin = 0.60, rub = 0.75},
    minimum = {otcoin = 150, rub = 30}
}

Cases.RankPity = Cases.RankPity or {
    vip = {softStart = 20, hardPity = 150, maxBoost = 9},
    sponsor = {softStart = 90, hardPity = 520, maxBoost = 20},
    operator = {softStart = 80, hardPity = 400, maxBoost = 36},
    moderator = {softStart = 120, hardPity = 620, maxBoost = 20}
}

Cases.Personal = Cases.Personal or {
    minSpend = {otcoin = 4000, rub = 900},
    coinFloor = 0.35,
    coinCap = 1.2,
    balanceSoft = 14,
    balanceHard = 34,
    coinSink = 0.65,
    itemPush = 1.6
}

Cases.Panel = Cases.Panel or {
    enabled = true,
    url = "",
    token = "",
    serverId = "",
    serverName = "",
    snapshotEvery = 30,
    forecastDepth = 10,
    includeForecast = false
}

local STATE_FILE = "hg_cases_state.txt"

local function PanelServerId()
    local configured = string.Trim(tostring(Cases.Panel.serverId or ""))
    if configured ~= "" and configured ~= "auto" then return configured end
    local address = game.GetIPAddress and tostring(game.GetIPAddress() or "") or ""
    address = string.lower(string.gsub(address, "[^%w]+", "_"))
    if address ~= "" and address ~= "0_0_0_0_0" then return "otcity_" .. address end
    return "otcity_shared"
end

local function PanelServerName()
    local configured = string.Trim(tostring(Cases.Panel.serverName or ""))
    if configured ~= "" then return configured end
    local hostname = GetConVar("hostname")
    local value = hostname and string.Trim(hostname:GetString() or "") or ""
    return value ~= "" and value or PanelServerId()
end

Cases.State = Cases.State or {
    players = {},
    ledger = {},
    crowd = {pressure = 0, armed = false, totalOpens = 0, lastDecay = 0},
    rankGrants = {},
    seed = math.random(1, 2147483000)
}
Cases.LeadershipSteamIds = Cases.LeadershipSteamIds or {}

local function PruneState()
    local now = os.time()
    for sid, pstate in pairs(Cases.State.players or {}) do
        local lastAt = tonumber(istable(pstate) and pstate.lastAt or 0) or 0
        if lastAt > 0 and now - lastAt > 7776000 then Cases.State.players[sid] = nil end
    end
    for sid, grants in pairs(Cases.State.rankGrants or {}) do
        if istable(grants) then
            local kept = {}
            for _, grant in ipairs(grants) do
                local ts = tonumber(grant.ts) or 0
                local duration = tonumber(grant.duration) or 0
                if ts > 0 and duration > 0 and ts + duration > now then kept[#kept + 1] = grant end
            end
            Cases.State.rankGrants[sid] = #kept > 0 and kept or nil
        else
            Cases.State.rankGrants[sid] = nil
        end
    end
end

local function SaveState()
    PruneState()
    local ok, encoded = pcall(util.TableToJSON, Cases.State)
    if ok and encoded then file.Write(STATE_FILE, encoded) end
end

local stateSaveQueued = false
local function QueueStateSave()
    if stateSaveQueued then return end
    stateSaveQueued = true
    timer.Simple(15, function()
        stateSaveQueued = false
        SaveState()
    end)
end

do
    local raw = file.Read(STATE_FILE, "DATA")
    if raw and raw ~= "" then
        local ok, decoded = pcall(util.JSONToTable, raw)
        if ok and istable(decoded) then
            Cases.State.players = istable(decoded.players) and decoded.players or {}
            Cases.State.ledger = istable(decoded.ledger) and decoded.ledger or {}
            Cases.State.crowd = istable(decoded.crowd) and decoded.crowd or Cases.State.crowd
            Cases.State.rankGrants = istable(decoded.rankGrants) and decoded.rankGrants or Cases.State.rankGrants
            Cases.State.seed = tonumber(decoded.seed) or Cases.State.seed
            Cases.LeadershipSteamIds = istable(decoded.leadershipSteamIds) and decoded.leadershipSteamIds or Cases.LeadershipSteamIds
            for _, pstate in pairs(Cases.State.players) do
                if istable(pstate) then pstate.reserved = nil end
            end
        end
    end
end

local function PlayerState(sid)
    local p = Cases.State.players[sid]
    if not p then
        p = {opens = 0, sinceGood = 999, lastRarity = "common", spent = {}, won = {}, lastCase = "", lastAt = 0, nick = "", seed = math.random(1, 2147483000)}
        Cases.State.players[sid] = p
    end
    p.spent = p.spent or {}
    p.won = p.won or {}
    p.rankOpens = istable(p.rankOpens) and p.rankOpens or {}
    p.reserved = istable(p.reserved) and p.reserved or {}
    if (tonumber(p.opens) or 0) <= 0 then p.sinceGood = 0 end
    p.sinceGood = math.max(0, math.floor(tonumber(p.sinceGood) or 0))
    p.rollNonce = math.max(0, math.floor(tonumber(p.rollNonce) or 0))
    return p
end

local function IsExcludedFromEconomy(sid)
    return Cases.LeadershipSteamIds[tostring(sid or '')] == true
end

local function Ledger(currency)
    local l = Cases.State.ledger[currency]
    if not l then
        l = {inValue = 0, outValue = 0, opens = 0}
        Cases.State.ledger[currency] = l
    end
    return l
end

local COIN_ICON = "monteract/case/coin.png"
local RUB_ICON = "monteract/case/money.png"

local function OTCoin(amount, rarity)
    return {id = "otcoin_" .. amount, kind = "otcoin", amount = amount, name = string.Comma(amount), subtitle = "OT-Coin", rarity = rarity, material = COIN_ICON}
end

local function Rub(amount, rarity)
    return {id = "rub_" .. amount, kind = "rub", amount = amount, name = string.Comma(amount), subtitle = "Рубли", rarity = rarity, material = RUB_ICON}
end

local function RarityForAccessory(d)
    if d.uid == "exojump" or d.donateOnly == true then return "legendary" end
    if d.isvip == true then return "epic" end
    local p = tonumber(d.coinPrice) or 0
    if p >= 2600 then return "rare" end
    if p >= 1100 then return "uncommon" end
    return "common"
end

local function AccessoryReward(uid)
    local d = hg and hg.Accessories and hg.Accessories[uid]
    if not istable(d) or uid == "none" then return nil end
    local model = string.Trim(tostring(d.model or ""))
    if model == "" then return nil end
    if util.IsValidModel and not util.IsValidModel(model) then return nil end
    local sub = d.donateOnly and "Донат-аксессуар" or (d.isvip and "VIP-аксессуар" or "Аксессуар")
    return {
        id = "acc_" .. uid, kind = "accessory", accId = uid,
        name = tostring(d.name or uid), subtitle = sub,
        rarity = RarityForAccessory(d), model = model, amount = 0,
        coinPrice = tonumber(d.coinPrice) or 0
    }
end

local DonateRankIcons = {
    vip = "https://monteract.ru/img/don2/vip.png",
    moderator = "https://monteract.ru/img/don2/dmod.png",
    dmod = "https://monteract.ru/img/don2/dmod.png",
    operator = "https://monteract.ru/img/don2/oper.png",
    sponsor = "https://monteract.ru/img/don2/sponsor.png",
    ss = "https://monteract.ru/img/don2/ss.png",
    rtv = "https://monteract.ru/img/don2/rtv.png"
}

local function RankReward(group, days, title, rarity, weightScale)
    local key = string.lower(tostring(group or ""))
    return {
        id = "rank_" .. group .. "_" .. days, kind = "rank",
        rankGroup = group, rankDuration = days * 86400,
        name = title, subtitle = "Привилегия • " .. days .. " дн.",
        rarity = rarity, material = DonateRankIcons[key] or "monteract/cases/vip.png", amount = 0,
        days = days, weightScale = weightScale
    }
end

local function AutoWeight(rewards, rarityScale)
    local cnt = {}
    for _, r in ipairs(rewards) do cnt[r.rarity] = (cnt[r.rarity] or 0) + 1 end
    for _, r in ipairs(rewards) do
        local rc = Cases.Rarities[r.rarity] and Cases.Rarities[r.rarity].chance or 1
        local scale = istable(rarityScale) and tonumber(rarityScale[r.rarity]) or 1
        r.weight = rc / math.max(1, cnt[r.rarity] or 1) * math.max(0, tonumber(r.weightScale) or 1) * math.max(0, scale)
    end
    return rewards
end

local CrownMarks = {"корон", "crown"}
local KillaMarks = {"килл", "killa", "kila"}
local HelmetMarks = {"шлем", "шлём", "helmet", "helm", "каск"}

local function HasMark(key, marks)
    for _, mark in ipairs(marks) do
        if string.find(key, mark, 1, true) then return true end
    end
    return false
end

local function IsLegendaryDonateAcc(key)
    if HasMark(key, CrownMarks) then return true end
    return HasMark(key, KillaMarks) and HasMark(key, HelmetMarks)
end

local Specs = {
    {
        id = "prospector", name = "СТАРАТЕЛЬ", title = "СУНДУК СТАРАТЕЛЯ",
        description = "С него начинают все. Простой кейс за OT-Coin с широким разбросом выплат: небольшая, но стабильная прибавка к балансу, чтобы раскрутиться и накопить на что-то посерьёзнее.",
        price = 250, currency = "otcoin", accent = Color(31, 182, 255), material = "monteract/case/3.png",
        fillers = {OTCoin(35, "common"), OTCoin(60, "common"), OTCoin(90, "common"), OTCoin(120, "uncommon"), OTCoin(160, "uncommon"), OTCoin(220, "uncommon"), OTCoin(300, "rare"), OTCoin(420, "rare"), OTCoin(520, "epic"), OTCoin(700, "epic"), OTCoin(2200, "legendary"), OTCoin(4500, "legendary")}
    },
    {
        id = "diamond", name = "АЛМАЗНЫЙ РЕЗЕРВ", title = "АЛМАЗНЫЙ РЕЗЕРВ",
        description = "Тяжёлая артиллерия среди монетных кейсов. Самые крупные выплаты OT-Coin на сервере, а в награду может залететь и VIP-привилегия.",
        price = 1000, currency = "otcoin", accent = Color(90, 210, 255), material = "monteract/case/2.png",
        fillers = {OTCoin(160, "common"), OTCoin(260, "common"), OTCoin(380, "common"), OTCoin(480, "uncommon"), OTCoin(680, "uncommon"), OTCoin(900, "uncommon"), OTCoin(1150, "rare"), OTCoin(1650, "rare"), OTCoin(2000, "epic"), OTCoin(2800, "epic"), OTCoin(11000, "legendary"), OTCoin(22000, "legendary")},
        extras = {RankReward("vip", 30, "VIP на месяц", "epic"), RankReward("operator", 30, "Оператор на месяц", "legendary", 0.24)}
    },
    {
        id = "arsenal", name = "АРСЕНАЛ", title = "АРСЕНАЛ НАЛЁТЧИКА",
        description = "Головная экипировка налётчика: маски-шлемы, каски, капюшоны и всё, что надевается на голову и корпус. Плюс монеты на сдачу и шанс на VIP. Выпавший аксессуар можно носить даже без VIP-статуса.",
        price = 450, currency = "otcoin", accent = Color(127, 230, 255), material = "monteract/case/6.png",
        fillers = {OTCoin(70, "common"), OTCoin(110, "common"), OTCoin(150, "common"), OTCoin(230, "uncommon"), OTCoin(320, "uncommon"), OTCoin(520, "rare"), OTCoin(720, "rare"), OTCoin(3500, "legendary"), OTCoin(6500, "legendary")},
        accsFilter = function(d) return d.donateOnly ~= true and (d.placement == "head" or d.placement == "torso") and d.model ~= nil and d.model ~= "" end,
        extras = {RankReward("vip", 30, "VIP на месяц", "epic")}
    },
    {
        id = "masks", name = "МАСКАРАД", title = "ЛИЧИНЫ И МАСКИ",
        description = "Всё для лица и спины: маски, банданы, наушники, очки и спинное снаряжение. Богатый набор аксессуаров за OT-Coin с монетами на сдачу и шансом на VIP.",
        price = 400, currency = "otcoin", accent = Color(60, 200, 255), material = "monteract/case/4.png",
        fillers = {OTCoin(60, "common"), OTCoin(90, "common"), OTCoin(130, "common"), OTCoin(200, "uncommon"), OTCoin(290, "uncommon"), OTCoin(460, "rare"), OTCoin(640, "rare"), OTCoin(3000, "legendary"), OTCoin(6000, "legendary")},
        accsFilter = function(d) return d.donateOnly ~= true and (d.placement == "face" or d.placement == "bandanes" or d.placement == "headpones" or d.placement == "spine" or d.placement == nil or d.placement == "") and d.model ~= nil and d.model ~= "" end,
        extras = {RankReward("vip", 30, "VIP на месяц", "epic")}
    },
    {
        id = "jackpot", name = "ДЖЕКПОТ", title = "ДЖЕКПОТ",
        description = "Самый жирный рублёвый кейс. Внутри живой донат-баланс в рублях, который можно потратить на любой донат — один удачный прокрут закрывает целую покупку.",
        price = 249, currency = "rub", accent = Color(255, 190, 75), material = "monteract/case/5.png",
        fillers = {Rub(45, "common"), Rub(75, "common"), Rub(105, "common"), Rub(150, "uncommon"), Rub(210, "uncommon"), Rub(280, "uncommon"), Rub(320, "rare"), Rub(450, "rare"), Rub(750, "epic"), Rub(1080, "epic"), Rub(2200, "legendary"), Rub(4500, "legendary")},
        rarityScale = {common = 0.92, uncommon = 0.98, rare = 1.18, epic = 1.28, legendary = 1.2},
        extras = {RankReward("operator", 30, "Оператор на месяц", "legendary", 0.14)}
    },
    {
        id = "legends", name = "ЛЕГЕНДЫ", title = "ЛОГОВО ЛЕГЕНД",
        description = "Самое жирное, что есть на сервере. Донат-эксклюзивные ��ксессуары боссов, Экзо-Ботинки и полный набор привилегий — VIP и Спонсор. Выпадает редко, но заберёшь то, что обычно покупают за реал.",
        price = 349, currency = "rub", accent = Color(255, 205, 110), material = "monteract/case/1.png",
        fillers = {Rub(120, "common"), Rub(170, "common"), Rub(230, "common"), Rub(300, "uncommon"), Rub(400, "uncommon"), Rub(620, "rare"), Rub(880, "rare")},
        accsFilter = function(d) return d.donateOnly == true end,
        accsRarity = function(d, uid)
            local key = string.lower(tostring(uid or "") .. " " .. tostring(d.name or ""))
            if IsLegendaryDonateAcc(key) then return "legendary" end
            return "epic"
        end,
        rarityScale = {common = 0.92, uncommon = 0.98, rare = 1.18, epic = 1.28, legendary = 1.2},
        extras = {
            RankReward("vip", 30, "VIP на месяц", "epic"),
            RankReward("vip", 90, "VIP на сезон", "legendary"),
            RankReward("sponsor", 30, "Спонсор на месяц", "legendary"),
            RankReward("sponsor", 90, "Спонсор на сезон", "legendary"),
            RankReward("operator", 30, "Оператор на месяц", "legendary", 0.11),
            RankReward("operator", 90, "Оператор на сезон", "legendary", 0.045)
        },
        staffExtras = {
            RankReward("moderator", 30, "Модератор на месяц", "legendary", 0.02)
        }
    }
}

Cases.Config = {}
local built = false

local function BuildCase(spec)
    local case = {
        id = spec.id, name = spec.name, title = spec.title, description = spec.description,
        price = spec.price, currency = spec.currency, accent = spec.accent, material = spec.material,
        rewards = {}
    }
    local seen = {}
    local function add(r)
        if not istable(r) then return end
        if r.id and seen[r.id] then return end
        if r.id then seen[r.id] = true end
        case.rewards[#case.rewards + 1] = r
    end
    for _, r in ipairs(spec.fillers or {}) do add(r) end
    if isfunction(spec.accsFilter) and hg and istable(hg.Accessories) then
        for uid, d in pairs(hg.Accessories) do
            if istable(d) then
                local ok = false
                local okf, res = pcall(spec.accsFilter, d)
                if okf then ok = res == true end
                if ok then
                    local reward = AccessoryReward(uid)
                    if istable(reward) and isfunction(spec.accsRarity) then
                        local okr, res = pcall(spec.accsRarity, d, uid)
                        if okr and Cases.Rarities[res] then reward.rarity = res end
                    end
                    add(reward)
                end
            end
        end
    end
    for _, r in ipairs(spec.extras or {}) do add(r) end
    if Cases.AllowStaffRankDrops then
        for _, r in ipairs(spec.staffExtras or {}) do add(r) end
    end
    AutoWeight(case.rewards, spec.rarityScale)
    case.rankGroups = {}
    for _, r in ipairs(case.rewards) do
        if r.kind == "rank" then
            local group = string.lower(tostring(r.rankGroup or ""))
            if group ~= "" then case.rankGroups[group] = true end
        end
    end
    return case
end

local function EnsureBuilt()
    if built then return end
    if not (hg and istable(hg.Accessories)) then return end
    Cases.Config = {}
    for _, spec in ipairs(Specs) do
        Cases.Config[spec.id] = BuildCase(spec)
    end
    built = true
end
EnsureBuilt()
timer.Simple(2, EnsureBuilt)
timer.Simple(8, EnsureBuilt)

local function GetOTCoinKey()
    local AP = _G.hg and _G.hg.Appearance
    if AP and AP.OTCoin and tostring(AP.OTCoin.BalanceKey or "") ~= "" then return tostring(AP.OTCoin.BalanceKey) end
    return "hg_otcoins_balance"
end

local function GetOTCoins(ply)
    if not IsValid(ply) then return 0 end
    if OTCDonate and isfunction(OTCDonate.GetOTCoins) then
        local ok, value = pcall(OTCDonate.GetOTCoins, ply)
        if ok and tonumber(value) then return math.max(0, math.floor(tonumber(value))) end
    end
    local AP = _G.hg and _G.hg.Appearance
    if AP and isfunction(AP.GetOTCoinBalance) then
        local ok, value = pcall(AP.GetOTCoinBalance, ply)
        if ok and tonumber(value) then return math.max(0, math.floor(tonumber(value))) end
    end
    if isfunction(ply.GetMData) then
        return math.max(0, math.floor(tonumber(ply:GetMData(GetOTCoinKey(), 0)) or 0))
    end
    return 0
end

local function SpendOTCoins(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not IsValid(ply) then return false end
    if OTCDonate and isfunction(OTCDonate.TrySpendOTCoins) then
        local ok, success, balance = pcall(OTCDonate.TrySpendOTCoins, ply, amount)
        if ok then return success == true, balance end
        return false
    end
    if not isfunction(ply.GetMData) or not isfunction(ply.SetMData) then return false end
    local balance = GetOTCoins(ply)
    if balance < amount then return false end
    ply:SetMData(GetOTCoinKey(), balance - amount)
    return true, balance - amount
end

local function GetRub(ply)
    if not IsValid(ply) then return 0 end
    if OTCDonate and isfunction(OTCDonate.GetBalance) then
        local ok, value = pcall(OTCDonate.GetBalance, ply)
        if ok and tonumber(value) then return math.max(0, math.floor(tonumber(value))) end
    end
    return math.max(0, math.floor(tonumber(ply.OTC_DonateBalance) or 0))
end

local function GiveRub(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return true end
    if OTCDonate and isfunction(OTCDonate.AddBalance) then
        local ok = pcall(OTCDonate.AddBalance, ply, amount)
        if ok then return true end
    end
    if OTCDonate and isfunction(OTCDonate.GiveBalance) then
        local ok = pcall(OTCDonate.GiveBalance, ply, amount)
        if ok then return true end
    end
    ply.OTC_DonateBalance = math.max(0, math.floor(tonumber(ply.OTC_DonateBalance) or 0)) + amount
    return true
end

local function GiveOTCoins(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not IsValid(ply) or amount <= 0 then return false end
    if OTCDonate and isfunction(OTCDonate.AddOTCoins) then
        local ok = pcall(OTCDonate.AddOTCoins, ply, amount)
        if ok then return true end
    end
    if isfunction(ply.GetMData) and isfunction(ply.SetMData) then
        ply:SetMData(GetOTCoinKey(), GetOTCoins(ply) + amount)
        return true
    end
    return false
end

local function RecordCaseRankGrant(ply, reward)
    if not IsValid(ply) or not istable(reward) or tostring(reward.kind or "") ~= "rank" then return end
    local sid64 = tostring(ply:SteamID64() or "")
    local rank = string.lower(string.Trim(tostring(reward.rankGroup or "")))
    local duration = math.max(0, math.floor(tonumber(reward.rankDuration) or 0))
    if not sid64:match("^%d+$") or #sid64 < 16 or #sid64 > 20 then return end
    if rank == "" or duration <= 0 or duration > 90 * 86400 then return end
    Cases.State.rankGrants = istable(Cases.State.rankGrants) and Cases.State.rankGrants or {}
    local grants = istable(Cases.State.rankGrants[sid64]) and Cases.State.rankGrants[sid64] or {}
    local now = os.time()
    grants[#grants + 1] = {
        id = "case_rank_" .. sid64 .. "_" .. rank .. "_" .. tostring(now) .. "_" .. tostring(math.random(100000, 999999)),
        rank = rank,
        duration = duration,
        ts = now
    }
    Cases.State.rankGrants[sid64] = grants
    QueueStateSave()
end

Cases.GetRankEntitlements = function(sid64)
    sid64 = tostring(sid64 or "")
    local grants = Cases.State.rankGrants and Cases.State.rankGrants[sid64]
    if not istable(grants) then return {} end
    local out = {}
    for _, grant in ipairs(grants) do
        local rank = string.lower(string.Trim(tostring(grant.rank or "")))
        local duration = math.max(0, math.floor(tonumber(grant.duration) or 0))
        local ts = math.max(0, math.floor(tonumber(grant.ts) or 0))
        if rank ~= "" and duration > 0 and duration <= 90 * 86400 and ts > 0 and ts <= os.time() + 300 then
            out[#out + 1] = {id = tostring(grant.id or ""), rank = rank, duration = duration, ts = ts, source = "hg_cases"}
        end
    end
    return out
end

Cases.GetRankGrantSteamIDs = function()
    local out = {}
    for sid64, grants in pairs(Cases.State.rankGrants or {}) do
        if tostring(sid64):match("^%d+$") and #tostring(sid64) >= 16 and #tostring(sid64) <= 20 and istable(grants) and #grants > 0 then
            out[#out + 1] = tostring(sid64)
        end
    end
    return out
end

local function GiveReward(ply, reward)
    if not IsValid(ply) then return false end
    local handled = hook.Run("HG.Cases.GiveReward", ply, reward)
    if handled ~= nil then
        local delivered = handled ~= false
        if delivered and reward.kind == "rank" then RecordCaseRankGrant(ply, reward) end
        return delivered
    end
    if reward.kind == "otcoin" then return GiveOTCoins(ply, reward.amount) end
    if reward.kind == "rub" then return GiveRub(ply, reward.amount) end
    if reward.kind == "accessory" or reward.kind == "rank" then return true end
    return true
end

local function OwnsAccessory(ply, reward)
    if reward.kind ~= "accessory" then return false end
    local uid = tostring(reward.accId or "")
    if uid == "" then return false end
    local acc = (hg and hg.Accessories) and hg.Accessories[uid] or nil
    if istable(acc) and acc.donateOnly ~= true then
        if isfunction(_G.RK_HasCoinAccessory) and (tonumber(acc.coinPrice) or 0) > 0 then
            local ok, res = pcall(_G.RK_HasCoinAccessory, ply, uid)
            if ok and res == true then return true end
        end
        return false
    end
    if OTCDonate and isfunction(OTCDonate.HasAccessory) then
        local ok, res = pcall(OTCDonate.HasAccessory, ply, uid)
        if ok and res == true then return true end
    end
    if isfunction(_G.RK_HasDonateAccessory) then
        local ok, res = pcall(_G.RK_HasDonateAccessory, ply, uid)
        if ok and res == true then return true end
    end
    return false
end

local RANK_VALUE = {
    vip = {[30] = 150, [90] = 350},
    sponsor = {[30] = 300, [90] = 700},
    moderator = {[30] = 549, [90] = 1299}, operator = {[30] = 899, [90] = 1999}
}

local RANK_LEVEL = {user = 0, vip = 1, moderator = 2, operator = 3, sponsor = 4}

local function OwnsRank(ply, reward)
    if reward.kind ~= "rank" or not IsValid(ply) or not isfunction(ply.GetUserGroup) then return false end
    local current = string.lower(tostring(ply:GetUserGroup() or "user"))
    local wanted = string.lower(tostring(reward.rankGroup or ""))
    if wanted == "" then return false end
    if current == wanted then return true end
    if current ~= "" and current ~= "user" and RANK_LEVEL[current] == nil then return true end
    return (RANK_LEVEL[current] or 0) >= (RANK_LEVEL[wanted] or math.huge)
end

local function HasActiveCaseRankGrant(ply, group)
    if not IsValid(ply) then return false end
    local sid64 = tostring(ply:SteamID64() or "")
    local grants = Cases.State.rankGrants and Cases.State.rankGrants[sid64]
    if not istable(grants) then return false end
    local now = os.time()
    for _, grant in ipairs(grants) do
        if string.lower(tostring(grant.rank or "")) == group then
            local ts = math.max(0, tonumber(grant.ts) or 0)
            local duration = math.max(0, tonumber(grant.duration) or 0)
            if ts > 0 and duration > 0 and ts + duration > now then return true end
        end
    end
    return false
end

local function RankAlreadyHeld(ply, reward)
    if reward.kind ~= "rank" then return false end
    local group = string.lower(tostring(reward.rankGroup or ""))
    if group == "" then return true end
    if OwnsRank(ply, reward) then return true end
    return HasActiveCaseRankGrant(ply, group)
end

local function DuplicateKey(reward)
    if reward.kind == "accessory" then return "accessory:" .. tostring(reward.accId or reward.id or "") end
    if reward.kind == "rank" then return "rank:" .. tostring(reward.rankGroup or reward.id or "") end
    return nil
end

local function IsDuplicateReward(ply, reward, claimed)
    local key = DuplicateKey(reward)
    if not key then return false end
    if claimed and claimed[key] then return true end
    if reward.kind == "accessory" then return OwnsAccessory(ply, reward) end
    if reward.kind == "rank" then return OwnsRank(ply, reward) end
    return false
end

local function NominalValue(reward, currency)
    if reward.kind == "otcoin" or reward.kind == "rub" then
        return math.max(0, tonumber(reward.amount) or 0)
    end
    if reward.kind == "rank" then
        local byGroup = RANK_VALUE[reward.rankGroup or ""]
        local v = byGroup and (tonumber(byGroup[reward.days or 0]) or 0) or 0
        if v <= 0 then v = 300 end
        return currency == "rub" and v or v * 10
    end
    if reward.kind == "accessory" then
        local price = tonumber(reward.coinPrice) or 0
        if price <= 0 then price = 3500 end
        return currency == "rub" and math.max(1, math.floor(price / 10)) or price
    end
    return 0
end

local function DuplicateCompensation(reward, currency)
    local value = NominalValue(reward, currency)
    local fraction = tonumber(Cases.Duplicates.fraction[currency]) or 0.6
    local minimum = tonumber(Cases.Duplicates.minimum[currency]) or 1
    return math.max(minimum, math.floor(value * fraction))
end

local function GiveCurrency(ply, currency, amount)
    if currency == "rub" then return GiveRub(ply, amount) end
    return GiveOTCoins(ply, amount)
end

local function SettledReward(ply, currency, reward, claimed)
    local duplicate = IsDuplicateReward(ply, reward, claimed)
    local settled = {}
    for key, value in pairs(reward) do settled[key] = value end
    if duplicate then
        settled.duplicate = true
        settled.compensation = DuplicateCompensation(reward, currency)
        settled.compensationCurrency = currency
        settled.originalKind = reward.kind
        return settled, GiveCurrency(ply, currency, settled.compensation)
    end
    local delivered = GiveReward(ply, reward)
    local key = DuplicateKey(reward)
    if delivered and key and claimed then claimed[key] = true end
    return settled, delivered
end

local function RewardValue(reward, currency)
    if reward.duplicate == true and tonumber(reward.compensation) then
        return math.max(0, math.floor(tonumber(reward.compensation) or 0))
    end
    return NominalValue(reward, currency)
end

local function CurrentMargin(currency, ledger)
    local l = ledger or Ledger(currency)
    if l.inValue <= 0 then return EconomyFor(currency).targetMargin end
    return 1 - (l.outValue / l.inValue)
end

local function GenerosityFactor(currency, ledger)
    local margin = CurrentMargin(currency, ledger)
    local eco = EconomyFor(currency)
    if margin <= eco.hardFloorMargin then return eco.stinginessFloor end
    if margin >= eco.targetMargin then
        local extra = math.min(1, (margin - eco.targetMargin) / math.max(0.01, 1 - eco.targetMargin))
        return Lerp(extra, 1, eco.generosityCap)
    end
    local t = (margin - eco.hardFloorMargin) / math.max(0.01, eco.targetMargin - eco.hardFloorMargin)
    return Lerp(t, eco.stinginessFloor, 1)
end

local function MakeRNG(seed)
    local s = math.floor(math.abs(seed)) % 2147483647
    if s == 0 then s = 12345 end
    return function()
        s = (s * 1103515245 + 12345) % 2147483648
        return s / 2147483648
    end
end

local function HashSeed(a, b, c)
    local h = 2166136261
    local str = tostring(a) .. "|" .. tostring(b) .. "|" .. tostring(c)
    for i = 1, #str do
        h = bit.bxor(h, string.byte(str, i))
        h = (h * 16777619) % 2147483648
    end
    return h
end

local function PersonalLuck(pstate)
    local L = Cases.Luck
    if pstate.sinceGood <= Cases.Luck.lull then return 0 end
    local over = pstate.sinceGood - L.softStart
    if over <= 0 then return 0 end
    local span = math.max(1, L.hardPity - L.softStart)
    return math.Clamp(over / span, 0, L.maxLuck) * L.maxLuck
end

local function CrowdLuck(crowdState)
    local crowd = crowdState or Cases.State.crowd
    return math.Clamp((tonumber(crowd.pressure) or 0) / Cases.Crowd.threshold, 0, 1)
end

local function LuckForSpin(pstate, isFirstSpin, crowdState)
    local personal = PersonalLuck(pstate)
    local crowd = CrowdLuck(crowdState)
    local firstBonus = isFirstSpin and (crowd * Cases.Crowd.firstSpinBias) or 0
    return math.Clamp(personal * 0.65 + crowd * 0.2 + firstBonus, 0, 0.95)
end

local function RarityBoost(rarity, luck, generosity)
    local rank = RarityRank(rarity)
    if rank <= 1 then return 1 - luck * 0.55 end
    if rank == 2 then return 1 + luck * 0.25 end
    if rank == 3 then return 1 + luck * 1.1 end
    if rank == 4 then return (1 + luck * 2.3) * generosity end
    return (1 + luck * 3.4) * generosity
end

local function WeightedPick(list, rng, keyFn)
    local total = 0
    for _, r in ipairs(list) do total = total + math.max(0, keyFn and keyFn(r) or (tonumber(r.weight) or 0)) end
    if total <= 0 then return list[1] end
    local roll = (rng and rng() or math.random()) * total
    local current = 0
    for _, r in ipairs(list) do
        current = current + math.max(0, keyFn and keyFn(r) or (tonumber(r.weight) or 0))
        if roll <= current then return r end
    end
    return list[#list]
end

local function PersonalScale(pstate, currency)
    local P = Cases.Personal
    local spent = math.max(0, tonumber(pstate.spent and pstate.spent[currency] or 0) or 0)
    local won = math.max(0, tonumber(pstate.won and pstate.won[currency] or 0) or 0)
    local minSpend = math.max(0, tonumber(P.minSpend[currency]) or 0)
    if spent <= 0 or spent < minSpend then return 1 end
    local target = math.max(0.05, 1 - EconomyFor(currency).targetMargin)
    local ratio = won / spent
    if ratio <= 0 then return P.coinCap end
    return math.Clamp(target / ratio, P.coinFloor, P.coinCap)
end

local function BalancePressure(balance, case)
    local P = Cases.Personal
    local price = math.max(1, tonumber(case.price) or 1)
    local soft = price * (tonumber(P.balanceSoft) or 14)
    local hard = price * (tonumber(P.balanceHard) or 34)
    balance = math.max(0, tonumber(balance) or 0)
    if balance <= soft then return 0 end
    return math.Clamp((balance - soft) / math.max(1, hard - soft), 0, 1)
end

local function RankPityState(case, pstate)
    local boosts, forced, forcedScore = {}, nil, 0
    for group in pairs(case.rankGroups or {}) do
        local cfg = Cases.RankPity[group]
        local seen = math.max(0, math.floor(tonumber(istable(pstate.rankOpens) and pstate.rankOpens[group] or 0) or 0))
        local boost = 1
        if cfg then
            local soft = math.max(0, tonumber(cfg.softStart) or 0)
            local hard = math.max(soft + 1, tonumber(cfg.hardPity) or (soft + 1))
            local maxBoost = math.max(1, tonumber(cfg.maxBoost) or 1)
            if seen >= hard then
                boost = maxBoost
                local score = seen / hard
                if score >= forcedScore then
                    forced = group
                    forcedScore = score
                end
            elseif seen > soft then
                local t = math.Clamp((seen - soft) / (hard - soft), 0, 1)
                boost = Lerp(math.pow(t, 1.35), 1, maxBoost)
            end
        end
        boosts[group] = boost
    end
    return boosts, forced
end

local function OutcomeWeight(case, r, ctx)
    local w = math.max(0, tonumber(r.weight) or 0)
    if w <= 0 then return 0 end
    w = w * RarityBoost(r.rarity, ctx.luck or 0, ctx.generosity or 1)
    if r.kind == "rank" then
        local group = string.lower(tostring(r.rankGroup or ""))
        local boost = ctx.rankBoost and tonumber(ctx.rankBoost[group]) or 1
        w = w * boost * (ctx.itemScale or 1)
    elseif r.kind == "accessory" then
        w = w * (ctx.itemScale or 1)
    elseif r.kind == "otcoin" or r.kind == "rub" then
        w = w * (ctx.coinScale or 1)
        local price = math.max(0, tonumber(case.price) or 0)
        if price > 0 and (tonumber(r.amount) or 0) > price then w = w * (ctx.bigCoinScale or 1) end
    end
    if RewardValue(r, case.currency) > (ctx.cap or math.huge) then w = w * 0.05 end
    return math.max(0, w)
end

local function ComputeOutcome(case, elig, ctx)
    if #elig == 0 then return nil end
    local rng = ctx.rng

    if ctx.forceRank then
        local pool = {}
        for _, r in ipairs(elig) do
            if r.kind == "rank" and string.lower(tostring(r.rankGroup or "")) == ctx.forceRank then pool[#pool + 1] = r end
        end
        if #pool > 0 then
            return WeightedPick(pool, rng, function(r) return math.max(0.001, tonumber(r.weight) or 0) end)
        end
    end

    if ctx.forceTop then
        local top = {}
        for _, r in ipairs(elig) do
            if IsGoodRarity(r.rarity) then top[#top + 1] = r end
        end
        if #top > 0 then
            local boosted = {
                luck = 1, generosity = ctx.generosity, rankBoost = ctx.rankBoost,
                itemScale = ctx.itemScale, coinScale = ctx.coinScale,
                bigCoinScale = ctx.bigCoinScale, cap = ctx.cap
            }
            return WeightedPick(top, rng, function(r) return OutcomeWeight(case, r, boosted) end)
        end
    end

    return WeightedPick(elig, rng, function(r) return OutcomeWeight(case, r, ctx) end)
end

local function BuildRollContext(case, pstate, luck, generosity, rng, balance, forceTop)
    local P = Cases.Personal
    local personal = PersonalScale(pstate, case.currency)
    local pressure = BalancePressure(balance, case)
    local rankBoost, forced = RankPityState(case, pstate)
    local overflow = math.max(0, 1 - personal)
    return {
        luck = luck,
        generosity = (generosity or 1) * math.Clamp(personal, 0.65, 1.1),
        rng = rng,
        forceTop = forceTop == true,
        forceRank = forced,
        rankBoost = rankBoost,
        cap = (tonumber(case.price) or 0) * EconomyFor(case.currency).maxPayoutMult,
        coinScale = math.max(0.15, personal * (1 - 0.35 * pressure)),
        bigCoinScale = math.max(0.1, 1 - (tonumber(P.coinSink) or 0.65) * pressure),
        itemScale = 1 + (tonumber(P.itemPush) or 1.6) * pressure + overflow * 0.9,
        pressure = pressure,
        personal = personal
    }
end

local function EligibleRewards(case, ply, blockedIds)
    local elig, fallback = {}, {}
    for _, r in ipairs(case.rewards) do
        if not (blockedIds and blockedIds[r.id]) then
            fallback[#fallback + 1] = r
            local skip = false
            if IsValid(ply) then
                if r.kind == "rank" then
                    skip = RankAlreadyHeld(ply, r)
                elseif r.kind == "accessory" then
                    skip = OwnsAccessory(ply, r)
                end
            end
            if not skip then elig[#elig + 1] = r end
        end
    end
    if #elig == 0 then return fallback end
    return elig
end

local function ApplyOutcomeToState(pstate, case, reward, affectsEconomy)
    local currency = case.currency
    pstate.opens = (pstate.opens or 0) + 1
    if affectsEconomy then Cases.State.crowd.totalOpens = (Cases.State.crowd.totalOpens or 0) + 1 end

    if IsGoodRarity(reward.rarity) then
        pstate.sinceGood = 0
    else
        pstate.sinceGood = (pstate.sinceGood or 0) + 1
    end
    pstate.lastRarity = reward.rarity

    pstate.rankOpens = istable(pstate.rankOpens) and pstate.rankOpens or {}
    for group in pairs(case.rankGroups or {}) do
        pstate.rankOpens[group] = math.max(0, math.floor(tonumber(pstate.rankOpens[group]) or 0)) + 1
    end
    if reward.kind == "rank" and reward.duplicate ~= true then
        local group = string.lower(tostring(reward.rankGroup or ""))
        if group ~= "" then pstate.rankOpens[group] = 0 end
    end

    local val = RewardValue(reward, currency)
    pstate.won[currency] = (pstate.won[currency] or 0) + val
    if affectsEconomy then
        local l = Ledger(currency)
        l.outValue = l.outValue + val
        l.opens = l.opens + 1
    end
end

local function ChargePlayer(pstate, currency, cost, affectsEconomy)
    pstate.spent[currency] = (pstate.spent[currency] or 0) + cost
    if affectsEconomy then
        local l = Ledger(currency)
        l.inValue = l.inValue + cost
    end
end

local function NextRollRNG(pstate, caseId)
    pstate.rollNonce = math.max(0, math.floor(tonumber(pstate.rollNonce) or 0)) + 1
    return MakeRNG(HashSeed(pstate.seed or 1, caseId, pstate.rollNonce))
end

local function FindCaseReward(case, rewardId)
    for _, reward in ipairs(case.rewards or {}) do
        if reward.id == rewardId then return reward end
    end
    return nil
end

local function BuildReservationQueue(case, ply, pstate, depth, affectsEconomy)
    local clone = {
        opens = pstate.opens or 0, sinceGood = pstate.sinceGood or 0,
        seed = pstate.seed or 1, rollNonce = pstate.rollNonce or 0,
        rankOpens = {}, spent = {}, won = {}
    }
    for group, seen in pairs(istable(pstate.rankOpens) and pstate.rankOpens or {}) do clone.rankOpens[group] = math.max(0, tonumber(seen) or 0) end
    for currency, value in pairs(istable(pstate.spent) and pstate.spent or {}) do clone.spent[currency] = math.max(0, tonumber(value) or 0) end
    for currency, value in pairs(istable(pstate.won) and pstate.won or {}) do clone.won[currency] = math.max(0, tonumber(value) or 0) end
    local simBalance = case.currency == "rub" and GetRub(ply) or GetOTCoins(ply)
    local liveLedger = Ledger(case.currency)
    local ledger = affectsEconomy and {inValue = liveLedger.inValue or 0, outValue = liveLedger.outValue or 0, opens = liveLedger.opens or 0} or {inValue = 100, outValue = 65, opens = 0}
    local crowd = affectsEconomy and {pressure = Cases.State.crowd.pressure or 0, armed = Cases.State.crowd.armed == true} or {pressure = 0, armed = false}
    local blockedIds, queue = {}, {}
    for _ = 1, depth do
        local elig = EligibleRewards(case, ply, blockedIds)
        if #elig == 0 then break end
        if affectsEconomy then ledger.inValue = ledger.inValue + (tonumber(case.price) or 0) end
        local isFirst = clone.opens == 0
        local luck = affectsEconomy and LuckForSpin(clone, isFirst, crowd) or PersonalLuck(clone)
        local generosity = affectsEconomy and GenerosityFactor(case.currency, ledger) or 1
        local rng = NextRollRNG(clone, case.id)
        local forceTop = clone.sinceGood >= Cases.Luck.hardPity
        local consumeCrowd = false
        if affectsEconomy and crowd.armed then
            if isFirst or clone.opens <= 3 or rng() < 0.35 then
                forceTop = true
                consumeCrowd = true
                crowd.armed = false
                crowd.pressure = math.max(0, crowd.pressure - Cases.Crowd.threshold)
            end
        end
        local price = math.max(0, tonumber(case.price) or 0)
        clone.spent[case.currency] = (clone.spent[case.currency] or 0) + price
        simBalance = math.max(0, simBalance - price)
        local ctx = BuildRollContext(case, clone, luck, generosity, rng, simBalance, forceTop)
        local reward = ComputeOutcome(case, elig, ctx)
        if not reward then break end
        queue[#queue + 1] = {
            id = reward.id, consumeCrowd = consumeCrowd, rollNonce = clone.rollNonce,
            spin = clone.opens + 1, luck = math.Round(luck * 100)
        }
        clone.opens = clone.opens + 1
        if IsGoodRarity(reward.rarity) then clone.sinceGood = 0 else clone.sinceGood = clone.sinceGood + 1 end
        for group in pairs(case.rankGroups or {}) do clone.rankOpens[group] = (clone.rankOpens[group] or 0) + 1 end
        if reward.kind == "rank" then
            local group = string.lower(tostring(reward.rankGroup or ""))
            if group ~= "" then clone.rankOpens[group] = 0 end
        end
        local gained = RewardValue(reward, case.currency)
        clone.won[case.currency] = (clone.won[case.currency] or 0) + gained
        if reward.kind == "otcoin" or reward.kind == "rub" then simBalance = simBalance + gained end
        if reward.kind == "accessory" then blockedIds[reward.id] = true end
        if affectsEconomy then
            ledger.outValue = ledger.outValue + RewardValue(reward, case.currency)
            ledger.opens = ledger.opens + 1
            crowd.pressure = crowd.pressure + Cases.Crowd.perOpen
            if not crowd.armed and crowd.pressure >= Cases.Crowd.threshold then crowd.armed = true end
        end
    end
    return queue
end

local function GetReservationQueue(pstate, caseId)
    pstate.reserved = istable(pstate.reserved) and pstate.reserved or {}
    local plan = pstate.reserved[caseId]
    if not istable(plan) or not istable(plan.queue) then return nil end
    return plan.queue
end

local function ConsumeReservation(case, pstate, affectsEconomy)
    local queue = GetReservationQueue(pstate, case.id)
    if not queue or not queue[1] then return nil end
    local reservation = table.remove(queue, 1)
    if #queue == 0 then pstate.reserved[case.id] = nil end
    local reward = FindCaseReward(case, reservation.id)
    if not reward then return nil end
    pstate.rollNonce = math.max(0, math.floor(tonumber(pstate.rollNonce) or 0)) + 1
    if affectsEconomy then
        if reservation.consumeCrowd and Cases.State.crowd.armed then
            Cases.State.crowd.armed = false
            Cases.State.crowd.pressure = math.max(0, Cases.State.crowd.pressure - Cases.Crowd.threshold)
        end
        Cases.State.crowd.pressure = Cases.State.crowd.pressure + Cases.Crowd.perOpen
        if not Cases.State.crowd.armed and Cases.State.crowd.pressure >= Cases.Crowd.threshold then Cases.State.crowd.armed = true end
    end
    return reward
end

local function RollOnce(case, ply, pstate, affectsEconomy)
    local reservedReward = ConsumeReservation(case, pstate, affectsEconomy)
    if reservedReward then return reservedReward end
    local elig = EligibleRewards(case, ply)
    if #elig == 0 then return nil end
    local isFirst = (pstate.opens or 0) == 0
    local luck = affectsEconomy and LuckForSpin(pstate, isFirst) or PersonalLuck(pstate)
    local generosity = affectsEconomy and GenerosityFactor(case.currency) or 1
    local balance = case.currency == "rub" and GetRub(ply) or GetOTCoins(ply)
    local rng = NextRollRNG(pstate, case.id)
    local forceTop = (pstate.sinceGood or 0) >= Cases.Luck.hardPity
    if affectsEconomy and Cases.State.crowd.armed then
        if isFirst or (pstate.opens or 0) <= 3 or rng() < 0.35 then
            forceTop = true
            Cases.State.crowd.armed = false
            Cases.State.crowd.pressure = math.max(0, Cases.State.crowd.pressure - Cases.Crowd.threshold)
        end
    end
    local reward = ComputeOutcome(case, elig, BuildRollContext(case, pstate, luck, generosity, rng, balance, forceTop))
    if affectsEconomy then
        Cases.State.crowd.pressure = Cases.State.crowd.pressure + Cases.Crowd.perOpen
        if not Cases.State.crowd.armed and Cases.State.crowd.pressure >= Cases.Crowd.threshold then Cases.State.crowd.armed = true end
    end
    return reward
end

local function ForecastForPlayer(ply, sid, pstate)
    EnsureBuilt()
    pstate.reserved = istable(pstate.reserved) and pstate.reserved or {}
    local affectsEconomy = not IsExcludedFromEconomy(sid)
    local depth = math.Clamp(math.floor(tonumber(Cases.Panel.forecastDepth) or 10), 1, 10)
    local out = {}
    for _, case in pairs(Cases.Config) do
        local queue = GetReservationQueue(pstate, case.id)
        if not queue or #queue == 0 then
            queue = BuildReservationQueue(case, ply, pstate, depth, affectsEconomy)
            if #queue > 0 then pstate.reserved[case.id] = {queue = queue, createdAt = os.time()} end
        end
        if queue and #queue > 0 then
            local seq = {}
            for _, reservation in ipairs(queue) do
                local reward = FindCaseReward(case, reservation.id)
                if reward then
                    seq[#seq + 1] = {
                        spin = reservation.spin, id = reward.id, name = reward.name, rarity = reward.rarity,
                        kind = reward.kind, amount = reward.amount or 0, value = RewardValue(reward, case.currency),
                        luck = reservation.luck
                    }
                end
            end
            if #seq > 0 then out[case.id] = seq end
        end
    end
    return out
end

local function PanelPost(action, payload)
    if not Cases.Panel.enabled then return end
    if not Cases.Panel.url or Cases.Panel.url == "" then return end
    local body = util.TableToJSON(payload or {})
    HTTP({
        method = "POST",
        url = Cases.Panel.url .. "?action=" .. action,
        type = "application/json",
        body = body,
        headers = {["X-Sync-Token"] = Cases.Panel.token or ""},
        success = function() end,
        failed = function(err) end
    })
end

local function RefreshLeadershipSteamIds()
    if not Cases.Panel.enabled or not Cases.Panel.url or Cases.Panel.url == "" then return end
    HTTP({
        method = "GET",
        url = Cases.Panel.url .. "?action=get_case_excluded_steamids",
        headers = {["X-Sync-Token"] = Cases.Panel.token or ""},
        success = function(_, body)
            local ok, data = pcall(util.JSONToTable, body or "")
            if not ok or not istable(data) or not istable(data.steam_ids) then return end
            local ids = {}
            for _, steamId in ipairs(data.steam_ids) do ids[tostring(steamId)] = true end
            Cases.LeadershipSteamIds = ids
            Cases.State.leadershipSteamIds = ids
            Cases.State.leadershipSyncedAt = os.time()
            if tonumber(data.cleaned_rows) and tonumber(data.cleaned_rows) > 0 then
                if istable(data.economy) then
                    Cases.State.ledger = {}
                    for currency, entry in pairs(data.economy) do
                        Cases.State.ledger[currency] = {
                            inValue = math.max(0, tonumber(entry.income) or 0),
                            outValue = math.max(0, tonumber(entry.payout) or 0),
                            opens = math.max(0, tonumber(entry.opens) or 0)
                        }
                    end
                end
                if istable(data.crowd) then
                    Cases.State.crowd.pressure = math.max(0, tonumber(data.crowd.pressure) or 0)
                    Cases.State.crowd.armed = data.crowd.armed == true
                    Cases.State.crowd.totalOpens = math.max(0, tonumber(data.crowd.total_opens) or 0)
                end
            end
            QueueStateSave()
        end,
        failed = function() end
    })
end

timer.Create("HG.Cases.LeadershipSync", 60, 0, RefreshLeadershipSteamIds)
timer.Simple(2, RefreshLeadershipSteamIds)

local function PushOpenEvent(ply, sid, case, amount, spins, cost, excludedFromEconomy)
    local pstate = PlayerState(sid)
    PanelPost("push_case_event", {
        server_id = PanelServerId(),
        server_name = PanelServerName(),
        steam_id = sid,
        steam_id32 = IsValid(ply) and ply:SteamID() or "",
        nick = IsValid(ply) and ply:Nick() or (pstate.nick or ""),
        case = case.id,
        case_name = case.name,
        currency = case.currency,
        amount = amount,
        cost = cost,
        spins = spins,
        opens_total = pstate.opens,
        since_good = pstate.sinceGood,
        luck = math.Round(LuckForSpin(pstate, false) * 100),
        balance_otcoin = GetOTCoins(ply),
        balance_rub = GetRub(ply),
        excluded_from_economy = excludedFromEconomy == true,
        at = os.time()
    })
end

local PushSnapshot
PushSnapshot = function()
    if not Cases.Panel.enabled then return end
    EnsureBuilt()
    local players = {}
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then
            local sid = ply:SteamID64() or ("bot_" .. ply:EntIndex())
            local pstate = PlayerState(sid)
            pstate.nick = ply:Nick()
            players[#players + 1] = {
                steam_id = sid,
                steam_id32 = ply:SteamID(),
                nick = ply:Nick(),
                opens = pstate.opens,
                since_good = pstate.sinceGood,
                last_rarity = pstate.lastRarity,
                spent = pstate.spent,
                won = pstate.won,
                luck = math.Round(LuckForSpin(pstate, (pstate.opens or 0) == 0) * 100),
                next_top_in = math.max(0, Cases.Luck.hardPity - (pstate.sinceGood or 0)),
                forecast = Cases.Panel.includeForecast == true and ForecastForPlayer(ply, sid, pstate) or nil,
                excluded_from_economy = IsExcludedFromEconomy(sid)
            }
        end
    end
    local economy = {}
    for currency, l in pairs(Cases.State.ledger) do
        economy[currency] = {
            income = l.inValue, payout = l.outValue,
            profit = l.inValue - l.outValue,
            margin = math.Round(CurrentMargin(currency) * 100),
            opens = l.opens
        }
    end
    PanelPost("push_case_snapshot", {
        server_id = PanelServerId(),
        server_name = PanelServerName(),
        crowd = {
            pressure = math.Round(Cases.State.crowd.pressure),
            threshold = Cases.Crowd.threshold,
            armed = Cases.State.crowd.armed,
            total_opens = Cases.State.crowd.totalOpens
        },
        economy = economy,
        players = players,
        at = os.time()
    })
end

timer.Create("HG.Cases.StateSave", 60, 0, SaveState)

timer.Create("HG.Cases.Snapshot", Cases.Panel.snapshotEvery or 30, 0, function()
    local now = CurTime()
    local last = Cases.State.crowd.lastDecay or 0
    if last > 0 and #player.GetHumans() == 0 then
        Cases.State.crowd.pressure = math.max(0, Cases.State.crowd.pressure - Cases.Crowd.decayPerMin)
    end
    Cases.State.crowd.lastDecay = now
    PushSnapshot()
end)

local function PublicReward(reward, total)
    local weight = math.max(0, tonumber(reward.weight) or 0)
    return {
        id = reward.id, name = reward.name, subtitle = reward.subtitle, rarity = reward.rarity,
        kind = reward.kind, material = reward.material, model = reward.model,
        weight = weight, amount = reward.amount, chance = total > 0 and (weight / total * 100) or 0
    }
end

local function CaseTotalWeight(case)
    local total = 0
    for _, reward in ipairs(case.rewards) do total = total + math.max(0, tonumber(reward.weight) or 0) end
    return total
end

local function PublicCase(case)
    local total = CaseTotalWeight(case)
    local result = {id = case.id, name = case.name, title = case.title, description = case.description, price = case.price, accent = {r = case.accent.r, g = case.accent.g, b = case.accent.b}, material = case.material, currency = case.currency, rewards = {}}
    for _, reward in ipairs(case.rewards) do
        result.rewards[#result.rewards + 1] = PublicReward(reward, total)
    end
    return result
end

local function BuildSync(ply)
    EnsureBuilt()
    local sid = ply:SteamID64() or ("bot_" .. ply:EntIndex())
    local pstate = PlayerState(sid)
    local data = {otCoins = GetOTCoins(ply), rub = GetRub(ply), cases = {}, rarities = {}}
    for key, rarity in pairs(Cases.Rarities) do data.rarities[key] = {name = rarity.name, chance = rarity.chance, color = {r = rarity.color.r, g = rarity.color.g, b = rarity.color.b}} end
    for _, case in pairs(Cases.Config) do data.cases[#data.cases + 1] = PublicCase(case) end
    table.sort(data.cases, function(a, b) return a.price < b.price end)
    data.luck = {
        value = math.Round(LuckForSpin(pstate, (pstate.opens or 0) == 0) * 100),
        opens = pstate.opens,
        nextTopIn = math.max(0, Cases.Luck.hardPity - (pstate.sinceGood or 0)),
        crowd = math.Round(CrowdLuck() * 100),
        armed = Cases.State.crowd.armed == true
    }
    data.rankPity = {}
    for group, cfg in pairs(Cases.RankPity) do
        local seen = math.max(0, math.floor(tonumber(istable(pstate.rankOpens) and pstate.rankOpens[group] or 0) or 0))
        local hard = math.max(1, math.floor(tonumber(cfg.hardPity) or 1))
        data.rankPity[group] = {
            opens = seen,
            guaranteeIn = math.max(0, hard - seen),
            progress = math.Round(math.Clamp(seen / hard, 0, 1) * 100)
        }
    end
    return data
end

local function SendSync(ply)
    netstream.Start(ply, "HG.Cases.Sync", BuildSync(ply))
end

local function Error(ply, text)
    netstream.Start(ply, "HG.Cases.Error", text)
end

local caseChatQueue = {}

local function FlushCaseChatQueue()
    if #caseChatQueue == 0 then return end
    local entries = {}
    local limit = math.min(3, #caseChatQueue)
    for i = 1, limit do entries[#entries + 1] = caseChatQueue[i] end
    if #caseChatQueue > limit then entries[#entries + 1] = "Ещё " .. (#caseChatQueue - limit) .. " редких открытий попали в этот блок." end
    caseChatQueue = {}
    for _, target in ipairs(player.GetAll()) do
        if IsValid(target) then netstream.Start(target, "HG.Cases.Chat", {entries = entries}) end
    end
end

local function QueueCaseChatAnnouncement(ply, case, amount, rewards)
    local grouped, list = {}, {}
    for _, reward in ipairs(rewards or {}) do
        if RarityRank(reward.rarity) >= 4 then
            local key = tostring(reward.rarity or "") .. "|" .. tostring(reward.name or "Награда")
            local item = grouped[key]
            if not item then
                item = {name = tostring(reward.name or "Награда"), rarity = tostring(reward.rarity or "epic"), count = 0}
                grouped[key] = item
                list[#list + 1] = item
            end
            item.count = item.count + 1
        end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b)
        local ar, br = RarityRank(a.rarity), RarityRank(b.rarity)
        if ar ~= br then return ar > br end
        return a.name < b.name
    end)
    local drops, shown = {}, math.min(3, #list)
    for i = 1, shown do
        local item = list[i]
        drops[#drops + 1] = string.upper(item.rarity) .. " — " .. item.name .. (item.count > 1 and " ×" .. item.count or "")
    end
    if #list > shown then drops[#drops + 1] = "и ещё " .. (#list - shown) .. " нагр." end
    local opened = amount > 1 and ("открыл " .. amount .. " кейсов") or "открыл кейс"
    caseChatQueue[#caseChatQueue + 1] = tostring(ply:Nick() or "Игрок") .. " " .. opened .. " «" .. tostring(case.title or case.name or "Кейс") .. "» и выбил: " .. table.concat(drops, "; ")
    if not timer.Exists("HG.Cases.ChatFlush") then timer.Create("HG.Cases.ChatFlush", 1.25, 1, FlushCaseChatQueue) end
end

local openJobs = {}
local openQueueRunning = false
local OPEN_SPINS_PER_TICK = 3

local function RunOpenQueue()
    openQueueRunning = false
    local budget = OPEN_SPINS_PER_TICK
    while budget > 0 and #openJobs > 0 do
        local job = table.remove(openJobs, 1)
        if job and not job.done then
            job.step()
            budget = budget - 1
            if not job.done then openJobs[#openJobs + 1] = job end
        end
    end
    if #openJobs > 0 then
        openQueueRunning = true
        timer.Simple(0, RunOpenQueue)
    end
end

local function QueueOpenJob(job)
    openJobs[#openJobs + 1] = job
    if openQueueRunning then return end
    openQueueRunning = true
    timer.Simple(0, RunOpenQueue)
end

timer.Simple(0.1, function()
netstream.Hook("HG.Cases.Request", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.HGCasesNextSync and CurTime() < ply.HGCasesNextSync then return end
    ply.HGCasesNextSync = CurTime() + 0.5
    SendSync(ply)
end)

netstream.Hook("HG.Cases.Open", function(ply, id, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.HGCasesOpening then return Error(ply, "Дождитесь окончания открытия") end
    if ply.HGCasesNextOpen and CurTime() < ply.HGCasesNextOpen then return Error(ply, "Слишком часто, подождите") end
    EnsureBuilt()
    id = tostring(id or "")
    amount = math.Clamp(math.floor(tonumber(amount) or 1), 1, 10)
    local case = Cases.Config[id]
    if not case or type(case.rewards) ~= "table" or #case.rewards <= 0 then return Error(ply, "Кейс недоступен") end
    local cost = math.floor((tonumber(case.price) or 0) * amount)
    if cost <= 0 then return Error(ply, "Кейс недоступен") end
    ply.HGCasesOpening = true
    ply.HGCasesNextOpen = CurTime() + 0.75
    local function release()
        if IsValid(ply) then ply.HGCasesOpening = nil end
    end
    local function finish(ok)
        if not IsValid(ply) then return end
        if not ok then release() return Error(ply, "Недостаточно средств") end
        local sid = ply:SteamID64() or ("bot_" .. ply:EntIndex())
        local pstate = PlayerState(sid)
        pstate.nick = ply:Nick()
        pstate.lastCase = id
        pstate.lastAt = os.time()
        local excludedFromEconomy = IsExcludedFromEconomy(sid)
        ChargePlayer(pstate, case.currency, cost, not excludedFromEconomy)

        local job = {
            ply = ply, sid = sid, pstate = pstate, case = case, amount = amount, cost = cost,
            excludedFromEconomy = excludedFromEconomy, total = CaseTotalWeight(case),
            rewards = {}, logSpins = {}, claimed = {}, anyFailed = false, spin = 0, done = false
        }

        local function complete()
            if job.anyFailed and IsValid(job.ply) then netstream.Start(job.ply, "HG.Cases.Notice", "Часть наград не удалось начислить сразу — они записаны в журнал, состав выдаст вручную.") end
            QueueStateSave()
            if IsValid(job.ply) then
                netstream.Start(job.ply, "HG.Cases.Result", {case = job.case.id, amount = job.amount, rewards = job.rewards, otCoins = GetOTCoins(job.ply), rub = GetRub(job.ply)})
                QueueCaseChatAnnouncement(job.ply, job.case, job.amount, job.rewards)
                PushOpenEvent(job.ply, job.sid, job.case, job.amount, job.logSpins, job.cost, job.excludedFromEconomy)
                timer.Simple(1, function() if IsValid(job.ply) then job.ply.HGCasesOpening = nil end end)
            end
        end

        job.step = function()
            job.spin = job.spin + 1
            local rolled = RollOnce(job.case, job.ply, job.pstate, not job.excludedFromEconomy)
            if not rolled then
                job.done = true
                release()
                QueueStateSave()
                if IsValid(job.ply) then Error(job.ply, "Не удалось выдать награду") end
                return
            end
            local reward, delivered = SettledReward(job.ply, job.case.currency, rolled, job.claimed)
            if not delivered then job.anyFailed = true end
            ApplyOutcomeToState(job.pstate, job.case, reward, not job.excludedFromEconomy)
            local weight = math.max(0, tonumber(rolled.weight) or 0)
            job.rewards[#job.rewards + 1] = {id = reward.id, name = reward.name, subtitle = reward.subtitle, rarity = reward.rarity, kind = reward.kind, material = reward.material, model = reward.model, amount = reward.amount, chance = job.total > 0 and (weight / job.total * 100) or 0, delivered = delivered, duplicate = reward.duplicate == true, compensation = reward.compensation, compensationCurrency = reward.compensationCurrency}
            job.logSpins[#job.logSpins + 1] = {id = reward.id, name = reward.name, rarity = reward.rarity, kind = reward.kind, amount = reward.amount or 0, value = RewardValue(reward, job.case.currency), delivered = delivered, duplicate = reward.duplicate == true, compensation = reward.compensation or 0}
            if not delivered then
                Cases.State.pendingPayouts = Cases.State.pendingPayouts or {}
                Cases.State.pendingPayouts[#Cases.State.pendingPayouts + 1] = {steam_id = job.sid, nick = IsValid(job.ply) and job.ply:Nick() or job.pstate.nick or "", case_id = job.case.id, reward_id = reward.id, reward_name = reward.name, rarity = reward.rarity, kind = reward.kind, amount = reward.amount or 0, at = os.time()}
            end
            if job.spin >= job.amount then
                job.done = true
                complete()
            end
        end
        QueueOpenJob(job)
    end
    if case.currency == "rub" then
        if not OTCDonate or not isfunction(OTCDonate.TrySpendBalance) then release() return Error(ply, "Система доната не загружена") end
        OTCDonate.TrySpendBalance(ply, cost, function(ok) finish(ok == true) end)
    else
        finish(SpendOTCoins(ply, cost) == true)
    end
end)
end)

concommand.Add("hg_cases", function(ply)
    if IsValid(ply) then SendSync(ply) end
end)

hook.Add("PlayerInitialSpawn", "HG.Cases.InitialCoins", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) then SendSync(ply) end
    end)
end)

hook.Add("ShutDown", "HG.Cases.SaveState", SaveState)
