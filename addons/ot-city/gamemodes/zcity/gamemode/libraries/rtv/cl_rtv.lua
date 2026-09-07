local maps = {}
local timeLeft = 0
local votes = {}
local winmap = ""
local rtvStarted = false
local rtvEnded = false
local VoteCD = 0

local VOTE_DURATION = 200
local EARLY_FINISH_PERCENT = 0.8
local EARLY_FINISH_COUNTDOWN = 10

surface.CreateFont("VoteMap_Title", {
    font = "Montserrat SemiBold",
    size = 32,
    weight = 700,
    antialias = true,
    extended = true
})

surface.CreateFont("VoteMap_Small", {
    font = "Montserrat Medium",
    size = 20,
    weight = 600,
    antialias = true,
    extended = true
})

local blurMat = Material("pp/blurscreen")

local bgImages = {
    "materials/votemaps.jpg",
    "materials/votemaps1.jpg",
    "materials/votemaps3.jpg"
}

local function getRandomBgMat()
    local validMats = {}
    for _, path in ipairs(bgImages) do
        local m = Material(path, "smooth noclamp")
        if not m:IsError() then
            table.insert(validMats, m)
        end
    end
    if #validMats > 0 then
        return validMats[math.random(#validMats)]
    end
    return nil
end

local function drawScreenBlur(amount, passes)
    local sw, sh = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(blurMat)
    for i = 1, passes do
        blurMat:SetFloat("$blur", (i / passes) * amount)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(0, 0, sw, sh)
    end
end

local function generateRoundedPoly(x, y, w, h, r)
    local poly = {}
    local segments = 8
    r = math.min(r, w / 2, h / 2)

    for i = 0, segments do
        local angle = math.rad(180 + (90 / segments) * i)
        table.insert(poly, { x = x + r + math.cos(angle) * r, y = y + r + math.sin(angle) * r })
    end
    for i = 0, segments do
        local angle = math.rad(270 + (90 / segments) * i)
        table.insert(poly, { x = x + w - r + math.cos(angle) * r, y = y + r + math.sin(angle) * r })
    end
    for i = 0, segments do
        local angle = math.rad(0 + (90 / segments) * i)
        table.insert(poly, { x = x + w - r + math.cos(angle) * r, y = y + h - r + math.sin(angle) * r })
    end
    for i = 0, segments do
        local angle = math.rad(90 + (90 / segments) * i)
        table.insert(poly, { x = x + r + math.cos(angle) * r, y = y + h - r + math.sin(angle) * r })
    end

    return poly
end

local function drawBlurRounded(x, y, w, h, radius, amount, passes)
    amount = amount or 6
    passes = passes or 3

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.OverrideColorWriteEnable(true, false)

    local poly = generateRoundedPoly(x, y, w, h, radius)
    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawPoly(poly)

    render.OverrideColorWriteEnable(false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(blurMat)

    for i = 1, passes do
        blurMat:SetFloat("$blur", (i / passes) * amount)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end

    render.SetStencilEnable(false)
end

local vm = {
    open = false,
    maps = {},
    voteData = {},
    selected = nil,
    timeLeft = 0,
    openTime = 0,
    winner = nil,
    bgMat = nil,
    voteEndTime = 0,
    earlyCountdownActive = false,
    earlyCountdownEndTime = 0
}

local matCache = {}
local defaultMapIcon = Material("icon64/map.png", "smooth noclamp")
if defaultMapIcon:IsError() then
    defaultMapIcon = Material("icon64/tool.png", "smooth noclamp")
end

local function getMapMat(name)
    if matCache[name] ~= nil then
        return matCache[name]
    end

    if name == "random" then
        local m = Material("icon64/random.png", "smooth noclamp")
        if m:IsError() then
            m = Material("icon64/tool.png", "smooth noclamp")
        end
        matCache[name] = not m:IsError() and m or false
        return matCache[name]
    end

    local dataPaths = {
        "map_thumbnails/maps/thumb/" .. name .. ".png",
        "map_thumbnails/maps/thumb/" .. name .. ".jpg"
    }

    for _, path in ipairs(dataPaths) do
        if file.Exists(path, "DATA") then
            local mat = Material("data/" .. path, "smooth noclamp")
            if not mat:IsError() then
                matCache[name] = mat
                return mat
            end
        end
    end

    local fallbackPaths = {
        "maps/thumb/" .. name .. ".png",
        "maps/thumb/" .. name .. ".jpg"
    }

    for _, path in ipairs(fallbackPaths) do
        local mat = Material(path, "smooth noclamp")
        if not mat:IsError() then
            matCache[name] = mat
            return mat
        end
    end

    matCache[name] = false
    return false
end

local prefixes = {
    "gm_", "rp_", "ttt_", "cs_", "de_", "mg_", "zs_", "dm_",
    "prop_", "ph_", "arena_", "jail_", "ba_", "bhop_", "surf_", "kz_", "jb_", "gg_"
}

local function displayName(name)
    if name == "random" then return "Случайная карта" end
    for _, p in ipairs(prefixes) do
        if name:sub(1, #p) == p then
            return string.gsub(name:sub(#p + 1), "_", " ")
        end
    end
    return string.gsub(name, "_", " ")
end

local function drawBackground(a)
    local sw, sh = ScrW(), ScrH()

    if vm.bgMat then
        surface.SetDrawColor(255, 255, 255, math.min(a, 255))
        surface.SetMaterial(vm.bgMat)
        surface.DrawTexturedRect(0, 0, sw, sh)
    end

    drawScreenBlur(8, 4)

    surface.SetDrawColor(0, 0, 0, math.min(a * 0.35, 80))
    surface.DrawRect(0, 0, sw, sh)
end

local function drawRoundedImageStencil(mat, x, y, w, h, r, a)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilTestMask(0xFF)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_NEVER)
    render.SetStencilFailOperation(STENCIL_REPLACE)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

    local poly = generateRoundedPoly(x, y, w, h, r)
    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawPoly(poly)

    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

    surface.SetDrawColor(255, 255, 255, a)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, w, h)

    render.SetStencilEnable(false)
end

local function getHumanCount()
    local humans = 0
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then
            humans = humans + 1
        end
    end
    return humans
end

local function getTotalVotes()
    local total = 0
    for _, count in pairs(votes) do
        total = total + count
    end
    return total
end

local function updateVoteTimerState()
    if not vm.open or rtvEnded then return end

    local humans = getHumanCount()
    local totalVotes = getTotalVotes()
    local neededVotes = humans > 0 and math.ceil(humans * EARLY_FINISH_PERCENT) or 0

    if not vm.earlyCountdownActive and neededVotes > 0 and totalVotes >= neededVotes then
        vm.earlyCountdownActive = true
        vm.earlyCountdownEndTime = CurTime() + EARLY_FINISH_COUNTDOWN
    end

    if vm.earlyCountdownActive then
        vm.timeLeft = math.max(0, vm.earlyCountdownEndTime - CurTime())
    else
        vm.timeLeft = math.max(0, vm.voteEndTime - CurTime())
    end
end

local function buildVoteData()
    local data = {}
    local total = getTotalVotes()

    for _, name in ipairs(vm.maps) do
        local count = votes[name] or 0
        data[name] = {
            count = count,
            percent = total > 0 and math.Round(count / total * 100) or 0
        }
    end

    return data
end

local function drawCard(x, y, w, h, name, vdata, a)
    local isWinner = rtvEnded and name == winmap
    local pad = 4
    local imgH = math.floor(h * 0.82)
    local nameH = h - imgH

    drawBlurRounded(x, y, w, h, 8, 6, 3)
    draw.RoundedBox(8, x, y, w, h, Color(11, 11, 11, math.min(a * 0.94, 240)))

    if isWinner then
        surface.SetDrawColor(255, 215, 0, math.min(a, 255))
        surface.DrawOutlinedRect(x - 2, y - 2, w + 4, h + 4, 2)
    end

    local mat = getMapMat(name)
    if mat then
        drawRoundedImageStencil(mat, x + pad, y + pad, w - pad * 2, imgH - pad, 6, a)
    else
        draw.RoundedBox(6, x + pad, y + pad, w - pad * 2, imgH - pad, Color(11, 11, 11, 240))
        draw.SimpleText("NO IMAGE", "VoteMap_Small", x + w / 2, y + imgH / 2, Color(80, 80, 80, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    draw.SimpleText(displayName(name), "VoteMap_Small", x + w / 2, y + imgH + nameH / 2 - 2, Color(255, 255, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if vdata then
        local str = vdata.count .. " гол. | " .. vdata.percent .. "%"
        draw.SimpleText(str, "VoteMap_Small", x + w / 2, y + h + 4, Color(255, 255, 255, math.min(a * 0.85, 200)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

local function calcLayout(mapsList, sw, sh)
    local count = #mapsList
    local perRow = math.min(6, count)
    local cardW, cardH = 200, 140

    if count == 1 then
        cardW, cardH, perRow = 260, 165, 1
    elseif count == 2 then
        cardW, cardH, perRow = 240, 155, 2
    elseif count <= 4 then
        perRow = count
    end

    local spacing = 20
    local rows = math.ceil(count / perRow)
    local totalH = rows * cardH + (rows - 1) * (spacing + 28)
    local startY = math.max(120, (sh - totalH) / 2 + 40)

    return cardW, cardH, spacing, perRow, rows, startY
end

local closeHoverAlpha = 0
local closeHovered = false

local function drawCloseBtn(sw)
    local s = 32
    local x, y = sw - s - 14, 14
    local mx, my = gui.MouseX(), gui.MouseY()

    closeHovered = mx >= x and mx <= x + s and my >= y and my <= y + s

    local targetAlpha = closeHovered and 255 or 0
    closeHoverAlpha = Lerp(FrameTime() * 10, closeHoverAlpha, targetAlpha)

    if closeHoverAlpha > 1 then
        draw.RoundedBox(30, x, y, s, s, Color(255, 255, 255, closeHoverAlpha))
    end

    local crossAlpha = closeHoverAlpha / 255
    local col = math.floor(Lerp(crossAlpha, 255, 0))
    local crossColor = Color(col, col, col, 255)
    local padding = 8

    surface.SetDrawColor(crossColor)
    for i = -1, 1 do
        surface.DrawLine(x + padding + i, y + padding, x + s - padding + i, y + s - padding)
        surface.DrawLine(x + s - padding + i, y + padding, x + padding + i, y + s - padding)
    end

    return x, y, s
end

local function drawWinner()
    local sw, sh = ScrW(), ScrH()
    local elapsed = CurTime() - vm.openTime
    local a = math.min(elapsed / 0.4, 1) * 255
    local scale = math.ease and math.ease.OutElastic and math.ease.OutElastic(math.min(elapsed / 0.7, 1)) or math.min(elapsed / 0.7, 1)

    drawBackground(a)

    draw.SimpleText("ПОБЕДИТЕЛЬ", "VoteMap_Title", sw / 2, sh / 2 - 140, Color(255, 255, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local cw = 230 * scale
    local ch = 165 * scale
    drawCard(sw / 2 - cw / 2, sh / 2 - ch / 2, cw, ch, vm.winner, nil, a)
end

local function drawVote()
    local sw, sh = ScrW(), ScrH()
    local elapsed = CurTime() - vm.openTime
    local a = math.Clamp(elapsed / 0.35, 0, 1) * 255

    drawBackground(a)

    local cardW, cardH, spacing, perRow, rows, startY = calcLayout(vm.maps, sw, sh)

    draw.SimpleText("ВЫБЕРИТЕ КАРТУ", "VoteMap_Title", sw / 2, startY - 70, Color(255, 255, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local timeStr
    if vm.earlyCountdownActive then
        timeStr = "Финальный отсчёт: " .. math.max(0, math.ceil(vm.timeLeft)) .. " сек"
    else
        timeStr = "Осталось: " .. math.max(0, math.ceil(vm.timeLeft)) .. " сек"
    end
    draw.SimpleText(timeStr, "VoteMap_Title", sw / 2, startY - 34, Color(255, 255, 255, math.min(a * 0.85, 200)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    for i, name in ipairs(vm.maps) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local rowCount = math.min(perRow, #vm.maps - row * perRow)
        local rowW = rowCount * cardW + (rowCount - 1) * spacing
        local rx = (sw - rowW) / 2
        local x = rx + col * (cardW + spacing)
        local y = startY + row * (cardH + spacing + 28)

        drawCard(x, y, cardW, cardH, name, vm.voteData[name], a)
    end

    drawCloseBtn(sw)
end

hook.Add("HUDPaint", "ZB_RTV_Draw", function()
    if vm.winner then
        drawWinner()
        return
    end

    if vm.open then
        drawVote()
    end
end)

hook.Add("GUIMousePressed", "ZB_RTV_Click", function(code)
    if code ~= MOUSE_LEFT then return end
    if vm.winner then return end
    if not vm.open then return end

    local sw, sh = ScrW(), ScrH()
    local mx, my = gui.MouseX(), gui.MouseY()

    local cs = 32
    local cx = sw - cs - 14
    local cy = 14

    if mx >= cx and mx <= cx + cs and my >= cy and my <= cy + cs then
        vm.open = false
        gui.EnableScreenClicker(false)
        return
    end

    local cardW, cardH, spacing, perRow, rows, startY = calcLayout(vm.maps, sw, sh)

    for i, name in ipairs(vm.maps) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local rowCount = math.min(perRow, #vm.maps - row * perRow)
        local rowW = rowCount * cardW + (rowCount - 1) * spacing
        local rx = (sw - rowW) / 2
        local x = rx + col * (cardW + spacing)
        local y = startY + row * (cardH + spacing + 28)

        if mx >= x and mx <= x + cardW and my >= y and my <= y + cardH then
            if VoteCD > CurTime() then return end
            vm.selected = name
            net.Start("ZB_RockTheVote_vote")
                net.WriteString(name)
            net.SendToServer()
            VoteCD = CurTime() + 1
            surface.PlaySound("click.wav")
            return
        end
    end
end)

hook.Add("Think", "ZB_RTV_Think", function()
    if vm.open then
        updateVoteTimerState()
    end
end)

hook.Add("StartCommand", "ZB_RTV_Block", function(_, cmd)
    if vm.open or vm.winner then
        cmd:ClearMovement()
        cmd:ClearButtons()
    end
end)

function zb.RTVMenu()
    system.FlashWindow()
    vm.open = true
    vm.winner = nil
    vm.openTime = CurTime()
    vm.voteData = buildVoteData()
    vm.voteEndTime = CurTime() + VOTE_DURATION
    vm.timeLeft = VOTE_DURATION
    vm.earlyCountdownActive = false
    vm.earlyCountdownEndTime = 0
    if not vm.bgMat then
        vm.bgMat = getRandomBgMat()
    end
    for _, name in ipairs(vm.maps) do
        getMapMat(name)
    end
    updateVoteTimerState()
    gui.EnableScreenClicker(true)
end

function zb.StartRTV()
    maps = net.ReadTable()
    timeLeft = VOTE_DURATION
    votes = {}
    winmap = ""
    rtvStarted = true
    rtvEnded = false

    vm.maps = maps
    vm.timeLeft = VOTE_DURATION
    vm.voteData = {}
    vm.selected = nil
    vm.winner = nil
    vm.bgMat = getRandomBgMat()
    vm.voteEndTime = CurTime() + VOTE_DURATION
    vm.earlyCountdownActive = false
    vm.earlyCountdownEndTime = 0

    zb.RTVMenu()
end

net.Receive("RTVMenu", function()
    if not rtvStarted then return end
    vm.maps = maps
    vm.timeLeft = math.max(0, vm.timeLeft)
    vm.voteData = buildVoteData()
    vm.winner = nil
    vm.openTime = CurTime()
    if not vm.bgMat then
        vm.bgMat = getRandomBgMat()
    end
    vm.open = true
    updateVoteTimerState()
    gui.EnableScreenClicker(true)
end)

function zb.RTVregVote()
    votes = net.ReadTable()
    vm.voteData = buildVoteData()
    updateVoteTimerState()
end

function zb.EndRTV()
    winmap = net.ReadString()
    rtvEnded = true
    vm.open = false
    vm.winner = winmap
    vm.openTime = CurTime()
    vm.earlyCountdownActive = false
    vm.earlyCountdownEndTime = 0
    gui.EnableScreenClicker(false)
    surface.PlaySound("yes.wav")
end

net.Receive("ZB_RockTheVote_start", zb.StartRTV)
net.Receive("ZB_RockTheVote_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RockTheVote_end", zb.EndRTV)