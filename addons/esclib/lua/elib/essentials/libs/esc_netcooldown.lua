local SysTime = SysTime

esclib.net_cooldown = {}

--------------------
--# NET COOLDOWN #--
--------------------
function esclib:SetNetCooldown(uid,ply,time)
	if not IsValid(ply) then return end
	if not self.net_cooldown[uid] then
		self.net_cooldown[uid] = {}
	end

	self.net_cooldown[uid][ply:SteamID64()] = SysTime() + time
end

function esclib:PlyHasNetCooldown(uid,ply)
	if self.net_cooldown[uid] then
		local res = (self.net_cooldown[uid][ply:SteamID64()] or 0) > (SysTime())

		if not res then
			self.net_cooldown[uid][ply:SteamID64()] = nil
			return false
		else
			return true
		end
	end
	return false
end

function esclib:AddCooldownFunc(net_name,ply,cooldown,func,dont_use_timer)
	if not esclib:PlyHasNetCooldown(net_name, ply) then	
		func()
		esclib:SetNetCooldown(net_name, ply, cooldown)
	elseif (not timer.Exists(net_name.."_net_cooldown")) and not (dont_use_timer) then
		timer.Create(net_name.."_net_cooldown", cooldown*1.1, 1, function()
			func()
		end)
	end		
end

--Clear cooldown (per 10 minutes)
timer.Create("esclib.NetCooldownCleaner", 600, 0, function()
	for uid,values in pairs(esclib.net_cooldown) do

		for steamid,time in pairs(values) do
			if time < SysTime() then
				esclib.net_cooldown[steamid] = nil
				continue
			end

			if not player.GetBySteamID64(steamid) then
				esclib.net_cooldown[steamid] = nil
				continue
			end
		end

	end
end)