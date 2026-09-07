util.AddNetworkString("RunZManipAnim")

local zmanipAliases = {
	thumb_up = "thump_up",
}

local zmanipAnimations = {
	interact = true,
	use = true,
	flipoff = true,
	okayhand = true,
	thumbsup = true,
	swimforward = true,
	swimleft = true,
	explosion = true,
	usedoor = true,
	visordown = true,
	door_open_forward = true,
	door_open_back = true,
	fuckyou = true,
	point = true,
	thump_up = true,
}

local gestureCommands = {
	["fuckyou"] = {"fuckyou", false},
	["thumb_up"] = {"thump_up", false},
	["thumbsup"] = {"thumbsup", false},
	["point"] = {"point", false},
	["flipoff"] = {"flipoff", false},
	["okayhand"] = {"okayhand", false},
	["visordown"] = {"visordown", false},
	["explosion"] = {"explosion", false},
	["door_open_back"] = {"door_open_back", false},
	["door_open_forward"] = {"door_open_forward", false},
	["usedoor"] = {"usedoor", false},
}

local function resolveZManipAnim(anim)
	anim = tostring(anim or "")
	anim = zmanipAliases[anim] or anim
	if anim == "" or not zmanipAnimations[anim] then return nil end
	return anim
end

function hg.RunZManipAnim(ply, anim, revers, timeOveride, additionalTbl)
	anim = resolveZManipAnim(anim)
	if not anim then return false end
	if not IsValid(ply) then return false end

	net.Start("RunZManipAnim")
		net.WritePlayer(ply)
		net.WriteString(anim)
		net.WriteBool(revers or false)
		net.WriteFloat(timeOveride or 0)
		net.WriteTable(additionalTbl or {})
	net.SendPVS(ply:GetPos())

	return true
end

hook.Add("PlayerUse", "ZManipUseAnim", function(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return end
	if not ent.Use then return end
	if ply.ZManipInteractCD and ply.ZManipInteractCD >= CurTime() then return end

	if hgIsDoor(ent) then
		ply.ZManipInteractCD = CurTime() + 1.1
		timer.Simple(0, function()
			if not IsValid(ply) or not IsValid(ent) then return end
			local dot = ent:GetAngles():Forward():Dot(ply:EyeAngles():Forward())
			local anim = dot > 0 and "door_open_forward" or "door_open_back"
			hg.RunZManipAnim(ply, anim, nil, nil, {ent})
		end)
		return
	end

	if ent:IsRagdoll() then return end

	local class = ent:GetClass()
	if string.find(class, "prop") or string.find(class, "breakable") or string.find(class, "ladder") then return end

	ply.ZManipInteractCD = CurTime() + 0.95
	ply.ZManipOldUse = ply:KeyDown(IN_USE)

	local anim = (ent:IsWeapon() or ent.IsZPickup) and "interact" or "use"

	timer.Simple(0, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		hg.RunZManipAnim(ply, anim, nil, nil, {ent})
	end)
end)

hook.Add("Player Think", "ZManipSwimAnim", function(ply, time, dtime)
	if ply:WaterLevel() > 0 and not ply:IsOnGround() and ply:GetVelocity():LengthSqr() > 3000 and (not ply.ZManipSwimCD or ply.ZManipSwimCD < CurTime()) then
		ply.ZManipSwimCD = CurTime() + 0.95
		if not (ply:WaterLevel() > 2) then
			local snd = math.random(1, 11)
			ply:EmitSound("zcitysnd/player/footsteps/wade" .. snd .. ".wav")
		end
		if IsValid(ply:GetActiveWeapon()) and ishgweapon(ply:GetActiveWeapon()) then
			if ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_MOVERIGHT) then
				hg.RunZManipAnim(ply, "swimforward")
			else
				hg.RunZManipAnim(ply, "swimleft")
			end
		end
	end
end)

concommand.Add("hg_hand_gesture", function(ply, cmd, args)
	ply.handGestureCD = ply.handGestureCD or 0
	if ply.handGestureCD > CurTime() then return end

	local selected
	if args[1] and gestureCommands[args[1]] then
		selected = gestureCommands[args[1]]
	elseif not args[1] then
		selected = table.Random(gestureCommands)
	end

	if not selected then return end
	if hg.RunZManipAnim(ply, selected[1], selected[2]) then
		ply.handGestureCD = CurTime() + 2
	end
end)
