CRUCIFIX_GUILT = CRUCIFIX_GUILT or {}

local C = CRUCIFIX_GUILT

C.Model = "models/doors/crucifix.mdl"
C.SoundRitual = "doors/crucifix.wav"
C.SoundFail = "doors/crucifix_fail.wav"
C.SoundJudge = "doors/Hallelujah.ogg"
C.SoundScream = "doors/AmbushCrucifix.mp3"

C.Distance = 260
C.RitualTime = 9
C.Cooldown = 180
C.FailCooldown = 25
C.Uses = 2
C.LiftHeight = 34
C.SpinBase = 45
C.SpinPeak = 2200
C.SpinCurve = 3.2
C.CircleRadius = 65
C.CircleSize = 147.2
C.CylinderHeight = 24
C.CylinderRadius = 72.5
C.CylinderSides = 32
C.ChainSegments = 14
C.ChainWidth = 17
C.ChainGlowWidth = 40
C.ChainAlphaNear = 255
C.ChainAlphaFar = 150
C.ChainCount = 8
C.ShakeRadius = 1100
C.ShakeBase = 3
C.ShakePeak = 18
C.ShakeFinal = 34
C.ShakeFrequency = 95
C.ShakeTick = 0.05
C.ShakeFalloff = 0.85
C.PunchScale = 0.085
C.PunchRoll = 0.6
C.PropRadius = 700
C.PropForce = 45
C.PropMassLimit = 250
C.PropLimit = 24

C.CorpseSearch = 260
C.CorpseWait = 6
C.SinkDelay = 1.1
C.SinkTick = 0.04
C.SinkSpeed = 7
C.SinkAccel = 13
C.SinkDepth = 110
C.SinkFade = 0.75

C.GuiltMax = 120
C.GuiltMin = -70
C.GuiltDefault = 100
C.VictimThreshold = 45
C.WielderMinimum = 95
C.PunisherMinimum = 95
C.RewardCeiling = 118
C.RepeatWindow = 900
C.RepeatDecay = 0.5
C.RewardMin = 3
C.RewardMax = 8
C.RewardRoundLimit = 12
C.RewardDecay = 0.75
C.StreakForget = 1800
C.FailPenalty = 3

C.RequiredProfession = "exorcist"
C.RequiredProfessionTitle = "Экзорцист"
C.RejectBurnTime = 6
C.RejectDamage = 12
C.RejectCooldown = 2
C.LeashDistance = 420
C.BreakDamage = 1
C.BreakRefund = true

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

function C.GetProfession(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return "" end
	local prof = ply.Profession
	if not isstring(prof) or prof == "" then
		prof = isfunction(ply.GetNWString) and ply:GetNWString("HMCD_CurrentProfession", "") or ""
	end
	if not isstring(prof) then return "" end
	return string.lower(string.Trim(prof))
end

function C.IsPriest(ply)
	return C.GetProfession(ply) == C.RequiredProfession
end

function C.Depth(value)
	local span = math.max(C.VictimThreshold - C.GuiltMin, 1)
	return math.Clamp((C.VictimThreshold - value) / span, 0, 1)
end

SWEP.PrintName = "Крест совести"
SWEP.Author = "OT-CITY"
SWEP.Purpose = "Карать тех, чья совесть мертва"
SWEP.Instructions = "ЛКМ — суд над человеком с низкой совестью. ПКМ — состояние креста"
SWEP.Category = "OT-CITY"
SWEP.CrucifixGuilt = true

SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Damage = 0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.Weight = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.FiresUnderwater = true
SWEP.CSMuzzleFlashes = false

SWEP.HoldType = "pistol"
SWEP.ViewModelFOV = 75
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"
SWEP.WorldModel = C.Model
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false

SWEP.HandBone = "ValveBiped.Bip01_R_Hand"
SWEP.HandOffsetPos = Vector(4.4, -1.3, -2.5)
SWEP.HandOffsetAngle = Angle(176.667, 110, 14.444)
SWEP.HandScale = 0.5

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextRitual")
	self:NetworkVar("Int", 0, "UsesLeft")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	if SERVER then
		self:SetUsesLeft(C.Uses)
		self:SetNextRitual(0)
	end
	if CLIENT then
		self:BuildModel()
	end
end

function SWEP:GetHandMatrix()
	local owner = self:GetOwner()
	if not IsValid(owner) then return nil end

	local bone = owner:LookupBone(self.HandBone)
	if not bone then return nil end

	return owner:GetBoneMatrix(bone)
end
