local max = math.max
local accessor_fn = esclib.accessor
local color_black = Color(0,0,0)

local PANEL = {}

AccessorFunc(PANEL, "m_nBorderRadius", "BorderRadius", FORCE_NUMBER)
AccessorFunc(PANEL, "m_sButtonText", "ButtonText", FORCE_STRING)
AccessorFunc(PANEL, "m_cTextAlignX", "TextAlignX", FORCE_NUMBER)
AccessorFunc(PANEL, "m_cTextAlignY", "TextAlignY", FORCE_NUMBER)
AccessorFunc(PANEL, "icon_size", "IconSize", FORCE_NUMBER)
AccessorFunc(PANEL, "icon_offset", "IconOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "text_y_offset", "TextYOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "enabled", "Enabled", FORCE_BOOL)
AccessorFunc(PANEL, "draw_text_shadow", "DrawTextShadow", FORCE_BOOL)
AccessorFunc(PANEL, "draw_icon_shadow", "DrawIconShadow", FORCE_BOOL)
AccessorFunc(PANEL, "m_matIcon", "Icon")

AccessorFunc(PANEL, "bg_col", "BackgroundColor", FORCE_COLOR)
AccessorFunc(PANEL, "bg_col_hover", "BackgroundHoverColor", FORCE_COLOR)
AccessorFunc(PANEL, "bg_col_disabled", "BackgroundDisabledColor", FORCE_COLOR)
AccessorFunc(PANEL, "bg_col2", "BackgroundColor2")
AccessorFunc(PANEL, "bg_col2_hover", "BackgroundHoverColor2")

AccessorFunc(PANEL, "text_col", "TextColor", FORCE_COLOR)
AccessorFunc(PANEL, "text_col_hover", "TextHoverColor", FORCE_COLOR)

AccessorFunc(PANEL, "icon_col", "IconColor", FORCE_COLOR)
AccessorFunc(PANEL, "icon_col_hover", "IconHoverColor", FORCE_COLOR)

function PANEL:Init()
    self:SetMouseInputEnabled(true)
    self:SetEnabled(true)

    self.skin = esclib.addon:GetCurrentSkin()
    self.colors = self.skin.colors

    self:SetTextAlignX(TEXT_ALIGN_CENTER)
    self:SetTextAlignY(TEXT_ALIGN_CENTER)
    self:SetTextYOffset(0)

    self:SetText("")
    self:SetIcon(nil)
    self:SetIconSize(1)
    self:SetIconOffset(esclib:AdaptiveSize(8))

    self:SetBorderRadius(8)
    self:SetButtonText("SetButtonText")

    self:SetCursor("hand")
    self:SetFont(esclib:AdaptiveFont("esclib", 18, 500))

    self:SetBackgroundColor(self.colors.button.main)
    self:SetBackgroundHoverColor(self.colors.button.hover)
    self:SetBackgroundColor2(self.colors.button.hover)
    self:SetBackgroundHoverColor2(self.colors.button.hover)
    self:SetBackgroundDisabledColor(self.colors.button.discard)

    self:SetTextColor(self.colors.button.text)
    self:SetTextHoverColor(self.colors.button.text_hover)

	self:SetIconColor(self.colors.button.text)
    self:SetIconHoverColor(self.colors.button.text_hover)

    self:SetEnabled(true)

    function self.SetText(pnl, text)
        self:SetButtonText(text)
    end

    function self.GetText(pnl)
        return self:GetButtonText()
    end
end

function PANEL:IsDown()
    return self.Depressed
end

function PANEL:IsEnabled()
    return self.enabled
end

function PANEL:BeforePaint(w,h)
    --For override
end

function PANEL:PaintBackground(w,h)
    local enabled = self:IsEnabled()
    local hovered = self:IsHovered() and enabled
    local bg_col = hovered and self.bg_col_hover or self.bg_col
    local bg_col2 = hovered and self.bg_col2_hover or self.bg_col2
    if not enabled then
        bg_col = self:GetBackgroundDisabledColor()
        -- bg_col2 = self:GetBackgroundDisabledColor()
    end

    draw.RoundedBox(self:GetBorderRadius(),0,0,w,h,bg_col2)
    draw.RoundedBox(max(self:GetBorderRadius()-2, 0),2,2,w-4,h-4,bg_col)
end

function PANEL:Paint(w, h)
    self:BeforePaint(w,h)

    self:SetCursor("hand")
    local active = self:IsEnabled()
    local hovered = self:IsHovered() and active
    if self.PaintBackground then self:PaintBackground(w,h) end
    
    local tax = self:GetTextAlignX()
    local text = self:GetButtonText()
    local font = self:GetFont()
    local icon = self:GetIcon()
    local text_offset = esclib:AdaptiveSize(10)
    local text_y_offset = self.text_y_offset
    local iconSize = h * (0.5 * self.icon_size)
    surface.SetFont(font)
    local textWidth, textHeight = surface.GetTextSize(text)

	local icon_color = hovered and self.icon_col_hover or self.icon_col

    if text == "" then
        if icon then
            local iconOffsetX = (w - iconSize) * 0.5
            local iconOffsetY = (h - iconSize) * 0.5 + 1
            surface.SetDrawColor(icon_color.r, icon_color.g, icon_color.b, icon_color.a)
            surface.SetMaterial(icon)
            surface.DrawTexturedRect(iconOffsetX, iconOffsetY, iconSize, iconSize)
        end
    else
        if icon then
            local totalWidth = textWidth + iconSize + 5
            local iconOffsetX, textOffsetX
            
            if tax == TEXT_ALIGN_LEFT then
                iconOffsetX = text_offset
                textOffsetX = iconOffsetX + iconSize + self.icon_offset
            elseif tax == TEXT_ALIGN_RIGHT then
                textOffsetX = w - text_offset - textWidth
                iconOffsetX = textOffsetX - iconSize - self.icon_offset
            else
                local startX = (w - totalWidth) * 0.5
                iconOffsetX = startX
                textOffsetX = startX + iconSize + self.icon_offset
            end
            
            local iconOffsetY = (h - iconSize) * 0.5 + 1

            -----------------
            --# DRAW ICON #--
            -----------------
            if self.draw_icon_shadow then
                surface.SetDrawColor(color_black.r, color_black.g, color_black.b, color_black.a)
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(iconOffsetX+1, iconOffsetY+1, iconSize, iconSize)
            end
            surface.SetDrawColor(icon_color.r, icon_color.g, icon_color.b, icon_color.a)
            surface.SetMaterial(icon)
            surface.DrawTexturedRect(iconOffsetX, iconOffsetY, iconSize, iconSize)

            -----------------
            --# DRAW TEXT #--
            -----------------
            if self.draw_text_shadow then
                draw.SimpleText(text, font, textOffsetX+1, h * 0.5+1+text_y_offset, color_black, TEXT_ALIGN_LEFT, self:GetTextAlignY())
            end
            draw.SimpleText(text, font, textOffsetX, h * 0.5+text_y_offset, hovered and self.text_col_hover or self.text_col, TEXT_ALIGN_LEFT, self:GetTextAlignY())
        else
            local textOffsetX
            if tax == TEXT_ALIGN_LEFT then
                textOffsetX = text_offset
            elseif tax == TEXT_ALIGN_RIGHT then
                textOffsetX = w - text_offset - textWidth
            else
                textOffsetX = w * 0.5
            end
            
            if self.draw_text_shadow then
                draw.SimpleText(text, font, textOffsetX+1, h * 0.5+1+text_y_offset, color_black, tax, self:GetTextAlignY())
            end
            draw.SimpleText(text, font, textOffsetX, h * 0.5+text_y_offset, hovered and self.text_col_hover or self.text_col, tax, self:GetTextAlignY())
        end
    end

    if not active then
        self:SetCursor("no")
    end
end

function PANEL:SetIcon(material)
    self.m_matIcon = material
end

function PANEL:GetIcon()
    return self.m_matIcon
end

function PANEL:StretchWidth(additional_width)
    additional_width = additional_width or 0
    local w,h = self:GetSize()
    local icon_size = h * (0.5 * self.icon_size)
    local tw, th = esclib.util:TextSize(self:GetButtonText(), self:GetFont())
    self:SetWide(tw+icon_size+self.icon_offset*2+esclib:AdaptiveSize(10)+additional_width)
end

derma.DefineControl("esclib.button", "A button for esclib", PANEL, "DLabel")








----------------------
--# glow_button #--
----------------------
local PANEL = {}
accessor_fn(PANEL, "glow_size_x", "GlowSizeX", 0.5, "number")
accessor_fn(PANEL, "glow_size_y", "GlowSizeY", 0.7, "number")
accessor_fn(PANEL, "glow_clr", "GlowColor", Color(255,0,0,255), "table")
local allowed_modes = {
    ["radial"] = true,
    ["mouse"] = true,
    ["always"] = true
}
accessor_fn(PANEL, "glow_mode", "GlowMode", "radial", function(val) return allowed_modes[val] end)

function PANEL:Init()
    self.radial_grad = esclib:GetMaterial("radial_gradient.png")
    self:NoClipping(true)
end

function PANEL:PaintBackground(w,h)
    local enabled = self:IsEnabled()
    local hovered = self:IsHovered() and enabled
    local glow_mode = self:GetGlowMode()

    local bg_col = hovered and self.bg_col_hover or self.bg_col
    local bg_col2 = hovered and self.bg_col2_hover or self.bg_col2
    if not enabled then
        bg_col = self:GetBackgroundDisabledColor()
    end

    draw.RoundedBox(self:GetBorderRadius(),0,0,w,h,bg_col2)

    if hovered or glow_mode == "always" then
        surface.SetDrawColor(self:GetGlowColor())
        surface.SetMaterial(self.radial_grad)
        local offset_x = w*self.glow_size_x
        local offset_y = h*self.glow_size_y
    
        if glow_mode == "radial" then
            surface.DrawTexturedRect(-offset_x, -offset_y, w + offset_x*2, h + offset_y*2)
        elseif glow_mode == "mouse" then
            local mx,my = input.GetCursorPos()
            local px,py = self:ScreenToLocal(mx,my)
            surface.DrawTexturedRect(px-w*0.5-offset_x,py-h*0.5-offset_y,w+offset_x*2,h+offset_y*2)
        elseif glow_mode == "always" then
            surface.DrawTexturedRect(-offset_x, -offset_y, w + offset_x*2, h + offset_y*2)
        end
    end

    draw.RoundedBox(max(self:GetBorderRadius()-2, 0),2,2,w-4,h-4,bg_col)
end

function PANEL:OnCursorEntered()
    self:SetZPos(2)
end
function PANEL:OnCursorExited()
    self:SetZPos(0)
end

vgui.Register("esclib.glow_button", PANEL, "esclib.button")
--test
-- if IsValid(tests) then tests:Remove() end
-- tests = vgui.Create("esclib.glow_button")
-- tests:SetSize(75,25)
-- tests:SetPos(ScrW()/2, ScrH()/2)
-- tests:SetButtonText("Test")
-- tests:SetBackgroundColor(Color(13,13,13))
-- tests:SetBackgroundHoverColor(Color(20,20,20))
-- tests:SetBackgroundColor2(Color(20,20,20))
-- tests:SetBackgroundHoverColor2(Color(0,255,100))
-- tests:SetGlowMode("always")