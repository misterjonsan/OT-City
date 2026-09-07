if vFireInstalled then
	sam.command.set_category("VFire") 

	sam.command.new("vextinguish all")
		:SetPermission("vextinguish_all", "superadmin") 

		:DisallowConsole() 

		:SetCategory("VFire") 

		:Help("Потушить весь огонь")

		:MenuHide(false) 
		:DisableNotify(true) 
		
		:OnExecute(function(calling_ply)
			local removeCount = 0
			for k, v in pairs(ents.FindByClass("vfire")) do
				v:Remove()
				removeCount = removeCount + 1
			end

		sam.player.send_message(nil, "Админ {A} потушил {V} огонь", {
			A = calling_ply, V = removeCount
		})
	end)
	:End()

	sam.command.new("vextinguish")
		:SetPermission("vextinguish", "superadmin") 

		:DisallowConsole() 

		:SetCategory("VFire") 

		:Help("Потушить все огни, на которые смотрит игрок.")

		:MenuHide(false) 
		:DisableNotify(true) 
		
		:OnExecute(function(calling_ply)
			local lookedAt = ents.FindInCone(calling_ply:EyePos(), calling_ply:EyeAngles():Forward(), 30000, 0.9)
			local removeCount = 0
			for k, v in pairs(lookedAt) do
				local class = v:GetClass()
				if class == "vfire" or class == "vfire_ball" then
					v:Remove()
					removeCount = removeCount + 1
				end
			end

			sam.player.send_message(nil, "Админ {A} потушил {V} огонь", {
				A = calling_ply, V = removeCount
			})
		end)
	:End()

	sam.command.new("vstartfire")
		:SetPermission("vstartfire", "superadmin") 

		:DisallowConsole() 

		:SetCategory("VFire") 

		:Help("Разжечь костры")

		:AddArg("number", {
			optional = true, 
			default = 30, 
			hint = "size", 
			min = 1, 
			round = true, 
		})

		:MenuHide(false) 
		:DisableNotify(true) 
		
		:OnExecute(function(calling_ply, size)
			local tr = calling_ply:GetEyeTrace()
			local life = size
			local feedCarry = size
			local pos = tr.HitPos - tr.Normal * 250
			local vel = tr.Normal * 1000
			local owner = calling_ply
			CreateVFireBall(life, feedCarry, pos, vel, owner)

		sam.player.send_message(nil, "Админ {A} разжёг {V} большой огонь", {
			A = calling_ply, V = size
		})
		end)
	:End()
end