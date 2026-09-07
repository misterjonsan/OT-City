local floor = math.floor

--Register font here

echat.font = "Inter" --name from font file
echat.monofont = "Roboto Mono" --name from font file

local current_fontname = "echat"
echat.fonts = echat.fonts or {}
echat.font_exist = echat.font_exist or {}

function echat:GetFonts()
    return echat.fonts
end

local function register_fontname(name)
    if CLIENT then esclib:SetFontName(name) end
    current_fontname = name
end

local function register_font(size, weight)
    if CLIENT then esclib:Font(size,weight) end --register font on client. Font will not be registered if exists
    local name = "es_"..current_fontname.."_"..size.."_"..weight
    if not echat.font_exist[name] then
        table.insert(echat.fonts, name)
        echat.font_exist[name] = true
    end
    return name
end

local function set_font(name) --does nothing on server
    if CLIENT then return esclib:SetFont(name) end
end

function echat:AdaptiveSize(base_size, screen_base)
	local base_size = base_size or 18
	local base_scrh = screen_base or 1080
	local dif = ScrH() / base_scrh

	return floor(base_size * dif)+1
end

function echat:AdaptiveFont(name, base_size, weight)
    register_fontname(name)
    set_font(echat.font)
    return register_font(echat:AdaptiveSize(base_size), weight)
end

function echat:AdaptiveMonoFont(name, base_size, weight)
    register_fontname(name)
    set_font(echat.monofont)
    return register_font(echat:AdaptiveSize(base_size), weight)
end

-------------
--- FONTS ---
-------------
--static fonts for <font> modifier
register_fontname("echat")
set_font(echat.font)
register_font(12,500) --"es_echat_12_500"
register_font(14,500)
register_font(16,500)
register_font(18,500)
register_font(20,500)
register_font(30,500)

register_fontname("echatmono")
set_font(echat.monofont)
register_font(12,500) --"es_echatmono_12_500"
register_font(14,500)
register_font(16,500)
register_font(18,500)
register_font(20,500)
register_font(30,500)