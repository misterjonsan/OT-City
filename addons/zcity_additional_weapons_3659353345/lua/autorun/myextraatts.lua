-- МОИ ДОПОЛНИТЕЛЬНЫЕ ОБВЕСЫ ДЛЯ ZCITY
-- Файл: addons/my_attachments/lua/autorun/sh_my_attachments.lua

-- Проверяем, существует ли основная таблица
if not hg then hg = {} end
if not hg.attachments then hg.attachments = {} end

-- #####################################################################
-- ####################   ТВОИ НОВЫЕ ОБВЕСЫ   #########################
-- #####################################################################

-- Добавляем в существующие категории (или создаем, если их нет)
hg.attachments.sight = hg.attachments.sight or {}
hg.attachments.barrel = hg.attachments.barrel or {}
hg.attachments.underbarrel = hg.attachments.underbarrel or {}
hg.attachments.grip = hg.attachments.grip or {}
hg.attachments.mount = hg.attachments.mount or {}

-- ===================== НОВЫЙ ПРИЦЕЛ =====================
hg.attachments.sight["ironsight5"] = {
    "sight",
    "models/weapons/arc9_eft_shared/atts/ironsight/eft_rearsight_mbus.mdl",
    Angle(0, 0, -90),
    {},  -- <- подматериалы должны быть на этом месте!
    offset = Vector(-3, 0.2, 0),
    offsetView = Vector(-1.4, 0, 12),
    mountType = "ironsight",
    PhysModel = "models/hunter/plates/plate025.mdl",
    PhysPos = Vector(1, 0, 0),
    PhysAng = Angle(0, 90, 0),
    mount = "models/weapons/arc9_eft_shared/atts/ironsight/eft_frontsight_mbus.mdl",
    mountVec = Vector(15.5, 0, 0),
    mountAng = Angle(0, 180, 0),
    valid = true,
}

hg.attachments.sight["optic14"] = {
    "sight",
	"models/weapons/atts/1p59/kmz_1p59eyecup.mdl",
	Angle(0, 0, -90),
	offset = Vector(3, 1.9, -0.03),
	offsetView = Vector(0, 0, 14),
	{},
	mountType = "picatinny",
	scopemat = Material("decals/scope.png"),
	mat = Material("effects/arc9/rt"),
	perekrestie = Material("vgui/reticles/1p59_3-10x_mark_red_f.png"),
	localScopePos = Vector(0, 0, 0),
	scope_blackout = 3400,
	rot = 0,
	FOVMin = 2,
	FOVMax = 11,
	FOVScoped = 40,
	blackoutsize = 4200,
	sizeperekrestie = 3200,
	perekrestieSize = false,
	mountVec = Vector(-1.8, 0, -1.5),
	mountAng = Angle(0, 0, 0),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(1, 0, 0),
	PhysAng = Angle(0, 90, 0),

	drawFunction = function(self,model) -- in swep:drawattachment
	end,

	sightFunction = function(self)
		self:DoRT()
	end,

	transformFunction = function(self,model,vecadd,ang) -- in transformfunction
	end,
	valid = true,
}

hg.attachments.sight["optic15"] = {
    "sight",
	"models/weapons/atts/1p59/kmz_1p59.mdl",
	Angle(0, 0, -90),
	offset = Vector(3, 1.9, -0.03),
	offsetView = Vector(0, 0, 12),
	{},
	mountType = "picatinny",
	scopemat = Material("decals/scope.png"),
	mat = Material("effects/arc9/rt"),
	perekrestie = Material("vgui/reticles/1p59_3-10x_mark_red_f.png"),
	localScopePos = Vector(0, 0, 0),
	scope_blackout = 3400,
	rot = 0,
	FOVMin = 2,
	FOVMax = 11,
	FOVScoped = 40,
	blackoutsize = 4200,
	sizeperekrestie = 3200,
	perekrestieSize = false,
	mountVec = Vector(-1.8, 0, -1.5),
	mountAng = Angle(0, 0, 0),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(1, 0, 0),
	PhysAng = Angle(0, 90, 0),

	drawFunction = function(self,model) -- in swep:drawattachment
	end,

	sightFunction = function(self)
		self:DoRT()
	end,

	transformFunction = function(self,model,vecadd,ang) -- in transformfunction
	end,
	valid = true,
}

hg.attachments.sight["optic16"] = {
	"sight",
	"models/weapons/atts/sb_pm12x50/scope_sb_pm_ii_3_12x50_blk.mdl",
	Angle(0, 0, -90),
	offset = Vector(0.5, 1.5, -0.03),
	offsetView = Vector(0, 0, 12),
	{},
	mountType = "picatinny",
	scopemat = Material("decals/scope.png"),
	mat = Material("effects/arc9/rt"),
	perekrestie = Material("vgui/reticles/sb_pm_ii_3-12x50_mark_q.png"),
	localScopePos = Vector(0, 0, 0),
	scope_blackout = 3400,
	rot = 0,
	FOVMin = 2,
	FOVMax = 13,
	FOVScoped = 40,
	blackoutsize = 5000,
	sizeperekrestie = 2400,
	perekrestieSize = false,
	mount = "models/weapons/arc9/darsu_eft/mods/mount_all_lobaev_dvl.mdl",
	mountVec = Vector(-0.2, 0, -1.5),
	mountAng = Angle(0, 0, 0),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(0, 0, 0),
	PhysAng = Angle(0, 90, 0),

	drawFunction = function(self,model) -- in swep:drawattachment
	end,

	sightFunction = function(self)
		self:DoRT()
	end,

	transformFunction = function(self,model,vecadd,ang) -- in transformfunction
	end,
	valid = true,
}

hg.attachments.sight["optic17"] = {
	"sight",
	"models/weapons/atts/sb_pm25x56/scope_sb_pm_ii_5_25x56_blk.mdl",
	Angle(0, 0, -90),
	offset = Vector(0.5, 1.5, -0.03),
	offsetView = Vector(0, 0, 11),
	{},
	mountType = "picatinny",
	scopemat = Material("decals/scope.png"),
	mat = Material("effects/arc9/rt"),
	perekrestie = Material("vgui/reticles/sb_pm_ii_5-25x56_mark_q.png"),
	localScopePos = Vector(0, 0, 0),
	scope_blackout = 3400,
	rot = 0,
	FOVMin = 1,
	FOVMax = 8,
	FOVScoped = 40,
	blackoutsize = 5000,
	sizeperekrestie = 2700,
	perekrestieSize = false,
	mount = "models/weapons/arc9/darsu_eft/mods/mount_all_lobaev_dvl.mdl",
	mountVec = Vector(-0.2, 0, -1.5),
	mountAng = Angle(0, 0, 0),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(1, 0, 0),
	PhysAng = Angle(0, 90, 0),

	drawFunction = function(self,model) -- in swep:drawattachment
	end,

	sightFunction = function(self)
		self:DoRT()
	end,

	transformFunction = function(self,model,vecadd,ang) -- in transformfunction
	end,
	valid = true,
}

-- ===================== НОВЫЙ ГЛУШИТЕЛЬ =====================
hg.attachments.barrel["supressor9"] = {
	"barrel",
	"models/weapons/atts/hekate/silencer_hekate_dt_338.mdl", 
	Angle(0, 0, 0), 
	{}, 
	modelscale = 1, 
	offset = Vector(0.7,-0.4,-0.18),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(1, 0, 0),
	PhysAng = Angle(0, 0, 0),
	valid = true,
}

hg.attachments.barrel["supressor11"] = {
	"barrel",
	"models/weapons/atts/pgm_saco/silencer_trg_pgm_sako_86x70.mdl", 
	Angle(0, 0, 0), 
	{}, 
	modelscale = 1, 
	offset = Vector(0.7,-0.4,-0.18),
	PhysModel = "models/hunter/plates/plate025.mdl",
	PhysPos = Vector(1, 0, 0),
	PhysAng = Angle(0, 0, 0),
	valid = true,
}
-- ===================== НОВЫЙ ЛАЗЕР =====================
-- (добавишь потом)models/weapons/atts/pgm_saco/silencer_trg_pgm_sako_86x70.mdl

-- #####################################################################
-- ###############   ДОБАВЛЯЕМ НАЗВАНИЯ И ИКОНКИ   #####################
-- #####################################################################

-- Если таблиц еще нет, создаем
hg.attachmentslaunguage = hg.attachmentslaunguage or {}
hg.attachmentsIcons = hg.attachmentsIcons or {}

-- Добавляем названия (то, что будет отображаться в инвентаре)
hg.attachmentslaunguage["ironsight5"] = "Scar foreiron"
hg.attachmentslaunguage["optic14"] = "1p59 with eyecup"
hg.attachmentslaunguage["optic15"] = "1p59"
hg.attachmentslaunguage["optic16"] = "PM II 3-12x50"
hg.attachmentslaunguage["optic17"] = "PM II 5-25x56"
hg.attachmentslaunguage["supressor9"] = "Hecate 338."
hg.attachmentslaunguage["supressor11"] = "Saco 338."

-- Добавляем иконки (если есть файлы иконок)
-- hg.attachmentsIcons["ironsight5"] = "vgui/my_attachments/scar_iron"
hg.attachmentsIcons["optic14"] = "entities/1p59.png"
hg.attachmentsIcons["optic15"] = "entities/1p59.png"
hg.attachmentsIcons["optic16"] = "entities/30mmpmii18x24_blk.png"
hg.attachmentsIcons["optic17"] = "entities/34mmpmii525x56_blk.png"
hg.attachmentsIcons["supressor9"] = "entities/cgs_hekate_dt_338_lm_sound_suppressor.png"
hg.attachmentsIcons["supressor11"] = "entities/sako_trg_pgm_precision_338_lm_sound_suppressor.png"

-- #####################################################################
-- ###############   ДОБАВЛЯЕМ В VALIDATTACHMENTS   ####################
-- #####################################################################

-- Это нужно, чтобы обвес точно появился в инвентаре
hg.validattachments = hg.validattachments or {}
hg.validattachments.sight = hg.validattachments.sight or {}
hg.validattachments.sight["ironsight5"] = hg.attachments.sight["ironsight5"]
hg.validattachments.sight["optic14"] = hg.attachments.sight["optic14"]
hg.validattachments.sight["optic15"] = hg.attachments.sight["optic15"]
hg.validattachments.sight["optic16"] = hg.attachments.sight["optic16"]
hg.validattachments.sight["optic17"] = hg.attachments.sight["optic17"]
hg.validattachments.barrel["supressor9"] = hg.attachments.barrel["supressor9"]
hg.validattachments.barrel["supressor11"] = hg.attachments.barrel["supressor11"]
