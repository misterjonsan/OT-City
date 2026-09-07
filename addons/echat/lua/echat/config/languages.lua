local langs = {
	---------------
	--# ENGLISH #--
	---------------
	["en"] = {
		__name__ = "English", --name in game
		__code__ = "US", --Language code: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

		chat_mode_normal = "Say",
		chat_mode_team = "Team",

		type_something = "Type something...",
		send = "Send",
		settings = "Settings",
		emoji = "Emoji",
		copied_to_clipboard = "Text copied to clipboard!",
		sizing_mode = "Editing size",
		goto_end = "Go to end",
		copy = "Copy",

		--parser related
		rgb_hint = "RGB color 3 or 4 number(alpha)",
		rainbow_hint = "Rainbow effect",
		separator_hint = "Separation line. No arguments",
		clr_hint = "Color from pallete",
		shaking_hint = "Start / Stop shaking effect. Param: [0(none),1] - Shake intensivity",
		font_hint = "Use specific font",

		--settings related
		s_tab_general = "General",
		s_tab_location = "Location",
		s_tab_parser_examples = "Parser examples",
		s_chat_spacey_name = "Message gap",
		s_chat_spacey_desc = "Distance between chat messages",
		s_font_size_name = "Font size", --font size
		s_msg_time_name = "Message time",
		s_msg_time_desc = "Message time on screen in seconds",
		s_max_lines_name = "Maximum lines",
		s_max_lines_desc = "Maximum lines visible in chat",
		s_posx_name = "Position X",
		s_posy_name = "Position Y",
		s_sizew_name = "Width",
		s_sizeh_name = "Height",
		s_xywh_mod_name = "This setting is automatically saved when you change the chat window",
		s_autocomplete_count_name = "Autocomplete hints",
		s_autocomplete_count_desc = "Autocomplete hints count when you typing something",
		s_base_font_size_name = "Font size",
		s_base_font_size_desc = "Base font size (screen dependent)",
		s_clean_chat_name = "Clean input on close",
		s_clean_chat_desc = "Clean the input when closing chat",
		s_ambilight_name = "Ambilight",
		s_ambilight_clr1_name = "Ambilight color 1",
		s_ambilight_clr2_name = "Ambilight color 2",
		s_chat_name_name = "Chat name",
	},

	---------------
	--# RUSSIAN #--
	---------------
	["ru"] = {
		__name__ = "Русский", --name in game
		__code__ = "RU", --Language code: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

		chat_mode_normal = "Сказать",
		chat_mode_team = "Локальный",

		type_something = "Напишите что-то...",
		send = "Отправить",
		settings = "Настройки",
		emoji = "Эмодзи",
		copied_to_clipboard = "Текст скопирован в буфер обмена!",
		sizing_mode = "Редактирование размера ",
		goto_end = "К концу",
		copy = "Скопировать",

		--parser related
		rgb_hint = "RGB цвет 3 или 4 числа(альфа канал)",
		rainbow_hint = "Эффект радуги. Прерывается любым новым цветом",
		separator_hint = "Линия разделения. Без аргументов",
		clr_hint = "Цвет из палитры",
		shaking_hint = "Начать / остановить эффект тряски. Параметр: [0(none),1] - сила",
		font_hint = "Использовать специфический шрифт",

		--settings related
		s_tab_general = "Основа",
		s_tab_location = "Положение",
		s_tab_parser_examples = "Примеры парсера",
		s_chat_spacey_name = "Расстояние между сообщениями",
		s_chat_spacey_desc = "Дистанция между сообщениями в чате",
		s_font_size_name = "Размер шрифта", --font size
		s_msg_time_name = "Время сообщения",
		s_msg_time_desc = "Время сообщения на экране в секундах",
		s_max_lines_name = "Максимум линий",
		s_max_lines_desc = "Максимум линий, которые видны в чате",
		s_posx_name = "Позиция X",
		s_posy_name = "Позиция Y",
		s_sizew_name = "Ширина",
		s_sizeh_name = "Высота",
		s_xywh_mod_name = "Эта настройка автоматически сохраняется когда вы изменяете окно чата",
		s_autocomplete_count_name = "Количество подсказок",
		s_autocomplete_count_desc = "Количество подсказок при наборе текста в окне чата",
		s_base_font_size_name = "Размер шрифта",
		s_base_font_size_desc = "Базовый размер шрифта (зависит от экрана)",
		s_clean_chat_name = "Очистить ввод",
		s_clean_chat_desc = "Очистить ввод при закрытии",
		s_ambilight_name = "Подсветка",
		s_ambilight_clr1_name = "Цвет подсветки 1",
		s_ambilight_clr2_name = "Цвет подсветки 2",
		s_chat_name_name = "Имя чата",
	},

	---------------
	--# SPANISH #--
	---------------
	--by https://www.gmodstore.com/users/Goran
	["es"] = {
		__name__ = "Español",--name in game
		__code__ = "ES", --Language code: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

		chat_mode_normal = "Decir",
		chat_mode_team = "Equipo",

		type_something = "Escribe algo...",
		send = "Enviar",
		settings = "Ajustes",
		emoji = "Emoji",
		copied_to_clipboard = "¡Texto copiado al portapapeles!",
		sizing_mode = "Editar tamaño",
		goto_end = "Ir al final",
		copy = "Copiar",

		--parser related
		rgb_hint = "Color RGB. Admite 3 o 4 números (4 = alpha)",
		rainbow_hint = "Efecto arcoíris",
		separator_hint = "Línea de separación. Sin argumentos",
		clr_hint = "Paleta de colores",
		shaking_hint = "Iniciar / Detener efecto de temblor. Parám.: [0(nada),1] - Intensidad del temblor",
		font_hint = "Usar una fuente específica",

		--settings related
		s_tab_general = "General",
		s_tab_location = "Ubicación",
		s_tab_parser_examples = "Ejemplos de analizador",
		s_chat_spacey_name = "Espacio de los mensajes",
		s_chat_spacey_desc = "Distancia entre los mensajes de chat",
		s_font_size_name = "Tamaño de la fuente", --font size
		s_msg_time_name = "Duración del mensaje",
		s_msg_time_desc = "Tiempo del mensaje en pantalla en segundos",
		s_max_lines_name = "Líneas máximas",
		s_max_lines_desc = "Líneas máximas visibles",
		s_posx_name = "Posición en eje X",
		s_posy_name = "Posición en eje Y",
		s_sizew_name = "Largo",
		s_sizeh_name = "Alto",
		s_xywh_mod_name = "Este ajuste se guarda automáticamente cuando modificas la ventana de chat",
		s_autocomplete_count_name = "Pistas de autocompletado",
		s_autocomplete_count_desc = "Autocompleta los comandos mientras se escribe",
		s_base_font_size_name = "Tamaño de la fuente",
		s_base_font_size_desc = "Tamaño de la fuente base (depende de la resolución)",
		s_clean_chat_name = "Limpiar la entrada",
		s_clean_chat_desc = "Limpiar la entrada al cerrar",
		s_ambilight_name = "Subrayado",
		s_ambilight_clr1_name = "Color de subrayado 1",
		s_ambilight_clr2_name = "Color de subrayado 2",
		s_chat_name_name = "Nombre del chat",
	},


	--------------
	--# FRENCH #--
	--------------
	-- by https://www.gmodstore.com/users/76561198273468522
	["fr"] = {
		__name__ = "French",--name in game
		__code__ = "FR", --Language code: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

		chat_mode_normal = "Parler",
		chat_mode_team = "Equipe",

		type_something = "Ecrire quelque chose...",
		send = "Envoyer",
		settings = "Paramètres",
		emoji = "Emoji",
		copied_to_clipboard = "Texte copié dans le presse-papier !",
		sizing_mode = "Taille d'édition",
		goto_end = "Aller jusqu'au bout",
		copy = "Copier",

		--parser related
		rgb_hint = "Couleur RBG 3 ou 4 chiffres (alpha)",
		rainbow_hint = "Effet arc-en-ciel",
		separator_hint = "Ligne de séparation",
		clr_hint = "Couleur depuis la palette",
		shaking_hint = "Commencer / arrêter l'effet de secousse. Param: [0(none),1] - Intensité de la secousse",
		font_hint = "Utiliser une police spécifique",

		--settings related
		s_tab_general = "Général",
		s_tab_location = "Emplacement",
		s_tab_parser_examples = "Exemple d'analyse",
		s_chat_spacey_name = "Ecart de message",
		s_chat_spacey_desc = "Distance entre les messages dans le chat",
		s_font_size_name = "Taille de la police", --font size
		s_msg_time_name = "Durée du messages",
		s_msg_time_desc = "Durée du message à l'écran en secondes",
		s_max_lines_name = "Lignes maximum",
		s_max_lines_desc = "Maximum de lignes visibles dans le chat",
		s_posx_name = "Position X",
		s_posy_name = "Position Y",
		s_sizew_name = "Largeur",
		s_sizeh_name = "Hauteur",
		s_xywh_mod_name = "Ce paramètre est automatiquement enregistré lorsque vous modifiez la fenêtre de discussion",
		s_autocomplete_count_name = "Compteur du correcteur semi-automatique ",
		s_autocomplete_count_desc = "Compteur du correcteur semi-automatique pendant que vous tapez quelque chose",
		s_base_font_size_name = "Taille de la police",
		s_base_font_size_desc = "Taille de police de base (en fonction de l'écran)",
		s_clean_chat_name = "Nettoyez l'entrée lors",
		s_clean_chat_desc = "Nettoyez l'entrée lors de la fermeture",
		s_ambilight_name = "Sous-lumière",
		s_ambilight_clr1_name = "Couleur de sous-lumière 1",
		s_ambilight_clr2_name = "Couleur de sous-lumière 2",
		s_chat_name_name = "Nom du chat",
	},

	---------------
	--# DEUTSCH #--
	---------------
	--by https://www.gmodstore.com/users/76561198801156110
	["de"] = {
		__name__ = "Deutsch",--Name im Spiel
		__code__ = "DE", --Sprachcode: https://de.wikipedia.org/wiki/ISO_3166-1_alpha-2

		chat_mode_normal = "Sprechen",
		chat_mode_team = "Team",

		type_something = "Etwas schreiben...",
		send = "Senden",
		settings = "Einstellungen",
		emoji = "Emoji",
		copied_to_clipboard = "Text in die Zwischenablage kopiert!",
		sizing_mode = "Bearbeitungsgröße",
		goto_end = "Zum Ende gehen",
		copy = "Kopieren",

		--Parser-bezogen
		rgb_hint = "RGB-Farbe mit 3 oder 4 Ziffern (Alpha)",
		rainbow_hint = "Regenbogeneffekt",
		separator_hint = "Trennlinie",
		clr_hint = "Farbe aus der Palette",
		shaking_hint = "Starten/Stoppen des Schüttel-Effekts. Parameter: [0(keiner), 1] - Intensität des Schüttelns",
		font_hint = "Bestimmte Schriftart verwenden",

		--Einstellungsbezogen
		s_tab_general = "Allgemein",
		s_tab_location = "Ort",
		s_tab_parser_examples = "Parser-Beispiele",
		s_chat_spacey_name = "Nachrichtenabstand",
		s_chat_spacey_desc = "Abstand zwischen den Nachrichten im Chat",
		s_font_size_name = "Schriftgröße",
		s_msg_time_name = "Nachrichtendauer",
		s_msg_time_desc = "Dauer der Nachricht auf dem Bildschirm in Sekunden",
		s_max_lines_name = "Maximale Zeilen",
		s_max_lines_desc = "Maximale sichtbare Zeilen im Chat",
		s_posx_name = "Position X",
		s_posy_name = "Position Y",
		s_sizew_name = "Breite",
		s_sizeh_name = "Höhe",
		s_xywh_mod_name = "Diese Einstellung wird automatisch gespeichert, wenn Sie das Chat-Fenster ändern",
		s_autocomplete_count_name = "Semi-automatischer Autokorrektur-Zähler",
		s_autocomplete_count_desc = "Zähler für die semi-automatische Autokorrektur während des Schreibens",
		s_base_font_size_name = "Basis-Schriftgröße",
		s_base_font_size_desc = "Grundlegende Schriftgröße (abhängig vom Bildschirm)",
		s_clean_chat_name = "Reinigen Sie den Eingang",
		s_clean_chat_desc = "Reinigen Sie den Eingang beim Schließen",
		s_ambilight_name = "Unterstreichung",
		s_ambilight_clr1_name = "Basis-Schriftgröße",
		s_ambilight_clr2_name = "Basis-Schriftgröße",
		s_chat_name_name = "Basis-Schriftgröße",
	},

	--------------
	--# POLISH #--
	--------------
	-- by https://www.gmodstore.com/users/76561198260331846
	["pl"] = {
		__name__ = "Polish",
		__code__ = "PL",

		chat_mode_normal = "Globalny",
		chat_mode_team = "Drużyna",

		type_something = "Napisz coś...",
		send = "Wyślij",
		settings = "Ustawienia",
		emoji = "Emotki",
		copied_to_clipboard = "Tekst skopiowany do schowka!",
		sizing_mode = "Edycja rozmiarów",
		goto_end = "Idź do końca",
		copy = "Skopiuj",

		--parser related
		rgb_hint = "Kolor RGB 3 lub 4 wartości(alpha)",
		rainbow_hint = "Efekt tęczy",
		separator_hint = "Separator. Brak argumentów!",
		clr_hint = "Kolor z palety",
		shaking_hint = "Rozpocznij / Zatrzymaj efekt wstrząsów. Parametry: [0(none),1] - Intensywność wstrząsów",
		font_hint = "Użyj konkretnej czcionki",

		--settings related
		s_tab_general = "Ogólne",
		s_tab_location = "Lokalizacja",
		s_tab_parser_examples = "Przykłady parsera",
		s_chat_spacey_name = "Odstęp wiadomości",
		s_chat_spacey_desc = "Dystans między wiadomościami czatu",
		s_font_size_name = "Rozmiar czcionki", --font size
		s_msg_time_name = "Czas wiadomości",
		s_msg_time_desc = "Czas wiadomości na ekranie w sekundach",
		s_max_lines_name = "Maksymalna liczba linii",
		s_max_lines_desc = "Maksymalna ilość linii na czacie",
		s_posx_name = "Pozycja X",
		s_posy_name = "Pozycja Y",
		s_sizew_name = "Szerokość",
		s_sizeh_name = "Wysokość",
		s_xywh_mod_name = "To ustawienie jest automatycznie zapisywane po zmianie okna czatu",
		s_autocomplete_count_name = "Podpowiedzi autouzupełnienia",
		s_autocomplete_count_desc = "Liczba podpowiedzi autouzupełnienia, gdy coś piszesz",
		s_base_font_size_name = "Rozmiar czcionki",
		s_base_font_size_desc = "Podstawowy rozmiar czcionki (zależne od ekranu)",
		s_clean_chat_name = "Oczyść dane wejściowe",
		s_clean_chat_desc = "Oczyść dane wejściowe podczas zamykania",
		s_ambilight_name = "Podświetlenie",
		s_ambilight_clr1_name = "Podstawowy rozmiar czcionki",
		s_ambilight_clr2_name = "Podstawowy rozmiar czcionki",
		s_chat_name_name = "Podstawowy rozmiar czcionki",
	},

	--------------
	--# Turkish #--
	--------------
	-- by https://www.gmodstore.com/users/maellwoe
	["tr"] = {
        __name__ = "Turkish",
        __code__ = "TR",

        chat_mode_normal = "Konuş",
        chat_mode_team = "Takım",

        type_something = "Bir şeyler yaz...",
        send = "Gönder",
        settings = "Ayarlar",
        emoji = "Emoji",
        copied_to_clipboard = "Pano'ya kopyalandı.",
        sizing_mode = "Boyut ayarlanıyor",
        goto_end = "En sona git",
        copy = "Kopyala",

        --parser related
        rgb_hint = "3 veya 4 rakamlı RGB Renk(alpha)",
        rainbow_hint = "Gökkuşağı efekti",
        separator_hint = "Ayrım çizgisi. Konu yok.",
        clr_hint = "Palet'ten renk",
        shaking_hint = "Sallanma efektini Başlat / Durdur Param: [0(yok),1] - Sallanma Yoğunluğu",
        font_hint = "Spesifik font kullan",

        --settings related
        s_tab_general = "Genel",
        s_tab_location = "Konum",
        s_tab_parser_examples = "Ayrıştırıcı örnekleri",
        s_chat_spacey_name = "Mesaj boşluğu",
        s_chat_spacey_desc = "Sohbet mesajları arasındaki mesafe",
        s_font_size_name = "Font büyüklüğü", --font size
        s_msg_time_name = "Mesaj Zamanı",
        s_msg_time_desc = "Mesaj Zamanı'nda saniye",
        s_max_lines_name = "Maksimum satır",
        s_max_lines_desc = "Ekranda en fazla kaç satır gözükeceği",
        s_posx_name = "X Pozisyonu",
        s_posy_name = "Y Pozisyonu",
        s_sizew_name = "Genişlik",
        s_sizeh_name = "Uzunluk",
        s_xywh_mod_name = "Bu ayar, sohbet penceresini değiştirdiğinizde otomatik olarak kaydedilir",
        s_autocomplete_count_name = "Düzeltme ipuçları",
        s_autocomplete_count_desc = "Bir şeyler yazdığında hatalıları düzeltmek için ipuçları",
        s_base_font_size_name = "Font büyüklüğü",
        s_base_font_size_desc = "Temel yazı tipi boyutu (ekrana bağlı)",
		s_clean_chat_name = "Kapatırken girişi",
		s_clean_chat_desc = "Kapatırken girişi temizleyin",
		s_ambilight_name = "Podświetlenie",
		s_ambilight_clr1_name = "Podstawowy rozmiar czcionki",
		s_ambilight_clr2_name = "Podstawowy rozmiar czcionki",
		s_chat_name_name = "Podstawowy rozmiar czcionki",
    },

	----------------
	--# Chinese #--
	----------------
	-- by https://www.gmodstore.com/users/modcraft
	["zh-cn"] = {
		__name__ = "简体中文",
		__code__ = "CN",

		chat_mode_normal = "发言",
		chat_mode_team = "队伍",

		type_something = "说些什么...",
		send = "发送",
		settings = "设置",
		emoji = "表情",
		copied_to_clipboard = "已复制文本到剪切板!",
		sizing_mode = "编辑尺寸中",
		goto_end = "回到底部",
		copy = "复制",

		--parser related
		rgb_hint = "RGB 颜色 3 到 4 个数字(alpha)",
		rainbow_hint = "彩虹效果",
		separator_hint = "分割线. 无参数",
		clr_hint = "调色板上的颜色",
		shaking_hint = "开始 / 停止 抖动效果. 参数: [0,1] - 抖动强度",
		font_hint = "使用指定字体",

		--settings related
		s_tab_general = "一般",
		s_tab_location = "位置",
		s_tab_parser_examples = "解析器例子",
		s_chat_spacey_name = "间隔距离",
		s_chat_spacey_desc = "各条消息间的间隔距离",
		s_font_size_name = "字体大小", --font size
		s_msg_time_name = "消息时间",
		s_msg_time_desc = "消息显示在屏幕上的秒数",
		s_max_lines_name = "最大行数",
		s_max_lines_desc = "聊天中的最大可见行数",
		s_posx_name = "坐标 X",
		s_posy_name = "坐标 Y",
		s_sizew_name = "宽度",
		s_sizeh_name = "高度",
		s_xywh_mod_name = "设置将会在你关闭窗口后自动保存",
		s_autocomplete_count_name = "自动补全提示",
		s_autocomplete_count_desc = "在输入时使用自动补全",
		s_base_font_size_name = "字体大小",
		s_base_font_size_desc = "基础字体大小 (基于屏幕)",
		s_clean_chat_name = "关闭时清洁输入",
		s_clean_chat_desc = "关闭时清洁输入",
		s_ambilight_name = "高亮",
		s_ambilight_clr1_name = "基础字体大小",
		s_ambilight_clr2_name = "基础字体大小",
		s_chat_name_name = "基础字体大小",
	},
	-----------------
    --# PORTUGUÊS #--
    -----------------
    -- by: https://www.gmodstore.com/users/metzy
    ["pt-br"] = {
        __name__ = "Português", --name in game
        __code__ = "BR", --Language code: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
 
        chat_mode_normal = "Falar",
        chat_mode_team = "Equipe",
 
        type_something = "Digite algo...",
        send = "Enviar",
        settings = "Configurações",
        emoji = "Emoji",
        copied_to_clipboard = "Texto copiado!",
        sizing_mode = "Redimensionando",
        goto_end = "Ir para o final",
        copy = "Copiar",
 
        --parser related
        rgb_hint = "Cor RGB com 3 ou 4 números (alpha)",
        rainbow_hint = "Efeito arco-íris",
        separator_hint = "Linha de separação. Sem argumentos",
        clr_hint = "Cor da paleta",
        shaking_hint = "Iniciar/parar efeito de tremor. Parâmetro: [0(nenhum),1] - Intensidade do tremor",
        font_hint = "Usar fonte específica",
 
        --settings related
        s_tab_general = "Geral",
        s_tab_location = "Posição",
        s_tab_parser_examples = "Exemplos de formatação",
        s_chat_spacey_name = "Espaçamento das mensagens",
        s_chat_spacey_desc = "Distância entre as mensagens do chat",
        s_font_size_name = "Tamanho da fonte",
        s_msg_time_name = "Duração da mensagem",
        s_msg_time_desc = "Tempo em que a mensagem permanece na tela (em segundos)",
        s_max_lines_name = "Máximo de linhas",
        s_max_lines_desc = "Quantidade máxima de linhas visíveis no chat",
        s_posx_name = "Posição X",
        s_posy_name = "Posição Y",
        s_sizew_name = "Largura",
        s_sizeh_name = "Altura",
        s_xywh_mod_name = "Essa configuração é salva automaticamente ao mover/redimensionar o chat",
        s_autocomplete_count_name = "Sugestões de autocompletar",
        s_autocomplete_count_desc = "Quantidade de sugestões exibidas ao digitar",
        s_base_font_size_name = "Tamanho base da fonte",
        s_base_font_size_desc = "Tamanho base da fonte (depende da resolução da tela)",
        s_clean_chat_name = "Limpar ao fechar",
        s_clean_chat_desc = "Limpa o campo de texto ao fechar o chat",
        s_ambilight_name = "Ambilight",
        s_ambilight_clr1_name = "Cor 1 do Ambilight",
        s_ambilight_clr2_name = "Cor 2 do Ambilight",
        s_chat_name_name = "Nome do chat",
    },
}

echat.addon:RegisterLanguages(langs)

-- if GetConVar("gmod_language") not in languages table, sets this language
echat.addon:SetDefaultLanguage("en")