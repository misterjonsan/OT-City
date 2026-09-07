hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = hg.achievements.achievements_data.created_achevements or {}
hg.achievements.SqlActive = hg.achievements.SqlActive or false

local replacement_img = "homigrad/vgui/models/star.png"

local function getSteamID64(ply)
    if not IsValid(ply) then return nil end
    return ply:SteamID64()
end

local function getPlayerTableByID(steamID64)
    if not steamID64 then return {} end
    hg.achievements.achievements_data.player_achievements[steamID64] = hg.achievements.achievements_data.player_achievements[steamID64] or {}
    return hg.achievements.achievements_data.player_achievements[steamID64]
end

local function getAchievementValue(ply, key)
    local steamID64 = getSteamID64(ply)
    local data = getPlayerTableByID(steamID64)[key]
    return tonumber(data and data.value) or 0
end

local function syncAchievementsToPlayer(ply)
    if not IsValid(ply) then return end

    net.Start("req_ach")
    net.WriteTable(hg.achievements.GetAchievements())
    net.WriteTable(hg.achievements.GetPlayerAchievements(ply))
    net.Send(ply)
end

local function updatePlayer(ply)
    if not IsValid(ply) then return end

    local name = ply:Name()
    local steamID64 = ply:SteamID64()

    if not hg.achievements.SqlActive then
        hg.achievements.achievements_data.player_achievements[steamID64] = {}
        return
    end

    local query = mysql:Select("hg_achievements")
    query:Select("achievements")
    query:Where("steamid", steamID64)
    query:Callback(function(result)
        if not IsValid(ply) then return end

        if istable(result) and #result > 0 and result[1] and result[1].achievements then
            local parsed = util.JSONToTable(result[1].achievements or "") or {}

            local updateQuery = mysql:Update("hg_achievements")
            updateQuery:Update("steam_name", name)
            updateQuery:Where("steamid", steamID64)
            updateQuery:Execute()

            hg.achievements.achievements_data.player_achievements[steamID64] = parsed
        else
            local insertQuery = mysql:Insert("hg_achievements")
            insertQuery:Insert("steamid", steamID64)
            insertQuery:Insert("steam_name", name)
            insertQuery:Insert("achievements", util.TableToJSON({}))
            insertQuery:Execute()

            hg.achievements.achievements_data.player_achievements[steamID64] = {}
        end
    end)
    query:Execute()
end

hook.Add("DatabaseConnected", "AchievementsCreateData", function()
    local query = mysql:Create("hg_achievements")
    query:Create("steamid", "VARCHAR(20) NOT NULL")
    query:Create("steam_name", "VARCHAR(32) NOT NULL")
    query:Create("achievements", "TEXT NOT NULL")
    query:PrimaryKey("steamid")
    query:Execute()

    hg.achievements.SqlActive = true

    print("Achievements SQL database connected.")

    for _, ply in player.Iterator() do
        updatePlayer(ply)
    end
end)

hook.Add("PlayerInitialSpawn", "hg_achievements_initspawn", updatePlayer)

hook.Add("PlayerDisconnected", "hg_achievements_savevalues", function(ply)
    if not hg.achievements.SqlActive then
        print("Tried to save achievement data to SQL, but it is not active.")
        return
    end

    hg.achievements.SaveToSQL(ply)
end)

function hg.achievements.SaveToSQL(ply, data)
    if not hg.achievements.SqlActive then return end
    if not IsValid(ply) then return end

    local name = ply:Name()
    local steamID64 = ply:SteamID64()

    local updateQuery = mysql:Update("hg_achievements")
    updateQuery:Update("achievements", util.TableToJSON(data or hg.achievements.GetPlayerAchievements(ply) or {}))
    updateQuery:Update("steam_name", name)
    updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()
end

function hg.achievements.SavePlayerAchievements()
    if not hg.achievements.SqlActive then
        print("Tried to save achievement data to SQL, but it is not active.")
        return
    end

    for _, ply in player.Iterator() do
        hg.achievements.SaveToSQL(ply)
    end
end

function hg.achievements.CreateAchievementType(key, needed_value, start_value, description, name, img, showpercent)
    img = img or replacement_img

    hg.achievements.achievements_data.created_achevements[key] = {
        start_value = tonumber(start_value) or 0,
        needed_value = tonumber(needed_value) or 1,
        description = tostring(description or ""),
        name = tostring(name or key),
        img = img,
        key = key,
        showpercent = tobool(showpercent)
    }
end

function hg.achievements.GetAchievements()
    return hg.achievements.achievements_data.created_achevements
end

function hg.achievements.GetAchievementInfo(key)
    return hg.achievements.achievements_data.created_achevements[key]
end

function hg.achievements.GetPlayerAchievements(ply)
    local steamID64 = getSteamID64(ply)
    return getPlayerTableByID(steamID64)
end

function hg.achievements.GetPlayerAchievement(ply, key)
    local steamID64 = getSteamID64(ply)
    local tbl = getPlayerTableByID(steamID64)
    tbl[key] = tbl[key] or {}
    return tbl[key]
end

local function isAchievementCompleted(ply, key, val)
    if not IsValid(ply) then return false end

    local ach = hg.achievements.GetAchievementInfo(key)
    if not ach then return false end

    local oldValue = getAchievementValue(ply, key)
    local newValue = tonumber(val) or 0
    local neededValue = tonumber(ach.needed_value) or 1

    return oldValue < neededValue and newValue >= neededValue
end

util.AddNetworkString("hg_NewAchievement")

function hg.achievements.SetPlayerAchievement(ply, key, val)
    if not IsValid(ply) then return end

    local ach = hg.achievements.GetAchievementInfo(key)
    if not ach then return end

    local steamID64 = ply:SteamID64()
    hg.achievements.achievements_data.player_achievements[steamID64] = hg.achievements.achievements_data.player_achievements[steamID64] or {}

    local playerAchievements = hg.achievements.achievements_data.player_achievements[steamID64]
    playerAchievements[key] = playerAchievements[key] or {}

    local oldValue = tonumber(playerAchievements[key].value)
    if oldValue == nil then
        oldValue = tonumber(ach.start_value) or 0
    end

    local newValue = math.Clamp(tonumber(val) or 0, 0, ach.needed_value)

    if isAchievementCompleted(ply, key, newValue) then
        net.Start("hg_NewAchievement")
        net.WriteString(ach.name)
        net.WriteString(ach.img or replacement_img)
        net.Send(ply)
    end

    playerAchievements[key].value = newValue

    if oldValue ~= newValue then
        hg.achievements.SaveToSQL(ply, playerAchievements)
        syncAchievementsToPlayer(ply)
    end
end

function hg.achievements.AddPlayerAchievement(ply, key, val)
    if not IsValid(ply) then return end

    local achInfo = hg.achievements.GetAchievementInfo(key)
    if not achInfo then return end

    local ach = hg.achievements.GetPlayerAchievement(ply, key)
    local currentValue = tonumber(ach.value)
    if currentValue == nil then
        currentValue = tonumber(achInfo.start_value) or 0
    end

    hg.achievements.SetPlayerAchievement(ply, key, math.Approach(currentValue, achInfo.needed_value, tonumber(val) or 0))
end

util.AddNetworkString("req_ach")

net.Receive("req_ach", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.ach_cooldown or 0) > CurTime() then return end

    ply.ach_cooldown = CurTime() + 2

    net.Start("req_ach")
    net.WriteTable(hg.achievements.GetAchievements())
    net.WriteTable(hg.achievements.GetPlayerAchievements(ply))
    net.Send(ply)
end)

hg.achievements.CreateAchievementType("brain", 1, 0, "Погибните от гипоксии.", "Не хватило воздуха", nil, false)
hg.achievements.CreateAchievementType("drugs", 1, 0, "Погибните от передозировки опиоидами.", "Последняя доза", nil, false)
hg.achievements.CreateAchievementType("illbeback", 3, 0, "Переживите выстрел в голову, потерю сознания и вернитесь в строй.", "Я ещё вернусь", nil, true)
hg.achievements.CreateAchievementType("killemall", 1, 0, "Убейте всех предателей и принесите победу своей стороне.", "Охота окончена", nil, false)
hg.achievements.CreateAchievementType("deadlygambling", 10, 0, "Переживите 10 партий в русскую рулетку за одну жизнь.", "Ставка на жизнь", nil, true)
hg.achievements.CreateAchievementType("lobotomygaming", 1, 0, "Убейте предателя с тяжёлым повреждением мозга.", "На одних инстинктах", nil, false)
hg.achievements.CreateAchievementType("hotpotato", 1, 0, "Убейте предателя его собственной гранатой.", "Горячая картошка", nil, false)
hg.achievements.CreateAchievementType("bking", 1, 0, "Напишите в чат фразу «Sir, please, calm down» или её русский вариант.", "Сэр, пожалуйста, успокойтесь", nil, false)

local roundply = 0

hook.Add("ZB_StartRound", "hg_killemall_Achievement_CountPlayers", function()
    roundply = 0
    for _ in player.Iterator() do
        roundply = roundply + 1
    end
end)

hook.Add("ZB_TraitorWinOrNot", "hg_killemall_Achievement_CheckWin", function(ply, winner)
    if not IsValid(ply) then return end
    if winner ~= 1 then return end
    if roundply < 10 then return end

    local kills = ply.TraitorKills or 0
    if kills >= math.max(roundply - 1, 1) then
        hg.achievements.SetPlayerAchievement(ply, "killemall", 1)
    end
end)

hook.Add("PlayerDeath", "hg_deadlygambling_reset_on_death", function(ply)
    if not IsValid(ply) then return end

    local val = getAchievementValue(ply, "deadlygambling")
    if val > 0 and val < 10 then
        hg.achievements.SetPlayerAchievement(ply, "deadlygambling", 0)
    end
end)

hook.Add("PlayerDeath", "hg_traitor_related_achievements", function(ply)
    if not IsValid(ply) then return end

    if ply.isTraitor then
        if IsValid(ply.ZBestAttacker) and ply ~= ply.ZBestAttacker then
            if ply.ZBestAttacker:Alive() and ply.ZBestAttacker.organism and (ply.ZBestAttacker.organism.brain or 1) < 0.1 then
                hg.achievements.SetPlayerAchievement(ply.ZBestAttacker, "lobotomygaming", 1)
            end

            if IsValid(ply.ZBestInflictor) and ply.ZBestInflictor.ishggrenade and ply.ZBestInflictor.owner2 == ply and IsValid(ply.ZBestInflictor.owner) then
                hg.achievements.SetPlayerAchievement(ply.ZBestInflictor.owner, "hotpotato", 1)
            end
        end

        ply.TraitorKills = 0
        return
    end

    if IsValid(ply.ZBestAttacker) and ply.ZBestAttacker.isTraitor then
        ply.ZBestAttacker.TraitorKills = (ply.ZBestAttacker.TraitorKills or 0) + 1
    end
end)

hook.Add("PlayerSilentDeath", "hg_traitor_kills_reset", function(ply)
    if not IsValid(ply) then return end
    if ply.isTraitor then
        ply.TraitorKills = 0
    end
end)

hook.Add("HomigradDamage", "hg_illbeback_Achievement_Headshot", function(ply, dmgInfo, hitgroup)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(dmgInfo) then return end
    if hitgroup ~= HITGROUP_HEAD then return end
    if getAchievementValue(ply, "illbeback") >= 3 then return end

    if dmgInfo:IsDamageType(128) or dmgInfo:IsDamageType(DMG_BULLET) then
        hg.achievements.SetPlayerAchievement(ply, "illbeback", 1)
        ply.illbeback = CurTime() + 10
    end
end)

hook.Add("HG_OnOtrub", "hg_illbeback_Achievement_Unconscious", function(ply)
    if not IsValid(ply) then return end

    if ply:IsRagdoll() then
        ply = hg.RagdollOwner(ply)
    end

    if not IsValid(ply) then return end
    if getAchievementValue(ply, "illbeback") == 1 and (ply.illbeback or 0) > CurTime() then
        hg.achievements.SetPlayerAchievement(ply, "illbeback", 2)
    end
end)

hook.Add("PlayerDeath", "hg_illbeback_Achievement_ResetDeath", function(ply)
    if not IsValid(ply) then return end

    local val = getAchievementValue(ply, "illbeback")
    if val > 0 and val < 3 then
        hg.achievements.SetPlayerAchievement(ply, "illbeback", 0)
    end
end)

hook.Add("PlayerSilentDeath", "hg_illbeback_Achievement_ResetSilentDeath", function(ply)
    if not IsValid(ply) then return end

    local val = getAchievementValue(ply, "illbeback")
    if val > 0 and val < 3 then
        hg.achievements.SetPlayerAchievement(ply, "illbeback", 0)
    end
end)

hook.Add("HG_OnWakeOtrub", "hg_illbeback_Achievement_WakeUp", function(ply)
    if not IsValid(ply) then return end

    if ply:IsRagdoll() then
        ply = hg.RagdollOwner(ply)
    end

    if not IsValid(ply) then return end
    if getAchievementValue(ply, "illbeback") == 2 then
        hg.achievements.SetPlayerAchievement(ply, "illbeback", 3)
    end
end)

local tblToFind_bking = {
    {"sir", "sir"},
    {"сэр", "sir"},
    {"please", "please"},
    {"пожалуйста", "please"},
    {"calm down", "calm down"},
    {"успокойтесь", "calm down"}
}

local function collectChatTextParts(value, out)
    out = out or {}

    if isstring(value) then
        out[#out + 1] = value
    elseif istable(value) then
        for _, v in ipairs(value) do
            collectChatTextParts(v, out)
        end
    end

    return out
end

local function normalizeAchievementChatText(txtTbl, txt)
    local parts = {}

    collectChatTextParts(txtTbl, parts)

    if isstring(txt) and txt ~= "" then
        parts[#parts + 1] = txt
    end

    local raw = table.concat(parts, " ")

    if utf8 and utf8.lower then
        raw = utf8.lower(raw)
    else
        raw = string.lower(raw)
    end

    raw = string.gsub(raw, "[%p%c]", " ")
    raw = string.gsub(raw, "%s+", " ")
    raw = string.Trim(raw)

    return raw
end

local function tryGrantBurgerKingAchievement(ply, txtTbl, txt)
    if not IsValid(ply) then return end

    local lowerTxt = normalizeAchievementChatText(txtTbl, txt)
    if lowerTxt == "" then return end

    local bking = {
        ["sir"] = false,
        ["please"] = false,
        ["calm down"] = false
    }

    for _, v in ipairs(tblToFind_bking) do
        if string.find(lowerTxt, v[1], 1, true) then
            bking[v[2]] = true
        end
    end

    if not (bking["sir"] and bking["please"] and bking["calm down"]) then
        return
    end

    local alreadyHad = getAchievementValue(ply, "bking") >= 1
    hg.achievements.SetPlayerAchievement(ply, "bking", 1)

    if not alreadyHad and ply.PS_AddItem then
        ply:PS_AddItem("burger king crown")
    end
end

hook.Add("HG_PlayerSay", "hg_burgerking_Achievement_HGPlayerSay", function(ply, txtTbl, txt)
    tryGrantBurgerKingAchievement(ply, txtTbl, txt)
end)

hook.Add("PlayerSay", "hg_burgerking_Achievement_PlayerSay", function(ply, txt)
    tryGrantBurgerKingAchievement(ply, txt, txt)
end)
