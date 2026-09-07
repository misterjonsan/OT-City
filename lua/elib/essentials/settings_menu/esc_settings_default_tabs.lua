--esclib.settings_shared_funcs.draw_bg(w,h,hovered,clr, is_changed)
local draw_bg = esclib.settings_shared_funcs.draw_bg

esclib.default_settings_tabs = esclib.default_settings_tabs or {}

-----------------
--# FUNCTIONS #--
-----------------
--Add tab to all addons settings
--func parameters: addon, background_panel, combo_panel, callback
local allowed_realms = {
	["realm_Client"] = true,
	["realm_Server"] = true
}

function esclib:AddDefaultTab(uid, realm, sort_order,func)
	if not allowed_realms[realm] then
		error("Invalid realm (Must be realm_Client or realm_Server)")
	end
	local func = func or sort_order

	self.default_settings_tabs[uid] = {
		name = uid,
		realm = realm,
		func = func,
		sortOrder = sort_order,
	}
end

function esclib:RemoveDefaultTab(uid)
	self.default_settings_tabs[uid] = nil
end

function esclib:GetAllDefaultTabs()
	return self.default_settings_tabs
end

--------------------
--# LANGUAGE TAB #--
--------------------
esclib:AddDefaultTab("lang_tab", "realm_Client", 100, function(add, settab, combolist, callback)

	local clr = esclib.addon:GetColors()
	local addon_language = add:GetLanguage()

	local tabname_translated = esclib.addon:Translate("tab_language",add:GetLanguage())
	if not table.IsEmpty(add:GetLanguages()) then
		combolist:AddTab(tabname_translated,function(tab_content)

			local scroll = tab_content:Add("esclib.scrollpanel")
			scroll:SetSize(tab_content:GetWide(),tab_content:GetTall())

			local list = scroll:Add("DIconLayout")
			list:SetSize(tab_content:GetWide(),tab_content:GetTall())
			list:SetBorder(esclib:AdaptiveSize(15))
			list:SetSpaceY(5)
			list:SetSpaceX(5)

			local langs = add:GetLanguages()

			local button_wide = list:GetWide()*0.332-list:GetBorder()
			local button_tall = list:GetTall()*0.08
			local half_tall = button_tall * 0.5

			local icon_w = 24
			local icon_h = 16

			local true_mat = esclib:GetMaterial("true.png")
			local box_mat = esclib:GetMaterial("box.png")
			local offset = 0
			for _,lang in ipairs(table.GetKeys(add:GetLanguages())) do
				local lbutton = list:Add("DButton")
				lbutton:SetSize(button_wide,button_tall)
				lbutton:SetText("")
				local lang_name = langs[lang]["__name__"] or esclib.text:Capitalize(lang)
				local lang_code = langs[lang]["__code__"] or ""
				local lang_icon = Material("materials/flags16/"..lang_code..".png")
				local has_mat = not lang_icon:IsError()

				if has_mat then
					offset = icon_w+10
				end
				local font = esclib:AdaptiveFont("esclib", 24, 500)
				function lbutton:Paint(w,h)
					local hovered = self:IsHovered()
					local selected = add.info.language == lang
					local changed = (not selected and addon_language == lang)
					draw_bg(w,h,hovered,clr, changed)
					draw.SimpleText( lang_name.." ["..lang_code.."]",font,15+offset,h*0.5,selected and clr.button.accent or clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

					local checkbox_size = h*0.25
					esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size, hovered and clr.button.main or clr.button.hover , box_mat)
					if selected and addon_language == lang then
						esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size*0.6, clr.button.accent, true_mat)
					end

					if has_mat then
						esclib.draw:Material(15,half_tall-icon_h*0.5,icon_w,icon_h,clr.default.white, lang_icon)
					end

					if changed then
						esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size*0.6, clr.button.accent, true_mat)
					end
				end

				function lbutton:DoClick()
					addon_language = lang
					-- if add.info.language ~= addon_language then
					-- 	settings_changed = true
					-- end
					callback("language",addon_language)
				end

			end

			return scroll

		end)
	end

end)


-----------------
--# SKINS TAB #--
-----------------
esclib:AddDefaultTab("skin_tab", "realm_Client", 101, function(add, settab, combolist, callback)

	local addon_active_skin = add.info.active_skin
	local addon_custom_skin = table.Copy(add:GetSkinByName("skin_custom"))
	local clr = esclib.addon:GetColors()
	local tabname_translated = esclib.addon:Translate("tab_theme",add:GetLanguage())

	local function save_skin()
		add.data.skins["skin_custom"] = table.Copy(addon_custom_skin)
		add:SaveCustomSkin()
		if add.info.active_skin == "skin_custom" then
			hook.Run(add.info.uid.."_skin_changed","skin_custom")
		end
		if IsValid(settab.c_themepanel) then
			settab.c_themepanel:Close()
		end
	end

	combolist:AddTab(tabname_translated,function(tab_content)

		local scroll = tab_content:Add("esclib.scrollpanel")
		scroll:SetSize(tab_content:GetWide(),tab_content:GetTall())

		local list = scroll:Add("DIconLayout")
		list:SetSize(tab_content:GetWide(),tab_content:GetTall())
		list:SetBorder(esclib:AdaptiveSize(15))
		list:SetSpaceY(5)
		list:SetSpaceX(5)

		local button_wide = list:GetWide()*0.332-list:GetBorder()
		local button_tall = list:GetTall()*0.08

		local true_mat = esclib:GetMaterial("true.png")
		local box_mat = esclib:GetMaterial("box.png")

		for name,skin in pairs(add.data.skins) do
			if name == "skin_custom" then continue end

			local lbutton = list:Add("DButton")
			lbutton:SetSize(button_wide,button_tall)
			lbutton:SetText("")

			local skin_color = skin.color or Color(100,100,100)
			local font = esclib:AdaptiveFont("esclib", 24, 500)
			function lbutton:Paint(w,h)
				local hovered = self:IsHovered()
				local selected = add.info.active_skin == name
				local changed = (not selected and addon_active_skin == name)
				draw_bg(w,h,hovered,clr, changed)
				draw.SimpleText(skin.name or name,font,50,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

				draw.RoundedBox(8,10,h*0.5-h*0.25,h*0.5,h*0.5,clr.default.black)
				draw.RoundedBox(8,8,h*0.5-h*0.25,h*0.5,h*0.5,skin_color)

				local checkbox_size = h*0.25
				esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size, hovered and clr.button.main or clr.button.hover , box_mat)
				if addon_active_skin == name then
					esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size*0.6, clr.button.accent, true_mat)
				end
			end

			function lbutton:DoClick()
				if addon_active_skin == name then return end
				addon_active_skin = name

				callback("skin",addon_active_skin)

				-- settings_changed = true
			end

			function lbutton:DoRightClick()
				local context = settab:Add("esclib.contextmenu")
				context:SetPosClamped(gui.MouseX()+5,gui.MouseY()+5)

				context:AddHeader(skin.name)

				if add.info.active_skin ~= name then
					context:AddButton(esclib.addon:Translate("phrase_Activate", add:GetLanguage()),function()
						addon_active_skin = name
						callback("skin",addon_active_skin)
						-- save_settings()
					end, esclib:GetMaterial("power.png"))
				end

				context:AddButton(esclib.addon:Translate("button_PrintToConsole", add:GetLanguage()),function()
					add:PrintSkin(name)
				end)
			end
		end

		-----------------------
		--# CUSTOM SKIN TAB #--
		-----------------------
		local ug = LocalPlayer():GetUserGroup() or ""
		local allowed_ug = {
			["superadmin"] = true,
		}
		if not allowed_ug[ug] then return end

		local font = esclib:AdaptiveFont("esclib", 24, 500)
		local lbutton = list:Add("DButton")
		lbutton:SetSize(button_wide,button_tall)
		lbutton:SetText("")
		lbutton:eAddHint(esclib.addon:Translate("hint_CustomSkin", add:GetLanguage()),font,TEXT_ALIGN_CENTER,settab)

		local custom_name = esclib.addon:Translate("phrase_CustomSkin", add:GetLanguage())
		local name = "skin_custom"
		function lbutton:Paint(w,h)
			local hovered = self:IsHovered()
			local selected = add.info.active_skin == name
			local changed = (not selected and addon_active_skin == name)

			draw_bg(w,h,hovered,clr, changed)
			draw.SimpleText(custom_name,font,h*0.35+35,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

			esclib.draw:MaterialCentered(h*0.35+10,h*0.5,h*0.35,clr.button.text,esclib:GetMaterial("cog.png"))

			local checkbox_size = h*0.25
			esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size, hovered and clr.button.main or clr.button.hover , box_mat)
			if addon_active_skin == name then
				esclib.draw:MaterialCentered(w-checkbox_size-15, h*0.5, checkbox_size*0.6, clr.button.accent, true_mat)
			end
		end

		function lbutton:DoRightClick()
			local mx,my = gui.MouseX(), gui.MouseY()

			local context = settab:Add("esclib.contextmenu")
			context:SetPosClamped(mx+5,my+5)

			context:AddHeader(custom_name)

			if (add.info.active_skin ~= "skin_custom") then
				context:AddButton(esclib.addon:Translate("phrase_Activate", add:GetLanguage()),function()
					addon_active_skin = "skin_custom"
					callback("skin",addon_active_skin)
				end, esclib:GetMaterial("power.png"))
			end

			context:AddButton(esclib.addon:Translate("button_Edit", add:GetLanguage()),function()
				local function GenerateThemeEditPanel(bg,saved)
					if not addon_custom_skin then
						return 
					end

					local skin = esclib.addon:GetCurrentSkin()
					local clr = skin.colors
					local unsaved = saved

					local pnl = bg:Add("esclib.frame")
					pnl:SetSize(bg:GetWide()*0.7,bg:GetTall()*0.9)
					pnl:Center()
					pnl:SetTitle(custom_name)
					pnl:SetIcon(esclib:GetMaterial("cog.png"))
					settab:SetKeyBoardInputEnabled(true)

					function pnl:OnClose()
						callback("custom_skin",self)
					end
					local content = pnl:GetContent()


					local dobar_size = content:GetTall()*0.07
					local dobar = content:Add("DPanel")
					dobar:SetSize(content:GetWide(),dobar_size)
					dobar:SetY(content:GetTall()-dobar:GetTall())

					local phrase_unsaved = esclib.addon:Translate("phrase_Unsaved", add:GetLanguage())
					function dobar:Paint(w,h)
						draw.RoundedBoxEx(skin.roundsize, 0,0,w,h, clr.frame.accent,false,false,true,true)
					end

					local titlepnl = pnl:GetTitlePanel()
					local font = esclib:AdaptiveFont("esclib", 22, 500)
					function titlepnl:PaintOver(w,h)
						if unsaved then
							draw.SimpleText(phrase_unsaved.."!", font, w-35, h*0.5, clr.default.red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
						end
					end

					local scroll = content:Add("esclib.scrollpanel", add:GetLanguage())
					scroll:SetSize(content:GetWide(),content:GetTall()-dobar_size)

					local list = scroll:Add("DIconLayout")
					list:SetSize(tab_content:GetWide(),tab_content:GetTall())
					list:SetBorder(esclib:AdaptiveSize(15))
					list:SetSpaceY(5)
					list:SetSpaceX(10)

					local button_sizex = list:GetWide()*0.33-list:GetBorder()-2
					local button_sizey = list:GetTall()*0.08

					for color_tab_name, tab_colors in pairs(addon_custom_skin.colors) do
						if color_tab_name == "default" then continue end

						local color_tab = list:Add("DPanel")
						color_tab:SetSize(list:GetWide()-list:GetBorder()*2,list:GetTall()*0.07)
						local font_30 = esclib:AdaptiveFont("esclib", 28, 500)
						local font_24 = esclib:AdaptiveFont("esclib", 20, 500) --haha
						local font_16 = esclib:AdaptiveFont("esclib", 16, 500)
						local texts = esclib.util.GetTextSize(esclib.text:Capitalize(color_tab_name),font_30)
						function color_tab:Paint(w,h)
							draw.SimpleText(esclib.text:Capitalize(color_tab_name),font_30,15,h*0.5,clr.frame.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
							draw.RoundedBox(0, texts.w + 30, h*0.5-2,w-texts.w-45,4,clr.button.hover)
						end

						for color_name, color in pairs(tab_colors) do
							local color_panel = list:Add("esclib.button")
							color_panel:SetSize(button_sizex,button_sizey)
							color_panel:SetBorderRadius(16)
							color_panel:SetButtonText(color_name)

							local clblack = Color(13,13,13)
							local nalpha = color.a < 255
							function color_panel:Paint(w,h)
								local hovered = self:IsHovered()
								-- draw.RoundedBox(self:GetBorderRadius(),0,0,w,h,hovered and clr.button.hover or clr.button.main)
								draw_bg(w,h,hovered,clr)
								draw.SimpleText(color_name, font_24, 15, h*0.5, hovered and clr.button.text_hover or clr.button.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

								esclib.draw:ShadowText(""..color.r.." "..color.g.." "..color.b..(nalpha and (" "..color.a) or "").."", font_16, w-60, h*0.5, clr.button.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER,1)

								if not nalpha then draw.RoundedBox(16,w-43,h*0.5-h*0.25,h*0.5,h*0.5, color) end
								draw.RoundedBox(8,w-45,h*0.5-h*0.25,h*0.5,h*0.5, color)
							end

							function color_panel:DoClick()
								local cbg = esclib:GenerateBGClicker(true)
								-- cbg.Paint = nil

								local x,y = self:LocalToScreen(0,0)

								local change_panel = cbg:Add("DPanel")
								change_panel:SetSize(self:GetWide(),tab_content:GetTall()*0.4)
								change_panel:SetPos(math.Clamp(x, 0, esclib.scrw - change_panel:GetWide()),  math.Clamp(y+self:GetTall()+5, 0, esclib.scrh - change_panel:GetTall()))

								local close_btn = change_panel:Add("esclib.button")
								close_btn:SetSize(20,20)
								close_btn:SetFont("Marlett")
								close_btn:SetButtonText("r")
								close_btn:SetPos(change_panel:GetWide()-close_btn:GetWide()-2,2)
								function close_btn:Paint(w,h)
									local hovered = self:IsHovered()
									draw.SimpleText(self:GetButtonText(),self:GetFont(), w*0.5, h*0.5, hovered and clr.button.discard or clr.frame.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
								end
								function close_btn:DoClick()
									cbg:Close()
								end

								local colorpicker = change_panel:Add("esclib.colorpicker")
								colorpicker:SetPos(10,10)
								colorpicker:SetColor(table.Copy(color))
								colorpicker:Dock(FILL)

								local accept_btn = change_panel:Add("esclib.button")
								accept_btn:SetSize(change_panel:GetWide()*0.12,change_panel:GetTall()*0.1)
								accept_btn:SetFont(esclib:AdaptiveFont("esclib", 16, 500))
								accept_btn:SetButtonText(esclib.addon:Translate("phrase_Save", add:GetLanguage()), addon_lang)
								accept_btn:SetPos(change_panel:GetWide()-accept_btn:GetWide()-5,change_panel:GetTall()-accept_btn:GetTall()-26)
								accept_btn:SetZPos(1)
								function accept_btn:Paint(w,h)
									local hovered = self:IsHovered()

									draw.RoundedBox(8,0,0,w,h,hovered and clr.button.accent_hover or clr.button.accent)

									esclib.draw:ShadowText(self:GetButtonText(),self:GetFont(), w*0.5, h*0.5, clr.default.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
								end
								function accept_btn:DoClick()
									unsaved = true
									local newclr = table.Copy(colorpicker:GetColor())
									color = newclr
									addon_custom_skin.colors[color_tab_name][color_name] = newclr

									cbg:Close()
								end

								local matGrid = Material( "gui/alpha_grid.png", "nocull" )
								local clwhite = Color(255,255,255)
								function change_panel:Paint(w,h)
									esclib.draw:Material(0,0,w*0.5,h,clwhite,matGrid)
									esclib.draw:Material(w*0.5,0,w*0.5,h,clwhite,matGrid)
									local clr = colorpicker:GetColor()

									draw.RoundedBox(0,0,0,w,h*0.5,clr)
									local clr_copy = table.Copy(clr)
									clr_copy.a = 255
									draw.RoundedBox(0,0,h*0.5,w,h*0.5+2,clr_copy)
								end

								
							end
						end
					end


					local back_button = dobar:Add("esclib.button")
					back_button:SetSize(dobar:GetTall(),dobar:GetTall())
					back_button:SetX(dobar:GetWide()*0.5-back_button:GetWide()-5)
					back_button:SetButtonText(esclib.addon:Translate("phrase_ReturnDefault", add:GetLanguage()))
					back_button:SetBorderRadius(16)
					back_button:eAddHint(back_button:GetButtonText(),esclib:AdaptiveFont("esclib", 24, 500),TEXT_ALIGN_CENTER,settab)

					function back_button:Paint(w,h)
						local hovered = self:IsHovered()
						esclib.draw:MaterialCentered(w*0.5,h*0.5,h*0.3,hovered and clr.button.discard_hover or clr.button.discard, esclib:GetMaterial("revert.png"))
					end

					function back_button:DoClick()
						esclib:ConfirmWindow(esclib.addon:Translate("phrase_AreYouSure", add:GetLanguage()),esclib.addon:Translate("phrase_SureToReturn", add:GetLanguage()),function(res)
							if res then
								add:ReturnCustomSkinToDefault()
								if add.info.active_skin == "skin_custom" then
									settab:Remove()
								else
									settab.c_themepanel:Close()
								end
							end
						end)
					end

					local apply_button = dobar:Add("esclib.button")
					local font = esclib:AdaptiveFont("esclib", 24, 500)
					local text = esclib.addon:Translate("phrase_Save", add:GetLanguage())
					apply_button:SetSize(dobar:GetTall(),dobar:GetTall())
					apply_button:SetX(dobar:GetWide()*0.5+5)
					apply_button:SetButtonText(text)
					apply_button:SetBorderRadius(16)
					apply_button:eAddHint(text,font,TEXT_ALIGN_CENTER,settab)

					function apply_button:Paint(w,h)
						local hovered = self:IsHovered()
						esclib.draw:MaterialCentered(w*0.5,h*0.5,h*0.3,hovered and clr.button.accent_hover or clr.button.accent, esclib:GetMaterial("save.png"))
					end

					function apply_button:DoClick()
						unsaved = false
						save_skin()
					end

					local copy_button = dobar:Add("esclib.button")
					copy_button:SetSize(dobar:GetWide()*0.27,dobar:GetTall()*0.7)
					copy_button:SetPos(dobar:GetWide() - copy_button:GetWide() - 15, dobar:GetTall()*0.5 - copy_button:GetTall()*0.5)
					copy_button:SetBorderRadius(16)
					copy_button:SetFont(esclib:AdaptiveFont("esclib", 20, 500))
					copy_button:SetButtonText(esclib.addon:Translate("button_LoadOtherSkin", add:GetLanguage()))

					function copy_button:DoClick()
						local cbg = esclib:GenerateBGClicker()

						local pnl = cbg:Add("esclib.frame")
						pnl:SetSize(esclib.scrw*0.5,esclib.scrh*0.5)
						pnl:Center()
						pnl:SetTitle(esclib.addon:Translate("button_LoadOtherSkin", add:GetLanguage()))
						local content = pnl:GetContent()

						local scroll = content:Add("esclib.scrollpanel")
						scroll:SetSize(content:GetWide(),content:GetTall())

						local list = scroll:Add("DIconLayout")
						list:SetSize(scroll:GetWide(),scroll:GetTall())
						list:SetBorder(10)
						list:SetSpaceY(5)
						list:SetSpaceX(10)

						local font = esclib:AdaptiveFont("esclib", 24, 500)
						for name,skin in pairs(add.data.skins) do
							if (name == "skin_custom") then continue end

							local btn = list:Add("esclib.button")
							btn:SetSize(list:GetWide()*0.5-list:GetBorder()*2,50)
							function btn:Paint(w,h)
								local hovered = self:IsHovered()
								draw.RoundedBox(0,0,0,w,h,hovered and clr.button.hover or clr.button.main)
								draw.SimpleText(skin.name or name,font,50,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

								draw.RoundedBox(8,10,h*0.5-15,30,30,skin.color or clr.default.white)
							end
							function btn:DoClick()
								addon_custom_skin = table.Copy(skin)

								unsaved = true
								cbg:AlphaTo(0,esclib.addon:GetVar("animtime"),0,function()
									cbg:Remove()
									if IsValid(settab.c_themepanel) then settab.c_themepanel:Remove() end
									settab.c_themepanel = GenerateThemeEditPanel(settab,true)
									function settab.c_themepanel:OnClose(pnl,unsaved)
										settab:SetKeyBoardInputEnabled(false)
										callback("custom_skin",settab.c_themepanel)
										-- settings_on_close_any(self)
									end
								end)
							end
						end
					end

					local print_button = dobar:Add("esclib.button")
					print_button:SetSize(dobar:GetWide()*0.27,dobar:GetTall()*0.7)
					print_button:SetPos(15, dobar:GetTall()*0.5 - print_button:GetTall()*0.5)
					print_button:SetBorderRadius(16)
					print_button:SetFont(esclib:AdaptiveFont("esclib", 20, 500))
					print_button:SetButtonText(esclib.addon:Translate("button_PrintToConsole", add:GetLanguage()))

					function print_button:DoClick()
						add:PrintSkin("skin_custom")
					end

					return pnl
				end

				addon_custom_skin = table.Copy(add:GetSkinByName("skin_custom"))
				settab.c_themepanel = GenerateThemeEditPanel(settab)
				local c_themepanel = settab.c_themepanel

				-- callback("custom_skin",settab.c_themepanel)

				function c_themepanel:OnClose(pnl)
					settab:SetKeyBoardInputEnabled(false)
					callback("custom_skin",settab.c_themepanel)
					-- settings_on_close_any(self)
				end

				if IsValid(settab.c_themepanel) and IsValid(settab.c_addonpnl) then
					settab.c_addonpnl:SetAlpha(255)
					settab.c_addonpnl:AlphaTo(0,esclib.addon:GetVar("animtime"),0,function()
						if IsValid(settab.c_addonpnl) then settab.c_addonpnl:Hide() end
					end)
				end
			end, esclib:GetMaterial("wrench.png"))

			context:AddButton(esclib.addon:Translate("phrase_ReturnDefault", add:GetLanguage()),function()
				esclib:ConfirmWindow(esclib.addon:Translate("phrase_AreYouSure"),esclib.addon:Translate("phrase_SureToReturn", add:GetLanguage()),function(res)
					if res then
						add:ReturnCustomSkinToDefault()
						if add.info.active_skin == "skin_custom" then
							settab:Remove()
						end
					end
				end)
			end)

			context:AddButton(esclib.addon:Translate("button_PrintToConsole", add:GetLanguage()),function()
				add:PrintSkin("skin_custom")
			end)

		end

		function lbutton:DoClick()
			if addon_active_skin == "skin_custom" then 
				self:DoRightClick()
				return 
			end
			addon_active_skin = "skin_custom"

			callback("skin",addon_active_skin)
		end

		return scroll

	end)
end)