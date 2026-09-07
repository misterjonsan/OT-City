local FOG_DISTANCE = 2800
local FOG_THICKNESS = 50
local FOG_COLOR = Color(83, 83, 83)
local DRAW_SKYBOX_FILL = false

local NO_FOG_MAPS = {
    grd_indianapolis_day = true,
    grd_indianapolis_night = true
}

local fpsfog_no_fog = NO_FOG_MAPS[string.lower(game.GetMap() or "")] == true

local fpsfog_SC_pos = Vector(0, 0, 0)
local fpsfog_SC_scale = 1
local fpsfog_skycamera
local constructmat = Material("gm_construct/color_room")
local fpsfog_controller_name = "fpsfog_controller"
local fpsfog_target_farz = FOG_DISTANCE + 64

local function fpsfog_UpdateSkyCamera()
    fpsfog_skycamera = ents.FindByClass("sky_camera")[1]
    if IsValid(fpsfog_skycamera) then
        local kv = fpsfog_skycamera:GetKeyValues()
        fpsfog_SC_scale = tonumber(kv and kv.scale) or 1
        fpsfog_SC_pos = fpsfog_skycamera:GetPos()
    else
        fpsfog_SC_scale = 1
        fpsfog_SC_pos = Vector(0, 0, 0)
    end
end

if SERVER then
    local function fpsfog_DisableFogController(ent)
        if not IsValid(ent) then return end
        ent:SetKeyValue("fogenable", "0")
        ent:SetKeyValue("fogblend", "0")
        ent:SetKeyValue("use_angles", "0")
        ent:SetKeyValue("fogstart", "0")
        ent:SetKeyValue("fogend", "0")
        ent:SetKeyValue("fogmaxdensity", "0")
        ent:SetKeyValue("farz", "999999")
        ent:Spawn()
        ent:Activate()
    end

    local function fpsfog_DisableFogAll()
        for _, ent in ipairs(ents.FindByClass("env_fog_controller")) do
            fpsfog_DisableFogController(ent)
        end
    end

    local function fpsfog_ApplyFogController(ent)
        if not IsValid(ent) then return end

        if fpsfog_no_fog then
            fpsfog_DisableFogController(ent)
            return
        end

        ent:SetKeyValue("fogenable", "1")
        ent:SetKeyValue("fogblend", "0")
        ent:SetKeyValue("use_angles", "0")
        ent:SetKeyValue("fogcolor", string.format("%d %d %d", FOG_COLOR.r, FOG_COLOR.g, FOG_COLOR.b))
        ent:SetKeyValue("fogcolor2", string.format("%d %d %d", FOG_COLOR.r, FOG_COLOR.g, FOG_COLOR.b))
        ent:SetKeyValue("fogstart", tostring(math.max(0, FOG_DISTANCE - FOG_DISTANCE * (FOG_THICKNESS / 100))))
        ent:SetKeyValue("fogend", tostring(FOG_DISTANCE))
        ent:SetKeyValue("farz", tostring(fpsfog_target_farz))
        ent:Spawn()
        ent:Activate()
    end

    local function fpsfog_GetOrCreateController()
        local controllers = ents.FindByClass("env_fog_controller")
        for _, ent in ipairs(controllers) do
            if IsValid(ent) and ent:GetName() == fpsfog_controller_name then
                return ent
            end
        end

        local ent = ents.Create("env_fog_controller")
        if not IsValid(ent) then return nil end
        ent:SetName(fpsfog_controller_name)
        ent:SetPos(vector_origin)
        fpsfog_ApplyFogController(ent)
        return ent
    end

    local function fpsfog_SetFarZAll()
        for _, ent in ipairs(ents.FindByClass("env_fog_controller")) do
            if IsValid(ent) then
                if fpsfog_no_fog then
                    fpsfog_DisableFogController(ent)
                else
                    ent:SetKeyValue("farz", tostring(fpsfog_target_farz))
                end
            end
        end
    end

    hook.Add("InitPostEntity", "fpsfog_postinit_always", function()
        fpsfog_UpdateSkyCamera()

        if fpsfog_no_fog then
            fpsfog_DisableFogAll()
            return
        end

        fpsfog_GetOrCreateController()
        fpsfog_SetFarZAll()
    end)

    hook.Add("PostCleanupMap", "fpsfog_postcleanup_always", function()
        timer.Simple(0, function()
            fpsfog_UpdateSkyCamera()

            if fpsfog_no_fog then
                fpsfog_DisableFogAll()
                return
            end

            fpsfog_GetOrCreateController()
            fpsfog_SetFarZAll()
        end)
    end)

    hook.Add("OnEntityCreated", "fpsfog_onentitycreated_always", function(ent)
        if not IsValid(ent) then return end
        if ent:GetClass() ~= "env_fog_controller" then return end

        timer.Simple(0, function()
            if not IsValid(ent) then return end

            if fpsfog_no_fog then
                fpsfog_DisableFogController(ent)
            else
                ent:SetKeyValue("farz", tostring(fpsfog_target_farz))
            end
        end)
    end)
else
    hook.Add("InitPostEntity", "fpsfog_postinit_always", function()
        fpsfog_UpdateSkyCamera()
    end)

    hook.Add("PreDrawOpaqueRenderables", "fpsfog_skybox_fill_always", function(depth, skybox)
        if fpsfog_no_fog then return end
        if not DRAW_SKYBOX_FILL then return end
        if not skybox then return end

        local view = render.GetViewSetup()
        if not view then return end

        local lookdir = view.angles
        local lookpos = view.origin
        local looknorm = Vector(1, 0, 0)
        looknorm:Rotate(lookdir)

        render.SetMaterial(constructmat)

        if fpsfog_SC_scale ~= 0 then
            render.DrawQuadEasy(
                (lookpos + looknorm * FOG_DISTANCE) / fpsfog_SC_scale + fpsfog_SC_pos,
                -looknorm,
                1000000,
                1000000,
                FOG_COLOR
            )
        else
            render.DrawQuadEasy(
                lookpos + looknorm * FOG_DISTANCE,
                -looknorm,
                1000000,
                1000000,
                FOG_COLOR
            )
        end
    end)

    hook.Add("SetupWorldFog", "fpsfog_worldfog_always", function()
        if fpsfog_no_fog then
            render.FogMode(MATERIAL_FOG_NONE)
            render.FogMaxDensity(0)
            render.FogStart(0)
            render.FogEnd(0)
            return true
        end

        local fogend = FOG_DISTANCE
        local fogstart = fogend - fogend * (FOG_THICKNESS / 100)

        render.FogMode(MATERIAL_FOG_LINEAR)
        render.FogColor(FOG_COLOR.r, FOG_COLOR.g, FOG_COLOR.b)
        render.FogMaxDensity(1)
        render.FogStart(fogstart)
        render.FogEnd(fogend)

        return true
    end)

    hook.Add("SetupSkyboxFog", "fpsfog_skyfog_always", function(scale)
        if fpsfog_no_fog then
            render.FogMode(MATERIAL_FOG_NONE)
            render.FogMaxDensity(0)
            render.FogStart(0)
            render.FogEnd(0)
            return true
        end

        local fogend = FOG_DISTANCE
        local fogstart = fogend - fogend * (FOG_THICKNESS / 100)

        render.FogMode(MATERIAL_FOG_LINEAR)
        render.FogColor(FOG_COLOR.r, FOG_COLOR.g, FOG_COLOR.b)
        render.FogMaxDensity(1)
        render.FogStart(fogstart * scale)
        render.FogEnd(fogend * scale)

        return true
    end)
end