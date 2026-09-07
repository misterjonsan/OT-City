local accessor_fn = esclib.accessor
local PANEL = {}

accessor_fn(PANEL, "value", "Value", "SetValue", "string")
accessor_fn(PANEL, "values", "Values", {}, "table")
accessor_fn(PANEL, "opened", "Opened", false, "boolean")

function PANEL:Init()
    self.colors = esclib.addon:GetColors()

    accessor_fn(self, "font", "Font", esclib:AdaptiveFont("esclib", 20, 500), "string")
    accessor_fn(self, "IconFont", "IconFont", esclib:AdaptiveFont("esclib", 12, 500), "string")
    accessor_fn(self, "TextColor", "TextColor", self.colors.button.text)
    accessor_fn(self, "TextColorHover", "TextColorHover", self.colors.button.text_hover)
    accessor_fn(self, "BackgroundColor", "BackgroundColor", self.colors.button.main)
    accessor_fn(self, "BackgroundColorHover", "BackgroundColorHover", self.colors.button.hover)
    accessor_fn(self, "context_parent", "ContextParent", self:GetParent())


    self.offset_x = esclib:AdaptiveSize(10)
    self:SetWide(100)
    self:SetTall(draw.GetFontHeight(self.font)+10)
    self:SetText("")
end

function PANEL:DoClick()
    local bg = IsValid(self.context_parent) and self.context_parent or self:GetParent()
    self:SetOpened(true)
    --Context
    local context = vgui.Create("esclib.contextmenu", bg)
    context:SetColor(self.BackgroundColor)
    context:SetBorderColor(self.BackgroundColorHover)
    local x,y = self:LocalToScreen(0,self:GetTall())
    context:SetPosClamped(x, y)
    context:SetBorder(0)
    context:SetEnableLayouting(false)

    function context.OnClose(pnl)
        if not IsValid(self) then return end
        self:SetOpened(false)
    end

    function context.Paint(pnl,w,h)
        if not IsValid(self) then pnl:Remove() return end
        draw.RoundedBoxEx(8,0,0,w,h,self.BackgroundColorHover, false, false, true, true)
        draw.RoundedBoxEx(6,2,2,w-4,h-4,self.BackgroundColor, false, false, true, true)
    end

    self.context = context

    for _,v in ipairs(self.values) do
        local btn = context:AddButton(v, function()
            self:SetValue(v)
        end)
        btn:SetFont(self.font)
        btn:SetTextColor(self.TextColor)
        btn:SetColor(self.BackgroundColor)
        btn:SetColorHover(self.BackgroundColorHover)
        btn:SetWide(self:GetWide())
    end


    context:SetWide(self:GetWide() - context.list:GetBorder()*2)
    self:OnClick(context)
    return context
end

function PANEL:OnClick(context)
    --For override
end

function PANEL:OnValueChanged(value)
    --For override
end

function PANEL:SetValue(value)
    self.value = value
    self:OnValueChanged(value)
end

function PANEL:IsOpened()
    return self.opened
end

function PANEL:Paint(w,h)
    local hovered = self:IsHovered()
    draw.RoundedBoxEx(8, 0, 0, w, h, self.BackgroundColorHover, true, true, not self.opened, not self.opened)
    draw.RoundedBoxEx(6,2,2,w-4,h-(self.opened and 0 or 4), hovered and self.BackgroundColorHover or self.BackgroundColor, true, true, not self.opened, not self.opened)

    draw.SimpleText(self.value, self.font, self.offset_x, h*0.5, hovered and self.TextColorHover or self.TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(self:IsOpened() and "▲" or "▼", self.IconFont, w-self.offset_x, h*0.5-1, hovered and self.TextColorHover or self.TextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function PANEL:SizeToContents()
    self:SetTall(draw.GetFontHeight(self.font)+10)

    local max_width = 0
    for _,v in ipairs(self.values) do
        local w,h = esclib.util:TextSize(v, self.font)
        if w > max_width then max_width = w end
    end
    self:SetWide(max_width+self.offset_x*4)
end

vgui.Register("esclib.dropdown", PANEL, "DButton")