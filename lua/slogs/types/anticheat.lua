SLogs:Msg( Color( 255, 100, 100 ), "MilkyAC", Color( 255, 255, 255 ), " module loaded." )

local MilkyACID = SLogs:GetID( "MilkyAC" )

SLogs:Hook( "MilkyAC", function( name, steamid, length, reason )
    return {
        T = MilkyACID,
        I = 0,
        E = {
            ply1 = tostring( name or "unknown" ),
            sid1 = tostring( steamid or "unknown" ),
            int  = tonumber( length or 0 ) or 0,
            str  = tostring( reason or "unknown" )
        }
    }
end )

SLogs:Hook( "MilkyACKick", function( name, steamid, reason )
    return {
        T = MilkyACID,
        I = 1,
        E = {
            ply1 = tostring( name or "unknown" ),
            sid1 = tostring( steamid or "unknown" ),
            str  = tostring( reason or "unknown" )
        }
    }
end )

SLogs:Hook( "MilkyACNetDetected", function( ply, msg )
    return {
        T = MilkyACID,
        I = 2,
        E = {
            ply1 = SLogs:ValidCall( ply, "GetName" ),
            sid1 = SLogs:ValidCall( ply, "SteamID" ),
            str  = tostring( msg or "unknown" )
        }
    }
end )