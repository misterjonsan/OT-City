if SERVER then
    util.AddNetworkString("server_upwatch")

    local isMessageSending = false
    timer.Create("server_upwatch", 1, 0, function()
        if isMessageSending then return end
        isMessageSending = true
        net.Start("server_upwatch")
        net.Broadcast()
        isMessageSending = false
    end)

    return
end