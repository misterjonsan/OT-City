monteract = monteract or {}
  
MsgC(Color(0,200,255), "[_LOADER_] SH INIT:\n" )
local files = file.Find( "stark/sh_side/*", "LUA" )
if #files > 0 then
     for _, file in ipairs( files ) do
           AddCSLuaFile("stark/sh_side/" .. file)

           MsgC(Color(0,200,255), "[_LOADER_] SH: " .. file .. "\n" )

           include( "stark/sh_side/" .. file )
    end
else
    MsgC(Color(255,150,150), "[_LOADER_] SH FAILED\n" )
end


local files = file.Find( "stark/cl_side/*", "LUA" )
        if #files > 0 then
            for _, file in ipairs( files ) do
                MsgC(Color(0,200,255), "[_LOADER_/CSLUAADD] CL: " .. file .. "\n" )
                if SERVER then
                    AddCSLuaFile( "stark/cl_side/" .. file )
                else
                    include( "stark/cl_side/" .. file )
                end
            end
        else
            MsgC(Color(150,255,150), "[_LOADER_/CSLUAADD] FAILED\n" )
        end


if SERVER then  
    MsgC(Color(0,200,255), "[_LOADER_] SV INIT:\n" )
    timer.Simple(1,function() 

        local files = file.Find( "stark/sv_side/*", "LUA" )
        if #files > 0 then
            for _, file in ipairs( files ) do
                timer.Simple(_*0.1,function() 
                    MsgC(Color(0,200,255), "[_LOADER_] SV: " .. file .. "\n" )
                    include( "stark/sv_side/" .. file )
                end)
            end
        else
            MsgC(Color(255,150,150), "[_LOADER_] SV FAILED\n" )
        end
    end)
end

 
if CLIENT then  
    MsgC(Color(0,200,255), "[_LOADER_] CL INIT:\n" )
    //PrintTable(file.Find( "stark/cl_side/*", "LUA" ))
    timer.Simple(1,function() 
        local files = file.Find( "stark/cl_side/*", "LUA" )
        if #files > 0 then
            for _, file in ipairs( files ) do
                timer.Simple(3+_*0.5,function() 
                    MsgC(Color(0,200,255), "[_LOADER_] CL: " .. file .. "\n" )
                    include( "stark/cl_side/" .. file )
                end)
            end
        else
            MsgC(Color(150,255,150), "[_LOADER_] FAILED\n" )
        end
    end)
end