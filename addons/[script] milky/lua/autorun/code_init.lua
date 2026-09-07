-- include 'cfg.lua'
-- AddCSLuaFile 'cfg.lua'
-- AddCSLuaFile 'milkyLib.lua'
-- include 'milkyLib.lua'

local loader = loader or {}
function loader:IncludeFile(path)
    local file_name = string.Split( path, "/" ) 
          file_name = file_name[#file_name]
    if not file_name then return end
    local CL = file_name:StartWith("cl_")
    local SV = file_name:StartWith("sv_")
    local SH = file_name:StartWith("sh_")
    if not CL and not SV and not SH then SV = true end // any non flag files set to Serverside
    if (SERVER) then
        if (CL or SH) then
            print("ADDCLFILE: ",path)
            AddCSLuaFile(path)
        end
        if (SV or SH) then 
            print("LOAD: ",path)
            include(path)
        end
    elseif (CL or SH) then
        print("LOAD: ",path)
        include(path)
    end
end

function loader:IncludeDirectory(dir)
    local files, folders = file.Find(dir .. "/*", "LUA")
    for _, v in ipairs(files) do 
        self:IncludeFile(dir .. "/" .. v)
    end
    for _, v in ipairs(folders) do 
        self:IncludeDirectory(dir .. "/" .. v)
    end
end

loader:IncludeDirectory("code")