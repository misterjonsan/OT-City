if not CRUCIFIX_GUILT then include("autorun/sh_crucifix_guilt.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Суд креста"
ENT.Category = "OT-CITY"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "StartTime")
	self:NetworkVar("Float", 1, "EndTime")
	self:NetworkVar("Bool", 0, "Failed")
	self:NetworkVar("Entity", 0, "Victim")
end

function ENT:GetProgress()
	local start = self:GetStartTime()
	local finish = self:GetEndTime()
	if finish <= start then return 1 end
	return math.Clamp((CurTime() - start) / (finish - start), 0, 1)
end
