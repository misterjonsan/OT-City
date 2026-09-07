local MODE = MODE

local RNDX = _G.gSims_RNDX

local clr_accent = Color(31, 182, 255)
local clr_cyan = Color(127, 230, 255)
local clr_text = Color(240, 248, 255)
local clr_card = Color(6, 12, 20, 168)
local clr_card_hover = Color(12, 22, 36, 205)
local clr_bg = Color(3, 5, 9, 235)
local clr_apply_ready = Color(31, 182, 255)

local function DrawRound(rad, x, y, w, h, col)
	if RNDX then
		RNDX.Draw(rad, x, y, w, h, col)
	else
		draw.RoundedBox(rad, x, y, w, h, col)
	end
end

local function DrawRoundOutlined(rad, x, y, w, h, col, thickness)
	if RNDX then
		RNDX.DrawOutlined(rad, x, y, w, h, col, thickness or 1)
	else
		surface.SetDrawColor(col.r, col.g, col.b, col.a)
		surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
	end
end

local function Sc()
	return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.55, 1.75)
end

local function SX(n)
	return math.floor(Sc() * n + 0.5)
end

local function DrawSlant(x, y, w, h, skew, col)
	draw.NoTexture()
	surface.SetDrawColor(col)
	surface.DrawPoly({
		{x = x + skew, y = y},
		{x = x + w + skew, y = y},
		{x = x + w, y = y + h},
		{x = x, y = y + h}
	})
end

local function SmoothNoise(t, f1, f2, f3, phase)
	phase = phase or 0

	return math.sin(t * f1 * math.pi * 2 + phase) * 0.55
		+ math.sin(t * f2 * math.pi * 2 + phase + 2.399) * 0.30
		+ math.sin(t * f3 * math.pi * 2 + phase + 5.131) * 0.15
end

local function WrapText(text, font, maxw)
	surface.SetFont(font)
	local out = {}
	for _, paragraph in ipairs(string.Explode("\n", text)) do
		local line = ""
		for _, word in ipairs(string.Explode(" ", paragraph)) do
			local test = (line == "") and word or (line .. " " .. word)
			local tw = surface.GetTextSize(test)
			if tw > maxw and line ~= "" then
				out[#out + 1] = line
				line = word
			else
				line = test
			end
		end
		out[#out + 1] = line
	end
	return out
end

local function CreateFonts()
	local s = Sc()

	surface.CreateFont("ZRole_Brand", {font = "Montserrat SemiBold", size = math.floor(44 * s + 0.5), weight = 800, italic = true, antialias = true, extended = true})
	surface.CreateFont("ZRole_Sub", {font = "Montserrat Medium", size = math.floor(20 * s + 0.5), weight = 600, antialias = true, extended = true})
	surface.CreateFont("ZRole_Close", {font = "Montserrat SemiBold", size = math.floor(34 * s + 0.5), weight = 800, antialias = true, extended = true})
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "XC_RoleFonts", CreateFonts)

local function set_role(role, mode)
	if mode == "soe" then
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor_SOE, role)
	else
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor, role)
	end
end

local PANEL = {}

function PANEL:IsSelected()
	if self.Mode == "soe" then
		return MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role
	else
		return MODE.ConVar_SubRole_Traitor:GetString() == self.Role
	end
end

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())

	self.Title = self.Title or "No title"
	self.HoverLerp = 0
	self.SelectLerp = 0

	local label_name = vgui.Create("DButton", self)
	label_name.ZRolePanel = self
	label_name:SetText("")
	label_name:SetSkin(hg.GetMainSkin())
	label_name:DockMargin(ScreenScale(7), ScreenScaleH(7), ScreenScale(7), ScreenScaleH(4))
	label_name:Dock(TOP)
	label_name:SetTall(ScreenScaleH(28))
	label_name:SetMouseInputEnabled(true)
	label_name:SetCursor("hand")

	label_name.Paint = function(sel, w, h)
		local selected = self:IsSelected()
		local col = selected and clr_accent or clr_text

		draw.SimpleText(self.Title, "ZB_InterfaceMedium", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	label_name.DoClick = function(sel)
		set_role(self.Role, self.Mode or "soe")
	end

	local text_description = vgui.Create("RichText", self)
	text_description.ZRolePanel = self
	text_description:SetText(self.Description)
	text_description:SetSkin(hg.GetMainSkin())
	text_description:Dock(FILL)
	text_description:DockMargin(ScreenScale(10), 0, ScreenScale(10), ScreenScaleH(8))

	text_description.PerformLayout = function(sel)
		if sel:GetFont() ~= "ZB_InterfaceSmall" then
			sel:SetFontInternal("ZB_InterfaceSmall")
		end

		sel:SetFGColor(Color(215, 232, 245, 235))
	end

	text_description.Paint = function(sel, w, h)
	end
end

function PANEL:Paint(w, h)
	local hov = self:IsHovered() or self:IsChildHovered()
	local selected = self:IsSelected()

	self.HoverLerp = LerpFT(0.16, self.HoverLerp or 0, hov and 1 or 0)
	self.SelectLerp = LerpFT(0.16, self.SelectLerp or 0, selected and 1 or 0)

	local bg = Color(
		Lerp(self.HoverLerp, clr_card.r, clr_card_hover.r),
		Lerp(self.HoverLerp, clr_card.g, clr_card_hover.g),
		Lerp(self.HoverLerp, clr_card.b, clr_card_hover.b),
		Lerp(self.HoverLerp, clr_card.a, clr_card_hover.a)
	)

	DrawRound(10, 0, 0, w, h, bg)

	surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 70 + self.HoverLerp * 90 + self.SelectLerp * 95)
	surface.DrawRect(ScreenScale(8), ScreenScaleH(6), w - ScreenScale(16), math.max(2, ScreenScaleH(2)))

	if self.SelectLerp > 0.01 then
		DrawRoundOutlined(10, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, self.SelectLerp * 60), 5)
	end

	local outlineA = 14 + self.HoverLerp * 60 + self.SelectLerp * 180
	DrawRoundOutlined(10, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, outlineA), 1 + math.Round(self.SelectLerp))
end

function PANEL:PaintOver(w, h)
end

derma.DefineControl("HMCD_RolePanel", "", PANEL, "DPanel")

local PANEL = {}

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())

	self.RolesIDsList = self.RolesIDsList or MODE.RoleChooseRoundTypes["standard"].Traitor

	self.BGMaterial = Material("otcity/fone.png", "smooth")
	self.BGStartTime = RealTime()
	self.BGZoom = 1.18
	self.BGPanX = 0
	self.BGPanY = 0

	self.RoleCount = 0
	for _ in pairs(self.RolesIDsList) do
		self.RoleCount = self.RoleCount + 1
	end

	self.CardWrap = vgui.Create("DPanel", self)
	self.CardWrap.Paint = nil
	self.Cards = {}

	for role_id, _ in pairs(self.RolesIDsList) do
		local role_info = MODE.SubRoles[role_id]
		local role_name = role_info.Name
		local role_description = role_info.Description

		local role_panel = vgui.Create("HMCD_RolePanel", self.CardWrap)
		role_panel.Title = role_name
		role_panel.Description = role_description
		role_panel.Role = role_id
		role_panel.Mode = self.Mode or "soe"
		role_panel:Construct()

		self.Cards[#self.Cards + 1] = role_panel
	end

	local button_ready = vgui.Create("DButton", self)
	button_ready:SetSkin(hg.GetMainSkin())
	button_ready:SetText("")
	button_ready:SetCursor("hand")
	button_ready.HoverLerp = 0
	self.ApplyButton = button_ready

	button_ready.DoClick = function(sel)
		if IsValid(VGUI_HMCD_RolePanelList) then
			VGUI_HMCD_RolePanelList:Remove()
		end
	end

	button_ready.Paint = function(sel, w, h)
		sel.HoverLerp = LerpFT(0.16, sel.HoverLerp or 0, sel:IsHovered() and 1 or 0)

		local rad = math.max(5, SX(10))

		if sel.Clicked then
			DrawRound(rad, 0, 0, w, h, clr_apply_ready)
		else
			DrawRound(rad, 0, 0, w, h, Color(10, 30, 48, 200 + sel.HoverLerp * 55))
		end

		if sel.HoverLerp > 0.01 and not sel.Clicked then
			DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, sel.HoverLerp * 45), math.max(3, SX(6)))
		end

		DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 120 + sel.HoverLerp * 135), math.max(1, SX(1)))

		local txtCol = sel.Clicked and Color(5, 10, 16, 245) or Color(
			Lerp(sel.HoverLerp, 215, 255),
			Lerp(sel.HoverLerp, 238, 255),
			Lerp(sel.HoverLerp, 250, 255),
			245
		)

		draw.SimpleText("ПРИМЕНИТЬ", "ZB_InterfaceMedium", w / 2, h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local close = vgui.Create("DButton", self)
	close:SetText("")
	close:SetCursor("hand")
	close.HoverLerp = 0
	self.CloseButton = close

	close.DoClick = function()
		if IsValid(VGUI_HMCD_RolePanelList) and VGUI_HMCD_RolePanelList == self then
			VGUI_HMCD_RolePanelList = nil
		end
		self:Remove()
	end

	close.Paint = function(btn, w, h)
		btn.HoverLerp = LerpFT(0.18, btn.HoverLerp or 0, btn:IsHovered() and 1 or 0)

		local bg = Color(
			Lerp(btn.HoverLerp, 8, 16),
			Lerp(btn.HoverLerp, 18, 60),
			Lerp(btn.HoverLerp, 30, 96),
			Lerp(btn.HoverLerp, 155, 225)
		)

		local rad = math.max(4, SX(8))

		DrawRound(rad, 0, 0, w, h, bg)
		DrawRoundOutlined(rad, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 70 + btn.HoverLerp * 150), 1)
		draw.SimpleText("×", "ZRole_Close", w * 0.5, h * 0.46, Color(Lerp(btn.HoverLerp, 235, clr_accent.r), Lerp(btn.HoverLerp, 235, clr_accent.g), Lerp(btn.HoverLerp, 235, clr_accent.b), 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PANEL:PerformLayout()
	self:SetPos(0, 0)
	self:SetSize(ScrW(), ScrH())

	local w, h = self:GetSize()

	if IsValid(self.CardWrap) then
		local count = math.max(#self.Cards, 1)
		local gap = SX(14)
		local availW = math.min(w - SX(96), SX(1700))
		local cardW = math.min(SX(330), math.floor((availW - (count - 1) * gap) / count))
		local descW = cardW - ScreenScale(24)

		surface.SetFont("ZB_InterfaceSmall")
		local _, lineH = surface.GetTextSize("W")
		lineH = lineH + SX(4)

		local contentH = 0
		for _, card in ipairs(self.Cards) do
			local lines = WrapText(card.Description or "", "ZB_InterfaceSmall", descW)
			contentH = math.max(contentH, #lines * lineH)
		end

		local cardH = ScreenScaleH(47) + contentH + SX(22)
		cardH = math.min(cardH, h - SX(260))

		local totalW = count * cardW + (count - 1) * gap
		local startX = math.floor((w - totalW) * 0.5)
		local bandY = math.floor(h * 0.5 - cardH * 0.5 + SX(24))

		self.CardWrap:SetPos(0, 0)
		self.CardWrap:SetSize(w, h)

		for i, card in ipairs(self.Cards) do
			card:SetSize(cardW, cardH)
			card:SetPos(startX + (i - 1) * (cardW + gap), bandY)
		end

		self.BandBottom = bandY + cardH
	end

	if IsValid(self.ApplyButton) then
		local bw = SX(360)
		local bh = SX(56)
		self.ApplyButton:SetSize(bw, bh)
		self.ApplyButton:SetPos(math.floor((w - bw) * 0.5), (self.BandBottom or math.floor(h * 0.5)) + SX(48))
	end

	if IsValid(self.CloseButton) then
		local s = SX(46)
		self.CloseButton:SetSize(s, s)
		self.CloseButton:SetPos(w - s - SX(48), SX(40))
	end
end

function PANEL:PaintBackground(w, h)
	local mat = self.BGMaterial

	if not mat or mat:IsError() then
		surface.SetDrawColor(clr_bg)
		surface.DrawRect(0, 0, w, h)
		return
	end

	local iw, ih = mat:Width(), mat:Height()

	if iw <= 0 or ih <= 0 then
		surface.SetDrawColor(clr_bg)
		surface.DrawRect(0, 0, w, h)
		return
	end

	local elapsed = RealTime() - (self.BGStartTime or RealTime())
	local dt = math.Clamp(FrameTime(), 0, 0.1)
	local blend = 1 - math.exp(-dt * 1.35)

	local zoomTarget = 1.18 + (SmoothNoise(elapsed, 0.0170, 0.0271, 0.0413, 0.0) * 0.5 + 0.5) * 0.15
	local panXTarget = SmoothNoise(elapsed, 0.0131, 0.0207, 0.0331, 1.3)
	local panYTarget = SmoothNoise(elapsed, 0.0113, 0.0181, 0.0293, 4.9)

	self.BGZoom = (self.BGZoom or zoomTarget) + (zoomTarget - (self.BGZoom or zoomTarget)) * blend
	self.BGPanX = (self.BGPanX or panXTarget) + (panXTarget - (self.BGPanX or panXTarget)) * blend
	self.BGPanY = (self.BGPanY or panYTarget) + (panYTarget - (self.BGPanY or panYTarget)) * blend

	local baseScale = math.max(w / iw, h / ih)
	local scale = baseScale * self.BGZoom
	local drawW = iw * scale
	local drawH = ih * scale

	local safeX = math.max((drawW - w) * 0.5, 0)
	local safeY = math.max((drawH - h) * 0.5, 0)

	local x = (w - drawW) * 0.5 + self.BGPanX * safeX * 0.72
	local y = (h - drawH) * 0.5 + self.BGPanY * safeY * 0.72

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x, y, drawW, drawH)

	surface.SetDrawColor(2, 8, 14, 60)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:Paint(w, h)
	self:PaintBackground(w, h)

	draw.NoTexture()

	surface.SetDrawColor(1, 4, 8, 132)
	surface.DrawRect(0, 0, w, h)

	local headerY = SX(36)
	local cx = w * 0.5

	surface.SetFont("ZRole_Brand")
	local otW = surface.GetTextSize("OT-")
	local brandW = otW + surface.GetTextSize("CITY")

	draw.SimpleText("OT-", "ZRole_Brand", cx - brandW * 0.5 + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("CITY", "ZRole_Brand", cx - brandW * 0.5 + otW + SX(1), headerY + SX(2), Color(2, 8, 14, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("OT-", "ZRole_Brand", cx - brandW * 0.5, headerY, clr_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("CITY", "ZRole_Brand", cx - brandW * 0.5 + otW, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local sub = "ВЫБОР РОЛИ"
	surface.SetFont("ZRole_Sub")
	local subW = surface.GetTextSize(sub)

	draw.SimpleText(sub, "ZRole_Sub", cx, headerY + SX(58), Color(200, 225, 245, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	local stripeY = headerY + SX(58) + SX(11)
	local stripeW = SX(48)

	DrawSlant(cx - subW * 0.5 - SX(18) - stripeW, stripeY, stripeW, math.max(2, SX(3)), -SX(6), clr_accent)
	DrawSlant(cx + subW * 0.5 + SX(18), stripeY, stripeW, math.max(2, SX(3)), SX(6), clr_accent)
end

derma.DefineControl("HMCD_RolePanelList", "", PANEL, "DPanel")

local delta = 0
hook.Add("CreateMove", "HMCD_RolePanelClick", function(cmd)
	local dlta = (input.WasMousePressed(MOUSE_WHEEL_DOWN) and -1) or (input.WasMousePressed(MOUSE_WHEEL_UP) and 1) or 0

	delta = LerpFT(0.05, delta, dlta)
	local delta = delta * 2

	if math.abs(delta) > 0.01 then
		local hovered_panel = vgui.GetHoveredPanel()

		local parent_panel = IsValid(hovered_panel) and hovered_panel:GetParent()
		local parent_panel2 = IsValid(parent_panel) and parent_panel:GetParent()
		local parent_panel3 = IsValid(parent_panel2) and parent_panel2:GetParent()
		local parent_panel4 = IsValid(parent_panel3) and parent_panel3:GetParent()
		local parent_panel5 = IsValid(parent_panel4) and parent_panel4:GetParent()

		if IsValid(hovered_panel) and hovered_panel.OnMouseWheeled then
			hovered_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel) and parent_panel.OnMouseWheeled then
			parent_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel2) and parent_panel2.OnMouseWheeled then
			parent_panel2:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel3) and parent_panel3.OnMouseWheeled then
			parent_panel3:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel4) and parent_panel4.OnMouseWheeled then
			parent_panel4:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel5) and parent_panel5.OnMouseWheeled then
			parent_panel5:OnMouseWheeled(delta)
		end
	end

	if input.WasMousePressed(MOUSE_LEFT) then
		local hovered_panel = vgui.GetHoveredPanel()

		if IsValid(hovered_panel) and IsValid(hovered_panel.ZRolePanel) then
			set_role(hovered_panel.ZRolePanel.Role, hovered_panel.ZRolePanel.Mode)
		end
	end
end)

local PANEL = {}

AccessorFunc(PANEL, "m_iOverlap", "Overlap")
AccessorFunc(PANEL, "m_bShowDropTargets", "ShowDropTargets", FORCE_BOOL)

function PANEL:Init()
	self.Panels = {}
	self.OffsetX = 0
	self.FrameTime = 0

	self.pnlCanvas = vgui.Create("DDragBase", self)
	self.pnlCanvas:SetDropPos("6")
	self.pnlCanvas:SetUseLiveDrag(false)
	self.pnlCanvas.OnModified = function() self:OnDragModified() end

	self.pnlCanvas.UpdateDropTarget = function(Canvas, drop, pnl)
		if not self:GetShowDropTargets() then return end
		DDragBase.UpdateDropTarget(Canvas, drop, pnl)
	end

	self.pnlCanvas.OnChildAdded = function(Canvas, child)
		local dn = Canvas:GetDnD()

		if dn then
			child:Droppable(dn)

			child.OnDrop = function()
				local x, y = Canvas:LocalCursorPos()
				local closest, id = self.pnlCanvas:GetClosestChild(x, Canvas:GetTall() / 2), 0

				for k, v in pairs(self.Panels) do
					if v == closest then id = k break end
				end

				table.RemoveByValue(self.Panels, child)
			table.insert(self.Panels, id, child)

				self:InvalidateLayout()

				return child
			end
		end
	end

	self:SetOverlap(0)

	self.btnLeft = vgui.Create("DButton", self)
	self.btnLeft:SetText("")
	self.btnLeft.HoverLerp = 0
	self.btnLeft.Paint = function(panel, w, h)
		panel.HoverLerp = LerpFT(0.16, panel.HoverLerp or 0, panel:IsHovered() and 1 or 0)

		DrawRound(6, 0, 0, w, h, Color(8, 18, 30, 150 + panel.HoverLerp * 60))
		DrawRoundOutlined(6, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60 + panel.HoverLerp * 150), 1)

		draw.SimpleText("‹", "ZB_InterfaceMedium", w / 2, h / 2 - 1, Color(255, 255, 255, 200 + panel.HoverLerp * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	self.btnRight = vgui.Create("DButton", self)
	self.btnRight:SetText("")
	self.btnRight.HoverLerp = 0
	self.btnRight.Paint = function(panel, w, h)
		panel.HoverLerp = LerpFT(0.16, panel.HoverLerp or 0, panel:IsHovered() and 1 or 0)

		DrawRound(6, 0, 0, w, h, Color(8, 18, 30, 150 + panel.HoverLerp * 60))
		DrawRoundOutlined(6, 0, 0, w, h, Color(clr_accent.r, clr_accent.g, clr_accent.b, 60 + panel.HoverLerp * 150), 1)

		draw.SimpleText("›", "ZB_InterfaceMedium", w / 2, h / 2 - 1, Color(255, 255, 255, 200 + panel.HoverLerp * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:ScrollToChild(panel)
	self:InvalidateLayout(true)

	local x, y = self.pnlCanvas:GetChildPosition(panel)
	local w, h = panel:GetSize()

	x = x + w * 0.5
	x = x - self:GetWide() * 0.5

	self:SetScroll(x)
end

function PANEL:SetScroll(x)
	self.OffsetX = x
	self:InvalidateLayout(true)
end

function PANEL:SetUseLiveDrag(bool)
	self.pnlCanvas:SetUseLiveDrag(bool)
end

function PANEL:MakeDroppable(name, allowCopy)
	self.pnlCanvas:MakeDroppable(name, allowCopy)
end

function PANEL:AddPanel(pnl)
	table.insert(self.Panels, pnl)

	pnl:SetParent(self.pnlCanvas)
	self:InvalidateLayout(true)
end

function PANEL:Clear()
	self.pnlCanvas:Clear()
	self.Panels = {}
end

function PANEL:OnMouseWheeled(dlta)
	self.OffsetX = self.OffsetX + dlta * -30
	self:InvalidateLayout(true)

	return true
end

function PANEL:Think()
	local FrameRate = VGUIFrameTime() - self.FrameTime
	self.FrameTime = VGUIFrameTime()

	if self.btnRight:IsDown() then
		self.OffsetX = self.OffsetX + (500 * FrameRate)
		self:InvalidateLayout(true)
	end

	if self.btnLeft:IsDown() then
		self.OffsetX = self.OffsetX - (500 * FrameRate)
		self:InvalidateLayout(true)
	end

	if dragndrop.IsDragging() then
		local x, y = self:LocalCursorPos()

		if x < 30 then
			self.OffsetX = self.OffsetX - (350 * FrameRate)
		elseif x > self:GetWide() - 30 then
			self.OffsetX = self.OffsetX + (350 * FrameRate)
		end

		self:InvalidateLayout(true)
	end
end

function PANEL:PerformLayout()
	local w, h = self:GetSize()

	self.pnlCanvas:SetTall(h)

	local x = 0

	for k, v in pairs(self.Panels) do
		if not IsValid(v) then continue end
		if not v:IsVisible() then continue end

		v:SetPos(x, 0)
		v:SetTall(h)
		if v.ApplySchemeSettings then v:ApplySchemeSettings() end

		x = x + v:GetWide() - self.m_iOverlap
	end

	self.pnlCanvas:SetWide(x + self.m_iOverlap)

	if w < self.pnlCanvas:GetWide() then
		self.OffsetX = math.Clamp(self.OffsetX, 0, self.pnlCanvas:GetWide() - self:GetWide())
	else
		self.OffsetX = 0
	end

	self.pnlCanvas.x = self.OffsetX * -1

	self.btnLeft:SetSize(ScreenScale(11), ScreenScaleH(20))
	self.btnLeft:AlignLeft(4)
	self.btnLeft:CenterVertical()

	self.btnRight:SetSize(ScreenScale(11), ScreenScaleH(20))
	self.btnRight:AlignRight(4)
	self.btnRight:CenterVertical()

	self.btnLeft:SetVisible(self.pnlCanvas.x < 0)
	self.btnRight:SetVisible(self.pnlCanvas.x + self.pnlCanvas:GetWide() > self:GetWide())
end

function PANEL:OnDragModified()
end

derma.DefineControl("ZHorizontalScroller", "", PANEL, "Panel")

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "role panels loaded\n")
