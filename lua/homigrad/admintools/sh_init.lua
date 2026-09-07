hg.AdminTools = hg.AdminTools or {}

local plyMeta = FindMetaTable("Player")

ZCTOOLS_LIMITED_GROUPS = {
    ["moderator"] = true,
    ["moder"] = true,
    ["mod"] = true,
    ["operator"] = true,
    ["oper"] = true,
    ["op"] = true,
    ["sponsor"] = true,
    ["spons"] = true
}

function plyMeta:ZCTools_IsModerator()
    local grp = string.lower( self:GetUserGroup() or "" )
    return ZCTOOLS_LIMITED_GROUPS[ grp ] == true
end

function plyMeta:ZCTools_IsLimitedStaff()
    return self:ZCTools_IsModerator()
end

function plyMeta:ZCTools_GetAccess( bSAdmin )
    if bSAdmin and self:IsSuperAdmin() then return true end
    if not bSAdmin then
        if self:IsAdmin() then return true end
        if self:ZCTools_IsLimitedStaff() then return true end
    end
    return false
end

if CLIENT then
    net.Receive("HG_AdminTools",function()
        local func = net.ReadString()
        local args = net.ReadTable()
        if hg.AdminTools[func] then
            hg.AdminTools[func](unpack(args))
        end
    end)

    surface.CreateFont("timer_Font", {
        font = "Banchshift Bold",
        size = 68,
        extended = true,
        weight = 650,
        antialias = true,
        italic = true
    })

    surface.CreateFont("timer_Font1", {
        font = "Banchshift Bold",
        size = 72/3,
        extended = true,
        weight = 650,
        antialias = true,
        italic = true
    })
end

function hg.AdminTools:Notify( str )

end

local w, h = 270,72

local color_black_alpha, color_white = Color(0, 0, 0, 150), Color(255, 255, 255)

function hg.AdminTools:Timer( str, time )
    local FirstTime = 0
    local Text = str
    local Timer = time - CurTime()
    local RTimer = time - CurTime()
    hook.Remove("HUDPaint","HG_AT_Timer")
    hook.Add("HUDPaint","HG_AT_Timer",function()
        FirstTime = LerpFT( 0.2, FirstTime, time > CurTime() - 3 and 1 or 0)
        if time < CurTime() then
            Timer = 0
            if FirstTime < 0.01 then
                hook.Remove("HUDPaint","HG_AT_Timer")
            end
            local beep = math.ceil(math.cos(CurTime() * 12))
            if beep == 0 then
                if not played then
                    surface.PlaySound("buttons/blip1.wav")
                    played = true
                end
                return
            end
            played = false
        else
            Timer = time - CurTime()
        end

        local TDisp = string.FormattedTime( Timer, "%02i:%02i.%02i" )

        local random = 1 - (Timer / RTimer)
        local x, y = math.random() * random * 1, math.random() * random * 2
        local pos = ScrW() - w/1.5
        draw.RoundedBox(0, pos - w / 2 + 10 + x, 30 + y, w, h, ColorAlpha(color_black_alpha,150*FirstTime))
        draw.RoundedBox(0, pos - w / 2 + 10 + x, 30 + y, w * (1 - (Timer / RTimer)), h, Color(150, 50, 40, 150*FirstTime))

        draw.SimpleText(TDisp, "timer_Font", pos + x+4, 30 + y+4, ColorAlpha(color_black_alpha,150*FirstTime), 1)
        draw.SimpleText(TDisp, "timer_Font", pos + x, 30 + y, ColorAlpha(color_white,255*FirstTime), 1)

        draw.RoundedBox(0, pos - w / 2 + 10 + x, 30 + h + y, w, 30, ColorAlpha(color_black_alpha,150*FirstTime))
        draw.SimpleText(Text, "timer_Font1", pos - x + 2, 30 + h + y + 2, ColorAlpha(color_black_alpha,150*FirstTime), 1)
        draw.SimpleText(Text, "timer_Font1", pos - x, 30 + h + y, ColorAlpha(color_white,255*FirstTime), 1)
    end)

end

function hg.AdminTools:Point( str, vec )

end

if not SERVER then return end

util.AddNetworkString("HG_AdminTools")

function hg.AdminTools:SendNet(strFunc,tArgs,entPly)
    net.Start("HG_AdminTools")
    net.WriteString( strFunc )
    net.WriteTable( tArgs )
    if IsValid( entPly ) then
        net.Send( entPly )
    else
        net.Broadcast()
    end
end

function hg.AdminTools:Notify( str )
    hg.AdminTools:SendNet( "Notify", { str } )
end

function hg.AdminTools:Timer( str, time )
    hg.AdminTools:SendNet( "Timer", { str, CurTime() + time } )
end

function hg.AdminTools:Point( str, vec )
    hg.AdminTools:SendNet( "Point", { str, vec } )
end

concommand.Add("hg_timer",function( ply, _, args )
    if not ply:IsAdmin() then return end
    hg.AdminTools:Timer( args[2], args[1] )
end)
