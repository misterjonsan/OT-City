util.AddNetworkString("addpredictable")

function SWEP:CreateWorldModel()
	local model = ents.Create("prop_physics")
	if not IsValid(model) then return nil end

	model:SetNoDraw(not hg.show_weapons)
	model:SetModel(self.WorldModel or "")
	model:SetMaterial("models/wireframe")
	model:Spawn()

	timer.Simple(0, function()
		if IsValid(model) then
			model:PhysicsDestroy()
		end
	end)

	model:SetMoveType(MOVETYPE_NONE)
	model:SetNWBool("nophys", true)
	model:SetSolidFlags(FSOLID_NOT_SOLID)
	model:AddEFlags(EFL_NO_DISSOLVE)

	self:DeleteOnRemove(model)
	self.worldModel = model
	self:SetLagCompensated(true)
	model.weapon = self

	return model
end

local math_max = math.max
local vecZero = Vector(0, 0, 0)
local angZero = Angle(0, 0, 0)
local hook_Run = hook.Run

function SWEP:WorldModel_Transform(bNoApply, bNoAdditional)
	local model = self.worldModel
	local owner = self:GetOwner()

	if not IsValid(model) then
		model = self:CreateWorldModel()
		if not IsValid(model) then return end
	end

	if not IsValid(owner) then
		model:SetPos(self:GetPos())
		model:SetAngles(self:GetAngles())
		return
	end

	if owner:IsNPC() then
		return false
	end

	local activeWeapon = owner:GetActiveWeapon()
	if IsValid(activeWeapon) and self == activeWeapon then
		local ent = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
		if not IsValid(ent) then return end

		local ctime = SysTime()
		local dtime = ctime - (self.last_transform or ctime)
		self.last_transform = ctime

		local RHand = ent:LookupBone("ValveBiped.Bip01_R_Hand")
		if not RHand then return end

		local matrixR = ent:GetBoneMatrix(RHand)
		if not matrixR then return end

		local aimvec = ent:IsNPC() and matrixR:GetAngles() or owner:GetAimVector():Angle()
		local matrixRAngRot = matrixR:GetAngles()
		matrixRAngRot:RotateAroundAxis(matrixRAngRot:Forward(), 180)

		local lerp = self:KeyDown(IN_ATTACK2) and 1 or 1
		local _, ang = WorldToLocal(vecZero, matrixRAngRot, vecZero, aimvec)
		ang = ang * lerp
		local _, ang2 = LocalToWorld(vecZero, ang, vecZero, aimvec)
		ang2[3] = matrixRAngRot[3]

		local desiredAng = (ent ~= owner) and ang2 or aimvec
		desiredAng[3] = desiredAng[3] + owner:EyeAngles()[3]
		desiredAng:RotateAroundAxis(desiredAng:Forward(), ent:IsNPC() and 0 or 180)

		local desiredPos = matrixR:GetTranslation()

		if not owner:IsNPC() and self.PosAngChanges then
			local desiredPos1, desiredAng1 = self:PosAngChanges(owner, desiredPos, desiredAng, bNoAdditional, nil, dtime)
			if desiredPos1 then
				desiredPos = LerpVector(self.lerped_positioning or 0, desiredPos, desiredPos1)
			end
			if desiredAng1 then
				desiredAng = LerpAngle(self.lerped_angle or 0, desiredAng, desiredAng1)
			end
		end

		local worldPos = self.WorldPos or vecZero
		local worldAng = self.WorldAng or angZero
		local newPos, newAng = LocalToWorld(worldPos, worldAng, desiredPos, desiredAng)
		newAng:RotateAroundAxis(newAng:Forward(), 180)

		self.desiredPos = newPos
		self.desiredAng = newAng

		if bNoApply then
			return newPos, newAng, desiredPos, desiredAng
		end

		self.handPos = desiredPos
		self.handAng = desiredAng

		if IsValid(model) then
			model:SetPos(newPos)
			model:SetAngles(newAng)
		end

		return newPos, newAng
	else
		if IsValid(model) then
			model:SetPos(self:GetPos())
			model:SetAngles(self:GetAngles())
		end
	end
end

local weaponsList = hg.weapons

concommand.Add("hg_show_weapons", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	hg.show_weapons = tonumber(args[1]) > 0

	for i, wep in ipairs(weaponsList) do
		if not IsValid(wep) then continue end
		if not IsValid(wep.worldModel) then continue end
		wep.worldModel:SetNoDraw(not hg.show_weapons)
	end
end)