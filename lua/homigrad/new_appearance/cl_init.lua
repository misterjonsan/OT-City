hg.Appearance = hg.Appearance or {}

local AP = hg.Appearance

AP.PresetsCache = AP.PresetsCache or {}
AP.ActivePresetName = "main"
AP.ClientSavedAppearance = AP.ClientSavedAppearance or nil
AP.ClientSavedAppearanceRaw = AP.ClientSavedAppearanceRaw or ""
AP.ClientOTCoins = AP.ClientOTCoins or 0
AP.ClientOwnedCoinAccessories = AP.ClientOwnedCoinAccessories or {}
RK_DonateAccessories = RK_DonateAccessories or {}
RK_DonateAccessoriesSynced = RK_DonateAccessoriesSynced or false

local MDATA_OTCOIN_BALANCE_KEY = AP.OTCoin and AP.OTCoin.BalanceKey or "hg_otcoins_balance"
local MDATA_OTCOIN_OWNED_KEY = AP.OTCoin and AP.OTCoin.OwnedAccessoriesKey or "hg_otcoins_owned_accessories"

local weaponWhitelist = {
    weapon_physgun = true,
    gmod_tool = true,
    gmod_camera = true,
    weapon_crowbar = true,
    weapon_pistol = true,
    weapon_crossbow = true
}

local flashlightOffsetPos = Vector(4, -1, 0)
local flashlightOffsetAng = Angle(0, 0, 0)
local leftHandOffsetPos = Vector(1, 0, 0)
local leftHandOffsetAng = Angle(100, 90, 0)
local specialMaleOffset = Vector(0.4, 0, 0.4)
local glowMat = Material("sprites/light_glow02_add_noz")
local flashlightMat = Material("effects/flashlight/soft")
local caseEffectData = {
    crown = {
        material = Material("monteract/crown.png", "smooth"),
        color = Color(255, 208, 80),
        maxDistance = 2250000,
        rate = 0.16,
        burst = 1,
        maxParticles = 20,
        size = 1.6,
        spread = 6,
        rise = 3.2,
        life = 3.2,
        spin = 16,
        swirl = 0.6,
        offset = 6
    },
    killa = {
        material = Material("monteract/killa.png", "smooth"),
        color = Color(196, 104, 255),
        maxDistance = 1440000,
        rate = 0.2,
        burst = 1,
        maxParticles = 15,
        size = 1.9,
        spread = 5,
        life = 2.9,
        rise = 2.8,
        spin = 13,
        swirl = 0.5,
        offset = 9
    }
}

local function DrawCaseAccessoryEffect(effect, model, pos)
    local data = caseEffectData[effect]
    if not data or not IsValid(model) or not pos then return end
    if model.HGCaseEffectFrame == FrameNumber() then return end
    model.HGCaseEffectFrame = FrameNumber()

    local lply = LocalPlayer()
    if not IsValid(lply) then return end

    if EyePos():DistToSqr(pos) > data.maxDistance then
        model.HGCaseParticles = nil
        model.HGCaseNextSpawn = nil
        return
    end

    local particles = model.HGCaseParticles
    if not particles then
        particles = {}
        model.HGCaseParticles = particles
    end

    local now = CurTime()
    local delta = math.min(FrameTime(), 0.1)

    local maxParticles = data.maxParticles or 200
    local spawnTime = model.HGCaseNextSpawn or 0

    if spawnTime <= now and #particles < maxParticles then
        local catchUp = math.min(math.floor((now - spawnTime) / data.rate) + 1, 2)
        model.HGCaseNextSpawn = now + data.rate

        for _ = 1, data.burst * catchUp do
            if #particles >= maxParticles then break end

            local yaw = math.Rand(0, 360)
            local radius = math.Rand(data.spread * .2, data.spread)
            particles[#particles + 1] = {
                pos = pos + Vector(math.cos(math.rad(yaw)) * radius, math.sin(math.rad(yaw)) * radius, (data.offset or 0) + math.Rand(-1, 2)),
                vel = Vector(math.Rand(-0.5, 0.5), math.Rand(-0.5, 0.5), math.Rand(data.rise * .6, data.rise)),
                phase = math.Rand(0, math.pi * 2),
                life = 0,
                maxLife = math.Rand(data.life * .8, data.life * 1.2),
                size = math.Rand(data.size * .7, data.size * 1.15),
                rot = math.Rand(-180, 180),
                spin = math.Rand(-data.spin, data.spin)
            }
        end
    end

    render.SetMaterial(data.material)

    local eyePos = EyePos()

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life + delta

        if p.life >= p.maxLife then
            table.remove(particles, i)
        else
            local frac = p.life / p.maxLife
            p.vel.z = p.vel.z + delta * 0.35
            p.vel.x = p.vel.x * (1 - delta * 2.2)
            p.vel.y = p.vel.y * (1 - delta * 2.2)
            p.pos = p.pos + p.vel * delta
            p.rot = p.rot + p.spin * delta

            local swirl = data.swirl * (0.4 + frac)
            local drawPos = p.pos + Vector(math.sin(now * 0.75 + p.phase) * swirl, math.cos(now * 0.65 + p.phase) * swirl, 0)
            local fade = math.min(1, frac * 4) * (1 - frac) ^ 1.3
            local size = p.size * (0.7 + (1 - frac) * 0.45)
            local normal = (eyePos - drawPos):GetNormalized()

            render.DrawQuadEasy(drawPos, normal, size, size, ColorAlpha(data.color, math.Clamp(255 * fade, 0, 255)), p.rot)
        end
    end
end

local function IsValidAccessoryUID(uid)
    uid = tostring(uid or "")
    return uid ~= "" and uid ~= "none" and uid ~= "Убрать"
end

local function RemoveAccessoryModels(ent)
    if not IsValid(ent) then return end
    ent.modelAccess = ent.modelAccess or {}

    for uid, mdl in pairs(ent.modelAccess) do
        if IsValid(mdl) then
            mdl:Remove()
        end
        ent.modelAccess[uid] = nil
    end
end

local function RemoveSingleAccessoryModel(ent, uid)
    if not IsValid(ent) then return end
    ent.modelAccess = ent.modelAccess or {}

    local mdl = ent.modelAccess[uid]
    if IsValid(mdl) then
        mdl:Remove()
    end

    ent.modelAccess[uid] = nil
end

local function DecodeOwnedCoinAccessories(raw)
    if not isstring(raw) or raw == "" then return {} end

    local decoded = util.JSONToTable(raw)
    if not istable(decoded) then return {} end

    local out = {}
    for uid, has in pairs(decoded) do
        if has == true then
            out[tostring(uid)] = true
        end
    end

    return out
end

local function RefreshOTCoinCache()
    local lply = LocalPlayer()
    if not IsValid(lply) or not lply.GetMData then return end

    AP.ClientOTCoins = math.max(0, math.floor(tonumber(lply:GetMData(MDATA_OTCOIN_BALANCE_KEY, 0)) or 0))
    AP.ClientOwnedCoinAccessories = DecodeOwnedCoinAccessories(lply:GetMData(MDATA_OTCOIN_OWNED_KEY, "{}"))
end
AP.RefreshOTCoinCache = RefreshOTCoinCache

function AP.GetClientOTCoins()
    if AP.RefreshOTCoinCache then
        AP.RefreshOTCoinCache()
    end
    return AP.ClientOTCoins or 0
end

function RK_HasDonateAccessory(ply, uid)
    uid = tostring(uid or "")
    if uid == "" then return false end
    if not IsValid(ply) then return false end

    local lply = LocalPlayer()
    if not IsValid(lply) then return false end
    if ply ~= lply then return false end

    return RK_DonateAccessories[uid] == true
end

function RK_HasCoinAccessory(ply, uid)
    uid = tostring(uid or "")
    if uid == "" then return false end
    if not IsValid(ply) then return false end

    local lply = LocalPlayer()
    if not IsValid(lply) then return false end
    if ply ~= lply then return false end

    return AP.ClientOwnedCoinAccessories[uid] == true
end

function AP.ClientOwnsCoinAccessory(uid, acc)
    if not AP.IsAccessoryCoinRestricted or not AP.IsAccessoryCoinRestricted(acc) then return true end
    return RK_HasCoinAccessory(LocalPlayer(), uid)
end

function AP.RequestBuyAccessory(uid)
    uid = tostring(uid or "")
    if uid == "" then return false end

    net.Start("hg_otcoins_purchase_accessory")
        net.WriteString(uid)
    net.SendToServer()

    return true
end

function AP.ClientHasAccessoryAccess(uid, acc, ply)
    local targetPly = IsValid(ply) and ply or LocalPlayer()
    if not IsValid(targetPly) then return false end

    if acc and acc.isvip == true then
        if not targetPly.GetUserGroup or targetPly:GetUserGroup() == "user" then
            if AP.ClientOwnsCoinAccessory and AP.ClientOwnsCoinAccessory(uid, acc) then
                return true
            end
            return false
        end
    end

    if AP.GetAccessToAll and AP.GetAccessToAll(targetPly) then return true end

    if AP.IsAccessoryDonateRestricted and AP.IsAccessoryDonateRestricted(acc) then
        local shopUID = AP.GetAccessoryShopUID and AP.GetAccessoryShopUID(acc, uid) or tostring(uid or "")
        if shopUID == "" then return false end

        local lply = LocalPlayer()
        if not IsValid(lply) then return false end
        if targetPly ~= lply then return false end
        if RK_DonateAccessoriesSynced ~= true then return true end

        return RK_DonateAccessories[shopUID] == true
    end

    if AP.IsAccessoryCoinRestricted and AP.IsAccessoryCoinRestricted(acc) then
        return AP.ClientOwnsCoinAccessory and AP.ClientOwnsCoinAccessory(uid, acc) or false
    end

    return true
end

function AP.ClientSanitizeAttachments(tbl, ply, allowPreview)
    if not istable(tbl) then return {} end

    local out = {}
    local occupied = {}

    for i = 1, 5 do
        local uid = tostring(tbl[i] or "")
        if not IsValidAccessoryUID(uid) then
            out[i] = ""
            continue
        end

        local acc = hg.Accessories and hg.Accessories[uid]
        if not acc or acc.disallowinappearance then
            out[i] = ""
            continue
        end

        if not allowPreview and IsValid(ply) and ply == LocalPlayer() then
            if not AP.ClientHasAccessoryAccess(uid, acc, ply) then
                out[i] = ""
                continue
            end
        end

        if acc.placement and occupied[acc.placement] then
            out[i] = ""
            continue
        end

        if acc.placement then
            occupied[acc.placement] = true
        end

        out[i] = uid
    end

    return out
end

local function DecodeAppearanceRaw(raw)
    if not isstring(raw) or raw == "" then return nil end

    local tbl = util.JSONToTable(raw)
    if not istable(tbl) then return nil end
    if AP.AppearanceValidater and not AP.AppearanceValidater(tbl) then return nil end

    tbl.AAttachments = istable(tbl.AAttachments) and tbl.AAttachments or {}
    return tbl
end

local function SaveLocalAppearance(tbl)
    if not istable(tbl) then return end

    local copy = table.Copy(tbl)
    copy.AAttachments = istable(copy.AAttachments) and copy.AAttachments or {}

    AP.ClientSavedAppearance = copy
    AP.ClientSavedAppearanceRaw = util.TableToJSON(copy, false) or ""
end

local function GetLocalAppearanceRaw()
    local lply = LocalPlayer()

    if IsValid(lply) and lply.GetMData then
        local raw = lply:GetMData("hg_appearance_selected", "")
        if isstring(raw) and raw ~= "" then
            return raw
        end
    end

    if isstring(AP.ClientSavedAppearanceRaw) and AP.ClientSavedAppearanceRaw ~= "" then
        return AP.ClientSavedAppearanceRaw
    end

    return ""
end

function AP.CreateAppearanceFile(_, tblAppearance)
    SaveLocalAppearance(tblAppearance)
end

function AP.LoadAppearanceFile()
    local tblAppearance = DecodeAppearanceRaw(GetLocalAppearanceRaw()) or AP.ClientSavedAppearance
    if not istable(tblAppearance) then
        return false, "appearance_not_found"
    end

    if AP.AppearanceValidater and not AP.AppearanceValidater(tblAppearance) then
        return false, "appearance_invalid"
    end

    tblAppearance = table.Copy(tblAppearance)
    tblAppearance.AAttachments = istable(tblAppearance.AAttachments) and tblAppearance.AAttachments or {}
    return tblAppearance
end

function AP.GetAppearanceList()
    return { AP.ActivePresetName .. ".json" }
end

timer.Simple(0.1, function()
netstream.Hook("rk_donate_accs_sync", function(data)
    RK_DonateAccessories = {}
    RK_DonateAccessoriesSynced = true

    local lply = LocalPlayer()

    if istable(data) and istable(data.items) then
        for uid, has in pairs(data.items) do
            if has == true then
                RK_DonateAccessories[tostring(uid)] = true
            end
        end
    end

    if IsValid(lply) and IsValid(lply.FakeRagdoll) then
        RemoveAccessoryModels(lply.FakeRagdoll)
    end

    if IsValid(lply) then
        RemoveAccessoryModels(lply)

        local tbl = AP.LoadAppearanceFile()
        if istable(tbl) then
            net.Start("OnlyGet_Appearance")
                net.WriteTable(tbl)
            net.SendToServer()
        end
    end
end)
end)

local function SendAppearanceToServer(netMessage, allowRandomFallback)
    local tbl, reason = AP.LoadAppearanceFile()

    if not tbl and allowRandomFallback ~= true then
        tbl = {}
    end

    net.Start(netMessage)
        net.WriteTable(tbl or {})
        if netMessage == "Get_Appearance" then
            net.WriteBool(not istable(tbl))
        end
    net.SendToServer()

    if not tbl and IsValid(LocalPlayer()) then
        LocalPlayer():ChatPrint("[Внешность] не удалось загрузить внешний вид: " .. tostring(reason))
    end
end

net.Receive("Get_Appearance", function()
    SendAppearanceToServer("Get_Appearance", true)
end)

net.Receive("OnlyGet_Appearance", function()
    SendAppearanceToServer("OnlyGet_Appearance", false)
end)

net.Receive("hg_appearance_presets_sync", function()
    local presets = net.ReadTable()
    if not istable(presets) then return end
    if next(presets) == nil and next(AP.PresetsCache or {}) ~= nil then return end
    AP.PresetsCache = presets
end)

net.Receive("hg_otcoins_purchase_result", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    local uid = net.ReadString()
    AP.ClientOTCoins = math.max(0, net.ReadInt(32) or 0)

    if success and uid ~= "" then
        AP.ClientOwnedCoinAccessories[tostring(uid)] = true
    end

    if message ~= "" then
        if notification and notification.AddLegacy then
            notification.AddLegacy(message, success and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
        end

        local lply = LocalPlayer()
        if IsValid(lply) then
            lply:ChatPrint(message)
        end
    end
end)

hook.Add("InitPostEntity", "hg.Appearance.RequestPresetsSync", function()
    net.Start("hg_appearance_presets_request")
    net.SendToServer()
end)

timer.Simple(1, function()
    if not (mdata and mdata.AddCallback) then return end

    mdata.AddCallback("hg_appearance_selected", function(ply, val)
        if ply ~= LocalPlayer() then return end

        local tbl = DecodeAppearanceRaw(val)
        if istable(tbl) then
            SaveLocalAppearance(tbl)
        end
    end)

    mdata.AddCallback("hg_appearance_presets", function(ply, val)
        if ply ~= LocalPlayer() then return end

        local decoded = util.JSONToTable(tostring(val or "")) or {}
        if not istable(decoded) then
            AP.PresetsCache = {}
            return
        end

        AP.PresetsCache = decoded
    end)

    mdata.AddCallback(MDATA_OTCOIN_BALANCE_KEY, function(ply, val)
        if ply ~= LocalPlayer() then return end
        AP.ClientOTCoins = math.max(0, math.floor(tonumber(val) or 0))
    end)

    mdata.AddCallback(MDATA_OTCOIN_OWNED_KEY, function(ply, val)
        if ply ~= LocalPlayer() then return end
        AP.ClientOwnedCoinAccessories = DecodeOwnedCoinAccessories(tostring(val or "{}"))
    end)

    timer.Simple(0.25, RefreshOTCoinCache)
end)

local function GetRenderOwner(ent)
    local lply = LocalPlayer()
    if not IsValid(lply) then return nil, nil end

    local viewPly = lply:Alive() and lply or lply:GetNWEntity("spect", lply)
    local owner = ent

    if IsValid(ent) and ent.IsRagdoll and ent:IsRagdoll() and hg.RagdollOwner then
        owner = hg.RagdollOwner(ent) or ent
    end

    return owner, viewPly
end

local function ResolveAppearanceOwner(ent, fallback)
    if IsValid(ent) and ent:IsPlayer() then
        return ent
    end

    if IsValid(ent) and ent.IsRagdoll and ent:IsRagdoll() and hg.RagdollOwner then
        local owner = hg.RagdollOwner(ent)
        if IsValid(owner) then
            return owner
        end
    end

    if IsValid(fallback) and fallback:IsPlayer() then
        return fallback
    end

    return fallback
end

local function IsLocalRenderEntity(ent)
    local owner, viewPly = GetRenderOwner(ent)
    return IsValid(owner) and IsValid(viewPly) and owner == viewPly and GetViewEntity() == viewPly
end

local function CanRenderAccessories(owner, ent)
    if not IsValid(owner) or not IsValid(ent) then
        RemoveAccessoryModels(ent)
        return false
    end

    local wep = owner:IsPlayer() and owner:GetActiveWeapon() or nil
    if IsLocalRenderEntity(ent) and IsValid(wep) and weaponWhitelist[wep:GetClass()] then
        RemoveAccessoryModels(ent)
        return false
    end

    if ent.shouldTransmit == false or ent.NotSeen then
        RemoveAccessoryModels(ent)
        return false
    end

    return true
end

local function IterateAccessories(accessories, fn)
    if not accessories or accessories == "none" then return end

    if istable(accessories) then
        for i = 1, 5 do
            fn(accessories[i], i)
        end
        return
    end

    fn(accessories, 1)
end

local function ShouldAllowPreviewRender(owner, force)
    if force ~= true then return false end
    if not IsValid(owner) then return false end
    if owner:IsPlayer() then return false end
    return true
end

local function AccessoryEntityBelongsToOwner(owner, ent)
    if not IsValid(owner) or not IsValid(ent) then return false end
    if ent == owner then return true end
    if ent:IsPlayer() then return false end

    if ent.IsRagdoll and ent:IsRagdoll() then
        if hg.RagdollOwner then
            local ragdollOwner = hg.RagdollOwner(ent)
            if IsValid(ragdollOwner) then
                return ragdollOwner == owner
            end
        end

        if owner.GetRagdollEntity then
            local ownerRagdoll = owner:GetRagdollEntity()
            if IsValid(ownerRagdoll) then
                return ownerRagdoll == ent
            end
        end
    end

    return true
end

local function AccessoryEquippedOn(ent, accessoryID)
    if not IsValid(ent) or not ent.GetNetVar then return true end

    local accessories = ent:GetNetVar("Accessories")
    if accessories == nil then
        accessories = ent.PredictedAccessories
    end

    if accessories == nil then return true end
    if accessories == "none" then return false end

    if istable(accessories) then
        for i = 1, 5 do
            if tostring(accessories[i] or "") == accessoryID then return true end
        end
        return false
    end

    return tostring(accessories) == accessoryID
end

local function ApplyAccessoryBodygroups(model, accessData, ent)
    if not IsValid(model) then return end

    local groups = accessData.bodygroups
    if isfunction(groups) then
        groups = groups(ent)
    end

    if groups == nil or groups == "" then
        model.HGBodygroupsApplied = true
        return
    end

    local count = model:GetNumBodyGroups() or 0
    if count <= 0 then
        model.HGBodygroupsApplied = false
        return
    end

    local applied = false

    if istable(groups) then
        for id, value in pairs(groups) do
            id = tonumber(id)
            value = tonumber(value)
            if id and value and id >= 0 and id < count then
                local options = model:GetBodygroupCount(id) or 1
                if options > 1 then
                    model:SetBodygroup(id, math.Clamp(value, 0, options - 1))
                    applied = true
                end
            end
        end

        model.HGBodygroupsApplied = applied
        return
    end

    groups = tostring(groups)

    for i = 1, #groups do
        local value = tonumber(groups:sub(i, i))
        local id = i - 1
        if value and id < count then
            local options = model:GetBodygroupCount(id) or 1
            if options > 1 then
                model:SetBodygroup(id, math.Clamp(value, 0, options - 1))
                applied = true
            end
        end
    end

    if not applied and #groups <= 2 then
        local value = tonumber(groups)
        if value then
            for id = 0, count - 1 do
                local options = model:GetBodygroupCount(id) or 1
                if options > 1 then
                    model:SetBodygroup(id, math.Clamp(value, 0, options - 1))
                    applied = true
                    break
                end
            end
        end
    end

    model.HGBodygroupsApplied = applied
end

function DrawAccesories(owner, ent, accessoryID, accessData, isLocal, force, setup)
    if not IsValid(owner) or not IsValid(ent) then return end
    if not IsValidAccessoryUID(accessoryID) then
        RemoveSingleAccessoryModel(ent, accessoryID)
        return
    end
    if not istable(accessData) then
        RemoveSingleAccessoryModel(ent, accessoryID)
        return
    end

    local previewRender = ShouldAllowPreviewRender(owner, force)
    local realOwner = ResolveAppearanceOwner(ent, owner)

    if not previewRender then
        if not AccessoryEntityBelongsToOwner(realOwner, ent) then
            RemoveSingleAccessoryModel(ent, accessoryID)
            return
        end

        if not AccessoryEquippedOn(ent, accessoryID) then
            RemoveSingleAccessoryModel(ent, accessoryID)
            return
        end

        if IsValid(realOwner) and realOwner:IsPlayer() and ent == realOwner and not realOwner:Alive() then
            RemoveSingleAccessoryModel(ent, accessoryID)
            return
        end
    end

    if not previewRender and IsValid(realOwner) and realOwner == LocalPlayer() then
        if AP.ClientHasAccessoryAccess and not AP.ClientHasAccessoryAccess(accessoryID, accessData, realOwner) then
            RemoveSingleAccessoryModel(ent, accessoryID)
            return
        end
    end

    ent.modelAccess = ent.modelAccess or {}

    local fem = ThatPlyIsFemale(ent)
    local posData = accessData[fem and "fempos" or "malepos"]
    if not posData then
        RemoveSingleAccessoryModel(ent, accessoryID)
        return
    end

    local model = ent.modelAccess[accessoryID]
    if not IsValid(model) then
        local mdl = fem and accessData.femmodel or accessData.model
        if not mdl then return end

        model = ClientsideModel(mdl, RENDERGROUP_BOTH)
        if not IsValid(model) then return end

        ent.modelAccess[accessoryID] = model
        model:SetNoDraw(true)
        model:SetModelScale(posData[3] or 1, 0)
        model:SetSkin(isfunction(accessData.skin) and accessData.skin(ent) or (accessData.skin or 0))
        ApplyAccessoryBodygroups(model, accessData, ent)
        model:SetParent(ent, ent:LookupBone(accessData.bone) or 0)

        if accessData.bonemerge then
            model:AddEffects(EF_BONEMERGE)
        end

        if accessData.bSetColor then
            local clr = owner.GetPlayerColor and owner:GetPlayerColor() or owner:GetNWVector("PlayerColor", Vector(1, 1, 1))
            model:SetColor(clr:ToColor())
        end

        if accessData.SubMat then
            model:SetSubMaterial(0, accessData.SubMat)
        end

        owner:CallOnRemove("RemoveAccessoriesOwner." .. accessoryID .. "." .. ent:EntIndex(), function()
            if IsValid(model) then
                model:Remove()
            end
        end)

        ent:CallOnRemove("RemoveAccessoriesEntity." .. accessoryID .. "." .. ent:EntIndex(), function()
            if IsValid(model) then
                model:Remove()
            end
            if istable(ent.modelAccess) then
                ent.modelAccess[accessoryID] = nil
            end
        end)
    end

    if not IsValid(model) then
        ent.modelAccess[accessoryID] = nil
        return
    end

    local entModel = ent:GetModel() or ""
    local split = string.Explode("/", string.sub(entModel, 1, -5))
    local mdlFlex = split[#split]
    local flexID = mdlFlex and model:GetFlexIDByName(mdlFlex) or nil
    if flexID and flexID >= 0 then
        model:SetFlexWeight(flexID, 1)
    end

    model:SetSkin(isfunction(accessData.skin) and accessData.skin(ent) or (accessData.skin or 0))

    if model.HGBodygroupsApplied ~= true then
        ApplyAccessoryBodygroups(model, accessData, ent)
    end

    if owner.armors and accessData.placement and owner.armors[accessData.placement] then return end
    if not force and ((ent.NotSeen or ent.shouldTransmit == false) or (IsValid(realOwner) and realOwner:IsPlayer() and not realOwner:Alive() and ent == realOwner)) then
        model.HGCaseParticles = nil
        model.HGCaseNextSpawn = nil
        return
    end

    local bone = ent:LookupBone(accessData.bone)
    if setup ~= false then
        if not bone then return end
        if ent:GetManipulateBoneScale(bone):LengthSqr() < 0.1 then return end

        local matrix = ent:GetBoneMatrix(bone)
        if not matrix then return end

        local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
        local addVec = ((ent:GetModel() == "models/player/group01/male_06.mdl") and (accessData.placement == "head" or accessData.placement == "face")) and specialMaleOffset or vector_origin
        local pos, ang = LocalToWorld(posData[1], posData[2], bonePos, boneAng)
        pos = LocalToWorld(addVec, angle_zero, pos, ang)
        if accessData.caseEffect == "crown" then
            local time = CurTime()
            pos = pos + Vector(0, 0, 8 + math.sin(time * 1.8 + ent:EntIndex()) * 1.6)
            ang:RotateAroundAxis(ang:Up(), time * 34)
        end
        model.HGCaseEffectPosition = pos

        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
    end

    if bone and model:GetParent() ~= ent then
        model:SetParent(ent, bone)
    end

    if not (isLocal and accessData.norender) and (not setup or accessData.bonemerge) then
        if accessData.bSetColor then
            local clr = accessData.vecColorOveride or (owner.GetPlayerColor and owner:GetPlayerColor() or owner:GetNWVector("PlayerColor", Vector(1, 1, 1)))
            render.SetColorModulation(clr[1], clr[2], clr[3])
        end

        model:DrawModel()
        if accessData.caseEffect then DrawCaseAccessoryEffect(accessData.caseEffect, model, model.HGCaseEffectPosition or model:GetPos()) end

        if accessData.bSetColor then
            render.SetColorModulation(1, 1, 1)
        end
    end
end

local function RenderAccessoriesInternal(owner, ent, accessories, setup, coolOnly)
    if not IsValid(owner) or not IsValid(ent) or not accessories or accessories == "none" then return end
    if not CanRenderAccessories(owner, ent) then return end

    local isLocal = IsLocalRenderEntity(ent)

    IterateAccessories(accessories, function(accessoryID)
        if not IsValidAccessoryUID(accessoryID) then
            return
        end

        local accessData = hg.Accessories and hg.Accessories[accessoryID]
        if not accessData then
            RemoveSingleAccessoryModel(ent, accessoryID)
            return
        end

        if IsValid(owner) and owner == LocalPlayer() then
            if AP.ClientHasAccessoryAccess and not AP.ClientHasAccessoryAccess(accessoryID, accessData, owner) then
                RemoveSingleAccessoryModel(ent, accessoryID)
                return
            end
        end

        if coolOnly then
            if not accessData.needcoolRender then return end
        else
            if accessData.needcoolRender then return end
        end

        DrawAccesories(owner, ent, accessoryID, accessData, isLocal, nil, setup)
    end)
end

function RenderAccessories(owner, ent, accessories, setup)
    RenderAccessoriesInternal(owner, ent, AP.ClientSanitizeAttachments(accessories, owner, false), setup, false)
end

function CoolRenderAccessories(owner, ent, accessories)
    RenderAccessoriesInternal(owner, ent, AP.ClientSanitizeAttachments(accessories, owner, false), nil, true)
end

function DrawAppearance(ent, ply, setup)
    if not IsValid(ent) then return end

    local owner = ResolveAppearanceOwner(ent, ply)
    if not IsValid(owner) then return end

    local accessories = ent:GetNetVar("Accessories") or ent.PredictedAccessories
    if accessories then
        RenderAccessories(owner, ent, accessories, setup)
    end

    if setup or not owner:IsPlayer() then return end

    local inv = owner:GetNetVar("Inventory", {})
    if not inv.Weapons or not inv.Weapons.hg_flashlight then
        if IsValid(owner.flashlight) then
            owner.flashlight:Remove()
        end
        if IsValid(owner.flmodel) then
            owner.flmodel:Remove()
        end
        owner.flashlight = nil
        owner.flmodel = nil
        return
    end

    local wep = owner:GetActiveWeapon()
    local flashlightWeaponBlocked = false

    if IsValid(wep) then
        local underbarrel = wep.attachments and wep.attachments.underbarrel
        local attachmentData

        if (underbarrel and not table.IsEmpty(underbarrel)) or wep.laser then
            attachmentData = (underbarrel and not table.IsEmpty(underbarrel)) and hg.attachments.underbarrel[underbarrel[1]] or wep.laserData
        end

        if attachmentData then
            flashlightWeaponBlocked = attachmentData.supportFlashlight
        end
    end

    if IsValid(owner.flmodel) then
        owner.flmodel:SetNoDraw(not (owner:GetNetVar("flashlight") and (not wep.IsPistolHoldType or wep:IsPistolHoldType())) or wep.reload or flashlightWeaponBlocked)
    end

    if owner:GetNetVar("flashlight") and not flashlightWeaponBlocked and (not wep.IsPistolHoldType or wep:IsPistolHoldType() or owner.PlayerClassName == "Gordon") and not wep.reload and hg.CanUseLeftHand(owner) then
        local hand = ent:LookupBone("ValveBiped.Bip01_L_Hand")
        if not hand then return end

        local handMat = ent:GetBoneMatrix(hand)
        if not handMat then return end

        local pos, ang = handMat:GetTranslation(), handMat:GetAngles()
        pos, ang = LocalToWorld(leftHandOffsetPos, leftHandOffsetAng, pos, ang)

        owner.flmodel = IsValid(owner.flmodel) and owner.flmodel or ClientsideModel("models/runaway911/props/item/flashlight.mdl")
        if not IsValid(owner.flmodel) then return end

        owner.flmodel:SetModelScale(0.75, 0)

        if ent ~= owner then
            pos = handMat:GetTranslation()
        end

        pos = LocalToWorld(flashlightOffsetPos, flashlightOffsetAng, pos, handMat:GetAngles())
        owner.flmodel:SetRenderOrigin(pos)
        owner.flmodel:SetRenderAngles(ang)
        owner.flmodel:DrawModel()

        owner.flashlight = IsValid(owner.flashlight) and owner.flashlight or ProjectedTexture()
        if owner.flashlight and owner.flashlight:IsValid() and (owner.FlashlightUpdateTime or 0) < CurTime() then
            local flash = owner.flashlight
            owner.FlashlightUpdateTime = CurTime() + 0.01
            flash:SetTexture(flashlightMat:GetTexture("$basetexture"))
            flash:SetFarZ(1500)
            flash:SetHorizontalFOV(60)
            flash:SetVerticalFOV(60)
            flash:SetConstantAttenuation(0.1)
            flash:SetLinearAttenuation(50)
            flash:SetPos(owner.flmodel:GetPos() + owner.flmodel:GetAngles():Forward() * (owner:GetVelocity():Length() / 10 + 15))
            flash:SetAngles(owner.flmodel:GetAngles())
            flash:Update()
        end

        local view = render.GetViewSetup(true)
        local deg = owner.flmodel:GetAngles():Forward():Dot(view.angles:Forward())
        deg = -math.ease.InBack(-deg + 0.05) * 2

        local trace = util.TraceLine({
            start = owner.flmodel:GetPos() + owner.flmodel:GetAngles():Forward() * 6,
            endpos = view.origin,
            filter = {owner, ent, owner.flmodel, LocalPlayer()},
            mask = MASK_VISIBLE
        })

        if deg < 0 and not trace.Hit then
            render.SetMaterial(glowMat)
            render.DrawSprite(
                owner.flmodel:GetPos() + owner.flmodel:GetAngles():Forward() * 5 + owner.flmodel:GetAngles():Right() * -0.5,
                50 * math.min(deg, 0),
                50 * math.min(deg, 0),
                color_white
            )
        end
    else
        if IsValid(owner.flashlight) then
            owner.flashlight:Remove()
        end
        owner.flashlight = nil
    end
end

hook.Add("RenderScreenspaceEffects", "hg.Appearance.ScreenSpaceAccessories", function()
    local lply = LocalPlayer()
    if not IsValid(lply) or not lply:Alive() or lply:GetViewEntity() ~= lply then return end

    local accessories = AP.ClientSanitizeAttachments(lply:GetNetVar("Accessories", "none"), lply, false)
    IterateAccessories(accessories, function(accessoryID)
        if not IsValidAccessoryUID(accessoryID) then return end

        local accessData = hg.Accessories and hg.Accessories[accessoryID]
        if not accessData then return end
        if not AP.ClientHasAccessoryAccess or not AP.ClientHasAccessoryAccess(accessoryID, accessData, lply) then return end
        if lply.armors and accessData.placement and lply.armors[accessData.placement] then return end

        if accessData.ScreenSpaceEffects then
            accessData.ScreenSpaceEffects()
        end
    end)
end)

function RenderAccessoriesCool(ent, ply)
    if not IsValid(ent) then return end
    local owner = ResolveAppearanceOwner(ent, ply)
    if not IsValid(owner) then return end

    local accessories = ent:GetNetVar("Accessories", "none")
    if accessories then
        CoolRenderAccessories(owner, ent, accessories)
    end
end
