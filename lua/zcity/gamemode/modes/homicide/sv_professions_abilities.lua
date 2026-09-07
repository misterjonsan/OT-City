timer.Simple(.1, function()
MODE = MODE or {}
local MODE = MODE

MODE.HuntsmanStepInterval = 0.22
MODE.HuntsmanStepMoveDistSqr = 26 * 26
MODE.HuntsmanSendDistanceSqr = 2500 * 2500
MODE.HuntsmanScanInterval = 0.25
MODE.HuntsmanFallbackInterval = 0.1
MODE.BuilderDoorHP = MODE.BuilderDoorHP or 400
MODE.BuilderBoardCooldown = MODE.BuilderBoardCooldown or 3
MODE.BuilderReachDistance = MODE.BuilderReachDistance or 140
MODE.CookBuffRadius = MODE.CookBuffRadius or 300
MODE.CookBuffAmount = MODE.CookBuffAmount or 12
MODE.CookBuffCooldown = MODE.CookBuffCooldown or 8

util.AddNetworkString("HMCD_Professions_Abilities_AddFootstep")
util.AddNetworkString("HMCD_Professions_Abilities_DisplayOrganismInfo")
util.AddNetworkString("HMCD_Professions_AbilityUse")
util.AddNetworkString("HMCD_Professions_AbilityKey")

local function Prof(ply)
    if not IsValid(ply) then return "" end
    local prof = ply.Profession
    if not isstring(prof) or prof == "" then
        prof = ply.GetNWString and ply:GetNWString("HMCD_CurrentProfession", "") or ""
    end
    if not isstring(prof) then return "" end
    return string.lower(string.Trim(prof))
end
MODE.GetProfession = Prof

local huntsmen = {}
local nextHuntsmanScan = 0

local function HuntsmanRecipients()
    local now = CurTime()
    if now >= nextHuntsmanScan then
        nextHuntsmanScan = now + MODE.HuntsmanScanInterval
        local list = {}
        for _, recipient in player.Iterator() do
            if IsValid(recipient) and recipient:Alive() and Prof(recipient) == "huntsman" then
                list[#list + 1] = recipient
            end
        end
        huntsmen = list
    end
    return huntsmen
end
MODE.HuntsmanRecipients = HuntsmanRecipients

local function Notify(ply, msg, col)
    if not IsValid(ply) then return end
    if (ply.HMCDNextProfessionNotify or 0) > CurTime() then return end
    ply.HMCDNextProfessionNotify = CurTime() + 0.8
    if isfunction(ply.Notify) then
        ply:Notify(msg, 4, "prof_ability", 1, nil, col or Color(120, 230, 150))
    else
        ply:ChatPrint(msg)
    end
end

local ORG_NUMERIC = {
    "blood", "pulse", "consciousness", "pain", "bleed", "internalBleed",
    "temperature", "pneumothorax", "analgesia", "brain", "wantToVomit",
    "adrenaline", "shock", "disorientation", "assimilated", "berserk", "heartbeat",
    "skull", "jaw", "chest", "spine1", "spine2", "spine3", "pelvis",
    "rarm", "larm", "rleg", "lleg",
    "heart", "liver", "stomach", "intestines",
}

local ORG_FLAGS = {
    "llegamputated", "rlegamputated", "larmamputated", "rarmamputated", "headamputated",
    "llegdislocation", "rlegdislocation", "larmdislocation", "rarmdislocation", "jawdislocation",
    "heartstop", "lungsfunction", "berserkActive2", "hasHealthChip", "otrub", "alive", "canmove",
    "arteria", "rarmarteria", "larmarteria", "rlegarteria", "llegarteria",
}

local function FirstNumber(v)
    if isnumber(v) then return v end
    if istable(v) and isnumber(v[1]) then return v[1] end
    return 0
end

local function BuildOrganismSnapshot(target)
    local d = {nick = target:Nick(), hp = math.floor(target:Health() or 0)}
    local org = target.organism
    if not istable(org) then return d end

    for _, k in ipairs(ORG_NUMERIC) do
        if isnumber(org[k]) then d[k] = org[k] end
    end
    for _, k in ipairs(ORG_FLAGS) do
        local v = org[k]
        if isbool(v) or isnumber(v) then d[k] = v end
    end

    d.dead = (not target:Alive()) or org.alive == false or target:Health() <= 0

    if isfunction(target.GetNetVar) then
        local aw = target:GetNetVar("arterialwounds")
        d.arterialWounds = istable(aw) and table.Count(aw) or 0
        d.chipNet = target:GetNetVar("zb_has_healthchip", false) and true or false
    end

    local cls = target.PlayerClassName
    if cls == "furry" or cls == "Combine" then d.chipNet = true end

    local o2 = org.o2
    if istable(o2) then
        d.o2 = tonumber(o2[1]) or 0
        d.o2max = tonumber(o2.range) or 30
    elseif isnumber(o2) then
        d.o2 = o2
        d.o2max = 30
    end

    local st = org.stamina
    if istable(st) then
        d.stamina = tonumber(st[1]) or 0
        d.staminaMax = tonumber(st.max) or 180
    end

    d.lungsR = FirstNumber(org.lungsR)
    d.lungsL = FirstNumber(org.lungsL)
    return d
end

local function IsDoor(ent)
    if not IsValid(ent) then return false end
    local class = string.lower(ent:GetClass() or "")
    return class == "prop_door_rotating"
        or class == "func_door"
        or class == "func_door_rotating"
        or class == "func_movelinear"
        or string.find(class, "door", 1, true) ~= nil
end

local function LookingDoor(ply)
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * MODE.BuilderReachDistance,
        filter = ply,
        mask = MASK_SOLID
    })
    local ent = tr and tr.Entity
    if IsDoor(ent) then return ent, tr end

    tr = ply:GetEyeTrace()
    ent = tr and tr.Entity
    if IsDoor(ent) and ply:GetShootPos():DistToSqr(tr.HitPos) <= MODE.BuilderReachDistance * MODE.BuilderReachDistance then
        return ent, tr
    end
end

function MODE.BuilderBoardDoor(ply, ent, tr)
    if not IsValid(ply) then return false end
    local now = CurTime()
    if (ply.BuilderNextBoard or 0) > now then return true end

    if not IsValid(ent) then
        ent, tr = LookingDoor(ply)
    end

    if not IsDoor(ent) then
        Notify(ply, "Строитель: наведитесь на дверь", Color(220, 170, 90))
        return false
    end

    if tr and tr.HitPos and ply:GetShootPos():DistToSqr(tr.HitPos) > MODE.BuilderReachDistance * MODE.BuilderReachDistance then
        Notify(ply, "Строитель: подойдите ближе", Color(220, 170, 90))
        return false
    end

    ply.BuilderNextBoard = now + MODE.BuilderBoardCooldown
    ent:Fire("close")
    ent:Fire("lock")
    ent:SetNWBool("HMCD_BoardedDoor", true)
    ent.BoardedUp = true
    ent.DoorHP = math.max(ent.DoorHP or 100, MODE.BuilderDoorHP)
    ent:EmitSound("physics/wood/wood_plank_impact_hard" .. math.random(1, 3) .. ".wav", 75)
    Notify(ply, "Дверь заколочена", Color(200, 170, 110))
    return true
end

hook.Add("PlayerUse", "HMCD_Builder_UseDoor", function(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end

    if ent.BoardedUp or ent:GetNWBool("HMCD_BoardedDoor", false) then
        Notify(ply, "Дверь заколочена", Color(200, 170, 110))
        return false
    end

    if Prof(ply) == "builder" and (ply:KeyDown(IN_SPEED) or ply:KeyDown(IN_WALK)) and IsDoor(ent) and (ply.HMCDAbilityKey or KEY_E) == KEY_E then
        MODE.BuilderBoardDoor(ply, ent)
        return false
    end
end)

local function RunProfessionAbility(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if (ply.HMCDNextAbilityUse or 0) > CurTime() then return end

    ply.HMCDNextAbilityUse = CurTime() + 0.15

    local prof = Prof(ply)
    if prof == "builder" then
        MODE.BuilderBoardDoor(ply)
        return
    end

    if prof == "doctor" then
        if (ply.HMCDNextDoctorUse or 0) > CurTime() then return end
        ply.HMCDNextDoctorUse = CurTime() + 1.0
        local target = nil
        local tr = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 170,
            filter = ply,
            mask = MASK_SHOT
        })
        if tr and IsValid(tr.Entity) then
            if tr.Entity:IsPlayer() then target = tr.Entity end
            if tr.Entity:IsRagdoll() and IsValid(tr.Entity.ply) then target = tr.Entity.ply end
        end
        if not IsValid(target) then
            local aim = ply:GetAimVector()
            local shoot = ply:GetShootPos()
            local bestDot = 0.94
            for _, other in player.Iterator() do
                if other ~= ply and IsValid(other) and other:Alive() and other:WorldSpaceCenter():DistToSqr(shoot) <= 170 * 170 then
                    local dir = other:WorldSpaceCenter() - shoot
                    dir:Normalize()
                    local dot = aim:Dot(dir)
                    if dot > bestDot then
                        bestDot = dot
                        target = other
                    end
                end
            end
        end
        if IsValid(target) then
            net.Start("HMCD_Professions_Abilities_DisplayOrganismInfo")
                net.WriteTable(BuildOrganismSnapshot(target))
            net.Send(ply)
        else
            Notify(ply, "Осмотр: наведитесь на человека", Color(220, 170, 90))
        end
        return
    end

    if prof == "cook" then
        if (ply.CookNextFeed or 0) > CurTime() then return end
        ply.CookNextFeed = CurTime() + MODE.CookBuffCooldown
        local affected = 0
        for _, target in ipairs(ents.FindInSphere(ply:GetPos(), MODE.CookBuffRadius)) do
            if IsValid(target) and target:IsPlayer() and target:Alive() then
                local org = target.organism
                if istable(org) and istable(org.o2) and isnumber(org.o2[1]) then
                    local max_o2 = tonumber(org.o2.range) or 30
                    org.o2[1] = math.min(org.o2[1] + MODE.CookBuffAmount, max_o2)
                    affected = affected + 1
                end
            end
        end
        Notify(ply, "Насыщение восстановлено союзникам: " .. affected, Color(120, 230, 150))
    end
end

MODE.RunProfessionAbility = RunProfessionAbility

local function AbilityModifierDown(ply)
    return ply:KeyDown(IN_SPEED) or ply:KeyDown(IN_WALK)
end

hook.Add("KeyPress", "HMCD_Professions_KeyPress", function(ply, key)
    if key ~= IN_USE then return end
    if not IsValid(ply) or not ply:Alive() then return end
    if not AbilityModifierDown(ply) then return end
    if (ply.HMCDAbilityKey or KEY_E) ~= KEY_E then return end

    RunProfessionAbility(ply)
end)

net.Receive("HMCD_Professions_AbilityUse", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not AbilityModifierDown(ply) then return end

    RunProfessionAbility(ply)
end)

net.Receive("HMCD_Professions_AbilityKey", function(_, ply)
    if not IsValid(ply) then return end

    local key = net.ReadUInt(10)

    if not isnumber(key) or key <= 0 or key > 159 then
        key = KEY_E
    end

    ply.HMCDAbilityKey = math.floor(key)
end)

local traceUp = Vector(0, 0, 40)
local traceDown = Vector(0, 0, -180)

local function GetFootstepGround(walker, pos)
    local tr = util.TraceLine({
        start = pos + traceUp,
        endpos = pos + traceDown,
        filter = walker,
        mask = MASK_SOLID_BRUSHONLY
    })

    if not tr or not tr.Hit or tr.HitSky or not isvector(tr.HitNormal) or tr.HitNormal.z < 0.3 then
        tr = util.TraceLine({
            start = pos + traceUp,
            endpos = pos + traceDown,
            filter = walker,
            mask = MASK_SOLID
        })
    end

    if not tr or not tr.Hit or tr.HitSky then return end
    if not isvector(tr.HitNormal) or tr.HitNormal.z < 0.3 then return end
    return tr.HitPos, tr.HitNormal
end

local function WalkerColor(walker)
    local appearance = walker.CurAppearance or walker.Appearance
    local col = appearance and appearance.AColor
    if IsColor(col) then return col end
    if istable(col) and isnumber(col.r) then return Color(col.r, col.g or 255, col.b or 255) end
    if walker.GetPlayerColor then
        local v = walker:GetPlayerColor()
        if isvector(v) then
            return Color(math.Clamp(v.x * 255, 0, 255), math.Clamp(v.y * 255, 0, 255), math.Clamp(v.z * 255, 0, 255))
        end
    end
    return Color(255, 255, 255)
end

local function SendFootstep(walker, pos, foot)
    if not IsValid(walker) or not walker:IsPlayer() or not walker:Alive() then return end
    if TEAM_SPECTATOR and walker:Team() == TEAM_SPECTATOR then return end

    local hunters = HuntsmanRecipients()
    if #hunters <= 0 then return end

    local origin = pos or walker:GetPos()
    local recipients = {}
    local maxDistSqr = MODE.HuntsmanSendDistanceSqr

    for i = 1, #hunters do
        local recipient = hunters[i]
        if IsValid(recipient) and recipient ~= walker and recipient:Alive() and recipient:GetPos():DistToSqr(origin) <= maxDistSqr then
            recipients[#recipients + 1] = recipient
        end
    end
    if #recipients <= 0 then return end

    local groundPos, groundNormal = GetFootstepGround(walker, origin)
    if not groundPos then return end

    local col = WalkerColor(walker)

    net.Start("HMCD_Professions_Abilities_AddFootstep")
        net.WriteVector(groundPos)
        net.WriteFloat(walker:EyeAngles().y)
        net.WriteBool(foot == 0)
        net.WriteColor(col, false)
        net.WriteVector(groundNormal)
    net.Send(recipients)
end
MODE.SendFootstep = SendFootstep

hook.Add("PlayerFootstep", "HMCD_Professions_Abilities", function(ply, pos, foot)
    if not IsValid(ply) then return end
    ply.HMCDLastHuntsmanStepPos = pos
    ply.HMCDNextHuntsmanStep = CurTime() + MODE.HuntsmanStepInterval
    SendFootstep(ply, pos, foot)
end)

local nextFallback = 0
hook.Add("Think", "HMCD_Professions_FootstepFallback", function()
    local now = CurTime()
    if now < nextFallback then return end
    nextFallback = now + MODE.HuntsmanFallbackInterval

    if #HuntsmanRecipients() <= 0 then return end

    local moveDistSqr = MODE.HuntsmanStepMoveDistSqr
    local interval = MODE.HuntsmanStepInterval

    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:Alive() and not (TEAM_SPECTATOR and ply:Team() == TEAM_SPECTATOR) then
            if (ply.HMCDNextHuntsmanStep or 0) <= now and ply:OnGround() then
                local pos = ply:GetPos()
                local last = ply.HMCDLastHuntsmanStepPos
                if (not last) or pos:DistToSqr(last) >= moveDistSqr then
                    ply.HMCDLastHuntsmanStepPos = pos
                    ply.HMCDNextHuntsmanStep = now + interval
                    ply.HMCDHuntsmanFoot = not ply.HMCDHuntsmanFoot
                    SendFootstep(ply, pos, ply.HMCDHuntsmanFoot and 0 or 1)
                end
            end
        end
    end
end)

hook.Add("PlayerSpawn", "HMCD_Professions_FootstepReset", function(ply)
    if not IsValid(ply) then return end
    ply.HMCDLastHuntsmanStepPos = nil
    ply.HMCDNextHuntsmanStep = 0
    nextHuntsmanScan = 0
end)

hook.Add("PlayerDeath", "HMCD_Professions_FootstepResetDeath", function(ply)
    if not IsValid(ply) then return end
    ply.HMCDLastHuntsmanStepPos = nil
    nextHuntsmanScan = 0
end)

concommand.Add("hg_create_pipebomb", function(ply)
    if not IsValid(ply) or not ply:Alive() or (ply.organism and ply.organism.otrub) or Prof(ply) ~= "engineer" then return end
    local have_ammo
    local have_nails
    for id, amt in pairs(ply:GetAmmo()) do
        local name = game.GetAmmoName(id)
        if name == "Nails" and amt >= 3 then
            have_nails = true
        else
            local tbl = hg.ammotypeshuy and hg.ammotypeshuy[name]
            if tbl and tbl.BulletSettings and tbl.BulletSettings.Mass and tbl.BulletSettings.Mass * amt > 50 then have_ammo = {name, amt} end
        end
    end
    if have_ammo and ply:HasWeapon("weapon_leadpipe") and have_nails then
        local ammo_tbl = hg.ammotypeshuy and hg.ammotypeshuy[have_ammo[1]]
        if not ammo_tbl then return end
        ply:SetAmmo(ply:GetAmmoCount("Nails") - 3, "Nails")
        ply:SetAmmo(math.Round((ammo_tbl.BulletSettings.Mass * have_ammo[2] - 50) / ammo_tbl.BulletSettings.Mass), have_ammo[1])
        ply:StripWeapon("weapon_leadpipe")
        ply:Give("weapon_hg_pipebomb_tpik")
        Notify(ply, "Инженер: труба-бомба создана", Color(90, 160, 230))
    else
        Notify(ply, "Инженер: нужны труба, 3 гвоздя и тяжёлые патроны", Color(220, 170, 90))
    end
end)

concommand.Add("hg_create_molotov", function(ply)
    if not IsValid(ply) or not ply:Alive() or (ply.organism and ply.organism.otrub) or Prof(ply) ~= "engineer" then return end
    local have_barrel
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 80)) do
        if IsValid(ent) and hg.gas_models and hg.gas_models[ent:GetModel()] then have_barrel = true break end
    end
    if have_barrel and (ply:HasWeapon("weapon_bandage_sh") or ply:HasWeapon("weapon_bigbandage_sh")) and ply:HasWeapon("weapon_hg_bottle") then
        if ply:HasWeapon("weapon_bandage_sh") then ply:StripWeapon("weapon_bandage_sh") else ply:StripWeapon("weapon_bigbandage_sh") end
        ply:StripWeapon("weapon_hg_bottle")
        ply:Give("weapon_hg_molotov_tpik")
        Notify(ply, "Инженер: коктейль Молотова создан", Color(90, 160, 230))
    else
        Notify(ply, "Инженер: нужны бутылка, бинт и газовая бочка рядом", Color(220, 170, 90))
    end
end)
end)

local EX_NET = "HMCD_Professions_Sinners"
local EX_WEAPON = "weapon_crucifix_guilt"
local EX_KEY = "exorcist"
local EX_RADIUS = 750
local EX_RADIUS_SQR = EX_RADIUS * EX_RADIUS
local EX_UPDATE = 0.45
local EX_THRESHOLD = 45
local EX_DEEP = 5
local EX_CONE = 0.2
local EX_MAX_TARGETS = 6
local EX_SPRINT_BLIND = true
local EX_SPRINT_SPEED_SQR = 40000

util.AddNetworkString(EX_NET)

if istable(MODE) then
    MODE.ExorcistRadius = EX_RADIUS
    MODE.ExorcistUpdate = EX_UPDATE
    MODE.ExorcistThreshold = EX_THRESHOLD
    MODE.ExorcistDeepThreshold = EX_DEEP
    MODE.ExorcistCone = EX_CONE
    MODE.ExorcistMaxTargets = EX_MAX_TARGETS
    MODE.ExorcistWeapon = EX_WEAPON
end

local function ExorcistPlayers()
    if isfunction(player.Iterator) then return player.Iterator() end
    return ipairs(player.GetAll())
end

local function ExorcistProfession(ply)
    if not IsValid(ply) then return "" end

    local prof = ply.Profession

    if not isstring(prof) or prof == "" then
        prof = isfunction(ply.GetNWString) and ply:GetNWString("HMCD_CurrentProfession", "") or ""
    end

    if not isstring(prof) then return "" end

    return string.lower(string.Trim(prof))
end

local function IsExorcist(ply)
    return ExorcistProfession(ply) == EX_KEY
end

local function SinnerGuilt(ply)
    if istable(CRUCIFIX_GUILT) and isfunction(CRUCIFIX_GUILT.GetGuilt) then
        local value = tonumber(CRUCIFIX_GUILT.GetGuilt(ply))
        if value then return value end
    end

    local value = tonumber(ply.Sovest)

    if value == nil and isfunction(ply.guilt_GetValue) then value = tonumber(ply:guilt_GetValue()) end
    if value == nil and isfunction(ply.GetNWFloat) then value = tonumber(ply:GetNWFloat("Sovest", 100)) end

    return value or 100
end

local function SinnerBody(ply)
    local ragdoll = ply.FakeRagdoll

    if not IsValid(ragdoll) and istable(hg) and istable(hg.ragdollFake) then ragdoll = hg.ragdollFake[ply] end
    if IsValid(ragdoll) then return ragdoll end

    return ply
end

local function IsSpectating(ply)
    if not isfunction(ply.Team) then return false end
    if TEAM_SPECTATOR == nil then return false end

    return ply:Team() == TEAM_SPECTATOR
end

local nextExorcistScan = 0

hook.Add("Think", "HMCD_Professions_ExorcistScan", function()
    local now = CurTime()
    if now < nextExorcistScan then return end
    nextExorcistScan = now + EX_UPDATE

    local exorcists = {}

    for _, ply in ExorcistPlayers() do
        if IsValid(ply) and ply:Alive() and IsExorcist(ply) then
            exorcists[#exorcists + 1] = ply
        end
    end

    if #exorcists <= 0 then return end

    for index = 1, #exorcists do
        local seer = exorcists[index]
        local eyes = seer:EyePos()
        local aim = seer:GetAimVector()
        local blind = EX_SPRINT_BLIND and seer:KeyDown(IN_SPEED) and seer:GetVelocity():Length2DSqr() > EX_SPRINT_SPEED_SQR
        local found = {}

        if not blind then
            for _, target in ExorcistPlayers() do
                if #found >= EX_MAX_TARGETS then break end

                if IsValid(target) and target ~= seer and target:Alive() and not IsSpectating(target) then
                    local guilt = SinnerGuilt(target)

                    if guilt <= EX_THRESHOLD then
                        local body = SinnerBody(target)
                        local center = body:WorldSpaceCenter()

                        if center:DistToSqr(eyes) <= EX_RADIUS_SQR then
                            local dir = center - eyes
                            dir:Normalize()

                            if aim:Dot(dir) >= EX_CONE then
                                local tr = util.TraceLine({
                                    start = eyes,
                                    endpos = center,
                                    filter = {seer, target, body},
                                    mask = MASK_SHOT
                                })

                                if not tr.Hit then
                                    found[#found + 1] = {body, guilt <= EX_DEEP and 2 or 1}
                                end
                            end
                        end
                    end
                end
            end
        end

        net.Start(EX_NET)
            net.WriteUInt(#found, 4)
            for slot = 1, #found do
                net.WriteEntity(found[slot][1])
                net.WriteUInt(found[slot][2], 2)
            end
        net.Send(seer)
    end
end)

local function GiveExorcistWeapon(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not IsExorcist(ply) then return end
    if not weapons.Get(EX_WEAPON) then return end
    if ply:HasWeapon(EX_WEAPON) then return end

    ply:Give(EX_WEAPON)
end

if istable(MODE) then MODE.GiveExorcistWeapon = GiveExorcistWeapon end

hook.Add("PlayerSpawn", "HMCD_Professions_ExorcistWeapon", function(ply)
    timer.Simple(0.6, function() GiveExorcistWeapon(ply) end)
    timer.Simple(2.5, function() GiveExorcistWeapon(ply) end)
end)

hook.Add("HMCD_ProfessionAssigned", "HMCD_Professions_ExorcistWeapon", function(ply)
    timer.Simple(0.2, function() GiveExorcistWeapon(ply) end)
end)
