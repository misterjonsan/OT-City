SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "MK18 Mjolnir"
SWEP.Author = "Colt’s Manufacturing Company"
SWEP.Instructions = "The M16 rifle is a family of assault rifles adapted from the ArmaLite AR-15 rifle for the United States military. Chambered in 5.56x45 mm"
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_svd.mdl"
SWEP.WorldModelFake = "models/weapons/mk18/c_mk18.mdl"

SWEP.FakePos = Vector(-13, 3.81, 6)
SWEP.FakeAng = Angle(0, 0, 0.1)
SWEP.AttachmentPos = Vector(0,1.65,-28)
SWEP.AttachmentAng = Angle(0,-0.4,0)
SWEP.FakeAttachment = "1"
SWEP.FakeBodyGroups = "0111112"
SWEP.ZoomPos = Vector(0, -0.46, 4.65)

SWEP.GunCamPos = Vector(4,-15,-6)
SWEP.GunCamAng = Angle(190,-5,-100)

SWEP.FakeEjectBrassATT = "2"

SWEP.FakeViewBobBone = "CAM_Homefield"
SWEP.FakeReloadSounds = {
	[0.22] = "weapons/universal/uni_crawl_l_03.wav",
	[0.32] = "weapons/mk18/mk18_magrelease_button.ogg",
	[0.34] = "weapons/mk18/mk18_mag_out.ogg",
	[0.38] = "weapons/g36/g36_mag_rattle1.ogg",
	[0.6] = "weapons/universal/uni_crawl_l_04.wav",
	[0.79] = "weapons/g36/g36_mag_rattle1.ogg",
	[0.82] = "weapons/mk18/mk18_mag_in.ogg",
	[0.99] = "weapons/universal/uni_crawl_l_04.wav",

}

SWEP.FakeEmptyReloadSounds = {

	[0.27] = "weapons/mk18/mk18_magrelease_button.ogg",
	[0.29] = "weapons/mk18/mk18_mag_out.ogg",
	[0.5] = "weapons/universal/uni_crawl_l_04.wav",
	[0.62] = "weapons/mk18/mk18_mag_in.ogg",
	[0.65] = "weapons/g36/g36_mag_rattle1.ogg",
	[0.89] = "weapons/mk18/p90_bolt_handle_grab.ogg",
	[0.91] = "weapons/mk18/mk18_bolt_out.ogg",
	[0.99] = "weapons/mk18/mk18_bolt_in.ogg",
	[1] = "weapons/mk18/mk18_bolt_catch.ogg",
	[1.03] = "weapons/universal/uni_crawl_l_04.wav",
}

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor9", Vector(0,0,0), {}},
		[2] = {"supressor11", Vector(0,0,0), {}},
		["mount"] = Vector(-1.6,0.4,0.18),
		["mountAngle"] = {["picatinny"] = Angle(0, 0, 0)},
	},
	sight = {
		["mountType"] = {"picatinny", "ironsight"},
		["mount"] = {ironsight = Vector(-26.5, 1.4, 0.01), picatinny = Vector(-27.5, 1.6, 0.01)}
	},
}

SWEP.StartAtt = {"ironsight5"}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 70

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty0_bolt",
}

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(3,9.5,-16.5)
SWEP.lmagang2 = Angle(0,0,-90)
SWEP.FakeMagDropBone = 52

SWEP.EjectPos = Vector(3,4.5,-16)
SWEP.EjectAng = Angle(0,0,0)

if CLIENT then
	local vector_full = Vector(1,1,1)
	SWEP.MagModel = "models/weapons/arccw/c_ud_m16.mdl"
	SWEP.FakeReloadEvents = {	
		[0.15] = function(self,timeMul)
			if self:Clip1() > 1 then
				self:GetWM():ManipulateBoneScale(52, vector_origin)
				self:GetWM():ManipulateBoneScale(55, vector_full)
			end
		end,

		[0.25] = function(self,timeMul)
			if self:Clip1() > 1 then
				self:GetWM():ManipulateBoneScale(52, vector_full)
				self:GetWM():ManipulateBoneScale(55, vector_full)
			end
		end,
		[0.30] = function(self,timeMul)
			if self:Clip1() < 1 then
				local ent = hg.CreateMag( self, Vector(0,0,-12), self.FakeBodyGroups or "0", true)
				for i = 0, ent:GetBoneCount() - 1 do
					ent:ManipulateBoneScale(i, vector_origin)
				end
				ent:ManipulateBoneScale(52, vector_full)
				ent:ManipulateBoneScale(55, vector_full)

				self:GetWM():ManipulateBoneScale(52, vector_origin)
				self:GetWM():ManipulateBoneScale(55, vector_origin)
				--self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 0.5 * timeMul)
			end
		end,
		[0.50] = function(self,timeMul)
			self:GetWM():ManipulateBoneScale(52, vector_full)
			if self:Clip1() < 1 then
				self:GetWM():ManipulateBoneScale(55, vector_origin)
			end
		end,
		[0.85] = function(self,timeMul)
			if self:Clip1() > 1 then
				self:GetWM():ManipulateBoneScale(55, vector_origin)
			end
		end
	}
end

function SWEP:ModelCreated(model)
	if CLIENT and self:GetWM() and not isbool(self:GetWM()) and isstring(self.FakeBodyGroups) then
		self:GetWM():ManipulateBoneScale(55, vector_origin)
		self:GetWM():SetBodyGroups(self.FakeBodyGroups)
	end
end

SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.BurstNum = 0


SWEP.weaponInvCategory = 1
SWEP.CustomEjectAngle = Angle(0, 0, 90)
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ".338 Lapua Magnum"

SWEP.CustomShell = ".338Lapua"


SWEP.ScrappersSlot = "Primary"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 35
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 35
SWEP.Primary.Sound = {"weapons/mk18/mk18_fire_close.ogg", 75, 120, 140}
SWEP.SupressedSound = {"weapons/mk18/mk18_fire_silenced_close.ogg", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/ak74/handling/ak74_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.3
SWEP.ReloadTime = 4
SWEP.ReloadSoundes = {
	"none",
	"none",
	"weapons/tfa_ins2/akp/ak47/ak47_magout.wav",
	"none",
	"weapons/tfa_ins2/akp/ak47/ak47_magin.wav",
	"weapons/tfa_ins2/akp/aks74u/aks_boltback.wav",
	"weapons/tfa_ins2/akp/aks74u/aks_boltrelease.wav",
	"none",
	"none",
	"none"
}

SWEP.PPSMuzzleEffect = "pcf_jack_mf_mrifle2" -- shared in sh_effects.lua

SWEP.LocalMuzzlePos = Vector(30.5,-0.43,2.73)
SWEP.LocalMuzzleAng = Angle(0.2,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.HoldType = "rpg"

SWEP.RHandPos = Vector(-12, -1, 4)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.Penetration = 11
SWEP.Spray = {}
for i = 1, 30 do
	SWEP.Spray[i] = Angle(-0.01 - math.cos(i) * 0.02, math.cos(i * i) * 0.02, 0) * 0.5
end

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_mk18_mjolnir.png")
SWEP.WepSelectIcon2box = false
SWEP.IconOverride = "entities/arc9_eft_mk18_mjolnir.png"

SWEP.Ergonomics = 1
SWEP.WorldPos = Vector(5, -0.8, -1.1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0.25, -2.1, 28)
SWEP.attAng = Angle(0, 0.4, 0)
SWEP.lengthSub = 25
SWEP.handsAng = Angle(1, -1.5, 0)
SWEP.DistSound = "weapons/mk18/mk18_fire_distant.ogg"



SWEP.weight = 6.5

--local to head
SWEP.RHPos = Vector(3,-6,3.5)
SWEP.RHAng = Angle(0,-12,90)
--local to rh
SWEP.LHPos = Vector(15,1,-3.3)
SWEP.LHAng = Angle(-110,-180,0)

local finger1 = Angle(25,0, 40)

SWEP.ShootAnimMul = 0
function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = Lerp(FrameTime()*15,self.shooanim or 0,self.ReloadSlideOffset)
		vec[1] = 0 * self.shooanim
		vec[2] = 0 * self.shooanim
		vec[3] = -2 * self.shooanim
		wep:ManipulateBonePosition(46,vec,false)
	end
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