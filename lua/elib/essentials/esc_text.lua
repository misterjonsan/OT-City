local insert, byte, min = table.insert, string.byte, math.min
local gsub, ipairs = string.gsub, ipairs
local tonum = {[true] = 0, [false] = 1}

----------------------
--# TEXT FUNCTIONS #--
----------------------
esclib.text = {}
function esclib.text:Multiline(text, font, mWidth, interval)
	local mWidth = mWidth or esclib.scrw
	local interval = interval or 2

	local result = {}
	result.lines = {}

	surface.SetFont(font)
	text = text:gsub("\n"," \\n ")
	local fontw = surface.GetTextSize(text)
	local fonth = draw.GetFontHeight(font)
	
	local buffer = { }

	local maxsize = 0
	for word in string.gmatch(text, "%S+") do
		local temp_text = (string.gsub((table.concat(buffer, " ").." "..word),"\\n","")):Trim()

		local w,h = surface.GetTextSize(temp_text)
		local newline = string.find(word,"\\n")
		if maxsize < w then maxsize = w end
		if (w > mWidth) or (newline) then
			table.insert(result.lines, table.concat(buffer, " "))

			buffer = { }
		end
		if not newline then
			table.insert(buffer, word)
		end
	end

	
	if #buffer > 0 then
		table.insert(result.lines, table.concat(buffer, " "))
	end

	local width = math.min(maxsize,mWidth)
	local height = (#result.lines*fonth)+(interval*#result.lines)


	result.font = font
	result.spacing = fonth+interval
	result.width = width
	result.height = height
	
	return result
end

function esclib.text:MultilineToString(multiline_data)
	return table.concat( multiline_data.lines, "\n" )
end

function esclib.text:DrawMultiline(multiline_data, x, y, color, alignX, alignY)
	for i,line in ipairs(multiline_data.lines) do
		draw.SimpleText(line, multiline_data.font, x, y + (i - 1) * multiline_data.spacing, color, alignX, alignY)
	end
end

function esclib.text:DrawMultilineShadow(multiline_data, x, y, color, alignX, alignY, offsetx)
	local offsetx = offsetx or 1
	for i,line in ipairs(multiline_data.lines) do
		draw.SimpleText(line, multiline_data.font, x+offsetx, y + (i - 1) * multiline_data.spacing+offsetx, color_black, alignX, alignY)
		draw.SimpleText(line, multiline_data.font, x, y + (i - 1) * multiline_data.spacing, color, alignX, alignY)
	end
end

function esclib.text:Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

--example: "[{rank}] {nickname}:", {rank = "hello", nickname = "NickName"}
function esclib.text:KeyFormat(formatString, replacements)
    for key, value in pairs(replacements) do
		value = value:gsub("%%", "%%%%")
        formatString = formatString:gsub("{" .. key .. "}", value)
    end
    return formatString
end

-- Example:
-- local tbl = esclib.text:MatchSplit("<hello>lorem<world> imsulum", "<(.-)>")
-- PrintTable(tbl) =>
-- [1]:
-- 	["matched"]	=	true
-- 	["value"]	=	<hello>
-- [2]:
-- 	["value"]	=	lorem
-- [3]:
-- 	["matched"]	=	true
-- 	["value"]	=	<world>
-- [4]:
-- 	["value"]	=	 imsulum
function esclib.text:MatchSplit(str, pattern)
	if not str then return end
	if not pattern then return end

	--find start pattern
	local startpos, endpos, text = string.find(str, pattern)
	if not startpos then return { {["value"] = str} } end --if pattern not finded

	local result = {}

	while (startpos~=nil) do
		--add not matched text
		local clipped = string.sub(str,1, startpos-1)
		if clipped ~= "" then
			table.insert(result, {["value"] = clipped})
		end

		--add matched text
		table.insert(result, {["matched"] = true, ["value"] = string.sub(str,startpos, endpos)})

		str = string.sub(str, endpos+1) --cut already added text
		startpos, endpos, text = string.find(str, pattern) --find next values
	end

	--add remaining text
	if str ~= "" then
		table.insert(result, {["value"] = str})
	end

	return result
end

--https://github.com/Be1zebub/Small-GLua-Things/blob/dfed7255bf03beb3617e39abe3810266a71887fa/string_search.lua#L8
function esclib.text.distance(str1, str2) -- levenshtein
    local len1, len2 = #str1, #str2
    local char1, char2, distance = {}, {}, {}
    gsub(str1, ".", function (c) insert(char1, byte(c)) end)
    gsub(str2, ".", function (c) insert(char2, byte(c)) end)
    for i = 0, len1 do
        distance[i] = {[0] = i}
    end
    for i = 0, len2 do distance[0][i] = i end
    for i = 1, len1 do
        for j = 1, len2 do
            distance[i][j] = min(
                distance[i-1][j] + 1,
                distance[i][j-1] + 1,
                distance[i-1][j-1] + tonum[char1[i] == char2[j]]
            )
        end
    end
    return distance[len1][len2]
end