require("mysqloo")

hg = hg or {}
hg.db = hg.db or {}

hg.db.host = "46.174.50.7"
hg.db.user = "u39635_necoder"
hg.db.pass = "0T8d8A6f8A!!!!!!!"
hg.db.name = "u39635_zcity2"
hg.db.port = 3306

function hg.db.Connect()
    if hg.db._conn and hg.db._conn:status() == mysqloo.DATABASE_CONNECTED then return end

    hg.db._conn = mysqloo.connect(hg.db.host, hg.db.user, hg.db.pass, hg.db.name, hg.db.port)

    hg.db._conn.onConnected = function()
        -- ВАЖНО: привязали коннект к врапперу
        mysql.module = "mysqloo"
        mysql.connection = hg.db._conn

        -- пусть враппер сам кинет DatabaseConnected
        mysql:OnConnected()
    end

    hg.db._conn.onConnectionFailed = function(_, err)
        -- чтобы ты видел причину!
        print("[DB] ConnectionFailed:", err)

        mysql.connection = nil
        if mysql.OnConnectionFailed then
            mysql:OnConnectionFailed(err)
        else
            hook.Run("DatabaseConnectionFailed", err)
        end

        timer.Simple(5, function()
            if not IsValid(game.GetWorld()) then return end
            hg.db.Connect()
        end)
    end

    hg.db._conn:connect()
end

hook.Add("InitPostEntity", "zbDatabaseConnect", function()
    hg.db.Connect()
end)