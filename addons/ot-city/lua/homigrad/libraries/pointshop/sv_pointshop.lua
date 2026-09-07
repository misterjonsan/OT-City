hg.Pointshop = hg.Pointshop or {}

local POINTS_AMOUNT = 2
local POINTS_INTERVAL = 60
local ADMINS_GET_POINTS = true

local PLUGIN = hg.Pointshop
PLUGIN.PlayerInstances = PLUGIN.PlayerInstances or {}
PLUGIN.Active = PLUGIN.Active or false

local function EnsureRKBalance()
    if RK_Balance and isfunction(RK_Balance.Load) and isfunction(RK_Balance.Add) then return true end

    if not mdata then
        print("[Z-City Shop] RK_Balance не найден и mdata тоже не найден. Донат-поинты будут недоступны, пока не загрузится mdata.")
        return false
    end

    RK_Balance = RK_Balance or {}

    if not isfunction(RK_Balance.Load) then
        function RK_Balance.Load(ply)
            if not IsValid(ply) then return end
            local function apply()
                if not IsValid(ply) then return end
                local v = 0
                if mdata and mdata.IsLoaded and mdata:IsLoaded(ply) then
                    v = tonumber(ply:GetMData("rk_donate_balance", 0)) or 0
                end
                ply.RK_DonateBalance = math.max(0, v)
            end

            if mdata and mdata.IsLoaded and mdata:IsLoaded(ply) then
                apply()
                return
            end

            local sid = ply:SteamID64()
            local tries = 0
            timer.Create("ZCity_RKBalanceWait_" .. tostring(sid), 0.25, 80, function()
                if not IsValid(ply) then timer.Remove("ZCity_RKBalanceWait_" .. tostring(sid)) return end
                tries = tries + 1
                if mdata and mdata.IsLoaded and mdata:IsLoaded(ply) then
                    apply()
                    timer.Remove("ZCity_RKBalanceWait_" .. tostring(sid))
                    return
                end
                if tries >= 80 then
                    apply()
                    timer.Remove("ZCity_RKBalanceWait_" .. tostring(sid))
                end
            end)
        end
    end

    if not isfunction(RK_Balance.Add) then
        function RK_Balance.Add(ply, delta)
            if not IsValid(ply) then return end
            delta = tonumber(delta) or 0
            if delta == 0 then
                RK_Balance.Load(ply)
                return
            end

            local cur = tonumber(ply.RK_DonateBalance) or 0

            if mdata and mdata.IsLoaded and mdata:IsLoaded(ply) then
                cur = tonumber(ply:GetMData("rk_donate_balance", cur)) or cur
            end

            local newv = math.max(0, cur + delta)

            ply.RK_DonateBalance = newv

            if mdata then
                ply:SetMData("rk_donate_balance", newv)
            end
        end
    end

    if not RK_Balance.__zcity_mdata_hooked then
        RK_Balance.__zcity_mdata_hooked = true
        if mdata and isfunction(mdata.AddCallback) then
            mdata:AddCallback("rk_donate_balance", function(ply, val)
                if not IsValid(ply) then return end
                ply.RK_DonateBalance = math.max(0, tonumber(val) or 0)
            end)
        end
    end

    print("[Z-City Shop] RK_Balance не найден. Подключён совместимый слой на mdata (rk_donate_balance).")
    return true
end

local function PS_RefreshDonPoints(ply)
    if not IsValid(ply) then return end
    local sid64 = ply:SteamID64()
    if not PLUGIN.PlayerInstances[sid64] then
        PLUGIN.PlayerInstances[sid64] = { donpoints = 0, points = 0, items = {} }
    end
    PLUGIN.PlayerInstances[sid64].donpoints = math.max(0, tonumber(ply.RK_DonateBalance) or 0)
end

hook.Add("DatabaseConnected", "PointshopCreateData", function()
    EnsureRKBalance()

    local query = mysql:Create("hg_pointshop")
        query:Create("steamid", "VARCHAR(20) NOT NULL")
        query:Create("steam_name", "VARCHAR(32) NOT NULL")
        query:Create("points", "FLOAT NOT NULL")
        query:Create("items", "TEXT NOT NULL")
        query:PrimaryKey("steamid")
    query:Execute()

    PLUGIN.Active = true
    print("[Z-City Shop] База данных успешно загружена.")
end)

hook.Add("PlayerInitialSpawn", "Pointshop_OnInitSpawn", function(ply)
    EnsureRKBalance()

    local name = ply:Name()
    local steamID64 = ply:SteamID64()

    if not PLUGIN.Active then
        PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }
        RK_Balance.Load(ply)
        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            PS_RefreshDonPoints(ply)
            hook.Run("PS_PlayerLoaded", ply, steamID64)
            PLUGIN:NET_SendPointShopVars(ply)
        end)
        return
    end

    local query = mysql:Select("hg_pointshop")
        query:Select("points")
        query:Select("items")
        query:Where("steamid", steamID64)
        query:Callback(function(result)
            if IsValid(ply) and istable(result) and #result > 0 and result[1].points then
                local updateQuery = mysql:Update("hg_pointshop")
                    updateQuery:Update("steam_name", name)
                    updateQuery:Where("steamid", steamID64)
                updateQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = {}
                PLUGIN.PlayerInstances[steamID64].points = tonumber(result[1].points) or 0
                PLUGIN.PlayerInstances[steamID64].items = util.JSONToTable(result[1].items or "[]") or {}

                RK_Balance.Load(ply)

                timer.Simple(0.5, function()
                    if not IsValid(ply) then return end
                    PS_RefreshDonPoints(ply)
                    hook.Run("PS_PlayerLoaded", ply, steamID64)
                    PLUGIN:NET_SendPointShopVars(ply)
                end)
            else
                local insertQuery = mysql:Insert("hg_pointshop")
                    insertQuery:Insert("steamid", steamID64)
                    insertQuery:Insert("steam_name", name)
                    insertQuery:Insert("points", 0)
                    insertQuery:Insert("items", util.TableToJSON({}))
                insertQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }

                RK_Balance.Load(ply)

                timer.Simple(0.5, function()
                    if not IsValid(ply) then return end
                    PS_RefreshDonPoints(ply)
                    hook.Run("PS_PlayerLoaded", ply, steamID64)
                    PLUGIN:NET_SendPointShopVars(ply)
                end)
            end
        end)
    query:Execute()
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetPointshopVars()
    local steamID64 = self:SteamID64()
    if not PLUGIN.PlayerInstances[steamID64] then
        PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }
    end
    PLUGIN.PlayerInstances[steamID64].donpoints = math.max(0, tonumber(self.RK_DonateBalance) or 0)
    return PLUGIN.PlayerInstances[steamID64]
end

function plyMeta:PS_AddPoints(ammout)
    local pointshopVars = self:GetPointshopVars()
    ammout = tonumber(ammout) or 0
    if ammout < 1 then return false end
    self:PS_SetPoints(pointshopVars.points + ammout)
    return true, tostring(ammout) .. " поинтов добавлено"
end

function plyMeta:PS_SetPoints(value)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    value = tonumber(value) or 0

    local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("points", value)
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    pointshopVars.points = value
end

function plyMeta:PS_TakePoints(ammout, callback)
    local pointshopVars = self:GetPointshopVars()
    ammout = tonumber(ammout) or 0
    if ammout > pointshopVars.points then return false, "Вам не хватает поинтов." end
    self:PS_SetPoints(pointshopVars.points - ammout)
    if callback then callback(self) end
    return true, ""
end

function plyMeta:PS_AddDPoints(ammout)
    EnsureRKBalance()
    ammout = tonumber(ammout) or 0
    if ammout < 1 then return false end
    RK_Balance.Add(self, ammout)
    PS_RefreshDonPoints(self)
    return true
end

function plyMeta:PS_SetDPoints(value)
    EnsureRKBalance()
    value = tonumber(value) or 0
    local cur = math.max(0, tonumber(self.RK_DonateBalance) or 0)
    local delta = value - cur
    if delta == 0 then
        PS_RefreshDonPoints(self)
        return
    end
    RK_Balance.Add(self, delta)
    PS_RefreshDonPoints(self)
end

function plyMeta:PS_TakeDPoints(ammout, callback)
    EnsureRKBalance()
    local cur = math.max(0, tonumber(self.RK_DonateBalance) or 0)
    ammout = tonumber(ammout) or 0
    if ammout > cur then return false, "Вам не хватает донат-поинтов." end
    RK_Balance.Add(self, -ammout)
    PS_RefreshDonPoints(self)
    if callback then callback(self) end
    return true, ""
end

function plyMeta:PS_SetItems(tItems)
    local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("items", util.TableToJSON(tItems))
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    pointshopVars.items = tItems
end

function plyMeta:PS_AddItem(uid)
    if not hg.PointShop or not hg.PointShop.Items or not hg.PointShop.Items[uid] then return end
    local pointshopVars = self:GetPointshopVars()
    pointshopVars.items[uid] = true
    self:PS_SetItems(pointshopVars.items)
end

function plyMeta:PS_HasItem(uid)
    local pointshopVars = self:GetPointshopVars()
    if not pointshopVars then return false end
    return pointshopVars.items[uid] or false
end

util.AddNetworkString("hg_pointshop_net")

function PLUGIN:NET_SendPointShopVars(ply)
    PS_RefreshDonPoints(ply)

    net.Start("hg_pointshop_net")
        net.WriteTable(ply:GetPointshopVars())
    net.Send(ply)
end

util.AddNetworkString("hg_pointshop_send_notificate")

function PLUGIN:NET_BuyItem(ply, uid)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    if not hg.PointShop or not hg.PointShop.Items or not hg.PointShop.Items[uid] then return end

    if ply:PS_HasItem(uid) then
        PLUGIN:NET_SendPointShopVars(ply)
        return
    end

    local yes = false
    local reason = ""

    if hg.PointShop.Items[uid].ISDONATE then
        yes, reason = ply:PS_TakeDPoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    else
        yes, reason = ply:PS_TakePoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    end

    net.Start("hg_pointshop_send_notificate")
        net.WriteString(reason or "")
    net.Send(ply)

    PLUGIN:NET_SendPointShopVars(ply)
end

function PLUGIN:NET_GetBuyedItems(ply)
    PLUGIN:NET_SendPointShopVars(ply)
end

net.Receive("hg_pointshop_net", function(_, ply)
    if ply.PSNetCD and ply.PSNetCD > CurTime() then return end
    ply.PSNetCD = CurTime() + 0.01

    local str = net.ReadString()
    local funcstring = PLUGIN["NET_" .. str]
    if not funcstring then return end

    local vars = net.ReadTable()
    if table.Count(vars) > 5 then return end

    funcstring(PLUGIN, ply, unpack(vars))
end)

hook.Add("HG_PlayerSay", "OpenPointShop", function(ply, txtTbl, txt)
    if txt == "!pointshop" then
        ply:ConCommand("hg_pointshop")
    end
end)

timer.Create("ZCity_PointsTimer", POINTS_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsFullyAuthenticated() then
            if not ADMINS_GET_POINTS and (ply:IsSuperAdmin() or ply:IsAdmin()) then
                continue
            end
            ply:PS_AddPoints(POINTS_AMOUNT)
            PLUGIN:NET_SendPointShopVars(ply)
        end
    end
end)

local function FindPlayerFinal(input)
    if not input then return nil end
    input = string.Replace(input, '"', "")
    input = string.Trim(input)

    for _, v in ipairs(player.GetAll()) do
        if v:SteamID() == input then return v end
        if v:SteamID64() == input then return v end
        if v:Nick() == input then return v end
    end
    return nil
end

concommand.Add("zcity_tebex_add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if target and amount then
        target:PS_AddPoints(amount)
        PLUGIN:NET_SendPointShopVars(target)
        print("[TEBEX] УСПЕХ: добавлено " .. amount .. " ZP для " .. target:Nick())
        if IsValid(target) then target:ChatPrint("[Магазин] Спасибо! Вы получили " .. amount .. " ZP!") end
    else
        print("[TEBEX] ОШИБКА: игрок не найден или сумма неверная.")
    end
end)

concommand.Add("zcity_tebex_add_premium", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if target and amount then
        target:PS_AddDPoints(amount)
        PLUGIN:NET_SendPointShopVars(target)
        print("[TEBEX] УСПЕХ: добавлено " .. amount .. " DZP для " .. target:Nick())
        if IsValid(target) then target:ChatPrint("[ПРЕМИУМ МАГАЗИН] Спасибо! Вы получили " .. amount .. " DZP!") end
    else
        print("[TEBEX] ОШИБКА: игрок не найден или сумма неверная.")
    end
end)