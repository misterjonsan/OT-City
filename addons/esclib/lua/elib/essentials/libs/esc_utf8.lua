--THIS SECTION UNDER DEVELOPMENT IT MAY BE UNACCURATE

esclib.utf8 = esclib.utf8 or {}
eutf8 = esclib.utf8


local function strRelToAbsChar(str, pos)
	if not pos then return 0 end
	pos = pos < 0 and math.max(pos + #str + 1, 0) or pos
	return pos
end

local function getNextByte(str, i)
	local c = string.byte(str, i)
	if c and c > 0 and c <= 127 then
		return 1
	elseif c and c >= 194 and c <= 223 then
		return 2
	elseif c and c >= 224 and c <= 239 then
		return 3
	elseif c and c >= 240 and c <= 244 then
		return 4
	end
	return 1  -- default value if byte value is out of range or i > #str
end

local function getCharSize(str, i)
    local prefix = string.byte(str, i)
    if prefix <= 0x7F then
        return 1
    elseif prefix <= 0xDF then
        return 2
    elseif prefix <= 0xEF then
        return 3
    else
        return 4
    end
end

local function getChar(str, i, size)
    return string.sub(str, i, i + size - 1)
end

function eutf8:reverse(str)
    local chars = {}
    local i = 1
    while i <= #str do
        local size = getCharSize(str, i)
        chars[#chars + 1] = getChar(str, i, size)
        i = i + size
    end
    local buffer = {}
    for i = #chars, 1, -1 do
        buffer[#buffer + 1] = chars[i]
    end
    return table.concat(buffer)
end

function eutf8.getLastWord(str)
    local lastWord = str:match("[%S%p]+$")
    return lastWord
end

function eutf8.sub(s,i,j)
    i = i or 1
    j = j or -1
    if i<1 or j<1 then
       local n = utf8.len(s)
       if not n then return nil end
       if i<0 then i = n+1+i end
       if j<0 then j = n+1+j end
       if i<0 then i = 1 elseif i>n then i = n end
       if j<0 then j = 1 elseif j>n then j = n end
    end
    if j<i then return "" end
    i = utf8.offset(s,i)
    j = utf8.offset(s,j+1)
    if i and j then return s:sub(i,j-1)
       elseif i then return s:sub(i)
       else return ""
    end
end
