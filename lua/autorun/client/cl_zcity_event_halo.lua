-- Local player finder for the Z-City map event.

local haloEnabled = false
local haloColor = Color(255, 55, 35)
local databaseSchemaTransfers = {}

net.Receive("ZCityEventTogglePlayerHalo", function()
    haloEnabled = not haloEnabled
    MsgC(
        Color(120, 200, 255), "[ZCity] ",
        color_white, "Ореол игроков: " .. (haloEnabled and "включён" or "выключен") .. "\n"
    )
end)

net.Receive("ZCityEventDatabaseSchemaBegin", function()
    local requestID = net.ReadUInt(32)
    databaseSchemaTransfers[requestID] = {
        expected = net.ReadUInt(16),
        filenamePrefix = net.ReadString(),
        extension = net.ReadString(),
        received = 0,
        chunks = {}
    }
end)

net.Receive("ZCityEventDatabaseSchemaChunk", function()
    local requestID = net.ReadUInt(32)
    local index = net.ReadUInt(16)
    local length = net.ReadUInt(16)
    local transfer = databaseSchemaTransfers[requestID]
    if not transfer or index < 1 or index > transfer.expected then return end

    if not transfer.chunks[index] then
        transfer.chunks[index] = net.ReadData(length)
        transfer.received = transfer.received + 1
    else
        net.ReadData(length)
    end

    if transfer.received < transfer.expected then return end

    local compressed = table.concat(transfer.chunks)
    local payload = util.Decompress(compressed)
    databaseSchemaTransfers[requestID] = nil

    if not payload then
        MsgC(Color(255, 80, 80), "[ZCity DB] Не удалось распаковать файл базы.\n")
        return
    end

    file.CreateDir("zcity")
    local filename = "zcity/" .. transfer.filenamePrefix .. "_" .. os.date("%Y-%m-%d_%H-%M-%S") .. "." .. transfer.extension
    file.Write(filename, payload)
    MsgC(Color(120, 200, 255), "[ZCity DB] Файл сохранён: garrysmod/data/" .. filename .. "\n")
end)

local function addUniqueEntity(list, seen, ent)
    if not IsValid(ent) or seen[ent] then return end
    seen[ent] = true
    list[#list + 1] = ent
end

hook.Add("PreDrawHalos", "ZCityEventPlayerFinder", function()
    if not haloEnabled then return end

    local localPlayer = LocalPlayer()
    local targets, seen = {}, {}

    for _, ply in player.Iterator() do
        if ply == localPlayer or ply:Team() == TEAM_SPECTATOR then continue end

        addUniqueEntity(targets, seen, ply)
        addUniqueEntity(targets, seen, ply:GetNWEntity("FakeRagdoll"))
        addUniqueEntity(targets, seen, ply:GetNWEntity("RagdollDeath"))

        if IsValid(ply.FakeRagdoll) then
            addUniqueEntity(targets, seen, ply.FakeRagdoll)
        end
        if IsValid(ply.RagdollDeath) then
            addUniqueEntity(targets, seen, ply.RagdollDeath)
        end
        if hg and isfunction(hg.GetCurrentCharacter) then
            addUniqueEntity(targets, seen, hg.GetCurrentCharacter(ply))
        end
    end

    if #targets > 0 then
        halo.Add(targets, haloColor, 2, 2, 1, true, true)
    end
end)
