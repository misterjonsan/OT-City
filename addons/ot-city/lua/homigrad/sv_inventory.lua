local blackList = {
    ["weapon_hands_sh"] = true,
    ["weapon_zombclaws"] = true
}

local META = getmetatable("PLAYER")
META.inventory = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}
META.armors = {}

local vecZero = Vector(0, 0, 0)
local lootSessions = {}

local function IsLootableEntity(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() and not IsValid(ent.FakeRagdoll) then return false end
    return true
end

local function EnsureInventory(ent)
    ent.inventory = ent.inventory or {}
    ent.inventory.Weapons = ent.inventory.Weapons or {}
    ent.inventory.Ammo = ent.inventory.Ammo or {}
    ent.inventory.Armor = ent.inventory.Armor or {}
    ent.inventory.Attachments = ent.inventory.Attachments or {}
    ent.armors = ent.armors or {}
    return ent.inventory
end

local function SyncInventory(ent)
    if not IsValid(ent) then return end
    EnsureInventory(ent)
    ent:SetNetVar("Inventory", ent.inventory)
end

local function CanReachLoot(ply, ent, dist)
    if not IsValid(ply) or not IsValid(ent) then return false end
    dist = dist or 125
    return ent:GetPos():DistToSqr(ply:GetPos()) <= dist * dist
end

local function GetWeaponEntry(inv, class)
    if not inv or not inv.Weapons then return nil end
    return inv.Weapons[class]
end

local function MakeLootKey(tab, thing, extra)
    if tab == "Armor" then
        return tab .. "|" .. tostring(thing) .. "|" .. tostring(extra or "")
    end
    return tab .. "|" .. tostring(thing)
end

local function RandomToken()
    return util.CRC(tostring(SysTime()) .. tostring(math.random(1, 2147483647)) .. tostring(os.time()) .. tostring(math.random(1, 2147483647)) .. tostring(CurTime()))
end

local function RandomSessionId(ply, ent)
    return util.CRC(tostring(ply) .. tostring(ent) .. tostring(SysTime()) .. tostring(math.random(1, 2147483647)))
end

local function BuildLootRevealMap(ent, openedAt)
    local inv = ent:GetNetVar("Inventory") or {}
    local armor = ent:GetNetVar("Armor") or {}

    inv = table.Copy(inv)
    inv.Money = {}
    inv.Armor = armor

    ent.foundloot = ent.foundloot or {}

    local revealAt = {}
    local count2 = 0

    local function canShow(tab, ent2, a, b)
        if tab == "Weapons" then
            return true
        elseif tab == "Ammo" then
            return true
        elseif tab == "Armor" then
            if not hg.armor or not hg.armor[a] or not hg.armor[a][b] then return false end
            if hg.armor[a][b].nodrop then return false end
            return true
        elseif tab == "Attachments" then
            return true
        elseif tab == "Money" then
            return true
        end
        return false
    end

    for tab, things in pairs(inv) do
        if not istable(things) then continue end

        local keys = table.GetKeys(things)
        table.sort(keys, function(a, b)
            local aextra = nil
            local bextra = nil
            if tab == "Armor" then
                aextra = things[a]
                bextra = things[b]
            end
            return (ent.foundloot[MakeLootKey(tab, a, aextra)] and 1 or 0) > (ent.foundloot[MakeLootKey(tab, b, bextra)] and 1 or 0)
        end)

        for _, i in ipairs(keys) do
            local thing = things[i]
            local thing1 = istable(thing) and thing or { thing }

            if not canShow(tab, ent, i, unpack(thing1)) then continue end
            if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end

            local extra = nil
            if tab == "Armor" then
                extra = thing1[1]
            end

            local lootKey = MakeLootKey(tab, i, extra)
            local alreadyFound = ent.foundloot[lootKey] and true or false
            local delay = 0

            if not alreadyFound then
                count2 = count2 + 1
                delay = 2 + count2
            end

            revealAt[lootKey] = openedAt + delay
        end
    end

    return revealAt
end

local function StartLootSession(ply, ent)
    local openedAt = CurTime()
    local revealAt = BuildLootRevealMap(ent, openedAt)
    local sessionId = RandomSessionId(ply, ent)

    lootSessions[ply] = {
        ent = ent,
        openedAt = openedAt,
        sessionId = sessionId,
        revealAt = revealAt,
        tokens = {},
        used = {}
    }

    local sendTokens = {}
    for lootKey, t in pairs(revealAt) do
        local token = RandomToken()
        lootSessions[ply].tokens[lootKey] = token
        sendTokens[lootKey] = {
            token = token,
            revealAt = t
        }
    end

    return lootSessions[ply], sendTokens
end

local function GetLootSession(ply, ent)
    local session = lootSessions[ply]
    if not session then return nil end
    if session.ent ~= ent then return nil end
    return session
end

local function CanTakeLootNow(ply, ent, tab, thing, extra)
    local session = GetLootSession(ply, ent)
    if not session then return false end
    local t = session.revealAt[MakeLootKey(tab, thing, extra)]
    if not t then return false end
    return CurTime() >= t
end

local function ValidateLootToken(ply, ent, sessionId, lootKey, token)
    local session = GetLootSession(ply, ent)
    if not session then return false end
    if session.sessionId ~= sessionId then return false end
    if session.used[lootKey] then return false end
    if session.tokens[lootKey] ~= token then return false end
    return true
end

local function ConsumeLootToken(ply, lootKey)
    local session = lootSessions[ply]
    if not session then return end
    session.used[lootKey] = true
    session.tokens[lootKey] = nil
    session.revealAt[lootKey] = nil
end

local function ClearLootSession(ply)
    lootSessions[ply] = nil
end

function hg.CreateInv(ply)
    ply.inventory = {}
    local inv = EnsureInventory(ply)

    inv.Weapons = {}
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            local class = wep:GetClass()
            if not blackList[class] then
                inv.Weapons[class] = wep
            end
        end
    end

    inv.Ammo = ply:GetAmmo() or {}
    inv.Armor = {}
    inv.Attachments = {}
    SyncInventory(ply)
end

function hg.RenewInv(ply, isDead)
    local inv = EnsureInventory(ply)

    local sling = inv.Weapons["hg_sling"]
    local kastet = inv.Weapons["hg_brassknuckles"]
    local flashlight = inv.Weapons["hg_flashlight"]

    inv.Weapons = {}

    for _, wep in pairs(ply:GetWeapons()) do
        if IsValid(wep) then
            local class = wep:GetClass()
            if not blackList[class] then
                if not isDead then
                    inv.Weapons[class] = wep
                else
                    ply.nohook = true
                    ply:DropWeapon(wep)

                    wep:SetNoDraw(true)
                    wep:DrawShadow(false)
                    wep:AddSolidFlags(FSOLID_NOT_SOLID)

                    local rag = ply:GetNWEntity("RagdollDeath")

                    if IsValid(rag) then
                        wep:SetPos(rag:GetPos() + vector_up * -10000)
                        wep:SetParent(rag, 0)
                    else
                        wep:SetPos(ply:GetPos())
                        wep:SetParent(ply, 0)
                    end

                    inv.Weapons[class] = wep
                end
            end
        end
    end

    inv.Weapons["hg_sling"] = sling
    inv.Weapons["hg_brassknuckles"] = kastet
    inv.Weapons["hg_flashlight"] = flashlight
    inv.Ammo = ply:GetAmmo() or {}
    inv.Armor = inv.Armor or {}
    inv.Attachments = inv.Attachments or {}
    SyncInventory(ply)
end

hook.Add("PlayerSpawn", "homigrad-inventory", function(ply)
    hg.CreateInv(ply)
    ply.armors = {}
    ply.armors_health = {}
    ply:SyncArmor()
    ClearLootSession(ply)
end)

hook.Add("PlayerDisconnected", "homigrad-inventory-lootsession", function(ply)
    ClearLootSession(ply)
end)

hook.Add("WeaponEquip", "homigrad-inventory", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) then return end
    if blackList[wep:GetClass()] then return end

    local inv = EnsureInventory(ply)

    wep:SetNoDraw(false)
    inv.Weapons[wep:GetClass()] = wep

    if wep.sling then
        wep.sling = nil
        if not inv.Weapons["hg_sling"] then
            inv.Weapons["hg_sling"] = true
            ply:ChatPrint("Ты взял ремень,который был прикреплен на оружии")
        else
            local sling = ents.Create("hg_sling")
            if IsValid(sling) then
                sling:SetPos(ply:EyePos())
                sling:SetVelocity(ply:GetAimVector() * 5)
                sling:Spawn()
            end
            ply:ChatPrint("Ты отсоединил ремень от оружия.")
        end
    end

    SyncInventory(ply)
end)

hook.Add("PlayerDroppedWeapon", "homigrad-inventory", function(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return end
    if ply:IsNPC() then return end
    if blackList[wep:GetClass()] then return end

    local inv = EnsureInventory(ply)
    if not inv.Weapons[wep:GetClass()] then return end
    if ply.nohook then
        ply.nohook = nil
        return
    end

    inv.Weapons[wep:GetClass()] = nil
    SyncInventory(ply)
end)

hook.Add("PlayerAmmoChanged", "homigrad-inventory", function(ply, ammoID, oldcount, newcount)
    if not IsValid(ply) then return end
    if not ply.inventory then return end

    ply.inventory.Ammo = ply:GetAmmo() or {}
    SyncInventory(ply)

    if game.GetAmmoName(ammoID) == "Grenade" then
        local delta = math.max((newcount or 0) - (oldcount or 0), 0)
        if delta <= 0 then return end

        local wep = ply:Give("weapon_hg_hl2nade_tpik")
        if IsValid(wep) then
            wep.DontEquipInstantly = true
            wep.count = delta
            ply:SetAmmo(0, ammoID)

            timer.Simple(0.1, function()
                if IsValid(wep) then
                    wep.DontEquipInstantly = nil
                end
            end)
        end
    end
end)

hook.Add("PlayerDropWeapon", "homigrad-inventory", function(ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep.NoDrop then return end

    local ent = hg.GetCurrentCharacter(ply)
    if not IsValid(ent) then return end

    if wep.RemoveFake then
        wep:RemoveFake()
    end

    wep:SetCollisionGroup(COLLISION_GROUP_WORLD)
    ply:DropWeapon(wep, ply:EyePos(), vecZero)
    wep:SetPos(ply:EyePos())

    local inv = EnsureInventory(ply)
    inv.Weapons[wep:GetClass()] = nil
    SyncInventory(ply)

    ply:SetActiveWeapon(NULL)

    timer.Simple(0.1, function()
        if not IsValid(wep) or not IsValid(ply) then return end

        local rag = ply:GetNWEntity("RagdollDeath")
        local ent2 = IsValid(rag) and rag or ply.FakeRagdoll
        if not IsValid(ent2) then return end

        local handBone = ent2:LookupBone("ValveBiped.Bip01_R_Hand")
        local handpos, handang = ent2:GetPos(), ent2:GetAngles()

        if handBone then
            local phys = ent2:GetPhysicsObjectNum(ent2:TranslateBoneToPhysBone(handBone))
            if IsValid(phys) then
                handpos = phys:GetPos()
                handang = phys:GetAngles()
            end
        end

        local localpos, localang = LocalToWorld(wep.WorldPos and wep.WorldPos + Vector(3.5, 0, 0) or vector_origin, wep.WorldAng or angle_zero, handpos, handang)
        localang:RotateAroundAxis(localang:Forward(), 180)

        wep:SetPos(localpos)
        wep:SetAngles(localang)
        wep:SetVelocity(vector_origin)
        wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local physbone = ent2:TranslateBoneToPhysBone(handBone)
        local physbonetorso = ent2:TranslateBoneToPhysBone(ent2:LookupBone("ValveBiped.Bip01_Spine2"))

        local cons = constraint.Weld(wep, ent2, 0, physbone, 600, true, false)

        if math.random(1, 10) <= 2 then
            timer.Simple(4, function()
                timer.Simple(0, function()
                    if IsValid(wep) and IsValid(ent2) then
                        constraint.NoCollide(wep, ent2, 0, 0)
                    end
                end)
                if IsValid(cons) then
                    cons:Remove()
                    cons = nil
                end
            end)
        end

        local enta = ply:Alive() and (ply.organism and not ply.organism.otrub) and ply or ent2
        local inv2 = enta:GetNetVar("Inventory", {})
        if not inv2.Weapons then return end

        if inv2.Weapons["hg_sling"] and ishgweapon(wep) and not wep:IsPistolHoldType() then
            constraint.Rope(wep, ent2, 0, physbonetorso, vector_origin, vector_origin, 10, 5, 0, 0, "null", true, color_white)
            wep.sling = true
            ent2.rope_attach = wep
            inv2.Weapons["hg_sling"] = nil
            enta:SetNetVar("Inventory", inv2)
        end
    end)
end)

hook.Add("PlayerLoadout", "giveHands", function(ply)
    ply:Give("weapon_hands_sh")
    return true
end)

hook.Add("DoPlayerDeath", "homigrad-inventory", function(ply)
    hook.Run("PlayerDropWeapon", ply)
end)

function hg.TransferItems(ply, ragdoll)
    if not IsValid(ragdoll) then return end

    local inv = ply:GetNetVar("Inventory", {})
    ragdoll.inventory = inv
    ragdoll:SetNetVar("Inventory", ragdoll.inventory)

    hg.CreateInv(ply)
    ply:SetNetVar("Inventory", {})
    ply.inventory = ply:GetNetVar("Inventory", {})

    ragdoll:SetNetVar("Armor", ply.armors)
    ragdoll.armors = ragdoll:GetNetVar("Armor", {})
    ragdoll:SetNetVar("HideArmorRender", ply:GetNetVar("HideArmorRender", false))

    ply:SetNetVar("Armor", {})
    ply.armors = ply:GetNetVar("Armor", {})

    hg.SyncWeapons()
    hook.Run("ItemTransfered", ply, ragdoll)
end

hook.Add("PostPlayerDeath", "homigrad-inventory", function(ply)
    local ragdoll = ply:GetNWEntity("RagdollDeath")
    hg.RenewInv(ply, true)
    hg.TransferItems(ply, ragdoll)
    SyncInventory(ply)
    if IsValid(ragdoll) then
        ragdoll:SetNetVar("Inventory", ragdoll.inventory)
    end
    ply:SetNetVar("Armor", {})
    ply:SetNetVar("Inventory", {})
    ply:RemoveAllAmmo()
    ClearLootSession(ply)
end)

local functions = {
    ["Weapons"] = function(ply, ent, wep)
        local inv = EnsureInventory(ent)

        if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == wep then return end
        if not inv.Weapons[wep] then return end

        local weapon
        local entry = inv.Weapons[wep]
        local weaponIsEnt = (not isbool(entry)) and IsValid(entry) and entry:IsWeapon()

        if not weaponIsEnt then
            weapon = ents.Create(wep)
            if not IsValid(weapon) then return end
            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory ~= 1)
            weapon.IsSpawned = true
            weapon.init = true
            weapon:Spawn()
            weapon:SetPos(ent:GetPos())
            weapon:SetAngles(ent:GetAngles())

            if weapon.SetInfo and istable(entry) then
                weapon:SetInfo(entry)
            end
        else
            weapon = entry
            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory ~= 1)
            weapon:SetParent(NULL)
            weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            weapon:SetAngles(ent:GetAngles())
            weapon:SetNoDraw(false)
            weapon:DrawShadow(true)
            weapon:RemoveSolidFlags(FSOLID_NOT_SOLID)
        end

        inv.Weapons[wep] = nil

        if ent:IsPlayer() then
            if weaponIsEnt then
                ent:DropWeapon(weapon)
                if IsValid(weapon) then
                    weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
                end
            else
                ent:StripWeapon(wep)
            end
        end

        ply:DropObject()

        if not IsValid(weapon) then return end
        if not weapon:IsWeapon() then
            weapon:Use(ply)
            return
        end

        weapon.IsSpawned = false
        weapon.init = false

        if hook.Run("PlayerCanPickupWeapon", ply, weapon) == false then
            weapon.IsSpawned = true
            weapon.init = true
            weapon:SetPos(ply:EyePos())
            return
        end

        if IsValid(weapon) and weapon:IsWeapon() then
            ply:PickupWeapon(weapon)
        end

        if IsValid(weapon) and not weapon.DontEquipInstantly then
            timer.Simple(0, function()
                if IsValid(ply) and IsValid(weapon) then
                    ply:SelectWeapon(weapon:GetClass())
                end
            end)
        end
    end,
    ["Ammo"] = function(ply, ent, ammo)
        ammo = tonumber(ammo)
        if not ammo then return end

        local inv = EnsureInventory(ent)
        local amt = inv.Ammo[ammo]
        if not amt or amt <= 0 then return end

        ply:GiveAmmo(amt, game.GetAmmoName(ammo), true)

        if ent:IsPlayer() then
            ent:SetAmmo(0, game.GetAmmoName(ammo))
            inv.Ammo = ent:GetAmmo() or {}
        else
            inv.Ammo[ammo] = nil
        end
    end,
    ["Armor"] = function(ply, ent, placement, armor)
        if not isstring(placement) or not isstring(armor) then return end
        if not hg.armor or not hg.armor[placement] or not hg.armor[placement][armor] then return end
        if hg.armor[placement][armor].nodrop then return end

        ent.armors = ent.armors or {}
        ply.armors = ply.armors or {}

        if ent.armors[placement] ~= armor or ply.armors[placement] then return end
        if not hg.AddArmor(ply, armor) then return end

        ent.armors[placement] = nil

        if placement == "face" and ent:GetNetVar("zableval_masku", false) and armor ~= "nightvision1" then
            ply:SetNetVar("zableval_masku", true)
            ent:SetNetVar("zableval_masku", false)
        end

        hook.Run("ItemTransfer", ply, ent, placement, armor)
    end,
    ["Attachments"] = function(ply, ent, att)
        att = tonumber(att)
        if not att then return end

        local invEnt = EnsureInventory(ent)
        local invPly = EnsureInventory(ply)

        if not invEnt.Attachments[att] then return end
        invPly.Attachments[#invPly.Attachments + 1] = invEnt.Attachments[att]
        invEnt.Attachments[att] = nil
    end
}

util.AddNetworkString("ply_take_item")
util.AddNetworkString("loot_open_inv")

net.Receive("ply_take_item", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end
    if (ply.cooldown_takeitem or 0) > CurTime() then return end
    ply.cooldown_takeitem = CurTime() + 0.35

    local tblIndex = net.ReadString()
    local thing = net.ReadString()
    local rawTbl = net.ReadTable()
    local ent = net.ReadEntity()
    local sessionId = net.ReadString()
    local lootKey = net.ReadString()
    local token = net.ReadString()

    if not isstring(tblIndex) or not isstring(thing) then return end
    if not isstring(sessionId) or sessionId == "" then return end
    if not isstring(lootKey) or lootKey == "" then return end
    if not isstring(token) or token == "" then return end
    if not IsLootableEntity(ent) then return end

    local session = GetLootSession(ply, ent)
    if not session then return end
    if session.sessionId ~= sessionId then return end

    if not CanReachLoot(ply, ent, 125) then
        ClearLootSession(ply)
        return
    end

    if not ValidateLootToken(ply, ent, sessionId, lootKey, token) then return end

    local func = functions[tblIndex]
    if not func then return end

    local inv = EnsureInventory(ent)
    local expectedKey = nil

    if tblIndex == "Weapons" then
        if blackList[thing] then return end
        if not inv.Weapons[thing] then return end
        expectedKey = MakeLootKey("Weapons", thing)
        if expectedKey ~= lootKey then return end
        if not CanTakeLootNow(ply, ent, "Weapons", thing) then return end
        func(ply, ent, thing)
    elseif tblIndex == "Ammo" then
        local ammoID = tonumber(thing)
        if not ammoID then return end
        if inv.Ammo[ammoID] == nil then return end
        expectedKey = MakeLootKey("Ammo", ammoID)
        if expectedKey ~= lootKey then return end
        if not CanTakeLootNow(ply, ent, "Ammo", ammoID) then return end
        func(ply, ent, ammoID)
    elseif tblIndex == "Armor" then
        local placement = thing
        local armor = istable(rawTbl) and rawTbl[1] or nil
        if not isstring(armor) then return end
        if not ent.armors or ent.armors[placement] ~= armor then return end
        expectedKey = MakeLootKey("Armor", placement, armor)
        if expectedKey ~= lootKey then return end
        if not CanTakeLootNow(ply, ent, "Armor", placement, armor) then return end
        func(ply, ent, placement, armor)
    elseif tblIndex == "Attachments" then
        local att = tonumber(thing)
        if not att then return end
        if not inv.Attachments[att] then return end
        expectedKey = MakeLootKey("Attachments", att)
        if expectedKey ~= lootKey then return end
        if not CanTakeLootNow(ply, ent, "Attachments", att) then return end
        func(ply, ent, att)
    else
        return
    end

    ConsumeLootToken(ply, lootKey)

    SyncInventory(ply)
    SyncInventory(ent)
    if ply.SyncArmor then ply:SyncArmor() end
    if ent.SyncArmor then ent:SyncArmor() end
end)

local playerMeta = FindMetaTable("Player")

function playerMeta:OpenInventory(ent)
    if not IsValid(self) or not self:IsPlayer() then return end
    if not IsLootableEntity(ent) then return end
    if not CanReachLoot(self, ent, 125) then return end

    hook.Run("ZB_InventoryOpened", self, ent)

    if ent:IsPlayer() then
        hg.RenewInv(ent)
    end

    hg.RenewInv(self)

    self.cooldown_takeitem = CurTime() + 0.35

    local session, sendTokens = StartLootSession(self, ent)
    if not session then return end

    net.Start("loot_open_inv")
    net.WriteEntity(ent)
    net.WriteString(session.sessionId)
    net.WriteTable(sendTokens)
    net.Send(self)
end

function playerMeta:GetLookTrace()
    if not IsValid(self) or not self:Alive() then return end
    local tr = {}
    local ent = IsValid(self.FakeRagdoll) and self.FakeRagdoll or self
    local att = ent:GetAttachment(ent:LookupAttachment("eyes"))
    if not att then return false end
    tr.start = att.Pos
    tr.endpos = att.Pos + self:EyeAngles():Forward() * 80
    tr.filter = ent
    return util.TraceLine(tr)
end

hook.Add("Player Think", "loot-fellows", function(ply)
    if not IsValid(ply) or not ply:Alive() then
        ClearLootSession(ply)
        return
    end

    ply.keypressed = ply.keypressed or false

    local trace = hg.eyeTrace(ply, 60)
    if not trace then return end

    local ent = trace.Entity
    ent = IsValid(hg.RagdollOwner(ent)) and hg.RagdollOwner(ent) or ent

    local use = IsValid(ply.FakeRagdoll) and (ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED) and not ply:KeyDown(IN_ATTACK) and not ply:KeyDown(IN_ATTACK2)) or (not IsValid(ply.FakeRagdoll) and (ply:KeyDown(IN_ATTACK2) and ply:KeyDown(IN_USE)))

    if use then
        hook.Run("ZB_InventoryChecked", ply, ent)
        if not IsValid(ent) or not ent:GetNetVar("Inventory") then return end
        if not ply.keypressed then
            ply:OpenInventory(ent)
        end
        ply.keypressed = true
    else
        ply.keypressed = false
    end

    local session = lootSessions[ply]
    if not session then return end

    if not IsValid(session.ent) then
        ClearLootSession(ply)
        return
    end

    if not ply:Alive() then
        ClearLootSession(ply)
        return
    end

    if ply.organism and ply.organism.otrub then
        ClearLootSession(ply)
        return
    end

    if not CanReachLoot(ply, session.ent, 125) then
        ClearLootSession(ply)
        return
    end
end)