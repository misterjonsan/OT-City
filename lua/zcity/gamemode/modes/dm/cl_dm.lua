MODE.name = "dm"

local MODE = MODE

local radius = nil
local mapsize = 7500

local roundend = false

local snds = {
	"https://github.com/Milky182828/MILKY/raw/refs/heads/master/Buckshot_Roulette_-_Before_Every_Load_RuditheRaven_Remix_(SkySound.cc).mp3"
}

local endsnd = "https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/kvlgywwwnt/13.%20Escape.mp3"

local musicMode = "none"

local function startRoundMusic()
	musicMode = "round"

	if IsValid(dmendmusic) then dmendmusic:Stop() dmendmusic = nil end
	if IsValid(dmmusic) then dmmusic:Stop() dmmusic = nil end

	local snd = snds[math.random(#snds)]

	sound.PlayURL(snd, "mono noblock noplay", function(station, errID, err)
		if not IsValid(station) then
			print(errID, err)
			return
		end

		if musicMode ~= "round" then
			station:Stop()
			return
		end

		station:EnableLooping(true)
		station:SetVolume(GetConVar("snd_musicvolume"):GetFloat())
		station:Play()

		dmmusic = station
	end)
end

local function startEndMusic()
	musicMode = "end"

	if IsValid(dmmusic) then dmmusic:Stop() dmmusic = nil end
	if IsValid(dmendmusic) then dmendmusic:Stop() dmendmusic = nil end

	sound.PlayURL(endsnd, "mono noblock noplay", function(station, errID, err)
		if not IsValid(station) then
			print(errID, err)
			return
		end

		if musicMode ~= "end" then
			station:Stop()
			return
		end

		station:EnableLooping(false)
		station:SetVolume(GetConVar("snd_musicvolume"):GetFloat())
		station:Play()

		dmendmusic = station
	end)
end

local function stopAllMusic()
	musicMode = "none"

	if IsValid(dmmusic) then dmmusic:Stop() end
	dmmusic = nil

	if IsValid(dmendmusic) then dmendmusic:Stop() end
	dmendmusic = nil
end

hook.Add("Think", "DM_MusicThink", function()
	local rnd = CurrentRound()
	if rnd and rnd.name ~= "dm" then
		if musicMode ~= "none" or IsValid(dmmusic) or IsValid(dmendmusic) then
			stopAllMusic()
		end
		return
	end

	local musicVol = GetConVar("snd_musicvolume"):GetFloat()

	if IsValid(dmmusic) and musicMode == "round" then
		dmmusic:SetVolume(musicVol)
	end

	if IsValid(dmendmusic) then
		if dmendmusic:GetState() == GMOD_CHANNEL_STOPPED then
			dmendmusic:Stop()
			dmendmusic = nil
			if musicMode == "end" then musicMode = "none" end
		else
			dmendmusic:SetVolume(musicVol)
		end
	end
end)


net.Receive("dm_start", function()
	roundend = false

	startRoundMusic()

	zb.RemoveFade()

	ZonePos = net.ReadVector()
	zonedistance = net.ReadFloat()

	surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
	sound.PlayFile("sound/ambient/energy/force_field_loop1.wav", "noblock", function(station, errCode, errStr)
		if (IsValid(station)) then
			zb.SoundStation = station

			station:Play()
			station:EnableLooping(true)
			station:SetVolume(0)
		end
	end)
end)

hook.Add("Think", "ZoneSoundThink", function()
	if CurrentRound() and CurrentRound().name ~= "dm" then return end
	local station = zb.SoundStation
	if not IsValid(station) then return end
	local radius = MODE.GetZoneRadius()
	local volume = math.Clamp((LocalPlayer():GetPos():Distance(ZonePos) - radius) + 200, 0, 200) / 200
	station:SetVolume(volume)
end)

local fighter = {
	objective = "Убей всех. И да, реально всех — друзей тут не завезли, только будущие записи в твоём фраг-листе.",
	name = "Боец",
	color1 = Color(0, 120, 190)
}

--local zonemodel = ClientsideModel("models/hunter/misc/sphere375x375.mdl",RENDERGROUP_TRANSLUCENT)
--zonemodel:SetNoDraw(true)
--zonemodel:SetMaterial("hmcd_dmzone")

local mat = Material("hmcd_dmzone")

local mapsize = 7500

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if (not bSkybox and not isDraw3DSkybox) then
		local radius = MODE.GetZoneRadius()
		render.SetMaterial(mat)
		render.DrawSphere(ZonePos, -radius, 60, 60, color_white)
	end
	--zonemodel:DrawModel()
end

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end

	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	if zb.ROUND_START + 20 > CurTime() then
		draw.SimpleText(string.FormattedTime(zb.ROUND_START + 20 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255, 55, 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end


	if not lply:Alive() then return end
	if zb.ROUND_START + 8.5 < CurTime() then return end
	zb.RemoveFade()
	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

	draw.SimpleText("OT-City | Каждый сам за себя", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Rolename = fighter.name
	local ColorRole = fighter.color1
	ColorRole.a = 255 * fade
	draw.SimpleText("Ты: " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Objective = fighter.objective
	local ColorObj = fighter.color1
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("ГДЕ-ТО В ПЛУВТАУНЕ", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu = nil
local wonply = nil

net.Receive("dm_end", function()
	local ent = net.ReadEntity()
	local most_violent_player = net.ReadEntity()

	if IsValid(most_violent_player) then
		most_violent_player.most_violent_player = true
	end

	wonply = nil
	if IsValid(ent) then
		ent.won = true
		wonply = ent
	end

	zb.SoundStation = nil
	roundend = CurTime()

	if (MODE.SoundStation and MODE.SoundStation:IsValid()) then
		MODE.SoundStation:Stop()

		MODE.SoundStation = nil
	end

	startEndMusic()

	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(217, 201, 99)
local colRedUp = Color(207, 181, 59)

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

	hmcdEndMenu.PaintOver = function(self, w, h)

		local txt = (wonply and wonply:GetPlayerName() or "Никто") .. " победил!"
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText(txt)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
			local col1 = ((ply.won or ply.most_violent_player) and colRed) or (ply:Alive() and colBlue) or colGray
			local col2 = ((ply.won or ply.most_violent_player) and colRedUp) or (ply:Alive() and colBlueUp) or colSpect1

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local col = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "Слился...")

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "Слился...")

			surface.SetTextColor(col.r, col.g, col.b, col.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "Слился...")


			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "Слился...")
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (ply.most_violent_player and " - МВП" or (not ply:Alive() and " - труп" or ""))))

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:Frags() or "Слился...")
			surface.SetTextPos(w - lengthX - 15, h / 2 - lengthY / 2)
			surface.DrawText(ply:Frags() or "Слился...")
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255, 0, 0), "не, так нельзя") return end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	for i, ply in player.Iterator() do
		ply.won = nil
		ply.most_violent_player = nil
	end

	if IsValid(dmendmusic) then
		dmendmusic:Stop()
		dmendmusic = nil
	end
	if musicMode == "end" then musicMode = "none" end

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end
