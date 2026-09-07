----------------------------
--# MESSAGE SEND TO CHAT #--
----------------------------
local netstream = esclib.netstream
if SERVER then
    local PLAYER_META = FindMetaTable("Player")
    function PLAYER_META:EsclibChatPrint(...)
        netstream.Start(self, "esclib.message", ...)
    end
else --CLIENT
    netstream.Hook("esclib.message", function(...)
		chat.AddText(...)
	end)
end


--https://github.com/Be1zebub/Small-GLua-Things/blob/master/printtable_v2.lua

local white = Color( 230, 230, 230 )
local red = Color( 212, 53, 109 )
local yellow = Color( 212, 202, 107 )
local purple = Color( 157, 110, 212 )
local cyan = Color( 102, 217, 239 )
local dark = Color( 105, 105, 105 )

local IsValidKeyName

do
	local reserved = { [ "and" ] = true, [ "break" ] = true, [ "do" ] = true, [ "else" ] = true, [ "elseif" ] = true, [ "end" ] = true, [ "false" ] = true, [ "for" ] = true, [ "function" ] = true, [ "if" ] = true, [ "in" ] = true, [ "local" ] = true, [ "nil" ] = true, [ "not" ] = true, [ "or" ] = true, [ "repeat" ] = true, [ "return" ] = true, [ "then" ] = true, [ "true" ] = true, [ "until" ] = true, [ "while" ] = true}

	function IsValidKeyName( key ) -- localized before
		-- name cant be reserved word
		if reserved[ key ] then return false end

		-- it should start with letters or underscore, It should continue with alphanumerics
		if ( key:match( "^[%a_][%w_]*$" ) == nil ) then return false end

		return true
	end
end

local MsgC = MsgC

if SERVER and system.IsLinux() then
	function MsgC( ... ) -- GMODSTORE CODECHECK: LOCALIZED BEFORE -- polyfill to make MsgC works in linux srcds
		for _, v in ipairs( { ... } ) do
			if ( IsColor( v ) ) then
				Msg( string.format( "\27[38;2;%d;%d;%dm", v.r, v.g, v.b ) )
			else
				Msg( v )
			end
		end

		Msg("\27[0m")
	end
end

local function Round( num )
	return math.Round( num, 3 )
end

local gmodObjects = {}

function gmodObjects.Player( v )
	MsgC( cyan, "Player", white, "( ", purple, v:UserID(), white, " )" )
end

function gmodObjects.Entity( v )
	MsgC( cyan, "Entity", white, "( ", purple, v:EntIndex(), white, " )" )
end

local gmodAxisObjects = { Vector = true, Angle = true }

local function MsgValue( v )
	if isstring( v ) then
		if v:find( "\n", 1, true ) then
			MsgC( yellow, "[[", v, "]]" )
		else
			MsgC( yellow, "\"", v, "\"" )
		end
	elseif IsColor( v ) then
		MsgC(
			cyan, "Color", white, "( ",
			purple, v.r, red, ", ",
			purple, v.g, red, ", ",
			purple, v.b
		)

		if v.a ~= 255 then
			MsgC(
				red, ", ",
				purple, v.a
			)
		end

		MsgC( white, " )" )
	elseif gmodObjects[ type( v ) ] then
		gmodObjects[ type( v ) ]( v )
	elseif gmodAxisObjects[ type( v ) ] then
		MsgC(
			cyan, type( v ), white, "( ",
			purple, Round( v[ 1 ] )
		)

		if v[ 2 ] ~= 0 then
			MsgC( red, ", ", purple, Round( v[ 2 ] ) )
		end

		if v[ 3 ] ~= 0 then
			MsgC( red, ", ", purple, Round( v[ 3 ] ) )
		end

		MsgC( white, " )" )
	elseif isfunction( v ) then
		local info = debug.getinfo( v )
		local defined = info.linedefined == info.lastlinedefined and info.linedefined or info.linedefined .. "-" .. info.lastlinedefined

		MsgC( purple, v, dark, " --[[ ", info.short_src, ":", defined, " ]]" )
	else
		MsgC( purple, v )
	end
end

local function MsgKey( indent, k )
	if ( isstring( k ) == false ) then
		MsgC( indent, red, "[ " )
		MsgValue( k )
		MsgC( red, " ] = " )
	elseif ( IsValidKeyName( k ) ) then
		MsgC( indent, white, k, red, " = " )
	else
		MsgC( indent, red, "[ ", yellow, "\"", k, yellow, "\"", red, " ] = " )
	end
end

function esclib:PrintTable( tbl, lvl, already )
	already = already or { [ tbl ] = true }
	lvl = lvl or 1

	local len = 0
	for _ in pairs( tbl ) do
		len = len + 1
	end

	if ( len == 0 ) then
		return MsgC( red, "{}" )
	end

	local isSeq = len == #tbl
	local not_isSeq = not isSeq

	if ( not_isSeq ) then
		local new = {}
		local index = 0

		for k, v in pairs( tbl ) do
			index = index + 1
			new[ index ] = { k = k, v = v }
		end

		table.sort( new, function( a, b )
			if ( isnumber( a.k ) and isnumber( b.k ) ) then
				return a.k < b.k
			end

			return tostring( a.k ) < tostring( b.k )
		end )

		tbl = new
	end

	local iter = isSeq and ipairs or pairs
	local indent = string.rep( "  ", lvl )
	local table_indent = string.rep( "  ", lvl - 1 )
	local i = 1

	MsgC( red, "{\n" )

	for k, v in iter( tbl ) do
		if ( isSeq ) then
			Msg( indent )
		else
			k, v = v.k, v.v
			MsgKey( indent, k )
		end

		if ( istable( v ) and IsColor( v ) == false ) then
			if already[ v ] then
				MsgC( purple, tostring( v ) )
			else
				already[ v ] = true
				esclib:PrintTable( v, lvl + 1, already )
			end
		else
			MsgValue( v )
		end

		if i == len then
			Msg( "\n" )
		else
			MsgC( red, ",\n" )
		end

		i = i + 1
	end

	MsgC( table_indent, red, "}" )

	if ( lvl == 1 ) then Msg( "\n" ) end
end






-------------------------
--# LOGGING FUNCTIONS #--
-------------------------
local log_invitation_clr = Color(170,170,170)
local log_client_color = Color(255,181,20)
local log_server_color = Color(20,188,255)
function esclib.print(...)
	local message = {...}
	if #message == 1 then
		message = message[1]
	end

    local info = debug.getinfo(2, "Sl")
    local source = info and info.source or ""
    local filename = source:match("@(.-)$") or source
	filename = string.TrimLeft(filename, "addons/")
    local line = info and info.currentline or -1

    local prefix = "["..(CLIENT and "CL" or "SV") .. "|DEBUG] "
    local location = string.format("[%s L%s]:\n> ",
        filename,
        line
    )

    local content = tostring(message)
    local msg_istable = type(message) == "table"
    if msg_istable then
        content = ""
    end

    MsgC(
        CLIENT and log_client_color or log_server_color,
        prefix,
        log_invitation_clr,
        location,
        CLIENT and log_client_color or log_server_color,
        content .. "\n"
    )

    if msg_istable then
        esclib:PrintTable(message)
    end
end