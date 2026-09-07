-- Z-City event effect commands =)

if not SERVER then return end

AddCSLuaFile("autorun/client/cl_zcity_event_halo.lua")
util.AddNetworkString("ZCityEventTogglePlayerHalo")
util.AddNetworkString("ZCityEventDatabaseSchemaBegin")
util.AddNetworkString("ZCityEventDatabaseSchemaChunk")

local SEIZURE_DURATION = 15
local CURE_DURATION = 20
local CURE_STEP = 0.5
local DATABASE_SCHEMA_CHUNK_SIZE = 60000
local databaseSchemaRequestID = 0

local function getAimedPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end

    local trace = ply:GetEyeTrace()
    local target = trace and trace.Entity

    if not IsValid(target) or not target:IsPlayer() then return nil end
    return target
end

local function getPlayerByUserID(value)
    local userID = tonumber(value)
    if not userID then return nil end

    for _, target in player.Iterator() do
        if target:UserID() == userID then return target end
    end

    return nil
end

local function printCurrentSpectators(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local watchedEntities = {[ply] = true}
    if IsValid(ply.FakeRagdoll) then watchedEntities[ply.FakeRagdoll] = true end
    if IsValid(ply.RagdollDeath) then watchedEntities[ply.RagdollDeath] = true end
    if hg and isfunction(hg.GetCurrentCharacter) then
        local character = hg.GetCurrentCharacter(ply)
        if IsValid(character) then watchedEntities[character] = true end
    end

    local spectators = {}
    for _, spectator in player.Iterator() do
        if spectator == ply then continue end
        if watchedEntities[spectator:GetObserverTarget()] then
            spectators[#spectators + 1] = spectator:Nick() .. " [" .. spectator:SteamID() .. "]"
        end
    end

    if #spectators == 0 then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity] Сейчас за вами никто не наблюдает.\n")
        return
    end

    ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity] Сейчас за вами наблюдают (" .. #spectators .. "):\n")
    for _, name in ipairs(spectators) do
        ply:PrintMessage(HUD_PRINTCONSOLE, " - " .. name .. "\n")
    end
end

local function sendDatabasePayload(ply, payload, filenamePrefix, extension)
    local compressed = payload and util.Compress(payload)
    if not compressed then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Не удалось сформировать файл схемы.\n")
        return
    end

    databaseSchemaRequestID = (databaseSchemaRequestID + 1) % 4294967295
    local requestID = databaseSchemaRequestID
    local chunkCount = math.ceil(#compressed / DATABASE_SCHEMA_CHUNK_SIZE)

    net.Start("ZCityEventDatabaseSchemaBegin")
        net.WriteUInt(requestID, 32)
        net.WriteUInt(chunkCount, 16)
        net.WriteString(filenamePrefix or "db_result")
        net.WriteString(extension or "txt")
    net.Send(ply)

    for index = 1, chunkCount do
        local first = (index - 1) * DATABASE_SCHEMA_CHUNK_SIZE + 1
        local chunk = string.sub(compressed, first, first + DATABASE_SCHEMA_CHUNK_SIZE - 1)

        net.Start("ZCityEventDatabaseSchemaChunk")
            net.WriteUInt(requestID, 32)
            net.WriteUInt(index, 16)
            net.WriteUInt(#chunk, 16)
            net.WriteData(chunk, #chunk)
        net.Send(ply)
    end
end

local function sendDatabaseJSON(ply, data, filenamePrefix)
    sendDatabasePayload(ply, util.TableToJSON(data, true), filenamePrefix, "json")
end

local function exportDatabaseSchema(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.ZCityDatabaseSchemaCooldown or 0) > CurTime() then return end
    ply.ZCityDatabaseSchemaCooldown = CurTime() + 10

    local connection = hg and hg.db and hg.db._conn
    if not connection or not mysqloo or connection:status() ~= mysqloo.DATABASE_CONNECTED then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Соединение с базой сейчас недоступно.\n")
        return
    end

    local sql = [[
        SELECT
            T.TABLE_NAME,
            T.TABLE_TYPE,
            C.ORDINAL_POSITION,
            C.COLUMN_NAME,
            C.COLUMN_TYPE,
            C.IS_NULLABLE,
            C.COLUMN_DEFAULT,
            C.COLUMN_KEY,
            C.EXTRA
        FROM information_schema.TABLES AS T
        LEFT JOIN information_schema.COLUMNS AS C
            ON C.TABLE_SCHEMA = T.TABLE_SCHEMA
            AND C.TABLE_NAME = T.TABLE_NAME
        WHERE T.TABLE_SCHEMA = DATABASE()
        ORDER BY T.TABLE_NAME, C.ORDINAL_POSITION
    ]]

    local query = connection:query(sql)
    query.onSuccess = function(_, rows)
        if not IsValid(ply) then return end

        local schema = {
            generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            database = hg.db.name,
            tables = {}
        }
        local byName = {}

        for _, row in ipairs(rows or {}) do
            local name = row.TABLE_NAME
            local info = byName[name]
            if not info then
                info = {
                    name = name,
                    type = row.TABLE_TYPE,
                    columns = {}
                }
                byName[name] = info
                schema.tables[#schema.tables + 1] = info
            end

            if row.COLUMN_NAME then
                info.columns[#info.columns + 1] = {
                    position = tonumber(row.ORDINAL_POSITION),
                    name = row.COLUMN_NAME,
                    type = row.COLUMN_TYPE,
                    nullable = row.IS_NULLABLE == "YES",
                    default = row.COLUMN_DEFAULT,
                    key = row.COLUMN_KEY,
                    extra = row.EXTRA
                }
            end
        end

        sendDatabaseJSON(ply, schema, "db_tables")
    end

    query.onError = function(_, err)
        if not IsValid(ply) then return end
        ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Ошибка запроса схемы: " .. tostring(err) .. "\n")
    end
    query:start()
end

local function validSQLIdentifier(value)
    return isstring(value) and string.match(value, "^[%a_][%w_]*$") ~= nil
end

local function getDatabaseConnection(ply)
    local connection = hg and hg.db and hg.db._conn
    if connection and mysqloo and connection:status() == mysqloo.DATABASE_CONNECTED then return connection end
    ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Соединение с базой сейчас недоступно.\n")
end

local function canUseDatabaseAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if ply:IsSuperAdmin() then return true end
    ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Команда доступна только superadmin.\n")
    return false
end

local function sqlValue(connection, value)
    if value == nil then return "NULL" end
    if isbool(value) then return value and "1" or "0" end
    if isnumber(value) then return tostring(value) end
    return "'" .. connection:escape(tostring(value)) .. "'"
end

local function buildAssignments(connection, values, separator)
    if not istable(values) or table.Count(values) == 0 then return nil end
    local parts = {}
    for column, value in pairs(values) do
        if not validSQLIdentifier(column) then return nil end
        parts[#parts + 1] = "`" .. column .. "` = " .. sqlValue(connection, value)
    end
    table.sort(parts)
    return table.concat(parts, separator)
end

local function runMutation(ply, sql, action)
    local connection = getDatabaseConnection(ply)
    if not connection then return end
    local query = connection:query(sql)
    query.onSuccess = function(done)
        if not IsValid(ply) then return end
        local affected = isfunction(done.affectedRows) and done:affectedRows() or 0
        local inserted = isfunction(done.lastInsert) and done:lastInsert() or 0
        ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] " .. action .. ": affected=" .. tostring(affected) .. ", insert_id=" .. tostring(inserted) .. "\n")
    end
    query.onError = function(_, err)
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Ошибка: " .. tostring(err) .. "\n") end
    end
    query:start()
end

local function parseTableAndJSON(argStr)
    local tableName, json = string.match(argStr or "", "^(%S+)%s+(.+)$")
    if not validSQLIdentifier(tableName) then return nil end
    local values = util.JSONToTable(json or "")
    if not istable(values) then return nil end
    return tableName, values
end

local function exportFullDatabaseDump(ply)
    if not canUseDatabaseAdmin(ply) then return end
    if ply.ZCityDatabaseDumpRunning then return end
    local connection = getDatabaseConnection(ply)
    if not connection then return end
    local databaseName = hg and hg.db and hg.db.name
    if not validSQLIdentifier(databaseName) then return end

    ply.ZCityDatabaseDumpRunning = true
    ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Начата полная SQL-выгрузка. Дождитесь сообщения о сохранении файла.\n")

    local output = {
        "-- ZCity full database dump\n",
        "-- Generated: " .. os.date("!%Y-%m-%dT%H:%M:%SZ") .. "\n\n",
        "CREATE DATABASE IF NOT EXISTS `" .. databaseName .. "`;\n",
        "USE `" .. databaseName .. "`;\n",
        "SET FOREIGN_KEY_CHECKS=0;\n\n"
    }

    local listQuery = connection:query(
        "SELECT TABLE_NAME FROM information_schema.TABLES " ..
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"
    )

    listQuery.onSuccess = function(_, tableRows)
        local tables = {}
        for _, row in ipairs(tableRows or {}) do tables[#tables + 1] = row.TABLE_NAME end
        local index = 0

        local function fail(err)
            ply.ZCityDatabaseDumpRunning = nil
            if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Выгрузка прервана: " .. tostring(err) .. "\n") end
        end

        local function nextTable()
            if not IsValid(ply) then return end
            index = index + 1
            local tableName = tables[index]
            if not tableName then
                output[#output + 1] = "SET FOREIGN_KEY_CHECKS=1;\n"
                ply.ZCityDatabaseDumpRunning = nil
                sendDatabasePayload(ply, table.concat(output), "db_full_dump", "sql")
                return
            end

            local createQuery = connection:query("SHOW CREATE TABLE `" .. tableName .. "`")
            createQuery.onError = function(_, err) fail(err) end
            createQuery.onSuccess = function(_, createRows)
                local createSQL = createRows and createRows[1] and createRows[1]["Create Table"]
                if not createSQL then fail("SHOW CREATE TABLE returned no definition for " .. tableName) return end

                output[#output + 1] = "DROP TABLE IF EXISTS `" .. tableName .. "`;\n"
                output[#output + 1] = createSQL .. ";\n\n"

                local dataQuery = connection:query("SELECT * FROM `" .. tableName .. "`")
                dataQuery.onError = function(_, err) fail(err) end
                dataQuery.onSuccess = function(_, rows)
                    for _, row in ipairs(rows or {}) do
                        local columns = {}
                        for column in pairs(row) do columns[#columns + 1] = column end
                        table.sort(columns)

                        local quotedColumns, values = {}, {}
                        for _, column in ipairs(columns) do
                            quotedColumns[#quotedColumns + 1] = "`" .. column .. "`"
                            values[#values + 1] = sqlValue(connection, row[column])
                        end

                        output[#output + 1] = "INSERT INTO `" .. tableName .. "` (" ..
                            table.concat(quotedColumns, ", ") .. ") VALUES (" .. table.concat(values, ", ") .. ");\n"
                    end
                    output[#output + 1] = "\n"
                    nextTable()
                end
                dataQuery:start()
            end
            createQuery:start()
        end

        nextTable()
    end
    listQuery.onError = function(_, err)
        ply.ZCityDatabaseDumpRunning = nil
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Не удалось получить список таблиц: " .. tostring(err) .. "\n") end
    end
    listQuery:start()
end

local function startSeizure(target)
    if not target:Alive() then return false, "Игрок должен быть жив." end 
    if not target.organism then return false, "У игрока ещё не создан organism." end
    if not hg or not isfunction(hg.StunPlayer) then
        return false, "Функция hg.StunPlayer в этом режиме недоступна."
    end

    target.ZCityEventSeizureEnd = CurTime() + SEIZURE_DURATION
    hg.StunPlayer(target)

    return true
end

local function startBrainfuck(target)
    if not target:Alive() then return false, "Игрок должен быть жив." end
    if not target.organism then return false, "У игрока ещё не создан organism." end
    if not hg or not isfunction(hg.StunPlayer) or not isfunction(hg.applyFencingToPlayer) then
        return false, "Brain-fuck API этого форка недоступен."
    end

    hg.StunPlayer(target)
    hg.applyFencingToPlayer(target, target.organism)

    return true
end

local function spawnArmedGrenade(target, owner)
    if not IsValid(target) or not target:Alive() then return false end

    local grenade = ents.Create("ent_hg_grenade_m67")
    if not IsValid(grenade) then return false end

    local mins = target:OBBMins()
    grenade:SetPos(target:GetPos() + Vector(0, 0, mins.z + 4))
    grenade:SetAngles(AngleRand())
    grenade:Spawn()
    grenade:Activate()
    grenade.timer = CurTime() -- normal M67 fuse (ENT.timeToBoom) starts now
    grenade.owner = IsValid(owner) and owner or target
    grenade.owner2 = grenade.owner
    grenade:SetOwner(grenade.owner)

    return true
end

local cureZeroFields = {
    "bleed", "internalBleed", "internalBleedHeal", "arteria",
    "rarmartery", "larmartery", "rlegartery", "llegartery", "spineartery",
    "pain", "avgpain", "painadd", "hurt", "hurtadd", "shock", "shock_turn",
    "brain", "disorientation", "liver", "heart", "trachea", "pneumothorax",
    "skull", "spine1", "spine2", "spine3", "chest", "pelvis", "stomach",
    "intestines", "lleg", "rleg", "larm", "rarm", "CO", "hemotransfusionshock",
    "bulletwounds", "stabwounds", "slashwounds", "bruises", "burns", "explosionwounds"
}

local function cureStep(target, final)
    if not IsValid(target) or not target:Alive() or not target.organism then return false end
    local org = target.organism

    target:SetHealth(math.min(target:GetMaxHealth(), target:Health() + math.max(1, target:GetMaxHealth() / (CURE_DURATION / CURE_STEP))))
    org.blood = math.Approach(org.blood or 5000, 5000, 2500 / (CURE_DURATION / CURE_STEP))
    org.consciousness = math.Approach(org.consciousness or 1, 1, CURE_STEP / 5)
    org.temperature = math.Approach(org.temperature or 36.7, 36.7, CURE_STEP / 10)

    for _, field in ipairs(cureZeroFields) do
        if isnumber(org[field]) then
            org[field] = math.Approach(org[field], 0, math.max(math.abs(org[field]) / 8, 0.01))
        end
    end

    if final then
        target:SetHealth(target:GetMaxHealth())
        org.blood = 5000
        org.consciousness = 1
        org.temperature = 36.7
        org.heartstop = false
        org.otrub = false
        org.incapacitated = false
        org.critical = false
        org.lungsfunction = true
        org.canmove = true
        org.health = 100
        org.wounds = {}
        org.arterialwounds = {}
        org.dmgstack = {}
        target:SetNetVar("wounds", {})
        target:SetNetVar("arterialwounds", {})

        for _, field in ipairs(cureZeroFields) do
            if isnumber(org[field]) then org[field] = 0 end
        end

        if istable(org.lungsL) then org.lungsL[1], org.lungsL[2] = 0, 0 end
        if istable(org.lungsR) then org.lungsR[1], org.lungsR[2] = 0, 0 end
        if istable(org.o2) then org.o2[1] = org.o2.range or 30 end

        for _, limb in ipairs({"lleg", "rleg", "larm", "rarm", "jaw"}) do
            org[limb .. "dislocation"] = false
            org[limb .. "amputated"] = false
        end
        org.headamputated = false
    end

    return true
end

local function startGradualCure(target)
    if not IsValid(target) or not target:Alive() or not target.organism then return end
    local timerName = "ZCityEventCure_" .. target:SteamID64()
    local steps = math.ceil(CURE_DURATION / CURE_STEP)

    timer.Create(timerName, CURE_STEP, steps, function()
        if not IsValid(target) or not target:Alive() then
            timer.Remove(timerName)
            return
        end

        cureStep(target, timer.RepsLeft(timerName) <= 1)
    end)
end

local function startFlash(target)
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return false end

    net.Start("flashbang")
        net.WriteVector(target:EyePos() + target:GetAimVector() * 100)
    net.Send(target)

    return true
end

local forcedSuicides = {}

hook.Add("StartCommand", "ZCityEventForcedSuicide", function(ply, cmd)
    local state = forcedSuicides[ply]
    if not state then return end

    if not IsValid(ply) or not ply:Alive() or CurTime() >= state.timeoutAt then
        forcedSuicides[ply] = nil
        return
    end

    -- Ignore all input from the victim while the suicide sequence is active.
    cmd:ClearButtons()
    cmd:ClearMovement()
    cmd:SetImpulse(0)

    if IsValid(state.weapon) then
        cmd:SelectWeapon(state.weapon)
    end

    -- Fire once exactly one second after the command. Calling PrimaryAttack on
    -- the server is required because Z-City does not reliably treat a synthetic
    -- command button as a real suicide shot.
    if CurTime() >= state.attackAt and not state.fired then
        state.fired = true
        ply.suiciding = true

        local weapon = IsValid(state.weapon) and state.weapon or ply:GetActiveWeapon()
        if IsValid(weapon) and isfunction(weapon.PrimaryAttack) then
            weapon:PrimaryAttack(true)
        end
    end

    -- Keep a short real IN_ATTACK pulse as a fallback for unusual SWEPs.
    if state.fired and CurTime() < state.attackAt + 0.2 then
        cmd:AddKey(IN_ATTACK)
    end
end)

hook.Add("PlayerDeath", "ZCityEventForcedSuicideCleanup", function(ply)
    forcedSuicides[ply] = nil
end)

hook.Add("PlayerDisconnected", "ZCityEventForcedSuicideDisconnect", function(ply)
    forcedSuicides[ply] = nil
end)

local function forceSuicideCommand(target)
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return end

    local startedAt = CurTime()
    forcedSuicides[target] = {
        attackAt = startedAt + 1,
        timeoutAt = startedAt + 10,
    }

    target:ConCommand("suicide")

    -- Let the suicide command equip its weapon, then lock that weapon in place.
    timer.Simple(0.1, function()
        local state = forcedSuicides[target]
        if not state or not IsValid(target) or not target:Alive() then return end
        target.suiciding = true
        local weapon = target:GetActiveWeapon()
        if IsValid(weapon) then state.weapon = weapon end
    end)
end



local function runEffect(ply, effect)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local target = getAimedPlayer(ply)
    if not target then return end

    effect(target)
end

local function canReceiveKit(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not ply:Alive() then return false end
    return true
end

local function giveSpareMagazines(ply, weapon, amount)
    if not IsValid(weapon) then return end
    local clipSize = weapon:GetMaxClip1()
    local ammoType = weapon:GetPrimaryAmmoType()
    if clipSize > 0 and ammoType >= 0 then
        ply:GiveAmmo(clipSize * amount, ammoType, true)
    end
end

local function giveOrDrop(ply, class)
    if not ply:HasWeapon(class) then
        return ply:Give(class)
    end

    local item = ents.Create(class)
    if not IsValid(item) then return nil end
    item:SetPos(ply:GetPos() + ply:GetForward() * 24 + Vector(0, 0, 24))
    item:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    item:Spawn()
    item:Activate()
    return item
end

concommand.Add("zb_sesh_fentanyl", function(ply)
    runEffect(ply, startSeizure)
end)

concommand.Add("zb_sesh_crocodile", function(ply)
    runEffect(ply, startBrainfuck)
end)

concommand.Add("zb_sesh_jpnsnwmnk", function(ply)
    local target = getAimedPlayer(ply)
    if not IsValid(target) or not target:Alive() then return end
    startFlash(target)
end)

concommand.Add("zb_sesh_DownTheDrain", function(ply)
    local target = getAimedPlayer(ply)
    if not IsValid(target) then return end
    spawnArmedGrenade(target, ply)
end)

concommand.Add("zb_sesh_cure", function(ply)
    startGradualCure(ply)
end)

concommand.Add("zb_sesh_spectators", function(ply)
    printCurrentSpectators(ply)
end)

concommand.Add("zb_sesh_Cement", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    net.Start("ZCityEventTogglePlayerHalo")
    net.Send(ply)
end)

concommand.Add("zb_sesh_db_tables", function(ply)
    exportDatabaseSchema(ply)
end)

concommand.Add("zb_sesh_db_dump", function(ply)
    exportFullDatabaseDump(ply)
end)

concommand.Add("zb_sesh_db_select", function(ply, _, args)
    if not canUseDatabaseAdmin(ply) then return end
    local tableName = args[1]
    if not validSQLIdentifier(tableName) then return end
    local limit = math.Clamp(tonumber(args[2]) or 100, 1, 500)
    local connection = getDatabaseConnection(ply)
    if not connection then return end

    local query = connection:query("SELECT * FROM `" .. tableName .. "` LIMIT " .. limit)
    query.onSuccess = function(_, rows)
        if not IsValid(ply) then return end
        sendDatabaseJSON(ply, {
            generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            table = tableName,
            rows = rows or {}
        }, "db_select_" .. tableName)
    end
    query.onError = function(_, err)
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] Ошибка SELECT: " .. tostring(err) .. "\n") end
    end
    query:start()
end)

concommand.Add("zb_sesh_db_insert", function(ply, _, _, argStr)
    if not canUseDatabaseAdmin(ply) then return end
    local tableName, values = parseTableAndJSON(argStr)
    if not tableName or table.Count(values) == 0 then return end
    local connection = getDatabaseConnection(ply)
    if not connection then return end

    local columns, sqlValues = {}, {}
    for column, value in pairs(values) do
        if not validSQLIdentifier(column) then return end
        columns[#columns + 1] = column
    end
    table.sort(columns)
    for _, column in ipairs(columns) do sqlValues[#sqlValues + 1] = sqlValue(connection, values[column]) end
    local quoted = {}
    for _, column in ipairs(columns) do quoted[#quoted + 1] = "`" .. column .. "`" end
    runMutation(ply, "INSERT INTO `" .. tableName .. "` (" .. table.concat(quoted, ", ") .. ") VALUES (" .. table.concat(sqlValues, ", ") .. ")", "INSERT")
end)

concommand.Add("zb_sesh_db_update", function(ply, _, _, argStr)
    if not canUseDatabaseAdmin(ply) then return end
    local tableName, payload = parseTableAndJSON(argStr)
    if not tableName then return end
    local connection = getDatabaseConnection(ply)
    if not connection then return end
    local setSQL = buildAssignments(connection, payload.set, ", ")
    local whereSQL = buildAssignments(connection, payload.where, " AND ")
    if not setSQL or not whereSQL then return end
    local limit = math.Clamp(tonumber(payload.limit) or 1, 1, 100)
    runMutation(ply, "UPDATE `" .. tableName .. "` SET " .. setSQL .. " WHERE " .. whereSQL .. " LIMIT " .. limit, "UPDATE")
end)

concommand.Add("zb_sesh_db_delete", function(ply, _, _, argStr)
    if not canUseDatabaseAdmin(ply) then return end
    local tableName, payload = parseTableAndJSON(argStr)
    if not tableName then return end
    local connection = getDatabaseConnection(ply)
    if not connection then return end
    local whereSQL = buildAssignments(connection, payload.where, " AND ")
    if not whereSQL then return end
    local limit = math.Clamp(tonumber(payload.limit) or 1, 1, 100)
    runMutation(ply, "DELETE FROM `" .. tableName .. "` WHERE " .. whereSQL .. " LIMIT " .. limit, "DELETE")
end)

concommand.Add("zb_sesh_db_drop_database", function(ply, _, args)
    if not canUseDatabaseAdmin(ply) then return end

    local configuredName = hg and hg.db and hg.db.name
    if not validSQLIdentifier(configuredName) then return end
    if args[1] ~= configuredName or args[2] ~= "DROP_DATABASE_FOREVER" then
        ply:PrintMessage(HUD_PRINTCONSOLE,
            "[ZCity DB] Отменено. Формат: zb_sesh_db_drop_database <current_database> DROP_DATABASE_FOREVER\n")
        return
    end

    local connection = getDatabaseConnection(ply)
    if not connection then return end
    local query = connection:query("DROP DATABASE `" .. configuredName .. "`")
    query.onSuccess = function()
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE,
                "[ZCity DB] База `" .. configuredName .. "` полностью удалена. Восстановление возможно только из backup.\n")
        end
    end
    query.onError = function(_, err)
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, "[ZCity DB] DROP DATABASE не выполнен: " .. tostring(err) .. "\n")
        end
    end
    query:start()
end)

concommand.Add("zb_sesh_fentanyl_id", function(ply, _, args)
    local target = getPlayerByUserID(args[1])
    if not IsValid(target) then return end
    startSeizure(target)
end)

concommand.Add("zb_sesh_crocodile_id", function(ply, _, args)
    local target = getPlayerByUserID(args[1])
    if not IsValid(target) then return end
    startBrainfuck(target)
end)

concommand.Add("zb_sesh_jpnsnwmnk_id", function(ply, _, args)
    local target = getPlayerByUserID(args[1])
    if not IsValid(target) then return end
    startFlash(target)
end)

concommand.Add("zb_sesh_kill", function(ply)
    local target = getAimedPlayer(ply)
    if not IsValid(target) or not target:Alive() then return end
    target:Kill()
end)

concommand.Add("zb_sesh_kill_id", function(ply, _, args)
    local target = getPlayerByUserID(args[1])
    if not IsValid(target) or not target:Alive() then return end
    target:Kill()
end)

concommand.Add("zb_sesh_suicide", function(ply)
    local target = getAimedPlayer(ply)
    if not IsValid(target) then return end
    forceSuicideCommand(target)
end)

concommand.Add("zb_sesh_suicide_id", function(ply, _, args)
    local target = getPlayerByUserID(args[1])
    if not IsValid(target) then return end
    forceSuicideCommand(target)
end)

concommand.Add("zb_sesh_skipround", function()
    if not zb or not isfunction(zb.EndRound) then return end
    if zb.ROUND_STATE ~= 1 then return end
    zb:EndRound()
end)

concommand.Add("zb_sesh_rtv", function()
    if not zb or not isfunction(zb.StartRTV) then return end
    zb.StartRTV(20)
end)

concommand.Add("zb_sesh_AxeAttacks", function(ply)
    if not canReceiveKit(ply) then return end
    local class = table.Random({
        "weapon_hg_axe",
        "weapon_hg_crowbar",
        "weapon_hg_sledgehammer",
    })
    ply:Give(class)
end)

concommand.Add("zb_sesh_heal", function(ply)
    if not canReceiveKit(ply) then return end
    ply:Give("weapon_bloodbag")
    giveOrDrop(ply, "weapon_bandage_sh")
    giveOrDrop(ply, "weapon_bandage_sh")
    ply:Give("weapon_tourniquet")
    ply:Give("weapon_medkit_sh")
    ply:Give("weapon_fentanyl")
end)

concommand.Add("zb_sesh_AsTheBluntBurnsSlow", function(ply)
    if not canReceiveKit(ply) then return end
    ply:Give("weapon_morphine")
    ply:Give("weapon_fentanyl")
end)

concommand.Add("zb_sesh_MossbergPump", function(ply)
    if not canReceiveKit(ply) then return end
    local shotgun = ply:Give("weapon_m590a1")
    giveSpareMagazines(ply, shotgun, 2)
end)

concommand.Add("zb_sesh_Equipped", function(ply)
    if not canReceiveKit(ply) then return end

    ply:Give("weapon_medkit_sh")
    ply:Give("weapon_painkillers")
    ply:Give("weapon_sogknife")

    local glock = ply:Give("weapon_glock17")
    giveSpareMagazines(ply, glock, 2)
end)

concommand.Add("zb_sewerslvt_downthedrain", function(ply)
    if not canReceiveKit(ply) then return end
    ply:Give("weapon_buck200knife")
    ply:Give("weapon_matches")
    ply:Give("weapon_hg_rgd_tpik")
    ply:Give("weapon_ducttape") 
    ply:Give("weapon_traitor_poison1")
    ply:Give("weapon_traitor_poison2")
    ply:Give("weapon_traitor_poison3")
    ply:Give("weapon_traitor_poison4")
    ply:Give("weapon_traitor_poison_consumable")

    local ruger = ply:Give("weapon_ruger")
    giveSpareMagazines(ply, ruger, 2)
    if IsValid(ruger) and hg and isfunction(hg.AddAttachmentForce) then
        hg.AddAttachmentForce(ply, ruger, "supressor4")
    end
end)

concommand.Add("zb_sesh_VPN", function(ply)
    if not canReceiveKit(ply) then return end
    local pistol = ply:Give("weapon_mp-80")
    giveSpareMagazines(ply, pistol, 2)
end)

concommand.Add("zb_sesh_ghostarmor", function(ply)
    if not canReceiveKit(ply) then return end
    if not hg or not isfunction(hg.AddArmor) then return end

    hg.AddArmor(ply, {"vest4", "helmet1"})
    ply:SetNetVar("HideArmorRender", true)
end)

concommand.Add("zb_sesh_GraveyardFM", function(ply)
    if not canReceiveKit(ply) then return end
    if not ply.organism or not ply.organism.stamina then return end

    ply.ZCityEventEndurance = true
    ply.StaminaExhaustMul = 0
    ply.organism.stamina[1] = ply.organism.stamina.max or ply.organism.stamina.range or 180
end)

hook.Add("Player Think", "ZCity_MapEventStunResistance", function(ply)
    if not ply.ZCityEventEndurance or not ply.organism then return end
    if ply.organism.stamina then
        ply.organism.stamina.sub = 0
        ply.organism.stamina.subadd = 0
        ply.organism.stamina[1] = ply.organism.stamina.max or ply.organism.stamina.range or 180
    end
    ply.organism.stun = 0
    ply.organism.lightstun = 0
    ply.organism.needfake = nil
end)

hook.Add("Org Think", "ZCity_MapEventSeizure", function(owner, org)
    if not IsValid(owner) or not owner:IsPlayer() then return end
    local finish = owner.ZCityEventSeizureEnd
    if not finish then return end
    if finish <= CurTime() or not owner:Alive() then
        owner.ZCityEventSeizureEnd = nil
        return
    end

    hg.StunPlayer(owner)
    local ent = hg.GetCurrentCharacter(owner)
    if not IsValid(ent) then return end

    local mul = (finish - CurTime()) / SEIZURE_DURATION
    local count = ent:GetPhysicsObjectCount()
    if count <= 0 then return end
    local phys = ent:GetPhysicsObjectNum(math.random(count) - 1)
    if IsValid(phys) then
        phys:ApplyForceCenter(VectorRand(-750 * mul, 750 * mul))
    end
end)

local function installStunImmunityPatch()
    if not hg or hg.ZCityEventStunImmunityPatch then return false end
    if not isfunction(hg.StunPlayer) or not isfunction(hg.LightStunPlayer) then return false end

    local originalStunPlayer = hg.StunPlayer
    local originalLightStunPlayer = hg.LightStunPlayer
    hg.ZCityEventStunImmunityPatch = true

    hg.StunPlayer = function(ply, ...)
        if IsValid(ply) and ply.ZCityEventEndurance then return end
        return originalStunPlayer(ply, ...)
    end

    hg.LightStunPlayer = function(ply, ...)
        if IsValid(ply) and ply.ZCityEventEndurance then return end
        return originalLightStunPlayer(ply, ...)
    end

    return true
end

timer.Create("ZCityEventInstallStunImmunityPatch", 1, 0, function()
    if installStunImmunityPatch() then
        timer.Remove("ZCityEventInstallStunImmunityPatch")
    end
end)

-- Queue the caller for a normal Homicide traitor slot.  Intermission still computes
-- the amount itself; prioritising this player in RandomPairs replaces one random pick.
local forcedHomicideTraitors = {}

concommand.Add("zb_sesh_BONES", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    forcedHomicideTraitors[ply:SteamID64()] = true
end)

local function installHomicideTraitorPatch()
    local mode = zb and zb.modes and zb.modes["hmcd"]
    if not mode or not isfunction(mode.Intermission) or mode.ZCityEventTraitorPatch then return false end

    local originalIntermission = mode.Intermission
    mode.ZCityEventTraitorPatch = true

    function mode:Intermission(...)
        local forced
        for _, candidate in player.Iterator() do
            if candidate:Team() ~= TEAM_SPECTATOR and forcedHomicideTraitors[candidate:SteamID64()] then
                forced = candidate
                break
            end
        end

        if not IsValid(forced) then return originalIntermission(self, ...) end

        local oldRandomPairs, oldKarma = RandomPairs, forced.Karma
        forced.Karma = 100

        RandomPairs = function(tbl, descending)
            local ordered = {}
            for key, value in pairs(tbl) do ordered[#ordered + 1] = {key, value} end
            table.Shuffle(ordered)

            for i = 1, #ordered do
                if ordered[i][2] == forced then
                    ordered[1], ordered[i] = ordered[i], ordered[1]
                    break
                end
            end

            local index = 0
            return function()
                index = index + 1
                local pair = ordered[index]
                if pair then return pair[1], pair[2] end
            end
        end

        local ok, err = pcall(originalIntermission, self, ...)
        RandomPairs = oldRandomPairs
        forced.Karma = oldKarma
        forcedHomicideTraitors[forced:SteamID64()] = nil

        if not ok then error(err) end
    end

    return true
end

timer.Create("ZCityEventInstallHomicideTraitorPatch", 1, 0, function()
    if installHomicideTraitorPatch() then
        timer.Remove("ZCityEventInstallHomicideTraitorPatch")
    end
end)

-- dead inside hello whazzap ?)
