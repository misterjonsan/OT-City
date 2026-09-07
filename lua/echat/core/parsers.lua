local clamp = math.Clamp
local min, max = math.min, math.max
local format = string.format

---------------------------------------
--# USERGROUP CHECKER (from config) #--
---------------------------------------
local function default_checker(ply, parser)
	if not ply then return true end --if server doesnt know msg author then skip check
	local user_group = ply:GetUserGroup()

	if echat.config.rank_parsers[parser["uid"]] then
		return echat.config.rank_parsers[parser["uid"]][user_group]
	else
		return true
	end
end


local function format_time()
	local currentTime = os.date("*t")

	local hour = currentTime.hour
	local hours12 = hour
    local suffix = "AM"

    if hours12 >= 12 then
        suffix = "PM"
        if hours12 > 12 then
            hours12 = hours12 - 12
        end
    elseif hours12 == 0 then
        hours12 = 12
    end

	-- {hour}:{minute}:{second} --24 time format
	-- {hour12}:{minute}:{second} {am_pm} --12 hours format
	-- {time}, 24 hours time format
	-- {time12}, 12 hours time format
	local final_str = esclib.text:KeyFormat(echat.config.time_format, {
		["hour"] = format("%02d", hour),
		["minute"] = format("%02d", currentTime.min),
		["second"] = format("%02d", currentTime.sec),
		["hour12"] = format("%02d", hours12),
		["am_pm"] = suffix,
	})

	return final_str
end


----------------
--# RICHTEXT #--
----------------
--This function converts parsed data into richtext functions echat/vgui/echat_richtext.lua
local errorMat = Material("error")
function echat:ConvertParsedToRichtext(richtext, parsed)
	local colors = echat.addon:GetColors()
	
	local clr = Color(255,255,255)
	local stop_shaking = false
	local font_change = nil
	local bg_col_changed = nil

	for _, item in ipairs(parsed) do
		local _type = item.type
		local v = item.value
		
		if _type == "rgb" then
			clr = Color(v.r, v.g, v.b, v.a)
			richtext:InsertColorChange(clr:Unpack())
		elseif _type == "bg_col" then
			bg_col_changed = true
			if not v then
				richtext:InsertBackgroundColorChange(nil)
			else
				richtext:InsertBackgroundColorChange(v.r, v.g, v.b, v.a)
			end
		elseif _type == "text" then
			richtext:AppendText(v)
		elseif _type == "rainbow" then
			richtext:InsertRainbowEffect()
		elseif _type == "separator" then
			richtext:AppendSeparator( )
		elseif _type == "emoji" then
			richtext:AppendEmoji(v)
		elseif _type == "shake" then
			richtext:InsertShakingEffect(v and (clamp(v, 0, 1)) or 0.5)
			stop_shaking = true
		elseif _type == "font" then
			font_change = richtext:GetFont()
			richtext:InsertFontChange(v)
		elseif _type == "adafont" then
			font_change = richtext:GetFont()
			richtext:InsertFontChange(echat:AdaptiveFont("echat", echat.addon:GetVar("base_font_size") or v, 500))
		elseif _type == "adafont_mono" then
			font_change = richtext:GetFont()
			richtext:InsertFontChange(echat:AdaptiveMonoFont("echatmono", echat.addon:GetVar("base_font_size") or v, 500))
		elseif _type == "theme" then
			local clr = colors
			for _, v in ipairs(string.Explode(".", v)) do
				if clr[v] then clr = clr[v] else break end
			end

			if not IsColor(clr) then continue end
			richtext:InsertColorChange(clr.r, clr.g, clr.b, clr.a)
		elseif _type == "time" then
			richtext:AppendText(format_time())
		elseif _type == "link" then
			--copy color
			local clr_copy = table.Copy(clr)
			clr = Color(colors.main.accent.r, colors.main.accent.g, colors.main.accent.b, colors.main.accent.a)
			richtext:InsertColorChange(clr:Unpack())

			richtext:InsertClickable(function()
				gui.OpenURL(v)
			end)
			richtext:AppendText(v)
			richtext:InsertClickable() --remove clickable
			richtext:AppendText("")

			--restore color
			clr = Color(clr_copy:Unpack())
			richtext:InsertColorChange(clr:Unpack())
		elseif _type == "img" then
			local mat = errorMat

			local chatw, chath = chat.GetChatBoxSize()

			local width = min(esclib:AdaptiveSize(v["w"]), chatw-10)
			local height = min(esclib:AdaptiveSize(v["h"]), chath/2-10)

			echat.addon:DownloadMaterial(v["url"], 
				function(mater)
					mat = mater
				end,
				function(errMsg)
					--nothing
				end,
				nil,
				"temp"
			)

			local pnl = vgui.Create("DPanel")
			pnl:SetWide(width)
			pnl:SetHeight(height)
			function pnl:Paint(w,h)
				if mat:IsError() then
					esclib.draw:Border(0,0,w,h,3, colors.main.accent)
					return
				end
				esclib.draw:Material(0,0,w,h,color_white,mat)
			end

			richtext:AppendPanel(pnl)
		end
	end

	--return all back
	if stop_shaking then
		richtext:InsertShakingEffect(0)
	end

	if font_change then
		richtext:InsertFontChange(font_change)
	end

	if bg_col_changed then
		richtext:InsertBackgroundColorChange(nil)
	end
end


local nil_equivalents = {
	["none"] = true,
	["false"] = true,
	["nil"] = true,
	["end"] = true,
	["cancel"] = true,
	["stop"] = true
}

--------------------------
--# REGISTERED PARSERS #--
--------------------------
-- echat:AddParser(
-- 	 unique_name, 
-- 	 encode_func, --to table
-- 	 decode_func, --to string
-- 	 examples, --table or string
-- 	 description, --string
-- 	 custom_check_func, --check for availability
--   icon, --icon material
-- )
--args - command splits args with ":" example: <rgb:10,20,30> -> {1:"rgb", 2:"10,20,30"}

------------------
--# RGB PARSER #--
------------------
local function string_to_color(str)
	local components = {}
	for component in str:gmatch("%d+") do
		table.insert(components, tonumber(component))
	end
	local count = #components

	if count < 3 then return end

	local result = Color(components[1], components[2], components[3], 255)
	if count > 3 then
		result.a = components[4]
	end
	return result
end

local function encode(args) --function itself
	if #args < 2 then return end --nothing to return

	local result = string_to_color(args[2])
	if not result then return end

	return {type="rgb", value=result}
end

local function decode(encoded) --encoded will be {type="rgb", value=result} you need to return string
	return string.format("%s:%d,%d,%d,%d", encoded.type, encoded.value.r, encoded.value.g, encoded.value.b, encoded.value.a)
end

local examples = {"rgb:255,0,0", "rgb:10,10,255,140"}
local description = echat.addon:Translate("rgb_hint") --description of hint in chat
local custom_check = default_checker

echat:AddParser("rgb", encode, decode, examples, description, custom_check, echat:GetEmoji("art")) --add parser to addon



------------------
--# CLR PARSER #--
------------------
local clr_examples = {}
for k,_ in pairs(echat.config.pallete) do
	table.insert(clr_examples, "clr:"..k)
end
echat:AddParser(
	"clr", 

	function(args) 
		if #args < 2 then return end --nothing to return
		if not echat.config.pallete[args[2]] then return end --not in pallete
		return {type="rgb", value=echat.config.pallete[args[2]]} --NOTE: we using other parser type. Will be used decoder from rgb parser
	end, 

	function(encoded) return "" end, --as we use type rgb(other parser) we dont need to specify decoder

	clr_examples, 
	echat.addon:Translate("clr_hint"), 
	default_checker,
	echat:GetEmoji("sparkles")
)


--------------------------
--# THEME COLOR PARSER #--
--------------------------

local theme_examples = {}
if CLIENT then --only on client
	local theme = echat.addon:GetCurrentSkin()
	for _,theme_tab in ipairs(table.GetKeys(theme["colors"])) do
		if theme_tab == "default" then continue end --skip

		for _,theme_clr in ipairs(table.GetKeys(theme["colors"][theme_tab])) do
			local clr = theme["colors"][theme_tab][theme_clr]
			if not IsColor(clr) then continue end

			table.insert(theme_examples, string.format("theme:%s.%s", theme_tab, theme_clr))
		end
	end
end

echat:AddParser(
	"theme", 

	function(args)
		if #args < 2 then return end --nothing to return

		return {type="theme", value=string.format("%s.%s", args[2], args[3])}
	end, 

	function(encoded) 
		return string.format("%s:%s", encoded.type, encoded.value)
	end,

	theme_examples, 
	echat.addon:Translate("clr_hint"), 
	default_checker,
	echat:GetEmoji("fleur_de_lis")
)



-------------------------------
--# BACKGROUND COLOR PARSER #--
-------------------------------
local function encode(args)
	if #args < 2 then return end

	if nil_equivalents[args[2] or ""] then return {type="bg_col", value=nil} end --end background color

	local result = string_to_color(args[2])
	if not result then return end

	return {type="bg_col", value=result}
end

local function decode(encoded)
	return string.format("%s:%d,%d,%d,%d", encoded.type, encoded.value.r, encoded.value.g, encoded.value.b, encoded.value.a)
end

local examples = {"bg_col:255,0,0", "bg_col:none"}
local description = echat.addon:Translate("rgb_hint") --description of hint in chat
local custom_check = default_checker

echat:AddParser("bg_col", encode, decode, examples, description, custom_check, echat:GetEmoji("globe_with_meridians")) --add parser to addon


-------------------
--# FONT PARSER #--
-------------------
--generate examples
local all_fonts = echat:GetFonts()
local allowed_fonts = {}
local font_examples = {} 
for k,v in ipairs(all_fonts) do
	allowed_fonts[v] = true
	table.insert(font_examples, "font:"..v)
end

local function font_decoder(encoded)
	return string.format("%s:%s", encoded.type, encoded.value)
end

--add parser
echat:AddParser(
	"font", 

	function(args)
		if #args < 2 then return end
		if not allowed_fonts[args[2]] then return end 
		return {type="font", value=args[2]}
	end, 

	font_decoder,

	font_examples, 
	echat.addon:Translate("font_hint"), 
	default_checker,
	echat:GetEmoji("abc")
)

local function adaptive_encode(args)
	return {type=args[1], value=args[2]}
end

--adaptive font
echat:AddParser(
	"adafont", 
	adaptive_encode,
	font_decoder,
	{"adafont"}, 
	echat.addon:Translate("font_hint"), 
	default_checker,
	echat:GetEmoji("abc")
)

--adaptive monofont
echat:AddParser(
	"adafont_mono", 
	adaptive_encode,
	font_decoder,
	{"adafont_mono"}, 
	echat.addon:Translate("font_hint"), 
	default_checker,
	echat:GetEmoji("abc")
)






----------------------
--# LINE SEPARATOR #--
----------------------
echat:AddParser(
	"separator", 

	function(args) 
		return {type="separator", value=args[2]}
	end,

	function(encoded)
		return encoded.type --will be <separator>
	end,

	{"separator"}, 
	echat.addon:Translate("separator_hint"), 
	default_checker,
	echat:GetEmoji("construction")
)


----------------------
--# RAINBOW EFFECT #--
----------------------
echat:AddParser(
	"rainbow", 

	function(args) 
		return {type="rainbow"}
	end,

	function(encoded)
		return encoded.type
	end,

	{"rainbow"}, --examples
	echat.addon:Translate("rainbow_hint"), 
	default_checker,
	echat:GetEmoji("rainbow_flag") --icon
)


--------------------
--# SHAKE EFFECT #--
--------------------
echat:AddParser(
	"shake", 

	function(args)
		if nil_equivalents[args[2] or ""] then return {type="shake", value=0} end --end shake effect

		if not tonumber(args[2]) then return end

		return {type="shake", value=args[2]}
	end,

	function(encoded)
		return string.format("%s:%f",encoded.type,encoded.value)
	end,
	
	{"shake:0.5", "shake:none"}, 
	echat.addon:Translate("shaking_hint"), 
	default_checker,
	echat:GetEmoji("zap") --icon
)


-------------------------
--# LOCAL TIME PARSER #--
-------------------------
echat:AddParser(
	"time", 

	function(args) 
		return {type="time"}
	end,

	function(encoded)
		return encoded.type --will be <separator>
	end,

	{"time"}, 
	"", 
	default_checker,
	echat:GetEmoji("date")
)


-------------------
--# LINK PARSER #--
-------------------
echat:AddParser(
	"link", 

	function(args)
		local args_copy = table.Copy(args)
		table.remove(args_copy, 1)
		local url = table.concat(args_copy, ":")
		if string.StartsWith(url, "http://") or string.StartsWith(url, "https://")  then
			return {type="link", value=url}
		end
	end,

	function(encoded)
		return encoded.type
	end,

	{"link:https://"}, 
	"", 
	default_checker,
	echat:GetEmoji("link")
)

--------------------
--# IMAGE PARSER #--
--------------------
echat:AddParser(
	"img", 

	function(args)
		local args_copy = table.Copy(args)
		table.remove(args_copy, 1)

		local width = args_copy[1]
		local height = args_copy[2]
		table.remove(args_copy, 2)
		table.remove(args_copy, 1)
		
		local url = table.concat(args_copy, ":")
		if string.StartsWith(url, "http://") or string.StartsWith(url, "https://")  then
			return {type="img", value={w=max(width, 30), h=max(height, 30), url=url}}
		end
	end,

	function(encoded)
		return encoded.type
	end,

	{"img:100:100:https://"}, 
	"", 
	default_checker,
	echat:GetEmoji("link")
)