if not sam or not sam.command or not sam.player then return end

local function voteModeDone(options, results, voters)
    local winner
    local winnernum = 0

    for i = 1, #options do
        local n = results[i] or 0
        if n > winnernum then
            winner = i
            winnernum = n
        end
    end

    local str
    if not winner then
        str = "Результаты голосования: ни один режим не победил, потому что никто не проголосовал!"
    else
        local mode = zb and zb.modes and zb.modes[options[winner]] or nil
        if mode and mode.CanLaunch and mode:CanLaunch() then
            str = "Результаты голосования: режим '" .. options[winner] .. "' победил. (" .. winnernum .. "/" .. voters .. ")"
            NextRound(options[winner])
        else
            str = "Результаты голосования: режим '" .. options[winner] .. "' нельзя запустить."
        end
    end

    sam.player.send_message(nil, str)
    Msg(str .. "\n")
end

local function startVote(calling_ply, argv)
    calling_ply.CoolDownVote = calling_ply.CoolDownVote or 0
    if calling_ply.CoolDownVote > CurTime() then
        sam.player.send_message(calling_ply, "Подожди " .. math.Round(calling_ply.CoolDownVote - CurTime(), 1) .. " сек., прежде чем создавать новое голосование")
        return
    end
    calling_ply.CoolDownVote = CurTime() + 180

    if sam.vote and sam.vote.is_active and sam.vote.is_active() then
        sam.player.send_message(calling_ply, "Голосование уже идёт. Дождись окончания текущего.")
        return
    end

    for i = 2, #argv do
        for j = 1, i - 1 do
            if argv[j] == argv[i] then
                sam.player.send_message(calling_ply, "Режим " .. argv[i] .. " указан дважды. Попробуй ещё раз.")
                return
            end
        end
    end

    for _, modeName in ipairs(argv) do
        local mode = zb and zb.modes and zb.modes[modeName] or nil
        if not (mode and mode.CanLaunch and mode:CanLaunch()) then
            sam.player.send_message(calling_ply, "Режим '" .. modeName .. "' нельзя запустить.")
            return
        end
    end

    if #argv > 1 then
        sam.vote.create("Сменить режим на..", argv, 15, function(results, voters)
            voteModeDone(argv, results, voters)
        end)
        sam.player.send_message(nil, calling_ply:Name() .. " запустил голосование за режим.")
        if sam.log then sam.log(calling_ply, "запустил голосование за режим") end
    elseif #argv == 1 then
        sam.vote.create("Сменить режим на " .. argv[1] .. "?", { "Да", "Нет" }, 15, function(results, voters)
            local yesVotes = results[1] or 0
            local noVotes = results[2] or 0
            if yesVotes > noVotes then
                voteModeDone(argv, { [1] = yesVotes }, voters)
            else
                local str = "Результаты голосования: смена режима на '" .. argv[1] .. "' отклонена."
                sam.player.send_message(nil, str)
                if sam.log then sam.log(calling_ply, "голосование за режим отклонено для " .. argv[1]) end
                Msg(str .. "\n")
            end
        end)
        sam.player.send_message(nil, calling_ply:Name() .. " запустил голосование за режим " .. argv[1] .. ".")
        if sam.log then sam.log(calling_ply, "запустил голосование за режим " .. argv[1]) end
    else
        sam.player.send_message(calling_ply, "Нужно указать хотя бы один вариант для голосования.")
    end
end

sam.command.set_category("ZB")

sam.command.new("votemode")
    :SetPermission("votemode", "admin")
    :AddArg("text", { optional = false, multi = true })
    :Help("Запускает публичное голосование за режим.")
    :OnExecute(function(ply, modes)
        local argv = {}

        if istable(modes) then
            for i = 1, #modes do
                if isstring(modes[i]) and modes[i] ~= "" then
                    argv[#argv + 1] = modes[i]
                end
            end
        elseif isstring(modes) and modes ~= "" then
            for s in string.gmatch(modes, "%S+") do
                argv[#argv + 1] = s
            end
        end

        startVote(ply, argv)
    end)
:End()