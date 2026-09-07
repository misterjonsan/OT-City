sound.Add({
    name = "mark_footsteps",
    channel = CHAN_BODY,
    volume = 0.5,
    level = 60,
    pitch = {90, 110},
    sound = {
        "npc/dog/dog_footstep1.wav",
        "npc/dog/dog_footstep2.wav",
        "npc/dog/dog_footstep3.wav",
        "npc/dog/dog_footstep4.wav"
    }
})

local function HasAccessory(ply, uid)
    if not IsValid(ply) then return false end

    local accessories = ply:GetNetVar("Accessories", {})
    if not istable(accessories) then return false end

    for _, accUID in pairs(accessories) do
        if tostring(accUID) == uid then
            return true
        end
    end

    return false
end

local function PlayExojumpFootstep(ply)
    if not IsValid(ply) then return end
    if (ply.ExojumpNextFootstep or 0) > CurTime() then return end

    local speed = ply:GetVelocity():Length2D()
    if speed < 35 then return end

    local delay = ply:Crouching() and 0.45 or 0.32
    if ply:KeyDown(IN_SPEED) then delay = 0.25 end

    ply.ExojumpNextFootstep = CurTime() + delay

    ply:EmitSound("mark_footsteps", 60, math.random(90,110), 0.5, CHAN_BODY)
end

hook.Add("HG_PlayerFootstep", "Exojump_BlockHGFootsteps", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not HasAccessory(ply, "exojump") then return end

    PlayExojumpFootstep(ply)
    return true
end)

hook.Add("Exojump_PlayFootstep", "Exojump_PlayFootstep", function(ply)
    if not IsValid(ply) or not ply:Alive() then return true end
    if not HasAccessory(ply, "exojump") then return true end

    PlayExojumpFootstep(ply)
    return true
end)

hook.Add("Think", "Exojump_BackwardFootsteps", function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        if not HasAccessory(ply, "exojump") then continue end
        if not ply:OnGround() then continue end
        if ply:GetMoveType() ~= MOVETYPE_WALK then continue end
        if ply:GetVelocity():Length2D() < 35 then continue end

        PlayExojumpFootstep(ply)
    end
end)