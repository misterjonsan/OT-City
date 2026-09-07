local CLASS = player.RegClass("invader_robot")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local invaderNames = {
    "Захватчик-X1", "Захватчик-X2", "Захватчик-X3", "Захватчик-X4", "Захватчик-X5",
    "Штурмовик-Z1", "Штурмовик-Z2", "Штурмовик-Z3", "Дрон-K1", "Дрон-K2",
    "Титан-R1", "Титан-R2", "Каратель-V1", "Каратель-V2", "Нексус-01"
}

local models = {
    "models/fsb/a/Phoenix_fsb.mdl"
}

function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(170, 50, 50):ToVector())
    self:SetModel(table.Random(models))

    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    self:SetNWString("PlayerName", invaderNames[math.random(#invaderNames)])
    self.CurAppearance = Appearance

    self:SetNetVar("HideArmorRender", true)
end