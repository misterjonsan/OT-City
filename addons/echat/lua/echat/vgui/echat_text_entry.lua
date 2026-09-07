local min = math.min
local max = math.max
local clamp = math.Clamp

local PANEL = {}

AccessorFunc(PANEL, "autocompletetext", "AutoCompleteText")

function PANEL:Init()
	self.clr = echat.addon:GetColors()
	self:SetHistoryEnabled(true)
	-- self:SetFont(echat:AdaptiveFont("echat", 20, 500))

	self.check_cooldown = 0

	self.oldcaret = 0
	self.oldstart = 0 --selection
	self.oldend = 0

	self.scroll = 0
	self.caretX = 0
	self.selStartX = 0
	self.selEndX = 0

	self.padding_left = 10
	self.padding_right = 10

	self.blink = true
	self.next_blink = 0

	self.text_width = 0
	self.text_height = 0
	self.text_len = 0

	local old_fontchange = self.SetFont
	function self:SetFont(font)
		old_fontchange(self,font)
		-- self:SetFontInternal(font)
	end

	self:SetUpdateOnType(true)
end

function PANEL:Paint(w,h)
	draw.RoundedBox(6,0,0,w,h,self.clr.main.text_entry)
	self:DrawTextEntryText(self.clr.main.text, self.clr.main.text_selection, self.clr.main.text )
	self:DrawAutocompleteHint(w,h)
end

function PANEL:Think()
	local caret_pos = self:GetCaretPos()
	if caret_pos ~= self.oldcaret then
		self:CalculateScroll()
		self.oldcaret = caret_pos
	end

	local start, stop = self:GetSelectedTextRange()
	if (start ~= stop) and ((self.oldstart ~= start) or (self.oldend ~= stop)) then
		local w,h = self:GetSize()
		local text = self:GetText()
		surface.SetFont(self:GetFont())

		self.selStartX = surface.GetTextSize(eutf8.sub(text, 0, start-1)) - self.scroll
	    self.selEndX = surface.GetTextSize(eutf8.sub(text, 0, stop-1)) - self.scroll

		self.oldstart = start
		self.oldend = stop

		if self.selStartX > w then
            self.selStartX = w
        end
        if self.selEndX < 0 then
            self.selEndX = 0
        end
	end
end


function PANEL:DrawAutocompleteHint(w,h)
	local text = self:GetValue()
    local font = self:GetFont()
	local caret_pos = self:GetCaretPos()
	local autocomplete = self:GetAutoCompleteText()
    if autocomplete && (caret_pos == #text) then
    	local text_w, text_h = esclib.util:TextSize(text, font)
		draw.SimpleText(autocomplete, font, text_w+5,  self.text_height+1, self.clr.main.text_gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end


--offset in px
function PANEL:GetCaretOffsetX()
	local pos = self:GetCaretPos()
	surface.SetFont(self:GetFont())
	local text = self:GetText()
	local tw, th = surface.GetTextSize(eutf8.sub(text,0,pos-1))
	local max_w, max_h = self:LocalToScreen(self:GetWide(),self:GetTall())
	return min(tw, max_w)
end

function PANEL:SendToChat()
	local text = self:GetText()

	if ( IsValid( self.Menu ) ) then
		self.Menu:Close()
		self:RequestFocus()
		return
	end

	self:FocusNext()
	self:OnEnter( self:GetText() )
	self.HistoryPos = 0

	if string.Trim( text ) ~= "" then -- if not empty string
		echat:SendMessageToServer(text)

		table.insert(self.History, text)

		timer.Simple(0,function() --gmod things
			if not IsValid(self) then return end
			self:SetText("")
		end)
	else
		timer.Simple(0,function() --gmod things
			if not IsValid(self) then return end
			self:SetText("")
		end)
	end
end

function PANEL:OnKeyCodeTyped( code )

	local ply = LocalPlayer()
	local text = self:GetText()
	local has_menu = IsValid( self.Menu)

	self:OnKeyCode( code )

	--if pressed space when menu is opened
	if code == KEY_SPACE && has_menu then
		self.Menu:Close()
		self:RequestFocus()
		self.HistoryPos = 0
		return true --prevent 
	end

	--arrows
	if (code == KEY_RIGHT || code == KEY_LEFT || code == KEY_ENTER) and has_menu then
		if has_menu then
			self.Menu:Close()
			self:RequestFocus()
			self.HistoryPos = 0
		end
	end

	--On enter
	if ( (not input.IsKeyDown(KEY_LSHIFT) and code == KEY_ENTER) and self:GetEnterAllowed() ) then
		if ( IsValid( self.Menu ) ) then
			self.Menu:Close()
			self:RequestFocus()
			return
		end

		local text = self:GetText()

		self:FocusNext()
		self:OnEnter( text )
		self.HistoryPos = 0

		table.insert(self.History, text)
		timer.Simple(0, function()
			if not IsValid(self) then return end
			self:SetText("")
		end)
	end

	--recalculate size
	timer.Simple(0, function()
		if IsValid(self) and self.CalculateParentSize then
			self:CalculateParentSize()
		end
	end)

	-- history related
	if ( self.m_bHistory || has_menu ) then

		if ( code == KEY_UP and (self:GetLineCount() < 2) ) then
			self.HistoryPos = self.HistoryPos - 1
			self:UpdateFromHistory()
		end

		if  ( (code == KEY_DOWN) and (self:GetLineCount() < 2) ) then
			self.HistoryPos = self.HistoryPos + 1
			self:UpdateFromHistory()
		end

		if (code == KEY_TAB) then
			self.HistoryPos = self.HistoryPos - 1
			self:UpdateFromHistory()
		end

		if code == KEY_TAB then return true end --prevent loose focus
	end
end

function PANEL:GetLineCount()
	local text = self:GetText()
	local count = 1
	for _ in string.gmatch(text, "\n") do
	    count = count + 1
	end
	return count
end
	
function PANEL:CalculateScroll()
	local w,h = self:GetSize()

	local font = self:GetFont()
	local text = self:GetText()

	local caret_pos = self:GetCaretPos()

	if text == "" then return end
	self.caretX = esclib.util:TextSize(eutf8.sub(text, 0, caret_pos-1),font)
	if self.caretX - self.scroll > w - self.padding_right then 
        self.scroll = self.caretX - (w - self.padding_right)
    elseif self.caretX - self.scroll < self.padding_left and self.scroll > 0 then
        self.scroll = self.caretX
    end
    self.caretX = self.caretX - self.scroll
end

function PANEL:CalculateParentSize()
	local lines = math.min(self:GetLineCount(), 3) --only to 3 lines up
	local font = self:GetFont()
	local fh = draw.GetFontHeight(font)
	local parent = self:GetParent()
	local px, py, pw, ph = parent:GetDockPadding()
	parent:SetTall(fh*lines+2 + py + ph)
	parent:InvalidateParent()
end

function PANEL:OnTextChanged( noMenuRemoval )
	
	self.HistoryPos = 0
	local text = self:GetText()

	if ( self:GetUpdateOnType() ) then
		self:UpdateConvarValue()
		self:OnValueChange( text )
	end

	if ( IsValid( self.Menu ) && not noMenuRemoval ) then
		self:SetAutoCompleteText(text)
		self.Menu:Remove()
	end

	local font = self:GetFont()
	local tw,th = esclib.util:TextSize(text, font)
	self.text_width = tw
	self.text_height = th
	self.text_len = #text

	local caret_pos = self:GetCaretPos()
	if caret_pos < 1 then
		caret_pos = utf8.len(text)
	end

	if text == "" then return end
	local subbed_text = eutf8.sub(text, 0, caret_pos-1) --perfomance +- friendly (utf8 suc s)
	
	local last_word = eutf8.getLastWord(subbed_text) or ""
	local tab = self:GetAutoComplete( text, last_word )
	if ( tab and istable(tab) and (#tab > 0)) then
		self:OpenAutoComplete( tab )

		local target = tab[1].text
		local offset = tab[1].offset or 0
		local target_len = utf8.len(target)
		local last_text_len = utf8.len(last_word)

		if last_text_len < target_len then
			local tail_auto_text = eutf8.sub(target, last_text_len+offset, target_len-1)
			self:SetAutoCompleteText(tail_auto_text)
		else
			self:SetAutoCompleteText("")
		end
	else
		self:SetAutoCompleteText("")
	end

	self:OnChange()

end

function PANEL:OpenAutoComplete( tab )

	if ( not tab ) then return end
	if ( #tab == 0 ) then return end

	self.Menu = vgui.Create("echat.menu")

	local font = self:GetFont()
	local count = self.Menu:ChildCount()
	local max_w = 50
	for i=1,#tab do
		local v = tab[i]
		local option = self.Menu:AddOption( v.text, function() 
			self:SetText( v.text ) 
			self:SetCaretPos( v.text:len() ) 
			self:RequestFocus() 
		end )
		option.command_data = v
		option.DoClick = function(pnl)
			self:UpdateFromMenu(i)
		end

		if v.icon then option:SetIcon(v.icon) end
		option:SetDescription(v.description or "")
		option:SetArgs(v.args)
		local tw = option:GetFullWide()
		if tw > max_w then
			max_w = tw
		end
	end

	local x, y = self:LocalToScreen( 0, 0 )
	self.Menu:SetMinimumWidth( self:GetWide() )
	self.Menu:Open( x, y, true, self )
	self.Menu:SetMaxHeight( echat.chatbox:GetTall()*0.5 )
	self.Menu:SetPos( x, y-min(self.Menu:GetMaxHeight(), self.Menu:GetTall())+1 )
end

local function replace_last(str, replacement)
    local lastWord = str:match("[%S%p]+$") or ""
    local new_str = utf8.sub(str, 1, utf8.len(str) - utf8.len(lastWord))
    return new_str .. replacement
end

local function replaceWordAtCaret(str, replacement, caretPos)
	if str == "" then return replacement end
    local head = eutf8.sub(str, 0, caretPos-1)
    local tail = eutf8.sub(str, caretPos)

	head = replace_last(string.TrimRight(head), replacement)
	return head.." "..tail, utf8.len(head)+1
end

function PANEL:UpdateFromMenu(new_pos)

	local pos = new_pos or self.HistoryPos
	local num = self.Menu:ChildCount()

	self.Menu:ClearHighlights()

	if ( pos < 1 ) then pos = num end
	if ( pos > num ) then pos = 1 end

	local item = self.Menu:GetChild( pos )
	if ( not item ) then
		self:SetText( "" )
		self.HistoryPos = pos
		return
	end
	if item.command_data and item.command_data.type == "command" then
		self.command_data = item.command_data
	end

	self.Menu:HighlightItem( item )
	self.Menu:ScrollToChild( item )

	--replace last word
	local target = item:GetText()
	local current_text = self:GetText()
	local target_len = #target
	local current_text_len = #current_text

	if self.Menu:ChildCount() < 2 then
		self.Menu:Close()
	end

	local replaced_text, replaced_text_len = replaceWordAtCaret(string.Trim(current_text, " "), target, self:GetCaretPos())
	self:SetText(replaced_text)
	self:SetCaretPos(self:GetCaretPos()+replaced_text_len)

	self:OnTextChanged(true)
	self.HistoryPos = pos

	self:SetAutoCompleteText("")
end



function PANEL:UpdateFromHistory()

	if ( IsValid( self.Menu ) ) then
		return self:UpdateFromMenu()
	end

	local pos = self.HistoryPos
	-- Is the Pos within bounds?
	if #self.History < 1 then return end
	if ( pos < 0 ) then pos = #self.History end
	if ( pos > #self.History ) then pos = 0 end

	local text = self.History[ pos ]
	if ( not text ) then text = "" end

	self:SetText( text )
	self:SetCaretPos( text:len() )

	self:OnTextChanged()

	self.HistoryPos = pos

end

vgui.Register("echat.textentry", PANEL, "DTextEntry")