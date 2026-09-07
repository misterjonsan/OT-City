MODE.name = "hl2dm"
MODE.PrintName = "Half-Life 2"
MODE.start_time = 6
MODE.end_time = 6

MODE.ROUND_TIME = 450
MODE.LootSpawn = false
MODE.OverideSpawnPos = true
MODE.ForBigMaps = true
MODE.Chance = 0.16

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

function MODE:CanLaunch()
    do return false end
    local pointsA = zb.GetMapPoints("HMCD_HL2DM_COMBINE")
    local pointsB = zb.GetMapPoints("HMCD_HL2DM_REBEL")
    return (#pointsA > 0) and (#pointsB > 0)
end

util.AddNetworkString("HL2DM_start")
util.AddNetworkString("HL2DM_score")
util.AddNetworkString("HL2DM_roundend")
util.AddNetworkString("HL2DM_reinforce")
util.AddNetworkString("HL2DM_status")

local function BroadcastScore(score)
    net.Start("HL2DM_score")
        net.WriteTable(score or {
            [0] = 0,
            [1] = 0
        })
    net.Broadcast()
end

local function GetRealAttacker(attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        return attacker
    end

    if IsValid(attacker) then
        local owner = attacker.GetOwner and attacker:GetOwner() or nil
        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end
    end

    if IsValid(inflictor) then
        if inflictor:IsPlayer() then
            return inflictor
        end

        local owner = inflictor.GetOwner and inflictor:GetOwner() or nil
        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end
    end

    return nil
end

local function AssignHL2DMTeams()
    local players = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then
            table.insert(players, ply)
        end
    end

    local playerCount = #players
    if playerCount <= 0 then return end

    for i = #players, 2, -1 do
        local j = math.random(i)
        players[i], players[j] = players[j], players[i]
    end

    local combineCount = math.max(1, math.ceil(playerCount / 3))

    for i, ply in ipairs(players) do
        if i <= combineCount then
            ply:SetTeam(1)
        else
            ply:SetTeam(0)
        end
    end
end

local function GiveEquip(ply, teamId)
    if teamId == 1 then
        ply:SetPlayerClass("Combine")
        zb.GiveRole(ply, "Альянс", Color(0, 210, 255))
    else
        ply:SetPlayerClass("Refugee")
        zb.GiveRole(ply, "Сопротивление", Color(40, 170, 70))
    end

    ply:PlayerClassEvent("GiveEquipment")
end

local function CountAliveForTeam(teamId)
    local count = 0

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= teamId then continue end
        if not ply:Alive() then continue end
        if ply.Lives and ply.Lives < 1 then continue end
        if ply.organism and ply.organism.incapacitated and ply.Lives and ply.Lives < 1 then continue end
        count = count + 1
    end

    return count
end

function MODE:GetLosingTeam()
    self.Score = self.Score or {
        [0] = 0,
        [1] = 0
    }

    local rebelScore = tonumber(self.Score[0]) or 0
    local combineScore = tonumber(self.Score[1]) or 0

    if rebelScore < combineScore then
        return 0
    elseif combineScore < rebelScore then
        return 1
    end

    local rebelAlive = CountAliveForTeam(0)
    local combineAlive = CountAliveForTeam(1)

    if rebelAlive < combineAlive then
        return 0
    elseif combineAlive < rebelAlive then
        return 1
    end

    local rebelTotal = 0
    local combineTotal = 0

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == 0 then
            rebelTotal = rebelTotal + 1
        elseif ply:Team() == 1 then
            combineTotal = combineTotal + 1
        end
    end

    if rebelTotal < combineTotal then
        return 0
    elseif combineTotal < rebelTotal then
        return 1
    end

    return nil
end

function MODE:GetReinforcementTimeLeft()
    local roundBegin = zb.ROUND_BEGIN or CurTime()
    return math.max(0, 120 - (CurTime() - roundBegin))
end

function MODE:BroadcastStatus(target)
    self.Score = self.Score or {
        [0] = 0,
        [1] = 0
    }

    local losingTeam = self:GetLosingTeam()
    local timeLeft = self:GetReinforcementTimeLeft()
    local spawned = self.ReinforcementSpawned or false
    local reinforceTeam = self.ReinforcementTeam

    net.Start("HL2DM_status")
        net.WriteTable(self.Score)
        net.WriteFloat(timeLeft)
        net.WriteInt(losingTeam ~= nil and losingTeam or -1, 4)
        net.WriteBool(spawned)
        net.WriteInt(reinforceTeam ~= nil and reinforceTeam or -1, 4)
    if target then
        net.Send(target)
    else
        net.Broadcast()
    end
end

function MODE:Intermission()
    game.CleanUpMap()

    AssignHL2DMTeams()

    self.Score = {
        [0] = 0,
        [1] = 0
    }

    self.ReinforcementSpawned = false
    self.ReinforcementTeam = nil
    self.NextStateBroadcast = 0

    self.COMBINEPoints = {}
    table.CopyFromTo(zb.GetMapPoints("HMCD_HL2DM_COMBINE"), self.COMBINEPoints)

    self.REBELPoints = {}
    table.CopyFromTo(zb.GetMapPoints("HMCD_HL2DM_REBEL"), self.REBELPoints)

    local combinePos
    local rebelPos

    for i, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end

        ply:SetFrags(0)

        local pos
        if ply:Team() == 1 then
            if not combinePos then
                combinePos = (#self.COMBINEPoints > 0 and self.COMBINEPoints[1].pos) or zb:GetRandomSpawn()
                pos = combinePos
            else
                pos = hg.tpPlayer(combinePos, ply, i, 0)
            end
        end

        if ply:Team() == 0 then
            if not rebelPos then
                rebelPos = (#self.REBELPoints > 0 and self.REBELPoints[1].pos) or zb:GetRandomSpawn()
                pos = rebelPos
            else
                pos = hg.tpPlayer(rebelPos, ply, i, 0)
            end
        end

        ply:SetupTeam(ply:Team())
        ply.Lives = 1
        ply.timeDeath = nil

        if pos then
            ply:SetPos(pos)
        end
    end

    net.Start("HL2DM_start")
    net.Broadcast()

    BroadcastScore(self.Score)
    self:BroadcastStatus()
end

local player_GetAll = player.GetAll
local team_GetAllTeams = team.GetAllTeams

function MODE:CheckAlivePlayers()
    local tbl = {}

    for i, info in pairs(team_GetAllTeams()) do
        if i == TEAM_UNASSIGNED or i == TEAM_SPECTATOR then continue end
        tbl[i] = {}
    end

    for _, ply in ipairs(player_GetAll()) do
        if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then continue end
        if (not ply:Alive()) and ply.Lives and ply.Lives < 1 then continue end
        if ply.organism and ply.organism.incapacitated and ply.Lives and ply.Lives < 1 then continue end

        tbl[ply:Team() or 0] = tbl[ply:Team() or 0] or {}
        tbl[ply:Team()][(#tbl[ply:Team() or 0] or 0) + 1] = ply
    end

    return tbl
end

function MODE:ShouldRoundEnd()
    local endround = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end

function MODE:GetPlySpawn(ply)
    if ply:Team() == 1 then
        if self.COMBINEPoints and #self.COMBINEPoints > 0 then
            ply:SetPos(self.COMBINEPoints[#self.COMBINEPoints].pos)
            if #self.COMBINEPoints > 1 then
                table.remove(self.COMBINEPoints)
            end
        end
    else
        if self.REBELPoints and #self.REBELPoints > 0 then
            ply:SetPos(self.REBELPoints[#self.REBELPoints].pos)
            if #self.REBELPoints > 1 then
                table.remove(self.REBELPoints)
            end
        end
    end
end

function MODE:GiveEquipment()
    self.COMBINEPoints = {}
    table.CopyFromTo(zb.GetMapPoints("HMCD_HL2DM_COMBINE"), self.COMBINEPoints)

    self.REBELPoints = {}
    table.CopyFromTo(zb.GetMapPoints("HMCD_HL2DM_REBEL"), self.REBELPoints)

    timer.Simple(0.1, function()
        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() then continue end

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true

            GiveEquip(ply, ply:Team())
            ply.Lives = 1
            ply.timeDeath = nil

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply.noSound = false
                end
            end)

            ply:SetSuppressPickupNotices(false)
        end
    end)
end

function MODE:SpawnReinforcements(teamId)
    local deadPlayers = {}

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= teamId then continue end
        if ply:Alive() then continue end
        table.insert(deadPlayers, ply)
    end

    if #deadPlayers <= 0 then
        self.ReinforcementSpawned = true
        self.ReinforcementTeam = teamId

        net.Start("HL2DM_reinforce")
            net.WriteUInt(teamId, 3)
        net.Broadcast()

        self:BroadcastStatus()
        return
    end

    local spawnPoints = teamId == 1 and (self.COMBINEPoints or zb.GetMapPoints("HMCD_HL2DM_COMBINE")) or (self.REBELPoints or zb.GetMapPoints("HMCD_HL2DM_REBEL"))
    local startPos = spawnPoints and spawnPoints[1] and spawnPoints[1].pos or zb:GetRandomSpawn()

    for i = 1, math.min(4, #deadPlayers) do
        local ply = deadPlayers[i]
        if not IsValid(ply) then continue end

        ply:Spawn()
        ply:SetupTeam(teamId)
        ply.Lives = 1
        ply.timeDeath = nil

        if startPos then
            if i == 1 then
                ply:SetPos(startPos)
            else
                hg.tpPlayer(startPos, ply, i, 0)
            end
        end

        ply:SetSuppressPickupNotices(true)
        ply.noSound = true

        GiveEquip(ply, teamId)

        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply.noSound = false
                ply:SetSuppressPickupNotices(false)
            end
        end)
    end

    self.ReinforcementSpawned = true
    self.ReinforcementTeam = teamId

    net.Start("HL2DM_reinforce")
        net.WriteUInt(teamId, 3)
    net.Broadcast()

    self:BroadcastStatus()
end

function MODE:RoundStart()
    self.ReinforcementSpawned = false
    self.ReinforcementTeam = nil
    self.NextStateBroadcast = 0
    self:BroadcastStatus()
end

function MODE:RoundThink()
    if not self.ReinforcementSpawned and CurTime() >= (self.NextStateBroadcast or 0) then
        self.NextStateBroadcast = CurTime() + 1
        self:BroadcastStatus()
    end

    if self.ReinforcementSpawned then return end
    if (CurTime() - (zb.ROUND_BEGIN or CurTime())) < 120 then return end

    local losingTeam = self:GetLosingTeam()
    if losingTeam == nil then
        self.ReinforcementSpawned = true
        self.ReinforcementTeam = nil
        self:BroadcastStatus()
        return
    end

    self:SpawnReinforcements(losingTeam)
end

function MODE:GetTeamSpawn()
    return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_HL2DM_COMBINE")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_HL2DM_REBEL"))
end

function MODE:CanSpawn()
end

function MODE:PlayerDeath(ply, inflictor, attacker)
    if not IsValid(ply) then return end
    ply.Lives = 0
    ply.timeDeath = nil
end

function MODE:EndRound()
    timer.Simple(0.5, function()
        net.Start("HL2DM_roundend")
        net.Broadcast()
    end)

    local _, winner = zb:CheckWinner(self:CheckAlivePlayers())
    for _, ply in player.Iterator() do
        if ply:Team() == winner then
            ply:GiveExp(math.random(15, 30))
            ply:GiveSkill(math.Rand(0.1, 0.15))
        else
            ply:GiveSkill(math.Rand(0.01, 0.05))
        end
    end
end

hook.Add("PlayerDeath", "HL2DM_ScoreFix", function(victim, inflictor, attacker)
    local MODE = zb:GetCurrentMode()
    if not MODE or MODE.name ~= "hl2dm" then return end
    if not IsValid(victim) then return end

    MODE.Score = MODE.Score or {
        [0] = 0,
        [1] = 0
    }

    victim.Lives = 0
    victim.timeDeath = nil

    local killer = GetRealAttacker(attacker, inflictor)
    if not IsValid(killer) then
        MODE:BroadcastStatus()
        return
    end

    if killer == victim then
        MODE:BroadcastStatus()
        return
    end

    local atkTeam = killer:Team()
    local vicTeam = victim:Team()

    if atkTeam == TEAM_SPECTATOR or atkTeam == TEAM_UNASSIGNED then
        MODE:BroadcastStatus()
        return
    end

    if vicTeam == TEAM_SPECTATOR or vicTeam == TEAM_UNASSIGNED then
        MODE:BroadcastStatus()
        return
    end

    if atkTeam == vicTeam then
        MODE:BroadcastStatus()
        return
    end

    killer:AddFrags(1)

    MODE.Score[atkTeam] = (MODE.Score[atkTeam] or 0) + 1
    BroadcastScore(MODE.Score)
    MODE:BroadcastStatus()
end)

hook.Add("PlayerInitialSpawn", "HL2DM_SendStateOnJoin", function(ply)
    timer.Simple(1, function()
        local MODE = zb:GetCurrentMode()
        if not MODE or MODE.name ~= "hl2dm" then return end
        if not IsValid(ply) then return end
        MODE:BroadcastStatus(ply)
    end)
end)