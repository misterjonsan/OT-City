if SERVER then return end

local RNDX = _G.RNDX or include("libnyx/lib/rndx.lua")

HG = HG or {}
HG.Cases = HG.Cases or {}

local Cases = HG.Cases
local UI = {}
local state = {data = nil, selected = nil, amount = 1, frame = nil, opening = false, wantOpen = false}
local palette = {bg = Color(3, 5, 9, 248), panel = Color(5, 10, 18, 245), card = Color(6, 12, 20, 245), cardHover = Color(12, 22, 36, 250), text = Color(240, 248, 255), muted = Color(150, 190, 220), accent = Color(31, 182, 255), cyan = Color(127, 230, 255), green = Color(31, 182, 255), black = Color(0, 0, 0, 180)}

local fontScale = math.Clamp(ScrH() / 900, .82, 1.15)
local function FontSize(size) return math.max(10, math.floor(size * fontScale)) end
surface.CreateFont("HGCases.Title", {font = "Montserrat SemiBold", size = FontSize(32), weight = 700, extended = true})
surface.CreateFont("HGCases.Heading", {font = "Montserrat SemiBold", size = FontSize(24), weight = 700, extended = true})
surface.CreateFont("HGCases.Medium", {font = "Montserrat Medium", size = FontSize(19), weight = 500, extended = true})
surface.CreateFont("HGCases.Small", {font = "Montserrat Medium", size = FontSize(16), weight = 500, extended = true})
surface.CreateFont("HGCases.Tiny", {font = "Montserrat SemiBold", size = FontSize(14), weight = 600, extended = true})
surface.CreateFont("HGCases.Price", {font = "Montserrat SemiBold", size = FontSize(27), weight = 700, extended = true})
surface.CreateFont("HGCases.Brand", {font = "Bahnschrift", size = FontSize(38), weight = 800, italic = true, antialias = true, extended = true})
surface.CreateFont("HGCases.Close", {font = "Montserrat SemiBold", size = FontSize(34), weight = 800, antialias = true, extended = true})

local function Scale(n)
    return math.floor(n * math.min(ScrW() / 1600, ScrH() / 900))
end

local function C(c, a)
    return Color(c.r, c.g, c.b, a == nil and c.a or a)
end

local function LerpColor(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a, b.a))
end

local function Box(r, x, y, w, h, col)
    RNDX.Draw(math.min(r, math.floor(math.min(w, h) / 2)), x, y, w, h, col)
end

local function Outline(r, x, y, w, h, col, thick)
    RNDX.DrawOutlined(math.min(r, math.floor(math.min(w, h) / 2)), x, y, w, h, col, thick or 1)
end

local function Slant(x, y, w, h, col, skew)
    skew = skew or h
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly({{x = x + skew, y = y}, {x = x + w + skew, y = y}, {x = x + w, y = y + h}, {x = x, y = y + h}})
end

local bgMaterial = Material("otcity/fone.png", "smooth")

local function SmoothNoise(t, f1, f2, f3, phase)
    phase = phase or 0
    return math.sin(t * f1 * math.pi * 2 + phase) * 0.55
        + math.sin(t * f2 * math.pi * 2 + phase + 2.399) * 0.30
        + math.sin(t * f3 * math.pi * 2 + phase + 5.131) * 0.15
end

local function PaintBG(pnl, w, h, dim)
    local mat = bgMaterial
    local iw = mat and mat:Width() or 0
    local ih = mat and mat:Height() or 0
    if not mat or mat:IsError() or iw <= 0 or ih <= 0 then
        surface.SetDrawColor(palette.bg)
        surface.DrawRect(0, 0, w, h)
        return
    end
    pnl.BGStartTime = pnl.BGStartTime or RealTime()
    local elapsed = RealTime() - pnl.BGStartTime
    local dt = math.Clamp(FrameTime(), 0, 0.1)
    local blend = 1 - math.exp(-dt * 1.35)
    local zoomTarget = 1.18 + (SmoothNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
    local panXTarget = SmoothNoise(elapsed, 0.0131, 0.0207, 0.0331, 1.3)
    local panYTarget = SmoothNoise(elapsed, 0.0113, 0.0181, 0.0293, 4.9)
    pnl.BGZoom = (pnl.BGZoom or zoomTarget) + (zoomTarget - (pnl.BGZoom or zoomTarget)) * blend
    pnl.BGPanX = (pnl.BGPanX or panXTarget) + (panXTarget - (pnl.BGPanX or panXTarget)) * blend
    pnl.BGPanY = (pnl.BGPanY or panYTarget) + (panYTarget - (pnl.BGPanY or panYTarget)) * blend
    local scale = math.max(w / iw, h / ih) * pnl.BGZoom
    local drawW, drawH = iw * scale, ih * scale
    local safeX = math.max((drawW - w) * 0.5, 0)
    local safeY = math.max((drawH - h) * 0.5, 0)
    local x = (w - drawW) * 0.5 + pnl.BGPanX * safeX * 0.72
    local y = (h - drawH) * 0.5 + pnl.BGPanY * safeY * 0.72
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, drawW, drawH)
    surface.SetDrawColor(2, 8, 14, 60)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(1, 4, 8, dim or 170)
    surface.DrawRect(0, 0, w, h)
end

local function Text(text, font, x, y, col, ax, ay)
    draw.SimpleText(tostring(text or ""), font, x + 1, y + 1, Color(0, 0, 0, math.min(190, col.a or 255)), ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(text or ""), font, x, y, col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

local function Wrapped(text, font, width)
    surface.SetFont(font)
    local lines, line = {}, ""
    for _, word in ipairs(string.Explode(" ", tostring(text or ""))) do
        local test = line == "" and word or line .. " " .. word
        if surface.GetTextSize(test) > width and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local function TextWrap(text, font, x, y, width, col, maxLines)
    local lines = Wrapped(text, font, width)
    surface.SetFont(font)
    local _, lineH = surface.GetTextSize("Wg")
    for i, line in ipairs(lines) do
        if maxLines and i > maxLines then break end
        if maxLines and i == maxLines and #lines > maxLines then line = line .. "..." end
        Text(line, font, x, y + (i - 1) * (lineH + Scale(3)), col)
    end
end

local function TextWrapFit(text, fonts, x, y, width, maxH, col)
    for fi, font in ipairs(fonts) do
        local lines = Wrapped(text, font, width)
        surface.SetFont(font)
        local _, lineH = surface.GetTextSize("Wg")
        local step = lineH + Scale(3)
        if #lines * step <= maxH or fi == #fonts then
            for i, line in ipairs(lines) do
                Text(line, font, x, y + (i - 1) * step, col)
            end
            return
        end
    end
end

local function ReelWrapped(text, font, width)
    surface.SetFont(font)
    width = math.max(1, tonumber(width) or 1)
    local lines, line = {}, ""
    local function appendWord(word)
        if surface.GetTextSize(word) <= width then return {word} end
        local parts, part = {}, ""
        for i = 1, #word do
            local test = part .. string.sub(word, i, i)
            if part ~= "" and surface.GetTextSize(test) > width then
                parts[#parts + 1] = part
                part = string.sub(word, i, i)
            else
                part = test
            end
        end
        if part ~= "" then parts[#parts + 1] = part end
        return parts
    end
    for _, raw in ipairs(string.Explode(" ", tostring(text or ""))) do
        for _, word in ipairs(appendWord(raw)) do
            local test = line == "" and word or line .. " " .. word
            if line ~= "" and surface.GetTextSize(test) > width then
                lines[#lines + 1] = line
                line = word
            else
                line = test
            end
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local function DrawReelName(text, x, y, width, maxH)
    local fonts = {"HGCases.Small", "HGCases.Tiny"}
    for index, font in ipairs(fonts) do
        local lines = ReelWrapped(text, font, width)
        surface.SetFont(font)
        local _, lineH = surface.GetTextSize("Wg")
        local step = lineH + math.max(1, Scale(2))
        if (#lines <= 2 and #lines * step <= maxH) or index == #fonts then
            if #lines > 2 then
                lines = {lines[1], lines[2] .. "..."}
            end
            local top = y - (#lines * step) * .5 + step * .5
            for i, line in ipairs(lines) do
                Text(line, font, x, top + (i - 1) * step, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return
        end
    end
end

local function Coin(x, y, size, col)
    col = col or palette.accent
    local radius = math.max(3, math.floor(size * .5))
    RNDX.DrawCircle(x, y, radius, col)
    RNDX.DrawCircleOutlined(x, y, radius, Color(200, 235, 255, 135), 1)
end

local rankIconCache = {}
local rankIconLoading = {}

local function IsURL(path)
    path = tostring(path or "")
    return string.StartWith(path, "http://") or string.StartWith(path, "https://")
end

local function URLIconPath(url, ext)
    return "hg_cases_icons/" .. util.CRC(tostring(url or "")) .. "." .. ext
end

local function DataMaterial(path)
    local mat = Material("../data/" .. path, "smooth noclamp")
    if not mat or mat:IsError() then return nil end
    return mat
end

local function ImageExtension(body, url)
    if body:sub(1, 8) == "\137PNG\r\n\26\n" then return "png" end
    if body:sub(1, 3) == "\255\216\255" then return "jpg" end
    if body:sub(1, 4) == "RIFF" and body:sub(9, 12) == "WEBP" then return "webp" end
    return string.match(tostring(url):lower(), "%.(png|jpg|jpeg|webp)%??[^/]*$") or "png"
end

local function FetchRankIcon(url)
    if rankIconLoading[url] then return end
    rankIconLoading[url] = true
    http.Fetch(url, function(body, _, _, code)
        if tonumber(code) and (code < 200 or code >= 300) then rankIconLoading[url] = nil return end
        if not body or body == "" or body:find("<html", 1, true) or body:find("<!DOCTYPE", 1, true) then rankIconLoading[url] = nil return end
        file.CreateDir("hg_cases_icons")
        local path = URLIconPath(url, ImageExtension(body, url))
        file.Write(path, body)
        local mat = DataMaterial(path)
        if mat then rankIconCache[url] = mat else file.Delete(path) end
        rankIconLoading[url] = nil
    end, function()
        rankIconLoading[url] = nil
    end)
end

local function MaterialSafe(path)
    path = tostring(path or "")
    if path == "" then return nil end
    if IsURL(path) then
        if rankIconCache[path] and not rankIconCache[path]:IsError() then return rankIconCache[path] end
        for _, ext in ipairs({"png", "jpg", "jpeg", "webp"}) do
            local cached = URLIconPath(path, ext)
            if file.Exists(cached, "DATA") then
                local mat = DataMaterial(cached)
                if mat then rankIconCache[path] = mat return mat end
                file.Delete(cached)
            end
        end
        FetchRankIcon(path)
        return nil
    end
    local mat = Material(path, "smooth noclamp")
    if mat:IsError() then return nil end
    return mat
end

local function DrawMaterial(mat, x, y, w, h, tint)
    if not mat then return false end
    local mw, mh = mat:Width(), mat:Height()
    local scale = math.min(w / math.max(mw, 1), h / math.max(mh, 1))
    local dw, dh = mw * scale, mh * scale
    surface.SetMaterial(mat)
    surface.SetDrawColor((tint or color_white).r, (tint or color_white).g, (tint or color_white).b, (tint or color_white).a)
    surface.DrawTexturedRect(x + (w - dw) / 2, y + (h - dh) / 2, dw, dh)
    return true
end

local function Rarity(key)
    if not state.data then return {name = "COMMON", chance = 0, color = {r = 220, g = 225, b = 222}} end
    return state.data.rarities[key] or state.data.rarities.common
end

local RARITY_COLORS = {
    common = Color(150, 178, 200),
    uncommon = Color(90, 210, 255),
    rare = Color(31, 182, 255),
    epic = Color(168, 132, 255),
    legendary = Color(255, 190, 75),
}

local function RarityColor(key, alpha)
    local c = state.data and state.data.rarities and state.data.rarities[key] and state.data.rarities[key].color
    c = c or RARITY_COLORS[key] or RARITY_COLORS.common
    return Color(c.r, c.g, c.b, alpha or 255)
end

local function CaseAccent(case, alpha)
    local a = case and case.accent
    if a then return Color(a.r, a.g, a.b, alpha or 255) end
    if case and case.currency == "rub" then return Color(255, 190, 75, alpha or 255) end
    return Color(palette.accent.r, palette.accent.g, palette.accent.b, alpha or 255)
end

local function Selected()
    if not state.data then return nil end
    for _, case in ipairs(state.data.cases) do if case.id == state.selected then return case end end
    return state.data.cases[1]
end

local function ToggleButton(parent, label, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Hover = 0
    b.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
        local fill = LerpColor(self.Hover, Color(6, 12, 20, 255), Color(12, 22, 36, 255))
        Box(10, 0, 0, w, h, fill)
        Outline(10, 0, 0, w, h, C(palette.accent, 70 + self.Hover * 150), 1)
        Text(label, "HGCases.Small", w / 2, h / 2, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = function()
        surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
        onClick()
    end
    return b
end

local function CloseButton(parent, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Hover = 0
    b.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 12, self.Hover, self:IsHovered() and 1 or 0)
        Box(10, 0, 0, w, h, LerpColor(self.Hover, Color(6, 12, 20, 190), Color(12, 22, 36, 225)))
        Outline(10, 0, 0, w, h, LerpColor(self.Hover, C(palette.accent, 110), C(palette.accent, 235)), 2)
        local col = LerpColor(self.Hover, palette.text, palette.accent)
        Text("×", "HGCases.Close", w * 0.5, h * 0.46, Color(col.r, col.g, col.b, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = function()
        surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
        onClick()
    end
    return b
end

local function DrawCaseArt(case, x, y, w, h)
    local mat = MaterialSafe(case.material)
    if not DrawMaterial(mat, x, y, w, h) then Text("НЕТ ИЗОБРАЖЕНИЯ", "HGCases.Tiny", x + w / 2, y + h / 2, palette.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
end

local iconModels = {}
local iconQueue = {}
local iconQueued = {}
local iconTries = {}
local ICON_LOAD_PER_TICK = 2
local ICON_MAX_TRIES = 40
local function RequestIconModel(path)
    if not path or path == "" then return nil end
    local cached = iconModels[path]
    if IsValid(cached) then return cached end
    if not iconQueued[path] then
        iconQueued[path] = true
        iconQueue[#iconQueue + 1] = path
    end
    return nil
end
hook.Add("Think", "HGCases.IconLoader", function()
    for i = 1, ICON_LOAD_PER_TICK do
        local path = table.remove(iconQueue, 1)
        if not path then return end
        if not IsValid(iconModels[path]) then
            if util.IsValidModel and not util.IsValidModel(path) then
                pcall(util.PrecacheModel, path)
            end
            local ent = ClientsideModel(path, RENDERGROUP_OTHER)
            if IsValid(ent) then
                ent:SetNoDraw(true)
                ent:SetIK(false)
                iconModels[path] = ent
                iconQueued[path] = nil
                iconTries[path] = nil
            else
                iconTries[path] = (iconTries[path] or 0) + 1
                if iconTries[path] < ICON_MAX_TRIES then
                    iconQueue[#iconQueue + 1] = path
                else
                    iconQueued[path] = nil
                end
            end
        else
            iconQueued[path] = nil
        end
    end
end)
local function IconModelReady(path)
    local v = RequestIconModel(path)
    return v ~= nil and v ~= false and IsValid(v)
end
local function GetIconModel(path)
    local v = RequestIconModel(path)
    if v and v ~= false and IsValid(v) then return v end
    return nil
end

local function DrawModelIcon(path, sx, sy, w, h)
    if w <= 0 or h <= 0 then return false end
    local ent = GetIconModel(path)
    if not ent then return false end
    ent:SetupBones()
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local center = (mins + maxs) * 0.5
    local radius = math.max(1, mins:Distance(maxs) * 0.5)
    local fov = 32
    local dist = radius / math.sin(math.rad(fov * 0.5)) * 1.08
    local yaw = 35
    local dir = Angle(0, yaw, 0):Forward()
    local pos = center + dir * dist + Vector(0, 0, radius * 0.04)
    local ang = (center - pos):Angle()
    local ok = true
    cam.Start3D(pos, ang, fov, sx, sy, w, h)
        render.SuppressEngineLighting(true)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        for i = 0, 6 do render.SetModelLighting(i, 0.62, 0.66, 0.6) end
        ok = pcall(ent.DrawModel, ent)
        render.SuppressEngineLighting(false)
    cam.End3D()
    return ok ~= false
end

local function RewardFallbackLabel(reward)
    if reward.kind == "rank" then return "..." end
    if reward.kind == "accessory" then return "ITEM" end
    return "DROP"
end

local CURRENCY_ICONS = {rub = "monteract/case/money.png", otcoin = "monteract/case/coin.png"}

local function DrawRewardIcon(reward, x, y, w, h, panel)
    local col = RarityColor(reward.rarity)
    if reward.kind == "rub" or reward.kind == "otcoin" then
        local mat = MaterialSafe(reward.material)
        if not mat then mat = MaterialSafe(CURRENCY_ICONS[reward.kind]) end
        if DrawMaterial(mat, x, y, w, h, color_white) then return end
        if reward.kind == "rub" then
            Text("₽", "HGCases.Title", x + w * .5, y + h * .5, Color(255, 198, 78), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            Text("COIN", "HGCases.Small", x + w * .5, y + h * .5, palette.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end
    if reward.model and reward.model ~= "" then
        local sx, sy = x, y
        if IsValid(panel) then sx, sy = panel:LocalToScreen(x, y) end
        if DrawModelIcon(reward.model, sx, sy, w, h) then return end
    end
    local mat = MaterialSafe(reward.material)
    if DrawMaterial(mat, x, y, w, h, color_white) then return end
    draw.SimpleText(RewardFallbackLabel(reward), "HGCases.Tiny", x + w * .5, y + h * .5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function Pct(chance)
    chance = tonumber(chance) or 0
    if chance <= 0 then return "0%" end
    if chance < 10 and chance ~= math.floor(chance) then return string.format("%.1f%%", chance) end
    return string.format("%d%%", math.Round(chance))
end

local function BuildRewardCard(parent, reward, compact)
    local pnl = vgui.Create("DPanel", parent)
    pnl.Reward = reward
    pnl.Hover = 0
    pnl:SetPaintBackground(false)
    pnl.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 10, self.Hover, self:IsHovered() and 1 or 0)
        local col = RarityColor(self.Reward.rarity)
        Box(10, 0, 0, w, h, Color(6 + self.Hover * 6, 12 + self.Hover * 10, 20 + self.Hover * 16, 250))
        Outline(10, 0, 0, w, h, C(col, 70 + self.Hover * 90), 1)
        DrawRewardIcon(self.Reward, 8, 6, w - 16, h * .46, self)
        Text(self.Reward.name, "HGCases.Small", w / 2, h * .60, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Text(self.Reward.subtitle, "HGCases.Tiny", w / 2, h * .74, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Text(Pct(self.Reward.chance), "HGCases.Small", w / 2, h * .89, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return pnl
end

local function OpenResult(result)
    state.opening = true
    local f = vgui.Create("DFrame")
    f:SetSize(ScrW(), ScrH())
    f:SetPos(0, 0)
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, .16, 0)
    local rewards = result.rewards or {}
    local n = math.max(1, #rewards)
    f.Paint = function(self, w, h)
        PaintBG(self, w, h, 215)
        Text(n > 1 and "ВАШИ НАГРАДЫ" or "ВАША НАГРАДА", "HGCases.Title", w / 2, ScrH() / 2 - Scale(235), palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local gap = Scale(20)
    local cardW = math.min(Scale(250), math.floor((ScrW() * 0.86 - gap * (n - 1)) / n))
    local cardH = math.floor(cardW * 1.24)
    local totalW = cardW * n + gap * (n - 1)
    local startX = math.floor(ScrW() / 2 - totalW / 2)
    local cy = math.floor(ScrH() / 2 - cardH / 2)
    for i = 1, n do
        local reward = rewards[i]
        local card = vgui.Create("DPanel", f)
        card:SetSize(cardW, cardH)
        card:SetPos(startX + (i - 1) * (cardW + gap), cy)
        card:SetPaintBackground(false)
        card.t = 0
        card.delay = (i - 1) * 0.1
        card.born = SysTime()
        card.Think = function(self)
            if SysTime() - self.born < self.delay then return end
            if self.t < 1 then self.t = math.min(1, self.t + FrameTime() * 4.5) end
        end
        card.Paint = function(self, w, h)
            local e = 1 - (1 - self.t) ^ 3
            local s = 0.72 + 0.28 * e
            local dw, dh = w * s, h * s
            local ox, oy = (w - dw) / 2, (h - dh) / 2
            local col = RarityColor(reward.rarity)
            Box(16, ox, oy, dw, dh, Color(6, 12, 20, math.floor(255 * e)))
            Outline(16, ox, oy, dw, dh, C(col, 235 * e), 2)
            if self.t < 0.15 then return end
            DrawRewardIcon(reward, ox + dw * 0.12, oy + dh * 0.12, dw * 0.76, dh * 0.44, self)
            Text(reward.name, "HGCases.Heading", ox + dw / 2, oy + dh - Scale(70), palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if reward.duplicate then
                local dcur = reward.compensationCurrency == "rub" and " ₽" or " OT-COIN"
                Text("УЖЕ ЕСТЬ • +" .. string.Comma(math.floor(tonumber(reward.compensation) or 0)) .. dcur, "HGCases.Small", ox + dw / 2, oy + dh - Scale(44), Color(255, 205, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                Text(reward.subtitle, "HGCases.Small", ox + dw / 2, oy + dh - Scale(44), col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            if reward.chance then Text("ШАНС " .. Pct(reward.chance), "HGCases.Tiny", ox + dw / 2, oy + dh - Scale(22), palette.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        end
    end
    local close = ToggleButton(f, "ЗАБРАТЬ", function()
        f:AlphaTo(0, .16, 0, function() if IsValid(f) then f:Remove() end end)
        state.opening = false
        state.wantOpen = true
        if IsValid(state.frame) then state.frame:Remove() end
        netstream.Start("HG.Cases.Request")
    end)
    close:SetSize(Scale(210), Scale(48))
    close:SetPos(ScrW() / 2 - close:GetWide() / 2, cy + cardH + Scale(30))
end

local function BuildOpening(case)
    local f = vgui.Create("DFrame")
    f:SetSize(ScrW(), ScrH())
    f:SetPos(0, 0)
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:MakePopup()
    f:SetDraggable(false)
    f:SetAlpha(0)
    f:AlphaTo(255, .16, 0)
    f.Paint = function(self, w, h)
        PaintBG(self, w, h, 178)
        Outline(16, 0, 0, w, h, C(palette.accent, 70), 1)
        surface.SetFont("HGCases.Title")
        local titleW = surface.GetTextSize(case.title)
        Text(case.title, "HGCases.Title", w * .5, Scale(44), palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Slant(w * .5 - titleW * .5 - Scale(72), Scale(43), Scale(54), math.max(2, Scale(3)), C(palette.accent, 190), Scale(6))
        Slant(w * .5 + titleW * .5 + Scale(18), Scale(43), Scale(54), math.max(2, Scale(3)), C(palette.accent, 190), Scale(6))
        surface.SetDrawColor(palette.accent.r, palette.accent.g, palette.accent.b, 32)
        surface.DrawRect(0, Scale(80), w, 1)
    end
    f.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then if state.opening then return true end state.wantOpen = false end end
    local back = ToggleButton(f, "← НАЗАД", function()
        if state.opening then return end
        state.awaitOpen = nil
        state.wantOpen = true
        f:Remove()
        state.opening = false
        UI.Main()
    end)
    back:SetSize(Scale(125), Scale(42))
    back:SetPos(Scale(16), Scale(17))
    local closeBtn = CloseButton(f, function()
        if state.opening then return end
        state.awaitOpen = nil
        state.wantOpen = false
        f:Remove()
        state.opening = false
    end)
    closeBtn:SetSize(Scale(46), Scale(46))
    closeBtn:SetPos(f:GetWide() - Scale(58), Scale(15))
    local reelArea = vgui.Create("DPanel", f)
    reelArea:SetPos(Scale(55), Scale(100))
    reelArea:SetSize(f:GetWide() - Scale(110), Scale(560))
    reelArea:SetPaintBackground(false)
    local amountBox = vgui.Create("DPanel", f)
    amountBox:SetSize(Scale(98), Scale(62))
    amountBox:SetPos(f:GetWide() / 2 - Scale(220), Scale(690))
    amountBox:SetPaintBackground(false)
    amountBox.Paint = function(self, w, h)
        Box(10, 0, 0, w, h, Color(6, 12, 20, 255))
        Outline(10, 0, 0, w, h, C(CaseAccent(case), 100), 1)
        Text("x" .. state.amount, "HGCases.Heading", w / 2, h / 2, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local open = vgui.Create("DButton", f)
    open:SetText("")
    open:SetSize(Scale(400), Scale(62))
    open:SetPos(f:GetWide() / 2 - Scale(105), Scale(690))
    open.Hover = 0
    open.Paint = function(self, w, h)
        self.Hover = Lerp(FrameTime() * 10, self.Hover, self:IsHovered() and 1 or 0)
        local ca = CaseAccent(case)
        Box(10, 0, 0, w, h, LerpColor(self.Hover, Color(ca.r * .82, ca.g * .82, ca.b * .82), ca))
        Text("ОТКРЫТЬ ЗА " .. string.Comma(case.price * state.amount) .. (case.currency == "rub" and " ₽" or " OT-COIN"), "HGCases.Heading", w / 2, h / 2, Color(3, 10, 18), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    open.DoClick = function()
        if state.opening then return end
        surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
        state.opening = true
        netstream.Start("HG.Cases.Open", case.id, state.amount)
    end
    local chance = vgui.Create("DPanel", f)
    chance:SetSize(Scale(620), Scale(115))
    chance:SetPos(f:GetWide() / 2 - chance:GetWide() / 2, Scale(766))
    chance:SetPaintBackground(false)
    chance.Paint = function(self, w, h)
        Text("ШАНСЫ ВЫПАДЕНИЯ", "HGCases.Small", w / 2, 4, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local keys = {"common", "uncommon", "rare", "epic", "legendary"}
        for i, key in ipairs(keys) do
            local r = Rarity(key)
            local col = RarityColor(key)
            local bw, bh, x = Scale(110), Scale(62), (i - 1) * Scale(125)
            Box(8, x, Scale(35), bw, bh, Color(6, 12, 20, 255))
            Outline(7, x, Scale(35), bw, bh, C(col, 90), 1)
            Text(r.name, "HGCases.Tiny", x + bw / 2, Scale(48), col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            Text(r.chance .. "%", "HGCases.Heading", x + bw / 2, Scale(72), col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    local function MakeReel(index, total, won, rh, top)
        local reel = vgui.Create("DPanel", reelArea)
        reel:SetSize(reelArea:GetWide(), rh)
        reel:SetPos(0, top)
        reel:SetPaintBackground(false)
        local pad = rh * 0.09
        local ch = rh - pad * 2
        local cw = math.max(ch * 0.82, Scale(118))
        reel.cw, reel.ch, reel.pad, reel.step = cw, ch, pad, cw + cw * 0.1
        reel.items = {}
        for i = 1, 60 do reel.items[i] = case.rewards[math.random(1, #case.rewards)] end
        local landIndex = math.random(44, 51)
        if won then reel.items[landIndex] = won end
        reel.landIndex = landIndex
        reel.offset = 0
        reel.spinning = false
        reel.landed = false
        reel.glow = 0
        reel.lastUnder = nil
        reel.tick = index == 1
        reel.Think = function(self)
            if self.spinning then
                local t = math.Clamp((SysTime() - self.spinStart) / self.spinDuration, 0, 1)
                local e = 1 - (1 - t) ^ 4
                self.offset = self.startOffset + (self.targetOffset - self.startOffset) * e
                if self.tick then
                    local under = math.floor((self.offset + self:GetWide() / 2) / self.step)
                    if under ~= self.lastUnder then
                        if self.lastUnder ~= nil then surface.PlaySound("ui/buttonrollover.wav") end
                        self.lastUnder = under
                    end
                end
                if t >= 1 then
                    self.spinning = false
                    self.landed = true
                    surface.PlaySound("friends/friend_join.wav")
                    if self.onDone then self.onDone() end
                end
            end
            if self.landed and self.glow < 1 then self.glow = math.min(1, self.glow + FrameTime() * 3) end
        end
        reel.Paint = function(self, w, h)
            Box(12, 0, 0, w, h, Color(4, 8, 14, 255))
            Outline(12, 0, 0, w, h, C(CaseAccent(case), 92), 1)
            local cx = w / 2
            for i, reward in ipairs(self.items) do
                local x = (i - 1) * self.step - self.offset
                if x > -self.cw and x < w then
                    local col = RarityColor(reward.rarity)
                    local center = x + self.cw / 2
                    local focus = math.Clamp(1 - math.abs(center - cx) / (self.cw * 1.4), 0, 1)
                    local isWin = self.landed and i == self.landIndex
                    Box(8, x, self.pad, self.cw, self.ch, LerpColor(focus, Color(6, 12, 20, 255), Color(14, 28, 44, 255)))
                    local a = 110 + focus * 130
                    if isWin then a = 200 + math.sin(SysTime() * 6) * 55 end
                    if isWin and self.glow > 0 then Box(7, x, self.pad, self.cw, self.ch, C(col, 26 * self.glow)) end
                    Outline(7, x, self.pad, self.cw, self.ch, C(col, a), isWin and 2 or 1)
                    local isz = self.ch * 0.5
                    DrawRewardIcon(reward, center - isz / 2, self.pad + self.ch * 0.08, isz, isz, self)
                    DrawReelName(reward.name, center, self.pad + self.ch * 0.68, self.cw - Scale(12), self.ch * .20)
                    Text(reward.subtitle, "HGCases.Tiny", center, self.pad + self.ch * 0.91, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            local accent = C(CaseAccent(case), 255)
            Box(3, cx - Scale(2), Scale(4), Scale(4), h - Scale(8), accent)
            draw.NoTexture()
            surface.SetDrawColor(accent.r, accent.g, accent.b, 255)
            surface.DrawPoly({{x = cx - Scale(8), y = 2}, {x = cx + Scale(8), y = 2}, {x = cx, y = Scale(14)}})
            surface.DrawPoly({{x = cx - Scale(8), y = h - 2}, {x = cx, y = h - Scale(14)}, {x = cx + Scale(8), y = h - 2}})
        end
        return reel
    end
    local function PopulateReels(total, winners)
        reelArea:Clear()
        total = math.max(1, total)
        local gap = Scale(16)
        local avail = reelArea:GetTall()
        local rh = math.min(Scale(240), math.floor((avail - gap * (total - 1)) / total))
        local stackH = rh * total + gap * (total - 1)
        local top0 = math.floor((avail - stackH) / 2)
        local reels = {}
        for i = 1, total do
            reels[i] = MakeReel(i, total, winners and winners[i] or nil, rh, top0 + (i - 1) * (rh + gap))
        end
        return reels
    end
    local function SpinReels(data)
        local total = math.max(1, #data.rewards)
        local reels = PopulateReels(total, data.rewards)
        local landed = 0
        for i = 1, total do
            local reel = reels[i]
            timer.Simple((i - 1) * 0.3, function()
                if not IsValid(reel) then return end
                reel.startOffset = 0
                reel.offset = 0
                reel.targetOffset = (reel.landIndex - 1) * reel.step + reel.cw / 2 - reel:GetWide() / 2 + math.Rand(-reel.cw * 0.28, reel.cw * 0.28)
                reel.spinStart = SysTime()
                reel.spinDuration = 4.8
                reel.spinning = true
                reel.landed = false
                reel.glow = 0
                reel.lastUnder = nil
                surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
                reel.onDone = function()
                    landed = landed + 1
                    if landed >= total then
                        timer.Simple(0.7, function()
                            if IsValid(f) then f:Remove() end
                            state.awaitOpen = nil
                            OpenResult(data)
                        end)
                    end
                end
            end)
        end
    end
    PopulateReels(state.amount)
    state.awaitOpen = {frame = f, begin = SpinReels}
    state.frame = f
end

function UI.Main()
    if IsValid(state.frame) then state.frame:Remove() end
    if not Selected() then return end
    local f = vgui.Create("DFrame")
    f:SetSize(ScrW(), ScrH())
    f:SetPos(0, 0)
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:MakePopup()
    f:SetDraggable(false)
    f:SetAlpha(0)
    f:AlphaTo(255, .16, 0)
    f.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then if state.opening then return true end state.wantOpen = false end end
    f.NextSync = 0
    f.Think = function(self)
        if CurTime() >= self.NextSync then
            self.NextSync = CurTime() + 1
            netstream.Start("HG.Cases.Request")
        end
    end
    f.Paint = function(self, w, h)
        PaintBG(self, w, h, 178)
        Outline(16, 0, 0, w, h, C(palette.accent, 70), 1)
        surface.SetFont("HGCases.Brand")
        local otW = surface.GetTextSize("OT-")
        local brandW = otW + surface.GetTextSize("CITY")
        Text("OT-", "HGCases.Brand", Scale(30), Scale(34), palette.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        Text("CITY", "HGCases.Brand", Scale(30) + otW, Scale(34), palette.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        Text("КЕЙСЫ", "HGCases.Small", Scale(30) + brandW + Scale(16), Scale(30), palette.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        Slant(Scale(30) + brandW + Scale(16), Scale(42), Scale(44), math.max(2, Scale(3)), C(palette.accent, 170), Scale(6))
        Text("OT-COIN " .. string.Comma(math.max(0, math.floor(tonumber(state.data.otCoins) or 0))), "HGCases.Heading", w - Scale(74), Scale(24), palette.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        Text(string.Comma(math.max(0, math.floor(tonumber(state.data.rub) or 0))) .. " ₽", "HGCases.Heading", w - Scale(74), Scale(48), Color(255, 190, 75), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    local close = CloseButton(f, function() if state.opening then return end state.wantOpen = false f:Remove() end)
    close:SetSize(Scale(46), Scale(46))
    close:SetPos(f:GetWide() - Scale(58), Scale(14))
    local RebuildRewards
    local hero = vgui.Create("DPanel", f)
    hero:SetSize(f:GetWide() - Scale(84), Scale(300))
    hero:SetPos(Scale(42), Scale(70))
    hero:SetPaintBackground(false)
    hero.Paint = function(self, w, h)
        local selected = Selected()
        if not selected then return end
        Box(18, 0, 0, w, h, Color(4, 9, 16, 225))
        Outline(18, 0, 0, w, h, C(CaseAccent(selected), 70), 1)
        DrawCaseArt(selected, Scale(55), Scale(30), Scale(510), Scale(285))
        Text(selected.title, "HGCases.Title", Scale(630), Scale(75), palette.text)
        TextWrapFit(selected.description, {"HGCases.Medium", "HGCases.Small", "HGCases.Tiny"}, Scale(630), Scale(122), math.max(Scale(210), w - Scale(1010)), Scale(80), palette.muted)
        Text("ШАНСЫ ВЫПАДЕНИЯ:", "HGCases.Tiny", Scale(630), Scale(206), palette.text)
        local keys = {"common", "uncommon", "rare", "epic", "legendary"}
        for i, key in ipairs(keys) do
            local r = Rarity(key)
            local col = RarityColor(key)
            local x = Scale(630) + (i - 1) * Scale(99)
            Text(r.name, "HGCases.Tiny", x, Scale(230), col)
            Text(r.chance .. "%", "HGCases.Heading", x, Scale(252), col)
        end
        local bx, by, bw, bh = w - Scale(330), Scale(24), Scale(285), Scale(252)
        Box(14, bx, by, bw, bh, Color(6, 12, 20, 230))
        Outline(14, bx, by, bw, bh, C(CaseAccent(selected), 72), 1)
        Text("СТОИМОСТЬ", "HGCases.Tiny", bx + Scale(24), by + Scale(34), palette.text)
        local isRub = selected.currency == "rub"
        Text(string.Comma(selected.price * state.amount) .. (isRub and " ₽" or " OT-COIN"), "HGCases.Price", bx + Scale(24), by + Scale(98), isRub and Color(255, 190, 75) or palette.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local quantities = {1, 2, 3}
    for i, n in ipairs(quantities) do
        local button = vgui.Create("DButton", hero)
        button:SetText("")
        button:SetSize(Scale(76), Scale(42))
        button:SetPos(hero:GetWide() - Scale(330) + (i - 1) * Scale(80) + Scale(18), Scale(38))
        button.Paint = function(self, w, h)
            local selected = Selected()
            local ac = selected and CaseAccent(selected) or palette.accent
            local active = state.amount == n
            Box(8, 0, 0, w, h, active and Color(ac.r * .55, ac.g * .55, ac.b * .55) or Color(6, 12, 20, 255))
            Outline(7, 0, 0, w, h, active and C(Color(ac.r, ac.g, ac.b), 255) or Color(255, 255, 255, 20), 1)
            Text("x" .. n, "HGCases.Medium", w / 2, h / 2, active and Color(3, 10, 18) or palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        button.DoClick = function()
            if state.opening then return end
            state.amount = n
            surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
        end
    end
    local heroOpen = ToggleButton(hero, "ОТКРЫТЬ КЕЙС", function()
        if state.opening then return end
        local selected = Selected()
        if not selected then return end
        state.opening = false
        f:Remove()
        BuildOpening(selected)
    end)
    heroOpen:SetSize(Scale(240), Scale(55))
    heroOpen:SetPos(hero:GetWide() - Scale(308), Scale(191))
    local label = vgui.Create("DPanel", f)
    label:SetSize(Scale(250), Scale(38))
    label:SetPos(f:GetWide() / 2 - label:GetWide() / 2, Scale(375))
    label:SetPaintBackground(false)
    label.Paint = function(self, w, h)
        local caption = "ВЫБЕРИ КЕЙС"
        surface.SetFont("HGCases.Heading")
        local tw = surface.GetTextSize(caption)
        Text(caption, "HGCases.Heading", w / 2, h / 2, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Slant(w / 2 - tw / 2 - Scale(58), h / 2 - Scale(2), Scale(42), math.max(2, Scale(3)), C(palette.accent, 180), Scale(6))
        Slant(w / 2 + tw / 2 + Scale(16), h / 2 - Scale(2), Scale(42), math.max(2, Scale(3)), C(palette.accent, 180), Scale(6))
    end
    local cards = vgui.Create("DPanel", f)
    cards:SetSize(f:GetWide() - Scale(60), Scale(180))
    cards:SetPos(Scale(30), Scale(415))
    cards:SetPaintBackground(false)
    local ordered = {}
    do
        local money, other = {}, {}
        for _, c in ipairs(state.data.cases) do
            if c.currency == "rub" then money[#money + 1] = c else other[#other + 1] = c end
        end
        local leftN = math.floor(#other / 2)
        for i = 1, leftN do ordered[#ordered + 1] = other[i] end
        for _, c in ipairs(money) do ordered[#ordered + 1] = c end
        for i = leftN + 1, #other do ordered[#ordered + 1] = other[i] end
    end
    local count = #ordered
    for i, case in ipairs(ordered) do
        local isMoney = case.currency == "rub"
        local card = vgui.Create("DButton", cards)
        card:SetText("")
        card:SetSize(math.floor((cards:GetWide() - Scale(12) * (count - 1)) / count), cards:GetTall())
        card:SetPos((i - 1) * (card:GetWide() + Scale(12)), 0)
        card.Hover = 0
        card.Paint = function(self, w, h)
            self.Hover = Lerp(FrameTime() * 10, self.Hover, (self:IsHovered() or state.selected == case.id) and 1 or 0)
            local col = CaseAccent(case)
            if isMoney then
                local pulse = 0.5 + 0.5 * math.abs(math.sin(RealTime() * 2.2))
                Box(10, 0, 0, w, h, LerpColor(self.Hover, Color(14, 12, 8, 235), Color(24, 20, 12, 245)))
                Outline(10, 0, 0, w, h, C(col, 120 + pulse * 90), state.selected == case.id and 3 or 2)
            else
                Box(10, 0, 0, w, h, LerpColor(self.Hover, Color(6, 12, 20, 235), Color(12, 22, 36, 245)))
                Outline(10, 0, 0, w, h, C(col, 60 + self.Hover * 175), state.selected == case.id and 3 or 2)
            end
            DrawCaseArt(case, Scale(10), Scale(10), w - Scale(20), Scale(135))
            Text("КЕЙС " .. case.name, "HGCases.Small", w / 2, Scale(163), palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            Text(string.Comma(case.price) .. (isMoney and " ₽" or " OT-COIN"), "HGCases.Heading", w / 2, Scale(195), isMoney and Color(255, 205, 70) or col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        card.DoClick = function()
            if state.opening then return end
            if state.selected == case.id then return end
            state.selected = case.id
            state.amount = 1
            surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
            if RebuildRewards then RebuildRewards() end
        end
    end
    local rewardsTitle = vgui.Create("DPanel", f)
    rewardsTitle:SetSize(Scale(310), Scale(38))
    rewardsTitle:SetPos(f:GetWide() / 2 - rewardsTitle:GetWide() / 2, Scale(610))
    rewardsTitle:SetPaintBackground(false)
    rewardsTitle.Paint = function(self, w, h)
        local caption = "ВОЗМОЖНЫЕ НАГРАДЫ"
        surface.SetFont("HGCases.Heading")
        local tw = surface.GetTextSize(caption)
        Text(caption, "HGCases.Heading", w / 2, h / 2, palette.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Slant(w / 2 - tw / 2 - Scale(58), h / 2 - Scale(2), Scale(42), math.max(2, Scale(3)), C(palette.accent, 180), Scale(6))
        Slant(w / 2 + tw / 2 + Scale(16), h / 2 - Scale(2), Scale(42), math.max(2, Scale(3)), C(palette.accent, 180), Scale(6))
    end
    local rewards = vgui.Create("DPanel", f)
    local rTop = Scale(645)
    rewards:SetPos(Scale(30), rTop)
    rewards:SetSize(f:GetWide() - Scale(60), math.max(Scale(150), f:GetTall() - rTop - Scale(24)))
    rewards:SetPaintBackground(false)
    RebuildRewards = function()
        rewards:Clear()
        local sel = Selected()
        if not sel then return end
        local list = sel.rewards or {}
        local n = #list
        if n == 0 then return end
        local W, H = rewards:GetWide(), rewards:GetTall()
        local gap = Scale(8)
        local bestCols, bestScore = 1, -1
        for cols = 1, n do
            local rows = math.ceil(n / cols)
            local cw = (W - gap * (cols - 1)) / cols
            local ch = (H - gap * (rows - 1)) / rows
            if cw > 4 and ch > 4 then
                local score = math.min(cw, ch)
                if score > bestScore then
                    bestScore = score
                    bestCols = cols
                end
            end
        end
        local cols = bestCols
        local rows = math.ceil(n / cols)
        local side = math.floor(math.min((W - gap * (cols - 1)) / cols, (H - gap * (rows - 1)) / rows))
        if side < 8 then side = 8 end
        local gridW = cols * side + gap * (cols - 1)
        local gridH = rows * side + gap * (rows - 1)
        local offX = math.max(0, math.floor((W - gridW) * 0.5))
        local offY = math.max(0, math.floor((H - gridH) * 0.5))
        for i = 1, n do
            local reward = list[i]
            local ci = (i - 1) % cols
            local ri = math.floor((i - 1) / cols)
            local card = vgui.Create("DPanel", rewards)
            card.Reward = reward
            card:SetSize(side, side)
            card:SetPos(offX + ci * (side + gap), offY + ri * (side + gap))
            card:SetPaintBackground(false)
            card.Paint = function(self, w, h)
                local rw = self.Reward
                local col = RarityColor(rw.rarity)
                local r = math.Clamp(math.floor(math.min(w, h) * 0.16), 2, 8)
                Box(r, 0, 0, w, h, Color(6, 12, 20, 250))
                Outline(r, 0, 0, w, h, C(col, 120), 1)
                local pad = math.Clamp(math.floor(w * 0.10), 2, 10)
                local ix, iy, iw = pad, pad, w - pad * 2
                DrawRewardIcon(rw, ix, iy, iw, iw, self)
            end
        end
    end
    RebuildRewards()
    state.frame = f
end

timer.Simple(0.1, function()
netstream.Hook("HG.Cases.Sync", function(data)
    state.data = data
    if not state.selected and data.cases[1] then state.selected = data.cases[1].id end
    if state.opening then return end
    if not state.wantOpen then return end
    if not IsValid(state.frame) then UI.Main() end
end)

netstream.Hook("HG.Cases.Result", function(data)
    if state.data then state.data.otCoins = data.otCoins; state.data.rub = data.rub end
    local await = state.awaitOpen
    if await and IsValid(await.frame) and data.rewards and data.rewards[1] then
        await.begin(data)
    else
        state.opening = false
        state.awaitOpen = nil
        if IsValid(state.frame) then state.frame:Remove() end
        if data.rewards and data.rewards[1] then OpenResult(data) end
    end
end)

netstream.Hook("HG.Cases.Error", function(text)
    state.opening = false
    notification.AddLegacy(tostring(text), NOTIFY_ERROR, 4)
    surface.PlaySound("buttons/button10.wav")
end)

netstream.Hook("HG.Cases.Chat", function(data)
    local entries = istable(data) and data.entries or nil
    if not istable(entries) then return end
    local shown = false
    for _, line in ipairs(entries) do
        line = tostring(line or "")
        if line ~= "" then
            chat.AddText(Color(255, 205, 40), "[\208\154\208\181\208\185\209\129\209\139] ", Color(235, 235, 235), line)
            shown = true
        end
    end
    if shown then surface.PlaySound("nyx_uniqueui/nyxclick_3.wav") end
end)

netstream.Hook("HG.Cases.Notice", function(text)
    text = tostring(text or "")
    if text == "" then return end
    notification.AddLegacy(text, NOTIFY_HINT, 6)
    surface.PlaySound("nyx_uniqueui/nyxclick_3.wav")
end)

end)
concommand.Add("hg_cases", function()
    state.wantOpen = true
    netstream.Start("HG.Cases.Request")
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "cases menu loaded\n")
