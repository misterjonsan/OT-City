local max = math.max


local function tablesAreEqual(table1, table2)
	for k, v in pairs(table1) do
		if type(v) ~= type(table2[k]) then return false end
		if istable(v) and istable(table2[k]) then
			if not tablesAreEqual(v, table2[k]) then
				return false
			end
		elseif table2[k] ~= v then
			return false
		end
	end

	for k, _ in pairs(table2) do
		if table1[k] == nil then
			return false
		end
	end

	return true
end

-------------
--# PANEL #--
-------------
local settab = settab or nil
function esclib:closesettings()
	if IsValid(settab) then
		settab:Remove()
		return true
	end
	return false
end

function esclib:opensettings(naddon, skip_anim)
	esclib:closesettings()

	local skin = esclib.addon:GetCurrentSkin()
	local clr = skin.colors
	local scrw, scrh = esclib.scrw, esclib.scrh
	local addons = esclib:GetAddons() or {}
	local c_addonpnl = nil
	local c_themepanel = nil

	local needaddon
	local needrestart = false

	if naddon then
		if not isstring(naddon) then
			naddon = tostring(naddon)
		end
		naddon = string.lower(naddon)
		
		if esclib:GetAddons()[naddon] then
			needaddon = true
		end
	end

	settab = vgui.Create("EditablePanel")
	if not skip_anim then
		settab:SetAlpha(0)
		settab:AlphaTo(255,esclib.addon:GetVar("animtime") or 0.1)
	else
		settab:SetAlpha(255)
	end
	settab:SetSize(scrw,scrh)
	settab:SetText("")
	settab:MakePopup()
	settab:SetKeyBoardInputEnabled(false)
	local draw_blur = esclib.addon:GetVar("drawblur")

	local setbutton = settab:Add("DButton")
	setbutton:SetSize(scrw,scrh)
	setbutton:SetText("")
	setbutton.Paint = nil

	local version = string.format("%s v%s", esclib.addon:GetBranch() or "", esclib.addon:GetVersion() or "")
	local hash = esclib:GetServerHash()
	
	local font = esclib:AdaptiveFont("esclib", 20, 500)
	local font_h = draw.GetFontHeight(font)
	local gradient_text = esclib.draw:GradientText(esclib.addon:GetName(), esclib:AdaptiveFont("esclib", 24, 500), Color(111,255,27), Color(0,255,128))

	local icon = esclib:GetMaterial("cog.png")
	local icon_tall = gradient_text["info"]["text_h"] + draw.GetFontHeight(font) * 2 + 6

	local btn = settab:Add("esclib.button")
	btn:SetSize(icon_tall*0.8, icon_tall*0.8)
	btn:SetText("")
	btn:SetIcon(icon)
	btn:SetPos(
		settab:GetWide()-btn:GetWide()-10, 
		settab:GetTall()-icon_tall*0.5-btn:GetTall()*0.5-5
	)
	btn:SetMouseInputEnabled(true)
	btn:SetIconSize(1.5)
	btn:SetBackgroundColor(color_transparent)
	btn:SetBackgroundHoverColor(color_transparent)
	function btn:DoClick()
		esclib:closesettings()
		esclib:opensettings("esclib")
	end

	local offset_x = btn:GetWide()
	function settab:Paint(w,h)
		-- if draw_blur then
		-- 	esclib.draw:Blur(self,6)
		-- end

		-- draw.RoundedBox(0, 0, 0, w, h, clr.background.col)

		gradient_text:Draw(w-offset_x-20, h-font_h*2-10, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, true)
		draw.SimpleText(version, font, w-offset_x-20, h-font_h-10, clr.frame.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		draw.SimpleText("SVUID "..hash, font, w-offset_x-20, h-7, clr.frame.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
	end

	if esclib.addon:GetVar("debug") then

		local offset = 5

		local text = "DEV MODE"
		local font = esclib:AdaptiveFont("esclib", 18, 500)
		local textw, texth = esclib.util:TextSize(text, font)
		local dbg_btn = setbutton:Add("esclib.button")
		dbg_btn:SetSize(textw+20, texth+5)
		dbg_btn:SetPos(offset, 5)
		dbg_btn:SetButtonText(text)
		dbg_btn:SetFont(font)
		dbg_btn:SetMouseInputEnabled(false)
		offset = offset + textw+25


		local text = "Fonts"
		font = esclib:AdaptiveFont("esclib", 18, 500)
		textw, texth = esclib.util:TextSize(text, font)

		dbg_btn = setbutton:Add("esclib.button")
		dbg_btn:SetSize(textw+20, texth+5)
		dbg_btn:SetPos(offset, 5)
		dbg_btn:SetButtonText(text)
		dbg_btn:SetFont(font)
		function dbg_btn:DoClick()
			local fonts = table.GetKeys(esclib.fonts.list)
			local count = #fonts
			if count < 1 then return end
			table.sort(fonts, function(a, b) return a:upper() < b:upper() end)

			local pnl = esclib:GeneratePopWindow(false)
			pnl:SetSize(esclib.scrw*0.7,esclib.scrh*0.8)
			pnl:SetPos(esclib.scrw*0.5 - pnl:GetWide()*0.5, esclib.scrh*0.5 - pnl:GetTall()*0.5)

			pnl:SetTitle(text.." ("..count..")")
			local content = pnl:GetContent()
			content:InvalidateParent()
			local scroll = content:Add("esclib.scrollpanel")
			scroll:SetSize(content:GetWide(),content:GetTall())


			local list = scroll:Add("DIconLayout")
			list:SetY(5)
			list:SetSize(content:GetWide(),content:GetTall()-10)
			list:SetSpaceY(5)
			list:SetBorder(esclib:AdaptiveSize(30))

			local adafont = esclib:AdaptiveFont("esclib", 20, 500)
			for id,font in pairs(fonts) do
				local text = "Preview 12345"
				local textw,texth = esclib.util:TextSize(text,font)

				local font_pnl = list:Add("DPanel")
				function font_pnl:Paint(w,h)
					draw.RoundedBox(0,0,0,w,h,clr.frame.accent)
				
					draw.SimpleText(id..". ["..font.."]",adafont, 5, 5, clr.frame.text_gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end

				local textw2,texth2 = esclib.util:TextSize(id,adafont)
				font_pnl:SetSize(list:GetWide()-list:GetBorder()*2, max(texth+6,texth2+6)+20)

				local font_lbl = font_pnl:Add("DLabel")
				font_lbl:SetSize(font_pnl:GetWide()-15, font_pnl:GetTall())
				font_lbl:SetX(textw2+15)
				font_lbl:SetY(10)
				font_lbl:SetText(text)
				font_lbl:SetFont(font)
				font_lbl:SetColor(clr.frame.text_hover)
			end

		end
		offset = offset + textw+25
	end

	local main = vgui.Create("esclib.frame", settab)
	if needaddon then main:Hide() end
	main:SetSize(scrw*0.5,scrh*0.6)
	main:SetPos(scrw*0.5 - main:GetWide()*0.5, scrh*0.5 - main:GetTall()*0.5)
	main:SetIcon(esclib:GetMaterial("cog.png"))
	main:SetTitle(esclib.addon:Translate("tab_settings"))
	main:SetColorThink(true)
	main:SetAutoRestoreColor(true)
	function main:OnClose(callback)
		if IsValid(settab.c_themepanel) then settab.c_themepanel:Remove() end

		if IsValid(settab.c_addonpnl) then settab.c_addonpnl:Remove() end

		local animtime = esclib.addon:GetVar("animtime") or 0
		settab:AlphaTo(0,animtime,0,function()
			if callback then callback() end
			if IsValid(settab) then
				settab:Remove()
				return
			end
			if IsValid(main) then
				main:Remove()
			end
		end)
		gui.EnableScreenClicker(false)
	end
	function main:Close()
		self:OnClose()
		self:Remove()
	end

	local function settings_on_close_any(pnl)
		local animtime = skip_anim and 0 or (esclib.addon:GetVar("animtime") or 0)

		if IsValid(settab.c_themepanel) then
			if pnl ~= settab.c_themepanel then
				if settab.c_themepanel.OnClose then settab.c_themepanel:OnClose(self) end
			end
			settab.c_themepanel:AlphaTo(0,animtime,0,function()
				if IsValid(settab.c_themepanel) then settab.c_themepanel:Remove() end
			end)

			if IsValid(c_addonpnl) then
				c_addonpnl:Show()
				c_addonpnl:SetAlpha(0)
				c_addonpnl:AlphaTo(255,animtime)
			end
			return true
		end

		if IsValid(c_addonpnl) then
			if needaddon then
				main:Close()
				return
			end

			c_addonpnl:AlphaTo(0,animtime,0,function()
				c_addonpnl:Remove()
			end)
		end

		if not main:IsVisible() then
			main:Show()
			main:SetAlpha(0)
			main:AlphaTo(255,animtime)
		else
			main:Close()
		end

		return true
	end

	function setbutton:DoClick()
		if settings_on_close_any() then return end
		main:Close()
	end

	local content = main:GetContent()
	local scroll = content:Add("esclib.scrollpanel")
	scroll:SetSize(content:GetWide(),content:GetTall())

	local list = scroll:Add("DIconLayout")
	list:SetWide(content:GetWide())
	list:SetSpaceY(esclib:AdaptiveSize(10))
	list:SetSpaceX(list:GetSpaceY())
	list:SetBorder(esclib:AdaptiveSize(15))
	list:SetStretchHeight(true)

	local addon_list = {}
	for uid,addon in pairs(addons) do
		table.insert(addon_list, addon)
	end
	table.sort(addon_list, function(a,b)
		return a:GetSortOrder() < b:GetSortOrder()
	end)

	local total_height = 0
	for addon_num,add in ipairs(addon_list) do
		local uid = add.info.uid

		------------------
		--# ALL ADDONS #--
		------------------
		local name_font = esclib:AdaptiveFont("esclib", 24, 500)

		local addpan = list:Add("DButton")
		addpan:SetWide(content:GetWide()*0.25-list:GetBorder())
		addpan:SetTall(addpan:GetWide()+draw.GetFontHeight(name_font)+esclib:AdaptiveSize(20))
		addpan:SetText("")

		total_height = total_height + addpan:GetTall() + list:GetSpaceY()

		local drawicon = false
		if type((add.info.thumbnail or "")) == "IMaterial" then
			drawicon = true
		end

		local version = string.format("%s v%s", add:GetBranch() or "", add:GetVersion() or "")
		local version_wide, version_height = esclib.util:TextSize(version, esclib:AdaptiveFont("esclib", 16, 500))

		local font = esclib:AdaptiveFont("esclib", 16, 500)
		function addpan:Paint(w,h)
			local hovered = self:IsHovered()
			draw.RoundedBox(8, 0, 0, w, h, hovered and add.info.color or clr.button.hover)
			draw.RoundedBox(6, 2, 2, w - 4, h - 4, hovered and clr.frame.bg or clr.button.main)

			--version
			draw.SimpleText(version, font, w-version_wide-15, 10, clr.frame.text)

			if hovered then
				local aclr = table.Copy(add.info.color)
				aclr.a = 50
				main:SetTargetGradientColor(aclr)
			end
		end

		local icon_pnl = addpan:Add("DPanel")
		icon_pnl:Dock(TOP)
		local margin = esclib:AdaptiveSize(5)
		icon_pnl:SetTall(addpan:GetWide()-margin*2)
		icon_pnl:DockMargin(margin,margin,margin,margin)
		icon_pnl:SetMouseInputEnabled(false)
		local poly = nil
		function icon_pnl:Paint(w,h)
			esclib.draw:Mask(function() --draw poly
				if not poly then
					poly = esclib.util:PrecacheRoundedPoly(0, 0, w, h, 6, 3)
				end
				draw.NoTexture();
				surface.SetDrawColor( color_white )
				surface.DrawPoly( poly )
			end, 
			function() --draw main
				if drawicon then
					esclib.draw:Material(0,0,w,w,clr.default.white , add.info.thumbnail)
				else
					draw.RoundedBox(0,0,0, w, w, clr.frame.text)
				end
			end,false)

			esclib.draw:ShadowText(version, font, w-version_wide-15, 10, clr.default.white)
		end

		local info_pnl = addpan:Add("DPanel")
		info_pnl:Dock(FILL)
		info_pnl:SetMouseInputEnabled(false)
		function info_pnl:Paint(w,h)
			draw.SimpleText(add.info.name, name_font, w*0.5-2, h*0.5-3, clr.frame.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		-------------------
		--# EDIT ADDONS #--
		-------------------
		-- removed: cur_realm, cur_sub_realm, tabnames (handled by panel)
		local function open_addon_edit()
			main:Hide()

			if IsValid(c_addonpnl) then c_addonpnl:Remove() end
			c_addonpnl = vgui.Create("esclib.addon_settings_panel",settab)
			settab.c_addonpnl = c_addonpnl
			c_addonpnl:SetPos(scrw*0.5 - c_addonpnl:GetWide()*0.5, scrh*0.5 - c_addonpnl:GetTall()*0.5)
			if c_addonpnl.SetCloseHandler then
				c_addonpnl:SetCloseHandler(function(pnl)
					settings_on_close_any(pnl)
				end)
			end
			c_addonpnl:Setup(add, addon_list, settab)
		end

		if needaddon then
			if uid == naddon then
				open_addon_edit()
			end
		end

		function addpan:DoClick()
			open_addon_edit()
		end
	end
end

concommand.Add("esettings",function(ply,cmd,args)
	if table.IsEmpty(args) then
		esclib:opensettings()
		return
	end

	esclib:opensettings(args[1])
end)

hook.Add("OnPlayerChat","esclib.hook.open_settings",function(ply,text,isteam,isplydead)
	if ply ~= LocalPlayer() then return end
	if text == "!esettings" then
		RunConsoleCommand("esettings")
		return true
	end
end)