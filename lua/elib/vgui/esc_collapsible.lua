local ceil = math.ceil
local PANEL = {}

AccessorFunc(PANEL, "animate", "Animate", FORCE_BOOL)

local empty_fn = function() end

function PANEL:Init()
    self.clr = esclib.addon:GetColors()
    self.opened = false
    self.animate = true

    self:SetText("")

    -- Top bar setup
    self.topbar = self:Add("DButton")
    self.topbar:SetPos(0, 0)
    self.topbar:SetSize(self:GetWide(), 30) -- Default height
    self.topbar:SetText("")
    self.topbar.DoClick = function(pnl)
        if self.opened then 
            self:Close()
        else
            self:Open()
        end
    end
    self.topbar.Paint = function(pnl, w, h)
        -- local hovered = pnl:IsHovered() or self.opened
        draw.RoundedBoxEx(8, 0, 0, w, h, self.clr.frame.bg, true, true, not self.opened, not self.opened)
    end

    -- Bottom panel setup
    self.botbar = self:Add("esclib.iconlayout")
    self.botbar:SetPos(0, self.topbar:GetTall())
    self.botbar:SetSize(self:GetWide(), 0)
    self.botbar:Hide()
    self.botbar:SetStretchHeight(true)
    self.botbar.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, self.clr.frame.accent, false, false, true, true)
        draw.RoundedBoxEx(8, 2, 0, w-4, h-2, self.clr.frame.bg, false, false, true, true)
    end

    -- Set initial size
    self:SetSize(self:GetWide(), self.topbar:GetTall())
end

function PANEL:PerformSize()
    local w = self:GetWide()
    local h = self:GetTall()

    self.topbar:SetSize(w, self.topbar:GetTall())
    self.botbar:SetWide(w)

    local wanted_tall = self.topbar:GetTall()
    if self.opened then
        wanted_tall = wanted_tall + self.botbar:GetTall()
    end

    self.botbar:SetPos(0, self.topbar:GetTall())

    self:SetTall(wanted_tall)
end

function PANEL:PerformLayout()
    self:PerformSize()
end

-- Override functions
function PANEL:OnOpen() end
function PANEL:OnClose() end
function PANEL:OnRemove() end
function PANEL:AnimTick(frac) end

function PANEL:GetHeader()
    return self.topbar
end

function PANEL:GetContent()
    return self.botbar
end

function PANEL:IsOpened()
    return self.opened
end

function PANEL:Open()
    local border = self.botbar:GetBorder()
    self.botbar:Show()

    self.opened = true

    self:PerformSize()
    self:OnOpen()
end

function PANEL:Close()
    self.opened = false
    self.botbar:Hide()

    self:PerformSize()
    self:OnClose()
end

function PANEL:Paint(w, h)
    --for override
end

vgui.Register("esclib.collapsible", PANEL, "DPanel")