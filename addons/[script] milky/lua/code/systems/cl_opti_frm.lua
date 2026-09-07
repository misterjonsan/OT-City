local nxtframe, framerate = 0, 1 / 15

local RecalcRate do
    local tab = {30, 60, 120, 122, 140, 144, 240}

    function RecalcRate()
        local prev, rate = 1, GetConVarNumber'fps_max'
        if rate == 0 then rate = 300 end
        for _, v in ipairs(tab) do
            if rate < v then return prev end
            prev = v
        end
        return 240
    end

    function DynFrameTime()
        return framerate
    end
end

do
    local SetMaterial, DrawScreenQuad, CopyRenderTargetToTexture, RenderHUD, IsValid =
        render.SetMaterial, render.DrawScreenQuad, render.CopyRenderTargetToTexture, render.RenderHUD,
        IsValid
    local w, h = ScrW(), ScrH()
    local name = Format('__screenspace_%u_%u_%u', w, h, os.time())
    local tex0 = GetRenderTargetEx(name, w, h,
            4, 2, 2 + 4 + 8 + 16 + 256 + 512, 4, 2)
    local mat = CreateMaterial(name, 'UnlitGeneric', {
        ['$basetexture'] = tex0:GetName(),
        ['$translucent'] = '0',
        ['$no_fullbright'] = '1',
        ['$writez'] = '0',
        ['$nocull'] = '0',
        ['$nodecal'] = '1',
        ['$notint'] = '1',
        ['$nofog'] = '1'
    })

    local rendered = false
    local lastframe, world = 0

    hook.Add('RenderScene', '\0DynFPS', function()
        local now = SysTime()
        if now < nxtframe then
            SetMaterial(mat)
            DrawScreenQuad(true)

            if not IsValid(world) then world = vgui.GetWorldPanel() end
            RenderHUD(0, 0, w, h)
            world:PaintManual()
            return true
        end
        nxtframe, rendered, lastframe = now + framerate, true, now
    end)

    hook.Add('PreDrawHUD', '\0DynFPS', function()
        if rendered then
            rendered = false
            CopyRenderTargetToTexture(tex0)
        end
    end)
end

framerate = 1 / RecalcRate()
do
    local function Recalc()
        framerate = 1 / RecalcRate()
        hook.Remove('Think', '\0DynFPS_RecalcRate')
    end

    cvars.AddChangeCallback('fps_max', function()
        hook.Add('Think', '\0DynFPS_RecalcRate', Recalc)
    end)
end