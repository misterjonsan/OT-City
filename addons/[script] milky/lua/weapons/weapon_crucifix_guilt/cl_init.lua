include("shared.lua")

local C = CRUCIFIX_GUILT

surface.CreateFont("CrucifixGuiltMedium", {
	font = "Montserrat Medium",
	extended = true,
	size = 19,
	weight = 500,
	antialias = true
})

surface.CreateFont("CrucifixGuiltSemiBold", {
	font = "Montserrat SemiBold",
	extended = true,
	size = 21,
	weight = 600,
	antialias = true
})

surface.CreateFont("CrucifixGuiltSelection", {
	font = "Montserrat SemiBold",
	extended = true,
	size = 34,
	weight = 600,
	antialias = true
})

local function LoadMaterial(path, fallback, params)
	local mat = Material(path, params)
	if not mat or mat:IsError() then mat = Material(fallback, params) end
	return mat
end

local matMoon = LoadMaterial("models/doors/chains/Cruc_iris.png", "effects/select_ring")
local matStar = LoadMaterial("models/doors/chains/Cruc_inner.png", "effects/select_ring")
local matCircles = LoadMaterial("models/doors/chains/Cruc_outter.png", "effects/select_ring")
local matSymbols = LoadMaterial("models/doors/chains/Cruc_middle.png", "effects/select_ring")
local matChain = LoadMaterial("models/doors/chains/chain1.png", "cable/cable2", "noclamp")
local matChainGlow = LoadMaterial("trails/laser", "sprites/light_glow02_add", "noclamp")
local matGradient = LoadMaterial("vgui/gradient-u", "color", "noclamp smooth")
local matGlow = LoadMaterial("sprites/light_glow02_add", "sprites/glow04_noz")

C.Active = C.Active or {}
C.RitualModel = C.RitualModel or nil

local function Fade(value, amount)
	return math.max(value - amount, 0)
end

local function CirclePos(origin, rot, radius)
	local rad = math.rad(rot)
	return Vector(origin.x + math.cos(rad) * radius, origin.y + math.sin(rad) * radius, origin.z)
end

local function TraceFloor(pos)
	local trace = util.TraceLine({
		start = pos + Vector(0, 0, 24),
		endpos = pos - Vector(0, 0, 96),
		mask = MASK_SOLID_BRUSHONLY
	})
	if trace.Hit then return trace.HitPos, trace.HitNormal end
	return pos, vector_up
end

net.Receive("CrucifixGuiltRitual", function()
	local victim = net.ReadEntity()
	local duration = net.ReadFloat()
	local failed = net.ReadBool()
	if not IsValid(victim) then return end

	local existing = C.Active[victim]
	if failed then
		if existing then
			existing.failed = true
			existing.fadeStart = CurTime()
			existing.endTime = CurTime() + 2.5
		end
		return
	end

	local ground, normal = TraceFloor(victim:GetPos())

	C.Active[victim] = {
		startTime = CurTime(),
		duration = duration,
		fadeStart = CurTime() + duration,
		endTime = CurTime() + duration + 3.5,
		anchor = victim:GetPos(),
		ground = ground,
		normal = normal,
		spinRaw = 0,
		chainPush = 0,
		alphaMoon = 255,
		alphaStar = 255,
		alphaCircles = 255,
		alphaSymbols = 255,
		failed = false
	}
end)

local function GetRitualModel()
	if IsValid(C.RitualModel) then return C.RitualModel end
	C.RitualModel = ClientsideModel(C.Model, RENDERGROUP_BOTH)
	if IsValid(C.RitualModel) then
		C.RitualModel:SetNoDraw(true)
		C.RitualModel:DrawShadow(false)
	end
	return C.RitualModel
end

local function FadeLayers(data)
	local since = CurTime() - data.fadeStart
	if since < 0 then return end

	local frame = RealFrameTime()
	data.alphaCircles = Fade(data.alphaCircles, 1.5 * frame * 160)
	if since > 0.5 then data.alphaSymbols = Fade(data.alphaSymbols, 2.5 * frame * 135) end
	if since > 1 then data.alphaStar = Fade(data.alphaStar, 3.8 * frame * 65) end
	if since > 1.5 then data.alphaMoon = Fade(data.alphaMoon, 0.85 * frame * 145) end
end

local function DrawFloorLayers(data, progress)
	local origin = data.ground + data.normal * 2
	local size = C.CircleSize
	local circles = data.spinRaw % 360
	local symbols = -circles
	local star = (data.spinRaw / 25) % 360

	render.SetMaterial(matMoon)
	render.DrawQuadEasy(origin, data.normal, size, size, Color(C.ColorRing.r, C.ColorRing.g, C.ColorRing.b, data.alphaMoon), 0)

	render.SetMaterial(matStar)
	render.DrawQuadEasy(origin + data.normal * 0.5, data.normal, size, size, Color(C.ColorDeep.r, C.ColorDeep.g, C.ColorDeep.b, data.alphaStar), star)

	render.SetMaterial(matCircles)
	render.DrawQuadEasy(origin + data.normal * 1, data.normal, size, size, Color(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b, data.alphaCircles), circles)

	render.SetMaterial(matSymbols)
	render.DrawQuadEasy(origin + data.normal * 1.5, data.normal, size, size, Color(C.ColorGlow.r, C.ColorGlow.g, C.ColorGlow.b, data.alphaSymbols), symbols)
end

local function DrawCylinder(data)
	local alpha = data.alphaCircles
	if alpha <= 0 then return end

	local origin = data.ground + data.normal * 1
	local height = Vector(0, 0, C.CylinderHeight)
	local step = 360 / C.CylinderSides
	local top = Color(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b, 0)
	local bottom = Color(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b, alpha)

	render.SetMaterial(matGradient)

	for pass = 1, 2 do
		render.CullMode(pass == 1 and MATERIAL_CULLMODE_CW or MATERIAL_CULLMODE_CCW)
		for i = 0, C.CylinderSides - 1 do
			local first = CirclePos(origin, i * step, C.CylinderRadius)
			local second = CirclePos(origin, (i + 1) * step, C.CylinderRadius)
			render.DrawQuad(first + height, second + height, second, first, pass == 1 and bottom or top)
		end
	end

	render.CullMode(MATERIAL_CULLMODE_CCW)
end

local function DrawChain(data, rot, middle)
	if data.alphaCircles <= 0 then return end

	local pos = CirclePos(data.ground, rot, C.CircleRadius)
	pos = TraceFloor(pos)

	local dist = pos:Distance(middle)
	if dist < 4 then return end

	local segments = math.Clamp(math.floor(dist / 25), 3, C.ChainSegments)
	local inc = dist / segments
	local normal = middle - pos
	normal:Normalize()

	render.SetMaterial(matChainGlow)
	render.StartBeam(segments + 1)
	for i = 0, segments do
		local alpha = math.Clamp(120 - ((i / segments) * 40), 0, data.alphaCircles * 0.55)
		render.AddBeam(pos + normal * (inc * i), C.ChainGlowWidth, (i / segments) + data.chainPush, Color(255, 70, 90, alpha))
	end
	render.EndBeam()

	render.SetMaterial(matChain)
	render.StartBeam(segments + 1)
	for i = 0, segments do
		local near = C.ChainAlphaNear
		local far = C.ChainAlphaFar
		local alpha = math.Clamp(near - ((i / segments) * (near - far)), 0, data.alphaCircles)
		render.AddBeam(pos + normal * (inc * i), C.ChainWidth, data.chainPush + i, Color(255, 210, 215, alpha))
	end
	render.EndBeam()
end

local function DrawChains(data, victim, progress)
	local middle = data.ground + Vector(0, 0, 45 + C.LiftHeight * math.sin(progress * math.pi * 0.5))
	if IsValid(victim) then
		local mins, maxs = victim:GetCollisionBounds()
		middle = victim:GetPos() + Vector(0, 0, (mins.z + maxs.z) * 0.5)
		middle.x = data.ground.x
		middle.y = data.ground.y
		if middle.z <= data.ground.z then middle = middle + Vector(0, 0, 45) end
	end

	local chainRot = data.spinRaw / 100
	local step = 360 / math.max(C.ChainCount, 1)

	for index = 0, C.ChainCount - 1 do
		DrawChain(data, chainRot + index * step, middle)
	end
end

local function DrawCrucifix(data, victim, progress)
	local model = GetRitualModel()
	if not IsValid(model) then return end

	local origin = (IsValid(victim) and victim:GetPos() or data.anchor) + Vector(0, 0, 46 + C.LiftHeight * math.sin(progress * math.pi * 0.5))
	local alpha = math.Clamp(data.alphaMoon / 255, 0, 1)

	local matrix = Matrix()
	matrix:Translate(origin)
	matrix:Rotate(Angle(0, data.spinRaw % 360, data.failed and 180 or 0))
	matrix:Scale(Vector(0.9, 0.9, 0.9))

	render.SetColorModulation(1, 0.22 + 0.18 * progress, 0.3)
	render.SetBlend(alpha)
	cam.PushModelMatrix(matrix)
	model:DrawModel()
	cam.PopModelMatrix()
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)

	render.SetMaterial(matGlow)
	local glow = 70 + math.sin(CurTime() * 4) * 10 + progress * 110
	render.DrawSprite(origin, glow, glow, Color(C.ColorGlow.r, C.ColorGlow.g, C.ColorGlow.b, data.alphaMoon * 0.7))
end

local function DrawLight(data, victim, progress)
	local average = (data.alphaMoon + data.alphaStar + data.alphaCircles + data.alphaSymbols) / 4
	if average <= 0 then return end

	local index = IsValid(victim) and victim:EntIndex() or 9000
	local light = DynamicLight(index + 8000)
	if not light then return end

	light.Pos = data.ground + Vector(0, 0, 40)
	light.r = C.ColorDeep.r
	light.g = C.ColorDeep.g
	light.b = C.ColorDeep.b
	light.Brightness = (2 + progress * 2.5) * (average / 255)
	light.Size = 240 + progress * 160
	light.Decay = 0
	light.Style = 0
	light.DieTime = CurTime() + 0.6
end

local function DrawRitual(victim, data)
	local progress = math.Clamp((CurTime() - data.startTime) / math.max(data.duration, 0.1), 0, 1)

	local spin = C.SpinBase + (C.SpinPeak - C.SpinBase) * (progress ^ C.SpinCurve)
	data.spinRaw = data.spinRaw + spin * FrameTime() * 0.35
	data.chainPush = data.chainPush >= 1 and 0 or data.chainPush + FrameTime() / 5

	FadeLayers(data)

	render.SuppressEngineLighting(true)
	DrawFloorLayers(data, progress)
	DrawCylinder(data)
	DrawChains(data, victim, progress)
	DrawCrucifix(data, victim, progress)
	render.SuppressEngineLighting(false)

	DrawLight(data, victim, progress)
end

hook.Add("PostDrawTranslucentRenderables", "CrucifixGuiltRitualRender", function(depth, sky)
	if depth or sky then return end

	for victim, data in pairs(C.Active) do
		if data.endTime <= CurTime() or data.alphaMoon <= 0 and data.alphaCircles <= 0 and CurTime() > data.fadeStart + 2 then
			C.Active[victim] = nil
		else
			DrawRitual(victim, data)
		end
	end
end)

function SWEP:BuildModel()
	if IsValid(self.HandModel) then self.HandModel:Remove() end

	self.HandModel = ClientsideModel(C.Model, RENDERGROUP_BOTH)
	if not IsValid(self.HandModel) then return end

	self.HandModel:SetNoDraw(true)
	self.HandModel:SetModelScale(self.HandScale, 0)
end

function SWEP:OnRemove()
	if IsValid(self.HandModel) then self.HandModel:Remove() end
end

function SWEP:DrawHeldModel()
	if not IsValid(self.HandModel) then self:BuildModel() end
	if not IsValid(self.HandModel) then return end

	local matrix = self:GetHandMatrix()
	if not matrix then return end

	local pos, ang = LocalToWorld(self.HandOffsetPos, self.HandOffsetAngle, matrix:GetTranslation(), matrix:GetAngles())

	self.HandModel:SetPos(pos)
	self.HandModel:SetAngles(ang)
	self.HandModel:SetupBones()
	self.HandModel:DrawModel()
end

function SWEP:ViewModelDrawn(viewmodel)
	self:DrawHeldModel()
end

function SWEP:DrawWorldModel()
	if IsValid(self:GetOwner()) then
		self:DrawHeldModel()
		return
	end

	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	draw.SimpleText("†", "CrucifixGuiltSelection", x + wide * 0.5, y + tall * 0.35, Color(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(self.PrintName, "CrucifixGuiltMedium", x + wide * 0.5, y + tall * 0.78, Color(235, 215, 220, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function SWEP:DrawHUD()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local ready = self:GetNextRitual() <= CurTime() and self:GetUsesLeft() > 0
	local size = ready and 26 or 18
	local alpha = ready and 220 or 90
	local x, y = ScrW() * 0.5, ScrH() * 0.5

	surface.SetDrawColor(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b, alpha)
	surface.SetMaterial(matCircles)
	surface.DrawTexturedRectRotated(x, y, size * 2, size * 2, CurTime() * 25 % 360)

	surface.DrawLine(x, y - size * 0.6, x, y + size * 0.6)
	surface.DrawLine(x - size * 0.45, y - size * 0.15, x + size * 0.45, y - size * 0.15)

	local wait = math.max(self:GetNextRitual() - CurTime(), 0)
	local status = self:GetUsesLeft() <= 0 and "крест исчерпан" or (wait > 0 and ("откат " .. math.ceil(wait) .. " сек") or "готов к суду")

	draw.SimpleTextOutlined(status, "CrucifixGuiltSemiBold", x, y + size + 20, Color(232, 208, 214, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(18, 0, 4, 225))
	draw.SimpleText("судов: " .. self:GetUsesLeft() .. "  •  совесть: " .. math.Round(C.GetGuilt(owner)), "CrucifixGuiltMedium", x, y + size + 42, Color(196, 168, 176, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
