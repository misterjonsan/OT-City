local PANEL = {}
AccessorFunc(PANEL, "TextColor", "TextColor", FORCE_COLOR)
AccessorFunc(PANEL, "Color", "Color", FORCE_COLOR)
AccessorFunc(PANEL, "AccentColor", "AccentColor", FORCE_COLOR)

function PANEL:Init()
    local skin = esclib.addon:GetCurrentSkin()
    self.clr = skin.colors

    self:SetSize(100, 100)
    self:SetTextColor(self.clr.hint.text)
    self:SetColor(self.clr.hint.bg)
    self:SetAccentColor(self.clr.hint.bg2)
end

function PANEL:Setup(text, font, align, parent_panel, hovered_panel)

    font = font or esclib:AdaptiveFont("esclib", 20, 500)
    align = align or TEXT_ALIGN_CENTER

    local maxwidth = esclib.scrw * 0.3
    local multiline = esclib.text:Multiline(text, font, maxwidth)
    local width = multiline.width + 40
    local height = multiline.height + 10

    self:SetSize(width, height)
    self.hovered_panel = hovered_panel
    self.align = align
    self.multiline = multiline
    self.parent_panel = parent_panel

    self.Think = function()
        if not IsValid(self.hovered_panel) then
            self:Remove()
            return
        end

        local posx, posy = 0, 0
        if self.parent_panel and IsValid(self.parent_panel) then
            posx, posy = self.hovered_panel:LocalToScreen(0, 0)
        end

        local x, y = 0, 0
        if (self.align == TEXT_ALIGN_RIGHT) then
            x = posx + self.hovered_panel:GetWide() + 5
            y = posy + self.hovered_panel:GetTall() * 0.5 - self:GetTall() * 0.5
        elseif (self.align == TEXT_ALIGN_LEFT) then
            x = posx - self:GetWide() - 5
            y = posy + self.hovered_panel:GetTall() * 0.5 - self:GetTall() * 0.5
        elseif (self.align == TEXT_ALIGN_TOP) then
            x = posx + self.hovered_panel:GetWide() * 0.5 - self:GetWide() * 0.5
            y = posy - self:GetTall() - 5
        elseif (self.align == TEXT_ALIGN_BOTTOM) then
            x = posx + self.hovered_panel:GetWide() * 0.5 - self:GetWide() * 0.5
            y = posy + self.hovered_panel:GetTall() + 5
        else
            local mx, my = gui.MouseX(), gui.MouseY()
            if self.parent_panel and IsValid(self.parent_panel) then
                mx, my = self.parent_panel:ScreenToLocal(mx, my)
            end

            x = mx + 5
            y = my + 5
        end

        x = math.Clamp(x, 0, esclib.scrw - self:GetWide())
        y = math.Clamp(y, 0, esclib.scrh - self:GetTall())
        self:SetPos(x, y)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, self.AccentColor)
    draw.RoundedBox(6, 2, 2, w - 4, h - 4, self.Color)
    esclib.text:DrawMultilineShadow(self.multiline, 20, 5, self.TextColor, TEXT_ALIGN_LEFT)
end

vgui.Register("esclib.hint_panel", PANEL, "DPanel")