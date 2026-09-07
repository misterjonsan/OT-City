--[[
    .408 Cheytac Ammo Type for HG Ammo System
    Исправленная версия
]]

-- Проверяем, существует ли основная таблица аммо
if not hg or not hg.ammotypes then
    ErrorNoHalt("[.408 Cheytac] Ошибка: основная система аммо не найдена!\n")
    return
end

-- Материал для иконки (используем существующий или создаем новый)
local matRfileAmmo = Material("vgui/hud/bullets/high_caliber.png")

-- Добавляем .408 Cheytac в таблицу ammotypes
hg.ammotypes[".408cheytac"] = {
    name = ".408 Cheytac",  -- Это имя будет отображаться в игре
    allowed = true,
    dmgtype = DMG_BULLET,
    tracer = TRACER_LINE,
    plydmg = 0,
    npcdmg = 0,
    force = 450,
    maxcarry = 40,
    minsplash = 18,
    maxsplash = 18,
    TracerSetings = {
        TracerBody = Material("particle/fire"),
        TracerTail = Material("effects/laser_tracer"),
        TracerHeadSize = 8,
        TracerLength = 120,
        TracerWidth = 4,
        TracerColor = Color(255, 220, 150),
        TracerTPoint1 = 0.25,
        TracerTPoint2 = 1,
        TracerSpeed = 30000
    },
    BulletSettings = {
        Damage = 235,
        Force = 65,
        Penetration = 50,
        Shell = ".408cheytac",
        Speed = 950,
        Diameter = 10.36,
        Mass = 27,
        AirResistMul = 0.00009,
        Icon = matRfileAmmo
    }
}

-- Добавляем энтити для патронов
if not hg.ammoents then
    hg.ammoents = hg.ammoents or {}
end

hg.ammoents[".408cheytac"] = {
    Material = "models/hmcd_ammobox_792",
    Scale = 1.2,
    Color = Color(218, 165, 32),
    Count = 15,
}

-- Регистрируем тип аммо если игра уже загружена
local function registerCheytac()
    -- Добавляем в game.GetAmmoTypes
    game.AddAmmoType(hg.ammotypes[".408cheytac"])
    
    -- Регистрируем энтити
    if CLIENT then
        -- ВАЖНО: имя для language.Add должно совпадать с name из таблицы + "_ammo"
        language.Add(".408 Cheytac_ammo", ".408 Cheytac")
    end
    
    local ammoent = {}
    ammoent.Base = "ammo_base"
    ammoent.PrintName = ".408 Cheytac"
    ammoent.Category = "ZCity Ammo"
    ammoent.Spawnable = true
    ammoent.AmmoCount = hg.ammoents[".408cheytac"].Count or 15
    -- ВАЖНО: AmmoType должно быть точно таким же, как name в таблице ammotypes
    ammoent.AmmoType = ".408 Cheytac"
    ammoent.Model = "models/props_lab/box01a.mdl"
    ammoent.ModelMaterial = hg.ammoents[".408cheytac"].Material or ""
    ammoent.ModelScale = hg.ammoents[".408cheytac"].Scale or 1.2
    ammoent.Color = hg.ammoents[".408cheytac"].Color or Color(218, 165, 32)
    
    scripted_ents.Register(ammoent, "ent_ammo_.408cheytac")
    
    -- Перестраиваем типы аммо
    game.BuildAmmoTypes()
    
    print("[.408 Cheytac] Успешно загружен!")
end

if game.IsDedicated() or game.GetMap() ~= "" then
    registerCheytac()
else
    hook.Add("Initialize", "init-ammo-408cheytac", registerCheytac)
end

-- Добавляем в таблицу allowed если она существует
if hg.ammotypesallowed then
    -- В этой таблице ключи - это отображаемые имена (name)
    hg.ammotypesallowed[".408 Cheytac"] = hg.ammotypes[".408cheytac"]
end

-- Добавляем в таблицу обратного соответствия если она существует
if hg.ammotypeshuy then
    -- В этой таблице ключи - отображаемые имена, значения - таблицы с добавленным полем name (ключ)
    hg.ammotypeshuy[".408 Cheytac"] = table.Copy(hg.ammotypes[".408cheytac"])
    hg.ammotypeshuy[".408 Cheytac"].name = ".408cheytac"
end

-- Создаем обратную связь для системы дропа
if SERVER then
    -- Добавляем хук для обработки создания энтити при дропе
    hook.Add("PlayerAmmoDrop", "408cheytac_drop_fix", function(ply, ammotype, count)
        -- Если это наш калибр, убеждаемся что создается правильная энтити
        if ammotype == ".408 Cheytac" then
            -- Эта функция будет вызвана из основного кода дропа
            -- Мы ничего не делаем, просто даем основному коду работать
        end
    end)
end

print("[.408 Cheytac] Файл загружен, используйте ключ '.408cheytac' в коде винтовки")

--[[Проверяем существование системы
if not hg or not hg.ammotypes then return end

-- 1. ОСНОВНАЯ ТАБЛИЦА КАЛИБРА (в hg.ammotypes)
hg.ammotypes["НАЗВАНИЕ_КЛЮЧ"] = {  -- Ключ маленькими буквами, без пробелов
    name = "Отображаемое Имя",      -- То что видит игрок
    allowed = true,                  -- Разрешен ли в игре
    dmgtype = DMG_BULLET,            -- Тип урона (обычно DMG_BULLET)
    tracer = TRACER_LINE,            -- Тип трассера
    
    -- Стандартные параметры (для game.AddAmmoType)
    plydmg = 0,                       -- Урон по игрокам (обычно 0)
    npcdmg = 0,                        -- Урон по NPC (обычно 0)
    force = ЧИСЛО,                     -- Базовая сила (для стандартной системы)
    maxcarry = ЧИСЛО,                   -- Максимум в инвентаре
    minsplash = ЧИСЛО,                   -- Мин. радиус разбрызга
    maxsplash = ЧИСЛО,                    -- Макс. радиус разбрызга
    
    -- Настройки трассера (визуал)
    TracerSetings = {
        TracerBody = Material("particle/fire"),
        TracerTail = Material("effects/laser_tracer"),
        TracerHeadSize = ЧИСЛО,        -- Размер головы трассера
        TracerLength = ЧИСЛО,           -- Длина хвоста
        TracerWidth = ЧИСЛО,             -- Толщина
        TracerColor = Color(R,G,B),       -- Цвет
        TracerTPoint1 = 0.25,               -- Точка начала (обычно 0.25)
        TracerTPoint2 = 1,                    -- Точка конца (обычно 1)
        TracerSpeed = ЧИСЛО,                    -- Скорость отрисовки
        -- NoSpin = true,                    -- Если нужно отключить вращение
    },
    
    -- Настройки баллистики (для hg.PhysBullet)
    BulletSettings = {
        Damage = ЧИСЛО,                    -- Урон
        Force = ЧИСЛО,                      -- Сила толчка (кастомная)
        Penetration = ЧИСЛО,                  -- Пробиваемость
        Shell = "НАЗВАНИЕ",                     -- Тип гильзы (для эффектов)
        Speed = ЧИСЛО,                           -- Скорость пули (м/с)
        Diameter = ЧИСЛО,                          -- Калибр в мм
        Mass = ЧИСЛО,                               -- Масса пули в граммах
        AirResistMul = 0.000Х,                        -- Сопротивление воздуха
        Icon = Material("путь/к/иконке"),               -- Иконка в инвентаре
        -- Доп. параметры по желанию:
        -- NumBullet = ЧИСЛО,                           -- Для дробовых (кол-во pellets)
        -- PhysPenetrationMul = ЧИСЛО,                   -- Множитель пробития физики
        -- Distance = ЧИСЛО,                             -- Макс. дистанция
    }
}

-- 2. ТАБЛИЦА ЭНТИТИ (модель патронов в hg.ammoents)
hg.ammoents["НАЗВАНИЕ_КЛЮЧ"] = {  -- Тот же ключ что и выше
    Material = "путь/к/материалу",     -- Материал для модели
    -- ИЛИ
    -- Model = "путь/к/модели.mdl",    -- Если используется кастомная модель
    
    Scale = ЧИСЛО,                      -- Масштаб модели
    Color = Color(R,G,B),                -- Цвет модели
    Count = ЧИСЛО,                        -- Сколько патронов в коробке
}

-- 3. РЕГИСТРАЦИЯ ЭНТИТИ
local function registerNewAmmo()
    -- Регистрируем тип в game.AddAmmoType
    game.AddAmmoType(hg.ammotypes["НАЗВАНИЕ_КЛЮЧ"])
    
    -- Для клиента добавляем языковую строку
    if CLIENT then
        language.Add("Отображаемое Имя_ammo", "Отображаемое Имя")
    end
    
    -- Создаем таблицу энтити
    local ammoent = {}
    ammoent.Base = "ammo_base"
    ammoent.PrintName = "Отображаемое Имя"
    ammoent.Category = "ZCity Ammo"
    ammoent.Spawnable = true
    ammoent.AmmoCount = hg.ammoents["НАЗВАНИЕ_КЛЮЧ"].Count or 30
    ammoent.AmmoType = "Отображаемое Имя"
    ammoent.Model = "models/props_lab/box01a.mdl"  -- или кастомная
    ammoent.ModelMaterial = hg.ammoents["НАЗВАНИЕ_КЛЮЧ"].Material or ""
    ammoent.ModelScale = hg.ammoents["НАЗВАНИЕ_КЛЮЧ"].Scale or 1
    ammoent.Color = hg.ammoents["НАЗВАНИЕ_КЛЮЧ"].Color or Color(255,255,255)
    
    -- Регистрируем энтити
    scripted_ents.Register(ammoent, "ent_ammo_НАЗВАНИЕ_КЛЮЧ")
    
    -- Перестраиваем типы аммо
    game.BuildAmmoTypes()
end

-- Вызываем регистрацию
if game.IsDedicated() or game.GetMap() ~= "" then
    registerNewAmmo()
else
    hook.Add("Initialize", "init-ammo-НАЗВАНИЕ_КЛЮЧ", registerNewAmmo)
end

-- 4. ДОБАВЛЯЕМ В ДОП. ТАБЛИЦЫ (если нужны)
if hg.ammotypesallowed then
    hg.ammotypesallowed["Отображаемое Имя"] = hg.ammotypes["НАЗВАНИЕ_КЛЮЧ"]
end

if hg.ammotypeshuy then
    hg.ammotypeshuy["Отображаемое Имя"] = table.Copy(hg.ammotypes["НАЗВАНИЕ_КЛЮЧ"])
    hg.ammotypeshuy["Отображаемое Имя"].name = "НАЗВАНИЕ_КЛЮЧ"
end

print("[Отображаемое Имя] Загружен! Ключ: 'НАЗВАНИЕ_КЛЮЧ'")
]]