return {
	You = "Вы",
	Yourself = "Себе",
	Themself = "Себя",
	Everyone = "Всех",

	cant_use_as_console = "Вам нужно быть игроком, чтобы использовать {S Red} команду!",
	no_permission = "У вас нет разрешения на использование '{S Red}'!",

	cant_target_multi_players = "Вы не можете выбрать нескольких игроков, используя эту команду!",
	invalid_id = "Неверный id ({S Red})!",
	cant_target_player = "Вы не можете выбрать {S Red}!",
	cant_target_self = "Вы не можете выбрать себя, используя {S Red} команду!",
	player_id_not_found = "Игрок с id {S Red} не найден!",
	found_multi_players = "Найдено несколько игроков: {T}!",
	cant_find_target = "Не могу найти игрока ({S Red})!",

	invalid = "Несуществующий {S} ({S_2 Red})",
	default_reason = "отсутствует",

	menu_help = "Открыть меню администратора.",

	-- Chat Commands
	pm_to = "PM to {T}: {V}",
	pm_from = "PM from {A}: {V}",
	pm_help = "Отправить личное сообщение (PM) игроку.",

	to_admins = "[Админ] {A}: {V}",
	asay_help = "Отправить сообщение администраторам.",

	mute = "{A} заблокировал чат {T} на {V}. ({V_2})",
	mute_help = "Запретить игроку отправлять сообщения в чате.",

	unmute = "{A} разблокировал чат {T}.",
	unmute_help = "Включить текстовыйй чат игроку.",

	you_muted = "Вы не можете отправлять сообщение в чат.",

	gag = "{A} заблокировал голосовой чат {T} на {V}. ({V_2})",
	gag_help = "Запретить игроку говорить в голосовой чат.",

	ungag = "{A} разблокировал голосовой чат {T}.",
	ungag_help = "Включить голосовой чат игроку.",

	-- Fun Commands
	slap = "{A} шлепнул {T}.",
	slap_damage = "{A} шлепнул {T} с {V} уроном.",
	slap_help = "Шлепок",

	slay = "{A} убил {T}.",
	slay_help = "Убить игрока.",

	set_hp = "{A} установил здоровье {T} на {V}.",
	hp_help = "Установить здоровье для игрока.",

	set_armor = "{A} установил броню {T} на {V}.",
	armor_help = "Установить броню для игрока.",

	ignite = "{A} поджег {T} на {V} секунду.",
	ignite_help = "Поджечь игрока.",

	unignite = "{A} потушил {T}.",
	unignite_help = "Потушить игрока.",

	god = "{A} включил режим бессмертия {T}.",
	god_help = "Включить режим бессмертия.",

	ungod = "{A} выключил режим бессмертия {T}.",
	ungod_help = "Отключить режим бессмертия для игрока",

	freeze = "{A} заморозил {T}.",
	freeze_help = "Заморозить игрока.",

	unfreeze = "{A} разморозил {T}.",
	unfreeze_help = "Разморозить игрока.",

	cloak = "{A} включил невидимость {T}.",
	cloak_help = "Включить невидимость.",

	uncloak = "{A} выключил невидимость {T}.",
	uncloak_help = "Выключить невидимость.",

	jail = "{A} посадил в деморган {T} на {V}. ({V_2})",
	jail_help = "Посадить в деморган игрока.",

	unjail = "{A} освободил из деморгана {T}.",
	unjail_help = "Освободить игрока из деморгана.",

	strip = "{A} отобрал все оружие у {T}.",
	strip_help = "Отобрать все оружие у игрока.",

	respawn = "{A} возродил {T}.",
	respawn_help = "Респавн игрока.",

	setmodel = "{A} поменял модель {T} на {V}.",
	setmodel_help = "Поменять модель игрока.",

	giveammo = "{A} выдал {T} {V} боеприпасов.",
	giveammo_help = "Выдать патроны игроку.",

	scale = "{A} установил размер игрока {T} на {V}.",
	scale_help = "Размер игрока.",

	freezeprops = "{A} заморозил все объекты на карте.",
	freezeprops_help = "Замораживает все объекты на карте.",

	-- Teleport Commands
	dead = "Вы мертвы!",
	leave_car = "Сначала покиньте автомобиль!",

	bring = "{A} телепортировал {T} к себе.",
	bring_help = "Телепорт игрока к себе.",

	goto = "{A} телепортировался к {T}.",
	goto_help = "Телепорт к игроку.",

	no_location = "Нет предыдущего местоположения для возврата {T}.",
	returned = "{A} вернул {T}.",
	return_help = "Возврат игрока туда, где он был.",

	-- User Management Commands
	setrank = "{A} установил {T} ранг {V} на {V_2}.",
	setrank_help = "Установите ранг игрока.",
	setrankid_help = "Установите ранг игрока по его steamid/steamid64.",

	addrank = "{A} создал новую группу {V}.",
	addrank_help = "Создайте новый ранг.",

	removerank = "{A} удалил группу {V}.",
	removerank_help = "Удалить ранг.",

	super_admin_access = "Вы имеете доступ ко всему!",

	giveaccess = "{A} выдал доступ {V} на {T}.",
	givepermission_help = "Выдача прав к командам.",

	takeaccess = "{A} забрал права {V} на {T}.",
	takepermission_help = "Снятие прав к командам.",

	renamerank = "{A} переименовал группу {T} на {V}.",
	renamerank_help = "Переименовать группу.",

	changeinherit = "{A} changed the rank to inherit from for {T} to {V}.",
	changeinherit_help = "Изменил группу, чтобы наследовать от.",

	rank_immunity = "{A} changed rank {T}'s immunity to {V}.",
	changerankimmunity_help = "Изменил иммунитет группы.",

	rank_ban_limit = "{A} changed rank {T}'s ban limit to {V}.",
	changerankbanlimit_help = "Изменить группе ограничение бана.",

	changeranklimit = "{A} changed {V} limit for {T} to {V_2}.",
	changeranklimit_help = "Изменение ограничений на группы.",

	-- Utility Commands
	map_change = "{A} changing the map to {V} in 10 seconds.",
	map_change2 = "{A} changing the map to {V} with gamemode {V_2} in 10 seconds.",
	map_help = "Изменение текущей карты и режима игры.",

	map_restart = "{A}: перезагрузка сервера через 10 секунд.",
	map_restart_help = "Перезапуск текущей карты.",

	mapreset = "{A} сбросил карту.",
	mapreset_help = "Сбросить карту.",

	kick = "{A} кикнул {T} Причина: {V}.",
	kick_help = "Кикнуть игрока.",

	ban = "{A} заблокировал {T} на {V} ({V_2}).",
	ban_help = "Заблокировать игрока.",

	banid = "{A} заблокировал ${T} на {V} ({V_2}).",
	banid_help = "Заблокировать игрока через SteamID (SID).",

	-- ban message when admin name doesn't exists
	ban_message = [[


		Вас забанил: {S}

		Причина: {S_2}

		Вы будете разбанены: {S_3}]],

	-- ban message when admin name exists
	ban_message_2 = [[


		Вас забанил: {S} ({S_2})

		Причина: {S_3}

		Вы будете разбанены: {S_4}]],

	unban = "{A} разблокировал {T}.",
	unban_help = "Разблокируйте игрока, используя еге SteamID (SID).",

	noclip = "{A} переключил режим полета {T}.",
	noclip_help = "Переключить режим полёта.",

	cleardecals = "{A} очистил ragdolls и decals.",
	cleardecals_help = "Очистить регдолы всех игроков.",

	stopsound = "{A} остановил все звуки.",
	stopsound_help = "Остановить все звуки для всех игроков.",

	not_in_vehicle = "Вы не находитесь в транспортном средстве!",
	not_in_vehicle2 = "{S Blue} не находится в транспортном средстве!",
	exit_vehicle = "{A} выгнал {T} из транспортного средства.",
	exit_vehicle_help = "Заставить игрока выйти из транспортного средства.",

	time_your = "Вы отыграли {V}.",
	time_player = "{T} отыграл {V}.",
	time_help = "Проверьте время игрока",

	admin_help = "Активировать режим администратора.",
	unadmin_help = "Отключить режим администратора.",

	buddha = "{A} включил режим бессмертия {T}.",
	buddha_help = "Сделайте игрока бессмертным, когда его здоровье равно 1.",

	unbuddha = "{A} отключил режим бессмертия {T}.",
	unbuddha_help = "Отлючить режим будды.",

	give = "{A} выдал {T} {V}.",
	give_help = "Выдача игроку weapon/entity",

	-- DarkRP Commands
	arrest = "{A} арестовал {T} навсегда.",
	arrest2 = "{A} арестовал {T} на {V} секунд.",
	arrest_help = "Арестовать игрока.",

	unarrest = "{A} выпустил {T}.",
	unarrest_help = "Снять аррест с игрока.",

	setmoney = "{A} установил деньги {T} на {V}.",
	setmoney_help = "Установить деньги игроку.",

	addmoney = "{A} выдал {V} для {T}.",
	addmoney_help = "Добавить деньги игроку.",

	door_invalid = "недействительная дверь для продажи.",
	door_no_owner = "эта дверь никому не принадлежит.",

	selldoor = "{A} продал дверь/транспортное средство {T}.",
	selldoor_help = "Продать дверь/транспортное средство, на которое вы смотрите.",

	sellall = "{A} продал все двери/транспортные средства принадлежащие {T}.",
	sellall_help = "Продать все двери/транспортные средства, принадлежащие игроку.",

	s_jail_pos = "{A} установил новую позицию для тюрьмы.",
	setjailpos_help = "Сбрасывает все позиции в тюрьме и устанавливает новую в вашем местоположении.",

	a_jail_pos = "{A} добавил новую позицию для тюрьмы.",
	addjailpos_help = "Добавляет новую позицию в тюрьме в вашем местоположении.",

	setjob = "{A} установил {T} профессию {V}.",
	setjob_help = "Сменить профессию игрока",

	shipment = "{A} создал {V} ящик.",
	shipment_help = "Поставить ящик.",

	forcename = "{A} поменял имя {T} на {V}.",
	forcename_taken = "Имя уже занято. ({V})",
	forcename_help = "Смена имени игрока.",

	report_claimed = "{A} принял жалобу игрока {T}.",
	report_closed = "{A} закрыл жалобу игрока {T}.",
	report_aclosed = "Ваша жалоба закрыта.(время истекло)",

	rank_expired = "Срок действия группы {V} для {T} истек.",

	-- TTT Commands
	setslays = "{A} set amount of auto-slays for {T} to {V}.",
	setslays_help = "Set amount of rounds to auto-slay a player for.",

	setslays_slayed = "{T} got auto-slayed, slays left: {V}.",

	removeslays = "{A} removed auto-slays for {T}.",
	removeslays_help = "Remove auto-slays for a player."
}