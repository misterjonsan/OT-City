local RNDX = _G.gSims_RNDX or _G.RNDX or _G.rndx

local EXO_MAX = 5

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_card = Color(6, 12, 20, 168)
local clr_empty = Color(64, 78, 92, 190)
local clr_red = Color(255, 92, 92)

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
end

local function Fade(col, a)
    return Color(col.r, col.g, col.b, math.Clamp(a, 0, 255))
end

local function DrawRound(rad, x, y, w, h, col)
    if RNDX and RNDX.Draw then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(math.floor(rad), math.floor(x), math.floor(y), math.floor(w), math.floor(h), col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thick)
    if RNDX and RNDX.DrawOutlined then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thick or 1)
    else
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), math.floor(thick or 1))
    end
end

local function BuildFonts()
    surface.CreateFont("ExoHud_Title", {
        font = "Montserrat",
        extended = true,
        size = SX(15),
        weight = 800
    })

    surface.CreateFont("ExoHud_Sub", {
        font = "Montserrat",
        extended = true,
        size = SX(12),
        weight = 600
    })

    surface.CreateFont("ExoHud_Num", {
        font = "Montserrat",
        extended = true,
        size = SX(20),
        weight = 900
    })
end

BuildFonts()

hook.Add("OnScreenSizeChanged", "ExoHud_Fonts", BuildFonts)

local anim = {}
local alpha = 0
local pulse = 0

local function HasBoots(ply)
    if ply:GetNWBool("ExoBoots", false) then return true end

    if ply.GetNetVar then
        local acc = ply:GetNetVar("Accessories", {})

        if istable(acc) then
            for _, uid in pairs(acc) do
                if tostring(uid or "") == "exojump" then return true end
            end
        end
    end

    return false
end

hook.Add("HUDPaint", "ExoJump_ChargesHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local show = ply:Alive() and HasBoots(ply)
    local ft = FrameTime()

    alpha = Lerp(math.Clamp(ft * 8, 0, 1), alpha, show and 255 or 0)

    if alpha <= 3 then return end

    local charges = math.Clamp(ply:GetNWInt("ExoCharges", EXO_MAX), 0, EXO_MAX)
    local maxc = math.max(1, ply:GetNWInt("ExoMaxCharges", EXO_MAX))

    pulse = pulse + ft * 3.2

    local pw, ph = SX(30), SX(9)
    local gap = SX(6)
    local padx, pady = SX(14), SX(11)

    local barW = pw * maxc + gap * (maxc - 1)
    local w = barW + padx * 2
    local h = pady * 2 + SX(17) + ph + (charges <= 0 and SX(18) or 0)

    local x = ScrW() - w - SX(34)
    local y = ScrH() - h - SX(210)

    DrawRound(SX(10), x, y, w, h, Fade(clr_card, alpha * 0.75))
    DrawRoundOutlined(SX(10), x, y, w, h, Fade(clr_accent, alpha * 0.35), SX(1))
    DrawRound(SX(4), x, y + SX(8), SX(3), h - SX(16), Fade(clr_accent, alpha))

    draw.SimpleText("Экзо-Ботинки", "ExoHud_Title", x + padx, y + pady - SX(2), Fade(clr_text, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local rightTxt = charges .. "/" .. maxc
    draw.SimpleText(rightTxt, "ExoHud_Sub", x + w - padx, y + pady, Fade(charges > 0 and clr_cyan or clr_red, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    local by = y + pady + SX(19)

    for i = 1, maxc do
        local px = x + padx + (i - 1) * (pw + gap)
        local filled = i <= charges

        anim[i] = Lerp(math.Clamp(ft * 9, 0, 1), anim[i] or 0, filled and 1 or 0)

        DrawRound(SX(4), px, by, pw, ph, Fade(clr_empty, alpha * 0.65))

        if anim[i] > 0.01 then
            local col = Fade(clr_accent, alpha * (0.55 + anim[i] * 0.45))
            DrawRound(SX(4), px, by, pw * anim[i], ph, col)
            DrawRound(SX(4), px, by, pw * anim[i], math.max(1, ph * 0.42), Fade(clr_cyan, alpha * 0.35 * anim[i]))
        end
    end

    if charges <= 0 then
        local a = alpha * (0.55 + math.abs(math.sin(pulse)) * 0.45)
        draw.SimpleText("Заряд исчерпан", "ExoHud_Sub", x + w * 0.5, by + ph + SX(6), Fade(clr_red, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end)

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

hook.Add("hg_AdjustMouseSensitivity", "HG-LegKickAnim", function(ply)
    if ply:GetNWFloat("InLegKick", 0) > CurTime() then
        return math.min(math.max(0.02, 1 - (ply:GetNWFloat("InLegKick", 0) - CurTime()) * 2), 1)
    end
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "exojump charges hud loaded\n")
