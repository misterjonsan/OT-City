esclib.addon = esclib:Addon("esclib")
esclib.addon:SetName("esclib")
esclib.addon:SetBranch("release")
esclib.addon:SetVersion("2.6.0")
esclib.addon:SetDescription("Brain for addons.")
esclib.addon:SetSortOrder(999) --go to the end)
esclib.addon:SetColor(Color(255,53,73))

if CLIENT then
	esclib.addon:SetThumbnail(esclib:GetMaterial("esclib_logo.png"))
end