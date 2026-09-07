zb = zb or {}
ZSov = ZSov or {}

local RNDX = _G.gSims_RNDX or _G.RNDX or _G.rndx

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_bg = Color(3, 5, 9, 235)
local clr_card = Color(6, 12, 20, 168)
local clr_card_hover = Color(12, 22, 36, 205)
local clr_soft = Color(190, 210, 228, 215)
local clr_shadow = Color(2, 8, 14, 190)

local function Fade(col, a)
    return Color(col.r, col.g, col.b, math.Clamp(a or 255, 0, 255))
end

local function LerpFrame(speed, from, to)
    if isfunction(LerpFT) then
        return LerpFT(speed, from or 0, to or 0)
    end

    return Lerp(math.Clamp(FrameTime() / math.max(speed, 0.0001), 0, 1), from or 0, to or 0)
end

local function DrawRound(rad, x, y, w, h, col)
    if RNDX and RNDX.Draw then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(math.floor(rad), x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if RNDX and RNDX.DrawOutlined then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

local function Sc()
    return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
    return math.floor(Sc() * n + 0.5)
end

local function DrawSlant(x, y, w, h, skew, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w + skew, y = y},
        {x = x + w, y = y + h},
        {x = x, y = y + h}
    })
end

local function TrimToWidth(text, fontName, maxW)
    text = tostring(text or "")
    surface.SetFont(fontName)

    if surface.GetTextSize(text) <= maxW then return text end

    local dots = ".."
    local len = utf8.len(text) or #text

    while len > 0 do
        local part = utf8.sub(text, 1, len)
        if surface.GetTextSize(part .. dots) <= maxW then return part .. dots end
        len = len - 1
    end

    return dots
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("ZSov_Brand", {font = "Montserrat SemiBold", size = math.floor(44 * s + 0.5), weight = 800, italic = true, antialias = true, extended = true})
    surface.CreateFont("ZSov_Sub", {font = "Montserrat Medium", size = math.floor(20 * s + 0.5), weight = 600, antialias = true, extended = true})
    surface.CreateFont("ZSov_Title", {font = "Montserrat SemiBold", size = math.floor(24 * s + 0.5), weight = 800, antialias = true, extended = true})
    surface.CreateFont("ZSov_Desc", {font = "Montserrat Medium", size = math.floor(17 * s + 0.5), weight = 500, antialias = true, extended = true})
    surface.CreateFont("ZSov_Status", {font = "Montserrat SemiBold", size = math.floor(16 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("ZSov_Close", {font = "Montserrat SemiBold", size = math.floor(34 * s + 0.5), weight = 800, antialias = true, extended = true})
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "ZSov_Fonts", CreateFonts)

local Forgiveable = {}
local requested = false
local bannerAnim = 0
local bannerStart = 0
local bannerLastCount = 0
local BANNER_TIME = 8

local function CleanForgiveable()
    for i = #Forgiveable, 1, -1 do
        local d = Forgiveable[i]

        if not d or not IsValid(d.ply) or (tonumber(d.amt) or 0) <= 0.01 then
            table.remove(Forgiveable, i)
        end
    end

    return #Forgiveable
end

local function TotalForgiveable()
    local total = 0

    for _, d in ipairs(Forgiveable) do
        if IsValid(d.ply) then total = total + (tonumber(d.amt) or 0) end
    end

    return total
end

hook.Add("OnNetVarSet", "SovestNetVar", function(index, key, var)
    if key == "Sovest" then
        local e = Entity(index)
        if IsValid(e) then e.Sovest = var end
    end
end)

local function MySovest()
    local p = LocalPlayer()
    if not IsValid(p) then return 0 end

    local v = p.Sovest

    if v == nil and p.GetNetVar then v = p:GetNetVar("Sovest", nil) end
    if v == nil and p.GetNWFloat then v = p:GetNWFloat("Sovest", 100) end

    return math.Round(tonumber(v) or 100, 1)
end

local function MyMaxSovest()
    local p = LocalPlayer()
    local v = 120

    if IsValid(p) and p.GetNetVar then v = tonumber(p:GetNetVar("MaxSovest", 120)) or 120 end

    return math.max(v, 1)
end

local PANEL = {}

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetPaintShadow(false)

    self.OpenTime = RealTime()
    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()
    self.LastCount = -1
    self.EmptySince = nil
    self.Fill = 0

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("")
    self.CloseButton:SetCursor("hand")
    self.CloseButton.HoverLerp = 0
    self.CloseButton.DoClick = function()
        if IsValid(self) then self:Close() end
    end
    self.CloseButton.Paint = function(btn, w, h)
        btn.HoverLerp = LerpFrame(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverLerp, 8, 16),
            Lerp(btn.HoverLerp, 18, 60),
            Lerp(btn.HoverLerp, 30, 96),
            Lerp(btn.HoverLerp, 155, 225)
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Fade(clr_accent, 70 + btn.HoverLerp * 150), 1)
        draw.SimpleText("×", "ZSov_Close", w * 0.5, h * 0.46, Color(Lerp(btn.HoverLerp, 235, clr_accent.r), Lerp(btn.HoverLerp, 235, clr_accent.g), Lerp(btn.HoverLerp, 235, clr_accent.b), 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.List = vgui.Create("DScrollPanel", self)
    self.List:SetPaintBackground(false)

    local bar = self.List:GetVBar()
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h)
        DrawRound(math.max(2, SX(4)), w * 0.5 - math.max(1, SX(2)), 0, math.max(2, SX(4)), h, Color(255, 255, 255, 18))
    end
    bar.btnGrip.Paint = function(_, w, h)
        DrawRound(math.max(2, SX(4)), w * 0.5 - math.max(1, SX(2)), 0, math.max(2, SX(4)), h, Fade(clr_accent, 190))
    end

    self:Rebuild()
end

function PANEL:AddRow(data)
    local row = vgui.Create("DButton", self.List)
    row:Dock(TOP)
    row:SetTall(SX(84))
    row:DockMargin(0, SX(12), 0, 0)
    row:SetText("")
    row:SetCursor("hand")
    row.HoverLerp = 0
    row.Ent = data.ply
    row.Amt = tonumber(data.amt) or 0
    row.PName = data.ply:Name()

    local menu = self

    row.Think = function(btn)
        btn.HoverLerp = LerpFrame(0.16, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)
    end

    row.Paint = function(btn, w, h)
        local hover = btn.HoverLerp or 0
        local rad = math.max(5, SX(12))

        DrawRound(rad, 0, 0, w, h, Color(
            Lerp(hover, clr_card.r, clr_card_hover.r),
            Lerp(hover, clr_card.g, clr_card_hover.g),
            Lerp(hover, clr_card.b, clr_card_hover.b),
            Lerp(hover, clr_card.a, clr_card_hover.a)
        ))

        if hover > 0.01 then
            DrawRoundOutlined(rad, 0, 0, w, h, Fade(clr_accent, hover * 45), math.max(3, SX(6)))
        end

        DrawRoundOutlined(rad, 0, 0, w, h, Fade(clr_accent, 20 + hover * 175), math.max(1, SX(1)))
        DrawRound(math.max(2, SX(3)), SX(16), SX(18), math.max(2, SX(4)), h - SX(36), Fade(clr_accent, 190 + hover * 65))

        local textX = SX(34)
        local name = TrimToWidth(btn.PName, "ZSov_Title", w - SX(240))

        draw.SimpleText(name, "ZSov_Title", textX, h * 0.5 - SX(12), clr_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("ВЕРНУТЬ +" .. math.Round(btn.Amt, 1) .. " СОВЕСТИ", "ZSov_Status", textX, h * 0.5 + SX(16), Fade(clr_cyan, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local label = "ПРОСТИТЬ"

        surface.SetFont("ZSov_Status")

        local tw = surface.GetTextSize(label)
        local pillW = tw + SX(40)
        local pillH = SX(38)
        local pillX = w - pillW - SX(20)
        local pillY = h * 0.5 - pillH * 0.5
        local pillRad = math.max(4, SX(8))

        DrawRound(pillRad, pillX, pillY, pillW, pillH, Color(10, 30, 48, 200 + hover * 55))
        DrawRoundOutlined(pillRad, pillX, pillY, pillW, pillH, Fade(clr_accent, 120 + hover * 135), math.max(1, SX(1)))
        draw.SimpleText(label, "ZSov_Status", pillX + pillW * 0.5, pillY + pillH * 0.5, hover > 0.5 and clr_text or Fade(clr_accent, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    row.DoClick = function(btn)
        surface.PlaySound("buttons/button14.wav")

        net.Start("zb_sovest_forgive")
        net.WriteEntity(btn.Ent)
        net.SendToServer()

        for i = #Forgiveable, 1, -1 do
            if Forgiveable[i].ply == btn.Ent then
                table.remove(Forgiveable, i)
            end
        end

        if IsValid(menu) then menu:Rebuild() end
    end

    return row
end

function PANEL:AddEmpty()
    local card = vgui.Create("DPanel", self.List)
    card:Dock(TOP)
    card:SetTall(SX(96))
    card:DockMargin(0, SX(12), 0, 0)
    card.Paint = function(_, w, h)
        local rad = math.max(5, SX(12))

        DrawRound(rad, 0, 0, w, h, clr_card)
        DrawRoundOutlined(rad, 0, 0, w, h, Fade(clr_accent, 22), math.max(1, SX(1)))
        draw.SimpleText("ПРОЩАТЬ НЕКОГО", "ZSov_Title", w * 0.5, h * 0.5 - SX(12), Fade(clr_text, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ваша Совесть чиста", "ZSov_Desc", w * 0.5, h * 0.5 + SX(16), clr_soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return card
end

function PANEL:Rebuild()
    if not IsValid(self.List) then return end

    self.List:Clear()

    if CleanForgiveable() <= 0 then
        self:AddEmpty()
        return
    end

    for _, data in ipairs(Forgiveable) do
        if IsValid(data.ply) then
            self:AddRow(data)
        end
    end
end

function PANEL:Think()
    local lp = LocalPlayer()

    if not IsValid(lp) or lp:Alive() then
        self:Close()
        return
    end

    local n = CleanForgiveable()

    if n ~= self.LastCount then
        self.LastCount = n
        self:Rebuild()
    end

    if n <= 0 then
        self.EmptySince = self.EmptySince or CurTime()

        if CurTime() - self.EmptySince > 1.6 then
            self:Close()
        end
    else
        self.EmptySince = nil
    end
end

function PANEL:PerformLayout(w, h)
    local listW = math.max(SX(520), math.min(SX(780), w * 0.52))
    local listY = math.floor(h * 0.30)
    local listH = math.floor(h * 0.52)

    if IsValid(self.List) then
        self.List:SetPos(math.floor((w - listW) * 0.5), listY)
        self.List:SetSize(listW, listH)
    end

    if IsValid(self.CloseButton) then
        local s = SX(46)
        self.CloseButton:SetSize(s, s)
        self.CloseButton:SetPos(w - s - SX(48), SX(40))
    end
end

function PANEL:PaintBackground(w, h)
    local mat = self.BGMaterial

    if not mat or mat:IsError() then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local iw, ih = mat:Width(), mat:Height()

    if iw <= 0 or ih <= 0 then
        surface.SetDrawColor(clr_bg)
        surface.DrawRect(0, 0, w, h)
        return
    end

    local elapsed = RealTime() - (self.BGStartTime or RealTime())
    local zoomTime = elapsed * 0.040
    local panTime = elapsed * 0.040
    local zoomWave = math.sin(zoomTime) * 0.5 + 0.5
    local zoom = 1.20 + zoomWave * 0.16
    local baseScale = math.max(w / iw, h / ih)
    local scale = baseScale * zoom
    local drawW = iw * scale
    local drawH = ih * scale
    local safeX = (drawW - w) * 0.5
    local safeY = (drawH - h) * 0.5

    if safeX < 0 then safeX = 0 end
    if safeY < 0 then safeY = 0 end

    local panX = math.sin(panTime * 0.80)
    local panY = math.sin(panTime * 0.61 + 1.7)
    local x = (w - drawW) * 0.5 + panX * safeX * 0.80
    local y = (h - drawH) * 0.5 + panY * safeY * 0.80

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Paint(w, h)
    self:PaintBackground(w, h)

    draw.NoTexture()

    surface.SetDrawColor(1, 4, 8, 132)
    surface.DrawRect(0, 0, w, h)

    local headerY = SX(36)
    local cx = w * 0.5

    surface.SetFont("ZSov_Brand")

    local xW = surface.GetTextSize("OT-")
    local brandW = xW + surface.GetTextSize("CITY")

    draw.SimpleText("OT-", "ZSov_Brand", cx - brandW * 0.5 + SX(1), headerY + SX(2), clr_shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZSov_Brand", cx - brandW * 0.5 + xW + SX(1), headerY + SX(2), clr_shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "ZSov_Brand", cx - brandW * 0.5, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZSov_Brand", cx - brandW * 0.5 + xW, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local sub = "ПРОЩЕНИЕ"

    surface.SetFont("ZSov_Sub")

    local subW = surface.GetTextSize(sub)

    draw.SimpleText(sub, "ZSov_Sub", cx, headerY + SX(58), Color(200, 225, 245, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local stripeY = headerY + SX(58) + SX(11)
    local stripeW = SX(48)

    DrawSlant(cx - subW * 0.5 - SX(18) - stripeW, stripeY, stripeW, math.max(2, SX(3)), -SX(6), clr_accent)
    DrawSlant(cx + subW * 0.5 + SX(18), stripeY, stripeW, math.max(2, SX(3)), SX(6), clr_accent)

    local sovest = MySovest()
    local target = math.Clamp(sovest / MyMaxSovest(), 0, 1)

    self.Fill = LerpFrame(0.2, self.Fill or 0, target)

    local fill = math.Clamp(self.Fill or 0, 0, 1)
    local barW = math.min(SX(560), w * 0.44)
    local barH = math.max(6, SX(14))
    local barX = cx - barW * 0.5
    local barY = headerY + SX(98)
    local barRad = barH * 0.5

    DrawRound(barRad, barX, barY, barW, barH, Color(4, 10, 18, 225))

    if fill > 0.001 then
        DrawRound(barRad, barX, barY, math.max(barH, barW * fill), barH, Fade(clr_accent, 235))
    end

    DrawRoundOutlined(barRad, barX, barY, barW, barH, Fade(clr_accent, 130), 1)

    draw.SimpleText("СОВЕСТЬ: " .. sovest, "ZSov_Status", barX, barY - SX(8), Fade(clr_text, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText("К ВОЗВРАТУ: " .. math.Round(TotalForgiveable(), 1), "ZSov_Status", barX + barW, barY - SX(8), Fade(clr_cyan, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText("Верните Совесть тем, кто перед вами провинился", "ZSov_Desc", cx, barY + barH + SX(9), clr_soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function PANEL:Close()
    if self.Closing then return end

    self.Closing = true

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
    self:AlphaTo(0, 0.12, 0, function()
        if IsValid(self) then self:Remove() end
    end)

    ZSov.Menu = nil
end

function PANEL:First()
    self:AlphaTo(255, 0.18, 0, nil)
end

vgui.Register("ZSovest", PANEL, "DFrame")

local function OpenSovestMenu()
    if IsValid(ZSov.Menu) then
        ZSov.Menu:Close()
        ZSov.Menu = nil
    end

    net.Start("zb_sovest_query")
    net.SendToServer()

    surface.PlaySound("buttons/button15.wav")

    local f = vgui.Create("ZSovest")
    f:MakePopup()
    f:First()

    ZSov.Menu = f
end

hook.Add("Think", "SovestRequestList", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:Alive() then
        if not requested then
            requested = true

            net.Start("zb_sovest_query")
            net.SendToServer()

            timer.Create("sovest_refresh", 2, 0, function()
                local lp = LocalPlayer()

                if IsValid(lp) and not lp:Alive() then
                    net.Start("zb_sovest_query")
                    net.SendToServer()
                else
                    timer.Remove("sovest_refresh")
                end
            end)
        end
    else
        if requested then
            requested = false
            Forgiveable = {}

            timer.Remove("sovest_refresh")

            if IsValid(ZSov.Menu) then ZSov.Menu:Close() end
        end
    end
end)

net.Receive("zb_sovest_list", function()
    local n = net.ReadUInt(8)
    local t = {}

    for i = 1, n do
        local e = net.ReadEntity()
        local a = net.ReadFloat()

        if IsValid(e) then
            t[#t + 1] = { ply = e, amt = a }
        end
    end

    Forgiveable = t

    if IsValid(ZSov.Menu) and ZSov.Menu.Rebuild then
        ZSov.Menu:Rebuild()
    end
end)

hook.Add("HUDPaint", "SovestForgiveBanner", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local n = 0

    if ply:Alive() or IsValid(ZSov.Menu) then
        bannerStart = 0
        bannerLastCount = 0
    else
        n = CleanForgiveable()

        if n > bannerLastCount then
            bannerStart = CurTime()
        end

        bannerLastCount = n
    end

    local within = bannerStart > 0 and (CurTime() - bannerStart) < BANNER_TIME
    local show = n > 0 and within

    bannerAnim = LerpFrame(0.14, bannerAnim, show and 1 or 0)

    if bannerAnim < 0.01 then return end

    local a = bannerAnim
    local pulse = 0.5 + math.sin(CurTime() * 3) * 0.5

    local pad_x = SX(22)
    local pad_y = SX(16)
    local stripe_w = math.max(2, SX(4))
    local gap = SX(8)

    local title_text = "ВАМ ДОСТУПНО ПРОЩЕНИЕ"
    local desc_text = "Вы можете вернуть Совесть тем, кто вас ранил"
    local key_text = "НАЖМИТЕ  [ F ]"

    surface.SetFont("ZSov_Sub")
    local brand_w, brand_h = surface.GetTextSize("OT-CITY")
    local brand_pre_w = surface.GetTextSize("OT-")

    surface.SetFont("ZSov_Title")
    local title_w, title_h = surface.GetTextSize(title_text)

    surface.SetFont("ZSov_Desc")
    local desc_w, desc_h = surface.GetTextSize(desc_text)

    surface.SetFont("ZSov_Status")
    local key_text_w, key_text_h = surface.GetTextSize(key_text)

    local key_h = key_text_h + SX(14)
    local key_w = key_text_w + SX(46)

    local content_w = math.max(title_w, desc_w, key_w, brand_w)
    local w = content_w + stripe_w + pad_x * 3
    local h = pad_y * 2 + brand_h + gap + title_h + gap + desc_h + math.floor(gap * 1.6) + key_h

    local max_w = ScrW() * 0.9

    if w > max_w then
        w = max_w
        content_w = w - stripe_w - pad_x * 3
        title_text = TrimToWidth(title_text, "ZSov_Title", content_w)
        desc_text = TrimToWidth(desc_text, "ZSov_Desc", content_w)
    end

    local x = math.floor(ScrW() * 0.5 - w * 0.5)
    local baseY = math.floor(ScrH() * 0.28)
    local y = math.floor(Lerp(a, -h - SX(40), baseY))
    local rad = math.max(5, SX(12))

    local content_x = x + pad_x + stripe_w + pad_x
    local cx = content_x + content_w * 0.5

    DrawRound(rad, x, y, w, h, Color(3, 8, 14, 232 * a))
    DrawRoundOutlined(rad, x, y, w, h, Fade(clr_accent, (55 + pulse * 45) * a), math.max(3, SX(6)))
    DrawRoundOutlined(rad, x, y, w, h, Fade(clr_accent, (170 + pulse * 60) * a), math.max(1, SX(2)))
    DrawRound(math.max(2, SX(3)), x + pad_x, y + pad_y, stripe_w, h - pad_y * 2, Fade(clr_accent, 220 * a))

    local cursor_y = y + pad_y

    draw.SimpleText("OT-", "ZSov_Sub", cx - brand_w * 0.5, cursor_y, Fade(clr_accent, 235 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZSov_Sub", cx - brand_w * 0.5 + brand_pre_w, cursor_y, Fade(clr_text, 235 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    cursor_y = cursor_y + brand_h + gap

    draw.SimpleText(title_text, "ZSov_Title", cx, cursor_y, Fade(clr_text, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    cursor_y = cursor_y + title_h + gap

    draw.SimpleText(desc_text, "ZSov_Desc", cx, cursor_y, Fade(clr_soft, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    cursor_y = cursor_y + desc_h + math.floor(gap * 1.6)

    local key_x = math.floor(cx - key_w * 0.5)
    local key_y = math.floor(cursor_y)
    local key_rad = math.max(4, SX(8))

    DrawRound(key_rad, key_x, key_y, key_w, key_h, Color(10, 30, 48, (200 + pulse * 45) * a))
    DrawRoundOutlined(key_rad, key_x, key_y, key_w, key_h, Fade(clr_accent, (130 + pulse * 90) * a), math.max(1, SX(1)))
    draw.SimpleText(key_text, "ZSov_Status", key_x + key_w * 0.5, key_y + key_h * 0.5, Fade(clr_accent, 245 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("PlayerButtonDown", "SovestOpenKey", function(ply, btn)
    if ply ~= LocalPlayer() then return end
    if btn ~= KEY_F then return end
    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end
    if LocalPlayer():Alive() then return end
    if CleanForgiveable() <= 0 then return end
    if IsValid(ZSov.Menu) then return end

    OpenSovestMenu()
end)

concommand.Add("hg_sovest_menu", function()
    if not IsValid(LocalPlayer()) or LocalPlayer():Alive() then return end
    if CleanForgiveable() <= 0 then return end

    OpenSovestMenu()
end)

concommand.Add("hg_getsovest", function()
    if not LocalPlayer():IsAdmin() then return end

    net.Start("zb_sovest_admin")
    net.SendToServer()
end)

net.Receive("zb_sovest_admin", function()
    local tbl = net.ReadTable()
    local out = "\nСовесть игроков:\n"

    for id, val in pairs(tbl) do
        local pl = Player(id)

        if IsValid(pl) then
            out = out .. "\t" .. pl:Name() .. " - " .. math.Round(tonumber(val) or 0, 2) .. "\n"
        end
    end

    LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, out)
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "sovest menu loaded\n")
