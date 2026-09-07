local PANEL = {}

local clr_frame_bg = Color(5, 9, 16, 222)
local clr_frame_border = Color(31, 182, 255, 160)

local RNDX = gSims_RNDX

local function DrawRound(rad, x, y, w, h, col)
    if RNDX then
        RNDX.Draw(rad, x, y, w, h, col)
    else
        draw.RoundedBox(rad, x, y, w, h, col)
    end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
    if RNDX then
        RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
    end
end

function PANEL:Init()
    self.Itensens = {}
    self:SetAlpha(0)
    self:SetTitle("")

    self.DrawBorder = true
    self.CornerRadius = 0

    self.ColorBG = Color(clr_frame_bg:Unpack())
    self.ColorBR = Color(clr_frame_border:Unpack())
    self.BlurStrengh = 2

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)
end

function PANEL:Paint(w, h)
    local rad = self.CornerRadius or 0

    DrawRound(rad, 0, 0, w, h, self.ColorBG)
    hg.DrawBlur(self, self.BlurStrengh)

    if self.DrawBorder then
        DrawRoundOutlined(rad, 0, 0, w, h, self.ColorBR, 1)
    end
end

function PANEL:SetBorder(bDraw)
    self.DrawBorder = bDraw
end

function PANEL:SetCornerRadius(rad)
    self.CornerRadius = rad
end

function PANEL:SetColorBG(cColor)
    self.ColorBG = cColor
end

function PANEL:SetColorBR(cColor)
    self.ColorBR = cColor
end

function PANEL:SetBlurStrengh(floatVal)
    self.BlurStrengh = floatVal
end

function PANEL:First(ply)
    self:SetY(self:GetY() + self:GetTall())
    self:MoveTo(self:GetX(), self:GetY() - self:GetTall(), 0.4, 0, 0.2, function() end)
    self:AlphaTo(255, 0.2, 0.1, nil)

    if self.PostInit then
        self:PostInit()
    end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    self:MoveTo(self:GetX(), ScrH() / 2 + self:GetTall(), 5, 0, 0.3, function() end)
    self:AlphaTo(0, 0.2, 0, function()
        if self.OnClose then self:OnClose() end
        self:Remove()
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZFrame", PANEL, "DFrame")
