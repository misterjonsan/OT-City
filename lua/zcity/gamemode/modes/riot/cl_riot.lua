MODE.name = "riot"

local MODE = MODE

local skSirensPlayed = false
local RiotSound

net.Receive("riot_start", function()
	if RiotSound then
		RiotSound:Stop()
		RiotSound = nil
	end

	sound.PlayFile("sound/zbattle/riot.wav", "noplay", function(station)
		if IsValid(station) then
			station:SetVolume(6)
			station:Play()
			RiotSound = station
		end
	end)

	zb.RemoveFade()
end)

net.Receive("riot_swat_spawn", function()
	if not skSirensPlayed then
		surface.PlaySound("snd_jack_hmcd_policesiren.wav")
		skSirensPlayed = true
	end
end)

local teams = {
	[0] = {
		objective = "Создавать хаос, давить толпу и не дать силовикам быстро подавить бунт.",
		name = "Протестующий",
		color1 = Color(190, 0, 0),
		color2 = Color(190, 0, 0)
	},
	[1] = {
		objective = "Подавить беспорядки, удержать ситуацию под контролем и не дать протесту выйти из-под контроля.",
		name = "Вершитель правосудия",
		color1 = Color(0, 120, 190),
		color2 = Color(0, 120, 190)
	},
	[2] = {
		objective = "Прибыть на место, зачистить район и завершить то, что остальные не смогли.",
		name = "Следственный комитет",
		color1 = Color(120, 120, 255),
		color2 = Color(120, 120, 255)
	},
}

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	local sw, sh = ScrW(), ScrH()
	local startTime = zb.ROUND_START or CurTime()
	local skArrivalTime = startTime + 240

	if not lply:Alive() then return end

	if CurTime() < startTime + 8.5 then
		zb.RemoveFade()

		local fade = math.Clamp(startTime + 8 - CurTime(), 0, 1)
		local team_ = lply:Team()
		local teamData = teams[team_]

		draw.SimpleText("Homicide | Бунт", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if teamData then
			local roleColor = teamData.color1
			roleColor.a = 255 * fade
			draw.SimpleText("Вы: " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			local objColor = teamData.color2
			objColor.a = 255 * fade
			draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if hg.PluvTown.Active then
			surface.SetMaterial(hg.PluvTown.PluvMadness)
			surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
			surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

			draw.SimpleText("ГДЕ-ТО В ПЛАВТАУНЕ", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local timeBeforeSK = skArrivalTime - CurTime()
	if timeBeforeSK > 0 then
		local text = "Следственный комитет прибудет через: " .. string.FormattedTime(timeBeforeSK, "%02i:%02i")
		local pulse = (math.sin(CurTime() * 3) + 1) / 2
		local col = Color(255 * pulse, 255 * pulse, 255)

		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.95 - 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu

net.Receive("riot_roundend", function()
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

local colorBG = Color(55, 55, 55, 255)
local colorBGBlacky = Color(40, 40, 40, 255)

local blurMat = Material("pp/blurscreen")
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
		local lengthX, lengthY = surface.GetTextSize("Закрыть")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Закрыть")
	end

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)

		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Игроки:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Игроки:")

		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	function DScrollPanel:Paint(w, h)
		BlurBackground(self)

		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for i, ply in player.Iterator() do
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

			local plyCol = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local name = ply:GetPlayerName() or "Игрок вышел"
			local lengthX, lengthY = surface.GetTextSize(name)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(name)

			surface.SetTextColor(plyCol.r, plyCol.g, plyCol.b, plyCol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(name)

			local infoCol = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(infoCol.r, infoCol.g, infoCol.b, infoCol.a)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - погиб" or "")) or "Игрок вышел")

			local fragText = tostring(ply:Frags() or 0)
			local fragLenX, fragLenY = surface.GetTextSize(fragText)
			surface.SetTextPos(w - fragLenX - 15, h / 2 - fragLenY / 2)
			surface.DrawText(fragText)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "нет, так не получится")
				return
			end

			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	skSirensPlayed = false

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end