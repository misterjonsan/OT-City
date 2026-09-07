local PLAYER = FindMetaTable("Player")

local vpang = Angle(2, 0, 0)

local EXOJUMP_KICK_PLAYER_VEL_MUL = 1.6
local EXOJUMP_KICK_RAG_FORCE_MUL = 1.55
local EXOJUMP_KICK_PHYS_FORCE_MUL = 1.55
local EXOJUMP_KICK_DOOR_BLAST_MUL = 2.25

EXOJUMP_MAX_CHARGES = 5

local EXO_EMPTY_SPEED_MUL = 2.6
local EXO_EMPTY_DMG_MUL = 0.5
local EXO_EMPTY_STAMINA_MUL = 1.6
local EXO_SPEND_COOLDOWN = 0.15
local EXO_ABSORB_COOLDOWN = 0.25
local EXO_KICK_FALL_WINDOW = 0.4
local EXO_FORCEUP_COOLDOWN = 0.6
local EXO_FORCEUP_MAX_TRIES = 2

local function ExoSafeChar(ply)
    if not IsValid(ply) then return nil end
    if not hg or not isfunction(hg.GetCurrentCharacter) then return nil end

    local ok, char = pcall(hg.GetCurrentCharacter, ply)
    if not ok or not IsValid(char) then return nil end

    return char
end

local function ExoIsRagdolled(ply)
    local char = ExoSafeChar(ply)
    if not char or not isfunction(char.IsRagdoll) then return false end

    local ok, ragdolled = pcall(char.IsRagdoll, char)

    return ok and ragdolled == true
end

local function HasEquippedAccessory(ply, uid)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not isfunction(ply.GetNetVar) then return false end

    uid = tostring(uid or "")
    if uid == "" then return false end

    local ok, attachments = pcall(ply.GetNetVar, ply, "Accessories", {})
    if not ok or not istable(attachments) then return false end

    for _, accUID in pairs(attachments) do
        if tostring(accUID or "") == uid then
            return true
        end
    end

    return false
end

function PLAYER:ExoHasBoots()
    return HasEquippedAccessory(self, "exojump")
end

local function ExoSync(ply)
    if not IsValid(ply) then return end

    local value = math.Clamp(math.floor(tonumber(ply.ExoChargesValue) or EXOJUMP_MAX_CHARGES), 0, EXOJUMP_MAX_CHARGES)

    ply.ExoChargesValue = value

    if ply:GetNWInt("ExoCharges", -1) ~= value then
        ply:SetNWInt("ExoCharges", value)
    end

    if ply:GetNWInt("ExoMaxCharges", -1) ~= EXOJUMP_MAX_CHARGES then
        ply:SetNWInt("ExoMaxCharges", EXOJUMP_MAX_CHARGES)
    end
end

function PLAYER:ExoGetCharges()
    if self.ExoChargesValue == nil then
        self.ExoChargesValue = EXOJUMP_MAX_CHARGES
        ExoSync(self)
    end

    return math.Clamp(math.floor(tonumber(self.ExoChargesValue) or 0), 0, EXOJUMP_MAX_CHARGES)
end

function PLAYER:ExoSetCharges(amount)
    self.ExoChargesValue = math.Clamp(math.floor(tonumber(amount) or 0), 0, EXOJUMP_MAX_CHARGES)

    ExoSync(self)

    return self.ExoChargesValue
end

function PLAYER:ExoIsCharged()
    if not self:Alive() then return false end
    if not self:ExoHasBoots() then return false end

    return self:ExoGetCharges() > 0
end

function PLAYER:ExoTakeCharge(amount, reason)
    if not IsValid(self) or not self:IsPlayer() then return false end
    if not self:ExoHasBoots() then return false end

    local now = CurTime()

    if (self.ExoLastSpend or -1) + EXO_SPEND_COOLDOWN > now then return false end

    local cur = self:ExoGetCharges()
    if cur <= 0 then return false end

    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local new = math.max(0, cur - amount)

    self.ExoLastSpend = now
    self:ExoSetCharges(new)

    if new <= 0 then
        self:EmitSound("buttons/combine_button_locked.wav", 65, 105)
    else
        self:EmitSound("buttons/button24.wav", 60, 110)
    end

    hook.Run("ExoJumpChargeSpent", self, new, reason or "kick")

    return true
end

local function ExoProtected(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return false end
    if not isfunction(ent.ExoIsCharged) then return false end

    return ent:ExoIsCharged()
end

local function ExoMarkKickFall(victim, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    victim.ExoKickFallUntil = CurTime() + EXO_KICK_FALL_WINDOW
    victim.ExoKickFallBy = IsValid(attacker) and attacker or nil
end

local function ExoWasKickedDown(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    return (ply.ExoKickFallUntil or 0) > CurTime()
end

local function ExoClearKickFall(ply)
    if not IsValid(ply) then return end

    ply.ExoKickFallUntil = nil
    ply.ExoKickFallBy = nil
end

local function ExoForceUp(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not ply:Alive() then return false end
    if ply.InVehicle and ply:InVehicle() then return false end
    if not hg or not isfunction(hg.FakeUp) then return false end
    if not IsValid(ply.FakeRagdoll) then return false end

    local now = CurTime()

    if (ply.ExoLastForceUp or -1) + EXO_FORCEUP_COOLDOWN > now then return false end

    local rag = ply.FakeRagdoll
    local phys = rag.GetPhysicsObject and rag:GetPhysicsObject() or nil

    if IsValid(phys) and phys:GetVelocity():Length() > 250 then return false end

    ply.ExoLastForceUp = now
    ply.fakecd = 0

    local ok = pcall(hg.FakeUp, ply, true, true)

    ply.fakecd = 0

    return ok
end

function PLAYER:ExoAbsorbHit(attacker, reason)
    if not ExoProtected(self) then return false end

    local now = CurTime()

    if (self.ExoLastAbsorb or -1) + EXO_ABSORB_COOLDOWN > now then return true end

    self.ExoLastAbsorb = now

    self:ExoTakeCharge(1, reason or "absorb")
    self:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 8) .. ".wav", 70, math.random(95, 105))

    return true
end

local function ExoRefill(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply.ExoLastSpend = nil
    ply.ExoLastAbsorb = nil
    ply.ExoPendingRefill = nil
    ply:ExoSetCharges(EXOJUMP_MAX_CHARGES)
    ply:SetNWBool("ExoBoots", ply:ExoHasBoots())
end

function PLAYER:ExoRefillCharges()
    ExoRefill(self)

    return self:ExoGetCharges()
end

local function ExoSpawnRefill(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if ply.ExoChargesValue == nil then
        ExoRefill(ply)

        return true
    end

    if not ply.ExoPendingRefill then return false end
    if not ply:Alive() then return false end

    ExoRefill(ply)

    return true
end

local function ExoMarkRespawn(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply.ExoPendingRefill = true
end

local function ExoQueueSpawnRefill(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ExoSpawnRefill(ply)

    for _, delay in ipairs({ 0, 0.1, 0.5, 1 }) do
        timer.Simple(delay, function()
            ExoSpawnRefill(ply)
        end)
    end
end

hook.Add("PlayerDeath", "ExoJump_MarkRespawn", ExoMarkRespawn)
hook.Add("DoPlayerDeath", "ExoJump_MarkRespawn", ExoMarkRespawn)
hook.Add("PlayerSilentDeath", "ExoJump_MarkRespawn", ExoMarkRespawn)

hook.Add("PlayerDisconnected", "ExoJump_ClearState", function(ply)
    if not IsValid(ply) then return end

    ply.ExoChargesValue = nil
    ply.ExoPendingRefill = nil
    ply.ExoWasAlive = nil
end)

hook.Add("PlayerSpawn", "ExoJump_RefillCharges", function(ply)
    ExoMarkRespawn(ply)
    ExoQueueSpawnRefill(ply)
end)

hook.Add("PlayerInitialSpawn", "ExoJump_RefillCharges", function(ply)
    ExoMarkRespawn(ply)
    ExoQueueSpawnRefill(ply)
end)

timer.Create("ExoJump_ChargeSync", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end

        local has = HasEquippedAccessory(ply, "exojump")

        if ply:GetNWBool("ExoBoots", false) ~= has then
            ply:SetNWBool("ExoBoots", has)
        end

        local alive = ply:Alive()

        if ply.ExoWasAlive == nil then
            ply.ExoWasAlive = alive
        elseif alive and not ply.ExoWasAlive then
            ply.ExoPendingRefill = true
        end

        ply.ExoWasAlive = alive

        if alive and ply.ExoPendingRefill then
            ExoSpawnRefill(ply)
        end

        ExoSync(ply)
    end
end)

hook.Add("Fake", "ExoJump_NoFall", function(ply, ragdoll)
    if not ExoProtected(ply) then return end
    if not ExoWasKickedDown(ply) then return end
    if ply.ExoNoFallBusy then return end

    ply.ExoNoFallBusy = true

    local attacker = ply.ExoKickFallBy

    ExoClearKickFall(ply)
    ply:ExoAbsorbHit(attacker, "kicked")

    local tries = 0

    local function attempt()
        if not IsValid(ply) then return end

        tries = tries + 1

        if not IsValid(ply.FakeRagdoll) or ExoForceUp(ply) or tries >= EXO_FORCEUP_MAX_TRIES then
            ply.ExoNoFallBusy = nil

            return
        end

        timer.Simple(0.35, attempt)
    end

    timer.Simple(0, attempt)
end)

hook.Add("ZC_SomeoneGetFallBy", "ExoJump_NoFall", function(attacker, victim)
    if not ExoProtected(victim) then return end
    if not IsValid(attacker) or attacker == victim then return end

    ExoMarkKickFall(victim, attacker)
    victim:ExoAbsorbHit(attacker, "kicked")
end)

function PLAYER:LegAttack()
    if not self:Alive() or ExoIsRagdolled(self) or self:GetNWFloat("InLegKick", 0) > CurTime() or not self:IsOnGround() or self:IsSprinting() then return end
    if self.InLegKick and self.InLegKick > CurTime() then return end
    if self:GetNWBool("TauntStopMoving", false) then return end
    if not self.organism then return end
    if hook.Run("PlayerCanLegAttack", self) == false then return end

    local attackerHasExojump = self:ExoHasBoots()
    local attackerCharged = attackerHasExojump and self:ExoGetCharges() > 0
    local attackerDrained = attackerHasExojump and not attackerCharged

    local anim = "kick_pistol_base"
    anim = (self:KeyDown(IN_DUCK) or self:Crouching()) and "kick_pistol_base_crouch" or self:EyeAngles()[1] > 60 and "curbstomp_base" or self:EyeAngles()[1] > 35 and "kick_pistol_25_base" or self:EyeAngles()[1] > 20 and "kick_pistol_45_base" or anim

    if attackerCharged then
        self:EmitSound("milky/exo.mp3", 75)
    else
        self:EmitSound("player/clothes_generic_foley_0" .. math.random(1, 5) .. ".wav", 65)
    end

    local org = self.organism
    org.stamina.subadd = org.stamina.subadd + (anim == "curbstomp_base" and 12 or 20) * (attackerDrained and EXO_EMPTY_STAMINA_MUL or 1)

    local speedmul = 2 - (org.stamina[1] / org.stamina.max)
    local speed = 1.5 * speedmul
    local animstopAdjust = 0.3 * speedmul
    local dmg = anim == "curbstomp_base" and 22 or 10 * (2 - speedmul)

    dmg = dmg * (self:IsBerserk() and org.berserk * 5 or 1)
    dmg = dmg * (org.legstrength or 1)

    if attackerDrained then
        speed = speed * EXO_EMPTY_SPEED_MUL
        animstopAdjust = animstopAdjust * EXO_EMPTY_SPEED_MUL
        dmg = dmg * EXO_EMPTY_DMG_MUL
    end

    self:PlayCustomAnims(anim, true, speed, true, animstopAdjust, {
        [0.12] = function(self)
            if ExoIsRagdolled(self) then return end
            if not self:IsOnGround() then self:PlayCustomAnims("") return end

            local ang = self:EyeAngles()
            ang[1] = 0

            local reportPos = self:GetPos() + self:OBBCenter()
            local tr = util.TraceLine({
                start = reportPos,
                endpos = reportPos + ang:Forward() * 32,
                filter = {ExoSafeChar(self), self}
            })

            if tr.Hit and self:IsOnGround() then
                self:SetVelocity(ang:Forward() * -300)
            end
        end,
        [0.21] = function(self)
            if ExoIsRagdolled(self) then return end
            if not self:IsOnGround() then self:PlayCustomAnims("") return end

            local ang = self:EyeAngles()

            if ang[1] > 55 and not (self:KeyDown(IN_DUCK) or self:Crouching()) then
                self:ViewPunch(vpang)
                return
            else
                self:ViewPunch(-vpang)
            end

            ang[1] = 0

            local reportPos = self:GetPos() + self:OBBCenter()
            local tr = util.TraceLine({
                start = reportPos,
                endpos = reportPos + ang:Forward() * 72,
                filter = {ExoSafeChar(self), self}
            })

            if tr.Hit and self:IsOnGround() then
                self:SetVelocity(ang:Forward() * -150)
            end
        end,
        [0.33] = function(self)
            if ExoIsRagdolled(self) then return end
            if not self:IsOnGround() then self:PlayCustomAnims("") return end
            if not self.organism then return end

            local ang = self:EyeAngles()
            ang[1] = 0

            self:EmitSound("player/shove_0" .. math.random(1, 5) .. ".wav", 65)

            local inDuck = self:KeyDown(IN_DUCK) or self:Crouching()

            ang = self:EyeAngles()
            ang[1] = inDuck and 0 or math.max(ang[1], 10)

            local reportPos = self:GetPos() + self:OBBCenter() + self:GetUp() * -5
            local rad = Vector(5, 5, 5)

            local tr = util.TraceHull({
                start = inDuck and reportPos or self:EyePos(),
                endpos = (inDuck and reportPos or self:EyePos()) + ang:Forward() * 82,
                filter = {ExoSafeChar(self), self},
                maxs = rad,
                mins = -rad
            })

            local org = self.organism

            local attackerHasExojump = self:ExoHasBoots()
            local attackerCharged = attackerHasExojump and self:ExoGetCharges() > 0
            local chargeSpent = false
            local kickDmg = dmg
            local playerKickVel = 150
            local ragForceMul = 1
            local physForceMul = 1

            if attackerCharged then
                kickDmg = kickDmg * 1.3
                playerKickVel = playerKickVel * EXOJUMP_KICK_PLAYER_VEL_MUL
                ragForceMul = EXOJUMP_KICK_RAG_FORCE_MUL
                physForceMul = EXOJUMP_KICK_PHYS_FORCE_MUL
            elseif attackerHasExojump then
                playerKickVel = playerKickVel * 0.5
            end

            local function SpendCharge()
                if chargeSpent or not attackerCharged then return end

                chargeSpent = true
                self:ExoTakeCharge(1, "kick")
            end

            if org.rleg == 1 or org.rlegdislocation then
                org.painadd = org.painadd + 20
            end

            local entss = {}

            if IsValid(tr.Entity) then
                entss[#entss + 1] = tr.Entity
            end

            local soundplayed = false
            local blacklist = {
                [self] = true
            }

            local selfChar = ExoSafeChar(self)

            if selfChar then
                blacklist[selfChar] = true
            end

            if tr.Hit then
                soundplayed = true

                if org.rleg == 1 or org.rlegdislocation then
                    org.painadd = org.painadd + 20
                end

                self:EmitSound("weapons/melee/blunt_light" .. math.random(1, 8) .. ".wav")
            end

            if IsValid(tr.Entity) and istable(tr.Entity.fires) then
                local key = next(tr.Entity.fires)

                if key then
                    tr.Entity.fires[key] = nil

                    if IsValid(key) then
                        key:Remove()
                    end
                end
            end

            for _, ent in ipairs(entss) do
                if IsValid(ent) and not blacklist[ent] then
                    local normal = ang:Forward()
                    local phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
                    local targetProtected = ExoProtected(ent)

                    if not ent:IsPlayer() and not IsValid(phys) then continue end

                    if not soundplayed then
                        soundplayed = true

                        if org.rleg == 1 or org.rlegdislocation then
                            org.painadd = org.painadd + 20
                        end

                        self:EmitSound("weapons/melee/blunt_light" .. math.random(1, 8) .. ".wav")
                    end

                    local dmginfo = DamageInfo()

                    dmginfo:SetAttacker(self)
                    dmginfo:SetInflictor(self)
                    dmginfo:SetDamage(targetProtected and 0 or kickDmg)
                    dmginfo:SetDamageForce(targetProtected and vector_origin or normal * kickDmg)
                    dmginfo:SetDamageType(targetProtected and DMG_GENERIC or ((ent:GetClass() == "func_breakable_surf") and DMG_SLASH or DMG_CLUB))
                    dmginfo:SetDamagePosition(tr.HitPos)

                    PenetrationGlobal = 1
                    MaxPenLenGlobal = 1

                    if not targetProtected then
                        if hg and isfunction(hg.AddForceRag) then
                            hg.AddForceRag(ent, tr.PhysicsBone or 0, normal * kickDmg * 1000 * ragForceMul, 0.25)
                        end

                        ent:TakeDamageInfo(dmginfo)

                        if IsValid(phys) then
                            phys:ApplyForceOffset(normal * kickDmg * 200 * physForceMul, tr.HitPos)
                        end
                    end

                    if ent:IsPlayer() or ent:GetClass() == "prop_ragdoll" then
                        ent:EmitSound("physics/body/body_medium_impact_hard" .. math.random(6) .. ".wav", 60, math.random(85, 105), 0.6)
                    end

                    if ent:IsPlayer() then
                        SpendCharge()

                        if targetProtected then
                            ExoMarkKickFall(ent, self)
                            ent:ExoAbsorbHit(self, "kicked")
                        else
                            if math.random(1, 5) > 1 then
                                local victim = ent

                                timer.Simple(0, function()
                                    if not IsValid(victim) or not victim:IsPlayer() then return end
                                    if not victim:Alive() then return end
                                    if ExoProtected(victim) then return end
                                    if not hg or not isfunction(hg.Fake) then return end

                                    pcall(hg.Fake, victim)
                                end)
                            end

                            ent:SetVelocity(normal * playerKickVel)
                        end
                    end

                    if isfunction(hgIsDoor) and hgIsDoor(ent) and not ent:GetNoDraw() then
                        ent.HP = ent.HP or 200
                        ent:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(1, 4) .. ".wav")

                        SpendCharge()

                        if attackerCharged then
                            ent.HP = 0
                            ent:EmitSound("physics/wood/wood_box_impact_hard3.wav")

                            if isfunction(hgBlastThatDoor) then
                                hgBlastThatDoor(ent, normal * 125 * EXOJUMP_KICK_DOOR_BLAST_MUL)
                            end
                        else
                            ent.HP = ent.HP - kickDmg * (tr.MatType == MAT_METAL and 1 or 2)

                            if isfunction(DoorIsOpen) and DoorIsOpen(ent) then
                                local oldname = self:GetName()

                                if isfunction(DoorIsOpen2) and not DoorIsOpen2(ent) then
                                    ent:FastOpenDoor(self, 5, true)
                                    self:SetName(oldname .. self:EntIndex())

                                    if ent:GetClass() == "func_door_rotating" then
                                        ent:Fire("open", self:GetName(), 0, self, self)
                                    elseif ent:GetClass() == "prop_door_rotating" then
                                        ent:Fire("openawayfrom", self:GetName(), 0, self, self)
                                    end

                                    self:SetName(oldname)
                                else
                                    ent:FastOpenDoor(self, 2, true)
                                    ent:Fire("Close", oldname, 0, self, self)
                                end

                                ent:EmitSound("physics/wood/wood_box_impact_hard3.wav")
                            end

                            if ent.HP <= 0 and isfunction(hgBlastThatDoor) then
                                hgBlastThatDoor(ent, normal * 125)
                            end
                        end
                    end
                end
            end
        end
    })

    self.InLegKick = CurTime() + speed - animstopAdjust
    self:SetNWFloat("InLegKick", CurTime() + speed - animstopAdjust)
end

hook.Add("HG_MovementCalc_2", "HG-LegKickAnim", function(mul, ply, cmd, mv)
    if ply:GetNWFloat("InLegKick", 0) > CurTime() then
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)
        cmd:RemoveKey(IN_JUMP)

        mv:RemoveKey(IN_MOVELEFT)
        mv:RemoveKey(IN_MOVERIGHT)
        mv:RemoveKey(IN_JUMP)

        mul[1] = math.min(math.max(0.001, 1 - (ply:GetNWFloat("InLegKick", 0) - CurTime()) * 2), 1)

        if cmd:KeyDown(IN_DUCK) or ply:Crouching() then
            cmd:AddKey(IN_DUCK)
            mv:AddKey(IN_DUCK)
        else
            cmd:RemoveKey(IN_DUCK)
            mv:RemoveKey(IN_DUCK)
        end
    end
end)

concommand.Add("hg_kick", function(ply)
    if not IsValid(ply) then return end

    ply:LegAttack()
end)

concommand.Add("hg_exo_setcharges", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = IsValid(ply) and ply or nil

    if #args > 1 then
        target = player.GetListByName(args[1])[1]
    end

    if not IsValid(target) or not target:IsPlayer() then return end

    target:ExoSetCharges(tonumber(args[#args]) or EXOJUMP_MAX_CHARGES)
end)
