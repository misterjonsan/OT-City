local min, max, Round = math.min, math.max, math.Round

hg.organism.module.stamina = {}
local module = hg.organism.module.stamina

local function HasEquippedAccessory(ply, uid)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	uid = tostring(uid or "")
	if uid == "" then return false end

	local function CheckTable(t)
		if not istable(t) then return false end

		for _, accUID in pairs(t) do
			if tostring(accUID or "") == uid then
				return true
			end
		end

		return false
	end

	if CheckTable(ply:GetNetVar("Accessories", {})) then return true end

	if istable(ply.CurAppearance) and CheckTable(ply.CurAppearance.AAttachments) then return true end
	if istable(ply.CachedAppearance) and CheckTable(ply.CachedAppearance.AAttachments) then return true end

	return false
end

module[1] = function(org)
	org.adrenaline = 0
	org.adrenalineAdd = 0
	org.adrenalineStorage = 5

	org.stamina = {
		range = 60 * 3,
		regen = 1,
		sub = 0,
		subadd = 0,
		weight = 0,
		max = 60 * 3,
	}

	org.energy = 0
	org.hemotransfusionshock = 0

	org.stamina[1] = org.stamina.range

	local owner = org.owner
	org.moveMaxSpeed = IsValid(owner) and owner:IsPlayer() and owner:GetRunSpeed() or 250
end

module[2] = function(owner, org, timeValue)
	if not IsValid(owner) then return end

	local stamina = org.stamina
	local hasExojump = owner:IsPlayer() and HasEquippedAccessory(owner, "exojump")

	local painfrommoving = 0
	local painDiv = stamina.sub * ((org.jaw == 1 and 1 or 0) + org.chest + (org.jawdislocation and 1 or 0))

	if painDiv ~= 0 then
		painfrommoving = (stamina.sub * org.chest) // painDiv
	end

	if painfrommoving > 0 then
		if (org.jaw == 1) or org.jawdislocation then
		end

		if org.chest > 0.25 then
		end
	end

	stamina.sub = 0

	local velLen = 0
	local sprintSub = 0

	if owner:IsPlayer() then
		local walk = owner:KeyDown(IN_FORWARD) or owner:KeyDown(IN_BACK) or owner:KeyDown(IN_MOVELEFT) or owner:KeyDown(IN_MOVERIGHT)
		local runSpeed = max(owner:GetRunSpeed(), 1)
		local speedMul = hasExojump and 1.5 or 1
		local moveMaxSpeed = max(org.moveMaxSpeed or runSpeed * speedMul, 1)

		velLen = max(min(owner:GetVelocity():Length(), moveMaxSpeed), 0) / (runSpeed / 1.3)

		if (owner:OnGround() or owner:WaterLevel() >= 2) and walk and not owner:InVehicle() and owner:IsSprinting() and stamina[1] > 20 then
			sprintSub = (owner:WaterLevel() >= 2 and 2 or 1) * (velLen ^ 0.5)
		end
	end

	if not hasExojump then
		stamina.sub = stamina.sub + sprintSub
	end

	if org.superfighter then
		stamina.subadd = stamina.subadd / 4
	end

	if org.chest > 0.3 then
		org.lungsL[2] = min(org.lungsL[2] + stamina.sub / 200 * org.chest, 1)
		org.lungsR[2] = min(org.lungsR[2] + stamina.sub / 200 * org.chest, 1)
	end

	stamina.sub = stamina.sub + stamina.subadd + (org.painkiller > 1.6 and (stamina[1] > 10 and 0.8 or 0) or 0) + (org.analgesia > 1.7 and (stamina[1] > 10 and 2 or 0) or 0)
	stamina.sub = stamina.sub * (owner.StaminaExhaustMul or 1)
	stamina.sub = stamina.sub / (1 + org.berserk)

	stamina.subadd = 0
	stamina.weight = owner:IsPlayer() and math.Clamp((1 / hg.CalculateWeight(owner, 250)) - 1, 0, 1) or 0

	local muffed = owner.armors and owner.armors["face"] == "mask2"

	if not hasExojump then
		stamina.sub = stamina.sub + stamina.sub * stamina.weight * (muffed and 2 or 1)
	end

	org.hungry = org.hungry or 0

	stamina.max = (org.superfighter and 2 or 1) * ((stamina.range * (1 - org.pneumothorax / 2) + org.adrenaline * 20) * max(1 - org.hemotransfusionshock, 0.2)) * max(1 - org.hungry / 100, 0.65)

	stamina[1] = max(stamina[1] - stamina.sub * timeValue * 17, 0)

	stamina[1] = min(stamina[1] + stamina.regen * timeValue * 9 * 1.5 * max(stamina[1] / stamina.max, 0.2) ^ 0.5 * (org.adrenaline / 16 + 1) * (org.satiety / 700 + 1) * ((owner:IsPlayer() and owner:Crouching() and velLen < 0.1) and 1.1 or 1) * (org.holdingbreath and 0 or 1) * (org.lungsfunction and 1 or 0), stamina.max)

	if org.nextAdrenalineRegen and org.nextAdrenalineRegen < CurTime() then
		org.adrenalineStorage = math.Approach(org.adrenalineStorage, 5, timeValue / 60 * (org.satiety * 0.01 + 1))
	end
end

function hg.organism.AddNaturalAdrenaline(org, fAmount)
	if org.adrenalineStorage == 0 then return end
	if fAmount < 0 then return end

	local amt = min(org.adrenalineStorage, fAmount)
	org.adrenaline = min(org.adrenaline + amt, 5)
	org.adrenalineStorage = org.adrenalineStorage - amt
	org.nextAdrenalineRegen = CurTime() + 30
end

local entMeta = FindMetaTable("Entity")

function entMeta:AddNaturalAdrenaline(fAmount)
	local org = self.organism

	if not org then return end

	hg.organism.AddNaturalAdrenaline(org, fAmount)
end

local vecZero = Vector(0, 0, 0)

hook.Add("FinishMove", "!homigrad-organism", function(ply, move)
	local org = ply.organism
	if not org or not org.stamina then return end

	local baseMaxSpeed = ply:GetRunSpeed()
	local baseClientSpeed = ply:GetRunSpeed()
	local hasExojump = HasEquippedAccessory(ply, "exojump")

	if hasExojump then
		local speedMul = 1.5
		local newMaxSpeed = baseMaxSpeed * speedMul
		local newClientSpeed = baseClientSpeed * speedMul

		move:SetMaxSpeed(newMaxSpeed)
		move:SetMaxClientSpeed(newClientSpeed)

		org.moveMaxSpeed = newMaxSpeed
	else
		org.moveMaxSpeed = baseMaxSpeed
	end

	local vel = move:GetFinalJumpVelocity()

	if vel ~= vecZero and not hasExojump then
		org.stamina[1] = max(org.stamina[1] - ply:GetJumpPower() / 10, 0)
	end
end)