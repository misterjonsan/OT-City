--- Melon's Masks
--- https://github.com/melonstuff/melonsmasks/
--- Licensed under MIT

-- MIT License

-- Copyright (c) 2023 MelonStuff

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- Precache global functions to local variables for performance
local esclib = esclib
local get_var = function(...) return esclib.addon:GetVar(...) end
local bit_bor = bit.bor
local cam_End2D = cam.End2D
local cam_Start2D = cam.Start2D
local CreateMaterial = CreateMaterial
local GetRenderTargetEx = GetRenderTargetEx
local hook_Add = hook.Add
local IsValid = IsValid
local render_BlurRenderTarget = render.BlurRenderTarget
local render_Clear = render.Clear
local render_CopyTexture = render.CopyTexture
local render_OverrideBlend = render.OverrideBlend
local render_PopRenderTarget = render.PopRenderTarget
local render_PushRenderTarget = render.PushRenderTarget
local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
local ScrH = ScrH
local ScrW = ScrW
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local timer_Simple = timer.Simple
local ispanel = ispanel
local FrameNumber = FrameNumber
local _rt_FullFrameFB = _rt_FullFrameFB
local math_floor = math.floor
local CurTime = CurTime
local RealFrameTime = RealFrameTime
local math_max = math.max
local math_clamp = math.Clamp

----
---@module
---@name masks
---@realm CLIENT
----
---- An alternative to stencils that samples a texture
---- For reference:
----  The destination is what is being masked, so a multi stage gradient or some other complex stuff
----  The source is the text, or the thing with alpha
----
-- Re-use existing table to keep references valid across LuaRefresh
esclib.masks = esclib.masks or {}
local masks = esclib.masks

masks.source = {}
masks.dest   = {}
masks.blur   = {}
masks.last_time = 0

-- downscale factor for blur (0.25 => 1/4 size). Change if needed
masks.blur_scale = 0.25
masks.blur_every_n_frame = 2

local blur_mat = Material("pp/blurscreen")
blur_mat:SetFloat("$blur", 0)   -- constant value
blur_mat:Recompute()

local last_screen_effect_frame = -1 -- frame cache

local function UpdateScreenEffectTextureOnce()
    local frame = FrameNumber()
    if last_screen_effect_frame == frame then return end -- already updated this frame
    render_UpdateScreenEffectTexture()
    last_screen_effect_frame = frame
end

----
---@name masks.RecreateMaterials
----
---- Creates or recreates materials when screen size changes.
---- The engine caches GetRenderTargetEx calls, so we don't need to do it manually.
----
function masks.RecreateMaterials()
    local w, h = ScrW(), ScrH()
    local uid = w .. "_" .. h

    local source_rt = GetRenderTargetEx("EsclibMasks_Source"..uid, w, h, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit_bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)
    local dest_rt   = GetRenderTargetEx("EsclibMasks_Destination"..uid, w, h, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit_bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)

    -- blur render target (downscaled)
    local scale = masks.blur_scale or 1
    local bw = math_floor(w * scale + 0.5)
    local bh = math_floor(h * scale + 0.5)
    bw = math_max(bw, 1)
    bh = math_max(bh, 1)
    local blur_uid = uid .. "_" .. bw .. "x" .. bh
    local blur_rt   = GetRenderTargetEx("EsclibMasks_Blur"..blur_uid, bw, bh, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 256, 0, IMAGE_FORMAT_BGRA8888)

    masks.source = {
        rt = source_rt,
        mat = CreateMaterial("EsclibMasks_Source_Mat"..uid, "UnlitGeneric", {
            ["$basetexture"] = source_rt:GetName(),
            ["$translucent"] = "1",
            ["$vertexalpha"] = "1",
            ["$vertexcolor"] = "1",
        })
    }

    masks.dest = {
        rt = dest_rt,
        mat = CreateMaterial("EsclibMasks_Destination_Mat"..uid, "UnlitGeneric", {
            ["$basetexture"] = dest_rt:GetName(),
            ["$translucent"] = "1",
            ["$vertexalpha"] = "1",
            ["$vertexcolor"] = "1",
        })
    }

    masks.blur = {
        rt = blur_rt,
        mat = CreateMaterial("EsclibMasks_Blur_Mat"..blur_uid, "UnlitGeneric", {
            ["$basetexture"] = blur_rt:GetName(),
            ["$translucent"] = "1",
        })
    }
end

-- Create initial materials
masks.RecreateMaterials()

-- Initialize blur update timer
masks.last_time = 0

----
---@enumeration
---@name masks.KIND
----
---@enum (CUT)   Cuts the source out of the destination
---@enum (STAMP) Cuts the destination out of the source
----
---- Determines the type of mask were rendering
----
masks.KIND_CUT   = {BLEND_ZERO, BLEND_SRC_ALPHA, BLENDFUNC_ADD}
masks.KIND_STAMP = {BLEND_ZERO, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD}

-- Internal helper to apply the blend operation
local function ApplyBlend(kind)
    render_OverrideBlend(true, kind[1], kind[2], kind[3])
    surface_SetDrawColor(255, 255, 255)
    surface_SetMaterial(masks.source.mat)
    surface_DrawTexturedRect(0, 0, esclib.scrw, esclib.scrh)
    render_OverrideBlend(false)
end

----
---@name masks.Start
----
----
---- Starts the mask destination render
---- Whats between this and the `masks.Source` call is the destination
---- See the module declaration for an explaination
----
function masks.Start()
    render_PushRenderTarget(masks.dest.rt)
    render_Clear(0, 0, 0, 0, true, true)
    cam_Start2D()
end

----
---@name masks.Source
----
---- Stops the destination render
---- Whats between this and the `masks.End` call is the source
---- See the module declaration for an explaination
----
function masks.Source()
    cam_End2D()
    render_PopRenderTarget()

    render_PushRenderTarget(masks.source.rt)
    render_Clear(0, 0, 0, 0, true, true)
    cam_Start2D()
end

----
---@name masks.And
----
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
----
---- Renders the given kind of mask and continues the mask render
---- This can be used to layer masks
---- This must be called post [masks.Source]
---- You still need to call End
----
function masks.And(kind)
    cam_End2D()
    render_PopRenderTarget()

    render_PushRenderTarget(masks.dest.rt)
    cam_Start2D()
        ApplyBlend(kind)
    masks.Source()
end

----
---@name masks.End
----
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
---@arg (x:         number) The x coordinate to render the rectangle at, defaults to 0
---@arg (y:         number) The y coordinate to render the rectangle at, defaults to 0
---@arg (w:         number) The width of the rectangle to render
---@arg (h:         number) The height of the rectangle to render
----
---- Stops the source render and renders everything finally
---- See the module declaration for an explaination
----
function masks.End(kind, x, y, w, h)
    kind = kind or masks.KIND_CUT

    cam_End2D()
    render_PopRenderTarget()

    render_PushRenderTarget(masks.dest.rt)
    cam_Start2D()
        ApplyBlend(kind)
    cam_End2D()
    render_PopRenderTarget()

    surface_SetDrawColor(255, 255, 255)
    surface_SetMaterial(masks.dest.mat)
    surface_DrawTexturedRect(x or 0, y or 0, w or esclib.scrw, h or esclib.scrh)
end

----
---@name masks.EndToTexture
----
---@arg (tex:     ITexture)
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
----
---- Stops the source render and renders everything to the given ITexture
----
function masks.EndToTexture(texture, kind)
    kind = kind or masks.KIND_CUT

    cam_End2D()
    render_PopRenderTarget()

    render_PushRenderTarget(masks.dest.rt)
    cam_Start2D()
        ApplyBlend(kind)
    cam_End2D()
    render_PopRenderTarget()

    if IsValid(texture) then
        render_CopyTexture(masks.dest.rt, texture)
    end
end

----
---@name masks.UpdateBlur
---@arg (passes: number) The number of blur passes
---@arg (amount: number) The amount of blur for both X and Y axes
----
---- Captures the screen and blurs it, storing it for use with masks.DrawBlur.
---- Should be called in a hook like HUDPaintBackground.
----
function masks.UpdateBlur(passes, amount)
    -- if (not masks.blur) or (not IsValid(masks.blur.rt)) then return end

    passes = passes or 1
    amount = amount or 3

    UpdateScreenEffectTextureOnce()

    render_PushRenderTarget(masks.blur.rt)
    render_Clear(0, 0, 0, 0, true, true)
    cam_Start2D()
        surface_SetDrawColor(255,255,255,255)
        surface_SetMaterial(blur_mat)
        surface_DrawTexturedRect(0,0,masks.blur.rt:Width(), masks.blur.rt:Height())
    cam_End2D()

    if passes > 0 then
        render_BlurRenderTarget(masks.blur.rt, amount, amount, passes)
    end

    render_PopRenderTarget()
    -- render.SetViewPort(0, 0, esclib.scrw, esclib.scrh)
end

----
---@name masks.DrawBlur
---@arg (x: number | Panel) The x coordinate to base the blur on, or a panel
---@arg (y: number) The y coordinate to base the blur on
---@arg (content_blur_passes: number) Optional number of blur passes to apply to the content on top of the blurred background. Defaults to 0.
---@arg (content_blur_amount: number) Optional amount of blur for the content. Defaults to 3.
----
---- Draws a blurred rectangle based on a panel's position using the pre-captured screen blur.
---- This must be called inside a masks.Start() / masks.End() block.
----
function masks.DrawBlur(x, y)
    if not get_var("drawblur") then return end

    if ispanel(x) and IsValid(x) then
        x, y = x:LocalToScreen(0,0)
    end

    x = (type(x) == "number" and x) or 0
    y = (type(y) == "number" and y) or 0

    masks.last_time = CurTime() + 1 --update blur if UpdateBlur used recently

    -- Draw the pre-blurred screen content into the current render target.
    -- The offset (-x, -y) makes it so the blur aligns with the screen behind the panel.
    surface_SetDrawColor(255, 255, 255, 255)
    surface_SetMaterial(masks.blur.mat)
    surface_DrawTexturedRect(-x, -y, esclib.scrw, esclib.scrh)
end


----
---@name masks.DrawBlur_OLD
---@arg (pnl: Panel) The panel to base the blur on
---@arg (passes: number) The number of blur passes
---@arg (amount: number) The amount of blur for both X and Y axes
----
---- Draws a blurred rectangle based on a panel's position using the more efficient render.BlurRenderTarget.
---- This function temporarily switches render targets to capture the screen content for blurring.
----
-- function masks.DrawBlur_OLD(passes, amount, x, y)
--     if ispanel(x) and IsValid(x) then
--         x, y = x:LocalToScreen(0,0)
--     end

--     passes = passes or 1
--     amount = amount or 3

--     -- Preserve current content by copying it to source render target.
--     render_CopyTexture(masks.dest.rt, masks.source.rt)

--     -- We are on a render target. Pop it to get to the backbuffer.
--     cam_End2D()
--     render_PopRenderTarget()

--     -- Now we are on the backbuffer, capture it
--     UpdateScreenEffectTextureOnce()

--     -- Restore the render target
--     render_PushRenderTarget(masks.dest.rt)
--     cam_Start2D()

--     -- First, draw the captured screen content to our render target with the correct offset.
--     -- We use the blur material but set the blur amount to 0, so it just acts as a texture renderer.
--     surface_SetDrawColor(255, 255, 255, 255)
--     surface_SetMaterial(blur_mat)
--     surface_DrawTexturedRect(-x, -y, esclib.scrw, esclib.scrh)

--     -- Draw preserved content
--     surface_SetDrawColor(255, 255, 255, 255)
--     surface_SetMaterial(masks.source.mat)
--     surface_DrawTexturedRect(0, 0, esclib.scrw, esclib.scrh)

--     --Draw blur
--     if passes > 0 then
--         render_BlurRenderTarget(masks.dest.rt, amount, amount, passes)
--     end
-- end

--Blur without screen capture
function masks.DrawBlurContent(passes, amount)
    render_BlurRenderTarget(masks.dest.rt, amount, amount, passes)
end

-- Hook to recreate materials when screen size changes
hook_Add("OnScreenSizeChanged", "ESCMasks_UpdateMaterials", function()
    timer_Simple(0.1, function()
        masks.RecreateMaterials()
    end)
end)

--Greater FPS = less blur update calls = greater fps on high end devices
--This is because at high fps it's less noticeable that blur is lagging behind.
local function GetAdaptiveBlurFrame()
    local fps = 1 / RealFrameTime()
    local blur_every_n_frame = math_clamp(math_floor(fps / 60), 1, 6)
    return blur_every_n_frame
end

-- Update blur hook
hook_Add("HUDPaintBackground", "esclib.masks.update_blur", function()
    if not get_var("drawblur") then return end
    if masks.last_time < CurTime() then return end --update blur only if UpdateBlur used recently

    --update blur every N frames
    if FrameNumber() % GetAdaptiveBlurFrame() ~= 0 then return end

    masks.UpdateBlur(2, 3)
end)