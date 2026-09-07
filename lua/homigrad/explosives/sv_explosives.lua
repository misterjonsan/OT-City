util.AddNetworkString("hg_booom")

hg = hg or {}

local hg = hg
local util = util
local ents = ents
local net = net
local timer = timer
local hook = hook
local math = math
local table = table
local player = player
local bit = bit
local IsValid = IsValid
local Vector = Vector
local VectorRand = VectorRand
local SafeRemoveEntity = SafeRemoveEntity
local EmitSound = EmitSound
local RecipientFilter = RecipientFilter
local CurTime = CurTime
local math_random = math.random
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local math_Clamp = math.Clamp
local table_remove = table.remove

local vector_up = vector_up or Vector(0, 0, 1)
local vector_origin = vector_origin or Vector(0, 0, 0)
local vecCone = Vector(5, 5, 0)

local MAX_ENTS_PER_EXPLOSION = 96
local MAX_TRACES_PER_EXPLOSION = 32
local MAX_FIREBALLS = 6
local PHYS_FORCE = 42000
local PLAYER_FORCE_MULT = 0.45

local SHRAPNEL_INTERVAL = 0.05
local SHRAPNEL_GLOBAL_BUDGET = 28
local SHRAPNEL_DISTANCE = 4000
local SHRAPNEL_MAX_JOBS = 12

local EXPLOSIONS_PER_TICK = 2
local MAX_QUEUED_EXPLOSIONS = 64

local NET_RADIUS_SQR = 7000 * 7000
local DEBRIS_RADIUS_SQR = 3000 * 3000

local TYPE_IDS = {
    Fire = 1,
    Sharpnel = 2,
    Normal = 3
}

local scaleCache = 1
local scaleNext = 0

local function LoadScale()
    local t = CurTime()

    if t < scaleNext then return scaleCache end

    scaleNext = t + 1

    local n = player.GetCount()

    if n <= 16 then
        scaleCache = 1
    elseif n <= 32 then
        scaleCache = 0.7
    elseif n <= 48 then
        scaleCache = 0.5
    else
        scaleCache = 0.35
    end

    return scaleCache
end

function hg.FindOtherExplosive(inflictor, pos, radius)
end

function hg.MakeCombinedExplosion()
end

local DebrisSounds = {
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave01.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave010.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave02.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave03.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave04.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave05.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave06.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave07.wav",
    "explosion_debris/interior/explosion_debris_sprinkle_interior_wave09.wav"
}

local DebrisCount = #DebrisSounds

local function NearbyFilter(pos, radiusSqr)
    local rf = RecipientFilter()
    local plys = player.GetAll()
    local added = 0

    for i = 1, #plys do
        local ply = plys[i]

        if ply:GetPos():DistToSqr(pos) <= radiusSqr then
            rf:AddPlayer(ply)
            added = added + 1
        end
    end

    if added == 0 then return nil end

    return rf
end

local function EmitBoom(pos, typ)
    local id = TYPE_IDS[typ] or 3
    local rf = NearbyFilter(pos, NET_RADIUS_SQR)

    if not rf then return end

    net.Start("hg_booom", true)
    net.WriteVector(pos)
    net.WriteUInt(id, 3)
    net.Send(rf)
end

local function DebrisSound(ent, count)
    if count <= 10 or not IsValid(ent) then return end

    local pos = ent:GetPos()
    local rf = NearbyFilter(pos, DEBRIS_RADIUS_SQR)

    if not rf then return end

    EmitSound(DebrisSounds[math_random(DebrisCount)], pos, ent:EntIndex(), CHAN_AUTO, 1, 80, 0, 100, 0, rf)
end

local function GetOwner(ent)
    local owner = ent.owner

    if IsValid(owner) then return owner end

    return ent
end

local function ExplosionPos(ent)
    return ent:LocalToWorld(ent:OBBCenter())
end

local function FreezeExplosionProp(ent)
    if not IsValid(ent) then return end
    if ent.hgFrozen then return end

    ent.hgFrozen = true

    local phys = ent:GetPhysicsObject()

    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:SetVelocity(vector_origin)
        phys:SetAngleVelocity(vector_origin)
        phys:Sleep()
    end
end

local traceFilter = {}

local function PushAndDisorient(ent, ownerEnt, selfPos, dis, allowBehindWall)
    local list = ents.FindInSphere(selfPos, dis)
    local total = #list

    if total > MAX_ENTS_PER_EXPLOSION then
        total = MAX_ENTS_PER_EXPLOSION
    end

    local scale = LoadScale()
    local maxTraces = math_max(8, math_floor(MAX_TRACES_PER_EXPLOSION * scale))
    local entsCount = 0
    local traceCount = 0
    local invDis = 1 / dis

    traceFilter[1] = ownerEnt

    for i = 1, total do
        local enta = list[i]

        if enta ~= ownerEnt and IsValid(enta) then
            local pos = enta:GetPos()
            local force = pos - selfPos
            local len = force:Length()

            if len > 1 then
                force:Div(len)

                local isPlayer = enta:IsPlayer()
                local organism = enta.organism

                if not isPlayer then
                    local phys = enta:GetPhysicsObject()

                    if IsValid(phys) then
                        entsCount = entsCount + 1
                    end
                else
                    entsCount = entsCount + 1
                end

                if isPlayer or organism then
                    local frac = math_Clamp((dis - len) * invDis, 0.35, 1)
                    local forceadd = force * frac * PHYS_FORCE
                    local blocked = false

                    if traceCount < maxTraces then
                        traceCount = traceCount + 1

                        local tracePos = isPlayer and (pos + enta:OBBCenter()) or pos
                        local tr = hg.ExplosionTrace(selfPos, tracePos, traceFilter)

                        blocked = tr.Entity ~= enta and tr.MatType ~= MAT_GLASS
                    end

                    if organism then
                        local orgOwner = organism.owner

                        if IsValid(orgOwner) and orgOwner:IsPlayer() and (allowBehindWall or not blocked) then
                            local div = blocked and 3 or 1

                            hg.ExplosionDisorientation(enta, 5 * frac / div, 6 * frac / div)
                            hg.RunZManipAnim(orgOwner, "shieldexplosion")
                        end
                    end

                    if isPlayer and not blocked then
                        local applied = forceadd * PLAYER_FORCE_MULT

                        hg.AddForceRag(enta, 0, applied, 0.5)
                        hg.AddForceRag(enta, 1, applied, 0.5)
                        hg.LightStunPlayer(enta)
                    end
                end
            end
        end
    end

    traceFilter[1] = nil

    return entsCount
end

local shrapnelJobs = {}
local shrapnelJobCount = 0
local shrapnelRunning = false

local function ShrapnelTick()
    if shrapnelJobCount == 0 then
        shrapnelRunning = false
        timer.Remove("hg_shrapnel_tick")

        return
    end

    local budget = math_max(6, math_floor(SHRAPNEL_GLOBAL_BUDGET * LoadScale()))
    local perJob = math_max(1, math_floor(budget / shrapnelJobCount))

    for i = shrapnelJobCount, 1, -1 do
        local job = shrapnelJobs[i]
        local ent = job.ent

        if not IsValid(ent) then
            table_remove(shrapnelJobs, i)
            shrapnelJobCount = shrapnelJobCount - 1
        else
            local left = job.total - job.done
            local num = perJob

            if num > left then
                num = left
            end

            if num > 0 then
                local bullet = job.bullet

                job.done = job.done + num

                bullet.Num = num
                bullet.Dir = ent:GetAngles():Forward() * math_random(-1, 1)
                bullet.Spread = vecCone * math_Clamp(job.done / job.massDiv, 0.1, 2)

                ent:FireLuaBullets(bullet, true)
            end

            if job.done >= job.total then
                SafeRemoveEntity(ent)
                table_remove(shrapnelJobs, i)
                shrapnelJobCount = shrapnelJobCount - 1
            end
        end
    end
end

local function QueueShrapnel(ent, owner, selfPos, force, mass, countMult)
    if not IsValid(ent) then return end

    if shrapnelJobCount >= SHRAPNEL_MAX_JOBS then
        SafeRemoveEntity(ent)

        return
    end

    local filter = {ent}
    local drums = hg.drums2

    if drums then
        local n = 1

        for i = 1, #drums do
            n = n + 1
            filter[n] = drums[i]
        end
    end

    local scale = LoadScale()
    local multi = math_min((mass or 25) / 5, 16)
    local total = math_max(1, math_floor(multi * countMult * scale))

    shrapnelJobCount = shrapnelJobCount + 1
    shrapnelJobs[shrapnelJobCount] = {
        ent = ent,
        done = 0,
        total = total,
        massDiv = math_max(mass or 1, 1),
        bullet = {
            Src = selfPos,
            Spread = vecCone,
            Force = 0.01,
            Damage = force,
            Num = 1,
            AmmoType = "Metal Debris",
            Attacker = owner,
            Distance = SHRAPNEL_DISTANCE,
            DisableLagComp = true,
            Filter = filter
        }
    }

    if not shrapnelRunning then
        shrapnelRunning = true
        timer.Create("hg_shrapnel_tick", SHRAPNEL_INTERVAL, 0, ShrapnelTick)
    end
end

local function BaseExplosion(ent, expType, force, mass, withFire, withShrapnel, shrapnelMult, allowBehindWall)
    if not IsValid(ent) then return end

    mass = mass or 25

    FreezeExplosionProp(ent)

    local selfPos = ExplosionPos(ent)
    local owner = GetOwner(ent)
    local rad = force / 8
    local dis = rad / 0.019
    local blastRadius = (force / 7.5) / 0.01905

    if expType == "Fire" then
        local multi = math_min(mass / 10, 20)

        force = force * multi
        rad = force / 8
        dis = rad / 0.019
        blastRadius = rad / 0.01905

        util.BlastDamage(ent, owner, selfPos, blastRadius, force * 2)
        hgBlastDoors(ent, selfPos, force / 50, force / 15)
    else
        util.BlastDamage(ent, owner, selfPos, blastRadius, force)
        hgBlastDoors(ent, selfPos, force / 50)
    end

    hg.ExplosionEffect(selfPos, force / 0.2, 80)

    EmitBoom(selfPos, expType)

    if withFire and IsValid(ent) then
        local multi = math_min(mass / 5, 16)
        local tr = util.QuickTrace(selfPos, -vector_up * 500, {ent})
        local fire = CreateVFire(game.GetWorld(), tr.HitPos, tr.HitNormal, 150 / 7 * multi, ent)

        if IsValid(fire) then
            fire:ChangeLife(120)
        end

        local balls = math_min(math_floor(multi / 2), MAX_FIREBALLS)

        balls = math_floor(balls * LoadScale())

        for i = 1, balls do
            local randvec = VectorRand(-1000, 1000)

            randvec[3] = math_random(100, 1000)

            CreateVFireBall(20, 50, selfPos + vector_up * 10, randvec)
        end
    end

    local entsCount = PushAndDisorient(ent, ent, selfPos, dis, allowBehindWall)

    DebrisSound(ent, entsCount)

    util.ScreenShake(selfPos, 32, 120, 0.8, math_min(dis, 2200))

    if withShrapnel then
        QueueShrapnel(ent, owner, selfPos, force, mass, shrapnelMult)
    else
        SafeRemoveEntity(ent)
    end
end

local ExpTypes = {
    Fire = function(ent, force, mass)
        BaseExplosion(ent, "Fire", force, mass, true, true, 3, true)
    end,

    Sharpnel = function(ent, force, mass)
        BaseExplosion(ent, "Sharpnel", force, mass, false, true, 4, false)
    end,

    Normal = function(ent, force, mass)
        BaseExplosion(ent, "Normal", force, mass, false, false, 0, false)
    end
}

hg.ExpTypes = ExpTypes

local expQueue = {}
local expQueueHead = 1
local expQueueTail = 0
local expQueueRunning = false

local function RunExplosion(job)
    local ent = job[1]

    if not IsValid(ent) then return end

    local fn = ExpTypes[job[2]] or ExpTypes.Normal

    fn(ent, job[3], job[4])
end

local function ProcessExplosionQueue()
    local budget = EXPLOSIONS_PER_TICK

    while budget > 0 and expQueueHead <= expQueueTail do
        local job = expQueue[expQueueHead]

        expQueue[expQueueHead] = nil
        expQueueHead = expQueueHead + 1
        budget = budget - 1

        RunExplosion(job)
    end

    if expQueueHead > expQueueTail then
        expQueueHead = 1
        expQueueTail = 0
        expQueueRunning = false

        hook.Remove("Tick", "hg_explosion_queue")
    end
end

function hg.PropExplosion(ent, expType, force, mass)
    if not IsValid(ent) then return end
    if ent.HasExploded then return end

    ent.HasExploded = true

    FreezeExplosionProp(ent)

    if expQueueTail - expQueueHead + 1 >= MAX_QUEUED_EXPLOSIONS then
        SafeRemoveEntity(ent)

        return
    end

    expQueueTail = expQueueTail + 1
    expQueue[expQueueTail] = {ent, expType, force or 30, mass or 25}

    if not expQueueRunning then
        expQueueRunning = true

        hook.Add("Tick", "hg_explosion_queue", ProcessExplosionQueue)
    end
end

local expItems = {
    ["models/props_c17/oildrum001_explosive.mdl"] = {ExpType = "Fire", Force = 75},
    ["models/props_junk/gascan001a.mdl"] = {ExpType = "Fire", Force = 40},
    ["models/props_junk/propane_tank001a.mdl"] = {ExpType = "Sharpnel", Force = 30},
    ["models/props_junk/metalgascan.mdl"] = {ExpType = "Fire", Force = 40},
    ["models/props_junk/PropaneCanister001a.mdl"] = {ExpType = "Sharpnel", Force = 40},
    ["models/props_c17/canister01a.mdl"] = {ExpType = "Sharpnel", Force = 45},
    ["models/props_c17/canister02a.mdl"] = {ExpType = "Sharpnel", Force = 45},
    ["models/props_c17/canister_propane01a.mdl"] = {ExpType = "Fire", Force = 50}
}

hg.expItems = expItems

local validExplosiveDamage = bit.bor(DMG_BLAST_SURFACE, DMG_BLAST, DMG_BURN)
local validCoopDamage = bit.bor(DMG_BLAST_SURFACE, DMG_BLAST, DMG_BURN, DMG_BULLET, DMG_BUCKSHOT, DMG_AIRBOAT)

hook.Add("EntityTakeDamage", "ExplosiveDamage", function(target, dmginfo)
    if not IsValid(target) then return end

    local tbl = target.hgExpData

    if tbl == nil then
        tbl = expItems[target:GetModel()] or false
        target.hgExpData = tbl
    end

    if not tbl then return end

    if target.babahnut then
        dmginfo:ScaleDamage(0)

        return true
    end

    hook.Run("ExplosivesTakeDamage", target, dmginfo)

    local rnd = CurrentRound and CurrentRound()
    local isCoop = rnd and rnd.name == "coop"
    local canDamage = isCoop and dmginfo:IsDamageType(validCoopDamage) or dmginfo:IsDamageType(validExplosiveDamage)

    if canDamage then
        local hp = target.hp or 50
        local damage = dmginfo:GetDamage()

        if dmginfo:IsDamageType(DMG_BURN) then
            damage = damage / 12.5
        else
            damage = damage * 2
        end

        hp = hp - damage
        target.hp = hp

        if hp <= 0 and (not target.Volume or target.Volume > 0) then
            target.babahnut = true

            local phys = target:GetPhysicsObject()
            local mass = IsValid(phys) and phys:GetMass() or 25
            local finalForce = (target.Volume or tbl.Force) * 2

            FreezeExplosionProp(target)
            hg.PropExplosion(target, tbl.ExpType, finalForce, mass)
        end
    end

    dmginfo:ScaleDamage(0)

    return true
end)
