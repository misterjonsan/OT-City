local CLASS = player.RegClass("chappie_robot")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local chappieNames = {
    "Чаппи-А1", "Чаппи-Р7", "Чаппи-К3", "Чаппи-Н9", "Чаппи-Т2",
    "Чаппи-В4", "Чаппи-М8", "Чаппи-Е5", "Чаппи-С6", "Чаппи-Д1",
    "Чаппи-Л2", "Чаппи-Х4", "Чаппи-О7", "Чаппи-З9", "Чаппи-Ф3"
}

local models = {
    "models/Chap/neffery/Chappie.mdl"
}

function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()

    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(40, 140, 255):ToVector())
    self:SetModel(table.Random(models))

    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    Appearance.AColthes = ""
    self:SetNWString("PlayerName", chappieNames[math.random(#chappieNames)])
    self.CurAppearance = Appearance

    self:SetNetVar("HideArmorRender", true)
end