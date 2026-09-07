local esclib = esclib
local server_clr = Color( 136, 221, 255 )
local client_clr = Color( 255, 221, 102, 255 )
local title_clr = Color(88, 209, 187)

esclib.loader = esclib.loader or {}
esclib.loader.addons = esclib.loader.addons or {}


---------------------------
--# MATERIAL DOWNLOADER #--
---------------------------
--thanks to https://github.com/Be1zebub/Small-GLua-Things/blob/master/sh_material_downloader.lua

local file, Material, Fetch, find = file, Material, http.Fetch, string.find

if CLIENT then
	local DOWNLOAD_PATH = "esclib_download"
	local errorMat = Material("error")
	esclib.WebImageCache = esclib.WebImageCache or {}
	function esclib:DownloadMaterial(url, file_path, file_name, on_succ, on_err, retry_count)
		if not url then return end

		if esclib.WebImageCache[url] then 
			print("[esclib][MaterialDownloader] - Using chached material")
			if esclib.WebImageCache[url]:IsError() then
				on_err("Material isn't loaded properly. Maybe broken?")
				return false
			end
			on_succ(esclib.WebImageCache[url])
			return true
		end

		local folder = DOWNLOAD_PATH .. "/" .. file_path
		local path = folder .. "/" .. file_name
		esclib.file:MakeDirectoriesIfNotExists(folder)
		local data_path = "data/" .. path
		
		if file.Exists(path, "DATA") then
			print("[esclib][MaterialDownloader] - Material already exists. Using it")
			esclib.WebImageCache[url] = Material(data_path, "smooth")
			on_succ(esclib.WebImageCache[url])
		else
			Fetch(url, function(img)
				if img == nil or find(string.lower(img), "<!doctype html>", 1, true) then 
					print("[esclib][MaterialDownloader] - FAILED TO DOWNLOAD MATERIAL. URL: "..url)
					on_err("Bad url or not found image on it. Maybe link isn't direct?")
					return
				end

				file.Write(path, img)
				esclib.WebImageCache[url] = Material(data_path, "smooth")
				if esclib.WebImageCache[url]:IsError() then
					on_err("Downloaded material is broken.")
					print("[esclib][MaterialDownloader] Deleting bad downloaded file")
					file.Delete(path)
					return false
				end
				on_succ(esclib.WebImageCache[url])
			end, function(errMsg)
				if retry_count and retry_count > 0 then
					retry_count = retry_count - 1
					esclib:DownloadMaterial(url, path, on_succ, retry_count)
				else
					errMsg = errMsg or ""
					print("[esclib][MaterialDownloader] - BAD URL / PROBLEMS WITH INTERNET. URL: "..url.. " Response data: "..errMsg)
					on_err("Failed to download - "..errMsg)
				end
			end)
		end
	end

	function esclib:ClearDownloadCache(path)
		path = path or ""
		if path ~= "" then path = "/"..path end
		self.file:RemoveFolder(DOWNLOAD_PATH..path)
		table.Empty(esclib.WebImageCache)
	end

	concommand.Add("esclib_clear_cache", function()
		esclib:ClearDownloadCache()
	end)
end

--example
-- esclib:DownloadMaterial("https://i.imgur.com/Msmeqkq.png", "echat", "mat.png", function(mat)
--     local w, h = 128, 128
-- 	print(mat)
-- end)


local LOADER_META = {}
LOADER_META.__index = LOADER_META
function LOADER_META:Print(...)
	MsgC(Color(13, 255, 51), "[•] ", color_white, unpack({...}))
	MsgC("\n")
	-- print(msg)
end

function LOADER_META:Client(path)
	if (CLIENT) then include(self.dpath .. path) end
	if (SERVER) then
		self:Print(client_clr, "[CL] ", color_white, self.dpath..path)
		AddCSLuaFile(self.dpath .. path)
	end
end

function LOADER_META:ClientFolder(name,recurse)
	local files, folders = file.Find(self.dpath .. name .. "/*", "LUA")
	for k, fname in ipairs(files) do
		self:Client(name.."/"..fname)
	end
	if recurse then
		for _, fname in ipairs(folders) do
            self:ClientFolder(name .."/".. fname, recurse)
        end
    end
end

function LOADER_META:Server(path)
	if (SERVER) then
		self:Print(server_clr, "[SV] ", color_white, self.dpath..path)
		include(self.dpath .. path)
	end
end

function LOADER_META:ServerFolder(name,recurse)
	local files, folders = file.Find(self.dpath .. name .. "/*", "LUA")
	for k, fname in ipairs(files) do
		self:Server(name.."/"..fname)
	end
	if recurse then
		for _, fname in ipairs(folders) do
            self:ServerFolder(name .."/".. fname, recurse)
        end
    end
end

function LOADER_META:Shared(path)
	self:Client(path)
	self:Server(path)
end

function LOADER_META:SharedFolder(name,recurse)
	local files, folders = file.Find(self.dpath .. name .. "/*", "LUA")
	for k, fname in ipairs(files) do
		self:Shared(name.."/"..fname)
	end
	if recurse then
		for _, fname in ipairs(folders) do
            self:SharedFolder(name .."/".. fname, recurse)
        end
    end
end

function LOADER_META:Resource(fullpath)
	if (SERVER) then
		self:Print(server_clr, "[Resource] ", color_white, fullpath)
		resource.AddFile(fullpath)
	end
end

function LOADER_META:ResourceFolder(fullpath, recurse)
    local files, folders = file.Find(fullpath .."/*", "GAME")

    for _, fname in ipairs(files) do
        self:Resource(fullpath .."/".. fname)
    end

    if recurse then
        for _, fname in ipairs(folders) do
            self:ResourceFolder(fullpath .."/".. fname, recurse)
        end
    end
end

function LOADER_META:Material(fullpath, name, download)
	if (SERVER) and (download) then
		--add to load
		self:Print(server_clr, "[Material] ", color_white, fullpath)
		resource.AddFile(fullpath)
	end

	--yes on sv too
	local mat = Material(fullpath,"smooth")
	if name then
		self.Materials[name] = mat
	else
		table.insert(self.Materials, mat)
	end
	return mat
end

function LOADER_META:GetMaterials()
	return self.Materials or {}
end

function LOADER_META:MaterialFolder(fullpath, recurse, download)
    local files, folders = file.Find(fullpath .."/*", "GAME")

    for _, fname in ipairs(files) do
        self:Material(fullpath .."/".. fname, fname, download)
    end

    if recurse then
        for _, fname in ipairs(folders) do
            self:MaterialFolder(fullpath .."/".. fname, recurse, download)
        end
    end
end

function LOADER_META:MaterialUrl(name, url)
	if (CLIENT) then
		self:Print("Downloading material: ( ".. self.dpath .. name.." ) Retries: 2")
		esclib:DownloadMaterial(url, self.dpath, name, function(mat)

			if IsValid(mat) then
				self.Materials[name] = mat
				self:Print("Downloading succesuful")
			else
				self:Print("Downloading failed...")
			end
		end) --after 2 retries stop
	end
end




function esclib.loader:New(uid, path, callback)
	-- Validate required params
	if not uid or not path or not callback then return end
	
	-- Handle optional path param
	if isfunction(path) then
		callback = path
		path = ""
	end

	-- Create addon data
	local addon_data = {
		Materials = {},
		dpath = path,
		Load = function(add)
			add.finished = false
			callback(add)
			add.finished = true
		end
	}

	-- Update existing or create new
	self.addons[uid] = addon_data
	setmetatable(self.addons[uid], LOADER_META)
end

function esclib.loader:LoadAllAddons()
	for uid,addon in pairs(self.addons) do
		if (SERVER) then MsgC(title_clr, "\n["..(uid).."] Loading started...\n") end
		if hook.Run("esclib.should_load_addon", uid, addon) ~= nil then continue end
		addon:Load()
		if (SERVER) then MsgC(title_clr, "["..(uid).."] Loading finished!\n") end
	end
end

function esclib.loader:IsLoaded(addon_name)
	if esclib.loader.addons[addon_name] then
		return esclib.loader.addons[addon_name].finished
	end
end

-- esclib.loader:New("ehud","ehud/",function(load)
-- 	-- PrintTable(loader)
-- 	load:Client("config/ehud_config.lua")
-- end)

-- esclib.loader:LoadAllAddons()