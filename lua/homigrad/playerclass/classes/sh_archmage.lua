local CLASS = player.RegClass("archmage")

function CLASS.Off(self)
	if CLIENT then return end
	self:SetNetVar("HideArmorRender", false)
end

local names = {
	"Альдарион", "Элион", "Талмир", "Солариус", "Арканис",
	"Валерион", "Мирион", "Эстарион", "Люциар", "Астэр",
	"Каладор", "Тирион", "Мельхиор", "Элдрик", "Серрион"
}

local models = {
	"models/player/dumbledore.mdl",
	"models/player/voikanaa/albus_dumbledore.mdl"
}

function CLASS.On(self)
	if CLIENT then return end

	ApplyAppearance(self,nil,nil,nil,true)
	local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

	Appearance.AAttachments = ""
	Appearance.AColthes = ""

	self:SetNWString("PlayerName","")
	self:SetPlayerColor(Color(120,190,255):ToVector())
	self:SetModel(table.Random(models))

	self:SetNetVar("Accessories", Appearance.AAttachments or "none")

	self:SetSubMaterial()
	self:SetNWString("PlayerName", names[math.random(#names)])
	self.CurAppearance = Appearance

	self:SetNetVar("HideArmorRender", true)
end

//
//
//
//
//
//
//
//
//
//

local CLASS = player.RegClass("ministrylight")

function CLASS.Off(self)
	if CLIENT then return end
	self:SetNetVar("HideArmorRender", false)
end

local names = {
	"Люмен", "Аврелиан", "Солвейг", "Люциан", "Элисар",
	"Фаэтон", "Аурелия", "Кассиэль", "Серафин", "Офелион",
	"Эйрис", "Луксар", "Фелориан", "Гелиос", "Сильвен"
}

local models = {
	"models/Cult_of_Iron/Templar.mdl",
	"models/Cult_of_Iron/Cultist.mdl"
}

local ranks = {
	{ name = "Верховный инквизитор света", chance = 2 },
	{ name = "Лорд-комиссар рассвета", chance = 4 },
	{ name = "Гранд-маршал сияния", chance = 7 },
	{ name = "Архон света", chance = 10 },
	{ name = "Прелат лучезарности", chance = 14 },
	{ name = "Капитан священного дозора", chance = 18 },
	{ name = "Старший люминар", chance = 20 },
	{ name = "Люминар", chance = 25 }
}

local clr = Color(255,230,120):ToVector()

function CLASS.On(self)
	if CLIENT then return end

	ApplyAppearance(self,nil,nil,nil,true)
	local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

	Appearance.AAttachments = ""
	Appearance.AColthes = ""

	local randomValue = math.random(100)
	local cumulativeChance = 0
	local rank = "Люминар"

	for _, rankInfo in ipairs(ranks) do
		cumulativeChance = cumulativeChance + rankInfo.chance
		if randomValue <= cumulativeChance then
			rank = rankInfo.name
			break
		end
	end

	local codename = names[math.random(#names)]

	self:SetNWString("PlayerName", rank .. " " .. codename)
	self:SetPlayerColor(clr)
	self:SetModel(table.Random(models))
	self:SetBodyGroups("000000000000000000")
	self:SetSubMaterial()
	self:SetNetVar("Accessories", Appearance.AAttachments or "none")

	self.CurAppearance = Appearance

	self:SetNetVar("HideArmorRender", true)
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