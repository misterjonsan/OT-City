SLogs:Msg(Color(255, 100, 100), "Main", Color(255, 255, 255), " module loaded.")

local WarnID = SLogs:GetID("Warn")
local DamagesID = SLogs:GetID("Damages")
local KillsID = SLogs:GetID("Kills")
local ConnectionsID = SLogs:GetID("Connections")
local ULXID = SLogs:GetID("ULX")
local ToolsID = SLogs:GetID("Tools")
local WeaponsID = SLogs:GetID("Weapons")

local LAST_PLAYER_DAMAGE_TIME = 5
local HOMIGRAD_LOG_WINDOW = 0.05

local function IsDamage(dmg, dmg2)
	return bit.band(dmg, dmg2) == dmg2
end

local function GetOwnerPlayer(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent end

	local owner = nil

	owner = ent.Owner or ent.owner
	if IsValid(owner) and owner:IsPlayer() then
		return owner
	end

	if ent.CPPIGetOwner then
		owner = ent:CPPIGetOwner()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	if ent.GetOwner then
		owner = ent:GetOwner()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	if ent.GetCreator then
		owner = ent:GetCreator()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	if ent.GetParent then
		owner = ent:GetParent()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	return nil
end

function SLogs:RememberPlayerAttack(target, killer, weapon)
	if not IsValid(target) or not target:IsPlayer() then return end
	if not IsValid(killer) or not killer:IsPlayer() then return end
	if killer == target then return end

	local weaponClass = weapon

	if IsValid(weaponClass) then
		if weaponClass.IsWeapon and weaponClass:IsWeapon() then
			weaponClass = weaponClass:GetClass()
		else
			weaponClass = weaponClass:GetClass()
		end
	end

	if weaponClass == nil or weaponClass == "" then
		local active = SLogs:ValidCall(killer, "GetActiveWeapon")
		if IsValid(active) then
			weaponClass = active:GetClass()
		end
	end

	target.SLogs_LastPlayerDamage = {
		time = CurTime(),
		killer = killer,
		weapon = weaponClass or "unknown",
		attacker_nick = SLogs:ValidCall(killer, "GetName") or "Неизвестно",
		attacker_sid = SLogs:ValidCall(killer, "SteamID")
	}
end

local function ResolveDamageInfo(target, dmg)
	local attacker = IsValid(dmg:GetAttacker()) and dmg:GetAttacker() or nil
	local inflictor = IsValid(dmg:GetInflictor()) and dmg:GetInflictor() or nil

	local attacker_ply = GetOwnerPlayer(attacker)
	local inflictor_ply = GetOwnerPlayer(inflictor)

	local killer = attacker_ply or inflictor_ply
	local weapon = "Неизвестно"

	if IsValid(inflictor) and inflictor:IsWeapon() then
		weapon = inflictor:GetClass()
	elseif IsValid(attacker) and attacker:IsWeapon() then
		weapon = attacker:GetClass()
	elseif IsValid(killer) then
		local active = SLogs:ValidCall(killer, "GetActiveWeapon")
		if IsValid(active) then
			weapon = active:GetClass()
		end
	elseif IsValid(inflictor) then
		weapon = inflictor:GetClass()
	elseif IsValid(attacker) then
		weapon = attacker:GetClass()
	end

	local attacker_nick = "Карта"
	local attacker_sid = nil

	if IsValid(killer) and killer:IsPlayer() then
		attacker_nick = SLogs:ValidCall(killer, "GetName") or "Неизвестно"
		attacker_sid = SLogs:ValidCall(killer, "SteamID")
	end

	local eyeID = function() return nil end
	if IsValid(killer) and killer:IsPlayer() then
		eyeID = function()
			if not IsValid(killer) then return nil end
			return SLogs.Eye:RegisterCase(SLogs.Eye:GetWitnesses({ply2 = killer, ply1 = target}, nil, true))
		end
	end

	local is_self = IsValid(killer) and killer == target

	return {
		attacker = attacker,
		inflictor = inflictor,
		killer = killer,
		weapon = weapon,
		attacker_nick = attacker_nick,
		attacker_sid = attacker_sid,
		eyeID = eyeID,
		is_self = is_self
	}
end

local function SaveLastPlayerDamage(target, info)
	if not IsValid(target) or not target:IsPlayer() then return end
	if not IsValid(info.killer) or not info.killer:IsPlayer() then return end
	if info.killer == target then return end

	SLogs:RememberPlayerAttack(target, info.killer, info.weapon)
end

local function MarkRecentDamageLog(target, killer, amount)
	if not IsValid(target) or not target:IsPlayer() then return end

	target.SLogs_LastDamageLog = {
		time = CurTime(),
		killer = killer,
		amount = amount
	}
end

local function WasDamageLoggedRecently(target, killer, amount)
	if not IsValid(target) or not target:IsPlayer() then return false end

	local last = target.SLogs_LastDamageLog
	if not last then return false end
	if (CurTime() - (last.time or 0)) > HOMIGRAD_LOG_WINDOW then return false end
	if last.killer ~= killer then return false end
	if math.abs((last.amount or 0) - (amount or 0)) > 1 then return false end

	return true
end

local function ApplyLastPlayerDamage(target, info)
	local last = target.SLogs_LastPlayerDamage
	if not last then return info end
	if CurTime() - last.time > LAST_PLAYER_DAMAGE_TIME then return info end
	if not IsValid(last.killer) then return info end

	info.killer = last.killer
	info.weapon = last.weapon or info.weapon
	info.attacker_nick = last.attacker_nick or SLogs:ValidCall(last.killer, "GetName") or "Неизвестно"
	info.attacker_sid = last.attacker_sid or SLogs:ValidCall(last.killer, "SteamID")
	info.is_self = false

	info.eyeID = function()
		if not IsValid(last.killer) then return nil end
		return SLogs.Eye:RegisterCase(SLogs.Eye:GetWitnesses({ply2 = last.killer, ply1 = target}, nil, true))
	end

	return info
end

hook.Add("EntityTakeDamage", "SLogs_SaveRealAttacker", function(target, dmg)
	if not IsValid(target) or not target:IsPlayer() then return end

	local info = ResolveDamageInfo(target, dmg)
	SaveLastPlayerDamage(target, info)
end)

hook.Add("HomigradDamage", "SLogs_SaveHomigradAttacker", function(target, dmg, hitgroup, ent)
	if not IsValid(target) or not target:IsPlayer() then return end

	local info = ResolveDamageInfo(target, dmg)
	if IsValid(info.killer) and info.killer:IsPlayer() and info.killer ~= target then
		SLogs:RememberPlayerAttack(target, info.killer, info.weapon)
	end
end)

SLogs:Hook("PostEntityTakeDamage", function(target, dmg)
	if not IsValid(target) or not target:IsPlayer() then return end

	local damage_type = dmg:GetDamageType()
	local damage_int = math.floor(dmg:GetDamage())
	if damage_int == 0 then return end

	local info = ResolveDamageInfo(target, dmg)
	info = ApplyLastPlayerDamage(target, info)
	SaveLastPlayerDamage(target, info)

	if IsValid(info.killer) and info.killer:IsPlayer() and info.killer ~= target and IsDamage(damage_type, DMG_FALL) then
		damage_type = DMG_BULLET
	end

	if IsDamage(damage_type, DMG_BULLET) and not info.is_self and IsValid(info.killer) then
		MarkRecentDamageLog(target, info.killer, damage_int)
		return {
			T = DamagesID,
			I = 1,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_BLAST) and not info.is_self and IsValid(info.killer) then
		MarkRecentDamageLog(target, info.killer, damage_int)
		return {
			T = DamagesID,
			I = 2,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_VEHICLE) and not IsDamage(damage_type, DMG_CRUSH) then
		return {
			T = DamagesID,
			I = 7,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_VEHICLE) and not info.is_self and IsValid(info.killer) then
		MarkRecentDamageLog(target, info.killer, damage_int)
		return {
			T = DamagesID,
			I = 3,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif (IsDamage(damage_type, DMG_FALL) or info.is_self) and (not IsValid(info.killer) or info.killer == target) then
		return {
			T = DamagesID,
			I = 4,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_BLAST) then
		return {
			T = DamagesID,
			I = 5,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				int = damage_int,
				eye = info.eyeID()
			}
		}
	elseif target.last_h_dmg == CurTime() then
		return {
			T = DamagesID,
			I = 6,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				int = damage_int,
				eye = info.eyeID()
			}
		}
	else
		if IsValid(info.killer) and info.killer:IsPlayer() and info.killer ~= target then
			MarkRecentDamageLog(target, info.killer, damage_int)
		end
		return {
			T = DamagesID,
			I = 0,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				int = damage_int,
				eye = info.eyeID()
			}
		}
	end
end)

SLogs:Hook("ScalePlayerDamage", function(target, hitgroup, dmg)
	if not IsValid(target) or not target:IsPlayer() then return end

	local damage_int = math.floor(dmg:GetDamage())
	if damage_int <= 0 then return end

	local info = ResolveDamageInfo(target, dmg)
	SaveLastPlayerDamage(target, info)

	if not IsValid(info.killer) or not info.killer:IsPlayer() or info.killer == target then return end

	return {
		T = DamagesID,
		I = 1,
		E = {
			ply1 = info.attacker_nick,
			ply2 = SLogs:ValidCall(target, "GetName"),
			sid1 = info.attacker_sid,
			sid2 = SLogs:ValidCall(target, "SteamID"),
			wep = info.weapon,
			int = damage_int,
			eye = info.eyeID()
		}
	}
end)

SLogs:Hook("DoPlayerDeath", function(target, attacker, dmg)
	if not IsValid(target) or not target:IsPlayer() then return end

	local damage_type = dmg:GetDamageType()
	local info = ResolveDamageInfo(target, dmg)

	if IsValid(info.killer) and info.killer:IsPlayer() and info.killer ~= target then
		if IsDamage(damage_type, DMG_FALL) or damage_type == 0 then
			damage_type = DMG_BULLET
		end
	end

	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then
		local wep = SLogs:ValidCall(attacker, "GetActiveWeapon")
		info.killer = attacker
		info.weapon = IsValid(wep) and wep:GetClass() or info.weapon
		info.attacker_nick = SLogs:ValidCall(attacker, "GetName") or "Неизвестно"
		info.attacker_sid = SLogs:ValidCall(attacker, "SteamID")
		info.is_self = false
	end

	info = ApplyLastPlayerDamage(target, info)

	if IsDamage(damage_type, DMG_BULLET) and not info.is_self and IsValid(info.killer) then
		return {
			T = KillsID,
			I = 1,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_BLAST) and not info.is_self and IsValid(info.killer) then
		return {
			T = KillsID,
			I = 2,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_VEHICLE) and not IsDamage(damage_type, DMG_CRUSH) then
		return {
			T = KillsID,
			I = 7,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_VEHICLE) and not info.is_self and IsValid(info.killer) then
		return {
			T = KillsID,
			I = 3,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				eye = info.eyeID()
			}
		}
	elseif (IsDamage(damage_type, DMG_FALL) or info.is_self) and (not IsValid(info.killer) or info.killer == target) then
		return {
			T = KillsID,
			I = 4,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				eye = info.eyeID()
			}
		}
	elseif IsDamage(damage_type, DMG_BLAST) then
		return {
			T = KillsID,
			I = 5,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				eye = info.eyeID()
			}
		}
	elseif target.last_h_dmg == CurTime() then
		return {
			T = KillsID,
			I = 6,
			E = {
				ply1 = SLogs:ValidCall(target, "GetName"),
				sid1 = SLogs:ValidCall(target, "SteamID"),
				eye = info.eyeID()
			}
		}
	else
		return {
			T = KillsID,
			I = 0,
			E = {
				ply1 = info.attacker_nick,
				ply2 = SLogs:ValidCall(target, "GetName"),
				sid1 = info.attacker_sid,
				sid2 = SLogs:ValidCall(target, "SteamID"),
				wep = info.weapon,
				eye = info.eyeID()
			}
		}
	end
end)

gameevent.Listen("player_connect")

SLogs:Hook("player_connect", function(data)
	return {
		T = ConnectionsID,
		I = 0,
		E = {
			ply1 = data.name,
			sid1 = data.networkid
		}
	}
end)

gameevent.Listen("player_disconnect")

SLogs:Hook("player_disconnect", function(data)
	local reason = data.reason

	if reason:find("^Kicked by") then
		return {
			T = ConnectionsID,
			I = 2,
			E = {
				ply1 = data.name,
				sid1 = data.networkid,
				str = reason:match("^Kicked by (.*)")
			}
		}
	elseif reason:find("timed out$") then
		return {
			T = ConnectionsID,
			I = 3,
			E = {
				ply1 = data.name,
				sid1 = data.networkid
			}
		}
	elseif reason:find("Disconnect by user.$") then
		return {
			T = ConnectionsID,
			I = 4,
			E = {
				ply1 = data.name,
				sid1 = data.networkid
			}
		}
	else
		if reason:len() <= 1 then
			return {
				T = ConnectionsID,
				I = 1,
				E = {
					ply1 = data.name,
					sid1 = data.networkid
				}
			}
		else
			return {
				T = ConnectionsID,
				I = 2,
				E = {
					ply1 = data.name,
					sid1 = data.networkid,
					str = reason
				}
			}
		end
	end
end)

SLogs:Hook("PlayerInitialSpawn", function(ply)
	return {
		T = ConnectionsID,
		I = 5,
		E = {
			ply1 = SLogs:ValidCall(ply, "GetName"),
			sid1 = SLogs:ValidCall(ply, "SteamID")
		}
	}
end)

SLogs:Hook("SAM.RanCommand", function(ply, cmd_name, args, cmd)
	local plyName = (IsValid(ply) and ply:IsPlayer()) and SLogs:ValidCall(ply, "GetName") or "КОНСОЛЬ"
	local plySID = (IsValid(ply) and ply:IsPlayer()) and SLogs:ValidCall(ply, "SteamID") or "N/A"

	local targets, targetSIDs, other = {}, {}, {}

	local function pushTarget(p)
		if IsValid(p) and p:IsPlayer() then
			targets[#targets + 1] = SLogs:ValidCall(p, "GetName") or p:Nick() or "Unknown"
			targetSIDs[#targetSIDs + 1] = SLogs:ValidCall(p, "SteamID") or "N/A"
			return true
		end
		return false
	end

	local function handleArg(v)
		if istable(v) then
			for _, vv in ipairs(v) do
				if not pushTarget(vv) and vv ~= nil and not isbool(vv) then
					other[#other + 1] = tostring(vv)
				end
			end
		else
			if not pushTarget(v) and v ~= nil and not isbool(v) then
				other[#other + 1] = tostring(v)
			end
		end
	end

	if istable(args) then
		for i = 1, #args do
			handleArg(args[i])
		end
	end

	local args_str = table.concat(other, ", ")
	local targets_str = table.concat(targets, ", ")
	local sids_str = table.concat(targetSIDs, ", ")

	if #targets > 0 then
		return {
			T = ULXID,
			I = 2,
			E = {
				ply1 = plyName,
				sid1 = plySID,
				ply2 = targets_str,
				sid2 = sids_str,
				str1 = cmd_name,
				str2 = args_str
			}
		}
	else
		return {
			T = ULXID,
			I = 1,
			E = {
				ply1 = plyName,
				sid1 = plySID,
				str1 = cmd_name,
				str2 = args_str
			}
		}
	end
end)

SLogs:Hook("PlayerWarned", function(admin, name, sid, reason, time)
	return {
		T = WarnID,
		I = 0,
		E = {
			ply1 = SLogs:ValidCall(admin, "GetName"),
			ply2 = name,
			sid1 = SLogs:ValidCall(admin, "SteamID"),
			sid2 = sid,
			time = time <= 0 and 0 or (os.time() - SLogs.Time + time),
			str = reason
		}
	}
end)

SLogs:Hook("PlayerUnWarned", function(admin, name, sid)
	return {
		T = WarnID,
		I = 1,
		E = {
			ply1 = SLogs:ValidCall(admin, "GetName"),
			ply2 = name,
			sid1 = SLogs:ValidCall(admin, "SteamID"),
			sid2 = sid
		}
	}
end)

SLogs:Hook("CanTool", function(ply, trace, toolName)
	return {
		T = ToolsID,
		I = 0,
		E = {
			ply1 = SLogs:ValidCall(ply, "GetName"),
			sid1 = SLogs:ValidCall(ply, "SteamID"),
			str1 = toolName,
			str2 = Either(IsValid(trace.Entity), trace.Entity:GetClass(), "World")
		}
	}
end)

SLogs:Hook("event_giveweapon", function(admin, plys, weps)
	local plysNick = ""
	for k, v in pairs(plys) do
		if not IsValid(v) then continue end
		plysNick = plysNick .. (plysNick == "" and "" or ",") .. v:Nick()
	end

	return {
		T = WeaponsID,
		I = 0,
		E = {
			ply1 = SLogs:ValidCall(admin, "GetName"),
			sid1 = SLogs:ValidCall(admin, "SteamID"),
			weps = table.concat(weps, "<>"),
			plys = plysNick
		}
	}
end)

SLogs:Hook("HomigradDamage", function(target, dmg, hitgroup, ent, harm)
	if not IsValid(target) or not target:IsPlayer() then return end

	local damage_int = math.floor(tonumber(harm) or dmg:GetDamage() or 0)
	if damage_int <= 0 then return end

	local info = ResolveDamageInfo(target, dmg)
	SaveLastPlayerDamage(target, info)

	if not IsValid(info.killer) or not info.killer:IsPlayer() or info.killer == target then return end
	if WasDamageLoggedRecently(target, info.killer, damage_int) then return end

	MarkRecentDamageLog(target, info.killer, damage_int)

	return {
		T = DamagesID,
		I = 1,
		E = {
			ply1 = info.attacker_nick,
			ply2 = SLogs:ValidCall(target, "GetName"),
			sid1 = info.attacker_sid,
			sid2 = SLogs:ValidCall(target, "SteamID"),
			wep = info.weapon,
			int = damage_int,
			eye = info.eyeID()
		}
	}
end)
