MODE.name = "magic"

local MODE = MODE
local StartTime = 0
local PointsProgress = {}
local MinistryArrived = false
local MinistryNoticeEnd = 0

net.Receive("MAGIC_start",function()
	StartTime = CurTime()
	MinistryArrived = false
	MinistryNoticeEnd = 0

	timer.Simple(.5,function()
		local url = (LocalPlayer():Team() == 1)
			and "https://github.com/Milky182828/MILKY/raw/refs/heads/master/blissaniesgarden-everyone-is-dumb-animation-meme-audio-themp3info_cqZErwEs.mp3"
			or  "https://github.com/Milky182828/MILKY/raw/refs/heads/master/neizvesten-mazie-dumb-dumb-lyrics-everyone-is-dumb-tiktok-song-skysoundcc_RshSoCY7.mp3"

		sound.PlayURL(url, "noplay", function(chan)
			if IsValid(chan) then
				chan:SetVolume(2)
				chan:Play()
			end
		end)
	end)
	zb.RemoveFade()
	PointsProgress = {}
end)

net.Receive("MAGIC_ministry_spawn", function()
	MinistryArrived = true
	MinistryNoticeEnd = CurTime() + 8
	surface.PlaySound("snd_jack_hmcd_policesiren.wav")
end)

local respawntime = CurTime()

net.Receive("MAGIC_respawn",function()
	respawntime = net.ReadFloat() + 5
	hook.Add("HUDPaint","_Respawn",function()
		if respawntime < CurTime() then hook.Remove("HUDPaint","Respawn") return end
		if lply:Alive() then return end
		local fade = math.Clamp(respawntime - CurTime(),0,1)
		draw.SimpleText("Возрождение через "..string.FormattedTime(respawntime - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.8, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end)
end)

local teams = {
	[0] = {
		objective = "Вы — Верховный маг. Видите фиолетового долбоёба — убейте. Это чернокнижник.",
		name = "Верховный маг",
		color1 = Color(120, 190, 255),
		color2 = Color(120, 190, 255)
	},
	[1] = {
		objective = "Вы — Чернокнижник. Видите старого пердуна — ебните его. Это верховный маг.",
		name = "Чернокнижник",
		color1 = Color(190, 80, 255),
		color2 = Color(190, 80, 255)
	},
	[2] = {
		objective = "Вы — Министерство света. Ваша задача — задержать всех, кто ещё остался в живых.",
		name = "Министерство света",
		color1 = Color(255, 230, 120),
		color2 = Color(255, 230, 120)
	},
}

function MODE:RenderScreenspaceEffects()
	if StartTime + 7.5 < CurTime() then return end
	local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

	surface.SetDrawColor(0,0,0,255 * fade)
	surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

net.Receive("MAGIC_PointsUpdate",function()
	PointsProgress = net.ReadTable() or {}
end)

local hohColor = Color(190, 80, 255, 105)
local wagColor = Color(120, 190, 255, 105)
local bgColor = Color(0,0,0,155)
local sizeH = ScreenScale(8)
local sizeW = ScreenScale(10)

function MODE:HUDPaint()
	local i = -#PointsProgress/2
	for n,points in pairs(PointsProgress) do
		local pos = points[2]:ToScreen()
		local posH = sizeH
		local posW = pos.x
		draw.RoundedBox(0,posW,posH-sizeH*math.abs(points[1]/100),sizeW,sizeH*math.abs(points[1]/100),points[1] < 0 and hohColor or wagColor)
		draw.RoundedBox(0,posW,posH-sizeH,sizeW,sizeH,bgColor)
		draw.DrawText(string.Left(n,1),"ZCity_Tiny", posW + sizeW/2 - 1,posH-sizeH,color_white,TEXT_ALIGN_CENTER)
	end

	if lply:Alive() then
		local timeBeforeMinistry = StartTime + 120 - CurTime()
		if not MinistryArrived and timeBeforeMinistry > 0 then
			local text = "Министерство света прибудет через: " .. string.FormattedTime(timeBeforeMinistry, "%02i:%02i")
			draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.95 - 2, Color(255, 235, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	if MinistryNoticeEnd > CurTime() then
		local fade = math.Clamp(MinistryNoticeEnd - CurTime(), 0, 1)
		draw.SimpleText("Министерство света прибыло", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.18, Color(255, 235, 120, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if lply:Alive() and lply:Team() == 2 then
			draw.SimpleText("Задержите всех выживших", "ZB_HomicideMedium", sw * 0.5, sh * 0.24, Color(255, 235, 120, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if StartTime + 8.5 < CurTime() then return end
	if not lply:Alive() then return end
	zb.RemoveFade()

	local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
	local data = teams[team_]
	if not data then return end

	draw.SimpleText("OT-City | Магическая битва", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(150, 210, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Rolename = data.name
	local ColorRole = data.color1
	ColorRole.a = 255 * fade
	draw.SimpleText("Вы "..Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Objective = data.objective
	local ColorObj = data.color2
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local CreateEndMenu

net.Receive("MAGIC_roundend",function()
	CreateEndMenu()
end)

local colGray = Color(85,85,85,255)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)

local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

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

	local sizeX,sizeY = ScrW() / 2.5 ,ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2,ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX,posY)
	hmcdEndMenu:SetSize(sizeX,sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton",hmcdEndMenu)
	closebutton:SetPos(5,5)
	closebutton:SetSize(ScrW() / 20,ScrH() / 30)
	closebutton:SetText("")

	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize("Закрыть")
		surface.SetTextPos(lengthX - lengthX/1.1, 4)
		surface.DrawText("Закрыть")
	end

	hmcdEndMenu.Paint = function(self,w,h)
		BlurBackground(self)

		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize("Игроки:")
		surface.SetTextPos(w / 2 - lengthX/2,20)
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

	for i,ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton",DScrollPanel)
		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self,w,h)
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r,col1.g,col1.b,col1.a)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(col2.r,col2.g,col2.b,col2.a)
			surface.DrawRect(0,h/2,w,h/2)

			local col = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "Игрок вышел")

			surface.SetTextColor(0,0,0,255)
			surface.SetTextPos(w / 2 + 1,h/2 - lengthY/2 + 1)
			surface.DrawText(ply:GetPlayerName() or "Игрок вышел")

			surface.SetTextColor(col.r,col.g,col.b,col.a)
			surface.SetTextPos(w / 2,h/2 - lengthY/2)
			surface.DrawText(ply:GetPlayerName() or "Игрок вышел")

			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "Игрок вышел")
			surface.SetTextPos(15,h/2 - lengthY/2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - погиб" or "")) or "Игрок вышел")

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:Frags() or 0)
			surface.SetTextPos(w - lengthX -15,h/2 - lengthY/2)
			surface.DrawText(ply:Frags() or 0)
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "Нельзя открыть профиль бота") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
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
