hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName(self)
    local class = self:GetClass()
    local phrase = language.GetPhrase(class)
    return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

local RNDX = _G.gSims_RNDX

local function RndxFlags()
    if not RNDX then return nil end

    return RNDX.SHAPE_IOS or RNDX.SHAPE_FIGMA
end

function WS.Scale()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.45, 2.2)
end

function WS.DrawRound(rad, x, y, w, h, col)
    if w <= 0 or h <= 0 then return end

    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col, RndxFlags())
    else
        draw.RoundedBox(math.Round(math.min(rad, math.min(w, h) * 0.5)), math.Round(x), math.Round(y), math.Round(w), math.Round(h), col)
    end
end

function WS.DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if w <= 0 or h <= 0 then return end

    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness, RndxFlags())
    else
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(math.Round(x), math.Round(y), math.Round(w), math.Round(h), math.Round(thickness))
    end
end

function WS.DrawRoundMaterial(rad, x, y, w, h, col, mat)
    if w <= 0 or h <= 0 then return end

    if RNDX and RNDX.DrawMaterial then
        RNDX.DrawMaterial(rad, x, y, w, h, col, mat, RndxFlags())
    else
        surface.SetDrawColor(col)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, w, h)
    end
end

function WS.Trim(text, font, maxW)
    text = tostring(text or "")

    if maxW <= 0 then return text end

    surface.SetFont(font)

    if surface.GetTextSize(text) <= maxW then return text end

    local out = text

    while #out > 1 do
        out = string.sub(out, 1, #out - 1)

        if surface.GetTextSize(out .. "...") <= maxW then
            return out .. "..."
        end
    end

    return out
end

function WS.GetIconAspect(wep)
    local icon = wep.WepSelectIcon or wep.SelectIcon or wep.IconOverride

    if isnumber(icon) then
        local tw, th = surface.GetTextureSize(icon)

        if tw and th and tw > 0 and th > 0 then
            return tw / th
        end
    elseif icon and type(icon) == "IMaterial" and not icon:IsError() then
        local tw, th = icon:Width(), icon:Height()

        if tw > 0 and th > 0 then
            return tw / th
        end
    end

    return nil
end

function WS.DrawWeaponIcon(wep, x, y, w, h, alpha)
    local aspect = WS.GetIconAspect(wep)
    local dw, dh = w, h

    if aspect and aspect > 0 then
        dh = w / aspect

        if dh > h then
            dh = h
            dw = h * aspect
        end
    end

    wep:DrawWeaponSelection(x + (w - dw) * 0.5, y + (h - dh) * 0.5, dw, dh, alpha)
end

function WS.DrawText(text, font, posX, posY, color, textAlign)
    local off = math.max(1, ScrH() / 1080 * 2)
    draw.DrawText(text, font, posX + off, posY + off, ColorAlpha(color_black, WS.Transparent * 255), textAlign)
    draw.DrawText(text, font, posX, posY, ColorAlpha(color, WS.Transparent * 255), textAlign)
end

function WS.GetSelectedWeapon()
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
    local Weapons = WS.GetWeaponTable(LocalPlayer())
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetWeaponTable(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k, wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min((wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[iMinPos] and #tTbl + 1 or iMinPos
        tTbl[iPos] = wep
    end
    return FormatedTable
end

local clr_slot = Color(6, 12, 20, 210)
local clr_slot_sel = Color(10, 21, 35, 236)
local clr_select = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local gradient_u = Material("vgui/gradient-d")

WS.Anim = WS.Anim or {}

function WS.WeaponSelectorDraw(ply)
    if not IsValid(ply) or not ply:Alive() then return end

    if WS.Show < CurTime() then
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1

        return
    end

    local Weapons = WS.GetWeaponTable(ply)
    local SelectedWep = WS.GetSelectedWeapon()

    if not IsValid(SelectedWep) then return end

    WS.Transparent = LerpFT(0.2, WS.Transparent, math.min(WS.Show - CurTime(), 1))

    local frac = math.Clamp(WS.Transparent, 0, 1)

    if frac <= 0.01 then return end

    local scrW, scrH = ScrW(), ScrH()
    local s = WS.Scale()

    local gapX = math.max(2, math.Round(6 * s))
    local gapY = math.max(2, math.Round(4 * s))
    local pad = math.max(2, math.Round(6 * s))
    local rad = math.max(3, math.Round(8 * s))
    local border = math.max(1, math.Round(1.5 * s))

    local fontName = "HomigradFontSmall"
    local fontNum = "HomigradFontMedium"
    local fontH = draw.GetFontHeight(fontName)
    local numH = draw.GetFontHeight(fontNum)

    local slots = {}
    local maxRows = 1

    for i = 0, #Weapons do
        local slotTbl = Weapons[i]

        if table.Count(slotTbl) < 1 then continue end

        local rows = 0

        for Id = 0, #slotTbl do
            if slotTbl[Id] then rows = rows + 1 end
        end

        maxRows = math.max(maxRows, rows)
        slots[#slots + 1] = {index = i, tbl = slotTbl}
    end

    local count = #slots

    if count < 1 then return end

    local slotW = math.min(148 * s, (scrW * 0.86 - (count - 1) * gapX) / count)

    slotW = math.max(slotW, math.min(58 * s, (scrW * 0.94 - (count - 1) * gapX) / count))

    local totalW = count * slotW + (count - 1) * gapX
    local startX = math.max((scrW - totalW) * 0.5, gapX)

    local boxH = fontH + pad * 1.1
    local selH = math.min(slotW * 0.7, scrH * 0.135)
    local topY = math.max(numH + gapY * 2, scrH * 0.05)
    local availH = scrH * 0.7 - topY
    local needH = selH + (maxRows - 1) * (boxH + gapY)

    if needH > availH and needH > 0 then
        local shrink = availH / needH

        selH = selH * shrink
        boxH = boxH * shrink
        gapY = gapY * shrink
    end

    selH = math.max(selH, boxH)

    local numY = topY - numH - gapY

    for k = 1, count do
        local data = slots[k]
        local slotTbl = data.tbl
        local posX = startX + (k - 1) * (slotW + gapX)

        WS.DrawText(data.index + 1, fontNum, posX + slotW * 0.5, numY, clr_cyan, TEXT_ALIGN_CENTER)

        local boxY = topY

        for Id = 0, #slotTbl do
            local wep = slotTbl[Id]

            if not wep then continue end

            local IsSelected = SelectedWep == wep
            local key = wep:EntIndex()
            local target = IsSelected and 1 or 0

            WS.Anim[key] = LerpFT(0.16, WS.Anim[key] or target, target)

            local t = math.Clamp(WS.Anim[key], 0, 1)
            local sizeH = boxH + (selH - boxH) * t

            WS.DrawRound(rad, posX, boxY, slotW, sizeH, Color(
                Lerp(t, clr_slot.r, clr_slot_sel.r),
                Lerp(t, clr_slot.g, clr_slot_sel.g),
                Lerp(t, clr_slot.b, clr_slot_sel.b),
                frac * Lerp(t, clr_slot.a, clr_slot_sel.a)
            ))

            WS.DrawRoundMaterial(rad, posX, boxY, slotW, sizeH, Color(clr_select.r, clr_select.g, clr_select.b, frac * (16 + t * 64)), gradient_u)

            if t > 0.01 then
                WS.DrawRoundOutlined(rad, posX, boxY, slotW, sizeH, Color(clr_select.r, clr_select.g, clr_select.b, frac * t * 40), border * 2)
                WS.DrawRoundOutlined(rad, posX, boxY, slotW, sizeH, Color(clr_select.r, clr_select.g, clr_select.b, frac * t * 195), border)
            end

            local barH = math.max(1, math.Round(border * 1.2))
            local barW = (slotW - pad * 2) * (0.3 + 0.7 * t)

            WS.DrawRound(barH, posX + (slotW - barW) * 0.5, boxY + sizeH - barH - border, barW, barH, Color(clr_select.r, clr_select.g, clr_select.b, frac * (55 + t * 200)))

            local name = WS.Trim(WS.GetPrintName(wep), fontName, slotW - pad * 2)

            WS.DrawText(name, fontName, posX + slotW * 0.5, boxY + pad * 0.5, IsSelected and color_white or Color(205, 225, 240), TEXT_ALIGN_CENTER)

            if t > 0.02 and wep.DrawWeaponSelection then
                local iconTop = boxY + fontH + pad * 0.6
                local iconW = slotW - pad * 2
                local iconH = sizeH - (iconTop - boxY) - pad

                if iconW > 4 and iconH > 4 then
                    WS.DrawWeaponIcon(wep, posX + pad, iconTop, iconW, iconH, frac * t * 255)
                end
            end

            boxY = boxY + sizeH + gapY
        end
    end
end

local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100)
end

function WS.ChangeSelectionWep(ply, key)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector(ply) then return end
    local iPos = tAcceptKeys[key]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = WS.GetWeaponTable(ply)

        WS.Show = CurTime() + 4
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin" .. math.random(10) .. ".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min(WS.SelectedSlotPos + 1, #Weapons[iPos])) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0 then
                GetUpper(Weapons)
            end
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon(WS.LastInv)
            WS.LastInv = oldwep
        end
    end
end

function WS.SetActuallyWeapon(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
    if (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) and WS.Show > CurTime() then

        if WS.Selected and WS.Selected > CurTime() then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)

            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon(WS.GetSelectedWeapon())
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)

            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin" .. math.random(1, 10) .. ".ogg")
        end
    end
end

hook.Add("PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep)

hook.Add("HUDPaint", "WeaponSelector_Draw", function()
    WS.WeaponSelectorDraw(LocalPlayer())
end)

hook.Add("StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon)

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)
