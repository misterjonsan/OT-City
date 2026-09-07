local pickupHistory = {}
local typeState = {}

local font = "HomigradFont"
local color_bg = Color(4, 10, 18, 205)
local color_outline_def = Color(31, 182, 255)
local color_text_def = Color(240, 248, 255)
local color_loss = Color(255, 90, 90)
local displayTime = 5
local typeSpeed = 15
local maxBoxWidth = ScreenScale(200)

local RNDX = _G.gSims_RNDX

local function DrawRound(rad, x, y, w, h, col)
    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

local function GetAccentColor()
    if hg and hg.theme and hg.theme.c and hg.theme.c.accent then
        return hg.theme.c.accent
    end
    return color_outline_def
end

local function GetTextColor()
    if hg and hg.theme and hg.theme.c and hg.theme.c.text then
        return hg.theme.c.text
    end
    return color_text_def
end

function hg.AddPickupNotification(text, isLoss)
    local id = tostring(CurTime()) .. "_" .. math.random(1, 1000)
    local pickup = {
        text = text,
        time = CurTime(),
        id = id,
        isLoss = isLoss or false
    }
    table.insert(pickupHistory, pickup)
    typeState[id] = {t = 0, len = #text, smoothW = 0}
end

hook.Add("HUDItemPickedUp", "HomigradPickup_Item", function(itemName)
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
    local name = language.GetPhrase(itemName)
    hg.AddPickupNotification(name)
    return true
end)

hook.Add("HUDAmmoPickedUp", "HomigradPickup_Ammo", function(itemName, amount)
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
    local name = language.GetPhrase(itemName)
    hg.AddPickupNotification(amount .. " " .. name)
    return true
end)

hook.Add("HUDWeaponPickedUp", "HomigradPickup_Weapon", function(wep)
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
    if not IsValid(wep) then return end
    if wep:GetClass() == "weapon_hands_sh" then return end
    local name = language.GetPhrase(wep:GetPrintName())
    hg.AddPickupNotification(name)
    return true
end)

net.Receive("HG_WeaponDrop", function()
    local wep = net.ReadEntity()
    if IsValid(wep) then
        if wep:GetClass() == "weapon_hands_sh" then return end
        local name = language.GetPhrase(wep:GetPrintName())
        hg.AddPickupNotification(name, true)
    end
end)

hook.Add("HUDPaint", "HomigradPickup_Paint", function()
    if #pickupHistory == 0 then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    if ply.organism and ply.organism.otrub then return end

    local scrW, scrH = ScrW(), ScrH()
    local startX = scrW - ScreenScale(20)
    local startY = scrH * 0.4
    local padding = ScreenScale(3)
    local spacing = ScreenScale(2)

    local color_outline = GetAccentColor()
    local color_text = GetTextColor()

    local currentY = startY

    for i, pickup in ipairs(pickupHistory) do
        local elapsed = CurTime() - pickup.time
        local typeDuration = #pickup.text / typeSpeed
        local idleEnd = typeDuration + displayTime

        local phase = "IN"
        if elapsed > idleEnd then
            phase = "OUT"
        elseif elapsed > typeDuration then
            phase = "IDLE"
        end

        local charCount = 0
        local alpha = 255

        if phase == "IN" then
            charCount = math.min(#pickup.text, elapsed * typeSpeed)
        elseif phase == "IDLE" then
            charCount = #pickup.text
        elseif phase == "OUT" then
            local outElapsed = elapsed - idleEnd

            charCount = math.max(0, #pickup.text - (outElapsed * typeSpeed))

            if charCount <= 0 then
                charCount = 0
                local untypeTime = #pickup.text / typeSpeed
                local fadeElapsed = outElapsed - untypeTime

                if fadeElapsed > 0 then
                    local fadeDur = 1.0
                    local p = math.min(fadeElapsed / fadeDur, 1)
                    alpha = 255 * (1 - p)

                    if p >= 1 then
                        table.remove(pickupHistory, i)
                        typeState[pickup.id] = nil
                        continue
                    end
                end
            end
        end

        local displayLen = math.floor(charCount)
        local currentText = string.sub(pickup.text, 1, displayLen)
        local symbol = pickup.isLoss and "- " or "+ "
        local fullDisplay = symbol .. currentText

        surface.SetFont(font)
        local tw, th = surface.GetTextSize(fullDisplay)

        local targetWidth = tw + (padding * 2)
        if targetWidth > maxBoxWidth then targetWidth = maxBoxWidth end

        local s = typeState[pickup.id]
        if s then
            s.smoothW = Lerp(FrameTime() * 10, s.smoothW or 0, targetWidth)
        end

        local boxWidth = s and s.smoothW or targetWidth
        local boxHeight = th + padding

        local drawX = startX - boxWidth
        local drawY = currentY

        local tickCol = pickup.isLoss and color_loss or color_outline
        local current_bg = Color(color_bg.r, color_bg.g, color_bg.b, math.min(color_bg.a, alpha))
        local current_tick = Color(tickCol.r, tickCol.g, tickCol.b, math.min(220, alpha))
        local current_outline = Color(color_outline.r, color_outline.g, color_outline.b, math.min(90, alpha))
        local current_text = Color(color_text.r, color_text.g, color_text.b, math.min(color_text.a, alpha))

        local rad = math.max(2, ScreenScale(2))

        DrawRound(rad, drawX, drawY, boxWidth, boxHeight, current_bg)
        DrawRoundOutlined(rad, drawX, drawY, boxWidth, boxHeight, current_outline, 1)
        DrawRound(1, drawX, drawY + rad, math.max(2, ScreenScale(1)), boxHeight - rad * 2, current_tick)

        render.SetScissorRect(drawX, drawY, drawX + boxWidth, drawY + boxHeight, true)
        draw.SimpleText(fullDisplay, font, drawX + boxWidth / 2, drawY + boxHeight / 2, current_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        render.SetScissorRect(0, 0, 0, 0, false)

        currentY = currentY + boxHeight + spacing
    end
end)
