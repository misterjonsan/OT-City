if not CLIENT then return end

hg = hg or {}
hg.CPR = hg.CPR or {}

local C = hg.CPR

C.Voices = {
	"vo/breencast/br_welcome02.wav",
	"vo/breencast/br_welcome03.wav",
	"vo/breencast/br_welcome04.wav",
	"vo/breencast/br_welcome05.wav",
	"vo/breencast/br_welcome06.wav",
	"vo/breencast/br_welcome07.wav",
	"vo/breencast/br_instinct01.wav",
	"vo/breencast/br_collaboration07.wav",
	"vo/breencast/br_collaboration06.wav",
	"vo/breencast/br_collaboration05.wav",
	"vo/breencast/br_collaboration02.wav",
	"vo/eli_lab/eli_vilebiz03.wav",
	"vo/citadel/br_newleader_c.wav",
	"vo/k_lab/kl_modifications01.wav"
}

C.Stages = {
	{ 0, "Вас пытаются вернуть в мир живых…" },
	{ 0.2, "Держитесь. Может трясти." },
	{ 0.45, "Сквозь темноту доносятся чужие голоса." },
	{ 0.7, "Вы просыпаетесь…" },
	{ 0.9, "Ещё немного. Дышите." }
}

C.RevivedText = "Вы снова чувствуете боль."
C.LostText = "Голоса стихают. Темнота смыкается."
C.FatalText = "Тело сломано слишком сильно. Обратного пути нет."

local Active = false
local Ratio = 0
local Target = 0
local Blinded = false
local Shown = 0
local Emitter = nil
local Texts = {}
local HookCache = {}
local TimerCache = {}
local SoundCache = {}

local function AddSound(name)
	local snd = CreateSound(LocalPlayer(), name)

	table.insert(SoundCache, snd)

	return snd
end

local function NewHookAdd(str, name, func)
	name = "hg_cpr_hook_" .. name

	hook.Add(str, name, func)
	table.insert(HookCache, { str = str, name = name })
end

local function NewTimerSimple(time, func)
	local name = "hg_cpr_timer_" .. #TimerCache .. "_" .. math.random(1, 1000000)

	timer.Create(name, time, 1, func)
	table.insert(TimerCache, { name = name })
end

local function StopTimers()
	for _, v in pairs(TimerCache) do timer.Remove(v.name) end

	TimerCache = {}
end

local function RemoveHooks()
	for _, v in pairs(HookCache) do hook.Remove(v.str, v.name) end

	HookCache = {}
end

local function StopSounds()
	for _, v in pairs(SoundCache) do if v then v:Stop() end end

	SoundCache = {}
end

C.Beat = 60 / 120
C.TextSpeed = 16
C.TextHold = 1.2
C.TextLines = 5

local NotifyColor = Color(235, 225, 225)
local NotifyOutline = Color(40, 40, 40)
local NotifyDraw = Color(235, 225, 225, 255)

local function NotifyFont()
	return hg.notificationFont or "HuyFont"
end

local function NextBeat()
	local beat = C.Beat or 0.5

	return math.ceil(CurTime() / beat) * beat
end

local function AddText(text)
	local limit = C.TextLines or 5

	while #Texts >= limit do table.remove(Texts, 1) end

	table.insert(Texts, { text = text, start = NextBeat(), show = C.TextHold or 1.2, click = 0 })
	chat.AddText(Color(190, 40, 40), "[СЛР] ", Color(235, 230, 230), text)
end

local function MakeBlind(time, force)
	if not force and Blinded then return end

	Blinded = true

	local blind = 0
	local reverse = false
	local name = force and "render_forcedblind" or "render_blind"

	NewHookAdd("RenderScreenspaceEffects", name, function()
		blind = Lerp(0.1, blind, reverse and 0 or 1)

		DrawColorModify({
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = blind,
			["$pp_colour_contrast"] = 1,
			["$pp_colour_colour"] = 1,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		})
	end)

	NewTimerSimple(time / 2, function() reverse = true end)

	NewTimerSimple(time, function()
		hook.Remove("RenderScreenspaceEffects", "hg_cpr_hook_" .. name)
		Blinded = false
	end)
end

local function Clear()
	RemoveHooks()
	StopTimers()
	StopSounds()

	if Emitter then
		Emitter:Finish()
		Emitter = nil
	end

	Texts = {}
	Active = false
	Blinded = false
	Ratio = 0
	Target = 0
	Shown = 0
end

local function Start(ratio)
	if Active then
		Target = math.Clamp(ratio or 0, 0, 1)

		return
	end

	Clear()

	Active = true
	Ratio = 0
	Target = math.Clamp(ratio or 0, 0, 1)
	Shown = 1
	Emitter = ParticleEmitter(LocalPlayer():GetPos())

	AddText(C.Stages[1][2])

	local wind = AddSound("ambient/levels/canals/windmill_wind_loop1.wav")
	wind:Play()
	wind:ChangeVolume(0, 0)
	wind:ChangeVolume(0.35, 4)

	local siren = AddSound("ambient/alarms/city_siren_loop2.wav")
	siren:Play()
	siren:ChangeVolume(0, 0)
	siren:ChangeVolume(0.18, 6)

	MakeBlind(4)

	NewHookAdd("Think", "main", function()
		if not IsValid(LocalPlayer()) then return end

		Ratio = Lerp(FrameTime() * 2, Ratio, Target)

		if math.random(1, 80) == 1 then
			local snd = AddSound("ambient/wind/wind_snippet" .. math.random(1, 5) .. ".wav")
			snd:Play()
			snd:ChangeVolume(0.4, 0)
		end

		if math.random(1, 140) == 1 then
			local snd = AddSound("ambient/wind/wind_hit" .. math.random(1, 3) .. ".wav")
			snd:Play()
		end

		if math.random(1, math.max(200 - math.floor(Ratio * 150), 40)) == 1 then
			local snd = AddSound(table.Random(C.Voices))
			snd:Play()
			snd:ChangeVolume(math.Rand(0.07, 0.12), 0)
			snd:ChangePitch(math.random(70, 90), 0)
		end

		if math.random(1, 500) == 1 then MakeBlind(3) end

		if Emitter then
			local pos = EyePos()

			for i = 1, 2 do
				local vec = VectorRand() * 400
				local p = Emitter:Add("effects/fleck_cement" .. math.random(1, 2), pos + vec)

				if p then
					p:SetDieTime(4)
					p:SetStartAlpha(200)
					p:SetEndAlpha(0)
					p:SetStartSize(math.random(4, 12))
					p:SetEndSize(0)
					p:SetRoll(math.Rand(-10, 10))
					p:SetRollDelta(math.Rand(-4, 4))
					p:SetVelocity(-vec * 0.6)
					p:SetGravity(VectorRand() * 200)
					p:SetColor(150, 20, 20)
				end
			end

			for i = 1, 2 do
				local vec = VectorRand() * 900
				local p = Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos + vec)

				if p then
					p:SetDieTime(5)
					p:SetStartAlpha(90)
					p:SetEndAlpha(0)
					p:SetStartSize(math.random(200, 500))
					p:SetEndSize(100)
					p:SetRoll(math.Rand(-10, 10))
					p:SetRollDelta(math.Rand(-2, 2))
					p:SetVelocity(-vec * 0.2)
					p:SetGravity(VectorRand() * 100)
					p:SetColor(70, 20, 20)
				end
			end
		end
	end)

	NewHookAdd("CalcView", "shake", function(ply, pos, ang, fov)
		local power = 0.4 + Ratio * 1.6
		local view = {}

		view.origin = pos + VectorRand() * power * 0.6
		view.angles = ang + AngleRand() * power * 0.05
		view.fov = fov + math.sin(CurTime() * 6) * (1 + Ratio * 3)

		return view
	end)

	NewHookAdd("RenderScreenspaceEffects", "render", function()
		local warm = math.Clamp(Ratio, 0, 1)

		DrawColorModify({
			["$pp_colour_addr"] = 0.02 + warm * 0.05,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = -0.12 + warm * 0.12,
			["$pp_colour_contrast"] = 1 + warm * 0.35,
			["$pp_colour_colour"] = 0.15 + warm * 0.85,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		})

		DrawBloom(0.2 + warm * 0.5, 2 + warm * 4, 9, 9, 1, 1, 1, 1, 1)
		DrawMotionBlur(0.25, 0.55 - warm * 0.3, 0.02)
		DrawToyTown(math.floor(2 + warm * 6), ScrH())
		DrawSharpen(1 + warm, 1)
	end)

	NewHookAdd("HUDPaint", "text", function()
		if #Texts == 0 then return end

		local time = CurTime()
		local beat = C.Beat or 0.5
		local speed = beat / (C.TextSpeed or 16)
		local font = NotifyFont()

		surface.SetFont(font)

		local _, txth = surface.GetTextSize("А")
		local line = txth * 1.15
		local base = ScrH() - ScrH() / 6

		for i = #Texts, 1, -1 do
			local item = Texts[i]

			item.len = utf8.len(item.text) or string.len(item.text)
			item.read = math.max(item.len * speed, speed)
			item.wait = math.Clamp(item.read, beat, beat * 6) + (item.show or 1.2)

			if item.len <= 0 or item.start + item.read + item.wait < time then table.remove(Texts, i) end
		end

		local count = #Texts
		local shake = 1 + Ratio * 6

		for i = 1, count do
			local item = Texts[i]

			if item.start <= time then
				local part = math.min((time - item.start) / item.read, 1)
				local left = item.start + item.read + item.wait - time
				local fade = math.Clamp(left / item.wait, 0, 1) * math.Clamp((time - item.start) / (beat * 0.5), 0, 1)
				local click = math.max(math.ceil(part * item.len), 1)
				local txt = utf8.sub(utf8.force(item.text), 1, click)

				if click ~= item.click then
					item.click = click

					if click % 2 == 0 or click == item.len then
						sound.Play("peepsnd", render.GetViewSetup().origin - vector_up * 10)
					end
				end

				local txtw = surface.GetTextSize(txt)
				local x = ScrW() / 2 - txtw / 2 + math.Rand(0, shake)
				local y = base - (count - i) * line + math.Rand(0, shake)

				NotifyDraw.r = NotifyColor.r
				NotifyDraw.g = NotifyColor.g
				NotifyDraw.b = NotifyColor.b
				NotifyDraw.a = 255 * fade
				NotifyOutline.a = NotifyDraw.a

				draw.SimpleTextOutlined(txt, font, x, y, NotifyDraw, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1.5, NotifyOutline)
			end
		end
	end)
end

local function Update(ratio)
	if not Active then
		Start(ratio)

		return
	end

	Target = math.Clamp(ratio or 0, 0, 1)

	for i = Shown + 1, #C.Stages do
		if Target >= C.Stages[i][1] then
			Shown = i

			AddText(C.Stages[i][2])
			surface.PlaySound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav")
		end
	end
end

local function Finish(revived, fatal)
	if not Active then return end

	Target = revived and 1 or 0

	for _, v in pairs(SoundCache) do
		if v then v:ChangeVolume(0, revived and 1.5 or 2.5) end
	end

	AddText(revived and C.RevivedText or (fatal and C.FatalText or C.LostText))

	if revived then
		MakeBlind(3, true)
		--surface.PlaySound("ambient/levels/labs/electric_explosion1.wav")
	end

	NewTimerSimple(revived and 2.5 or 3, function() Clear() end)
end

net.Receive("hg cpr revive", function()
	local stage = net.ReadUInt(3)
	local ratio = net.ReadFloat()

	if stage == 1 then
		Start(ratio)
	elseif stage == 2 then
		Update(ratio)
	elseif stage == 3 then
		Finish(true)
	elseif stage == 5 then
		Finish(false, true)
	else
		Finish(false)
	end
end)
