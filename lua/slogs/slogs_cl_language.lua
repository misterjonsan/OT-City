SLogs.CurrentLanguage = "English"

SLogs.Colors = {
	LogMarkup = {
		ply = Color(100, 255, 100),
		str = Color(255, 100, 100),
		int = Color(255, 102, 0),
		fine = Color(255, 100, 100),
		wep = Color(0, 150, 255),
		time = Color(100, 100, 255),
		other = Color(100, 0, 0),

		weps = "wep",
		plys = "ply",
	}
}

local Decompress
Decompress = {
	wep = function(class)
		local tbl = weapons.Get(class)
		if not tbl or not tbl.PrintName then return class end
		return tbl.PrintName
	end,
	time = function(time)
		time = tonumber(time)
		if not time then
			return "<unknown date>"
		end
		if time == 0 then
			return "навсегда"
		else
			return os.date("%d/%m/%y %H:%M", SLogs.Time + time)
		end
	end,
	weps = function(compressedArray)
		local result = ""
		for k, class in pairs(string.Split(compressedArray or "", "<>")) do
			if class ~= "" then
				result = result .. (result == "" and "" or ", ") .. Decompress.wep(class)
			end
		end
		return result
	end,
	plys = function(plys)
		return plys
	end
}

if FineSystemConfig then
	local FineSystemLaws = FineSystemConfig.Laws

	local function FineTranslate(FineString)
		local CReason
		if string.find(FineString, "<>") then
			CReason = string.match(FineString, "<>(.-)<>")
			FineString = string.gsub(FineString, "^<>.-<>", "")
		end

		local SectionString = string.Explode(":", FineString)
		local Result = ""

		for k, v in pairs(SectionString) do
			if v ~= "" then
				local splitAgain = string.Explode(".", v)
				for i = 1, #splitAgain do
					local ID = tonumber(splitAgain[i])
					if not ID then return end
					if FineSystemLaws[k] and FineSystemLaws[k][2] and FineSystemLaws[k][2][ID] and FineSystemLaws[k][2][ID][1] then
						Result = Result .. "\n" .. FineSystemLaws[k][2][ID][1]
					end
				end
			end
		end

		if CReason then
			Result = Result .. "\n" .. CReason
		end

		return Result
	end

	Decompress.fine = function(str)
		return FineTranslate(str)
	end
end

function SLogs:InitLanguage(Language)
	if not Language then return end

	Language = string.lower(Language)

	if string.lower(self.CurrentLanguage or "") == Language and istable(self.Dictionary) then
		return
	end

	self.Dictionary = self.Dictionary or {}

	include(("slogs/languages/%s.lua"):format(Language))

	self.Dictionary = self.Dictionary or {}
	self.CurrentLanguage = Language
end

SLogs:InitLanguage("russian")

local function GetHighlightColor(Type)
	local colors = SLogs.Colors.LogMarkup

	if isstring(colors[Type]) then
		Type = colors[Type]
	end

	return colors[Type] or colors["other"]
end

local function Highlight(Tbl, Info, Colorful, TextColor, Time)
	TextColor = TextColor or Color(255, 255, 255)

	local result = {}
	local need_color = false

	if Time then
		table.Add(result, {TextColor, "[", SLogs.Colors.LogMarkup.time, os.date("%H:%M", SLogs.Time + Time), TextColor, "] "})
	end

	for _, str in pairs(Tbl) do
		local find = str:match("^{(.-)}$")

		if find then
			if Colorful then
				local dtype = find:match("^(.-)%d?$")
				local color = GetHighlightColor(dtype)

				if not color then
					color = TextColor
				end

				table.insert(result, color)
				need_color = false
			end

			local result_str = Info and Info[find] or nil

			local DecompressFunction = Decompress[find]
			if DecompressFunction then
				result_str = DecompressFunction(result_str)
			end

			table.insert(result, result_str or "{error}")
		else
			if Colorful then
				if not need_color then
					table.insert(result, TextColor)
					need_color = true
				else
					need_color = false
				end
			end

			table.insert(result, str)
		end
	end

	return Colorful and result or table.concat(result)
end

function SLogs:Translate(Category, ID, ID2, Info, Colorful, TextColor, Time)
	local dictionary = self.Dictionary
	if not istable(dictionary) then
		return Colorful and {TextColor or Color(255, 255, 255), "{error}"} or "{error}"
	end

	local error_value = dictionary[404] or "{error}"

	if Category then
		dictionary = dictionary[Category]
		if not istable(dictionary) then return error_value end
	end

	dictionary = dictionary[ID]
	if dictionary == nil then return error_value end

	if ID2 ~= nil then
		if not istable(dictionary) then return error_value end
		dictionary = dictionary[ID2]
		if dictionary == nil then return error_value end
	end

	if isfunction(dictionary) then
		return dictionary(Info, Colorful, TextColor)
	elseif isstring(dictionary) then
		if Info then
			return dictionary:format(unpack(istable(Info) and Info or {Info}))
		end
		return dictionary
	elseif istable(dictionary) then
		return Highlight(dictionary, Info or {}, Colorful, TextColor, Time) or {error_value}
	else
		return error_value
	end
end