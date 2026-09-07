local MODE = MODE
MODE.name = "shooter"

local TITLE = "Ночной вынос"
local song
local songfade = 0
local song2
local song2fade = 0
local ashStarted = false
local roundEnding = false

net.Receive("criresp_start", function()
	surface.PlaySound("shooterround.mp3")
	ashStarted = false
	roundEnding = false
	if IsValid(song2) then song2:Stop() song2 = nil end
	song2fade = 0
	timer.Simple(0.2, function()
		sound.PlayFile("sound/theyouthinmyblood.mp3", "mono noblock", function(station)
			if IsValid(station) then
				station:Play()
				song = station
				songfade = 1
			end
		end)
	end)
end)

local teams = {
	[0] = {
		objective = "Приехать поздно, но сделать вид, что так и было задумано.",
		name = "Группа зачистки",
		color1 = Color(68, 10, 255),
		color2 = Color(68, 10, 255)
	},
	[1] = {
		objective = "Лутайся, прячься, не геройствуй и не умри как NPC из катсцены.",
		name = "Выживший",
		color1 = Color(15, 228, 129),
		color2 = Color(20, 181, 209)
	},
	[2] = {
		objective = "Твоя задача простая: превратить раунд в криминальную новостную сводку.",
		name = "Мясник",
		color1 = Color(228, 49, 49),
		color2 = Color(228, 49, 49)
	},
}

local function getRoleInfo()
	local fallback = teams[lply:Team()] or teams[1]
	local roleName = lply:GetNWString("ShooterRoleName", "")
	local roleDesc = lply:GetNWString("ShooterRoleDesc", "")
	local roleType = lply:GetNWString("ShooterRoleType", "")

	local col1 = fallback.color1
	local col2 = fallback.color2

	if roleType == "shooter" then
		col1 = Color(228, 49, 49)
		col2 = Color(228, 49, 49)
	elseif roleType == "victim" then
		col1 = Color(15, 228, 129)
		col2 = Color(20, 181, 209)
	elseif roleType == "swat" then
		col1 = Color(68, 10, 255)
		col2 = Color(68, 10, 255)
	end

	return {
		name = roleName ~= "" and roleName or fallback.name,
		objective = roleDesc ~= "" and roleDesc or fallback.objective,
		color1 = col1,
		color2 = col2
	}
end

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local posadd = 0

function MODE:HUDPaint()
	local sw, sh = ScrW(), ScrH()
	local arriveShooter = zb.ROUND_START + 60
	local introFade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

	if IsValid(song) and CurTime() > arriveShooter then
		if songfade <= 0.01 then
			song:Stop()
			song = nil
		else
			songfade = Lerp(0.05, songfade, 0)
			song:SetVolume(songfade)
		end
	end

	if (not ashStarted) and (not IsValid(song)) and CurTime() > arriveShooter then
		ashStarted = true
		sound.PlayFile("sound/ashiswatching.mp3", "mono noblock", function(station)
			if IsValid(station) then
				station:Play()
				if station.SetTime then station:SetTime(60) end
				station:SetVolume(0)
				song2 = station
				song2fade = 0
			end
		end)
	end

	if IsValid(song2) and not roundEnding then
		song2fade = Lerp(0.02, song2fade, 1)
		song2:SetVolume(song2fade)
	end

	if roundEnding then
		if IsValid(song) then
			songfade = Lerp(0.05, songfade, 0)
			song:SetVolume(songfade)
			if songfade <= 0.01 then song:Stop() song = nil end
		end
		if IsValid(song2) then
			song2fade = Lerp(0.05, song2fade, 0)
			song2:SetVolume(song2fade)
			if song2fade <= 0.01 then song2:Stop() song2 = nil end
		end
	end

	if zb.ROUND_START + 60 > CurTime() then
		posadd = Lerp(FrameTime() * 5, posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
		local blink = math.sin(CurTime() * 3) >= 0 and Color(255,0,0) or Color(0,0,0)
		local text = "Мясник выйдет в эфир через: " .. string.FormattedTime(zb.ROUND_START + 60 - CurTime(), "%02i:%02i")
		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.91, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.91) - 2, blink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 240 > CurTime() then
		posadd = Lerp(FrameTime() * 5, posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
		local color = Color(255 * -math.sin(CurTime() * 3), 25, 255 * math.sin(CurTime() * 3))
		local text = string.FormattedTime(zb.ROUND_START + 240 - CurTime(), "%02i:%02i") .. " До зачистки"
		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if lply:Team() == 2 then
		local arrive = arriveShooter
		local t = CurTime()
		local active = t < arrive
		local fadeout = math.Clamp((arrive + 1.5 - t) / 1.5, 0, 1)
		local revealEnd = zb.ROUND_START + 8.5
		local roleInfo = getRoleInfo()
		if (active or fadeout > 0) and t >= revealEnd then
			local alpha = active and 255 or math.floor(255 * fadeout)
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(0, 0, sw, sh)
			local fade = active and 1 or fadeout
			local colRed = Color(228, 49, 49, 255 * fade)
			local colWhite = Color(255, 255, 255, 255 * fade)
			draw.SimpleText(roleInfo.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.4, colRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(roleInfo.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.5, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Стрелять по всем можно будет через " .. string.FormattedTime(math.max(arrive - t, 0), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.6, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if zb.ROUND_START + 8.5 > CurTime() then
		if (not lply:Alive()) and lply:Team() ~= 0 then return end
		local roleInfo = getRoleInfo()
		draw.SimpleText(TITLE, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * introFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local colorRole = roleInfo.color1
		colorRole.a = 255 * introFade
		draw.SimpleText("Ты: " .. roleInfo.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local colorObj = roleInfo.color2
		colorObj.a = 255 * introFade
		draw.SimpleText(roleInfo.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if hg.PluvTown.Active and introFade > 0 then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * introFade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))
		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * introFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu

net.Receive("cri_roundend", function()
	roundEnding = true
	CreateEndMenu(net.ReadBool())
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function(whowin)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	hmcdEndMenu = vgui.Create("ZFrame")
	surface.PlaySound((whowin == 1) and "zbattle/criresp/failedSWAT.mp3" or "ambient/alarms/warningbell1.wav")

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

	hmcdEndMenu.PaintOver = function(self, w, h)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Игроки")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Игроки")
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for _, ply in player.Iterator() do
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
			local displayName = ply:GetPlayerName() or "Игрок вышел"
			local lengthX, lengthY = surface.GetTextSize(displayName)
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(displayName)
			surface.SetTextColor(plyCol.r, plyCol.g, plyCol.b, plyCol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(displayName)
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText(ply:Name() .. (ply:GetNetVar("handcuffed", false) and " - нейтрализован" or (not ply:Alive() and " - мёртв") or ""))
			local fragText = tostring(ply:Frags() or 0)
			local fragX, fragY = surface.GetTextSize(fragText)
			surface.SetTextPos(w - fragX - 15, h / 2 - fragY / 2)
			surface.DrawText(fragText)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "боту стим не завезли")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end
