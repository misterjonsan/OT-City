if SERVER then return end

local UI_MAIN = Color(31, 182, 255)
local UI_MAIN_SOFT = Color(127, 230, 255)
local UI_DARK = Color(3, 5, 9)
local UI_DARK_SOFT = Color(6, 12, 20)
local UI_CARD = Color(9, 18, 30)
local UI_TEXT = Color(240, 248, 255)
local UI_MUTED = Color(150, 190, 220)
local UI_SHADOW = Color(0, 0, 0, 200)

local UI_RADIUS = 10

local function DrawUIBlock(x, y, w, h, col, radius)
    if w <= 0 or h <= 0 then return end
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))

    if RNDX and RNDX.Draw then
        RNDX.Draw(radius, x, y, w, h, col)
    elseif rndx and rndx.Draw then
        rndx.Draw(radius, x, y, w, h, col)
    else
        draw.RoundedBox(radius, x, y, w, h, col)
    end
end

local function DrawUIOutline(x, y, w, h, col, radius, thickness)
    if w <= 0 or h <= 0 then return end
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))
    thickness = thickness or 1

    if RNDX and RNDX.DrawOutlined then
        RNDX.DrawOutlined(radius, x, y, w, h, col, thickness)
    elseif rndx and rndx.DrawOutlined then
        rndx.DrawOutlined(radius, x, y, w, h, col, thickness)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        for i = 0, thickness - 1 do
            surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2)
        end
    end
end

local function DrawUIShadow(x, y, w, h, col, radius, spread, intensity)
    if w <= 0 or h <= 0 then return end

    local lib = (RNDX and RNDX.DrawShadows and RNDX) or (rndx and rndx.DrawShadows and rndx)
    if not lib then return end

    lib.DrawShadows(radius or UI_RADIUS, x, y, w, h, col, spread or 12, intensity or 18)
end

local function DrawUIGlowBar(x, y, w, h, col, radius)
    DrawUIBlock(x, y, w, h, Color(col.r, col.g, col.b, (col.a or 255) * 0.35), radius)
    DrawUIBlock(x, y + h * 0.15, w, h * 0.7, col, radius)
end

local function DrawUIText(text, font, x, y, col, ax, ay)
    local sa = (col.a or 255) * 0.7
    draw.SimpleText(text, font, x + 1, y + 1, Color(UI_SHADOW.r, UI_SHADOW.g, UI_SHADOW.b, sa), ax, ay)
    draw.SimpleText(text, font, x, y, col, ax, ay)
end

surface.CreateFont("ZCitySpectateFont", {
    font = "Montserrat Medium",
    extended = true,
    size = 18,
    weight = 500,
    antialias = true
})

surface.CreateFont("ZCitySpectateFontSmall", {
    font = "Montserrat Medium",
    extended = true,
    size = 16,
    weight = 500,
    antialias = true
})

local SpectateHideNick = false
local keyOld = false

net.Receive("ZCity_Spectator_Health_Sync", function()
    local count = net.ReadUInt(8)
    for i = 1, count do
        local ply = net.ReadEntity()
        local health = net.ReadFloat()
        if IsValid(ply) then
            ply.ZCitySpectatorHealth = health
        end
    end
end)

hook.Add("HUDPaint", "ZCity_Spectate_ALT_ESP", function()
    local lply = LocalPlayer()
    if not IsValid(lply) then return end

    if lply:Alive() and lply:GetObserverMode() == OBS_MODE_NONE then return end

    local key = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
    if keyOld ~= key and key then
        SpectateHideNick = not SpectateHideNick
    end
    keyOld = key

    local hint = "[ALT] Дисплей спектатора: " .. (SpectateHideNick and "ВЫКЛ" or "ВКЛ")
    surface.SetFont("ZCitySpectateFontSmall")
    local hw, hh = surface.GetTextSize(hint)
    local hint_pad = 10
    local hint_w = hw + hint_pad * 2 + 12
    local hint_h = hh + hint_pad
    local hx = 15
    local hy = ScrH() - 15 - hint_h
    local hint_col = SpectateHideNick and UI_MUTED or UI_MAIN

    local stripe_w = 3

    DrawUIShadow(hx, hy, hint_w, hint_h, Color(0, 0, 0, 210), 10, 16, 22)
    DrawUIBlock(hx, hy, hint_w, hint_h, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, 235), 10)
    DrawUIBlock(hx, hy, hint_w, hint_h, Color(UI_CARD.r, UI_CARD.g, UI_CARD.b, 170), 10)
    DrawUIBlock(hx, hy, hint_w, hint_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 16), 10)
    DrawUIOutline(hx, hy, hint_w, hint_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 95), 10, 1)
    DrawUIGlowBar(hx + 6, hy + 6, stripe_w, hint_h - 12, Color(hint_col.r, hint_col.g, hint_col.b, 235), 2)
    DrawUIText(hint, "ZCitySpectateFontSmall", hx + hint_w / 2 + 5, hy + hint_h / 2, Color(hint_col.r, hint_col.g, hint_col.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if SpectateHideNick then return end

    for _, v in ipairs(player.GetAll()) do
        if not v:Alive() or v == lply then continue end

        local ent = IsValid(v:GetNWEntity("Ragdoll")) and v:GetNWEntity("Ragdoll") or v
        local pos = ent:LocalToWorld(ent:OBBCenter())
        local screenPosition = pos:ToScreen()
        local x, y = screenPosition.x, screenPosition.y

        local teamColor = v:GetPlayerColor():ToColor()
        local distance = lply:GetPos():Distance(v:GetPos())
        local factor = 1 - math.Clamp(distance / 1024, 0, 1)
        local alpha = math.max(255 * factor, 80)

        local name = v:Name()
        surface.SetFont("ZCitySpectateFont")
        local tw, th = surface.GetTextSize(name)

        local pad_x = 10
        local pad_y = 5
        local marker_w = 6
        local box_w = tw + pad_x * 2 + marker_w + 6
        local box_h = th + pad_y * 2

        local bx = x - box_w / 2
        local by = y - box_h / 2

        DrawUIShadow(bx, by, box_w, box_h, Color(0, 0, 0, alpha * 0.75), 8, 12, 18)
        DrawUIBlock(bx, by, box_w, box_h, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, alpha * 0.92), 8)
        DrawUIBlock(bx, by, box_w, box_h, Color(UI_CARD.r, UI_CARD.g, UI_CARD.b, alpha * 0.65), 8)
        DrawUIBlock(bx, by, box_w, box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, alpha * 0.08), 8)
        DrawUIOutline(bx, by, box_w, box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, alpha * 0.45), 8, 1)
        DrawUIGlowBar(bx + 5, by + 5, marker_w, box_h - 10, Color(teamColor.r, teamColor.g, teamColor.b, alpha), 3)

        DrawUIText(name, "ZCitySpectateFont", bx + marker_w + 11, by + box_h / 2, Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local playerHealth = v.ZCitySpectatorHealth or v:Health()
        local healthFrac = math.Clamp(playerHealth / 100, 0, 1)

        local bar_w = box_w
        local bar_h = 5
        local bar_x = bx
        local bar_y = by + box_h + 3

        local hp_col = Color(
            Lerp(healthFrac, 235, UI_MAIN.r),
            Lerp(healthFrac, 85, UI_MAIN.g),
            Lerp(healthFrac, 80, UI_MAIN.b),
            alpha
        )

        DrawUIBlock(bar_x, bar_y, bar_w, bar_h, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, alpha * 0.9), 3)
        DrawUIBlock(bar_x, bar_y, bar_w, bar_h, Color(UI_CARD.r, UI_CARD.g, UI_CARD.b, alpha * 0.7), 3)
        DrawUIBlock(bar_x, bar_y, bar_w * healthFrac, bar_h, hp_col, 3)
        DrawUIBlock(bar_x, bar_y, bar_w * healthFrac, bar_h * 0.45, Color(255, 255, 255, alpha * 0.12), 3)
        DrawUIOutline(bar_x, bar_y, bar_w, bar_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, alpha * 0.3), 3, 1)
    end
end)
