esclib.file = {}

local function Split(istring,sep)
	local sep = sep or "%s"
    local t={}
    for str in string.gmatch(istring, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function esclib.file:NameFromPath(path)
    local _, startIndex = path:find("[^/\\]*$")
    if startIndex then
        return path:sub(startIndex)
    end
    return path
end

function esclib.file:MakeIfNotExists(file_name)
	if file.Exists(file_name, "DATA") then return end
	local files = Split(file_name,"/")
	local o_file_name = ""
	if #files > 1 then
		o_file_name = files[1]
		for i=2,#files-1 do
			o_file_name = o_file_name.."/"..files[i]
		end
		file.CreateDir( o_file_name )
		o_file_name = o_file_name.."/"..files[#files]
		file.Write(o_file_name,"")

		return true
	elseif #files == 0 then
		return false
	end
end

function esclib.file:MakeDirectoriesIfNotExists(path)
    if not file.Exists(path, "DATA") then
        local folders = string.Explode("/", path)
        local currentPath = ""

        for _, folder in ipairs(folders) do
            currentPath = currentPath == "" and folder or currentPath .. "/" .. folder

            if not file.Exists(currentPath, "DATA") then
                file.CreateDir(currentPath)
            end
        end

        return true
    end

    return false
end



--EXAMPLE:
-- esclib.file:SaveVar("ehud/savedvars.txt",{["hello"]={"214151","215161664",""}})
-- print(esclib.file:ReadVar("ehud/savedvars.txt","hello"))

function esclib.file:SaveVar(file_name, content, overwrite)
	esclib.file:MakeIfNotExists(file_name)

	local filecontent = {}
	if not overwrite then
		local existing = file.Read(file_name, "DATA")
		if existing then
			filecontent = util.JSONToTable(existing) or {}
		end
	end

	if istable(content) then
		if not overwrite and not table.IsEmpty(filecontent) then
			esclib:SafeMerge(filecontent, content, true)
		else
			filecontent = content
		end
	else
		if overwrite then
			filecontent = {content}
		else
			table.insert(filecontent, content)
		end
	end

	file.Write(file_name, util.TableToJSON(filecontent))
end

function esclib.file:ReadVar(file_name, var)
	local filecontent = file.Read(file_name,"DATA")
	if filecontent then
		local content = util.JSONToTable(filecontent) or {}
		if var then
			return content[var]
		else
			return content
		end
	else
		return
	end
end

function esclib.file:Remove(file_name)
	print("[esclib] Removing file/dir [".. file_name .. "] from DATA folder.")
	file.Delete(file_name)
end

function esclib.file:RemoveFolder(path, recurse)
	if not file.Exists(path, "DATA") then return end
	local files, directories = file.Find( path.."/*", "DATA" )
	
	for _, ffile in ipairs(files) do
		self:Remove(path.."/"..ffile)
	end

	if recurse ~= false then
		for _, fdir in ipairs(directories) do
			self:RemoveFolder(path.."/"..fdir)
			self:Remove(path.."/"..fdir)
		end
	end

	self:Remove(path)
end