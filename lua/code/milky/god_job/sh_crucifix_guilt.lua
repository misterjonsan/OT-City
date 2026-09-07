CRUCIFIX_GUILT = CRUCIFIX_GUILT or {}

local C = CRUCIFIX_GUILT

local function PickModel()
	if file.Exists("models/doors/crucifix.mdl", "GAME") then return "models/doors/crucifix.mdl" end
	if file.Exists("models/props_c17/gravestone_cross001a.mdl", "GAME") then return "models/props_c17/gravestone_cross001a.mdl" end
	return "models/props_junk/wood_crate001a.mdl"
end

local function PickSound(path, fallback)
	if file.Exists("sound/" .. path, "GAME") then return path end
	return fallback
end

C.Model = PickModel()
C.SoundRitual = PickSound("doors/crucifix.wav", "ambient/atmosphere/cave_hit4.wav")
C.SoundFail = PickSound("doors/crucifix_fail.wav", "ambient/machines/machine1_hit2.wav")
C.SoundJudge = PickSound("doors/Hallelujah.ogg", "ambient/levels/labs/electric_explosion4.wav")

C.Distance = 260
C.RitualTime = 9
C.Cooldown = 180
C.FailCooldown = 25
C.Uses = 2
C.LiftHeight = 34

C.GuiltMax = 120
C.GuiltMin = -70
C.GuiltDefault = 100
C.VictimThreshold = 45
C.PunisherMinimum = 70
C.RewardCeiling = 110
C.RepeatWindow = 900
C.RepeatDecay = 0.5
C.RewardMin = 1.5
C.RewardMax = 5
C.RewardRoundLimit = 8
C.RewardDecay = 0.7
C.StreakForget = 1800
C.FailPenalty = 3

C.ColorDeep = Color(96, 6, 20)
C.ColorRing = Color(122, 10, 26)
C.ColorBright = Color(178, 22, 40)
C.ColorGlow = Color(150, 14, 30)

C.Prefix = "[Крест] "

function C.Clamp(value)
	return math.Clamp(tonumber(value) or C.GuiltDefault, C.GuiltMin, C.GuiltMax)
end

function C.ResolvePlayer(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent end
	if ent.organism and ent.organism.fakePlayer and IsValid(ent.organism.fakePlayer) then return ent.organism.fakePlayer end
	if hg and isfunction(hg.RagdollOwner) then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end
	if hg and isfunction(hg.GetCurrentCharacter) then
		local char = hg.GetCurrentCharacter(ent)
		if IsValid(char) and char:IsPlayer() then return char end
	end
	return nil
end

function C.GetGuilt(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return C.GuiltDefault end
	local value = tonumber(ply.Sovest)
	if value == nil and isfunction(ply.guilt_GetValue) then value = tonumber(ply:guilt_GetValue()) end
	if value == nil and isfunction(ply.GetNetVar) then value = tonumber(ply:GetNetVar("Sovest", nil)) end
	if value == nil and isfunction(ply.GetNetVar) then value = tonumber(ply:GetNetVar("Karma", nil)) end
	if value == nil and isfunction(ply.GetNWFloat) then value = tonumber(ply:GetNWFloat("Sovest", C.GuiltDefault)) end
	return C.Clamp(value)
end

function C.Depth(value)
	local span = math.max(C.VictimThreshold - C.GuiltMin, 1)
	return math.Clamp((C.VictimThreshold - value) / span, 0, 1)
end

if CLIENT then return end

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
	local count = C.RepeatCount(punisher, victim)
	punisher.CrucifixGuiltHistory[key] = { count = count + 1, time = CurTime() }
end

function C.CalculateReward(punisher, victim, guilt)
	if not IsValid(punisher) then return 0 end
	local own = C.GetGuilt(punisher)
	if own >= C.RewardCeiling then return 0 end
	if own < C.PunisherMinimum then return 0 end

	local base = Lerp(C.Depth(guilt), C.RewardMin, C.RewardMax)
	base = base * (C.RewardDecay ^ math.max(tonumber(punisher.CrucifixGuiltStreak) or 0, 0))
	base = base * (C.RepeatDecay ^ C.RepeatCount(punisher, victim))

	local given = math.max(tonumber(punisher.CrucifixGuiltGiven) or 0, 0)
	local left = math.max(C.RewardRoundLimit - given, 0)
	local ceiling = math.max(C.RewardCeiling - own, 0)

	return math.Round(math.min(base, left, ceiling), 2)
end

function C.CanPunish(punisher, victim)
	if not IsValid(punisher) or not punisher:IsPlayer() then return false, "Крест не в руках человека." end
	if not IsValid(victim) or not victim:IsPlayer() then return false, "Крест не чувствует здесь души." end
	if victim == punisher then return false, "Крест не судит своего носителя." end
	if not victim:Alive() then return false, "Этот человек уже мёртв." end
	if IsValid(victim.CrucifixGuiltRitual) then return false, "Над этим человеком уже идёт суд." end
	if IsValid(punisher.CrucifixGuiltRitual) then return false, "Ты уже ведёшь суд." end

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

	punisher.CrucifixGuiltGiven = (tonumber(punisher.CrucifixGuiltGiven) or 0) + reward
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

hook.Add("PlayerDisconnected", "CrucifixGuiltCleanup", function(ply)
	if IsValid(ply.CrucifixGuiltRitual) then ply.CrucifixGuiltRitual:Cancel(true) end
end)

hook.Add("EntityTakeDamage", "CrucifixGuiltProtectRitual", function(target, dmginfo)
	if not IsValid(target) or not target:IsPlayer() then return end
	local ritual = target.CrucifixGuiltRitual
	if not IsValid(ritual) then return end
	if ritual:GetVictim() ~= target then return end
	if dmginfo:GetAttacker() == ritual then return end
	dmginfo:ScaleDamage(0)
	return true
end)
