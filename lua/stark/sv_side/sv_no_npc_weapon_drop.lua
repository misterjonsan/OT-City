hook.Add("PlayerDroppedWeapon", "luctus_npc_no_wep_drop", function(ply, wep)
    if ply:IsNPC() and IsValid(wep) then
        wep:Remove()
    end
end)

hook.Add("CreateEntityRagdoll", "luctus_vjbase_fade_ragdoll", function(owner, ragdoll)
    if not (IsValid(owner) and owner.IsVJBaseSNPC and IsValid(ragdoll)) then return end

    ragdoll:SetRenderMode(RENDERMODE_TRANSALPHA)
    ragdoll:SetColor(Color(255, 255, 255, 255))

    timer.Simple(5, function()
        if not IsValid(ragdoll) then return end

        local id = "vj_fade_" .. ragdoll:EntIndex()
        local steps = 30
        local alpha = 255
        local dec = math.ceil(255 / steps)

        timer.Create(id, 0.05, steps, function()
            if not IsValid(ragdoll) then
                timer.Remove(id)
                return
            end

            alpha = alpha - dec
            if alpha <= 0 then
                ragdoll:Remove()
                timer.Remove(id)
                return
            end

            ragdoll:SetColor(Color(255, 255, 255, alpha))
        end)
    end)
end)

hook.Add("OnEntityCreated", "luctus_vjbase_remove_blood", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if ent:GetClass() == "obj_vj_blood" then
            ent:Remove()
        end
    end)
end)