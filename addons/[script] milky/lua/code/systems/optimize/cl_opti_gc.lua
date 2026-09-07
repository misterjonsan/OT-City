if SERVER then return end

collectgarbage("setpause", 110)
collectgarbage("setstepmul", 200)

local next_gc_step = 0
local emergency_threshold = 384000
local emergency_step = 256
local normal_step = 64
local idle_delay = 2
local busy_delay = 4

hook.Add("Think", "client_gc_soft", function()
    local ct = CurTime()
    if ct < next_gc_step then return end

    local mem = collectgarbage("count")
    local lp = LocalPlayer()
    local delay = idle_delay

    if IsValid(lp) then
        local vel = lp:GetVelocity():Length2DSqr()
        if vel > 40000 then
            delay = busy_delay
        end
    end

    if gui.IsGameUIVisible() or vgui.CursorVisible() then
        collectgarbage("step", normal_step * 2)
        next_gc_step = ct + 1
        return
    end

    if mem >= emergency_threshold then
        collectgarbage("step", emergency_step)
        next_gc_step = ct + 0.5
        return
    end

    collectgarbage("step", normal_step)
    next_gc_step = ct + delay
end)

timer.Create("client_gc_stabilizer", 30, 0, function()
    local mem = collectgarbage("count")
    if mem >= emergency_threshold then
        collectgarbage("step", emergency_step * 2)
    else
        collectgarbage("step", normal_step)
    end
end)