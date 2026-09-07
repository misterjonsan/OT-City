timer.Simple(0.1, function()
MODE = MODE or {}
local MODE = MODE

MODE.FootStepsDrawDistanceStand = 170
MODE.FootStepsDrawDistanceCrouch = 1000
MODE.FootStepsAlphaStand = 105
MODE.FootStepsAlphaCrouch = 185
MODE.FootStepsFadeStartFrac = 0.45
MODE.FootStepsArrangementPadding = 150
MODE.FootStepsDistanceLerpSpeed = 1500
MODE.FootStepsAlphaLerpSpeed = 260
MODE.FootStepsLifeTimeMax = 13
MODE.FootStepsFadeOutTime = 3.5
MODE.FootStepsMaxCount = 350
MODE.FootStepsArrangementTimeCD = 0.05

MODE.FootStepsCurDrawDistance = MODE.FootStepsCurDrawDistance or MODE.FootStepsDrawDistanceStand
MODE.FootStepsCurAlphaMax = MODE.FootStepsCurAlphaMax or MODE.FootStepsAlphaStand
MODE.FootSteps = MODE.FootSteps or {}
MODE.FootStepId = MODE.FootStepId or 0
MODE.FootStepCount = MODE.FootStepCount or 0
MODE.ArrangedFootSteps = MODE.ArrangedFootSteps or {}
MODE.NextFootStepsArrangementTime = 0

local footMat = Material("thieves/footprint", "smooth mips")
local drawCol = Color(255, 255, 255, 255)

function MODE.IsRoundTypeSuitableForProfessions()
    return MODE.PrintName == "Homicide" and istable(MODE.Types)
end

local profCache = ""
local profCacheTime = 0

local function CurrentProfession()
    local ply = LocalPlayer()
    if not IsValid(ply) then return "" end

    local now = RealTime()
    if now < profCacheTime then return profCache end
    profCacheTime = now + 0.2

    local prof = ""
    if ply.GetNWString then
        prof = ply:GetNWString("HMCD_CurrentProfession", "") or ""
    end
    if prof == "" and isstring(ply.Profession) then
        prof = ply.Profession
    end
    if not isstring(prof) then prof = "" end

    prof = string.lower(string.Trim(prof))
    if prof ~= "" then ply.Profession = prof end
    profCache = prof
    return prof
end
MODE.CurrentProfession = CurrentProfession

local function IsHuntsman()
    return CurrentProfession() == "huntsman"
end
MODE.IsHuntsman = IsHuntsman

local lastChatText = ""
local lastChatTime = 0
local function ChatInfo(text)
    if not text or text == "" then return end
    if text == lastChatText and CurTime() - lastChatTime < 1 then return end
    lastChatText = text
    lastChatTime = CurTime()
    chat.AddText(Color(120, 230, 150), "[Профессия] ", color_white, text)
end

local function SafeColor(col, ent)
    if IsColor(col) then return Color(col.r, col.g, col.b, 255) end
    if istable(col) and isnumber(col.r) then return Color(col.r, col.g or 255, col.b or 255, 255) end
    if IsValid(ent) and ent.GetPlayerColor then
        local v = ent:GetPlayerColor()
        if isvector(v) then
            return Color(math.Clamp(v.x * 255, 0, 255), math.Clamp(v.y * 255, 0, 255), math.Clamp(v.z * 255, 0, 255), 255)
        end
    end
    return Color(255, 255, 255, 255)
end

local function RemoveFootstep(key)
    if MODE.FootSteps[key] ~= nil then
        MODE.FootSteps[key] = nil
        MODE.FootStepCount = math.max(MODE.FootStepCount - 1, 0)
    end
end
MODE.RemoveFootstep = RemoveFootstep

local function ClearFootsteps()
    MODE.FootSteps = {}
    MODE.ArrangedFootSteps = {}
    MODE.FootStepId = 0
    MODE.FootStepCount = 0
end
MODE.ClearFootsteps = ClearFootsteps

local function PruneOldest()
    local minKey
    for key in pairs(MODE.FootSteps) do
        if not minKey or key < minKey then minKey = key end
    end
    if minKey then RemoveFootstep(minKey) end
end

local upNormal = Vector(0, 0, 1)

function MODE.AddFootstep(pos, ang_y, foot, color, normal)
    if not isvector(pos) then return end
    if not isvector(normal) or normal.z < 0.2 then normal = upNormal end

    MODE.FootStepId = MODE.FootStepId + 1
    MODE.FootSteps[MODE.FootStepId] = {
        Pos = pos + normal * 1.0,
        Normal = normal,
        Ang = tonumber(ang_y) or 0,
        Color = SafeColor(color, nil),
        CreationTime = CurTime(),
        Foot = foot and 1 or -1,
        Fade = 0
    }
    MODE.FootStepCount = MODE.FootStepCount + 1

    while MODE.FootStepCount > MODE.FootStepsMaxCount do
        PruneOldest()
    end
end

hook.Add("PostDrawTranslucentRenderables", "HMCD_Professions_Abilities", function(bDrawingSkybox, bDrawingDepth)
    if bDrawingSkybox or bDrawingDepth then return end
    if MODE.FootStepCount <= 0 then return end
    if not IsHuntsman() then return end

    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local eyePos = EyePos()
    local frameTime = FrameTime()
    local now = CurTime()

    local crouching = lp:Crouching()
    local targetDist = crouching and MODE.FootStepsDrawDistanceCrouch or MODE.FootStepsDrawDistanceStand
    local targetAlpha = crouching and MODE.FootStepsAlphaCrouch or MODE.FootStepsAlphaStand

    MODE.FootStepsCurDrawDistance = math.Approach(MODE.FootStepsCurDrawDistance, targetDist, frameTime * MODE.FootStepsDistanceLerpSpeed)
    MODE.FootStepsCurAlphaMax = math.Approach(MODE.FootStepsCurAlphaMax, targetAlpha, frameTime * MODE.FootStepsAlphaLerpSpeed)

    local drawDist = MODE.FootStepsCurDrawDistance
    local drawDistSqr = drawDist * drawDist
    local arrangeDist = drawDist + MODE.FootStepsArrangementPadding
    local arrangeDistSqr = arrangeDist * arrangeDist
    local fadeStart = MODE.FootStepsFadeStartFrac
    local fadeRange = 1 - fadeStart
    local alphaMax = MODE.FootStepsCurAlphaMax
    local lifeMax = MODE.FootStepsLifeTimeMax
    local fadeOutTime = MODE.FootStepsFadeOutTime
    local blend = math.Clamp(frameTime * 8, 0, 1)

    if MODE.NextFootStepsArrangementTime <= now then
        MODE.NextFootStepsArrangementTime = now + MODE.FootStepsArrangementTimeCD
        local arranged = {}
        for key, step in pairs(MODE.FootSteps) do
            if not istable(step) or not isvector(step.Pos) or (step.CreationTime + lifeMax <= now) then
                RemoveFootstep(key)
            elseif step.Pos:DistToSqr(eyePos) <= arrangeDistSqr then
                arranged[#arranged + 1] = step
            end
        end
        MODE.ArrangedFootSteps = arranged
    end

    local arrangedSteps = MODE.ArrangedFootSteps

    render.SetMaterial(footMat)

    for i = 1, #arrangedSteps do
        local step = arrangedSteps[i]
        if istable(step) and isvector(step.Pos) then
            local distSqr = step.Pos:DistToSqr(eyePos)

            local distFade = 0
            if distSqr < drawDistSqr then
                local frac = math.sqrt(distSqr) / drawDist
                if frac <= fadeStart then
                    distFade = 1
                else
                    local f = math.Clamp((1 - frac) / fadeRange, 0, 1)
                    distFade = f * f * (3 - 2 * f)
                end
            end

            local age = now - step.CreationTime
            local appearFade = math.Clamp(age / 0.6, 0, 1)
            local disappearFade = math.Clamp((lifeMax - age) / fadeOutTime, 0, 1)
            disappearFade = disappearFade * disappearFade * (3 - 2 * disappearFade)

            local wanted = distFade * appearFade * disappearFade
            step.Fade = Lerp(blend, step.Fade or 0, wanted)

            local fade = step.Fade
            if fade > 0.004 then
                local col = step.Color
                local size = 7 + 2 * distFade
                local length = 13 + 4 * distFade

                drawCol.r = col.r
                drawCol.g = col.g
                drawCol.b = col.b
                drawCol.a = alphaMax * fade

                render.DrawQuadEasy(step.Pos, step.Normal, size, length, drawCol, step.Ang + (step.Foot or 0) * 11)
            end
        end
    end
end)

timer.Create("HMCD_Professions_FootstepPrune", 3, 0, function()
    if MODE.FootStepCount <= 0 then return end
    local now = CurTime()
    local lifeMax = MODE.FootStepsLifeTimeMax
    for key, step in pairs(MODE.FootSteps) do
        if not istable(step) or (step.CreationTime + lifeMax <= now) then
            RemoveFootstep(key)
        end
    end
end)

hook.Add("PostCleanupMap", "HMCD_Professions_Abilities", ClearFootsteps)

net.Receive("HMCD_Professions_Abilities_AddFootstep", function()
    local pos = net.ReadVector()
    local ang = net.ReadFloat()
    local foot = net.ReadBool()
    local col = net.ReadColor(false)
    local normal = net.ReadVector()
    MODE.AddFootstep(pos, ang, foot, col, normal)
end)

local MED_DURATION = 4
local MED_FADE_IN = 0.35
local MED_FADE_OUT = 1.2

local med = {active = false, start = 0, data = nil, findings = {}, vitals = {}, summary = {}, triage = "", triageCol = nil, advice = nil}
local medFontsReady = false
local medMats = nil

local BODY_PARTS = {
    {name = "head", x = 55, y = -15, w = 1, h = 1},
    {name = "torso", x = 54, y = 33, w = 1.4, h = 1.8},
    {name = "right_arm", x = 83, y = 36, w = 1, h = 2},
    {name = "left_arm", x = 24, y = 38, w = 1, h = 2},
    {name = "right_leg", x = 66, y = 92, w = 1.2, h = 3.5},
    {name = "left_leg", x = 35, y = 106, w = 1.2, h = 2.7},
}

local BODY_CX = 53.5
local BODY_CY = 58
local BODY_SPAN = 215

local AMPUT_KEY = {head = "headamputated", right_arm = "rarmamputated", left_arm = "larmamputated", right_leg = "rlegamputated", left_leg = "llegamputated"}
local DISLOC_KEY = {right_arm = "rarmdislocation", left_arm = "larmdislocation", right_leg = "rlegdislocation", left_leg = "llegdislocation"}
local ARTERY_KEY = {right_arm = "rarmarteria", left_arm = "larmarteria", right_leg = "rlegarteria", left_leg = "llegarteria"}

local function MedFonts()
    if medFontsReady then return end
    medFontsReady = true
    surface.CreateFont("HMCD_Med_Title", {font = "Roboto", size = 32, weight = 700, extended = true, antialias = true})
    surface.CreateFont("HMCD_Med_Sub", {font = "Roboto", size = 19, weight = 500, extended = true, antialias = true})
    surface.CreateFont("HMCD_Med_Line", {font = "Roboto", size = 19, weight = 500, extended = true, antialias = true})
    surface.CreateFont("HMCD_Med_Small", {font = "Roboto", size = 16, weight = 500, extended = true, antialias = true})
end

local function MedMats()
    if medMats then return medMats end
    medMats = {}
    local paths = {
        head = "vgui/hud/health_head.png",
        torso = "vgui/hud/health_torso.png",
        right_arm = "vgui/hud/health_right_arm.png",
        left_arm = "vgui/hud/health_left_arm.png",
        right_leg = "vgui/hud/health_right_leg.png",
        left_leg = "vgui/hud/health_left_leg.png",
    }
    for k, p in pairs(paths) do
        local m = Material(p, "smooth")
        if m and not m:IsError() then medMats[k] = m end
    end
    return medMats
end

local function PartDamage(d, name)
    if name == "head" then return math.max(d.skull or 0, (d.jaw or 0) * 0.7) end
    if name == "torso" then return math.max(d.chest or 0, d.spine1 or 0, d.spine2 or 0, d.spine3 or 0, (d.pelvis or 0) * 0.9) end
    if name == "right_arm" then return d.rarm or 0 end
    if name == "left_arm" then return d.larm or 0 end
    if name == "right_leg" then return d.rleg or 0 end
    if name == "left_leg" then return d.lleg or 0 end
    return 0
end

local function DamageColor(v)
    v = math.Clamp(v or 0, 0, 1)
    if v <= 0.3 then return 155, 160, 168 end
    if v <= 0.6 then return 235, 165, 60 end
    if v < 0.95 then return 228, 92, 58 end
    return 240, 55, 48
end

local function VitalColor(r)
    r = math.Clamp(r or 0, 0, 1)
    if r > 0.66 then return Color(130, 200, 140) end
    if r > 0.33 then return Color(235, 175, 70) end
    return Color(235, 80, 65)
end

local function flagOn(v)
    return v == true or v == 1
end

local function IsDead(d)
    return d.dead == true or d.alive == false
end

local function Saturation(d)
    local o2max = math.max(d.o2max or 30, 1)
    return math.Clamp((d.o2 or o2max) / o2max, 0, 1)
end

local function PulseText(d)
    if flagOn(d.heartstop) then return "Пульс не прощупывается" end
    local p = math.floor(d.pulse or 70)
    local s
    if p < 40 then s = "редкий, слабого наполнения"
    elseif p < 60 then s = "замедленный"
    elseif p <= 100 then s = "ровный"
    elseif p <= 130 then s = "учащённый"
    else s = "нитевидный" end
    return "Пульс " .. p .. ", " .. s
end

local function BloodText(d)
    local blood = d.blood or 5000
    local lost = math.max(0, 5000 - blood)
    if lost < 150 then return "Кровопотери нет" end
    if lost < 750 then return string.format("Кровопотеря около %d мл", math.floor(lost / 50) * 50) end
    if lost < 1500 then return string.format("Кровопотеря %.1f л, кожа бледная", lost / 1000) end
    if lost < 2200 then return string.format("Массивная кровопотеря %.1f л, конечности холодные", lost / 1000) end
    return string.format("Кри��иче��кая кровопотеря %.1f л", lost / 1000)
end

local function BreathText(d)
    if d.lungsfunction == false then return "Дыхание не определяется" end
    local o2max = math.max(d.o2max or 30, 1)
    local pct = math.Clamp((d.o2 or o2max) / o2max, 0, 1) * 100
    if pct < 30 then return string.format("Сат��рация %d%%, губы синюшные", math.floor(pct)) end
    if pct < 55 then return string.format("Сатурация %d%%, дыхание поверхностное", math.floor(pct)) end
    if pct < 80 then return string.format("Сатурация %d%%, дыхание учащённое", math.floor(pct)) end
    return string.format("Сатурация %d%%, дыхание ровное", math.floor(pct))
end

local function ConsText(d)
    if IsDead(d) then return "Признаков жизни нет" end
    if flagOn(d.otrub) then return "Без сознания, на оклик не реагирует" end
    local c = math.Clamp(d.consciousness or 1, 0, 1) * 100
    if c >= 90 then return "В сознании, ориентируется" end
    if c >= 70 then return "В сознании, заторможен" end
    if c >= 45 then return "Сознание спутано, речь бессвязная" end
    if c >= 20 then return "Реагирует только на боль" end
    return "Сознание почти утрачено"
end

local function PainText(d)
    if (d.analgesia or 0) > 0.2 then return "Боль притуплена обезболивающим" end
    local p = d.pain or 0
    if p < 5 then return "Боли нет" end
    if p < 20 then return "Боль терпимая" end
    if p < 40 then return "Сильная боль" end
    if p < 60 then return "Боль на грани переносимой" end
    return "Болевой шок"
end

local function BuildSummary(d)
    if IsDead(d) then
        return {
            "Признаков жизни нет. Пульс и дыхание отсутствуют.",
            BloodText(d) .. ".",
        }
    end
    return {
        ConsText(d) .. ". " .. PulseText(d) .. ".",
        BloodText(d) .. ". " .. BreathText(d) .. ".",
        PainText(d) .. ".",
    }
end

local function BuildFindings(d)
    local out = {}
    local dead = IsDead(d)

    local function add(txt, r, g, b, sev, need)
        out[#out + 1] = {t = txt, r = r, g = g, b = b, sev = sev or 1, need = need, idx = #out + 1}
    end

    if dead then
        add("Признаков жизни нет", 240, 70, 60, 4)
    elseif flagOn(d.otrub) then
        add("Без сознания, на оклик не реагирует", 240, 70, 60, 3)
    end

    local amp = {}
    if flagOn(d.headamputated) then amp[#amp + 1] = "голова" end
    if flagOn(d.rarmamputated) then amp[#amp + 1] = "правая рука" end
    if flagOn(d.larmamputated) then amp[#amp + 1] = "левая рука" end
    if flagOn(d.rlegamputated) then amp[#amp + 1] = "правая нога" end
    if flagOn(d.llegamputated) then amp[#amp + 1] = "левая нога" end
    if #amp > 0 then add("Оторвано: " .. table.concat(amp, ", "), 240, 70, 60, 4, "пережать культю и наложить жгут") end

    local art = {}
    if flagOn(d.rarmarteria) then art[#art + 1] = "правая рука" end
    if flagOn(d.larmarteria) then art[#art + 1] = "левая рука" end
    if flagOn(d.rlegarteria) then art[#art + 1] = "правая нога" end
    if flagOn(d.llegarteria) then art[#art + 1] = "левая нога" end
    if #art > 0 then
        add("Артерия вскрыта: " .. table.concat(art, ", "), 240, 70, 60, 4, "жгут выше раны")
    elseif flagOn(d.arteria) or (d.arterialWounds or 0) > 0 then
        add("Артериальное кровотечение", 240, 70, 60, 4, "жгут выше раны")
    end

    if not dead then
        if flagOn(d.heartstop) then
            add("Остановка сердца", 240, 55, 48, 4, "непрямой массаж сердца")
        else
            local pulse = d.pulse or 70
            local hb = d.heartbeat or 220
            if pulse <= 20 and hb >= 200 then
                add("Фибрилляция, сердце сокращается хаотично", 240, 55, 48, 4, "дефибрилляция")
            elseif pulse <= 40 and hb >= 170 then
                add("Аритмия, сердечный ритм нарушен", 232, 110, 55, 3)
            end
        end
    end

    if d.lungsfunction == false then add("Лёгкие не работают", 240, 55, 48, 4, "искусственное дыхание") end

    local pneumo = d.pneumothorax or 0
    if pneumo > 0.01 then
        local s = "начальный"
        if pneumo > 0.7 then s = "критический" elseif pneumo > 0.3 then s = "выраженный" elseif pneumo > 0.1 then s = "умеренный" end
        add("Гемоторакс " .. s .. ", кровь в плевральной полости", 240, 70, 60, pneumo > 0.3 and 4 or 3, "дренировать грудную клетку")
    end

    local spine = math.max(d.spine1 or 0, d.spine2 or 0, d.spine3 or 0)
    if spine >= 0.95 then add("Перелом позвоночника", 240, 70, 60, 4, "не двигать пострадавшего") end
    if (d.pelvis or 0) >= 0.95 then add("Перелом таза", 240, 70, 60, 3, "шина и покой") end
    if (d.skull or 0) >= 0.95 then add("Пролом черепа", 240, 55, 48, 4)
    elseif (d.skull or 0) >= 0.6 then add("Тяжёлая травма черепа", 240, 70, 60, 3) end
    if (d.chest or 0) >= 0.95 then add("Перелом рёбер", 232, 110, 55, 2) end
    if (d.jaw or 0) >= 0.6 then add("Перелом челюсти", 232, 165, 60, 2) end

    local fr = {}
    if (d.rarm or 0) >= 0.95 and not flagOn(d.rarmamputated) then fr[#fr + 1] = "правая рука" end
    if (d.larm or 0) >= 0.95 and not flagOn(d.larmamputated) then fr[#fr + 1] = "левая рука" end
    if (d.rleg or 0) >= 0.95 and not flagOn(d.rlegamputated) then fr[#fr + 1] = "правая нога" end
    if (d.lleg or 0) >= 0.95 and not flagOn(d.llegamputated) then fr[#fr + 1] = "левая нога" end
    if #fr > 0 then add("Перелом: " .. table.concat(fr, ", "), 232, 110, 55, 3, "наложить шину") end

    local dl = {}
    if flagOn(d.rarmdislocation) then dl[#dl + 1] = "правая рука" end
    if flagOn(d.larmdislocation) then dl[#dl + 1] = "левая рука" end
    if flagOn(d.rlegdislocation) then dl[#dl + 1] = "правая нога" end
    if flagOn(d.llegdislocation) then dl[#dl + 1] = "левая нога" end
    if flagOn(d.jawdislocation) then dl[#dl + 1] = "челюсть" end
    if #dl > 0 then add("Вывих: " .. table.concat(dl, ", "), 232, 165, 60, 2, "вправить сустав") end

    local organs = {}
    local organWorst = 0
    local function organ(v, name)
        v = v or 0
        if v > 0.3 then
            organs[#organs + 1] = name
            if v > organWorst then organWorst = v end
        end
    end
    organ(d.heart, "сердце")
    organ(math.max(d.lungsR or 0, d.lungsL or 0), "лёгкие")
    organ(d.liver, "печень")
    organ(d.stomach, "желудок")
    organ(d.intestines, "кишечник")
    if #organs > 0 then
        add("Повреждены органы: " .. table.concat(organs, ", "), 240, 70, 60, organWorst > 0.6 and 4 or 3, "нужна операция")
    end

    local bleed = d.bleed or 0
    if bleed > 0.1 then
        local s = "слабое"
        local sev = 2
        if bleed > 1.5 then s = "обильное" sev = 3 elseif bleed > 0.6 then s = "заметное" end
        add("Наружное кровотечение, " .. s, 232, 110, 55, sev, "перевязать раны")
    end
    if (d.internalBleed or 0) > 0.1 then
        add("Внутреннее кровотечение", 240, 70, 60, 3, "нужна операция")
    end

    local blood = d.blood or 5000
    local lost = math.max(0, 5000 - blood)
    if lost >= 1500 then
        add(string.format("Кровопотеря %.1f л", lost / 1000), 240, 70, 60, lost >= 2200 and 4 or 3, "переливание крови")
    end

    if (d.brain or 0) > 0.01 then
        local bv = d.brain or 0
        add("Повреждение мозга", 240, 70, 60, bv > 0.25 and 4 or 3)
    end

    if not dead then
        local sat = Saturation(d)
        if sat < 0.3 then
            add(string.format("Гипоксия, сатурация %d%%", math.floor(sat * 100)), 240, 70, 60, 4, "нужен кислород")
        elseif sat < 0.55 then
            add(string.format("Кислородное голодание, сатурация %d%%", math.floor(sat * 100)), 232, 110, 55, 3, "нужен кислород")
        end

        if (d.shock or 0) > 20 then add("Травматический шок", 240, 70, 60, 3, "снять боль и согреть") end
        if (d.pain or 0) > 55 and (d.analgesia or 0) <= 0.2 then add("Болевой шок", 240, 70, 60, 3, "обезболивающее") end
        if (d.disorientation or 0) > 0.2 then add("Оглушён, дезориентирован", 232, 165, 60, 2) end
        if (d.wantToVomit or 0) > 0.2 then add("Тошнит", 200, 205, 212, 1) end

        local temp = d.temperature
        if temp then
            if temp < 34 then add(string.format("Сильное переохлаждение, %.1f", temp), 120, 180, 235, 3, "согреть")
            elseif temp < 36 then add(string.format("Переохлаждение, %.1f", temp), 120, 180, 235, 2, "согреть")
            elseif temp > 39 then add(string.format("Сильный жар, %.1f", temp), 232, 110, 55, 3)
            elseif temp > 37.5 then add(string.format("Жар, %.1f", temp), 232, 110, 55, 2) end
        end

        if (d.adrenaline or 0) > 0.3 then add("Выброс адреналина", 232, 165, 60, 1) end
        if (d.analgesia or 0) > 0.2 then add("Под обезболивающим", 130, 200, 140, 1) end
        if flagOn(d.berserkActive2) then add("В аффекте, боли не чувствует", 220, 80, 200, 2) end
        if flagOn(d.canmove == false) then add("Не может двигаться", 232, 165, 60, 2) end
    end

    if (d.assimilated or 0) > 0.005 then
        add(string.format("Ассимиляция %d%%", math.floor((d.assimilated or 0) * 100)), 180, 80, 235, 3)
    end
    if flagOn(d.hasHealthChip) or d.chipNet == true then
        add("Вживлён медицинский чип", 120, 180, 235, 1)
    end

    if #out == 0 then add("Видимых повреждений нет", 130, 200, 140, 0) end

    table.sort(out, function(x, y)
        if x.sev ~= y.sev then return x.sev > y.sev end
        return x.idx < y.idx
    end)

    return out
end

local function BuildTriage(d, findings)
    if IsDead(d) then return "Мёртв", Color(160, 160, 168) end
    if flagOn(d.heartstop) then return "Клиническая смерть", Color(240, 55, 48) end

    local worst = 0
    for _, f in ipairs(findings) do
        if f.sev > worst then worst = f.sev end
    end

    if worst >= 4 then return "Критическое состояние", Color(240, 70, 60) end
    if worst == 3 then return "Тяжёлое состояние", Color(232, 110, 55) end
    if worst == 2 then return "Состояние средней тяжести", Color(235, 175, 70) end
    if worst == 1 then return "Легкие повреждения", Color(200, 205, 214) end
    return "Состояние стабильное", Color(130, 200, 140)
end

local function BuildAdvice(d, findings)
    if IsDead(d) then return nil end
    for _, f in ipairs(findings) do
        if f.need then return "В первую очередь: " .. f.need end
    end
    return nil
end

local function BuildVitals(d)
    local v = {}

    local blood = d.blood or 5000
    local br = math.Clamp(blood / 5000, 0, 1)
    v[#v + 1] = {label = "Кровь", value = math.floor(blood) .. " мл", ratio = br, col = VitalColor(br)}

    local pulse = math.floor(d.pulse or 70)
    local pr = 0
    if not flagOn(d.heartstop) and pulse > 0 then
        pr = math.Clamp(1 - math.abs(pulse - 75) / 75, 0, 1)
    end
    v[#v + 1] = {label = "Пульс", value = flagOn(d.heartstop) and "нет" or (pulse .. " уд/мин"), ratio = pr, col = VitalColor(pr)}

    local o2max = math.max(d.o2max or 30, 1)
    local sr = math.Clamp((d.o2 or o2max) / o2max, 0, 1)
    v[#v + 1] = {label = "Сатурация", value = math.floor(sr * 100) .. "%", ratio = sr, col = VitalColor(sr)}

    local cons = math.Clamp(d.consciousness or 1, 0, 1)
    v[#v + 1] = {label = "Сознание", value = math.floor(cons * 100) .. "%", ratio = cons, col = VitalColor(cons)}

    local pain = d.pain or 0
    local prr = math.Clamp(1 - pain / 80, 0, 1)
    v[#v + 1] = {label = "Боль", value = tostring(math.floor(pain)), ratio = prr, col = VitalColor(prr)}

    if d.stamina and d.staminaMax then
        local str = math.Clamp(d.stamina / math.max(d.staminaMax, 1), 0, 1)
        v[#v + 1] = {label = "Силы", value = math.floor(str * 100) .. "%", ratio = str, col = VitalColor(str)}
    end

    if d.temperature then
        local tr = math.Clamp(1 - math.abs(d.temperature - 36.6) / 4, 0, 1)
        v[#v + 1] = {label = "Температура", value = string.format("%.1f", d.temperature), ratio = tr, col = VitalColor(tr)}
    end

    return v
end

hook.Add("HUDPaint", "HMCD_Professions_MedScan", function()
    if not med.active then return end
    local d = med.data
    if not istable(d) then
        med.active = false
        return
    end

    local t = RealTime() - med.start
    if t >= MED_DURATION then
        med.active = false
        med.data = nil
        return
    end

    local a = 1
    if t < MED_FADE_IN then a = t / MED_FADE_IN end
    local fadeStart = MED_DURATION - MED_FADE_OUT
    if t > fadeStart then a = math.min(a, 1 - (t - fadeStart) / MED_FADE_OUT) end
    a = math.Clamp(a, 0, 1)
    a = a * a * (3 - 2 * a)
    if a <= 0.003 then return end

    MedFonts()
    local mats = MedMats()

    local sw, sh = ScrW(), ScrH()
    local scale = (sh * 0.56) / BODY_SPAN
    local cx = sw * 0.5
    local cy = sh * 0.5
    local bodyW = 92 * scale
    local bodyH = BODY_SPAN * scale
    local A = math.floor(255 * a)

    surface.SetDrawColor(6, 8, 12, math.floor(165 * a))
    surface.DrawRect(0, 0, sw, sh)

    local blink = math.sin(RealTime() * 7) * 0.5 + 0.5

    for _, p in ipairs(BODY_PARTS) do
        local ampKey = AMPUT_KEY[p.name]
        local amputated = ampKey ~= nil and flagOn(d[ampKey])
        local dmg = PartDamage(d, p.name)
        local w = 40 * p.w * scale
        local h = 40 * p.h * scale
        local x = cx + (p.x - BODY_CX) * scale - w * 0.5
        local y = cy + (p.y - BODY_CY) * scale - h * 0.5
        local r, g, b = DamageColor(dmg)
        local pa = 235

        if amputated then
            r, g, b, pa = 95, 32, 32, 95
        elseif dmg >= 0.95 then
            pa = 190 + 65 * blink
        end

        local mat = mats[p.name]
        if mat then
            surface.SetDrawColor(r, g, b, math.floor(pa * a))
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(x, y, w, h)
        else
            surface.SetDrawColor(r, g, b, math.floor(pa * a * 0.9))
            surface.DrawRect(x, y, w, h)
            surface.SetDrawColor(18, 20, 26, math.floor(210 * a))
            surface.DrawOutlinedRect(x, y, w, h, 2)
        end

    end

    draw.SimpleText(d.nick or "?", "HMCD_Med_Title", cx, cy - bodyH * 0.5 - 54, Color(238, 240, 245, A), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local tcol = med.triageCol or Color(140, 148, 160)
    draw.SimpleText(med.triage or "", "HMCD_Med_Sub", cx, cy - bodyH * 0.5 - 28, Color(tcol.r, tcol.g, tcol.b, A), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local barW = math.min(250, sw * 0.17)
    local bx = cx - bodyW * 0.5 - 46 - barW
    local by = cy - (#med.vitals * 46) * 0.5

    for _, v in ipairs(med.vitals) do
        draw.SimpleText(v.label, "HMCD_Med_Small", bx, by, Color(150, 156, 166, A), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(v.value, "HMCD_Med_Line", bx + barW, by - 2, Color(v.col.r, v.col.g, v.col.b, A), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(38, 42, 50, math.floor(210 * a))
        surface.DrawRect(bx, by + 24, barW, 6)
        surface.SetDrawColor(v.col.r, v.col.g, v.col.b, math.floor(230 * a))
        surface.DrawRect(bx, by + 24, barW * math.Clamp(v.ratio, 0, 1), 6)
        by = by + 46
    end

    local fx = cx + bodyW * 0.5 + 46
    local count = math.min(#med.findings, 12)
    local fy = cy - (count * 26) * 0.5

    for i = 1, count do
        local f = med.findings[i]
        surface.SetDrawColor(f.r, f.g, f.b, math.floor(230 * a))
        surface.DrawRect(fx, fy + 8, 4, 12)
        draw.SimpleText(f.t, "HMCD_Med_Line", fx + 14, fy + 13, Color(f.r, f.g, f.b, A), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        fy = fy + 26
    end

    local sy = cy + bodyH * 0.5 + 22
    for _, line in ipairs(med.summary) do
        draw.SimpleText(line, "HMCD_Med_Sub", cx, sy, Color(198, 204, 214, A), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        sy = sy + 24
    end

    if med.advice then
        draw.SimpleText(med.advice, "HMCD_Med_Line", cx, sy + 6, Color(120, 195, 235, A), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

net.Receive("HMCD_Professions_Abilities_DisplayOrganismInfo", function()
    local d = net.ReadTable()
    if not istable(d) then return end

    med.data = d
    med.findings = BuildFindings(d)
    med.vitals = IsDead(d) and {} or BuildVitals(d)
    med.summary = BuildSummary(d)

    local title, tcol = BuildTriage(d, med.findings)
    med.triage = title
    med.triageCol = tcol
    med.advice = BuildAdvice(d, med.findings)

    med.start = RealTime()
    med.active = true

    surface.PlaySound("items/medshot4.wav")
end)

local function createPipeBomb()
    RunConsoleCommand("hg_create_pipebomb")
end

local function createMolotov()
    RunConsoleCommand("hg_create_molotov")
end

hook.Add("radialOptions", "EngineerCraft", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local organism = ply.organism or {}
    if organism.otrub or CurrentProfession() ~= "engineer" then return end

    local haveAmmo
    local haveNails
    for id, amt in pairs(ply:GetAmmo()) do
        local name = game.GetAmmoName(id)
        if name == "Nails" and amt >= 3 then
            haveNails = true
        else
            local tbl = hg.ammotypeshuy and hg.ammotypeshuy[name]
            if tbl and tbl.BulletSettings and tbl.BulletSettings.Mass and tbl.BulletSettings.Mass * amt > 50 then
                haveAmmo = true
            end
        end
    end

    if haveAmmo and haveNails and ply:HasWeapon("weapon_leadpipe") then
        hg.radialOptions[#hg.radialOptions + 1] = {createPipeBomb, "Create pipe bomb"}
    end

    local haveBarrel
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 80)) do
        if IsValid(ent) and hg.gas_models and hg.gas_models[ent:GetModel()] then
            haveBarrel = true
            break
        end
    end

    if haveBarrel and (ply:HasWeapon("weapon_bandage_sh") or ply:HasWeapon("weapon_bigbandage_sh")) and ply:HasWeapon("weapon_hg_bottle") then
        hg.radialOptions[#hg.radialOptions + 1] = {createMolotov, "Create molotov"}
    end
end)
end)

local PROF_ABILITY_DEFAULT_KEY = KEY_E
local ProfAbilityKey = PROF_ABILITY_DEFAULT_KEY

local function SendProfAbilityKey()
    if not IsValid(LocalPlayer()) then return end

    net.Start("HMCD_Professions_AbilityKey")
        net.WriteUInt(ProfAbilityKey, 10)
    net.SendToServer()
end

concommand.Add("hg_prof_ability_key", function(_, _, args)
    local key = math.floor(tonumber(args and args[1] or "") or PROF_ABILITY_DEFAULT_KEY)

    if key <= 0 or key > 159 then
        key = PROF_ABILITY_DEFAULT_KEY
    end

    ProfAbilityKey = key
    SendProfAbilityKey()
end)

concommand.Add("hg_prof_ability", function()
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:Alive() then return end
    if not (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or ply:KeyDown(IN_SPEED) or ply:KeyDown(IN_WALK)) then return end

    net.Start("HMCD_Professions_AbilityUse")
    net.SendToServer()
end)

hook.Add("InitPostEntity", "HMCD_Professions_AbilityKeySync", function()
    timer.Simple(2, SendProfAbilityKey)
end)

timer.Simple(4, SendProfAbilityKey)

local SIN_NET = "HMCD_Professions_Sinners"
local SIN_KEY = "exorcist"
local SIN_RADIUS = 750
local SIN_FADE_SPEED = 4
local SIN_LIFETIME = 1.4
local SIN_TEXT_DISTANCE = 320

local sinnerMarks = {}
local sinnerGlow = Material("sprites/light_glow02_add")
local sinnerRing = Material("effects/select_ring")
local sinnerColorLight = Color(210, 60, 70)
local sinnerColorDeep = Color(255, 40, 55)
local sinnerDraw = Color(255, 255, 255, 255)
local sinnerShadow = Color(0, 0, 0, 255)
local sinnerFontsReady = false

if istable(MODE) then
    MODE.SinnerMarks = sinnerMarks
    MODE.SinnerRadius = SIN_RADIUS
    MODE.SinnerLifeTime = SIN_LIFETIME
    MODE.SinnerFadeSpeed = SIN_FADE_SPEED
end

local function SinnerFonts()
    if sinnerFontsReady then return end
    sinnerFontsReady = true

    surface.CreateFont("HMCD_SinnerMark", {font = "Montserrat SemiBold", size = 19, weight = 600, antialias = true, extended = true})
end

local function SinnerProfession()
    local ply = LocalPlayer()
    if not IsValid(ply) then return "" end

    local prof = isfunction(ply.GetNWString) and ply:GetNWString("HMCD_CurrentProfession", "") or ""

    if (not isstring(prof) or prof == "") and isstring(ply.Profession) then prof = ply.Profession end
    if not isstring(prof) then return "" end

    return string.lower(string.Trim(prof))
end

net.Receive(SIN_NET, function()
    local count = net.ReadUInt(4) or 0
    local now = CurTime()
    local fresh = {}

    for index = 1, count do
        local ent = net.ReadEntity()
        local tier = net.ReadUInt(2) or 1

        if IsValid(ent) then fresh[ent] = tier end
    end

    for ent, tier in pairs(fresh) do
        local mark = sinnerMarks[ent]

        if istable(mark) then
            mark.tier = tier
            mark.time = now
            mark.fade = tonumber(mark.fade) or 0
        else
            sinnerMarks[ent] = {tier = tier, time = now, fade = 0}
        end
    end

    for ent, mark in pairs(sinnerMarks) do
        if not IsValid(ent) or not istable(mark) then
            sinnerMarks[ent] = nil
        elseif not fresh[ent] then
            mark.time = math.min(tonumber(mark.time) or 0, now - SIN_LIFETIME)
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "HMCD_Professions_Sinners", function(skybox, depth)
    if skybox or depth then return end
    if table.IsEmpty(sinnerMarks) then return end
    if SinnerProfession() ~= SIN_KEY then
        table.Empty(sinnerMarks)
        return
    end

    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    SinnerFonts()

    local eyes = EyePos()
    local now = CurTime()
    local blend = math.Clamp(FrameTime() * SIN_FADE_SPEED, 0, 1)

    for ent, mark in pairs(sinnerMarks) do
        if not IsValid(ent) or not istable(mark) then
            sinnerMarks[ent] = nil
        else
            local born = tonumber(mark.time) or 0
            local fade = tonumber(mark.fade) or 0
            local tier = tonumber(mark.tier) or 1
            local center = ent:WorldSpaceCenter()
            local dist = center:Distance(eyes)
            local alive = (now - born) <= SIN_LIFETIME
            local wanted = 0

            if alive and dist <= SIN_RADIUS then
                local tr = util.TraceLine({
                    start = eyes,
                    endpos = center,
                    filter = {lp, ent},
                    mask = MASK_SHOT
                })

                if not tr.Hit then
                    wanted = math.Clamp(1 - (dist / SIN_RADIUS) * 0.6, 0, 1)
                end
            end

            fade = Lerp(blend, fade, wanted)
            mark.fade = fade
            mark.tier = tier
            mark.time = born

            if fade <= 0.01 and wanted <= 0 then
                mark.fade = 0

                if not alive then sinnerMarks[ent] = nil end
            end

            if fade > 0.02 then
                local deep = tier == 2
                local base = deep and sinnerColorDeep or sinnerColorLight
                local pulse = 0.82 + 0.18 * math.sin(now * (deep and 6 or 3.2))
                local alpha = math.Clamp(255 * fade * pulse * (deep and 1 or 0.72), 0, 255)
                local top = center + Vector(0, 0, ent:IsPlayer() and 44 or 22)

                sinnerDraw.r = base.r
                sinnerDraw.g = base.g
                sinnerDraw.b = base.b
                sinnerDraw.a = alpha

                render.SetMaterial(sinnerGlow)
                render.DrawSprite(top, 22 + 6 * pulse, 22 + 6 * pulse, sinnerDraw)

                sinnerDraw.a = alpha * 0.5
                render.DrawSprite(top, 52 + 10 * pulse, 52 + 10 * pulse, sinnerDraw)

                sinnerDraw.a = alpha * 0.35
                render.SetMaterial(sinnerRing)
                render.DrawQuadEasy(ent:GetPos() + Vector(0, 0, 2), Vector(0, 0, 1), 58, 58, sinnerDraw, now * (deep and 60 or 24) % 360)

                if dist < SIN_TEXT_DISTANCE then
                    local screen = (top + Vector(0, 0, 10)):ToScreen()

                    if screen.visible then
                        local textAlpha = math.Clamp(alpha * math.Clamp((SIN_TEXT_DISTANCE - dist) / 140, 0, 1), 0, 255)

                        sinnerShadow.a = textAlpha * 0.8

                        -- cam.Start2D()
                        --     draw.SimpleTextOutlined(deep and "ГРЕШНИК" or "Грешник", "HMCD_SinnerMark", screen.x, screen.y, Color(base.r, base.g, base.b, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, sinnerShadow)
                        -- cam.End2D()
                    end
                end
            end
        end
    end
end)

hook.Add("PostCleanupMap", "HMCD_Professions_SinnersClear", function()
    table.Empty(sinnerMarks)
end)
