if not SERVER then return end

hg = hg or {}
hg.CPR = hg.CPR or {}

local C = hg.CPR

C.Window = 60
C.WindowMin = 15
C.Required = 40
C.RequiredMax = 160
C.DoctorBonus = 2
C.Decay = 1
C.DecayDelay = 1.5
C.DecayRate = 0.5
C.Forget = 5
C.Health = 35
C.HealthMin = 8
C.UpdateRate = 0.4
C.GearRange = 250
C.active = C.active or {}

C.GearBlacklist = {
	["weapon_hands_sh"] = true
}

C.Fatal = {
	brain = 0.9,
	skull = 0.95,
	spine = 0.95,
	heart = 0.9,
	lungs = 0.9,
	blood = 1200,
	burns = 10
}

C.Reasons = {
	head = "Головы нет. Здесь некого возвращать.",
	brain = "Мозг разрушен — сознание уже не вернётся.",
	skull = "Череп раздроблен. СЛР бессмысленна.",
	spine = "Шея перебита — тело не ответит.",
	heart = "Сердце разорвано, качать нечего.",
	lungs = "Оба лёгких уничтожены — дышать он не сможет.",
	blood = "В теле почти не осталось крови.",
	burned = "Тело слишком сильно обгорело.",
	late = "Слишком поздно. Сердце больше не отвечает.",
	unknown = "СЛР здесь уже не поможет."
}

C.HeadBones = {
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_Neck1"
}

util.AddNetworkString("hg cpr revive")

local function send(victim, stage, ratio)
	if not IsValid(victim) or not victim:IsPlayer() then return end

	net.Start("hg cpr revive", true)
	net.WriteUInt(stage, 3)
	net.WriteFloat(math.Clamp(ratio or 0, 0, 1))
	net.Send(victim)
end

local function tell(medic, text)
	if not IsValid(medic) or not medic:IsPlayer() then return end
	if (medic.CPRPrint or 0) > CurTime() then return end

	medic.CPRPrint = CurTime() + 4
	medic:ChatPrint(text)
end

function C.Resolve(corpse)
	if not IsValid(corpse) then return nil end

	local ply = isfunction(corpse.GetNWEntity) and corpse:GetNWEntity("ply") or nil

	if IsValid(ply) and ply:IsPlayer() then return ply end

	if hg and isfunction(hg.RagdollOwner) then
		local owner = hg.RagdollOwner(corpse)

		if IsValid(owner) and owner:IsPlayer() then return owner end
	end

	for _, target in ipairs(player.GetAll()) do
		if target.FakeRagdoll == corpse then return target end
		if isfunction(target.GetNWEntity) and target:GetNWEntity("RagdollDeath") == corpse then return target end
		if isfunction(target.GetNWEntity) and target:GetNWEntity("FakeRagdoll") == corpse then return target end
		if target.CPRCorpse == corpse then return target end
	end

	return nil
end

function C.DeathTime(victim, org)
	local time = tonumber(victim.CPRDeathTime)

	if time then return time end

	if org and tonumber(org.last_heartbeat) then return tonumber(org.last_heartbeat) end

	return nil
end

function C.Value(org, key)
	if not org then return 0 end

	local value = org[key]

	if istable(value) then value = value[1] end

	return tonumber(value) or 0
end

function C.HasHead(corpse)
	if not IsValid(corpse) then return false end
	if not isfunction(corpse.LookupBone) then return true end

	local bone = nil

	for _, name in ipairs(C.HeadBones) do
		bone = corpse:LookupBone(name)

		if bone then break end
	end

	if not bone then return false end

	if isfunction(corpse.GetManipulateBoneScale) then
		local scale = corpse:GetManipulateBoneScale(bone)

		if isvector(scale) and scale:Length() > 0 and scale:Length() < 0.15 then return false end
	end

	if corpse:IsRagdoll() and isfunction(corpse.GetBonePosition) then
		local pos = corpse:GetBonePosition(bone)

		if isvector(pos) and pos:DistToSqr(corpse:GetPos()) > (240 * 240) then return false end
	end

	return true
end

function C.Headless(ent)
	if not IsValid(ent) then return false end
	if not ent.noHead then return false end

	return not C.HasHead(ent)
end

function C.Verdict(victim, corpse, org)
	local fatal = C.Fatal

	if C.Headless(corpse) then return false, "head", 1 end

	if not org then return false, "brain", 1 end

	local brain = C.Value(org, "brain")
	local skull = C.Value(org, "skull")
	local heart = C.Value(org, "heart")
	local lungsR = C.Value(org, "lungsR")
	local lungsL = C.Value(org, "lungsL")
	local spine = math.max(C.Value(org, "spine3"), C.Value(org, "spine2"))
	local blood = tonumber(org.blood) or 5000
	local burns = tonumber(org.burns) or 0

	if brain >= fatal.brain then return false, "brain", 1 end
	if skull >= fatal.skull then return false, "skull", 1 end
	if spine >= fatal.spine then return false, "spine", 1 end
	if heart >= fatal.heart then return false, "heart", 1 end
	if lungsR >= fatal.lungs and lungsL >= fatal.lungs then return false, "lungs", 1 end
	if blood < fatal.blood then return false, "blood", 1 end
	if burns >= fatal.burns then return false, "burned", 1 end

	local penalty = 1

	penalty = penalty + brain * 2
	penalty = penalty + heart * 1.5
	penalty = penalty + skull * 0.5
	penalty = penalty + spine * 0.75
	penalty = penalty + (lungsR + lungsL) * 0.5
	penalty = penalty + math.Clamp((2600 - blood) / 1400, 0, 1) * 1.5
	penalty = penalty + math.Clamp((tonumber(org.internalBleed) or 0) / 20, 0, 1) * 0.5
	penalty = penalty + math.Clamp(burns / fatal.burns, 0, 1) * 0.5

	if org.llegamputated then penalty = penalty + 0.25 end
	if org.rlegamputated then penalty = penalty + 0.25 end
	if org.larmamputated then penalty = penalty + 0.35 end
	if org.rarmamputated then penalty = penalty + 0.35 end

	local bleeding = 0

	if istable(org.arterialwounds) then
		for _, wound in pairs(org.arterialwounds) do
			bleeding = bleeding + (tonumber(wound[1]) or 0)
		end
	end

	penalty = penalty + math.Clamp(bleeding / 30, 0, 1)

	return true, nil, penalty
end

function C.Ratio(victim)
	local data = C.active[victim]

	if not data then return 0 end

	return math.Clamp(data.progress / math.max(data.required or C.Required, 1), 0, 1)
end

function C.Stop(victim, reason)
	local data = C.active[victim]

	if not data then return end

	local ratio = C.Ratio(victim)

	C.active[victim] = nil

	if not IsValid(victim) then return end

	if reason == "revived" then
		send(victim, 3, ratio)
	elseif reason == "fatal" then
		send(victim, 5, ratio)
	else
		send(victim, 4, ratio)
	end

	if reason == "late" then tell(data.medic, C.Reasons.late) end
end

function C.Inventory(ent)
	if not IsValid(ent) then return nil end

	local inv = ent.inventory

	if not istable(inv) and isfunction(ent.GetNetVar) then inv = ent:GetNetVar("Inventory", nil) end

	return istable(inv) and inv or nil
end

function C.FreeWeapon(wep)
	if not IsValid(wep) then return false end
	if C.GearBlacklist[wep:GetClass()] then return false end

	local owner = wep:GetOwner()

	if IsValid(owner) and owner:IsPlayer() then return false end

	constraint.RemoveAll(wep)

	wep:SetParent(nil)
	wep:SetNoDraw(false)
	wep:DrawShadow(true)
	wep:RemoveSolidFlags(FSOLID_NOT_SOLID)
	wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	wep.sling = nil

	return true
end

function C.TakeWeapon(victim, wep)
	if not C.FreeWeapon(wep) then return false end

	wep:SetPos(victim:GetPos() + vector_up * 16)
	wep:SetVelocity(vector_origin)

	victim:PickupWeapon(wep, false)

	return true
end

function C.RestoreGear(victim, corpse)
	if not IsValid(victim) or not victim:IsPlayer() then return end

	local inv = C.Inventory(corpse)
	local taken = 0

	if inv then
		local weps = istable(inv.Weapons) and inv.Weapons or {}

		for class, wep in pairs(weps) do
			if C.GearBlacklist[class] then continue end

			if isentity(wep) and IsValid(wep) then
				if C.TakeWeapon(victim, wep) then taken = taken + 1 end
			elseif wep and isstring(class) then
				local given = victim:Give(class)

				if IsValid(given) then taken = taken + 1 end
			end
		end

		if istable(inv.Ammo) then
			for id, amount in pairs(inv.Ammo) do
				local count = tonumber(amount) or 0

				if count > 0 then victim:SetAmmo(count, tonumber(id) or id) end
			end
		end
	end

	if istable(victim.CPRDropped) then
		for _, wep in pairs(victim.CPRDropped) do
			if IsValid(wep) then
				local near = not IsValid(corpse) or wep:GetPos():DistToSqr(corpse:GetPos()) < (C.GearRange * C.GearRange)

				if near and C.TakeWeapon(victim, wep) then taken = taken + 1 end
			end
		end
	end

	victim.CPRDropped = nil

	local armor = IsValid(corpse) and (istable(corpse.armors) and corpse.armors or (isfunction(corpse.GetNetVar) and corpse:GetNetVar("Armor", nil))) or nil

	if istable(armor) and next(armor) then
		victim.armors = armor
		victim:SetNetVar("Armor", armor)

		if istable(corpse.armors_health) then victim.armors_health = corpse.armors_health end
		if isfunction(victim.SyncArmor) then victim:SyncArmor() end
	end

	if IsValid(corpse) then
		corpse.inventory = { Weapons = {}, Ammo = {}, Armor = {}, Attachments = {} }
		corpse.armors = {}
		corpse.armors_health = {}

		if isfunction(corpse.SetNetVar) then
			corpse:SetNetVar("Inventory", corpse.inventory)
			corpse:SetNetVar("Armor", {})
		end
	end

	if hg and isfunction(hg.SyncWeapons) then hg.SyncWeapons() end

	return taken
end

function C.Wound(victim, penalty)
	if not IsValid(victim) then return end

	local org = victim.organism

	if not org then return end

	penalty = math.Clamp(penalty or 1, 1, 4)

	org.heartstop = false
	org.alive = true
	org.lungsfunction = true

	if tonumber(org.pulse) then org.pulse = math.max(org.pulse, 45 - penalty * 5) end
	if tonumber(org.blood) then org.blood = math.min(org.blood, 3400 - penalty * 200) end
	if tonumber(org.pain) then org.pain = math.max(org.pain, 30 + penalty * 15) end
	if tonumber(org.painadd) then org.painadd = math.max(org.painadd, 10 + penalty * 10) end
	if tonumber(org.shock) then org.shock = math.max(org.shock, 15 + penalty * 15) end
	if tonumber(org.disorientation) then org.disorientation = math.max(org.disorientation, 20 + penalty * 15) end
	if tonumber(org.consciousness) then org.consciousness = math.min(org.consciousness, 0.75) end
	if tonumber(org.brain) then org.brain = math.max(org.brain, math.Clamp((penalty - 1) * 0.15, 0, 0.55)) end

	if hg and isfunction(hg.LightStunPlayer) then hg.LightStunPlayer(victim, 2 + penalty) end
end

function C.GiveHands(victim)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if not victim:Alive() then return end

	local hands = victim:GetWeapon("weapon_hands_sh")

	if not IsValid(hands) then
		victim:Give("weapon_hands_sh")
		hands = victim:GetWeapon("weapon_hands_sh")
	end

	if not IsValid(hands) then return end

	local active = victim:GetActiveWeapon()

	if not IsValid(active) then victim:SetActiveWeapon(hands) end

	return hands
end

function C.Revive(victim, medic, corpse, penalty)
	if not IsValid(victim) or not victim:IsPlayer() then return end

	penalty = math.Clamp(penalty or 1, 1, 4)

	local pos = IsValid(corpse) and corpse:GetPos() or victim:GetPos()
	local ang = victim:EyeAngles()
	local health = math.max(math.floor(C.Health / penalty), C.HealthMin)

	C.active[victim] = nil
	victim.CPRDeathTime = nil
	victim.CPRCorpse = nil
	victim.CPRRevived = CurTime()

	if hg and isfunction(hg.OverrideSpawn) then hg.OverrideSpawn(victim) end

	victim:Spawn()
	victim:SetPos(pos + vector_up * 4)
	victim:SetEyeAngles(Angle(0, ang.y, 0))
	victim:SetHealth(math.min(health, victim:GetMaxHealth()))

	C.GiveHands(victim)
	C.Wound(victim, penalty)

	timer.Simple(0, function()
		if not IsValid(victim) then return end

		victim:SetPos(pos + vector_up * 4)
		victim:SetHealth(math.min(health, victim:GetMaxHealth()))

		C.Wound(victim, penalty)

		C.GiveHands(victim)

		local taken = C.RestoreGear(victim, corpse) or 0

		if taken > 0 then victim:ChatPrint("Ваше снаряжение вернулось к вам.") end

		if IsValid(corpse) then SafeRemoveEntity(corpse) end
	end)

	timer.Simple(0.25, function()
		C.GiveHands(victim)
	end)

	timer.Simple(1, function()
		C.GiveHands(victim)
	end)

	send(victim, 3, 1)

	if IsValid(medic) and medic:IsPlayer() then
		medic.CPRPrint = nil
		medic:ChatPrint("Сердце снова бьётся. Человек жив, но ему нужна помощь.")
	end

	hook.Run("HG CPR Revived", victim, medic, corpse, penalty)
end

function C.Compress(medic, corpse, org)
	if not IsValid(medic) or not medic:IsPlayer() then return end
	if not IsValid(corpse) then return end

	local victim = C.Resolve(corpse)

	if not IsValid(victim) or not victim:IsPlayer() then return end
	if victim:Alive() then return end

	local ok, reason, penalty = C.Verdict(victim, corpse, org)

	if not ok then
		if C.active[victim] then C.Stop(victim, "fatal") end

		tell(medic, C.Reasons[reason] or C.Reasons.unknown)

		return
	end

	local dead = C.DeathTime(victim, org)

	if not dead then return end

	local time = CurTime()
	local window = math.max(C.Window / penalty, C.WindowMin)

	if dead + window < time then
		if C.active[victim] then C.Stop(victim, "late") end

		tell(medic, C.Reasons.late)

		return
	end

	local data = C.active[victim]

	if not data then
		data = {
			progress = 0,
			dead = dead,
			next = 0,
			decay = 0,
			notified = 0,
			medic = medic,
			penalty = penalty,
			window = window,
			required = math.Clamp(math.ceil(C.Required * penalty), C.Required, C.RequiredMax)
		}

		C.active[victim] = data

		send(victim, 1, 0)

		medic.CPRPrint = nil

		if penalty >= 2.5 then
			tell(medic, "Тело изувечено. Шанс мизерный, но качать есть смысл.")
		elseif penalty >= 1.6 then
			tell(medic, "Ранения тяжёлые — качать придётся дольше.")
		else
			tell(medic, "Сердце ещё можно запустить. Не останавливайтесь.")
		end
	end

	data.medic = medic
	data.last = time
	data.penalty = penalty
	data.window = window
	data.required = math.Clamp(math.ceil(C.Required * penalty), C.Required, C.RequiredMax)
	data.progress = data.progress + (medic.Profession == "doctor" and C.DoctorBonus or 1)

	local ratio = C.Ratio(victim)
	local step = math.floor(ratio * 4)

	if step > (data.notified or 0) then
		data.notified = step
		medic.CPRPrint = nil

		tell(medic, "Сердце отвечает: " .. math.Round(ratio * 100) .. "%")
	end

	if data.progress >= data.required then
		C.Revive(victim, medic, corpse, penalty)

		return
	end

	if data.next < time then
		data.next = time + C.UpdateRate

		send(victim, 2, ratio)
	end
end

hook.Add("Think", "homigrad-cpr-revive", function()
	local time = CurTime()

	for victim, data in pairs(C.active) do
		if not IsValid(victim) then
			C.active[victim] = nil
			continue
		end

		if victim:Alive() then
			C.Stop(victim, "revived")
			continue
		end

		if data.dead + (data.window or C.Window) < time then
			C.Stop(victim, "late")
			continue
		end

		if (data.last or 0) + C.Forget < time then
			C.Stop(victim, "stopped")
			continue
		end

		if (data.last or 0) + C.DecayDelay < time and (data.decay or 0) < time then
			data.decay = time + C.DecayRate
			data.progress = math.max(data.progress - C.Decay * (data.penalty or 1), 0)

			send(victim, 2, C.Ratio(victim))
		end
	end
end)

hook.Add("PlayerDeath", "homigrad-cpr-revive", function(victim)
	if not IsValid(victim) then return end

	victim.CPRDeathTime = CurTime()
	victim.CPRDropped = {}
	C.active[victim] = nil

	timer.Simple(0, function()
		if not IsValid(victim) then return end

		local corpse = victim.FakeRagdoll

		if not IsValid(corpse) and isfunction(victim.GetNWEntity) then corpse = victim:GetNWEntity("RagdollDeath") end

		if IsValid(corpse) then victim.CPRCorpse = corpse end
	end)
end)

hook.Add("PlayerDroppedWeapon", "homigrad-cpr-revive", function(victim, wep)
	if not IsValid(victim) or not victim:IsPlayer() or not IsValid(wep) then return end
	if C.GearBlacklist[wep:GetClass()] then return end

	local dead = tonumber(victim.CPRDeathTime)

	if not dead or dead + 2 < CurTime() then return end

	victim.CPRDropped = istable(victim.CPRDropped) and victim.CPRDropped or {}
	victim.CPRDropped[wep:GetClass()] = wep
end)

hook.Add("PlayerSpawn", "homigrad-cpr-revive", function(victim)
	if not IsValid(victim) then return end

	C.active[victim] = nil
	victim.CPRCorpse = nil

	timer.Simple(0.2, function()
		if not IsValid(victim) then return end
		if (victim.CPRRevived or 0) + 1 > CurTime() then return end

		victim.CPRDropped = nil
	end)
end)

hook.Add("PlayerDisconnected", "homigrad-cpr-revive", function(victim)
	if not victim then return end

	C.active[victim] = nil
	victim.CPRDeathTime = nil
	victim.CPRCorpse = nil
	victim.CPRDropped = nil
end)
