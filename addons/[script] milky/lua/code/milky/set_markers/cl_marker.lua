local HMCDTraitorMarkers = {}

local MARKER_SIZE = 80
local MARKER_RING = 6
local ICON_PADDING = 22

local UNITS_TO_METERS = 0.01905

local STATIC_NEAR_START_UNITS = 3 / UNITS_TO_METERS
local STATIC_NEAR_END_UNITS = 5 / UNITS_TO_METERS
local STATIC_FAR_START_UNITS = 200 / UNITS_TO_METERS
local STATIC_FAR_END_UNITS = 250 / UNITS_TO_METERS

local TRAITOR_ICON = "traitor"

surface.CreateFont("MilkyMarkerMontserrat", {
    font = "Montserrat Medium",
    size = 22,
    weight = 500,
    extended = true,
    antialias = true
})

function HMCD_ClearTraitorMarkers()
    HMCDTraitorMarkers = {}
end

local function ResolveTraitorMarkerTarget(rawTarget, rawName, rawSteamID)
    if IsValid(rawTarget) and rawTarget:IsPlayer() then
        return rawTarget
    end

    local steamID = isstring(rawSteamID) and rawSteamID or ""
    local name = isstring(rawName) and rawName or ""

    for _, ply in player.Iterator() do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        if steamID ~= "" and not ply:IsBot() and ply:SteamID() == steamID then
            return ply
        end

        if name ~= "" and ply.CurAppearance and ply.CurAppearance.AName == name then
            return ply
        end

        if name ~= "" and ply.GetPlayerName and ply:GetPlayerName() == name then
            return ply
        end

        if name ~= "" and ply:Nick() == name then
            return ply
        end
    end
end

function HMCD_SetTraitorMarkersFromList(list)
    HMCDTraitorMarkers = {}

    if not istable(list) then return end

    for _, info in ipairs(list) do
        local target = info[1]
        local color = info[2]
        local name = info[3]
        local steamID = info[4]

        if not (IsValid(target) and target:IsPlayer()) then
            target = ResolveTraitorMarkerTarget(nil, info[2], info[3])
            color = info[1]
            name = info[2]
            steamID = info[3]
        end

        target = ResolveTraitorMarkerTarget(target, name, steamID)

        if IsValid(target) and target:IsPlayer() then
            HMCDTraitorMarkers[target] = {
                target = target,
                color = IsColor(color) and color or Color(190, 0, 0),
                name = name or target:Nick(),
                active = true
            }

            target.isTraitor = true
        end
    end
end

local function HMCD_RequestTraitorMarkers()
    if not IsValid(LocalPlayer()) then return end

    net.Start("HMCD_RequestTraitorMarkers")
    net.SendToServer()
end

net.Receive("HMCD_UpdateTraitorAssistants", function()
    local currentMode = MODE
    local traitorsLocal = {}

    if currentMode then
        currentMode.TraitorsLocal = traitorsLocal
    end

    local count = net.ReadUInt(8)

    for i = 1, count do
        local target = net.ReadEntity()
        local color = net.ReadColor(false)
        local name = net.ReadString()

        if IsValid(target) and target:IsPlayer() then
            traitorsLocal[#traitorsLocal + 1] = {
                target,
                IsColor(color) and color or Color(190, 0, 0),
                name or target:Nick()
            }
        end
    end

    HMCD_SetTraitorMarkersFromList(traitorsLocal)
end)

local function GetMarkerAlpha(distUnits)
    if distUnits <= STATIC_NEAR_END_UNITS then
        local t = math.Clamp((distUnits - STATIC_NEAR_START_UNITS) / (STATIC_NEAR_END_UNITS - STATIC_NEAR_START_UNITS), 0, 1)
        t = t * t * (3 - 2 * t)

        return Lerp(t, 25, 255)
    end

    if distUnits >= STATIC_FAR_START_UNITS then
        local t = math.Clamp((distUnits - STATIC_FAR_START_UNITS) / (STATIC_FAR_END_UNITS - STATIC_FAR_START_UNITS), 0, 1)
        t = t * t * (3 - 2 * t)

        return Lerp(t, 255, 0)
    end

    return 255
end

local function GetMarkerMaterial(icon)
    if not icon or icon == "" then return nil end
    if not monteract_materials or not monteract_materials.getByID then return nil end

    return monteract_materials.getByID(icon)
end

local function DrawSmoothIcon(mat, x, y, size)
    if not mat then return end

    surface.SetMaterial(mat)
    surface.SetDrawColor(255, 255, 255, 255)

    render.PushFilterMag(TEXFILTER.LINEAR)
    render.PushFilterMin(TEXFILTER.LINEAR)
        surface.DrawTexturedRectRotated(x, y, size, size, 0)
    render.PopFilterMin()
    render.PopFilterMag()
end

local function DrawNiceMarker(x, y, mat, color)
    local r = MARKER_SIZE / 2
    local innerRadius = r - MARKER_RING
    local safeRadius = innerRadius - ICON_PADDING
    local iconSize = math.max(1, math.floor(safeRadius * 2))

    color = IsColor(color) and color or Color(190, 0, 0)

    if RNDX and RNDX.DrawCircle then
        RNDX.DrawCircle(x, y, r + 10, Color(color.r, color.g, color.b, 18))
        RNDX.DrawCircle(x, y, r + 5, Color(color.r, color.g, color.b, 35))
        RNDX.DrawCircle(x, y, r, Color(255, 255, 255, 235))
        RNDX.DrawCircle(x, y, innerRadius, Color(12, 16, 24, 220))
        RNDX.DrawCircle(x, y, innerRadius - 8, Color(255, 255, 255, 15))
    else
        draw.NoTexture()

        surface.SetDrawColor(color.r, color.g, color.b, 220)
        surface.DrawCircle(x, y, r, color.r, color.g, color.b, 220)

        surface.SetDrawColor(12, 16, 24, 230)
        surface.DrawCircle(x, y, innerRadius, 12, 16, 24, 230)
    end

    if mat then
        DrawSmoothIcon(mat, x, y, iconSize)
    else
        draw.SimpleText("T", "MilkyMarkerMontserrat", x, y - 2, Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function DrawMarkerTitle(x, y, title)
    if not title or title == "" then return end

    draw.SimpleText(title, "MilkyMarkerMontserrat", x + 1, y + 35, Color(0, 0, 0, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(title, "MilkyMarkerMontserrat", x, y + 34, Color(255, 255, 255, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function CanDrawTraitorMarkers(ply)
    if not IsValid(ply) then return false end
    if not ply:Alive() then return false end
    if ply:Team() == TEAM_SPECTATOR then return false end

    if ply.isTraitor then return true end
    if next(HMCDTraitorMarkers) ~= nil then return true end

    return false
end

local function GetMarkerWorldPos(target)
    if not IsValid(target) then return vector_origin end

    local bone = target:LookupBone("ValveBiped.Bip01_Head1")

    if bone then
        local bone_pos = target:GetBonePosition(bone)

        if bone_pos and bone_pos ~= vector_origin then
            return bone_pos + Vector(0, 0, 18)
        end
    end

    return target:LocalToWorld(target:OBBCenter()) + Vector(0, 0, 42)
end

local function IsPointInFrontOfView(pos)
    local view_pos = EyePos()
    local view_dir = EyeAngles():Forward()
    local dir = pos - view_pos

    if dir:IsZero() then return false end

    dir:Normalize()

    return view_dir:Dot(dir) > 0.01
end

local function DrawHMCDTraitorMarkers()
    local ply = LocalPlayer()
    if not CanDrawTraitorMarkers(ply) then return end

    local plyPos = ply:GetPos()
    local mat = GetMarkerMaterial(TRAITOR_ICON)

    for target, data in pairs(HMCDTraitorMarkers) do
        if not data or data.active == false then continue end
        if not IsValid(target) then continue end
        if target == ply then continue end
        if not target:Alive() then continue end
        if target:Team() == TEAM_SPECTATOR then continue end

        local pos = GetMarkerWorldPos(target)
        local distUnits = plyPos:Distance(pos)

        if distUnits >= STATIC_FAR_END_UNITS then continue end
        if not IsPointInFrontOfView(pos) then continue end

        local alpha = GetMarkerAlpha(distUnits)
        if alpha <= 0 then continue end

        local screenPos = pos:ToScreen()
        if not screenPos.visible then continue end

        surface.SetAlphaMultiplier(alpha / 255)
            DrawNiceMarker(screenPos.x, screenPos.y, mat, data.color)
            DrawMarkerTitle(screenPos.x, screenPos.y, data.name or target:Nick())
        surface.SetAlphaMultiplier(1)
    end
end

hook.Add("HUDPaint", "HMCD_MilkyDrawTraitorMarkers", function()
    DrawHMCDTraitorMarkers()
end)

hook.Add("PostPlayerDeath", "HMCD_MilkyClearTraitorMarkersDeath", function(ply)
    if ply == LocalPlayer() then
        HMCD_ClearTraitorMarkers()
    end
end)

hook.Add("InitPostEntity", "HMCD_MilkyRequestTraitorMarkersInit", function()
    timer.Simple(1, HMCD_RequestTraitorMarkers)
    timer.Simple(3, HMCD_RequestTraitorMarkers)
end)

hook.Add("Think", "HMCD_MilkyTraitorMarkerFailsafe", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then
        if next(HMCDTraitorMarkers) ~= nil then
            HMCD_ClearTraitorMarkers()
        end

        return
    end

    if ply.isTraitor then
        if not ply.HMCD_NextMarkerRequest or ply.HMCD_NextMarkerRequest < CurTime() then
            ply.HMCD_NextMarkerRequest = CurTime() + 1
            HMCD_RequestTraitorMarkers()
        end
    end
end)
