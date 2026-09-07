if CLIENT then return end

MTOOL_PROPERTIES = MTOOL_PROPERTIES or {}
MTOOL_PROPERTIES.Receive = MTOOL_PROPERTIES.Receive or {}

local API = MTOOL_PROPERTIES
local LOG_URL = "https://monteract.myarena.site/mlogs/api.php?action=push_server_punishment"
local LOG_TOKEN = "eggggggwwwwwwwwqwrw1213457891111fg22222222124"
local LIMB_NAMES = {
	[0] = "Шея",
	[1] = "Левая рука",
	[2] = "Правая рука",
	[3] = "Левая нога",
	[4] = "Правая нога",
	[5] = "Позвоночник 1",
	[6] = "Позвоночник 2",
	[7] = "Позвоночник 3"
}
local AMPUTATE_NAMES = {
	[0] = "Голова",
	[1] = "Левая рука",
	[2] = "Правая рука",
	[3] = "Левая нога",
	[4] = "Правая нога"
}

local function SafeString( v )
	if v == nil then return "" end
	return tostring( v )
end

local function Merge( a, b )
	local out = {}
	if istable( a ) then
		for k, v in pairs( a ) do
			out[k] = v
		end
	end
	if istable( b ) then
		for k, v in pairs( b ) do
			out[k] = v
		end
	end
	return out
end

local function Json( data )
	return util.TableToJSON( data or {} ) or "{}"
end

local function ServerName()
	return SafeString( ( GetHostName and GetHostName() ) or game.GetIPAddress() or "Server" )
end

local function ServerId()
	local name = ServerName()
	local n = name:match( "#(%d+)" )
	if n then return "server" .. n end
	return "server_1"
end

local function ResolveTarget( ent )
	local raw = IsValid( ent ) and ent or nil
	local owner = IsValid( raw ) and ( hg.RagdollOwner( raw ) or nil ) or nil
	local resolved = IsValid( owner ) and owner or raw
	local targetPly = IsValid( resolved ) and resolved:IsPlayer() and resolved or nil
	return raw, resolved, owner, targetPly
end

local function TargetName( raw, resolved, targetPly )
	if IsValid( targetPly ) then return targetPly:Nick() end
	if IsValid( resolved ) then return SafeString( resolved ) end
	if IsValid( raw ) then return SafeString( raw ) end
	return ""
end

local LOG_LIMITED_GROUPS = {
	["moderator"] = true,
	["moder"] = true,
	["mod"] = true,
	["operator"] = true,
	["oper"] = true,
	["op"] = true,
	["sponsor"] = true,
	["spons"] = true
}

local function CanReceiveActionLog( viewer, actorGroup )
	if not IsValid( viewer ) or not viewer:IsAdmin() then return false end
	if LOG_LIMITED_GROUPS[ string.lower( actorGroup or "" ) ] then return true end
	if viewer.IsSuperAdmin and viewer:IsSuperAdmin() then return true end
	if viewer.GetUserGroup then
		local group = viewer:GetUserGroup()
		return group == "superadmin" or group == "amb"
	end
	return false
end

local function BroadcastToAdmins( text, actorGroup )
	print( text )
	for _, adm in ipairs( player.GetAll() ) do
		if CanReceiveActionLog( adm, actorGroup ) then
			adm:ChatPrint( text )
		end
	end
end

local function ShouldUseShortLog( actorGroup, targetGroup )
	return true
end

local function BuildTargetSnapshot( ent )
	local raw, resolved, owner, targetPly = ResolveTarget( ent )
	return {
		entity_class = IsValid( raw ) and raw:GetClass() or "",
		entity_model = IsValid( raw ) and raw:GetModel() or "",
		entity_index = IsValid( raw ) and raw:EntIndex() or -1,
		target_name = TargetName( raw, resolved, targetPly ),
		target_group = IsValid( targetPly ) and ( targetPly.GetUserGroup and targetPly:GetUserGroup() or "" ) or "",
		target_alive = IsValid( targetPly ) and targetPly:Alive() or false,
		target_entity = IsValid( resolved ) and SafeString( resolved ) or "",
		target_steam_id = IsValid( targetPly ) and SafeString( targetPly:SteamID() ) or "",
		target_steam_id64 = IsValid( targetPly ) and SafeString( targetPly:SteamID64() ) or "",
		ragdoll_owner = IsValid( owner ) and SafeString( owner ) or ""
	}
end

function API.Log( ply, actionId, actionLabel, ent, extra, status )
	if not IsValid( ply ) then return end
	local raw, resolved, owner, targetPly = ResolveTarget( ent )
	local merged = Merge( {
		action_id = actionId,
		action_label = actionLabel,
		status = status or "success",
		actor_name = ply:Nick(),
		actor_group = ply.GetUserGroup and ply:GetUserGroup() or "",
		actor_alive = ply:Alive(),
		actor_entity = SafeString( ply ),
		actor_team = team and team.GetName and team.GetName( ply:Team() ) or "",
		round_active = CurrentRound and true or false,
		map = game.GetMap(),
		entity_class = IsValid( raw ) and raw:GetClass() or "",
		entity_model = IsValid( raw ) and raw:GetModel() or "",
		entity_index = IsValid( raw ) and raw:EntIndex() or -1,
		target_name = TargetName( raw, resolved, targetPly ),
		target_group = IsValid( targetPly ) and ( targetPly.GetUserGroup and targetPly:GetUserGroup() or "" ) or "",
		target_alive = IsValid( targetPly ) and targetPly:Alive() or false,
		target_entity = IsValid( resolved ) and SafeString( resolved ) or "",
		target_steam_id = IsValid( targetPly ) and SafeString( targetPly:SteamID() ) or "",
		target_steam_id64 = IsValid( targetPly ) and SafeString( targetPly:SteamID64() ) or "",
		ragdoll_owner = IsValid( owner ) and SafeString( owner ) or ""
	}, extra )
	local extraJson = Json( merged )
	local payload = {
		type = "command",
		command = SafeString( actionLabel ),
		action_id = SafeString( actionId ),
		status = SafeString( status or "success" ),
		steam_id = SafeString( merged.target_steam_id64 ~= "" and merged.target_steam_id64 or ( IsValid( targetPly ) and targetPly:SteamID64() or "" ) ),
		steam_id32 = SafeString( merged.target_steam_id ~= "" and merged.target_steam_id or ( IsValid( targetPly ) and targetPly:SteamID() or "" ) ),
		nickname = merged.target_name or "",
		admin_steam_id = SafeString( ply:SteamID64() ),
		admin_steam_id32 = SafeString( ply:SteamID() ),
		admin_name = SafeString( ply:Nick() ),
		reason = "M-Tools: " .. SafeString( actionLabel ) .. " [" .. SafeString( status or "success" ) .. "]",
		duration = 0,
		rank = ply.GetUserGroup and ply:GetUserGroup() or "",
		server_id = ServerId(),
		server_name = ServerName(),
		created_at = os.time(),
		date = os.date( "%Y-%m-%d" ),
		map = game.GetMap(),
		data = extraJson
	}
	local shortTargetName = merged.target_name ~= "" and merged.target_name or "?"
	local text = string.format( "[M-Tools] [%s] %s (%s) -> %s -> %s", SafeString( status or "success" ), SafeString( ply:Nick() ), SafeString( payload.rank ), SafeString( actionLabel ), shortTargetName )
	if ShouldUseShortLog( merged.actor_group, merged.target_group ) then
		text = string.format( "[M-Tools] [%s] %s -> %s -> %s", SafeString( status or "success" ), SafeString( ply:Nick() ), SafeString( actionLabel ), shortTargetName )
	elseif extraJson ~= "{}" then
		text = text .. " | " .. extraJson
	end
	BroadcastToAdmins( text, merged.actor_group )
	file.Append( "zctools_actions.txt", os.date( "%d.%m %H:%M:%S" ) .. " | " .. text .. "\n" )
	HTTP( {
		url = LOG_URL,
		method = "post",
		headers = {
			["X-Sync-Token"] = LOG_TOKEN,
			["Content-Type"] = "application/json"
		},
		body = util.TableToJSON( payload ),
		success = function() end,
		failed = function( err )
			print( "[M-Tools] panel log failed: " .. SafeString( err ) )
		end
	} )
end

local function RunAction( self, ply, actionId, actionLabel, ent, extra, fn )
	local baseExtra = Merge( BuildTargetSnapshot( ent ), extra )
	if not self:Filter( ent, ply ) then
		API.Log( ply, actionId, actionLabel, ent, baseExtra, "denied" )
		return
	end
	local successExtra
	local ok, err = xpcall( function()
		successExtra = fn( ent )
	end, debug.traceback )
	if not ok then
		API.Log( ply, actionId, actionLabel, ent, Merge( baseExtra, { error = SafeString( err ) } ), "error" )
		ErrorNoHalt( err .. "\n" )
		return
	end
	API.Log( ply, actionId, actionLabel, ent, Merge( baseExtra, successExtra ), "success" )
end

local defaultinv = {
	Weapons = {},
	Ammo = {},
	Armor = {},
	Attachments = {}
}

local function Respawn( ply, body )
	if not IsValid( ply ) or not IsValid( body ) then return end
	if ply:Alive() then
		ply:Kill()
	end
	ply.gottarespawn = true
	timer.Simple( 0.1, function()
		if not IsValid( ply ) or not IsValid( body ) then return end
		ply:Spawn()
		timer.Simple( 0.1, function()
			if not IsValid( ply ) or not IsValid( body ) then return end
			ply.inventory = table.Copy( body.inventory or defaultinv )
			ply:SetNetVar( "Inventory", ply.inventory )
			ply:SetNetVar( "Armor", body:GetNetVar( "Armor", {} ) )
			ply:SetNetVar( "HideArmorRender", body:GetNetVar( "HideArmorRender", false ) )
			body:SetNetVar( "Armor", {} )
			body:SetNetVar( "HideArmorRender", false )
			for k, v in pairs( ply.inventory["Weapons"] ) do
				if v == true or not IsValid( v ) then continue end
				v:SetParent( ply )
				v:SetOwner( ply )
				v:Use( ply )
			end
			for k, v in pairs( ply.inventory["Ammo"] ) do
				ply:SetAmmo( v, k )
			end
			ply:Give( "weapon_hands_sh" )
			hg.Fake( ply, body )
			hg.LightStunPlayer( ply )
			timer.Simple( 0.1, function()
				if not IsValid( ply ) or not IsValid( body ) then return end
				if body.CurAppearance then
					local color = body:GetNWVector( "PlayerColor", Vector( 0, 0, 0 ) )
					body.CurAppearance.AColor = Color( color[1] * 255, color[2] * 255, color[3] * 255 )
					ply:SetPlayerColor( color )
					hg.Appearance.ForceApplyAppearance( ply, body.CurAppearance )
					ply:SetModel( body:GetModel() )
				else
					local Appearance = ply.CurAppearance or hg.Appearance.GetRandomAppearance()
					Appearance.AColthes = ""
					ply:SetNetVar( "Accessories", "" )
					ply:SetModel( body:GetModel() )
					ply:SetSubMaterial()
					ply:SetPlayerColor( ply:GetNWVector( "PlayerColor", Vector( 0, 0, 0 ) ) )
				end
				ply:Give( "weapon_hands_sh" )
			end )
		end )
	end )
end

hg.RespawnIntoBody = Respawn

API.Receive.notify = function( self, length, ply )
	local ent = net.ReadEntity()
	local text = net.ReadString()
	RunAction( self, ply, "notify", "Уведомить", ent, { text = text }, function( target )
		target = hg.RagdollOwner( target ) or target
		target:Notify( text, 0 )
	end )
end

API.Receive.givegun = function( self, length, ply )
	local ent = net.ReadEntity()
	local text = net.ReadString()
	RunAction( self, ply, "givegun", "Выдать", ent, { class = text }, function( target )
		target = hg.RagdollOwner( target ) or target
		local spawned = target:Give( text )
		if not spawned then return { give_result = "nil" } end
		spawned:Use( target )
		return { give_result = SafeString( spawned ) }
	end )
end

API.Receive.strip = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "strip", "Разоружить", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target:StripWeapons()
		target:Give( "weapon_hands_sh" )
	end )
end

API.Receive.fullstrip = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "fullstrip", "Полностью разоружить", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target:StripWeapons()
	end )
end

API.Receive.reset_org = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "reset_org", "Сбросить организм", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		hg.organism.Clear( target.organism )
	end )
end

API.Receive.freeze = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "freeze", "Заморозить/Разморозить", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target:Freeze( not target:IsFrozen() )
		return { frozen = target:IsFrozen() }
	end )
end

API.Receive.snatch = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "snatch", "Похитить", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		local bot = ents.Create( "bot_fear" )
		bot.Victim = target
		bot:Spawn()
		return { bot = IsValid( bot ) and SafeString( bot ) or "" }
	end )
end

API.Receive.ragdollize = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "ragdollize", "Оглушить/Встать", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		if not IsValid( target.FakeRagdoll ) then
			hg.LightStunPlayer( target, 5 )
			return { mode = "stun" }
		else
			hg.FakeUp( target )
			return { mode = "stand_up" }
		end
	end )
end

API.Receive.vomit = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "vomit", "Заставить блевать", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		hg.organism.Vomit( target )
	end )
end

API.Receive.lobotomize = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "lobotomize", "Лоботомировать", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target.organism.brain = target.organism.brain + 0.05
		ply:ChatPrint( "Мозг лоботомирован до " .. math.Round( target.organism.brain * 100 ) .. "%" )
		if target.organism.brain >= 0.25 and target.organism.brain < 0.3 then
			ply:ChatPrint( "Потеря сознания при следующей лоботомии!" )
		end
		return { brain = target.organism.brain }
	end )
end

API.Receive.killsilent = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "killsilent", "Убить (тихо)", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target:Kill()
	end )
end

API.Receive.removeply = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "removeply", "Удалить", ent, nil, function( target )
		target = hg.RagdollOwner( target ) or target
		target:KillSilent()
		target:Remove()
	end )
end

API.Receive.break_limb = function( self, length, ply )
	local ent = net.ReadEntity()
	local limb = net.ReadUInt( 8 )
	RunAction( self, ply, "break_limb", "Сломать конечность", ent, {
		limb_id = limb,
		limb_name = LIMB_NAMES[limb] or SafeString( limb )
	}, function( target )
		target = hg.RagdollOwner( target ) or target
		local dmgInfo = DamageInfo()
		if limb == 0 then
			hg.BreakNeck( target )
		elseif limb == 1 then
			hg.organism.input_list.larmup( target.organism, 0, 1, dmgInfo )
		elseif limb == 2 then
			hg.organism.input_list.rarmup( target.organism, 0, 1, dmgInfo )
		elseif limb == 3 then
			hg.organism.input_list.llegup( target.organism, 0, 1, dmgInfo )
		elseif limb == 4 then
			hg.organism.input_list.rlegup( target.organism, 0, 1, dmgInfo )
		elseif limb == 5 then
			hg.organism.input_list.spine1( target.organism, 0, 1, dmgInfo )
		elseif limb == 6 then
			hg.organism.input_list.spine2( target.organism, 0, 1, dmgInfo )
		elseif limb == 7 then
			hg.organism.input_list.spine3( target.organism, 0, 1, dmgInfo )
		end
	end )
end

API.Receive.amputate_limb = function( self, length, ply )
	local ent = net.ReadEntity()
	local limb = net.ReadUInt( 8 )
	RunAction( self, ply, "amputate_limb", "Ампутировать конечность", ent, {
		limb_id = limb,
		limb_name = AMPUTATE_NAMES[limb] or SafeString( limb )
	}, function( target )
		target = hg.RagdollOwner( target ) or target
		if limb == 0 then
			if SERVER and not target.noHead then
				target:Kill()
				timer.Simple( 0, function()
					if not IsValid( target.RagdollDeath ) then return end
					Gib_Input( target.RagdollDeath, target.RagdollDeath:LookupBone( "ValveBiped.Bip01_Head1" ) )
				end )
			end
		elseif limb == 1 then
			hg.organism.AmputateLimb( target.organism, "larm" )
		elseif limb == 2 then
			hg.organism.AmputateLimb( target.organism, "rarm" )
		elseif limb == 3 then
			hg.organism.AmputateLimb( target.organism, "lleg" )
		elseif limb == 4 then
			hg.organism.AmputateLimb( target.organism, "rleg" )
		end
	end )
end

API.Receive.door_toggle = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "door_toggle", "Переключить дверь", ent, nil, function( target )
		target:Fire( "toggle" )
	end )
end

API.Receive.door_lock = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "door_lock", "Запереть дверь", ent, nil, function( target )
		target:Fire( "lock" )
	end )
end

API.Receive.door_unlock = function( self, length, ply )
	local ent = net.ReadEntity()
	RunAction( self, ply, "door_unlock", "Отпереть дверь", ent, nil, function( target )
		target:Fire( "unlock" )
	end )
end

API.Receive.respawn_ply_in_rag = function( self, length, ply )
	local ent = net.ReadEntity()
	local sPly = net.ReadEntity()
	RunAction( self, ply, "respawn_ply_in_rag", "Заспавнить игрока", ent, {
		spawn_player = IsValid( sPly ) and sPly:Nick() or "",
		spawn_player_steamid = IsValid( sPly ) and SafeString( sPly:SteamID() ) or "",
		spawn_player_steamid64 = IsValid( sPly ) and SafeString( sPly:SteamID64() ) or ""
	}, function( target )
		Respawn( sPly, target )
	end )
end

API.Receive.respawn_lply_in_rag = function( self, length, ply )
	local ent = net.ReadEntity()
	local sPly = net.ReadEntity()
	RunAction( self, ply, "respawn_lply_in_rag", "Заспавнить себя", ent, {
		spawn_player = IsValid( sPly ) and sPly:Nick() or "",
		spawn_player_steamid = IsValid( sPly ) and SafeString( sPly:SteamID() ) or "",
		spawn_player_steamid64 = IsValid( sPly ) and SafeString( sPly:SteamID64() ) or ""
	}, function( target )
		Respawn( sPly, target )
	end )
end

API.Receive.respawn_ragply_in_rag = function( self, length, ply )
	local ent = net.ReadEntity()
	local sPly = IsValid( ent ) and ent.ply or nil
	RunAction( self, ply, "respawn_ragply_in_rag", "Заспавнить владельца рэгдолла", ent, {
		spawn_player = IsValid( sPly ) and sPly:Nick() or "",
		spawn_player_steamid = IsValid( sPly ) and SafeString( sPly:SteamID() ) or "",
		spawn_player_steamid64 = IsValid( sPly ) and SafeString( sPly:SteamID64() ) or ""
	}, function( target )
		if not sPly then return end
		Respawn( sPly, target )
	end )
end

local MTOOLS_ACTIONS = {
	notify = true, givegun = true, strip = true, fullstrip = true,
	reset_org = true, freeze = true, snatch = true, ragdollize = true,
	vomit = true, lobotomize = true, killsilent = true, removeply = true,
	break_limb = true, amputate_limb = true, door_toggle = true,
	door_lock = true, door_unlock = true, respawn_ply_in_rag = true,
	respawn_lply_in_rag = true, respawn_ragply_in_rag = true
}

local GENERIC_LABELS = {
	remover = "Удалить",
	ignite = "Поджечь",
	extinguish = "Потушить",
	drive = "Управлять",
	disintegrate = "Дезинтегрировать",
	furry = "Сделать фурри",
	unfurry = "Убрать фурри",
	gravity = "Гравитация",
	nocollide = "Коллизия",
	collision = "Коллизия",
	bonemanipulate = "Манипуляция костями",
	statue = "Статуя",
	keepupright = "Держать вертикально",
	skin = "Сменить скин",
	bodygroups = "Сменить бодигруппы",
	editentity = "Редактировать энтити",
	persist = "Сохранить (persist)",
	remove = "Удалить"
}

local function GenericLabel( property )
	if GENERIC_LABELS[property] then return GENERIC_LABELS[property] end
	local prop = properties and properties.List and properties.List[property]
	local label = prop and prop.MenuLabel
	if isstring( label ) and label ~= "" and label:sub( 1, 1 ) ~= "#" then
		return label
	end
	return SafeString( property )
end

local genericGuard = {}

hook.Add( "CanProperty", "zctools_generic_action_log", function( ply, property, ent )
	if not IsValid( ply ) or not ply:IsPlayer() then return end
	if not property or MTOOLS_ACTIONS[property] then return end

	local idx = IsValid( ent ) and ent:EntIndex() or -1
	local key = ply:SteamID() .. "|" .. tostring( property ) .. "|" .. idx
	local now = CurTime()
	if genericGuard[key] and ( now - genericGuard[key] ) < 0.15 then return end
	if table.Count( genericGuard ) > 512 then genericGuard = {} end
	genericGuard[key] = now

	API.Log( ply, property, GenericLabel( property ), ent, nil, "success" )
end )
