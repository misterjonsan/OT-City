local cos, sin, rad, floor = math.cos, math.sin, math.rad, math.floor

local PANEL = {}

AccessorFunc(PANEL, "poly_count", "PolyCount")
 
function PANEL:Init()
    self.Avatar = vgui.Create("AvatarImage", self)
    self.Avatar:SetPaintedManually(true)

    self:SetPolyCount(16)
end

function PANEL:MakePoly(x,y,w,h)
    return self:MakeCirclePoly(x+w*0.5, y+h*0.5, w*0.5)
end

function PANEL:MakeCirclePoly( x, y, r )
    local circle = {}

    local count = self.poly_count
    for i = 1, count do
        circle[i] = {}
        circle[i].x = x + cos(rad(i * 360) / count) * r
        circle[i].y = y + sin(rad(i * 360) / count) * r
    end

    return circle
end

function PANEL:SetPolyCount(count)
    self.poly_count = count
    self:PerformLayout()
end
 
function PANEL:PerformLayout()
    self:OnSizeChanged(self:GetWide(), self:GetTall())
end
 
function PANEL:SetSteamID(...)
    self.Avatar:SetSteamID(...)
end
 
function PANEL:SetPlayer(...)
    self.Avatar:SetPlayer(...)
end
 
function PANEL:OnSizeChanged(w, h)
    self.Avatar:SetSize(self:GetWide(), self:GetTall())
    self.poly = self:MakePoly(0, 0, self:GetWide(), self:GetTall())
end
 
function PANEL:DrawMask(w, h)
    draw.NoTexture();
    surface.SetDrawColor( color_white )
    surface.DrawPoly( self.poly )
end

function PANEL:DrawBackground(w,h)
    --for override
end

function PANEL:Paint(w, h)
    self:DrawBackground(w,h)

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask( 1 )
    render.SetStencilTestMask( 1 )
 
    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
    render.SetStencilPassOperation( STENCILOPERATION_ZERO )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
    render.SetStencilReferenceValue( 1 )
    self:DrawMask(w, h)

    render.SetStencilFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
    render.SetStencilReferenceValue( 1 )
 
    self.Avatar:SetPaintedManually(false)
    self.Avatar:PaintManual()
    self.Avatar:SetPaintedManually(true)
    render.SetStencilEnable(false)
 
    render.ClearStencil()
end

vgui.Register("esclib.circle_avatar", PANEL)