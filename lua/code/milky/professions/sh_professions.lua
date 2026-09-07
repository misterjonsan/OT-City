MODE = MODE or {}

MODE.ProfXPKey = "hmcd_prof_xp"
MODE.ProfChoiceKey = "hmcd_prof_choice"

MODE.ProfessionOrder = {"doctor", "huntsman", "engineer", "cook", "builder", "exorcist"}

MODE.ProfessionMeta = {
    ["doctor"] = {
        Title = "Доктор",
        Unlock = 0,
        Color = Color(70, 200, 120),
        Short = "Осмотр состояния тела",
        Desc = "Зажмите ходьбу (SHIFT) и нажмите E, глядя на игрока — вы увидите состояние его организма (насыщение). Помогает понять, кто ранен и кого лечить.",
    },
    ["huntsman"] = {
        Title = "Охотник",
        Unlock = 800,
        Color = Color(210, 170, 70),
        Short = "Видит следы игроков",
        Desc = "Вы видите следы других игроков прямо на земле — они подсвечиваются вокруг вас. Присядьте, чтобы разглядеть их вблизи чётче. Идеально, чтобы выследить убийцу или найти, куда все убежали.",
    },
    ["engineer"] = {
        Title = "Инженер",
        Unlock = 2200,
        Color = Color(90, 160, 230),
        Short = "Крафт взрывчатки",
        Desc = "Через радиальное меню вы можете смастерить самодельное оружие:\n- Труба + гвозди (x3) + патроны = труба-бомба.\n- Бутылка + бинт рядом с бочкой газа = коктейль Молотова.\nСоберите компоненты и создайте оружие на месте.",
    },
    ["cook"] = {
        Title = "Повар",
        Unlock = 4500,
        Color = Color(230, 120, 90),
        Short = "Восстанавливает насыщение союзникам",
        Desc = "Зажмите ходьбу (SHIFT) и нажмите E — все живые игроки рядом с вами (радиус ~300) получат прибавку насыщения. Помогает команде дольше держаться в долгой партии. Действует с перезарядкой в несколько секунд.",
    },
    ["builder"] = {
        Title = "Строитель",
        Unlock = 8000,
        Color = Color(180, 150, 110),
        Short = "Заколачивает двери",
        Desc = "Посмотрите на дверь, зажмите ходьбу (SHIFT) и нажмите E — вы заколотите её: дверь запирается и получает большой запас прочности, её труднее выбить. Отлично, чтобы закрепиться и перекрыть проход. Действует с перезарядкой.",
    },
    ["exorcist"] = {
        Title = "Экзорцист",
        Unlock = 8000,
        VIP = true,
        Color = Color(200, 55, 65),
        Short = "Видит грешников и владеет Крестом",
        Desc = "Пассивно: на тех, чья совесть мертва, вы видите алую метку над головой. Метка горит только в прямой видимости и только в том направлении, куда вы смотрите: сквозь стены, за спиной и дальше 750 единиц вы ничего не увидите, а точные цифры совести остаются скрыты — только глубина падения по яркости метки.\nТолько экзорцист может держать Крест совести: другие профессии крест отвергает и поджигает. Судить можно лишь с чистой совестью от 95.\nПрофессия доступна только VIP-игрокам.",
    },
}

MODE.ProfXP = {
    Kill = 4,
    Round = 6,
    Survive = 4,
}

function MODE.ProfessionUnlockCost(key)
    local meta = MODE.ProfessionMeta[key]
    return (meta and meta.Unlock) or 0
end

function MODE.ProfessionExists(key)
    return key ~= nil and key ~= "" and MODE.Professions ~= nil and MODE.Professions[key] ~= nil
end

function MODE.IsProfessionUnlocked(xp, key)
    return (tonumber(xp) or 0) >= MODE.ProfessionUnlockCost(key)
end

MODE.VIPProfessions = {["exorcist"] = true}

function MODE.IsProfessionVIPOnly(key)
    local meta = MODE.ProfessionMeta and MODE.ProfessionMeta[key]
    if meta and meta.VIP then return true end
    return MODE.VIPProfessions[key] == true
end

function MODE.IsVIPPlayer(ply)
    if not IsValid(ply) or not isfunction(ply.GetUserGroup) then return false end
    local group = string.lower(string.Trim(tostring(ply:GetUserGroup() or "user")))
    return group ~= "" and group ~= "user"
end

MODE.DefaultProfessions = {
    ["doctor"] = {Chance = 1},
    ["huntsman"] = {Chance = 1},
    ["engineer"] = {Chance = 1},
    ["cook"] = {Chance = 1},
    ["builder"] = {Chance = 1},
    ["exorcist"] = {Chance = 1},
}
