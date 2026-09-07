AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local C = CRUCIFIX_GUILT

util.AddNetworkString("CrucifixGuiltRitual")
util.AddNetworkString("CrucifixGuiltStop")

util.PrecacheSound(C.SoundRitual)
util.PrecacheSound(C.SoundFail)
util.PrecacheSound(C.SoundJudge)
util.PrecacheSound(C.SoundScream)

function C.SetGuilt(ply, value)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	value = C.Clamp(value)
	ply.Sovest = value
	ply.Karma = value
	if isfunction(ply.SetNetVar) then
		ply:SetNetVar("Sovest", value)
		ply:SetNetVar("Karma", value)
	end
	if isfunction(ply.guilt_SetValue) then
		ply:guilt_SetValue(value)
	elseif isfunction(ply.SetMData) then
		ply:SetMData("sovest", value)
	end
	if isfunction(ply.SetMData) then ply:SetMData("sovest_ts", os.time()) end
	return value
end

function C.AddGuilt(ply, amount)
	return C.SetGuilt(ply, C.GetGuilt(ply) + (tonumber(amount) or 0))
end

function C.Notify(ply, text)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	ply:ChatPrint(C.Prefix .. text)
end

function C.RepeatCount(punisher, victim)
	if not IsValid(punisher) or not IsValid(victim) then return 0 end
	punisher.CrucifixGuiltHistory = punisher.CrucifixGuiltHistory or {}
	local record = punisher.CrucifixGuiltHistory[victim:SteamID64() or victim:EntIndex()]
	if not record then return 0 end
	if record.time + C.RepeatWindow < CurTime() then return 0 end
	return record.count or 0
end

function C.RememberVictim(punisher, victim)
	if not IsValid(punisher) or not IsValid(victim) then return end
	punisher.CrucifixGuiltHistory = punisher.CrucifixGuiltHistory or {}
	local key = victim:SteamID64() or victim:EntIndex()
	punisher.CrucifixGuiltHistory[key] = { count = C.RepeatCount(punisher, victim) + 1, time = CurTime() }
end

function C.CalculateReward(punisher, victim, guilt)
	if not IsValid(punisher) then return 0 end
	local own = C.GetGuilt(punisher)
	if own >= C.RewardCeiling or own < C.PunisherMinimum then return 0 end

	local base = Lerp(C.Depth(guilt), C.RewardMin, C.RewardMax)
	base = base * (C.RewardDecay ^ math.max(tonumber(punisher.CrucifixGuiltStreak) or 0, 0))
	base = base * (C.RepeatDecay ^ C.RepeatCount(punisher, victim))

	local left = math.floor(math.max(C.RewardRoundLimit - math.max(tonumber(punisher.CrucifixGuiltGiven) or 0, 0), 0))
	local ceiling = math.floor(math.max(C.RewardCeiling - own, 0))
	local room = math.min(left, ceiling)

	if room < 1 then return 0 end

	local reward = math.floor(math.min(base, room) + 0.5)

	if reward < 1 then reward = 1 end

	return math.min(reward, room)
end

function C.CanPunish(punisher, victim)
	if not IsValid(punisher) or not punisher:IsPlayer() then return false, "Крест не в руках человека." end
	if not IsValid(victim) or not victim:IsPlayer() then return false, "Крест не чувствует здесь души." end
	if victim == punisher then return false, "Крест не судит своего носителя." end
	if not victim:Alive() then return false, "Этот человек уже мёртв." end
	if victim.CrucifixGuiltRitual then return false, "Над этим человеком уже идёт суд." end
	if not C.IsPriest(punisher) then return false, "Крест отверг тебя, он служит только экзорцисту." end

	local own = C.GetGuilt(punisher)
	if own < C.WielderMinimum then
		return false, "Твоя совесть слишком грязна для суда: " .. math.Round(own) .. " из " .. C.WielderMinimum .. " необходимых."
	end

	local guilt = C.GetGuilt(victim)
	if guilt > C.VictimThreshold then
		return false, "Совесть этого человека чиста, крест отказывается: " .. math.Round(guilt) .. " из " .. C.VictimThreshold .. " допустимых."
	end

	return true, nil, C.CalculateReward(punisher, victim, guilt), guilt
end

function C.Punish(punisher, victim, reward, guilt)
	if not IsValid(punisher) or not IsValid(victim) then return end

	local repeats = C.RepeatCount(punisher, victim)
	C.RememberVictim(punisher, victim)

	reward = tonumber(reward) or 0
	if reward <= 0 then
		if C.GetGuilt(punisher) < C.PunisherMinimum then
			C.Notify(punisher, "Суд свершён, но твоя собственная совесть слишком грязна для облегчения.")
		elseif repeats > 0 then
			C.Notify(punisher, "Суд свершён, но повторная казнь того же человека уже ничего не даёт.")
		else
			C.Notify(punisher, "Суд свершён, но чужая смерть больше не облегчает твою совесть.")
		end
		return
	end

	reward = math.floor(reward + 0.5)
	punisher.CrucifixGuiltGiven = math.floor((tonumber(punisher.CrucifixGuiltGiven) or 0)) + reward
	punisher.CrucifixGuiltStreak = (tonumber(punisher.CrucifixGuiltStreak) or 0) + 1

	local identifier = "CrucifixGuiltStreak_" .. punisher:SteamID64()
	timer.Create(identifier, C.StreakForget, 1, function()
		if not IsValid(punisher) then return end
		punisher.CrucifixGuiltStreak = 0
		punisher.CrucifixGuiltGiven = 0
	end)

	local result = C.AddGuilt(punisher, reward)
	C.Notify(punisher, "Ты покарал того, чья совесть мертва (" .. math.Round(guilt or 0) .. "). Совесть: " .. math.Round(result) .. " (+" .. reward .. ").")
end

function C.Reject(punisher, reason, penalty)
	if not IsValid(punisher) then return end
	C.Notify(punisher, reason or "Крест молчит.")
	if penalty and penalty > 0 then
		local result = C.AddGuilt(punisher, -penalty)
		C.Notify(punisher, "Попытка казнить невиновного легла на тебя. Совесть: " .. math.Round(result) .. " (-" .. penalty .. ").")
	end
end

function C.RumbleProps(pos, amplitude)
	local force = amplitude * C.PropForce
	if force <= 0 then return end

	local touched = 0
	for _, ent in ipairs(ents.FindInSphere(pos, C.PropRadius)) do
		if touched >= C.PropLimit then break end

		if IsValid(ent) and not ent:IsPlayer() and not ent:IsWeapon() then
			local phys = ent:GetPhysicsObject()

			if IsValid(phys) and phys:IsMotionEnabled() and phys:GetMass() <= C.PropMassLimit then
				local mass = math.max(phys:GetMass(), 1)
				phys:Wake()
				phys:ApplyForceCenter(Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(0.2, 1)) * force * mass)
				touched = touched + 1
			end
		end
	end
end

function C.Punch(pos, amplitude)
	local radius = C.ShakeRadius

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
			local dist = ply:GetPos():Distance(pos)

			if dist <= radius then
				local scale = 1 - (dist / radius) * C.ShakeFalloff
				local power = amplitude * scale * C.PunchScale

				if power > 0.01 then
					ply:ViewPunch(Angle(math.Rand(-power, power), math.Rand(-power, power) * 0.8, math.Rand(-power, power) * C.PunchRoll))

					local ragdoll = ply.FakeRagdoll
					if not IsValid(ragdoll) and hg and hg.ragdollFake then ragdoll = hg.ragdollFake[ply] end

					if IsValid(ragdoll) then
						local phys = ragdoll:GetPhysicsObject()
						if IsValid(phys) then
							phys:Wake()
							phys:ApplyForceCenter(Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(0, 1)) * power * 900)
						end
					end
				end
			end
		end
	end
end

local rumbleIndex = 0

function C.Shake(pos, amplitude, duration)
	pos = Vector(pos)
	duration = math.max(duration or 0.5, C.ShakeTick)

	util.ScreenShake(pos, amplitude, C.ShakeFrequency, duration, C.ShakeRadius)
	C.Punch(pos, amplitude)
	C.RumbleProps(pos, amplitude * 0.02)

	rumbleIndex = rumbleIndex + 1
	local identifier = "CrucifixGuiltRumble_" .. rumbleIndex
	local ticks = math.max(math.floor(duration / C.ShakeTick), 1)
	local tick = 0

	timer.Create(identifier, C.ShakeTick, ticks, function()
		tick = tick + 1
		local left = 1 - (tick / ticks)
		C.Punch(pos, amplitude * (0.4 + left * 0.6))
	end)
end

function C.IsCorpse(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return false end

	local class = ent:GetClass() or ""

	if class == "prop_ragdoll" then return true end
	if isfunction(ent.IsRagdoll) and ent:IsRagdoll() then return true end

	return false
end

function C.CorpseOf(victim, origin)
	local ragdoll = IsValid(victim) and victim.FakeRagdoll or nil

	if not IsValid(ragdoll) and IsValid(victim) and hg and hg.ragdollFake then ragdoll = hg.ragdollFake[victim] end
	if not IsValid(ragdoll) and IsValid(victim) and isfunction(victim.GetRagdollEntity) then ragdoll = victim:GetRagdollEntity() end
	if not IsValid(ragdoll) and IsValid(victim) and isfunction(victim.GetNWEntity) then ragdoll = victim:GetNWEntity("FakeRagdoll", NULL) end
	if C.IsCorpse(ragdoll) then return ragdoll end

	local center = origin

	if not isvector(center) then
		if not IsValid(victim) then return nil end
		center = victim:WorldSpaceCenter()
	end

	local best, bestDist = nil, C.CorpseSearch * C.CorpseSearch

	for _, ent in ipairs(ents.FindInSphere(center, C.CorpseSearch)) do
		if C.IsCorpse(ent) and ent ~= victim and not ent.CrucifixGuiltSinking then
			local dist = ent:WorldSpaceCenter():DistToSqr(center)

			if dist < bestDist then
				local owner = nil

				if hg and isfunction(hg.RagdollOwner) then owner = hg.RagdollOwner(ent) end
				if owner == nil and isfunction(ent.GetNWEntity) then
					local nwOwner = ent:GetNWEntity("RagdollOwner", NULL)
					if IsValid(nwOwner) then owner = nwOwner end
				end

				if owner == nil or owner == victim then
					best, bestDist = ent, dist
				end
			end
		end
	end

	return best
end

function C.FreezeCorpse(corpse)
	if not IsValid(corpse) then return end

	local count = isfunction(corpse.GetPhysicsObjectCount) and corpse:GetPhysicsObjectCount() or 0

	if count > 0 then
		for index = 0, count - 1 do
			local bone = corpse:GetPhysicsObjectNum(index)

			if IsValid(bone) then
				bone:EnableGravity(false)
				bone:EnableMotion(false)
			end
		end
	else
		local phys = corpse:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableGravity(false)
			phys:EnableMotion(false)
		end
	end
end

function C.MoveCorpse(corpse, offset)
	if not IsValid(corpse) then return false end

	local moved = false
	local count = isfunction(corpse.GetPhysicsObjectCount) and corpse:GetPhysicsObjectCount() or 0

	for index = 0, count - 1 do
		local bone = corpse:GetPhysicsObjectNum(index)

		if IsValid(bone) then
			bone:EnableMotion(false)
			bone:SetPos(bone:GetPos() + offset, true)
			bone:SetVelocity(vector_origin)
			bone:Sleep()
			moved = true
		end
	end

	if not moved then
		local phys = corpse:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(false)
			phys:SetPos(phys:GetPos() + offset, true)
			phys:Sleep()
			moved = true
		end
	end

	corpse:SetPos(corpse:GetPos() + offset)

	return moved
end

function C.ClearCorpseRefs(victim)
	if not IsValid(victim) then return end

	if hg and hg.ragdollFake then hg.ragdollFake[victim] = nil end
	victim.FakeRagdoll = nil
	if isfunction(victim.SetNWEntity) then victim:SetNWEntity("FakeRagdoll", NULL) end
end

function C.SinkCorpse(victim, origin)
	local identifier = "CrucifixGuiltSink_" .. (IsValid(victim) and victim:EntIndex() or math.random(1, 100000))
	local start = CurTime()
	local sunk = 0
	local target = C.SinkDepth
	local corpse = nil

	timer.Remove(identifier)

	timer.Create(identifier, C.SinkTick, 0, function()
		if not IsValid(corpse) then
			corpse = C.CorpseOf(victim, origin)

			if not IsValid(corpse) then
				if CurTime() - start > C.CorpseWait then timer.Remove(identifier) end
				return
			end

			corpse.CrucifixGuiltSinking = true
			corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			C.FreezeCorpse(corpse)
			C.ClearCorpseRefs(victim)
		end

		local progress = math.Clamp(sunk / target, 0, 1)
		local step = (C.SinkSpeed + C.SinkAccel * progress) * C.SinkTick
		sunk = sunk + step

		corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		C.MoveCorpse(corpse, Vector(0, 0, -step))

		if progress > C.SinkFade then
			local left = math.Clamp((1 - progress) / math.max(1 - C.SinkFade, 0.01), 0, 1)
			corpse:SetRenderMode(RENDERMODE_TRANSCOLOR)
			corpse:SetColor(Color(255, 255, 255, math.floor(255 * left)))
		end

		if sunk >= target then
			timer.Remove(identifier)

			local effect = EffectData()
			effect:SetOrigin(origin)
			effect:SetScale(1)
			util.Effect("cball_explode", effect, true, true)

			C.ClearCorpseRefs(victim)

			if IsValid(corpse) then corpse:Remove() end
		end
	end)
end

function C.LiftFake(victim)
	if not IsValid(victim) then return false end
	local ragdoll = victim.FakeRagdoll
	if not IsValid(ragdoll) and hg and hg.ragdollFake then ragdoll = hg.ragdollFake[victim] end
	if not IsValid(ragdoll) then return false end

	if hg and isfunction(hg.FakeUp) then hg.FakeUp(victim, true, true) end
	victim.FakeRagdoll = nil
	if isfunction(victim.SetNWEntity) then victim:SetNWEntity("FakeRagdoll", NULL) end
	if hg and hg.ragdollFake then hg.ragdollFake[victim] = nil end

	return true
end

function C.Broadcast(victim, duration, failed)
	if not IsValid(victim) then return end
	net.Start("CrucifixGuiltRitual")
	net.WriteEntity(victim)
	net.WriteFloat(duration)
	net.WriteBool(failed and true or false)
	net.Broadcast()
end

function C.PlayRitualSounds(victim, pos)
	victim:EmitSound(C.SoundRitual, 100, 100, 1, CHAN_STATIC)
	sound.Play(C.SoundRitual, pos, 100, 100, 1)
	timer.Simple(0.35, function()
		if IsValid(victim) then victim:EmitSound(C.SoundScream, 95, 100, 0.7, CHAN_VOICE) end
	end)
end

function C.StopRitualSounds(victim)
	if not IsValid(victim) then return end
	victim:StopSound(C.SoundRitual)
	victim:StopSound(C.SoundScream)
end

function C.PunishThief(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if (ply.CrucifixGuiltRejected or 0) > CurTime() then return end
	ply.CrucifixGuiltRejected = CurTime() + C.RejectCooldown

	C.Notify(ply, "Крест отверг тебя. Эта святыня подчиняется только экзорцисту.")
	ply:EmitSound(C.SoundFail, 95, 100, 1, CHAN_AUTO)
	ply:Ignite(C.RejectBurnTime)

	local info = DamageInfo()
	info:SetDamage(C.RejectDamage)
	info:SetDamageType(DMG_BURN)
	info:SetAttacker(game.GetWorld())
	info:SetInflictor(game.GetWorld())
	info:SetDamagePosition(ply:WorldSpaceCenter())
	ply:TakeDamageInfo(info)
end

function C.Expel(weapon, holder)
	if not IsValid(weapon) then return end

	local owner = IsValid(holder) and holder or weapon:GetOwner()

	timer.Simple(0, function()
		if not IsValid(weapon) then return end
		if IsValid(owner) and owner:IsPlayer() then owner:DropWeapon(weapon) end
		weapon.CrucifixGuiltDropped = true
		weapon.CrucifixGuiltInWorld = true
	end)
end

function C.Blocked(ply)
	if not IsValid(ply) then return false end
	if not ply.CrucifixGuiltGone then return false end

	if not IsValid(ply.CrucifixGuiltGoneWep) then
		ply.CrucifixGuiltGone = nil
		ply.CrucifixGuiltGoneWep = nil
		return false
	end

	return true
end

function C.WasFaked(ply)
	if not IsValid(ply) then return false end
	if IsValid(ply.FakeRagdoll) then return true end
	if hg and hg.ragdollFake and IsValid(hg.ragdollFake[ply]) then return true end
	if (CurTime() - (ply.CrucifixGuiltFakeTime or -100)) < 1.5 then return true end
	return false
end

function C.ClearGone(ply)
	if not IsValid(ply) then return end
	ply.CrucifixGuiltDied = nil
	ply.CrucifixGuiltGone = nil
	ply.CrucifixGuiltGoneWep = nil
end

C.UseGrace = C.UseGrace or 0.35
C.WorldMarkDelay = C.WorldMarkDelay or 0.25

function C.MarkWorld(weapon)
	if not IsValid(weapon) then return end
	if not weapon.CrucifixGuilt then return end
	if IsValid(weapon:GetOwner()) then return end

	weapon.CrucifixGuiltInWorld = true
end

function C.ClearWorld(weapon)
	if not IsValid(weapon) then return end

	weapon.CrucifixGuiltInWorld = nil
end

function C.NeedsUse(weapon)
	if not IsValid(weapon) then return false end
	if IsValid(weapon:GetOwner()) then return false end

	return weapon.CrucifixGuiltDropped == true or weapon.CrucifixGuiltInWorld == true
end

function C.WantsPickup(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply:KeyDown(IN_USE) then return true end

	return (ply.CrucifixGuiltUseTime or 0) > CurTime()
end

hook.Add("OnEntityCreated", "CrucifixGuiltWorldMark", function(ent)
	if not IsValid(ent) then return end
	if not ent.IsWeapon or not ent:IsWeapon() then return end

	timer.Simple(C.WorldMarkDelay, function()
		C.MarkWorld(ent)
	end)
end)

hook.Add("PlayerUse", "CrucifixGuiltUseTrack", function(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return end
	if not ent.CrucifixGuilt then return end

	ply.CrucifixGuiltUseTime = CurTime() + C.UseGrace
end)

function C.Break(victim, punisher, reason)
	if IsValid(punisher) then punisher.CrucifixGuiltCasting = nil end
	if not IsValid(victim) or not victim.CrucifixGuiltRitual then return end

	local weapon = victim.CrucifixGuiltWeapon

	victim.CrucifixGuiltRitual = nil
	victim.CrucifixGuiltWeapon = nil

	timer.Remove("CrucifixGuiltRitual_" .. victim:EntIndex())
	timer.Remove("CrucifixGuiltShake_" .. victim:EntIndex())

	victim:Freeze(false)

	if victim:Alive() then
		victim:SetMoveType(MOVETYPE_WALK)
		victim:SetVelocity(vector_origin)
	end

	C.StopRitualSounds(victim)
	sound.Play(C.SoundFail, victim:GetPos(), 95, 100, 0.9)
	C.Broadcast(victim, 1.5, true)

	if C.BreakRefund and IsValid(weapon) and isfunction(weapon.SetUsesLeft) then
		weapon:SetUsesLeft(math.min(weapon:GetUsesLeft() + 1, C.Uses))
		weapon:SetNextRitual(CurTime() + C.FailCooldown)
	end

	if victim:Alive() then C.Notify(victim, "Крест выпустил твою душу. Ты остался жив.") end

	if not IsValid(punisher) then return end

	if reason == "hurt" then
		C.Notify(punisher, "Тебя ранили — обряд сорвался, душа ушла из круга.")
	elseif reason == "left" then
		C.Notify(punisher, "Ты отошёл слишком далеко — крест потерял связь с душой.")
	elseif reason == "drop" then
		C.Notify(punisher, "Ты отпустил крест — обряд прерван.")
	elseif reason == nil then
		C.Notify(punisher, "Суд прерван, крест отпустил душу.")
	end
end

hook.Add("EntityTakeDamage", "CrucifixGuiltProtectVictim", function(target, dmginfo)
	if not IsValid(target) then return end

	local hurt = target:IsPlayer() and target or C.ResolvePlayer(target)
	if not IsValid(hurt) then return end

	if hurt.CrucifixGuiltRitual then
		dmginfo:ScaleDamage(0)
		return true
	end

	local victim = hurt.CrucifixGuiltCasting
	if not IsValid(victim) then return end
	if dmginfo:GetDamage() < C.BreakDamage then return end

	timer.Simple(0, function()
		if IsValid(victim) then C.Break(victim, hurt, "hurt") end
	end)
end)

hook.Add("PlayerDeath", "CrucifixGuiltDeath", function(ply)
	if not IsValid(ply) then return end
	ply.CrucifixGuiltDied = true
	C.Break(ply.CrucifixGuiltCasting, ply, "dead")
end)

hook.Add("PlayerCanPickupWeapon", "CrucifixGuiltPickup", function(ply, wep)
	if not IsValid(ply) or not IsValid(wep) then return end
	if not wep.CrucifixGuilt then return end

	if C.NeedsUse(wep) and not C.WantsPickup(ply) then return false end

	if not C.IsPriest(ply) then
		C.PunishThief(ply)
		return false
	end

	if wep.CrucifixGuiltDropped then
		C.ClearGone(ply)
		return true
	end

	if C.Blocked(ply) then return false end

	return true
end)

hook.Add("WeaponEquip", "CrucifixGuiltEquipGuard", function(wep, ply)
	if not IsValid(wep) or not wep.CrucifixGuilt then return end

	ply = IsValid(ply) and ply or wep:GetOwner()
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if not C.IsPriest(ply) then
		C.PunishThief(ply)
		C.Expel(wep, ply)
		return
	end

	if C.Blocked(ply) and not wep.CrucifixGuiltDropped then
		timer.Simple(0, function()
			if IsValid(wep) then wep:Remove() end
		end)
		return
	end

	wep.CrucifixGuiltDropped = nil
	wep.CrucifixGuiltHolder = ply
	C.ClearWorld(wep)
	C.ClearGone(ply)
end)

hook.Add("PlayerDisconnected", "CrucifixGuiltClearVictim", function(ply)
	C.Break(ply.CrucifixGuiltCasting, nil, "dead")
	ply.CrucifixGuiltRitual = nil
	timer.Remove("CrucifixGuiltRitual_" .. ply:EntIndex())
	timer.Remove("CrucifixGuiltShake_" .. ply:EntIndex())
	timer.Remove("CrucifixGuiltSink_" .. ply:EntIndex())
end)

hook.Add("PlayerSpawn", "CrucifixGuiltRestoreVictim", function(ply)
	ply.CrucifixGuiltRitual = nil
	ply.CrucifixGuiltWeapon = nil
	ply.CrucifixGuiltCasting = nil

	if not C.WasFaked(ply) then C.ClearGone(ply) end
end)

hook.Add("Fake", "CrucifixGuiltBlockFake", function(ply, ragdoll)
	if not IsValid(ply) then return end
	ply.CrucifixGuiltFakeTime = CurTime()
	if not ply.CrucifixGuiltRitual then return end
	timer.Simple(0, function()
		if IsValid(ply) and ply.CrucifixGuiltRitual then C.LiftFake(ply) end
	end)
end)

function SWEP:RejectWielder(owner)
	if not IsValid(owner) or not owner:IsPlayer() then return end

	C.PunishThief(owner)
	C.Expel(self, owner)
end

function SWEP:LegacyReject(owner)
	if not IsValid(owner) or not owner:IsPlayer() then return end
	if (owner.CrucifixGuiltRejected or 0) > CurTime() then return end
	owner.CrucifixGuiltRejected = CurTime() + C.RejectCooldown

	C.Notify(owner, "Крест отверг тебя. Эта святыня подчиняется только экзорцисту.")
	owner:EmitSound(C.SoundFail, 95, 100, 1, CHAN_AUTO)
	owner:Ignite(C.RejectBurnTime)

	local info = DamageInfo()
	info:SetDamage(C.RejectDamage)
	info:SetDamageType(DMG_BURN)
	info:SetAttacker(game.GetWorld())
	info:SetInflictor(game.GetWorld())
	info:SetDamagePosition(owner:WorldSpaceCenter())
	owner:TakeDamageInfo(info)

	local weapon = self
	timer.Simple(0, function()
		if not IsValid(owner) or not IsValid(weapon) then return end
		owner:DropWeapon(weapon)
	end)
end

function SWEP:Equip(owner)
	if not IsValid(owner) or not owner:IsPlayer() then return end

	if not C.IsPriest(owner) then
		self:RejectWielder(owner)
		return
	end

	self.CrucifixGuiltHolder = owner
	self.CrucifixGuiltDropped = nil
	C.ClearWorld(self)
	C.ClearGone(owner)
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then self.CrucifixGuiltHolder = owner end
end

function SWEP:OnDrop()
	self.CrucifixGuiltDropped = true
	self.CrucifixGuiltInWorld = true

	local owner = self.CrucifixGuiltHolder
	self.CrucifixGuiltHolder = nil

	if not IsValid(owner) then return end

	if C.IsPriest(owner) then
		owner.CrucifixGuiltGone = true
		owner.CrucifixGuiltGoneWep = self
	end
	C.Break(owner.CrucifixGuiltCasting, owner, "drop")
end

function SWEP:Deploy()
	self:SetHoldType(self.HoldType)

	local owner = self:GetOwner()
	if IsValid(owner) and not C.IsPriest(owner) then
		self:RejectWielder(owner)
		return false
	end

	if IsValid(owner) then self.CrucifixGuiltHolder = owner end

	return true
end

function SWEP:FindTarget()
	local owner = self:GetOwner()
	if not IsValid(owner) then return nil end

	local trace = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * C.Distance,
		filter = owner,
		mask = MASK_SHOT
	})

	local target = C.ResolvePlayer(trace.Entity)
	if IsValid(target) then return target end

	for _, found in ipairs(ents.FindInCone(owner:GetShootPos(), owner:GetAimVector(), C.Distance, math.cos(math.rad(14)))) do
		local resolved = C.ResolvePlayer(found)
		if IsValid(resolved) and resolved ~= owner and resolved:Alive() then
			local visible = util.TraceLine({
				start = owner:GetShootPos(),
				endpos = resolved:WorldSpaceCenter(),
				filter = { owner, found },
				mask = MASK_SHOT
			})
			if not visible.Hit then return resolved end
		end
	end

	return nil
end

function SWEP:Judge(punisher, victim, reward, guilt)
	if not IsValid(victim) then return end

	victim.CrucifixGuiltRitual = nil
	victim.CrucifixGuiltWeapon = nil
	if IsValid(punisher) then punisher.CrucifixGuiltCasting = nil end
	victim:Freeze(false)
	victim:SetMoveType(MOVETYPE_WALK)
	timer.Remove("CrucifixGuiltShake_" .. victim:EntIndex())

	C.Shake(victim:GetPos(), C.ShakeFinal, 1.4)

	C.StopRitualSounds(victim)
	victim:EmitSound(C.SoundJudge, 100, 100, 0.8, CHAN_STATIC)
	sound.Play(C.SoundJudge, victim:GetPos(), 100, 100, 0.8)

	local info = DamageInfo()
	info:SetDamage(math.max(victim:Health(), 1) + 500)
	info:SetDamageType(DMG_DISSOLVE)
	info:SetAttacker(game.GetWorld())
	info:SetInflictor(game.GetWorld())
	info:SetDamagePosition(victim:WorldSpaceCenter())
	victim:TakeDamageInfo(info)

	if victim:Alive() then victim:Kill() end

	local grave = victim:GetPos() + Vector(0, 0, 24)
	timer.Simple(C.SinkDelay, function()
		C.Shake(grave, C.ShakeFinal * 0.5, 1.2)
		C.SinkCorpse(victim, grave)
	end)

	if IsValid(punisher) then
		C.Punish(punisher, victim, reward, guilt)
	end
end

function SWEP:Cancel(victim, silent, punisher)
	if not IsValid(victim) then return end
	C.Break(victim, punisher, silent and "dead" or nil)
end

function SWEP:StartRitual(punisher, victim, reward, guilt)
	local anchor = victim:GetPos()
	local started = CurTime()
	local identifier = "CrucifixGuiltRitual_" .. victim:EntIndex()
	local shakeId = "CrucifixGuiltShake_" .. victim:EntIndex()
	local yaw = victim:EyeAngles().y
	local last = CurTime()

	C.LiftFake(victim)

	victim.CrucifixGuiltRitual = true
	victim.CrucifixGuiltWeapon = self
	if IsValid(punisher) then punisher.CrucifixGuiltCasting = victim end
	victim:Freeze(true)
	victim:SetMoveType(MOVETYPE_NONE)
	victim:SetVelocity(vector_origin)
	timer.Create(shakeId, 0.35, 0, function()
		if not IsValid(victim) then timer.Remove(shakeId) return end
		local progress = math.Clamp((CurTime() - started) / C.RitualTime, 0, 1)
		local amplitude = C.ShakeBase + (C.ShakePeak - C.ShakeBase) * (progress ^ 2.2)
		C.Shake(anchor, amplitude, 0.5)
	end)

	C.PlayRitualSounds(victim, anchor)
	C.Broadcast(victim, C.RitualTime, false)

	timer.Create(identifier, 0.02, 0, function()
		if not IsValid(self) then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			C.Break(victim, punisher, "drop")
			return
		end

		if not IsValid(victim) or not victim:Alive() then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			if IsValid(victim) then self:Cancel(victim, true, punisher) end
			return
		end

		if not IsValid(punisher) or not punisher:Alive() then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			C.Break(victim, punisher, "dead")
			return
		end

		local casterDown = IsValid(punisher.FakeRagdoll)
		if not casterDown and hg and hg.ragdollFake and IsValid(hg.ragdollFake[punisher]) then casterDown = true end

		if casterDown then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			C.Break(victim, punisher, "hurt")
			return
		end

		if punisher:GetActiveWeapon() ~= self then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			C.Break(victim, punisher, "drop")
			return
		end

		if punisher:GetPos():Distance(anchor) > C.LeashDistance then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			C.Break(victim, punisher, "left")
			return
		end

		local progress = math.Clamp((CurTime() - started) / C.RitualTime, 0, 1)
		local delta = math.max(CurTime() - last, 0)
		last = CurTime()

		local speed = C.SpinBase + (C.SpinPeak - C.SpinBase) * (progress ^ C.SpinCurve)
		yaw = (yaw + speed * delta) % 360

		if victim.FakeRagdoll then C.LiftFake(victim) end

		victim:SetPos(anchor + Vector(0, 0, C.LiftHeight * math.sin(progress * math.pi * 0.5)))
		victim:SetEyeAngles(Angle(math.Clamp(-30 * progress, -30, 0), yaw, 0))
		victim:SetLocalAngles(Angle(0, yaw, 0))
		victim:SetVelocity(vector_origin)

		if progress >= 1 then
			timer.Remove(identifier)
			timer.Remove(shakeId)
			self:Judge(punisher, victim, reward, guilt)
		end
	end)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1)

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	if not C.IsPriest(owner) then
		self:RejectWielder(owner)
		return
	end

	local own = C.GetGuilt(owner)
	if own < C.WielderMinimum then
		C.Notify(owner, "Крест мёртв в твоих руках: твоя совесть " .. math.Round(own) .. ", нужно минимум " .. C.WielderMinimum .. ".")
		self:SetNextRitual(CurTime() + C.FailCooldown)
		self:EmitSound(C.SoundFail, 85, 100, 0.9, CHAN_WEAPON)
		return
	end

	if self:GetUsesLeft() <= 0 then
		C.Notify(owner, "Крест исчерпан и больше не отвечает.")
		return
	end

	local wait = self:GetNextRitual() - CurTime()
	if wait > 0 then
		C.Notify(owner, "Крест ещё остывает: " .. math.ceil(wait) .. " сек.")
		return
	end

	local target = self:FindTarget()
	if not IsValid(target) then
		C.Notify(owner, "Перед тобой нет человека для суда.")
		self:SetNextRitual(CurTime() + 2)
		return
	end

	local allowed, reason, reward, guilt = C.CanPunish(owner, target)
	if not allowed then
		local innocent = C.GetGuilt(target) > C.VictimThreshold
		C.Reject(owner, reason, innocent and C.FailPenalty or 0)
		self:SetNextRitual(CurTime() + C.FailCooldown)
		self:EmitSound(C.SoundFail, 85, 100, 0.9, CHAN_WEAPON)
		return
	end

	self:StartRitual(owner, target, reward, guilt)

	self:SetUsesLeft(self:GetUsesLeft() - 1)
	self:SetNextRitual(CurTime() + C.Cooldown)
	self:SetNextPrimaryFire(CurTime() + 2)
	owner:SetAnimation(PLAYER_ATTACK1)

	C.Notify(owner, "Суд начат. Совесть осуждённого: " .. math.Round(guilt) .. ". Изгнание займёт " .. math.Round(C.RitualTime) .. " сек.")
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 1.5)

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	local wait = math.max(self:GetNextRitual() - CurTime(), 0)
	local own = C.GetGuilt(owner)
	C.Notify(owner, "Твоя совесть: " .. math.Round(own) .. " (нужно " .. C.WielderMinimum .. "). Осталось судов: " .. self:GetUsesLeft() .. ". Откат: " .. math.ceil(wait) .. " сек.")

	if not C.IsPriest(owner) then
		C.Notify(owner, "Крест не признаёт тебя: он служит только экзорцисту.")
	elseif own < C.WielderMinimum then
		C.Notify(owner, "Крест молчит, пока твоя совесть ниже " .. C.WielderMinimum .. ".")
	end
end

function SWEP:Reload()
end

function SWEP:Holster()
	local owner = self:GetOwner()
	if IsValid(owner) then C.Break(owner.CrucifixGuiltCasting, owner, "drop") end
	return true
end

function SWEP:OnRemove()
end
