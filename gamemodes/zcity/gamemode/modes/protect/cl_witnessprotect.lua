MODE.name = "witnessprotect"

local MODE = MODE
local TITLE = "OT-City | Программа защиты свидетелей"
local StartTime = 0
local MafiaArrivalTime = 0
local MafiaArrived = false
local WitnessesAlive = 2
local WitnessTotal = 2
local roundEnding = false
local noticeText = nil
local noticeUntil = 0

local teams = {
	[0] = {
		name = "Полиция",
		objective = "Закрыть свидетелей собой, удержать дом и не дать мафии закончить дело.",
		color1 = Color(40, 120, 255),
		color2 = Color(40, 120, 255),
	},
	[1] = {
		name = "Свидетель",
		objective = "Главная задача — дышать. Не геройствуй, ныкайся за копами и живи.",
		color1 = Color(255, 210, 70),
		color2 = Color(255, 210, 70),
	},
	[2] = {
		name = "Мафиози",
		objective = "Приехать, сломать охрану и закрыть рты свидетелям навсегда.",
		color1 = Color(180, 40, 40),
		color2 = Color(180, 40, 40),
	},
}

local function setNotice(text, duration)
	noticeText = text
	noticeUntil = CurTime() + (duration or 6)
end

local function getRoleInfo()
	local lply = LocalPlayer()
	local teamData = teams[lply:Team()] or teams[0]
	local roleName = lply:GetNWString("WitnessProtectRoleName", "")
	local roleDesc = lply:GetNWString("WitnessProtectRoleDesc", "")

	return {
		teamName = teamData.name,
		roleName = roleName ~= "" and roleName or teamData.name,
		roleDesc = roleDesc ~= "" and roleDesc or teamData.objective,
		color1 = teamData.color1,
		color2 = teamData.color2,
	}
end

net.Receive("WITPROTECT_start", function()
	StartTime = CurTime()
	WitnessTotal = net.ReadUInt(4)
	WitnessesAlive = WitnessTotal
	MafiaArrivalTime = StartTime + 35
	MafiaArrived = false
	roundEnding = false
	zb.RemoveFade()
	setNotice("Свидетели под охраной. Держите позиции.", 4)
end)

net.Receive("WITPROTECT_status", function()
	WitnessesAlive = net.ReadUInt(4)
	MafiaArrived = net.ReadBool()
	local arrivalLeft = net.ReadFloat()
	if not MafiaArrived then
		MafiaArrivalTime = CurTime() + math.max(0, arrivalLeft)
	end
end)

net.Receive("WITPROTECT_mafia_arrival", function()
	MafiaArrived = true
	MafiaArrivalTime = CurTime()
	surface.PlaySound("snd_jack_hmcd_policesiren.wav")
	setNotice("Мафия на месте. Начинается мясо.", 6)
end)

net.Receive("WITPROTECT_witness_down", function()
	local name = net.ReadString()
	WitnessesAlive = net.ReadUInt(4)
	local text = "Свидетель " .. name .. " был убит"
		chat.AddText(Color(255, 90, 90), text)
	setNotice(text, 7)
end)

net.Receive("WITPROTECT_roundend", function()
	roundEnding = true
	local winner = net.ReadUInt(3)
	if winner == 2 then
		setNotice("Мафия закрыла вопрос. Свидетели мертвы.", 8)
	else
		setNotice("Полиция удержала свидетелей. Дело живёт.", 8)
	end
end)

function MODE:RenderScreenspaceEffects()
	if StartTime + 7.5 < CurTime() then return end
	local fade = math.Clamp(StartTime + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	local lply = LocalPlayer()
	local sw, sh = ScrW(), ScrH()

	if IsValid(lply) and lply:Alive() and CurTime() < StartTime + 8.5 then
		zb.RemoveFade()
		local fade = math.Clamp(StartTime + 8 - CurTime(), 0, 1)
		local info = getRoleInfo()

		draw.SimpleText(TITLE, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(180, 220, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local colorRole = Color(info.color1.r, info.color1.g, info.color1.b, 255 * fade)
		draw.SimpleText("Сторона: " .. info.teamName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.44, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Роль: " .. info.roleName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.54, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local colorObj = Color(info.color2.r, info.color2.g, info.color2.b, 255 * fade)
		draw.DrawText(info.roleDesc, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.74, colorObj, TEXT_ALIGN_CENTER)
	end

	local witnessText = "Живых свидетелей: " .. tostring(WitnessesAlive) .. "/" .. tostring(WitnessTotal)
	draw.SimpleText(witnessText, "ZB_HomicideMedium", sw * 0.02, sh * 0.08, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(witnessText, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.08 - 2, Color(255, 210, 70), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	if not MafiaArrived then
		local timeBefore = math.max(0, MafiaArrivalTime - CurTime())
		local text = "Мафиози приедут через: " .. string.FormattedTime(timeBefore, "%02i:%02i")
		local pulse = (math.sin(CurTime() * 3) + 1) / 2
		local col = Color(255, 120 + 80 * pulse, 120 + 80 * pulse)
		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02, sh * 0.12, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.12 - 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	else
		draw.SimpleText("Мафиози уже в здании", "ZB_HomicideMedium", sw * 0.02, sh * 0.12, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Мафиози уже в здании", "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.12 - 2, Color(180, 40, 40), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if noticeText and noticeUntil > CurTime() then
		local fade = math.Clamp(noticeUntil - CurTime(), 0, 1)
		draw.SimpleText(noticeText, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.18, Color(255, 240, 200, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:RoundStart()
	noticeText = nil
	noticeUntil = 0
	if roundEnding then
		roundEnding = false
	end
end
