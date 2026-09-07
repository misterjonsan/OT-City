AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local C = CRUCIFIX_GUILT

function ENT:Initialize()
	self:SetModel(C.Model)
	self:SetModelScale(0.85, 0)
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetTrigger(false)
	self:DrawShadow(false)
	self:SetFailed(false)
	self.Finished = false
end

function ENT:Begin(punisher, victim, reward, guilt)
	self.Punisher = punisher
	self.Reward = reward
	self.Guilt = guilt
	self.Anchor = victim:GetPos()

	self:SetVictim(victim)
	self:SetStartTime(CurTime())
	self:SetEndTime(CurTime() + C.RitualTime)
	self:SetPos(self.Anchor)

	victim.CrucifixGuiltRitual = self
	punisher.CrucifixGuiltRitual = self

	victim:SetMoveType(MOVETYPE_NONE)
	victim:Freeze(true)
	victim:SetVelocity(vector_origin)

	self:EmitSound(C.SoundRitual, 95, 100, 0.85, CHAN_STATIC)
	self:NextThink(CurTime())
end

function ENT:Release(victim)
	if not IsValid(victim) then return end
	victim.CrucifixGuiltRitual = nil
	victim:Freeze(false)
	if victim:Alive() then
		victim:SetMoveType(MOVETYPE_WALK)
	end
end

function ENT:Cancel(silent)
	if self.Finished then return end
	self.Finished = true

	self:Release(self:GetVictim())

	if IsValid(self.Punisher) then
		self.Punisher.CrucifixGuiltRitual = nil
		if not silent then C.Notify(self.Punisher, "Суд прерван, крест отпустил душу.") end
	end

	self:SetFailed(true)
	self:StopSound(C.SoundRitual)
	self:EmitSound(C.SoundFail, 90, 100, 0.8, CHAN_STATIC)

	SafeRemoveEntityDelayed(self, 1.5)
end

function ENT:Judge()
	if self.Finished then return end
	self.Finished = true

	local victim = self:GetVictim()
	local punisher = self.Punisher

	if IsValid(punisher) then punisher.CrucifixGuiltRitual = nil end

	if IsValid(victim) then
		victim.CrucifixGuiltRitual = nil
		victim.CrucifixGuiltJudged = true
		victim:Freeze(false)

		local info = DamageInfo()
		info:SetDamage(math.max(victim:Health(), 1) + 500)
		info:SetDamageType(DMG_DISSOLVE)
		info:SetAttacker(self)
		info:SetInflictor(self)
		info:SetDamagePosition(victim:WorldSpaceCenter())
		victim:TakeDamageInfo(info)

		if victim:Alive() then
			victim:Kill()
		end

		victim:SetMoveType(MOVETYPE_WALK)

		if IsValid(punisher) then
			C.Punish(punisher, victim, self.Reward, self.Guilt)
		end
	end

	self:StopSound(C.SoundRitual)
	self:EmitSound(C.SoundJudge, 95, 100, 0.75, CHAN_STATIC)

	SafeRemoveEntityDelayed(self, 2.5)
end

function ENT:Think()
	if self.Finished then
		self:NextThink(CurTime() + 0.5)
		return true
	end

	local victim = self:GetVictim()

	if not IsValid(victim) or not victim:Alive() then
		self:Cancel(true)
		return true
	end

	local progress = self:GetProgress()
	victim:SetPos(self.Anchor + Vector(0, 0, C.LiftHeight * math.sin(progress * math.pi * 0.5)))
	victim:SetEyeAngles(Angle(math.Clamp(-30 * progress, -30, 0), victim:EyeAngles().y, 0))
	victim:SetVelocity(vector_origin)

	if progress >= 1 then
		self:Judge()
		return true
	end

	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:OnRemove()
	local victim = self:GetVictim()
	if IsValid(victim) and victim.CrucifixGuiltRitual == self then
		self:Release(victim)
	end
	if IsValid(self.Punisher) and self.Punisher.CrucifixGuiltRitual == self then
		self.Punisher.CrucifixGuiltRitual = nil
	end
	self:StopSound(C.SoundRitual)
end
