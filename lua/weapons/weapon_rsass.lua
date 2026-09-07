SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "RSASS"
SWEP.Author = "Knight's Armament Company"
SWEP.Instructions = "Semi-automatic Marksman rifle chambered in 7.62x51 NATO"
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_svd.mdl"
--models/weapons/v_sr25_eft.mdl
SWEP.WorldModelFake = "models/weapons/rsass/c_rsass.mdl"

SWEP.FakePos = Vector(-12, 3.7, 6.5)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(14.8,0.2,-0.05)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"

SWEP.EjectPos = Vector(3,5,-18)



SWEP.FakeReloadSounds = {
	[0.25] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.3] = "weapons/m4a1/m4a1_magout.wav",
	[0.8] = "weapons/m4a1/m4a1_magain.wav",
}

SWEP.FakeEmptyReloadSounds = {
	[0.22] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.25] = "weapons/m4a1/m4a1_magout.wav",
	[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.65] = "weapons/m4a1/m4a1_magain.wav",
	[0.89] = "weapons/m4a1/m4a1_boltarelease.wav",
}
SWEP.MagModel = "models/kali/weapons/10rd m14 magazine.mdl"

SWEP.FakeMagDropBone = "4"

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(0,0.3,0)
SWEP.lmagang2 = Angle(0,0,0)

local vector_full = Vector(1,1,1)
local vecPochtiZero = Vector(0.01,0.01,0.01)
if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.25] = function( self, timeMul )
			if self:Clip1() < 1 then
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 1.1 * timeMul)
			end
		end,
		[0.3] = function( self, timeMul )
			if self:Clip1() < 1 then
				hg.CreateMag( self, Vector(0,0,-50), "111111")
				self:GetWM():ManipulateBoneScale(56, vecPochtiZero)

			end 
		end,
		[0.4] = function( self, timeMul )
			if self:Clip1() < 1 then

				self:GetWM():ManipulateBoneScale(56, vector_full)
			end
		end,
	}
end

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload0",
	["reload_empty"] = "reload_empty0_0",
}

SWEP.ScrappersSlot = "Primary"
SWEP.WepSelectIcon2 = Material("entities/arc9_eft_rsass.png")
SWEP.IconOverride = "entities/arc9_eft_rsass.png"
SWEP.weight = 3.5
SWEP.weaponInvCategory = 1
SWEP.CustomShell = "762x51"
--SWEP.EjectPos = Vector(-2,0,4)
--SWEP.EjectAng = Angle(0,0,0)
SWEP.AutomaticDraw = true
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "7.62x51 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Force = 65
SWEP.Primary.Sound = {"weapons/rsass/rsass_fire_close5.ogg", 65, 90, 100}
SWEP.SupressedSound = {"weapons/rsass/rsass_close_silenced1.ogg", 65, 90, 100}
SWEP.availableAttachments = {
	sight = {
		["mountType"] = {"picatinny", "ironsight"},
		["mount"] = {ironsight = Vector(-27, 1.26, 0.04), picatinny = Vector(-26.5, 1.28, 0.05)}
	},
	barrel = {
		[1] = {"supressor7", Vector(-5, 0, 0), {}},
		["mount"] = Vector(4.5,-0.1,0),
	},
	underbarrel = {
		["mount"] = {["picatinny"] = Vector(4,0.25,0)},
		["mountAngle"] = {["picatinny"] = Angle(0, 0, 0)},
		["mountType"] = {"picatinny"},
		["removehuy"] = {
			["picatinny"] = {
			}
		}
	},
	grip = {
		["mount"] = Vector(0,0.3,0.3),
		["mountType"] = "picatinny"
	},
}

SWEP.LocalMuzzlePos = Vector(31.2,-0.58,3.4)
SWEP.LocalMuzzleAng = Angle(0,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.PPSMuzzleEffect = "muzzleflash_SR25" -- shared in sh_effects.lua

SWEP.ShockMultiplier = 2

SWEP.handsAng = Angle(0, 0, 0)
SWEP.handsAng2 = Angle(-1, -0.5, 0)

SWEP.Primary.Wait = 0.1
SWEP.NumBullet = 1
SWEP.AnimShootMul = .5
SWEP.AnimShootHandMul = 10.5
SWEP.ReloadTime = 3.7
SWEP.ReloadSoundes = {
	"none",
	"none",
	"none",
	"none",
	"pwb2/weapons/m4a1/ru-556 clip out 1.wav",
	"none",
	"none",
	"pwb2/weapons/m4a1/ru-556 clip in 2.wav",
	"none",
	"none",
	"pwb2/weapons/m4a1/ru-556 bolt back.wav",
	"pwb2/weapons/m4a1/ru-556 bolt forward.wav",
	"none",
	"none",
	"none",
	"none"
}
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-3, -0.58, 5.4)
SWEP.RHandPos = Vector(-8, -2, 6)
SWEP.LHandPos = Vector(6, -3, 1)
SWEP.AimHands = Vector(-10, 1.8, -6.1)
SWEP.SprayRand = {Angle(-0.03, -0.04, 0), Angle(-0.05, 0.04, 0)}
SWEP.Ergonomics = 0.9
SWEP.Penetration = 15
SWEP.ZoomFOV = 20
SWEP.WorldPos = Vector(5, -1.2, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.handsAng = Angle(4, -2, 0)
SWEP.scopemat = Material("decals/scope.png")
SWEP.perekrestie = Material("decals/perekrestie8.png", "smooth")
SWEP.localScopePos = Vector(-21, 3.95, -0.2)
SWEP.scope_blackout = 400
SWEP.maxzoom = 3.5
SWEP.rot = 37
SWEP.FOVMin = 3.5
SWEP.FOVMax = 10
SWEP.huyRotate = 25
SWEP.FOVScoped = 40

SWEP.addSprayMul = 1
SWEP.cameraShakeMul = 2

SWEP.ShootAnimMul = 5

function SWEP:AnimHoldPost()
	--self:BoneSet("l_finger0", Vector(0, 0, 0), Angle(0, -20, 40))
	--self:BoneSet("l_finger02", Vector(0, 0, 0), Angle(0, 25, 0))
	--self:BoneSet("l_finger1", Vector(0, 0, 0), Angle(0, -5, 0))
	--self:BoneSet("l_finger2", Vector(0, 0, 0), Angle(0, -5, 0))
end

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,self:Clip1() > 0 and 0 or 0)
		wep:ManipulateBonePosition(54,Vector(0 ,1.8*self.shooanim ,0 ),false)
		--wep:ManipulateBonePosition(7,Vector(-1*self.ReloadSlideOffset ,0.09*self.ReloadSlideOffset ,-(0.18/3)*self.ReloadSlideOffset ),false)
	end
end

SWEP.StartAtt = {"ironsight1"}


SWEP.lengthSub = 15


--local to head
SWEP.RHPos = Vector(2,-6.5,3.5)
SWEP.RHAng = Angle(0,-12,90)
--local to rh
SWEP.LHPos = Vector(16,1.9,-3.2)
SWEP.LHAng = Angle(-110,-180,0)

-- RELOAD ANIM SR25/AR15
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(-2,2,-10),
	Vector(-2,2,-11),
	Vector(-2,3,-11),
	Vector(-2,7,-13),
	Vector(-8,15,-25),
	Vector(-15,5,-25),
	Vector(-5,5,-25),
	Vector(-2,4,-11),
	Vector(-2,2,-11),
	Vector(-2,2,-11),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	"fastreload",
	Vector(-3,1,-3),
	Vector(-3,2,-3),
	Vector(-3,3,-3),
	Vector(-9,3,-3),
	Vector(-9,3,-3),
	Vector(0,3,-3),
	"reloadend",
	Vector(0,0,0),
	Vector(0,0,0),
}

SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(-60,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(0,0,95),
	Angle(0,0,60),
	Angle(0,0,30),
	Angle(0,0,2),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
}

SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(-15,25,-15),
	Angle(-15,25,-25),
	Angle(5,28,-25),
	Angle(5,25,-25),
	Angle(1,24,-22),
	Angle(2,25,-21),
	Angle(-5,24,-22),
	Angle(1,25,-21),
	Angle(0,24,-22),
	Angle(1,25,-32),
	Angle(-5,24,-25),
	Angle(0,25,-26),
	Angle(0,0,2),
	Angle(0,0,0),
}

SWEP.ReloadSlideAnim = {
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	4,
	4,
	4,
	0,
	0,
	0,
	0
}

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