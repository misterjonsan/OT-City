MODE.name = "standoff_2"

local MODE = MODE
local StartTime = 0
local PointsProgress = {}
local grtArrived = false
local ModeMusic
local respawntime = CurTime()

net.Receive("s2_start", function()
	StartTime = CurTime()
	grtArrived = false
	PointsProgress = {}

	if IsValid(ModeMusic) then
		ModeMusic:Stop()
		ModeMusic = nil
	end

	timer.Simple(0.5, function()
		local url = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/standoff2.mp3"
		sound.PlayURL(url, "noplay", function(chan)
			if IsValid(chan) then
				ModeMusic = chan
				chan:SetVolume(2)
				chan:Play()
			end
		end)
	end)

	zb.RemoveFade()
end)

net.Receive("s2_respawn", function()
	respawntime = net.ReadFloat() + 5

	hook.Add("HUDPaint", "_RespawnStandoff2", function()
		if respawntime < CurTime() then
			hook.Remove("HUDPaint", "_RespawnStandoff2")
			return
		end

		if lply:Alive() then return end

		local fade = math.Clamp(respawntime - CurTime(), 0, 1)
		draw.SimpleText(
			"Респавн через " .. string.FormattedTime(respawntime - CurTime(), "%02i:%02i:%02i"),
			"ZB_HomicideMedium",
			sw * 0.5,
			sh * 0.8,
			Color(200, 220, 255, 255 * fade),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end)
end)

net.Receive("S2_PointsUpdate", function()
	PointsProgress = net.ReadTable() or {}
end)

net.Receive("s2_grt_spawn", function()
	if not grtArrived then
		grtArrived = true
		surface.PlaySound("snd_jack_hmcd_policesiren.wav")
	end
end)

local teams = {
	[0] = {
		objective = "Ваша задача устранить спецназ и удержать преимущество.",
		name = "Террорист",
		color1 = Color(185, 60, 60),
		color2 = Color(185, 60, 60)
	},
	[1] = {
		objective = "Ваша задача остановить террористов и не дать им захватить мир.",
		name = "Спецназ",
		color1 = Color(60, 140, 255),
		color2 = Color(60, 140, 255)
	},
	[2] = {
		objective = "Ваша задача прибыть на подкрепление, зачистить зону и завершить раунд в пользу сил правопорядка.",
		name = "ГРТ",
		color1 = Color(120, 120, 255),
		color2 = Color(120, 120, 255)
	},
}

hook.Add("StartCommand", "S2_DisallowMoveOrShooting", function(ply, mv)
	if zb.CROUND == "standoff_2" and StartTime > 0 and StartTime + 20 > CurTime() then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
		mv:RemoveKey(IN_JUMP)
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetUpSpeed(0)
	end
end)

function MODE:RenderScreenspaceEffects()
	if StartTime + 7.5 < CurTime() then return end

	local fade = math.Clamp(StartTime + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local terroristColor = Color(185, 60, 60, 105)
local ctColor = Color(60, 140, 255, 105)
local bgColor = Color(0, 0, 0, 155)
local sizeH = ScreenScale(8)
local sizeW = ScreenScale(10)

function MODE:HUDPaint()
	local sw, sh = ScrW(), ScrH()

	for n, points in pairs(PointsProgress) do
		local pos = points[2]:ToScreen()
		local posH = sizeH
		local posW = pos.x

		draw.RoundedBox(0, posW, posH - sizeH * math.abs(points[1] / 100), sizeW, sizeH * math.abs(points[1] / 100), points[1] < 0 and ctColor or terroristColor)
		draw.RoundedBox(0, posW, posH - sizeH, sizeW, sizeH, bgColor)
		draw.DrawText(string.Left(n, 1), "ZCity_Tiny", posW + sizeW / 2 - 1, posH - sizeH, color_white, TEXT_ALIGN_CENTER)
	end

	if lply:Alive() then
		local grtArrival = StartTime + 120
		local timeLeft = grtArrival - CurTime()

		if timeLeft > 0 then
			local text = "ГРТ прибудет к вам через: " .. string.FormattedTime(timeLeft, "%02i:%02i")
			local pulse = (math.sin(CurTime() * 3) + 1) / 2
			local col = Color(255 * pulse, 255 * pulse, 255)

			draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.95 - 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		elseif not grtArrived then
			draw.SimpleText("ГРТ уже в пути...", "ZB_HomicideMedium", sw * 0.02, sh * 0.95, Color(180, 180, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	if lply:Alive() and (lply:Team() == 0 or lply:Team() == 1) and StartTime + 20 > CurTime() then
		local money = lply:GetNWInt("TDM_Money", 0)
		local buyText = "Нажмите F3 для закупки  |  Баланс: $" .. tostring(money)
		draw.SimpleText(buyText, "ZB_HomicideMedium", sw * 0.5, sh * 0.82, Color(0, 0, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(buyText, "ZB_HomicideMedium", sw * 0.5 - 1, sh * 0.82 - 1, Color(255, 255, 255, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local timeText = string.FormattedTime(math.max(StartTime + 20 - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(timeText, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local timeText = string.FormattedTime(math.max(StartTime + 580 - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(timeText, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if StartTime + 8.5 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = math.Clamp(StartTime + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
	local teamData = teams[team_]
	if not teamData then return end

	draw.SimpleText("OT-City | Standoff 2", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(150, 220, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local roleColor = Color(teamData.color1.r, teamData.color1.g, teamData.color1.b, 255 * fade)
	draw.SimpleText("Вы: " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local objColor = Color(teamData.color2.r, teamData.color2.g, teamData.color2.b, 255 * fade)
	draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local CreateEndMenu

net.Receive("s2_roundend", function()
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")

	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Закрыть")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Закрыть")
	end

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Игроки:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Игроки:")
		surface.SetDrawColor(100, 180, 255, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(100, 180, 255, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")

		but.Paint = function(self, w, h)
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local plycol = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")

			local pname = ply:GetPlayerName() or "Disconnected"
			local _, lengthY = surface.GetTextSize(pname)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(pname)

			surface.SetTextColor(plycol.r, plycol.g, plycol.b, plycol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(pname)

			local txcol = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(txcol.r, txcol.g, txcol.b, txcol.a)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - eliminated" or "")) or "Disconnected")

			local fragText = tostring(ply:Frags() or 0)
			local fragLenX, fragLenY = surface.GetTextSize(fragText)
			surface.SetTextPos(w - fragLenX - 15, h / 2 - fragLenY / 2)
			surface.DrawText(fragText)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "Для ботов профиль недоступен")
				return
			end

			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	grtArrived = false

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end

surface.CreateFont("ZB_TDM_MENU", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	extended = true,
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_TDM_DESC", {
	font = "Bahnschrift",
	size = ScreenScale(7),
	extended = true,
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_TDM_CATEGORY", {
	font = "Bahnschrift",
	size = ScreenScale(6),
	extended = true,
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_TDM_DESCSMALL", {
	font = "Bahnschrift",
	size = ScreenScale(5),
	extended = true,
	weight = 400,
	antialias = true
})

local function PaintFrame(self,w,h)
	BlurBackground(self)
	surface.SetDrawColor(100, 180, 255, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
end

local function PaintPanel(self,w,h)
	surface.SetDrawColor(0, 0, 0, 155)
	surface.DrawRect(0, 0, w, h, 2.5)
	surface.SetDrawColor(100, 180, 255, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
end

local gradient_l = Material("vgui/gradient-l")

local function PaintPanel1(self,w,h)
	surface.SetDrawColor(0, 0, 0, 155)
	surface.DrawRect(0, 0, w, h, 2.5)
	surface.SetDrawColor(100, 180, 255, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	draw.RoundedBox(0, 2.5, 2.5, w - 5, h - 5, Color(0, 0, 0, 140))
	surface.SetDrawColor(55, 100, 155, 55)
	surface.SetMaterial(gradient_l)
	surface.DrawTexturedRect(0, 0, w / 1.5, h)
end

local function PaintPanel2(self,w,h)
	surface.SetDrawColor(55, 155, 55, 25)
	surface.SetMaterial(gradient_l)
	surface.DrawTexturedRect(0, 0, w * 1.2, h)
end

local rtabFunc = function(self)
	local ExtraInset = 10

	if self.Image then
		ExtraInset = ExtraInset + self.Image:GetWide()
	end

	self:SetTextInset(ExtraInset, 2)
	local w, h = self:GetContentSize()
	h = self:GetTabHeight()
	self:SetSize(w + 10, h + 7)

	DLabel.ApplySchemeSettings(self)
end

local function OpenBuyMenu()
	if TDM_OpenedBuyMenu then
		TDM_OpenedBuyMenu:Remove()
		TDM_OpenedBuyMenu = nil
	end

	if not LocalPlayer():Alive() then return end
	if LocalPlayer():Team() == 2 then return end
	if StartTime + 20 < CurTime() then return end

	TDM_OpenedBuyMenu = vgui.Create("ZFrame")
	local Frame = TDM_OpenedBuyMenu
	Frame:SetSize(1920 * 0.35, ScrH() * 0.85)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetTitle("Buy menu")
	Frame.Paint = PaintFrame

	local Sheet = vgui.Create("DPropertySheet", Frame)
	Sheet:Dock(FILL)
	Sheet:SetTextInset(50)
	Sheet.Paint = function() end
	Sheet.tabScroller:SetOverlap(0)
	Sheet.tabScroller:DockMargin(8, 0, 8, 0)
	Sheet:SetFadeTime(0.1)

	for k, category in SortedPairsByMemberValue(MODE.BuyItems, "Priority") do
		local CategoryPanel = vgui.Create("DScrollPanel", Sheet)
		CategoryPanel.Paint = function() end

		for n, Item in pairs(category) do
			if n == "Priority" then continue end
			if Item.TeamBased ~= nil and Item.TeamBased ~= LocalPlayer():Team() then continue end

			local weapon = weapons.GetStored(Item.ItemClass)
			local ent = scripted_ents.GetStored(Item.ItemClass)

			local ItemPanel = vgui.Create("DPanel", CategoryPanel)
			ItemPanel:SetSize(0, ScrH() * 0.1)
			ItemPanel:Dock(TOP)
			ItemPanel:DockMargin(0, 5, 0, 0)
			ItemPanel.Paint = PaintPanel1

			if (weapon ~= nil and (((weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName()) or weapon.IconOverride))) or ((ent and ent.t.IconOverride)) then
				local ItemButton = vgui.Create("DImage", ItemPanel)
				local bBox = ((ent and ent.t.IconOverride) or weapon ~= nil and weapon.WepSelectIcon2box)
				ItemButton:SetSize(ScrH() * ((bBox and 0.1) or 0.17), ScrH() * 0.1)
				ItemButton:Dock(LEFT)
				local boxed = ScrH() * 0.07 / 2
				ItemButton:DockMargin(5 + (bBox and boxed or 0), 5, 5 + (bBox and boxed or 0), 5)
				ItemButton:SetImage((weapon ~= nil and (((weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName() .. ".png") or weapon.IconOverride))) or ((ent and ent.t.IconOverride) or "none"))
			end

			local ItemButton = vgui.Create("DPanel", ItemPanel)
			ItemButton:Dock(FILL)
			ItemButton:DockMargin(0, 5, 0, 0)
			ItemButton.Paint = function() end

			local lbl = vgui.Create("DLabel", ItemButton)
			lbl:SetText(n)
			lbl:DockMargin(10, 0, 5, 0)
			lbl:Dock(TOP)
			lbl:SetFont("ZB_TDM_MENU")
			lbl:SetSize(ScrW() * 0.5, ScrH() * 0.04)

			local lbl2 = vgui.Create("DLabel", ItemButton)
			lbl2:SetText("Price: $" .. Item.Price)
			lbl2:DockMargin(10, 0, 5, 0)
			lbl2:Dock(TOP)
			lbl2:SetTextColor(Color(155, 200, 155))
			lbl2:SetFont("ZB_TDM_DESC")
			lbl2:SetSize(ScrW() * 0.5, ScrH() * 0.02)

			local BuyBtn = vgui.Create("DButton", ItemButton)
			BuyBtn:DockMargin(10, 5, 10, 10)
			BuyBtn:Dock(LEFT)
			BuyBtn:SetText("Buy")
			BuyBtn:SetTextColor(Color(200, 200, 200))
			BuyBtn:SetFont("ZB_TDM_DESC")
			BuyBtn:SetHeight(ScrH() * 0.025)
			BuyBtn.Paint = PaintPanel
			BuyBtn.Item = {k, n}

			function BuyBtn:DoClick()
				net.Start("s2_buyitem")
					net.WriteTable(self.Item)
				net.SendToServer()
			end

			if weapon then
				local ammo = weapon.Primary and weapon.Primary.Ammo ~= "none" and weapon.Primary.Ammo or weapon.Ammo or (weapons.GetStored(weapon.Base) and weapons.GetStored(weapon.Base).Primary and weapons.GetStored(weapon.Base).Primary.Ammo)

				if hg.ammotypeshuy[ammo] then
					local amm = vgui.Create("DButton", ItemButton)
					amm:DockMargin(10, 5, 10, 10)
					amm:Dock(LEFT)
					amm:SetText(ammo)
					amm:SetTextColor(Color(200, 200, 200))
					amm:SetFont("ZB_TDM_DESCSMALL")

					surface.SetFont("ZB_TDM_DESCSMALL")
					local w = surface.GetTextSize(ammo)

					amm:SetHeight(ScrH() * 0.025)
					amm:SetWidth(w + 7)

					local ammo2 = "ent_ammo_" .. hg.ammotypeshuy[ammo].name
					local name

					for name2, ammoTbl in pairs(MODE.BuyItems["Ammo"]) do
						if not istable(ammoTbl) then continue end
						if ammoTbl.ItemClass == ammo2 then
							name = name2
						end
					end

					amm.huy = {"Ammo", name}

					function amm:DoClick()
						net.Start("s2_buyitem")
							net.WriteTable(amm.huy)
						net.SendToServer()
					end

					amm.Paint = PaintPanel
				end
			end

			if Item.Attachments and #Item.Attachments > 0 then
				local ItemAtt = vgui.Create("DGrid", ItemPanel)
				ItemAtt:Dock(RIGHT)
				ItemAtt:DockMargin(0, 5, 0, 0)
				ItemAtt:SetCols(4)
				ItemAtt:SetColWide(50)
				ItemAtt:SetRowHeight(50)
				ItemAtt.Paint = function() end

				for _, AttachN in pairs(Item.Attachments) do
					local ico = hg.attachmentsIcons[AttachN]
					local Attach = vgui.Create("DImageButton")
					Attach:SetImage(ico)
					Attach:SetSize(45, 45)
					Attach.Attachment = {k, n, AttachN}

					function Attach:DoClick()
						net.Start("s2_buyitem")
							net.WriteTable(self.Attachment)
						net.SendToServer()
					end

					Attach.Paint = PaintPanel2
					ItemAtt:AddItem(Attach)
				end
			end
		end

		local tab = Sheet:AddSheet(k, CategoryPanel)
		local rTab = tab.Tab
		rTab.Paint = PaintPanel
		rTab:SetFont("ZB_TDM_CATEGORY")
		rTab.ApplySchemeSettings = rtabFunc
	end

	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Time Left: " .. string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"))
	lbl:DockMargin(10, 0, 10, 10)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(255, 255, 255))
	lbl:SetFont("ZB_TDM_DESC")
	lbl:SetSize(0, ScrH() * 0.015)

	function lbl:Think()
		if not IsValid(TDM_OpenedBuyMenu) then return end
		if not LocalPlayer():Alive() or LocalPlayer():Team() == 2 or StartTime + 20 < CurTime() then
			TDM_OpenedBuyMenu:Remove()
			return
		end
		self:SetText("Time Left: " .. string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"))
	end

	local lbl2 = vgui.Create("DLabel", Frame)
	lbl2:SetText("Cash: $" .. LocalPlayer():GetNWInt("TDM_Money", 0))
	lbl2:DockMargin(10, 5, 10, 5)
	lbl2:Dock(BOTTOM)
	lbl2:SetTextColor(Color(61, 173, 61))
	lbl2:SetFont("ZB_TDM_DESC")
	lbl2:SetSize(0, ScrH() * 0.02)

	function lbl2:Think()
		self:SetText("Cash: $" .. LocalPlayer():GetNWInt("TDM_Money", 0))
	end
end

net.Receive("s2_open_buymenu", function()
	OpenBuyMenu()
end)

TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil