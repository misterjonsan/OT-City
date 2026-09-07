MODE.name = "shooter"
MODE.PrintName = "Ночной вынос"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 480
MODE.LootSpawn = true
MODE.Chance = 0

local ROLE_COLORS = {
    victim = Color(15, 228, 129),
    shooter = Color(228, 49, 49),
    swat = Color(68, 10, 255)
}

local VICTIM_ROLES = {
    { name = "Паникёр", desc = "Бегаешь кругами, орёшь в войс и гениально находишь только мусор." },
    { name = "Лутер на опыте", desc = "Уверен, что сейчас залутаешь имбу, а пока держи бутылку и молитву." },
    { name = "Бармен не в ту смену", desc = "Хотел тихо доработать ночь, а получил хоррор с доставкой в лицо." },
    { name = "Чел \"я ща разрулю\"", desc = "Плана нет, патронов нет, зато самоуверенности как у босса рейда." },
    { name = "Выживальщик с Авито", desc = "Собираешь хлам так, будто через пять минут он станет легендарным билдом." },
    { name = "Местный таракан", desc = "Твоя сила — ныкайся так мерзко, чтобы тебя забыли даже боты." },
}

local SHOOTER_ROLES = {
    { name = "Апостол отдачи", desc = "Стреляет так бодро, будто recoil — это мнение, а не механика." },
    { name = "Менеджер по вайпу", desc = "Твой KPI на сегодня — минус весь сервер и ни одной жалобы в HR." },
    { name = "Существо из катки в 4 утра", desc = "Вышел из тьмы, забрал лобби и даже не вспотел." },
    { name = "Режиссёр мясорубки", desc = "Делаешь экшен настолько грязный, что монтажёр бы просто заплакал." },
    { name = "Главный псих района", desc = "Ты не пушишь — ты оформляешь доставку свинца по адресам." },
    { name = "Инкассатор чужих жизней", desc = "Заходишь молча, забираешь всё и оставляешь только вопросы." },
}

local SWAT_ROLES = {
    { name = "Дверной дипломат", desc = "Переговоры закончились ещё до первого удара тараном." },
    { name = "Щитовой философ", desc = "Думаешь мало, давишь много, живёшь красиво." },
    { name = "Тактик на энергетиках", desc = "План вроде есть, но выглядит так, будто ты придумал его в лифте." },
    { name = "Бюджетный терминатор", desc = "Не самый дорогой боец, но проблемы создаёт люксовые." },
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

local function shuffle(tbl)
    local len = #tbl
    for i = len, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function pickRole(list)
    return table.Random(list)
end

function MODE:ApplyModeRole(ply, roleData, roleType)
    if not IsValid(ply) then return end
    roleData = roleData or { name = "Без роли", desc = "Ты просто тут." }
    roleType = roleType or "victim"

    self.PlayerRoleData = self.PlayerRoleData or {}
    self.PlayerRoleData[ply] = {
        name = roleData.name,
        desc = roleData.desc,
        type = roleType
    }

    ply:SetNWString("ShooterRoleName", roleData.name or "")
    ply:SetNWString("ShooterRoleDesc", roleData.desc or "")
    ply:SetNWString("ShooterRoleType", roleType)
end

function MODE:AssignTeams()
    local players = player.GetAll()
    local numPlayers = #players

    shuffle(players)
    if numPlayers == 0 then return end

    local shooters = 1
    if numPlayers >= 15 then
        shooters = 3
    elseif numPlayers >= 10 then
        shooters = 2
    end

    self.ShooterIndex = {}
    self.PlayerRoleData = {}

    local shooterCount = 0

    for i = 1, numPlayers do
        local ply = players[i]
        if not IsValid(ply) then continue end

        if shooterCount < shooters then
            shooterCount = shooterCount + 1
            ply:SetTeam(2)
            self.ShooterIndex[ply] = shooterCount
            self:ApplyModeRole(ply, pickRole(SHOOTER_ROLES), "shooter")
        else
            ply:SetTeam(1)
            self:ApplyModeRole(ply, pickRole(VICTIM_ROLES), "victim")
        end
    end
end

util.AddNetworkString("criresp_start")

function MODE:Intermission()
    game.CleanUpMap()
    hg.UpdateRoundTime(self.ROUND_TIME)
    self:AssignTeams()

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply:Team() == TEAM_SPECTATOR or ply:Team() == 0 or ply:Team() == 2 then
            ply:KillSilent()
            continue
        end
        ply:SetupTeam(ply:Team())
    end

    net.Start("criresp_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    local swatPlayers = {}
    local victimPlayers = {}
    local shooterPlayers = {}

    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(swatPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(victimPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(2)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(shooterPlayers, ply)
        end
    end

    return { swatPlayers, victimPlayers, shooterPlayers }
end

function MODE:ShouldRoundEnd()
    if zb.ROUND_START + 61 > CurTime() then return false end

    local aliveTeams = self:CheckAlivePlayers()
    if CurTime() >= (zb.ROUND_START + 240) and table.Count(aliveTeams[3]) == 0 then
        return true
    end

    return zb:CheckWinner(aliveTeams)
end

function MODE:RoundStart()
end

MODE.LootTable = {
    {100, {
        {10,"weapon_ducttape"},
        {10,"weapon_matches"},
        {10,"weapon_zippo_tpik"},
        {10,"weapon_bigconsumable"},
        {10,"weapon_smallconsumable"},
        {8,"weapon_painkillers"},
        {8,"weapon_bandage_sh"},
        {5,"weapon_medkit_sh"},
        {5,"weapon_sogknife"},
        {5,"weapon_pocketknife"},
        {5,"weapon_bat"},
        {5,"weapon_hammer"},
        {5,"weapon_hg_bottle"},
    }}
}

function MODE:CanLaunch()
    return true
end

function MODE:GiveEquipment()
    timer.Simple(0.5, function()
        self.SWATQueue = {}
        self.SWATQueueSet = {}

        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SPECTATOR then continue end

            if ply:Team() == 2 then
                timer.Create("ShooterSpawn" .. ply:EntIndex(), 60, 1, function()
                    if not IsValid(ply) then return end
                    ply:Spawn()
                    ply:SetSuppressPickupNotices(true)
                    ply.noSound = true

                    ply:SetupTeam(ply:Team())
                    ply:SetPlayerClass()

                    local roleData = (self.PlayerRoleData and self.PlayerRoleData[ply]) or pickRole(SHOOTER_ROLES)
                    self:ApplyModeRole(ply, roleData, "shooter")
                    zb.GiveRole(ply, roleData.name, ROLE_COLORS.shooter)
                    ply:SetModel("models/gang_groove_boss/gang_groove_boss.mdl")

                    hg.AddArmor(ply, {"ent_armor_vest1","ent_armor_helmet5"})

                    local inv = ply:GetNetVar("Inventory") or {}
                    inv["Weapons"] = inv["Weapons"] or {}
                    inv["Weapons"]["hg_sling"] = true
                    inv["Weapons"]["hg_melee_belt"] = true
                    inv["Weapons"]["hg_flashlight"] = true
                    inv["Weapons"]["hg_brassknuckles"] = true
                    ply:SetNetVar("Inventory", inv)

                    local function giveWithReserve(class)
                        local wep = ply:Give(class)
                        if IsValid(wep) and wep.GetMaxClip1 and wep.GetPrimaryAmmoType and wep:GetMaxClip1() > 0 then
                            ply:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType(), true)
                        end
                    end

                    local shooterIndex = (self.ShooterIndex and self.ShooterIndex[ply]) or 1

                    if shooterIndex == 1 then
                        giveWithReserve("weapon_ruger")
                        giveWithReserve("weapon_handmadesmg")
                    elseif shooterIndex == 2 then
                        giveWithReserve("weapon_doublebarrel")
                        giveWithReserve("weapon_glock17")
                    elseif shooterIndex == 3 then
                        giveWithReserve("weapon_hipoint2")
                        giveWithReserve("weapon_tec9")
                    else
                        giveWithReserve("weapon_ruger")
                        giveWithReserve("weapon_handmadesmg")
                    end

                    giveWithReserve("weapon_hg_pipebomb_tpik")
                    ply:Give("weapon_hg_molotov_tpik")
                    giveWithReserve("weapon_drill")
                    giveWithReserve("weapon_fentanyl")
                    ply:Give("weapon_hands_sh")

                    ply:SetSuppressPickupNotices(false)
                    ply.noSound = false
                end)
            else
                ply:SetSuppressPickupNotices(true)
                ply.noSound = true
                ply:SetPlayerClass()

                local roleData = (self.PlayerRoleData and self.PlayerRoleData[ply]) or pickRole(VICTIM_ROLES)
                self:ApplyModeRole(ply, roleData, "victim")
                zb.GiveRole(ply, roleData.name, ROLE_COLORS.victim)
                ply:Give("weapon_hands_sh")

                ply:SetSuppressPickupNotices(false)
                ply.noSound = false
            end

            timer.Simple(0.5, function()
                if IsValid(ply) then
                    ply.noSound = false
                end
            end)

            ply:SetSuppressPickupNotices(false)
        end

        timer.Create("SWATArrival", 240, 1, function()
            for _, ply in ipairs(team.GetPlayers(2)) do
                if IsValid(ply) and ply:Alive() then
                    local pos = ply:GetPos()
                    sound.Play("c4explode.wav", pos, 140, 120, 1)
                    ParticleEffect("pcf_jack_groundsplode_medium", pos, Angle(0,0,0))
                    if hg and hg.ExplosionEffect then
                        hg.ExplosionEffect(pos, 500, 80)
                    end
                    util.BlastDamage(ply, ply, pos, 500, 1000)
                    ply:Kill()
                end
            end
            self.SWATQueue = {}
            self.SWATQueueSet = {}
        end)
    end)
end

function MODE:SpawnSWAT(ply)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
    return { zb:GetRandomSpawn() }, { zb:GetRandomSpawn() }
end

function MODE:CanSpawn()
end

util.AddNetworkString("cri_roundend")

function MODE:EndRound()
    for _, ply in player.Iterator() do
        if timer.Exists("SWATSpawn" .. ply:EntIndex()) then
            timer.Remove("SWATSpawn" .. ply:EntIndex())
        end
        if timer.Exists("ShooterSpawn" .. ply:EntIndex()) then
            timer.Remove("ShooterSpawn" .. ply:EntIndex())
        end
    end

    if timer.Exists("SWATSpawn") then
        timer.Remove("SWATSpawn")
    end
    if timer.Exists("SWATArrival") then
        timer.Remove("SWATArrival")
    end

    self.SWATQueue = {}
    self.SWATQueueSet = {}

    local aliveTeams = self:CheckAlivePlayers()
    local endround, winner = zb:CheckWinner(aliveTeams)
    if CurTime() >= (zb.ROUND_START + 240) and table.Count(aliveTeams[3]) == 0 then
        endround = true
        winner = 0
    end

    timer.Simple(2, function()
        net.Start("cri_roundend")
            net.WriteBool(winner == 1)
        net.Broadcast()
    end)

    for _, ply in player.Iterator() do
        if ply:Team() == winner then
            ply:GiveExp(math.random(15,30))
            ply:GiveSkill(math.Rand(0.1,0.15))
        else
            ply:GiveSkill(-math.Rand(0.05,0.1))
        end
    end
end

function MODE:PlayerDeath(_, ply)
end
