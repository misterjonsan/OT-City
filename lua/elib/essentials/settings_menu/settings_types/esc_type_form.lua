local draw_bg = esclib.settings_shared_funcs.draw_bg
local VarsIsEqual = esclib.settings_shared_funcs.VarsIsEqual
local SharedDoRightClick = esclib.settings_shared_funcs.SharedDoRightClick

------------
--# FORM #--
------------
local stype = esclib:RegisterSettingsType("form")
stype.form_data = {}
stype:Require("FormFields")
stype:Require("value")
stype:SoftRequire("HintTranslateKey")
function stype:Build( parent )
	local addon     = parent.addon
	local varid     = parent.var_uid
	local varc      = parent.var
	local callback  = parent.ApplyValue
	local varc_copy = parent.initial_values
	local settab    = parent.bg
	local listing   = parent.parent
	local def_val   = parent.default_value or {}

	local button_wide = parent:GetWide()
	local button_tall = parent:GetTall()

	local clr = esclib.addon:GetColors()
	local font = esclib:AdaptiveFont("esclib", 22, 500)
	local font2 = esclib:AdaptiveFont("esclib", 16, 500)
	local name_tr  = varc.name or addon:Translate(varc.name_tr)
	local desc = varc.desc or addon:Translate(varc.desc_tr)

	local name = esclib.util:TextCutAccurate(name_tr, font, button_wide-15-90, "...")

	local form_data = table.Copy(varc.FormFields)

	local shadow_bg = Color(0,0,0, 200)
	local mat = esclib:GetMaterial("cross.png")
	local x,y = 0,0
	for sub_name,subvar in pairs(varc.value) do
		local var_pnl = listing:Add("DButton")
		var_pnl:SetSize(button_wide, button_tall)
		var_pnl:SetText("")
		var_pnl.DoRightClick = function(self) 
			local context = SharedDoRightClick(self, settab, name_tr, addon, varid, varc.value[sub_name], nil, callback)

			local set_default = esclib.addon:Translate("phrase_ReturnDefault", addon:GetLanguage())
			context:AddButton(set_default, function()
				esclib:SafeMerge(varc.value[sub_name] or {}, def_val[sub_name] or {}, true)
				callback(varid,varc.value)
			end, esclib:GetMaterial("revert.png"))
		end

		local remove_btn = var_pnl:Add("DButton")
		remove_btn:SetText("")
		remove_btn:SetSize(var_pnl:GetTall()*0.8, var_pnl:GetTall())
		remove_btn:SetPos(var_pnl:GetWide()-remove_btn:GetWide(), var_pnl:GetTall()*0.5 - remove_btn:GetTall()*0.5)
		function remove_btn:Paint(w,h)
			local hovered = self:IsHovered()

			esclib.draw:MaterialCentered(w*0.5, h*0.5, h*0.15, hovered and clr.button.discard or clr.button.text, mat)
		end

		function remove_btn:DoClick()
			esclib:ConfirmWindow("", esclib.addon:Translate("phrase_AreYouSure", addon:GetLanguage()),function(res)
				if res then
					varc.value[sub_name] = nil
					callback()
					parent:SaveAll()
				end
			end)
		end

		function var_pnl:DoClick()
			local pnl = esclib:GeneratePopWindow()
			pnl:SetTitle(sub_name)
			pnl:SetSize(button_wide,esclib.scrh*0.7)
			pnl:SetRoundSize(8)
			pnl:SetIcon(esclib:GetMaterial("cog.png"))
			
			function pnl:OnEndDragging()
				x,y = self:GetPos()
			end

			local content = pnl:GetContent()

			local function own_build()
				content:Clear()
			
				local plist = content:Add("esclib.scrollpanel")
				plist:Dock(FILL)
				plist:InvalidateParent(true)
				plist:Clear()

				local layout = plist:Add("DIconLayout")
				-- layout:SetSize(plist:GetWide(), plist:GetTall())
				layout:SetWide(plist:GetWide())
				layout:SetBorder(5)
				layout:SetSpaceY(5)
				layout:SetStretchHeight(true)
				layout:Clear()
				
				for _,form_value in ipairs(form_data) do
					local form_name = form_value["uid"]
					local var_value = subvar[form_name]

					local var = {}
					esclib:SafeMerge(var, form_value, true)

					if type(var_value) == "table" then
						var.value = table.Copy(var_value)
					else
						var.value = var_value
					end

					local var_base = layout:Add("DPanel")
					var_base:SetSize(plist:GetWide()-layout:GetBorder()*2, button_tall)
					var_base.Paint = nil
					var_base.addon = addon
					var_base.var_uid = form_name
					var_base.var = var
					if def_val[sub_name] then
						var_base.default_value = def_val[sub_name][form_name]
					end

					var_base.initial_values = varc.value[sub_name]
					var_base.ApplyValue = function()
						subvar[form_name] = var_base.var.value
						varc.value[sub_name][form_name] = var_base.var.value
						-- callback()
						own_build()
					end
					var_base.bg = pnl.bg
					var_base.parent = listing

					local ftype = form_value["type"]
					local builder = esclib.allowed_settings_types[ftype]
					if builder then
						builder:Build(var_base)
					end
				end

				timer.Simple(0, function()
					if not IsValid(pnl) or not IsValid(layout) then return end
					
					local tall = layout:GetTall() + pnl.titlepanel:GetTall() + layout:GetBorder()
					pnl:SetTall(math.min(tall, esclib.scrh*0.7))
					if x == 0 and y == 0 then
						pnl:Center()
						x,y = pnl:GetPos()
					else
						pnl:SetPos(x,y)
					end
				end)
			end

			function pnl.bg:OnClose()
				callback()
			end

			own_build()
		end

		local mat = esclib:GetMaterial("wrench.png")
		local offset_x = esclib:AdaptiveSize(20)
		local target_offset_x = offset_x
        local first_text = name.." ["..sub_name.."]"
        local second_text = ""
        for _,sfdata in ipairs(form_data) do
            if sfdata.form_display then
                local form_name = sfdata.name or addon:Translate(sfdata.name_tr) or ""
				local form_value = varc.value[sub_name][sfdata.uid]
				if istable(form_value) then
					form_value = table.concat(form_value, ", ")
				end
                local text_to_add = form_name..": "..tostring(form_value)
                if second_text ~= "" then
                    second_text = second_text..', '
                end
                second_text = second_text..text_to_add
            end
        end
		function var_pnl:Paint(w,h)
			local hovered = self:IsHovered()
			local is_changed = not VarsIsEqual(varc_copy[varid][sub_name], varc.value[sub_name])
			draw_bg(w,h,hovered,clr,is_changed)

			draw.SimpleText(first_text,font,offset_x,h*0.5,clr.button.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
			draw.SimpleText(second_text,font2,offset_x,h*0.52,clr.button.accent,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

			if hovered then
				offset_x = Lerp(0.1, offset_x, h)
				esclib.draw:MaterialCentered(offset_x-h*0.5, h*0.5, h*0.25, clr.button.text, mat)
			else
				offset_x = Lerp(0.1, offset_x, target_offset_x)
			end
		end
	end

	parent:Hide()

	local button = listing:Add("DButton")
	button:SetSize(button_wide, button_tall)
	button:SetText("")
	if desc then
		local added = ""
		button:eAddHint(added.." "..desc,esclib:AdaptiveFont("esclib", 20, 500),TEXT_ALIGN_CENTER,settab)
	end
	
	local offsety = button:GetTall()*0.2
	local clr_black = Color(0,0,0)
	function button:Paint(w,h)
		local hovered = self:IsHovered()
		draw.RoundedBox(8,0,0,w,h,hovered and clr.button.accent_hover or clr.button.accent)
		
		draw.SimpleText("+ "..name,font,15,h*0.5,clr_black,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		draw.SimpleText(desc,font2,15,h*0.52,clr_black,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
	end

	function button:DoClick()
		local hint = varc.HintTranslateKey and addon:Translate(varc.HintTranslateKey) or esclib.addon:Translate("window_ValueEdit", addon.info.language)
		local text_input = esclib:TextInputWindow(name_tr, hint, false, false, 
			function(result)
				if not result then return end

				local tbl = {}

				for _,v in ipairs(form_data) do
					tbl[v["uid"]] = v["value"] or ""
				end

				varc.value[result] = tbl
				callback()
				parent:SaveAll()
			end,
			function(val)
				local slen = string.len(string.Trim(val) or "")
				local maxv = 255
				local minv = 2

				if not ((slen >= minv) and (slen <= maxv)) then
					return string.format("%s <= #str <= %s", minv, maxv)
				end
				return not ((slen >= minv) and (slen <= maxv))
			end,
			addon.info.language
		)
		text_input:SetText("")
	end
end



---------------
--# EXAMPLE #--
---------------

--[[
sv_tab:AddVar("rank_form", "form")
:SetNameTranslateKey("s_rank_name")
:SetDescTranslateKey("s_rank_desc")
:SetHintTranslateKey("s_rank_hint")
:SetShared(true)
:SetValue({
    ["superadmin"] = {
        ["rank_draw"] = true,
        ["rank_name"] = "superadmin",
        ["rank_color1"] = Color(220,27,255),
        ["rank_color2"] = Color(255,0,150),
        ["rank_glow"] = true,
        ["rank_admin_cmds"] = true,
    },
    ["user"] = {
        ["rank_draw"] = false,
        ["rank_name"] = "user",
        ["rank_color1"] = Color(255,255,255),
        ["rank_color2"] = Color(255,255,255),
        ["rank_glow"] = false,
        ["rank_admin_cmds"] = false,
    },
}) -- by default
:SetFormFields({
    {
        ["uid"] = "rank_draw",
        ["type"] = "bool",
        ["name_tr"] = "form_rank_draw",
        ["value"] = true,
    },
    {
        ["uid"] = "rank_name",
        ["type"] = "str",
        ["name_tr"] = "form_rank_name",
        ["MinimumCharCount"] = 1,
        ["MaximumCharCount"] = 255,
        ["value"] = "change_me",
        ["form_display"] = true,
    },
    {
        ["uid"] = "rank_color1",
        ["type"] = "clr",
        ["name_tr"] = "form_rank_color1",
        ["value"] = Color(255,255,255),
    },
    {
        ["uid"] = "rank_color2",
        ["type"] = "clr",
        ["name_tr"] = "form_rank_color2",
        ["value"] = Color(255,255,255),
    },
    {
        ["uid"] = "rank_glow",
        ["type"] = "bool",
        ["name_tr"] = "form_rank_glow",
        ["value"] = false,
    },
    {
        ["uid"] = "rank_admin_cmds",
        ["type"] = "bool",
        ["name_tr"] = "form_rank_admin_cmds",
        ["value"] = false,
    },
})
--]]