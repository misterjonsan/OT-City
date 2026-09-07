local CLASS = player.RegClass("terroristss")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local terroristNames = {
    "Феникс-1", "Феникс-2", "Беркут-7", "Кобра-3", "Шторм-9",
    "Скат-4", "Грач-8", "Барс-5", "Вектор-6", "Тайфун-2",
    "Гранит-1", "Ястреб-3", "Сокол-7", "Рубеж-4", "Призрак-9"
}

local models = {
    "models/outcasts/c/outcast_victor.mdl",
    "models/outcasts/b/outcast_ceasar.mdl",
    "models/outcasts/a/outcast_adam.mdl"
}

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(185, 60, 60):ToVector())
    self:SetModel(table.Random(models))

    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    Appearance.AColthes = ""

    self:SetNWString("PlayerName", terroristNames[math.random(#terroristNames)])
    self.CurAppearance = Appearance

    self:SetNetVar("HideArmorRender", true)
end

//
//
//

local CLASS = player.RegClass("counter_terrorist")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local ctNames = {
    "Альфа-1", "Альфа-2", "Бастион-3", "Вымпел-4", "Штурм-5",
    "Гроза-6", "Рубеж-7", "Форпост-8", "Заслон-9", "Барьер-2",
    "Сфера-3", "Гром-4", "Клинок-5", "Титан-6", "Каскад-7"
}

local models = {
    "models/fidremaster/c/fid_lincoln.mdl",
    "models/fidremaster/l/fid_lincoln.mdl",
    "models/fidremaster/b/fid_michael.mdl",
    "models/fidremaster/a/fid_archie.mdl"
}

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(60, 140, 255):ToVector())
    self:SetModel(table.Random(models))

    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    Appearance.AColthes = ""

    self:SetNWString("PlayerName", ctNames[math.random(#ctNames)])
    self.CurAppearance = Appearance

    self:SetNetVar("HideArmorRender", true)
end

//
//
//
//

local CLASS = player.RegClass("grt")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local grtNames = {
    "ГРТ-1", "ГРТ-2", "ГРТ-3", "ГРТ-4", "ГРТ-5",
    "Периметр-1", "Периметр-2", "Блок-3", "Штурм-4", "Барьер-5",
    "Гром-6", "Щит-7", "Заслон-8", "Купол-9", "Фланг-2"
}

local models = {
    "models/fsb/b/fsb_character_b.mdl",
    "models/fsb/a/phoenix_fsb.mdl",
    "models/fsb/c/fsb_character_c.mdl"
}

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(120, 120, 255):ToVector())
    self:SetModel(table.Random(models))

    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    Appearance.AColthes = ""

    self:SetNWString("PlayerName", grtNames[math.random(#grtNames)])
    self.CurAppearance = Appearance

    self:SetNetVar("HideArmorRender", true)
end