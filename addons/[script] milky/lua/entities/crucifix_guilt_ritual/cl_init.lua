include("shared.lua")

local C = CRUCIFIX_GUILT

local function LoadMaterial(path, fallback)
	local mat = Material(path)
	if not mat or mat:IsError() then mat = Material(fallback) end
	return mat
end

local matOuter = LoadMaterial("models/doors/chains/Cruc_outter.png", "effects/select_ring")
local matMiddle = LoadMaterial("models/doors/chains/Cruc_middle.png", "effects/select_ring")
local matInner = LoadMaterial("models/doors/chains/Cruc_inner.png", "effects/select_ring")
local matGlow = LoadMaterial("sprites/light_glow02_add", "sprites/glow04_noz")

local function Shade(base, alpha, pulse)
	return Color(
		math.Clamp(base.r + pulse * 40, 0, 255),
		math.Clamp(base.g + pulse * 8, 0, 255),
		math.Clamp(base.b + pulse * 14, 0, 255),
		math.Clamp(alpha, 0, 255)
	)
end

function ENT:Initialize()
	self.Spin = 0
	self.LastFrame = -1
	self.Ground = self:GetPos()
	self.Normal = vector_up
	self.NextTrace = 0
	self:SetRenderBounds(Vector(-160, -160, -32), Vector(160, 160, 220))
	self:DrawShadow(false)
	self.Emitter = ParticleEmitter(self:GetPos(), false)
end

function ENT:OnRemove()
	if self.Emitter then self.Emitter:Finish() end
end

function ENT:UpdateGround()
	if CurTime() < (self.NextTrace or 0) then return end
	self.NextTrace = CurTime() + 0.5

	local trace = util.TraceLine({
		start = self:GetPos() + Vector(0, 0, 16),
		endpos = self:GetPos() - Vector(0, 0, 256),
		mask = MASK_SOLID_BRUSHONLY
	})

	self.Ground = (trace.Hit and trace.HitPos or self:GetPos()) + Vector(0, 0, 1.5)
	self.Normal = trace.Hit and trace.HitNormal or vector_up
end

function ENT:Think()
	local progress = self:GetProgress()
	self.Spin = (self.Spin or 0) + FrameTime() * (70 + progress * 330)
	self:UpdateGround()

	if self.Emitter and not self:GetFailed() and math.random() <= 0.5 then
		local origin = self:GetPos() + Vector(math.Rand(-22, 22), math.Rand(-22, 22), math.Rand(0, 10))
		local particle = self.Emitter:Add("particle/particle_glow_04", origin)
		if particle then
			particle:SetDieTime(math.Rand(0.7, 1.4))
			particle:SetStartAlpha(math.random(110, 190))
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(3, 7))
			particle:SetEndSize(0)
			particle:SetVelocity(Vector(0, 0, math.Rand(25, 65)))
			particle:SetGravity(Vector(0, 0, 10))
			particle:SetColor(C.ColorBright.r, C.ColorBright.g, C.ColorBright.b)
		end
	end

	self:SetNextClientThink(CurTime())
	return true
end

function ENT:Render()
	local frame = FrameNumber()
	if self.LastFrame == frame then return end
	self.LastFrame = frame

	local progress = self:GetProgress()
	local failed = self:GetFailed()
	local height = 42 + progress * 54
	local origin = self:GetPos()
	local pulse = math.abs(math.sin(CurTime() * 2.5)) * 0.5 + progress * 0.5
	local alpha = 255 - progress * 45
	local scale = 96 + progress * 44
	local ground = self.Ground or origin
	local normal = self.Normal or vector_up

	render.SuppressEngineLighting(true)

	local matrix = Matrix()
	matrix:Translate(origin + Vector(0, 0, height))
	matrix:Rotate(Angle(0, self.Spin or 0, failed and 180 or 0))
	matrix:Scale(Vector(0.85, 0.85, 0.85))

	render.SetColorModulation(C.ColorBright.r / 255, C.ColorBright.g / 255, C.ColorBright.b / 255)
	render.SetBlend(failed and 0.4 or 1)
	cam.PushModelMatrix(matrix)
	self:DrawModel()
	cam.PopModelMatrix()
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)
	render.SuppressEngineLighting(false)

	render.SetMaterial(matOuter)
	render.DrawQuadEasy(ground, normal, scale, scale, Shade(C.ColorRing, alpha, pulse), -self.Spin * 0.35)

	render.SetMaterial(matMiddle)
	render.DrawQuadEasy(ground + normal * 0.5, normal, scale * 0.74, scale * 0.74, Shade(C.ColorDeep, alpha, pulse), self.Spin * 0.6)

	render.SetMaterial(matInner)
	render.DrawQuadEasy(ground + normal * 1, normal, scale * 0.46, scale * 0.46, Shade(C.ColorBright, alpha, pulse), -self.Spin)

	render.SetMaterial(matGlow)
	render.DrawSprite(origin + Vector(0, 0, height), 150 + progress * 90, 150 + progress * 90, Color(C.ColorGlow.r, C.ColorGlow.g, C.ColorGlow.b, failed and 70 or 200))

	local light = DynamicLight(self:EntIndex(), true)
	if light then
		light.Pos = origin + Vector(0, 0, 44)
		light.r = C.ColorBright.r
		light.g = C.ColorBright.g
		light.b = C.ColorBright.b
		light.Brightness = failed and 1 or 2.6
		light.Decay = 0
		light.Size = 360
		light.Style = 0
		light.DieTime = CurTime() + 0.6
	end
end

function ENT:Draw()
	self:Render()
end

function ENT:DrawTranslucent()
	self:Render()
end
