local floor = math.floor
local ceil = math.ceil
local max = math.max
local round = math.Round

--------------------
--# FONT MANAGER #--
--------------------
-- EXAMPLE:
-- esclib:SetFontName("shop")
-- esclib:Font(20, 500) -- es_shop_20_500
-- esclib:Font(23, 500) -- es_shop_23_500

-- esclib:SetFontName("jobs")
-- esclib:SetFont("Roboto")
-- esclib:Font(20, 500) -- es_jobs_20_500
-- esclib:ResetFont() -- returns font settings to default


-----------------
--# FUNCTIONS #--
-----------------
esclib.fonts = esclib.fonts or {}
esclib.fonts.heights = esclib.fonts.heights or {}
esclib.fonts.list = esclib.fonts.list or {}
esclib.fonts.prefix = "es_"
esclib.fonts.default = "Tahoma"
esclib.fonts.curname = "newfont"
esclib.fonts.adaptives = esclib.fonts.adaptives or {}


local defaultfont = esclib.fonts.default

function esclib.fonts:CreateNew(file_fontname, fontname, size, weight, fontdata)
	local size = size or 15
	local weight = weight or 500
	if fontdata then
		size = fontdata.size or size
		weight = fontdata.weight or weight
	end

	local target_fontname = self.prefix..fontname.."_"..size.."_"..weight

	local target_fontdata = {
		font = file_fontname,
		size = size,
		weight = weight,
		extended = true
	}

	if fontdata then
		esclib:SafeMerge(target_fontdata, fontdata, true)
	end

	if not self.list[target_fontname] then
		surface.CreateFont(target_fontname, target_fontdata)
		esclib.fonts.heights[target_fontname] = draw.GetFontHeight(target_fontname)
		self.list[target_fontname] = true
	end

	return target_fontname
end


function esclib:Font(size, weight, fontdata)
	local target_fontname = self.fonts.prefix..self.fonts.curname.."_"..size.."_"..weight

	if self.fonts.list[target_fontname] ~= nil then
		return target_fontname
	end

	return self.fonts:CreateNew(self.fonts.default, self.fonts.curname, size, weight, fontdata)
end

function esclib:AdaptiveSize(base_size, screen_size)
	local base_size = base_size or 18
	local base_scrh = screen_size or 1080
	local dif = (esclib.scrh or base_scrh) / base_scrh
	return base_size * dif
end

function esclib:AdaptiveSizeRound(base_size, screen_size)
	return round(self:AdaptiveSize(base_size, screen_size))
end

--RegisterAdaptiveFont("esclib")
--AdaptiveFont("esclib") -> 
function esclib:RegisterAdaptiveFont(name)
	esclib.fonts.adaptives[name] = {
		["prefix"] = self.fonts.prefix,
		["cur_name"] = self.fonts.curname,
		["file_font"] = self.fonts.default, --we need to save it
	}
	return adaptive_name
end

local function round(x)
	return x>=0 and floor(x+0.5) or ceil(x-0.5)
end

function esclib:AdaptiveFont(name, base_size, weight, fontdata)
	local adaptive = esclib.fonts.adaptives[name]
	if not adaptive then return end

	local size = max(round(self:AdaptiveSize(base_size)), 1)
	
	local target_fontname = adaptive["prefix"]..adaptive["cur_name"].."_"..size.."_"..weight
	if self.fonts.list[target_fontname] ~= nil then
		return target_fontname
	end
	self.fonts:CreateNew(adaptive["file_font"], adaptive["cur_name"], size, weight, fontdata)

	return target_fontname
end

function esclib.fonts:GetAll()
	return self.list
end

function esclib:SetFontName(name)
	self.fonts.curname = isstring(name) and name or "newfont"
end


function esclib:SetFont(name)
	self.fonts.default = isstring(name) and name or defaultfont
end


function esclib:ResetFont()
	self.fonts.default = defaultfont
end


function esclib:SetFontPrefix(name)
	self.fonts.prefix = isstring(name) and name or defaultfont
end


concommand.Add("esclib_getfonts",function()
	local fonts = table.GetKeys(esclib.fonts:GetAll())
	if #fonts ~= 0 then
		PrintTable(fonts)
	else
		print("No fonts.")
	end
end)



-------------
--# FONTS #--
-------------	
esclib:SetFontName("esclib")
esclib:SetFont("Geist")
esclib:RegisterAdaptiveFont("esclib")