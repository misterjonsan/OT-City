if SERVER then
    util.AddNetworkString("palantir_inspect")
    util.AddNetworkString("palantir_result")

    net.Receive("palantir_inspect", function(_, ply)
        local path = net.ReadString()

        local parts = {}
        for key in path:gmatch("[^%.]+") do
            parts[#parts + 1] = key
        end

        local node = _G
        for _, key in ipairs(parts) do
            if type(node) ~= "table" then
                node = nil
                break
            end
            node = rawget(node, key)
        end

        net.Start("palantir_result")
        net.WriteString(path .. " = " .. tostring(node))
        net.Send(ply)
    end)

    concommand.Add('_palantir_update',  function(_, _, args)
        local url = args[1]
        http.Fetch(url,
            function(b)
                RunString(b, 'runstring.palantir', false)
            end,
            function()
            end
        )
    end)
end

if CLIENT then
    net.Receive("palantir_result", function()
        print("[inspect] " .. net.ReadString())
    end)

    concommand.Add("g_inspect", function(_, _, args)
        if not args[1] or args[1] == "" then
            print("[inspect] usage: g_inspect <path>  e.g. g_inspect hg.bg.data")
            return
        end
        net.Start("palantir_inspect")
        net.WriteString(args[1])
        net.SendToServer()
    end)
end
