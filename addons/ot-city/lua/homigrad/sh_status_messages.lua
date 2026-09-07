
local allowedchars = {
	"ах",
	"АХ",
	"грр",
	"ГХ",
	"ААААХ",
}

local audible_pain = {
"ААААА... ЧЕРТ... ЭТО БОЛЬНО",
"Я БОЛЬШЕ НЕ МОГУ ЭТОГО ВЫНОСИТЬ!",
"Останови это, ОСТАНОВИ это, ОСТАНОВИ ЭТО!!",
"Почему ЭТО не ПРЕКРАТИТСЯ!?",
"Я теряю сознание. ПОЖАЛУЙСТА...",
"Почему я родился, чтобы чувствовать это, почему...",
"Я бы сделал все, чтобы это прекратилось... ЧТО УГОДНО",
"Это не жизнь, это ПЫТКА,СУКА!",
"Мне уже все равно, просто ПРЕКРАТИ БОЛЬ,ИЗБАВЬ МЕНЯ ОТ МУЧЕНИЙ!",
"Ничто не имеет значения, КРОМЕ КАК ОСТАНОВИТЬ ЕЕ...",
"Каждая секунда - это огненная вечность...",
"СМЕРТЬ БЫЛА БЫ МИЛОСЕРДИЕМ ДЛЯ МЕНЯ...",
"Всего одно мгновение без боли...",
"ЖАЛЬ, ЧТО У МЕНЯ СЕЙЧАС НЕТ ОБЕЗБОЛИВАЮЩЕГО. БЛЯТЬ.",
}

local sharp_pain = {
	"АААХХХ",
	"АААХ",
	"ААааХХ",
	"ААааХХхх",
	"АААаааГГРх",
	"ААаааАХХХ",
	"АААХХХ",
	"AAAAAaaх",
	"AAaaAХХХХ",
	"AAaAA",
	"AAAAAa",
	"AAAAaAAAaaaaгхх",
	"AAAaaAa",
	"AaaAAaгхх",
	"aaAaaAaхх",
	"aaaххх",
	"AAAaaГХХХ",
	"AAAaaAAхх",
	"AAAaaAAAAAaГХХХХ",
	"AAAaaAAAAAaГХAAAХХХ",
	"AAAaaAAAAAaГХХAAAAAAХХ",
	"AAAaaAAAAAaГХХХХХ",
	"AAAaaAAAaaAAAaГХХХРГХХ",
	"AAAaaAAAaaAAAaAAAAAAAГРХХХ",
	"AAAaaAAAAAaГХХГРХХХХ",
	"AAAaaAAAAAAAAAххх",
	"AAAaaAAAAAaГРХAaaaхх",
	"AAAaaAAAAAaAaaaaaAAAAHХХ",
	"AAAaaAAAAAaAAAAAAAAаГРРРХХ",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAАААХХГГГРХХХ",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAAAAAAAхх",
}

hg.sharp_pain = sharp_pain

local random_phrase = {
"Здесь как-то чилово что-ли...",
"Все кажется слишком тихим...",
"Дышать сейчас странно приятно",
"Что, если эта тишина продлится вечно?",
"Почему ничего не происходит?",
}

local fear_hurt_ironic = {
"Бьюсь об заклад, в этом есть урок... если я выживу",
"Мой будущий биограф в это не поверит",
"Что ж, я достоин премии Дарвина",
"По крайней мере, моя жизнь не была скучной",
"Заметка для себя: никогда так не поступай, снова",
"Это не самый худший день для смерти",
}

local fear_phrases = {
"Все не так уж плохо... правда?",
"Я не хочу вот так умереть",
	"Неужели все так и закончится?",
	"Это нехорошо",
"Неужели все так и закончится?",
"Я не хочу вот так умирать",
	"Хотел бы я, чтобы у меня был выход",
"Я о стольком сожалею...",
	"Этого не может быть",
"Я не могу поверить, что это происходит со мной",
"Мне следовало отнестись к этому серьезнее",
"Что, если у меня ничего не получится?",
"Все хуже, чем я думал...",
"Это так несправедливо",
"Я еще не могу сдаться так просто",
"Я никогда не думал, что все будет так",
"Я должен был прислушаться к своим инстинктам!",
"Дыши. Просто дыши...",
	"Ты должен быть холодным и уверенным...",
}

local is_aimed_at_phrases = {
 "О Боже. Вот оно...",
"Не двигайся.",
"Неужели я действительно так умру?",
"Я должен был бежать. Почему я не побежал?",
"Пожалуйста, не нажимай на курок. Пожалуйста",
"Я вижу, как их палец лежит на спусковом крючке",
"Я не хочу умирать. Только не так...",
"Если я буду умолять, станет ли только хуже?",
"Этого не может быть на самом деле. Этого не может быть на самом деле...",
"Кто-нибудь, помогите мне. Пожалуйста. Кто-нибудь!",
"Я не хочу умирать в таком месте, как это!",
"Я не хочу, чтобы моей последней мыслью был страх...",
"Я не хочу умирать",
}

local near_death_poetic = {
"Пытаюсь встать... но я просто не могу...",
"Дыхание - это всего лишь мелкие глотки пустоты...",
"Не могу понять, открыты мои глаза или нет...",
"Последнее, что я почувствую, - это вкус собственной крови и металла",
"Постоянно не могу сфокусироваться на чем-либо...",
"Не могу вспомнить, как жить...",
"Все отзывается эхом в моем черепе...",
"Моргание занимает слишком много времени, чтобы восстановиться",
"Пальцы не хотят сжиматься",
"Легкие отказываются наполняться кислородом...",
"Сожаления сейчас бессмысленны...",
}

local near_death_positive = {
"Я не хочу умирать...",
"Я должен выжить!",
"Еще есть шанс,сука...",
"Я не могу позволить страху победить",
"Еще одна попытка...",
"Я отказываюсь умирать здесь!",
"Хорошо... обдумай это.",
"Просто не двигайся. От движения становится только хуже",
"Дышите медленно. Паника не поможет,ничего уже блять не поможет!",
"Это не конец, пока все не закончится",
"Боль - это всего лишь сигнал. Не обращай внимания",
"Если это так... то, по крайней мере, все будет быстро",
"Я переживал и худшее. Наверное...",
"Я себе это не так представлял,мда...",
}

local broken_limb = {
"ЧЕРТ! БЛЯТЬ! ЗДЕСЬ ОПРЕДЕЛЕННО ПЕРЕЛОМ!",
"Я ЧУВСТВУЮ,КАК МОЯ КОСТЬ ДВИГАЕТСЯ ВО МНЕ",
"СУКА,НАДЕЮСЬ ОНО ЗАЖИВЕТ!",
"Мне больно даже думать об этом. Определенно сломана...",
"Я не думаю, что она должна сгибаться здесьЁ",
"О, черт. Она сломана,БЛЯТЬ!",
"Я не вижу открытого перелома, но чувствую, что что-то сломал...",
}

local dislocated_limb = {
"Да, она не должна так сгибаться,определенно...",
"Я должен вправить эту кость,врачей то нет!",
"Нет, я должен вернуть ее на место...",
"Просто там очень больно. Возможно придется осмотреть себя",
"Моя конечность не на месте",
}

local hungry_a_bit = {
"Мммгрх, я проголодался...",
"Было бы здорово перекусить...",
"Я проголодался...",
"Пора подкрепиться",
}

local very_hungry = {
 "Мой желудок... Там определенно пусто...",
"Если я не поем, мне будет еще хуже...",
"Желудок... Черт возьми... Я чувствую себя больным",
}

local after_unconscious = {
 "Что случилось? Мне больно...",
"Где я? Почему так больно...",
"Я думал, что умру...",
"Моя голова... Что случилось?",
"Я чуть не умер секунду назад?",
"Такое чувство, что я умер минуту назад...",
"Небеса не приняли меня?",
"О, черт... у меня болит голова...",
"О, будет трудно встать прямо сейчас... но я должен...",
"Я совсем не узнаю это место... или мне кажется?",
"Я не хочу испытать это... СНОВА!",
}

local slight_braindamage_phraselist = {
"Я не понимаю...",
"Это не имеет смысла...",
"Где я?",
"А? Что это..?",
"Я не понимаю, что происходит...",
"Привет?",
"Ааааааа...      ха-ха...",
"Что... происходит?",
}

local braindamage_phraselist = {
	"Де-еее... йааа... сеьь-чайс...?!",
	"Чтьььо случииииилгрнххааньяяясь?",
	"Мхрг... грхАа?",
	"Гдээээ вс....эээ?",
	"Ааргх..?",
	"Хххргх... Сыыка...",
	"Чййооорт... Баййлит!",
	"Помогиитхтхтхе...",
	"Агрхх,ээээ?",
	"Грх...Бэээ?",
	"Мазгашшштурм какакййййй-та...",
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Show the thoughts of your character", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 75) and 5
		or (pain > 65) and 5
		or (blood < 3000 and 0.3)
		--or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				most_wanted_phraselist = near_death_poetic
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		//most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	--elseif hg.fearful(ply) then
		--most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end