local max, min, clamp = math.max, math.min, math.Clamp

local PANEL = {}

function PANEL:Init()
    
end

--For override
function PANEL:BeforePaint(w,h)

end

function PANEL:Paint( w, h )
    if ( !IsValid( self.Entity ) ) then return end

    self:BeforePaint(w,h)

    -- Get corners of the panel
    local x, y = self:LocalToScreen( 0, 0 )
    local scrw, scrh = esclib.scrw, esclib.scrh
    
    -- Make sure we have valid render coordinates even when partially off-screen
    local validX = max(0, min(x, scrw - 10))
    local validY = max(0, min(y, scrh - 10))
    local validW = clamp(w, 10, scrw)
    local validH = clamp(h, 10, scrh)
    
    self:LayoutEntity( self.Entity )
    
    local ang = self.aLookAngle
    if ( !ang ) then
        ang = ( self.vLookatPos - self.vCamPos ):Angle()
    end
    
    -- Calculate camera offset based on how much panel is off-screen
    local offsetX = validX - x
    local offsetY = validY - y
    
    -- Create adjusted camera position that shifts with the panel
    local adjustedCamPos = Vector(self.vCamPos)
    local right = ang:Right() * (offsetX * 0.1) -- Adjust multiplier as needed
    local up = ang:Up() * (-offsetY * 0.1) -- Negative because screen Y is inverted
    
    adjustedCamPos:Add(right)
    adjustedCamPos:Add(up)
    
    -- Use valid coordinates for 3D context with adjusted camera position
    cam.Start3D( adjustedCamPos, ang, self.fFOV, validX, validY, validW, validH, 5, self.FarZ )

    render.SuppressEngineLighting( true )
    render.SetLightingOrigin( self.Entity:GetPos() )
    render.ResetModelLighting( self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255 )
    render.SetColorModulation( self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255 )
    render.SetBlend( ( self:GetAlpha() / 255 ) * ( self.colColor.a / 255 ) ) -- * surface.GetAlphaMultiplier()

    for i = 0, 6 do
        local col = self.DirectionalLight[ i ]
        if ( col ) then
            render.SetModelLighting( i, col.r / 255, col.g / 255, col.b / 255 )
        end
    end

    self:DrawModel()

    render.SuppressEngineLighting( false )
    cam.End3D()

    self.LastPaint = RealTime()
end

function PANEL:DrawModel()

	local curparent = self
	local leftx, topy = self:LocalToScreen( 0, 0 )
	local rightx, bottomy = self:LocalToScreen( self:GetWide(), self:GetTall() )
	while ( curparent:GetParent() != nil ) do
		curparent = curparent:GetParent()

		local x1, y1 = curparent:LocalToScreen( 0, 0 )
		local x2, y2 = curparent:LocalToScreen( curparent:GetWide(), curparent:GetTall() )

		leftx = max( leftx, x1 )
		topy = max( topy, y1 )
		rightx = min( rightx, x2 )
		bottomy = min( bottomy, y2 )
		previous = curparent
	end

	render.ClearDepth( false )

	render.SetScissorRect( leftx, topy, rightx, bottomy, true )

	local ret = self:PreDrawModel( self.Entity )
	if ( ret != false ) then
		self.Entity:DrawModel()
		self:PostDrawModel( self.Entity )
	end

	render.SetScissorRect( 0, 0, 0, 0, false )
end

function PANEL:EnableMouseDragging(callback)
    local defaultfov = self:GetFOV()
    function self:LayoutEntity(ent)
        if not IsValid(ent) then return end
        if self.mouseinput then
            self:SetCursor("blank")
            local mx,my = input.GetCursorPos()
            local x,y = self:LocalToScreen()
            local w,h = self:GetSize()
            local suspension = self:GetFOV() / defaultfov

            local deltax = self.mousex - mx
            local ang = ent:GetAngles()
            ang.y = ang.y - (deltax*0.2*suspension)
            ent:SetAngles(ang)
            self.mousex = mx

            local deltay = self.mousey - my
            local pos = ent:GetPos()
            pos.z = clamp(pos.z + (deltay*0.05*suspension),-50,50)
            ent:SetPos(pos)
            self.mousey = my

            -- X
            local newx = mx
            if mx > x+w then 
                newx = x
                self.mousex = newx
            elseif mx < x then
                newx = x+w
                self.mousex = newx
            end

            -- Y
            local newy = my
            if my > y+h then
                newy = y
                self.mousey = newy
            elseif my < y then
                newy = y+h
                self.mousey = newy
            end
            input.SetCursorPos(newx,newy)
        else
            self:SetCursor("hand")
        end

        if isfunction(callback) then
            callback(self)
        end
    end
    function self:OnMousePressed()
        local posx,posy = input.GetCursorPos()
        self.mouseinput = true
        self.mousex, self.mousey = posx, posy
        self.startx,self.starty = posx,posy
        self:MouseCapture(true)
    end
    function self:OnMouseReleased()
        self.mouseinput = nil
        self:MouseCapture(false)
        if self.startx and self.starty then
            input.SetCursorPos(self.startx, self.starty)
        end
    end
    function self:OnMouseWheeled(dlta)
        self:SetFOV(clamp(self:GetFOV()-dlta, 1, 90) )
    end
end

vgui.Register("esclib.modelpanel", PANEL, "DModelPanel")