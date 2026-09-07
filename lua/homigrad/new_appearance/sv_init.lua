util.AddNetworkString("Get_Appearance")
util.AddNetworkString("OnlyGet_Appearance")
util.AddNetworkString("hg_appearance_presets_request")
util.AddNetworkString("hg_appearance_presets_sync")
util.AddNetworkString("hg_appearance_preset_save")
util.AddNetworkString("hg_appearance_preset_delete")
util.AddNetworkString("hg_otcoins_purchase_accessory")
util.AddNetworkString("hg_otcoins_purchase_result")

hg.Appearance = hg.Appearance or {}

local AP = hg.Appearance

local MDATA_APPEARANCE_KEY = "hg_appearance_selected"
local MDATA_PRESETS_KEY = "hg_appearance_presets"
local MDATA_OTCOIN_BALANCE_KEY = AP.OTCoin and AP.OTCoin.BalanceKey or "hg_otcoins_balance"
local MDATA_OTCOIN_OWNED_KEY = AP.OTCoin and AP.OTCoin.OwnedAccessoriesKey or "hg_otcoins_owned_accessories"
local MDATA_OTCOIN_MIGRATED_KEY = AP.OTCoin and AP.OTCoin.OwnedAccessoriesMigratedKey or "hg_otcoins_owned_accessories_migrated"

local tWaitResponse = {}

local DONATE_RESTORE_GRACE = 20

local BLOCKED_APPEARANCE_MODELS = {
    ["models/dih/wednesday.mdl"] = true,
    ["models/mug/ncfom/anton_chigurh.mdl"] = true,
    ["models/charliekirk/charliekirk_pm.mdl"] = true,
    ["models/splinks/hotline_miami/jacket/drive/player_jacket_drive.mdl"] = true,
    ["models/sheepylord/grok/ani.mdl"] = true,

    ["models/models/ferrari_leclerc/ferrari_leclerc.mdl"] = true,
    ["models/panman/arc_future.mdl"] = true,
    ["models/postal1_dude.mdl"] = true,
}

local function IsAppearanceBlockedModel(mdl)
    if not isstring(mdl) or mdl == "" then return false end
    mdl = string.lower(mdl)
    if BLOCKED_APPEARANCE_MODELS[mdl] == true then return true end
    if OTCDonate and isfunction(OTCDonate.IsManagedModel) and OTCDonate.IsManagedModel(mdl) then return true end
    return false
end

local function CanUseMData(ply)
    return IsValid(ply) and mdata and isfunction(mdata.IsLoaded) and mdata:IsLoaded(ply) and isfunction(ply.SetMData) and isfunction(ply.GetMData)
end

local function StartDonateRestoreGrace(ply, duration)
    if not IsValid(ply) then return end

    local graceTime = CurTime() + math.max(duration or DONATE_RESTORE_GRACE, 0)
    ply.hgAppearanceDonateRestoreGrace = math.max(tonumber(ply.hgAppearanceDonateRestoreGrace) or 0, graceTime)
end

local function IsDonateRestoreGraceActive(ply)
    return IsValid(ply) and (tonumber(ply.hgAppearanceDonateRestoreGrace) or 0) > CurTime()
end

local function EncodeAppearance(tbl)
    if not istable(tbl) then return "" end
    return util.TableToJSON(tbl, false) or ""
end

local function DecodeAppearance(raw)
    if not isstring(raw) or raw == "" then return nil end

    local tbl = util.JSONToTable(raw)
    if not istable(tbl) then return nil end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(tbl) then return nil end

    return tbl
end

local function GetAppearanceModel(tbl)
    if not istable(tbl) then return nil, nil end

    local modelKey = tbl.AModel
    local tMdl = AP.PlayerModels[1][modelKey] or AP.PlayerModels[2][modelKey] or modelKey
    local mdl = istable(tMdl) and tMdl.mdl or tMdl

    if not isstring(mdl) or mdl == "" then
        return tMdl, nil
    end

    return tMdl, mdl
end

function AP.GetModelPathFromAppearance(tbl)
    local _, mdl = GetAppearanceModel(tbl)
    return mdl
end

local function GetAppearanceSex(tbl)
    local tMdl = AP.PlayerModels[1][tbl.AModel] or AP.PlayerModels[2][tbl.AModel]
    if istable(tMdl) and tMdl.sex then
        return 2
    end
    return 1
end

local function GetSavedAppearanceFromMData(ply)
    if not CanUseMData(ply) then return nil end
    return DecodeAppearance(ply:GetMData(MDATA_APPEARANCE_KEY, ""))
end

local function GetSavedPresetsFromMData(ply)
    if not CanUseMData(ply) then return {} end

    local raw = ply:GetMData(MDATA_PRESETS_KEY, "")
    if not isstring(raw) or raw == "" then
        return {}
    end

    local decoded = util.JSONToTable(raw)
    if not istable(decoded) then
        return {}
    end

    local presets = {}
    for name, appearance in pairs(decoded) do
        name = string.Trim(tostring(name or ""))
        if name ~= "" and istable(appearance) then
            presets[name] = appearance
        end
    end

    return presets
end

local function SavePresetsToMData(ply, presets)
    if not CanUseMData(ply) then return end

    local sanitized = {}
    if istable(presets) then
        for name, appearance in pairs(presets) do
            name = string.Trim(tostring(name or ""))
            if name ~= "" and istable(appearance) then
                sanitized[name] = appearance
            end
        end
    end

    ply:SetMData(MDATA_PRESETS_KEY, util.TableToJSON(sanitized, false) or "{}")
end

local function SyncPresetsToClient(ply)
    if not IsValid(ply) or not CanUseMData(ply) then return end

    net.Start("hg_appearance_presets_sync")
        net.WriteTable(GetSavedPresetsFromMData(ply))
    net.Send(ply)
end

local function SaveAppearanceToMData(ply, appearance)
    if not IsValid(ply) or not istable(appearance) then return false end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return false end

    if not CanUseMData(ply) then
        ply.hgAppearancePendingSave = table.Copy(appearance)
        return false
    end

    ply:SetMData(MDATA_APPEARANCE_KEY, EncodeAppearance(appearance))
    return true
end

local function NormalizePresetName(name)
    name = string.Trim(tostring(name or ""))
    if name == "" or not utf8.len(name) then return "" end
    return utf8.sub(name, 1, 32)
end

local function QueuePresetOperation(ply, operation)
    if not IsValid(ply) or not istable(operation) then return end
    ply.hgAppearancePendingPresetOperations = ply.hgAppearancePendingPresetOperations or {}
    ply.hgAppearancePendingPresetOperations[#ply.hgAppearancePendingPresetOperations + 1] = operation
end

local function FlushPendingAppearanceData(ply)
    if not CanUseMData(ply) then return false end

    local changed = false
    if istable(ply.hgAppearancePendingSave) then
        local appearance = ply.hgAppearancePendingSave
        ply.hgAppearancePendingSave = nil
        SaveAppearanceToMData(ply, appearance)
        changed = true
    end

    local operations = ply.hgAppearancePendingPresetOperations
    if istable(operations) and #operations > 0 then
        local presets = GetSavedPresetsFromMData(ply)
        for _, operation in ipairs(operations) do
            if operation.kind == "save" and operation.name and istable(operation.appearance) then
                presets[operation.name] = operation.appearance
            elseif operation.kind == "delete" and operation.name then
                presets[operation.name] = nil
            end
        end
        ply.hgAppearancePendingPresetOperations = nil
        SavePresetsToMData(ply, presets)
        changed = true
    end

    if changed then SyncPresetsToClient(ply) end
    return changed
end

timer.Create("hg.Appearance.FlushPendingMData", 0.5, 0, function()
    for _, ply in player.Iterator() do
        if IsValid(ply) then FlushPendingAppearanceData(ply) end
    end
end)

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

local function EncodeOwnedCoinAccessories(map)
    local out = {}
    if istable(map) then
        for uid, has in pairs(map) do
            if has == true then
                out[tostring(uid)] = true
            end
        end
    end

    return util.TableToJSON(out, false) or "{}"
end

local function GetOTCoinBalance(ply)
    if not CanUseMData(ply) then return 0 end
    return math.max(0, math.floor(tonumber(ply:GetMData(MDATA_OTCOIN_BALANCE_KEY, 0)) or 0))
end

local function SetOTCoinBalance(ply, amount)
    if not CanUseMData(ply) then return false end
    ply:SetMData(MDATA_OTCOIN_BALANCE_KEY, math.max(0, math.floor(tonumber(amount) or 0)))
    return true
end

local function AddOTCoins(ply, amount, reason, silent)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not CanUseMData(ply) then return false, GetOTCoinBalance(ply) end

    local balance = GetOTCoinBalance(ply) + amount
    SetOTCoinBalance(ply, balance)

    if not silent and IsValid(ply) then
        ply:ChatPrint("[OT-Coin] +" .. amount .. " " .. tostring(reason or "") .. ". Баланс: " .. balance)
    end

    return true, balance
end

local function TakeOTCoins(ply, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not CanUseMData(ply) then return false, GetOTCoinBalance(ply) end

    local balance = math.max(0, GetOTCoinBalance(ply) - amount)
    SetOTCoinBalance(ply, balance)
    return true, balance
end

local function GetOwnedCoinAccessories(ply)
    if not CanUseMData(ply) then return {} end
    return DecodeOwnedCoinAccessories(ply:GetMData(MDATA_OTCOIN_OWNED_KEY, "{}"))
end

local function SetOwnedCoinAccessories(ply, map)
    if not CanUseMData(ply) then return false end
    ply:SetMData(MDATA_OTCOIN_OWNED_KEY, EncodeOwnedCoinAccessories(map))
    return true
end

local function GrantCoinAccessory(ply, uid)
    uid = tostring(uid or "")
    if uid == "" then return false end

    local owned = GetOwnedCoinAccessories(ply)
    owned[uid] = true
    SetOwnedCoinAccessories(ply, owned)
    return true
end

function RK_HasCoinAccessory(ply, uid)
    uid = tostring(uid or "")
    if uid == "" then return false end
    if not IsValid(ply) then return false end
    if AP.GetAccessToAll and AP.GetAccessToAll(ply) then return true end

    local acc = hg.Accessories and hg.Accessories[uid]
    if AP.IsAccessoryCoinRestricted and not AP.IsAccessoryCoinRestricted(acc) then
        return true
    end

    local owned = GetOwnedCoinAccessories(ply)
    return owned[uid] == true
end
_G.RK_HasCoinAccessory = RK_HasCoinAccessory

local function EnsureOTCoinDataReady(ply)
    if not CanUseMData(ply) then return false end

    SetOTCoinBalance(ply, GetOTCoinBalance(ply))

    local owned = GetOwnedCoinAccessories(ply)
    if not ply:GetMData(MDATA_OTCOIN_MIGRATED_KEY, false) then
        local appearance = GetSavedAppearanceFromMData(ply)
        if istable(appearance) and istable(appearance.AAttachments) then
            for i = 1, 5 do
                local uid = tostring(appearance.AAttachments[i] or "")
                local acc = hg.Accessories and hg.Accessories[uid]
                if uid ~= "" and acc and AP.IsAccessoryCoinRestricted and AP.IsAccessoryCoinRestricted(acc) then
                    owned[uid] = true
                end
            end
        end

        SetOwnedCoinAccessories(ply, owned)
        ply:SetMData(MDATA_OTCOIN_MIGRATED_KEY, true)
    elseif ply:GetMData(MDATA_OTCOIN_OWNED_KEY, "") == "" then
        SetOwnedCoinAccessories(ply, owned)
    end

    return true
end

function RK_GiveCoinAccessory(ply, uid)
    if not IsValid(ply) then return false end
    EnsureOTCoinDataReady(ply)
    return GrantCoinAccessory(ply, uid)
end
_G.RK_GiveCoinAccessory = RK_GiveCoinAccessory

local function SendOTCoinPurchaseResult(ply, success, message, uid)
    if not IsValid(ply) then return end

    net.Start("hg_otcoins_purchase_result")
        net.WriteBool(success == true)
        net.WriteString(tostring(message or ""))
        net.WriteString(tostring(uid or ""))
        net.WriteInt(GetOTCoinBalance(ply), 32)
    net.Send(ply)
end

AP.AddOTCoins = AddOTCoins
AP.GetOTCoinBalance = GetOTCoinBalance

local function NormalizeAttachmentUID(uid)
    uid = tostring(uid or "")
    if uid == "none" or uid == "Убрать" then
        return ""
    end
    return uid
end

local function SanitizeAttachmentsForPlayer(ply, appearance, preserveDonateDuringGrace)
    appearance.AAttachments = istable(appearance.AAttachments) and appearance.AAttachments or {}

    local result = {}
    local occupied = {}

    for i = 1, 5 do
        local uid = NormalizeAttachmentUID(appearance.AAttachments[i])
        if uid == "" then
            result[i] = ""
            continue
        end

        local acc = hg.Accessories and hg.Accessories[uid]
        if not acc or acc.disallowinappearance then
            result[i] = ""
            continue
        end

        if acc.placement and occupied[acc.placement] then
            result[i] = ""
            continue
        end

        if not CanUseMData(ply) then
            result[i] = uid
            if acc.placement then
                occupied[acc.placement] = true
            end
            continue
        end

        if acc.donateOnly == true and preserveDonateDuringGrace and IsDonateRestoreGraceActive(ply) then
            result[i] = uid
            if acc.placement then
                occupied[acc.placement] = true
            end
            continue
        end

        if AP.PlayerHasAccessoryAccess and not AP.PlayerHasAccessoryAccess(ply, uid, acc) then
            result[i] = ""
            continue
        end

        if acc.placement then
            occupied[acc.placement] = true
        end

        result[i] = uid
    end

    appearance.AAttachments = result
end

local function ApplyAppearanceAccessoriesOnly(ply, appearance)
    if not IsValid(ply) then return false end

    appearance = appearance or ply.CurAppearance or ply.CachedAppearance or GetSavedAppearanceFromMData(ply)

    if not istable(appearance) then return false end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return false end

    local copy = table.Copy(appearance)

    SanitizeAttachmentsForPlayer(ply, copy, IsDonateRestoreGraceActive(ply))

    ply:SetNWString("PlayerName", tostring(copy.AName or ply:GetNWString("PlayerName", "")))
    ply:SetNetVar("Accessories", copy.AAttachments or {})

    ply.CurAppearance = table.Copy(copy)
    ply.CachedAppearance = table.Copy(copy)

    return true
end

AP.ApplyAppearanceAccessoriesOnly = ApplyAppearanceAccessoriesOnly

local function RestoreSavedAccessoriesOnly(ply, appearance)
    if not IsValid(ply) then return false end
    if not istable(appearance) then return false end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return false end

    local copy = table.Copy(appearance)
    SanitizeAttachmentsForPlayer(ply, copy, IsDonateRestoreGraceActive(ply))

    ply:SetNetVar("Accessories", copy.AAttachments or {})

    ply.CachedAppearance = ply.CachedAppearance or {}
    if istable(ply.CachedAppearance) then
        ply.CachedAppearance.AAttachments = table.Copy(copy.AAttachments or {})
    end

    if istable(ply.CurAppearance) then
        ply.CurAppearance.AAttachments = table.Copy(copy.AAttachments or {})
    end

    return true
end

AP.RestoreSavedAccessoriesOnly = RestoreSavedAccessoriesOnly

local function SanitizeBodygroupsForPlayer(ply, appearance, preserveDonateDuringGrace)
    appearance.ABodygroups = istable(appearance.ABodygroups) and appearance.ABodygroups or {}

    local sex = GetAppearanceSex(appearance)
    local sanitized = {}

    for groupName, selectedName in pairs(appearance.ABodygroups) do
        if not isstring(groupName) or not isstring(selectedName) then
            continue
        end

        local sexTable = AP.Bodygroups[groupName] and AP.Bodygroups[groupName][sex]
        local row = sexTable and sexTable[selectedName] or nil
        if not row then
            continue
        end

        local fakeAcc = {
            donateOnly = row[2] == true,
            ID = tostring(row.ID or ""),
            DonateID = tostring(row.DonateID or row.ID or "")
        }

        if fakeAcc.donateOnly and fakeAcc.DonateID ~= "" then
            if CanUseMData(ply) and not (preserveDonateDuringGrace and IsDonateRestoreGraceActive(ply)) then
                if AP.PlayerHasAccessoryAccess and not AP.PlayerHasAccessoryAccess(ply, fakeAcc.DonateID, fakeAcc) then
                    continue
                end
            end
        end

        sanitized[groupName] = selectedName
    end

    appearance.ABodygroups = sanitized
end

local function SanitizeClothesForModel(appearance)
    appearance.AClothes = istable(appearance.AClothes) and appearance.AClothes or {}

    local sex = GetAppearanceSex(appearance)
    local clothes = AP.Clothes[sex] or {}
    local sanitized = {}

    for slotName, matName in pairs(appearance.AClothes) do
        if isstring(slotName) and isstring(matName) and clothes[matName] then
            sanitized[slotName] = matName
        end
    end

    sanitized.main = sanitized.main or "normal"
    sanitized.pants = sanitized.pants or sanitized.main
    sanitized.boots = sanitized.boots or sanitized.main
    appearance.AClothes = sanitized
end

local function SanitizeFacemapForModel(appearance)
    appearance.AFacemap = tostring(appearance.AFacemap or "По умолчанию")

    local tMdl = AP.PlayerModels[1][appearance.AModel] or AP.PlayerModels[2][appearance.AModel]
    local mdl = istable(tMdl) and tMdl.mdl or nil
    local slots = mdl and AP.GetModelFacemaps and AP.GetModelFacemaps(mdl) or nil

    if not istable(slots) or slots[appearance.AFacemap] == nil then
        appearance.AFacemap = "По умолчанию"
    end
end

local function SanitizeAppearance(ply, appearance, preserveDonateDuringGrace)
    if not istable(appearance) then return nil end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return nil end

    local copy = table.Copy(appearance)
    SanitizeAttachmentsForPlayer(ply, copy, preserveDonateDuringGrace)
    SanitizeBodygroupsForPlayer(ply, copy, preserveDonateDuringGrace)
    SanitizeClothesForModel(copy)
    SanitizeFacemapForModel(copy)

    if not AP.AppearanceValidater(copy) then
        return nil
    end

    return copy
end

local function ClearAppearanceDetails(ply)
    if not IsValid(ply) then return end

    if IsAppearanceBlockedModel(ply:GetModel()) then
        return
    end

    ply:SetSubMaterial()

    local mats = ply:GetMaterials() or {}
    for i = 1, #mats do
        ply:SetSubMaterial(i - 1, nil)
    end

    ply:SetBodyGroups("00000000000000000000")

    local bodygroups = ply:GetBodyGroups() or {}
    for i = 1, #bodygroups do
        ply:SetBodygroup(i - 1, 0)
    end

    ply:SetNetVar("Accessories", {})

    ply:SetNWString("Colthesmain", "normal")
    ply:SetNWString("Colthespants", "normal")
    ply:SetNWString("Colthesboots", "normal")
    ply:SetNWString("Coltheshands", "normal")
end

AP.ClearAppearanceDetails = ClearAppearanceDetails

local function ApplySubmaterials(ply, appearance, tMdl)
    if not IsValid(ply) then return end
    if not istable(appearance) then return end
    if not istable(tMdl) or not istable(tMdl.submatSlots) then return end

    local sex = tMdl.sex and 2 or 1
    local mats = ply:GetMaterials() or {}

    for slotName, originalMaterial in pairs(tMdl.submatSlots) do
        local slotIndex = nil
        for i = 1, #mats do
            if mats[i] == originalMaterial then
                slotIndex = i - 1
                break
            end
        end

        if slotIndex ~= nil then
            local clothesKey = appearance.AClothes[slotName] or "normal"
            local replacement = (AP.Clothes[sex] and AP.Clothes[sex][clothesKey]) or (AP.Clothes[sex] and AP.Clothes[sex].normal) or nil
            if replacement then
                ply:SetSubMaterial(slotIndex, replacement)
                ply:SetNWString("Colthes" .. slotName, clothesKey)
            end
        end
    end

    if AP.ApplyFacemap then
        AP.ApplyFacemap(ply, ply:GetModel(), appearance.AFacemap, mats)
    else
        for i = 1, #mats do
            local facemapSlots = AP.FacemapsSlots[mats[i]]
            if facemapSlots and facemapSlots[appearance.AFacemap] ~= nil then
                ply:SetSubMaterial(i - 1, facemapSlots[appearance.AFacemap])
            end
        end
    end
end

local function ApplyBodygroups(ply, appearance, sex)
    if not IsValid(ply) then return end

    local bodygroups = ply:GetBodyGroups() or {}
    appearance.ABodygroups = istable(appearance.ABodygroups) and appearance.ABodygroups or {}

    for bodygroupIndex, bodygroupData in ipairs(bodygroups) do
        local wantedName = appearance.ABodygroups[bodygroupData.name]
        if wantedName and AP.Bodygroups[bodygroupData.name] and AP.Bodygroups[bodygroupData.name][sex] then
            local wanted = AP.Bodygroups[bodygroupData.name][sex][wantedName]
            if wanted then
                for submodelIndex = 0, #bodygroupData.submodels do
                    if wanted[1] == bodygroupData.submodels[submodelIndex] then
                        ply:SetBodygroup(bodygroupIndex - 1, submodelIndex)
                        break
                    end
                end
            end
        end
    end
end

local function ApplyAppearanceCurrentModel(ply, appearance, tMdl)
    if not IsValid(ply) or not istable(appearance) then return false end
    local sex = istable(tMdl) and (tMdl.sex and 2 or 1) or GetAppearanceSex(appearance)
    local clr = appearance.AColor or color_white
    local vec = Vector((clr.r or 255) / 255, (clr.g or 255) / 255, (clr.b or 255) / 255)
    if ply.SetPlayerColor then
        ply:SetPlayerColor(vec)
    end
    ply:SetNWVector("PlayerColor", vec)
    ApplySubmaterials(ply, appearance, tMdl)
    ApplyBodygroups(ply, appearance, sex)
    ply:SetNWString("PlayerName", tostring(appearance.AName or ply:GetNWString("PlayerName", "")))
    ply:SetNetVar("Accessories", appearance.AAttachments or {})
    ply.CurAppearance = table.Copy(appearance)
    ply.CachedAppearance = table.Copy(appearance)
    return true
end

local function ForceApplyAppearance(ply, appearance, noModelChange)
    if not IsValid(ply) or not istable(appearance) then return end

    local tMdl, mdl = GetAppearanceModel(appearance)

    if IsAppearanceBlockedModel(ply:GetModel()) then
        ApplyAppearanceCurrentModel(ply, appearance, tMdl)
        return
    end

    if IsAppearanceBlockedModel(mdl) then
        ApplyAppearanceCurrentModel(ply, appearance, tMdl)
        return
    end

    local sex = istable(tMdl) and (tMdl.sex and 2 or 1) or 1

    if mdl and not noModelChange and ply:GetModel() ~= mdl then
        ply:SetModel(mdl)
    end

    if IsAppearanceBlockedModel(ply:GetModel()) then
        ApplyAppearanceCurrentModel(ply, appearance, tMdl)
        return
    end

    local clr = appearance.AColor or color_white
    ply.RK_AppearanceBaseModel = string.lower(tostring(mdl or ply:GetModel() or ""))
    local vec = Vector((clr.r or 255) / 255, (clr.g or 255) / 255, (clr.b or 255) / 255)

    if ply.SetPlayerColor then
        ply:SetPlayerColor(vec)
    end

    ply:SetNWVector("PlayerColor", vec)

    ClearAppearanceDetails(ply)
    ApplySubmaterials(ply, appearance, tMdl)
    ApplyBodygroups(ply, appearance, sex)

    ply:SetNWString("PlayerName", tostring(appearance.AName or ""))
    ply:SetNetVar("Accessories", appearance.AAttachments or {})

    ply.CurAppearance = table.Copy(appearance)
    ply.CachedAppearance = table.Copy(appearance)
    if OTCDonate and isfunction(OTCDonate.TryRestoreManagedModel) and IsValid(ply) and ply:IsPlayer() then
        timer.Simple(0, function()
            if IsValid(ply) and ply:IsPlayer() then OTCDonate.TryRestoreManagedModel(ply, false) end
        end)
    end
end

local function WearAppearance(ply, appearance, noModelChange)
    if not IsValid(ply) or not istable(appearance) then return end

    local sanitized = SanitizeAppearance(ply, appearance, IsDonateRestoreGraceActive(ply))
    if not sanitized then return end

    ForceApplyAppearance(ply, sanitized, noModelChange)
end

AP.ForceApplyAppearance = ForceApplyAppearance

local function StripUnavailableAppearanceItems(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if IsAppearanceBlockedModel(ply:GetModel()) then
        return
    end

    local appearance = ply.CurAppearance or ply.CachedAppearance or GetSavedAppearanceFromMData(ply)
    if not istable(appearance) then return end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return end

    local sanitized = SanitizeAppearance(ply, appearance, IsDonateRestoreGraceActive(ply))
    if not sanitized then return end

    local oldAttachments = util.TableToJSON((appearance.AAttachments or {}), false) or "[]"
    local newAttachments = util.TableToJSON((sanitized.AAttachments or {}), false) or "[]"
    local oldBodygroups = util.TableToJSON((appearance.ABodygroups or {}), false) or "{}"
    local newBodygroups = util.TableToJSON((sanitized.ABodygroups or {}), false) or "{}"

    if oldAttachments == newAttachments and oldBodygroups == newBodygroups then
        return
    end

    ply.CurAppearance = table.Copy(sanitized)
    ply.CachedAppearance = table.Copy(sanitized)
    SaveAppearanceToMData(ply, sanitized)
    ForceApplyAppearance(ply, sanitized, false)
end

function ApplyAppearance(client, tAppearance, bRandom, bResponseIsValid, bUseCached)
    if not IsValid(client) then return end

    if IsAppearanceBlockedModel(client:GetModel()) then
        local appearance = tAppearance

        if bUseCached or not istable(appearance) then
            appearance = GetSavedAppearanceFromMData(client) or client.CachedAppearance or client.CurAppearance
        end

        if istable(appearance) then
            appearance = SanitizeAppearance(client, appearance, true)
            if appearance then
                SaveAppearanceToMData(client, appearance)
                ApplyAppearanceAccessoriesOnly(client, appearance)
            end
        end

        return
    end

    if bRandom or (client.IsBot and client:IsBot()) or (client.IsRagdoll and client:IsRagdoll()) then
        local randomAppearance = AP.GetRandomAppearance and AP.GetRandomAppearance() or nil
        if randomAppearance then
            WearAppearance(client, randomAppearance, false)
        end
        return
    end

    if bUseCached then
        local saved = GetSavedAppearanceFromMData(client)
        tAppearance = saved or client.CachedAppearance or (AP.GetRandomAppearance and AP.GetRandomAppearance() or nil)

        if not tAppearance or not AP.AppearanceValidater or not AP.AppearanceValidater(tAppearance) then
            tAppearance = AP.GetRandomAppearance and AP.GetRandomAppearance() or nil
        end

        if not tAppearance then return end

        tAppearance = SanitizeAppearance(client, tAppearance, true) or (AP.GetRandomAppearance and AP.GetRandomAppearance() or nil)
        if not tAppearance then return end

        client.CachedAppearance = table.Copy(tAppearance)

        net.Start("OnlyGet_Appearance")
        net.Send(client)

        WearAppearance(client, tAppearance, false)
        return
    end

    if not bResponseIsValid then
        tWaitResponse[client] = CurTime() + 3
        net.Start("Get_Appearance")
        net.Send(client)
        return
    end

    if not tWaitResponse[client] then return end

    if tWaitResponse[client] < CurTime() then
        ApplyAppearance(client, nil, true)
        return
    end

    if not tAppearance or not AP.AppearanceValidater or not AP.AppearanceValidater(tAppearance) then
        ApplyAppearance(client, nil, true)
        return
    end

    tAppearance = SanitizeAppearance(client, tAppearance, IsDonateRestoreGraceActive(client))
    if not tAppearance then
        ApplyAppearance(client, nil, true)
        return
    end

    client.CachedAppearance = table.Copy(tAppearance)
    SaveAppearanceToMData(client, tAppearance)
    WearAppearance(client, tAppearance, false)
    tWaitResponse[client] = nil
end

net.Receive("Get_Appearance", function(_, client)
    local tAppearance = net.ReadTable()
    local bRandom = net.ReadBool()

    if not istable(tAppearance) or not AP.AppearanceValidater or not AP.AppearanceValidater(tAppearance) then
        bRandom = true
    end

    if not bRandom and istable(tAppearance) and AP.AppearanceValidater and AP.AppearanceValidater(tAppearance) then
        tAppearance = SanitizeAppearance(client, tAppearance, IsDonateRestoreGraceActive(client))
        if tAppearance then
            SaveAppearanceToMData(client, tAppearance)
        end
    end

    ApplyAppearance(client, tAppearance, table.IsEmpty(tAppearance or {}) and true or bRandom, true)
    StripUnavailableAppearanceItems(client)
end)

net.Receive("OnlyGet_Appearance", function(_, client)
    local tAppearance = net.ReadTable()
    if not istable(tAppearance) then return end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(tAppearance) then return end

    tAppearance = SanitizeAppearance(client, tAppearance, IsDonateRestoreGraceActive(client))
    if not tAppearance then return end

    client.CachedAppearance = table.Copy(tAppearance)
    SaveAppearanceToMData(client, tAppearance)
    RestoreSavedAccessoriesOnly(client, tAppearance)
    StripUnavailableAppearanceItems(client)
end)

net.Receive("hg_appearance_presets_request", function(_, ply)
    SyncPresetsToClient(ply)
end)

net.Receive("hg_appearance_preset_save", function(_, ply)
    local presetName = string.Trim(net.ReadString() or "")
    local appearance = net.ReadTable()

    presetName = NormalizePresetName(presetName)
    if presetName == "" then return end
    if not istable(appearance) then return end
    if not AP.AppearanceValidater or not AP.AppearanceValidater(appearance) then return end

    appearance = SanitizeAppearance(ply, appearance)
    if not appearance then return end

    if not CanUseMData(ply) then
        QueuePresetOperation(ply, {kind = "save", name = presetName, appearance = table.Copy(appearance)})
        return
    end

    local presets = GetSavedPresetsFromMData(ply)
    presets[presetName] = appearance
    SavePresetsToMData(ply, presets)
    SyncPresetsToClient(ply)
end)

net.Receive("hg_appearance_preset_delete", function(_, ply)
    local presetName = NormalizePresetName(net.ReadString() or "")
    if presetName == "" then return end

    if not CanUseMData(ply) then
        QueuePresetOperation(ply, {kind = "delete", name = presetName})
        return
    end

    local presets = GetSavedPresetsFromMData(ply)
    presets[presetName] = nil
    SavePresetsToMData(ply, presets)
    SyncPresetsToClient(ply)
end)

net.Receive("hg_otcoins_purchase_accessory", function(_, ply)
    local uid = tostring(net.ReadString() or "")

    if uid == "" or uid == "none" then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] аксессуар не найден", uid)
        return
    end

    if not EnsureOTCoinDataReady(ply) then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] профиль ещё загружается", uid)
        return
    end

    local acc = hg.Accessories and hg.Accessories[uid]
    if not acc then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] аксессуар не найден", uid)
        return
    end

    if acc.donateOnly == true then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] этот аксессуар только донатный", uid)
        return
    end

    if acc.isvip == true and (not ply.GetUserGroup or ply:GetUserGroup() == "user") then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] для этого аксессуара нужен VIP", uid)
        return
    end

    local price = AP.GetAccessoryCoinPrice and AP.GetAccessoryCoinPrice(acc, uid) or math.max(0, math.floor(tonumber(acc.coinPrice or acc.price) or 0))
    if price <= 0 then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] этот аксессуар не продаётся", uid)
        return
    end

    if RK_HasCoinAccessory(ply, uid) then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] аксессуар уже куплен", uid)
        return
    end

    local balance = GetOTCoinBalance(ply)
    if balance < price then
        SendOTCoinPurchaseResult(ply, false, "[OT-Coin] недостаточно монет", uid)
        return
    end

    TakeOTCoins(ply, price)
    GrantCoinAccessory(ply, uid)
    SendOTCoinPurchaseResult(ply, true, "[OT-Coin] куплен аксессуар '" .. tostring(acc.name or uid) .. "' за " .. price, uid)
end)

local function IsSpectatorForOTCoin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    if TEAM_SPECTATOR ~= nil and ply:Team() == TEAM_SPECTATOR then return true end
    return false
end

local function GetRewardEligiblePlayers()
    local out = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() and not IsSpectatorForOTCoin(ply) then
            out[#out + 1] = ply
        end
    end
    return out
end

local function ResolveRoundWinner(mode)
    if not mode or not zb or not zb.CheckWinner or not mode.CheckAlivePlayers then return nil end

    local okPlayers, teams = pcall(function()
        return mode:CheckAlivePlayers()
    end)
    if not okPlayers or not istable(teams) then return nil end

    local okWinner, ended, winner = pcall(function()
        return zb:CheckWinner(teams)
    end)
    if not okWinner or ended ~= true then return nil end

    return winner
end

hook.Add("ZB_EndRound", "hg.Appearance.OTCoinRoundRewards", function()
    local mode = isfunction(CurrentRound) and CurrentRound() or nil
    local winner = ResolveRoundWinner(mode)
    local modeName = tostring(mode and (mode.PrintName or mode.name) or "Раунд")
    local roundStart = (zb and (zb.ROUND_BEGIN or zb.ROUND_START)) or 0
    local minRoundRewardSeconds = AP.OTCoin and AP.OTCoin.MinRoundRewardSeconds or 60

    if roundStart <= 0 or (CurTime() - roundStart) < minRoundRewardSeconds then
        return
    end

    local baseReward = AP.OTCoin and AP.OTCoin.RoundPlayedReward or 15
    local winReward = AP.OTCoin and AP.OTCoin.WinReward or 35
    local aliveReward = AP.OTCoin and AP.OTCoin.AliveWinReward or 10

    for _, ply in ipairs(GetRewardEligiblePlayers()) do
        if EnsureOTCoinDataReady(ply) and not IsSpectatorForOTCoin(ply) then
            local reward = baseReward
            if winner and winner ~= 3 and ply:Team() == winner then
                reward = reward + winReward
                if ply:Alive() then
                    reward = reward + aliveReward
                end
            end

            AddOTCoins(ply, reward, "за режим '" .. modeName .. "'")
        end
    end
end)

timer.Create("hg.Appearance.OTCoinPlaytime", AP.OTCoin and AP.OTCoin.PlaytimeInterval or 300, 0, function()
    local reward = AP.OTCoin and AP.OTCoin.PlaytimeReward or 25

    for _, ply in ipairs(GetRewardEligiblePlayers()) do
        if EnsureOTCoinDataReady(ply) and not IsSpectatorForOTCoin(ply) then
            AddOTCoins(ply, reward, "за игру на сервере")
        end
    end
end)

AP.ApplyAppearance = ApplyAppearance

function ApplyAppearanceRagdoll(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return end
    if IsAppearanceBlockedModel(ent:GetModel()) or IsAppearanceBlockedModel(ply:GetModel()) then return end

    local appearance = ply.CurAppearance
    if not istable(appearance) then return end

    ent:SetNWString("PlayerName", ply:GetNWString("PlayerName", appearance.AName or ""))
    ent:SetNetVar("Accessories", ply:GetNetVar("Accessories", {}))

    local tMdl = AP.PlayerModels[1][ent:GetModel()] or AP.PlayerModels[2][ent:GetModel()] or ent:GetModel()
    if istable(tMdl) and istable(tMdl.submatSlots) then
        for slotName in pairs(tMdl.submatSlots) do
            ent:SetNWString("Colthes" .. slotName, ply:GetNWString("Colthes" .. slotName, "normal"))
        end
    end
end

hook.Add("PlayerInitialSpawn", "hg.Appearance.SyncPresetsOnJoin", function(ply)
    StartDonateRestoreGrace(ply)

    local steamID64 = ply:SteamID64()
    local waitTimerName = "hg.Appearance.WaitMData." .. steamID64

    timer.Create(waitTimerName, 0.25, 0, function()
        if not IsValid(ply) then
            timer.Remove(waitTimerName)
            return
        end

        if CanUseMData(ply) then
            EnsureOTCoinDataReady(ply)
            FlushPendingAppearanceData(ply)
            SyncPresetsToClient(ply)

            local saved = GetSavedAppearanceFromMData(ply)
            if istable(saved) then
                RestoreSavedAccessoriesOnly(ply, saved)
            end

            StripUnavailableAppearanceItems(ply)
            timer.Remove(waitTimerName)
        end
    end)
end)

hook.Add("PlayerSpawn", "hg.Appearance.StripUnavailableOnSpawn", function(ply)
    timer.Simple(0.2, function()
        if IsValid(ply) then
            StripUnavailableAppearanceItems(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "hg.Appearance.ClearWaitState", function(ply)
    tWaitResponse[ply] = nil
end)

timer.Create("hg.Appearance.ValidateDonateAccessories", 5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        StripUnavailableAppearanceItems(ply)
    end
end)

if engine.ActiveGamemode() == "sandbox" then
    hook.Add("PlayerSpawn", "SetAppearance", function(ply)
        if OverrideSpawn then return end

        timer.Create("hg.Appearance.ApplySaved." .. ply:SteamID64(), 0.25, 40, function()
            if not IsValid(ply) then
                timer.Remove("hg.Appearance.ApplySaved." .. tostring(ply:SteamID64()))
                return
            end

            if CanUseMData(ply) then
                ApplyAppearance(ply, nil, nil, nil, true)
                timer.Remove("hg.Appearance.ApplySaved." .. tostring(ply:SteamID64()))
            end
        end)
    end)
end

local function RK_NormalizeSteamID64(raw)
    raw = string.Trim(tostring(raw or ""))
    if raw == "" then return "" end
    if string.match(raw, "^%d+$") then return raw end
    if string.match(raw, "^STEAM_%d:%d:%d+$") then return util.SteamIDTo64(raw) end
    return ""
end

local function RK_GiveCoinsOnline(target, amount)
    local current = GetOTCoinBalance(target)
    local newBalance = math.max(0, current + amount)
    SetOTCoinBalance(target, newBalance)
    return newBalance
end

local function RK_GiveCoinsOffline(sid64, amount, cb)
    if not mdata or not mdata.ready or not mdata.db then
        if cb then cb(false, "mdata not ready") end
        return
    end

    local key = MDATA_OTCOIN_BALANCE_KEY

    local function runUpdate()
        local esid = mdata.db:escape(sid64)
        local addInit = math.max(0, amount)
        local sql = string.format(
            "INSERT INTO `%s` (steamid, `%s`) VALUES (\'%s\', %d) ON DUPLICATE KEY UPDATE `%s` = GREATEST(0, CAST(`%s` AS SIGNED) + (%d))",
            mdata.TableName, key, esid, addInit, key, key, amount
        )

        local q = mdata.db:query(sql)
        function q:onSuccess()
            if cb then cb(true) end
        end
        function q:onError(err)
            if cb then cb(false, tostring(err)) end
        end
        q:start()
    end

    if mdata.columns and mdata.columns[key] then
        runUpdate()
    elseif isfunction(mdata.AutoRegisterColumn) then
        mdata.AutoRegisterColumn(key, 0)
        timer.Simple(0.5, runUpdate)
    else
        runUpdate()
    end
end

concommand.Add("rk_otcoins_give", function(ply, _, args)
    local isConsole = not IsValid(ply)
    if not isConsole and not ply:IsSuperAdmin() then
        ply:ChatPrint("[OT-Coin] недостаточно прав")
        return
    end

    local function reply(msg)
        if isConsole then
            print(msg)
        elseif IsValid(ply) then
            ply:ChatPrint(msg)
        end
    end

    local sid64 = RK_NormalizeSteamID64(args and args[1])
    local amount = math.floor(tonumber(args and args[2]) or 0)

    if sid64 == "" then
        reply("[OT-Coin] rk_otcoins_give <steamid64> <amount>")
        return
    end

    if amount == 0 then
        reply("[OT-Coin] amount must not be zero")
        return
    end

    local target = player.GetBySteamID64(sid64)
    if IsValid(target) and CanUseMData(target) then
        EnsureOTCoinDataReady(target)
        local newBalance = RK_GiveCoinsOnline(target, amount)
        reply("[OT-Coin] " .. sid64 .. " +" .. amount .. " (online). Баланс: " .. newBalance)
        target:ChatPrint("[OT-Coin] вам начислено " .. amount .. ". Баланс: " .. newBalance)
        return
    end

    RK_GiveCoinsOffline(sid64, amount, function(ok, info)
        if ok then
            reply("[OT-Coin] " .. sid64 .. " +" .. amount .. " (offline)")
        else
            reply("[OT-Coin] offline error: " .. tostring(info))
        end
    end)
end)
