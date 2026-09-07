if CLIENT then

	echat.addon:AddSettingsTab("parsers_examples", "realm_Client", 10, function(addon, settab, combolist, callback)
	local clr = esclib.addon:GetColors()
	combolist:AddTab( echat.addon:Translate("s_tab_parser_examples"), function(tab_content)

		local scroll = tab_content:Add("esclib.scrollpanel")
		scroll:SetScrollSpeed(15)
		
		local parsers = echat:GetParsers()

		local pnl = scroll:Add("DIconLayout")
		pnl:SetSize(tab_content:GetWide(),tab_content:GetTall())
		local w,h = pnl:GetWide(), pnl:GetTall()

		pnl:SetBorder(w*0.01)
		w = w - pnl:GetBorder()*2

		pnl:SetSpaceY(h*0.02)

		scroll:SetSize(tab_content:GetWide(),tab_content:GetTall()-pnl:GetBorder())

		for name,parser in pairs(parsers) do
			local example = parser.example or parser.uid
			if istable(example) and table.IsSequential(example) then
				example = example[1] or parser.uid
			end
			example = "<"..example.."> Hello world!"

			local parser_pnl = pnl:Add("DPanel")
			function parser_pnl:Paint(w,h)
				draw.RoundedBox(16,0,0,w,h, clr.frame.accent)
				draw.RoundedBox(14,2,2,w-4,h-4, clr.frame.bg)
			end

			local richtext = parser_pnl:Add("echat.richtext")
			richtext:Dock(FILL)
			local mx, my, mw, mh = w*0.015,h*0.03,w*0.015,h*0.03
			richtext:DockMargin(mx,my,mw,mh)

			richtext:SetW(pnl:GetWide())
			richtext:SetHeight(parser_pnl:GetTall())
			richtext:SetVerticalScrollbarEnabled(false)
			richtext:SetMouseInputEnabled(false)

			richtext:InsertColorChange(clr.button.apply.r, clr.button.apply.g, clr.button.apply.b)
			richtext:InsertFontChange(echat:AdaptiveMonoFont("echatmono", 30, 500)) --no need to be adapted
			richtext:AppendText(parser.uid.."\n")

			richtext:InsertFontChange(echat:AdaptiveFont("echat", 16, 500))
			richtext:InsertColorChange(clr.frame.text_gray.r, clr.frame.text_gray.g, clr.frame.text_gray.b)
			richtext:AppendText(parser.description)

			richtext:AppendEmptyLine(12)

			richtext:InsertColorChange(clr.frame.text.r, clr.frame.text.g, clr.frame.text.b)
			richtext:InsertFontChange(echat:AdaptiveFont("echat", 20, 500))
			richtext:AppendText(example)
			richtext:InsertColorChange(clr.button.apply.r, clr.button.apply.g, clr.button.apply.b)
			richtext:AppendText(" -> ")
			richtext:InsertColorChange(clr.frame.text.r, clr.frame.text.g, clr.frame.text.b)
			echat:ConvertParsedToRichtext(richtext, echat:ParseText(example.." "))

			local tall = richtext:GetCanvas():CalculateMaxTall()+my+mh
			parser_pnl:SetSize(w, tall)
		end

		

		return scroll
	end)
end)

end