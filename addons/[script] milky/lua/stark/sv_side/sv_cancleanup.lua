if SERVER then
    function CanMilkyCleanup(ply)
        return IsValid(ply) and ply:IsSuperAdmin()
    end

    hook.Add("CanCleanupMap", "RestrictCleanupMilky", CanMilkyCleanup)
end

//
//
//

if CLIENT then return end

local DOOR_CLASSES = {
    func_door = true,
    func_door_rotating = true,
    prop_door_rotating = true
}

local IGNORE_CLASSES = {
    worldspawn = true,
    player = true,
    npc = true,
    viewmodel = true,
    predicted_viewmodel = true
}

local TRACK = {}
local STUCK_TIME = 0.75
local SCAN_INTERVAL = 0.1
local EXTRA_MARGIN = 4
local MAX_SCAN_RADIUS = 160
local DOOR_MIN_SPEED_SQR = 4
local ENT_MAX_MOVE_SQR = 16
local DOOR_TOUCH_COOLDOWN = 0.5

local function IsDoor(ent)
    return IsValid(ent) and DOOR_CLASSES[ent:GetClass()] == true
end

local function DoorVelocitySqr(ent)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        local vel = phys:GetVelocity()
        return vel:LengthSqr()
    end
    local vel = ent:GetVelocity()
    return vel:LengthSqr()
end

local function IsDoorActive(ent)
    if not IsValid(ent) then return false end
    return DoorVelocitySqr(ent) >= DOOR_MIN_SPEED_SQR
end

local function IsHeldByPlayer(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayerHolding() then return true end

    local owner = ent.CPPIGetOwner and ent:CPPIGetOwner() or nil
    if IsValid(owner) and owner:IsPlayer() then
        local wep = owner:GetActiveWeapon()
        if IsValid(wep) and wep.GetClass and wep:GetClass() == "weapon_physgun" then
            local tr = owner:GetEyeTrace()
            if tr and tr.Entity == ent then
                return true
            end
        end
    end

    return false
end

local function HasConstraintsSafe(ent)
    if not IsValid(ent) then return false end
    if not constraint or not constraint.HasConstraints then return false end
    return constraint.HasConstraints(ent) == true
end

local function IsRemovable(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() or ent:IsNPC() then return false end
    if ent:IsWeapon() then return false end
    if ent:IsVehicle() then return false end
    if IsDoor(ent) then return false end
    if IGNORE_CLASSES[ent:GetClass()] then return false end
    if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
    if ent:GetParent() ~= NULL then return false end
    if HasConstraintsSafe(ent) then return false end
    if IsHeldByPlayer(ent) then return false end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return false end
    if not phys:IsMotionEnabled() then return false end

    return true
end

local function GetDoorCenter(ent)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    return ent:LocalToWorld((mins + maxs) * 0.5)
end

local function GetDoorRadius(ent)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    return math.min((maxs - mins):Length() * 0.5 + EXTRA_MARGIN, MAX_SCAN_RADIUS)
end

local function IsInsideDoor(door, ent)
    local pos = door:WorldToLocal(ent:WorldSpaceCenter())
    local mins = door:OBBMins() - Vector(EXTRA_MARGIN, EXTRA_MARGIN, EXTRA_MARGIN)
    local maxs = door:OBBMaxs() + Vector(EXTRA_MARGIN, EXTRA_MARGIN, EXTRA_MARGIN)

    return pos.x >= mins.x and pos.x <= maxs.x
       and pos.y >= mins.y and pos.y <= maxs.y
       and pos.z >= mins.z and pos.z <= maxs.z
end

local function RecentlyTouchedByPlayer(ent)
    if not IsValid(ent) then return false end
    local t = ent.__door_last_player_touch
    return t and t > CurTime()
end

local function MarkPlayerTouch(ply)
    if not IsValid(ply) then return end

    local center = ply:WorldSpaceCenter()
    for _, ent in ipairs(ents.FindInSphere(center, 24)) do
        if IsValid(ent) then
            ent.__door_last_player_touch = CurTime() + DOOR_TOUCH_COOLDOWN
        end
    end
end

hook.Add("StartTouch", "door_antistuck_player_touch_mark", function(ent, other)
    if IsValid(ent) and ent:IsPlayer() and IsValid(other) then
        other.__door_last_player_touch = CurTime() + DOOR_TOUCH_COOLDOWN
    elseif IsValid(other) and other:IsPlayer() and IsValid(ent) then
        ent.__door_last_player_touch = CurTime() + DOOR_TOUCH_COOLDOWN
    end
end)

hook.Add("ShouldCollide", "door_antistuck_player_touch_mark", function(a, b)
    if IsValid(a) and a:IsPlayer() then
        MarkPlayerTouch(a)
    end
    if IsValid(b) and b:IsPlayer() then
        MarkPlayerTouch(b)
    end
end)

local function CleanupTrack()
    for di, data in pairs(TRACK) do
        local door = Entity(di)
        if not IsValid(door) then
            TRACK[di] = nil
        else
            for ei in pairs(data) do
                local ent = Entity(ei)
                if not IsValid(ent) then
                    data[ei] = nil
                end
            end
            if next(data) == nil then
                TRACK[di] = nil
            end
        end
    end
end

local function RemoveStuck(ent)
    if not IsValid(ent) then return end
    SafeRemoveEntity(ent)
end

local function TrackEnt(door, ent)
    local di = door:EntIndex()
    local ei = ent:EntIndex()

    TRACK[di] = TRACK[di] or {}

    local record = TRACK[di][ei]
    local pos = ent:GetPos()

    if not record then
        TRACK[di][ei] = {
            since = CurTime(),
            lastpos = pos
        }
        return
    end

    if record.lastpos:DistToSqr(pos) > ENT_MAX_MOVE_SQR then
        record.since = CurTime()
        record.lastpos = pos
        return
    end

    if CurTime() - record.since >= STUCK_TIME then
        RemoveStuck(ent)
        TRACK[di][ei] = nil
        return
    end

    record.lastpos = pos
end

timer.Create("door_antistuck_remove_scan", SCAN_INTERVAL, 0, function()
    CleanupTrack()

    for _, door in ipairs(ents.GetAll()) do
        if IsDoor(door) and IsDoorActive(door) then
            local center = GetDoorCenter(door)
            local radius = GetDoorRadius(door)

            for _, ent in ipairs(ents.FindInSphere(center, radius)) do
                if IsRemovable(ent) and not RecentlyTouchedByPlayer(ent) and IsInsideDoor(door, ent) then
                    TrackEnt(door, ent)
                end
            end
        end
    end
end)