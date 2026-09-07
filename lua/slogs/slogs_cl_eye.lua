SLogs.Eye = SLogs.Eye or {Cases={},Enabled=false,Cache={},Mdls={}}

local usePanel = true
local useTriangles = false

local null = function()end

surface.CreateFont("3dfontpizdati",{font = "Tahoma",size = 160,weight = 1700,shadow = true, antialias = true})

local descs = {
    [ "ply1" ] = "[Жертва]",
    [ "ply2" ] = "[Убийца]",
    default = "[Свидетель]",
}
function SLogs.Eye:GetPlayerDescription( info )
    return info and descs[ info ] or descs.default
end

local colors = {
    [ "ply1" ] = Color( 0, 255, 0 ),
    [ "ply2" ] = Color( 255, 0, 0 ),
    default = color_white
}
function SLogs.Eye:GetPlayerColor( info )
    return info and colors[ info ] or colors.default
end

local function createOption( parent, name, text, icon )
    if !text then return end

    if isfunction( text ) then
        option = parent:AddOption( name, text )
    else
        option = parent:AddOption( "Скопировать: " .. name, function( )
            SetClipboardText( text )
        end )
    end

    if icon then
        option:SetIcon( icon )
    end

    return option
end

function SLogs.Eye:CreateContextMenu( target )
    local menu = DermaMenu( )

    createOption( menu, "Ник", target.name, "icon16/user.png" )
    createOption( menu, "SteamID", target.stid, "icon16/tag.png" )
    createOption( menu, "Класс", target.job, "icon16/vcard.png" )
    createOption( menu, "Оружие", target.wep, "icon16/gun.png" )

    menu:Open( )
end

function SLogs.Eye:GetMiddlePosition( case )

    local pos = Vector()
    local num = 0

    for _, tbl in pairs( case ) do
        
        if tbl.pos then
            num = num + 1
        end

        pos = pos + (tbl.pos or Vector() )

    end

    return pos / num

end

function SLogs.Eye:InitModels( tbl )
    self:RemoveModels( )

    for k,v in pairs( tbl ) do
        if v.mdl and v.ang and v.pos then
            local ent = ClientsideModel( v.mdl )
            if !IsValid( ent ) then continue end

            ent:SetRenderOrigin( v.pos )
            ent:SetPos( v.pos )
            local ang = v.ang
            ent:SetPoseParameter( "aim_pitch", ang.p )
            ang.p = 0
            ent:SetAngles( ang )
            ent:SetNoDraw( true )
            ent.EyeKey = k

            if v.name then
                ent.Name = function()return v.name end
                ent.GetRankName = function()return v.mask and "В маске" end
                ent.IsWanted = null
                ent.IsSpeaking = null
                ent.IsTyping = null
            end


            if v.sec then
                ent:SetSequence( v.sec )
                ent.DoRender = function( self )
                    self:SetCycle( math.abs(math.sin(CurTime()/5)) )
                    self:DrawModel( )
                    if self.Hats then
                        Hats.UpdateAccessoriesPos( self )
                    end
                end
            else
                ent.DoRender = function( self )
                    self:DrawModel( )
                end
            end

            if v.mask then
                local mdl = table.KeyFromValue( Hats.Keys, v.mask )
                if !mdl then continue end
                Hats.SetupAccessories( ent, {
                    Mask = {mdl=mdl, skin=1}
                } )
                ent.cfgs = {
                    [mdl] = Hats.GetCFG( ent, mdl )
                }
                ent.InMask = true
            end

            self.Mdls[ k ] = ent
        end
    end

    local colors = {}
    for key, ent in pairs( self.Mdls ) do
        local color = self:GetPlayerColor( key )
        colors[ color ] = colors[ color ] or {}
        table.insert( colors[ color ], ent )
    end

    for color, entities in pairs( colors ) do
        table.insert( self.HaloData, {
            Ents = entities,
            Color = color,
            BlurX = 2,
            BlurY = 2,
            DrawPasses = 1,
            Additive = true,
            IgnoreZ = true
        } )
    end
end
function SLogs.Eye:RemoveModels( )
    self.HaloData = {}
    if next( self.Mdls ) != nil then
        for k,v in pairs( self.Mdls ) do
            if IsValid( v ) then
                v:Remove( )
            end
        end
        self.Mdls = {}
    end
end

function SLogs.Eye:Load( ID )
    local tbl = istable( ID ) and ID or self.Cases[ ID ]
    if !tbl then

        net.Start( "SLogs.Eye" )
            net.WriteUInt( ID, 32 )
        net.SendToServer( )

        SLogs:StartLoading( "Eye" )

        return false
    end

    for k, case in pairs( tbl ) do
        if case.wep then
            local scriptedWeapon = weapons.Get( case.wep )
            if scriptedWeapon then
                case.wep = scriptedWeapon.PrintName or case.wep
            else
                case.wep = language.GetPhrase( case.wep )
            end
        end
    end

    self:Disable( ) // recreate

    self:InitModels( tbl )
    self.Cache = tbl
    self.Enabled = true
    self.Position = self.Position or self:GetMiddlePosition( tbl )


    if usePanel then
        self:Enable2D()
    else
        self:Enable3D()
    end

    self:EnableMain( )

    return true

end

local lp = LocalPlayer()
local function down( input )
    return lp:KeyDownLast( input )
end

function SLogs.Eye:Disable( )
    self:RemoveModels( )

    if IsValid( self.Panel2D ) then
        self.Panel2D:Remove( )
    end

    hook.Remove( "PostDrawOpaqueRenderables", "SLogs.Eye" )
    hook.Remove( "PreDrawViewModel", "SLogs.Eye" )
    hook.Remove( "DrawPhysgunBeam", "SLogs.Eye" )
    hook.Remove( "PrePlayerDraw", "SLogs.Eye" )
    hook.Remove( "StartCommand", "SLogs.Eye" )
    hook.Remove( "CalcView", "SLogs.Eye" )
    hook.Remove( "HUDPaint", "SLogs.Eye" )
end

local y = 0
local function Draw( addX, addY, text, desc, color )
    if !text then return end
    local tw, th = draw.SimpleText( desc .. text, "3dfontpizdati", addX or 0, y + (addY or 0), color or color_white, useTriangles and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 4, color_black )
    y = y + th
end
function SLogs.Eye:RenderFunction( eyepos, angle, aimvector, addX, addY )
    if !self.Enabled then return end

    y = 0
    local cache = self.Cache

    local eyepos = eyepos or EyePos( )
    local aimvector = aimvector or (angle and angle:Forward( )) or LocalPlayer():GetAimVector()

    render.SuppressEngineLighting( true )

    render.ResetModelLighting( 1, 1, 1 )

    for _, case in pairs( cache ) do
        
        if !case.pos then continue end

        y = 0
        local ang = angle and Angle( angle:Unpack( ) ) or EyeAngles( )
        ang.p = 0
        ang.y = ang.y - 90

        if !case.name then continue end
        local color = case.job and team.GetColor( case.job ) or Color( 100, 100, 100 )
        local line_color = self:GetPlayerColor( _ )

        if isstring( _ ) then
            render.SetModelLighting( BOX_TOP, line_color.r / 20, line_color.g / 20, 0 )
        end

        local position = case.pos + Vector( 0, 0, 100 )
        local headPos = case.pos + Vector( 0, 0, 75 )

        local mdl = self.Mdls[ _ ]
        if IsValid( mdl ) then
            mdl:DoRender( )

            local bonePos = mdl:GetBonePosition( mdl:LookupBone( "ValveBiped.Bip01_Head1" ) )
            if bonePos then
                headPos = bonePos
            end
        end

        cam.IgnoreZ( true )
            if useTriangles then
                render.DrawLine( case.pos, headPos, line_color )

                cam.Start3D2D( case.pos, case.ang, 0.05 )
                    surface.SetDrawColor( color.r, color.g, color.b, 150 )
                    draw.NoTexture()
                    surface.DrawPoly({
                        { y = -3600, x = 2700},
                        { y = 3600, x = 2700},
                        { y = 0, x = 0},
                    })
                cam.End3D2D( )
            else
                render.DrawLine( headPos, headPos + case.ang:Forward( ) * 50, line_color )
            end 

            local dot = 1

            cam.Start3D2D( headPos, ang + Angle(0,0,90), 0.02 )
                draw.SimpleText( self:GetPlayerDescription( _ ), "3dfontpizdati", addX or 0, -500 + (addY or 0), line_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
            cam.End3D2D( )
        cam.IgnoreZ( false )
    end

    render.SuppressEngineLighting( false )
end

function SLogs.Eye:EnableMain( )
    hook.Add( "PrePlayerDraw", "SLogs.Eye", function() if SLogs.Eye.Enabled then return true end end )
    hook.Add( "PreDrawViewModel", "SLogs.Eye", function() if SLogs.Eye.Enabled then return true end end )
    hook.Add( "DrawPhysgunBeam", "SLogs.Eye", function() if SLogs.Eye.Enabled then return false end end )
end


local mat_Copy      = Material( "pp/copy" )
local mat_Add       = Material( "pp/add" )
local mat_Sub       = Material( "pp/sub" )
local rt_Store      = render.GetScreenEffectTexture( 0 )
local rt_Blur       = render.GetScreenEffectTexture( 1 )
function SLogs.Eye:RenderHalo( entry, camData )
    local rt_Scene = render.GetRenderTarget()

    render.CopyRenderTargetToTexture( rt_Store )

    if ( entry.Additive ) then
        render.Clear( 0, 0, 0, 255, false, true )
    else
        render.Clear( 255, 255, 255, 255, false, true )
    end

    if camData then
        cam.Start( camData )
    else
        cam.Start3D( )
    end
        render.SetStencilEnable( true )
            render.SuppressEngineLighting(true)
            cam.IgnoreZ( entry.IgnoreZ )

                render.SetStencilWriteMask( 1 )
                render.SetStencilTestMask( 1 )
                render.SetStencilReferenceValue( 1 )

                render.SetStencilCompareFunction( STENCIL_ALWAYS )
                render.SetStencilPassOperation( STENCIL_REPLACE )
                render.SetStencilFailOperation( STENCIL_KEEP )
                render.SetStencilZFailOperation( STENCIL_KEEP )

                    for k, v in pairs( entry.Ents ) do

                        if ( !IsValid( v ) ) then continue end

                        v:DoRender()

                    end

                render.SetStencilCompareFunction( STENCIL_EQUAL )
                render.SetStencilPassOperation( STENCIL_KEEP )

                    cam.Start2D()
                        surface.SetDrawColor( entry.Color )
                        surface.DrawRect( 0, 0, ScrW(), ScrH() )
                    cam.End2D()

            cam.IgnoreZ( false )
            render.SuppressEngineLighting(false)
        render.SetStencilEnable( false )
    cam.End3D()

    render.CopyRenderTargetToTexture( rt_Blur )
    render.BlurRenderTarget( rt_Blur, entry.BlurX, entry.BlurY, 1 )

    render.SetRenderTarget( rt_Scene )
    mat_Copy:SetTexture( "$basetexture", rt_Store )
    render.SetMaterial( mat_Copy )
    render.DrawScreenQuad()

    render.SetStencilEnable( true )

        render.SetStencilCompareFunction( STENCIL_NOTEQUAL )

            if ( entry.Additive ) then

                mat_Add:SetTexture( "$basetexture", rt_Blur )
                render.SetMaterial( mat_Add )

            else

                mat_Sub:SetTexture( "$basetexture", rt_Blur )
                render.SetMaterial( mat_Sub )

            end

            for i = 0, entry.DrawPasses do

                render.DrawScreenQuad()

            end

    render.SetStencilEnable( false )
    render.SetStencilTestMask( 0 )
    render.SetStencilWriteMask( 0 )
    render.SetStencilReferenceValue( 0 )
end

function SLogs.Eye:DrawHalos( camData )
    if !self.HaloData then return end
    for k, v in pairs( self.HaloData ) do
        self:RenderHalo( v, camData )
    end
end

function SLogs.Eye:Enable3D( )
    hook.Add( "CalcView", "SLogs.Eye", function()

        local self = SLogs.Eye

        if !self.Enabled then return end

        local pos = self.Position

        return {
            origin = pos,
            drawviewer = false
        }

    end )

    hook.Add( "StartCommand", "SLogs.Eye", function( ply, cmd )
        local self = SLogs.Eye
        if !self.Enabled then return end

        local angles = cmd:GetViewAngles( )
        
        local sidemove = cmd:GetSideMove( )
        local forward_move = cmd:GetForwardMove( )

        local speed = 8
        if cmd:KeyDown( IN_SPEED ) then
            speed = 16
        end
        if cmd:KeyDown( IN_DUCK ) then
            speed = speed / 4
        end

        if cmd:KeyDown( IN_JUMP ) then
            self.Position = self.Position + Vector( 0, 0, 1 )  * speed / 2
        end

        if forward_move > 0 then
            self.Position = self.Position + angles:Forward( ) * speed
        end
        if forward_move < 0 then
            self.Position = self.Position - angles:Forward( ) * speed
        end

        if sidemove < 0 then
            self.Position = self.Position - angles:Right( ) * speed
        end
        if sidemove > 0 then
            self.Position = self.Position + angles:Right( ) * speed
        end

        if cmd:KeyDown( IN_RELOAD ) then
            self.Enabled = false
            self:RemoveModels( )
            self.Cache = {}
        end
        cmd:ClearButtons( )
        cmd:ClearMovement( )
    end )

    hook.Add( "PostDrawOpaqueRenderables", "SLogs.Eye", function()
        self:DrawHalos( )
        self:RenderFunction( )
    end )

    hook.Add( "HUDPaint", "SLogs.Eye", function()
        local self = SLogs.Eye
        if !self.Enabled then return end
        draw.SimpleText( "Нажмите R чтобы выйти", "DermaLarge", 0, ScrH()/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end)
end

function SLogs.Eye:Enable2D( )
    local frame = vgui.Create( "DFrame" )
    self.Panel2D = frame

    frame:SetPaintedManually( false )
    frame:SetSize( ScrW( ) * 0.9, ScrH( ) * 0.9 )
    frame:SetKeyboardInputEnabled( true )
    frame:SetTitle( "" )
    frame:MakePopup( )
    frame:Center( )
    frame:ShowCloseButton( false )
    frame.OnClose = function( s )
        self:Disable( )
    end


    frame:DockPadding( 2, 24, 2, 2 )
    frame:SetSizable( true )
    frame:SetMinWidth( ScrW( ) * 0.4 )
    frame:SetMinHeight( ScrH( ) * 0.4 )
    frame.Paint = function( s, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, color_black )

        surface.SetDrawColor( 255, 255, 255 )
        surface.DrawOutlinedRect( 0, 0, w, h, 2 )
        draw.SimpleText( "Позиция смерти", "Trebuchet24", 5, 24/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end
    frame.PaintOver = function( s, w, h )
        draw.SimpleText( "Управление: AWSD | Удерживайте мышь что-бы осматриваться", "DermaLarge", w/2, h - 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black )
    end

    local closeButton = vgui.Create( "DButton", frame )
		closeButton:SetPos( frame:GetWide( ) - 24, 2 )
		closeButton:SetSize( 22, 22 )
		closeButton:SetText( "" )
		closeButton.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:IsDown( ) and Color( 150, 50, 50 ) or self:IsHovered( ) and Color( 200, 50, 50 ) or Color( 255, 50, 50 ) )
			draw.SimpleText( "X", "Trebuchet24", w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		closeButton.DoClick = function()
			frame:Remove( )
            self:Disable( )
		end

    local panel = vgui.Create( "EditablePanel", frame )

    for k, v in pairs( {"OnKeyCodeReleased", "OnKeyCodePressed"} ) do
        frame[ v ] = function( _, key )
            panel[ v ]( panel, key )
        end
    end


    panel:Dock( FILL )
    panel.Angles = Angle( 0, -90, 0 )
    panel:SetKeyboardInputEnabled( true )


    local controls = {
        w = "forward",
        s = "back",
        a = "moveleft",
        d = "moveright",

        shift = "speed",
        ctrl = "duck",
    }
    for k, v in pairs( controls ) do
        controls[ k ] = input.GetKeyCode( input.LookupBinding( v ) or "e" ) or KEY_UP
    end

    panel.RememberButtons = {}
    panel.OnKeyCodeReleased = function( s, key ) s.RememberButtons[ key ] = nil end
    panel.OnKeyCodePressed = function( s, key ) s.RememberButtons[ key ] = true end

    panel:InvalidateLayout( true )


    panel.LastX, panel.LastY = input.GetCursorPos( )
    panel.Think = function( s )
        local x, y = input.GetCursorPos( )
        local diffX, diffY = s.LastX - x, y - s.LastY

        if s.CameraEnabled then
            s.Angles = Angle( s.Angles.p + diffY / 4, s.Angles.y + diffX / 4, s.Angles.r )
            input.SetCursorPos( s.LastX, s.LastY )
        end

        s.LastX, s.LastY = input.GetCursorPos( )

        local speed = 8
        if s.RememberButtons[ controls[ "shift" ] ] then
            speed = 16
        end
        if s.RememberButtons[ controls[ "ctrl" ] ] then
            speed = speed / 4
        end

        for key in pairs( s.RememberButtons ) do
            if key == controls.s then
                self.Position = self.Position - s.Angles:Forward( ) * speed
            end
            if key == controls.w then
                self.Position = self.Position + s.Angles:Forward( ) * speed
            end

            if key == controls.a then
                self.Position = self.Position - s.Angles:Right( ) * speed
            end
            if key == controls.d then
                self.Position = self.Position + s.Angles:Right( ) * speed
            end
        end
    end

    
    panel.OnMousePressed = function( s, key )
        if key == MOUSE_RIGHT then return end

        s:SetCursor( "blank" )
        s.CameraEnabled = true
        s:MouseCapture( true )

        RememberCursorPosition()
    end
    panel.OnMouseReleased = function( s, key )
        if key == MOUSE_RIGHT then
            s:OnRightClick( )
            return
        end
        s:SetCursor( "" )
        s.CameraEnabled = false
        s:MouseCapture( false )

        RestoreCursorPosition()
    end

    local cache = self.Cache

    panel.OnRightClick = function( s )
        local target = s.HoveredEntity
        if !target or !target.EyeKey or !cache[ target.EyeKey ] then return end

        self:CreateContextMenu( cache[ target.EyeKey ] )
    end

    panel.OnCursorMoved = function( s, mouseX, mouseY )
        if s.CameraEnabled then
            s.HoveredEntity = false
            return
        end

        local closestDistace
        local closestEntity

        local aim = util.AimVector( s.Angles, 90, mouseX, mouseY, s:GetWide( ), s:GetTall( ) )

        for k, v in pairs( self.Mdls ) do
            if !IsValid( v ) or !v.EyeKey or !self.Cache[ v.EyeKey ] then continue end

            local mins, maxs = v:GetRenderBounds( )

            if util.IntersectRayWithOBB( self.Position, aim * 1000, v:GetPos( ), v:GetAngles( ), mins, maxs ) then
                local dist = self.Position:Distance( v:GetPos( ) )
                if !closestDistace or closestDistace > dist then
                    closestDistace = dist
                    closestEntity = v
                end
            end
        end

        s.HoveredEntity = closestEntity

        if closestEntity then
            s:SetCursor( "hand" )
        else
            s:SetCursor( "" )
        end
    end

    panel.Paint = function( s, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30 ) )

        local o = DisableClipping( true )
        local s = panel
        local x,y = s:LocalToScreen( )

        local hoveredEntity = s.HoveredEntity
        local camData = {
            origin = self.Position,
            angles = s.Angles,
            x = x, y = y,
            w = w, h = h,
            aspect = w/h,
            fov = 90,
            type = "3D",

            drawviewmodel = false,
        }

        render.RenderView( camData )


        cam.Start( camData )

            self:RenderFunction( self.Position, s.Angles, nil, -x, -y )

            if hoveredEntity and hoveredEntity.EyeKey then
                local ent = hoveredEntity
                local mins, maxs = ent:GetRenderBounds( )
                render.DrawWireframeBox( ent:GetPos( ), ent:GetAngles( ), mins, maxs, self:GetPlayerColor( ent.EyeKey ) )
            end

        cam.End3D( )
        self:DrawHalos( camData )

        if hoveredEntity then 
            local eyeKey = hoveredEntity.EyeKey
            local entityInfo = self.Cache[ eyeKey ]

            local mouseX, mouseY = s:CursorPos( )
            mouseX = mouseX + 20
            mouseY = mouseY + 20

            surface.SetFont( "Trebuchet24" )
            surface.SetTextColor( self:GetPlayerColor( eyeKey ) )

            local tw = surface.GetTextSize( self:GetPlayerDescription( eyeKey ) )
            surface.SetTextPos( mouseX - tw/2 - 20/2, mouseY - 45 )
            surface.DrawText( self:GetPlayerDescription( eyeKey ) )

            surface.SetTextColor( color_white )

            for i, value in ipairs{
                {"Ник", entityInfo.name},
                {"SteamID", entityInfo.stid},
                {"Оружие", entityInfo.wep},
                {"Класс", entityInfo.job and team.GetName( entityInfo.job ) or nil}
            } do
                if !value[ 2 ] then continue end
                local tw = surface.GetTextSize( value[ 1 ] .. ": " .. value[ 2 ] )

                surface.SetTextPos( mouseX - tw / 2 - 20/2, mouseY + i * 20 - 20 )

                surface.DrawText( value[ 1 ] .. ": " .. value[ 2 ] )
            end
        end

        DisableClipping( o )
    end
end

net.Receive( "SLogs.Eye", function( len, ply )

    SLogs:StopLoading( "Eye" )

    local ID = net.ReadUInt( 32 )
    local len = net.ReadUInt( 32 )
    local data = net.ReadData( len )
    local tbl = SLogs:DecompressTable( data )

    SLogs.Eye.Cases[ ID ] = tbl
    SLogs.Eye:Load( tbl )

end )
