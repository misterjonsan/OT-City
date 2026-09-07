local PANEL = {}

PANEL.pallete = {
    red = Color(255, 0, 0),
    green = Color(0, 255, 0),
    blue = Color(0, 0, 255),
    yellow = Color(255, 255, 0),
    orange = Color(255, 165, 0),
    purple = Color(128, 0, 128),
    pink = Color(255, 192, 203),
    cyan = Color(0, 255, 255),
    white = Color(255, 255, 255),
    black = Color(0, 0, 0),
	gold = Color(255, 215, 0),
	silver = Color(192, 192, 192),
	gray = Color(128, 128, 128),
}

AccessorFunc(PANEL, "TextColor", "TextColor")
AccessorFunc(PANEL, "DrawShadow", "DrawShadow", FORCE_BOOL)
AccessorFunc(PANEL, "colors", "Colors") --addon colors

function PANEL:Init()
    self.RawText = {}
    self.Lines = {}
    self.MaxWidth = nil
    self.MaxHeight = nil
    self.TextWidth = 0
    self.TextHeight = 0
    self.Font = esclib:AdaptiveFont("esclib", 20, 500)
    self.LineHeight = 0
    self.TextColor = color_white
    self.LineOffset = 0
    self.DrawShadow = false

    self:SetColors(esclib.addon:GetColors())
    self:SetFont(self.Font)
end

function PANEL:SetMaxDimensions(maxWidth, maxHeight)
    self.MaxWidth = maxWidth
    self.MaxHeight = maxHeight
    self:ProcessText()
end

function PANEL:SetMaxWidth(maxWidth)
    self.MaxWidth = maxWidth
    self:ProcessText()
end

function PANEL:SetMaxHeight(maxHeight)
    self.MaxHeight = maxHeight
    self:ProcessText()
end

function PANEL:SetLineOffset(offset)
    self.LineOffset = offset
    self:ProcessText()
end

function PANEL:GetLineOffset()
    return self.LineOffset
end

function PANEL:SetFont(font)
    self.Font = font
    self.LineHeight = draw.GetFontHeight(font) + self.LineOffset
    self:ProcessText()
end

function PANEL:GetFont()
    return self.Font
end

function PANEL:SetText(...)
    self.RawText = {...}
    self:ProcessText()
end

function PANEL:AppendText(text)
    table.insert(self.RawText, text)
    self:ProcessText()
end

function PANEL:AppendColor(color)
    table.insert(self.RawText, color)
    self:ProcessText()
end

function PANEL:SetTextParsed(text)
    local bracket_match = esclib.text:MatchSplit(text, "<(.-)>")
    for k,v in ipairs(bracket_match) do
        if not v.matched then
            table.insert(self.RawText, v.value)
            continue
        end

        --If pattern is matched, get text between brackets
        local text = string.sub(v.value, 2, -2)
        local not_matched = true

        --Check in pallete
        local col = self.pallete[text]
        if col then
            table.insert(self.RawText, col)
            not_matched = false
        elseif text == "/" or text == "\\" then --restore original color
            table.insert(self.RawText, self:GetTextColor())
            not_matched = false
        end

        --Check in addon colors
        local splitted_text = string.Explode(".", text)
        local prev_col = self.colors
        for _, clr_name in ipairs(splitted_text) do
            if prev_col[clr_name] then
                prev_col = prev_col[clr_name]
            end
        end
        if IsColor(prev_col) then
            table.insert(self.RawText, prev_col)
            not_matched = false
        end

        if not_matched then
            table.insert(self.RawText, v.value)
        end
    end

    self:ProcessText()
end


function PANEL:GetText()
    return self.RawText
end

function PANEL:ProcessText()
    self.Lines = {}
    self.TextWidth = 0
    self.TextHeight = 0
    
    if #self.RawText == 0 then return end
    
    surface.SetFont(self.Font)
    
    local currentColor = self.TextColor
    local currentLine = {segments = {}, width = 0}
    local maxWidth = self.MaxWidth or 9999
    
    for _, item in ipairs(self.RawText) do
        if IsColor(item) then
            currentColor = item
        elseif type(item) == "string" then
            -- Replace escaped newlines with actual newlines
            local processedItem = string.Replace(item, "\\n", "\n")
            local parts = string.Explode("\n", processedItem)
            
            for i, part in ipairs(parts) do
                if i > 1 then
                    table.insert(self.Lines, currentLine)
                    currentLine = {segments = {}, width = 0}
                end
                
                if part ~= "" then
                    local segment = {text = part, color = currentColor}
                    local segmentWidth = surface.GetTextSize(part)
                    
                    if currentLine.width + segmentWidth > maxWidth then
                        local words = string.Explode(" ", part)
                        local currentWords = ""
                        
                        for _, word in ipairs(words) do
                            local testText = currentWords == "" and word or (currentWords .. " " .. word)
                            local testWidth = surface.GetTextSize(testText)
                            
                            if currentLine.width + testWidth > maxWidth then
                                if currentWords ~= "" then
                                    table.insert(currentLine.segments, {
                                        text = currentWords,
                                        color = currentColor
                                    })
                                    self.TextWidth = math.max(self.TextWidth, currentLine.width + surface.GetTextSize(currentWords))
                                    
                                    table.insert(self.Lines, currentLine)
                                    currentLine = {segments = {}, width = 0}
                                    currentWords = word
                                else
                                    currentWords = word
                                end
                            else
                                currentWords = testText
                            end
                        end
                        
                        if currentWords ~= "" then
                            table.insert(currentLine.segments, {
                                text = currentWords,
                                color = currentColor
                            })
                            currentLine.width = currentLine.width + surface.GetTextSize(currentWords)
                            self.TextWidth = math.max(self.TextWidth, currentLine.width)
                        end
                    else
                        table.insert(currentLine.segments, segment)
                        currentLine.width = currentLine.width + segmentWidth
                        self.TextWidth = math.max(self.TextWidth, currentLine.width)
                    end
                end
            end
        end
    end
    
    if #currentLine.segments > 0 then
        table.insert(self.Lines, currentLine)
    end
    
    local maxLines = self.MaxHeight and math.floor(self.MaxHeight / self.LineHeight) or #self.Lines
    
    if #self.Lines > maxLines then
        local lastLine = self.Lines[maxLines]
        local ellipsis = "..."
        local ellipsisWidth = surface.GetTextSize(ellipsis)
        
        if lastLine.width + ellipsisWidth <= maxWidth then
            table.insert(lastLine.segments, {
                text = ellipsis,
                color = Color(255, 255, 255)
            })
        end
        
        for i = maxLines + 1, #self.Lines do
            self.Lines[i] = nil
        end
    end
    
    self.TextHeight = #self.Lines * self.LineHeight
    
    local width = self.TextWidth
    local height = self.TextHeight
    
    if self.MaxWidth and width > self.MaxWidth then
        width = self.MaxWidth
    end
    
    if self.MaxHeight and height > self.MaxHeight then
        height = self.MaxHeight
    end
    
    self:SetSize(width, height)
end

function PANEL:GetTextSize()
    return self.TextWidth, self.TextHeight
end

function PANEL:GetTextWidth()
    return self.TextWidth
end

function PANEL:GetTextHeight()
    return self.TextHeight
end

function PANEL:Paint(w, h)
    surface.SetFont(self.Font)
    
    local y = 0
    
    for _, line in ipairs(self.Lines) do
        surface.SetTextPos(0, y)
        
        for _, segment in ipairs(line.segments) do
            if self.DrawShadow then
                local x, y = surface.GetTextPos()
                surface.SetTextColor(esclib.shadow)
                surface.SetTextPos(x + 1, y + 1)
                surface.DrawText(segment.text)
                surface.SetTextPos(x, y)
            end
            
            surface.SetTextColor(segment.color)
            surface.DrawText(segment.text)
        end
        
        y = y + self.LineHeight
    end
    
    return true
end

vgui.Register("esclib.label", PANEL, "DPanel")


-- if IsValid(test) then test:Remove() end

-- test = vgui.Create("esclib.label")
-- test:SetDrawShadow(true)
-- test:SetFont(esclib:AdaptiveFont("esclib", 20, 500))
-- test:SetMaxDimensions(500, 1000)
-- test:SetText(Color(255,0,0), "Hello", Color(0,255,0), "World")
-- test:SetTextParsed("Привет, <frame.bg>Мирs! lorem ipsum dolor <green>sit amet <yellow>consectetur</>, adipiscing elit. sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. lorem ipsum dolor sit amet, consectetur adipiscing elit. sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
-- esclib.print({test:GetSize()})