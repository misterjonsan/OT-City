local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Homicide"

--\\
MODE.TraitorExpectedAmtBits = 13
--//

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor_SOE = "hmcd_subrole_traitor_soe"
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor_SOE = CreateClientConVar(MODE.ConVarName_SubRole_Traitor_SOE, "traitor_default_soe", true, true, "Выбор роли трейтора в режиме SOE хомисайда")
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_default", true, true, "Выбор роли трейтора в стандартном режиме хомисайда")
end

--; TODO
--; Инженер - шахид бомба + иеды

MODE.SubRoles = {
	--=\\Traitor
	--==\\
	--; https://youtu.be/zP7ux8WsYYI?si=S-Uw2EAehGR5WD3D
	["traitor_default"] = {
		Name = "Defoko",
		Description = [[Default.
Вы долго готовились к этому моменту.
У вас есть различное оружие, яды и взрывчатые вещества, гранаты, а также ваш любимый сверхпрочный нож и оглушающий пистолет с дополнительным магазином, которые помогут вам убивать.]],
		Objective = "У вас в карманах спрятаны предметы, яды, взрывчатка и оружие. Убейте здесь всех.",
		SpawnFunction = function(ply)
			local wep = ply:Give("weapon_glock17")
			
			timer.Simple(1, function()
				wep:ApplyAmmoChanges(2)
			end)
			
			ply:Give("weapon_buck200knife")	
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_shuriken")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_jam")
			-- ply:Give("weapon_traitor_poison2")
			-- ply:Give("weapon_traitor_poison3")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_default_soe"] = {
		Name = "Defoko",
		Description = [[Default.
Вы долго готовились к этому моменту.
У вас есть различное оружие, яды и взрывчатые вещества, гранаты, а также ваш любимый сверхпрочный нож и пистолет с глушителем и дополнительным магазином, которые помогут вам убивать.]],
		Objective = "У вас в карманах спрятаны предметы, яды, взрывчатка и оружие. Убейте здесь всех",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			local p22 = ply:Give("weapon_p22")
			if not IsValid(p22) then return end
			ply:GiveAmmo(p22:GetMaxClip1() * 1, p22:GetPrimaryAmmoType(), true)
			
			hg.AddAttachmentForce(ply, p22, "supressor4")
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			
			ply:SetNetVar("Inventory",inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_infiltrator"] = {
		Name = "Infiltrator",
		Description = [[Может ломать людям шеи сзади.
Может полностью маскироваться под других игроков, если они в регдолле.
Не имеет никакого оружия или инструментов, кроме ножа, адреналина и дымовой гранаты.
Для тех, кто любит стратегии.]],
		Objective = "Ты эксперт по диверсиям. Будь осторожен и убивай одного за другим",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_thaumaturgic_arm")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_infiltrator_soe"] = {
		Name = "Infiltrator",
		Description = [[Может ломать людям шеи сзади.
Может полностью маскироваться под других игроков, если они в костюме тряпичной куклы.
Имеет дымовую гранату, рацию, нож, электрошокер с 2 дополнительными стреляющими насадками и эпипен.
Для тех, кто любит играть в шахматы.]],
		Objective = "Ты эксперт по диверсиям. Будь осторожен и убивай одного за другим",
		SpawnFunction = function(ply)
			local taser = ply:Give("weapon_taser")
			
			ply:GiveAmmo(taser:GetMaxClip1() * 2, taser:GetPrimaryAmmoType(), true)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_zc_fiberwire_standalone")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_thaumaturgic_arm")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	--; СДЕЛАТЬ ЕМУ ЛУТ ДРУГИХ ИГРОКОВ ДАЖЕ ПОКА У НИХ НЕТ ПУШКИ В РУКАХ
	--; Сделать ему вырубание по вагус нерву
	["traitor_assasin"] = {
		Name = "Assasin",
		Description = [[Может быстро обезоруживать людей под любым углом.
Быстрее обезоруживает сзади.
Быстрее обезоруживает спереди, если жертва в регдолле.
Умеет стрелять из огнестрельного оружия.
Обладает дополнительной выносливостью (+80 единиц по сравнению с другими предателями).
Оснащен портативной рацией.
Для тех, кто любит играть быстро.]],
		Objective = "Вы эксперт по оружию и разоружению. Обезоружьте стрелка и используйте его оружие против других",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.8
			ply.organism.stamina.max = 300
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_assasin_soe"] = {
		Name = "Assasin",
		Description = [[Может быстро обезоруживать людей под любым углом.
Быстрее обезоруживает сзади.
Быстрее обезоруживает спереди, если жертва в форме тряпичной куклы.
Умеет стрелять из огнестрельного оружия.
Обладает дополнительной выносливостью (+80 единиц по сравнению с другими предателями).
Оснащен портативной рацией.
Для тех, кто любит играть в шашки.]],
		Objective = "Вы эксперт по оружию и разоружению. Обезоружьте стрелка и используйте его оружие против других",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_zc_fiberwire_standalone")
			ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_walkie_talkie")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.4
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {})
			--inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_chemist"] = {
		Name = "Chemist",
		Description = [[Содержит множество химических веществ, а также адреналин и нож.
В определенной степени устойчив ко всем упомянутым химическим веществам.
Может определять присутствие и действие химических веществ в воздухе.]],
		Objective = "Вы химик, который решил использовать свои знания, чтобы навредить другим. Отравляйте все подряд.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_tranquilizer")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_zc_fiberwire_standalone")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			
			ply:SetNetVar("Inventory", inv)
			MODE.CleanChemicalsOfPlayer(ply)
		end,
	},
	--==//
	-- ["traitor_demoman"] = {
		-- Name = "Demoman",
		-- Description = [[Has many explosives.
-- Can rig certain items with bombs
-- (Radio, certain consumables, etc.)]],
		-- Objective = "You're the ultimate chemist who decided to use knowledge to hurt others.",
		-- SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_hg_pipebomb_tpik")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_traitor_ied")
			-- ply:Give("weapon_walkie_talkie")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		-- end,
	-- },
	["traitor_zombie"] = {
		Name = "Zombie",
		Description = [[Can infect other players silently.
Infected players can be cured by a doctor.
If all players are cured zombie will lose.
Instead of dying will be randomly transported to another infected player's body.
Has no weapons or any tools.
Despite being zombie, still bears appearance of a normal human.]],
		Objective = "You're the zombie. Infect everyone to win. Avoid doctor.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		end,
	},
	--=//
}
--//

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["soe"] = true,
}

MODE.Professions = {
	["doctor"] = {
		Name = "Doctor",
		SpawnFunction = function(ply)	--; TODO MAKE IT WORK
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["huntsman"] = {
		Name = "Huntsman",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["engineer"] = {
		Name = "Engineer",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["cook"] = {
		Name = "Cook",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["builder"] = {
		Name = "Builder",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["exorcist"] = {
		Name = "Exorcist",
		SpawnFunction = function(ply)
			if not IsValid(ply) or not ply:Alive() then return end
			if ply:HasWeapon("weapon_crucifix_guilt") then return end
			ply:Give("weapon_crucifix_guilt")
		end,
	},
}
--//

--\\
--; Названия перменных чуть чуть конченные получились, нужно будет подумать как улучшить
--; ужас
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			["traitor_assasin"] = true,
			--; ОБЪЕДЕНИТЬ ХИМИКА И ДИВЕРСАНТА!!! наверное
			-- ["traitor_demoman"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
			["exorcist"] = {
				Chance = 0.5,
			},
		},
	},
	["soe"] = {
		TraitorDefaultRole = "traitor_default_soe",
		Traitor = {
			["traitor_default_soe"] = true,
			["traitor_infiltrator_soe"] = true,
			-- ["traitor_chemist_soe"] = true,
			["traitor_assasin_soe"] = true,
			-- ["traitor_demoman_soe"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["exorcist"] = {
				Chance = 0.5,
			},
		},
	},
}
--//

MODE.Roles = {}
MODE.Roles.soe = {
	traitor = {
		name = "Предатель",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Невиновный с пушкой",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Невиновный",
		color = Color(0,120,190)
	},
}

MODE.Roles.standard = {
	traitor = {
		objective = "Вы ждали это очень долго. Замочи всех!",
		name = "Маньяк",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Свидетель",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Свидетель",
		color = Color(0,120,190)
	},
}

MODE.Roles.wildwest = {
	traitor = {
		objective = "Замочи всех.",
		name = "Маньяк",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Прохожий с пушкой",
		color = Color(159,85,0)
	},

	innocent = {
		name = "Прохожий с пушкой",
		color = Color(159,85,0)
	},
}

MODE.Roles.gunfreezone = {
	traitor = {
		name = "Маньяк",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Невиновный с пушкой",
		color = Color(0,120,190)
	},

	innocent = {
		name = "Невиновный",
		color = Color(0,120,190)
	},
}

MODE.Roles.supermario = {
	traitor = {
		objective = "You're the evil Mario! Jump around and take down everyone.",
		name = "Traitor Mario",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "You're the hero Mario! Use your jumping ability to stop the traitor.",
		name = "Hero Mario",
		color = Color(158,0,190)
	},

	innocent = {
		objective = "You're a bystander Mario, survive and avoid the traitor's traps!",
		name = "Innocent Mario",
		color = Color(0,120,190)
	},
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end