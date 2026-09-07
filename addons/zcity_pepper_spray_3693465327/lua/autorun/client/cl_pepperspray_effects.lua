local SPRAY_THRESHOLD = 2
hook.Add("HUDPaint", "PepperSprayVisuals", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local exposure   = ply:GetNWFloat("PS_Exposure", 0)
    local blindEnd   = ply:GetNWFloat("PS_BlindEndTime", 0)
    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
    local lingeringTint = ply:GetNWFloat("PS_LingeringTint", 0)
    if lingeringTint > 0 and (blindEnd <= 0 or CurTime() >= blindEnd) and recovStart <= 0 then
        local intensity = math.Clamp(lingeringTint / 100, 0, 1)
        local alpha = intensity * 200
        surface.SetDrawColor(255, 60, 0, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        local pulse = math.sin(CurTime() * 8) * 0.3 + 0.7
        surface.SetDrawColor(255, 30, 0, alpha * 0.4 * pulse)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    if recovStart > 0 and CurTime() - recovStart < 5 then
        local fade = 1 - math.Clamp((CurTime() - recovStart) / 5, 0, 1)
        surface.SetDrawColor(255, 80, 0, fade * 150)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)
hook.Add("RenderScreenspaceEffects", "PepperSprayVisualsBlur", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local exposure = ply:GetNWFloat("PS_Exposure", 0)
    local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
    local lingeringTint = ply:GetNWFloat("PS_LingeringTint", 0)
    if lingeringTint > 0 and (blindEnd <= 0 or CurTime() >= blindEnd) and recovStart <= 0 then
        local intensity = math.Clamp(lingeringTint / 100, 0, 1)
        if intensity > 0.1 then
            DrawToyTown(2, intensity * 15 * (ScrH() / 1080))
        end
        if intensity > 0.5 then
            local blurAmt = (intensity - 0.5) * 2
            DrawMotionBlur(0.1, blurAmt * 0.8, 0.01)
        end
    end
    if recovStart > 0 and CurTime() - recovStart < 5 then
        local fade = 1 - math.Clamp((CurTime() - recovStart) / 5, 0, 1)
        if fade > 0.1 then
            DrawToyTown(1, fade * 8 * (ScrH() / 1080))
        end
    end
end)

