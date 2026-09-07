if CLIENT then
	concommand.Add("hg_unload_ammo", function(ply, cmd, args)
		local wep = ply:GetActiveWeapon()
		if wep and ishgweapon(wep) and wep:Clip1() > 0 and wep:CanUse() then
			net.Start("unload_ammo")
			net.WriteEntity(wep)
			net.SendToServer()
			wep:SetClip1(0)
			wep.drawBullet = nil
		end
	end)

	concommand.Add("hg_change_ammotype", function(ply, cmd, args)
	    local wep = ply:GetActiveWeapon()
	    local type_ = math.Round(args[1])
	    if wep and ishgweapon(wep) and (wep:Clip1() == 0 or wep.AllwaysChangeAmmo) and wep:CanUse() and wep.AmmoTypes and wep.AmmoTypes[type_] then
	        ply:ChatPrint("Тип боеприпасов изменён на: " .. wep.AmmoTypes[type_][1])
	        net.Start("changeAmmoType")
	        net.WriteEntity(wep)
	        net.WriteInt(type_, 4)
	        net.SendToServer()
	    end
	end)

	net.Receive("unload_ammo",function()
		local wep = net.ReadEntity()

		if wep.Unload then
			wep:Unload()
		end
	end)
else
	util.AddNetworkString("unload_ammo")
	util.AddNetworkString("changeAmmoType")

	net.Receive("unload_ammo", function(len, ply)
		local wep = net.ReadEntity()
        if ply:GetNWFloat("willsuicide", 0) > 0 then return end -- you cant escape.
        wep.drawBullet = nil
        if wep and wep:GetOwner() == ply and ishgweapon(wep) and wep:Clip1() > 0 and wep:CanUse() then
			ply:GiveAmmo(wep:Clip1(), wep:GetPrimaryAmmoType(), true)
			wep:SetClip1(0)
			if wep.Unload then
				wep:Unload()
			end
			net.Start("unload_ammo")
			net.WriteEntity(wep)
			net.Broadcast()
			hg.GetCurrentCharacter(ply):EmitSound("snd_jack_hmcd_ammotake.wav")
		end
	end)

	net.Receive("changeAmmoType", function(len, ply)
	    local wep = net.ReadEntity()
	    local type_ = net.ReadInt(4)
	    if not IsValid(wep) then return end
	    if wep:GetOwner() ~= ply then return end
	    if not ishgweapon(wep) then return end
	    if not wep:CanUse() then return end
	    if not wep.AmmoTypes or not wep.AmmoTypes[type_] then return end
	    if not wep.AllwaysChangeAmmo and wep:Clip1() ~= 0 then return end
	    wep:ApplyAmmoChanges(type_)
	end)
end

if CLIENT then
	local printed

	hg.postures = {
        [0] = "Обычный хват",
        [1] = "Стрельба с бедра",
        [2] = "С левого плеча",
        [3] = "Высокая готовность",
        [4] = "Низкая готовность",
        [5] = "Точечная стрельба",
        [6] = "Стрельба из укрытия",
        [7] = "Гангстерский стиль",
        [8] = "Одной рукой",
        [9] = "Сомалийский стиль",

    }

	concommand.Add("hg_change_posture", function(ply, cmd, args)
		if not args[1] and not isnumber(args[1]) and not printed then print([[Сменить стойку оружия:
0 - Обычный хват  
1 - Стрельба с бедра  
2 - С левого плеча  
3 - Высокая готовность  
4 - Низкая готовность  
5 - Точечная стрельба  
6 - Стрельба из укрытия  
7 - Гангстерская стрельба  
8 - Стрельба одной рукой  
9 - Сомалийская стрельба
]]) printed = true end
		local pos = math.Round(args[1] or -1)
		net.Start("change_posture")
		net.WriteInt(pos, 8)
		net.SendToServer()
	end)

	net.Receive("change_posture", function()
		local ply = net.ReadEntity()
		local pos = net.ReadInt(8)
		
		ply.posture = pos
	end)
else
	util.AddNetworkString("change_posture")
	net.Receive("change_posture", function(len, ply)
		local pos = net.ReadInt(8)

		if (ply.change_posture_cooldown or 0) > CurTime() then return end
		ply.change_posture_cooldown = CurTime() + 0.1

		if pos ~= -1 then 
			if pos == ply.posture then
				ply.posture = 0
				pos = 0
			else
				ply.posture = pos 
			end
		else
			ply.posture = ply.posture or 0
			ply.posture = (ply.posture + 1) >= 9 and 0 or ply.posture + 1
		end
		net.Start("change_posture")
		net.WriteEntity(ply)
		net.WriteInt(ply.posture, 9)
		net.Broadcast()
	end)
end

if SERVER then
	util.AddNetworkString("hg_viewgun")

	concommand.Add("hg_inspect", function(ply, cmd, args)
		local gun = ply:GetActiveWeapon()
		if not IsValid(gun) or not gun or not gun.AllowedInspect then return end
		gun.inspect = CurTime() + 5
		net.Start("hg_viewgun")
		net.WriteEntity(gun)
		net.WriteFloat(gun.inspect)
		net.Broadcast()
	end)
else
	net.Receive("hg_viewgun", function() 
		local ent = net.ReadEntity()
		local time = net.ReadFloat()
		ent.inspect = time
		ent.hudinspect = time
	end)
end

if CLIENT then
	hook.Add("radialOptions", "weapon_manipulations", function()
		local wep = lply:GetActiveWeapon()
		local organism = lply.organism or {}
		
		if !lply:Alive() or !organism or organism.otrub or !organism.canmove then return end
		
		local attmenu = {
			[1] = function()
				RunConsoleCommand("hg_get_attachments", 0)

				return 0
			end,
			[2] = "Меню модификаций"
		}

        if !IsValid(wep) or !ishgweapon(wep) then
			if #hg.GetAttachmentsInv() > 0 then
				hg.radialOptions[#hg.radialOptions + 1] = attmenu
			end

			return
		end
		
        local tbl = {
            [1] = {
                [1] = function(mouseClick)
                    if mouseClick == 1 then
                        RunConsoleCommand("hg_change_posture", -1)
                    else
                        local tbl2 = {}

                        for i, str in pairs(hg.postures) do -- DO. NOT. CHANGE. TO. IPAIRS. kthxbye
                            tbl2[#tbl2 + 1] = {
                                [1] = function()
                                    RunConsoleCommand("hg_change_posture", i)

                                end,
                                [2] = str
                            }
                        end

                        hg.CreateRadialMenu(tbl2)
                    end

                    return -1
                end,
                [2] = "Сменить стойку\n(MOUSE2 для выбора)" 
            },
            [2] = {
                [1] = function()
                    RunConsoleCommand("hg_change_posture", 0)
                end,
                [2] = "Сбросить стойку"
            },
			[3] = attmenu,
        }

        if wep.GetDrum then
            local tbl3 = {function() RunConsoleCommand("hg_rolldrum") end, "Крутить барабан"}
            tbl[#tbl + 1] = tbl3
        
            --if wep:Clip1() > 0 then return end
            --if primaryAmmoCount <= 0 then return end
        
            local drum = wep:GetDrum()
            
            local drum1 = {}
            for i = 1, #drum do
                drum1[i] = "Слот №"..tostring(i)
            end
        
            local tbl4 = {
                function(mouseClick, val)
                    RunConsoleCommand("hg_insertbullet", val)
                end,
                "Загрузить один патрон",
                true,
                drum1
            }
            
            tbl[#tbl + 1] = tbl4
        end

        if wep.AllowedInspect then
            tbl[#tbl + 1] = {
                [1] = function()
                    RunConsoleCommand("hg_inspect")
                end,
                [2] = "Осмотр оружия" 
            }
        end

        if wep:Clip1() > 0 then
            tbl[#tbl + 1] = {
                [1] = function()
                    RunConsoleCommand("hg_unload_ammo", 0)
                end,
                [2] = "Разгрузить" 
            }
        elseif (wep:Clip1() == 0 or wep.AllwaysChangeAmmo) and wep.AmmoTypes and not wep.reload then
            local ammotypes = {}
            
            for k, ammotype in ipairs(wep.AmmoTypes) do
                ammotypes[k] = ammotype[1]
            end 

            tbl[#tbl + 1] = {
                function(mouseClick, chosen)
                    RunConsoleCommand("hg_change_ammotype", chosen) 
                end,
                "Сменить тип патронов",
                true,
                ammotypes
            }
        end

        local laser = wep.attachments and wep.attachments.underbarrel
        if (laser and not table.IsEmpty(laser)) or wep.laser then
			tbl[#tbl + 1] = {
                [1] = function()
                    RunConsoleCommand("hmcd_togglelaser")
                end,
                [2] = "Переключить лазер" 
            }
		end

        hg.radialOptions[#hg.radialOptions + 1] = {
            [1] = function(mouseClick)
                hg.CreateRadialMenu(tbl)

                return -1
            end,
            [2] = "Меню манипуляций с оружием"
        }
    end)
end
