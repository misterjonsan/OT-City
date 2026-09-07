local player_GetAll = player.GetAll
local player_GetCount = player.GetCount
local ents_FindByClass = ents.FindByClass
local IsValid = IsValid
local CurTime = CurTime
local math_random = math.random
local math_max = math.max
local math_sqrt = math.sqrt
local table_insert = table.insert
local table_remove = table.remove
local net_Start = net.Start
local net_Broadcast = net.Broadcast
local net_Send = net.Send
local net_WriteString = net.WriteString
local net_WriteInt = net.WriteInt
local net_WriteTable = net.WriteTable
local net_WriteBool = net.WriteBool
local net_ReadTable = net.ReadTable
local net_ReadBool = net.ReadBool
local net_ReadString = net.ReadString
local file_Read = file.Read
local file_Write = file.Write
local file_CreateDir = file.CreateDir
local util_JSONToTable = util.JSONToTable
local util_TableToJSON = util.TableToJSON
local game_GetMap = game.GetMap

zb.modes = zb.modes or {}
zb.ModesPlaytime = zb.ModesPlaytime or {}
zb.ModesChances = zb.ModesChances or {}
zb.RoundList = zb.RoundList or {}
zb.QueuedModes = zb.QueuedModes or {}
zb.forcemode = zb.forcemode or "random"
zb.ROUND_TIME = zb.ROUND_TIME or 300

local forcemodeconvar = CreateConVar("zb_forcemode", "", FCVAR_ARCHIVE)
local forcemode = zb.forcemode

util.AddNetworkString("FadeScreen")
util.AddNetworkString("RoundInfo")
util.AddNetworkString("ZB_SendModesInfo")
util.AddNetworkString("ZB_SendRoundList")
util.AddNetworkString("ZB_RequestRoundList")
util.AddNetworkString("ZB_UpdateRoundList")
util.AddNetworkString("ZB_NotifyRoundListChange")
util.AddNetworkString("ZB_StaffLimits")
util.AddNetworkString("SendAvailableModes")
util.AddNetworkString("AdminSetGameMode")
util.AddNetworkString("AdminEndRound")
util.AddNetworkString("AdminSetGameQueue")
util.AddNetworkString("RequestGameQueue")
util.AddNetworkString("SendGameQueue")
util.AddNetworkString("QueueEmptiedNotification")
util.AddNetworkString("QueueModifiedNotification")

local trigger_changelevel_exists = false
local cachedWorldSize
local cachedModesInfo
local cachedModesSimple

local function IsModerator(ply)
    if not IsValid(ply) then return false end
    local group = ply:GetUserGroup()
    return group == "operator" or group == "sponsor"
end

local function HasMenuAccess(ply)
    return IsValid(ply) and ply:GetUserGroup() ~= "admin" and (ply:IsAdmin() or IsModerator(ply))
end

local function CanManageQueue(ply)
    return IsValid(ply) and ply:GetUserGroup() ~= "admin" and ply:IsAdmin()
end

local function CanSetNextMode(ply, modeObj)
    if not HasMenuAccess(ply) then return false end
    if not modeObj then return true end
    if ply:IsAdmin() then return true end
    return modeObj.CanLaunch and modeObj:CanLaunch()
end

local function CanEndRound(ply)
    return HasMenuAccess(ply)
end

local function HasChangeLevel()
    return trigger_changelevel_exists
end

local function RefreshChangeLevelState()
    trigger_changelevel_exists = IsValid(ents_FindByClass("trigger_changelevel")[1])
end

local function SendRoundInfo(target)
    local mode = CurrentRound()
    if not mode then return end

    net_Start("RoundInfo")
    net_WriteString(mode.name or "hmcd")
    net_WriteInt(zb.ROUND_STATE or 0, 4)
    if target then
        net_Send(target)
    else
        net_Broadcast()
    end
end

local function GetAdmins(except)
    local admins = {}
    for _, ply in player.Iterator() do
        if ply:IsAdmin() and ply ~= except then
            admins[#admins + 1] = ply
        end
    end
    return admins
end

local function GetMenuUsers(except)
    local users = {}
    for _, ply in player.Iterator() do
        if HasMenuAccess(ply) and ply ~= except then
            users[#users + 1] = ply
        end
    end
    return users
end

local STAFF_LIMIT_FILE = "zbattle/staff_limits.json"
local STAFF_LIMITS = {
    ["operator"] = { modes = 3, ends = 1, endCooldown = 900, minRoundTime = 120 },
    ["sponsor"] = { modes = 6, ends = 2, endCooldown = 600, minRoundTime = 90 }
}
local staffUsage

local function StaffToday()
    return os.date("%Y-%m-%d")
end

local function LoadStaffUsage()
    if staffUsage then return staffUsage end
    staffUsage = {}
    local raw = file_Read(STAFF_LIMIT_FILE, "DATA")
    if raw then
        local tbl = util_JSONToTable(raw)
        if istable(tbl) then staffUsage = tbl end
    end
    return staffUsage
end

local function SaveStaffUsage()
    file_CreateDir("zbattle")
    file_Write(STAFF_LIMIT_FILE, util_TableToJSON(LoadStaffUsage()))
end

local function GetStaffLimits(ply)
    if not IsValid(ply) then return nil end
    if ply:IsAdmin() then return nil end
    return STAFF_LIMITS[string.lower(ply:GetUserGroup() or "")]
end

local function GetStaffUsage(ply)
    local usage = LoadStaffUsage()
    local id = ply:SteamID64() or ply:SteamID() or "unknown"
    local today = StaffToday()
    local data = usage[id]
    if not istable(data) or data.day ~= today then
        data = { day = today, modes = 0, ends = 0, lastEnd = 0 }
        usage[id] = data
    end
    return data
end

local function StaffModesLeft(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return -1 end
    return math_max(0, limits.modes - (GetStaffUsage(ply).modes or 0))
end

local function StaffEndsLeft(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return -1 end
    return math_max(0, limits.ends - (GetStaffUsage(ply).ends or 0))
end

local function StaffEndCooldownLeft(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return 0 end
    local data = GetStaffUsage(ply)
    if (data.lastEnd or 0) <= 0 then return 0 end
    return math_max(0, (data.lastEnd + limits.endCooldown) - os.time())
end

local function StaffRoundElapsed()
    if not zb.ROUND_BEGIN then return 0 end
    return math_max(0, CurTime() - zb.ROUND_BEGIN)
end

local function SendStaffLimits(ply)
    if not IsValid(ply) then return end
    local limits = GetStaffLimits(ply)
    net_Start("ZB_StaffLimits")
    if not limits then
        net_WriteBool(false)
        net_Send(ply)
        return
    end
    net_WriteBool(true)
    net_WriteInt(limits.modes, 16)
    net_WriteInt(StaffModesLeft(ply), 16)
    net_WriteInt(limits.ends, 16)
    net_WriteInt(StaffEndsLeft(ply), 16)
    net_WriteInt(math.floor(StaffEndCooldownLeft(ply)), 32)
    net_WriteInt(limits.minRoundTime, 16)
    net_Send(ply)
end

local function NotifyStaffAction(ply, text)
    if not IsValid(ply) then return end
    local msg = "[Staff] " .. ply:Nick() .. " (" .. (ply:GetUserGroup() or "") .. ") " .. text
    print(msg)
    local admins = GetAdmins(ply)
    for i = 1, #admins do
        admins[i]:ChatPrint(msg)
    end
end

local function CanStaffSetMode(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return true end
    if StaffModesLeft(ply) <= 0 then
        return false, "Суточный лимит смены режимов исчерпан: " .. limits.modes .. " в сутки. Лимит обновится в 00:00."
    end
    return true
end

local function ConsumeStaffMode(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return end
    local data = GetStaffUsage(ply)
    data.modes = (data.modes or 0) + 1
    SaveStaffUsage()
    ply:ChatPrint("Осталось смен режима на сегодня: " .. StaffModesLeft(ply) .. " из " .. limits.modes)
    SendStaffLimits(ply)
end

local function CanStaffEndRound(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return true end
    if (zb.ROUND_STATE or 0) ~= 1 then
        return false, "Раунд ещё не идёт, дождись его начала."
    end
    local elapsed = StaffRoundElapsed()
    if elapsed < limits.minRoundTime then
        return false, "Завершить раунд можно только после " .. math.floor(limits.minRoundTime / 60) .. " мин. игры. Осталось ждать: " .. math.ceil(limits.minRoundTime - elapsed) .. " сек."
    end
    if StaffEndsLeft(ply) <= 0 then
        return false, "Суточный лимит досрочных завершений исчерпан: " .. limits.ends .. " в сутки. Лимит обновится в 00:00."
    end
    local cooldown = StaffEndCooldownLeft(ply)
    if cooldown > 0 then
        return false, "Откат на досрочное завершение: " .. math.ceil(cooldown / 60) .. " мин."
    end
    return true
end

local function ConsumeStaffEndRound(ply)
    local limits = GetStaffLimits(ply)
    if not limits then return end
    local data = GetStaffUsage(ply)
    data.ends = (data.ends or 0) + 1
    data.lastEnd = os.time()
    SaveStaffUsage()
    ply:ChatPrint("Осталось досрочных завершений на сегодня: " .. StaffEndsLeft(ply) .. " из " .. limits.ends)
    SendStaffLimits(ply)
end

function zb.AddFade()
    net_Start("FadeScreen")
    net_Broadcast()
end

function zb:GetMode(round)
    if zb.modes[round] then return round end

    for name, mode in pairs(zb.modes) do
        if mode.Types and mode.Types[round] then
            return name
        end
    end
end

function CurrentRound()
    if HasChangeLevel() then
        zb.nextround = "coop"
        zb.CROUND = zb.CROUND or "coop"
        return zb.modes["coop"]
    end

    zb.CROUND = zb.CROUND or "hmcd"

    if zb.LASTCROUND ~= zb.CROUND or not zb.CROUND_MAIN then
        zb.CROUND_MAIN = zb:GetMode(zb.CROUND)
        zb.LASTCROUND = zb.CROUND
    end

    return zb.modes[zb.CROUND_MAIN], zb.CROUND
end

function NextRound(round)
    if HasChangeLevel() then
        zb.nextround = "coop"
    else
        zb.nextround = round
    end
end

function zb:PreRound()
    if ((((zb.Roundscount or 0) > 15) and not GetConVar("zb_dev"):GetBool()) or ((player_GetCount() > 1) and zb.ROUND_STATE == 0 and zb.CheckRTVVotes())) and not (zb.RoundsLeft and zb.CROUND == "cstrike") then
        zb.StartRTV(20)
        zb.ROUND_STATE = 0
        return
    end

    if zb.ROUND_STATE ~= 0 then return end

    local players = player_GetAll()
    if #players <= 1 then return end

    zb.END_TIME = nil

    local round = CurrentRound()
    zb.START_TIME = zb.START_TIME or CurTime() + (round.start_time or 5)

    if zb.START_TIME < CurTime() then
        zb:RoundStart()
    end
end

function zb:RoundThink()
    if zb.ROUND_STATE ~= 1 then return end
    local round = CurrentRound()
    if round and round.RoundThink then
        round:RoundThink(round)
    end
end

hook.Add("CanListenOthers", "RoundStartChat", function(output, input, isChat, teamonly, text)
    if zb.ROUND_STATE == 0 or zb.ROUND_STATE == 3 then
        return true, false
    end
end)

function zb:EndRound()
    zb.ROUND_STATE = 3
    zb.Roundscount = (zb.Roundscount or 0) + 1

    local mode = CurrentRound()
    SendRoundInfo()

    mode:EndRound()
    hook.Run("ZB_EndRound")
    zb.AddFade()
    hg.achievements.SavePlayerAchievements()
end

function zb:CheckWinner(tbl)
    local foundKey
    local count = 0

    for key, players in pairs(tbl) do
        if next(players) ~= nil then
            count = count + 1
            foundKey = key
            if count > 1 then
                return nil, false
            end
        end
    end

    if count == 1 then
        return true, foundKey
    end

    return true, 3
end

function zb:ShouldRoundEnd()
    local round = CurrentRound()
    local shouldroundend = round:ShouldRoundEnd()

    if shouldroundend == false then
        return false
    end

    local boringround = (zb.ROUND_START + zb.ROUND_TIME) < CurTime()

    if boringround and round.BoringRoundFunction then
        PrintMessage(HUD_PRINTTALK, "Stopping round because it was TOO boring.")
        round:BoringRoundFunction()
    end

    return shouldroundend and true or boringround
end

function zb:EndRoundThink()
    if zb.ROUND_STATE == 1 then
        if zb:ShouldRoundEnd() then
            zb:EndRound()
        end
        return
    end

    if zb.ROUND_STATE ~= 3 then return end

    local round = CurrentRound()

    if not zb.END_TIME then
        zb.END_TIME = CurTime() + (round.end_time or 5)

        if zb.nextround == "coop" and GetGlobalVar("coop_first_round_timer", 0) == 0 then
            zb.END_TIME = CurTime() + 60
            SetGlobalVar("coop_first_round_timer", zb.END_TIME)
        end
    end

    if zb.SHOULD_FADE == nil then
        zb.SHOULD_FADE = true
    end

    if zb.SHOULD_FADE and zb.END_TIME < CurTime() + 1.5 then
        zb.SHOULD_FADE = false
        for _, ply in player.Iterator() do
            ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 1, 7)
        end
    end

    if zb.END_TIME >= CurTime() then return end

    zb.ROUND_STATE = 0
    zb.SHOULD_FADE = true

    hook.Run("ZB_PreRoundStart")

    zb.CROUND = zb.nextround or "hmcd"

    round = CurrentRound()

    if round.shouldfreeze then
        zb:Freeze()
    end

    SendRoundInfo()
    hg.UpdateRoundTime(round.ROUND_TIME, CurTime(), CurTime() + (round.start_time or 5))

    self:KillPlayers()
    self:AutoBalance()

    if hg.PluvTown.Active then
        for _, ply in player.Iterator() do
            ply:SetNetVar("CurPluv", "pluv")
        end
    end

    round.saved = {}
    round:Intermission()
    round:GiveEquipment()
end

hook.Add("PlayerInitialSpawn", "zb_SendRoundAndAdminData", function(ply)
    if zb.CROUND then
        SendRoundInfo(ply)
    end

    if ply.SyncVars then
        ply:SyncVars()
    end

    if not HasMenuAccess(ply) then return end

    timer.Simple(1, function()
        if not IsValid(ply) then return end
        zb.SendModesInfoToClient(ply)
        zb.SendRoundListToClient(ply)
        net_Start("SendAvailableModes")
        net_WriteTable(zb.GetModesSimple())
        net_Send(ply)
    end)
end)

function zb:Think(time)
    if (zb.thinkTime or time) > time then return end
    zb.thinkTime = time + 1
    zb:PreRound()
    zb:RoundThink()
    zb:EndRoundThink()
end

hook.Add("Think", "zb-think", function()
    zb:Think(CurTime())
end)

function zb:KillPlayers()
    local mode = CurrentRound()

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        ply:GiveExp(math_random(4, 15))

        if ply:Alive() and mode.DontKillPlayer and mode:DontKillPlayer(ply) then
            hg.organism.Clear(ply.organism)
            hg.FakeUp(ply, true, true)
            continue
        end

        if ply:FlashlightIsOn() then
            ply:Flashlight(false)
        end

        ply:KillSilent()
        ply:Spawn()
        ply:SetPlayerClass()
    end
end

function zb.GetModes()
    local newtbl = {}
    for name in pairs(zb.modes) do
        newtbl[#newtbl + 1] = name
    end
    return newtbl
end

ZBATTLE_BIGMAP = 5700

hook.Add("InitPostEntity", "zb_init_round_cache", function()
    RefreshChangeLevelState()

    local filik = file_Read("zbattle/mapsizes.json", "DATA")
    if filik then
        local tbl = util_JSONToTable(filik)
        if tbl and tbl[game_GetMap()] then
            ZBATTLE_BIGMAP = tbl[game_GetMap()]
        end
    end

    cachedWorldSize = nil
end)

COMMANDS.bigmap = {
    function(ply, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("You don't have access")
            return
        end

        ZBATTLE_BIGMAP = tonumber(args[1])
        ply:ChatPrint("Distance for big map: " .. ZBATTLE_BIGMAP)
        zb.RerollChances()

        file_CreateDir("zbattle")

        local raw = file_Read("zbattle/mapsizes.json", "DATA")
        local tbl = raw and util_JSONToTable(raw) or {}
        tbl[game_GetMap()] = ZBATTLE_BIGMAP
        file_Write("zbattle/mapsizes.json", util_TableToJSON(tbl))

        ply:ChatPrint("Saved into a file")
    end,
    0
}

zb.BigMaps = {
    ["mu_smallotown_v2_snow"] = true,
    ["mu_smallotown_v2_13"] = true,
    ["mu_smallotown_v2_13_night"] = true,
}

function zb.GetAvailableModes()
    zb.tdm_checkpoints()

    local newtbl = {}

    for _, name in ipairs(zb.GetModes()) do
        local tbl = zb.modes[name]

        if tbl.CanLaunch and tbl:CanLaunch() then
            if tbl.SubModes then
                for _, name2 in pairs(tbl:SubModes()) do
                    newtbl[#newtbl + 1] = name2
                end
            else
                newtbl[#newtbl + 1] = name
            end
        end
    end

    return newtbl
end

function zb.GetModesPlaytime()
    local tbl = zb.GetAvailableModes()
    local newtbl = {}
    local count = 0

    for i = 1, #tbl do
        local name = tbl[i]
        local amt = zb.ModesPlaytime[name] or 0
        newtbl[name] = amt
        count = count + amt
    end

    return newtbl, count
end

function zb.GetModePlaytime(name)
    return zb.ModesPlaytime[name] or 0
end

function zb.SetModePlaytime(name, set)
    zb.ModesPlaytime[name] = set
end

function zb.AddModePlaytime(name, add)
    zb.ModesPlaytime[name] = (zb.ModesPlaytime[name] or 0) + add
end

function zb.AddCurrentModePlayed()
    local mode = CurrentRound()
    if not mode then return end

    local name = mode.name
    if mode.SubModes then
        name = mode.Type or "hmcd"
    end

    zb.AddModePlaytime(name, 1)
end

function zb.GetChance(name, modes, amtplayed)
    local modeName = zb:GetMode(name)
    local tbl = zb.modes[modeName]
    if not tbl then return 0.1 end

    local newtbl = tbl.Types and tbl.Types[name] or tbl
    return newtbl.ChanceFunction and newtbl:ChanceFunction() or newtbl.Chance or 0.1
end

function zb.GetModesChances()
    local tbl = zb.GetAvailableModes()
    local newtbl = {}
    local modes, amtplayed = zb.GetModesPlaytime()

    for i = 1, #tbl do
        local name = tbl[i]
        newtbl[name] = zb.GetChance(name, modes, amtplayed)
    end

    return newtbl
end

function zb.WeightedChanceMode(modes_chances)
    local weight = 0

    for _, chance in pairs(modes_chances) do
        weight = weight + chance * 100
    end

    if weight <= 0 then
        return "hmcd"
    end

    local random = math_random(weight)
    local count = 0

    for name, chance in RandomPairs(modes_chances) do
        count = count + chance * 100
        if count >= random then
            return name
        end
    end

    return "hmcd"
end

function zb.GetWorldSize()
    if cachedWorldSize then
        return cachedWorldSize
    end

    local pts = zb.GetMapPoints("RandomSpawns")
    if not pts or #pts == 0 then
        cachedWorldSize = 0
        return 0
    end

    local minX, minY, minZ
    local maxX, maxY, maxZ

    for i = 1, #pts do
        local pos = pts[i].pos
        local x, y, z = pos.x, pos.y, pos.z

        if not minX then
            minX, minY, minZ = x, y, z
            maxX, maxY, maxZ = x, y, z
        else
            if x < minX then minX = x end
            if y < minY then minY = y end
            if z < minZ then minZ = z end
            if x > maxX then maxX = x end
            if y > maxY then maxY = y end
            if z > maxZ then maxZ = z end
        end
    end

    local dx = maxX - minX
    local dy = maxY - minY
    local dz = maxZ - minZ

    cachedWorldSize = math_sqrt(dx * dx + dy * dy + dz * dz)
    return cachedWorldSize
end

function zb.GetRoundName(name)
    local mode = zb:GetMode(name)
    if not mode or not zb.modes[mode] then return end
    return zb.modes[mode].PrintName
end

function zb.CheckChances()
    if #zb.RoundList == 0 then
        zb.RerollChances()
    end

    local nextrnd = zb.nextround or zb.RoundList[1]
    print("Следуйщий Рауд: " .. (zb.GetRoundName(nextrnd) or "Unknown") .. " (" .. tostring(nextrnd) .. ")")

    if #zb.QueuedModes > 0 then
        print("Queued game modes:")
        for i = 1, #zb.QueuedModes do
            print("  " .. i .. ": " .. (zb.GetRoundName(zb.QueuedModes[i]) or "Unknown") .. " (" .. zb.QueuedModes[i] .. ")")
        end
    else
        for i = 1, #zb.RoundList do
            print("Round " .. (i + 1) .. " will be " .. (zb.GetRoundName(zb.RoundList[i]) or "Unknown") .. " (" .. zb.RoundList[i] .. ")")
        end
    end
end

function zb.RerollChances()
    local chances = zb.GetModesChances()
    local roundList = {}

    for i = 1, 20 do
        roundList[i] = zb.WeightedChanceMode(chances)
    end

    zb.RoundList = roundList
    zb.nextround = table_remove(zb.RoundList, 1)
end

function zb.GetModesInfo()
    cachedModesInfo = nil

    local modesInfo = {}

    for name, mode in pairs(zb.modes) do
        if mode.Types then
            for name2 in pairs(mode.Types) do
                modesInfo[#modesInfo + 1] = {
                    key = name2,
                    name = (mode.PrintName or mode.name or name) .. "/" .. name2,
                    description = mode.Description or "",
                    forBigMaps = mode.ForBigMaps or false,
                    canlaunch = (mode:CanLaunch() and 1 or 0)
                }
            end
        else
            modesInfo[#modesInfo + 1] = {
                key = name,
                name = mode.PrintName or mode.name or name,
                description = mode.Description or "",
                forBigMaps = mode.ForBigMaps or false,
                canlaunch = (mode:CanLaunch() and 1 or 0)
            }
        end
    end

    cachedModesInfo = modesInfo
    return modesInfo
end

function zb.GetModesSimple()
    cachedModesSimple = nil

    local modesToSend = {}
    for key, mode in pairs(zb.modes) do
        modesToSend[#modesToSend + 1] = {
            key = key,
            name = mode.PrintName or mode.name
        }
    end

    cachedModesSimple = modesToSend
    return modesToSend
end

function zb.SetRoundList(newList)
    local newLista = table.Copy(newList)

    if #newLista > 0 then
        zb.nextround = table_remove(newLista, 1)
        zb.RoundList = newLista
    else
        zb.RerollChances()
        zb.nextround = table_remove(zb.RoundList, 1)
    end
end

function zb.SendModesInfoToClient(ply)
    net_Start("ZB_SendModesInfo")
    net_WriteTable(zb.GetModesInfo())
    net_Send(ply)
end

function zb.SendRoundListToClient(ply)
    net_Start("ZB_SendRoundList")
    net_WriteTable(zb.RoundList)
    net_WriteString(zb.nextround or "")
    net_Send(ply)
end

net.Receive("ZB_RequestRoundList", function(_, ply)
    if not HasMenuAccess(ply) then return end
    zb.SendModesInfoToClient(ply)
    zb.SendRoundListToClient(ply)
    SendStaffLimits(ply)
end)

net.Receive("ZB_UpdateRoundList", function(_, ply)
    if not CanManageQueue(ply) then return end

    local newList = net_ReadTable()
    local forceUpdate = net_ReadBool()

    zb.SetRoundList(newList)

    net_Start("ZB_NotifyRoundListChange")
    net_WriteString(ply:Nick())
    net_Send(zb.GetAllAdmins())

    local staff = GetMenuUsers()
    for i = 1, #staff do
        zb.SendRoundListToClient(staff[i])
    end
end)

function zb:RoundStart()
    local mode, roundName = CurrentRound()

    if mode.shouldfreeze then
        zb:Unfreeze()
    end

    zb.ROUND_STATE = 1
    zb.START_TIME = nil

    VFIRE_DISABLED = (mode.name == "coop")

    zb.ROUND_BEGIN = CurTime()
    hg.UpdateRoundTime()

    SendRoundInfo()

    local forced = forcemodeconvar:GetString()
    if forced ~= "" then
        forcemode = forced
    end

    zb.AddCurrentModePlayed()

    mode:RoundStart()

    if #zb.RoundList == 0 then
        zb.RerollChances()
    end

    local nextMode = table_remove(zb.RoundList, 1)
    print("Следующий режим игры " .. tostring(nextMode))

    NextRound(forcemode ~= "random" and forcemode or (nextMode or "hmcd"))

    if mode.RoundStartPost then
        mode:RoundStartPost()
    end

    hook.Run("ZB_StartRound")

    local staff = GetMenuUsers()
    for i = 1, #staff do
        zb.SendRoundListToClient(staff[i])
    end
end

concommand.Add("zb_checkchances", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    zb.CheckChances()
end)

concommand.Add("zb_rerollchances", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    zb.RerollChances()
    zb.CheckChances()
end)

function zb.NotifyQueueEmptied()
    net_Start("QueueEmptiedNotification")
    net_Send(zb.GetAllAdmins())
end

function zb.SyncQueueToAdmins()
    timer.Simple(0.1, function()
        net_Start("SendGameQueue")
        net_WriteTable(zb.QueuedModes)
        net_Send(zb.GetAllAdmins())
    end)
end

function zb.NotifyQueueModified(ply, action)
    local recipients = GetAdmins(ply)
    if #recipients == 0 then return end

    net_Start("QueueModifiedNotification")
    net_WriteString(IsValid(ply) and ply:Nick() or "Server")
    net_WriteString(action)
    net_Send(recipients)
end

net.Receive("AdminSetGameMode", function(_, ply)
    if not HasMenuAccess(ply) then return end

    local command = net_ReadString()
    local modeKey = net_ReadString()
    local addToQueue = net_ReadBool() or false
    local modeObj = zb.modes[modeKey] or zb.modes[zb:GetMode(modeKey)]

    if command == "setforcemode" and not ply:IsAdmin() then return end
    if addToQueue and not ply:IsAdmin() then return end
    if command ~= "setmode" and command ~= "setforcemode" then return end

    if not CanSetNextMode(ply, modeObj) then
        ply:ChatPrint("This mode can't launch (No points or Is blocked): " .. modeKey)
        return
    end

    local allowedMode, modeReason = CanStaffSetMode(ply)
    if not allowedMode then
        ply:ChatPrint(modeReason)
        SendStaffLimits(ply)
        return
    end

    if command == "setmode" then
        NextRound(modeKey)
        ply:ChatPrint("Game mode set to: " .. modeKey)

        if addToQueue then
            zb.QueuedModes[#zb.QueuedModes + 1] = modeKey
            zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")
            zb.SyncQueueToAdmins()
        end
    elseif command == "setforcemode" then
        forcemode = modeKey
        NextRound(forcemode)
        ply:ChatPrint("Force mode set to: " .. modeKey)

        if addToQueue then
            zb.QueuedModes[#zb.QueuedModes + 1] = modeKey
            zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")
            zb.SyncQueueToAdmins()
        end
    end

    ConsumeStaffMode(ply)
    NotifyStaffAction(ply, "поставил следующим режимом: " .. modeKey)

    local staff = GetMenuUsers()
    for i = 1, #staff do
        zb.SendRoundListToClient(staff[i])
    end
end)

net.Receive("AdminEndRound", function(_, ply)
    if not CanEndRound(ply) then return end

    local allowedEnd, endReason = CanStaffEndRound(ply)
    if not allowedEnd then
        ply:ChatPrint(endReason)
        SendStaffLimits(ply)
        return
    end

    ConsumeStaffEndRound(ply)
    NotifyStaffAction(ply, "досрочно завершил раунд")
    ply:ChatPrint("Раунд окончен!")
    zb:EndRound()
end)

net.Receive("AdminSetGameQueue", function(_, ply)
    if not CanManageQueue(ply) then return end

    local modeQueue = net_ReadTable()
    zb.QueuedModes = modeQueue

    if #modeQueue == 0 then
        ply:ChatPrint("Game mode queue has been cleared")
        zb.NotifyQueueModified(ply, "cleared")

        timer.Simple(0.2, function()
            net_Start("QueueEmptiedNotification")
            net_Send(zb.GetAllAdmins())
        end)
    else
        ply:ChatPrint("Game mode queue set with " .. #modeQueue .. " modes")
        zb.NotifyQueueModified(ply, "updated")
    end

    zb.SyncQueueToAdmins()
end)

function zb:Unfreeze()
    for _, ply in player.Iterator() do
        if ply:Alive() then
            ply:Freeze(false)
        end
    end
end

function zb:Freeze()
    for _, ply in player.Iterator() do
        if ply:Alive() then
            ply:Freeze(true)
        end
    end
end

function zb.GetAllAdmins()
    return GetAdmins()
end

COMMANDS.setmode = {
    function(ply, args)
        if not HasMenuAccess(ply) then
            ply:ChatPrint("У тебя нет доступа")
            return
        end

        if not args[1] or (not zb:GetMode(args[1]) and args[1] ~= "random") then
            return
        end

        if not ply:IsAdmin() and args[1] == "random" then
            ply:ChatPrint("У тебя нет доступа")
            return
        end

        local allowedMode, modeReason = CanStaffSetMode(ply)
        if not allowedMode then
            ply:ChatPrint(modeReason)
            return
        end

        ply:ChatPrint(args[1])
        NextRound(args[1])
        ConsumeStaffMode(ply)
        NotifyStaffAction(ply, "поставил следующим режимом: " .. args[1])
    end,
    0
}

COMMANDS.setforcemode = {
    function(ply, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("У тебя нет доступа")
            return
        end

        if not args[1] or (not zb:GetMode(args[1]) and args[1] ~= "random") then
            return
        end

        ply:ChatPrint(args[1])
        forcemode = args[1]

        if args[1] ~= "random" then
            NextRound(args[1])
        end
    end,
    0
}

COMMANDS.endround = {
    function(ply)
        if not CanEndRound(ply) then
            ply:ChatPrint("У тебя нет доступа")
            return
        end

        local allowedEnd, endReason = CanStaffEndRound(ply)
        if not allowedEnd then
            ply:ChatPrint(endReason)
            return
        end

        ConsumeStaffEndRound(ply)
        NotifyStaffAction(ply, "досрочно завершил раунд")
        zb:EndRound()
    end,
    0
}

hook.Add("PostCleanupMap", "zb_clear_worldsize_cache", function()
    RefreshChangeLevelState()
    cachedWorldSize = nil
end)
