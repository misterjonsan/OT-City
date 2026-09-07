if SERVER then return end
local mat_circle = Material("vgui/circle")
function surface.Loading( type, tbl )

	local x,y 			= tbl.x or 0, tbl.y or 0
	local scale,radius 	= tbl.scale or 100, tbl.radius or 10
	local circles,speed = tbl.circles or 5, tbl.speed or 1
	local dist 			= tbl.dist or 60 
	local stop 			= tbl.stop

	scale = scale/2

	surface.SetMaterial(mat_circle)

	local time = RealTime()

	if type == "Circle" then

		for i=1,circles do

			local a = math.rad( i / circles + time * speed ) * dist

			local sin = math.sin( a ) * scale
			local cos = math.cos( a ) * scale

			local x2, y2 = x + cos - radius/2, y + sin - radius/2

			if stop then
			
				if CurTime() > stop then

					if i == circles then continue end
					if !tbl.stop_tbl[ i ] then
						tbl.stop_tbl[ i ] = { x = x2, y = y2 }
					end

					x2 = Lerp( 0.03, tbl.stop_tbl[ i ].x, x + ( circles / 2 - i ) * scale / 11 / 1.4 - radius/2 )
					y2 = Lerp( 0.03, tbl.stop_tbl[ i ].y, y - math.abs( i - circles / 2 ) * scale / 11 + (circles-1)/4  * scale / 10 )

					tbl.stop_tbl[ i ] = { x = x2, y = y2 }

				end

			end

			surface.DrawTexturedRect( x2, y2, radius, radius )

		end

	elseif type == "Infinity" then

		for i=1,circles do

			local a = math.rad( i / circles + time * speed ) * dist

			local sin = math.sin( a * 2 ) * scale
			local cos = math.cos( a ) * scale

			surface.DrawTexturedRect( x + cos - radius/2, y + sin / 2 - radius/2, radius, radius )

		end

	elseif type == "Unknown" then

		for i=1,circles do

			local a = math.rad( i / circles + time * speed ) * dist
			local a2 = math.rad( i / circles / 2 + time * speed ) * dist

			local sin = math.sin( a ) * scale
			local cos = math.cos( a2 ) * scale

			surface.DrawTexturedRect( x + cos - radius/2, y + sin / 2 - radius/2, radius, radius )

		end

	elseif type == "X" then

		for i=1,circles do

			local a = math.rad( i / circles + time * speed ) * dist

			local sin = math.sin( a ) * scale
			local tan = math.tan( a ) * scale

			surface.DrawTexturedRect( x + math.Clamp( tan, -scale, scale ) - radius/2, y + sin - radius/2, radius, radius )
		end
	end
end