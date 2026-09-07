if SERVER then return end

hook.Add("ChatText", "HideAllSystemMessages", function()
    return true
end)

local COLOR_WHITE = Color(255, 255, 255, 255)
local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
local textY = centerY + 128

hook.Add("PreRender", "monteract_load", function()
    cam.Start2D()
    draw.SimpleText("Загрузка...", "GModToolSubtitle", centerX, textY, COLOR_WHITE, TEXT_ALIGN_CENTER)
    cam.End2D()
end)

local opti_commands = {
    {"cl_updaterate", "20"},
    {"cl_cmdrate", "20"},
    {"cl_interp_ratio", "3"},
    {"cl_interp", "0.15"},
    {"cl_timeout", "600"},
    {"gmod_mcore_test", "1"},
    {"mat_queue_mode", "-1"},
    {"cl_threaded_client_leaf_system", "1"},
    {"cl_threaded_bone_setup", "1"},
    {"r_threaded_client_shadow_manager", "1"},
    {"r_threaded_renderables", "1"},
    {"r_threaded_particles", "1"},
    {"r_queued_ropes", "1"},
    {"studio_queue_mode", "1"},
    {"r_lod", "2"},
    {"r_decals", "4096"},
    {"r_decal_cullsize", "0"},
    {"violence_agibs", "1"},
    {"violence_hgibs", "1"},
    {"violence_ablood", "1"},
    {"violence_hblood", "1"},
    {"r_waterdrawreflection", "0"}
}

do
    local delay = 0
    for i = 1, #opti_commands do
        local cmd = opti_commands[i][1]
        local val = opti_commands[i][2]
        timer.Simple(delay, function()
            if not cmd then return end
            if val ~= nil then
                RunConsoleCommand(cmd, val)
                MsgC(Color(255, 255, 0), cmd, Color(255, 255, 255), " сделано ", Color(0, 255, 0), tostring(val), "\n")
            else
                RunConsoleCommand(cmd)
                MsgC(Color(255, 255, 0), cmd, Color(255, 255, 255), " установлено\n")
            end
        end)
        delay = delay + 0.15
    end

    timer.Simple(delay + 2, function()
        hook.Remove("PreRender", "monteract_load")
    end)
end

timer.Create("little_remove_ragdolls", 45, 0, function()
    for _, ent in ipairs(ents.FindByClass("C_ClientRagdoll")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
end)

local badhooks = {
    RenderScreenspaceEffects = {
        "RenderBloom",
        "RenderBokeh",
        "RenderMaterialOverlay",
        "RenderSharpen",
        "RenderSobel",
        "RenderStereoscopy",
        "RenderSunbeams",
        "RenderTexturize",
        "RenderToyTown"
    },
    PreDrawHalos = {
        "PropertiesHover"
    },
    RenderScene = {
        "RenderSuperDoF",
        "RenderStereoscopy"
    },
    PreRender = {
        "PreRenderFlameBlend"
    },
    PostRender = {
        "RenderFrameBlend",
        "PreRenderFrameBlend"
    },
    PostDrawEffects = {
        "RenderWidgets"
    },
    GUIMousePressed = {
        "SuperDOFMouseDown",
        "SuperDOFMouseUp"
    },
    Think = {
        "DOFThink"
    },
    PlayerTick = {
        "TickWidgets"
    },
    PlayerBindPress = {
        "PlayerOptionInput"
    },
    NeedsDepthPass = {
        "NeedsDepthPassBokeh"
    },
    OnGamemodeLoaded = {
        "CreateMenuBar"
    },
    OnEntityCreated = {
        "WidgetInit"
    }
}

local function RemoveHooks()
    for eventName, hookNames in pairs(badhooks) do
        for _, hookName in ipairs(hookNames) do
            hook.Remove(eventName, hookName)
        end
    end
end

timer.Simple(5, RemoveHooks)

timer.Simple(5, function()
    local hideHUDElements = {
        ["DarkRP_HUD"] = true,
        ["DarkRP_EntityDisplay"] = true,
        ["DarkRP_LocalPlayerHUD"] = true,
        ["DarkRP_Hungermod"] = true,
        ["DarkRP_Agenda"] = true,
        ["DarkRP_LockdownHUD"] = true,
        ["DarkRP_ArrestedHUD"] = true,
        ["CHudDamageIndicator"] = true
    }

    hook.Add("HUDShouldDraw", "HideDefaultDarkRPHud", function(name)
        if hideHUDElements[name] then
            return false
        end
    end)
end)

timer.Simple(5, function()
    local PLAYER = FindMetaTable("Player")
    if not PLAYER or not PLAYER.GetEyeTrace then return end

    local oldGetEyeTrace = PLAYER.GetEyeTrace
    local eyeTraceBuffer = nil
    local localPlayerCached = nil

    timer.Create("update_eye_trace", 0.05, 0, function()
        localPlayerCached = LocalPlayer()
        if not IsValid(localPlayerCached) then return end
        eyeTraceBuffer = oldGetEyeTrace(localPlayerCached)
    end)

    PLAYER.GetEyeTrace = function(ent, force)
        if force then
            return oldGetEyeTrace(ent)
        end

        if not IsValid(ent) then
            return oldGetEyeTrace(ent)
        end

        if ent ~= LocalPlayer() then
            return oldGetEyeTrace(ent)
        end

        return eyeTraceBuffer or oldGetEyeTrace(ent)
    end
end)
