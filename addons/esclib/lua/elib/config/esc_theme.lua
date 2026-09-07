local skin = {}
skin.roundsize = 8

skin.name = "Blackout"
skin.color = Color(13,13,13)
skin.colors = {}
skin.colors.background = {
	col = Color(23,23,24,250),
}
skin.colors.button = {
	main = Color(21,21,21),
	hover = Color(33, 33, 33),

	text = Color(160,160,160),
	text_hover = Color(225,225,255),
	text_gray = Color(82,82,82),
	text_black = Color(0,0,0),

	discard = Color(252, 59, 80),
	discard_hover = Color(255, 80, 100),

	apply = Color(30, 215, 96),
	apply_hover = Color(70, 245, 136),

	accent = Color(36, 255, 164),
	accent_hover = Color(91, 255, 186),
}
skin.colors.frame = {
	bg = Color(21,21,21),
	accent = Color(35, 35, 36),
	accent2 = Color(30, 215, 96),

	text = Color(214, 214, 214),
	text_hover = Color(30, 215, 96),

	text_gray = Color(82,82,82),
}
skin.colors.hint = {
	bg = Color(25, 25, 25),
	bg2 = Color(49, 49, 51),
	text = Color(235,235,255)
}
esclib.addon:RegisterSkin("blackout", skin)


local skin = {}
skin.roundsize = 8

skin.name = "Whiteout"
skin.color = Color(255,255,255)
skin.colors = {}
skin.colors.background = {
	col = Color(150,150,170,70),
}
skin.colors.button = {
	main = Color(230, 230, 235, 250),
	hover = Color(255, 255, 255, 250),

	text = Color(13,13,13),
	text_hover = Color(30,30,35),
	text_gray = Color(0,0,0),
	text_black = Color(253,253,253), --inverse :)

	discard = Color(252, 59, 80),
	discard_hover = Color(255, 80, 100),

	apply = Color(30, 215, 96),
	apply_hover = Color(50, 225, 116),

	accent = Color(24, 185, 118),
	accent_hover = Color(59, 173, 126),
}
skin.colors.frame = {
	bg = Color(170, 170, 195, 240),
	accent = Color(240, 240, 255),
	accent2 = Color(30, 215, 96),

	text = Color(13,13,13),
	text_hover = Color(35, 35, 35),

	text_gray = Color(50,50,55),
}
skin.colors.hint = {
	bg = Color(230, 230, 235),
	bg2 = Color(255, 255, 255),
	text = Color(13,13,13)
}
esclib.addon:RegisterSkin("whiteout", skin)

local skin = {}
skin.roundsize = 8

skin.name = "Monokai"
skin.color = Color(46, 46, 46)
skin.colors = {}
skin.colors.background = {
	col = Color(23,23,33,200),
}
skin.colors.button = {
	main = Color(60, 60, 57, 250),
	hover = Color(65, 65, 62, 250),

	text = Color(200,200,200),
	text_hover = Color(225,225,255),
	text_gray = Color(100,100,100),
	text_black = Color(0,0,0),

	discard = Color(252, 59, 80),
	discard_hover = Color(255, 80, 100),

	apply = Color(30, 215, 96),
	apply_hover = Color(50, 225, 116),

	accent = Color(36, 255, 164),
	accent_hover = Color(91, 255, 186),
}
skin.colors.frame = {
	bg = Color(46, 46, 46, 250),
	accent = Color(67, 67, 66),
	accent2 = Color(30, 215, 96),

	text = Color(214, 214, 214),
	text_hover = Color(30, 215, 96),

	text_gray = Color(121, 121, 121),
}
skin.colors.hint = {
	bg = Color(23,23,30,250),
	bg2 = Color(45,45,48),
	text = Color(235,235,255)
}
esclib.addon:RegisterSkin("monokai", skin)


esclib.addon:SetDefaultSkin("blackout")
