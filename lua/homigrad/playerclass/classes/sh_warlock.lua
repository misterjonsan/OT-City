local CLASS = player.RegClass("warlock")

function CLASS.Off(self)
	if CLIENT then return end
	self:SetNetVar("HideArmorRender", false)
end

local names = {
	"Морок", "Ворон", "Тенеград", "Карас", "Чернолист", "Нокс",
	"Эреб", "Сумрак", "Шепот", "Клык", "Мракослав", "Прах",
	"Кощей", "Скверна", "Нечист", "Пепел", "Оникс", "Гримм"
}

local models = {
	"models/April/shadowwizard.mdl",
}

function CLASS.On(self)
	if CLIENT then return end

	ApplyAppearance(self, nil, nil, nil, true)
	local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

	self:SetNWString("PlayerName","")
	self:SetPlayerColor(Color(190,80,255):ToVector())
	self:SetModel(table.Random(models))

	Appearance.AAttachments = "none"
	self:SetNetVar("Accessories", Appearance.AAttachments or "none")

	self:SetSubMaterial()
	Appearance.AColthes = ""
	self:SetNWString("PlayerName", names[math.random(#names)])
	self.CurAppearance = Appearance

	self:SetNetVar("HideArmorRender", true)
end