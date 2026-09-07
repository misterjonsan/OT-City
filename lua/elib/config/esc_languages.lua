
--------------------
--# LOCALIZATION #--
--------------------
-- key MUST be an abbreviation like ru en de cz
-- some abbr-s: https://wiki.facepunch.com/gmod/Addon_Localization
-- __name__ - key for abbreviation translation. 

local langs = {
	["en"] = {
		__name__ = "English",
		__code__ = "US",

		tab_general = "General",
		tab_language = "Language",
		tab_settings = "Settings",
		tab_theme = "Theme",

		window_ValueEdit = "Edit value",

		phrase_ReturnDefault = "Reset",
		phrase_Save = "Save",

		phrase_Activate = "Activate",
		phrase_CustomSkin = "Custom",
		phrase_Themes = "Themes",
		phrase_Unsaved = "Unsaved",

		hint_CustomSkin = "Make your own skin. RMB to edit. Only for admins",

		button_Edit = "Edit",
		button_Confirm = "Confirm",
		button_Discard = "Discard",
		button_PrintToConsole = "Print to console",
		button_LoadOtherSkin = "Copy existing",

		phrase_AreYouSure = "Are you sure?",
		phrase_SureToReturn = "Return the default settings?",
		phrase_EnterValue = "Enter value",
		phrase_Search = "Search",
		phrase_Friend = "Friend",
		phrase_NoResults = "No results",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Save as default",
		phrase_BackGlobalDefault = "Remove default",
		phrase_AdminInfoButtons = "These buttons control the settings for all players. To change settings globally, you must first change these settings in your settings, save them, and then send them to the server with the appropriate button.",
		phrase_RecievedFromServer = "Settings have been received from the server",
		phrase_EmptySettings = "Settings is empty",
		phrase_restart_needed = "Changes will be applied after restart",
		phrase_WhoCanChange = "Who can change",
		phrase_NoOne = "No one",

		realm_Client = "Client",
		realm_Server = "Server",

		--Config
        s_debug_name = "Debug Mode",
        s_drawblur_name = "Draw Blur",
        s_animationspeed_name = "Animation speed",

		--timevalues
		char_hours = "h",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",

	},
	["ru"] = {
		__name__ = "Русский",
		__code__ = "RU",

		tab_general = "Главные",
		tab_language = "Язык",
		tab_settings = "Настройки",
		tab_theme = "Тема",

		window_ValueEdit = "Изменить значение",

		phrase_ReturnDefault = "Сбросить",
		phrase_Save = "Сохранить",

		phrase_Activate = "Активировать",
		phrase_CustomSkin = "Свой скин",
		phrase_Themes = "Темы",
		phrase_Unsaved = "Не сохранено",

		hint_CustomSkin = "Создай свой скин. ПКМ чтобы открыть меню. Только для администраторов.",

		button_Edit = "Редактировать",
		button_Confirm = "Применить",
		button_Discard = "Отмена",
		button_PrintToConsole = "Отправить в консоль",
		button_LoadOtherSkin = "Скопировать существующий",

		phrase_AreYouSure = "Вы уверены?",
		phrase_SureToReturn = "Вернуть начальные настройки?",
		phrase_EnterValue = "Введите значение",
		phrase_Search = "Поиск",
		phrase_Friend = "Друг",
		phrase_NoResults = "Нет результатов",
		phrase_Admin = "Администратор",
		phrase_SetGlobalDefault = "Загрузить текущие настройки как стандартные на сервер.\nТекущие настройки обязаны быть сохранены!\nДоступно только для администрации.",
		phrase_BackGlobalDefault = "Удалить текущие глобальные настройки.\nТолько для администрации.",
		phrase_AdminInfoButtons = "Эти кнопки управляют настройками для всех игроков. Для изменения настроек глобально, нужно сначала изменить эти настройки у себя и ОБЯЗАТЕЛЬНО нажать кнопку сохранить, а после отправить их на сервер соответствующей кнопкой.",
		phrase_RecievedFromServer = "Получены настройки с сервера",
		phrase_EmptySettings = "Настройки пусты",
		phrase_restart_needed = "Изменения будут применены после рестарта",
		phrase_WhoCanChange = "Могут изменять",
		phrase_NoOne = "Никто",

		realm_Client = "Клиент",
		realm_Server = "Сервер",

		--Config
        s_debug_name = "Режим отладки",
        s_drawblur_name = "Размытие фона",
        s_animationspeed_name = "Скорость анимации",

		--timevalues
		char_hours = "ч",
		char_minutes = "м",
		char_seconds = "с",
		char_milliseconds = "мс",
	},
	--translation by https://www.gmodstore.com/users/kbrpluma
	["de"] = {
		__name__ = "Deutsch",
		__code__ = "DE",
 
		tab_general = "Allgemein",
		tab_language = "Sprache",
		tab_settings = "Einstellungen",
		tab_theme = "Theme",
 
		window_ValueEdit = "Wert bearbeiten",
 
		phrase_ReturnDefault = "Standard zurückkehren",
		phrase_Save = "Speichern",
 
		phrase_Activate = "Aktivieren",
		phrase_CustomSkin = "Benutzerdefiniert",
		phrase_Themes = "Themes",
		phrase_Unsaved = "Ungespeichert",
 
		hint_CustomSkin = "Mache deinen eigenen Skin. RMT zum bearbeiten. Only for admins.",
 
		button_Edit = "Editieren",
		button_Confirm = "Bestätigen",
		button_Discard = "Verwerfen",
		button_PrintToConsole = "In die Konsole schreiben",
		button_LoadOtherSkin = "Vorhandenes kopieren",
 
		phrase_AreYouSure = "Bist du sicher?",
		phrase_SureToReturn = "Wiederherstellung der Standardeinstellungen?",
		phrase_EnterValue = "Wert eingeben",
		phrase_Search = "Suche",
		phrase_Friend = "Freund",
		phrase_NoResults = "Keine Ergebnisse",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Aktuelle Einstellungen als Standard auf diesem Server speichern.\nAktuelle Einstellungen müssen gespeichert werden!\nNur für Admins.",
		phrase_BackGlobalDefault = "Globale Standardeinstellungen entfernen.\nNur für Admins.",
		phrase_AdminInfoButtons = "Diese Buttons kontrollieren die Einstellungen für jeden Spieler. Um die Einstellungen global zu ändern, musst du die Einstellungen erst bei dir speichern und dann mit dem Button zum Server senden.",
		phrase_RecievedFromServer = "Einstellungen vom Server erhalten",
		phrase_EmptySettings = "Einstellungen sind leer",
		phrase_restart_needed = "Änderungen werden nach dem Neustart angewendet",
		phrase_WhoCanChange = "Wer kann es ändern",
		phrase_NoOne = "Niemand",
 
		realm_Client = "Client",
		realm_Server = "Server",
 
		--Config
        s_debug_name = "Debug Mode",
        s_drawblur_name = "Unschärfe anzeigen",
        s_animationspeed_name = "Animationsgeschwindigkeit",
 
		--timevalues
		char_hours = "s",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",
 
	},
	--translation by https://www.gmodstore.com/users/76561198363331907
	["zh-cn"] = {
		__name__ = "简体中文",
		__code__ = "CN",

		tab_general = "一般",
		tab_language = "语言",
		tab_settings = "设置",
		tab_theme = "主题",

		window_ValueEdit = "编辑值",

		phrase_ReturnDefault = "恢复默认",
		phrase_Save = "保存",

		phrase_Activate = "激活",
		phrase_CustomSkin = "自定义",
		phrase_Themes = "主题",
		phrase_Unsaved = "未保存",

		hint_CustomSkin = "制作你自己的皮肤. 右键编辑. Only for admins.",

		button_Edit = "编辑",
		button_Confirm = "确定",
		button_Discard = "放弃",
		button_PrintToConsole = "输出至控制台",
		button_LoadOtherSkin = "复制已有",

		phrase_AreYouSure = "你确定吗?",
		phrase_SureToReturn = "恢复默认设置?",
		phrase_EnterValue = "输入值",
		phrase_Search = "搜索",
		phrase_Friend = "好友",
		phrase_NoResults = "无结果",
		phrase_Admin = "管理员",
		phrase_SetGlobalDefault = "将当前设置保存为该服务器的默认值.\n必须保存当前设置!\n仅管理员.",
		phrase_BackGlobalDefault = "移除全局默认设置.\n仅管理员.",
		phrase_AdminInfoButtons = "这些按钮控制所有玩家的设置. 要改变全局设置, 你必须首先在你的设置中改变这些设置, 保存它们, 然后用对应的按钮将它们发送到服务器.",
		phrase_RecievedFromServer = "已收到来自服务器的设置",
		phrase_EmptySettings = "设置为空",
		phrase_restart_needed = "将在重新启动后应用更改",
		phrase_WhoCanChange = "谁能修改",
		phrase_NoOne = "无人",

		realm_Client = "客户端",
		realm_Server = "服务器",

		--Config
        s_debug_name = "调试模式",
        s_drawblur_name = "绘制 Blur",
        s_animationspeed_name = "动画速度",

		--timevalues
		char_hours = "时",
		char_minutes = "分",
		char_seconds = "秒",
		char_milliseconds = "毫秒",
	},
	--translation by https://www.gmodstore.com/users/76561198093244860
	["dk"] = {
		__name__ = "Danish",
		__code__ = "DK",

		tab_general = "General",
		tab_language = "Sprog",
		tab_settings = "Indstillinger",
		tab_theme = "Tema",

		window_ValueEdit = "Rediger værdi",

		phrase_ReturnDefault = "Returner Standard",
		phrase_Save = "Gem",

		phrase_Activate = "Aktiver",
		phrase_CustomSkin = "Custom",
		phrase_Themes = "Temaer",
		phrase_Unsaved = "Ikke gemt",

		hint_CustomSkin = "Lav dit egent skin. RMB for at redigere. Only for admins.",

		button_Edit = "Rediger",
		button_Confirm = "Bekræft",
		button_Discard = "Fortryd", 
		button_PrintToConsole = "Udskriv til konsol",
		button_LoadOtherSkin = "Kopier eksisterende",

		phrase_AreYouSure = "Er du sikker?",
		phrase_SureToReturn = "Returner standardindstillinger?",
		phrase_EnterValue = "Indsæt værdi",
		phrase_Search = "Søg",
		phrase_Friend = "Venner",
		phrase_NoResults = "Ingen resultater",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Gem aktuelle indstillinger som standard på denne server.\nAktuelle indstillinger skal gemmes!\nKun for administratorer.",
		phrase_BackGlobalDefault = "Fjern globale standardindstillinger.\nKun for administratorer.",
		phrase_AdminInfoButtons = "Disse knapper styrer indstillingerne for alle spillere. For at ændre indstillinger globalt skal du først ændre disse indstillinger i dine indstillinger, gemme dem og derefter sende dem til serveren med den relevante knap.",
		phrase_RecievedFromServer = "Indstillingerne er modtaget fra serveren",
		phrase_EmptySettings = "Indstillingerne er tomme",
		phrase_restart_needed = "Ændringer vil blive anvendt efter genstart",
		phrase_WhoCanChange = "Hvem kan ændre",
		phrase_NoOne = "Ingen",

		realm_Client = "Client",
		realm_Server = "Server",

		--Config
        s_debug_name = "Fejlretningstilstand",
        s_drawblur_name = "Tegn sløring",
        s_animationspeed_name = "Animations Hastighed",

		--timevalues
		char_hours = "t",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",
	},
	--translation by https://www.gmodstore.com/users/76561198198168751
	["fr"] = {
		__name__ = "French",
		__code__ = "FR",

		tab_general = "General",
		tab_language = "Langue",
		tab_settings = "Paramètres",
		tab_theme = "Theme",

		window_ValueEdit = "Modifier la valeur",

		phrase_ReturnDefault = "Retour par défaut",
		phrase_Save = "Sauvegarder",

		phrase_Activate = "Activer",
		phrase_CustomSkin = "Modifier",
		phrase_Themes = "Themes",
		phrase_Unsaved = "Non enregistré",

		hint_CustomSkin = "Faites votre propre skin. Clique droit pour éditer. Only for admins.",

		button_Edit = "Modifier",
		button_Confirm = "Confirmer",
		button_Discard = "Supprimer",
		button_PrintToConsole = "Copier dans la console",
		button_LoadOtherSkin = "Copie existant",

		phrase_AreYouSure = "Es-tu sûr?",
		phrase_SureToReturn = "Rétablir les paramètres par défaut ?",
		phrase_EnterValue = "Entrez la valeur",
		phrase_Search = "Rechercher",
		phrase_Friend = "Ami(e)(s)",
		phrase_NoResults = "Aucun résultat",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Enregistrer les paramètres actuels par défaut sur ce serveur.\nLes paramètres actuels doivent être enregistrés !\nReservé pour les administrateurs.",
		phrase_BackGlobalDefault = "Supprimer les paramètres globaux par défaut.\nReservé pour les administrateurs.",
		phrase_AdminInfoButtons = "Ces boutons contrôlent les paramètres de tous les joueurs. Pour modifier les paramètres globalement, vous devez d'abord modifier ces paramètres dans vos paramètres, les enregistrer, puis les envoyer au serveur avec le bouton approprié.",
		phrase_RecievedFromServer = "Les paramètres ont été reçus par le serveur",
		phrase_EmptySettings = "Les paramètres sont vides",
		phrase_restart_needed = "Les modifications seront appliquées après le redémarrage du serveur",
		phrase_WhoCanChange = "Qui peut changer",
		phrase_NoOne = "Personne",

		realm_Client = "Client",
		realm_Server = "Serveur",

		--Config
        s_debug_name = "Debug Mode",
        s_drawblur_name = "Dessiner le flou",
        s_animationspeed_name = "La vitesse d'animation",

		--timevalues
		char_hours = "h",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",

	},
	--translation by https://www.gmodstore.com/users/76561199213364106
	["pl"] = {
		__name__ = "Polish",
		__code__ = "PL",

		tab_general = "Główne",
		tab_language = "Języki",
		tab_settings = "Ustawienia",
		tab_theme = "Motyw",

		window_ValueEdit = "Edytuj Wartość",

		phrase_ReturnDefault = "Powrót do ustawień podstawowych",
		phrase_Save = "Zapisz",

		phrase_Activate = "Aktywuj",
		phrase_CustomSkin = "Niestandardowe",
		phrase_Themes = "Motywy",
		phrase_Unsaved = "Nie zapisane",

		hint_CustomSkin = "Stwórz własną skórkę. PPM do edycji. Only for admins.",

		button_Edit = "Edytuj",
		button_Confirm = "Potwierdź",
		button_Discard = "Odrzuć",
		button_PrintToConsole = "Wydrukuj do konsoli",
		button_LoadOtherSkin = "Załaduj skórkę",

		phrase_AreYouSure = "Jesteś pewien?",
		phrase_SureToReturn = "Powrócić do podstawowych ustawień?",
		phrase_EnterValue = "Wprowadż wartość",
		phrase_Search = "Szukaj",
		phrase_Friend = "Przyjaciel",
		phrase_NoResults = "Brak wyników",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Zapisz bieżące ustawienia jako domyślne na tym serwerze.\nBieżące ustawienia muszą zostać zapisane!\nTylko dla administracji.",
		phrase_BackGlobalDefault = "Usuń globalne ustawienia domyślne.\nTylko dla administracji.",
		phrase_AdminInfoButtons = "Te przyciski sterują ustawieniami dla wszystkich graczy. Aby zmienić ustawienia globalnie, należy najpierw zmienić te ustawienia w swoich ustawieniach, zapisać je, a następnie za pomocą odpowiedniego przycisku przesłać na serwer.",
		phrase_RecievedFromServer = "Ustawienia zostały odebrane z serwera.",
		phrase_EmptySettings = "Ustawienia są puste.",
		phrase_restart_needed = "Zmiany zostaną aktywowane po restarcie serwera!",
		phrase_WhoCanChange = "Kto może zmienić",
		phrase_NoOne = "Nikt inny",

		realm_Client = "Klient",
		realm_Server = "Serwer",

		--Config
        s_debug_name = "Tryb debugowania",
        s_drawblur_name = "Stwórz rozmycie",
        s_animationspeed_name = "Prędkość animacji",

		--timevalues
		char_hours = "h",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",
	},
	--translation by https://www.gmodstore.com/users/76561199213364106
	["cz"] = {
		__name__ = "Czech",
		__code__ = "CZ",

		tab_general = "Hlavní",
		tab_language = "Jazyky",
		tab_settings = "Nastavení",
		tab_theme = "Téma",

		window_ValueEdit = "Upravit hodnotu",

		phrase_ReturnDefault = "Zpět k základnímu nastavení",
		phrase_Save = "Zapsat",

		phrase_Activate = "Aktivovat",
		phrase_CustomSkin = "Nestandardní",
		phrase_Themes = "Témata",
		phrase_Unsaved = "Neuloženo",

		hint_CustomSkin = "Vytvořte si vlastní skin. PPM k úpravě. Only for admins.",

		button_Edit = "Upravit",
		button_Confirm = "Potvrdit",
		button_Discard = "Odmítnout",
		button_PrintToConsole = "Tisk do konzole",
		button_LoadOtherSkin = "Naložte kůži",

		phrase_AreYouSure = "Jsi si jistá?",
		phrase_SureToReturn = "Vrátit se k základnímu nastavení?",
		phrase_EnterValue = "Zadejte hodnotu",
		phrase_Search = "Vyhledávání",
		phrase_Friend = "Příteli",
		phrase_NoResults = "Žádné výsledky",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Uložte aktuální nastavení jako výchozí na tomto serveru.\nAktuální nastavení musí být uloženo!\nPouze pro administraci.",
		phrase_BackGlobalDefault = "Odebrat globální výchozí hodnoty.\nPouze pro administraci.",
		phrase_AdminInfoButtons = "Tato tlačítka ovládají nastavení pro všechny hráče. Chcete-li změnit nastavení globálně, musíte nejprve tato nastavení změnit ve svém nastavení, uložit je a poté je nahrát na server pomocí příslušného tlačítka.",
		phrase_RecievedFromServer = "Nastavení byla přijata ze serveru.",
		phrase_EmptySettings = "Nastavení jsou prázdná.",
		phrase_restart_needed = "Změny budou aktivovány po restartu serveru!",
		phrase_WhoCanChange = "Kdo může změnit",
		phrase_NoOne = "Nikdo jiný",

		realm_Client = "Klient",
		realm_Server = "Server",

		--Config
        s_debug_name = "Debugovací mód",
        s_drawblur_name = "Vytvořte rozostření",
        s_animationspeed_name = "Rychlost animace",

		--timevalues
		char_hours = "h",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",

	},
	--translation by https://www.gmodstore.com/users/Goran
	["es"] = {
		__name__ = "Spanish",
		__code__ = "ES",

		tab_general = "General",
		tab_language = "Idioma",
		tab_settings = "Ajustes",
		tab_theme = "Tema",

		window_ValueEdit = "Editar valor",

		phrase_ReturnDefault = "Config. por Defecto",
		phrase_Save = "Guardar",

		phrase_Activate = "Activar",
		phrase_CustomSkin = "Personalizado",
		phrase_Themes = "Temas",
		phrase_Unsaved = "No guardado",

		hint_CustomSkin = "Crea tu propio aspecto. Click derecho para editar. Only for admins.",

		button_Edit = "Editar",
		button_Confirm = "Confirmar",
		button_Discard = "Descartar",
		button_PrintToConsole = "Imprimir en consola",
		button_LoadOtherSkin = "Copiar existente",

		phrase_AreYouSure = "¿Seguro?",
		phrase_SureToReturn = "¿Regresar a valores por defecto?",
		phrase_EnterValue = "Ingresar valor",
		phrase_Search = "Buscar",
		phrase_Friend = "Amigo",
		phrase_NoResults = "Sin resultados",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Guardar los ajustes actuales como por defecto.\n¡Los ajustes actuales deben ser guardados!\nSólo para admins.",
		phrase_BackGlobalDefault = "Remover ajustes globales gugardados\nSólo para admins.",
		phrase_AdminInfoButtons = "Estos botones controlan los ajustes para todos los jugadores. Para cambiar ajustes globalmente, primero debes modificar estos ajustes en tus propios ajustes, guardarlos, y luego enviarlos al servidor con el botón correspondiente.",
		phrase_RecievedFromServer = "Ajustes recibidos del servidor",
		phrase_EmptySettings = "Los ajustes están vacíos",
		phrase_restart_needed = "Los cambios serán aplicados luego del reinicio",
		phrase_WhoCanChange = "Quién puede modificar",
		phrase_NoOne = "Nadie",

		realm_Client = "Cliente",
		realm_Server = "Servidor",

		--Config
        s_debug_name = "Modo Debug",
        s_drawblur_name = "Dibujar difuminado",
        s_animationspeed_name = "Velocidad de la animación",

		--timevalues
		char_hours = "h",
		char_minutes = "m",
		char_seconds = "s",
		char_milliseconds = "ms",
	},
	--translation by https://www.gmodstore.com/users/illusion
	["tr"] = {
		__name__ = "Türkçe",
		__code__ = "TR",

		tab_general = "Genel",
		tab_language = "Dil",
		tab_settings = "Ayarlar",
		tab_theme = "Tema",

		window_ValueEdit = "Düzenle",

		phrase_ReturnDefault = "Varsayılan",
		phrase_Save = "Kaydet",

		phrase_Activate = "Etkinleştir",
		phrase_CustomSkin = "Özel",
		phrase_Themes = "Temalar",
		phrase_Unsaved = "Kaydedilmemiş",

		hint_CustomSkin = "Kendi temanızı yapın. Düzenlemek için SAĞTIK. Only for admins.",

		button_Edit = "Düzenle",
		button_Confirm = "Onayla",
		button_Discard = "Çıkar",
		button_PrintToConsole = "Konsola yazdırma",
		button_LoadOtherSkin = "Var olanı kopyala",

		phrase_AreYouSure = "Emin misiniz?",
		phrase_SureToReturn = "Varsayılan ayarları döndürüyorsunuz?",
		phrase_EnterValue = "Değer girin",
		phrase_Search = "Ara",
		phrase_Friend = "Arkadaş",
		phrase_NoResults = "Sonuç yok",
		phrase_Admin = "Admin",
		phrase_SetGlobalDefault = "Geçerli ayarları bu sunucuda varsayılan olarak kaydet.\nGeçerli ayarlar kaydedilmelidir!\nYalnızca yöneticiler için.",
		phrase_BackGlobalDefault = "Genel varsayılan ayarları kaldırın.\nYalnızca yöneticiler için.",
		phrase_AdminInfoButtons = "Bu düğmeler tüm oyuncuların ayarlarını kontrol eder. Ayarları genel olarak değiştirmek için, önce ayarlarınızdan bu ayarları değiştirmeniz, kaydetmeniz ve ardından uygun düğmeyle sunucuya göndermeniz gerekir.",
		phrase_RecievedFromServer = "Ayarlar sunucudan alındı",
		phrase_EmptySettings = "Ayarlar boş",
		phrase_restart_needed = "Değişiklikler yeniden başlatıldıktan sonra uygulanacaktır",
		phrase_WhoCanChange = "Kim değiştirebilir",
		phrase_NoOne = "Kimse",

		realm_Client = "Client",
		realm_Server = "Server",

		--Config
        s_debug_name = "Debug Mod",
        s_drawblur_name = "Blur oluştur",
        s_animationspeed_name = "Animasyon hızı",

		--timevalues
		char_hours = "sa",
		char_minutes = "dk",
		char_seconds = "sn",
		char_milliseconds = "ms",
	},
	--translation by https://www.gmodstore.com/users/metzy
    ["pt-br"] = {
        __name__ = "Português",
        __code__ = "BR",
 
        tab_general = "Geral",
        tab_language = "Idioma",
        tab_settings = "Configurações",
        tab_theme = "Tema",
 
        window_ValueEdit = "Editar valor",
 
        phrase_ReturnDefault = "Restaurar Padrão",
        phrase_Save = "Salvar",
 
        phrase_Activate = "Ativar",
        phrase_CustomSkin = "Personalizado",
        phrase_Themes = "Temas",
        phrase_Unsaved = "Não salvo",
 
        hint_CustomSkin = "Crie sua própria skin. Botão direito para editar. Somente para admins",
 
        button_Edit = "Editar",
        button_Confirm = "Confirmar",
        button_Discard = "Descartar",
        button_PrintToConsole = "Imprimir no console",
        button_LoadOtherSkin = "Copiar existente",
 
        phrase_AreYouSure = "Tem certeza?",
        phrase_SureToReturn = "Deseja restaurar as configurações padrão?",
        phrase_EnterValue = "Digite um valor",
        phrase_Search = "Pesquisar",
        phrase_Friend = "Amigo",
        phrase_NoResults = "Nenhum resultado",
        phrase_Admin = "Admin",
        phrase_SetGlobalDefault = "Salvar configurações atuais como padrão neste servidor.\nAs configurações atuais devem estar salvas!\nSomente para admins.",
        phrase_BackGlobalDefault = "Remover as configurações padrão globais.\nSomente para admins.",
        phrase_AdminInfoButtons = "Esses botões controlam as configurações de todos os jogadores. Para alterar as configurações globalmente, primeiro altere no seu próprio menu, salve e depois envie para o servidor com o botão apropriado.",
        phrase_RecievedFromServer = "Configurações recebidas do servidor",
        phrase_EmptySettings = "Configurações estão vazias",
        phrase_restart_needed = "As alterações serão aplicadas após reiniciar",
        phrase_WhoCanChange = "Quem pode alterar",
        phrase_NoOne = "Ninguém",
 
        realm_Client = "Cliente",
        realm_Server = "Servidor",
 
        --Config
        s_debug_name = "Modo Debug",
        s_drawblur_name = "Desenhar Desfoque",
        s_animationspeed_name = "Velocidade da Animação",
 
        --timevalues
        char_hours = "h",
        char_minutes = "m",
        char_seconds = "s",
        char_milliseconds = "ms",
    },
}

esclib.addon:RegisterLanguages(langs)

-- if GetConVar("gmod_language") not in languages table, sets this language
esclib.addon:SetDefaultLanguage("en")