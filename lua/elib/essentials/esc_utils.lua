esclib.util = {}

local esclib = esclib
local masks = esclib.masks
local sin = math.sin
local cos = math.cos
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min
local abs = math.abs
local clamp = math.Clamp
local table_Copy = table.Copy
local color_white = color_white

local function checktype(val, lua_type)
	local lua_type = lua_type or ""
    if isfunction(lua_type) then
        if not lua_type(val) then 
            error("Customcheck failed. Maybe wrong lua type provided?")
        end
    elseif type(val) ~= lua_type then
        error("Wrong lua type or value is empty [type(val) = "..type(val) .." lua_type = "..lua_type)
    end
end

function esclib.accessor(tbl, key, name, default_val, lua_type, on_change)
    if lua_type and default_val ~= nil then 
        checktype(default_val, lua_type)
    end
    tbl[key] = default_val
    
    local set_name = string.format("Set%s", name)
    local get_name = string.format("Get%s", name)
    tbl[set_name] = function(self, val)
        if lua_type and val ~= nil then
            checktype(val, lua_type)
        end
        if on_change and isfunction(on_change) then
            on_change(self, val)
        end
        self[key] = val
        return self
    end
    tbl[get_name] = function(self, val)
        return self[key]
    end
end
local accessor_fn = esclib.accessor

function esclib.util:Round(x)
	return x>=0 and floor(x+0.5) or ceil(x-0.5)
end

function esclib.util:NiceTime(time, bHours, bMinutes, bSeconds, bMilliseconds, try_language)
	local time = string.FormattedTime( time )
	local result = ""

	local hours, bHours 	= time.h, ((bHours == nil) or bHours)
	local minutes, bMinutes = time.m, ((bMinutes == nil) or bMinutes)
	local seconds, bSeconds = time.s, ((bSeconds == nil) or bSeconds)
	local milliseconds, bMilliseconds = time.ms, (bMilliseconds)

	if (not bHours) then minutes = minutes + (hours * 60) end
	if (not bHours) and (not bMinutes) then seconds = seconds + (minutes * 60) end
	if (not bHours) and (not bMinutes) and (not bSeconds) then milliseconds = milliseconds + (seconds * 1000) end

	if bHours then
		result = result..string.format("%d%s ", hours, esclib.addon:Translate("char_hours", try_language))
	end
	if bMinutes then
		result = result..string.format("%d%s ", minutes, esclib.addon:Translate("char_minutes", try_language))
	end
	if bSeconds then
		result = result..string.format("%d%s ", seconds, esclib.addon:Translate("char_seconds", try_language))
	end
	if bMilliseconds then
		result = result..string.format("%d%s ", milliseconds, esclib.addon:Translate("char_milliseconds", try_language))
	end

	return result
end

function esclib.util:NumberLimit(number, min, max, str_format)
	local res = number

	if number >= max then
		res = string.format(str_format or "%d+", max-1 )
	elseif number < min then
		res = string.format(str_format or "<%d", min )
	end

	return res
end

function esclib.util:HexToColor(hex, alpha)
	hex = hex:gsub("#","")
    return Color(tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), alpha or 255)
end


esclib.restricted_chars = {
	["\\"] = true,
	["/"] = true,
	[":"] = true,
	["*"] = true,
	["?"] = true,
	['"'] = true,
	["'"] = true,
	["<"] = true,
	[">"] = true,
	["|"] = true,
	["CON"] = true,
	["PRN"] = true,
	["AUX"] = true,
	["NUL"] = true,
	["COM"] = true,
	["LPT"] = true,
}

function esclib.util:IsRestrictedChar(strs)
	return esclib.restricted_chars[strs or ""]
end

function esclib.util:TruncateStr(str, maxLength)
	if #str > maxLength then str = str:sub(1, maxLength-3) .. "..." end
	return str
end


local function tablesAreEqual(table1, table2)
	if table1 == table2 then return true end
	if type(table1) ~= type(table2) then return false end
	
	for k, v in pairs(table1) do
		if type(v) ~= type(table2[k]) then return false end
		if type(v) == "table" and type(table2[k]) == "table" then
			if not tablesAreEqual(v, table2[k]) then
				return false
			end
		elseif table2[k] ~= v then
			return false
		end
	end
	
	for k in pairs(table2) do
		if table1[k] == nil then
			return false
		end
	end
	
	return true
end

local function VarsIsEqual(var1, var2)
	if type(var1) ~= type(var2) then return false end
	if type(var1) == "table" and type(var2) == "table" then return tablesAreEqual(var1, var2) end
	return var1 == var2
end

function esclib.util:IsValuesEqual(var1, var2)
	return VarsIsEqual(var1, var2)
end

function esclib.util:ColorMean(...)
	local values = {...}
	local count = #values
	if count < 1 then return end

	local r, g, b, a = 0, 0, 0, 0
	for _,v in ipairs(values) do
		r = r + v.r
		g = g + v.g
		b = b + v.b
		a = a + v.a
	end

	return Color(r/count, g/count, b/count, a/count)
end

--this function mutates from
--example: esclib.print(esclib.util:ColorLerp(0.5, Color(255,255,255), Color(0,0,0)))
function esclib.util:ColorLerp(frac, from, to, fast_alpha)
	-- assert(IsColor(from), "'from' must be color")
	-- assert(IsColor(to), "'to' must be color")

	from.r = Lerp(frac, from.r, to.r)
	from.g = Lerp(frac, from.g, to.g)
	from.b = Lerp(frac, from.b, to.b)
	from.a = Lerp(fast_alpha and 1 or frac, from.a, to.a)

	return from
end

--This function NOT mutate original color
function esclib.util:ColorLerpCP(frac, from, to, fast_alpha)
	local new_clr = table_Copy(from)
	self:ColorLerp(frac, new_clr, to, fast_alpha)
	return new_clr
end

function esclib.util:ColorAdjust(clr, amount)
    amount = amount or 50
	local new_clr = table_Copy(clr)	
	if not istable(amount) then
		new_clr.r = clamp(clr.r+amount, 0, 255)
		new_clr.g = clamp(clr.g+amount, 0, 255)
		new_clr.b = clamp(clr.b+amount, 0, 255)
		new_clr.a = clr.a
	else
		for k,v in pairs(amount) do
			new_clr[k] = clamp(clr[k]+v, 0, 255)
		end
	end
	return new_clr
end

function esclib.util:ColorSet(clr, replacers)
	local new_clr = table_Copy(clr)
	for k,v in pairs(replacers) do
		new_clr[k] = v
	end
	return new_clr
end


function esclib.util:ColorDiff(clr1, clr2)
	assert(IsColor(clr1), "'clr1' must be color")
	assert(IsColor(clr2), "'clr2' must be color")

	local dif = abs(clr1.r - clr2.r)
	dif = dif + abs(clr1.g - clr2.g)
	dif = dif + abs(clr1.b - clr2.b)
	dif = dif + abs(clr1.a - clr2.a)

	return dif
end


--------------------
--# CLIENT UTILS #--
--------------------
if CLIENT then
	--Do it once
	if not esclib.scrw or not esclib.scrh then
		esclib.scrw = ScrW()
		esclib.scrh = ScrH()
	end

	hook.Add("OnScreenSizeChanged", "esclib.onscreenchange", function(oldw, oldh)
		esclib.scrw = ScrW()
		esclib.scrh = ScrH()
	end)

	--col_white if bg is white
	--col_black if bg is black
	function esclib.util:TextOnBG(bgCol, col_white, col_black, switch_value)
		switch_value = switch_value or 150
		return (((bgCol.r + bgCol.g + bgCol.b) / 3 >= switch_value) and col_white or col_black)
	end

	function esclib.util.GetTextSize(txt,font)
		surface.SetFont(font)
		local x, y = surface.GetTextSize(txt)
		return {w = x, h = y}
	end

	function esclib.util:TextSize(txt,font)
		surface.SetFont(font)
		return surface.GetTextSize(txt)
	end

	--fast function, but can be less accurate
	function esclib.util:TextCut(text,font,maxw, add_symbol)
		if not text then return end
		local add_symbol = add_symbol or ""

		local textw,texth = esclib.util:TextSize(text,font)
		if textw <= maxw then return text end

		local len = string.len( text )

		local to_cut = math.Clamp(math.ceil((textw-maxw)/(textw/len)), 0, len )

		return string.sub( text, 1, len-to_cut )..add_symbol
	end

	function esclib.util:TextCutAccurate(text,font,maxw,add_symbol)
		if not text then return end
		local add_symbol = add_symbol or ""

		local textw_max,_ = esclib.util:TextSize(text,font)
		if textw_max <= maxw then return text end

		local text_cutted = text
		for i = string.len(text), 1, -1 do
			text_cutted = string.sub( text, 1, i )
			local textw,_ = esclib.util:TextSize(text_cutted,font)
			if textw <= maxw then
				break
			end
		end

		return text_cutted..add_symbol
	end

	--https://gist.github.com/theawesomecoder61/d2c3a3d42bbce809ca446a85b4dda754
	function esclib.util.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness, rote)
		local triarc = {}
		local deg2rad = math.pi / 180
		local rote = rote or 0
		
		-- Correct start/end ang
		local startang,endang = startang or 0, endang or 0
		local bClockwise = (startang < endang)
		startang = startang + rote
		endang = endang + rote
		if bClockwise then
			local temp = startang
			startang = endang
			endang = temp
			temp = nil
		elseif (startang > endang) then 
			local temp = startang
			startang = endang
			endang = temp
			temp = nil
		end
		
		
		-- Define step
		local roughness = max(roughness or 1, 1)
		local step = roughness
		if bClockwise then
			step = math.abs(roughness) * -1
		end
		
		
		-- Create the inner circle's points.
		local inner = {}
		local r = radius - thickness
		for deg=startang, endang, step do
			local rad = deg2rad * deg
			table.insert(inner, {
				x=cx+(cos(rad)*r),
				y=cy+(sin(rad)*r)
			})
		end
		
		
		-- Create the outer circle's points.
		local outer = {}
		for deg=startang, endang, step do
			local rad = deg2rad * deg
			table.insert(outer, {
				x=cx+(cos(rad)*radius),
				y=cy+(sin(rad)*radius)
			})
		end
		
		
		-- Triangulize the points.
		for tri=1,#inner*2 do -- twice as many triangles as there are degrees.
			local p1,p2,p3
			p1 = outer[floor(tri/2)+1]
			p3 = inner[floor((tri+1)/2)+1]
			if tri%2 == 0 then --if the number is even use outer.
				p2 = outer[floor((tri+1)/2)]
			else
				p2 = inner[floor((tri+1)/2)]
			end
		
			table.insert(triarc, {p1,p2,p3})
		end
		
		-- Return a table of triangles to draw.
		return triarc
		
	end

	function esclib.util:PrecacheRoundedPoly(x, y, w, h, radius, cornerPoints)
		local poly = {}
		local function addCorner(centerX, centerY, startAngle)
			for i = 0, cornerPoints do
				local angle = math.rad(startAngle + (90 / cornerPoints) * i)
				table.insert(poly, {
					x = centerX + math.cos(angle) * radius,
					y = centerY + math.sin(angle) * radius
				})
			end
		end
	
		-- Top-left corner
		addCorner(x + radius, y + radius, 180)
		-- Top-right corner
		addCorner(x + w - radius, y + radius, 270)
		-- Bottom-right corner
		addCorner(x + w - radius, y + h - radius, 0)
		-- Bottom-left corner
		addCorner(x + radius, y + h - radius, 90)
	
		return poly
	end

	-----------------
	--# AMBILIGHT #--
	-----------------
	local Ambilight = {}
	Ambilight.__index = Ambilight
	accessor_fn(Ambilight, "poly", "Poly", nil, "table")
	accessor_fn(Ambilight, "rounding", "Rounding", 8, "number")
	accessor_fn(Ambilight, "speed", "Speed", 2, "number")
	accessor_fn(Ambilight, "radius_multiplier", "RadiusMultiplier", 1, "number")
	accessor_fn(Ambilight, "initial_angle", "InitialAngle", 0, "number")
	accessor_fn(Ambilight, "colors", "Colors", {
		Color(255,215,130),
		Color(0,255,136),
		Color(82,82,255),
		Color(255,102,82)}, 
		"table",
		function(self, val)
			self.colors_count = #val
		end
	)
	local allowed_modes = {
		["trigonometric"] = true,
		["border"] = true
	}
	accessor_fn(Ambilight, "mode", "Mode", "trigonometric", function(val) return allowed_modes[val] end)



	function Ambilight.DrawMask(self, x, y, w, h)
		-- if not self.poly then
		-- 	self.poly = self:GeneratePoly(x,y,w,h)
		-- end
		-- draw.NoTexture()
		-- surface.SetDrawColor(color_white)
		-- surface.DrawPoly(self.poly)

		draw.RoundedBox(self.rounding, x, y, w, h, color_white)
	end

	local grad_mat = esclib:GetMaterial("radial_gradient.png")
	function Ambilight.DrawContent(self, x, y, w, h)
		local time = CurTime() * self.speed
		local radius = math.max(w, h) * self.radius_multiplier
		
		if self.mode == "border" then
			for i = 1, self.colors_count do
				-- Calculate position along rectangle perimeter (0 to 1)
				local pos = ((i-1) / self.colors_count + time*0.15) % 1
				local mx, my = x + w*0.5, y + h*0.5
				
				-- Determine which side of rectangle and position along it
				if pos < 0.25 then -- Top side
					mx = x + w * (pos * 4)
					my = y
				elseif pos < 0.5 then -- Right side
					mx = x + w
					my = y + h * ((pos - 0.25) * 4)
				elseif pos < 0.75 then -- Bottom side
					mx = x + w * (1 - (pos - 0.5) * 4)
					my = y + h
				else -- Left side
					mx = x
					my = y + h * (1 - (pos - 0.75) * 4)
				end
				
				esclib.draw:MaterialCentered(mx, my, radius, self.colors[i], grad_mat)
			end
		else
			for i = 1, self.colors_count do
				local angle = self.initial_angle + time + math.pi * 2 * (i-1) / self.colors_count
				local mx = x + w*0.5 + math.cos(angle) * w*0.5
				local my = y + h*0.5 + math.sin(angle) * h*0.5
				
				esclib.draw:MaterialCentered(mx, my, radius, self.colors[i], grad_mat)
			end
		end

		if isfunction(self.OnDraw) then
			self:OnDraw(x,y,w,h)
		end
	end

	function Ambilight:GeneratePoly(x,y,w,h)
		return esclib.util:PrecacheRoundedPoly(x, y, w, h, self.rounding, esclib:AdaptiveSize(8))
	end

	function Ambilight:UpdatePoly()
		self.poly = nil --Delete it for force rerender
	end

	function Ambilight:SetDrawBlur(do_draw, pnl)
		if not IsValid(pnl) then return end
		self.draw_blur = do_draw
		self.blur_pnl = pnl
	end

	function Ambilight:Draw(x,y,w, h)
		masks.Start()
			if self.draw_blur and IsValid(self.blur_pnl) then
				masks.DrawBlur(self.blur_pnl)
			end
			self.DrawContent(self, x, y, w, h)
		masks.Source()
			self.DrawMask(self, x, y, w, h)
		masks.End()
	end

	function esclib.util:PrecacheAmbilight(rounding, colors, speed, radius_multiplier, initial_angle)
		local instance = {}
		setmetatable(instance, Ambilight)

		if colors then instance:SetColors(colors) end
		if speed then instance:SetSpeed(speed) end
		if rounding then instance:SetRounding(rounding) end
		if radius_multiplier then instance:SetRadiusMultiplier(radius_multiplier) end
		if initial_angle then instance:SetInitialAngle(initial_angle) end

		instance.poly = nil
		instance.colors_count = #instance.colors
		
		return instance
	end
end