zb = zb or {}
zb.Points = zb.Points or {}
zb.Points.Example = zb.Points.Example or {}

local function zb_msg(txt)
    print("[zb points] " .. tostring(txt))
end

function zb.RegisterPointGroup(pointGroup, data)
    if not isstring(pointGroup) or pointGroup == "" then return false end

    zb.Points[pointGroup] = zb.Points[pointGroup] or {}
    zb.Points[pointGroup].Name = zb.Points[pointGroup].Name or pointGroup
    zb.Points[pointGroup].Color = zb.Points[pointGroup].Color or Color(255, 255, 255)
    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or {}

    if istable(data) then
        for k, v in pairs(data) do
            zb.Points[pointGroup][k] = v
        end
        zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or {}
    end

    return true
end

function zb.EnsurePointGroup(pointGroup)
    if not isstring(pointGroup) or pointGroup == "" then return false end
    if zb.Points[pointGroup] then return true end
    return zb.RegisterPointGroup(pointGroup)
end

function zb.CreateMapDir()
    local map = game.GetMap()
    if not file.Exists("zbattle", "DATA") then
        file.CreateDir("zbattle")
    end
    if not file.Exists("zbattle/mappoints", "DATA") then
        file.CreateDir("zbattle/mappoints")
    end
    if not file.Exists("zbattle/mappoints/" .. map, "DATA") then
        file.CreateDir("zbattle/mappoints/" .. map)
    end
    return file.Exists("zbattle/mappoints/" .. map, "DATA")
end

local function normalizePoint(point)
    if not istable(point) then return nil end
    if not isvector(point.pos) then return nil end
    if not isangle(point.ang) then
        point.ang = Angle(0, 0, 0)
    end
    return {
        pos = point.pos,
        ang = point.ang
    }
end

local function normalizePoints(pointsData)
    local result = {}

    if not istable(pointsData) then
        return result
    end

    for _, point in pairs(pointsData) do
        if isvector(point) then
            result[#result + 1] = {
                pos = point,
                ang = Angle(0, 0, 0)
            }
        elseif istable(point) then
            local norm = normalizePoint(point)
            if norm then
                result[#result + 1] = norm
            end
        end
    end

    return result
end

function zb.GetMapPoints(pointGroup, forceupdatepoints)
    if not zb.CreateMapDir() then
        zb_msg("map folder doesn't exist")
        return {}
    end

    if not zb.EnsurePointGroup(pointGroup) then
        zb_msg("invalid point group")
        return {}
    end

    forceupdatepoints = forceupdatepoints or false

    if (not forceupdatepoints) and istable(zb.Points[pointGroup].Points) then
        local cached = {}
        table.CopyFromTo(zb.Points[pointGroup].Points, cached)
        return cached
    end

    local map = game.GetMap()
    local path = "zbattle/mappoints/" .. map .. "/" .. pointGroup .. ".json"
    local raw = file.Read(path, "DATA")
    local decoded = util.JSONToTable(raw or "")
    local points = normalizePoints(decoded)

    zb.Points[pointGroup].Points = points

    local newTbl = {}
    table.CopyFromTo(points, newTbl)
    return newTbl
end

function zb.SaveMapPoints(pointGroup, pointsData)
    if not zb.CreateMapDir() then
        zb_msg("map folder doesn't exist")
        return false
    end

    if not zb.EnsurePointGroup(pointGroup) then
        zb_msg("invalid point group")
        return false
    end

    local map = game.GetMap()
    local path = "zbattle/mappoints/" .. map .. "/" .. pointGroup .. ".json"
    local normalized = normalizePoints(pointsData)

    zb.Points[pointGroup].Points = normalized
    file.Write(path, util.TableToJSON(normalized, true))

    return true
end

function zb.CreateMapPoint(pointGroup, pointData, needsave)
    if not zb.CreateMapDir() then
        zb_msg("map folder doesn't exist")
        return false
    end

    if not zb.EnsurePointGroup(pointGroup) then
        zb_msg("invalid point group")
        return false
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints(pointGroup)

    local normalized = normalizePoint(pointData)
    if not normalized then
        zb_msg("invalid point data")
        return false
    end

    zb.Points[pointGroup].Points[#zb.Points[pointGroup].Points + 1] = normalized

    if needsave ~= false then
        zb.SaveMapPoints(pointGroup, zb.Points[pointGroup].Points)
    end

    return true
end

function zb.RemoveMapPoint(pointGroup, pointNum, needsave, removeall)
    if not zb.CreateMapDir() then
        zb_msg("map folder doesn't exist")
        return false
    end

    if not zb.EnsurePointGroup(pointGroup) then
        zb_msg("invalid point group")
        return false
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints(pointGroup)
    removeall = removeall or false

    if removeall then
        zb.Points[pointGroup].Points = {}
    else
        local idx = math.Clamp(tonumber(pointNum) or 0, 1, #zb.Points[pointGroup].Points)
        if not zb.Points[pointGroup].Points[idx] then
            zb_msg("point doesn't exist")
            return false
        end
        table.remove(zb.Points[pointGroup].Points, idx)
    end

    if needsave ~= false then
        zb.SaveMapPoints(pointGroup, zb.Points[pointGroup].Points)
    end

    return true
end

function zb.SetMapPoint(pointGroup, pointNum, pointData, needsave)
    if not zb.CreateMapDir() then
        zb_msg("map folder couldn't be created")
        return false
    end

    if not zb.EnsurePointGroup(pointGroup) then
        zb_msg("invalid point group")
        return false
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints(pointGroup)

    local idx = math.Clamp(tonumber(pointNum) or 0, 1, #zb.Points[pointGroup].Points)
    if not zb.Points[pointGroup].Points[idx] then
        zb_msg("point doesn't exist")
        return false
    end

    local normalized = normalizePoint(pointData)
    if not normalized then
        zb_msg("invalid point data")
        return false
    end

    zb.Points[pointGroup].Points[idx] = normalized

    if needsave ~= false then
        zb.SaveMapPoints(pointGroup, zb.Points[pointGroup].Points)
    end

    return true
end

function zb.GetAllPoints(forceupdate)
    local allpoints = {}
    forceupdate = forceupdate or false

    for pointGroup, _ in pairs(zb.Points) do
        local pointgroups = zb.GetMapPoints(pointGroup, forceupdate)
        allpoints[pointGroup] = pointgroups or {}
    end

    hook.Run("ZB_AfterAllPoints", zb.Points)

    return allpoints
end

hook.Add("InitPostEntity", "zb_init_points_cache", function()
    zb.GetAllPoints(true)
end)

hook.Add("Initialize", "LoadMapPoints", function()
    zb.CreateMapDir()
end)

COMMANDS.pointnew = {
    function(ply, args)
        local pointGroup = args[1]
        if not pointGroup or pointGroup == "" then return end

        local ang = ply:EyeAngles()
        ang.x = 0

        local pointData = {
            pos = ply:GetPos(),
            ang = ang
        }

        zb.CreateMapPoint(pointGroup, pointData, true)
        ply:ConCommand("zb_pointsupdate")
    end,
    1,
    "Creates a new point on the map\nArgs - pointGroup"
}

COMMANDS.pointset = {
    function(ply, args)
        local pointGroup = args[1]
        local pointNum = tonumber(args[2])

        if not pointGroup or not pointNum then return end

        local ang = ply:EyeAngles()
        ang.x = 0

        local pointData = {
            pos = ply:GetPos(),
            ang = ang
        }

        zb.SetMapPoint(pointGroup, pointNum, pointData, true)
        ply:ConCommand("zb_pointsupdate")
    end,
    2,
    "Sets a point on the map\nArgs - pointGroup, pointNumber"
}

COMMANDS.pointremove = {
    function(ply, args)
        local pointGroup = args[1]
        local pointNum = args[2]

        if not pointGroup or not pointNum then return end

        zb.RemoveMapPoint(pointGroup, pointNum, true, pointNum == "*")
        ply:ConCommand("zb_pointsupdate")
    end,
    2,
    "Remove point (points) on the map\nArgs - pointGroup, pointNumber ( * - allpoints )"
}

function zb.SendPointsToPly(ply, shouldprint)
    net.Start("zb_getallpoints")
        net.WriteTable(zb.GetAllPoints())
    net.Send(ply)

    if shouldprint then
        ply:ChatPrint("Points: Points transferred")
    end
end

function zb.SendPoints()
    local rf = RecipientFilter()

    for _, v in player.Iterator() do
        rf:AddPlayer(v)
    end

    net.Start("zb_getallpoints")
        net.WriteTable(zb.GetAllPoints())
    net.Send(rf)
end

function zb.SendSpecificPointsToPly(ply, pointGroup, shouldprint)
    zb.EnsurePointGroup(pointGroup)

    net.Start("zb_getspecificpoints")
        net.WriteString(pointGroup)
        net.WriteTable(zb.GetAllPoints()[pointGroup] or {})
    if IsValid(ply) then
        net.Send(ply)

        if shouldprint then
            ply:ChatPrint("Points: Points transferred")
        end
    else
        net.Broadcast()
    end
end

local angZero = Angle(0, 0, 0)

function zb.TranslateVectorsToPoints(tbl)
    local newtbl = {}

    for _, val in pairs(tbl or {}) do
        if istable(val) then
            if val.pos and val.ang and isvector(val.pos) and isangle(val.ang) then
                table.insert(newtbl, {
                    pos = val.pos,
                    ang = val.ang
                })
            end
        elseif isvector(val) then
            table.insert(newtbl, {
                pos = val,
                ang = angZero
            })
        end
    end

    return newtbl
end

function zb.TranslatePointsToVectors(tbl)
    local newtbl = {}

    for _, val in pairs(tbl or {}) do
        if istable(val) then
            if val.pos and val.ang and isvector(val.pos) and isangle(val.ang) then
                table.insert(newtbl, val.pos)
            end
        elseif isvector(val) then
            table.insert(newtbl, val)
        end
    end

    return newtbl
end

net.Receive("zb_getallpoints", function(len, ply)
    if not ply:IsAdmin() then
        ply:ChatPrint("Points: Access denied")
        return
    end

    zb.SendPointsToPly(ply, true)
end)

function zb.tdm_checkpoints()
    zb.RegisterPointGroup("HMCD_TDM_T")
    zb.RegisterPointGroup("RIOT_TDM_RIOTERS")
    zb.RegisterPointGroup("HMCD_SWO_AZOV")
    zb.RegisterPointGroup("HMCD_CRI_T")
    zb.RegisterPointGroup("HMCD_TDM_CT")
    zb.RegisterPointGroup("HMCD_CRI_CT")
    zb.RegisterPointGroup("RIOT_TDM_LAW")
    zb.RegisterPointGroup("HMCD_SWO_WAGNER")
    zb.RegisterPointGroup("BOMB_ZONE_A")
    zb.RegisterPointGroup("BOMB_ZONE_B")
    zb.RegisterPointGroup("HOSTAGE_DELIVERY_ZONE")

    local vecsT = {}
    local pointsT = zb.GetMapPoints("HMCD_TDM_T")

    for _, ent in pairs(ents.FindByClass("info_player_terrorist")) do
        table.insert(vecsT, ent:GetPos())
    end

    pointsT = (#pointsT == 0) and zb.TranslateVectorsToPoints(vecsT) or pointsT

    if #zb.GetMapPoints("HMCD_TDM_T") == 0 then
        zb.SaveMapPoints("HMCD_TDM_T", pointsT)
    end
    if #zb.GetMapPoints("RIOT_TDM_RIOTERS") == 0 then
        zb.SaveMapPoints("RIOT_TDM_RIOTERS", pointsT)
    end
    if #zb.GetMapPoints("HMCD_SWO_AZOV") == 0 then
        zb.SaveMapPoints("HMCD_SWO_AZOV", pointsT)
    end
    if #zb.GetMapPoints("HMCD_CRI_T") == 0 then
        zb.SaveMapPoints("HMCD_CRI_T", pointsT)
    end

    local vecsCT = {}
    local pointsCT = zb.GetMapPoints("HMCD_TDM_CT")

    for _, ent in pairs(ents.FindByClass("info_player_counterterrorist")) do
        table.insert(vecsCT, ent:GetPos())
    end

    pointsCT = (#pointsCT == 0) and zb.TranslateVectorsToPoints(vecsCT) or pointsCT

    if #zb.GetMapPoints("HMCD_TDM_CT") == 0 then
        zb.SaveMapPoints("HMCD_TDM_CT", pointsCT)
    end
    if #zb.GetMapPoints("HMCD_CRI_CT") == 0 then
        zb.SaveMapPoints("HMCD_CRI_CT", pointsCT)
    end
    if #zb.GetMapPoints("RIOT_TDM_LAW") == 0 then
        zb.SaveMapPoints("RIOT_TDM_LAW", pointsCT)
    end
    if #zb.GetMapPoints("HMCD_SWO_WAGNER") == 0 then
        zb.SaveMapPoints("HMCD_SWO_WAGNER", pointsCT)
    end

    local foundA = false
    local foundB = false

    for _, ent in ipairs(ents.FindByClass("func_bomb_target")) do
        local vecs = {}
        local min, max = ent:WorldSpaceAABB()

        vecs[1] = min
        vecs[2] = max

        if not foundB then
            zb.SaveMapPoints("BOMB_ZONE_B", zb.TranslateVectorsToPoints(vecs))
            foundB = true
            continue
        end

        if not foundA then
            zb.SaveMapPoints("BOMB_ZONE_A", zb.TranslateVectorsToPoints(vecs))
            foundA = true
            continue
        end
    end

    local hostagePoints = {}

    for _, ent in pairs(ents.FindByClass("func_hostage_rescue")) do
        local min, max = ent:WorldSpaceAABB()
        table.insert(hostagePoints, min)
        table.insert(hostagePoints, max)
    end

    hostagePoints = zb.TranslateVectorsToPoints(hostagePoints)

    if #zb.GetMapPoints("HOSTAGE_DELIVERY_ZONE") == 0 then
        zb.SaveMapPoints("HOSTAGE_DELIVERY_ZONE", hostagePoints)
    end
end

hook.Add("PostCleanupMap", "zb_autofill_t_ct_spawns", function()
    zb.tdm_checkpoints()
end)