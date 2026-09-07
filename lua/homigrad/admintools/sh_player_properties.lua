local function IsLimited()
	if not CLIENT then return false end
	local ply = LocalPlayer()
	if not IsValid( ply ) then return false end
	if ply:IsAdmin() then return false end
	return ply:ZCTools_IsLimitedStaff()
end

local function IsMod( ply )
	if not IsValid( ply ) then return false end
	if ply:IsAdmin() then return false end
	return ply:ZCTools_IsLimitedStaff()
end

local function ModGuard( warning, fn )
	if not IsLimited() then
		fn()
		return
	end

	Derma_Query(
		( warning and ( warning .. "\n\n" ) or "" ) .. "Мы следим за вами. Это действие будет записано и отправлено администрации.",
		"Вы уверены?",
		"Да",
		fn,
		"Нет"
	)
end

local function check( self, ent, ply )
	if not ply:ZCTools_GetAccess() then return false end
	if not IsValid( ent ) then return false end
	if ent:IsPlayer() then return true end
	local pEnt = hg.RagdollOwner( ent )
	if ent:IsRagdoll() and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
end

local function adminOnlyCheck( self, ent, ply )
	if IsMod( ply ) then return false end
	return check( self, ent, ply )
end

local function doorCheck( self, ent, ply )
	if not ply:ZCTools_GetAccess() then return false end
	if not IsValid( ent ) then return false end
	if not ent:GetClass():lower():find( "door" ) then return false end
	return true
end

local function ServerReceive( name )
	if not SERVER then return nil end
	return function( self, length, ply )
		local api = _G.MTOOL_PROPERTIES
		if not api or not api.Receive or not api.Receive[name] then return end
		return api.Receive[name]( self, length, ply )
	end
end

properties.Add( "notify", {
	MenuLabel = "Уведомить",
	Order = 1,
	MenuIcon = "icon16/note_add.png",
	Filter = check,
	Action = function( self, ent )
		Derma_StringRequest(
			"Уведомить " .. ent:GetPlayerName(),
			"Напишите сообщение",
			"",
			function( text )
				self:MsgStart()
				net.WriteEntity( ent )
				net.WriteString( text )
				self:MsgEnd()
			end
		)
	end,
	Receive = ServerReceive( "notify" )
} )

properties.Add( "givegun", {
	MenuLabel = "Выдать",
	Order = 2,
	MenuIcon = "icon16/gun.png",
	Filter = check,
	Action = function( self, ent )
		local function ask()
			Derma_StringRequest(
				"Выдать " .. ent:GetPlayerName(),
				"Напишите класс энтити",
				"",
				function( text )
					self:MsgStart()
					net.WriteEntity( ent )
					net.WriteString( text )
					self:MsgEnd()
				end
			)
		end
		ModGuard( "Вы выдаёте оружие/энтити игроку.", ask )
	end,
	Receive = ServerReceive( "givegun" )
} )

properties.Add( "strip", {
	MenuLabel = "Разоружить",
	Order = 3,
	MenuIcon = "icon16/basket_delete.png",
	Filter = check,
	Action = function( self, ent )
		local function send()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end
		if IsLimited() then
			ModGuard( "Игрок будет разоружён (получит руки).", send )
		else
			Derma_Query(
				"Игрок автоматически получит руки",
				"Вы уверены?",
				"Да",
				send,
				"Нет"
			)
		end
	end,
	Receive = ServerReceive( "strip" )
} )

properties.Add( "fullstrip", {
	MenuLabel = "Полностью разоружить",
	Order = 4,
	MenuIcon = "icon16/lorry_delete.png",
	Filter = check,
	Action = function( self, ent )
		local function send()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end
		if IsLimited() then
			ModGuard( "Руки тоже будут убраны.", send )
		else
			Derma_Query(
				"Руки тоже будут убраны",
				"Вы уверены?",
				"Да",
				send,
				"Нет"
			)
		end
	end,
	Receive = ServerReceive( "fullstrip" )
} )

properties.Add( "reset_org", {
	MenuLabel = "Сбросить организм",
	Order = 5,
	MenuIcon = "icon16/heart_add.png",
	Filter = check,
	Action = function( self, ent )
		local function send()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end
		if IsLimited() then
			ModGuard( "Организм будет новым, как после респавна.", send )
		else
			Derma_Query(
				"Организм будет новым, как после респавна",
				"Вы уверены?",
				"Да",
				send,
				"Нет"
			)
		end
	end,
	Receive = ServerReceive( "reset_org" )
} )

properties.Add( "freeze", {
	MenuLabel = "Заморозить",
	Order = 6,
	MenuIcon = "icon16/control_pause_blue.png",
	Filter = function( self, ent, ply )
		if not ply:ZCTools_GetAccess() then return false end
		if not IsValid( ent ) then return false end
		local pEnt = hg.RagdollOwner( ent ) or ent
		self.MenuLabel = pEnt:IsPlayer() and pEnt:IsFrozen() and "Разморозить" or "Заморозить"
		self.MenuIcon = pEnt:IsPlayer() and pEnt:IsFrozen() and "icon16/control_pause.png" or "icon16/control_pause_blue.png"
		if ent:IsPlayer() then return true end
		if ent:IsRagdoll() and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
	end,
	Action = function( self, ent )
		ModGuard( "Вы замораживаете/размораживаете игрока.", function()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end )
	end,
	Receive = ServerReceive( "freeze" )
} )

properties.Add( "snatch", {
	MenuLabel = "Похитить",
	Order = 7,
	MenuIcon = "icon16/cross.png",
	Filter = function( self, ent, ply )
		if IsMod( ply ) then return false end
		if not CurrentRound then return false end
		return check( self, ent, ply )
	end,
	Action = function( self, ent )
		Derma_Query(
			"Если рядом нет игроков, он просто исчезнет.",
			"Вы уверены?",
			"Да",
			function()
				self:MsgStart()
				net.WriteEntity( ent )
				self:MsgEnd()
			end,
			"Нет"
		)
	end,
	Receive = ServerReceive( "snatch" )
} )

properties.Add( "ragdollize", {
	MenuLabel = "Оглушить/Встать",
	Order = 8,
	MenuIcon = "icon16/anchor.png",
	Filter = check,
	Action = function( self, ent )
		ModGuard( "Вы оглушаете/поднимаете игрока.", function()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end )
	end,
	Receive = ServerReceive( "ragdollize" )
} )

properties.Add( "vomit", {
	MenuLabel = "Заставить блевать",
	Order = 9,
	MenuIcon = "pluv/pluv51.png",
	Filter = adminOnlyCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "vomit" )
} )

properties.Add( "lobotomize", {
	MenuLabel = "Лоботомировать",
	Order = 10,
	MenuIcon = "pluv/pluv51.png",
	Filter = adminOnlyCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "lobotomize" )
} )

properties.Add( "killsilent", {
	MenuLabel = "Убить (тихо)",
	Order = 11,
	MenuIcon = "icon16/cross.png",
	Filter = check,
	Action = function( self, ent )
		ModGuard( "Вы убиваете игрока.", function()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end )
	end,
	Receive = ServerReceive( "killsilent" )
} )

properties.Add( "removeply", {
	MenuLabel = "Удалить",
	Order = 12,
	MenuIcon = "icon16/cross.png",
	Filter = adminOnlyCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "removeply" )
} )

properties.Add( "break_limb", {
	MenuLabel = "Сломать конечность",
	Order = 13,
	MenuIcon = "pluv/pluv51.png",
	Filter = adminOnlyCheck,
	MenuOpen = function( self, option, ent, tr )
		ent = hg.RagdollOwner( ent ) or ent
		local submenu = option:AddSubMenu()
		local neck = submenu:AddOption( "Шея" )
		neck:SetRadio( true )
		neck:SetChecked( ent.organism.larm > 0 )
		neck:SetIsCheckable( true )
		neck.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 0 ) end end
		local larm = submenu:AddOption( "Левая рука" )
		larm:SetRadio( true )
		larm:SetChecked( ent.organism.larm > 0 )
		larm:SetIsCheckable( true )
		larm.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 1 ) end end
		local rarm = submenu:AddOption( "Правая рука" )
		rarm:SetRadio( true )
		rarm:SetChecked( ent.organism.rarm > 0 )
		rarm:SetIsCheckable( true )
		rarm.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 2 ) end end
		local lleg = submenu:AddOption( "Левая нога" )
		lleg:SetRadio( true )
		lleg:SetChecked( ent.organism.lleg > 0 )
		lleg:SetIsCheckable( true )
		lleg.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 3 ) end end
		local rleg = submenu:AddOption( "Правая нога" )
		rleg:SetRadio( true )
		rleg:SetChecked( ent.organism.rleg > 0 )
		rleg:SetIsCheckable( true )
		rleg.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 4 ) end end
		local spine1 = submenu:AddOption( "Позвоночник 1" )
		spine1:SetRadio( true )
		spine1:SetChecked( ent.organism.rleg > 0 )
		spine1:SetIsCheckable( true )
		spine1.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 5 ) end end
		local spine2 = submenu:AddOption( "Позвоночник 2" )
		spine2:SetRadio( true )
		spine2:SetChecked( ent.organism.rleg > 0 )
		spine2:SetIsCheckable( true )
		spine2.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 6 ) end end
		local spine3 = submenu:AddOption( "Позвоночник 3" )
		spine3:SetRadio( true )
		spine3:SetChecked( ent.organism.rleg > 0 )
		spine3:SetIsCheckable( true )
		spine3.OnChecked = function( s, checked ) if checked then self:BreakLimb( ent, 7 ) end end
	end,
	BreakLimb = function( self, ent, id )
		self:MsgStart()
		net.WriteEntity( ent )
		net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "break_limb" )
} )

properties.Add( "amputate_limb", {
	MenuLabel = "Ампутировать конечность",
	Order = 14,
	MenuIcon = "effects/arc9_eft/evil.png",
	Filter = adminOnlyCheck,
	MenuOpen = function( self, option, ent, tr )
		ent = hg.RagdollOwner( ent ) or ent
		local submenu = option:AddSubMenu()
		local head = submenu:AddOption( "Голова" )
		head:SetRadio( true )
		head:SetChecked( ent.organism.larm > 0 )
		head:SetIsCheckable( true )
		head.OnChecked = function( s, checked ) if checked then self:AmputateLimb( ent, 0 ) end end
		local larm = submenu:AddOption( "Левая рука" )
		larm:SetRadio( true )
		larm:SetChecked( ent.organism.larm > 0 )
		larm:SetIsCheckable( true )
		larm.OnChecked = function( s, checked ) if checked then self:AmputateLimb( ent, 1 ) end end
		local rarm = submenu:AddOption( "Правая рука" )
		rarm:SetRadio( true )
		rarm:SetChecked( ent.organism.rarm > 0 )
		rarm:SetIsCheckable( true )
		rarm.OnChecked = function( s, checked ) if checked then self:AmputateLimb( ent, 2 ) end end
		local lleg = submenu:AddOption( "Левая нога" )
		lleg:SetRadio( true )
		lleg:SetChecked( ent.organism.lleg > 0 )
		lleg:SetIsCheckable( true )
		lleg.OnChecked = function( s, checked ) if checked then self:AmputateLimb( ent, 3 ) end end
		local rleg = submenu:AddOption( "Правая нога" )
		rleg:SetRadio( true )
		rleg:SetChecked( ent.organism.rleg > 0 )
		rleg:SetIsCheckable( true )
		rleg.OnChecked = function( s, checked ) if checked then self:AmputateLimb( ent, 4 ) end end
	end,
	AmputateLimb = function( self, ent, id )
		self:MsgStart()
		net.WriteEntity( ent )
		net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "amputate_limb" )
} )

properties.Add( "door_toggle", {
	MenuLabel = "Переключить дверь",
	Order = 7,
	MenuIcon = "icon16/door.png",
	Filter = doorCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "door_toggle" )
} )

properties.Add( "door_lock", {
	MenuLabel = "Запереть дверь",
	Order = 8,
	MenuIcon = "icon16/lock.png",
	Filter = doorCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "door_lock" )
} )

properties.Add( "door_unlock", {
	MenuLabel = "Отпереть дверь",
	Order = 9,
	MenuIcon = "icon16/lock_open.png",
	Filter = doorCheck,
	Action = function( self, ent )
		self:MsgStart()
		net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = ServerReceive( "door_unlock" )
} )

properties.Add( "respawn_ply_in_rag", {
	MenuLabel = "Заспавнить игрока",
	Order = 1,
	MenuIcon = "icon16/heart.png",
	Filter = function( self, ent, ply )
		if not ply:ZCTools_GetAccess() then return false end
		if not IsValid( ent ) then return false end
		local pEnt = hg.RagdollOwner( ent ) or ent
		if pEnt:IsRagdoll() then return true end
	end,
	Action = function( self, ent )
		local function pick()
			hg.DermaPlayerQuery( function( ply )
				self:MsgStart()
				net.WriteEntity( ent )
				net.WriteEntity( ply )
				self:MsgEnd()
			end )
		end
		if IsLimited() then
			ModGuard( "Вы заспавните игрока в это тело.", pick )
		else
			pick()
		end
	end,
	Receive = ServerReceive( "respawn_ply_in_rag" )
} )

properties.Add( "respawn_lply_in_rag", {
	MenuLabel = "Заспавнить себя",
	Order = 2,
	MenuIcon = "icon16/heart.png",
	Filter = function( self, ent, ply )
		if not ply:ZCTools_GetAccess() then return false end
		if not IsValid( ent ) then return false end
		local pEnt = hg.RagdollOwner( ent ) or ent
		if pEnt:IsRagdoll() then return true end
	end,
	Action = function( self, ent )
		local function send()
			self:MsgStart()
			net.WriteEntity( ent )
			net.WriteEntity( LocalPlayer() )
			self:MsgEnd()
		end
		if IsLimited() then
			ModGuard( "Вы заспавнитесь в это тело.", send )
		else
			Derma_Query(
				"Вы заспавнитесь в это тело",
				"Вы уверены?",
				"Да",
				send,
				"Нет"
			)
		end
	end,
	Receive = ServerReceive( "respawn_lply_in_rag" )
} )

properties.Add( "respawn_ragply_in_rag", {
	MenuLabel = "Заспавнить владельца рэгдолла",
	Order = 3,
	MenuIcon = "icon16/heart.png",
	Filter = function( self, ent, ply )
		if not ply:ZCTools_GetAccess() then return false end
		if not IsValid( ent ) then return false end
		local pEnt = hg.RagdollOwner( ent ) or ent
		if pEnt:IsRagdoll() then return true end
	end,
	Action = function( self, ent )
		local function send()
			self:MsgStart()
			net.WriteEntity( ent )
			self:MsgEnd()
		end
		if IsLimited() then
			ModGuard( "Владелец рэгдолла будет заспавнен в своё тело.", send )
		else
			Derma_Query(
				"Владелец рэгдолла будет заспавнен в свое тело",
				"Вы уверены?",
				"Да",
				send,
				"Нет"
			)
		end
	end,
	Receive = ServerReceive( "respawn_ragply_in_rag" )
} )
