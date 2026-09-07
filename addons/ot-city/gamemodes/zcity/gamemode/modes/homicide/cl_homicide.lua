local MODE = MODE
MODE.name = "hmcd"

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--//

MODE.TypeSounds = {
	["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gunfreezone"] = "snd_jack_hmcd_panic.mp3" ,
	["suicidelunatic"] = "zbattle/jihadmode.mp3",
	["wildwest"] = "snd_jack_hmcd_wildwest.mp3",
	["supermario"] = "snd_jack_hmcd_psycho.mp3"
}

local fade = 0

net.Receive("HMCD_RoundStart", function()
	for i, ply in player.Iterator() do
		ply.isTraitor = false
		ply.isGunner = false
	end

	lply = lply or LocalPlayer()

	lply.isTraitor = net.ReadBool()
	lply.isGunner = net.ReadBool()
	MODE.Type = net.ReadString()

	local screen_time_is_default = net.ReadBool()

	lply.SubRole = net.ReadString()
	lply.MainTraitor = net.ReadBool()
	MODE.TraitorWord = net.ReadString()
	MODE.TraitorWordSecond = net.ReadString()
	MODE.TraitorExpectedAmt = net.ReadUInt(MODE.TraitorExpectedAmtBits)
	StartTime = CurTime()
	MODE.TraitorsLocal = {}

	if HMCD_ClearTraitorMarkers then
		HMCD_ClearTraitorMarkers()
	end

	if lply.isTraitor and screen_time_is_default then
		if MODE.TraitorExpectedAmt == 1 then
			chat.AddText("Ты один на этой миссии")
		else
			chat.AddText("Всего предателей: " .. MODE.TraitorExpectedAmt)
			chat.AddText("Ваши секретные слова для связи: \"" .. MODE.TraitorWord .. "\" and \"" .. MODE.TraitorWordSecond .. "\".")
		end

		for key = 1, MODE.TraitorExpectedAmt do
		    local traitor_info = {
		        net.ReadColor(false),
		        net.ReadString(),
		        net.ReadString()
		    }

		    MODE.TraitorsLocal[#MODE.TraitorsLocal + 1] = traitor_info

		    if MODE.TraitorExpectedAmt > 1 then
		        chat.AddText(traitor_info[1], "\t" .. traitor_info[2])
		    end
		end

		if HMCD_SetTraitorMarkersFromList then
		    HMCD_SetTraitorMarkersFromList(MODE.TraitorsLocal)
		end

	end

	lply.Profession = net.ReadString()
	if (not lply.Profession or lply.Profession == "") and lply.GetNWString then
		lply.Profession = lply:GetNWString("HMCD_CurrentProfession", "")
	end

	if MODE.RoleChooseRoundTypes[MODE.Type] and not screen_time_is_default then
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.RoleChooseRoundStartTime
	else
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.DefaultRoundStartTime
	end

	MODE.RoleEndedChosingState = screen_time_is_default

	if screen_time_is_default then
		if istable(MODE.TypeSounds[MODE.Type]) then
			surface.PlaySound(table.Random(MODE.TypeSounds[MODE.Type]))
		else
			surface.PlaySound(MODE.TypeSounds[MODE.Type])
		end
	end

	if lply.isTraitor then
		timer.Simple(0.05, function()
			if IsValid(LocalPlayer()) and LocalPlayer().isTraitor and HMCD_SetTraitorMarkersFromList and istable(MODE.TraitorsLocal) then
				HMCD_SetTraitorMarkersFromList(MODE.TraitorsLocal)
			end
		end)

		timer.Simple(0.2, function()
			if IsValid(LocalPlayer()) and LocalPlayer().isTraitor then
				net.Start("HMCD_RequestTraitorMarkers")
				net.SendToServer()
			end
		end)

		timer.Simple(1, function()
			if IsValid(LocalPlayer()) and LocalPlayer().isTraitor then
				net.Start("HMCD_RequestTraitorMarkers")
				net.SendToServer()
			end
		end)

		timer.Simple(2, function()
			if IsValid(LocalPlayer()) and LocalPlayer().isTraitor then
				net.Start("HMCD_RequestTraitorMarkers")
				net.SendToServer()
			end
		end)
	end

	fade = 0
end)

MODE.TypeNames = {
	["standard"] = "Стандарт",
	["soe"] = "Чрезвычайное положение",
	["gunfreezone"] = "Финский нож (зона без оружия)",
	["suicidelunatic"] = "Убийственные лунатики",
	["wildwest"] = "Дикий запад",
	["supermario"] = "БЛЯДСКИЙ СУПЕРМАРИО"
}

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")

local font = function()
	local usefont = "Bahnschrift"

	if hg_font:GetString() ~= "" then
		usefont = hg_font:GetString()
	end

	return usefont
end

surface.CreateFont("ZB_HomicideSmall", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMedium", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMediumLarge", {
	font = font(),
	size = ScreenScale(25),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideLarge", {
	font = font(),
	size = ScreenScale(30),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideHumongous", {
	font = font(),
	size = 255,
	weight = 400,
	antialias = true
})

MODE.TypeObjectives = {}

MODE.TypeObjectives.soe = {
	traitor = {
		objective = "У вас в карманах спрятаны предметы, яды, взрывчатка и оружие. Убейте всех,пока вас не вычислили",
		name = "Предатель",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Вы самаритянин с оружием. Найдите и убейте предателя,пока все не пошло по пизде.",
		name = "Невиновный",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Вы невинный, полагаетесь только на себя, но общаетесь с толпой, чтобы усложнить работу предателя.",
		name = "Невиновный",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.standard = {
	traitor = {
		objective = "У вас есть все,что нужно для массовой резни. Сделай что тебе сказано",
		name = "Маньяк",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Вы - случайный прохожий, у которого спрятано огнестрельное оружие. Вы поставили перед собой задачу помочь полиции быстрее найти преступника.",
		name = "Прохожий",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = " Вы-случайный прохожий,видевший преступление. Берегите себя",
		name = "Прохожий",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.wildwest = {
	traitor = {
		objective = "Этот город слишком мал для нас всех...",
		name = "Убийца",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Вы шериф этого городка. Найдите и убейте беззаконную суку",
		name = "Шериф",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Ты здесь чтобы вершить правосудие. Найдите убийцу и завалите его",
		name = "Ковбой",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},
}

MODE.TypeObjectives.gunfreezone = {
	traitor = {
		objective = "У тебя есть все. Ёбни уже всех",
		name = "Маньяк",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Ты свидетель преступления со спрятанным оружием. Тебе стоит беспокоиться о своей жизне",
		name = "Прохожий",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Ты свидетель преступления. Береги себя",
		name = "Прохожий",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.suicidelunatic = {
	traitor = {
		objective = "Во имя Аллаха! Убей всех кафиров!",
		name = "Шахид",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Убей этих исламистов.",
		name = "Невиновный",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Тебе нужно выжить в этом ужасе.",
		name = "Невиновный",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.supermario = {
	traitor = {
		objective = "Я ебал это переводить,нахуй нам этот марио",
		name = "Traitor Mario",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Вы Марио. Остановите убийцу",
		name = "Марио-Герой",
		color1 = Color(158,0,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Вы Марио-прохожий,вычислите убийцу и затопчите его!",
		name = "Марио-прохожий",
		color1 = Color(0,120,190)
	},
}

function MODE:RenderScreenspaceEffects()
	local fade_end_time = MODE.DynamicFadeScreenEndTime or 0
	local time_diff = fade_end_time - CurTime()

	if time_diff > 0 then
		zb.RemoveFade()

		local fade_value = math.min(time_diff / MODE.FadeScreenTime, 1)

		surface.SetDrawColor(0, 0, 0, 255 * fade_value)
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
	end
end

local handicap = {
	[1] = "You are handicapped: your right leg is broken.",
	[2] = "You are handicapped: you are suffering from severe obesity.",
	[3] = "You are handicapped: you are suffering from hemophilia.",
	[4] = "You are handicapped: you are physically incapacitated."
}

function MODE:HUDPaint()
	if not MODE.Type or not MODE.TypeObjectives[MODE.Type] then return end
	if lply:Team() == TEAM_SPECTATOR then return end
	if StartTime + 12 < CurTime() then return end

	fade = Lerp(FrameTime() * 1, fade, math.Clamp(StartTime + 5 - CurTime(), -2, 2))

	draw.SimpleText("Homicide | " .. (MODE.TypeNames[MODE.Type] or "Unknown"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Rolename = (lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.name) or (lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.name) or MODE.TypeObjectives[MODE.Type].innocent.name
	local ColorRole = (lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color1) or (lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color1) or MODE.TypeObjectives[MODE.Type].innocent.color1
	ColorRole.a = 255 * fade

	local color_role_innocent = MODE.TypeObjectives[MODE.Type].innocent.color1
	color_role_innocent.a = 255 * fade

	local color_white_faded = Color(255, 255, 255, 255 * fade)
	color_white_faded.a = 255 * fade

	draw.SimpleText("Вы " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local cur_y = sh * 0.5

	if lply.SubRole and lply.SubRole ~= "" then
		cur_y = cur_y + ScreenScale(20)
		draw.SimpleText("" .. ((MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Name or lply.SubRole) or lply.SubRole), "ZB_HomicideMediumLarge", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if lply.isTraitor then
		cur_y = cur_y + ScreenScale(20)
		MODE.TraitorsLocal = MODE.TraitorsLocal or {}

		if #MODE.TraitorsLocal > 1 then
			draw.SimpleText("Предатели:", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			for _, traitor_info in ipairs(MODE.TraitorsLocal) do
				local traitor_color = Color(traitor_info[1].r, traitor_info[1].g, traitor_info[1].b, 255 * fade)
				cur_y = cur_y + ScreenScale(15)
				draw.SimpleText(traitor_info[2], "ZB_HomicideMedium", sw * 0.5, cur_y, traitor_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		else
			draw.SimpleText("Секретные слова:", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)
			draw.SimpleText("\"" .. MODE.TraitorWord .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)
			draw.SimpleText("\"" .. MODE.TraitorWordSecond .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if lply.Profession and lply.Profession ~= "" then
		cur_y = cur_y + ScreenScale(20)
		draw.SimpleText("Профессия: " .. ((MODE.Professions[lply.Profession] and MODE.Professions[lply.Profession].Name or lply.Profession) or lply.Profession), "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if handicap[lply:GetLocalVar("karma_sickness", 0)] then
		cur_y = cur_y + ScreenScale(20)
		draw.SimpleText(handicap[lply:GetLocalVar("karma_sickness", 0)], "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local Objective = (lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.objective) or (lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.objective) or MODE.TypeObjectives[MODE.Type].innocent.objective

	if lply.SubRole and lply.SubRole ~= "" then
		if MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Objective then
			Objective = MODE.SubRoles[lply.SubRole].Objective
		end
	end

	if not MODE.RoleEndedChosingState then
		Objective = "Раунд начинается..."
	end

	local ColorObj = (lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color2) or (lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color2) or MODE.TypeObjectives[MODE.Type].innocent.color2 or Color(255, 255, 255)
	ColorObj.a = 255 * fade

	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))
		draw.SimpleText("ГДЕ-ТО В ПЛЫВТАУНЕ", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu

net.Receive("hmcd_roundend", function()
	local traitors, gunners = {}, {}

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local traitor = net.ReadEntity()
		traitors[key] = traitor

		if IsValid(traitor) then
			traitor.isTraitor = true
		end
	end

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local gunner = net.ReadEntity()
		gunners[key] = gunner

		if IsValid(gunner) then
			gunner.isGunner = true
		end
	end

	timer.Simple(2.5, function()
		lply.isPolice = false
		lply.isTraitor = false
		lply.isGunner = false
		lply.MainTraitor = false
		lply.SubRole = nil
		lply.Profession = nil
	end)

	CreateEndMenu(traitors)
end)

net.Receive("hmcd_announce_traitor_lose", function()
	local traitor = net.ReadEntity()
	local traitor_alive = net.ReadBool()

	if IsValid(traitor) then
		chat.AddText(color_white, "Предатель", traitor:GetPlayerColor():ToColor(), traitor:GetPlayerName() .. ", " .. traitor:Nick(), color_white, " был " .. (traitor_alive and "арестован." or "ликвидирован."))
	end
end)

local colGray = Color(85,85,85)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)
local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)
local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function(traitors)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	traitors = istable(traitors) and traitors or {}

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

	if not IsValid(hmcdEndMenu) then return end

	local players = {}
	local traitorNames = {}

	for _, traitor in ipairs(traitors) do
		if IsValid(traitor) then
			traitorNames[#traitorNames + 1] = traitor:GetPlayerName() .. " (" .. traitor:Nick() .. ")"
		end
	end

	local traitorText = #traitorNames > 0 and table.concat(traitorNames, ", ") or "unknown"

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not IsValid(ply) then return end

		players[#players + 1] = {
			nick = ply:Nick(),
			name = ply:GetPlayerName(),
			isTraitor = ply.isTraitor,
			isGunner = ply.isGunner,
			incapacitated = ply.organism and ply.organism.otrub,
			alive = ply:Alive(),
			col = ply:GetPlayerColor():ToColor(),
			frags = ply:Frags(),
			steamid = ply:IsBot() and "BOT" or ply:SteamID64(),
		}
	end

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
		local lengthX = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.PaintOver = function(self, w, h)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local text = "Предатели: " .. traitorText
		local lengthX = surface.GetTextSize(text)
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText(text)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for i, info in ipairs(players) do
		local but = vgui.Create("DButton", DScrollPanel)

		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")

		but.Paint = function(self, w, h)
			local col1 = (info.isTraitor and colRed) or (info.alive and colBlue) or colGray
			local col2 = info.isTraitor and (info.alive and colRedUp or colSpect1) or ((info.alive and not info.incapacitated) and colBlueUp) or colSpect1
			local name = info.nick

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local player_color = info.col
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(name)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(name)

			surface.SetTextColor(player_color.r, player_color.g, player_color.b, player_color.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(name)

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)

			local info_text = info.name .. ((!info.alive and " - мертв") or (info.incapacitated and " - без сознания") or "")
			local _, info_h = surface.GetTextSize(info_text)

			surface.SetTextPos(15, h / 2 - info_h / 2)
			surface.DrawText(info_text)

			surface.SetFont("ZB_InterfaceMediumLarge")
			local frag_w, frag_h = surface.GetTextSize(info.frags)
			surface.SetTextPos(w - frag_w - 15, h / 2 - frag_h / 2)
			surface.DrawText(info.frags)
		end

		function but:DoClick()
			if info.steamid == "BOT" then
				chat.AddText(Color(255, 0, 0), "Это просто бот блять.")
				return
			end

			gui.OpenURL("https://steamcommunity.com/profiles/" .. info.steamid)
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
end

net.Receive("HMCD(StartPlayersRoleSelection)", function()
	local role = net.ReadString()

	hg.SelectPlayerRole(role)
end)

function hg.SelectPlayerRole(role, mode)
	role = role or "Traitor"
	mode = mode or "soe"

	if IsValid(VGUI_HMCD_RolePanelList) then
		VGUI_HMCD_RolePanelList:Remove()
	end

	if MODE.RoleChooseRoundTypes[mode] then
		VGUI_HMCD_RolePanelList = vgui.Create("HMCD_RolePanelList")
		VGUI_HMCD_RolePanelList.RolesIDsList = MODE.RoleChooseRoundTypes[mode][role]
		VGUI_HMCD_RolePanelList.Mode = mode
		VGUI_HMCD_RolePanelList:SetSize(screen_scale_2(700), screen_scale_2(300))
		VGUI_HMCD_RolePanelList:Center()
		VGUI_HMCD_RolePanelList:InvalidateParent(false)
		VGUI_HMCD_RolePanelList:Construct()
		VGUI_HMCD_RolePanelList:MakePopup()
	end
end

net.Receive("HMCD(EndPlayersRoleSelection)", function()
	if IsValid(VGUI_HMCD_RolePanelList) then
		VGUI_HMCD_RolePanelList:Remove()
	end
end)

net.Receive("HMCD(SetSubRole)", function()
	lply.SubRole = net.ReadString()
end)


hook.Add("Think", "HMCD_CurrentProfessionSync", function()
    local ply = LocalPlayer()
    if IsValid(ply) and ply.GetNWString then
        local prof = ply:GetNWString("HMCD_CurrentProfession", "")
        if prof ~= "" then ply.Profession = prof end
    end
end)
