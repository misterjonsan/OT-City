local PANEL = {}

function PANEL:Init()
    self.clr = echat.addon:GetColors()
    self.DropButton.Paint = self.PaintComboDownArrow

    self.TextColor = self.clr.main.text_gray
    self.TextColorHovered = self.clr.main.text
    self.BackgroundColor = self.clr.main.bg2
end

function PANEL:SetBackgroundColor(clr)
    self.BackgroundColor = clr
end

function PANEL:OpenMenu( pControlOpener )

    if ( pControlOpener && pControlOpener == self.TextEntry ) then
        return
    end

    -- Don't do anything if there aren't any options..
    if ( #self.Choices == 0 ) then return end

    -- If the menu still exists and hasn't been deleted
    -- then just close it and don't open a new one.
    if ( IsValid( self.Menu ) ) then
        self.Menu:Remove()
        self.Menu = nil
    end

    -- If we have a modal parent at some level, we gotta parent to that or our menu items are not gonna be selectable
    local parent = self
    while ( IsValid( parent ) && not parent:IsModal() ) do
        parent = parent:GetParent()
    end
    if ( not IsValid( parent ) ) then parent = self end

    self.Menu = vgui.Create("echat.menu", parent)
    self.Menu:SetWide(self:GetWide())

    if ( self:GetSortItems() ) then
        local sorted = {}
        for k, v in pairs( self.Choices ) do
            local val = tostring( v ) --tonumber( v ) || v -- This would make nicer number sorting, but SortedPairsByMemberValue doesn't seem to like number-string mixing
            if ( string.len( val ) > 1 && not tonumber( val ) && val:StartWith( "#" ) ) then val = language.GetPhrase( val:sub( 2 ) ) end
            table.insert( sorted, { id = k, data = v, label = val } )
        end
        for k, v in SortedPairsByMemberValue( sorted, "label" ) do
            local option = self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )
            option:SetFont(self:GetFont())
            option:SetTextColor(self:GetTextColor())
            if ( self.ChoiceIcons[ v.id ] ) then
                option:SetIcon( self.ChoiceIcons[ v.id ] )
            end
            if ( self.Spacers[ v.id ] ) then
                self.Menu:AddSpacer()
            end
        end
    else
        for k, v in pairs( self.Choices ) do
            local option = self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
            option:SetFont(self:GetFont())
            option:SetTextColor(self:GetTextColor())
            if ( self.ChoiceIcons[ k ] ) then
                option:SetIcon( self.ChoiceIcons[ k ] )
            end
            if ( self.Spacers[ k ] ) then
                self.Menu:AddSpacer()
            end
        end
    end

    local x, y = self:LocalToScreen( 0, 0 )

    self.Menu:InvalidateLayout(true)
    self.Menu:SetMinimumWidth( self:GetWide() )
    self.Menu:Open( x, y-self.Menu:GetTall(), false, self )

    self:OnMenuOpened( self.Menu )

end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, self.BackgroundColor)
end

function PANEL.PaintComboDownArrow( panel, w, h )

    if IsValid(panel.ComboBox.Menu) then
        --font dont need to be adapted
        draw.SimpleText("▼","es_echat_12_500",w*0.5,h*0.5, panel.ComboBox.clr.main.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("▲","es_echat_12_500",w*0.5,h*0.5, panel.ComboBox.clr.main.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

end

vgui.Register("echat.choicelist", PANEL, "DComboBox")
