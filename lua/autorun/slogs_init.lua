if SERVER then
    AddCSLuaFile( "surface_loading.lua" )
else
    include("surface_loading.lua")
end

SLogs = SLogs or {} 
SLogs.Time = 1587760000 
SLogs.Allowed = {
	"moderator","sponsor","superadmin","youtube","helper","sponsor","moder","admin","eventer","st_eventer","head_eventer","d_kurator","kurator","d_head_admin","head_admin","manager","vice_superadmin"
}
function SLogs:Msg(...)
	MsgC( Color(255,100,100), "[", Color(255,0,0), "SLogs", Color(255,100,100), "] " )
	MsgC( ... )
	Msg( "\n" )
end

function SLogs:ExecFile( name )
	local symbol = name [ 8 ]
	if symbol == "h" then
		if SERVER then
			AddCSLuaFile( "slogs/"..name )
		end
		include( "slogs/"..name )
	elseif symbol == "l" then
		if SERVER then
			AddCSLuaFile( "slogs/"..name )
		else
			include( "slogs/"..name )
		end
	elseif symbol == "v" then
		include( "slogs/"..name )
	else
		if SERVER then
			AddCSLuaFile( "slogs/"..name )
		else
			include( "slogs/"..name )
		end
	end
end

local files = file.Find( "slogs/*.lua", "LUA" )
local preload = {
	"slogs_sh_types.lua",
	"languages/russian.lua",
	"slogs_cl_language.lua",
}

for _, name in SortedPairs( preload ) do
	SLogs:ExecFile( name )
end

for _, name in pairs( files ) do
	if table.HasValue( preload, name ) then continue end
	SLogs:ExecFile( name )
end