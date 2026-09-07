local function spiralGrid(rings)
    local grid = {}
    local col, row

    for ring = 1, rings do
        row = ring
        for col = 1 - ring, ring do
            grid[#grid + 1] = { col, row }
        end

        col = ring
        for row = ring - 1, -ring, -1 do
            grid[#grid + 1] = { col, row }
        end

        row = -ring
        for col = ring - 1, -ring, -1 do
            grid[#grid + 1] = { col, row }
        end

        col = -ring
        for row = 1 - ring, ring do
            grid[#grid + 1] = { col, row }
        end
    end

    return grid
end

local tpGrid = spiralGrid(24)

local vec32 = Vector(0, 0, 32)

function MODE:BringPlayers(players, pos, angle)
    local cell_size = 50
    local teleportable_plys = table.Copy(players)

    for i = 1, #tpGrid do
        local c = tpGrid[i][1]
        local r = tpGrid[i][2]

        local target = table.remove(teleportable_plys)
        if not target then break end

        local yawForward = angle.yaw
        local offset = Vector(r * cell_size, c * cell_size, 0)
        offset:Rotate(Angle(0, yawForward, 0))

        local t = {}
        t.start = pos + vec32
        t.filter = players
        t.endpos = t.start + offset

        local tr = util.TraceEntity(t, target)
        if tr.Hit then
            teleportable_plys[#teleportable_plys + 1] = target
        else
            if target:InVehicle() then target:ExitVehicle() end
            target:SetPos(t.endpos)
            target:SetEyeAngles((pos - t.endpos):Angle())
            target:SetLocalVelocity(Vector(0, 0, 0))
        end
    end

    for i = 1, #teleportable_plys do
        teleportable_plys[i]:SetPos(pos)
    end
end