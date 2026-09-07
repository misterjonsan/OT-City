local clamp = math.Clamp
local max, min = math.max, math.min
local random = math.random

local shadow_clr = Color(0,0,0)
local mat_shadow_clr = Color(0,0,0, 200)


local function isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and y >= ry and x < rx + rw and y < ry + rh
end

local function GetIndexFromX(text, font, x)
	local px = 0
	for i = 1, #text do
		surface.SetFont(font)
		local w = surface.GetTextSize(utf8.sub(text, i, i))
		if x >= px and x <= px + w then
		 	return i
		end
		px = px + w
	end
	return nil
end


local function GetOffsetFromX(text, font, x)
	local px = 0
	for i = 1, #text do
		surface.SetFont(font)
		local w = surface.GetTextSize(utf8.sub(text, i, i))
		if x >= px and x <= px + w then
		 	return px
		end
		px = px + w
	end
	return 0
end





-- rewrited https://github.com/Herover/fancytext
PANEL = {}
function PANEL:Init()
	local clr = echat.addon:GetColors()
	self.selection_color = clr.main.text_selection
	self.default_color = clr.main.text

	self:SetMouseInputEnabled(true)
	self.mx_start, self.my_start, self.mx_end, self.my_end = nil

	self.sepwide = 18	-- We cant run surface.GetTextSize if the panel is made too early

	self.should_draw = true
	self.lines = {}
	self.maxlines = false --false or number
	self.curwide = 0
	self.margin = 5
	self.line_space_y = echat.addon:GetVar("chat_spacey") or 1

  	self.maxwide = 0 --Max known curwide used
	
	self.fontInternal = nil
	self.font = echat:AdaptiveFont("echat", 16, 500)
	
	self.scroll = 0
	self.max_tall = 0
	
	self.pnlCanvas = vgui.Create( "Panel", self )
	-- self.pnlCanvas:SetCursor("beam")
	self.pnlCanvas.OnMousePressed = function( self, code ) self:GetParent():OnMousePressed( code ) end
	self.pnlCanvas:SetMouseInputEnabled( true )
	self.pnlCanvas.PerformLayout = function( pnl )
		self.pnlCanvas.VBar = self.vBar
		self.pnlCanvas.OnMouseReleased = function(pnl, code) self:OnMouseReleased(code) end
		-- self.pnlCanvas.Think = self.CanvasThink
		self:_PerformLayout()
		self:InvalidateParent()
	end

	-- Create the scroll bar
	self.VBar = vgui.Create( "esclib.scrollbar", self )
	self.VBar:Dock( RIGHT )
	self.VBar:SetSpeed(6)
	self.VBar:SetSoftness(0.1)
	self.VBar:SetColor(clr.main.accent)

	-- local me = self
	self.sel_start = nil 
	self.sel_end = nil
	self.selected = {}

	local selected = self.selected
	local lines = self.lines
	local sel_start = self.sel_start
	local sel_end = self.sel_end

	local spacer, ctall = surface.GetTextSize( " " )

	self.pnlCanvas.CalculateMaxTall = function(pnl)
		local liney = 0

		for l_n=1, #lines do
			local l_v = lines[l_n]

			local h = 0
			for i_n=1, #l_v do
				local i_v = l_v[i_n]
				if istable(i_v[2]) then
					h = max(h, (i_v[2].h or 0))
				end
			end

			liney = liney + h + self.line_space_y
		end

		return liney
	end

	self.pnlCanvas.Paint = function(pnl, width, height)
		table.Empty(selected)

		local has_selection = self.mx_start and self.my_start and self.mx_end and self.my_end

		if font then
			surface.SetFont( font )
		end

		local bg_col = nil
		local color = self.default_color
		local font = self.font
		local offsetX, offsetY = 0, 0
		local clickable_context = nil
		local selection_color = self.selection_color

		
		self.sepwide = spacer
		local liney = 0

		for l_n=1, #lines do
			local l_v = lines[l_n]
			local lastx = 0
			local scroll = self.VBar:GetScroll()
			local should_draw = ((liney+20 > scroll) and (liney < scroll + self:GetTall())) and self.should_draw

			local h = 0
			local w = 0

			for i_n=1, #l_v do
				local i_v = l_v[i_n]

				local is_selected, reversed = false
				if sel_start and sel_end then
					local start_line, end_line, start_pos, end_pos = sel_start.line, sel_end.line, sel_start.pos, sel_end.pos
				  
					--reverse if needed
					if start_line > end_line or (start_line == end_line and start_pos > end_pos) then
						start_line, end_line = end_line, start_line
						start_pos, end_pos = end_pos, start_pos
						reversed = true
					elseif (start_pos == end_pos) and (start_line == end_line) then
						if (sel_start.offset_i or 0) >= (sel_end.offset_i or 0) then
							reversed = true
						end
					end

					if (l_n >= start_line and l_n <= end_line) and
						((l_n ~= end_line or i_n <= end_pos) and (l_n ~= start_line or i_n >= start_pos)) then
						is_selected = true
					end
				end

				local is_startword = false
				local is_endword = false
				local text_type = i_v[1]

				if is_selected then
					is_startword = (sel_start.line == l_n and sel_start.pos == i_n)
					is_endword = (sel_end.line == l_n and sel_end.pos == i_n)
				end

				w = i_v[2].w or 0
				h = max(h, i_v[2].h or 0)


				-------------
				/// TYPES ///
				-------------
				if text_type == "text" and should_draw then

					if bg_col then
						draw.RoundedBox(0,lastx,liney,w,h,bg_col)
					end

					--draw selection
					if is_selected then
						if is_startword and is_endword then --if only one world
							if not reversed then
								local offset_start = sel_start.offset_x
								local offset_end = w - sel_end.offset_x
								draw.RoundedBox(0, lastx + offset_start, liney, w - offset_start - offset_end, h, selection_color)
							else
								local offset_start = sel_end.offset_x
								local offset_end = w - sel_start.offset_x
								draw.RoundedBox(0, lastx + offset_start, liney, w - offset_start - offset_end, h, selection_color)
							end
						elseif is_startword then
							if reversed then
								local offset = sel_start.offset_x
								draw.RoundedBox(0,lastx, liney, offset,h, selection_color)
							else
								local offset = sel_start.offset_x
								draw.RoundedBox(0,lastx+offset, liney, w-offset,h, selection_color)
							end
						elseif is_endword then
							if reversed then
								local offset = sel_end.offset_x
								draw.RoundedBox(0,lastx+offset, liney, w-offset,h, selection_color)
							else
								local offset = sel_end.offset_x
								draw.RoundedBox(0,lastx, liney, offset,h, selection_color)
							end
						else
							draw.RoundedBox(0,lastx, liney, w,h, selection_color)
						end
					end
					
					if ( (color.r + color.g + color.b)/3 > 50 ) then --draw shadow only for daaaaaaark colors
						self:PaintTextpart( i_v[2].text, font, lastx+1 + offsetX, liney+1 + offsetY, shadow_clr ) --shadow
					end
					self:PaintTextpart( i_v[2].text, font, lastx + offsetX, liney + offsetY, color)

				elseif (text_type == "image" or text_type == "emoji") and should_draw then
					if bg_col then
						draw.RoundedBox(0,lastx,liney,w,h,bg_col)
					end

					if is_selected then
						draw.RoundedBox(0,lastx, liney, w,h, selection_color)
					end

					surface.SetMaterial( i_v[2].mat )

					surface.SetDrawColor(mat_shadow_clr)
					surface.DrawTexturedRect( lastx + offsetX+1, liney + offsetY+1, i_v[2].w, i_v[2].h )

					surface.SetDrawColor(color)
					surface.DrawTexturedRect( lastx + offsetX, liney + offsetY, i_v[2].w, i_v[2].h )
				elseif text_type == "color" then
					color = i_v[2].clr
				elseif text_type == "rainbow" then
					color = HSVToColor(  ( (CurTime() * i_v[2].speed ) + i_v[2].offset) % 360, 1, 1 )
				elseif text_type == "shaking" then
					local value = i_v[2].speed
					if (value == 0) then
						offsetX = 0
						offsetY = 0
					else
						offsetX = random(-value, value)
						offsetY = random(-value, value)
					end
				elseif text_type == "font" then
					font = i_v[2]["font"]
				elseif text_type == "blank" or text_type == "gap" and should_draw then
					if bg_col and text_type ~= "gap" then
						draw.RoundedBox(0,lastx,liney,w,h,bg_col)
					end

					if is_selected and text_type ~= "gap" then
						draw.RoundedBox(0,lastx, liney, w,h, selection_color)
					end
				elseif text_type == "separator" and should_draw then
					if bg_col then
						draw.RoundedBox(0,lastx,liney,w,h,bg_col)
					end

					if is_selected then
						draw.RoundedBox(0,lastx, liney, w,h, selection_color)
					else
						draw.RoundedBox(0,lastx, liney+h*0.5 + offsetY-2, w-10, h*0.25, color)
					end

				elseif text_type == "panel" and should_draw then
					if bg_col then
						draw.RoundedBox(0,lastx,liney,w,h,bg_col)
					end

					if is_selected then
						draw.RoundedBox(0,lastx, liney, w,h, selection_color)
					end

					i_v[2].panel:SetPos( lastx, liney )
					i_v[2].panel:SetVisible( true )
				elseif text_type == "clickable" then
					if not i_v[2].fn then 
						clickable_context = nil 
					else
						clickable_context = {fn = i_v[2].fn, key=i_v[2].key}
					end
				elseif text_type == "bg_col" then
					bg_col = i_v[2].clr
				end
			


				-----------------------
				/// SELECTION LOGIC ///
				-----------------------
				-- if w and h then

				---- if you need to draw clickable_context then uncomment following:
				-- if should_draw and clickable_context and w and h then
				-- 	draw.RoundedBox(0, lastx, liney+h+2, w,1, selection_color)
				-- end
				
				if should_draw then

					local mx,my = gui.MouseX(), gui.MouseY()
					mx, my = pnl:ScreenToLocal(mx,my)

					if isPointInRect(mx, my, lastx, liney, w, h) then
						if clickable_context then
							pnl:SetCursor("hand")
							
							if self.lmb_clicked then
								clickable_context.fn(i_v)
								self.lmb_clicked = false
							end
						else
							pnl:SetCursor("beam")
						end
					end
						

					if has_selection then
						--if start point at element
						if isPointInRect(self.mx_start, self.my_start, lastx, liney, w, h) then
							if text_type == "text" then
								local ind = GetIndexFromX(i_v[2].text, font, self.mx_start-lastx)
								if not ind then continue end
								if not reversed then ind = ind - 1 end
								local subbed = utf8.sub(i_v[2].text, 1, ind)
								sel_start = {
									line=l_n,
									pos=i_n,
									offset_i=ind,
									offset_x=esclib.util.GetTextSize(subbed,font).w
								}
							else
								sel_start = {line=l_n,pos=i_n}
							end
						end

						--if end point at element
						if isPointInRect(self.mx_end, self.my_end, lastx, liney, w, h) then
							if text_type == "text" then --if text
								local ind = GetIndexFromX(i_v[2].text, font, self.mx_end-lastx)
								if not ind then continue end
								if reversed then ind = ind - 1 end
								local subbed = utf8.sub(i_v[2].text, 1, ind)
								sel_end = {
									line=l_n,
									pos=i_n,
									offset_i=ind,
									offset_x=esclib.util.GetTextSize(subbed,font).w
								}
							else
								sel_end = {line=l_n,pos=i_n}
							end
						end
					end
				end
				
				if not has_selection then
					--clear selection
					sel_start = nil
					sel_end = nil
				end

				-------------------------
				/// START / END WORDS ///
				-------------------------
				if is_selected then
					if is_startword and is_endword then
						local news_tbl = {}
						esclib:SafeMerge(news_tbl, i_v, true)
						news_tbl["data"] = {}
						news_tbl["data"]["start"] = sel_start
						news_tbl["data"]["end"] = sel_end
						news_tbl["data"]["is_start"] = true
						news_tbl["data"]["is_end"] = true
						news_tbl["data"]["reversed"] = reversed
						table.insert(selected, news_tbl)
					elseif is_startword then
						local news_tbl = {}
						esclib:SafeMerge(news_tbl, i_v, true)
						news_tbl["data"] = {}
						news_tbl["data"]["start"] = sel_start
						news_tbl["data"]["is_start"] = true
						news_tbl["data"]["reversed"] = not reversed
						table.insert(selected, news_tbl)
					elseif is_endword then
						local news_tbl = {}
						esclib:SafeMerge(news_tbl, i_v, true)
						news_tbl["data"] = {}
						news_tbl["data"]["end"] = sel_end
						news_tbl["data"]["is_end"] = true
						news_tbl["data"]["reversed"] = reversed
						table.insert(selected, news_tbl)
					else
						if istable(i_v[2]) then
							i_v[2].line = l_n
						end
						table.insert(selected, i_v)
					end
				end
				-- end

				lastx = lastx + w
				
			end

			liney = liney + h + self.line_space_y
		end
	end

end

function PANEL:DataToText(data)
	local l_v = data
	local i_v
	local result = ""
	for i_n=1, #l_v do
		i_v = l_v[i_n]
		local text_type = i_v[1]
		local value = i_v[2]
		prev_line = cur_line
		if text_type == "text" then
			if i_v["data"] ~= nil and (i_v["data"].is_start or i_v["data"].is_end) then
				local data = i_v["data"]

				if data.is_start and data.is_end then
					local is_reversed = data.reversed
					local text = value.text

					if is_reversed then
						text = utf8.sub(text, data["end"].offset_i+1, data["start"].offset_i)
					else --if not reversed
						text = utf8.sub(text, data["start"].offset_i+1, data["end"].offset_i)
					end

					result = result..text
				elseif data.is_start then
					local is_reversed = data.reversed
					local text = value.text

					data = data["start"]

					if is_reversed then
						text = utf8.sub(text, data.offset_i+1, -1)
					else
						text = utf8.sub(text, 1, data.offset_i)
					end

					result = result..text
				elseif data.is_end then
					local is_reversed = data.reversed
					local text = value.text

					data = data["end"]

					if is_reversed then
						text = utf8.sub(text, data.offset_i+1, -1)
					else
						text = utf8.sub(text, 1, data.offset_i)
					end

					result = result..text
				end
			else
				result = result..value.text
			end
		elseif text_type == "blank" then
			result = result.." "
		elseif text_type == "emoji" then
			result = result..":"..value.name..":"
		elseif text_type == "separator" or (text_type == "gap" and value.use_as_newline) then
			result = result.."\n"
		end
	end
	return result
end

function PANEL:SetMaximumLines(num)
	self.maxlines = num
end

function PANEL:GetSelectedText()
	if table.IsEmpty(self.selected) then return end
	return self:DataToText(self.selected)
end

function PANEL:GetText()
	local result = ""
	local l_n, l_v
	for l_n=1, #self.lines do
		l_v = self.lines[l_n]
		result = result .. self:DataToText(l_v)
	end
	return result
end

function PANEL:CopySelectedToClipboard(notify)
	local text = self:GetSelectedText()
	if text then
		SetClipboardText(text)
		self:ClearSelection()
		
		if notification and notify then
			notification.AddLegacy(echat.addon:Translate("copied_to_clipboard"), NOTIFY_GENERIC, 3)
			chat.PlaySound()
		end
	end
end

function PANEL:OnKeyCodePressed(code)
	if (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and (code == KEY_C) then
		self:CopySelectedToClipboard(true)
	end
end

function PANEL:UpdateCanvasTall()
	local pnl = self:GetCanvas()
	local liney = pnl:CalculateMaxTall()
	if liney > self.max_tall then
		self.max_tall = liney
		pnl:SetTall(liney)
	end
end

--[[---------------------------------------------------------
   Name: SizeToContents
-----------------------------------------------------------]]
function PANEL:SizeToContents()
	self:SetSize( self.pnlCanvas:GetSize() )
end

function PANEL:GetVBar()
	return self.VBar
end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:InnerWidth()

	return self:GetCanvas():GetWide()

end

function PANEL:GetContentWide()
  return self.maxwide
end

function PANEL:SetW(w)
  self:SetWide(w)
  self:GetCanvas():SetWide(w)
end

--[[---------------------------------------------------------
   Name: Rebuild
-----------------------------------------------------------]]
function PANEL:Rebuild()

	--self:GetCanvas():SizeToChildren( false, true )
		
	-- Although this behaviour isn't exactly implied, center vertically too
	if ( self.m_bNoSizing && self:GetCanvas():GetTall() < self:GetTall() ) then
		self:GetCanvas():SetPos( 0, (self:GetTall()-self:GetCanvas():GetTall()) * 0.5 )
	end
	
end

--[[---------------------------------------------------------
   Name: PerformLayout
-----------------------------------------------------------]]
function PANEL:_PerformLayout()

	self:UpdateCanvasTall()

	self.scroll = self.VBar:GetScroll()
	local vbarvisible = self.VBar:IsVisible()
	
	if self.PerformLayout then
		self:PerformLayout()
	end

	local Wide = self:GetWide()
	local YPos = 0

	self.pnlCanvas:SetTall( self.max_tall )

	
	self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
	YPos = self.VBar:GetOffset()
	self.pnlCanvas:SetWide( Wide )
	
	self.VBar:SetScroll( self.scroll )
	self.VBar:SetVisible( vbarvisible )
end

--[[---------------------------------------------------------
   Name: OnMouseWheeled
-----------------------------------------------------------]]
function PANEL:OnMouseWheeled( dlta )
	if not self.VBar:IsEnabled() then return end
	return self.VBar:OnMouseWheeled( dlta )
end

--[[---------------------------------------------------------
   Name: OnVScroll
-----------------------------------------------------------]]
function PANEL:OnVScroll( iOffset )
	if self.max_tall < self:GetTall() then
		self.pnlCanvas:SetPos( 0, self:GetTall()-self.max_tall )
	else
		self.pnlCanvas:SetPos( 0, iOffset )
	end
	self.scroll = -iOffset
end

function PANEL:Clear()

	return self.pnlCanvas:Clear()

end

function PANEL:GotoTextEnd()
	self.VBar:SetScroll( self.pnlCanvas:GetTall()-self:GetTall() )
	self.scroll = self.VBar:GetScroll()
end

function PANEL:SetVerticalScrollbarEnabled( bool )
	self.VBar:SetEnabled( bool )
	self.VBar:SetVisible( bool )
end

function PANEL:SetFontInternal( font )
	self:InsertFontChange( font )
	self.fontInternal = font
end






---------------------------
/// ADDING CUSTOM ITEMS ///
---------------------------
function PANEL:AppendItem( item )
	if #self.lines == 0 then
		table.insert(self.lines, {})
	end

	if type(item) == "string" then
		return self:AppendText( item )
	end
	local wide = istable(item[2]) and item[2].w or 0
	if self.curwide + wide < self:GetWide() - self.margin*2 then
		--If above passes, theres enough room to add another word
		self.curwide = self.curwide + wide
		table.insert( self.lines[#self.lines], item )
		self.maxwide = max(self.curwide, self.maxwide)
	else
		--Otherwise add another line before inserting part
		local spacing_line = {"gap", {w = self:GetWide() - (self.curwide+self.margin*2+5), h = 4, use_as_newline = true}}
		table.insert(self.lines[#self.lines], spacing_line)

		table.insert(self.lines, {})
		self.maxwide = max(self.curwide, self.maxwide)
		self.curwide = wide
		table.insert( self.lines[#self.lines], item )
	end

	if self.maxlines and #self.lines > self.maxlines then
		table.remove( self.lines, 1 )
	end
	
	self:_PerformLayout()
end

function PANEL:AppendText( text )
    surface.SetFont( self.fontInternal and self.fontInternal or self.font )
	
	local function appendPart(part)
		local wide, tall = surface.GetTextSize(part)
		if part and (part ~= "") then
			self:AppendItem( {"text", {text = part, w = wide, h = tall}} )
		end
	end

	local function processLine(line)
		local parts = {}
		local currentPart = ""
		for i = 1, #line do
			local char = line:sub(i, i)
			local testPart = currentPart .. char
			local wide, _ = surface.GetTextSize(testPart)

			if char == " " then
				table.insert(parts, currentPart)
				currentPart = char
				continue
			end

			if (wide) <= (self.pnlCanvas:GetWide()-5) then
				currentPart = testPart
			else
				table.insert(parts, currentPart)
				currentPart = char
			end
		end
		table.insert(parts, currentPart)
		return parts
	end

	local etext = string.Explode("\n", text) -- Split newlines in sections

	for l, line in pairs(etext) do -- Loop lines
		local lineParts = processLine(line)

		for n, part in pairs(lineParts) do
			appendPart(part)
		end

		if l ~= #etext then -- Begin new line, except if it's the last line
			self:AppendEmptyToEnd(nil, false) --bool add \n to copied text
		end
	end

	self.maxwide = max(self.curwide, self.maxwide)
	self:_PerformLayout()
end


function PANEL:AppendBlank(width)
	if not width then width = 4 end

	if self.fontInternal then
		surface.SetFont( self.fontInternal )
	else
		surface.SetFont( self.font )
	end
	local wide, tall = surface.GetTextSize( " " )

	self:AppendItem( {"blank", {w = width, h = tall}} )
end

function PANEL:AppendSeparator(height)
	if not height then height = 10 end
	self:AppendItem( {"separator", {w = self:GetWide(), h = height}} )
end

function PANEL:AppendEmptyLine(height)
	if not height then height = 4 end
	self:AppendItem( {"gap", {w = self:GetWide() - self.margin*2-5, h = height}} ) --gap is blank but with no selection
end

function PANEL:AppendEmptyToEnd(height, use_as_newline) --add empty space to the end of current width
	if not height then height = 4 end
	self:AppendItem( {"gap", {w = self:GetWide() - (self.curwide+self.margin*2+5), h = height, use_as_newline = use_as_newline}} ) --gap is blank but with no selection
end

function PANEL:AppendImage( w,h,mat )
	self:AppendItem( {"image", {w=w, h=h, mat=mat}} )
end

--echat functionality
function PANEL:AppendEmoji( name )
	local emojies = echat:GetEmojiTable()
	if not emojies[name] then
		self:AppendText(":"..name..":") 
		return 
	end

	local size = draw.GetFontHeight(self.font)
	self:AppendItem( {"emoji", {mat = emojies[name], name=name, w = size, h = size}} )
end

function PANEL:AppendPanel( pnl )
	if not IsValid(pnl) then return end
	pnl:SetParent( self.pnlCanvas )
	self.pnlCanvas:Add( pnl )
	self:AppendItem( {"panel", {w=pnl:GetWide(),h=pnl:GetTall(), panel=pnl}} )
end

function PANEL:InsertColorChange( r, g, b, a )
	local clr = color_white
	local clr = IsColor(r) and r or Color(r,g,b,a)

	self:AppendItem( {"color", {["clr"]= Color(r, g, b, a), ["w"] = 0, ["h"] = 0}} )
end

function PANEL:InsertBackgroundColorChange( r, g, b, a )
	if not r then
		self:AppendItem( {"bg_col", {["clr"]=nil, ["w"] = 0, ["h"] = 0}} )
		return
	end

	local clr = IsColor(r) and r or Color(r,g,b,a)
	self:AppendItem( {"bg_col", {["clr"]= clr, ["w"] = 0, ["h"] = 0}} )
end

--KEY: ONLY MOUSE_LEFT 
function PANEL:InsertClickable(fun, key)
	local key = key or MOUSE_LEFT
	if not isfunction(fun) then
		self:AppendItem( {"clickable", {["fn"]=nil, ["key"]=key, ["w"] = 0, ["h"] = 0}} )
		return
	end
	self:AppendItem( {"clickable", {["fn"]=fun, ["key"]=key, ["w"] = 0, ["h"] = 0}} )
end

--speed, offset
function PANEL:InsertRainbowEffect( speed, offset )
	local speed = speed or 75
	if not offset then
		offset = 10--math.random(0,255) --if you want to randomize different messages
	end
	
	self:AppendItem( {"rainbow", {speed=speed, offset = offset, w = 0, h = 0}} )
end

--expensive effect
function PANEL:AppendRainbowText( text, speed )
	local speed = speed or 100
	for i = 1, #text do
		self:InsertRainbowEffect(speed, -10*i)
		self:AppendText(text[i], true)
    end
end

function PANEL:InsertShakingEffect(speed) 
	local speed = speed or 0.5

	self:AppendItem( {"shaking", {["speed"]=speed, ["w"] = 0, ["h"] = 0}} )
end

function PANEL:InsertFontChange( font )
	surface.SetFont( font )
	self.font = font
	self:AppendItem( {"font", {["font"]=font, ["w"] = 0, ["h"] = 0}} )
end

function PANEL:GetFont()
	return self.font
end

function PANEL:Paint( w, h ) --background painting
	--for override
end

function PANEL:PaintTextpart( text, font, x, y, colour )
	surface.SetFont( font )
	surface.SetTextPos( x, y )
	surface.SetTextColor( colour )
	surface.DrawText( text )
	local px, py = surface.GetTextPos()
	return px-x, py-y
end

function PANEL:MouseAtPanel()
	local screenX, screenY = self:LocalToScreen( 0, 0 )
	local w,h = self:GetSize()
	local mx, my = gui.MousePos()

	return ((mx > screenX) && (mx < (screenX+w))) && ((my > screenY) && (my < (screenY+h)))
end


function PANEL:DoRightClick()
	--for override
end

function PANEL:OnMousePressed(code)
	if (code == MOUSE_RIGHT) then
		self:DoRightClick()
	end

	if self:MouseAtPanel() and (code == MOUSE_LEFT) then
		self:RequestFocus()
		self.selecting = true

		local scroll = self.VBar:GetScroll()
		local x,y = self:ScreenToLocal(gui.MouseX(),gui.MouseY())
		if self.max_tall < self:GetTall() then
			y = -(self:GetTall()- self.max_tall-y)
		else
			y = y + scroll
		end

		self.sel_start = nil
		self.sel_end = nil

		self.mx_start = x
		self.my_start = y
	end
end

--just drop all vars
function PANEL:ClearSelection()
	self.sel_start = nil
	self.sel_end = nil
	self.mx_start = nil
	self.my_start = nil
	self.mx_end = nil
	self.my_end = nil
end

function PANEL:OnMouseReleased(code)
	self.lmb_clicked = (code == MOUSE_LEFT)
	timer.Simple(0, function()
		self.lmb_clicked = false
	end)
	if self.selecting then self.selecting = false end
end

function PANEL:Think()
	if self.selecting then
		if not input.IsMouseDown(MOUSE_LEFT) and not self:MouseAtPanel() then
			self.selecting = false
			return
		end

		local scroll = self.VBar:GetScroll()
		local x,y = self:ScreenToLocal(gui.MouseX(),gui.MouseY())
		if self.max_tall < self:GetTall() then
			y = -(self:GetTall()- self.max_tall-y)
		else
			y = y + scroll
		end

		self.mx_end = x
		self.my_end = y

		if input.IsMouseDown(MOUSE_LEFT) then
			local screenX, screenY = self:LocalToScreen( 0, 0 )
			local w,h = self:GetSize()
			local mx, my = gui.MousePos()

			if ((mx > screenX) && (mx < (screenX+w))) && ((my < (screenY+10))) then
				local strenght = clamp(-0.5 * ((screenY+10) / (my or 1)), -1, 0)
				self.VBar:AddScroll( strenght )
			end

			if ((mx > screenX) && (mx < (screenX+w))) && ((my > (screenY+h-10))) then
				local strenght = clamp(0.7 * ((my or 1) / (screenY+h)), 0, 1)
				self.VBar:AddScroll( strenght )
			end
		end
	end
end

function PANEL:OnFocusChanged(gained)
	if not gained then
		self:ClearSelection()
	end
end


vgui.Register('echat.richtext', PANEL)