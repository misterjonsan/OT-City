AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end

		local SpawnPos = tr.HitPose + tr.HitNormal * 6
		self.Spawn_angles = ply:GetAngles()
		self.Spawn_angles.pitch = 0
		self.Spawn_angles.roll = 0
		self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180

		local ent = ents.Create( "npc_hostile_femhound" )
		ent:SetKeyValue( "disableshadows", "1" )
		ent:SetPos( SpawnPos )
		ent:SetAngles( self.Spawn_angles )
		ent:Spawn()
		ent:Activate()

	return ent
end

function ENT:Initialize()
	self:SetModel("models/props_lab/huladoll.mdl")
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetName(self.PrintName)
	self:SetOwner(self.Owner)
	self:DropToFloor()

	self.npc = ents.Create( "npc_combine_s" )
	self.npc:SetPos(self:GetPos())
	self.npc:SetAngles(self:GetAngles())
	self.npc:SetKeyValue( "squadname", "FH" )
	self.npc:SetKeyValue( "NumGrenades", "5" )

	Weapon1 = "weapon_smg1"
	Weapon2 = "weapon_ar2"
	Weapon3 = "weapon_shotgun"

	local Weapon = {}
		Weapon[1] = (Weapon1)
		Weapon[2] = (Weapon2)
		Weapon[3] = (Weapon3)
		
	self.npc:SetKeyValue( "additionalequipment", GetConVarString("gmod_npcweapon") )
	
	if GetConVarString("gmod_npcweapon") == "" then
		self.npc:SetKeyValue( "additionalequipment", Weapon[math.random(1,3)] )
	end

	self.npc:SetSpawnEffect(false)
	self.npc:Spawn()
	self.npc:Activate()
	self:SetParent(self.npc)
	self.npc:SetHealth(300)
	self.npc:SetMaxHealth(300)
	self.npc:SetBloodColor(0)
	self.npc:Fire("startpatrolling","",10)
	self.npc:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_GOOD)
	self.npc:CapabilitiesAdd(CAP_MOVE_JUMP)
	self.npc:CapabilitiesAdd(CAP_USE)
	self.npc:CapabilitiesAdd(CAP_AUTO_DOORS)
	self.npc:CapabilitiesAdd(CAP_OPEN_DOORS)
	self.npc:CapabilitiesAdd(CAP_FRIENDLY_DMG_IMMUNE)
	self.npc:CapabilitiesAdd(CAP_DUCK)
	self.npc:CapabilitiesAdd(CAP_SQUAD)
	self.npc:CapabilitiesAdd(16384)
	self.npc:CapabilitiesAdd(256)

	if IsValid(self.npc) and IsValid(self) then self.npc:DeleteOnRemove(self) end
	self:DeleteOnRemove(self.npc)
	
	if( IsValid(self.npc))then

		local min,max = self.npc:GetCollisionBounds()
		local hull = self.npc:GetHullType()
		self.npc:SetModel("models/npc/hostile/femhound.mdl")
		self.npc:SetSolid(SOLID_BBOX)
		self.npc:SetPos(self.npc:GetPos()+self.npc:GetUp()*16)
		self.npc:SetHullType(hull)
		self.npc:SetHullSizeNormal()
		self.npc:SetCollisionBounds(min,max)
		self.npc:DropToFloor()
		self.npc:SetModelScale(1)

		self.npc.allies = {
			"npc_combine_s",
			"npc_rollermine",
			"npc_helicopter",
			"npc_clawscanner",
			"npc_cscanner",
			"npc_metropolice",
			"npc_manhack",
			"npc_hunter",
			"npc_strider",
			"npc_combinegunship",
			"npc_combinedropship",
			"npc_stalker"
		}
		
	end
end

function ENT:Think()
	if IsValid(self) and IsValid(self.npc) then
		local npc = self.npc
		local enemy = self.npc:GetEnemy()
		local anim = self.npc:GetSequenceName(self.npc:GetSequence())
		local act = self.npc:GetActivity()
	end
end

function ENT:OnRemove()
	if IsValid(self.npc) then
		self.npc:Remove()
	end
end