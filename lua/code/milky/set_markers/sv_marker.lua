util.AddNetworkString("HMCD_UpdateTraitorAssistants")
util.AddNetworkString("HMCD_RequestTraitorMarkers")

local function GetHMCDTraitorMarkerName(ply)
    if not IsValid(ply) then return "unknown" end

    if ply.CurAppearance and ply.CurAppearance.AName and ply.CurAppearance.AName ~= "" then
        return ply.CurAppearance.AName
    end

    if ply.GetPlayerName then
        local name = ply:GetPlayerName()

        if name and name ~= "" then
            return name
        end
    end

    return ply:Nick()
end

local function GetHMCDTraitorMarkerColor(ply)
    if IsValid(ply) and ply.CurAppearance then
        local color = ply.CurAppearance.AColor

        if IsColor(color) then
            return color
        end

        if istable(color) and color.r and color.g and color.b then
            return Color(color.r, color.g, color.b)
        end
    end

    if IsValid(ply) and ply.GetPlayerColor then
        local vec = ply:GetPlayerColor()

        if vec and vec.ToColor then
            return vec:ToColor()
        end
    end

    return Color(190, 0, 0)
end

local function IsHMCDTraitorValid(ply)
    if not IsValid(ply) then return false end
    if not ply.isTraitor then return false end
    if ply:Team() == TEAM_SPECTATOR then return false end

    return true
end

local function BuildHMCDTraitorMarkerList()
    local traitors = {}

    for _, other in player.Iterator() do
        if IsHMCDTraitorValid(other) then
            traitors[#traitors + 1] = {
                ply = other,
                color = GetHMCDTraitorMarkerColor(other),
                name = GetHMCDTraitorMarkerName(other)
            }
        end
    end

    return traitors
end

function HMCD_SendTraitorMarkers(ply)
    if not IsValid(ply) then return end
    if not ply.isTraitor then return end
    if ply:Team() == TEAM_SPECTATOR then return end

    local traitors = BuildHMCDTraitorMarkerList()
    local count = math.min(#traitors, 255)

    net.Start("HMCD_UpdateTraitorAssistants")
        net.WriteUInt(count, 8)

        for i = 1, count do
            local info = traitors[i]

            net.WriteEntity(info.ply)
            net.WriteColor(info.color or Color(190, 0, 0), false)
            net.WriteString(info.name or "???")
        end
    net.Send(ply)
end

function HMCD_BroadcastTraitorMarkers()
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply.isTraitor and ply:Team() ~= TEAM_SPECTATOR then
            HMCD_SendTraitorMarkers(ply)
        end
    end
end

net.Receive("HMCD_RequestTraitorMarkers", function(_, ply)
    if not IsValid(ply) then return end

    timer.Simple(0, function()
        if not IsValid(ply) then return end
        HMCD_SendTraitorMarkers(ply)
    end)
end)

hook.Add("PlayerSpawn", "HMCD_Marker_PlayerSpawn", function()
    timer.Simple(0.5, function()
        HMCD_BroadcastTraitorMarkers()
    end)

    timer.Simple(1.5, function()
        HMCD_BroadcastTraitorMarkers()
    end)
end)

hook.Add("PlayerDeath", "HMCD_Marker_PlayerDeath", function()
    timer.Simple(0.2, function()
        HMCD_BroadcastTraitorMarkers()
    end)
end)

hook.Add("PlayerSilentDeath", "HMCD_Marker_PlayerSilentDeath", function()
    timer.Simple(0.2, function()
        HMCD_BroadcastTraitorMarkers()
    end)
end)

hook.Add("PlayerDisconnected", "HMCD_Marker_PlayerDisconnected", function()
    timer.Simple(0.2, function()
        HMCD_BroadcastTraitorMarkers()
    end)
end)

timer.Create("HMCD_Marker_PeriodicSync", 1, 0, function()
    HMCD_BroadcastTraitorMarkers()
end)