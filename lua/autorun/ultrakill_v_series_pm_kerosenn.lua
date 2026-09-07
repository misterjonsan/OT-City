player_manager.AddValidModel( "Ultrakill - V Series - Feedbacker", "models/kerosenn/ultrakill/machine/v_series/playermodel/v_pm_feedbacker.mdl" )
player_manager.AddValidHands( "Ultrakill - V Series - Feedbacker", "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_feedbacker.mdl", 0, "00000000" )

hook.Add("PreDrawPlayerHands", "v_vm_feedbacker", function(hands, vm, ply, wpn)
    if IsValid(hands) and hands:GetModel() == "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_feedbacker.mdl" then
        hands:SetSkin(ply:GetSkin())
    end
end)

player_manager.AddValidModel( "Ultrakill - V Series - Knuckleblaster", "models/kerosenn/ultrakill/machine/v_series/playermodel/v_pm_knuckleblaster.mdl" )
player_manager.AddValidHands( "Ultrakill - V Series - Knuckleblaster", "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_knuckleblaster.mdl", 0, "00000000" )

hook.Add("PreDrawPlayerHands", "v_vm_knuckleblaster", function(hands, vm, ply, wpn)
    if IsValid(hands) and hands:GetModel() == "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_knuckleblaster.mdl" then
        hands:SetSkin(ply:GetSkin())
    end
end)

player_manager.AddValidModel( "Ultrakill - V Series - Whiplash", "models/kerosenn/ultrakill/machine/v_series/playermodel/v_pm_whiplash.mdl" )
player_manager.AddValidHands( "Ultrakill - V Series - Whiplash", "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_whiplash.mdl", 0, "00000000" )

hook.Add("PreDrawPlayerHands", "v_vm_whiplash", function(hands, vm, ply, wpn)
    if IsValid(hands) and hands:GetModel() == "models/kerosenn/ultrakill/machine/v_series/viewmodel/v_vm_whiplash.mdl" then
        hands:SetSkin(ply:GetSkin())
    end
end)



