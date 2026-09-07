SWEP.Base = "weapon_m4super"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Orsis t-5000"
SWEP.Author = "Manufactured by ORSIS (Promtechnologii) in Russia."
SWEP.Instructions = "Bolt-action sniper rifle chambered in .338 Lapua Magnum.\nHigh-precision rifle designed for extreme long-range shooting."
SWEP.Category = "Weapons - Sniper Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_svd.mdl"
SWEP.WorldModelFake = "models/weapons/t-5000/c_t5000.mdl"
SWEP.FakeAttachment = "1"
SWEP.FakeBodyGroups = "110011111"
SWEP.FakeBodyGroupsPresets = {
	"110011111",
	"110012112",
	"110011110",
	"110012110",
	--"110020010",
	--"110030010",
}

SWEP.FakePos = Vector(-16, 4.7, 7)
SWEP.FakeAng = Angle(-0.2, 0, 0)
SWEP.AttachmentPos = Vector(-2,0.4,0.5)
SWEP.AttachmentAng = Angle(0,0,0)

SWEP.FakeReloadSounds = {
	[0.28] = "weapons/dvl10/dvl_magbutton.ogg",
	[0.3] = "weapons/dvl10/dvl_mag_out.ogg",
	[0.4] = "weapons/dvl10/backpack_drop_generic1.ogg",
	[0.6] = "weapons/dvl10/backpack_drop_generic2.ogg",
	[0.9] = "weapons/dvl10/dvl_mag_in.ogg",
}

SWEP.FakeEmptyReloadSounds = {
	[0.28] = "weapons/dvl10/dvl_magbutton.ogg",
	[0.3] = "weapons/dvl10/dvl_mag_out.ogg",
	[0.4] = "weapons/dvl10/backpack_drop_generic1.ogg",
	[0.6] = "weapons/dvl10/backpack_drop_generic2.ogg",
	[0.9] = "weapons/dvl10/dvl_mag_in.ogg",
}

local math = math
local math_random = math.random
SWEP.AnimsEvents = {
	["bolt0"] = {
		[0.1] = function(self)
			self:EmitSound("weapons/dvl10/dvl_bolt_1.ogg", 45, math_random(110, 115))
		end,
		[0.3] = function(self)
			self:EmitSound("weapons/dvl10/dvl_bolt_2.ogg", 45, math_random(110, 115))
		end,
		[0.5] = function(self)
			self:EmitSound("weapons/dvl10/dvl_bolt_3.ogg", 45, math_random(110, 115))
		end,
		[0.6] = function(self)
			self:EmitSound("weapons/dvl10/dvl_bolt_1.ogg", 45, math_random(110, 115))
		end
    }
}
SWEP.MagModel = "models/kali/weapons/10rd m14 magazine.mdl"

SWEP.FakeMagDropBone = "Magazine"

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(0,0.3,0)
SWEP.lmagang2 = Angle(0,0,0)

local vector_full = Vector(1,1,1)
local vecPochtiZero = Vector(0.01,0.01,0.01)
if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.35] = function( self, timeMul )
			if self:Clip1() < 1 then
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 1.1 * timeMul)//, self.MagModel, {self.lmagpos3, self.lmagang3, isnumber(self.FakeMagDropBone) and self.FakeMagDropBone or self:GetWM():LookupBone(self.FakeMagDropBone or "Magazine") or self:GetWM():LookupBone("ValveBiped.Bip01_L_Hand"), self.lmagpos2, self.lmagang2}, function(self)
				//	if IsValid(self) then
				//		self:GetWM():ManipulateBoneScale(75, vector_full)
				//		self:GetWM():ManipulateBoneScale(76, vector_full)
				//		self:GetWM():ManipulateBoneScale(77, vector_full)
				//	end
				//end)
			else
				//self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 1.5 * timeMul, self.MagModel, {Vector(-2,-3,0), Angle(180,-0,90), 75, self.lmagpos, self.lmagang}, true)
			end
		end,
		[0.36] = function( self, timeMul )
			if self:Clip1() < 1 then
				hg.CreateMag( self, Vector(0,0,-50), "111111")
				self:GetWM():ManipulateBoneScale(67, vecPochtiZero)
			else
				//self:GetWM():ManipulateBoneScale(75, vecPochtiZero)
				//self:GetWM():ManipulateBoneScale(76, vecPochtiZero)
				//self:GetWM():ManipulateBoneScale(77, vecPochtiZero)
			end 
		end,
		[0.6] = function( self, timeMul )
			if self:Clip1() < 1 then
				//self:GetOwner():PullLHTowards()
				self:GetWM():ManipulateBoneScale(67, vector_full)
			else
				//self:GetWM():ManipulateBoneScale(75, vector_full)
				//self:GetWM():ManipulateBoneScale(76, vector_full)
				//self:GetWM():ManipulateBoneScale(77, vector_full)
			end 
		end,
	}
end

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload0",
	["reload_empty"] = "reload_empty",
	["cycle"] = "bolt0",
}

SWEP.ScrappersSlot = "Primary"
SWEP.WepSelectIcon2 = Material("entities/arc9_eft_t5000.png")
SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "entities/arc9_eft_t5000.png"
SWEP.weight = 5
SWEP.weaponInvCategory = 1
SWEP.CustomShell = "762x51"
--SWEP.EjectPos = Vector(0,5,5)
--SWEP.EjectAng = Angle(-5,180,0)
SWEP.AutomaticDraw = false
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "7.62x51 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.Primary.Damage = 65
SWEP.Primary.Force = 65
SWEP.Primary.Sound = {"weapons/t5000/t5000_fire_close.ogg", 65, 90, 100}
SWEP.SupressedSound = {"weapons/t5000/t5000_fire_silenced_close.ogg", 65, 90, 100}
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor7", Vector(-5, 0, 0), {}},
		["mount"] = Vector(6, -0.55, -0.2)
	},
	sight = {
		["mountType"] = {"picatinny", "ironsight"},
		["mount"] = {picatinny = Vector(-28, 0.45, -0.2)}
	},
}

SWEP.StartAtt = {"optic6"}

SWEP.addSprayMul = 1
SWEP.cameraShakeMul = 1
SWEP.RecoilMul = 0.7

SWEP.LocalMuzzlePos = Vector(34.9,0.45,3.6)
SWEP.LocalMuzzleAng = Angle(-0.2,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.PPSMuzzleEffect = "muzzleflash_suppressed" -- shared in sh_effects.lu

SWEP.ShockMultiplier = 2

SWEP.handsAng = Angle(0, 0, 0)
SWEP.handsAng2 = Angle(-3, 1, 0)

SWEP.Primary.Wait = 0.15
SWEP.NumBullet = 1
SWEP.AnimShootMul = 1
SWEP.AnimShootHandMul = 1
SWEP.ReloadTime = 5.5
SWEP.ReloadSoundes = {
	"none",
	"none",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magout.wav",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magoutrattle.wav",
	"weapons/tfa_ins2/ak103/ak103_magin.wav",
	"weapons/tfa_ins2/ak103/ak103_boltback.wav",
	"weapons/tfa_ins2/ak103/ak103_boltrelease.wav",
	"none",
	"none",
	"none"
}
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-3, 0.4, 5)
SWEP.RHandPos = Vector(-8, -2, 6)
SWEP.LHandPos = Vector(6, -3, 1)
SWEP.AimHands = Vector(-10, 1.8, -6.1)
SWEP.SprayRand = {Angle(-0.2, -0.4, 0), Angle(-0.4, 0.4, 0)}
SWEP.Ergonomics = 1
SWEP.Penetration = 8
SWEP.ZoomFOV = 20
SWEP.WorldPos = Vector(5.5, -0.5, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.handsAng = Angle(-2, -1, 0)
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

SWEP.FakeViewBobBone = "ValveBiped.Bip01_L_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 90

SWEP.DistSound = "weapons/dvl10/dvl_fire_silenced_distant.ogg"

SWEP.lengthSub = 15
--SWEP.Supressor = false
--SWEP.SetSupressor = true

--local to head
SWEP.RHPos = Vector(3,-6.5,4)
SWEP.RHAng = Angle(0,-12,90)
--local to rh
SWEP.LHPos = Vector(17,1.3,-3.4)
SWEP.LHAng = Angle(-110,-180,-5)

SWEP.ShootAnimMul = 5

function SWEP:AnimHoldPost(model)
end

function SWEP:AnimationPost()
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
		self.LastReload = CurTime()
		self:ReloadStart()
		self:ReloadStartPost()
		local org = self:GetOwner().organism
		self.StaminaReloadMul = (org and ((2 - (self:GetOwner().organism.stamina[1] / 180)) + ((org.pain / 40) + (org.larm / 3) + (org.rarm / 5)) - (1 - math.Clamp(org.recoilmul or 1,0.45,1.4))) or 1)
		self.StaminaReloadMul = math.Clamp(self.StaminaReloadMul,0.65,1.5)
		self.StaminaReloadTime = self.ReloadTime * self.StaminaReloadMul
		self.StaminaReloadTime = (self.StaminaReloadTime + (self:Clip1() > 0 and -self.StaminaReloadTime/3 or 0 ))
		self.reload = self.LastReload + self.StaminaReloadTime
		self.dwr_reverbDisable = true
		self:PlayAnim(self.AnimList["reload"] or "reload", self.StaminaReloadTime, false, nil, false, true)
		net.Start("hgwep reload")
			net.WriteEntity(self)
			net.WriteFloat(self.LastReload)
			net.WriteInt(self:Clip1(),10)
			net.WriteFloat(self.StaminaReloadTime)
			net.WriteFloat(self.StaminaReloadMul)
		net.Broadcast()
	end
end

function SWEP:ReloadEnd()
	--if not self.CustomAmmoInsertEvent then
	self:InsertAmmo(self:GetMaxClip1() - self:Clip1() + (self.drawBullet ~= nil and not self.OpenBolt and 1 or 0))
	--end
	self.ReloadNext = CurTime() + self.ReloadCooldown --я хуй знает чо это
	if CLIENT and self.drawBullet == nil then
		self.noeject = true
	end
	if SERVER and self.drawBullet == nil then
		self:SetNetVar("shootgunReload",CurTime() + 1.3)
		self:PlayAnim(self.AnimList["cycle"] or "cycle", 1.5, false, nil, false, true)
	end

	self:Draw(nil,true)
end

function SWEP:CanPrimaryAttack()
	return not (self:GetNetVar("shootgunReload",0) > CurTime())
end

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,(self:Clip1() < 1 and not self.reload) and 2.3 or self.ReloadSlideOffset)
		--wep:ManipulateBonePosition(70,Vector(-1.8*self.shooanim , 0,0 ),false)
	end
end

function SWEP:ModelCreated(model)
	model:SetBodyGroups(self:GetRandomBodygroups() or "1112011")
end

function SWEP:PostSetupDataTables()
	self:NetworkVar("String",0,"RandomBodygroups")
	if ( CLIENT ) then
		self:NetworkVarNotify( "RandomBodygroups", self.OnVarChanged )
	end
end

function SWEP:OnVarChanged( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetBodyGroups(new)
end

function SWEP:InitializePost()
	self:SetRandomBodygroups(self.FakeBodyGroupsPresets[math.random(#self.FakeBodyGroupsPresets)])
	self.AnimStart_Insert = 0
	self.AnimStart_Draw = 0
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