echat = echat or {} -- initialize
echat.EmojiMaterials = echat.EmojiMaterials or {}
echat.Materials = echat.Materials or {}

local errorMat = Material("error")
function echat:GetMaterial(filename)
	return echat.Materials[filename] or errorMat
end

local function load_emojies(load)
	local emoji = {}

	--copy
	local copied_mats = table.Copy(load.Materials)
	table.Empty(load.Materials)

	load:MaterialFolder("materials/echat/emoji",true,false) --path, recurse, share with clients
	esclib:SafeMerge(emoji, load.Materials, true)
	table.Empty(load.Materials)

	--restore
	load.Materials = table.Copy(copied_mats)

	local result = {}
	local count = 0
	for name,mat in pairs(emoji) do
		local sname = string.TrimRight(name,".png")
		sname = string.TrimRight(sname,".jpeg")
		sname = string.TrimRight(sname,".jpg")
		sname = sname or "Unknown"

		result[sname] = mat
		count = count + 1
	end

	load:Print("[echat] Loaded "..count.." emoji")

	esclib:SafeMerge(echat.EmojiMaterials, result, true)
end

local function loader()
	print("[echat loader]")
	--Using esclib loader system

	esclib.loader:New("echat","echat/",function(load)
		--fonts used in addon
		load:Resource("resource/fonts/inter_regular.ttf")
		load:Resource("resource/fonts/robotomono_regular.ttf")

		--In workshop content

		--load all emoji, and clears current materials table (to split them)
		load_emojies(load)

		load:MaterialFolder("materials/echat",false,false) --load.Materials params: path, isrecurse, download
		esclib:SafeMerge(echat.Materials, load.Materials, true)

		--CONFIGS
		load:Shared("config/meta.lua") -- creating addon instance
		load:Shared("config/config.lua")
		load:Shared("config/ingame_config.lua")
		load:Client("config/themes.lua")
		load:Client("config/languages.lua")

		--VGUI
		load:ClientFolder("vgui")

		--MAIN FILES
		load:Shared("core/tools/fonts.lua")
		load:Client("core/tools/module_loader.lua")
		load:Shared("core/tools/parsers_core.lua")
		load:Client("core/tools/auto_complete.lua")
		load:Server("core/tools/server_funcs.lua")
		
		load:Shared("core/parsers.lua")
		load:Client("core/complete_helpers.lua")

		--load all files from modules folder
		load:SharedFolder("core/modules")

		--Main app
		load:Client("core/__core_build__.lua")
		load:Client("core/__core_funcs__.lua")

	end)
end

--lua refresh compat
if esclib && esclib.loader then
	if esclib.loader:IsLoaded("echat") then
		loader()
	end
end

hook.Add("esclib_loaded", "echat_load", function()
	loader()
end)