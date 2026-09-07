local skin = {}
skin.name = "Blackout"
skin.color = Color(13,13,13)
skin.colors = {}
skin.colors.main = {
	bg = Color(26, 27, 30, 250),
	bg2 = Color(14, 17, 14, 250),

	button = Color(1, 10, 25, 250),
	button_hover = Color(45, 45, 47),
	accent = Color(206,133,255),
	scrollbar = Color(57, 57, 59, 100),
	text_entry = Color(14, 17, 14, 170),

	text = Color(255,255,255),
	text_gray = Color(160,160,160),
	text_hover = Color(183, 176, 255),
	text_selection = Color(92, 79, 238),
}

echat.addon:RegisterSkin("blackout", skin)

local skin = {}
skin.name = "Snow"
skin.color = Color(255,255,255)
skin.colors = {}
skin.colors.main = {
	bg = Color(200, 200, 220, 200),
	bg2 = Color(229, 238, 238),
	
	button = Color(255, 255, 255),
	button_hover = Color(200, 200, 200),
	accent = Color(153,0,255),
	scrollbar = Color(246, 255, 255, 155),
	text_entry = Color(229, 238, 238),
	
	text = Color(20, 20, 20),
	text_gray = Color(95, 95, 95),
	text_hover = Color(183, 176, 255),
	text_selection = Color(92, 79, 238),
}

echat.addon:RegisterSkin("snow", skin)

local skin = {}
skin.name = "Transparent"
skin.color = Color(50,50,50)
skin.colors = {}
skin.colors.main = {
	bg = Color(1, 10, 25, 200),
	bg2 = Color(1, 10, 25, 200),
	
	button = Color(1, 10, 25),
	button_hover = Color(20, 30, 45),
	accent = Color(153,0,255),
	scrollbar = Color(20, 20, 20, 150),
	text_entry = Color(1, 10, 25, 0),

	text = Color(255,255,255),
	text_gray = Color(160,160,160),
	text_hover = Color(183, 176, 255),
	text_selection = Color(92, 79, 238),
}

echat.addon:RegisterSkin("transparent", skin)


--RegisterSkin(<uid>,<skin table>)

echat.addon:SetDefaultSkin("blackout")