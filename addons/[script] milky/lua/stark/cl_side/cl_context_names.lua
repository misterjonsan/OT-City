if SERVER then
AddCSLuaFile()
return
end

local RK = RK or {}
RK.ContextNames = RK.ContextNames or {}
local CN = RK.ContextNames

CN.Show = false
CN.Alpha = 0
CN.Cards = CN.Cards or {}

local voice_mat = Material("icon16/sound.png", "smooth")

local RK_RADIUS = 18
local RK_ACCENT = Color(210, 25, 45)
local RK_ACCENT_DARK = Color(85, 0, 18)
local RK_PANEL = Color(18, 6, 9)
local RK_TEXT = Color(255, 245, 245)
local RK_OUTLINE = Color(255, 55, 75, 170)

local function FT()
return FrameTime()
end

local function LerpAnim(speed, from, to)
return Lerp(math.Clamp(FT() * speed, 0, 1), from, to)
end

local function DrawRKBlock(x, y, w, h, col, radius)
radius = math.min(radius or RK_RADIUS, math.floor(math.min(w, h) / 2))

if RNDX and RNDX.Draw then
RNDX.Draw(radius, x, y, w, h, col)
elseif rndx and rndx.Draw then
rndx.Draw(radius, x, y, w, h, col)
else
draw.RoundedBox(radius, x, y, w, h, col)
end
end

local function DrawRKOutline(x, y, w, h, col, radius, thickness)
radius = math.min(radius or RK_RADIUS, math.floor(math.min(w, h) / 2))
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

local function DrawRKGrid(x, y, w, h, radius, col, alpha)
radius = math.min(radius or RK_RADIUS, math.floor(math.min(w, h) / 2))
alpha = math.floor(alpha or 0)

if alpha <= 0 then return end

local step = 10
local off = (CurTime() * 9) % step

render.ClearStencil()
render.SetStencilEnable(true)
render.SetStencilWriteMask(255)
render.SetStencilTestMask(255)
render.SetStencilReferenceValue(1)
render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
render.SetStencilFailOperation(STENCILOPERATION_KEEP)
render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

render.OverrideColorWriteEnable(true, false)
render.OverrideAlphaWriteEnable(true, false)
DrawRKBlock(x, y, w, h, Color(255, 255, 255, 255), radius)
render.OverrideColorWriteEnable(false)
render.OverrideAlphaWriteEnable(false)

render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
render.SetStencilPassOperation(STENCILOPERATION_KEEP)
render.SetStencilFailOperation(STENCILOPERATION_KEEP)
render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

surface.SetDrawColor(col.r, col.g, col.b, alpha)

for gx = x - off - step, x + w + step, step do
surface.DrawLine(gx, y - step, gx, y + h + step)
end

for gy = y - off - step, y + h + step, step do
surface.DrawLine(x - step, gy, x + w + step, gy)
end

render.SetStencilEnable(false)
end

local function DrawRKText(text, font, x, y, col, ax, ay)
draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, math.min(col.a or 255, 190)), ax, ay)
draw.SimpleText(text, font, x, y, col, ax, ay)
end

local function GetSteamNick(ply)
if not IsValid(ply) then return "" end

if ply.SteamName then
local name = ply:SteamName()
if name and name ~= "" then
return name
end
end

return ply:Nick()
end

hook.Add("OnContextMenuOpen", "rk_context_players_names_open", function()
CN.Show = true
end)

hook.Add("OnContextMenuClose", "rk_context_players_names_close", function()
CN.Show = false
end)

hook.Add("HUDPaint", "rk_context_players_names_draw", function()
local lp = LocalPlayer()

if not IsValid(lp) then return end
if not lp:IsAdmin() then return end
if lp.GetUserGroup and lp:GetUserGroup() == "admin" then return end

CN.Alpha = LerpAnim(10, CN.Alpha, CN.Show and 1 or 0)

if CN.Alpha <= 0.01 then
CN.Cards = {}
return
end

local active = {}

for _, ply in ipairs(player.GetAll()) do
if not IsValid(ply) then continue end
if ply == lp then continue end
if not ply:Alive() then continue end

local dist = lp:GetPos():Distance(ply:GetPos())
if dist > 3000 then continue end

local pos = ply:EyePos() + Vector(0, 0, 12)
local scr = pos:ToScreen()

if not scr.visible then continue end

local id = ply:SteamID64() or tostring(ply:EntIndex())
active[id] = true

local name = GetSteamNick(ply)
local speaking = ply:IsSpeaking()

surface.SetFont("Trebuchet24")
local tw, th = surface.GetTextSize(name)

local dist_frac = math.Clamp(dist / 3000, 0, 1)
local dist_alpha = 1 - dist_frac
local target_alpha = CN.Alpha * dist_alpha
local pulse = speaking and (0.5 + math.sin(CurTime() * 10) * 0.5) or 0

local pad_x = 14
local pad_y = 7
local icon_size = speaking and 18 or 0
local gap = speaking and 8 or 0

local target_w = tw + pad_x * 2 + icon_size + gap
local target_h = math.max(th + pad_y * 2, 34)

local card = CN.Cards[id] or {
x = scr.x,
y = scr.y,
w = 4,
h = 4,
a = 0,
glow = 0,
icon = 0
}

card.x = LerpAnim(14, card.x, scr.x)
card.y = LerpAnim(14, card.y, scr.y)
card.w = LerpAnim(12, card.w, target_w)
card.h = LerpAnim(12, card.h, target_h)
card.a = LerpAnim(12, card.a, target_alpha)
card.glow = LerpAnim(10, card.glow, speaking and 1 or 0)
card.icon = LerpAnim(14, card.icon, speaking and 1 or 0)

CN.Cards[id] = card

local a = math.Clamp(card.a * 255, 0, 255)
if a <= 1 then continue end

local scale_pop = 1 + (1 - math.Clamp(card.a, 0, 1)) * 0.08
local box_w = card.w * scale_pop
local box_h = card.h * scale_pop
local x = card.x - box_w / 2
local y = card.y - box_h / 2
local radius = math.min(RK_RADIUS, math.floor(math.min(box_w, box_h) / 2))

DrawRKBlock(x, y, box_w, box_h, Color(RK_PANEL.r, RK_PANEL.g, RK_PANEL.b, a * 0.88), radius)
DrawRKBlock(x, y, box_w, box_h, Color(RK_ACCENT_DARK.r, RK_ACCENT_DARK.g, RK_ACCENT_DARK.b, a * 0.62), radius)
DrawRKBlock(x, y, box_w, box_h, Color(RK_ACCENT.r, RK_ACCENT.g, RK_ACCENT.b, a * (0.14 + pulse * 0.16)), radius)

DrawRKGrid(x, y, box_w, box_h, radius, RK_OUTLINE, a * (0.08 + card.glow * 0.08))

DrawRKOutline(x, y, box_w, box_h, Color(RK_ACCENT.r, RK_ACCENT.g, RK_ACCENT.b, a * (0.55 + card.glow * 0.35)), radius, 2)
DrawRKOutline(x - 2, y - 2, box_w + 4, box_h + 4, Color(RK_ACCENT.r, RK_ACCENT.g, RK_ACCENT.b, a * (0.12 + card.glow * 0.22)), radius + 2, 1)

local text_x = x + pad_x
local text_y = y + box_h / 2

DrawRKText(name, "Trebuchet24", text_x, text_y, Color(RK_TEXT.r, RK_TEXT.g, RK_TEXT.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

if card.icon > 0.01 then
local icon_a = a * card.icon
local icon_s = 18 * (0.85 + card.icon * 0.15 + pulse * 0.08)
local icon_x = x + pad_x + tw + gap
local icon_y = y + box_h / 2 - icon_s / 2

surface.SetMaterial(voice_mat)
surface.SetDrawColor(255, 255, 255, icon_a)
surface.DrawTexturedRect(icon_x, icon_y, icon_s, icon_s)
end
end

for id, card in pairs(CN.Cards) do
if not active[id] then
card.a = LerpAnim(12, card.a, 0)

if card.a <= 0.01 then
CN.Cards[id] = nil
end
end
end
end)