local PANEL_META = FindMetaTable("Panel")

local clamp = math.Clamp
local sin = math.sin
local TimeFraction = math.TimeFraction
local random = math.random

-- --example
-- local pnl = vgui.Create("DPanel")
-- pnl:eSetHoverPanel(function(prnt)
-- 	local pnl = vgui.Create("DPanel")
-- 	pnl:SetSize(200,200)
-- 	return pnl
-- end)
function PANEL_META:eSetHoverPanel(generate_panel)
    if not isfunction(generate_panel) then return end

    local pnl = self

    local oldOnCursorEntered = self.OnCursorEntered
    local oldOnCursorExited = self.OnCursorExited

	local generated_pnl = generate_panel(self)
	generated_pnl:SetVisible(false)

    function self:OnCursorEntered()
        if isfunction(oldOnCursorEntered) then oldOnCursorEntered(self) end
        
        if not IsValid(generated_pnl) then return end

		generated_pnl:SetVisible(true)
        generated_pnl:SetMouseInputEnabled(false)
        generated_pnl:SetAlpha(0)
        generated_pnl:AlphaTo(255, 0.1)

        self.eHoverPanel = generated_pnl
        self.eHasHoverPanel = true

        local oldGeneratedPnlThink = generated_pnl.Think

        function generated_pnl:Think()
            if isfunction(oldGeneratedPnlThink) then oldGeneratedPnlThink(self) end

            if not IsValid(pnl) then
                if IsValid(generated_pnl) then generated_pnl:Remove() end
                return
            end

            if not pnl:IsHovered() then
				self:SetVisible(false)
            else
                self:SetVisible(true)
            end
        end
    end

    function self:OnCursorExited()
        if isfunction(oldOnCursorExited) then oldOnCursorExited(self) end

        if IsValid(self.eHoverPanel) then
            self.eHoverPanel:SetVisible(false)
        end
    end

	return generated_pnl
end

--align uses TEXT_ALIGN ENUM but TEXT_ALIGN_CENTER uses mouse pos
function PANEL_META:eAddHint(text, font, align, parent_panel)
    return self:eSetHoverPanel(function(hovered_panel)
        local pnl = vgui.Create("esclib.hint_panel", parent_panel)
        pnl:Setup(text, font, align, parent_panel, hovered_panel)
        return pnl
    end, true)
end


---------------------
--# QUICK WINDOWS #--
---------------------
function esclib:GenerateBGClicker(key_input, disable_anim)
	local clr = esclib.addon:GetColors()

	local uid = tostring(SysTime()):gsub("%.", "_")
	local hook_id = "esclib.bg_clicker_"..uid

	local scrw,scrh = esclib.scrw,esclib.scrh
	local bg = vgui.Create("EditablePanel")
	bg:SetSize(scrw,scrh)
	bg:MakePopup()
	bg:SetKeyboardInputEnabled(key_input or false)
	bg:SetAlpha(0)
	if not disable_anim then
		bg:AlphaTo(255,0.1)
	end
	bg:SetZPos(102)
	function bg:Paint(w,h)
		draw.RoundedBox(0, 0,0,w,h, clr.background.col)
	end

	function bg:Close()
		if self.OnClose then self:OnClose() end
		if not disable_anim then
			self:AlphaTo(0,esclib.addon:GetVar("animtime") or 0.01,0,function()
				self:Remove()
			end)
		else
			self:Remove()
		end

		hook.Remove("OnPauseMenuShow", hook_id)
	end

	function bg:OnMousePressed(key)
		self:Close()
	end

	function bg:OnKeyCodePressed(key)
		if (key == KEY_F4) or (key == KEY_ESCAPE) then
			self:Close()
		end
	end

	hook.Add("OnPauseMenuShow", hook_id, function()
		if not IsValid(bg) then 
			hook.Remove("OnPauseMenuShow", hook_id)
			return
		end

		bg:Close()
		hook.Remove("OnPauseMenuShow", hook_id)
		return false
	end)

	return bg
end



function esclib:GeneratePopWindow(key_input)
	self.ready2close = false

	local clr = esclib.addon:GetColors()

	local scrw,scrh = esclib.scrw,esclib.scrh
	local bg = self:GenerateBGClicker(key_input)

	local pnl = vgui.Create("esclib.frame",bg)
	pnl.bg = bg
	pnl:SetSize(scrw*0.3, scrh*0.2)
	pnl:Center()
	function pnl:OnRemove()
		bg:Remove()
	end

	function pnl:Close()
		bg:Close()
	end
	
	return pnl
end


-- EXAMPLE
-- esclib:TextInputWindow("title", "text", false, false, function(result)
-- 	print(result)
-- end, function()
-- 	return true
-- end)
function esclib:TextInputWindow(title, text, is_multiline, is_numeric, callback, custom_check, try_language)
    local wide = esclib.scrw * 0.35
    local tall = 0
	if is_numeric then is_multiline = false end
    local font = esclib:AdaptiveFont("esclib", 20, 500)
    local multiline_data = esclib.text:Multiline(text, font, wide)
	local font_height = draw.GetFontHeight(font)
    local clr = esclib.addon:GetColors()

    local pnl = self:GeneratePopWindow()
    pnl:SetTitle(title)
    pnl:SetSize(wide, esclib.scrh * 0.3)
    pnl:Center()
    pnl:SetRoundSize(8)
	pnl:SetGradientColor(clr.frame.bg)
	pnl:SetColorThink(true)
	pnl:SetAutoRestoreColor(true)
    local content = pnl:GetContent()

    local lbl = content:Add("DPanel")
    lbl:SetSize(wide, multiline_data.height + 5)
    lbl:Dock(TOP)
    lbl:DockMargin(0, 10, 0, 0)
    function lbl:Paint(w, h)
        esclib.text:DrawMultiline(multiline_data, w * 0.5, 0, clr.frame.text, TEXT_ALIGN_CENTER)
    end
    tall = tall + lbl:GetTall() + 20

	local offset = 10
	local input_base = content:Add("DPanel")
	if not is_multiline then
		input_base:SetSize(wide - offset * 2, font_height+offset+4)
	else
		input_base:SetSize(wide - offset * 2, font_height*2+offset+4)
	end
    input_base:Dock(TOP)
    input_base:DockMargin(10, 5, 10, 5)
	function input_base:Paint(w,h)
		draw.RoundedBox(8, 0, 0, w, h, clr.frame.accent)
	end

    local textinput = input_base:Add("DTextEntry")
    textinput:Dock(FILL)
	textinput:DockMargin(5,5,5,5)
    textinput:SetFont(font)
    textinput:SetTextColor(clr.frame.text)
	if is_multiline then
		textinput:SetMultiline(true)
		textinput:SetVerticalScrollbarEnabled(true)
	end

    tall = tall + input_base:GetTall() + 10

    if is_numeric then
        textinput:SetPlaceholderText("500")
        textinput:SetNumeric(true)
        function textinput:AllowInput(str)
            local disallow = true
            local text = self:GetText()

            if string.find(str, "%d") or (str == ".") then
                if string.find(text, "%.") then
                    return str == "."
                end

                disallow = false
            end

            return disallow
        end
    end

    function textinput:Paint(w, h)
        -- draw.RoundedBox(0, 0, 0, w, h, clr.frame.accent)

        local textcol = self:GetTextColor()
        self:DrawTextEntryText(textcol, clr.frame.text_hover, textcol)
    end

    function textinput:OnGetFocus()
        pnl.bg:SetKeyboardInputEnabled(true)
    end

    function textinput:OnLoseFocus()
        pnl.bg:SetKeyboardInputEnabled(false)
    end

    function textinput:Shake()
        local x = input_base:GetX()
        local copy_clr = table.Copy(self:GetTextColor())
        local anim = self:NewAnimation(0.2, 0, -1, function(anim, pnl)
            input_base:SetX(x)
            self:SetTextColor(copy_clr)
            input_base:Dock(TOP)
        end)

        anim.Think = function(anim, pnl, fraction)
            local sin_v = math.sin(Lerp(fraction, -math.pi, math.pi))
            copy_clr.g = math.Clamp(copy_clr.g + sin_v * 50, 0, 255)
            copy_clr.b = math.Clamp(copy_clr.b + sin_v * 50, 0, 255)
            pnl:SetTextColor(copy_clr)
            input_base:SetPos(x + sin_v * 10, input_base:GetY())
        end
    end

    function textinput:OnEnter(text)
        if isfunction(custom_check) then
            local custom_check = custom_check(text)

            if custom_check then
                self:Shake()
                return
            end
        end
        if is_numeric then
            callback(self:GetFloat() or 0)
        else
            callback(text)
        end
        pnl:Close()
    end

    local buttonlist = content:Add("DPanel")
    buttonlist:SetSize(content:GetWide(), content:GetTall() * 0.15)
    buttonlist:Dock(BOTTOM)
    buttonlist:DockMargin(0, 10, 0, 10)
    buttonlist.Paint = nil

    tall = tall + content:GetTall() * 0.18 + 40

    local border = 25
    local revert = buttonlist:Add("esclib.button")
    revert:SetText(esclib.addon:Translate("button_Discard", try_language))
    revert:SetSize(buttonlist:GetWide() * 0.5 - border, buttonlist:GetTall())
    revert:SetX(border * 0.5)
    revert:SetIcon(esclib:GetMaterial("cross.png"))
    revert:SetIconColor(clr.button.discard)
    function revert:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.discard_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)

		if hovered then pnl:SetTargetGradientColor(clr.button.discard_hover) end
    end
    function revert:DoClick()
        pnl:Close()
    end

    local confirm = buttonlist:Add("esclib.button")
    confirm:SetSize(revert:GetWide(), revert:GetTall())
    confirm:SetX(revert:GetX() + revert:GetWide() + border)
    confirm:SetText(esclib.addon:Translate("button_Confirm", try_language))
    confirm:SetIcon(esclib:GetMaterial("true.png"))
    confirm:SetIconColor(clr.button.apply)
    function confirm:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.apply_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)

		if hovered then pnl:SetTargetGradientColor(clr.button.apply_hover) end
    end
    function confirm:DoClick()
        textinput:OnEnter(textinput:GetText())
    end

    pnl:SetTall(tall)

    return textinput
end


function esclib:ConfirmWindow(title, text, callback)
	local clr = esclib.addon:GetColors()
	local font = esclib:AdaptiveFont("esclib", 20, 500)
	
	local pnl = self:GeneratePopWindow(false)
	pnl:SetTitle(title)
	pnl:SetSize(esclib:AdaptiveSize(500),esclib:AdaptiveSize(150))
	pnl:Center()
	pnl:SetRoundSize(8)
	pnl:SetGradientColor(clr.frame.bg)
	pnl:SetColorThink(true)
	pnl:SetAutoRestoreColor(true)
	local content = pnl:GetContent()
	local tall = 0
	local border = 8
	local answered = false

	function pnl:OnRemove()
		if not answered then callback(false) end
	end

	if text ~= "" then
		local multiline_data = esclib.text:Multiline(text, font, content:GetWide())
		local lbl = content:Add("DPanel")
		lbl:SetSize(content:GetWide(), multiline_data.height+border)
		function lbl:Paint(w,h)
			esclib.text:DrawMultiline(multiline_data, w * 0.5, border, clr.frame.text, TEXT_ALIGN_CENTER)
		end
		tall = tall + lbl:GetTall()
	end
	
	tall = tall + pnl.titlepanel:GetTall() + border*2

	local buttonlist = content:Add("DPanel")
	buttonlist:SetSize(content:GetWide(), content:GetTall()*0.4)
	buttonlist:Dock(BOTTOM)
	buttonlist:DockMargin(border,0,border,border)
	buttonlist.Paint = nil

	tall = tall + buttonlist:GetTall()

	local revert = buttonlist:Add("esclib.button")
	revert:SetText(esclib.addon:Translate("button_Discard"))
	revert:SetSize( buttonlist:GetWide()*0.5-border,buttonlist:GetTall() )
	revert:SetIcon(esclib:GetMaterial("cross.png"))
    revert:SetIconColor(clr.button.discard)
	revert:Dock(LEFT)
	revert:DockMargin(0,0,border,0)
	function revert:DoClick()
		answered = true
		callback(false)
		pnl:Close()
	end
	function revert:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.discard_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)

		if hovered then pnl:SetTargetGradientColor(clr.button.discard_hover) end
    end

	local confirm = buttonlist:Add("esclib.button")
	confirm:SetSize(revert:GetWide()-border,revert:GetTall())
	confirm:SetX(revert:GetX() + revert:GetWide())
	confirm:SetText(esclib.addon:Translate("button_Confirm"))
	confirm:SetIcon(esclib:GetMaterial("true.png"))
    confirm:SetIconColor(clr.button.apply)
	confirm:Dock(LEFT)
	function confirm:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.apply_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)

		if hovered then pnl:SetTargetGradientColor(clr.button.apply_hover) end
    end
	
	function confirm:DoClick()
		answered = true
		callback(true)
		pnl:Close()
	end

	pnl:SetTall(tall)
end

--sel_count - bool or number | if false then only 1 can be selected
--selected - already selected values or value
function esclib:ChoiceMenu(title,items,max_selections,item_paint,callback,custom_filter,need_search,selected_values, wide)
	local items_list
	if not istable(items) then 
		if isfunction(items) then
			items_list = items()
		end
	else
		items_list = items
	end

	if items_list then
		if not istable(items_list) then return end
	else
		return
	end

	local items_list = table.Copy(items)
	if table.IsEmpty(items_list) then callback() return end
	
	local clr = esclib.addon:GetColors()
	local ply = LocalPlayer()

	local pnl = self:GeneratePopWindow()
	pnl:SetSize(wide or esclib.scrw*0.4,esclib.scrh*0.9)
	local base_tall = pnl:GetTall()
	pnl:Center()
	pnl:SetRoundSize(16)
	local content = pnl:GetContent()

	local top_bar = content:Add("DPanel")
	if need_search ~= false then
		top_bar:SetSize(content:GetWide(),content:GetTall()*0.05)
		top_bar:SetY(10)
	else
		top_bar:SetHeight(0)
		top_bar:Hide()
	end

	local font_door = esclib:AdaptiveFont("esclib", 20, 500)
	local textinput = top_bar:Add("DTextEntry")
	local offset = esclib.util.GetTextSize(esclib.addon:Translate("phrase_Search"),font_door).w + 25
	textinput:SetSize(top_bar:GetWide()-offset-10,top_bar:GetTall())
	textinput:SetX(offset)
	textinput:CenterVertical(0.45)
	textinput:SetFont(font_door)
	textinput:SetTextColor(clr.frame.text)

	function textinput:OnGetFocus()
		pnl.bg:SetKeyboardInputEnabled(true)
	end

	function textinput:OnLoseFocus()
		pnl.bg:SetKeyboardInputEnabled(false)
	end


	function top_bar:Paint(w,h)
		draw.SimpleText(esclib.addon:Translate("phrase_Search")..":",font_door, 10, h*0.5-2,clr.frame.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	end

	function textinput:Paint(w,h)
		draw.RoundedBox(16,0,0,w,h,clr.frame.accent)

		local textcol = self:GetTextColor()
		self:DrawTextEntryText( textcol, clr.frame.text_hover, textcol )
	end

	local selected
	local max_values = 1

	if isnumber(max_selections) and max_selections ~= 1 then
		max_values = max_selections
		max_selections = true
	else
		max_selections = false
		max_values = 1
	end

	local border = 25
	local bot_bar = content:Add("DPanel")
	bot_bar:SetSize(content:GetWide(),content:GetTall()*0.07)
	bot_bar:Dock(BOTTOM)
	bot_bar:SetMouseInputEnabled(true)
	bot_bar:SetZPos(10)
	function bot_bar:Paint(w,h)
		draw.RoundedBoxEx(16,0,0,w,h,clr.frame.accent,false,false,true,true)
	end
	if not max_selections then
		bot_bar:Hide()
	end

	local scroll = content:Add("esclib.scrollpanel")
	if top_bar:IsVisible() then
		scroll:SetY(top_bar:GetY()+top_bar:GetTall()+5)
	end
	scroll:SetSize(content:GetWide(),content:GetTall()-top_bar:GetTall()-bot_bar:GetTall()-20)

	local list = scroll:Add("DIconLayout")
	list:SetBorder(5)
	list:SetWide(content:GetWide())
	list:SetStretchHeight(true)
	list:SetSpaceY(5)

	
	local cur_count = 0
	if max_selections then
		selected = istable(selected_values) and table.Copy(selected_values) or {}
		cur_count = table.Count(selected)
	else
		selected = selected_values and selected_values or nil
	end

	local function UpdateTitle()
		pnl:SetTitle(("(%d/%d) "):format(cur_count, max_values)..title)
	end
	UpdateTitle()


	function list:eClear()
		for k,v in ipairs(self:GetChildren()) do
			v:Remove()
		end
	end

    local revert = bot_bar:Add("esclib.button")
    revert:SetText(esclib.addon:Translate("button_Discard", try_language))
    revert:SetSize(bot_bar:GetWide() * 0.5 - border, bot_bar:GetTall()*0.6)
    revert:SetX(border * 0.5)
	revert:SetY(bot_bar:GetTall()*0.5 - revert:GetTall()*0.5)
    revert:SetIcon(esclib:GetMaterial("cross.png"))
    revert:SetIconColor(clr.button.discard)
    function revert:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.discard_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)
    end
    function revert:DoClick()
        callback()
		pnl:Close()
    end

    local confirm = bot_bar:Add("esclib.button")
    confirm:SetSize(revert:GetWide(), revert:GetTall())
    confirm:SetX(revert:GetX() + revert:GetWide() + border)
	confirm:SetY(bot_bar:GetTall()*0.5 - confirm:GetTall()*0.5)
    confirm:SetText(esclib.addon:Translate("button_Confirm", try_language))
    confirm:SetIcon(esclib:GetMaterial("true.png"))
    confirm:SetIconColor(clr.button.apply)
    function confirm:PaintBackground(w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, hovered and clr.button.apply_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)
    end
    function confirm:DoClick()
        if istable(selected) then
			if table.IsEmpty(selected) then
				selected = nil
			else
				selected = table.ClearKeys(selected)
			end
		end

		callback(selected)
		pnl:Close()
    end

	local function Update()
		local filter = string.lower(textinput:GetValue())


		local has_results = false
		for k,name in ipairs(items_list) do
			if custom_filter then
				if isfunction(custom_filter) then
					if not custom_filter(name,(filter or "")) then continue end
				end
			else
				if type(name) == "string" then
					if (not string.find(string.lower(name),filter)) then continue end
				end
			end

			local player_panel = list:Add("DButton")
			player_panel:SetSize(scroll:GetWide()-list:GetBorder()*2,scroll:GetTall()*0.07)
			player_panel:SetText("")

			local font = esclib:AdaptiveFont("esclib", 24, 500)
			function player_panel:Paint(w,h)
				local active
				if selected ~= nil and max_selections then 
					active = selected[name] 
				else
					active = (selected == name)
				end

				if item_paint then
					if isfunction(item_paint) then item_paint(self, w,h, name, active) end
				else
					local hovered = self:IsHovered()

					draw.RoundedBox(0,0,0,w,h,hovered and clr.button.hover or clr.button.main)
					if active then
						draw.RoundedBox(0,0,0,5,h,clr.button.apply)
					end

					draw.SimpleText(name,font,w*0.5,h*0.5,hovered and clr.button.text_hover or clr.button.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
			function player_panel:DoClick()
				if max_selections then
					if selected[name] then 
						selected[name] = nil
						cur_count = cur_count - 1
						UpdateTitle()
						return 
					end
					
					if cur_count < max_values then
						selected[name] = name
						cur_count = cur_count + 1
					end
				else
					selected = name
					cur_count = 1
					confirm:DoClick()
				end

				UpdateTitle()
			end
			has_results = true
		end

		local font = esclib:AdaptiveFont("esclib", 24, 500)
		if not has_results then
			local player_panel = list:Add("DPanel")
			player_panel:SetSize(scroll:GetWide(),scroll:GetTall()*0.07)
			player_panel:SetText("")

			function player_panel:Paint(w,h)
				-- draw.RoundedBox(0,0,0,w,h,clr.button.main)

				draw.SimpleText(esclib.addon:Translate("phrase_NoResults"),font,w*0.5,h*0.5,hovered and clr.button.text_hover or clr.button.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			return
		end

		timer.Simple(0, function()
			local tall = list:GetTall() + pnl.titlepanel:GetTall() + list:GetBorder()

			if textinput:IsVisible() then
				tall = tall + textinput:GetTall()
			end

			if top_bar:IsVisible() then
				tall = tall + top_bar:GetTall()
			end

			if bot_bar:IsVisible() then
				tall = tall + bot_bar:GetTall()
			end

			pnl:SetTall( math.min(tall, base_tall) )
			pnl:Center()
		end)

	end

	Update()

	function textinput:OnChange()
		list:eClear()
		Update()
	end

	return pnl
end

function esclib:PlayerSelectWindow(title,multi,hide_self,callback,custom_filter)
	local player_list = player.GetAll()
	table.sort(player_list, function(a,b) return a:Nick() < b:Nick() end)

	local filter_func = function(ply,filter)
		if not IsValid(ply) then return false end
		if hide_self then 
			if ply:Name() == LocalPlayer():Name() then return false end
		end

		local res = false

		if ply.Name then
			res = string.find(string.lower(ply:Name()),filter)
		else
			res = (filter == "")
		end

		if custom_filter then
			if isfunction(custom_filter) then
				if not custom_filter(ply) then res = false end
			end
		end

		return res
	end

	local font = esclib:AdaptiveFont("esclib", 24, 500)
	local player_paint = function(self,w,h,ply,active)
		local hovered = self:IsHovered()
		local clr = esclib.addon:GetColors()

		local hovered = self:IsHovered()
        draw.RoundedBox(8, 0, 0, w, h, (hovered or active) and clr.button.apply_hover or clr.button.hover)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.button.hover or clr.button.main)

		-- draw.RoundedBox(0,0,0,w,h,hovered and clr.button.hover or clr.button.main)
		-- if active then
		-- 	draw.RoundedBox(0,0,0,5,h,clr.button.apply)
		-- end

		draw.SimpleText(ply:Name(),font,15,h*0.5,hovered and clr.button.text_hover or clr.button.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		if DarkRP then
			local jobclr = team.GetColor(ply:Team()) or color_white
			draw.SimpleText(ply:getDarkRPVar("job"),font,w-15,h*0.5,jobclr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	local return_result = function(result)
		callback(result)
	end

	-- function esclib:ChoiceMenu(title,items,max_selections,item_paint,callback,custom_filter,need_search, selected_values)
	esclib:ChoiceMenu(title, player_list, multi, player_paint, return_result, filter_func, true)
end

--https://github.com/Be1zebub/Small-GLua-Things/blob/54ce959d8375c1c94d077f7ed1a94095b7ed62d0/ui_animations.lua
function esclib:NewAnimation(length, delay, ease, onend, think_fn)
    ease = ease or -1
    delay = delay or 0

    local systime = SysTime()
    local starttime, endtime = systime + delay, systime + delay + length
    local h_name = "esclib.animation."..starttime.."." ..endtime.."."..random(-1000,1000)
    local fraction, frac

    hook.Add("Think", h_name, function()
        systime = SysTime()
        if starttime > systime then return end

        fraction = clamp(TimeFraction(starttime, endtime, systime), 0, 1)

        if ease < 0 then
            frac = fraction ^ (1 - fraction - 0.5)
        elseif ease > 0 and ease < 1 then
            frac = 1 - (1 - fraction) ^ (1 / ease)
        end

        if fraction == 1 or think_fn(frac) then
            if onend then onend() end
            hook.Remove("Think", h_name)
        end
    end)
    
    return function()
		if onend then onend() end
    	hook.Remove("Think", h_name)
    end
end