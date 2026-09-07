esclib.config = esclib.config or {}

esclib.config.AdminAccess = esclib.config.AdminAccess or {}

function esclib:ChangeAdminAccess(user_group,access)
	self.config.AdminAccess[user_group] = access
end

function esclib:HasAdminAccess(ply)
	local ug = esclib:GetUserGroup(ply)
	return (ug == "superadmin") or self.config.AdminAccess[ug]
end

-----------------------
--# CLIENT SETTINGS #--
-----------------------
local settings = esclib:InitSettings("esclib", "client")

local tab = settings:AddTab("general")
tab:SetNameTranslateKey("tab_general")

tab:AddVar("drawblur", "bool")
:SetNameTranslateKey("s_drawblur_name")
:SetValue(true)

tab:AddVar("animtime", "float")
:SetNameTranslateKey("s_animationspeed_name")
:SetValue(0.15)
:SetMin(0.01)
:SetMax(3)

settings:End()



-----------------------
--# SERVER SETTINGS #--
-----------------------
local settings = esclib:InitSettings("esclib", "server")

local tab = settings:AddTab("general")
tab:SetNameTranslateKey("tab_general")

tab:AddVar("debug", "bool")
:SetNameTranslateKey("s_debug_name")
:SetValue(false)
:SetShared(true)

settings:End()