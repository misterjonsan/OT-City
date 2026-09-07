--[[
	NetStream - 2.0.1
	https://github.com/alexgrist/NetStream/blob/master/netstream2.lua

	Alexander Grist-Hucker
	http://www.revotech.org
]]--

--[[
	if SERVER then
		netstream.Hook("Hi", function(ply, ...) -- Third argument is called to check if the player has permission to send the net message before decoding
			print(...)
		end, function(ply)
			if not ply:IsAdmin() then
				return false
			end
		end)
		-- OR
		netstream.Hook("Hi", function(ply, ...)
			print(...)
		end)
		netstream.Start(Entity(1), "Hi", "a", 1, {}, true, false, nil, "!") -- First argument player or table of players or any other argument to send to all players
		netstream.Start({Entity(1), Entity(2)}, "Hi", "a", 1, {}, true, false, nil, "!")
		netstream.Start(nil, "Hi", "a", 1, {}, true, false, nil, "!")
	end
	if CLIENT then
		netstream.Hook("Hi", function(...)
			print(...)
		end)
		netstream.Start("Hi", "a", 1, {}, true, false, nil, "!")
	end
]]--



-- netstream
local mp = esclib.mp
local net = net
local table_maxn = table.maxn
local netStreamSend = "esclib.netstream"

esclib.netstream = esclib.netstream or {}
local netstream = esclib.netstream
netstream.checks = netstream.checks or {}
local checks = netstream.checks
netstream.receivers = netstream.receivers or {}
local receivers = netstream.receivers

local concat = table.concat
local pack = function(t, n)
	local buffer = {}
	mp.packers["array"](buffer, t, n)
	return concat(buffer)
end

if SERVER then
	util.AddNetworkString(netStreamSend)

	local player_GetAll = player.GetAll
	function netstream.Start(ply, name, ...)
		local ply_type = type(ply)
		if ply_type ~= "Player" and ply_type ~= "table" then
			ply = player_GetAll()
		end

		local encoded_data = pack({...}, select("#", ...))
		local length = #encoded_data

		net.Start(netStreamSend)
			net.WriteString(name)
			net.WriteUInt(length, 17)
			net.WriteData(encoded_data, length)
		net.Send(ply)
	end

	function netstream.Hook(name, callback, check)
		receivers[name] = callback
		if type(check) == "function" then
			checks[name] = check
        else
            checks[name] = nil
        end
	end

    function netstream.HookRemove(name)
        receivers[name] = nil
        checks[name] = nil
    end

	--Alias
	function netstream.Unhook(name)
		netstream.HookRemove(name)
	end

    function netstream.OnRequest(name, callback, check)
        netstream.Hook(name, function(ply, hook_name, ...)
            local status, response = xpcall(callback, function(err)
				print( "ERROR: ", err )
				debug.Trace()

				return err
			end, ply, ...)

            if not status then
                error(response)
                return
            end

            if not istable(response) then
                error("Request handler return non table answer!")
            end
    
            netstream.Start(ply, hook_name, unpack(response))
        end, check)
    end

	net.Receive(netStreamSend, function(_, ply)
		local name = net.ReadString()

		local callback = receivers[name]
		if not callback then return end

		local length = net.ReadUInt(17)

		local check = checks[name]
		if check and check(ply, length) == false then return end

		local data = net.ReadData(length)

		local status
		status, data = pcall(mp.unpack, data)
		if not status or not istable(data) then return end

		callback(ply, unpack(data, 1, table_maxn(data)))
	end)
else
	checks = nil

	function netstream.Start(name, ...)
		local encoded_data = pack({...}, select("#", ...))
		local length = #encoded_data

		net.Start(netStreamSend)
			net.WriteString(name)
			net.WriteUInt(length, 17)
			net.WriteData(encoded_data, length)
		net.SendToServer()
	end

	function netstream.Hook(name, callback)
		receivers[name] = callback
	end

    function netstream.HookRemove(name)
        receivers[name] = nil
    end

    function netstream.Request(name, timeout, callback, on_timeout, ...)
        assert(name ~= "", "Name must be provided")
        timeout = timeout or 3
		local unique_id = tostring(os.time()) .. "_" .. tostring(math.random(1, 99999))
        local timer_name = "esclib.netstream." .. name .. "_" .. unique_id
		local hook_name = name.."_"..unique_id

        netstream.Hook(hook_name, function(...)
            timer.Remove(timer_name)

            local status, data = pcall(callback, ...)
			if not status then
				error(data)
			end
            netstream.HookRemove(hook_name)
            return data
        end)

        timer.Create(timer_name, timeout, 1, function()
            netstream.HookRemove(hook_name)
            if isfunction(on_timeout) then 
                on_timeout() 
            else
                esclib.addon:Print("[error] Timeout reached for netstream request: '" .. hook_name .. "' and no timeout handler found")
            end
        end)

        netstream.Start(name, hook_name, ...)
    end

	net.Receive(netStreamSend, function()
		local callback = receivers[net.ReadString()]
		if not callback then return end

		local length = net.ReadUInt(17)
		local data = net.ReadData(length)

		data = mp.unpack(data)
		callback(unpack(data, 1, table_maxn(data)))
	end)
end