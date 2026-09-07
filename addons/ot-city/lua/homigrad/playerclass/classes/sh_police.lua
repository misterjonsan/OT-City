local CLASS = player.RegClass("police")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    ["male 01"] = "models/monolithservers/mpd/male_01.mdl",
    ["male 03"] = "models/monolithservers/mpd/male_03.mdl",
    ["male 04"] = "models/monolithservers/mpd/male_04_2.mdl",
    ["male 05"] = "models/monolithservers/mpd/male_05.mdl",
    ["male 07"] = "models/monolithservers/mpd/male_07_2.mdl",
    ["male 08"] = "models/monolithservers/mpd/male_08.mdl",
    ["male 09"] = "models/monolithservers/mpd/male_09_2.mdl",
}

local ranks = {
    {name = "Полковник полиции", chance = 2},
    {name = "Подполковник полиции", chance = 4},
    {name = "Майор полиции", chance = 8},
    {name = "Капитан полиции", chance = 12},
    {name = "Старший лейтенант полиции", chance = 18},
    {name = "Лейтенант полиции", chance = 22},
    {name = "Сержант полиции", chance = 20},
    {name = "Младший сержант полиции", chance = 14}
}

local clr = Color(10, 10, 100):ToVector()

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self,nil,nil,nil,true)

    local Appearance = self.CurAppearance
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local randomValue = math.random(100)
    local cumulativeChance = 0
    local rank = "Сержант полиции"

    for _, rankInfo in ipairs(ranks) do
        cumulativeChance = cumulativeChance + rankInfo.chance
        if randomValue <= cumulativeChance then
            rank = rankInfo.name
            break
        end
    end

    self:SetNWString("PlayerName", rank .. " " .. Appearance.AName)
    self:SetPlayerColor(clr)
    self:SetModel(models[string.lower(Appearance.AModel)] or table.Random(models))
    self:SetBodyGroups("000000000000000000")
    self:SetSubMaterial()
    self:SetNetVar("Accessories", Appearance.AAttachmets or "none")

    self.CurAppearance = Appearance
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end

    if Victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end

    if CurrentRound().name == "hmcd" then
        return zb.ForcesAttackedInnocent(self, Victim)
    end

    return 1
end

//
//
//
//

local CLASS = player.RegClass("sledcom")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {}
for i = 1, 9 do
    table.insert(models,"models/dejtriyev/enhancednatguard/male_0"..i..".mdl")
end

local ranks = {
    { name = "Генерал-майор юстиции", chance = 3 },
    { name = "Полковник юстиции", chance = 7 },
    { name = "Подполковник юстиции", chance = 10 },
    { name = "Майор юстиции", chance = 15 },
    { name = "Капитан юстиции", chance = 20 },
    { name = "Старший лейтенант юстиции", chance = 20 },
    { name = "Лейтенант юстиции", chance = 25 }
}

local clr = Color(80, 80, 140):ToVector()

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self,nil,nil,nil,true)

    local Appearance = self.CurAppearance
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local randomValue = math.random(100)
    local cumulativeChance = 0
    local rank = "Лейтенант юстиции"

    for _, rankInfo in ipairs(ranks) do
        cumulativeChance = cumulativeChance + rankInfo.chance
        if randomValue <= cumulativeChance then
            rank = rankInfo.name
            break
        end
    end

    self:SetNWString("PlayerName", rank .. " " .. Appearance.AName)
    self:SetPlayerColor(clr)
    self:SetModel(models[string.lower(Appearance.AModel)] or table.Random(models))
    self:SetBodyGroups("000000000000000000")
    self:SetSubMaterial()
    self:SetNetVar("Accessories", Appearance.AAttachmets or "none")

    self.CurAppearance = Appearance
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end

    if Victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end

    if CurrentRound().name == "hmcd" then
        return zb.ForcesAttackedInnocent(self, Victim)
    end

    return 1
end