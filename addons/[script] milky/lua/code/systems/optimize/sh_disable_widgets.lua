timer.Simple(2, function()
if SERVER then
	function GAMEMODE:CanEditVariable(ent, pl, key, val, editor)
		return false
	end

	if timer.Exists("CheckHookTimes") then
		timer.Remove("CheckHookTimes")
	end

	timer.Remove("HostnameThink")
end

hook.Add("PreGamemodeLoaded", "DisableWidgets", function()
	widgets.PlayerTick = function() end
	hook.Remove("PlayerTick", "TickWidgets")
	hook.Remove("PostDrawEffects", "RenderWidgets")
end)
end)