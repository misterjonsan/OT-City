local PANEL = {}

AccessorFunc(PANEL, "placeholder_text", "PlaceholderText")
AccessorFunc(PANEL, "background_color", "BackgroundColor")
AccessorFunc(PANEL, "background_color2", "BackgroundColor2")
AccessorFunc(PANEL, "text_color", "TextColor")
AccessorFunc(PANEL, "text_color_gray", "TextColorGray")
AccessorFunc(PANEL, "text_color_selected", "TextColorSelected")

function PANEL:Init()
    self.clr = esclib.addon:GetColors()
    local clr = self.clr

    --Text Entry
    self.textentry = self:Add("DTextEntry")
    self.textentry:Dock(FILL)
    self.textentry:SetFont(esclib:AdaptiveFont("esclib", 20, 500))

    --Vars
    self:SetCursor("beam")
    self:SetText("")
    self.border = 0
    self:SetBorder(self.border)

    --Colors
    self:SetBackgroundColor(clr.button.main)
    self:SetBackgroundColor2(clr.button.hover)
    self:SetTextColor(clr.button.text)
    self:SetTextColorGray(clr.button.text_gray)
    self:SetTextColorSelected(clr.button.hover)

    function self.textentry.Paint(pnl, w,h)
        local text = pnl:GetText()
        if self.placeholder_text and text=="" then
            draw.SimpleText(self.placeholder_text, pnl:GetFont(), 2,h*0.5-1, self.text_color_gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        pnl:DrawTextEntryText(self.text_color, self.text_color_selected, self.text_color)
    end

    local orig_setenabled = self.textentry.SetEnabled
    function self.textentry.SetEnabled(pnl, val)
        if val then
            pnl:SetCursor("beam")
            self:SetCursor("beam")
        else
            pnl:SetCursor("no")
            self:SetCursor("no")
        end
        orig_setenabled(pnl,val)
    end
end

function PANEL:SetInputPanel(pnl)
    if not IsValid(pnl) then return end
    function self.textentry:OnMousePressed()
        if not IsValid(pnl) then return end
        pnl:SetKeyboardInputEnabled(true)
    end
    function self.textentry:OnLoseFocus()
        -- if not IsValid(self.textentry) or vgui.GetKeyboardFocus() == self.textentry then return end
        -- esclib.print("lose focus")
        if not IsValid(pnl) then return end
        pnl:SetKeyboardInputEnabled(false)
    end
end

function PANEL:OnMousePressed(mousecode)
    local te = self.textentry
    if not IsValid(te) then return end
    te:OnMousePressed(mousecode)
    te:RequestFocus()
    te:SetCaretPos(#(te:GetValue() or ""))
end

function PANEL:SetFont(font)
    self.textentry:SetFont(font)
end

function PANEL:GetFont()
    return self.textentry:GetFont()
end

function PANEL:GetText()
    return self.textentry:GetValue()
end

function PANEL:SetText(text)
    self.textentry:SetValue(text)
end

function PANEL:SetBorder(val)
    self.border = val
    self.textentry:DockMargin(val,0,val,0)
end

function PANEL:GetBorder()
    return self.border
end

function PANEL:GetTextEntry()
    return self.textentry
end

function PANEL:Paint(w,h)
    draw.RoundedBox(8, 0, 0, w, h, self.background_color2)
    draw.RoundedBox(6, 2, 2, w-4, h-4, self.background_color)
end

vgui.Register("esclib.textentry", PANEL, "EditablePanel")