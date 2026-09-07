hg = hg or {}
hg.Accessories = hg.Accessories or {}

local bandanamat
if CLIENT then
    bandanamat = Material("mats_jack_gmod_sprites/respirator_vignette.png")
end

local DEFAULT_OTCOIN_PRICE_BY_PLACEMENT = {
    head = 900,
    face = 700,
    torso = 2200,
    spine = 1200,
    headpones = 850,
    bandanes = 600,
    boots = 1800,
    ears = 650,
    [""] = 700
}

local function NormalizeAccessoryCoinPrice(price)
    price = tonumber(price) or 0
    if price <= 0 then return 0 end
    return math.max(200, math.floor((price + 25) / 50) * 50)
end

local function LowerContains(haystack, needle)
    haystack = string.lower(tostring(haystack or ""))
    needle = string.lower(tostring(needle or ""))
    return needle ~= "" and string.find(haystack, needle, 1, true) ~= nil
end

local function AccessoryMatches(data, ...)
    local uid = tostring(data.uid or "")
    local name = tostring(data.name or "")

    for i = 1, select("#", ...) do
        local token = tostring(select(i, ...) or "")
        if token ~= "" and (LowerContains(uid, token) or LowerContains(name, token)) then
            return true
        end
    end

    return false
end

local function BuildAccessoryCoinPrice(data)
    local base = DEFAULT_OTCOIN_PRICE_BY_PLACEMENT[data.placement] or DEFAULT_OTCOIN_PRICE_BY_PLACEMENT[""] or 700

    if data.placement == "face" then
        if AccessoryMatches(data, "mask", "маска", "balaclava", "балаклава", "shemagh", "шема", "arafat", "аноним", "doom", "hockey", "airsoft", "welding") then
            base = 1400
        elseif AccessoryMatches(data, "oakley", "ess", "glasses", "очки", "aviator", "aviators", "монокл", "occluder", "retro") then
            base = 550
        end
    elseif data.placement == "head" then
        if AccessoryMatches(data, "helmet", "шлем") then
            base = 2600
        elseif AccessoryMatches(data, "hood", "капюшон") then
            base = 1100
        elseif AccessoryMatches(data, "cap", "кеп", "hat", "шля", "fedora", "beanie", "шап", "crown", "ushanka", "повяз") then
            base = 750
        end
    elseif data.placement == "torso" then
        if AccessoryMatches(data, "armor", "брон", "плит", "разгруз", "жилет", "slick", "banshee", "tv-", "tv110", "tv115", "mbss", "mmac", "cpc", "arma") then
            base = 3800
        elseif AccessoryMatches(data, "scarf", "шарф", "bag", "сумк") then
            base = 950
        end
    elseif data.placement == "spine" then
        if AccessoryMatches(data, "backpack", "рюкзак") then
            base = 1300
        elseif AccessoryMatches(data, "slugcat", "ящер", "lizard", "sticker", "наклей", "tooths", "зуб") then
            base = 1750
        end
    elseif data.placement == "headpones" then
        base = AccessoryMatches(data, "razor", "tactical", "xcel", "coolpro") and 1250 or 850
    elseif data.placement == "bandanes" then
        base = AccessoryMatches(data, "ghost", "groove", "crips", "лыж", "ski") and 850 or 600
    elseif data.placement == "boots" then
        base = 2200
    end

    if data.isvip == true then
        base = base * 1.15
    end

    if data.bonemerge then
        base = base * 1.08
    end

    if data.bSetColor then
        base = base * 1.06
    end

    if AccessoryMatches(data, "killa", "tagilla", "knight", "bigpipe", "zryachii", "кайман", "тор-2", "ulach", "galvion", "caiman", "coyote", "hops") then
        base = base * 1.18
    end

    return NormalizeAccessoryCoinPrice(base)
end

local function AddAccessory(uid, data)
    data = data or {}
    data.uid = tostring(uid)
    data.ID = tostring(data.ID or uid)
    data.DonateID = tostring(data.DonateID or data.ID or uid)
    data.name = tostring(data.name or uid)
    data.placement = tostring(data.placement or "")
    data.donateOnly = data.donateOnly == true
    data.isvip = data.isvip == true
    data.coinPurchasable = data.donateOnly ~= true and data.uid ~= "none"
    data.coinPrice = data.coinPurchasable and BuildAccessoryCoinPrice(data) or 0
    data.price = data.coinPrice > 0 and data.coinPrice or (tonumber(data.price) or 0)
    data.bPointShop = data.coinPrice > 0
    hg.Accessories[uid] = data
end

hg.Accessories = {
    ["none"] = {
        uid = "none",
        ID = "none",
        DonateID = "none",
        name = "none",
        placement = "",
        coinPrice = 0,
        coinPurchasable = false
    }
}

AddAccessory("arafatka", {
    model = "models/eft_props/gear/facecover/facecover_arafat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.4,-0.6,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.6,-1.2,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Арафатка",
    donateOnly = false,

    isvip = true
})

AddAccessory("exojump", {
    model = "models/minic23/csgo/exojump_bonemerge.mdl",
    
    bone = "ValveBiped.Bip01_L_Foot",
    malepos = {Vector(0,0,0), Angle(0,-75,-90), 1},
    fempos = {Vector(0,0,0), Angle(0,-75,-90), 0.95},

    skin = 0,
    norender = false,
    placement = "boots",
    
    name = "Экзо-Ботинки",
    donateOnly = true,
    bonemerge = true
})

AddAccessory("case_crown_hypocrisy", {
    model = "models/crown/crown.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.1,-0.6,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.4,-0.8,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Корона Лицемерия",
    donateOnly = true,
    caseEffect = "crown"
})

AddAccessory("case_killa_helmet", {
    model = "models/killa/items/killa_helmet.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.8,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(-0.2,-0.9,0),Angle(0,-75,-90),0.95},
    skin = 0,
    bodygroups = "1",
    norender = true,
    placement = "head",
    name = "Шлем Киллы",
    donateOnly = true,
    caseEffect = "killa"
})

AddAccessory("japanese_mask", {
    model = "models/eft_props/gear/facecover/facecover_ballistic_mask.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.1,-0.8,0.1),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.2,-1,0.1),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Японская маска",
    isvip = true,
    donateOnly = false
})

AddAccessory("knight_mask", {
    model = "models/eft_props/gear/facecover/facecover_boss_black_knight.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.3,-0.7,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.1,-0.5,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Маска Кнайта",
    donateOnly = true
})

AddAccessory("tagilla_mask", {
    model = "models/eft_props/gear/facecover/facecover_boss_welding_ubey.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.1,-0.5,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1,-0.5,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Маска Тагиллы",
    donateOnly = true
})

AddAccessory("skull_mask", {
    model = "models/eft_props/gear/facecover/facecover_halloween_skull.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.2,-0.5,0),Angle(0,-75,-90),1},
    fempos = {Vector(2,-0.5,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Маска череп",
    isvip = true,
    donateOnly = false
})

AddAccessory("ski_mask", {
    model = "models/eft_props/gear/facecover/facecover_mask_skull.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.2,-0.9,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.6,-0.8,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "bandanes",
    name = "Лыжная маска",
    isvip = true,
    donateOnly = false
})

AddAccessory("shemagh", {
    model = "models/eft_props/gear/facecover/facecover_shemagh.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.2,-0.5,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.4,-1,0),Angle(0,-75,-90),1},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Балаклава шема",
    isvip = true,
    donateOnly = false
})

AddAccessory("half_ski_mask", {
    model = "models/eft_props/gear/facecover/facecover_skull_half_mask.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.5,-0.5,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.5,-0.8,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "bandanes",
    name = "Лыжная маска (половина)",
    isvip = true,
    donateOnly = false
})

AddAccessory("airsoft_mask", {
    model = "models/eft_props/gear/facecover/facecover_strikeball_mask.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.0,-0.7,0),Angle(0,-75,-90),0.97},
    fempos = {Vector(1.2,-1,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Страйкбольная маска",
    isvip = true,
    donateOnly = false
})

AddAccessory("zryachii_mask", {
    model = "models/eft_props/gear/facecover/facecover_zryachii_closed.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,-0.5,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.3,-1.3,0),Angle(0,-75,-90),1},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Маска Зрячего",
    donateOnly = true
})

AddAccessory("razor_headset", {
    model = "models/eft_props/gear/headsets/headset_razor.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,0,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.8,0,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "headpones",
    name = "Наушники Разор",
    isvip = true,
    donateOnly = false
})

AddAccessory("tactical_headset", {
    model = "models/eft_props/gear/headsets/headset_tactical_sport.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.5,0,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(2,0,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "headpones",
    name = "Тактические наушники",
    isvip = true,
    donateOnly = false
})

AddAccessory("xcel_headset", {
    model = "models/eft_props/gear/headsets/headset_xcel.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,0,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.7,0,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "headpones",
    name = "Наушники XCEL",
    isvip = true,
    donateOnly = false
})

AddAccessory("ulach_helmet", {
    model = "models/eft_props/gear/helmets/helmet_ulach_c.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,-0.5,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.5,-0.5,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем Улач",
    isvip = true,
    donateOnly = false
})

AddAccessory("tor2_helmet", {
    model = "models/eft_props/gear/helmets/helmet_tor_2.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.9,-1,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.5,-1,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем Тор-2",
    isvip = true,
    donateOnly = false
})

AddAccessory("coyote_helmet", {
    model = "models/eft_props/gear/helmets/helmet_team_wendy_exfil_coyote.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,-1,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.5,0,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем Койот",
    isvip = true,
    donateOnly = false
})

AddAccessory("caiman_helmet", {
    model = "models/eft_props/gear/helmets/helmet_galvion_caiman.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.8,-0.6,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.1,-0.6,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем Кайман",
    isvip = true,
    donateOnly = false
})

AddAccessory("hops_helmet", {
    model = "models/eft_props/gear/helmets/helmet_hops_core_fast.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.5,-0.8,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.8,-0.9,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем ХОПС",
    isvip = true,
    donateOnly = false
})

AddAccessory("galvion_helmet", {
    model = "models/eft_props/gear/helmets/helmet_galvion_applique.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.7,-0.6,0),Angle(0,-75,-90),0.95},
    fempos = {Vector(1.3,-0.8,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Шлем Гальвион",
    isvip = true,
    donateOnly = false
})

AddAccessory("usec_cap", {
    model = "models/eft_props/gear/headwear/cap_usec_tan.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.8,-0.9,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.5,-1,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Кепка USEC",
    donateOnly = false
})

AddAccessory("bear_cap", {
    model = "models/eft_props/gear/headwear/cap_bear_black.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.8,-0.9,0),Angle(0,-75,-90),1},
    fempos = {Vector(1.2,-0.8,0),Angle(0,-75,-90),0.95},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Кепка BEAR",
    donateOnly = false
})

AddAccessory("armor_killa_plate", {
    model = "models/eft_props/gear/armor/ar_6b13_killa.mdl",
    femmodel = "models/eft_props/gear/armor/ar_6b13_killa.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.5,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,3.1,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    donateOnly = true,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Бронеплитник Киллы"
})

AddAccessory("armor_slick", {
    model = "models/eft_props/gear/armor/ar_custom_hexgrid.mdl",
    femmodel = "models/eft_props/gear/armor/ar_custom_hexgrid.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Слик-разгрузка"
})

AddAccessory("armor_ars_arma18", {
    model = "models/eft_props/gear/armor/cr/cr_ars_arma_18.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_ars_arma_18.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    isvip = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Тактический разгрузочный жилет ARS Arma 18"
})

AddAccessory("armor_arscpc", {
    model = "models/eft_props/gear/armor/cr/cr_arscpc.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_arscpc.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    isvip = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Тактический разгруз ARS CPC"
})

AddAccessory("armor_black_knight", {
    model = "models/eft_props/gear/armor/cr/cr_black_knight.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_black_knight.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    donateOnly = true,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Бронежилет Кнайта"
})

AddAccessory("armor_mbss", {
    model = "models/eft_props/gear/armor/cr/cr_mbss.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_mbss.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    isvip = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Легкий разгрузочный жилет MBSS"
})

AddAccessory("armor_mmac", {
    model = "models/eft_props/gear/armor/cr/cr_mmac.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_mmac.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    isvip = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Разгрузочный жилет MMAC"
})

AddAccessory("armor_bigpipe", {
    model = "models/eft_props/gear/armor/cr/cr_precision_bigpipe.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_precision_bigpipe.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    donateOnly = true,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Бронеплитник Биг Пайпа"
})

AddAccessory("armor_banshee", {
    model = "models/eft_props/gear/armor/cr/cr_shellback_tactical_banshee.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_shellback_tactical_banshee.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    isvip = true,
    bonemerge = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Бронеразгруз Banshee"
})

AddAccessory("armor_tagilla", {
    model = "models/eft_props/gear/armor/cr/cr_tagilla.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_tagilla.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    bonemerge = true,
    donateOnly = true,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Слик-разгрузка Тагиллы"
})

AddAccessory("armor_tv110", {
    model = "models/eft_props/gear/armor/cr/cr_tv110.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_tv110.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    isvip = true,
    placement = "torso",
    bonemerge = true,
    donateOnly = false,
    vpos = Vector(0,0,11),
    name = "Разгрузка ТВ-110"
})

AddAccessory("armor_tv115", {
    model = "models/eft_props/gear/armor/cr/cr_tv115.mdl",
    femmodel = "models/eft_props/gear/armor/cr/cr_tv115.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-10,5.0,0),Angle(0,80,90),1},
    fempos = {Vector(-11.5,4.5,0),Angle(0,80,90),1},
    skin = 0,
    norender = false,
    placement = "torso",
    isvip = true,
    bonemerge = true,
    donateOnly = false,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,11),
    name = "Разгрузка ТВ-115"
})

//
//
//
//
//

AddAccessory("eyeglasses", {
    model = "models/captainbigbutt/skeyler/accessories/glasses01.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = { Vector(3,-2.9,0), Angle(0,-70,-90), .9},
    fempos = {Vector(2.1,-2.7,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Очки"
})

AddAccessory("bugeye sunglasses", {
    model = "models/captainbigbutt/skeyler/accessories/glasses04.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.2,-3.3,0),Angle(0,-70,-90),.9},
    fempos = {Vector(2.2,-3.3,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Жучиные солнцезащитные очки"
})

AddAccessory("aviators", {
    model = "models/arctic_nvgs/aviators.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.7,0,0),Angle(0,-80,-90),1},
    fempos = {Vector(0.25,0,0),Angle(0,-85,-90),.95},
    skin = 0,
    norender = true,
    placement = "face",
    bPointShop = true,
    price = 5000,
    vpos = Vector(0,0,0),
    name = "Авиаторы"
})

AddAccessory("nerd glasses", {
    model = "models/gmod_tower/klienerglasses.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.8,-2.2,0),Angle(0,-80,-90),1},
    fempos = {Vector(2.5,-2.5,0),Angle(0,-85,-90),.95},
    skin = 0,
    norender = true,
    placement = "face",
    bPointShop = true,
    price = 1000,
    name = "Ботанские очки"
})

AddAccessory("headphones", {
    model = "models/gmod_tower/headphones.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.6,-1,0),Angle(0,-80,-90),.85},
    fempos = {Vector(2.4,-1,0),Angle(0,-85,-90),.8},
    skin = 0,
    norender = true,
    placement = "headpones",
    bPointShop = true,
    price = 1000,
    name = "Наушники"
})

AddAccessory("baseball cap", {
    model = "models/gmod_tower/jaseballcap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0,0),Angle(0,-75,-90), 1.12},
    fempos = {Vector(4,-0.1,0),Angle(0,-75,-90), 1.125},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Бейсболка"
})

AddAccessory("fedora", {
    model = "models/captainbigbutt/skeyler/hats/fedora.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5.5,-0.2,0),Angle(0,-80,-90), 0.7},
    fempos = {Vector(4.5,-0.2,0),Angle(0,-75,-90), 0.7},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Федора"
})

AddAccessory("stetson", {
    model = "models/captainbigbutt/skeyler/hats/cowboyhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(6.2,0.6,0),Angle(0,-60,-90), 0.7},
    fempos = {Vector(5.2,0.5,0),Angle(0,-65,-90), 0.65},
    skin = 0,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Стетсон"
})

AddAccessory("straw hat", {
    model = "models/captainbigbutt/skeyler/hats/strawhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5.2,-0.4,0),Angle(0,-70,-90), 0.85},
    fempos = {Vector(4.5,-0.5,0),Angle(0,-75,-90), 0.8},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Соломенная шляпа"
})

AddAccessory("sun hat", {
    model = "models/captainbigbutt/skeyler/hats/sunhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4.2,2,0),Angle(0,-90,-90), 0.8},
    fempos = {Vector(3.4,2,0),Angle(0,-90,-90), 0.75},
    skin = 0,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Солнечная шляпа"
})

AddAccessory("bling cap", {
    model = "models/captainbigbutt/skeyler/hats/zhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.9,0.1,0),Angle(0,-80,-90), 0.75},
    fempos = {Vector(3.5,0.2,0),Angle(-10,-80,-90), 0.75},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Блинг-кепка"
})

AddAccessory("top hat", {
    model = "models/player/items/humans/top_hat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0,-1.5,0),Angle(0,-80,-90), 1},
    fempos = {Vector(-0.8,-1.8,0),Angle(0,-80,-90), 1},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Цилиндр"
})

AddAccessory("backpack", {
    model = "models/makka12/bag/jag.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-3,0,0),Angle(0,90,90),.75},
    fempos = {Vector(-3,-1,0),Angle(0,90,90),.6},
    skin = 0,
    norender = true,
    placement = "spine",
    name = "Рюкзак"
})

AddAccessory("backpack hellokitty", {
    model = "models/gleb/backpack_pink.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-7.5,5,0),Angle(0,80,90),1},
    fempos = {Vector(-8,3,0),Angle(0,80,90),0.9},
    skin = 0,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 4000,
    vpos = Vector(0,0,0),
    name = "Рюкзак Hello Kitty"
})

AddAccessory("kickme sticker", {
    model = "models/gleb/kickme.mdl",
    bone = "ValveBiped.Bip01_Pelvis",
    malepos = {Vector(0,4,-6.8),Angle(-75,-90,0),1},
    fempos = {Vector(0,4,-5.8),Angle(-65,-90,0),1},
    skin = 0,
    norender = true,
    placement = "spine",
    bonemerge = true,
    bPointShop = true,
    price = 2500,
    name = "Наклейка Пни меня"
})

AddAccessory("nerd tooths", {
    model = "models/gleb/nerd.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.3,-0.4,0),Angle(0,-85,-90),1},
    fempos = {Vector(1.9,-0.8,0),Angle(0,-85,-90),.95},
    skin = 0,
    norender = true,
    placement = "spine",
    bonemerge = true,
    bPointShop = true,
    price = 2500,
    name = "Зубы ботана"
})

AddAccessory("purse", {
    model = "models/props_c17/BriefCase001a.mdl",
    bone = "ValveBiped.Bip01_Spine1",
    malepos = {Vector(-7,1,7),Angle(0,90,100),.5},
    fempos = {Vector(-7,0,7),Angle(0,90,100),.5},
    skin = 0,
    norender = true,
    placement = "spine",
    name = "Сумочка"
})

AddAccessory("zcity cap", {
    model = "models/gleb/zcap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1500,
    name = "Бейсболка ZCITY"
})

AddAccessory("gray cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    placement = "head",
    name = "Серая бейсболка"
})

AddAccessory("light gray cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 2,
    norender = true,
    placement = "head",
    name = "Светло-серая бейсболка"
})

AddAccessory("white cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 3,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Белая бейсболка"
})

AddAccessory("green cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.5,0.1),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 4,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Зелёная бейсболка"
})

AddAccessory("dark green cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 5,
    norender = true,
    placement = "head",
    name = "Тёмно-зелёная бейсболка"
})

AddAccessory("brown cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 6,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Коричневая бейсболка"
})

AddAccessory("blue cap", {
    model = "models/modified/hat07.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(5,0.4,0),Angle(180,105,90),1},
    fempos = {Vector(3.5,0.2,0),Angle(180,105,90),1},
    skin = 7,
    norender = true,
    placement = "head",
    name = "Синяя бейсболка"
})

AddAccessory("bandana", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 0,
    bSetColor = true,
    vecColorOveride = Vector(0.2,0.2,0.2),
    norender = true,
    placement = "bandanes",
    ScreenSpaceEffects = function()
        if not bandanamat then return end
        surface.SetMaterial(bandanamat)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(-1,0,ScrW()*1.01,ScrH()*1.2)
    end,
    bPointShop = true,
    vpos = Vector(0,0,63),
    price = 1000,
    name = "Бандана"
})

AddAccessory("bandana colorable", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 0,
    bSetColor = true,
    norender = true,
    placement = "bandanes",
    ScreenSpaceEffects = function()
        if not bandanamat then return end
        surface.SetMaterial(bandanamat)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(-1,0,ScrW()*1.01,ScrH()*1.2)
    end,
    bPointShop = true,
    vpos = Vector(0,0,63),
    price = 4500,
    name = "Бандана с покраской"
})

AddAccessory("arctic_balaclava", {
    model = "models/d/balaklava/arctic_reference.mdl",
    femmodel = "models/distac/feminine_mask.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1.1},
    fempos = {Vector(-1,-0.8,0),Angle(180,105,90),1.05},
    skin = 0,
    norender = true,
    disallowinappearance = true,
    bonemerge = true,
    name = "Арктическая балаклава"
})

AddAccessory("phoenix_balaclava", {
    model = "models/d/balaklava/phoenix_balaclava.mdl",
    femmodel = "models/distac/feminine_mask.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.6,-0.95,0),Angle(180,100,90),0.95},
    fempos = {Vector(-0.6,-0.6,0),Angle(180,100,90),0.95},
    skin = 0,
    norender = true,
    disallowinappearance = true,
    bonemerge = true,
    name = "Балаклава Феникс"
})

AddAccessory("terrorist_band", {
    model = "models/distac/band_team.mdl",
    femmodel = "models/distac/band_team_f.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.6,-0.95,0),Angle(180,100,90),0.95},
    fempos = {Vector(-0.6,-0.6,0),Angle(180,100,90),0.95},
    skin = 0,
    norender = true,
    disallowinappearance = true,
    bonemerge = true,
    needcoolRender = true,
    flex = true,
    name = "Террористическая повязка"
})

AddAccessory("white scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 0,
    norender = true,
    vpos = Vector(0,0,20),
    placement = "torso",
    name = "Белый шарф"
})

AddAccessory("gray scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 1,
    norender = true,
    vpos = Vector(0,0,20),
    placement = "torso",
    name = "Серый шарф"
})

AddAccessory("black scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 2,
    norender = true,
    placement = "torso",
    bPointShop = true,
    vpos = Vector(0,0,20),
    price = 1000,
    name = "Чёрный шарф"
})

AddAccessory("blue scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 3,
    norender = true,
    placement = "torso",
    bPointShop = true,
    vpos = Vector(0,0,20),
    price = 1000,
    name = "Синий шарф"
})

AddAccessory("red scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 4,
    norender = true,
    placement = "torso",
    bPointShop = true,
    vpos = Vector(0,0,20),
    price = 1000,
    name = "Красный шарф"
})

AddAccessory("green scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 5,
    norender = true,
    placement = "torso",
    bPointShop = true,
    vpos = Vector(0,0,20),
    price = 1000,
    name = "Зелёный шарф"
})

AddAccessory("pink scarf", {
    model = "models/sal/acc/fix/scarf01.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-18,8,0),Angle(0,75,90),1},
    fempos = {Vector(-18,5.5,0),Angle(0,80,90),.9},
    skin = 6,
    norender = true,
    placement = "torso",
    bPointShop = true,
    vpos = Vector(0,0,20),
    price = 1000,
    name = "Розовый шарф"
})

AddAccessory("red earmuffs", {
    model = "models/modified/headphones.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.8,-1,0),Angle(180,105,90),1},
    fempos = {Vector(1.8,-1,0),Angle(180,105,90),0.95},
    skin = 0,
    norender = true,
    placement = "headpones",
    bPointShop = true,
    price = 1000,
    name = "Красные наушники-ушанки"
})

AddAccessory("pink earmuffs", {
    model = "models/modified/headphones.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.8,-1,0),Angle(180,105,90),1},
    fempos = {Vector(1.8,-1,0),Angle(180,105,90),0.95},
    skin = 1,
    norender = true,
    placement = "headpones",
    bPointShop = true,
    price = 1000,
    name = "Розовые наушники-ушанки"
})

AddAccessory("green earmuffs", {
    model = "models/modified/headphones.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.8,-1,0),Angle(180,105,90),1},
    fempos = {Vector(1.8,-1,0),Angle(180,105,90),0.95},
    skin = 2,
    norender = true,
    placement = "headpones",
    bPointShop = true,
    price = 1000,
    name = "Зелёные наушники-ушанки"
})

AddAccessory("yellow earmuffs", {
    model = "models/modified/headphones.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2.8,-1,0),Angle(180,105,90),1},
    fempos = {Vector(1.8,-1,0),Angle(180,105,90),0.95},
    skin = 3,
    norender = true,
    placement = "headpones",
    bPointShop = true,
    price = 1000,
    name = "Жёлтые наушники-ушанки"
})

AddAccessory("gray fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Серая федора"
})

AddAccessory("black fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 1,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Чёрная федора"
})

AddAccessory("white fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 2,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Белая федора"
})

AddAccessory("beige fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 3,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Бежевая федора"
})

AddAccessory("black/red fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 5,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Чёрно-красная федора"
})

AddAccessory("blue fedora", {
    model = "models/modified/hat01_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    fempos = {Vector(3,0.2,0),Angle(180,105,90),1},
    skin = 7,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Синяя федора"
})

AddAccessory("striped beanie", {
    model = "models/modified/hat03.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4,0,0),Angle(180,105,90),1},
    fempos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Полосатая шапка"
})

AddAccessory("periwinkle beanie", {
    model = "models/modified/hat03.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4,0,0),Angle(180,105,90),1},
    fempos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    skin = 1,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Барвинковая шапка"
})

AddAccessory("fuschia beanie", {
    model = "models/modified/hat03.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4,0,0),Angle(180,105,90),1},
    fempos = {Vector(3.8,0.2,0),Angle(180,105,90),1},
    skin = 2,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Фуксиевая шапка"
})

AddAccessory("white beanie", {
    model = "models/modified/hat03.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4,0,0),Angle(180,105,90),1},
    fempos = {Vector(3.8,0.2,0),Angle(180,100,90),1},
    skin = 3,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Белая шапка"
})

AddAccessory("gray beanie", {
    model = "models/modified/hat03.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4,0,0),Angle(180,105,90),1},
    fempos = {Vector(3.8,0.2,0),Angle(180,100,90),1},
    skin = 4,
    norender = true,
    placement = "head",
    bPointShop = true,
    price = 1000,
    name = "Серая шапка"
})

AddAccessory("large red backpack", {
    model = "models/modified/backpack_1.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-7.5,5.2,0),Angle(0,80,90),1},
    fempos = {Vector(-8,4,0),Angle(0,80,90),0.9},
    skin = 0,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 1000,
    name = "Большой красный рюкзак"
})

AddAccessory("large gray backpack", {
    model = "models/modified/backpack_1.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-7.5,5.2,0),Angle(0,80,90),1},
    fempos = {Vector(-8,4,0),Angle(0,80,90),0.9},
    skin = 1,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 1000,
    name = "Большой серый рюкзак"
})

AddAccessory("medium backpack", {
    model = "models/modified/backpack_3.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-7.5,4,0),Angle(0,80,90),1},
    fempos = {Vector(-8,3,0),Angle(0,80,90),0.9},
    skin = 0,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 1000,
    name = "Средний рюкзак"
})

AddAccessory("medium gray backpack", {
    model = "models/modified/backpack_3.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(-7.5,4,0),Angle(0,80,90),1},
    fempos = {Vector(-8,3,0),Angle(0,80,90),0.9},
    skin = 1,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 1000,
    name = "Средний серый рюкзак"
})

AddAccessory("monokl", {
    model = "models/distac/monokl.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4.05,-4.8,-1.3),Angle(180,100,90),1},
    fempos = {Vector(-1,-0.8,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    bPointShop = true,
    price = 2000,
    vpos = Vector(0,0,69),
    name = "Монокль"
})

AddAccessory("china hat", {
    model = "models/distac/china_hat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(4.5,-0.35,0),Angle(180,100,90),1},
    fempos = {Vector(3,-0.8,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "head",
    bPointShop = true,
    isdpoint = false,
    price = 2500,
    vpos = Vector(0,0,0),
    name = "Китайская шляпа"
})

AddAccessory("helicopter cap", {
    model = "models/distac/cap_helecopterkid.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-70,-13.5,0),Angle(180,100,90),1.1},
    fempos = {Vector(-63,-18.5,0),Angle(180,105,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "head",
    bPointShop = true,
    isdpoint = false,
    price = 2500,
    vpos = Vector(0,0,69),
    name = "Бейсболка с пропеллером"
})

AddAccessory("welding glasses", {
    model = "models/distac/glassis_welding glasses.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1},
    fempos = {Vector(0,0,0),Angle(0,0,0),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    bPointShop = true,
    isdpoint = false,
    price = 2500,
    vpos = Vector(0,0,69),
    name = "Сварочные очки"
})

AddAccessory("big glasses", {
    model = "models/distac/big_ahhh_glassis.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1},
    fempos = {Vector(0,0,0),Angle(0,0,0),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    flex = true,
    bPointShop = true,
    isdpoint = false,
    price = 2000,
    vpos = Vector(0,0,69),
    name = "Большие очки"
})

AddAccessory("glasses with nose", {
    model = "models/distac/glasses_with_mustache.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1},
    fempos = {Vector(0,0,0),Angle(0,0,0),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    flex = true,
    bPointShop = true,
    price = 2500,
    vpos = Vector(0,0,69),
    name = "Очки с носом и усами"
})

AddAccessory("glasses fmf", {
    model = "models/distac/street_kid_fmf.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1},
    fempos = {Vector(0,0,0),Angle(0,0,0),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    flex = true,
    bPointShop = true,
    price = 3000,
    vpos = Vector(0,0,69),
    name = "Очки FMF"
})

AddAccessory("warmcap", {
    model = "models/distac/warmcap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,-0.95,0),Angle(180,100,90),1},
    fempos = {Vector(0,0,0),Angle(0,0,0),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "head",
    flex = true,
    bPointShop = true,
    price = 2600,
    vpos = Vector(0,0,69),
    name = "Тёплая шапка"
})

AddAccessory("slugcat", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "0",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Выживший"
})

AddAccessory("slugcat monk", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.6,5,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "1",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Монах"
})

AddAccessory("slugcat gourmand", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "2",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Гурман"
})

AddAccessory("slugcat arti", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "3",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Артификер"
})

AddAccessory("slugcat rivulet", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "4",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Ривулет"
})

AddAccessory("slugcat speermaster", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "5",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Копьемастер"
})

AddAccessory("slugcat saint", {
    model = "models/salat_port/slugcat_figure.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "spine",
    bodygroups = "6",
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,0),
    name = "Слагкэт Святой"
})

AddAccessory("pinklizard", {
    model = "models/zcity/lizard.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(2,1,-6),Angle(100,0,0),1},
    fempos = {Vector(1,0,-5),Angle(70,180,180),1},
    skin = 0,
    norender = true,
    placement = "spine",
    bPointShop = true,
    price = 1,
    vpos = Vector(0,0,0),
    name = "Розовая ящерица"
})

AddAccessory("headband", {
    model = "models/distac/headband.mdl",
    femmodel = "models/distac/headband_f.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 3500,
    vpos = Vector(0,0,69),
    name = "Повязка на голову"
})

AddAccessory("occluder", {
    model = "models/distac/occluder.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    bonemerge = true,
    placement = "face",
    bPointShop = true,
    isdpoint = false,
    price = 1200,
    vpos = Vector(0,0,69),
    name = "Окклюдер"
})

AddAccessory("shapka ushanka", {
    model = "models/distac/shapka_ushanka.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "head",
    bPointShop = true,
    price = 2300,
    vpos = Vector(0,0,69),
    name = "Шапка-ушанка"
})

AddAccessory("cap gop", {
    model = "models/distac/cap_gop.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "head",
    bPointShop = true,
    price = 2300,
    vpos = Vector(0,0,69),
    name = "Гоп-кепка"
})

AddAccessory("glasses viktor", {
    model = "models/distac/viktor.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    bPointShop = true,
    isdpoint = false,
    price = 1350,
    vpos = Vector(0,0,69),
    name = "Очки Виктора"
})

AddAccessory("glasses folding", {
    model = "models/distac/folding.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    norender = true,
    bonemerge = true,
    placement = "face",
    bPointShop = true,
    price = 1350,
    vpos = Vector(0,0,69),
    name = "Складные очки"
})

AddAccessory("headband kamikadze", {
    model = "models/distac/headband.mdl",
    femmodel = "models/distac/headband_f.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    placement = "head",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    isdpoint = false,
    price = 750,
    vpos = Vector(0,0,69),
    name = "Повязка камикадзе"
})

AddAccessory("mfdoom mask", {
    model = "models/distac/mfdoom.mdl",
    femmodel = "models/distac/mfdoom.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    placement = "face",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 2500,
    vpos = Vector(0,0,69),
    name = "Маска MF Doom"
})

AddAccessory("anon mask", {
    model = "models/rawjesus/wear/anon.mdl",
    femmodel = "models/rawjesus/wear/anon.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0,-0.8,0),Angle(180,100,90),1},
    fempos = {Vector(-1.2,-0.8,0),Angle(180,100,90),1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 6500,
    vpos = Vector(0,0,0),
    name = "Маска Анонимуса"
})

AddAccessory("hockey mask", {
    model = "models/rawjesus/wear/jason.mdl",
    femmodel = "models/rawjesus/wear/jason.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.5,-0.8,0),Angle(180,100,90),1},
    fempos = {Vector(-0.5,-0.8,0),Angle(180,100,90),1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 7500,
    vpos = Vector(0,0,0),
    name = "Хоккейная маска"
})

AddAccessory("hood", {
    model = "models/distac/kapishon2.mdl",
    femmodel = "models/distac/kapishon2.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = function(ent)
        local colthes = IsValid(ent) and ent.GetNWString and ent:GetNWString("Colthesmain","normal") or ""
        return colthes == "cold" and 0 or 1
    end,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = true,
    bPointShop = true,
    price = 850,
    vpos = Vector(0,0,69),
    name = "Капюшон"
})

AddAccessory("christmas hat", {
    model = "models/grinchfox/head_wear/christmas_hat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,0.5,0),Angle(180,90,90),1},
    fempos = {Vector(0.2,0,0),Angle(180,90,90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = true,
    name = "Рождественская шапка"
})

AddAccessory("cap deeper", {
    model = "models/grinchfox/head_wear/caphat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1,0.4,0),Angle(0,-95,-90),1},
    fempos = {Vector(0,0.1,0),Angle(0,-95,-90),1},
    skin = 7,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 850,
    vpos = Vector(0,0,5),
    name = "Кепка Deeper"
})

AddAccessory("cap nurse", {
    model = "models/grinchfox/head_wear/caphat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1,0.4,0),Angle(0,-95,-90),1},
    fempos = {Vector(0,0.1,0),Angle(0,-95,-90),1},
    skin = 9,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 750,
    vpos = Vector(0,0,5),
    name = "Кепка медсестры"
})

AddAccessory("cap payot", {
    model = "models/grinchfox/head_wear/jewhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1,0.4,0),Angle(0,-95,-90),1},
    fempos = {Vector(0,0.1,0),Angle(0,-95,-90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 4000,
    vpos = Vector(0,0,5),
    name = "Кепка с пейсами"
})

AddAccessory("burger king crown", {
    model = "models/roblox_assets/burger_king_crown.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(7.8,-0.1,0),Angle(-90,-80,-90),0.7},
    fempos = {Vector(7.8,-0.1,0),Angle(-90,-80,-90),0.7},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    isdpoint = true,
    price = 5,
    vpos = Vector(0,0,5),
    name = "Корона Burger King"
})

AddAccessory("deal glasses", {
    model = "models/grinchfox/head_wear/dealglasses_fix.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.6,0.5,0),Angle(0,-90,-90),1.1},
    fempos = {Vector(-0.5,.5,0),Angle(0,-90,-90),1.1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 7331,
    vpos = Vector(0,0,5),
    name = "Deal With It очки"
})

AddAccessory("cool glasses", {
    model = "models/grinchfox/head_wear/fancyglasses2.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.6,0.2,0),Angle(0,-90,-90),1.1},
    fempos = {Vector(-0.5,.2,0),Angle(0,-90,-90),1.1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 4000,
    vpos = Vector(0,0,5),
    name = "Модные очки"
})

AddAccessory("retro glasses", {
    model = "models/grinchfox/head_wear/fancyglasses3.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.6,0.2,0),Angle(0,-90,-90),1.1},
    fempos = {Vector(-0.5,.2,0),Angle(0,-90,-90),1.1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 2500,
    vpos = Vector(0,0,5),
    name = "Ретро-очки"
})

AddAccessory("tophat white", {
    model = "models/grinchfox/head_wear/tophat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(2,0.4,0),Angle(0,-95,-90),1},
    fempos = {Vector(1,0.1,0),Angle(0,-95,-90),1},
    skin = 1,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 1700,
    vpos = Vector(0,0,5),
    name = "Белый цилиндр"
})

AddAccessory("bandana groove", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 3,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    isdpoint = false,
    price = 1400,
    vpos = Vector(0,0,63),
    name = "Бандана Groove"
})

AddAccessory("bandana crips", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 1,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    isdpoint = false,
    price = 1400,
    vpos = Vector(0,0,63),
    name = "Бандана Crips"
})

AddAccessory("bandana white", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 0,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    isdpoint = false,
    price = 1100,
    vpos = Vector(0,0,63),
    name = "Белая бандана"
})

AddAccessory("bandana ghost", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 10,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    price = 2500,
    vpos = Vector(0,0,63),
    name = "Бандана Ghost"
})

AddAccessory("bandana hm", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 11,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    price = 1100,
    vpos = Vector(0,0,63),
    name = "Бандана HM"
})

AddAccessory("bandana evil", {
    model = "models/fix/grinchfox/gangwrap/gangwrap.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-63.5,-12,0),Angle(90,10,0),1},
    fempos = {Vector(-63.6,-12,0),Angle(90,10,0),1},
    skin = 5,
    placement = "bandanes",
    norender = true,
    bonemerge = false,
    bSetColor = false,
    bPointShop = true,
    price = 1500,
    vpos = Vector(0,0,63),
    name = "Бандана Evil"
})

AddAccessory("baseball hub", {
    model = "models/grinchfox/head_wear/baseballhat.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1,0.4,0),Angle(0,-95,-90),1.1},
    fempos = {Vector(0,0.1,0),Angle(0,-95,-90),1},
    skin = 6,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = false,
    bPointShop = true,
    price = 1750,
    vpos = Vector(0,0,5),
    name = "Бейсболка"
})

AddAccessory("leather bag", {
    model = "models/distac/bag.mdl",
    femmodel = "models/distac/bagf.mdl",
    bone = "ValveBiped.Bip01_Spine4",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 1,
    norender = true,
    placement = "torso",
    bonemerge = true,
    bPointShop = true,
    isdpoint = false,
    price = 1550,
    vpos = Vector(0,0,42),
    name = "Кожаная сумка"
})

AddAccessory("starglassis", {
    model = "models/distac/starglassis.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(-64,-0.3,0),Angle(180,90,90),1},
    fempos = {Vector(-64,-0.3,0),Angle(180,90,90),1},
    skin = 0,
    placement = "face",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 2000,
    vpos = Vector(0,0,69),
    name = "Очки-звёзды"
})

AddAccessory("cap brain", {
    model = "models/distac/cap_brain.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.5,1.5,0),Angle(180,80,90),1},
    fempos = {Vector(0.5,1.5,0),Angle(180,80,90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 2000,
    vpos = Vector(0,0,0),
    name = "Кепка с мозгом"
})

AddAccessory("coolPro headphone", {
    model = "models/distac/headphone.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    placement = "headpones",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 2500,
    vpos = Vector(0,0,69),
    name = "Наушники coolPro"
})

AddAccessory("medieval hood", {
    model = "models/distac/kapishom_m.mdl",
    femmodel = "models/distac/kapishom_f.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(0.2,4.8,0),Angle(0,90,90),1},
    fempos = {Vector(-1.2,3.5,0),Angle(0,90,90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bSetColor = true,
    bPointShop = true,
    price = 950,
    vpos = Vector(0,0,69),
    name = "Средневековый капюшон"
})

AddAccessory("cap cool", {
    model = "models/distac/cap_brain.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.5,1.5,0),Angle(180,80,90),1},
    fempos = {Vector(0.5,1.5,0),Angle(180,80,90),1},
    skin = 0,
    placement = "head",
    norender = true,
    bonemerge = true,
    bPointShop = true,
    price = 2000,
    vpos = Vector(0,0,0),
    SubMat = "distac/41/cap_fire",
    name = "Крутая кепка"
})

//
//

AddAccessory("glusses_dodoma", {
    model = "models/eft_props/gear/eyewear/glasses_duduma.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.7,-1.3,0),Angle(0,-70,-90),.9},
    fempos = {Vector(0.8,-1.5,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Очки Oakley"
})

AddAccessory("glusses_ess", {
    model = "models/eft_props/gear/eyewear/glasses_ess.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.7,-1.3,0),Angle(0,-70,-90),.9},
    fempos = {Vector(0.8,-1.5,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Очки ESS"
})

AddAccessory("glusses_oakle", {
    model = "models/eft_props/gear/eyewear/glasses_oakley.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.7,-1.3,0),Angle(0,-70,-90),.9},
    fempos = {Vector(0.8,-1.5,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Тактические очки Oakley"
})

AddAccessory("glusses_tacticc", {
    model = "models/eft_props/gear/eyewear/glasses_tactical.mdl",
    bone = "ValveBiped.Bip01_Head1",
    malepos = {Vector(1.7,-1.3,0),Angle(0,-70,-90),.9},
    fempos = {Vector(0.8,-1.5,0),Angle(0,-70,-90),.8},
    skin = 0,
    norender = true,
    placement = "face",
    name = "Очки тактические"
})