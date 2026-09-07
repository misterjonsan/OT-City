MODE = MODE or {}
MODE.ProfXPKey = "hmcd_prof_xp"
MODE.ProfChoiceKey = "hmcd_prof_choice"

local PROFESSION_ORDER = {"doctor", "huntsman", "engineer", "cook", "builder", "exorcist"}
local PROFESSION_META = {
    doctor = {
        Title = "Доктор",
        Unlock = 0,
        Color = Color(70, 200, 120),
        Short = "Осмотр состояния тела",
        Desc = "Зажмите ходьбу (SHIFT) и нажмите E, глядя на игрока — вы увидите состояние его организма (насыщение). Помогает понять, кто ранен и кого лечить.",
    },
    huntsman = {
        Title = "Охотник",
        Unlock = 800,
        Color = Color(210, 170, 70),
        Short = "Видит следы игроков",
        Desc = "Вы видите следы других игроков прямо на земле — они подсвечиваются вокруг вас. Присядьте, чтобы разглядеть их вблизи чётче. Идеально, чтобы выследить убийцу или найти, куда все убежали.",
    },
    engineer = {
        Title = "Инженер",
        Unlock = 2200,
        Color = Color(90, 160, 230),
        Short = "Крафт взрывчатки",
        Desc = "Через радиальное меню вы можете смастерить самодельное оружие:\n- Труба + гвозди (x3) + патроны = труба-бомба.\n- Бутылка + бинт рядом с бочкой газа = коктейль Молотова.\nСоберите компоненты и создайте оружие на месте.",
    },
    cook = {
        Title = "Повар",
        Unlock = 4500,
        Color = Color(230, 120, 90),
        Short = "Восстанавливает насыщение союзникам",
        Desc = "Зажмите ходьбу (SHIFT) и нажмите E — все живые игроки рядом с вами (радиус ~300) получат прибавку насыщения. Помогает команде дольше держаться в долгой партии. Действует с перезарядкой в несколько секунд.",
    },
    builder = {
        Title = "Строитель",
        Unlock = 8000,
        Color = Color(180, 150, 110),
        Short = "Заколачивает двери",
        Desc = "Посмотрите на дверь, зажмите ходьбу (SHIFT) и нажмите E — вы заколотите её: дверь запирается и получает большой запас прочности, её труднее выбить. Отлично, чтобы закрепиться и перекрыть проход. Действует с перезарядкой.",
    },
    exorcist = {
        Title = "Экзорцист",
        Unlock = 8000,
        VIP = true,
        Color = Color(200, 55, 65),
        Short = "Видит грешников и владеет Крестом",
        Desc = "На спавне вы получаете Крест совести — им можно изгнать грешника.\nГрешники горят алой меткой, но только в прямой видимости и в радиусе 750.\nСквозь стены, за спиной и на бегу меток не видно.\nКрест слушается только экзорциста: чужих он отвергает и поджигает.\nСудить можно лишь со своей совестью от 95.\nДоступно только VIP-игрокам.",
    },
}

MODE.ProfessionOrder = PROFESSION_ORDER
MODE.ProfessionMeta = PROFESSION_META

local function ProfCost(key)
    local meta = PROFESSION_META[key]
    return tonumber(meta and meta.Unlock) or 0
end

local VIP_PROFESSIONS = {exorcist = true}

local function ProfVIPOnly(key)
    if key == nil or key == "" then return false end
    local meta = PROFESSION_META[key]
    if meta and meta.VIP then return true end
    return VIP_PROFESSIONS[key] == true
end

local function IsVIP()
    local ply = LocalPlayer()
    if not IsValid(ply) or not isfunction(ply.GetUserGroup) then return false end
    local group = string.lower(string.Trim(tostring(ply:GetUserGroup() or "user")))
    return group ~= "" and group ~= "user"
end

local function ProfUnlocked(xp, key)
    if key == nil or key == "" then return true end
    if ProfVIPOnly(key) and not IsVIP() then return false end
    return (tonumber(xp) or 0) >= ProfCost(key)
end

MODE.IsProfessionVIPOnly = ProfVIPOnly

function MODE.ProfessionUnlockCost(key)
    return ProfCost(key)
end

function MODE.IsProfessionUnlocked(xp, key)
    return ProfUnlocked(xp, key)
end

local PANEL = {}

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_dim = Color(150, 190, 220)
local clr_bg = Color(3, 5, 9, 235)
local clr_card = Color(6, 12, 20, 168)
local clr_card_hover = Color(12, 22, 36, 205)
local clr_locked = Color(112, 126, 140)

ZProf = ZProf or {}

ZProf.ClientXP = ZProf.ClientXP
ZProf.ClientChoice = ZProf.ClientChoice

net.Receive("HMCD_ProfSync", function()
    ZProf.ClientXP = net.ReadUInt(30) or 0
    ZProf.ClientChoice = net.ReadString() or ""
end)

hook.Add("InitPostEntity", "HMCD_Professions_RequestSync", function()
    timer.Simple(1, function()
        if net then RunConsoleCommand("hmcd_prof_sync") end
    end)
end)

local function MyXP()
    local p = LocalPlayer()
    if ZProf and ZProf.ClientXP ~= nil then return math.floor(tonumber(ZProf.ClientXP) or 0) end
    if IsValid(p) and p.GetNWInt then return p:GetNWInt("HMCD_ProfXP", 0) end
    return 0
end

local function MyChoice()
    local p = LocalPlayer()
    local c = (ZProf and ZProf.ClientChoice) or nil
    if c ~= nil then return c end
    if IsValid(p) and p.GetNWString then c = p:GetNWString("HMCD_ProfChoice", "") end
    return isstring(c) and c or ""
end

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

local function WrapText(text, font, maxw)
    surface.SetFont(font)
    local out = {}
    for _, paragraph in ipairs(string.Explode("\n", text)) do
        local line = ""
        for _, word in ipairs(string.Explode(" ", paragraph)) do
            local test = (line == "") and word or (line .. " " .. word)
            local tw = surface.GetTextSize(test)
            if tw > maxw and line ~= "" then
                out[#out + 1] = line
                line = word
            else
                line = test
            end
        end
        out[#out + 1] = line
    end
    return out
end

local DESC_FONTS = {
    {font = "ZProf_Desc", line = 20},
    {font = "ZProf_DescMid", line = 18},
    {font = "ZProf_DescSmall", line = 16}
}

local function FitDesc(text, maxw, maxh)
    local best = nil

    for index = 1, #DESC_FONTS do
        local entry = DESC_FONTS[index]
        local lineH = SX(entry.line)
        local lines = WrapText(text, entry.font, maxw)
        local fits = math.max(math.floor(maxh / lineH), 1)

        best = {font = entry.font, lineH = lineH, lines = lines, limit = fits}

        if #lines <= fits then return best end
    end

    return best
end

local function CreateFonts()
    local s = Sc()

    surface.CreateFont("ZProf_Brand", {font = "Montserrat SemiBold", size = math.floor(44 * s + 0.5), weight = 800, italic = true, antialias = true, extended = true})
    surface.CreateFont("ZProf_Sub", {font = "Montserrat Medium", size = math.floor(20 * s + 0.5), weight = 600, antialias = true, extended = true})
    surface.CreateFont("ZProf_CardTitle", {font = "Montserrat SemiBold", size = math.floor(26 * s + 0.5), weight = 800, antialias = true, extended = true})
    surface.CreateFont("ZProf_Short", {font = "Montserrat Medium", size = math.floor(19 * s + 0.5), weight = 600, antialias = true, extended = true})
    surface.CreateFont("ZProf_Desc", {font = "Montserrat Medium", size = math.floor(17 * s + 0.5), weight = 500, antialias = true, extended = true})
    surface.CreateFont("ZProf_DescMid", {font = "Montserrat Medium", size = math.floor(15 * s + 0.5), weight = 500, antialias = true, extended = true})
    surface.CreateFont("ZProf_DescSmall", {font = "Montserrat Medium", size = math.floor(13 * s + 0.5), weight = 500, antialias = true, extended = true})
    surface.CreateFont("ZProf_Status", {font = "Montserrat SemiBold", size = math.floor(16 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("ZProf_Btn", {font = "Montserrat SemiBold", size = math.floor(22 * s + 0.5), weight = 700, antialias = true, extended = true})
    surface.CreateFont("ZProf_Close", {font = "Montserrat SemiBold", size = math.floor(34 * s + 0.5), weight = 800, antialias = true, extended = true})
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_ProfFonts", CreateFonts)

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetTitle("")
    self:SetBorder(false)
    self:SetColorBG(clr_bg)
    self:SetBlurStrengh(0)
    self:SetDraggable(false)
    self:ShowCloseButton(false)

    self.OpenTime = RealTime()
    self.BGMaterial = Material("otcity/fone.png", "smooth")
    self.BGStartTime = RealTime()
    self.Selected = MyChoice()
    self.Cards = {}

    self.CloseButton = vgui.Create("DButton", self)
    self.CloseButton:SetText("")
    self.CloseButton:SetCursor("hand")
    self.CloseButton.HoverLerp = 0
    self.CloseButton.DoClick = function()
        if IsValid(self) then self:Close() end
    end
    self.CloseButton.Paint = function(btn, w, h)
        btn.HoverLerp = LerpFT(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local bg = Color(
            Lerp(btn.HoverLerp, 8, 16),
            Lerp(btn.HoverLerp, 18, 60),
            Lerp(btn.HoverLerp, 30, 96),
            Lerp(btn.HoverLerp, 155, 225)
        )

        local rad = math.max(4, SX(8))

        DrawRound(rad, 0, 0, w, h, bg)
        DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + btn.HoverLerp * 150), 1)
        draw.SimpleText("×", "ZProf_Close", w * 0.5, h * 0.46, Color(Lerp(btn.HoverLerp, 235, clr_accent.r), Lerp(btn.HoverLerp, 235, clr_accent.g), Lerp(btn.HoverLerp, 235, clr_accent.b), 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.SelectButton = vgui.Create("DButton", self)
    self.SelectButton:SetText("")
    self.SelectButton:SetCursor("hand")
    self.SelectButton.HoverLerp = 0
    self.SelectButton.Paint = function(btn, w, h)
        local key = self.Selected or ""
        local isCurrent = (MyChoice() == key)
        local unlocked = ProfUnlocked(MyXP(), key)
        btn.HoverLerp = LerpFT(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

        local rad = math.max(5, SX(10))

        if not unlocked then
            local need = math.max(0, ProfCost(key) - MyXP())
            local label = "НУЖНО ЕЩЁ " .. string.Comma(need) .. " ОПЫТА"

            if ProfVIPOnly(key) and not IsVIP() then
                label = "ДОСТУПНО ТОЛЬКО VIP"
            end

            DrawRound(rad, 0, 0, w, h, Color(8, 13, 19, 220))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_locked.r, clr_locked.g, clr_locked.b, 150), 1)
            draw.SimpleText(label, "ZProf_Btn", w * 0.5, h * 0.5, Color(clr_locked.r, clr_locked.g, clr_locked.b, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            return
        end

        if isCurrent then
            DrawRound(rad, 0, 0, w, h, Color(10, 26, 40, 220))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 170), 1)
        else
            DrawRound(rad, 0, 0, w, h, Color(10, 30, 48, 200 + btn.HoverLerp * 55))

            if btn.HoverLerp > 0.01 then
                DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, btn.HoverLerp * 45), math.max(3, SX(6)))
            end

            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 120 + btn.HoverLerp * 135), math.max(1, SX(1)))
        end

        local label = isCurrent and "ВЫБРАНО" or "ВЫБРАТЬ"
        local tc = isCurrent and clr_accent or Color(240, 248, 255, 245)

        draw.SimpleText(label, "ZProf_Btn", w * 0.5, h * 0.5, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.SelectButton.DoClick = function()
        local key = self.Selected or ""
        if MyChoice() == key then return end

        if not ProfUnlocked(MyXP(), key) then
            surface.PlaySound("buttons/button10.wav")
            return
        end

        net.Start("HMCD_ProfSelect")
            net.WriteString(key)
        net.SendToServer()
        ZProf.ClientChoice = key
        RunConsoleCommand("hmcd_prof_setchoice", key)
        surface.PlaySound("buttons/button14.wav")
    end

    self:BuildCards()
end

function PANEL:AddCard(key, meta, isAuto)
    local card = vgui.Create("DButton", self)
    card:SetText("")
    card:SetCursor("hand")
    card.Key = key
    card.Meta = meta
    card.IsAuto = isAuto or false
    card.HoverLerp = 0

    local luaMenu = self

    card.DoClick = function()
        luaMenu.Selected = key
        surface.PlaySound("ui/buttonrollover.wav")
    end

    card.Think = function()
        card.HoverLerp = LerpFT(0.16, card.HoverLerp or 0, card:IsHovered() and 1 or 0)

        if card.BaseX then
            card:SetPos(card.BaseX, card.BaseY - card.HoverLerp * SX(10))
        end
    end

    card.Paint = function(btn, w, h)
        local hover = btn.HoverLerp or 0
        local meta = btn.Meta
        local isSel = luaMenu.Selected == btn.Key
        local xp = MyXP()
        local cost = btn.IsAuto and 0 or ProfCost(btn.Key)
        local unlocked = btn.IsAuto or ProfUnlocked(xp, btn.Key)
        local accent = (btn.IsAuto and clr_cyan) or (meta and meta.Color) or clr_accent

        if not unlocked then
            accent = clr_locked
        end

        local rad = math.max(5, SX(12))

        DrawRound(rad, 0, 0, w, h, Color(
            Lerp(hover, clr_card.r, clr_card_hover.r),
            Lerp(hover, clr_card.g, clr_card_hover.g),
            Lerp(hover, clr_card.b, clr_card_hover.b),
            Lerp(hover, clr_card.a, clr_card_hover.a)
        ))

        if isSel then
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60), math.max(3, SX(6)))
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 220), math.max(1, SX(2)))
        else
            DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 14 + hover * 60), 1)
        end

        DrawRound(SX(3), SX(18), SX(18), w - SX(36), math.max(2, SX(4)), Color(accent.r, accent.g, accent.b, 190 + hover * 65))

        local title = btn.IsAuto and "Авто" or meta.Title

        surface.SetFont("ZProf_CardTitle")
        local titleW = surface.GetTextSize(title)
        local titleX = w * 0.5

        if titleW > w - SX(36) then
            surface.SetFont("ZProf_Short")
            titleW = surface.GetTextSize(title)
        end

        draw.SimpleText(title, titleW > w - SX(36) and "ZProf_Short" or "ZProf_CardTitle", titleX, SX(44), unlocked and clr_text or clr_locked, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local short = btn.IsAuto and "Случайная профессия каждый раунд" or meta.Short
        local shortLines = WrapText(short, "ZProf_Short", w - SX(36))
        local sy = SX(84)

        for i = 1, math.min(#shortLines, 2) do
            draw.SimpleText(shortLines[i], "ZProf_Short", w * 0.5, sy, Color(accent.r, accent.g, accent.b, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            sy = sy + SX(22)
        end

        local desc = btn.IsAuto and "Профессия выдаётся случайно каждый раунд.\nВыберите карточку, чтобы получать её всегда." or meta.Desc
        local ly = sy + SX(12)
        local space = h - ly - SX(74)
        local fitted = FitDesc(desc, w - SX(36), space)
        local lines = fitted.lines
        local shown = math.min(#lines, fitted.limit)
        local textCol = Color(196, 214, 232, unlocked and 220 or 170)

        for i = 1, shown do
            local line = lines[i]

            if i == shown and #lines > shown then
                surface.SetFont(fitted.font)
                while line ~= "" and surface.GetTextSize(line .. "...") > w - SX(36) do
                    line = string.sub(line, 1, #line - 2)
                end
                line = line .. "..."
            end

            draw.SimpleText(line, fitted.font, w * 0.5, ly, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            ly = ly + fitted.lineH
        end

        -- if isSel then
        --     draw.SimpleText("✓", "ZProf_Status", w - SX(28), SX(10), clr_accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        -- end

        if btn.IsAuto then
            draw.SimpleText("ВСЕГДА ДОСТУПНО", "ZProf_Status", w * 0.5, h - SX(34), Color(clr_cyan.r, clr_cyan.g, clr_cyan.b, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif unlocked then
            local openText = cost > 0 and ("ОТКРЫТО — " .. string.Comma(cost) .. " ОПЫТА") or "ОТКРЫТО СРАЗУ"

            if ProfVIPOnly(btn.Key) then openText = "VIP — " .. openText end

            draw.SimpleText(openText, "ZProf_Status", w * 0.5, h - SX(34), Color(accent.r, accent.g, accent.b, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            local frac = cost > 0 and math.Clamp(xp / cost, 0, 1) or 1
            local liveCol = (meta and meta.Color) or clr_accent
            local barW = w - SX(44)
            local barH = math.max(3, SX(7))
            local barX = SX(22)
            local barY = h - SX(28)
            local barRad = barH * 0.5

            local lockText = "НУЖНО " .. string.Comma(cost) .. " ОПЫТА"

            if ProfVIPOnly(btn.Key) and not IsVIP() then
                lockText = xp >= cost and "ТОЛЬКО ДЛЯ VIP" or ("ТОЛЬКО ДЛЯ VIP — " .. string.Comma(cost) .. " ОПЫТА")
            end

            draw.SimpleText(lockText, "ZProf_Status", w * 0.5, h - SX(48), Color(clr_locked.r, clr_locked.g, clr_locked.b, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            DrawRound(barRad, barX, barY, barW, barH, Color(255, 255, 255, 24))
            DrawRound(barRad, barX, barY, math.max(barH, barW * frac), barH, Color(liveCol.r, liveCol.g, liveCol.b, 205))

            draw.SimpleText(string.Comma(xp) .. " / " .. string.Comma(cost), "ZProf_Status", w * 0.5, barY + barH + SX(10), Color(142, 162, 180, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    self.Cards[#self.Cards + 1] = card

    return card
end

function PANEL:BuildCards()
    self:AddCard("", nil, true)

    for _, key in ipairs(PROFESSION_ORDER) do
        local meta = PROFESSION_META[key]
        if meta then
            self:AddCard(key, meta, false)
        end
    end
end

function PANEL:First()
    self:AlphaTo(255, 0.18, 0, nil)
end

function PANEL:PerformLayout(w, h)
    local count = #self.Cards

    if count > 0 then
        local gap = SX(14)
        local availW = w - SX(72)
        local cardW = math.min(SX(310), math.floor((availW - (count - 1) * gap) / count))
        local cardH = math.floor(math.min(cardW * 1.55, h * 0.62))
        local totalW = count * cardW + (count - 1) * gap
        local startX = math.floor((w - totalW) * 0.5)
        local y = math.floor(h * 0.5 - cardH * 0.5 + SX(24))

        for i, card in ipairs(self.Cards) do
            card.BaseX = startX + (i - 1) * (cardW + gap)
            card.BaseY = y
            card:SetSize(cardW, cardH)
        end
    end

    if IsValid(self.SelectButton) then
        local bw = SX(360)
        local bh = SX(64)
        self.SelectButton:SetSize(bw, bh)
        self.SelectButton:SetPos(math.floor((w - bw) * 0.5), h - bh - SX(44))
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

    surface.SetFont("ZProf_Brand")
    local xW = surface.GetTextSize("OT-")
    local brandW = xW + surface.GetTextSize("CITY")

    draw.SimpleText("OT-", "ZProf_Brand", cx - brandW * 0.5 + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZProf_Brand", cx - brandW * 0.5 + xW + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("OT-", "ZProf_Brand", cx - brandW * 0.5, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("CITY", "ZProf_Brand", cx - brandW * 0.5 + xW, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local sub = "ВЫБОР ПРОФЕССИИ"
    surface.SetFont("ZProf_Sub")
    local subW = surface.GetTextSize(sub)

    draw.SimpleText(sub, "ZProf_Sub", cx, headerY + SX(58), Color(200, 225, 245, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local stripeY = headerY + SX(58) + SX(11)
    local stripeW = SX(48)

    DrawSlant(cx - subW * 0.5 - SX(18) - stripeW, stripeY, stripeW, math.max(2, SX(3)), -SX(6), clr_accent)
    DrawSlant(cx + subW * 0.5 + SX(18), stripeY, stripeW, math.max(2, SX(3)), SX(6), clr_accent)

    local xp = MyXP()
    local prevCost, nextKey, nextCost = 0, nil, nil

    for _, key in ipairs(PROFESSION_ORDER) do
        local cost = ProfCost(key)

        if xp >= cost then
            if cost > prevCost then prevCost = cost end
        elseif not nextKey or cost < nextCost then
            nextKey, nextCost = key, cost
        end
    end

    local nextMeta = nextKey and PROFESSION_META[nextKey] or nil
    local fillCol = (nextMeta and nextMeta.Color) or clr_cyan
    local target = 1

    if nextKey then
        target = math.Clamp((xp - prevCost) / math.max(1, nextCost - prevCost), 0, 1)
    end

    self.XPFill = LerpFT(0.2, self.XPFill or 0, target)

    local fill = math.Clamp(self.XPFill or 0, 0, 1)
    local barW = math.min(SX(560), w * 0.44)
    local barH = math.max(6, SX(14))
    local barX = cx - barW * 0.5
    local barY = headerY + SX(98)
    local barRad = barH * 0.5

    DrawRound(barRad, barX, barY, barW, barH, Color(4, 10, 18, 225))

    if fill > 0.001 then
        DrawRound(barRad, barX, barY, math.max(barH, barW * fill), barH, Color(fillCol.r, fillCol.g, fillCol.b, 235))
    end

    DrawRoundOutlined(barRad, barX, barY, barW, barH, Color(clr_accent.r, clr_accent.g, clr_accent.b, 130), 1)

    draw.SimpleText("ОПЫТ: " .. string.Comma(xp), "ZProf_Status", barX, barY - SX(8), Color(clr_text.r, clr_text.g, clr_text.b, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

    local rightText = "ВСЕ ПРОФЕССИИ ОТКРЫТЫ"

    if nextKey then
        rightText = "ДО " .. string.upper(tostring((nextMeta and nextMeta.Title) or nextKey)) .. ": " .. string.Comma(math.max(0, nextCost - xp))
    end

    draw.SimpleText(rightText, "ZProf_Status", barX + barW, barY - SX(8), Color(fillCol.r, fillCol.g, fillCol.b, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(math.floor(fill * 100 + 0.5) .. "%", "ZProf_Status", cx, barY + barH + SX(7), Color(162, 190, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    self:AlphaTo(0, 0.12, 0, function()
        if IsValid(self) then self:Remove() end
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZProfessions", PANEL, "ZFrame")

local function ToggleMenu()
    if IsValid(ZProf.Menu) then
        ZProf.Menu:Close()
        ZProf.Menu = nil
        return
    end
    local f = vgui.Create("ZProfessions")
    f:MakePopup()
    f:First()
    ZProf.Menu = f
end

concommand.Add("hg_professions", ToggleMenu)
concommand.Add("hmcd_professions", ToggleMenu)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "professions menu loaded\n")
