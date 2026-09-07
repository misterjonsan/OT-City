if SERVER then
	local SPRITES = {
		"materials/vgui/hud/health_head.png",
		"materials/vgui/hud/health_torso.png",
		"materials/vgui/hud/health_right_arm.png",
		"materials/vgui/hud/health_left_arm.png",
		"materials/vgui/hud/health_right_leg.png",
		"materials/vgui/hud/health_left_leg.png",
	}
	local ICONS = {
		"materials/vgui/hud/bloodmeter.png",
		"materials/vgui/hud/pulsemeter.png",
		"materials/vgui/hud/assimilationmeter.png",
		"materials/vgui/hud/o2meter.png",
		"materials/vgui/hud/o2meter_alt.png",
	}
	local STATUS_SPRITES = {
		"materials/vgui/hud/status_level1_bg.png",
		"materials/vgui/hud/status_level2_bg.png",
		"materials/vgui/hud/status_level3_bg.png",
		"materials/vgui/hud/status_level4_bg.png",
		"materials/vgui/hud/status_background.png",
		"materials/vgui/hud/status_pain_icon.png",
		"materials/vgui/hud/status_conscious_icon.png",
		"materials/vgui/hud/status_stamina_icon.png",
		"materials/vgui/hud/status_bleeding_icon.png",
		"materials/vgui/hud/status_internal_bleed_icon.png",
		"materials/vgui/hud/status_organ_damage.png",
		"materials/vgui/hud/status_dislocation.png",
		"materials/vgui/hud/status_spine_fracture.png",
		"materials/vgui/hud/status_leg_fracture.png",
		"materials/vgui/hud/status_blood_loss.png",
		"materials/vgui/hud/status_cardiac_arrest.png",
		"materials/vgui/hud/status_cold.png",
		"materials/vgui/hud/status_heat.png",
		"materials/vgui/hud/status_hemothorax.png",
		"materials/vgui/hud/status_lungs_failure.png",
		"materials/vgui/hud/status_overdose.png",
		"materials/vgui/hud/status_oxygen.png",
		"materials/vgui/hud/status_vomit.png",
		"materials/vgui/hud/status_brain_damage.png",
		"materials/vgui/hud/status_adrenaline.png",
		"materials/vgui/hud/status_shock.png",
		"materials/vgui/hud/status_trauma.png",
		"materials/vgui/hud/status_death.png",
		"materials/vgui/hud/status_berserk.png",
		"materials/vgui/hud/status_amputant.png",
		"materials/vgui/hud/status_chip.png",
		"materials/vgui/hud/status_bleedartery.png",
		"materials/vgui/hud/status_arrhythmia.png",
		"materials/vgui/hud/status_fibrillation.png",
		"materials/vgui/hud/status_level1_bgalt.png",
		"materials/vgui/hud/status_level2_bgalt.png",
		"materials/vgui/hud/status_level3_bgalt.png",
		"materials/vgui/hud/status_level4_bgalt.png",
		"materials/vgui/hud/status_backgroundalt.png",
		"materials/vgui/hud/status_pain_iconalt.png",
		"materials/vgui/hud/status_conscious_iconalt.png",
		"materials/vgui/hud/status_stamina_iconalt.png",
		"materials/vgui/hud/status_bleeding_iconalt.png",
		"materials/vgui/hud/status_internal_bleed_iconalt.png",
		"materials/vgui/hud/status_organ_damagealt.png",
		"materials/vgui/hud/status_dislocationalt.png",
		"materials/vgui/hud/status_spine_fracturealt.png",
		"materials/vgui/hud/status_leg_fracturealt.png",
		"materials/vgui/hud/status_blood_lossalt.png",
		"materials/vgui/hud/status_cardiac_arrestalt.png",
		"materials/vgui/hud/status_coldalt.png",
		"materials/vgui/hud/status_heatalt.png",
		"materials/vgui/hud/status_hemothoraxalt.png",
		"materials/vgui/hud/status_lungs_failurealt.png",
		"materials/vgui/hud/status_overdosealt.png",
		"materials/vgui/hud/status_oxygenalt.png",
		"materials/vgui/hud/status_vomitalt.png",
		"materials/vgui/hud/status_brain_damagealt.png",
		"materials/vgui/hud/status_adrenalinealt.png",
		"materials/vgui/hud/status_shockalt.png",
		"materials/vgui/hud/status_traumaalt.png",
		"materials/vgui/hud/status_deathalt.png",
		"materials/vgui/hud/status_berserkalt.png",
		"materials/vgui/hud/status_amputantalt.png",
		"materials/vgui/hud/status_chipalt.png",
		"materials/vgui/hud/status_bleedarteryalt.png",
		"materials/vgui/hud/status_arrhythmiaalt.png",
		"materials/vgui/hud/status_fibrillationalt.png",
	}
	for _, path in ipairs(SPRITES) do resource.AddFile(path) end
	for _, path in ipairs(ICONS) do resource.AddFile(path) end
	for _, path in ipairs(STATUS_SPRITES) do resource.AddFile(path) end
	AddCSLuaFile("autorun/zb_health_hud.lua")
	util.AddNetworkString("zb_hud_spect_sync")
	util.AddNetworkString("zb_hud_giveup")
	net.Receive("zb_hud_giveup", function(_, ply)
		if not IsValid(ply) or not ply:Alive() then return end
		local org = ply.organism
		if not istable(org) then return end
		if not (org.otrub or org.canmove == false) then return end
		ply:Kill()
	end)
	local SPECT_KEYS = {
		"alive", "blood", "consciousness", "pain", "pulse", "heartbeat",
		"assimilated", "o2", "bleed", "internalBleed", "temperature",
		"pneumothorax", "analgesia", "brain", "wantToVomit", "adrenaline",
		"shock", "disorientation", "stamina",
		"skull", "jaw", "chest", "spine1", "spine2", "spine3", "pelvis",
		"rarm", "larm", "rleg", "lleg",
		"heart", "liver", "stomach", "intestines", "lungsR", "lungsL",
		"llegdislocation", "rlegdislocation", "larmdislocation", "rarmdislocation", "jawdislocation",
		"llegamputated", "rlegamputated", "larmamputated", "rarmamputated", "headamputated",
		"lungsfunction", "heartstop", "berserk", "berserkActive2",
		"arteria", "rarmarteria", "larmarteria", "rlegarteria", "llegarteria",
		"hasHealthChip",
	}
	local function buildSpectTable(org)
		local t = {}
		for _, k in ipairs(SPECT_KEYS) do
			t[k] = org[k]
		end
		return t
	end
	local nextSpectSync = 0
	hook.Add("Think", "ZB_HUD_SpectatorSync", function()
		if CurTime() < nextSpectSync then return end
		nextSpectSync = CurTime() + 0.2
		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() then continue end
			local target = ply:GetNWEntity("spect")
			if not IsValid(target) or not target:IsPlayer() then
				target = ply:GetObserverTarget()
			end
			if not IsValid(target) or not target:IsPlayer() or target == ply then continue end
			local org = target.organism
			if not istable(org) then continue end
			net.Start("zb_hud_spect_sync")
			net.WriteEntity(target)
			net.WriteTable(buildSpectTable(org))
			net.Send(ply)
		end
	end)
	return
end
local math_min, math_max, math_floor, math_sin, math_abs, math_cos, math_sqrt = math.min, math.max, math.floor, math.sin, math.abs, math.cos, math.sqrt
local Color = Color
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local ScrW, ScrH = ScrW, ScrH
local FrameTime = FrameTime
local Lerp = Lerp
local CurTime = CurTime
local gui = gui
local LANGUAGE = "ru"
local function getOrgVal(org, key, def)
	local v = org[key]
	return type(v) == "number" and v or (def or 0)
end
local function getOrgTableVal(org, tbl, key, index, def)
	if not org[tbl] or type(org[tbl]) ~= "table" then return def or 0 end
	local val = org[tbl][key]
	if index and type(val) == "table" then
		val = val[index]
	end
	return type(val) == "number" and val or (def or 0)
end
local function getO2Value(org)
	if not org.o2 then return 30 end
	if type(org.o2) == "table" then
		return org.o2[1] or 30
	end
	return type(org.o2) == "number" and org.o2 or 30
end
local function getO2Max(org)
	if not org.o2 then return 30 end
	if type(org.o2) == "table" then
		return org.o2.range or 30
	end
	return 30
end
local function isPlayerDead(ply)
	if not IsValid(ply) then return true end
	if not ply:Alive() then return true end
	local org = ply.organism
	if org and org.alive == false then return true end
	return false
end
local function getOrganism(ply)
	if not IsValid(ply) then return nil end
	if ply ~= LocalPlayer() and istable(ply.zb_spect_organism) and (CurTime() - (ply.zb_spect_organism_time or 0)) < 2 then
		return ply.zb_spect_organism
	end
	return ply.new_organism or ply.organism
end
net.Receive("zb_hud_spect_sync", function()
	local target = net.ReadEntity()
	local tbl = net.ReadTable()
	if IsValid(target) then
		target.zb_spect_organism = tbl
		target.zb_spect_organism_time = CurTime()
	end
end)
local function getViewPlayer()
	local lply = LocalPlayer()
	if not IsValid(lply) then return lply end
	if lply:Alive() then return lply end
	local target = lply:GetNWEntity("spect")
	if IsValid(target) and target:IsPlayer() then
		return target
	end
	local obs = lply:GetObserverTarget()
	if IsValid(obs) and obs:IsPlayer() and obs ~= lply then
		return obs
	end
	return lply
end
local function isBerserkActive(org)
	return org and org.berserkActive2 == true
end
local function lerpCol(ratio, from, to)
	ratio = math_min(math_max(ratio, 0), 1)
	return Color(
		math_floor((from.r or 0) + ((to.r or 0) - (from.r or 0)) * ratio),
		math_floor((from.g or 0) + ((to.g or 0) - (from.g or 0)) * ratio),
		math_floor((from.b or 0) + ((to.b or 0) - (from.b or 0)) * ratio),
		255
	)
end
local function getLimbColor(damage)
	local ratio = math_min(math_max(damage, 0), 1)
	if ratio <= 0.3 then return Color(128, 128, 128, 255)
	elseif ratio <= 0.6 then return Color(255, 165, 0, 255)
	else return Color(255, 0, 0, 255) end
end
local function hasAnyLimbDamage(org)
	return (getOrgVal(org, "skull", 0) > 0.01 or
		getOrgVal(org, "jaw", 0) > 0.01 or
		getOrgVal(org, "chest", 0) > 0.01 or
		getOrgVal(org, "spine1", 0) > 0.01 or
		getOrgVal(org, "spine2", 0) > 0.01 or
		getOrgVal(org, "spine3", 0) > 0.01 or
		getOrgVal(org, "pelvis", 0) > 0.01 or
		getOrgVal(org, "rarm", 0) > 0.01 or
		getOrgVal(org, "larm", 0) > 0.01 or
		getOrgVal(org, "rleg", 0) > 0.01 or
		getOrgVal(org, "lleg", 0) > 0.01)
end
local function hasAnyAmputation(org)
	return org.llegamputated == true or
		org.rlegamputated == true or
		org.larmamputated == true or
		org.rarmamputated == true
end
local function hasAnyFracture(org, threshold)
	threshold = threshold or 0.95
	local lleg = getOrgVal(org, "lleg", 0)
	local rleg = getOrgVal(org, "rleg", 0)
	local larm = getOrgVal(org, "larm", 0)
	local rarm = getOrgVal(org, "rarm", 0)
	return (lleg >= threshold and not org.llegamputated) or
		(rleg >= threshold and not org.rlegamputated) or
		(larm >= threshold and not org.larmamputated) or
		(rarm >= threshold and not org.rarmamputated)
end
local HUD = {
	enabled = true,
	bar_y = 4440,
	bar_scale = 0,
	base_x = nil,
	base_y = 60,
	limb_offsets = {
		head =        { x = 55,  y = -15 },
		torso =       { x = 54,  y = 33 },
		right_arm =   { x = 83,  y = 36 },
		left_arm =    { x = 24,  y = 38 },
		right_leg =   { x = 66,  y = 92 },
		left_leg =    { x = 35,  y = 106 },
	},
	limb_scale = {
		head =        { w = 1, h = 1 },
		torso =       { w = 1.4, h = 1.8 },
		right_arm =   { w = 1, h = 2 },
		left_arm =    { w = 1, h = 2 },
		right_leg =   { w = 1.2, h = 3.5 },
		left_leg =    { w = 1.2, h = 2.7 },
	},
	sprite_visibility = 100,
	always_show_limbs = true,
	smooth = 0.35,
	show_damage_percent = false,
	blood_hide_threshold = 4500,
	pulse_hide_min = 60,
	pulse_hide_max = 100,
	stable_time = 15,
	status_effects_size = 46,
	status_effects_gap = 8,
	status_effects_bottom_margin = 8,
	show_status_effects = true,
	organ_damage_threshold = 0.3,
	fracture_threshold = 0.95,
	bleeding_threshold = 0.1,
	internal_bleed_threshold = 0.1,
	blood_loss_threshold = 4700,
	cardiac_arrest_threshold = true,
	cold_threshold = 36,
	heat_threshold = 37,
	hemothorax_threshold = 0.01,
	oxygen_threshold = 28,
	vomit_threshold = 0.2,
	brain_damage_threshold = 0.01,
	adrenaline_threshold = 0.3,
	shock_threshold = 20,
	trauma_threshold = 0.2,
	limb_damage_threshold = 0.01,
	limb_fade_speed = 3.0,
}
local sprites = {}
local icons = {}
local status_sprites = {
	level_backgrounds = {nil, nil, nil, nil},
	background = nil,
	pain_icon = nil,
	conscious_icon = nil,
	stamina_icon = nil,
	bleeding_icon = nil,
	internal_bleed_icon = nil,
	organ_damage = nil,
	dislocation = nil,
	spine_fracture = nil,
	fracture = nil,
	blood_loss = nil,
	cardiac_arrest = nil,
	cold = nil,
	heat = nil,
	hemothorax = nil,
	lungs_failure = nil,
	overdose = nil,
	oxygen = nil,
	vomit = nil,
	brain_damage = nil,
	adrenaline = nil,
	shock = nil,
	trauma = nil,
	death = nil,
	berserk = nil,
	amputant = nil,
	chip = nil,
	bleedartery = nil,
	arrhythmia = nil,
	fibrillation = nil,
}
local status_sprites_loaded = false
local debug_done = false
local statusEffectAppearance = {}
local statusEffectPositions = {}
local smooth = {
	blood = 5000,
	conscious = 1.0,
	pain = 0,
	pulse = 70,
	assimilation = 0,
	o2 = 30,
	bleed = 0,
	internalBleed = 0,
	temperature = 36.7,
	pneumothorax = 0,
	analgesia = 0,
	brain = 0,
	wantToVomit = 0,
	adrenaline = 0,
	shock = 0,
	disorientation = 0,
}
local limbFadeStates = {
	head = {alpha = 0, target = 0},
	torso = {alpha = 0, target = 0},
	right_arm = {alpha = 0, target = 0},
	left_arm = {alpha = 0, target = 0},
	right_leg = {alpha = 0, target = 0},
	left_leg = {alpha = 0, target = 0},
}
local limbsRevealed = false
local stability = {
	blood = {last_value = 5000, last_change = 0, hidden = false},
	pulse = {last_value = 70, last_change = 0, hidden = false},
}
local hoverEffect = {
	hoveredIndex = nil,
	hoverTime = 0,
	mouseOffsetX = 0,
	mouseOffsetY = 0,
	lastMouseX = 0,
	lastMouseY = 0,
	scale = 1.0,
	painShakeTime = 0,
	berserkShakeTime = 0,
}
local function isAnyMenuOpen()
	local menu = g_ContextMenu
	if menu and (menu.Visible or menu:IsVisible()) then
		return true
	end
	local spawnmenu = g_SpawnMenu
	if spawnmenu and spawnmenu:IsVisible() then
		return false
	end
	if gui.MouseX() ~= 0 or gui.MouseY() ~= 0 then
		local hovered = vgui.GetHoveredPanel()
		if hovered then
			local name = hovered:GetName() or ""
			local className = hovered:GetClassName() or ""
			if string.find(className, "Radial") or string.find(className, "Menu") then
				return true
			end
			if string.find(name, "Radial") or string.find(name, "Menu") then
				return true
			end
			local parent = hovered:GetParent()
			while parent do
				local pname = parent:GetName() or ""
				local pclass = parent:GetClassName() or ""
				if string.find(pclass, "Radial") or string.find(pclass, "Menu") then
					return true
				end
				if string.find(pname, "Radial") or string.find(pname, "Menu") then
					return true
				end
				parent = parent:GetParent()
			end
		end
	end
	return gui.MouseX() ~= 0 or gui.MouseY() ~= 0
end
local tooltipTexts = {
	ru = {
		pain = {
			[4] = "Агония - Невыносимая боль. Движения ограничены. Смерть сейчас звучит заманчиво.",
			[3] = "Сильная боль - Полусознателен, разум затуманен сильной болью.",
			[2] = "Боль - Довольно сильная боль.",
			[1] = "Небольшая боль - Ощущается легкая боль."
		},
		bleeding = "Кровотечение - Кровь льётся из относительно большой раны. Это вряд ли приведет к летальному исходу, если ты полностью здоров.",
		internal_bleed = "Внутреннее кровотечение - Как выяснилось, кишки и легкие — это явно НЕ место для твоей крови. Крайне рекомендуется лечение.",
		conscious = {
			[4] = "Без сознания - Нет реакции ни на какие внешние раздражители. Ты в отключке.",
			[3] = "Обморок - Едва в сознании, чувствуя, что можешь упасть в любой момент.",
			[2] = "Растерян - Чувство растерянности и головокружения, трудности с восприятием окружающего мира.",
			[1] = "Запутан - Слегка дезориентирован с легким головокружением."
		},
		stamina = {
			[4] = "Совершенно измотан - Кое-как способен дышать.",
			[3] = "Сильно выдохся - Практически не можешь двигаться.",
			[2] = "Выдохся - Испытываешь дискомфорт и усталость, с трудом двигаешься и работаешь.",
			[1] = "Слегка устал - Незначительное физическое напряжение."
		},
		spine_fracture = "Сломаный позвоночник - Сломан позвоночник. Если спинной мозг не оборван, считай это удачей.",
		fracture = "Перелом конечности - У тебя сломана рука или нога. Движение повреждённой конечностью затруднено и причиняет сильную боль.",
		organ_damage = "Повреждение органов - Органы внутри тебя чувствуют себя не хорошо.",
		dislocation = "Вывих сустава - Ты вывихнул конечность. Постарайся не использовать поврежденную конечность и найди способ ее вправить.",
		amputant = "Ампутант - Одна из твоих конечностей была оторвана. Травмирующе. Очевидно, ты навсегда утратил возможность пользоваться оторванной конечностью.",
		blood_loss = {
			[4] = "Обескровлен - Угрожающая жизни потеря крови. Еще чуть-чуть, и сердце остановится. Смерть неизбежна.",
			[3] = "Критическая гиповолемия - Сильная потеря крови. Полусознателен. Ты нечетко видишь... Необходимо лечение.",
			[2] = "Гиповолемия - Слабость и дезориентация вследствие кровопотери. Ты чувствуешь себя очень плохо. Рекомендуется лечение.",
			[1] = "Бледен - Незначительная потеря крови. Артериальное давление понижено. Ты чувствуваешь небольшую слабость, кожа бледная."
		},
		cardiac_arrest = "Остановка сердца - Твоё сердце перестало биться, а значит кислород в мозг больше не поступает.",
		cold = {
			[4] = "Замерзание до смерти - По неизвестной причине тебе становится тепло...",
			[3] = "Гипотермия - Опасно низкая температура, тело и разум изнемогают от холода.",
			[2] = "Холодно - Неприятно холодно. Твой организм замедляется.",
			[1] = "Прохладно - Немного прохладно для комфорта."
		},
		heat = {
			[4] = "Тепловой удар - Твой организм явно долго не протянет в такую жару.",
			[3] = "Гипертермия - Опасно жарко. Тебе тяжело выдерживать жару...",
			[2] = "Жарко - Неприятно жарко.",
			[1] = "Тепло - Немного жарковато для комфорта."
		},
		hemothorax = {
			[4] = "Критический гемоторакс - Лёгкие пытаются зачерпнуть хоть каплю кислорода, но всё четно... Спокойной ночи.",
			[3] = "Сильнейший гемоторакс - Грудная клетка очень сильно болит. Кровь уже заполнила лёгкие больше, чем на половину.",
			[2] = "Серьёзный гемоторакс - Кровь скопилась до такого уровня, что дышать стало труднее.",
			[1] = "Гемоторакс - В плевральной полости скапливается кровь из-за внутреннего кровотечения или прокола лёгких. У тебя болит грудь... Требуется лечение."
		},
		lungs_failure = "Отказ лёгких - лёгкие перестали работать в связи с повреждением, долгим отсутсвием цикла дыхания или по другой причине.",
		overdose = {
			[4] = "Фатальная передозировка - Дыхательная недостаточность. Ты покидаешь этот мир в состоянии эйфории, вызванной наркотиками, но тебе уже глубоко наплевать.",
			[3] = "Передозировка - Дышать тяжело, в голове царит эйфория. Это определенно плохо для организма. Если бы только это могло длиться вечно...",
			[2] = "Средняя доза - Очень расслаблен и спокоен, но легкие ощущаются тяжелыми. Устаешь немного быстрее обычного. Чувствуешь себя отлично, пока что...",
			[1] = "Доза - Расслаблен и спокоен. Тело чувствуется онемевшим."
		},
		oxygen = {
			[4] = "Аноксемия - Мозг отмирает от кислородного голодания. Весь организм стремительно отказывает. Смерть неизбежна.",
			[3] = "Асфиксия - Теряешь сознание. Ткани лишены кислорода.",
			[2] = "Сильная гипоксемия - Недостаточно кислорода в организме. Головокружение и онемение конечностей. Что-то ЯВНО не так.",
			[1] = "Гипоксемия - Понижен уровень кислорода в крови. Немного запутан, кожа вялая. Что-то не так..."
		},
		vomit = {
			[4] = "Ужасная тошнота - Опасная тошнота. Внутри что-то ОЧЕНЬ не так.",
			[3] = "Сильная тошнота - Сильный дискомфорт. Сильная склонность к рвоте.",
			[2] = "Тошнота - Дискомфорт в области желудка. Склонность к рвоте.",
			[1] = "Подташнивает - Чувствуешь дискомфорт. Немного плохо. Небольшая склонность к рвоте."
		},
		brain_damage = {
			[4] = "Кома - Едва цепляясь за жизнь, ты страдаешь от cильнейшего повреждения мозга. Ты - овощ. Восстановление маловероятно.",
			[3] = "Тяжелое нейрофизиологическое ухудшение - Сильно умственно отстал, едва способный мыслить разумно и оставаться в сознании. Серьёзная мозговая травма",
			[2] = "Неврологические повреждения - Тяжелый ментальный дефицит. Ограничена способность к интеллектуальному мышлению и самодостаточности. Серьезные повреждения головного мозга.",
			[1] = "Когнитивные нарушения - Психические расстройства вследствие повреждения головного мозга. Ты чувствуешь странную растерянность..."
		},
		adrenaline = {
			[4] = "Адреналин - Сердце работает на износ качая кровь. Практически полное отсутствие боли, прилив сил, и увеличенная стойкость.",
			[3] = "Адреналин - Почти не чувствуешь боль. Выносливость увеличилась в разы.",
			[2] = "Адреналин - Боль притупилась. Состояние повышенной готовности",
			[1] = "Адреналин - Ты чувствуешь небольшой прилив сил."
		},
		shock = {
			[4] = "Шок - Организм включает самый лучший защитный механизм, чтобы справится с этой болью. Сладких снов.",
			[3] = "Шок - Сильнейшая боль в твоей жизни туманит разум и рассудок делая из тебя животное.",
			[2] = "Шок - Агонизирующая боль прорезает каждую клеточку твоего тела.",
			[1] = "Шок - Входишь в состояние шока"
		},
		trauma = {
			[4] = "Контужен - Ужас и Беспомощность.",
			[3] = "Сильная дезориентация - Звон в ушах и мир, как на карусели.",
			[2] = "Серьёзная дезориентация - Голова кружится и всё кругом плывёт.",
			[1] = "Лёгкая дезориентация - Чувствуешь себя сонным."
		},
		death = "Смерть - Пермаментная и грустная или весёлая, а впрочем уже не важно.",
		berserk = {
			[4] = "Берсерк - Невообразимая сила, регенерация, и стойкость. Ты машина для убийств.",
			[3] = "Берсерк - Невообразимая сила, регенерация, и стойкость. Ты машина для убийств.",
			[2] = "Берсерк - Невообразимая сила, регенерация, и стойкость. Ты машина для убийств.",
			[1] = "Берсерк - Невообразимая сила, регенерация, и стойкость. Ты машина для убийств."
		},
		berserk_brain_damage = "Повреждение мозга - ЧУТЬ ЧУТЬ ОТЛЕЖУСЬ И НОРМАЛЬНО.",
		berserk_fracture = "Перелом - МНЕ РАЗВЕ ДОЛЖНО БЫТЬ НЕ БОЛЬНО... А ПОХУЙ ВООБЩЕМ.",
		berserk_dislocation = "Вывих - ДА КОГО ОН ЁБЕТ ВООБЩЕ.",
		berserk_adrenaline = "Адреналин - ПРИЯТНЫЙ БОНУС.",
		berserk_oxygen = "Кислородное голодание - ОДНА ВЕЩЬ, КОТОРАЯ МЕНЯ ПУГАЕТ.",
		berserk_trauma = "Дезориентация - ЭТО ОЧЕНЬ ЗАВОРАЖИВАЕТ.",
		berserk_amputant = "Ампутант - МЕНЯ ЭТО ДОЛЖНО ОСТАНОВИТЬ?",
		berserk_cardiac_arrest = "Остановка сердца - ЭТО УЖЕ ЗВУЧИТ НЕ ТАК КРУТО.",
		berserk_lungs_failure = "Отказ лёгких - ЭТО УЖЕ ЗВУЧИТ НЕ ТАК КРУТО.",
		chip = "Чип - Вживлённый биосенсор.",
		bleedartery = "Артериальное кровотечение - Повреждена артерия. Кровь хлещет с огромной скоростью. Без немедленной помощи исход будет летальным.",
		arrhythmia = "Аритмия - Твой сердечный ритм нарушен. Пульс опасно низкий, а сердце бьётся слишком часто.",
		fibrillation = "Фибрилляция - Хаотичные сокращения сердца. Пульс критически низкий, сердцебиение неконтролируемо высокое. Как ты себя довёл до этого?",
	},
}
local function getTooltipText(statusName, pos, berserkActive)
	local texts = tooltipTexts.ru
	if berserkActive then
		local berserkKey = "berserk_" .. statusName
		if texts[berserkKey] then
			return texts[berserkKey]
		end
	end
	if statusName == "pain" or statusName == "conscious" or statusName == "stamina" or
		statusName == "blood_loss" or statusName == "cold" or statusName == "heat" or
		statusName == "hemothorax" or statusName == "overdose" or statusName == "oxygen" or
		statusName == "vomit" or statusName == "brain_damage" or statusName == "adrenaline" or
		statusName == "shock" or statusName == "trauma" or statusName == "berserk" then
		local levelTexts = texts[statusName]
		if levelTexts and type(levelTexts) == "table" then
			return levelTexts[pos.level_num] or levelTexts[1] or ""
		end
	else
		return texts[statusName] or ""
	end
	return ""
end
local function load_icons()
	if icons.loaded then return end
	icons.loaded = true
	local paths = {
		blood = "vgui/hud/bloodmeter.png",
		pulse = "vgui/hud/pulsemeter.png",
		assimilation = "vgui/hud/assimilationmeter.png",
		o2 = "vgui/hud/o2meter_alt.png",
	}
	for name, path in pairs(paths) do
		local mat = Material(path, "smooth")
		icons[name] = (mat and not mat:IsError()) and mat or false
	end
end
local function load_status_sprites()
	if status_sprites_loaded then return end
	status_sprites_loaded = true
	local function loadMaterial(path)
		local mat = Material(path, "smooth")
		return (mat and not mat:IsError()) and mat or nil
	end
	for i = 1, 4 do
		status_sprites.level_backgrounds[i] = loadMaterial("vgui/hud/status_level" .. i .. "_bgalt.png")
	end
	status_sprites.background = loadMaterial("vgui/hud/status_backgroundalt.png")
	status_sprites.pain_icon = loadMaterial("vgui/hud/status_pain_iconalt.png")
	status_sprites.conscious_icon = loadMaterial("vgui/hud/status_conscious_iconalt.png")
	status_sprites.stamina_icon = loadMaterial("vgui/hud/status_stamina_iconalt.png")
	status_sprites.bleeding_icon = loadMaterial("vgui/hud/status_bleeding_iconalt.png")
	status_sprites.internal_bleed_icon = loadMaterial("vgui/hud/status_internal_bleed_iconalt.png")
	status_sprites.organ_damage = loadMaterial("vgui/hud/status_organ_damagealt.png")
	status_sprites.dislocation = loadMaterial("vgui/hud/status_dislocationalt.png")
	status_sprites.spine_fracture = loadMaterial("vgui/hud/status_spine_fracturealt.png")
	status_sprites.fracture = loadMaterial("vgui/hud/status_leg_fracturealt.png")
	status_sprites.blood_loss = loadMaterial("vgui/hud/status_blood_lossalt.png")
	status_sprites.cardiac_arrest = loadMaterial("vgui/hud/status_cardiac_arrestalt.png")
	status_sprites.cold = loadMaterial("vgui/hud/status_coldalt.png")
	status_sprites.heat = loadMaterial("vgui/hud/status_heatalt.png")
	status_sprites.hemothorax = loadMaterial("vgui/hud/status_hemothoraxalt.png")
	status_sprites.lungs_failure = loadMaterial("vgui/hud/status_lungs_failurealt.png")
	status_sprites.overdose = loadMaterial("vgui/hud/status_overdosealt.png")
	status_sprites.oxygen = loadMaterial("vgui/hud/status_oxygenalt.png")
	status_sprites.vomit = loadMaterial("vgui/hud/status_vomitalt.png")
	status_sprites.brain_damage = loadMaterial("vgui/hud/status_brain_damagealt.png")
	status_sprites.adrenaline = loadMaterial("vgui/hud/status_adrenalinealt.png")
	status_sprites.shock = loadMaterial("vgui/hud/status_shockalt.png")
	status_sprites.trauma = loadMaterial("vgui/hud/status_traumaalt.png")
	status_sprites.death = loadMaterial("vgui/hud/status_deathalt.png")
	status_sprites.berserk = loadMaterial("vgui/hud/status_berserkalt.png")
	status_sprites.amputant = loadMaterial("vgui/hud/status_amputantalt.png")
	status_sprites.chip = loadMaterial("vgui/hud/status_chipalt.png")
	status_sprites.bleedartery = loadMaterial("vgui/hud/status_bleedarteryalt.png")
	status_sprites.arrhythmia = loadMaterial("vgui/hud/status_arrhythmiaalt.png")
	status_sprites.fibrillation = loadMaterial("vgui/hud/status_fibrillationalt.png")
end
local function update_stability(blood_val, pulse_val)
	local now = CurTime()
	if math_abs(blood_val - stability.blood.last_value) > 50 then
		stability.blood.last_value = blood_val
		stability.blood.last_change = now
		stability.blood.hidden = false
	end
	if math_abs(pulse_val - stability.pulse.last_value) > 3 then
		stability.pulse.last_value = pulse_val
		stability.pulse.last_change = now
		stability.pulse.hidden = false
	end
	if blood_val >= HUD.blood_hide_threshold and (now - stability.blood.last_change) >= HUD.stable_time then
		stability.blood.hidden = true
	end
	if pulse_val >= HUD.pulse_hide_min and pulse_val <= HUD.pulse_hide_max and (now - stability.pulse.last_change) >= HUD.stable_time then
		stability.pulse.hidden = true
	end
end
local function draw_bar()
	if not HUD.enabled then return end
	local ply = getViewPlayer()
	local org = getOrganism(ply)
	if not IsValid(ply) or not org then return end
	local scale = math_max(HUD.bar_scale, 0.5)
	local base_bar_h = 34
	local base_bar_w = 440
	local bar_h = math_floor(base_bar_h * scale)
	local bar_w = math_floor(base_bar_w * scale)
	local bar_y = ScrH() + HUD.bar_y
	local max_bar_w = ScrW() * 0.95
	local max_scale = max_bar_w / base_bar_w
	if scale > max_scale then
		scale = max_scale
		bar_w = math_floor(base_bar_w * scale)
		bar_h = math_floor(base_bar_h * scale)
	end
	local bar_x = ScrW() * 0.5 - bar_w * 0.5
	local pad = math_floor(5 * scale)
	local icon_size = math_floor(26 * scale)
	load_icons()
	local dt = math_min(FrameTime() * 60, 1)
	local s = HUD.smooth
	local o2_val = getO2Value(org)
	local o2_max = getO2Max(org)
	smooth.blood = Lerp(s * dt, smooth.blood or 5000, getOrgVal(org, "blood", 5000))
	smooth.conscious = Lerp(s * dt, smooth.conscious or 1.0, getOrgVal(org, "consciousness", 1))
	smooth.pain = Lerp(s * dt, smooth.pain or 0, getOrgVal(org, "pain", 0))
	smooth.pulse = Lerp(s * dt, smooth.pulse or 70, getOrgVal(org, "pulse", 70))
	smooth.assimilation = Lerp(s * dt, smooth.assimilation or 0, getOrgVal(org, "assimilated", 0))
	smooth.o2 = Lerp(s * dt, smooth.o2 or o2_max, o2_val)
	smooth.bleed = Lerp(s * dt, smooth.bleed or 0, getOrgVal(org, "bleed", 0))
	smooth.internalBleed = Lerp(s * dt, smooth.internalBleed or 0, getOrgVal(org, "internalBleed", 0))
	smooth.temperature = Lerp(s * dt, smooth.temperature or 36.7, getOrgVal(org, "temperature", 36.7))
	smooth.pneumothorax = Lerp(s * dt, smooth.pneumothorax or 0, getOrgVal(org, "pneumothorax", 0))
	smooth.analgesia = Lerp(s * dt, smooth.analgesia or 0, getOrgVal(org, "analgesia", 0))
	smooth.brain = Lerp(s * dt, smooth.brain or 0, getOrgVal(org, "brain", 0))
	smooth.wantToVomit = Lerp(s * dt, smooth.wantToVomit or 0, getOrgVal(org, "wantToVomit", 0))
	smooth.adrenaline = Lerp(s * dt, smooth.adrenaline or 0, getOrgVal(org, "adrenaline", 0))
	smooth.shock = Lerp(s * dt, smooth.shock or 0, getOrgVal(org, "shock", 0))
	smooth.disorientation = Lerp(s * dt, smooth.disorientation or 0, getOrgVal(org, "disorientation", 0))
	update_stability(smooth.blood or 5000, smooth.pulse or 70)
	local segs = {}
	local blood_val = smooth.blood or 5000
	if not stability.blood.hidden then
		local r_blood = math_min(blood_val / 5000, 1)
		local c_blood = r_blood < 0.5 and lerpCol(r_blood * 2, Color(80, 255, 80), Color(255, 180, 50)) or lerpCol((r_blood - 0.5) * 2, Color(255, 180, 50), Color(255, 50, 50))
		table.insert(segs, {label = "BLOOD", val = math_floor(blood_val), suf = "ml", ratio = r_blood, col = c_blood, w = math_floor(95 * scale), icon = "blood", prio = 1})
	end
	local o2_val = smooth.o2 or o2_max
	local r_o2 = math_min(o2_val / o2_max, 1)
	local c_o2 = lerpCol(r_o2, Color(255, 50, 50), Color(80, 200, 255))
	if o2_val < HUD.oxygen_threshold or (#segs == 0 and not stability.pulse.hidden) then
		table.insert(segs, {label = "O2", val = math_floor(o2_val), suf = "%", ratio = r_o2, col = c_o2, w = math_floor(75 * scale), icon = "o2", prio = 2})
	end
	local assim_val = smooth.assimilation or 0
	if assim_val > 0.005 then
		local r_assim = assim_val
		table.insert(segs, {label = "ASSIMILATION", val = math_floor(assim_val * 100), suf = "%", ratio = r_assim, col = Color(180, 50, 255, 255), w = math_floor(105 * scale), icon = "assimilation", prio = 3})
	end
	local pulse_val = smooth.pulse or 70
	if not stability.pulse.hidden then
		local r_pulse = math_min(pulse_val / 100, 1)
		local c_pulse = (pulse_val < 50 or pulse_val > 130) and Color(255, 80, 80) or Color(180, 220, 255)
		table.insert(segs, {label = "PULSE", val = math_floor(pulse_val), suf = "bpm", ratio = r_pulse, col = c_pulse, w = math_floor(80 * scale), icon = "pulse", prio = 4})
	end
	if #segs == 0 then return end
	table.sort(segs, function(a, b) return a.prio < b.prio end)
	local total_width = pad
	for _, seg in ipairs(segs) do total_width = total_width + seg.w + pad end
	if total_width > bar_w then
		local new_scale = (bar_w - pad) / (total_width - pad)
		scale = scale * new_scale * 0.98
		bar_w = math_floor(base_bar_w * scale)
		bar_h = math_floor(base_bar_h * scale)
		bar_x = ScrW() * 0.5 - bar_w * 0.5
		pad = math_floor(5 * scale)
		icon_size = math_floor(26 * scale)
		for i, seg in ipairs(segs) do
			segs[i].w = math_floor(segs[i].w * new_scale * 0.98)
		end
	end
	local x = bar_x + pad
	for _, seg in ipairs(segs) do
		local icon = icons[seg.icon]
		if icon and not icon:IsError() then
			surface_SetDrawColor(255, 255, 255, 255)
			surface_SetMaterial(icon)
			surface_DrawTexturedRect(x, bar_y + (bar_h - icon_size) * 0.5, icon_size, icon_size)
		else
			local letters = {blood = "B", o2 = "O", assimilation = "A", pulse = "♥"}
			surface_SetDrawColor(40, 40, 50, 200)
			surface_DrawRect(x + 1, bar_y + (bar_h - icon_size) * 0.5 + 1, icon_size - 2, icon_size - 2)
			surface_SetDrawColor(seg.col.r, seg.col.g, seg.col.b, 255)
			surface_DrawRect(x + 2, bar_y + (bar_h - icon_size) * 0.5 + 2, icon_size - 4, icon_size - 4)
			draw_SimpleText(letters[seg.icon] or "?", "TargetID", x + icon_size * 0.5, bar_y + bar_h * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		local meter_x = x + icon_size + math_floor(3 * scale)
		local meter_w = seg.w - icon_size - math_floor(10 * scale)
		local meter_y = bar_y + pad + math_floor(2 * scale)
		local meter_h = bar_h - pad * 2 - math_floor(4 * scale)
		surface_SetDrawColor(30, 30, 40, 180)
		surface_DrawRect(meter_x, meter_y, meter_w, meter_h)
		surface_SetDrawColor(seg.col.r, seg.col.g, seg.col.b, 200)
		surface_DrawRect(meter_x, meter_y, meter_w * seg.ratio, meter_h)
		surface_SetDrawColor(80, 80, 90, 230)
		surface_DrawOutlinedRect(meter_x, meter_y, meter_w, meter_h)
		local value_text = seg.val .. (seg.suf or "")
		local text_x = meter_x + math_floor(4 * scale)
		local text_y = bar_y + bar_h * 0.5
		draw_SimpleText(value_text, "DermaDefault", text_x, text_y, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		x = x + seg.w + pad
	end
end
local function draw_status_effects()
	if not HUD.enabled or not HUD.show_status_effects then
		statusEffectPositions = {}
		return
	end
	local ply = getViewPlayer()
	local org = getOrganism(ply)
	if not IsValid(ply) or not org then
		statusEffectPositions = {}
		return
	end
	local size = HUD.status_effects_size
	local currentTime = CurTime()
	local mx, my = gui.MousePos()
	if mx and my then
		hoverEffect.lastMouseX = mx
		hoverEffect.lastMouseY = my
	end
	local dead = isPlayerDead(ply)
	local berserkActive = isBerserkActive(org)
	local painVal = smooth.pain or getOrgVal(org, "pain", 0)
	if painVal >= 60 then
		hoverEffect.painShakeTime = currentTime
	end
	if berserkActive then
		hoverEffect.berserkShakeTime = currentTime
	end
	load_status_sprites()
	statusEffectPositions = {}
	local currentEffectNames = {}
	local effects = {}
	if dead then
		table.insert(effects, {
			name = "death",
			priority = -1000,
			value = nil
		})
		currentEffectNames["death"] = true
	else
		local hasChip = ply:GetNetVar("zb_has_healthchip", false) or
			(ply.organism and ply.organism.hasHealthChip == true) or
			ply.PlayerClassName == "furry" or
			ply.PlayerClassName == "Combine"
		if hasChip then
			table.insert(effects, {name = "chip", priority = -2})
			currentEffectNames["chip"] = true
		end
		local pain_val = smooth.pain or getOrgVal(org, "pain", 0)
		if pain_val > 10 and not berserkActive then
			local level_num = 1
			if pain_val >= 60 then level_num = 4
			elseif pain_val >= 40 then level_num = 3
			elseif pain_val >= 25 then level_num = 2 end
			table.insert(effects, {
				name = "pain",
				level_num = level_num,
				has_levels = true,
				priority = 0,
				value = math_floor(pain_val)
			})
			currentEffectNames["pain"] = true
		end
		if berserkActive then
			local berserk_val = org.berserk or 0
			local level_num = 1
			if berserk_val > 2.5 then level_num = 4
			elseif berserk_val > 1.5 then level_num = 3
			elseif berserk_val > 0.5 then level_num = 2 end
			table.insert(effects, {
				name = "berserk",
				level_num = level_num,
				has_levels = true,
				priority = -1,
				value = math_floor(berserk_val * 10) / 10
			})
			currentEffectNames["berserk"] = true
		end
		local showAllIcons = not berserkActive
		if berserkActive then
			local brain_val = smooth.brain or getOrgVal(org, "brain", 0)
			if brain_val > HUD.brain_damage_threshold then
				local level_num = 1
				if brain_val > 0.3 then level_num = 4
				elseif brain_val > 0.25 then level_num = 3
				elseif brain_val > 0.15 then level_num = 2 end
				table.insert(effects, {
					name = "brain_damage",
					level_num = level_num,
					has_levels = true,
					priority = 0.6,
					value = math_floor(brain_val * 100)
				})
				currentEffectNames["brain_damage"] = true
			end
			local spine1 = getOrgVal(org, "spine1", 0)
			local spine2 = getOrgVal(org, "spine2", 0)
			local spine3 = getOrgVal(org, "spine3", 0)
			local spine_fracture = spine1 >= HUD.fracture_threshold or spine2 >= HUD.fracture_threshold or spine3 >= HUD.fracture_threshold
			if spine_fracture then
				table.insert(effects, {name = "spine_fracture", priority = 3})
				currentEffectNames["spine_fracture"] = true
			end
			if hasAnyFracture(org, HUD.fracture_threshold) then
				table.insert(effects, {name = "fracture", priority = 6})
				currentEffectNames["fracture"] = true
			end
			if org.llegdislocation or org.rlegdislocation or
				org.larmdislocation or org.rarmdislocation or
				org.jawdislocation then
				table.insert(effects, {name = "dislocation", priority = 5})
				currentEffectNames["dislocation"] = true
			end
			local adrenaline_val = smooth.adrenaline or getOrgVal(org, "adrenaline", 0)
			if adrenaline_val > HUD.adrenaline_threshold then
				local level_num = 1
				if adrenaline_val > 2.1 then level_num = 4
				elseif adrenaline_val > 1.5 then level_num = 3
				elseif adrenaline_val > 0.8 then level_num = 2 end
				table.insert(effects, {
					name = "adrenaline",
					level_num = level_num,
					has_levels = true,
					priority = 0.65,
					value = math_floor(adrenaline_val * 10) / 10
				})
				currentEffectNames["adrenaline"] = true
			end
			local o2_val = getO2Value(org)
			if o2_val < HUD.oxygen_threshold then
				local level_num = 1
				if o2_val < 8 then level_num = 4
				elseif o2_val < 14 then level_num = 3
				elseif o2_val < 23 then level_num = 2 end
				table.insert(effects, {
					name = "oxygen",
					level_num = level_num,
					has_levels = true,
					priority = 0.5,
					value = math_floor(o2_val)
				})
				currentEffectNames["oxygen"] = true
			end
			local trauma_val = smooth.disorientation or getOrgVal(org, "disorientation", 0)
			if trauma_val > HUD.trauma_threshold then
				local level_num = 1
				if trauma_val > 3 then level_num = 4
				elseif trauma_val > 2.5 then level_num = 3
				elseif trauma_val > 1 then level_num = 2 end
				table.insert(effects, {
					name = "trauma",
					level_num = level_num,
					has_levels = true,
					priority = 0.75,
					value = math_floor(trauma_val * 10) / 10
				})
				currentEffectNames["trauma"] = true
			end
			if hasAnyAmputation(org) then
				table.insert(effects, {name = "amputant", priority = 8})
				currentEffectNames["amputant"] = true
			end
			if org.heartstop == true then
				table.insert(effects, {name = "cardiac_arrest", priority = 0.15})
				currentEffectNames["cardiac_arrest"] = true
			end
			if org.lungsfunction == false then
				table.insert(effects, {name = "lungs_failure", priority = 0.35})
				currentEffectNames["lungs_failure"] = true
			end
		end
		if showAllIcons then
			local bleed_val = smooth.bleed or getOrgVal(org, "bleed", 0)
			if bleed_val > HUD.bleeding_threshold then
				table.insert(effects, {
					name = "bleeding",
					priority = 0.3,
					value = math_floor(bleed_val)
				})
				currentEffectNames["bleeding"] = true
			end
			local internal_bleed_val = smooth.internalBleed or getOrgVal(org, "internalBleed", 0)
			if internal_bleed_val > HUD.internal_bleed_threshold then
				table.insert(effects, {
					name = "internal_bleed",
					priority = 0.4,
					value = math_floor(internal_bleed_val * 100)
				})
				currentEffectNames["internal_bleed"] = true
			end
			local cons_val = smooth.conscious or getOrgVal(org, "consciousness", 1)
			local cons_percent = math_floor(cons_val * 100)
			if cons_percent < 90 then
				local level_num = 1
				if cons_percent <= 24 then level_num = 4
				elseif cons_percent <= 49 then level_num = 3
				elseif cons_percent <= 74 then level_num = 2 end
				table.insert(effects, {
					name = "conscious",
					level_num = level_num,
					has_levels = true,
					priority = 1,
					value = cons_percent
				})
				currentEffectNames["conscious"] = true
			end
			local stamina_table = org.stamina
			if stamina_table and type(stamina_table) == "table" then
				local stamina_val = stamina_table[1] or 0
				local stamina_max = stamina_table.max or 180
				if stamina_max <= 0 then stamina_max = 180 end
				local stamina_percent = (stamina_val / stamina_max) * 100
				if stamina_percent < 75 then
					local level_num = 1
					if stamina_percent <= 24 then level_num = 4
					elseif stamina_percent <= 49 then level_num = 3
					elseif stamina_percent <= 74 then level_num = 2 end
					table.insert(effects, {
						name = "stamina",
						level_num = level_num,
						has_levels = true,
						priority = 2,
						value = math_floor(stamina_percent)
					})
					currentEffectNames["stamina"] = true
				end
			end
			local spine1 = getOrgVal(org, "spine1", 0)
			local spine2 = getOrgVal(org, "spine2", 0)
			local spine3 = getOrgVal(org, "spine3", 0)
			local spine_fracture = spine1 >= HUD.fracture_threshold or spine2 >= HUD.fracture_threshold or spine3 >= HUD.fracture_threshold
			if spine_fracture then
				table.insert(effects, {name = "spine_fracture", priority = 3})
				currentEffectNames["spine_fracture"] = true
			end
			if hasAnyFracture(org, HUD.fracture_threshold) then
				table.insert(effects, {name = "fracture", priority = 6})
				currentEffectNames["fracture"] = true
			end
			local organ_damage = math_max(
				getOrgVal(org, "heart", 0),
				getOrgVal(org, "liver", 0),
				getOrgVal(org, "stomach", 0),
				getOrgVal(org, "intestines", 0),
				getOrgTableVal(org, "lungsR", 1, nil, 0),
				getOrgTableVal(org, "lungsL", 1, nil, 0),
				getOrgTableVal(org, "lungsR", 2, nil, 0),
				getOrgTableVal(org, "lungsL", 2, nil, 0)
			)
			if organ_damage > HUD.organ_damage_threshold then
				table.insert(effects, {name = "organ_damage", priority = 4})
				currentEffectNames["organ_damage"] = true
			end
			if org.llegdislocation or org.rlegdislocation or
				org.larmdislocation or org.rarmdislocation or
				org.jawdislocation then
				table.insert(effects, {name = "dislocation", priority = 5})
				currentEffectNames["dislocation"] = true
			end
			local blood_val = smooth.blood or getOrgVal(org, "blood", 5000)
			if blood_val < HUD.blood_loss_threshold then
				local level_num = 1
				if blood_val < 2500 then level_num = 4
				elseif blood_val < 3600 then level_num = 3
				elseif blood_val < 4500 then level_num = 2 end
				table.insert(effects, {
					name = "blood_loss",
					level_num = level_num,
					has_levels = true,
					priority = 0.1,
					value = math_floor(blood_val)
				})
				currentEffectNames["blood_loss"] = true
			end
			if org.heartstop == true then
				table.insert(effects, {
					name = "cardiac_arrest",
					priority = 0.15
				})
				currentEffectNames["cardiac_arrest"] = true
			end
			local temp_val = smooth.temperature or getOrgVal(org, "temperature", 36.7)
			if temp_val < HUD.cold_threshold then
				local level_num = 1
				if temp_val < 31 then level_num = 4
				elseif temp_val < 33 then level_num = 3
				elseif temp_val < 35 then level_num = 2 end
				table.insert(effects, {
					name = "cold",
					level_num = level_num,
					has_levels = true,
					priority = 0.2,
					value = math_floor(temp_val * 10) / 10
				})
				currentEffectNames["cold"] = true
			end
			if temp_val > HUD.heat_threshold then
				local level_num = 1
				if temp_val > 40 then level_num = 4
				elseif temp_val > 39 then level_num = 3
				elseif temp_val > 38 then level_num = 2 end
				table.insert(effects, {
					name = "heat",
					level_num = level_num,
					has_levels = true,
					priority = 0.2,
					value = math_floor(temp_val * 10) / 10
				})
				currentEffectNames["heat"] = true
			end
			local pneumo_val = smooth.pneumothorax or getOrgVal(org, "pneumothorax", 0)
			if pneumo_val > HUD.hemothorax_threshold then
				local level_num = 1
				if pneumo_val > 0.7 then level_num = 4
				elseif pneumo_val > 0.3 then level_num = 3
				elseif pneumo_val > 0.1 then level_num = 2 end
				table.insert(effects, {
					name = "hemothorax",
					level_num = level_num,
					has_levels = true,
					priority = 0.25,
					value = math_floor(pneumo_val * 100)
				})
				currentEffectNames["hemothorax"] = true
			end
			if org.lungsfunction == false then
				table.insert(effects, {
					name = "lungs_failure",
					priority = 0.35
				})
				currentEffectNames["lungs_failure"] = true
			end
			local analgesia_val = smooth.analgesia or getOrgVal(org, "analgesia", 0)
			if analgesia_val > 0.1 then
				local level_num = 1
				if analgesia_val > 2 then level_num = 4
				elseif analgesia_val > 1.6 then level_num = 3
				elseif analgesia_val > 1 then level_num = 2 end
				table.insert(effects, {
					name = "overdose",
					level_num = level_num,
					has_levels = true,
					priority = 0.45,
					value = math_floor(analgesia_val * 10) / 10
				})
				currentEffectNames["overdose"] = true
			end
			local o2_val = getO2Value(org)
			if o2_val < HUD.oxygen_threshold then
				local level_num = 1
				if o2_val < 8 then level_num = 4
				elseif o2_val < 14 then level_num = 3
				elseif o2_val < 23 then level_num = 2 end
				table.insert(effects, {
					name = "oxygen",
					level_num = level_num,
					has_levels = true,
					priority = 0.5,
					value = math_floor(o2_val)
				})
				currentEffectNames["oxygen"] = true
			end
			local vomit_val = smooth.wantToVomit or getOrgVal(org, "wantToVomit", 0)
			if vomit_val > HUD.vomit_threshold then
				local level_num = 1
				if vomit_val > 0.9 then level_num = 4
				elseif vomit_val > 0.8 then level_num = 3
				elseif vomit_val > 0.6 then level_num = 2 end
				table.insert(effects, {
					name = "vomit",
					level_num = level_num,
					has_levels = true,
					priority = 0.55,
					value = math_floor(vomit_val * 100)
				})
				currentEffectNames["vomit"] = true
			end
			local brain_val = smooth.brain or getOrgVal(org, "brain", 0)
			if brain_val > HUD.brain_damage_threshold then
				local level_num = 1
				if brain_val > 0.3 then level_num = 4
				elseif brain_val > 0.25 then level_num = 3
				elseif brain_val > 0.15 then level_num = 2 end
				table.insert(effects, {
					name = "brain_damage",
					level_num = level_num,
					has_levels = true,
					priority = 0.6,
					value = math_floor(brain_val * 100)
				})
				currentEffectNames["brain_damage"] = true
			end
			local adrenaline_val = smooth.adrenaline or getOrgVal(org, "adrenaline", 0)
			if adrenaline_val > HUD.adrenaline_threshold then
				local level_num = 1
				if adrenaline_val > 2.1 then level_num = 4
				elseif adrenaline_val > 1.5 then level_num = 3
				elseif adrenaline_val > 0.8 then level_num = 2 end
				table.insert(effects, {
					name = "adrenaline",
					level_num = level_num,
					has_levels = true,
					priority = 0.65,
					value = math_floor(adrenaline_val * 10) / 10
				})
				currentEffectNames["adrenaline"] = true
			end
			local shock_val = smooth.shock or getOrgVal(org, "shock", 0)
			if shock_val > HUD.shock_threshold then
				local level_num = 1
				if shock_val > 35 then level_num = 4
				elseif shock_val > 25 then level_num = 3
				elseif shock_val > 10 then level_num = 2 end
				table.insert(effects, {
					name = "shock",
					level_num = level_num,
					has_levels = true,
					priority = 0.7,
					value = math_floor(shock_val)
				})
				currentEffectNames["shock"] = true
			end
			local trauma_val = smooth.disorientation or getOrgVal(org, "disorientation", 0)
			if trauma_val > HUD.trauma_threshold then
				local level_num = 1
				if trauma_val > 3 then level_num = 4
				elseif trauma_val > 2.5 then level_num = 3
				elseif trauma_val > 1 then level_num = 2 end
				table.insert(effects, {
					name = "trauma",
					level_num = level_num,
					has_levels = true,
					priority = 0.75,
					value = math_floor(trauma_val * 10) / 10
				})
				currentEffectNames["trauma"] = true
			end
			if hasAnyAmputation(org) then
				table.insert(effects, {name = "amputant", priority = 8})
				currentEffectNames["amputant"] = true
			end
			local arterialwounds = ply:GetNetVar("arterialwounds")
			local hasArterialBleed = (org.arteria == 1) or
				(org.rarmarteria == 1) or (org.larmarteria == 1) or
				(org.rlegarteria == 1) or (org.llegarteria == 1) or
				(arterialwounds and next(arterialwounds) ~= nil)
			if hasArterialBleed then
				table.insert(effects, {name = "bleedartery", priority = 0.05})
				currentEffectNames["bleedartery"] = true
			end
			if not currentEffectNames["cardiac_arrest"] then
				local pulse_v = getOrgVal(org, "pulse", 70)
				local heartbeat_v = getOrgVal(org, "heartbeat", 220)
				if pulse_v <= 20 and heartbeat_v >= 200 then
					table.insert(effects, {name = "fibrillation", priority = 0.08})
					currentEffectNames["fibrillation"] = true
				elseif pulse_v <= 40 and heartbeat_v >= 170 then
					table.insert(effects, {name = "arrhythmia", priority = 0.12})
					currentEffectNames["arrhythmia"] = true
				end
			end
		end
	end
	for name, _ in pairs(statusEffectAppearance) do
		if not currentEffectNames[name] then
			statusEffectAppearance[name] = nil
		end
	end
	for _, effect in ipairs(effects) do
		if not statusEffectAppearance[effect.name] then
			statusEffectAppearance[effect.name] = currentTime
		end
	end
	table.sort(effects, function(a, b) return a.priority < b.priority end)
	local count = #effects
	if count == 0 then return end
	local gap = HUD.status_effects_gap
	local totalWidth = count * size + math_max(count - 1, 0) * gap
	local start_x = ScrW() * 0.5 - totalWidth * 0.5
	local row_y = ScrH() - size - HUD.status_effects_bottom_margin
	local rawPositions = {}
	for i, effect in ipairs(effects) do
		local base_x_pos = start_x + (i - 1) * (size + gap)
		local base_y_pos = row_y
		table.insert(rawPositions, {
			x = base_x_pos,
			y = base_y_pos,
			index = i,
			effect = effect
		})
	end
	local hoveredIndex = nil
	if mx and my then
		for i, pos in ipairs(rawPositions) do
			if mx >= pos.x and mx <= pos.x + size and my >= pos.y and my <= pos.y + size then
				hoveredIndex = i
				break
			end
		end
	end
	if hoveredIndex then
		if hoverEffect.hoveredIndex ~= hoveredIndex then
			hoverEffect.hoveredIndex = hoveredIndex
			hoverEffect.hoverTime = currentTime
		end
	else
		hoverEffect.hoveredIndex = nil
	end
	local mouseOffsetX = 0
	local mouseOffsetY = 0
	if hoverEffect.hoveredIndex and mx and my then
		local hoveredPos = rawPositions[hoverEffect.hoveredIndex]
		if hoveredPos then
			local centerX = hoveredPos.x + size / 2
			local centerY = hoveredPos.y + size / 2
			local distX = mx - centerX
			local distY = my - centerY
			local maxDist = 30
			mouseOffsetX = math_min(math_max(distX * 0.15, -maxDist), maxDist)
			mouseOffsetY = math_min(math_max(distY * 0.15, -maxDist), maxDist)
		end
	end
	local targetScale = hoverEffect.hoveredIndex and 1.35 or 1.0
	hoverEffect.scale = Lerp(0.2, hoverEffect.scale, targetScale)
	local painShakeX, painShakeY = 0, 0
	if painVal > 20 then
		local painIntensity = math_min((painVal - 20) / 80, 1)
		local baseShake = painIntensity * 5
		painShakeX = math_sin(currentTime * 120) * baseShake * 0.8 + math_sin(currentTime * 70) * baseShake * 0.4
		painShakeY = math_cos(currentTime * 2) * baseShake * 0.8 + math_cos(currentTime * 2) * baseShake * 0.4
	end
	local beatShakeX, beatShakeY = 0, 0
	local beatScale = 1.0
	if berserkActive and hg and hg.berserkStation and IsValid(hg.berserkStation) then
		local offsetVal = 0.85
		local bpmVal = 70
		local stationTime = hg.berserkStation:GetTime()
		local beat = 1 - ((stationTime - offsetVal) / 60 * bpmVal)
		beat = (beat - math.Round(beat)) % 1
		local beatIntensity = math.abs(math.sin(beat * math.pi * 2)) ^ 2
		local beatTime = currentTime * (bpmVal / 60 * math.pi * 2)
		beatShakeX = math_sin(beatTime) * beatIntensity * 5
		beatShakeY = math_cos(beatTime * 0.8) * beatIntensity * 4
		beatScale = 1.0 + beatIntensity * 0.2
	end
	for i, pos in ipairs(rawPositions) do
		local effect = pos.effect
		local base_x_pos = pos.x
		local base_y_pos = pos.y
		local repelX = 0
		local repelY = 0
		local scale = 1.0
		local offsetX = 0
		local offsetY = 0
		if hoverEffect.hoveredIndex then
			local dist = i - hoverEffect.hoveredIndex
			if dist == 0 then
				scale = hoverEffect.scale
				offsetX = mouseOffsetX
				offsetY = mouseOffsetY
			else
				local distAbs = math_abs(dist)
				local repelStrength = (hoverEffect.scale - 1) * size * 0.8
				local hoveredPos = rawPositions[hoverEffect.hoveredIndex]
				if hoveredPos then
					local dx = base_x_pos - hoveredPos.x
					local dy = base_y_pos - hoveredPos.y
					local distance = math_sqrt(dx * dx + dy * dy)
					if distance > 0 then
						local normX = dx / distance
						local normY = dy / distance
						local falloff = 1 / (1 + distAbs * 0.3)
						repelX = normX * repelStrength * falloff
						repelY = normY * repelStrength * falloff * 0.5
					end
				end
			end
		end
		scale = scale * beatScale
		local shakeOffset = 0
		local appearanceTime = statusEffectAppearance[effect.name]
		if appearanceTime then
			local timeActive = currentTime - appearanceTime
			if timeActive < 1.5 then
				local easeOut = (1 - timeActive) ^ 3
				shakeOffset = math_sin(timeActive * 18) * easeOut * 30
			end
		end
		local final_x = base_x_pos + repelX + painShakeX + beatShakeX
		local final_y = base_y_pos + repelY - shakeOffset + painShakeY + beatShakeY
		table.insert(statusEffectPositions, {
			x = final_x,
			y = final_y,
			size = size,
			name = effect.name,
			level_num = effect.level_num,
			value = effect.value
		})
		local drawSize = size * scale
		local drawX = final_x - (drawSize - size) / 2
		local drawY = final_y - (drawSize - size) / 2
		local bg_mat
		if effect.has_levels then
			bg_mat = status_sprites.level_backgrounds[effect.level_num] or status_sprites.background
		else
			bg_mat = status_sprites.background
		end
		if bg_mat and not bg_mat:IsError() then
			surface_SetDrawColor(255, 255, 255, 220)
			surface_SetMaterial(bg_mat)
			surface_DrawTexturedRect(drawX + offsetX * 0.5, drawY + offsetY * 0.5, drawSize, drawSize)
		else
			local bg_color = Color(40, 40, 50, 220)
			if effect.name == "bleeding" then bg_color = Color(180, 30, 30, 220)
			elseif effect.name == "internal_bleed" then bg_color = Color(200, 50, 100, 220)
			elseif effect.name == "blood_loss" then bg_color = Color(150, 0, 0, 220)
			elseif effect.name == "cardiac_arrest" then bg_color = Color(100, 0, 100, 220)
			elseif effect.name == "cold" then bg_color = Color(0, 100, 200, 220)
			elseif effect.name == "heat" then bg_color = Color(200, 100, 0, 220)
			elseif effect.name == "hemothorax" then bg_color = Color(150, 50, 0, 220)
			elseif effect.name == "lungs_failure" then bg_color = Color(100, 100, 100, 220)
			elseif effect.name == "overdose" then bg_color = Color(150, 0, 150, 220)
			elseif effect.name == "oxygen" then bg_color = Color(0, 50, 150, 220)
			elseif effect.name == "vomit" then bg_color = Color(100, 80, 0, 220)
			elseif effect.name == "brain_damage" then bg_color = Color(100, 0, 50, 220)
			elseif effect.name == "adrenaline" then bg_color = Color(255, 100, 0, 220)
			elseif effect.name == "shock" then bg_color = Color(100, 100, 200, 220)
			elseif effect.name == "trauma" then bg_color = Color(150, 50, 150, 220)
			elseif effect.name == "death" then bg_color = Color(0, 0, 0, 220)
			elseif effect.name == "berserk" then bg_color = Color(180, 0, 0, 220)
			elseif effect.name == "amputant" then bg_color = Color(80, 40, 40, 220)
			elseif effect.name == "fracture" then bg_color = Color(200, 100, 0, 220)
			elseif effect.name == "chip" then bg_color = Color(0, 200, 255, 220)
			elseif effect.name == "bleedartery" then bg_color = Color(180, 0, 0, 220)
			elseif effect.name == "arrhythmia" then bg_color = Color(180, 80, 0, 220)
			elseif effect.name == "fibrillation" then bg_color = Color(150, 0, 80, 220)
			elseif effect.has_levels then
				if effect.level_num == 4 then bg_color = Color(180, 30, 30, 220)
				elseif effect.level_num == 3 then bg_color = Color(220, 60, 30, 220)
				elseif effect.level_num == 2 then bg_color = Color(255, 140, 40, 220)
				else bg_color = Color(80, 200, 100, 220) end
			end
			surface_SetDrawColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
			surface_DrawRect(drawX, drawY, drawSize, drawSize)
		end
		local icon_mat = nil
		if effect.name == "pain" then icon_mat = status_sprites.pain_icon
		elseif effect.name == "conscious" then icon_mat = status_sprites.conscious_icon
		elseif effect.name == "stamina" then icon_mat = status_sprites.stamina_icon
		elseif effect.name == "bleeding" then icon_mat = status_sprites.bleeding_icon
		elseif effect.name == "internal_bleed" then icon_mat = status_sprites.internal_bleed_icon
		elseif effect.name == "blood_loss" then icon_mat = status_sprites.blood_loss
		elseif effect.name == "cardiac_arrest" then icon_mat = status_sprites.cardiac_arrest
		elseif effect.name == "cold" then icon_mat = status_sprites.cold
		elseif effect.name == "heat" then icon_mat = status_sprites.heat
		elseif effect.name == "hemothorax" then icon_mat = status_sprites.hemothorax
		elseif effect.name == "lungs_failure" then icon_mat = status_sprites.lungs_failure
		elseif effect.name == "overdose" then icon_mat = status_sprites.overdose
		elseif effect.name == "oxygen" then icon_mat = status_sprites.oxygen
		elseif effect.name == "vomit" then icon_mat = status_sprites.vomit
		elseif effect.name == "brain_damage" then icon_mat = status_sprites.brain_damage
		elseif effect.name == "adrenaline" then icon_mat = status_sprites.adrenaline
		elseif effect.name == "shock" then icon_mat = status_sprites.shock
		elseif effect.name == "trauma" then icon_mat = status_sprites.trauma
		elseif effect.name == "death" then icon_mat = status_sprites.death
		elseif effect.name == "berserk" then icon_mat = status_sprites.berserk
		elseif effect.name == "amputant" then icon_mat = status_sprites.amputant
		elseif effect.name == "fracture" then icon_mat = status_sprites.fracture
		elseif effect.name == "chip" then icon_mat = status_sprites.chip
		elseif effect.name == "bleedartery" then icon_mat = status_sprites.bleedartery
		elseif effect.name == "arrhythmia" then icon_mat = status_sprites.arrhythmia
		elseif effect.name == "fibrillation" then icon_mat = status_sprites.fibrillation
		else icon_mat = status_sprites[effect.name] end
		if icon_mat and not icon_mat:IsError() then
			surface_SetDrawColor(255, 255, 255, 255)
			surface_SetMaterial(icon_mat)
			local iconDrawSize = drawSize - 4
			local iconDrawX = drawX + 2 + offsetX
			local iconDrawY = drawY + 2 + offsetY
			surface_DrawTexturedRect(iconDrawX, iconDrawY, iconDrawSize, iconDrawSize)
		else
			local letterColor = berserkActive and Color(255, 100, 100, 255) or Color(255, 255, 255, 255)
			local letter = "?"
			local value_text = ""
			if effect.name == "pain" then letter = "P" value_text = effect.value .. ""
			elseif effect.name == "conscious" then letter = "C" value_text = effect.value .. "%"
			elseif effect.name == "stamina" then letter = "S" value_text = effect.value .. "%"
			elseif effect.name == "bleeding" then letter = "B" value_text = effect.value .. ""
			elseif effect.name == "internal_bleed" then letter = "IB" value_text = effect.value .. "%"
			elseif effect.name == "blood_loss" then letter = "BL" value_text = effect.value .. "ml"
			elseif effect.name == "cardiac_arrest" then letter = "CA"
			elseif effect.name == "cold" then letter = "C" value_text = effect.value .. "°C"
			elseif effect.name == "heat" then letter = "H" value_text = effect.value .. "°C"
			elseif effect.name == "hemothorax" then letter = "HX" value_text = effect.value .. "%"
			elseif effect.name == "lungs_failure" then letter = "LF"
			elseif effect.name == "overdose" then letter = "OD" value_text = effect.value .. ""
			elseif effect.name == "oxygen" then letter = "O2" value_text = effect.value .. "%"
			elseif effect.name == "vomit" then letter = "V" value_text = effect.value .. "%"
			elseif effect.name == "brain_damage" then letter = "BD" value_text = effect.value .. "%"
			elseif effect.name == "adrenaline" then letter = "A" value_text = effect.value .. ""
			elseif effect.name == "shock" then letter = "SH" value_text = effect.value .. ""
			elseif effect.name == "trauma" then letter = "T" value_text = effect.value .. ""
			elseif effect.name == "death" then letter = "☠"
			elseif effect.name == "berserk" then letter = "⚡" value_text = effect.value .. ""
			elseif effect.name == "amputant" then letter = "✂"
			elseif effect.name == "fracture" then letter = "F"
			elseif effect.name == "chip" then letter = "CHIP"
			elseif effect.name == "bleedartery" then letter = "BA"
			elseif effect.name == "arrhythmia" then letter = "AR"
			elseif effect.name == "fibrillation" then letter = "FB"
			else
				local letters = {spine_fracture = "SF", organ_damage = "OD", dislocation = "D"}
				letter = letters[effect.name] or "?"
			end
			draw_SimpleText(letter, "TargetID", drawX + drawSize * 0.4 + offsetX, drawY + drawSize * 0.3 + offsetY, letterColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			if value_text ~= "" then
				draw_SimpleText(value_text, "DermaDefault", drawX + drawSize * 0.5 + offsetX, drawY + drawSize * 0.7 + offsetY, letterColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end
end
surface.CreateFont("GPS_Nickname", {
	font = "Montserrat SemiBold",
	extended = true,
	size = 18,
	antialias = true
})
local color_gray = Color(50, 50, 50, 200)
local color_white = Color(255, 255, 255)
local color_accent = Color(0, 150, 255)
local function getMesureXTxt(txt, add, font)
	surface.SetFont(font or "GPS_Nickname")
	return select(1, surface.GetTextSize(txt or "")) + add
end
local toltipe
create_toltip = function(panel, text, color)
	if not IsValid(toltipe) then
		local pos_x, pos_y = input.GetCursorPos()
		toltipe = vgui.Create("DPanel")
		toltipe.panel_from = panel
		toltipe.text = text or "Задайте колонтитул"
		toltipe.text_size = getMesureXTxt(toltipe.text, 20)
		toltipe:InvalidateLayout(true)
		toltipe:SetDrawOnTop(true)
		toltipe:SetPos(pos_x + 10, pos_y + 30)
		toltipe:SetSize(0, 23)
		toltipe:SizeTo(toltipe.text_size, 23, 0.3, 0, -1, function() end)
		toltipe.Paint = function(self, w, h)
			if not IsValid(self.panel_from) then self:Remove(); return end
			drusherLib.draw.drawBlur(self, 3)
			draw.RoundedBox(10, 0, 0, w, h, color or color_gray)
			draw.SimpleText(self.text, "GPS_Nickname", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			if self.panel_from != panel then self:Remove() return end
			local pos_x, pos_y = input.GetCursorPos()
			toltipe:SetPos(pos_x + 10, pos_y + 30)
			local w, h = panel:GetSize()
			local lx, ly = panel:LocalToScreen(0, 0)
			if pos_x > lx + w or pos_x < lx then self:Remove() end
			if pos_y > ly + h or pos_y < ly then self:Remove() end
		end
	else
		if not IsValid(toltipe.panel_from) then toltipe:Remove(); return end
	end
	return toltipe
end
create_toltip_multiline = function(panel, tab)
	if not IsValid(toltipe) then
		toltipe = vgui.Create("DPanel")
		toltipe.panel_from = panel
		panel.toltipe = toltipe
		toltipe.tab = {}
		toltipe.color = tab.color or Color(26, 26, 26, 200)
		local size_x = 0
		local total_lines = 0
		for k, v in ipairs(tab) do
			local lines = string.Explode("\n", v.text)
			for _, line in ipairs(lines) do
				total_lines = total_lines + 1
				if getMesureXTxt(line, 10) > size_x then
					size_x = getMesureXTxt(line, 10)
				end
				table.insert(toltipe.tab, {
					text = line,
					color = v.color or Color(255, 255, 255)
				})
			end
		end
		local size_y = 5 + total_lines * 23
		local screen_w, screen_h = ScrW(), ScrH()
		local function computePos()
			local px, py = panel:LocalToScreen(0, 0)
			local pw, ph = panel:GetSize()
			local cx, cy = input.GetCursorPos()
			local tip_x = cx - size_x / 2
			local tip_y = py - size_y - 22
			if tip_x < 5 then tip_x = 5 end
			if tip_x + size_x > screen_w - 5 then tip_x = screen_w - size_x - 5 end
			if tip_y < 5 then tip_y = py + ph + 22 end
			if tip_y + size_y > screen_h - 5 then tip_y = screen_h - size_y - 5 end
			if tip_y < 5 then tip_y = 5 end
			return tip_x, tip_y
		end
		toltipe:InvalidateLayout(true)
		toltipe:SetDrawOnTop(true)
		local start_x, start_y = computePos()
		toltipe:SetPos(start_x, start_y)
		toltipe:SetSize(0, 0)
		toltipe:SizeTo(size_x, size_y, 0.2, 0, -1, function() end)
		toltipe.Paint = function(self, w, h)
			if not IsValid(self.panel_from) then
				self:Remove()
				return
			end
			drusherLib.draw.drawBlur(self, 3)
			draw.RoundedBox(4, 0, 0, w, h, self.color)
			local y = 5
			for k, v in ipairs(self.tab) do
				draw.SimpleText(v.text, "GPS_Nickname", 5, y, v.color, TEXT_ALIGN_LEFT)
				y = y + 23
			end
			if self.panel_from ~= panel then
				self:Remove()
				return
			end
			local tip_x, tip_y = computePos()
			toltipe:SetPos(tip_x, tip_y)
			local cx, cy = input.GetCursorPos()
			local px, py = panel:LocalToScreen(0, 0)
			local pw, ph = panel:GetSize()
			if cx > px + pw or cx < px then
				self:Remove()
			end
			if cy > py + ph or cy < py then
				self:Remove()
			end
		end
	else
		if not IsValid(toltipe.panel_from) then
			print(4)
			toltipe:Remove()
			return
		end
	end
	return toltipe
end
local statusTooltipPanel
local function removeStatusTooltipPanel()
	if IsValid(statusTooltipPanel) then statusTooltipPanel:Remove() end
	statusTooltipPanel = nil
end
local function draw_status_tooltips()
	if not HUD.enabled or not HUD.show_status_effects or #statusEffectPositions == 0 then
		removeStatusTooltipPanel()
		return
	end
	if not isAnyMenuOpen() then
		removeStatusTooltipPanel()
		return
	end
	local mx, my = gui.MousePos()
	if not mx or mx == 0 then
		removeStatusTooltipPanel()
		return
	end
	local ply = getViewPlayer()
	local org = getOrganism(ply)
	local berserkActive = IsValid(ply) and org and isBerserkActive(org) or false
	local hoveredStatus = nil
	local hoveredPos = nil
	for idx, pos in ipairs(statusEffectPositions) do
		if mx >= pos.x and mx <= pos.x + pos.size and my >= pos.y and my <= pos.y + pos.size then
			hoveredStatus = pos.name
			hoveredPos = pos
			break
		end
	end
	if not hoveredStatus or not hoveredPos then
		removeStatusTooltipPanel()
		return
	end
	local tooltipText = getTooltipText(hoveredStatus, hoveredPos, berserkActive)
	if not tooltipText or tooltipText == "" then
		removeStatusTooltipPanel()
		return
	end
	if IsValid(statusTooltipPanel) and statusTooltipPanel.statusName ~= hoveredStatus then
		removeStatusTooltipPanel()
	end
	if not IsValid(statusTooltipPanel) then
		statusTooltipPanel = vgui.Create("DPanel")
		statusTooltipPanel.Paint = function() end
		statusTooltipPanel.statusName = hoveredStatus
	end
	statusTooltipPanel:SetSize(hoveredPos.size, hoveredPos.size)
	statusTooltipPanel:SetPos(hoveredPos.x, hoveredPos.y)
	create_toltip_multiline(statusTooltipPanel, {
		color = Color(26, 26, 26, 220),
		{ text = tooltipText, color = Color(255, 255, 255) }
	})
end
local function draw_sprites()
	if not HUD.enabled then return end
	local lply = LocalPlayer()
	local ply = getViewPlayer()
	local org = getOrganism(ply)
	if not IsValid(ply) or not org then return end
	if isPlayerDead(ply) then return end
	if ply == lply and lply:GetObserverMode() ~= OBS_MODE_NONE then return end
	if HUD.base_x == nil then HUD.base_x = ScrW() - 118 end
	local base_x = HUD.base_x
	local base_y = 60
	local dt = FrameTime() * HUD.limb_fade_speed
	if not debug_done then
		debug_done = true
		local paths = {
			head = {"vgui/hud/health_head.png", "vgui/hud/health_head"},
			torso = {"vgui/hud/health_torso.png", "vgui/hud/health_torso"},
			right_arm = {"vgui/hud/health_right_arm.png", "vgui/hud/health_right_arm"},
			left_arm = {"vgui/hud/health_left_arm.png", "vgui/hud/health_left_arm"},
			right_leg = {"vgui/hud/health_right_leg.png", "vgui/hud/health_right_leg"},
			left_leg = {"vgui/hud/health_left_leg.png", "vgui/hud/health_left_leg"},
		}
		for name, tries in pairs(paths) do
			for _, path in ipairs(tries) do
				local mat = Material(path, "smooth")
				if mat and not mat:IsError() then
					sprites[name] = mat
					break
				end
			end
			if not sprites[name] then sprites[name] = false end
		end
	end
	local anyDamage = hasAnyLimbDamage(org)
	if anyDamage and not limbsRevealed then
		limbsRevealed = true
	elseif not anyDamage and limbsRevealed then
		limbsRevealed = false
	end
	local limbs = {
		{name = "head", dmg = math_max(getOrgVal(org, "skull", 0), getOrgVal(org, "jaw", 0) * 0.7), amput = "headamputated", label = "H"},
		{name = "torso", dmg = math_max(getOrgVal(org, "chest", 0), getOrgVal(org, "spine1", 0), getOrgVal(org, "spine2", 0), getOrgVal(org, "spine3", 0), getOrgVal(org, "pelvis", 0) * 0.9), amput = nil, label = "T"},
		{name = "right_arm", dmg = getOrgVal(org, "rarm", 0), amput = "rarmamputated", label = "RA"},
		{name = "left_arm", dmg = getOrgVal(org, "larm", 0), amput = "larmamputated", label = "LA"},
		{name = "right_leg", dmg = getOrgVal(org, "rleg", 0), amput = "rlegamputated", label = "RL"},
		{name = "left_leg", dmg = getOrgVal(org, "lleg", 0), amput = "llegamputated", label = "LL"},
	}
	for _, limb in ipairs(limbs) do
		local state = limbFadeStates[limb.name]
		if not state then continue end
		if limb.amput and org[limb.amput] then
			state.target = 0
		else
			if HUD.always_show_limbs then
				state.target = 255
			else
				state.target = limbsRevealed and 255 or 0
			end
		end
		state.alpha = Lerp(dt, state.alpha, state.target)
		if state.alpha < 1 then
			continue
		end
		local dmg = limb.dmg
		local ofs = HUD.limb_offsets[limb.name] or {x = 0, y = 0}
		local scale = HUD.limb_scale[limb.name] or {w = 1.0, h = 1.0}
		local x = base_x + ofs.x
		local y = base_y + ofs.y
		local base_size = 40
		local width = base_size * scale.w
		local height = base_size * scale.h
		local col = getLimbColor(dmg)
		local damage_boost = math_min(dmg * 150, 100)
		local total_visibility = math_min(HUD.sprite_visibility + damage_boost, 100)
		local alpha = math_floor(state.alpha * (total_visibility / 100))
		local mat = sprites[limb.name]
		if mat and not mat:IsError() then
			surface_SetDrawColor(col.r, col.g, col.b, alpha)
			surface_SetMaterial(mat)
			surface_DrawTexturedRect(x - width * 0.5, y - height * 0.5, width, height)
		else
			surface_SetDrawColor(0, 0, 0, math_floor(alpha * 0.5))
			surface_DrawRect(x - width * 0.5 + 2, y - height * 0.5 + 2, width - 4, height - 4)
			surface_SetDrawColor(col.r, col.g, col.b, alpha)
			surface_DrawRect(x - width * 0.5 + 4, y - height * 0.5 + 4, width - 8, height - 8)
			draw_SimpleText(limb.label, "TargetID", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end
local GIVEUP_KEY = KEY_J
local GIVEUP_HOLD = 3
local DISMISS_KEY = KEY_X
local giveup = {
	holding = 0,
	sent = false,
	active = false,
	reason = nil,
	alpha = 0,
	dismissed = false,
	dismissKeyWasDown = false,
}
local function getGiveupReason()
	local lply = LocalPlayer()
	if not IsValid(lply) or not lply:Alive() then return nil end
	local org = lply.new_organism or lply.organism
	if not istable(org) then return nil end
	if org.otrub == true then return "uncon" end
	if org.canmove == false then return "paralyzed" end
	return nil
end
local function resetGiveup(clearDismiss)
	giveup.active = false
	giveup.reason = nil
	giveup.holding = 0
	giveup.sent = false
	giveup.alpha = 0
	giveup.dismissKeyWasDown = false
	if clearDismiss then giveup.dismissed = false end
end
hook.Add("Think", "ZB_Health_GiveupInput", function()
	local reason = getGiveupReason()
	if reason == nil then
		resetGiveup(true)
		return
	end
	if giveup.reason ~= reason then
		giveup.reason = reason
		giveup.holding = 0
		giveup.sent = false
		giveup.dismissed = false
	end
	giveup.active = true
	local typing = IsValid(vgui.GetKeyboardFocus()) or gui.IsGameUIVisible()
	if not typing and input.IsKeyDown(DISMISS_KEY) then
		if not giveup.dismissKeyWasDown then
			giveup.dismissed = not giveup.dismissed
			giveup.holding = 0
		end
		giveup.dismissKeyWasDown = true
	else
		giveup.dismissKeyWasDown = false
	end
	if giveup.dismissed then
		giveup.holding = 0
		return
	end
	if input.IsKeyDown(GIVEUP_KEY) and not typing then
		giveup.holding = giveup.holding + FrameTime()
		if giveup.holding >= GIVEUP_HOLD and not giveup.sent then
			giveup.sent = true
			net.Start("zb_hud_giveup")
			net.SendToServer()
		end
	else
		giveup.holding = 0
	end
end)
local GIVEUP_SCALE = 1
local function ZB_CreateGiveupFonts()
	GIVEUP_SCALE = math_max(ScrH() / 1080, 0.7)
	local function sz(base) return math.Round(base * GIVEUP_SCALE) end
	surface.CreateFont("ZB_Giveup_Title", {
		font = "Montserrat Medium",
		size = sz(52),
		weight = 600,
		antialias = true,
		extended = true,
	})
	surface.CreateFont("ZB_Giveup_Desc", {
		font = "Montserrat Medium",
		size = sz(30),
		weight = 500,
		antialias = true,
		extended = true,
	})
	surface.CreateFont("ZB_Giveup_Text", {
		font = "Montserrat Medium",
		size = sz(25),
		weight = 500,
		antialias = true,
		extended = true,
	})
	surface.CreateFont("ZB_Giveup_Small", {
		font = "Montserrat Medium",
		size = sz(21),
		weight = 500,
		antialias = true,
		extended = true,
	})
end
ZB_CreateGiveupFonts()
hook.Add("OnScreenSizeChanged", "ZB_Health_GiveupFonts", ZB_CreateGiveupFonts)
local GIVEUP_GLOW_OFFSETS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 } }
local function giveupText(text, font, tx, ty, col, ax, ay, a, glow, pulse)
	if glow then
		local g = math_floor(a * (0.10 + 0.30 * (pulse or 0)))
		if g > 1 then
			local spread = 3 * GIVEUP_SCALE
			for i = 1, #GIVEUP_GLOW_OFFSETS do
				local o = GIVEUP_GLOW_OFFSETS[i]
				draw_SimpleText(text, font, tx + o[1] * spread, ty + o[2] * spread, Color(glow.r, glow.g, glow.b, g), ax, ay)
			end
		end
	end
	draw_SimpleText(text, font, tx + 2, ty + 2, Color(0, 0, 0, math_floor(a * 0.8)), ax, ay)
	draw_SimpleText(text, font, tx, ty, col, ax, ay)
end
local function draw_giveup()
	if not HUD.enabled then giveup.alpha = 0 return end
	if not giveup.active or giveup.reason == nil or giveup.dismissed then
		giveup.alpha = 0
		return
	end
	if getGiveupReason() == nil then
		resetGiveup(true)
		return
	end
	giveup.alpha = Lerp(FrameTime() * 6, giveup.alpha or 0, 255)
	local a = math_floor(giveup.alpha)
	if a < 2 then return end
	local reason = giveup.reason
	local title = reason == "paralyzed" and "ТЫ ПАРАЛИЗОВАН" or "ТЫ БЕЗ СОЗНАНИЯ"
	local desc = reason == "paralyzed" and "Тело больше тебя не слушается..." or "Сознание ускользает, и тьма обволакивает тебя..."
	local s = GIVEUP_SCALE
	local frac = math_min(giveup.holding / GIVEUP_HOLD, 1)
	local pulse = 0.5 + 0.5 * math_abs(math_sin(CurTime() * 2.2))
	local cx = ScrW() * 0.5
	local y = ScrH() * 0.20
	local titleCol = Color(245, 235 - math_floor(35 * pulse), 235 - math_floor(35 * pulse), a)
	giveupText(title, "ZB_Giveup_Title", cx, y, titleCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, a, Color(200, 45, 45), pulse)
	giveupText(desc, "ZB_Giveup_Desc", cx, y + 62 * s, Color(190, 190, 195, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, a)
	giveupText("Зажми и держи [ J ], чтобы сдаться и покинуть этот грешный мир", "ZB_Giveup_Text", cx, y + 120 * s, Color(225, math_floor(150 + 60 * pulse), math_floor(150 + 60 * pulse), a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, a)
	giveupText("Нажми [ X ], чтобы скрыть до следующей ситуации", "ZB_Giveup_Small", cx, y + 158 * s, Color(165, 165, 170, math_floor(a * 0.85)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, a)
	local bw, bh = 560 * s, 16 * s
	local bx = cx - bw * 0.5
	local by = y + 228 * s
	if giveup.holding > 0.05 and frac < 1 then
		local secs = math.ceil(GIVEUP_HOLD - giveup.holding)
		giveupText("Смерть через " .. secs .. "...", "ZB_Giveup_Text", cx, by - 34 * s, Color(255, 200, 200, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, a)
	end
	draw.RoundedBox(math_floor(bh * 0.5), bx, by, bw, bh, Color(35, 35, 40, math_floor(a * 0.55)))
	if frac > 0 then
		draw.RoundedBox(math_floor(bh * 0.5), bx, by, math_max(bw * frac, bh), bh, Color(200, 50, 50, a))
	end
end
hook.Add("HUDPaint", "ZB_Health_Bar", draw_bar)
hook.Add("HUDPaint", "ZB_Health_Sprites", draw_sprites)
hook.Add("HUDPaint", "ZB_Health_StatusEffects", draw_status_effects)
hook.Add("HUDPaint", "ZB_Health_StatusTooltips", draw_status_tooltips)
hook.Add("HUDPaint", "ZB_Health_Giveup", draw_giveup)
