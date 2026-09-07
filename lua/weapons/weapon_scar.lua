SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Scar-H"
SWEP.Author = "Manufactured by FN Herstal in Belgium."
SWEP.Instructions = "Battle rifle chambered in 7.62×51mm NATO.\nPowerful modern rifle with strong stopping power and good accuracy at medium to long range."
SWEP.Category = "Weapons - Assault Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/zcity/akpack/w_akm.mdl"
SWEP.WorldModelFake = "models/weapons/scar/c_uc_myt_scar.mdl" -- МОДЕЛЬ ГОВНА, НАЙТИ НОРМАЛЬНЫЙ КАЛАШ
--PrintBones(Entity(1):GetActiveWeapon():GetWM())
--uncomment for funny
SWEP.FakePos = Vector(-6, 3.9, 6.5)
SWEP.FakeAng = Angle(0, 0, -0)
SWEP.AttachmentPos = Vector(3,3,-26.8)
SWEP.AttachmentAng = Angle(0,-0.5,0)
SWEP.FakeAttachment = "1"
SWEP.FakeBodyGroups = "07C000401210000"

SWEP.FakeEjectBrassATT = "2"
//SWEP.MagIndex = 57
//MagazineSwap
--Entity(1):GetActiveWeapon():GetWM():AddLayeredSequence(Entity(1):GetActiveWeapon():GetWM():LookupSequence("delta_foregrip"),1)
SWEP.FakeViewBobBone = "CAM_Homefield"
SWEP.FakeReloadSounds = {
	[0.22] = "weapons/universal/uni_crawl_l_03.wav",
	[0.34] = "weapons/uc_osk/magout.ogg",
	[0.51] = "weapons/universal/uni_crawl_l_02.wav",
	[0.72] = "weapons/uc_osk/magin.ogg",
	[0.85] = "weapons/uc_osk/magtap.ogg",
	[0.91] = "weapons/universal/uni_crawl_l_03.wav",
	[0.99] = "weapons/universal/uni_crawl_l_04.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav"
}

SWEP.FakeEmptyReloadSounds = {
	[0.21] = "weapons/uc_osk/chpull.ogg",
	[0.22] = "weapons/universal/uni_crawl_l_03.wav",
	[0.24] = "weapons/uc_osk/magout.ogg",
	[0.4] = "weapons/ak74/ak74_magout_rattle.wav",
	[0.72] = "weapons/uc_osk/magin.ogg",
	--[0.75] = "weapons/universal/uni_crawl_l_05.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav",
	[0.89] = "weapons/uc_osk/magtap.ogg",
	[0.9] = "weapons/uc_osk/bolt1.wav",
	--[1.01] = "weapons/universal/uni_crawl_l_04.wav",
}

SWEP.MagModel = "models/weapons/arc9/darsu_eft/mods/mag_stanag_magpul_pmag_gen_m3_556x45_10.mdl"
SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(0,0,1)
SWEP.lmagang2 = Angle(90,0,-90)

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 70
SWEP.FakeMagDropBone = 57

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty",
}

local vector_full = Vector(1,1,1)

function SWEP:RevertMag()
	local wm = self:GetWM()

	if IsValid(wm) and wm:GetManipulateBoneScale(55):IsEqualTol(vector_origin, 0.1) then
		wm:ManipulateBoneScale(55, vector_full)
		wm:ManipulateBoneScale(56, vector_full)
		wm:ManipulateBoneScale(57, vector_origin)
		wm:ManipulateBoneScale(58, vector_origin)
	end
end

if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.15] = function( self, timeMul )
			local wm = self:GetWM()
			wm:ManipulateBoneScale(55, vector_origin)
			wm:ManipulateBoneScale(56, vector_origin)
			wm:ManipulateBoneScale(57, vector_full)
			wm:ManipulateBoneScale(58, vector_full)
		end,
		[0.16] = function( self, timeMul )
			self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 0.58 * timeMul)
		end,
		[0.27] = function( self, timeMul )
			local wm = self:GetWM()
			wm:ManipulateBoneScale(55, vector_full)
			wm:ManipulateBoneScale(56, vector_full)
			wm:ManipulateBoneScale(58, vector_full)
			wm:ManipulateBoneScale(57, vector_full)
		end,
		
		[0.40] = function(self,timeMul)
			if self:Clip1() < 1 then
				hg.CreateMag( self, Vector(50,10,10),nil,true )
				self:GetWM():ManipulateBoneScale(57, vector_origin)
				self:GetWM():ManipulateBoneScale(58, vector_origin)
				--self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 0.5 * timeMul)
			end
		end,
		[0.85] = function(self,timeMul)
			self:GetWM():ManipulateBoneScale(57, vector_origin)
			self:GetWM():ManipulateBoneScale(58, vector_origin)
		end
	}
end

function SWEP:ModelCreated(model)
	if CLIENT and self:GetWM() then
		self:GetWM():ManipulateBoneScale(57, vector_origin)
		self:GetWM():ManipulateBoneScale(58, vector_origin)
		self:GetWM():SetBodyGroups(self.FakeBodyGroups)
	end
end

--function SWEP:PostFireBullet() --- Funny
	--self:PlayAnim("fire", 1, false)
--end

SWEP.GunCamPos = Vector(4,-15,-6)
SWEP.GunCamAng = Angle(190,-5,-100)

SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.weaponInvCategory = 1
SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "7.62x51 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 50
SWEP.ShockMultiplier = 2
SWEP.Primary.Sound = {"weapons/uc_osk/fire-01.ogg", 85, 90, 100}
SWEP.SupressedSound = {"weapons/uc_osk/fire-sup-01.ogg", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"weapons/uc_osk/dryfire.ogg", 75, 100, 105, CHAN_WEAPON, 2}

--SWEP.EjectPos = Vector(1,4,3.5)
--SWEP.EjectAng = Angle(0,-90,0)

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_scarh.png")
SWEP.IconOverride = "entities/arc9_eft_scarh.png"
SWEP.ScrappersSlot = "Primary"
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor2", Vector(0,0,0), {}},
		[2] = {"supressor6", Vector(0,0,0), {}},
		["mount"] = Vector(-6,-0.1,0),
		["mountAngle"] = {["picatinny"] = Angle(0, 1.5, 0)},
	},
	sight = {
		["mount"] = { ironsight = Vector(-22.5, 1.28, -0.2), picatinny = Vector(-21, 1.51, -0.15)},
		["mountType"] = {"picatinny", "ironsight"},
		["empty"] = {
			"empty",
		},
	},
	grip = {
		["mount"] = { ["picatinny"] = Vector(5,-0.2,0) },
		["mountType"] = {"picatinny"},
		["mountAngle"] = {["picatinny"] = Angle(0, 1.5, 0)}
	},
	underbarrel = {
		["mount"] = {["picatinny_small"] = Vector(2, -1, 0),["picatinny"] = Vector(3,0.2,-0.05)},
		["mountAngle"] = {["picatinny_small"] = Angle(0.9, 1, 0),["picatinny"] = Angle(0, 1.5, 0)},
		["mountType"] = {"picatinny_small","picatinny"},
		["removehuy"] = {
			["picatinny"] = {
			},
			["picatinny_small"] = {
			}
		}
	},
}

SWEP.StartAtt = {"ironsight5"}

SWEP.Primary.Wait = 0.11
SWEP.ReloadTime = 5.5
SWEP.ReloadSoundes = {
	"none",
	"none",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magout.wav",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magin.wav",
	"none",
	"weapons/tfa_ins2/ak103/ak103_boltback.wav",
	"weapons/tfa_ins2/ak103/ak103_boltrelease.wav",
	"none",
	"none",
	"none"
}

SWEP.LocalMuzzlePos = Vector(21.4,-0.1,2.1)
SWEP.LocalMuzzleAng = Angle(0,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.PPSMuzzleEffect = "pcf_jack_mf_mrifle1" -- shared in sh_effects.lua

SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -0.19, 5)

SWEP.RHandPos = Vector(-12, -1, 4)
SWEP.LHandPos = Vector(7, -3, -2)
SWEP.Spray = {}
for i = 1, 30 do
	SWEP.Spray[i] = Angle(-0.02 - math.cos(i) * 0.03, math.cos(i * i) * 0.02, 0) * 2
end

SWEP.Ergonomics = 1
SWEP.HaveModel = "models/pwb/weapons/w_akm.mdl"
--SWEP.ShellEject = "EjectBrass_338Mag"
SWEP.CustomShell = "762x51"

SWEP.Penetration = 15
SWEP.WorldPos = Vector(5, -1, -1.5)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
--https://youtu.be/I7TUHPn_W8c?list=RDEMAfyWQ8p5xUzfAWa3B6zoJg
SWEP.attPos = Vector(0.2, -2.6, 27)
SWEP.attAng = Angle(-0, 0.3, 0)
SWEP.lengthSub = 20
SWEP.handsAng = Angle(3, -1, 0)
SWEP.AimHands = Vector(-4, 0.5, -4)
SWEP.DistSound = "ak74/ak74_dist.wav"

SWEP.weight = 4

--local to head
SWEP.RHPos = Vector(3,-6.5,3.5)
SWEP.RHAng = Angle(0,-8,90)
--local to rh
SWEP.LHPos = Vector(15,1.5,-3.5)
SWEP.LHAng = Angle(-110,-180,0)

SWEP.ShootAnimMul = 7

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = Lerp(FrameTime()*15,self.shooanim or 0,self.ReloadSlideOffset)
		vec[1] = 0*self.shooanim
		vec[2] = 1*self.shooanim
		vec[3] = 0*self.shooanim
		wep:ManipulateBonePosition(8,vec,false)
	end
end
local lfang4 = Angle(0,70,0)
local lfang3 = Angle(0,-25,0)
local lfang2 = Angle(0,46,0)
local lfang1 = Angle(0,-30,0)
local lfang0 = Angle(0,-7,0)
local vec_zero = Vector(0,0,0)
local l_finger02 = Angle(-10,0,0)
function SWEP:AnimHoldPost()

end

-- RELOAD ANIM AKM
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(-1.5,1.5,-8),
	Vector(-1.5,1.5,-8),
	Vector(-1.5,1.5,-8),
	Vector(-1,7,-3),
	Vector(-7,15,-15),
	Vector(-7,15,-15),
	Vector(-1,7,-3),
	Vector(-1.5,1.5,-8),
	Vector(-1.5,1.5,-8),
	Vector(-1.5,1.5,-8),
	"fastreload",
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
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,2),
	Vector(8,1,2),
	Vector(8,2.5,-2),
	Vector(7,2.5,-2),
	Vector(6,2.5,-2),
	Vector(3,2.5,-2),
	Vector(3,2.5,-1),
	Vector(0,4,-1),
	"reloadend",
	Vector(0,5,0),
	Vector(-2,2,1),
	Vector(0,0,0),
}

SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-80,0,110),
	Angle(-20,0,110),
	Angle(-30,0,110),
	Angle(-20,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-20,0,45),
	Angle(-2,0,-3),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(20,-10,-20),
	Angle(20,0,-20),
	Angle(20,0,-20),
	Angle(0,0,0),
}

SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(-15,15,17),
	Angle(-14,14,22),
	Angle(-10,15,24),
	Angle(12,14,23),
	Angle(11,15,20),
	Angle(12,14,19),
	Angle(11,14,20),
	Angle(7,9,21),
	Angle(0,14,-21),
	Angle(0,15,-22),
	Angle(0,18,-23),
	Angle(0,25,-22),
	Angle(-12,24,-25),
	Angle(-15,25,-23),
	-Angle(5,2,2),
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
	0,
	5,
	4.5,
	0,
	0,
	0,
	0
}

-- Inspect Assault

SWEP.InspectAnimLH = {
	Vector(0,0,0)
}
SWEP.InspectAnimLHAng = {
	Angle(0,0,0)
}
SWEP.InspectAnimRH = {
	Vector(0,0,0)
}
SWEP.InspectAnimRHAng = {
	Angle(0,0,0)
}
SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(15,15,15),
	Angle(15,15,24),
	Angle(15,15,24),
	Angle(15,15,24),
	Angle(15,7,24),
	Angle(10,3,-5),
	Angle(2,3,-15),
	Angle(0,4,-22),
	Angle(0,3,-45),
	Angle(0,3,-45),
	Angle(0,-2,-2),
	Angle(0,0,0)
}