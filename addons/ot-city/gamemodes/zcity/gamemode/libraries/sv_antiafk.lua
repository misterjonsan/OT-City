local AfkToSpectTime = 300

local function stopAFK(ply)
    if not IsValid(ply) then return end
    ply.afkTime = 0
    ply.afkTime2 = 0
    ply.afkIsIdle = nil
end

hook.Add("PlayerInitialSpawn", "ZB_AntiAfk", function(ply)
    ply.afkTime = 0
    ply.afkTime2 = 0
    ply.afkIsIdle = true
end)

timer.Create("ZB_AntiAfkThink", 10, 0, function()
    if GetConVar("zb_dev"):GetBool() then return end

    for _, ply in player.Iterator() do
        if not IsValid(ply) or ply:IsBot() or ply:IsSuperAdmin() then continue end
        
        if ply:Alive() and not ply.organism.otrub then
            ply.afkTime = ply.afkTime + 10
        end

        if not ply:Alive() then
            ply.afkTime2 = ply.afkTime2 + 10
        end

        if ply.organism.otrub then
            ply.afkTime = 0
        end
        
        if ply.afkTime > AfkToSpectTime and ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
            if ply:Alive() then ply:Kill() end
            ply:SetTeam(TEAM_SPECTATOR)
            PrintMessage(HUD_PRINTTALK, ply:Name() .. " был переведён в наблюдатели из-за длительного AFK.")
        end

        if ply:Team() == TEAM_SPECTATOR and not ply:IsAdmin() then
            ply.afkTime = ply.afkTime + 10
        end

        if ply.afkTime > AfkToSpectTime * 2 then
            ply:Kick("AFK")
        end
    end
end)

hook.Add("KeyPress", "ZB_AntiAfk", stopAFK)
hook.Add("HG_PlayerSay", "ZB_AntiAfk", stopAFK)