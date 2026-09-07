SLogs.Notify = {}
local Notices = {}

local function UpdateNotice( pnl, total_h )

	local x = pnl.fx
	local y = pnl.fy

	local w = pnl:GetWide() + 16
	local h = pnl:GetTall() + 4

	local tox = ScrW()
	local toy = ScrH()
	if IsValid( slogs_frame ) then
		tox = slogs_frame:GetWide( )
		toy = slogs_frame:GetTall( )
	end

	local ideal_x = tox - w - 20
	local ideal_y = toy - 150 - h - total_h

	local timeleft = pnl.StartTime - ( SysTime() - pnl.Length )

	if ( timeleft < 0.7 ) then
		ideal_x = ideal_x - 50
	end
	if ( timeleft < 0.2 ) then
		ideal_x = ideal_x + w * 2
	end

	local spd = RealFrameTime() * 15

	y = y + pnl.VelY * spd
	x = x + pnl.VelX * spd
	local dist = ideal_y - y
	pnl.VelY = pnl.VelY + dist * spd * 1
	if ( math.abs( dist ) < 2 && math.abs( pnl.VelY ) < 0.1 ) then pnl.VelY = 0 end
	dist = ideal_x - x
	pnl.VelX = pnl.VelX + dist * spd * 1
	if ( math.abs( dist ) < 2 && math.abs( pnl.VelX ) < 0.1 ) then pnl.VelX = 0 end
	pnl.VelX = pnl.VelX * ( 0.95 - RealFrameTime() * 8 )
	pnl.VelY = pnl.VelY * ( 0.95 - RealFrameTime() * 8 )
	pnl.fx = x
	pnl.fy = y
	if ( ideal_y > -toy ) then
		pnl:SetPos( pnl.fx, pnl.fy )
	end
	return total_h + h

end

local function Update()

	if ( !Notices ) then return end
	if table.Count( Notices ) == 0 then
		hook.Remove( "Think", "SLogsNotificationThink" )
		return
	end
	local h = 0
	for key, pnl in pairs( Notices ) do
		h = UpdateNotice( pnl, h )
	end
	for k, Panel in pairs( Notices ) do
		if ( !IsValid( Panel ) || Panel:KillSelf() ) then Notices[ k ] = nil end
	end

end

function SLogs.Notify.Add( uid, text )
	hook.Add( "Think", "SLogsNotificationThink", Update )

	if ( IsValid( Notices[ uid ] ) ) then

		Notices[ uid ].StartTime = SysTime()
		Notices[ uid ].Length = 100
		Notices[ uid ]:SetText( text )
		Notices[ uid ]:SetProgress()
		return

	end

	local Panel = vgui.Create( "NoticePanel", parent )
	Panel.StartTime = SysTime()
	Panel.Length = 100
	Panel.VelX = -5
	Panel.VelY = 4
	Panel.fx = ScrW() + 200
	Panel.fy = ScrH()

	Panel.tx = tx
	Panel.ty = ty

	Panel:SetAlpha( 255 )
	Panel:SetText( text )
	Panel:SetPos( Panel.fx, Panel.fy )
	Panel:SetProgress()

	Notices[ uid ] = Panel

end
function SLogs.Notify.Kill( uid )

	if ( !IsValid( Notices[ uid ] ) ) then return end

	Notices[ uid ].StartTime = SysTime()
	Notices[ uid ].Length = 0.8

end

--[[ AddProgress( "lol?", "test" )
timer.Simple(2,function()
	Kill( "lol?" )
end)--]] 