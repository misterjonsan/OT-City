milkyLib = milkyLib or {}

milkyLib.codes_table = {
	{
		cat_name = "ADMIN",
		banned = true,
		{
			id = "milky_here",
			sub = true,
			code = "Milky редактирует сервер",
            col = Color(255,255,255,255),
            --sound = "https://raw.githubusercontent.com/Milky182828/MILKY/master/sound/milky_here.mp3",
		},
		{
			id = "reset",
			sub = true,
			code = "!!! ВНИМАНИЕ ТЕХ.РЕСТАРТ СЕРВЕРА !!!",
			timed = 120,
			col = Color(255,0,0,255),
			sound = "https://raw.githubusercontent.com/Milky182828/MILKY/master/sound/restart.mp3",
		},
		{
			id = "nu242222222422",
			sub = true,
			code = "DUMB",
			timed = 170,
			col = Color(0, 176, 189,255),
			sound = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/Neizvesten_-_Mazie_-_Dumb_Dumb_Lyrics_Everyone_is_dumb_Tiktok_Song_(SkySound.cc).mp3",
		},
		{
			id = "nu24222412",
			sub = true,
			code = "none",
			timed = 200,
			col = Color(0, 176, 189,255),
			sound = "https://monteract.myarena.site/ptica.mp3",
		},
		{
			id = "10s",
			sub = true,
			code = "10s",
			timed = 15,
			col = Color(0, 176, 189,255),
			sound = "https://github.com/Milky182828/MILKY/raw/refs/heads/master/sound/nuclear_time.mp3",
		},
		{
			id = "alicego232",
			sub = true,
			code = "newYe",
			timed = 300,
			col = Color(0, 176, 189,255),
			sound = "https://fine.sunproxy.net/file/SmExakg3TFpUZGVTTlZ3a1Ivb3pJNkpxNXlJWTArL2JKYXQ5YVBrbXA4NGpnQnZqVFFBZWNsQjNHaFRIOWpVK1FpZ1ErT0VpdFFRU1BtcEZacFZRMlo5cG5KaU50SXA2a3FPRzY5ei9iQUE9/Ambient_-_Horror_(SkySound.cc).mp3",
		},
		{
			id = "nu",
			sub = true,
			code = "☢ АЛЬФА БОЕГОЛОВКА ☢",
			timed = 300,
			col = Color(255,0,0,255),
			sound = "https://raw.githubusercontent.com/Milky182828/MILKY/master/sound/intercom_area/nuclear.mp3",
		},
	},
	{
        cat_name = "Прочее",
	
		{
			id = "as",
			sub = true,
			timed = 9,
			code = "Отмена",
			//desc = "Отмена боеголовки либо отмена сбора.",
			col = Color(140,140,140,200),
		},
    },
}
  
milkyLib.codes_table.keys = (function()
    local keys = {}
    for _, category in ipairs(milkyLib.codes_table) do
        for _, code in ipairs(category) do
            keys[code.id] = code
        end
    end
    return keys
end)()