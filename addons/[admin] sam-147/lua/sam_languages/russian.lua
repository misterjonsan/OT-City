return {
	You = "Вы",
	Yourself = "Себя",
	Themself = "Себе",

	cant_use_as_console = "Вы должны быть игроком для использования команды {S Red}!",
	no_permission = "У вас недостаточно прав для использования команды '{S Red}'!",

	cant_target_multi_players = "Вы не можете использовать эту команду на нескольких игроков!",
	invalid_id = "Неверный идентификатор ({S Red})!",
	cant_target_player = "Вы не можете использовать эту команду на {S Red}!",
	cant_target_self = "Вы не можете использовать команду {S Red} на себя!",
	player_id_not_found = "Игрок {S Red} не найден!",
	found_multi_players = "Найдено несколько игроков: {T}!",
	cant_find_target = "Невозможно найти игрока ({S Red})!",

	invalid = "Неверный {S} ({S_2 Red})",
	default_reason = "причина",

	menu_help = "Открывает админ меню.",

	-- Chat Commands
	pm_to = "[PM] {T}: {V}",
	pm_from = "[PM] {A}: {V}",
	pm_help = "Отправляет сообщение игроку.",

	to_admins = "[Админы] {A}: {V}",
	asay_help = "Отправляет сообщение администраторам.",

	mute = "{A} замутил {T} на {V}. Причина: {V_2}",
	mute_help = "Запрещает игроку отправлять сообщения.",

	unmute = "{A} размутил {T}.",
	unmute_help = "Разрешает игроку отправлять сообщения.",

	you_muted = "Вам запретили отправлять сообщения.",

	gag = "{A} загагал {T} на {V}. ({V_2})",
	gag_help = "Запрещает игроку использовать голосовой чат.",

	ungag = "{A} разгагал {T}.",
	ungag_help = "Разрешает игроку использовать голосовой чат",

	-- Fun Commands
	slap = "{A} ударил {T}.",
	slap_damage = "{A} ударил {T} с {V} уроном.",
	slap_help = "Позволяет ударить игрока.",

	slay = "{A} убил {T}.",
	slay_help = "Убивает игрока.",

	set_hp = "{A} выдал {T} жизни {V}.",
	hp_help = "Выдает жизни выбранному игроку.",

	set_armor = "{A} выдал {T} броню {V}.",
	armor_help = "Выдает броню выбранному игроку.",

	ignite = "{A} поджог {T} на {V}.",
	ignite_help = "Плджигает выбранного игрока.",

	unignite = "{A} потушил {T}.",
	unignite_help = "Тушит выбранного игрока.",

	god = "{A} включил бессмертие {T}.",
	god_help = "Включает бессмертие.",

	ungod = "{A} выключил бессмертие {T}.",
	ungod_help = "Выключает бессмертие.",

	freeze = "{A} заморозил {T}.",
	freeze_help = "Замораживает игрока.",

	unfreeze = "{A} разморозил {T}.",
	unfreeze_help = "Размораживает игрока.",

	cloak = "{A} выдал невидимость {T}.",
	cloak_help = "Выдает невидимость.",

	uncloak = "{A} забрал невидимость {T}.",
	uncloak_help = "Забирает невидимость.",

	jail = "{A} заджайлил {T} на {V}. Причина: {V_2}",
	jail_help = "Джайлит выбранного игрока.",

	unjail = "{A} разджайлил {T}.",
	unjail_help = "Разджайлит выбранного игрока.",

	strip = "{A} забрал оружие у {T}.",
	strip_help = "Забирает оружие у выбранного игрока.",

	respawn = "{A} возродил {T}.",
	respawn_help = "Возрождает выбранного игрока.",

	setmodel = "{A} изменил модель {T} на {V}.",
	setmodel_help = "Меняет модель игрока.",

	giveammo = "{A} выдал {T} {V} боеприпасов.",
	giveammo_help = "Выдает боеприпасы.",

	scale = "{A} изменил размер модели {T} на {V}.",
	scale_help = "Меняет размер модели.",

	freezeprops = "{A} заморозил все пропы.",
	freezeprops_help = "Замораживает все пропы на карте.",

	-- Teleport Commands
	dead = "Вы мертвы!",
	leave_car = "Сначала покиньте машину!",

	bring = "{A} телепортировал к себе {T}.",
	bring_help = "Телепортирует к себе игроков.",

	goto = "{A} телепортировался к {T}.",
	goto_help = "Телепортирует к игроку.",

	no_location = "Нет предыдущих позиций у {T}.",
	returned = "{A} вернул {T}.",
	return_help = "Возвращает игрока на позицию перед телепортом.",

	-- User Management Commands
	setrank = "{A} выдал {T} ранг {V}. Длительность: {V_2}",
	setrank_help = "Выдает ранг выбранному игроку.",
	setrankid_help = "Выдает ранг по steamid/steamid64.",

	addrank = "{A} создал ранг {V}.",
	addrank_help = "Создает ранг.",

	removerank = "{A} удалил ранг {V}.",
	removerank_help = "Удаляет ранг.",

	super_admin_access = "superadmin имеет доступ ко всему!",

	giveaccess = "{A} выдал доступ к {V} игроку {T}.",
	givepermission_help = "Выдает игроку доступ к командам.",

	takeaccess = "{A} забрал доступ к {V} у игрока {T}.",
	takepermission_help = "Забирает у игрока доступ к командам.",

	renamerank = "{A} переименновал ранг {T} на {V}.",
	renamerank_help = "Переименновывает игрока.",

	changeinherit = "{A} изменил унаследование прав для {T} у {V}.",
	changeinherit_help = "Меняет унаследование прав.",

	rank_immunity = "{A} изменил иммунитет ранга {T} на {V}.",
	changerankimmunity_help = "Меняет иммунитет ранга.",

	rank_ban_limit = "{A} изменил {T} макс. длительность бана на {V}.",
	changerankbanlimit_help = "Меняет длительность бана.",

	changeranklimit = "{A} изменил {V} лимит для {T} на {V_2}.",
	changeranklimit_help = "Меняет лимит рангам.",

	-- Utility Commands
	map_change = "{A} меняет карту на {V} через 10 секунд.",
	map_change2 = "{A} меняет карту на {V} с режимом {V_2} через 10 секунд.",
	map_help = "Меняет карту и режим.",

	map_restart = "{A}: рестарт сервера через 10 секунд.",
	map_restart_help = "Перезапускает карту.",

	mapcleanup = "{A} очистил карту.",
	mapcleanup_help = "Очищает карту.",

	kick = "{A} кикнул {T}. Причина: {V}",
	kick_help = "Кикает игрока.",

	ban = "{A} забанил {T} на {V}. Причина: {V_2}",
	ban_help = "Блокирует игроку доступ к серверу.",

	banid = "{A} забанил ${T} на {V}. Причина: {V_2}",
	banid_help = "Блокирует игроку доступ к серверу по steamid.",

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

	unban = "{A} разбанил {T}.",
	unban_help = "Разбанит игрока по steamid.",

	noclip = "{A} переключил полет {T}.",
	noclip_help = "Переключает полет выбранному игроку.",

	cleardecals = "{A} очистил карту от декалей и регдоллов.",
	cleardecals_help = "Очищает карту от декалей и регдоллов.",

	stopsound = "{A} остановил звуки.",
	stopsound_help = "Останавливает звуки у всех игроков.",

	not_in_vehicle = "Вы не находитесь в машине!",
	not_in_vehicle2 = "{S Blue} не находится в машине!",
	exit_vehicle = "{A} заставил {T} вылезти из машины.",
	exit_vehicle_help = "Заставляет игрока вылезти из машины.",

	time_your = "Ваше наигранное время: {V}.",
	time_player = "{T} наигранное время: {V}.",
	time_help = "Позволяет просмотреть наигранное время выбранного игрока.",

	admin_help = "Включает режим администратирования.",
	unadmin_help = "Выключает режим администратирования.",

	buddha = "{A} выдал бесконечные хп {T}.",
	buddha_help = "Бессмертие, не опускающее жизни игрока ниже 1.",

	unbuddha = "{A} забрал бесконечные хп {T}.",
	unbuddha_help = "Забирает бесконечные хп у игрока.",

	give = "{A} выдал {T} {V}.",
	give_help = "Выдает игроку оружие/ентити",

	-- DarkRP Commands
	arrest = "{A} арестовал {T} навсегда.",
	arrest2 = "{A} арестовал {T} на {V} сек.",
	arrest_help = "Арестовывает игрока.",

	unarrest = "{A} разарестовал {T}.",
	unarrest_help = "Разарестовывает игрока.",

	setmoney = "{A} установил {T} {V} денег.",
	setmoney_help = "Устанавливает игроку выбранное кол-во денег.",

	addmoney = "{A} добавил {V} {T} денег.",
	addmoney_help = "Добавляет деньги выбранному игроку.",

	door_invalid = "неверная дверь для продажи.",
	door_no_owner = "у этой двери нет владельцев.",

	selldoor = "{A} продал дверь {T}.",
	selldoor_help = "Продает дверь, на которую вы смотрите.",

	sellall = "{A} продал все двери {T}.",
	sellall_help = "Продает все двери выбранного игрока.",

	s_jail_pos = "{A} поставил новую джайл позицию.",
	setjailpos_help = "Удаляет все джайл позиции и ставит эту.",

	a_jail_pos = "{A} добавил новую джайл позицию.",
	addjailpos_help = "Добавляет новую джайл позицию, не затрагивает другие.",

	setjob = "{A} выдал {T} профессию {V}.",
	setjob_help = "Выдает профессию.",

	shipment = "{A} заспавнил {V} коробку.",
	shipment_help = "Спавнит коробку.",

	forcename = "{A} изменил ник {T} на {V}.",
	forcename_taken = "Имя '{V}' занято.",
	forcename_help = "Меняет ник выбранному игроку.",

	-- TTT Commands
	setslays = "{A} set amount of auto-slays for {T} to {V}.",
	setslays_help = "Set amount of rounds to auto-slay a player for.",

	setslays_slayed = "{T} got auto-slayed, slays left: {V}.",

	removeslays = "{A} removed auto-slays for {T}.",
	removeslays_help = "Remove auto-slays for a player."
}