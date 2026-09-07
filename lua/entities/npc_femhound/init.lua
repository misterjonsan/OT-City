AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPose + tr.HitNormal * 6
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180

	local ent = ents.Create( "npc_femhound" )
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

	self.npc = ents.Create( "npc_citizen" )
	self.npc:SetPos(self:GetPos())
	self.npc:SetAngles(self:GetAngles())
	self.npc:SetKeyValue( "spawnflags", "256" )

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
	self.npc:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_VERY_GOOD)
	self.npc:CapabilitiesAdd(CAP_MOVE_JUMP)
	self.npc:CapabilitiesAdd(CAP_USE)
	self.npc:CapabilitiesAdd(CAP_AUTO_DOORS)
	self.npc:CapabilitiesAdd(CAP_OPEN_DOORS)
	self.npc:CapabilitiesAdd(CAP_FRIENDLY_DMG_IMMUNE)
	self.npc:CapabilitiesAdd(CAP_DUCK)
	self.npc:CapabilitiesAdd(CAP_SQUAD)
	
	if IsValid(self.npc) and IsValid(self) then self.npc:DeleteOnRemove(self) end
	
	self:DeleteOnRemove(self.npc)
	
	if( IsValid(self.npc))then

	local min,max = self.npc:GetCollisionBounds()
	local hull = self.npc:GetHullType()
	self.npc:SetModel("models/npc/friendly/femhound.mdl")
	self.npc:SetSolid(SOLID_BBOX)
	self.npc:SetPos(self.npc:GetPos()+self.npc:GetUp()*16)
	self.npc:SetHullType(hull)
	self.npc:SetHullSizeNormal()
	self.npc:SetCollisionBounds(min,max)
	self.npc:DropToFloor()
	self.npc:SetModelScale(1)

	self.npc.allies = {
	"npc_monk",
	"npc_alyx",
	"npc_barney",
	"npc_citizen",
	"npc_dog",
	"npc_kleiner",
	"npc_magnusson",
	"npc_mossman",
	"npc_eli",
	"npc_gman",
	"npc_fisherman",
	"npc_vortigaunt",
	"npc_crow",
	"npc_pigeon",
	"npc_bullseye"
	}
	end
end

function ENT:MeleeAttacks(npc)
	if IsValid(npc) then
		local enemy = npc:GetEnemy()
		local anim = npc:GetSequenceName(self.npc:GetSequence())
		local act = npc:GetActivity()

		if IsValid(enemy) and npc:Visible(enemy) and enemy:GetPos():Distance(npc:GetPos()) <= 50 then
		if (!IsValid(npc)) or (!IsValid(enemy)) then return end
		if IsValid(enemy) and enemy:GetPos():Distance(npc:GetPos()) > 50 then return end
		if (npc:GetNWFloat("MeleeAttack") > CurTime()) then return false end

		self:ActNPC(npc, "swing", false, true, nil, nil, nil )
		local pos = npc:GetShootPos()
		local ang = npc:GetAimVector()
		local damagedice = (15)
		local primdamage = (1)
		local pain = primdamage * damagedice

		local slash = {}
		slash.start = pos
		slash.endpos = pos+(ang*50)
		slash.filter = npc
		slash.mins = Vector(15,15,10)
		slash.maxs = Vector(26,26,26)
		local slashtrace = util.TraceHull(slash)
		if slashtrace.Hit then
		local targ = slashtrace.Entity

		if npc:Disposition(targ) == D_LI or npc:Disposition(targ) == D_NU then return end

		local paininfo = DamageInfo()
		paininfo:SetDamage(pain)
		paininfo:SetDamageType(DMG_CLUB)
		paininfo:SetAttacker(npc)

		if IsValid(npc:GetActiveWeapon()) then
			paininfo:SetInflictor(npc:GetActiveWeapon())
		else
			paininfo:SetInflictor(npc)
		end
		local RandomForce = math.random(100,200)
		paininfo:SetDamageForce(slashtrace.Normal * RandomForce)
		targ:SetVelocity(npc:GetForward()*500+npc:GetUp()*150)

		if targ:IsNPC() then
			targ:StopMoving()
		end

		if targ:IsPlayer() then
			targ:ViewPunch(Angle(-20,math.random(-50,50),math.random(-15,15)))
		end

			if targ:IsPlayer() or targ:IsNPC() then
				local blood = targ:GetBloodColor()	
				local fleshimpact = EffectData()
				fleshimpact:SetEntity(self.Weapon)
				fleshimpact:SetOrigin(slashtrace.HitPos)
				fleshimpact:SetNormal(slashtrace.HitPos)

				if blood >= 0 then
					fleshimpact:SetColor(blood)
					util.Effect("BloodImpact", fleshimpact)
				end
			end
				targ:TakeDamageInfo(paininfo)
			else
			end
			npc:SetNWFloat("MeleeAttack", CurTime() + 1)
		end
	end
end


function ENT:Think()
	if IsValid(self) and IsValid(self.npc) then
		local npc = self.npc
		local enemy = self.npc:GetEnemy()
		local anim = self.npc:GetSequenceName(self.npc:GetSequence())
		local act = self.npc:GetActivity()

		self:MeleeAttacks(npc)
	end
end
	
function ENT:ScriptedSequencePlay(npc, parent, npc_name, moveto, pos, ang, replay, pre_anim, main_anim, post_anim, sound1, sound2, sound3)
	self.seq = ents.Create("scripted_sequence")
	
	if(parent)then
		self.seq:SetParent(parent)
	end
		self.seq:SetPos(pos)		
		self.seq:SetAngles(ang)

	if(pre_anim)then
		self.seq:SetKeyValue("m_iszIdle", pre_anim) -- Pre Anim
	end

	if(main_anim)then
		self.seq:SetKeyValue("m_iszPlay", main_anim) -- Anim
	end

	if(post_anim)then
		self.seq:SetKeyValue("m_iszPostIdle", post_anim) -- Post Anim
	end

	self.seq:SetKeyValue("m_iszEntity", npc_name)
	self.seq:SetKeyValue("spawnflags", "16" + "32" + "64" + "128")
	self.seq:SetKeyValue("m_fMoveTo", moveto)
	self.seq:SetKeyValue("m_flRepeat", replay)
	self.seq:Spawn()
	self.seq:Fire("beginsequence")

	if(sound1)then npc:EmitSound(sound1) end
	if(sound2)then npc:EmitSound(sound2) end
	if(sound3)then npc:EmitSound(sound3) end
	if IsValid(self.seq) and IsValid(self) then self:DeleteOnRemove(self.seq) end
end

function ENT:ActNPC(npc, name, override, stationary, time, kill, killer, killerwep, faceent, sound1, sound2, sound3)
	if(!IsValid(npc))or(IsValid(npc) and npc:GetNWBool("ActSequencePlay") and !override)then return end
	if npc.ActDelay==nil then npc.ActDelay=0 end
	local seq, dur = npc:LookupSequence(name)
	if time==nil or time<=0 then time=dur end
	if (npc.ActDelay > CurTime()) then return false end
	
	npc.ActDelay = CurTime() + dur
	local act=npc:GetSequenceInfo(seq).activity
	npc:RestartGesture(act)

	if(sound1)then npc:EmitSound(sound1) end
	if(sound2)then npc:EmitSound(sound2) end
	if(sound3)then npc:EmitSound(sound3) end

		timer.Simple(dur,function()
			if IsValid(npc) and kill then
				npc:SetHealth(1)
				npc:TakeDamage(npc:Health(),killer,killerwep)
			end
		end)

	if(stationary)then
		npc:StopMoving()
		npc:SetNWBool("ActSequencePlay", true)
		npc:ClearCondition(68)
		npc:SetCondition(67)

		timer.Create("ActSequenceFaceTarget"..npc:EntIndex(),0.1,math.Round(time*10),function()
			if(IsValid(npc))and(IsValid(faceent))then
				local ang = (faceent:GetPos()-npc:GetPos()):Angle()
				local ang2 = npc:GetAngles()
				npc:SetAngles(Angle(ang2.p,ang.y,ang2.r))
			end
		end)

		timer.Create("ActSequenceForceStop"..npc:EntIndex(),0.1,math.Round(time*10),function()
			if(IsValid(npc))then
				npc:StopMoving()
			end
		end)

		timer.Create("ActSequenceForceMove"..npc:EntIndex(),time,1,function()
			if(IsValid(npc))then
				npc:SetNWBool("ActSequencePlay", false)
				npc:ClearCondition(67)
				npc:SetCondition(68)
			end
		end)
	end
end

function ENT:OnRemove()
	if IsValid(self.npc) then
		self.npc:Remove()
	end
end