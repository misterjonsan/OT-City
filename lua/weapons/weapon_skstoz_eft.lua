-- "addons\\homigrad-weapons\\lua\\weapons\\weapon_remington870.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
--ents.Reg(nil,"weapon_m4super")
SWEP.Base = "weapon_m4super"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "TOZ SKS"
SWEP.Author = "Originally designed by Sergei Simonov and produced in the Soviet Union"
SWEP.Instructions = "Semi-automatic carbine chambered in 7.62×39mm.\nSimple and reliable rifle with an internal magazine."
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_k98.mdl" --"models/weapons/zcity/gleb/w_kar98k.mdl"
SWEP.WorldModelFake = "models/weapons/tozsks/c_sks.mdl"
SWEP.FakeScale = 1
//PrintAnims(Entity(1):GetActiveWeapon():GetWM())
--PrintTable(Entity(1):GetActiveWeapon():GetWM():GetAttachments())
--uncomment for funny
SWEP.FakePos = Vector(-8, 3.6, 6.1)
SWEP.FakeAng = Angle(-0.1, 0, 0)
//SWEP.MagIndex = 41
SWEP.FakeAttachment = "1"
SWEP.AttachmentPos = Vector(-8.5,0,0)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeBodyGroups = "000000000"
SWEP.BarrelLength = 40
SWEP.SUPBarrelLenght = 47
SWEP.OpenBolt = false
SWEP.CantFireFromCollision = false // 2 спусковых крючка все дела

SWEP.FakeViewBobBone = "ValveBiped.Bip01_L_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 30

--SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.WepSelectIcon2 = Material("vgui/hud/tfa_ins2_sks")
SWEP.IconOverride = "entities/tfa_ins2_sks.png"

SWEP.LocalMuzzlePos = Vector(32.739, -0.6, 3.6)
SWEP.LocalMuzzleAng = Angle(0,-0.0,0)
SWEP.WeaponEyeAngles = Angle(-0.7,0.1,0)

SWEP.CustomShell = "762x39"
--SWEP.EjectPos = Vector(-0,8,4)
--SWEP.EjectAng = Angle(0,-90,0)
SWEP.ReloadSound = "weapons/tfa_ins2/k98/m40a1_boltlatch.wav"
SWEP.DistSound = "mosin/mosin_dist.wav"
SWEP.weight = 4
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.ShellEject = "RifleShellEject"
SWEP.AutomaticDraw = true
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "7.62x39 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Force = 45
SWEP.Primary.Sound = {"weapons/tfa_ins2/ak103/ak103_fp.wav", 65, 90, 100}
SWEP.SupressedSound = {"weapons/tfa_ins2/ak103/ak103_suppressed_fp.wav", 65, 90, 100}
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor1", Vector(0,0,0), {}},
		[2] = {"supressor6", Vector(0,0,0), {}},
		["mount"] = Vector(8,0.7,0.1),
	},
	sight = {
		["mountType"] = {"picatinny", "dovetail"},
		["mount"] = {["dovetail"] = Vector(-17.1, 1.8, -0.5),["picatinny"] = Vector(-19.1, 2.65, -0.22)},
	},
	mount = {
		["picatinny"] = {
			"mount3",
			Vector(-15.8, 0, -1.3),
			{},
			["mountType"] = "picatinny",
		},
		["dovetail"] = {
			"empty",
			Vector(0, 0, 0),
			{},
			["mountType"] = "dovetail",
		},
	},
}

SWEP.Primary.Wait = 0.15
SWEP.NumBullet = 1
SWEP.AnimShootMul = 1
SWEP.AnimShootHandMul = 5
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -0.572, 4.95)
SWEP.RHandPos = Vector(0, 0, -1)
SWEP.LHandPos = Vector(7, 0, -2)
SWEP.Ergonomics = 0.9
SWEP.Penetration = 7
SWEP.WorldPos = Vector(0.2, -0.5, 0)
SWEP.WorldAng = Angle(0.7, -0.1, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0.4, -0.15, 0)
SWEP.attAng = Angle(0, 0.2, 0)
SWEP.lengthSub = 20

SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(7, 8, -8)
SWEP.holsteredAng = Angle(210, 0, 180)

--local to head
--SWEP.RHPos = Vector(1,-5,3.4)
--SWEP.RHAng = Angle(0,-15,90)
----local to rh
--SWEP.LHPos = Vector(18,-0.8,-3.6)
--SWEP.LHAng = Angle(-100,-180,0)

SWEP.AnimList = {
	["idle"] = "base_idle",
	["reload"] = "base_Fire_end",
	["reload_empty"] = "base_Fire_end",
	["finish_empty"] = "sgreload_end",
	["finish"] = "sgreload_end",
	["insert"] = "sgreload_insert",
	["start"] = "sgreload_start",
}
local math = math
local math_random = math.random
SWEP.AnimsEvents = {
	["sgreload_start"] = {
		[0.3] = function(self)
			self:EmitSound("weapons/tfa_ins2/k98/m40a1_boltback.wav", 45, math_random(95, 105))
		end,
	},
	["sgreload_insert"] = {
		[0.1] = function(self)
			self:EmitSound("weapons/tfa_ins2/k98/mosin_bulletin_"..math_random(1,4)..".wav", 45, math_random(95, 105))
		end,
	},
	["sgreload_end"] = {
		[0.2] = function(self)
			self:EmitSound("weapons/tfa_ins2/k98/m40a1_boltforward.wav", 45, math_random(95, 105))
		end,
		[0.5] = function(self)
			self:EmitSound("weapons/tfa_ins2/k98/m40a1_boltlatch.wav", 45, math_random(95, 105))
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
		self:Draw(true)
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
	--if CLIENT then self:PlaySnd(self.CockSound or "snd_jack_hmcd_boltcycle.wav",true,CHAN_AUTO) end

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
		--self:GetOwner():ChatPrint(tostring(self.drawBullet))
		--self:PlaySnd(self.CockSound or "weapons/shotgun/shotgun_cock.wav",true,CHAN_AUTO)
		if !self.drawBullet then
			cock(self,1)
			self:PlayAnim(self.AnimList["finish_empty"] or "base_Fire_end", 1, false, function(self) self:SetNetVar("shootgunReload", 0) end, false, true) 
		else
			self:PlayAnim(self.AnimList["finish"] or "reload_end", 1, false, function(self) self:SetNetVar("shootgunReload", 0) end, false, true) 
		end
	end, false, true)
end

SWEP.FakeEjectBrassATT = "2"

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
		cock(self,1.5)
		self:SetNetVar("shootgunReload",CurTime() + 1.3)
		self:PlayAnim(self.AnimList["cycle"] or "cycle", 1.5, false, nil, false, true)
		return
	end

	if not self:CanReload() then return end

	if SERVER then
		self:SetNetVar("shootgunReload",CurTime() + 1.1)
		self:PlayAnim(self.AnimList["start"] or "Reload_Start",1,false,function() 
			reloadFunc(self)
		end,
		false,true)
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