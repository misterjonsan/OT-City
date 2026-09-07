local max = math.max
local min = math.min

------------------
--# MAIN BUILD #--
------------------
function echat:Build()
	echat.addon:ClearDownloadCache("temp")

	self.skin = echat.addon:GetCurrentSkin()
	self.sizing = false
	local clr = echat.addon:GetColors()
	local ply = LocalPlayer()

	--fullscreen panel
	local bg = vgui.Create("EditablePanel")
	bg:SetText("")
	bg:SetSize(esclib.scrw,esclib.scrh)
	bg:SetZPos(-10)
	bg:SetMouseInputEnabled(true)
	bg:SetKeyboardInputEnabled(true)
	bg.Paint = nil
	self.bg = bg

	function bg:OnKeyCodeReleased(key)
		if key == KEY_ESCAPE then
			echat:Close()
		end
	end

	-- Fullscreen button, detecting click outside
	local loose_focus_button = bg:Add("DButton")
	loose_focus_button:Dock(FILL)
	loose_focus_button:SetZPos(-1)
	loose_focus_button:SetText("")
	loose_focus_button:SetCursor("arrow")
	loose_focus_button:SetMouseInputEnabled(true)
	loose_focus_button:SetKeyboardInputEnabled(true)
	loose_focus_button.Paint = nil
	function loose_focus_button:DoClick()
		echat:Close()
	end
	loose_focus_button:SetZPos(-1)

	-----------------
	--# DRAG BASE #--
	-----------------
	local panel_top_height = max(bg:GetTall()*0.028, 20)
	local pnl = vgui.Create("esclib.dragbase", bg)
	if IsValid(echat.chatbox) then echat.chatbox:Remove() end
	echat.chatbox = pnl
	local size_w = bg:GetWide()*(echat.addon:GetVar("size_w") or 0.45)
	local size_h = bg:GetTall()*(echat.addon:GetVar("size_h") or 0.37)
	local pos_x  = bg:GetWide()*(echat.addon:GetVar("pos_x") or 0.01)
	local pos_y  = bg:GetTall()*(echat.addon:GetVar("pos_y") or 0.41)
	pnl:SetSize(size_w, size_h)
	pnl:SetPos(pos_x, pos_y)
	pnl:SetSizable(true)
	pnl:SetZPos(10)
	pnl:SetMinimumSize(bg:GetWide()*0.2, bg:GetTall()*0.2)
	pnl:DockPadding(5,panel_top_height,5,10)
	pnl.alpha_clr = table.Copy(clr.main.bg2)

	local sizing_clr = Color(13,13,13)
	local sizing_sub_clr = clr.main.accent
	local sizing_text = echat.addon:Translate("sizing_mode")

	local font = echat:AdaptiveFont("echat", 16, 500)
	function pnl:PaintOver(w,h)
		if echat.sizing then
			draw.RoundedBox(8,0,0,w,h,sizing_sub_clr)
			draw.RoundedBox(6,3,3,w-6,h-6,sizing_clr)

			draw.SimpleText(sizing_text, font, w*0.5, h*0.5, sizing_sub_clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(string.format("(%dpx x %dpx)", w, h), font, w*0.5, h*0.5, sizing_sub_clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(w.."px", font, w*0.5, h-15, sizing_sub_clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(h.."px", font, w-15, h*0.5, sizing_sub_clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			draw.SimpleText(w.."px", font, w*0.5, 15, sizing_sub_clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(h.."px", font, 15, h*0.5, sizing_sub_clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
	end

	--------------------
	--# OPENED PANEL #--
	--------------------
	local opened_base = pnl:Add("EditablePanel")
	opened_base:Dock(FILL)
	opened_base:InvalidateParent(true)
	opened_base:SetAlpha(0)
	echat.chatbox.opened_panel = opened_base

	local text_entry_font = echat:AdaptiveFont("echat", 18, 500)
	local button_tall = draw.GetFontHeight(text_entry_font)+4 -- font

	--panel for text entry, chat modes
	local bottom_panel = opened_base:Add("EditablePanel")
	bottom_panel:Dock(BOTTOM)
	bottom_panel:DockPadding(5,4,5,4) --just few pixels
	echat.bottom_panel = bottom_panel
	function bottom_panel:Paint(w,h)
		-- draw.RoundedBoxEx(8,0,0,w,h,clr.main.bg2,false,false,true,true)
	end

	
	function opened_base:Paint(w,h)
		-- draw.RoundedBox(0,0,0,w,h-bottom_panel:GetTall(), clr.main.bg)
	end

	------------------
	--# TEXT MODES #--
	------------------
	local text_mode = bottom_panel:Add("echat.choicelist")
	local tw, th = esclib.util:TextSize(echat.addon:Translate("chat_mode_normal"),text_entry_font)
	text_mode:SetWide(tw+30)
	text_mode:Dock(LEFT)
	text_mode:SetFont(text_entry_font)
	text_mode:SetColor(clr.main.text)
	text_mode:SetBackgroundColor(color_transparent)

	text_mode:AddChoice(echat.addon:Translate("chat_mode_normal"), nil, true)
	text_mode:AddChoice(echat.addon:Translate("chat_mode_team"))
	for k,_ in pairs(echat.chat_modes) do
		text_mode:AddChoice(k)
	end
	bg.mode_pnl = text_mode

	function text_mode:OnSelect(index, value, data)
		local tw, th = esclib.util:TextSize(value,self:GetFont())
		self:SetWide(tw+30)
	end
	
	local close_button = pnl:Add("DButton")
	close_button:Hide()
	close_button:SetText("")
	echat.chatbox.close_button = close_button
	function close_button:Paint(w,h)
		
		draw.SimpleText("r", "Marlett", w*0.5, h*0.5, self:IsHovered() and clr.main.text_gray or clr.main.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function close_button:DoClick() 
		echat:Close()
	end
	
	local btn_mar_x = bottom_panel:GetWide()*0.05
	local send_button = bottom_panel:Add("DButton")
	send_button:SetWide(button_tall)
	send_button:Dock(RIGHT)
	send_button:SetText("")
	send_button:eAddHint( echat.addon:Translate("send"), nil, nil, bg)
	send_button:DockMargin(btn_mar_x,0,btn_mar_x,0)
	function send_button:Paint(w,h)
		local hovered = self:IsHovered()
		esclib.draw:MaterialCentered(w*0.5,h*0.5,w*0.4,hovered and clr.main.text_hover or clr.main.text,echat:GetMaterial("send.png"))
	end

	local settings_button = bottom_panel:Add("DButton")
	settings_button:SetWide(button_tall)
	settings_button:Dock(RIGHT)
	settings_button:SetText("")
	settings_button:eAddHint(echat.addon:Translate("settings"), nil, nil, bg)
	settings_button:DockMargin(btn_mar_x,0,0,0)
	function settings_button:Paint(w,h)
		local hovered = self:IsHovered()
		esclib.draw:MaterialCentered(w*0.5,h*0.5,w*0.4,hovered and clr.main.text_hover or clr.main.text,esclib.Materials["cog.png"])
	end
	function settings_button:DoClick()
		esclib:opensettings("echat")
	end

	local font = echat:AdaptiveFont("echat", 16, 500)
	--panel paint
	pnl:NoClipping(true)
	local chat_name = echat.addon:GetVar("chat_name") or echat.config.chat_name
	function pnl:Paint(w,h)
		if not self.opened then return end
		if echat.sizing then return end

		self.alpha_clr.a = opened_base:GetAlpha()
		
		local px,py,pw,ph = self:GetDockPadding()
		if self.ambilight then
			-- draw.RoundedBox(8,px-3,-3,w-px-pw+6,h-ph+6,clr.main.bg)
			self.ambilight:Draw(px-2,0,w-px-pw+4,h-ph+2)
		end

		draw.RoundedBox(6,px,2,w-px-pw,h-ph-2,clr.main.bg)
		
		draw.SimpleText(chat_name, font, 15, panel_top_height*0.5-1, clr.main.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	------------------
	--# TEXT ENTRY #--
	------------------
	local text_entry = bottom_panel:Add("echat.textentry")
	text_entry:Dock(FILL)
	text_entry:DockMargin(0,0,btn_mar_x,0)
	text_entry:SetFont(text_entry_font)
	text_entry:SetPlaceholderText(echat.addon:Translate("type_something"))
	text_entry:SetDrawLanguageID(false)
	text_entry:SetMaximumCharCount(echat.config.max_message_len)
	text_entry:SetMultiline(echat.config.multiline)
	timer.Simple(0, function() -- update size
		if text_entry and text_entry.CalculateParentSize then text_entry:CalculateParentSize() end
	end)
	echat.chatbox.text_entry = text_entry
	function send_button:DoClick()
		text_entry:OnEnter( text_entry:GetText() )
	end

	function text_entry:OnKeyCode(key) 
		if input.IsKeyDown(KEY_ESCAPE) then
			echat:Close()
		end
	end

	function text_entry:OnEnter(text)
		self:SetText("")
		echat:SendMessageToServer(text)
		echat:Close()
	end

	--Auto complete sorting
	local function sortWordsBySubstring(words, target)
	  table.sort(words, function(a, b)
	    local aScore = string.find(a.text, target, 1, true)
	    local bScore = string.find(b.text, target, 1, true)
	    if aScore == bScore then
	      return a.text < b.text
	    else
	      return (aScore > bScore)
	    end
	  end)
	  return words
	end

	--Auto complete
	function text_entry:GetAutoComplete( text, word )
		local suggestions = {}

		local max_iters = echat.addon:GetVar("autocomplete_count") or 20 --maximum commands visible at once
		local iters = 0
		local need_break = false
		for id,fn in pairs(echat.auto_complete) do
			local prompt = fn(text, word)
			if prompt then
				for k,cmd in ipairs(prompt) do
					if iters >= max_iters then
						need_break = true
						break
					end
					table.insert(suggestions,cmd)
					iters = iters + 1
				end
				if need_break then
					break
				end
			end
		end
		
		suggestions = sortWordsBySubstring(suggestions, text)

		return suggestions
	end

	function text_entry:OnChange(text)
		hook.Run("ChatTextChanged", self:GetText())
	end


	--------------------
	--# EMOJI BUTTON #--
	--------------------
	if echat.config.emojies then
		local emoji_button = bottom_panel:Add("DButton")
		emoji_button:SetWide(button_tall)
		emoji_button:Dock(RIGHT)
		emoji_button:SetText("")
		emoji_button:eAddHint(echat.addon:Translate("emoji"), nil, nil, bg)
		emoji_button:DockMargin(btn_mar_x,0,0,0)
		function emoji_button:Paint(w,h)
			local hovered = self:IsHovered()
			esclib.draw:MaterialCentered(w*0.5,h*0.5,w*0.4,hovered and clr.main.text_hover or clr.main.text,echat:GetMaterial("emoji.png"))
		end
		function emoji_button:DoClick()
			local bg_clicker = esclib:GenerateBGClicker()
			bg_clicker.Paint = nil
			
			local mx,my = gui.MouseX(), gui.MouseY()
			local emoji_size = echat:AdaptiveSize(32)

			local pnl = bg_clicker:Add("DPanel")
			pnl:SetSize(emoji_size*10+5*12, esclib.scrh*0.4)
			pnl:SetPos(mx-pnl:GetWide()*0.5, my-pnl:GetTall()-15)
			function pnl:Paint(w,h)
				draw.RoundedBox(4,0,0,w,h,clr.main.bg2)
			end

			local scroll = pnl:Add("esclib.scrollpanel")
			scroll:Dock(FILL)
			scroll:SetScrollSpeed(10)
			
			local layout = scroll:Add("DIconLayout")
			layout:Dock(FILL)
			layout:SetBorder(5)
			layout:SetSpaceX(5)
			layout:SetSpaceY(5)

			local emoji_list = echat:GetEmojiList()
			table.sort(emoji_list)

			local prev_char = nil

			local font = echat:AdaptiveFont("echat", 24, 500)
			local font_height = draw.GetFontHeight(font)
			for i, name in ipairs(emoji_list) do
				if name == "" then continue end
				local ch = string.sub(name, 1,1)

				if prev_char ~= ch then
					local ch_pnl = layout:Add("DPanel")
					ch_pnl:SetSize(pnl:GetWide()-layout:GetBorder(),font_height+2)
					function ch_pnl:Paint(w,h)
						draw.RoundedBox(0,0,h-2,w,2,clr.main.scrollbar)
						draw.SimpleText(ch, font, 5, h*0.5-2, clr.main.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end
				end

				local img_btn = layout:Add("DImageButton")
				img_btn:SetMaterial(echat:GetEmoji(name))
				img_btn:SetSize(emoji_size,emoji_size)
				img_btn:eAddHint( ":"..name..":", nil, nil, bg_clicker)

				function img_btn:DoClick()
					text_entry:SetValue(text_entry:GetValue()..":"..name..":")
					bg_clicker:Close()
					text_entry:RequestFocus()
					text_entry:SetCaretPos( string.len(text_entry:GetValue() or "") ) 
				end

				prev_char = ch
			end
		end
	end



	local msg_base = vgui.Create("EditablePanel", opened_base)
	echat.bg.message_base = msg_base
	msg_base:Dock(FILL)

	----------------
	--# RICHTEXT #--
	----------------
	local richtext = vgui.Create("echat.richtext", msg_base)
	echat.richtext = richtext
	richtext:Dock(FILL)
	richtext:DockMargin(opened_base:GetWide()*0.01,0,0,0)
	richtext:SetW(opened_base:GetWide())
	richtext:SetMouseInputEnabled(true)
	richtext:GetVBar():SetColor(clr.main.scrollbar)
	richtext:SetMaximumLines(echat.addon:GetVar("max_lines") or 512)

	function richtext:DoRightClick()
		local text = richtext:GetSelectedText()
		if text then
			local bg_clicker = esclib:GenerateBGClicker()
			bg_clicker.Paint = nil

			local text = echat.addon:Translate("copy")
			local font = echat:AdaptiveFont("echat", 16, 500)

			local text_w, text_h = esclib.util:TextSize(text,font)
			local btn = bg_clicker:Add("DButton")
			btn:SetSize(text_w+40, text_h + 10)
			btn:SetText("")
			function btn:Paint(w,h)
				local hovered = self:IsHovered()
				draw.RoundedBox(8,0,0,w,h,hovered and clr.main.button_hover or clr.main.button)
				esclib.draw:MaterialCentered(h*0.6, h*0.5,h*0.3, hovered and clr.main.accent or clr.main.text, echat:GetMaterial("copy.png"))
				draw.SimpleText(text,font, h*1.1, h*0.5, clr.main.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
			local mx,my = gui.MouseX(), gui.MouseY()
			btn:SetPos(mx+2,my+2)

			function btn:DoClick()
				if IsValid(richtext) then
					richtext:CopySelectedToClipboard(true)
					bg_clicker:Close()
				end
			end


			function bg_clicker:OnClose()
				btn:Remove()
			end
		end
	end

	richtext:GotoTextEnd()


	------------------------
	--# GO TO END BUTTON #--
	------------------------
	local gotoend_btn = msg_base:Add("DButton")
	gotoend_btn:SetZPos(1)
	gotoend_btn:SetText("")
	function gotoend_btn:DoClick()
		if (richtext:GetVBar():GetScroll() + 50 < richtext.pnlCanvas:GetTall()-richtext:GetTall()) then
			richtext:GotoTextEnd()
		end
	end
	local gotoend_material = echat:GetMaterial("down_arrow.png")
	local gotoend_text = echat.addon:Translate("goto_end")
	local gotoend_button_size = echat:AdaptiveSize(28)
	gotoend_btn:SetSize(gotoend_button_size,gotoend_button_size)
	echat.bg.message_base.gotoend_btn = gotoend_btn
	function gotoend_btn:Paint(w,h)
		if (richtext:GetVBar():GetScroll() + 50 < richtext.pnlCanvas:GetTall()-richtext:GetTall()) then
			self:SetCursor("hand")
			local hovered = self:IsHovered()

			esclib.draw:MaterialCentered(h*0.5, h*0.5+1, h*0.25, hovered and clr.main.accent or clr.main.text, gotoend_material)

		else
			self:SetCursor("arrow")
		end
	end


	--drag area
	pnl:SetDragArea(0,0,pnl:GetWide(),pnl:GetTall()*0.1)
	function pnl:OnSizing(w,h)
		echat.sizing = true
	end
	function pnl:OnEndSizing(w,h)
		echat.sizing = false
		richtext:AppendEmptyToEnd(nil, true)
		self:UpdateDragArea()
		self:InvalidateChildren()
		echat:InvalidateLayout()

		echat.addon:SetVar("size_w", (w / esclib.scrw) or 0.45) --save settings to file
		echat.addon:SetVar("size_h", (h / esclib.scrh) or 0.37)

		if echat.addon:GetVar("ambilight") then
			local colors = {
				echat.addon:GetVar("ambilight_clr1") or Color(0,225,255, 100),
				echat.addon:GetVar("ambilight_clr2") or Color(0,255,157, 100)
			}
			pnl.ambilight = esclib.util:PrecacheAmbilight(8, colors, 1, 1)
			pnl.ambilight:SetDrawBlur(true, self)
		end
	end
	pnl:OnEndSizing(pnl:GetWide(), pnl:GetTall())
	function pnl:OnEndDragging(newx, newy)
		echat.addon:SetVar("pos_x", (newx / esclib.scrw) or 0.02) --save settings to file
		echat.addon:SetVar("pos_y", (newy / esclib.scrh) or 0.41)
	end
	
	pnl:UpdateDragArea()
	echat:InvalidateLayout()
	self:Close() --hidden by default

	echat:LoadModules()
end

--place items in chat depending on size
function echat:InvalidateLayout()
	local chatbox = echat.chatbox
	local richtext = echat.richtext

	local dx, dy, dw, dh = chatbox:GetDockPadding()
	local close_button = echat.chatbox.close_button
	close_button:SetSize(dy,dy)
	close_button:SetPos(chatbox:GetWide()-close_button:GetWide()-5)

	local msg_base = echat.bg.message_base
	msg_base:InvalidateChildren(true)
	msg_base:InvalidateParent(true)
	msg_base:InvalidateLayout(true)

	local gotoend_btn = echat.bg.message_base.gotoend_btn
	gotoend_btn:SetPos(msg_base:GetWide() - gotoend_btn:GetWide()-15, chatbox:GetTall() - gotoend_btn:GetTall() - 70)

	local px,py = chat.GetChatBoxPos()
	local pw,ph = chat.GetChatBoxSize()
	hook.Run("echat.InvalidateLayout", px,py,pw,ph)

end

--lua refresh
if echat.IsValid && echat:IsValid() then echat:Restart() end