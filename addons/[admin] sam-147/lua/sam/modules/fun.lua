if SAM_LOADED then return end



local sam, command, language = sam, sam.command, sam.language

command.set_category("Fun")

do
	local sounds = {}
	for i = 1, 6 do
		sounds[i] = "physics/body/body_medium_impact_hard" .. i .. ".wav"
	end

	local slap = function(ply, damage, admin)
		if not ply:Alive() or ply:sam_get_nwvar("frozen") then return end
		ply:ExitVehicle()

		ply:SetVelocity(Vector(math.random(-100, 100), math.random(-100, 100), math.random(200, 400)))
		ply:EmitSound(sounds[math.random(1, 6)], 60, math.random(80, 120))

		if damage > 0 then
			ply:TakeDamage(damage, admin, DMG_GENERIC)
		end
	end

	command.new("slap")
		:SetPermission("slap", "admin")

		:AddArg("player")
		:AddArg("number", {hint = "damage", round = true, optional = true, min = 0, default = 0})

		:Help("slap_help")

		:OnExecute(function(ply, targets, damage)
			for i = 1, #targets do
				slap(targets[i], damage, ply)
			end

			if damage > 0 then
				sam.player.send_message(nil, "slap_damage", {
					A = ply, T = targets, V = damage
				})
			else
				sam.player.send_message(nil, "slap", {
					A = ply, T = targets
				})
			end
		end)
	:End()
end

command.new("slay")
	:SetPermission("slay", "admin")

	:AddArg("player")

	:Help("slay_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			local v = targets[i]
			if not v:sam_get_exclusive(ply) then
				v:Kill()
			end
		end

		sam.player.send_message(nil, "slay", {
			A = ply, T = targets
		})
	end)
:End()

command.new("hp")
	:Aliases("sethp", "health", "sethealth")

	:SetPermission("hp", "admin")

	:AddArg("player")
	:AddArg("number", {hint = "amount", min = 1, max = 2147483647, round = true, optional = true, default = 100})

	:Help("hp_help")

	:OnExecute(function(ply, targets, amount)
		for i = 1, #targets do
			targets[i]:SetHealth(amount)
		end

		sam.player.send_message(nil, "set_hp", {
			A = ply, T = targets, V = amount
		})
	end)
:End()

command.new("armor")
	:Aliases("setarmor")

	:SetPermission("armor", "admin")

	:AddArg("player")
	:AddArg("number", {hint = "amount", min = 1, max = 2147483647, round = true, optional = true, default = 100})

	:Help("armor_help")

	:OnExecute(function(ply, targets, amount)
		for i = 1, #targets do
			targets[i]:SetArmor(amount)
		end

		sam.player.send_message(nil, "set_armor", {
			A = ply, T = targets, V = amount
		})
	end)
:End()

command.new("ignite")
	:SetPermission("ignite", "admin")

	:AddArg("player")
	:AddArg("number", {hint = "seconds", optional = true, default = 60, round = true})

	:Help("ignite_help")

	:OnExecute(function(ply, targets, length)
		for i = 1, #targets do
			local target = targets[i]

			if target:IsOnFire() then
				target:Extinguish()
			end

			target:Ignite(length)
		end

		sam.player.send_message(nil, "ignite", {
			A = ply, T = targets, V = length
		})
	end)
:End()

command.new("unignite")
	:Aliases("extinguish")

	:SetPermission("ignite", "admin")

	:AddArg("player", {optional = true})

	:Help("unignite_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			targets[i]:Extinguish()
		end

		sam.player.send_message(nil, "unignite", {
			A = ply, T = targets
		})
	end)
:End()

command.new("god")
	:Aliases("invincible")

	:SetPermission("god", "admin")

	:AddArg("player", {optional = true})

	:Help("god_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			local target = targets[i]
			target:GodEnable()
			target.sam_has_god_mode = true
		end

		sam.player.send_message(nil, "god", {
			A = ply, T = targets
		})
	end)
:End()

command.new("ungod")
	:Aliases("uninvincible")

	:SetPermission("ungod", "admin")

	:AddArg("player", {optional = true})

	:Help("ungod_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			local target = targets[i]
			target:GodDisable()
			target.sam_has_god_mode = nil
		end

		sam.player.send_message(nil, "ungod", {
			A = ply, T = targets
		})
	end)
:End()

do
	command.new("freeze")
		:SetPermission("freeze", "admin")

		:AddArg("player")

		:Help("freeze_help")

		:OnExecute(function(ply, targets)
			for i = 1, #targets do
				local v = targets[i]
				v:ExitVehicle()
				if v:sam_get_nwvar("frozen") then
					v:UnLock()
				end
				v:Lock()
				v:sam_set_nwvar("frozen", true)
				v:sam_set_exclusive("frozen")
			end

			sam.player.send_message(nil, "freeze", {
				A = ply, T = targets
			})
		end)
	:End()

	command.new("unfreeze")
		:SetPermission("unfreeze", "admin")

		:AddArg("player", {optional = true})

		:Help("unfreeze_help")

		:OnExecute(function(ply, targets)
			for i = 1, #targets do
				local v = targets[i]
				v:UnLock()
				v:sam_set_nwvar("frozen", false)
				v:sam_set_exclusive(nil)
			end

			sam.player.send_message(nil, "unfreeze", {
				A = ply, T = targets
			})
		end)
	:End()

	local disallow = function(ply)
		if ply:sam_get_nwvar("frozen") then
			return false
		end
	end

	for _, v in ipairs({"SAM.CanPlayerSpawn", "CanPlayerSuicide", "CanTool"}) do
		hook.Add(v, "SAM.FreezePlayer." .. v, disallow)
	end
end

command.new("cloak")
	:SetPermission("cloak", "admin")

	:AddArg("player", {optional = true})

	:Help("cloak_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			targets[i]:sam_cloak()
		end

		sam.player.send_message(nil, "cloak", {
			A = ply, T = targets
		})
	end)
:End()

command.new("uncloak")
	:SetPermission("uncloak", "admin")

	:AddArg("player", {optional = true})

	:Help("uncloak_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			targets[i]:sam_uncloak()
		end

		sam.player.send_message(nil, "uncloak", {
			A = ply, T = targets
		})
	end)
:End()


do
	local meta = FindMetaTable("Player")
    local jailpos = Vector(-3555.991699,4387.986328,-6467.968750)
	local jail_gays = {}

	function meta:IsJailed() 
		return istable(jail_gays[self:SteamID64()])
	end

	local pos1 = Vector(-3330.864502,4010.063721,-6540.018066)
	local pos2 = Vector(-4505.264648,4788.175781,-5705.025879)

	timer.Create("SAM.Watch", 5, 0, function()
		for k, v in pairs(jail_gays) do 
			if !jail_gays[k].player or !IsValid(jail_gays[k].player) then continue end
			local v = jail_gays[k].player
			if !v:GetPos():WithinAABox(pos1, pos2) then 
				v:SetPos(jailpos)
			end
		end
	end)

	local unjail = function(ply)
		if not IsValid(ply) then return end
		local uid = ply:SteamID64()
		if !jail_gays[uid] then return end
		if !jail_gays[uid].jailed then return end

		jail_gays[uid] = nil

		timer.Remove("SAM.Unjail." .. uid)

        netstream.Start(ply, "MilkyJailHUD", time)

        ply:Spawn()
	end

	local function jail(ply, time, admin, reason)
		if not IsValid(ply) then return end
		if not isnumber(time) or time < 0 then time = 0 end

		local uid = ply:SteamID64()

		if not jail_gays[uid] then 
			jail_gays[uid] = {}
		end

		jail_gays[uid].jailed = true
		jail_gays[uid].player = ply
		jail_gays[uid].admin = IsValid(admin) and admin:Nick() or "CONSOLE"
		jail_gays[uid].reason = reason or "Без причины"

		ply:SetPos(jailpos)
		ply:ExitVehicle()
		ply:SetMoveType(MOVETYPE_WALK)
		ply:StripWeapons()
		ply:changeTeam(TEAM_NEWSTUDENT, true)
		ply:Spawn()

		netstream.Start(ply, "MilkyJailHUD", {
			time = time,
			admin = jail_gays[uid].admin,
			reason = jail_gays[uid].reason
		})

		if time > 0 then
			timer.Create("SAM.Unjail." .. uid, time, 1, function()
				if IsValid(ply) then
					unjail(ply)
				end
			end)
		end
	end

	command.new("jail")
		:SetPermission("jail", "admin")

		:AddArg("player", { single_target = true})
		:AddArg("length", {optional = true, default = 0, min = 0})
		:AddArg("text", {hint = "причина", optional = true, default = sam.language.get("default_reason")})

		:GetRestArgs()

		:Help(language.get("jail_help"))

		:OnExecute(function(ply, targets, length, reason)
			local target = targets[1]
			jail(target, length * 60, ply)

			if sam.is_command_silent then return end
			sam.player.send_message(nil, "jail", {
				A = ply, T = targets, V = sam.format_length(length), V_2 = reason
			})
		end)
	:End()

	command.new("unjail")
		:SetPermission("unjail", "admin")

		:AddArg("player", { single_target = true, optional = true})

		:Help(language.get("unjail_help"))

		:OnExecute(function(ply, targets)
			local target = targets[1]
			if ply == target then
				monteract.sendNotify2('Вы не можете выпустить самого себя.', 5, ply)
			return end

			unjail(target)

			if sam.is_command_silent then return end
			sam.player.send_message(nil, "unjail", {
				A = ply, T = targets
			})
		end)
	:End()

	if SERVER then
		hook.Add("playerCanChangeTeam", "SAM.Jail", function(ply, tem, force)
			local uid = ply:SteamID64()
			if jail_gays[uid] and jail_gays[uid].jailed and !force then
				ply:ChatPrint("Нельзя менять профессию, находясь в джайле")
				return false
			end
		end)

		hook.Add("OnPlayerChangedTeam", "SAM.Jail", function(ply, before, after)
			local uid = ply:SteamID64()
			if jail_gays[uid] and jail_gays[uid].jailed and after != TEAM_NEWSTUDENT then
				ply:changeTeam(TEAM_NEWSTUDENT, true)
			end
		end)

		hook.Add("PlayerInitialSpawn", "SAM.Jail", function(ply)
			timer.Simple(0.1, function()
				local uid = ply:SteamID64()
				if jail_gays[uid] and jail_gays[uid].jailed then
					jail(ply, jail_gays[uid].timeleft)
					jail_gays[uid].player = ply
				end
			end)
		end)

		hook.Add("PlayerEnteredVehicle", "SAM.Jail", function(ply)
			local uid = ply:SteamID64()
			if jail_gays[uid] and jail_gays[uid].jailed then
				ply:ExitVehicle()
			end
		end)

		hook.Add("PlayerDisconnected", "SAM.Jail", function(ply)
			local uid = ply:SteamID64()
			if jail_gays[uid] and jail_gays[uid].jailed then
				jail_gays[uid].timeleft = timer.TimeLeft("SAM.Unjail." .. uid)
				jail_gays[uid].player = nil
				timer.Remove("SAM.Unjail." .. uid)
			end   
		end)
	end
 
	local disallow = function(ply)
		local uid = ply:SteamID64()
		if jail_gays[uid] then  	
			if jail_gays[uid].jailed then
				return false
			end
		end
	end

	for _, v in ipairs({"PlayerNoClip", "SAM.CanPlayerSpawn", "CanPlayerEnterVehicle", "CanPlayerSuicide", "CanTool"}) do
		hook.Add(v, "SAM.Jail", disallow)
	end
end

command.new("strip")
	:SetPermission("strip", "admin")

	:AddArg("player")

	:Help("strip_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			targets[i]:StripWeapons()
		end

		sam.player.send_message(nil, "strip", {
			A = ply, T = targets
		})
	end)
:End()

command.new("respawn")
	:SetPermission("respawn", "admin")

	:AddArg("player", {optional = true})

	:Help("respawn_help")

	:OnExecute(function(ply, targets)
		for i = 1, #targets do
			targets[i]:Spawn()
		end

		sam.player.send_message(nil, "respawn", {
			A = ply, T = targets
		})
	end)
:End()

command.new("setmodel")
	:SetPermission("setmodel", "superadmin")

	:AddArg("player")
	:AddArg("text", {hint = "model"})

	:Help("setmodel_help")

	:OnExecute(function(ply, targets, model)
		for i = 1, #targets do
			targets[i]:SetModel(model)
		end

		sam.player.send_message(nil, "setmodel", {
			A = ply, T = targets, V = model
		})
	end)
:End()

command.new("giveammo")
	:Aliases("ammo")

	:SetPermission("giveammo", "superadmin")

	:AddArg("player")
	:AddArg("number", {hint = "amount", min = 0, max = 99999})

	:Help("giveammo_help")

	:OnExecute(function(ply, targets, amount)
		if amount == 0 then
			amount = 99999
		end

		for i = 1, #targets do
			local target = targets[i]
			for _, wep in ipairs(target:GetWeapons()) do
				if wep:GetPrimaryAmmoType() ~= -1 then
					target:GiveAmmo(amount, wep:GetPrimaryAmmoType(), true)
				end

				if wep:GetSecondaryAmmoType() ~= -1 then
					target:GiveAmmo(amount, wep:GetSecondaryAmmoType(), true)
				end
			end
		end

		sam.player.send_message(nil, "giveammo", {
			A = ply, T = targets, V = amount
		})
	end)
:End()

do
	command.new("scale")
		:SetPermission("scale", "superadmin")

		:AddArg("player")
		:AddArg("number", {hint = "amount", optional = true, min = 0.2, max = 2.5, default = 1})

		:Help("scale_help")

		:OnExecute(function(ply, targets, amount)
			for i = 1, #targets do
				local v = targets[i]
				v:SetModelScale(amount)

				-- https://github.com/carz1175/More-ULX-Commands/blob/9b142ee4247a84f16e2dc2ec71c879ab76e145d4/lua/ulx/modules/sh/extended.lua#L313
				v:SetViewOffset(Vector(0, 0, 64 * amount))
				v:SetViewOffsetDucked(Vector(0, 0, 28 * amount))

				v.sam_scaled = true
			end

			sam.player.send_message(nil, "scale", {
				A = ply, T = targets, V = amount
			})
		end)
	:End()

	hook.Add("PlayerSpawn", "SAM.Scale", function(ply)
		if ply.sam_scaled then
			ply.sam_scaled = nil
			ply:SetViewOffset(Vector(0, 0, 64))
			ply:SetViewOffsetDucked(Vector(0, 0, 28))
		end
	end)
end

sam.command.new("freezeprops")
	:SetPermission("freezeprops", "admin")
	:Help("freezeprops_help")

	:OnExecute(function(ply)
		for _, prop in ipairs(ents.FindByClass("prop_physics")) do
			local physics_obj = prop:GetPhysicsObject()
			if IsValid(physics_obj) then
				physics_obj:EnableMotion(false)
			end
		end

		sam.player.send_message(nil, "freezeprops", {
			A = ply
		})
	end)
:End()