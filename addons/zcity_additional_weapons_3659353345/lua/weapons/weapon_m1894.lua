-- каряк сделан барой.. пулл реквест до того как стал известен
SWEP.Base = "weapon_m4super"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "M1894"
SWEP.Author = "Mauser"
SWEP.Instructions = "Sniper rifle chambered in 357 magnum"
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/zcity/w_m98b.mdl"
SWEP.WorldModelFake = "models/weapons/m1894/c_shg50.mdl"
SWEP.FakeScale = 1

SWEP.FakePos = Vector(-4, 3.3, 11.1)
SWEP.FakeAng = Angle(1, -3, 0)

SWEP.FakeAttachment = "ui_muzzle"
SWEP.AttachmentPos = Vector(-0.5,3,0)
SWEP.AttachmentAng = Angle(1,87.7,87.9)
SWEP.FakeBodyGroups = "000000000"
SWEP.BarrelLength = 40
SWEP.SUPBarrelLenght = 47
SWEP.OpenBolt = false
SWEP.CantFireFromCollision = false // 2 спусковых крючка все дела

SWEP.FakeViewBobBone = "ValveBiped.Bip01_L_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 30


SWEP.FakeVPShouldUseHand = false

SWEP.WepSelectIcon2 = Material("entities/tfa_shg50.png")
SWEP.IconOverride = "entities/tfa_shg50.png"

SWEP.LocalMuzzlePos = Vector(18.339, 0.3, 9.4)
SWEP.LocalMuzzleAng = Angle(-2.3,-0.0,0)
SWEP.WeaponEyeAngles = Angle(-0.7,0.1,0)

SWEP.CustomShell = "10mm"

SWEP.ReloadSound = "weapons/tfa_ins2/k98/m40a1_boltlatch.wav"
SWEP.CockSound = "weapons/tfa_ins2/k98/m40a1_boltlatch.wav"
SWEP.DistSound = "mosin/mosin_dist.wav"
SWEP.weight = 2
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.ShellEject = false
SWEP.AutomaticDraw = false
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ".357 Magnum"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.Primary.Sound = {"weapons/m1894/shg50_fire_fp_01.wav", 80, 90, 100}
SWEP.SupressedSound = {"weapons/m1894/shg50_fire_fp_silencer_01.wav", 80, 90, 100}
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor3", Vector(9,0,0), {}},
		["mount"] = Vector(-14.4, 0.2, 0.63),
		["mountAngle"] = Angle(0, -1.5, 0),
	},
	sight = {
		["mountType"] = "picatinny",
		["mount"] = Vector(-13, 0.45, 0.69),
			
	}
}


SWEP.Primary.Wait = 0.25
SWEP.NumBullet = 1
SWEP.AnimShootMul = 3
SWEP.AnimShootHandMul = 10
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, 0.25, 10.1)
SWEP.RHandPos = Vector(0, 0, -1)
SWEP.LHandPos = Vector(7, 0, -2)
SWEP.Ergonomics = 1
SWEP.Penetration = 7
SWEP.WorldPos = Vector(2.2, -0.5, 5)
SWEP.WorldAng = Angle(0.7, -0.1, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0.4, -0.15, 0)
SWEP.attAng = Angle(0, 0.2, 0)
SWEP.lengthSub = 20

SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(0, 8, -8)
SWEP.holsteredAng = Angle(210, 0, 180)



SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "base_Fire_end",
	["reload_empty"] = "base_Fire_end",
	["finish_empty"] = "fire_bullets_right_01",
	["finish"] = "Reload_End",
	["insert"] = "reload_chamberempty_02",
	["start"] = "Reload_Start",
	["cycle"] = "fire_bullets_right_01",
}
local math = math
local math_random = math.random
SWEP.AnimsEvents = {
	["reload_chamberempty_02"] = {
		[0.1] = function(self)
			self:EmitSound("weapons/m1894/shg50_reload_01.wav", 45, math_random(95, 105))
		end,
	},
	["fire_bullets_right_01"] = {
		[0.3] = function(self)
			self:EmitSound("weapons/m1894/shg50_pump_fp_01_cockbk.wav", 45, math_random(95, 105))
		end,
		[0.6] = function(self)
			self:RejectShell(self.ShellEject)
			self:EmitSound("weapons/m1894/shg50_pump_fp_01_cockfwd.wav", 45, math_random(95, 105))
		end
	}
}

SWEP.stupidgun = false

function SWEP:InitializePost()
	self.AnimStart_Insert = 0
	self.AnimStart_Draw = 0
end

function SWEP:AnimationPost()
	local animpos = math.Clamp(self:GetAnimPos_Draw(CurTime()),0,1)
	local sin = 1 - animpos
	if sin >= 0.5 then
		sin = 1 - sin
	else
		sin = sin * 1
	end
	sin = sin * 2
	--sin = math.ease.InOutExpo(sin)
	sin = math.ease.InOutSine(sin)

	if sin > 0 then
		self.LHPos[1] = 18 - sin * 6
		self.RHPos[1] = 1 - sin * 4
		self.inanim = true
	else
		self.inanim = nil
	end

	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		wep:ManipulateBonePosition(4,Vector(0,0,sin * -3),false)
	end
end

function SWEP:GetAnimPos_Insert(time)
	return 0
end

function SWEP:GetAnimPos_Draw(time)
	return 0
end

local function cock(self,time)
	if SERVER then
		self:Draw(true, true)
	end

	if self:Clip1() == 0 then
		self.drawBullet = nil
	end

	if CLIENT and LocalPlayer() == self:GetOwner() then return end

	net.Start("hgwep draw")
		net.WriteEntity(self)
		net.WriteBool(self.drawBullet)
		net.WriteFloat(CurTime())
	net.Broadcast()

	self.Primary.Next = CurTime() + self.AnimDraw + self.Primary.Wait
	

	local ply = self:GetOwner()

	self.reloadCoolDown = CurTime() + time
end


SWEP.GunCamPos = Vector(6,-12,-5)
SWEP.GunCamAng = Angle(190,-5,-95)

local vector_full = Vector(1,1,1)

local function reloadFunc(self)
	if CLIENT then return end

	self:SetNetVar("shootgunReload",CurTime() + 1.1)

	if self.MagIndex then
		self:GetWM():ManipulateBoneScale(self.MagIndex, vector_full)
	end

	self:PlayAnim(self.AnimList["insert"] or "Reload_Insert", 1, false, function() 
		self:InsertAmmo(1) 
		if self.MagIndex then
			self:GetWM():ManipulateBoneScale(self.MagIndex, vector_origin)
		end

		local key = hg.KeyDown(self:GetOwner(), IN_RELOAD)
		--print("reload",key)

		if key and self:CanReload() then
			reloadFunc(self)
			return
		end

		if !self.drawBullet then
			cock(self,1)
			self:PlayAnim(self.AnimList["finish_empty"] or "base_Fire_end", 1, false, function(self) self:SetNetVar("shootgunReload", 0) end, false, true) 
		else
			self:PlayAnim(self.AnimList["finish"] or "reload_end", 1, false, function(self) self:SetNetVar("shootgunReload", 0) end, false, true) 
		end
	end, false, true)
end

SWEP.FakeEjectBrassATT = "shells"

function SWEP:Reload(time)
	--print(self:GetNetVar("shootgunReload",0))
	local ply = self:GetOwner()
	--if ply.organism and (ply.organism.larmamputated or ply.organism.rarmamputated) then return end
	if self.AnimStart_Draw > CurTime() - 0.5 then return end
	if not self:CanUse() then return end
	if self.reloadCoolDown > CurTime() then return end
	if self.Primary.Next > CurTime() then return end
	if self:GetNetVar("shootgunReload",0) > CurTime() then return end

	if self.drawBullet == false and SERVER then
		cock(self,0.4)
		self:SetNetVar("shootgunReload",CurTime() + 0.5)
		self:PlayAnim(self.AnimList["cycle"] or "cycle", 0.7, false, nil, false, true)
		return
	end

	if not self:CanReload() then return end

	if SERVER then
		self:SetNetVar("shootgunReload",CurTime() + 1.1)
		self:PlayAnim(self.AnimList["start"] or "Reload_Start",0,false,function() 
			reloadFunc(self)
		end,
		false,false)
	end
end

function SWEP:CanPrimaryAttack()
	return not (self:GetNetVar("shootgunReload",0) > CurTime())
end

-- Inspect Assault

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(4,4,15),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(-6,-15,-15),
	Angle(1,15,-45),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(0,0,0),
	Angle(0,0,0)
}