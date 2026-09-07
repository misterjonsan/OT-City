zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
    return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect, prevspect, viewmode = nil, nil, 1
local hullscale = Vector(0, 0, 0)

net.Receive("ZB_SpectatePlayer", function(len)
    spect = net.ReadEntity()
    prevspect = net.ReadEntity()
    viewmode = net.ReadInt(4)

    timer.Simple(0.1, function()
        if not IsValid(LocalPlayer()) then return end
        LocalPlayer():SetHull(-hullscale, hullscale)
        LocalPlayer():SetHullDuck(-hullscale, hullscale)

        if viewmode == 3 then
            LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
        end
    end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime", function()
    local time = net.ReadFloat()
    local time2 = net.ReadFloat()
    local time3 = net.ReadFloat()

    zb.ROUND_TIME = time
    zb.ROUND_START = time2
    zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blursettings = {}
local hg_potatopc
hg = hg or {}

function hg.DrawBlur(panel, amount, passes, alpha)
    if is3d2d then return end
    amount = amount or 5
    hg_potatopc = hg_potatopc or hg.ConVars.potatopc

    if hg_potatopc:GetBool() then
        surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    else
        surface.SetMaterial(blur)
        surface.SetDrawColor(0, 0, 0, alpha or 125)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
        local x, y = panel:LocalToScreen(0, 0)
        if blursettings and blursettings[1] == amount and blursettings[2] == passes then
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
            return
        end
        blursettings = {amount, passes}
        for i = -(passes or 0.2), 1, 0.2 do
            blur:SetFloat("$blur", i * amount)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        end
    end
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint", "FUCKINGSAMENAMEUSEDINHOOKFUCKME", function()
    if LocalPlayer():Alive() then return end
    local spect = LocalPlayer():GetNWEntity("spect")
    if not IsValid(spect) then return end
    if viewmode == 3 then return end

    surface.SetFont("HomigradFont")
    surface.SetTextColor(255, 255, 255, 255)
    local txt = "Слежка за игроком: " .. spect:Name()
    local w, h = surface.GetTextSize(txt)
    surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
    surface.DrawText(txt)
    local txt2 = "Имя в игре: " .. spect:GetPlayerName()
    local w2, h2 = surface.GetTextSize(txt2)
    surface.SetTextPos(ScrW() / 2 - w2 / 2, ScrH() / 8 * 7 + h)
    surface.DrawText(txt2)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
    if not lply:Alive() then
        if lply:KeyDown(IN_ATTACK) then
            if not keydownattack then
                keydownattack = true
                net.Start("ZB_ChooseSpecPly")
                net.WriteInt(IN_ATTACK, 32)
                net.SendToServer()
            end
        else
            keydownattack = false
        end

        if lply:KeyDown(IN_ATTACK2) then
            if not keydownattack2 then
                keydownattack2 = true
                net.Start("ZB_ChooseSpecPly")
                net.WriteInt(IN_ATTACK2, 32)
                net.SendToServer()
            end
        else
            keydownattack2 = false
        end

        if lply:KeyDown(IN_RELOAD) then
            if not keydownreload then
                keydownreload = true
                net.Start("ZB_ChooseSpecPly")
                net.WriteInt(IN_RELOAD, 32)
                net.SendToServer()
            end
        else
            keydownreload = false
        end

        local spect = lply:GetNWEntity("spect", spect)
        if not IsValid(spect) then return end

        local viewmode = lply:GetNWInt("viewmode", viewmode)

        if viewmode == 3 then
            if lply:GetMoveType() ~= MOVETYPE_NOCLIP then
                lply:SetMoveType(MOVETYPE_NOCLIP)
            end
            lply:SetObserverMode(OBS_MODE_ROAMING)
            return
        else
            lply:SetPos(spect:GetPos())
        end

        local ent = hg.GetCurrentCharacter(spect)
        if not IsValid(ent) then return end

        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
        local bon = ent:GetBoneMatrix(headBone)

        if not bon then
            local eyePos = ent:EyePos()
            if eyePos and eyePos ~= vector_origin then
                pos = eyePos
                ang = ent:EyeAngles()
            else
                pos = ent:GetPos() + Vector(0, 0, 64)
                ang = ent:GetAngles()
            end
        else
            pos, ang = bon:GetTranslation(), bon:GetAngles()
        end

        local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()

        local tr = {}
        tr.start = pos
        tr.endpos = pos + eyeAng:Forward() * -120
        tr.filter = {ent, lply, spect}
        tr.mins = Vector(-4, -4, -4)
        tr.maxs = Vector(4, 4, 4)
        tr = util.TraceHull(tr)

        if viewmode == 2 then
            pos = tr.HitPos + eyeAng:Forward() * 8
            ang = eyeAng
        elseif viewmode == 1 then
            if ent ~= spect and IsValid(ent) then
                local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
                if eyeAtt then
                    ang = eyeAtt.Ang
                else
                    ang = spect:EyeAngles()
                end
            else
                ang = spect:EyeAngles()
            end
            pos = pos + spect:EyeAngles():Forward() * 8
        else
            pos = eyePos
            ang = eyeAng
        end

        ang[3] = 0

        local view
        local hg_newspectate = GetConVar("hg_newspectate")
        if hg_newspectate and hg_newspectate:GetBool() then
            if not lply.spectLastPos then
                lply.spectLastPos = pos
                lply.spectLastAng = ang
            end

            local lerpFactor = FrameTime() * 10
            lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
            lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

            view = {
                origin = lply.spectLastPos,
                angles = lply.spectLastAng,
                fov = fov,
            }
        else
            view = {
                origin = pos,
                angles = ang,
                fov = fov,
            }
        end

        return view
    else
        lply.spectLastPos = nil
        lply.spectLastAng = nil
        lply:SetObserverMode(OBS_MODE_NONE)
    end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
    if zb.fade > 0 then
        zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)
        surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
        surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
    end
end)

zb.ROUND_STATE = 0

net.Receive("RoundInfo", function()
    local rnd = net.ReadString()

    hook.Run("RoundInfoCalled", rnd)

    if zb.CROUND ~= rnd then
        if hg.DynaMusic then
            hg.DynaMusic:Stop()
        end
    end

    zb.CROUND = rnd
    zb.ROUND_STATE = net.ReadInt(4)

    if zb.ROUND_STATE == 0 then
        zb.fade = 7
    end

    if zb.CROUND ~= "" then
        if CurrentRound() then
            if zb.ROUND_STATE == 3 then
                if CurrentRound().EndRound then
                    CurrentRound():EndRound()
                end
            elseif zb.ROUND_STATE == 1 then
                if CurrentRound().RoundStart then
                    CurrentRound():RoundStart()
                end
            end
        end
    end
end)

if IsValid(scoreBoardMenu) then
    scoreBoardMenu:Remove()
    scoreBoardMenu = nil
end

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")

local font = function()
    local usefont = "Bahnschrift"
    if hg_font:GetString() ~= "" then
        usefont = hg_font:GetString()
    end
    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_TabTitle", {
    font = font(),
    size = ScreenScale(15),
    weight = 500,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_TabHeader", {
    font = font(),
    size = ScreenScale(10),
    weight = 500,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_TabRowName", {
    font = font(),
    size = ScreenScale(9),
    weight = 500,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_TabRowMeta", {
    font = font(),
    size = ScreenScale(7),
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont("ZB_TabButton", {
    font = font(),
    size = ScreenScale(6.4),
    weight = 500,
    antialias = true,
    extended = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
    if not IsValid(ply) then return end
    hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

    local json = util.TableToJSON(hg.playerInfo)
    file.Write("zcity_muted.txt", json)

    if file.Exists("zcity_muted.txt", "DATA") then
        local json2 = file.Read("zcity_muted.txt", "DATA")
        if json2 then
            hg.playerInfo = util.JSONToTable(json2)
        end
    end
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
    local ply = Player(data.userid)
    if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
        ply:SetMuted(hg.playerInfo[data.networkid][1])
        ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
    end
end)

hook.Add("InitPostEntity", "furryhuy", function()
    if file.Exists("zcity_muted.txt", "DATA") then
        local json = file.Read("zcity_muted.txt", "DATA")

        if json then
            hg.playerInfo = util.JSONToTable(json)
        end

        if hg.playerInfo then
            for i, ply in player.Iterator() do
                if not istable(hg.playerInfo[ply:SteamID()]) then
                    local muted = hg.playerInfo[ply:SteamID()]
                    hg.playerInfo[ply:SteamID()] = {}
                    hg.playerInfo[ply:SteamID()][1] = muted
                    hg.playerInfo[ply:SteamID()][2] = 1
                end

                if hg.playerInfo[ply:SteamID()] then
                    ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
                    ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
                end
            end
        end
    end
end)

local tab_bg = Color(3, 5, 9, 246)
local tab_bg_soft = Color(6, 12, 20, 236)
local tab_card = Color(9, 18, 30, 238)
local tab_card_alt = Color(12, 22, 36, 232)
local tab_text = Color(240, 248, 255)
local tab_muted = Color(150, 190, 220)
local tab_accent = Color(31, 182, 255)
local tab_accent_dark = Color(10, 38, 64)
local tab_gold = Color(255, 190, 75)
local tab_red = Color(210, 72, 72)
local tab_orange = Color(230, 145, 55)
local tab_blue = Color(127, 230, 255)
local tab_purple = Color(168, 132, 255)
local tab_gray = Color(150, 175, 195)
local tab_spec = Color(112, 126, 140)
local tab_button_idle = Color(31, 182, 255, 18)
local tab_button_hover = Color(31, 182, 255, 38)
local tab_outline = Color(90, 210, 255, 160)
local TAB_RADIUS = 24

local function TabFT()
    return FrameTime()
end

local function TabLerp(speed, from, to)
    return Lerp(math.Clamp(TabFT() * speed, 0, 1), from, to)
end

local function DrawTabBlock(x, y, w, h, col, radius)
    radius = math.min(radius or TAB_RADIUS, math.floor(math.min(w, h) / 2))

    if RNDX and RNDX.Draw then
        RNDX.Draw(radius, x, y, w, h, col)
    elseif rndx and rndx.Draw then
        rndx.Draw(radius, x, y, w, h, col)
    else
        draw.RoundedBox(radius, x, y, w, h, col)
    end
end

local function DrawTabOutline(x, y, w, h, col, radius, thickness)
    radius = math.min(radius or TAB_RADIUS, math.floor(math.min(w, h) / 2))
    thickness = thickness or 2

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

local function DrawTabText(text, fontName, x, y, col, ax, ay)
    draw.SimpleText(text, fontName, x + 1, y + 1, Color(0, 0, 0, math.min(col.a or 255, 185)), ax, ay)
    draw.SimpleText(text, fontName, x, y, col, ax, ay)
end

local function GetGroupTagData(ply)
    local tag = ""
    local tagColor = tab_gray
    local outlineColor = Color(18, 18, 18)

    if ply:IsSuperAdmin() then
        tag = "◆ КП"
        tagColor = Color(255, 215, 90)
        outlineColor = Color(120, 85, 10)

    elseif ply:GetUserGroup() == "head_admin" then
        tag = "◆ ГЛ.АДМИН"
        tagColor = Color(255, 70, 70)
        outlineColor = Color(110, 20, 20)

    elseif ply:GetUserGroup() == "d_head_admin" then
        tag = "◆ ЗАМ.ГЛ.АДМИН"
        tagColor = Color(255, 110, 80)
        outlineColor = Color(120, 45, 20)

    elseif ply:GetUserGroup() == "st_admin" then
        tag = "◆ СТ.АДМИН"
        tagColor = Color(255, 140, 140)
        outlineColor = Color(120, 50, 50)

    elseif ply:GetUserGroup() == "amb" then
        tag = "◆ АМБАССАДОР"
        tagColor = Color(255, 105, 180)
        outlineColor = Color(125, 35, 85)

    elseif ply:GetUserGroup() == "admin" then
        tag = "● МЛ.АДМИН"
        tagColor = Color(255, 80, 80)
        outlineColor = Color(120, 30, 30)

    elseif ply:GetUserGroup() == "admin+" then
        tag = "● АДМИН"
        tagColor = Color(255, 60, 120)
        outlineColor = Color(120, 20, 60)

    elseif ply:GetUserGroup() == "operator" then
        tag = "● ОПЕРАТОР"
        tagColor = Color(80, 220, 255)
        outlineColor = Color(25, 90, 120)

    elseif ply:GetUserGroup() == "sponsor" then
        tag = "● СПОНСОР"
        tagColor = Color(127, 230, 255)
        outlineColor = Color(18, 74, 104)

    elseif ply:GetUserGroup() == "head_event" then
        tag = "◆ ГЛ.ИВЕНТОЛОГ"
        tagColor = Color(168, 85, 247)
        outlineColor = Color(76, 29, 149)

    elseif ply:GetUserGroup() == "d_head_event" then
        tag = "◆ ЗАМ.ГЛ.ИВЕНТОЛОГА"
        tagColor = Color(139, 92, 246)
        outlineColor = Color(67, 36, 140)

    elseif ply:GetUserGroup() == "st_event" then
        tag = "● СТ.ИВЕНТОЛОГ"
        tagColor = Color(167, 139, 250)
        outlineColor = Color(70, 50, 130)

    elseif ply:GetUserGroup() == "event" then
        tag = "● ИВЕНТОЛОГ"
        tagColor = Color(192, 132, 252)
        outlineColor = Color(85, 40, 125)

    elseif ply:GetUserGroup() == "moderator" then
        tag = "● МОДЕРАТОР"
        tagColor = Color(90, 170, 255)
        outlineColor = Color(35, 75, 120)

    elseif ply:GetUserGroup() == "vip" then
        tag = "● VIP"
        tagColor = Color(190, 120, 255)
        outlineColor = Color(85, 45, 120)
    end

    return tag, tagColor, outlineColor
end

local function TrimTextToWidth(text, fontName, maxWidth)
    surface.SetFont(fontName)

    if surface.GetTextSize(text) <= maxWidth then
        return text
    end

    local ellipsis = "..."
    local len = utf8.len(text) or #text

    while len > 0 do
        local part = utf8.sub(text, 1, len)

        if surface.GetTextSize(part .. ellipsis) <= maxWidth then
            return part .. ellipsis
        end

        len = len - 1
    end

    return ellipsis
end

local function DrawMuteGlyph(x, y, s, muted, hovered)
    local iconColor = muted and (hovered and Color(255, 120, 120) or Color(220, 80, 80)) or (hovered and Color(255, 255, 255) or Color(225, 245, 255))
    local shellColor = hovered and Color(55, 190, 255, 24) or Color(255, 255, 255, 8)

    DrawTabBlock(x, y, s, s, shellColor, 14)
    DrawTabOutline(x, y, s, s, Color(55, 190, 255, hovered and 95 or 45), 14, 1)

    local cx = x + s * 0.48
    local cy = y + s * 0.5

    surface.SetDrawColor(iconColor)
    draw.NoTexture()
    surface.DrawPoly({
        {x = cx - s * 0.19, y = cy - s * 0.11},
        {x = cx - s * 0.06, y = cy - s * 0.11},
        {x = cx + s * 0.08, y = cy - s * 0.24},
        {x = cx + s * 0.08, y = cy + s * 0.24},
        {x = cx - s * 0.06, y = cy + s * 0.11},
        {x = cx - s * 0.19, y = cy + s * 0.11}
    })

    if muted then
        surface.DrawLine(cx + s * 0.14, cy - s * 0.18, cx + s * 0.31, cy + s * 0.18)
        surface.DrawLine(cx + s * 0.31, cy - s * 0.18, cx + s * 0.14, cy + s * 0.18)
        surface.DrawLine(cx + s * 0.15, cy - s * 0.17, cx + s * 0.30, cy + s * 0.17)
        surface.DrawLine(cx + s * 0.30, cy - s * 0.17, cx + s * 0.15, cy + s * 0.17)
    else
        local px = cx + s * 0.14
        surface.DrawLine(px, cy - s * 0.13, px + s * 0.08, cy - s * 0.05)
        surface.DrawLine(px, cy + s * 0.13, px + s * 0.08, cy + s * 0.05)
        surface.DrawLine(px + s * 0.10, cy - s * 0.20, px + s * 0.18, cy - s * 0.11)
        surface.DrawLine(px + s * 0.10, cy + s * 0.20, px + s * 0.18, cy + s * 0.11)
    end
end

local function PaintPremiumButton(self, w, h, active)
    local hovered = self:IsHovered()
    self._a = TabLerp(12, self._a or 0, hovered and 1 or 0)
    self._active = TabLerp(12, self._active or 0, active and 1 or 0)

    local radius = math.min(20, h / 2)
    local pulse = active and (0.5 + math.sin(CurTime() * 7) * 0.5) or 0

    self._press = TabLerp(16, self._press or 0, self:IsDown() and 1 or 0)

    local squeeze = self._press * 2

    DrawTabBlock(squeeze, squeeze, w - squeeze * 2, h - squeeze * 2, Color(tab_accent_dark.r, tab_accent_dark.g, tab_accent_dark.b, 150 + self._active * 60), radius)
    DrawTabBlock(squeeze, squeeze, w - squeeze * 2, h - squeeze * 2, Color(tab_accent.r, tab_accent.g, tab_accent.b, 14 + self._a * 30 + self._active * 72 + pulse * 16), radius)
    DrawTabOutline(squeeze, squeeze, w - squeeze * 2, h - squeeze * 2, Color(tab_accent.r, tab_accent.g, tab_accent.b, 48 + self._a * 95 + self._active * 90), radius, 2)

    if self._active > 0.01 then
        DrawTabBlock(w * 0.5 - (w * 0.3) * self._active, h - 3, (w * 0.6) * self._active, 2, Color(tab_accent.r, tab_accent.g, tab_accent.b, 200 * self._active), 1)
    end
end

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
    local Menu = DermaMenu()

    if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then
        addToPlayerInfo(ply, false, 1)
    end

    local mute = Menu:AddOption("Замутить", function(self)
        if hg.muteall or hg.mutespect then return end
        self:SetChecked(not ply:IsMuted())
        ply:SetMuted(not ply:IsMuted())
        addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
    end)

    mute:SetIsCheckable(true)
    mute:SetChecked(ply:IsMuted())

    local volumeSlider = vgui.Create("DSlider", Menu)
    volumeSlider:SetLockY(0.5)
    volumeSlider:SetTrapInside(true)
    volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2])

    volumeSlider.OnValueChanged = function(self, x)
        if not IsValid(ply) then return end
        if hg.muteall or (hg.mutespect and not ply:Alive()) then return end
        hg.playerInfo[ply:SteamID()][2] = x
        ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
        addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
    end

    function volumeSlider:Paint(w, h)
        DrawTabBlock(0, 0, w, h, Color(10, 18, 22, 245), 12)
        DrawTabBlock(0, 0, w * self:GetSlideX(), h, Color(55, 190, 255, 210), 12)
        DrawTabOutline(0, 0, w, h, Color(80, 198, 255, 100), 12, 1)
        draw.DrawText((math.Round(100 * self:GetSlideX(), 0)) .. "%", "DermaDefault", w / 2, h / 4, color_white, TEXT_ALIGN_CENTER)
    end

    function volumeSlider.Knob:Paint()
    end

    Menu:AddPanel(volumeSlider)
    Menu:Open()
end

hook.Add("Player Getup", "nomorespect", function(ply)
    if not hg.mutespect then return end
    ply:SetVoiceVolumeScale(not hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
    if not hg.mutespect then return end
    ply:SetVoiceVolumeScale(0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
    if eightbit and eightbit.EnableEffect and ply.UserID then
        eightbit.EnableEffect(ply:UserID(), 0)
    end
end)

local function RunSAMCommand(cmd, ply)
    if not IsValid(ply) then return end
    RunConsoleCommand("say", "!" .. cmd .. " " .. ply:SteamID())
end

local function CloseAllActionRows(container)
    if not IsValid(container) then return end

    for _, child in ipairs(container:GetChildren()) do
        if IsValid(child) and child.CloseActions then
            child:CloseActions()
        end
    end
end

if CLIENT then
    if timer.Exists("OTBoardRefreshRows") then timer.Remove("OTBoardRefreshRows") end
    if IsValid(_G.OTBoardFrame) then _G.OTBoardFrame:Remove() end

    hook.Remove("ScoreboardShow", "OTBoard_Open")
    hook.Remove("ScoreboardHide", "OTBoard_Close")
    hook.Remove("InitPostEntity", "OTBoard_DisableDefault_1")
    hook.Remove("OnGamemodeLoaded", "OTBoard_DisableDefault_2")
    hook.Remove("DarkRPFinishedLoading", "OTBoard_DisableDefault_3")
end

surface.CreateFont("OTBoard.Title", {font = "Montserrat SemiBold", size = 34, weight = 700, extended = true})
surface.CreateFont("OTBoard.Subtitle", {font = "Montserrat Medium", size = 17, weight = 500, extended = true})
surface.CreateFont("OTBoard.Header", {font = "Montserrat SemiBold", size = 15, weight = 650, extended = true})
surface.CreateFont("OTBoard.Row", {font = "Montserrat Medium", size = 18, weight = 500, extended = true})
surface.CreateFont("OTBoard.RowSmall", {font = "Montserrat Medium", size = 14, weight = 500, extended = true})
surface.CreateFont("OTBoard.StatValue", {font = "Montserrat SemiBold", size = 15, weight = 650, extended = true})
surface.CreateFont("OTBoard.StatLabel", {font = "Montserrat Medium", size = 14, weight = 500, extended = true})

local ScoreFrame = nil
_G.OTBoardFrame = nil

local COLOR_BG = Color(3, 5, 9, 246)
local COLOR_PANEL = Color(9, 18, 30, 245)
local COLOR_BG_SOFT = Color(6, 12, 20, 250)
local COLOR_PANEL_ALT = Color(12, 22, 36, 245)
local COLOR_PANEL_HOVER = Color(18, 38, 60, 250)
local COLOR_TEXT = Color(240, 248, 255)
local COLOR_TEXT_DIM = Color(150, 190, 220)
local COLOR_ACCENT = Color(31, 182, 255)
local COLOR_ACCENT_SOFT = Color(31, 182, 255, 60)
local COLOR_BADGE = Color(90, 210, 255)
local SHOW_USER_BADGE = false

local CUSTOM_RANKS = {}

local function GetRankTable()
    if istable(Ranks) then return Ranks end

    return CUSTOM_RANKS
end

local function GetRankData(group)
    if not group then return nil end

    return GetRankTable()[group] or CUSTOM_RANKS[group]
end

local RANK_ORDER = {
    "superadmin", "vice_superadmin", "kurator", "d_kurator", "manager", "developer",
    "head_admin", "d_head_admin", "st_admin", "admin", "m_admin",
    "head_eventer", "st_eventer", "eventer", "m_eventer",
    "moder", "m_moder", "moderator", "helper",
    "ultra", "prime", "vip", "sponsor", "youtube", "user"
}

local FORCED_RANKS = {
    ["76561198872477274"] = "kurator"
}

local RANK_WEIGHT = {}

for i, id in ipairs(RANK_ORDER) do
    RANK_WEIGHT[id] = #RANK_ORDER - i + 1
end

local MATERIAL_CACHE = {}

local function GetIcon(path)
    if not path or path == "" then return nil end

    if MATERIAL_CACHE[path] == nil then
        MATERIAL_CACHE[path] = Material(path, "smooth") or false
    end

    return MATERIAL_CACHE[path] or nil
 end

local function GetForcedGroup(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end

    local sid64 = ply.SteamID64 and ply:SteamID64() or nil
    if not sid64 then return nil end

    return FORCED_RANKS[sid64]
end

local function GetUserGroup(ply)
    if not IsValid(ply) then return "user" end

    local forced = GetForcedGroup(ply)
    if forced then return forced end

    local group = ply.GetUserGroup and ply:GetUserGroup() or "user"
    if not group or group == "" then group = "user" end

    group = string.lower(group)

    if not GetRankData(group) then
        if ply:IsSuperAdmin() then
            group = "superadmin"
        elseif ply:IsAdmin() then
            group = "admin"
        end
    end

    return group
end

local function GetRank(ply)
    local group = GetUserGroup(ply)
    local rank = GetRankData(group)

    if not rank then
        local pretty = string.gsub(group, "_", " ")
        pretty = string.upper(string.sub(pretty, 1, 1)) .. string.sub(pretty, 2)

        rank = {name = pretty, color = COLOR_BADGE, icon = "icon16/user.png"}
        CUSTOM_RANKS[group] = rank
    end

    return rank, group
end

local function GetRankWeight(ply)
    local _, group = GetRank(ply)

    return RANK_WEIGHT[group] or 0
end

local function ShouldShowRank(ply)
    if not IsValid(ply) then return false end

    local _, group = GetRank(ply)

    if group == "user" and not SHOW_USER_BADGE then return false end

    return true
end

local function RX(x)
    return math.floor(x * ScrW() / 1920)
end

local function RY(y)
    return math.floor(y * ScrH() / 1080)
end

local function RNDXBox(r, x, y, w, h, col)
    if RNDX and RNDX.Draw then
        RNDX.Draw(r, x, y, w, h, col)
        return
    end

    if RNDX and RNDX.RoundedBox then
        RNDX.RoundedBox(r, x, y, w, h, col)
        return
    end

    if RNDX and RNDX.DrawRoundedBox then
        RNDX.DrawRoundedBox(r, x, y, w, h, col)
        return
    end

    if gSims_RNDX and gSims_RNDX.RoundedBox then
        gSims_RNDX.RoundedBox(r, x, y, w, h, col)
        return
    end

    if libNyx and libNyx.RNDX and libNyx.RNDX.RoundedBox then
        libNyx.RNDX.RoundedBox(r, x, y, w, h, col)
        return
    end

    draw.RoundedBox(r, x, y, w, h, col)
end

local function DrawPanel(x, y, w, h, r, col)
    RNDXBox(r, x, y, w, h, col)
end

local function CountByKeywords(keywords)
    local c = 0

    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) then
            local job = string.lower(SafeJob(v))

            for _, key in ipairs(keywords) do
                if string.find(job, key, 1, true) then
                    c = c + 1
                    break
                end
            end
        end
    end

    return c
end

local function CountLaw()
    return CountByKeywords({
        "полиция",
        "полицейский",
        "омон",
        "фсб",
        "мвд",
        "судья",
        "прокурор",
        "военный",
        "силов",
        "спецназ"
    })
end

local function CountCrime()
    return CountByKeywords({
        "криминал",
        "бандит",
        "мафия",
        "вор",
        "грабитель",
        "убийца",
        "нарко",
        "картель",
        "рэкет",
        "преступ"
    })
end

local function SafeNick(ply)
    if not IsValid(ply) then return "Unknown" end
    local nick = ply:Nick()
    if not nick or nick == "" then return "Unknown" end
    return nick
end

local function GetIdentifier(ply)
    if not IsValid(ply) then return "000000" end
    local sid64 = ply:SteamID64() or "0"
    sid64 = tostring(sid64)
    if #sid64 < 6 then return string.rep("0", 6 - #sid64) .. sid64 end
    return string.sub(sid64, -6)
end

local function SafeJob(ply)
    if not IsValid(ply) then return "Без работы" end

    if ply.getDarkRPVar then
        local job = ply:getDarkRPVar("job")
        if job and job ~= "" then return job end
    end

    local teamName = team.GetName(ply:Team())
    if teamName and teamName ~= "" then return teamName end

    return "Без работы"
end

local function SafeJobColor(ply)
    if not IsValid(ply) then return COLOR_ACCENT end

    local c = team.GetColor(ply:Team())
    if not c then return COLOR_ACCENT end

    local yellowLike = c.r > 150 and c.g > 130 and c.b < 120
    local greenLike = c.g > c.r and c.g > c.b and c.g > 100

    if yellowLike or greenLike then
        return COLOR_ACCENT
    end

    return c
end

local function SafePlayTime(ply)
    if not IsValid(ply) then return "00:00:00" end

    local seconds = 0

    if ply.GetUTimeTotalTime then
        seconds = tonumber(ply:GetUTimeTotalTime()) or 0
    elseif ply.GetTimeTotalSeconds then
        seconds = tonumber(ply:GetTimeTotalSeconds()) or 0
    elseif ply.GetNWInt then
        seconds = tonumber(ply:GetNWInt("PlayTime", 0)) or tonumber(ply:GetNWInt("playtime", 0)) or 0
    end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    return string.format("%02d:%02d:%02d", h, m, s)
end

local function IsStaff(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not isfunction(ply.IsAdmin) then return false end

    return ply:IsAdmin()
end

local function CountAdmins()
    local c = 0

    for _, v in ipairs(player.GetAll()) do
        if IsStaff(v) then
            c = c + 1
        end
    end

    return c
end

local function GetServerSlots()
    return game.MaxPlayers and game.MaxPlayers() or 128
end

local function GetPingColor(ping)
    if ping <= 35 then return Color(255, 255, 255) end
    if ping <= 70 then return Color(220, 230, 235) end
    if ping <= 110 then return Color(160, 196, 214) end
    if ping <= 160 then return Color(74, 144, 178) end
    return Color(30, 93, 123)
end

local function TrimToWidth(text, font, maxW)
    text = tostring(text or "")
    surface.SetFont(font)

    if surface.GetTextSize(text) <= maxW then return text end

    local ell = "..."
    local ew = surface.GetTextSize(ell)
    local len = utf8.len(text) or #text

    for i = len, 1, -1 do
        local sub = utf8.sub(text, 1, i)
        if surface.GetTextSize(sub) + ew <= maxW then
            return sub .. ell
        end
    end

    return ell
end

local function SortPlayers(list)
    table.sort(list, function(a, b)
        if not IsValid(a) or not IsValid(b) then return IsValid(a) end

        local aw = GetRankWeight(a)
        local bw = GetRankWeight(b)

        if aw ~= bw then
            return aw > bw
        end

        local at = a:Team()
        local bt = b:Team()

        if at == bt then
            return SafeNick(a):lower() < SafeNick(b):lower()
        end

        return at < bt
    end)
end

local function DrawSearchIcon(x, y, s, col)
    surface.SetDrawColor(col)
    draw.NoTexture()
    surface.DrawCircle(x + s * 0.35, y + s * 0.35, s * 0.24, col.r, col.g, col.b, col.a)
    surface.DrawLine(x + s * 0.53, y + s * 0.53, x + s * 0.77, y + s * 0.77)
    surface.DrawLine(x + s * 0.56, y + s * 0.53, x + s * 0.79, y + s * 0.76)
end

local function DrawStatIcon(kind, x, y, col)
    surface.SetDrawColor(col)
    draw.NoTexture()

    if kind == "people" then
        surface.DrawCircle(x + 6, y + 7, 3, col.r, col.g, col.b, col.a)
        surface.DrawCircle(x + 14, y + 7, 3, col.r, col.g, col.b, col.a)
        surface.DrawRect(x + 3, y + 11, 6, 4)
        surface.DrawRect(x + 11, y + 11, 6, 4)
    elseif kind == "shield" then
        surface.DrawPoly({
            {x = x + 10, y = y + 1},
            {x = x + 17, y = y + 4},
            {x = x + 16, y = y + 13},
            {x = x + 10, y = y + 18},
            {x = x + 4, y = y + 13},
            {x = x + 3, y = y + 4}
        })
    end
end

local function DrawHeaderIcon(kind, x, y, col)
    surface.SetDrawColor(col)
    draw.NoTexture()

    if kind == "index" then
        surface.DrawRect(x + 2, y + 2, 10, 10)
    elseif kind == "player" then
        surface.DrawCircle(x + 7, y + 5, 3, col.r, col.g, col.b, col.a)
        surface.DrawRect(x + 3, y + 9, 8, 4)
    elseif kind == "job" then
        surface.DrawOutlinedRect(x + 2, y + 3, 11, 8, 1)
        surface.DrawRect(x + 4, y + 5, 7, 2)
        surface.DrawRect(x + 4, y + 8, 5, 2)
    elseif kind == "id" then
        surface.DrawOutlinedRect(x + 2, y + 3, 11, 8, 1)
        surface.DrawRect(x + 4, y + 5, 2, 2)
        surface.DrawRect(x + 7, y + 5, 4, 2)
    elseif kind == "time" then
        surface.DrawCircle(x + 7, y + 7, 5, col.r, col.g, col.b, col.a)
        surface.DrawLine(x + 7, y + 7, x + 7, y + 4)
        surface.DrawLine(x + 7, y + 7, x + 9, y + 8)
    elseif kind == "ping" then
        surface.DrawRect(x + 1, y + 9, 2, 3)
        surface.DrawRect(x + 5, y + 7, 2, 5)
        surface.DrawRect(x + 9, y + 4, 2, 8)
    end
end

local function DisableDefaultScoreboard()
    hook.Remove("ScoreboardShow", "FAdmin_scoreboard")
    hook.Remove("ScoreboardHide", "FAdmin_scoreboard")
    hook.Remove("HUDDrawScoreBoard", "FAdmin_scoreboard")
end

local function BoardEase(frac)
    return 1 - math.pow(1 - math.Clamp(frac, 0, 1), 3)
end

local function SkinBoardScroll(scroll)
    local bar = scroll:GetVBar()

    bar:SetWide(RX(7))
    bar.Paint = function(self, w, h)
        RNDXBox(4, 1, 0, w - 2, h, Color(255, 255, 255, 6))
    end

    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end

    bar.btnGrip.Paint = function(self, w, h)
        RNDXBox(4, 1, 0, w - 2, h, Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, self:IsHovered() and 210 or 150))
    end
end

local function CreateFooterStat(parent, iconType, label, value)
    local pnl = vgui.Create("DPanel", parent)

    pnl:SetWide(RX(200))
    pnl:Dock(LEFT)
    pnl:DockMargin(0, 0, RX(10), 0)
    pnl.LabelText = label
    pnl.ValueText = tostring(value)

    pnl.Paint = function(self, w, h)
        DrawPanel(0, 0, w, h, 12, COLOR_PANEL)
        RNDXBox(3, 0, RY(9), math.max(2, RX(3)), h - RY(18), Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 200))

        local iconY = math.floor(h * 0.5 - 15)

        RNDXBox(10, RX(12), iconY, 30, 30, Color(255, 255, 255, 5))
        DrawStatIcon(iconType, RX(16), iconY + 5, COLOR_ACCENT)

        draw.SimpleText(self.LabelText, "OTBoard.StatLabel", RX(52), h * 0.5 - 8, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.ValueText, "OTBoard.StatValue", RX(52), h * 0.5 + 7, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local val = {}

    function val:SetText(text)
        pnl.ValueText = tostring(text or "")
    end

    function val:SizeToContents()
    end

    return pnl, val
end

local function CreateBoardButton(parent, text, dock, activeFunc, clickFunc)
    local btn = vgui.Create("DButton", parent)

    btn:SetText("")
    btn:Dock(dock)
    btn:DockMargin(dock == LEFT and 0 or RX(8), 0, dock == LEFT and RX(8) or 0, 0)
    btn:SetCursor("hand")

    surface.SetFont("OTBoard.Header")

    local tw = select(1, surface.GetTextSize(text))

    btn:SetWide(tw + RX(34))
    btn.Paint = function(self, w, h)
        PaintPremiumButton(self, w, h, activeFunc and activeFunc() or false)
        draw.SimpleText(text, "OTBoard.Header", w * 0.5, h * 0.5, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = clickFunc

    return btn
end

local function CreateBoardRow(parent, ply, idx, isSpectator)
    local rowH = RY(52)
    local row = vgui.Create("DButton", parent)

    row:SetText("")
    row:SetTall(rowH)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, RY(8))
    row:SetCursor("hand")

    row.ply = ply
    row.Index = idx
    row.IsSpec = isSpectator
    row.MenuOpen = false
    row.AnimFrac = 0
    row.HoverFrac = 0
    row.InAnim = 0
    row.ActionsH = 0
    row.AnimStart = CurTime()
    row.AnimDelay = math.min((idx or 1) * 0.03, 0.4)

    local avatar = vgui.Create("AvatarImage", row)

    avatar:SetSize(RX(34), RX(34))
    avatar:SetPlayer(ply, 64)
    avatar:SetMouseInputEnabled(false)
    row.Avatar = avatar

    local mute = vgui.Create("DButton", row)

    mute:SetText("")
    mute:SetSize(RY(30), RY(30))
    mute:SetCursor("hand")

    mute.Paint = function(self, w, h)
        if not IsValid(ply) then return end
        DrawMuteGlyph(0, 0, w, ply:IsMuted(), self:IsHovered())
    end

    mute.DoClick = function(self)
        if not IsValid(ply) then return end
        OpenPlayerSoundSettings(self, ply)
    end

    row.MuteButton = mute

    if IsValid(ply) then
        ply.soundButton = mute
    end

    local function AddActionButton(parentPanel, text, callback)
        local btn = vgui.Create("DButton", parentPanel)

        btn:SetText("")
        btn:SetTall(RY(26))
        btn:SetCursor("hand")

        surface.SetFont("OTBoard.RowSmall")

        local tw = select(1, surface.GetTextSize(text))

        btn:SetWide(tw + RX(22))
        btn.HoverFrac = 0
        btn.Paint = function(self, w, h)
            self.HoverFrac = TabLerp(12, self.HoverFrac or 0, self:IsHovered() and 1 or 0)

            local frac = row.AnimFrac or 0

            DrawPanel(0, 0, w, h, 8, COLOR_PANEL_ALT)
            RNDXBox(8, 0, 0, w, h, Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, (10 + self.HoverFrac * 42) * frac))
            draw.SimpleText(text, "OTBoard.RowSmall", w * 0.5, h * 0.5, Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, math.Clamp(frac * 255, 0, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = callback

        return btn
    end

    local function LayoutActions(container, buttons)
        local maxW = math.max(RX(80), container:GetWide())
        local gap = RX(6)
        local lineH = RY(26)
        local x, y = 0, 0

        for _, btn in ipairs(buttons) do
            if IsValid(btn) then
                local bw = btn:GetWide()

                if x > 0 and x + bw > maxW then
                    x = 0
                    y = y + lineH + gap
                end

                btn:SetPos(x, y)
                x = x + bw + gap
            end
        end

        return y + lineH
    end

    local function CreateActions(self)
        if IsValid(self.ActionPanel) then return end

        local actions = vgui.Create("DPanel", self)

        actions.Paint = nil
        actions:SetPos(RX(14), rowH + RY(2))
        actions:SetSize(math.max(RX(80), self:GetWide() - RX(28)), RY(26))

        self.ActionPanel = actions

        local buttons = {}
        local lp = LocalPlayer()
        local group = IsValid(lp) and lp:GetUserGroup() or ""
        local isAdmin = IsValid(lp) and (lp:IsAdmin() or group == "moderator" or group == "operator")

        if isAdmin then
            buttons[#buttons + 1] = AddActionButton(actions, "goto", function()
                if not IsValid(self.ply) then return end
                RunSAMCommand("goto", self.ply)
            end)

            buttons[#buttons + 1] = AddActionButton(actions, "bring", function()
                if not IsValid(self.ply) then return end
                RunSAMCommand("bring", self.ply)
            end)

            buttons[#buttons + 1] = AddActionButton(actions, "return", function()
                if not IsValid(self.ply) then return end
                RunSAMCommand("return", self.ply)
            end)

            buttons[#buttons + 1] = AddActionButton(actions, "respawn", function()
                if not IsValid(self.ply) then return end
                RunSAMCommand("respawn", self.ply)
            end)
        end

        buttons[#buttons + 1] = AddActionButton(actions, "Профиль", function()
            if not IsValid(self.ply) or self.ply:IsBot() then return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. (self.ply:SteamID64() or ""))
        end)

        buttons[#buttons + 1] = AddActionButton(actions, "SteamID", function()
            if not IsValid(self.ply) then return end
            SetClipboardText(self.ply:SteamID() or "")
        end)

        buttons[#buttons + 1] = AddActionButton(actions, "Ник", function()
            if not IsValid(self.ply) then return end
            SetClipboardText(SafeNick(self.ply))
        end)

        self.ActionButtons = buttons
        self.ActionsH = LayoutActions(actions, buttons) + RY(12)

        actions:SetTall(self.ActionsH - RY(12))
    end

    local function RelayoutParent(self)
        local par = self:GetParent()

        if IsValid(par) then
            par:InvalidateLayout(true)
            par:SizeToChildren(false, true)
        end
    end

    local function CloseActions(self)
        self.MenuOpen = false

        local par = self:GetParent()

        if IsValid(par) and par.OpenedRow == self then
            par.OpenedRow = nil
        end
    end

    row.PerformLayout = function(self, w, h)
        if IsValid(self.Avatar) then
            local av = RY(34)

            self.Avatar:SetSize(av, av)
            self.Avatar:SetPos(RX(12), math.floor(rowH * 0.5 - av * 0.5))
        end

        if IsValid(self.MuteButton) then
            local ms = RY(30)

            self.MuteButton:SetSize(ms, ms)
            self.MuteButton:SetPos(w - RX(12) - ms, math.floor(rowH * 0.5 - ms * 0.5))
        end

        if IsValid(self.ActionPanel) then
            self.ActionPanel:SetPos(RX(14), rowH + RY(2))
            self.ActionPanel:SetWide(math.max(RX(80), w - RX(28)))
            self.ActionPanel:SetMouseInputEnabled((self.AnimFrac or 0) > 0.8)
        end
    end

    row.Think = function(self)
        self.HoverFrac = TabLerp(12, self.HoverFrac or 0, self:IsHovered() and 1 or 0)

        local raw = math.Clamp((CurTime() - (self.AnimStart or CurTime()) - (self.AnimDelay or 0)) / 0.28, 0, 1)

        self.InAnim = BoardEase(raw)
        self:SetAlpha(math.floor(255 * self.InAnim))

        local target = self.MenuOpen and 1 or 0

        self.AnimFrac = Lerp(FrameTime() * 12, self.AnimFrac or 0, target)

        if math.abs(self.AnimFrac - target) < 0.01 then
            self.AnimFrac = target
        end

        local newTall = math.floor(rowH + (self.ActionsH or 0) * self.AnimFrac)

        if self:GetTall() ~= newTall then
            self:SetTall(newTall)
            RelayoutParent(self)
        end

        if not self.MenuOpen and self.AnimFrac <= 0 and IsValid(self.ActionPanel) then
            self.ActionPanel:Remove()
            self.ActionPanel = nil
            self.ActionsH = 0
        end

        if IsValid(self.ActionPanel) then
            self.ActionPanel:SetAlpha(math.Clamp(self.AnimFrac * 255, 0, 255))
        end
    end

    row.Paint = function(self, w, h)
        local hf = self.HoverFrac or 0
        local slide = math.floor((1 - (self.InAnim or 1)) * RX(24))
        local accent = self.IsSpec and Color(120, 140, 158) or COLOR_ACCENT

        DrawPanel(slide, 0, w - slide, h, 12, Color(
            COLOR_PANEL.r + (COLOR_PANEL_HOVER.r - COLOR_PANEL.r) * hf,
            COLOR_PANEL.g + (COLOR_PANEL_HOVER.g - COLOR_PANEL.g) * hf,
            COLOR_PANEL.b + (COLOR_PANEL_HOVER.b - COLOR_PANEL.b) * hf,
            COLOR_PANEL.a
        ))

        local barH = rowH * (0.34 + hf * 0.52)

        RNDXBox(12, slide, 0, w - slide, h, Color(accent.r, accent.g, accent.b, 12 * hf))
        RNDXBox(4, slide, rowH * 0.5 - barH * 0.5, math.max(2, RX(3)), barH, Color(accent.r, accent.g, accent.b, 70 + hf * 185))

        if not IsValid(self.ply) then return end

        local cy = rowH * 0.5
        local textX = slide + RX(56)
        local muteW = RY(30)
        local ping = self.ply:Ping() or 0

        surface.SetFont("OTBoard.Row")

        local pingW = select(1, surface.GetTextSize(tostring(ping)))
        local pingRight = w - RX(14) - muteW - RX(8)
        local limit = pingRight - pingW - RX(14)

        local tag, tagColor, outlineColor = GetGroupTagData(self.ply)

        if (tonumber(self.ply:GetNetVar("DozorUntil", 0)) or 0) > CurTime() then
            tag = "⛔ ПОД ДОЗОРОМ"
            tagColor = Color(255, 170, 70)
            outlineColor = Color(120, 55, 10)
        end

        local nickSpace = math.max(RX(50), limit - textX)
        local nick = TrimToWidth(SafeNick(self.ply), "OTBoard.Row", tag ~= "" and math.floor(nickSpace * 0.62) or nickSpace)
        local nickW = draw.SimpleText(nick, "OTBoard.Row", textX, cy, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if tag ~= "" then
            local tagX = textX + nickW + RX(8)
            local trimmed = TrimToWidth(tag, "OTBoard.RowSmall", math.max(RX(24), limit - tagX))

            draw.SimpleText(trimmed, "OTBoard.RowSmall", tagX + 1, cy + 1, Color(outlineColor.r, outlineColor.g, outlineColor.b, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(trimmed, "OTBoard.RowSmall", tagX, cy, tagColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText(tostring(ping), "OTBoard.Row", pingRight, cy, GetPingColor(ping), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        if (self.AnimFrac or 0) > 0.01 then
            RNDXBox(10, slide + RX(12), rowH, math.max(1, w - slide - RX(24)), math.max(1, (self.ActionsH or 0) * self.AnimFrac - RY(4)), Color(255, 255, 255, 5 * self.AnimFrac))
        end
    end

    row.DoClick = function(self)
        if not IsValid(self.ply) then return end

        local par = self:GetParent()

        if IsValid(par) and IsValid(par.OpenedRow) and par.OpenedRow ~= self then
            CloseActions(par.OpenedRow)
        end

        if self.MenuOpen then
            CloseActions(self)

            return
        end

        self.MenuOpen = true

        if IsValid(par) then
            par.OpenedRow = self
        end

        CreateActions(self)
        self:InvalidateLayout(true)
        RelayoutParent(self)
    end

    return row
end

local function CreateListColumn(parent, titleText)
    local wrap = vgui.Create("DPanel", parent)

    wrap.TitleText = titleText
    wrap.CountText = "0"
    wrap.Paint = function(self, w, h)
        DrawPanel(0, 0, w, h, 16, COLOR_PANEL)
        RNDXBox(16, 0, 0, w, RY(46), COLOR_PANEL_ALT)
        RNDXBox(3, RX(14), RY(13), math.max(2, RX(3)), RY(20), COLOR_ACCENT)

        surface.SetFont("OTBoard.Header")

        local tw = select(1, surface.GetTextSize(self.TitleText))
        local cw = select(1, surface.GetTextSize(self.CountText)) + RX(18)

        draw.SimpleText(self.TitleText, "OTBoard.Header", RX(26), RY(23), COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        RNDXBox(8, RX(34) + tw, RY(13), cw, RY(20), Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 30))
        draw.SimpleText(self.CountText, "OTBoard.RowSmall", RX(34) + tw + cw * 0.5, RY(23), COLOR_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 40)
        surface.DrawRect(RX(14), RY(46), w - RX(28), 1)
    end

    local scroll = vgui.Create("DScrollPanel", wrap)

    scroll.Paint = nil
    SkinBoardScroll(scroll)

    local list = vgui.Create("DListLayout", scroll)

    list:Dock(TOP)
    list.Paint = nil
    list.PerformLayout = function(self, w, h)
        for _, child in ipairs(self:GetChildren()) do
            if IsValid(child) then
                child:SetWide(self:GetWide())
            end
        end

        DListLayout.PerformLayout(self, w, h)
        self:SizeToChildren(false, true)
    end

    wrap.Scroll = scroll
    wrap.List = list

    wrap.PerformLayout = function(self, w, h)
        if IsValid(self.Scroll) then
            self.Scroll:SetPos(RX(12), RY(56))
            self.Scroll:SetSize(w - RX(24), h - RY(68))
        end
    end

    return wrap
end

local function BoardHash()
    local t = {}

    for i, ply in player.Iterator() do
        t[#t + 1] = (ply:SteamID64() or ply:SteamID() or tostring(i)) .. ":" .. tostring(ply:Team()) .. ":" .. tostring(ply:Alive())
    end

    table.sort(t)

    return table.concat(t, "|")
end

local function RefreshBoard(frame)
    if not IsValid(frame) or not IsValid(frame.PlayerColumn) or not IsValid(frame.SpecColumn) then return end

    local lp = LocalPlayer()

    frame.PlayerColumn.List:Clear()
    frame.SpecColumn.List:Clear()
    frame.PlayerColumn.List.OpenedRow = nil
    frame.SpecColumn.List.OpenedRow = nil

    local players, specs = {}, {}
    local disappearance = IsValid(lp) and lp:GetNetVar("disappearance", nil) or nil
    local round = CurrentRound()

    for _, ply in player.Iterator() do
        if round and round.name == "fear" and not ply:Alive() then continue end
        if disappearance and ply ~= lp then continue end

        if ply:Team() == TEAM_SPECTATOR then
            specs[#specs + 1] = ply
        else
            players[#players + 1] = ply
        end
    end

    for i, ply in ipairs(players) do
        CreateBoardRow(frame.PlayerColumn.List, ply, i, false)
    end

    for i, ply in ipairs(specs) do
        CreateBoardRow(frame.SpecColumn.List, ply, i, true)
    end

    frame.PlayerColumn.CountText = tostring(#players)
    frame.SpecColumn.CountText = tostring(#specs)

    if frame.StatOnline then
        frame.StatOnline:SetText(#player.GetAll() .. "/" .. GetServerSlots())
    end

    if frame.StatAdmins then
        frame.StatAdmins:SetText(tostring(CountAdmins()))
    end

    frame.LastHash = BoardHash()
end

local function LayoutBoard(frame)
    if not IsValid(frame) then return end

    local sw, sh = ScrW(), ScrH()
    local w = math.Clamp(math.floor(sw * 0.74), 900, math.min(1320, sw - 40))
    local h = math.Clamp(math.floor(sh * 0.8), 600, math.min(900, sh - 40))

    frame:SetSize(w, h)
    frame:Center()

    frame.BaseX, frame.BaseY = frame:GetPos()

    if IsValid(frame.ButtonBar) then
        frame.ButtonBar:SetPos(RX(22), RY(92))
        frame.ButtonBar:SetSize(w - RX(44), RY(40))
    end

    local bodyY = RY(146)
    local bodyH = h - bodyY - RY(72)
    local gap = RX(14)
    local colW = math.floor((w - RX(44) - gap) * 0.5)

    if IsValid(frame.PlayerColumn) then
        frame.PlayerColumn:SetPos(RX(22), bodyY)
        frame.PlayerColumn:SetSize(colW, bodyH)
    end

    if IsValid(frame.SpecColumn) then
        frame.SpecColumn:SetPos(RX(22) + colW + gap, bodyY)
        frame.SpecColumn:SetSize(w - RX(44) - colW - gap, bodyH)
    end

    if IsValid(frame.FooterPanel) then
        frame.FooterPanel:SetPos(RX(22), h - RY(58))
        frame.FooterPanel:SetSize(w - RX(44), RY(42))
    end
end

function OTBoardCreate()
    if IsValid(ScoreFrame) then ScoreFrame:Remove() end

    ScoreFrame = vgui.Create("DFrame")
    _G.OTBoardFrame = ScoreFrame

    ScoreFrame:SetTitle("")
    ScoreFrame:SetDraggable(false)
    ScoreFrame:ShowCloseButton(false)
    ScoreFrame:MakePopup()
    ScoreFrame:SetKeyboardInputEnabled(false)
    ScoreFrame.LastW = ScrW()
    ScoreFrame.LastH = ScrH()
    ScoreFrame.AnimStart = CurTime()
    ScoreFrame.OpenAnim = 0
    ScoreFrame.Tick = 0

    gui.EnableScreenClicker(true)

    local serverName = GetHostName() or "OT-CITY"

    ScoreFrame.Paint = function(self, w, h)
        self.OpenAnim = Lerp(FrameTime() * 9, self.OpenAnim or 0, 1)

        local ease = BoardEase(self.OpenAnim)
        local a = math.Clamp(ease * 255, 0, 255)
        local pulse = 0.5 + math.sin(CurTime() * 2) * 0.5

        RNDXBox(20, 0, 0, w, h, Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, COLOR_BG.a * ease))
        RNDXBox(20, 0, 0, w, RY(78), Color(COLOR_BG_SOFT.r, COLOR_BG_SOFT.g, COLOR_BG_SOFT.b, COLOR_BG_SOFT.a * ease))
        RNDXBox(4, RX(22), RY(16), math.max(3, RX(4)), RY(46), Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, a))

        surface.SetFont("OTBoard.Title")

        local brandW = select(1, surface.GetTextSize("OT-"))

        draw.SimpleText("OT-", "OTBoard.Title", RX(36), RY(18), Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, (215 + pulse * 40) * ease), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("CITY", "OTBoard.Title", RX(36) + brandW, RY(18), Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("OT-City | Версия: 5.0", "OTBoard.Subtitle", RX(38), RY(54), Color(COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local nameText = TrimToWidth(serverName, "OTBoard.Subtitle", math.floor(w * 0.4))

        draw.SimpleText(nameText, "OTBoard.Subtitle", w - RX(22), RY(26), Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
            self.Tick = Lerp(FrameTime() * 3, self.Tick or 0, 1 / math.max(engine.ServerFrameTime(), 0.0001))

            draw.SimpleText("Тикрейт: " .. math.Round(self.Tick), "OTBoard.RowSmall", w - RX(22), RY(52), Color(COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        local lineW = math.max(0, (w - RX(44)) * ease)
        local sweep = (CurTime() * 0.3) % 1

        surface.SetDrawColor(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 40 * ease)
        surface.DrawRect(RX(22), RY(77), lineW, 1)

        surface.SetDrawColor(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 190 * ease)
        surface.DrawRect(RX(22) + lineW * sweep * 0.8, RY(77), math.min(RX(160), lineW * 0.2), 1)
    end

    local bar = vgui.Create("DPanel", ScoreFrame)

    bar.Paint = nil
    ScoreFrame.ButtonBar = bar

    CreateBoardButton(bar, "Замутить всех", RIGHT, function()
        return hg.muteall
    end, function()
        hg.muteall = not hg.muteall

        for _, ply in player.Iterator() do
            if hg.muteall then
                ply:SetVoiceVolumeScale(0)
            else
                ply:SetVoiceVolumeScale((not hg.mutespect or ply:Alive()) and (hg.playerInfo and hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
            end
        end
    end)

    CreateBoardButton(bar, "Замутить спеков", RIGHT, function()
        return hg.mutespect
    end, function()
        hg.mutespect = not hg.mutespect

        for _, ply in player.Iterator() do
            if ply:Alive() then continue end

            if hg.mutespect then
                ply:SetVoiceVolumeScale(0)
            else
                ply:SetVoiceVolumeScale(not hg.muteall and (hg.playerInfo and hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
            end
        end
    end)

    local isSpec = IsValid(LocalPlayer()) and LocalPlayer():Team() == TEAM_SPECTATOR

    CreateBoardButton(bar, isSpec and "Играть" or "В наблюдение", LEFT, function()
        return IsValid(LocalPlayer()) and LocalPlayer():Team() == TEAM_SPECTATOR
    end, function()
        net.Start("ZB_SpecMode")
        net.WriteBool(not (IsValid(LocalPlayer()) and LocalPlayer():Team() == TEAM_SPECTATOR))
        net.SendToServer()
    end)

    ScoreFrame.PlayerColumn = CreateListColumn(ScoreFrame, "Игроки")
    ScoreFrame.SpecColumn = CreateListColumn(ScoreFrame, "Наблюдающие")

    local footer = vgui.Create("DPanel", ScoreFrame)

    footer.Paint = nil
    ScoreFrame.FooterPanel = footer

    local _, statOnline = CreateFooterStat(footer, "people", "Общий онлайн", "0/" .. GetServerSlots())
    local _, statAdmins = CreateFooterStat(footer, "shield", "Администрация", "0")

    ScoreFrame.StatOnline = statOnline
    ScoreFrame.StatAdmins = statAdmins

    local me = vgui.Create("DPanel", footer)

    me:Dock(RIGHT)
    me:SetWide(RX(250))
    me.Paint = function(self, w, h)
        DrawPanel(0, 0, w, h, 12, COLOR_PANEL)
        RNDXBox(3, w - math.max(2, RX(3)), RY(9), math.max(2, RX(3)), h - RY(18), Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 200))

        local lp = LocalPlayer()

        if not IsValid(lp) then return end

        local tag, tagColor = GetGroupTagData(lp)

        draw.SimpleText(TrimToWidth(SafeNick(lp), "OTBoard.RowSmall", w - RX(70)), "OTBoard.RowSmall", RX(52), h * 0.5 - 8, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tag ~= "" and tag or "Игрок", "OTBoard.RowSmall", RX(52), h * 0.5 + 8, tag ~= "" and tagColor or COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local meAvatar = vgui.Create("AvatarImage", me)

    meAvatar:SetPlayer(LocalPlayer(), 64)
    meAvatar:SetMouseInputEnabled(false)

    me.PerformLayout = function(self, w, h)
        local av = RX(30)

        if IsValid(meAvatar) then
            meAvatar:SetSize(av, av)
            meAvatar:SetPos(RX(12), math.floor(h * 0.5 - av * 0.5))
        end
    end

    ScoreFrame.Think = function(self)
        gui.EnableScreenClicker(true)

        local frac = math.Clamp((CurTime() - (self.AnimStart or CurTime())) / 0.22, 0, 1)
        local ease = BoardEase(frac)

        self:SetAlpha(math.floor(40 + 215 * ease))

        if self.BaseX and self.BaseY then
            self:SetPos(self.BaseX, math.floor(self.BaseY + (1 - ease) * RY(46)))
        end

        if self.LastW ~= ScrW() or self.LastH ~= ScrH() then
            self.LastW = ScrW()
            self.LastH = ScrH()
            LayoutBoard(self)
        end

        if self.LastHash ~= BoardHash() then
            RefreshBoard(self)
        end
    end

    LayoutBoard(ScoreFrame)
    RefreshBoard(ScoreFrame)
end

local function OTBoardOpen()
    DisableDefaultScoreboard()
    OTBoardCreate()
end

local function OTBoardClose()
    if IsValid(ScoreFrame) then
        ScoreFrame:Remove()
        ScoreFrame = nil
        _G.OTBoardFrame = nil
    end

    gui.EnableScreenClicker(false)
end

function GM:ScoreboardShow()
    OTBoardOpen()

    return true
end

function GM:ScoreboardHide()
    OTBoardClose()

    return true
end

hook.Add("InitPostEntity", "OTBoard_DisableDefault_1", DisableDefaultScoreboard)
hook.Add("OnGamemodeLoaded", "OTBoard_DisableDefault_2", DisableDefaultScoreboard)

concommand.Remove("otboard_reload")
concommand.Add("otboard_reload", function()
    DisableDefaultScoreboard()
    OTBoardClose()
end)

timer.Simple(0, DisableDefaultScoreboard)

hook.Add("PlayerStartVoice", "asd", function(ply)
    if not IsValid(ply) then return end
    if LocalPlayer():IsAdmin() and AdminShowVoiceChat:GetBool() then return end
    local other_alive = (ply:Alive() and LocalPlayer() ~= ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))
    return other_alive or nil
end)

if CLIENT then
    net.Receive("PunishLightningEffect", function()
        local target = net.ReadEntity()
        if not IsValid(target) then return end
        local dlight = DynamicLight(target:EntIndex())
        if dlight then
            dlight.pos = target:GetPos()
            dlight.r = 126
            dlight.g = 139
            dlight.b = 212
            dlight.brightness = 1
            dlight.Decay = 1000
            dlight.Size = 500
            dlight.DieTime = CurTime() + 1
        end
    end)
end

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
    if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(-20, 20))
    end
    hook.Add("PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255, 255, 255, 255))
        end
        render.EndBeam()
        render.OverrideBlend(false)
    end)
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint(name, delay)
    return false
end

hook.Add("Player Spawn", "GuiltKnown", function(ply)
    if ply == LocalPlayer() then
        system.FlashWindow()
    end
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "client loaded\n")
