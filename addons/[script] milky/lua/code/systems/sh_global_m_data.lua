// это пропорциональонсть лени и долбоедибзма
// это не должно было существовать в реальности
// понятие пространства и времени было нарушено и это появилось на свет чернокнижником milky

mdata = mdata or {}

timer.Simple(1, function()
    local PLAYER = FindMetaTable("Player")

    mdata.TableName       = mdata.TableName or "mdata_players"
    mdata.FlushInterval   = mdata.FlushInterval or 10
    mdata.DebounceSeconds = mdata.DebounceSeconds or 2
    mdata.JoinSyncDelay   = mdata.JoinSyncDelay or 1

    mdata.db         = mdata.db or nil
    mdata.ready      = mdata.ready or false
    mdata.connecting = mdata.connecting or false

    mdata.columns = mdata.columns or {}
    mdata.cache   = mdata.cache or {}
    mdata.dirty   = mdata.dirty or {}
    mdata.debounce = mdata.debounce or {}
    mdata.cb      = mdata.cb or {}

    mdata.pendingLoads = mdata.pendingLoads or {}
    mdata.loaded       = mdata.loaded or {}

    local function EnsurePlayer(ply)
        if not mdata.cache[ply] then mdata.cache[ply] = {} end
        if not mdata.dirty[ply] then mdata.dirty[ply] = {} end
    end

    local function GuessKind(val)
        local t = type(val)
        if t == "number" then return "number" end
        if t == "boolean" then return "bool" end
        return "string"
    end

    local function DefaultFor(kind, val)
        if kind == "number" then return tonumber(val) or 0 end
        if kind == "bool" then return (val and true or false) end
        local s = tostring(val or "")
        return s
    end

    local function EscapeDDLString(s)
        s = tostring(s or "")
        s = string.gsub(s, "\\", "\\\\")
        s = string.gsub(s, "'", "''")
        return s
    end

    local function GuessSQL(kind, defaultVal)
        if kind == "number" then
            local n = tonumber(defaultVal) or 0
            if math.floor(n) ~= n then
                return string.format("DOUBLE NOT NULL DEFAULT %s", tostring(n))
            end
            return string.format("INT NOT NULL DEFAULT %d", tonumber(n) or 0)
        elseif kind == "bool" then
            return string.format("TINYINT(1) NOT NULL DEFAULT %d", defaultVal and 1 or 0)
        else
            return "LONGTEXT"
        end
    end

    local function KindFromSQLType(t)
        t = string.lower(t or "")
        if string.find(t, "tinyint%(1%)", 1, false) then return "bool" end
        if string.find(t, "int", 1, true) or string.find(t, "double", 1, true) or string.find(t, "float", 1, true) or string.find(t, "decimal", 1, true) then
            return "number"
        end
        return "string"
    end

    local function ParseDefault(kind, rawDefault)
        if rawDefault == nil then
            if kind == "number" then return 0 end
            if kind == "bool" then return false end
            return ""
        end
        if kind == "number" then return tonumber(rawDefault) or 0 end
        if kind == "bool" then
            local n = tonumber(rawDefault)
            return n == 1
        end
        return tostring(rawDefault or "")
    end

    local function EscapeValue(kind, val)
        if kind == "number" then
            return tostring(tonumber(val) or 0)
        elseif kind == "bool" then
            return (val and "1" or "0")
        else
            return mdata.db:escape(tostring(val or ""))
        end
    end

    function mdata:IsLoaded(ply)
        if not IsValid(ply) then return false end
        local sid = ply:SteamID64()
        if not sid or sid == "0" then return false end
        return mdata.loaded[sid] == true
    end

    local function MarkLoaded(ply)
        if not IsValid(ply) then return end
        local sid = ply:SteamID64()
        if not sid or sid == "0" then return end
        mdata.loaded[sid] = true
    end

    function mdata:AddCallback(key, func)
        self.cb[key] = func
    end

    function mdata:RemoveCallback(key)
        self.cb[key] = nil
    end

    function mdata.RefreshSchema(cb)
        if not mdata.db then if cb then cb(false) end return end

        local q = mdata.db:query("SHOW COLUMNS FROM `" .. mdata.TableName .. "`")

        function q:onSuccess(rows)
            rows = rows or {}
            for _, row in ipairs(rows) do
                local field = row.Field
                if field and field ~= "steamid" then
                    local kind = KindFromSQLType(row.Type)
                    local def = ParseDefault(kind, row.Default)
                    mdata.columns[field] = {
                        kind = kind,
                        sql = row.Type,
                        default = def
                    }
                end
            end
            if cb then cb(true) end
        end

        function q:onError(err)
            print("[MDATA] schema error: " .. tostring(err))
            if cb then cb(false) end
        end

        q:start()
    end

    function mdata.AutoRegisterColumn(key, val)
        if not isstring(key) or key == "" then return end
        if key == "steamid" then return end
        if mdata.columns[key] then return end

        local kind = GuessKind(val)
        local def = DefaultFor(kind, val)
        local sql = GuessSQL(kind, def)

        mdata.columns[key] = {
            kind = kind,
            sql = sql,
            default = def
        }

        if mdata.ready and mdata.db then
            local q = mdata.db:query(string.format(
                "ALTER TABLE `%s` ADD COLUMN `%s` %s",
                mdata.TableName,
                key,
                sql
            ))

            function q:onError(err)
                local msg = tostring(err or "")
                if string.find(msg, "Duplicate", 1, true) then
                    local q2 = mdata.db:query(string.format(
                        "ALTER TABLE `%s` MODIFY COLUMN `%s` %s",
                        mdata.TableName,
                        key,
                        sql
                    ))
                    function q2:onError(e2)
                        local msg2 = tostring(e2 or "")
                        if not string.find(msg2, "Duplicate", 1, true) then
                            print("[MDATA] alter modify error: " .. msg2)
                        end
                    end
                    function q2:onSuccess()
                        mdata.RefreshSchema()
                    end
                    q2:start()
                else
                    print("[MDATA] alter error: " .. msg)
                end
            end

            function q:onSuccess()
                mdata.RefreshSchema()
            end

            q:start()
        end
    end

    function PLAYER:SetMData(key, val)
        if CLIENT then return end
        if not IsValid(self) then return end
        if not isstring(key) or key == "" then return end
        if key == "steamid" then return end

        mdata.AutoRegisterColumn(key, val)

        EnsurePlayer(self)

        mdata.cache[self][key] = val
        mdata.dirty[self][key] = true

        if not mdata.debounce[self] then
            mdata.debounce[self] = true
            timer.Simple(mdata.DebounceSeconds, function()
                if IsValid(self) then
                    mdata.FlushPlayer(self)
                end
                mdata.debounce[self] = nil
            end)
        end

        if netstream then
            netstream.Start(nil, "get_mdata", { sid = self:SteamID64(), key = key, val = val })
        end

        if isfunction(mdata.cb[key]) then
            mdata.cb[key](self, val)
        end
    end

    function PLAYER:GetMData(key, default)
        EnsurePlayer(self)
        local v = mdata.cache[self][key]
        if v == nil then return default end
        return v
    end

    local function BuildUpdateSQL(steamid64, dirtyKeys, cacheRow)
        if not mdata.db then return nil end
        if not steamid64 or steamid64 == "0" then return nil end

        local sets = {}
        for key in pairs(dirtyKeys or {}) do
            local meta = mdata.columns[key]
            if meta then
                local val = cacheRow and cacheRow[key] or meta.default
                local esc = EscapeValue(meta.kind, val)
                if meta.kind == "number" or meta.kind == "bool" then
                    table.insert(sets, string.format("`%s`=%s", key, esc))
                else
                    table.insert(sets, string.format("`%s`='%s'", key, esc))
                end
            end
        end

        if #sets == 0 then return nil end

        local sid = mdata.db:escape(steamid64)
        return string.format(
            "UPDATE `%s` SET %s WHERE steamid='%s'",
            mdata.TableName,
            table.concat(sets, ", "),
            sid
        )
    end

    function mdata.FlushPlayer(ply)
        if not mdata.ready or not mdata.db then return end
        if not IsValid(ply) then return end

        local dirty = mdata.dirty[ply]
        if not dirty then return end

        local sid64 = ply:SteamID64()
        if not sid64 or sid64 == "0" then
            mdata.dirty[ply] = {}
            return
        end

        local flushing = {}
        local hasKeys = false
        for key in pairs(dirty) do
            flushing[key] = true
            hasKeys = true
        end

        if not hasKeys then return end

        local sql = BuildUpdateSQL(sid64, flushing, mdata.cache[ply])

        for key in pairs(flushing) do
            dirty[key] = nil
        end

        if not sql then return end

        local q = mdata.db:query(sql)

        function q:onSuccess()
        end

        function q:onError(err)
            local current = mdata.dirty[ply]
            if current then
                for key in pairs(flushing) do
                    if current[key] == nil then
                        current[key] = true
                    end
                end
            end
            print("[MDATA] save error: " .. tostring(err))
        end

        q:start()
    end

    local function FlushSnapshot(steamid64, dirtyKeys, cacheRow)
        if not mdata.ready or not mdata.db then return end
        local sql = BuildUpdateSQL(steamid64, dirtyKeys, cacheRow)
        if not sql then return end
        local q = mdata.db:query(sql)
        function q:onError(err)
            print("[MDATA] save error: " .. tostring(err))
        end
        q:start()
    end

    function mdata.FlushAll()
        for ply in pairs(mdata.dirty) do
            if IsValid(ply) then
                mdata.FlushPlayer(ply)
            end
        end
    end

    local function InsertIfMissing(ply, cb)
        local sid64 = ply:SteamID64()
        if not sid64 or sid64 == "0" then if cb then cb() end return end

        local cols = { "steamid" }
        local vals = { "'" .. mdata.db:escape(sid64) .. "'" }

        for key, meta in pairs(mdata.columns) do
            if key ~= "steamid" then
                cols[#cols + 1] = "`" .. key .. "`"
                local def = meta.default
                if meta.kind == "number" or meta.kind == "bool" then
                    vals[#vals + 1] = EscapeValue(meta.kind, def)
                else
                    vals[#vals + 1] = "'" .. EscapeValue(meta.kind, def) .. "'"
                end
            end
        end

        local sql = string.format(
            "INSERT INTO `%s` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE steamid=steamid",
            mdata.TableName,
            table.concat(cols, ", "),
            table.concat(vals, ", ")
        )

        local q = mdata.db:query(sql)

        function q:onSuccess()
            if cb then cb() end
        end

        function q:onError(err)
            print("[MDATA] insert error: " .. tostring(err))
            if cb then cb() end
        end

        q:start()
    end

    local function ApplyRowToCache(ply, row)
        EnsurePlayer(ply)

        for key, meta in pairs(mdata.columns) do
            if key ~= "steamid" then
                local raw = row and row[key] or nil
                if raw == nil then
                    mdata.cache[ply][key] = meta.default
                else
                    if meta.kind == "number" then
                        mdata.cache[ply][key] = tonumber(raw) or meta.default
                    elseif meta.kind == "bool" then
                        mdata.cache[ply][key] = (tonumber(raw) == 1)
                    else
                        mdata.cache[ply][key] = tostring(raw or "")
                    end
                end
            end
        end

        if row then
            for key, raw in pairs(row) do
                if key ~= "steamid" and not mdata.columns[key] then
                    local num = tonumber(raw)
                    local kind
                    if raw == "0" or raw == "1" then
                        kind = "bool"
                    elseif num ~= nil then
                        kind = "number"
                    else
                        kind = "string"
                    end
                    local def = DefaultFor(kind, (kind == "number") and (num or 0) or (kind == "bool") and (raw == "1") or tostring(raw))
                    mdata.columns[key] = {
                        kind = kind,
                        sql = GuessSQL(kind, def),
                        default = def
                    }
                    if kind == "number" then
                        mdata.cache[ply][key] = tonumber(raw) or def
                    elseif kind == "bool" then
                        mdata.cache[ply][key] = (tonumber(raw) == 1)
                    else
                        mdata.cache[ply][key] = tostring(raw or "")
                    end
                end
            end
        end
    end

    local function LoadPlayer(ply)
        if not IsValid(ply) then return end
        EnsurePlayer(ply)

        local sid64 = ply:SteamID64()
        if not sid64 or sid64 == "0" then return end

        if not mdata.ready or not mdata.db then
            mdata.pendingLoads[sid64] = true
            return
        end

        InsertIfMissing(ply, function()
            if not IsValid(ply) then return end

            local sid = mdata.db:escape(sid64)
            local q = mdata.db:query(string.format(
                "SELECT * FROM `%s` WHERE steamid='%s' LIMIT 1",
                mdata.TableName,
                sid
            ))

            function q:onSuccess(data)
                if not IsValid(ply) then return end
                local row = data and data[1] or nil
                ApplyRowToCache(ply, row)
                MarkLoaded(ply)

                timer.Simple(mdata.JoinSyncDelay, function()
                    if IsValid(ply) and netstream then
                        netstream.Start(ply, "get_all_mdata", { sid = sid64, data = mdata.cache[ply] })
                    end
                end)
            end

            function q:onError(err)
                print("[MDATA] load error: " .. tostring(err))
            end

            q:start()
        end)
    end

    local function WidenStringColumns(cb)
        if not mdata.db then if cb then cb() end return end

        local toFix = {}
        for key, meta in pairs(mdata.columns) do
            if key ~= "steamid" and meta and meta.kind == "string" then
                local t = string.lower(meta.sql or "")
                if string.find(t, "char", 1, true) then
                    toFix[#toFix + 1] = key
                end
            end
        end

        local index = 0
        local function step()
            index = index + 1
            local key = toFix[index]
            if not key then
                if cb then cb() end
                return
            end

            local q = mdata.db:query(string.format(
                "ALTER TABLE `%s` MODIFY COLUMN `%s` LONGTEXT",
                mdata.TableName,
                key
            ))

            function q:onSuccess()
                if mdata.columns[key] then
                    mdata.columns[key].sql = "longtext"
                end
                step()
            end

            function q:onError(err)
                print("[MDATA] widen error (" .. key .. "): " .. tostring(err))
                step()
            end

            q:start()
        end

        step()
    end

    if SERVER then
        timer.Simple(0.1, function()
            if mdata.connecting then return end
            mdata.connecting = true

            require("mysqloo")

            local DATABASE = mysqloo.connect(
                RP_MySQLConfig.Host,
                RP_MySQLConfig.Username,
                RP_MySQLConfig.Password,
                RP_MySQLConfig.Database_name,
                RP_MySQLConfig.Database_port
            )

            function DATABASE:onConnected()
                mdata.db = DATABASE

                local create = DATABASE:query(
                    "CREATE TABLE IF NOT EXISTS `" .. mdata.TableName .. "` (steamid VARCHAR(32) NOT NULL PRIMARY KEY)"
                )

                function create:onSuccess()
                    mdata.RefreshSchema(function(ok)
                        if not ok then
                            mdata.ready = false
                            mdata.connecting = false
                            return
                        end

                        WidenStringColumns(function()
                            mdata.RefreshSchema(function(ok2)
                                mdata.ready = ok2 and true or false
                                mdata.connecting = false

                                for sid64 in pairs(mdata.pendingLoads) do
                                    local ply = player.GetBySteamID64(sid64)
                                    if IsValid(ply) then
                                        LoadPlayer(ply)
                                    end
                                    mdata.pendingLoads[sid64] = nil
                                end
                            end)
                        end)
                    end)
                end

                function create:onError(err)
                    print("[MDATA] create error: " .. tostring(err))
                    mdata.connecting = false
                end

                create:start()

                timer.Create("mdata_flush_timer", mdata.FlushInterval, 0, function()
                    mdata.FlushAll()
                end)
            end

            function DATABASE:onConnectionFailed(err)
                print("[MDATA] mysql error: " .. tostring(err))
                mdata.connecting = false
            end

            DATABASE:connect()
        end)

        hook.Add("PlayerInitialSpawn", "mdata_init_and_load", function(ply)
            EnsurePlayer(ply)
            LoadPlayer(ply)
        end)

        hook.Add("PlayerDisconnected", "mdata_cleanup", function(ply)
            local sid64 = IsValid(ply) and ply:SteamID64() or nil
            local cacheRow = mdata.cache[ply]
            local dirtyKeys = mdata.dirty[ply]

            timer.Simple(0, function()
                if sid64 and sid64 ~= "0" and istable(cacheRow) and istable(dirtyKeys) then
                    FlushSnapshot(sid64, dirtyKeys, cacheRow)
                end

                mdata.cache[ply] = nil
                mdata.dirty[ply] = nil
                mdata.debounce[ply] = nil

                if sid64 and sid64 ~= "0" then
                    mdata.loaded[sid64] = nil
                    mdata.pendingLoads[sid64] = nil
                end
            end)
        end)

        hook.Add("ShutDown", "mdata_shutdown_flush", function()
            mdata.FlushAll()
        end)
    end

    if CLIENT then
        netstream.Hook("get_mdata", function(data)
            if not data then return end
            local sid = data.sid
            if not sid then return end
            local ply = player.GetBySteamID64(sid)
            if not IsValid(ply) then return end
            if not mdata.cache[ply] then mdata.cache[ply] = {} end
            mdata.cache[ply][data.key] = data.val
            if isfunction(mdata.cb[data.key]) then
                mdata.cb[data.key](ply, data.val)
            end
        end)

        netstream.Hook("get_all_mdata", function(payload)
            if not istable(payload) then return end
            local sid = payload.sid
            local data = payload.data
            if not sid or not istable(data) then return end
            local ply = player.GetBySteamID64(sid)
            if not IsValid(ply) then return end
            mdata.cache[ply] = data
        end)
    end
end)