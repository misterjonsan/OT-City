if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tpik_base"

local sprayRange = CreateConVar("pepperspray_range", "160", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Эффективная дальность перцового баллончика")

SWEP.PrintName = "Перцовый балончик"
SWEP.Instructions = "Нелетальное средство самообороны. Вызывает временную слепоту, дикое жжение и панику."
SWEP.Category = "ZCity"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.IconOverride = "entities/weapon_pepperspray_tpik.png"

if CLIENT then
    SWEP.WepSelectIcon = Material("entities/weapon_pepperspray_tpik.png")
    SWEP.WepSelectIcon2 = Material("entities/weapon_pepperspray_tpik.png")
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.ViewModel = "models/weapons/custom/v_pepperspray.mdl"
SWEP.WorldModel = "models/weapons/custom/pepperspray.mdl"
SWEP.WorldModelReal = "models/weapons/custom/v_pepperspray.mdl"
SWEP.WorldModelExchange = false
SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(0, 0, 0)
SWEP.HoldPos = Vector(-3.8, -6, 0)
SWEP.HoldAng = Angle(0, 0, 10)
SWEP.HoldType = "slam"
SWEP.modelscale = 1
SWEP.modelscale2 = 1

SWEP.AnimList = {
    ["deploy"] = { "draw", 1, false },
    ["idle"] = { "idle", 5, true },
    ["start_spray"] = { "startsh", 0.5, false },
    ["stop_spray"] = { "stopsh", 0.3, false },
    ["safety_off"] = { "safetyoff", 1, false },
    ["safety_on"] = { "safetyon", 1, false }
}

sound.Add({
    name = "PepperSpray.Loop",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 60,
    pitch = {95, 105},
    sound = "weapons/pepperspray/spray_loop.wav"
})

sound.Add({
    name = "PepperSpray.Shake",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 60,
    pitch = {95, 105},
    sound = "weapons/pepperspray/shake.wav"
})

local SPRAY_CLASS = "weapon_pepperspray_tpik"

local function SprayOwnerValid(wep)
    if not IsValid(wep) then return false end

    local owner = wep:GetOwner()

    if not IsValid(owner) then return false end
    if not owner:IsPlayer() then return false end
    if not owner:Alive() then return false end
    if owner:Health() <= 0 then return false end
    if IsValid(owner.FakeRagdoll) then return false end
    if owner:GetActiveWeapon() ~= wep then return false end

    return true
end

local function CallBase(self, name, ...)
    local base = self.BaseClass

    if base and isfunction(base[name]) then
        return base[name](self, ...)
    end
end

function SWEP:StopSpray()
    local wasSpraying = self.IsSpraying

    self.IsSpraying = false

    if SERVER and self:GetNWBool("IsSpraying", false) then
        self:SetNWBool("IsSpraying", false)
    end

    if wasSpraying and SprayOwnerValid(self) and isfunction(self.PlayAnim) then
        self:PlayAnim("stop_spray")
    end
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end

    if not SprayOwnerValid(self) then
        self:StopSpray()

        return
    end

    local owner = self:GetOwner()

    if not owner:KeyDown(IN_ATTACK) then
        self:StopSpray()

        return
    end

    self:SetNextPrimaryFire(CurTime() + 0.05)

    if not self.IsSpraying then
        self.IsSpraying = true

        if isfunction(self.PlayAnim) then
            self:PlayAnim("start_spray")
        end
    end

    if not SERVER then return end

    if not self:GetNWBool("IsSpraying", false) then
        self:SetNWBool("IsSpraying", true)
    end

    local shootPos = owner:GetShootPos()
    local tr = util.TraceLine({
        start = shootPos,
        endpos = shootPos + owner:GetAimVector() * sprayRange:GetFloat(),
        filter = owner
    })

    if not tr.Hit then return end

    local ent = tr.Entity

    if not IsValid(ent) then return end

    local org = ent.organism or (ent:IsPlayer() and IsValid(ent.FakeRagdoll) and ent.FakeRagdoll.organism)

    if not org then return end

    local isFace = false

    if tr.HitGroup == HITGROUP_HEAD then
        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")

        if headBone then
            local bonePos, boneAng = ent:GetBonePosition(headBone)
            local localHitPos = (tr.HitPos - bonePos):GetNormalized()

            if localHitPos:Dot(boneAng:Right()) < -0.2 then
                isFace = true
            end
        end
    end

    if isFace then
        org.pain = math.min((org.pain or 0) + 4, 250)
        org.disorientation = math.min((org.disorientation or 0) + 1.5, 10)

        if ent:IsPlayer() and ent:Alive() then
            ent:SetNWFloat("PS_Exposure", ent:GetNWFloat("PS_Exposure", 0) + 0.05)
            ent:SetNWFloat("PS_LastHitTime", CurTime())
            ent:SetNWFloat("PS_LingeringTint", math.min(ent:GetNWFloat("PS_LingeringTint", 0) + 15, 100))
        end
    end

    self.NextBareInfo = self.NextBareInfo or 0

    if self.NextBareInfo < CurTime() then
        self.NextBareInfo = CurTime() + 0.25

        hg.send_bareinfo(org)
    end
end

function SWEP:ThinkAdd()
    local stale = self.IsSpraying or (SERVER and self:GetNWBool("IsSpraying", false))

    if not SprayOwnerValid(self) then
        if stale then
            self:StopSpray()
        end

        return
    end

    if stale and not self:GetOwner():KeyDown(IN_ATTACK) then
        self:StopSpray()
    end
end

function SWEP:Holster(...)
    self:StopSpray()

    local ret = CallBase(self, "Holster", ...)

    if ret ~= nil then return ret end

    return true
end

function SWEP:OnDrop(...)
    self:StopSpray()

    return CallBase(self, "OnDrop", ...)
end

function SWEP:OwnerChanged(...)
    self:StopSpray()

    return CallBase(self, "OwnerChanged", ...)
end

function SWEP:Equip(...)
    self:StopSpray()

    return CallBase(self, "Equip", ...)
end

function SWEP:OnRemove()
    self:StopSpray()
end

function SWEP:PreDrawViewModel(vm, wep, ply)
    if IsValid(ply) and (IsValid(ply.FakeRagdoll) or (ply.IsFirstPerson and not ply:IsFirstPerson())) then
        return true
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Initialize()
    self:SetHold(self.HoldType)
    self:InitAdd()
end

function SWEP:InitAdd()
end

if SERVER then
    local function StopPlayerSprays(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local weps = ply:GetWeapons()

        for i = 1, #weps do
            local wep = weps[i]

            if IsValid(wep) and wep:GetClass() == SPRAY_CLASS then
                wep.IsSpraying = false

                if isfunction(wep.StopSpray) then
                    wep:StopSpray()
                else
                    wep:SetNWBool("IsSpraying", false)
                end
            end
        end
    end

    hook.Add("DoPlayerDeath", "PepperSpray_StopOnDeath", StopPlayerSprays)
    hook.Add("PlayerDeath", "PepperSpray_StopOnDeath2", StopPlayerSprays)
    hook.Add("PlayerSilentDeath", "PepperSpray_StopOnSilentDeath", StopPlayerSprays)
    hook.Add("PlayerSpawn", "PepperSpray_StopOnSpawn", StopPlayerSprays)

    hook.Add("PlayerDroppedWeapon", "PepperSpray_StopOnDropped", function(ply, wep)
        if IsValid(wep) and wep:GetClass() == SPRAY_CLASS then
            wep.IsSpraying = false
            wep:SetNWBool("IsSpraying", false)
        end
    end)

    timer.Create("PepperSpray_StaleSweep", 0.25, 0, function()
        local list = ents.FindByClass(SPRAY_CLASS)

        for i = 1, #list do
            local wep = list[i]

            if IsValid(wep) and wep:GetNWBool("IsSpraying", false) and not SprayOwnerValid(wep) then
                wep.IsSpraying = false
                wep:SetNWBool("IsSpraying", false)
            end
        end
    end)
end

if CLIENT then
    local emitter = nil

    local offX = CreateClientConVar("pepperspray_offset_x", "17", true, false, "Смещение струи вперёд")
    local offY = CreateClientConVar("pepperspray_offset_y", "3", true, false, "Смещение струи вправо")
    local offZ = CreateClientConVar("pepperspray_offset_z", "-6", true, false, "Смещение струи вверх")

    local PARTICLE_MAX_DIST_SQR = 2500 * 2500

    local cachedList = {}
    local nextListRefresh = 0

    local function IsSprayActive(swep)
        if not IsValid(swep) then return false end
        if not swep:GetNWBool("IsSpraying", false) then return false end

        local owner = swep:GetOwner()

        if not IsValid(owner) then return false end
        if not owner:IsPlayer() then return false end
        if not owner:Alive() then return false end
        if owner:Health() <= 0 then return false end
        if IsValid(owner.FakeRagdoll) then return false end
        if owner:GetActiveWeapon() ~= swep then return false end

        return true
    end

    local function StopClientSpray(swep)
        if not swep then return end

        if swep.PS_LoopSound then
            swep.PS_LoopSound:Stop()
            swep.PS_LoopSound = nil
        end

        swep.PS_ClientSpraying = nil
    end

    hook.Add("Think", "PepperSprayParticles", function()
        local now = CurTime()

        if now >= nextListRefresh then
            nextListRefresh = now + 0.25
            cachedList = ents.FindByClass("weapon_pepperspray_tpik")
        end

        local eyes = EyePos()
        local running = 0

        for i = 1, #cachedList do
            local swep = cachedList[i]

            if not IsValid(swep) then
                continue
            end

            if not IsSprayActive(swep) then
                if swep.PS_ClientSpraying then
                    StopClientSpray(swep)
                end

                continue
            end

            local owner = swep:GetOwner()

            swep.PS_ClientSpraying = true
            running = running + 1

            if not swep.PS_LoopSound then
                swep.PS_LoopSound = CreateSound(swep, "PepperSpray.Loop")
            end

            if not swep.PS_LoopSound:IsPlaying() then
                swep.PS_LoopSound:PlayEx(1, 100)
            end

            local ownerPos = owner:GetPos()

            if ownerPos:DistToSqr(eyes) > PARTICLE_MAX_DIST_SQR then
                continue
            end

            if not emitter then
                emitter = ParticleEmitter(ownerPos)
            else
                emitter:SetPos(ownerPos)
            end

            swep.NextParticle = swep.NextParticle or 0

            if swep.NextParticle >= now then
                continue
            end

            swep.NextParticle = now + 0.03

            local aimang = owner:EyeAngles()
            local dir = aimang:Forward()
            local muzzle = owner:GetShootPos() + dir * offX:GetFloat() + aimang:Right() * offY:GetFloat() + aimang:Up() * offZ:GetFloat()
            local p = emitter:Add("effects/splash2", muzzle)

            if p then
                p:SetVelocity(dir * math.Rand(400, 600) + VectorRand() * 30)
                p:SetDieTime(math.Rand(0.4, 0.6))
                p:SetStartAlpha(180)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(1, 2))
                p:SetEndSize(math.Rand(8, 12))
                p:SetRoll(math.Rand(0, 360))
                p:SetRollDelta(math.Rand(-5, 5))
                p:SetColor(255, 150, 0)
                p:SetAirResistance(150)
                p:SetGravity(Vector(0, 0, -100))
                p:SetLighting(false)
            end

            local trImpact = util.TraceLine({
                start = muzzle,
                endpos = muzzle + dir * sprayRange:GetFloat(),
                filter = owner
            })

            if trImpact.Hit then
                local pi = emitter:Add("effects/splash2", trImpact.HitPos + trImpact.HitNormal * 2)

                if pi then
                    pi:SetVelocity(trImpact.HitNormal * math.Rand(1, 3))
                    pi:SetDieTime(math.Rand(15, 25))
                    pi:SetStartAlpha(220)
                    pi:SetEndAlpha(0)
                    pi:SetStartSize(math.Rand(3, 5))
                    pi:SetEndSize(math.Rand(5, 7))
                    pi:SetRoll(math.Rand(0, 360))
                    pi:SetColor(255, 130, 0)
                    pi:SetGravity(Vector(0, 0, -5))
                end
            end
        end

        if running == 0 and emitter then
            emitter:Finish()
            emitter = nil
        end
    end)

    hook.Add("EntityRemoved", "PepperSprayCleanup", function(ent)
        if ent and ent.PS_LoopSound then
            ent.PS_LoopSound:Stop()
            ent.PS_LoopSound = nil
        end
    end)
end
