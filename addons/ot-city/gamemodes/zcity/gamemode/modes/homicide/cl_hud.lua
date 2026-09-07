local MODE = MODE

local UI_MAIN = Color(31, 182, 255)
local UI_MAIN_SOFT = Color(127, 230, 255)
local UI_DARK = Color(3, 5, 9)
local UI_DARK_SOFT = Color(6, 12, 20)
local UI_CARD = Color(9, 18, 30)
local UI_CARD_SOFT = Color(12, 22, 36)
local UI_TEXT = Color(240, 248, 255)
local UI_MUTED = Color(150, 190, 220)
local UI_OUTLINE = Color(90, 210, 255, 160)
local UI_LOCKED = Color(112, 126, 140)
local UI_TEXT_EDGE = Color(0, 0, 0, 170)

local mat_gradientdown = Material("vgui/gradient_down")
local vector_one = Vector(1, 1, 1)

local UI_RADIUS = 18

local function UIFrameTime()
    return FrameTime()
end

local function UILerp(speed, from, to)
    return Lerp(math.Clamp(UIFrameTime() * speed, 0, 1), from, to)
end

local function DrawUIBlock(x, y, w, h, col, radius)
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))

    if RNDX and RNDX.Draw then
        RNDX.Draw(radius, x, y, w, h, col)
    elseif rndx and rndx.Draw then
        rndx.Draw(radius, x, y, w, h, col)
    else
        draw.RoundedBox(radius, x, y, w, h, col)
    end
end

local function DrawUISlant(x, y, w, h, skew, col)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    draw.NoTexture()

    surface.DrawPoly({
        { x = x + skew, y = y },
        { x = x + w + skew, y = y },
        { x = x + w, y = y + h },
        { x = x, y = y + h }
    })
end

local function DrawUIOutline(x, y, w, h, col, radius, thickness)
    radius = math.min(radius or UI_RADIUS, math.floor(math.min(w, h) / 2))
    thickness = thickness or 1

    if RNDX and RNDX.DrawOutlined then
        RNDX.DrawOutlined(radius, x, y, w, h, col, thickness)
    elseif rndx and rndx.DrawOutlined then
        rndx.DrawOutlined(radius, x, y, w, h, col, thickness)
    else
        surface.SetDrawColor(col.r, col.g, col.b, col.a)

        for i = 0, thickness - 1 do
            surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2)
        end
    end
end

local function DrawUIText(text, font, x, y, col, ax, ay)
    draw.SimpleText(text, font, x + 1, y + 1, UI_TEXT_EDGE, ax, ay)
    draw.SimpleText(text, font, x, y, col, ax, ay)
end

local function DrawRotatedText(text, font, x, y, color, ang, scale)
    render.PushFilterMag(TEXFILTER.ANISOTROPIC)
    render.PushFilterMin(TEXFILTER.ANISOTROPIC)

    local m = Matrix()
    m:Translate(Vector(x, y, 0))
    m:Rotate(Angle(0, ang, 0))
    m:Scale(vector_one * (scale or 1))

    surface.SetFont(font)
    local w, h = surface.GetTextSize(text)

    m:Translate(Vector(-w / 2, -h / 2, 0))

    cam.PushModelMatrix(m, true)
        draw.DrawText(text, font, 0, 0, color)
    cam.PopModelMatrix()

    render.PopFilterMag()
    render.PopFilterMin()
end

local function TrimToWidth(text, fontName, maxW)
    text = tostring(text or "")
    surface.SetFont(fontName)

    if surface.GetTextSize(text) <= maxW then
        return text
    end

    local dots = ".."
    local len = utf8.len(text) or #text

    while len > 0 do
        local part = utf8.sub(text, 1, len)

        if surface.GetTextSize(part .. dots) <= maxW then
            return part .. dots
        end

        len = len - 1
    end

    return dots
end

local function DrawHintBubble(cx, cy, text, frac)
    surface.SetFont("HomigradFontMedium")
    local tw, th = surface.GetTextSize(text)

    local pad_x = 14
    local pad_y = 8
    local box_w = tw + pad_x * 2
    local box_h = th + pad_y * 2 + (frac and 8 or 0)

    local x = cx - box_w / 2
    local y = cy

    DrawUIBlock(x, y, box_w, box_h, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, 225), 16)
    DrawUIBlock(x, y, box_w, box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 16), 16)
    DrawUIOutline(x, y, box_w, box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 80), 16, 1)

    DrawUIText(text, "HomigradFontMedium", cx, y + pad_y, UI_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    if frac then
        frac = math.Clamp(frac, 0, 1)
        local bw = box_w - 10
        local bh = 4
        local bx = x + 5
        local by = y + box_h - 6

        DrawUIBlock(bx, by, bw, bh, Color(255, 255, 255, 12), 4)
        DrawUIBlock(bx, by, bw * frac, bh, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 210), 4)
    end

    return box_h
end

hook.Add("HUDPaint", "HMCD_SubRoles_Abilities", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply)
    local after_text_offset = 10
    local y_offset = 30 + ScreenScale(15)

    if not ply:Alive() then return end
    if not ply.isTraitor then return end

    if ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe" then
        local text = "(ДЕРЖИ)[ALT + E] Сломать шею"
        local cx = trace and trace.HitPos:ToScreen().x or ScrW() * 0.5
        local cy = trace and trace.HitPos:ToScreen().y or ScrH() * 0.5
        cy = cy + y_offset

        if (IsValid(aim_ent) and other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent)) or ply.Ability_NeckBreak then
            local frac = ply.Ability_NeckBreak and ply.Ability_NeckBreak.Progress / 100 or nil
            local h = DrawHintBubble(cx, cy, text, frac)
            y_offset = y_offset + h + after_text_offset
        end

        if IsValid(aim_ent) and aim_ent:IsRagdoll() then
            local text2 = "[ALT + R] Сменить внешность"
            local cx2 = trace and trace.HitPos:ToScreen().x or ScrW() * 0.5
            local cy2 = trace and trace.HitPos:ToScreen().y or ScrH() * 0.5
            local h = DrawHintBubble(cx2, cy2 + y_offset, text2)
            y_offset = y_offset + h + after_text_offset
        end
    end

    if ply.SubRole == "traitor_assasin" or ply.SubRole == "traitor_assasin_soe" or ply.PlayerClassName == "sc_infiltrator" then
        local aim_ent2, other_ply2, trace2 = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
        local text = "(ЗАЖАТЬ)[ALT + E] Схватить и обезоружить"
        local cx = trace2 and trace2.HitPos:ToScreen().x or ScrW() * 0.5
        local cy = trace2 and trace2.HitPos:ToScreen().y or ScrH() * 0.5
        cy = cy + y_offset

        if (IsValid(aim_ent2) and other_ply2 and MODE.CanPlayerDisarmOtherPly(ply, other_ply2, MODE.DisarmReach) and MODE.CanPlayerDisarmOther(ply, aim_ent2, MODE.DisarmReach)) or ply.Ability_Disarm then
            local frac = ply.Ability_Disarm and ply.Ability_Disarm.Progress / 100 or nil
            local h = DrawHintBubble(cx, cy, text, frac)
            y_offset = y_offset + h + after_text_offset
        end
    end

    if ply.SubRole == "traitor_chemist" then
        local after_side_bar_offset = 8
        local bar_border = 6
        local bar_width = ScreenScale(22)
        local bar_height = ScreenScale(92)
        local bar_y = (ScrH() - bar_height) / 2
        local bar_x = ScrW() - after_side_bar_offset

        ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
        ply.PassiveAbility_VGUI_ChemicalAccumulation = ply.PassiveAbility_VGUI_ChemicalAccumulation or {}

        local chem_names = {}

        for chemical_name in pairs(ply.PassiveAbility_ChemicalAccumulation) do
            chem_names[#chem_names + 1] = chemical_name
        end

        table.sort(chem_names)

        for _, chemical_name in ipairs(chem_names) do
            local amt = ply.PassiveAbility_ChemicalAccumulation[chemical_name]
            ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] or 0
            ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = Lerp(FrameTime() * 3, ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name], amt)

            if ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] > 0.1 then
                local x = bar_x - bar_width
                local y = bar_y
                local frac = math.min(ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] / 100, 1)
                local fillH = (bar_height - bar_border * 2) * frac
                local fillY = y + bar_height - bar_border - fillH

                DrawUIBlock(x, y, bar_width, bar_height, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, 228), 14)
                DrawUIBlock(x, y, bar_width, bar_height, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 16), 14)
                DrawUIOutline(x, y, bar_width, bar_height, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 90), 14, 1)
                DrawUIBlock(x + bar_border, fillY, bar_width - bar_border * 2, fillH, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 215), 8)

                render.SetScissorRect(x + bar_border, fillY, x + bar_width - bar_border, fillY + fillH, true)
                    surface.SetDrawColor(255, 255, 255, 28)
                    surface.SetMaterial(mat_gradientdown)
                    surface.DrawTexturedRect(x + bar_border, y + bar_border, bar_width - bar_border * 2, bar_height - bar_border * 2)
                render.SetScissorRect(0, 0, 0, 0, false)

                local tcx = x + bar_width / 2
                local tcy = y + bar_height / 2
                DrawRotatedText(chemical_name, "HomigradFontMedium", tcx + 1, tcy + 1, Color(0, 0, 0, 210), 90, 1)
                DrawRotatedText(chemical_name, "HomigradFontMedium", tcx, tcy, UI_TEXT, 90, 1)

                bar_x = bar_x - bar_width - after_side_bar_offset
            end
        end
    end
end)

surface.CreateFont("TraitorPanelTitle", {
    font = "Montserrat SemiBold",
    extended = true,
    size = 24,
    weight = 600,
    antialias = true
})

surface.CreateFont("TraitorPanelText", {
    font = "Montserrat Medium",
    extended = true,
    size = 18,
    weight = 500,
    antialias = true
})

surface.CreateFont("TraitorPanelWords", {
    font = "Montserrat SemiBold",
    extended = true,
    size = 22,
    weight = 600,
    antialias = true
})

surface.CreateFont("TraitorPanelSmall", {
    font = "Montserrat Medium",
    extended = true,
    size = 16,
    weight = 500,
    antialias = true
})

local traitor_panel = {
    visible = true,
    was_traitor = false,
    opened_for_traitor = false,
    dead_anim = {},
    last_toggle_time = 0,
    toggle_cooldown = 0.3,
    min_width = 300,
    max_width = 560,
    min_height = 210,
    smooth_toggle = 0,
    current_width = 320,
    current_height = 230,
    padding = 16,
    inner_padding = 14,
    section_gap = 12,
    row_height = 24
}

local function GetVisibleAssistants(ply)
    MODE.TraitorsLocal = MODE.TraitorsLocal or {}

    local self_name = ply.CurAppearance and ply.CurAppearance.AName or nil
    local visible_assistants = {}

    for _, traitor_info in ipairs(MODE.TraitorsLocal) do
        if traitor_info and #traitor_info >= 2 then
            local tname = traitor_info[2]

            if not self_name or tname ~= self_name then
                visible_assistants[#visible_assistants + 1] = traitor_info
            end
        end
    end

    return visible_assistants
end

local function GetAssistantAliveState(local_ply, name)
    for _, v in player.Iterator() do
        if v ~= local_ply and v.isTraitor and v.CurAppearance and v.CurAppearance.AName == name then
            return v:Alive() and (not v.organism or not v.organism.incapacitated)
        end
    end

    return true
end

local function MeasureTraitorPanel(ply, assistants)
    local word1 = MODE.TraitorWord or "???"
    local word2 = MODE.TraitorWordSecond or "???"

    surface.SetFont("TraitorPanelWords")
    local word1_w = surface.GetTextSize(word1)
    local word2_w = surface.GetTextSize(word2)

    surface.SetFont("TraitorPanelText")
    local secret_title_w = surface.GetTextSize("Секретные слова")
    local assistants_title_w = surface.GetTextSize("Предатели")
    local empty_w = surface.GetTextSize("Другие предатели отсутствуют")

    local assistant_count = #assistants
    local use_two_columns = assistant_count > 1
    local column_gap = use_two_columns and 12 or 0
    local left_count = use_two_columns and math.ceil(assistant_count / 2) or assistant_count
    local right_count = use_two_columns and assistant_count - left_count or 0

    local left_max_w = 0
    local right_max_w = 0

    for i, traitor_info in ipairs(assistants) do
        local name = tostring(traitor_info[2] or "???")
        local text = tostring(i) .. ". " .. name .. " [МЕРТВ]"
        local tw = surface.GetTextSize(text)

        if use_two_columns and i > left_count then
            right_max_w = math.max(right_max_w, tw)
        else
            left_max_w = math.max(left_max_w, tw)
        end
    end

    local header_h = 54
    local words_box_h = 84
    local assistant_rows = use_two_columns and math.ceil(assistant_count / 2) or assistant_count
    assistant_rows = math.max(assistant_rows, 1)

    local row_h = 24

    if assistant_rows > 5 then
        row_h = 22
    end

    traitor_panel.row_height = row_h

    local assistant_content_h = 24 + assistant_rows * row_h + traitor_panel.inner_padding * 2

    if assistant_count <= 0 then
        assistant_content_h = 24 + 30 + traitor_panel.inner_padding * 2
    end

    local word_content_w = math.max(secret_title_w, word1_w, word2_w) + traitor_panel.inner_padding * 2 + 20
    local assistant_content_w

    if assistant_count > 0 then
        if use_two_columns then
            assistant_content_w = left_max_w + right_max_w + column_gap + traitor_panel.inner_padding * 2 + 34
        else
            assistant_content_w = math.max(assistants_title_w, left_max_w) + traitor_panel.inner_padding * 2 + 18
        end
    else
        assistant_content_w = math.max(assistants_title_w, empty_w) + traitor_panel.inner_padding * 2 + 18
    end

    local target_w = math.max(traitor_panel.min_width, word_content_w, assistant_content_w, 320)
    target_w = math.min(target_w, math.min(traitor_panel.max_width or 560, ScrW() - 40))

    local target_h = traitor_panel.padding * 2 + header_h + traitor_panel.section_gap + words_box_h + traitor_panel.section_gap + assistant_content_h
    target_h = math.max(target_h, traitor_panel.min_height)
    target_h = math.min(target_h, ScrH() - 40)

    return {
        width = target_w,
        height = target_h,
        header_h = header_h,
        words_box_h = words_box_h,
        assistant_box_h = assistant_content_h,
        use_two_columns = use_two_columns,
        left_count = left_count,
        right_count = right_count,
        column_gap = column_gap,
        word1 = word1,
        word2 = word2
    }
end

hook.Add("PlayerButtonDown", "TraitorPanelToggle", function(ply, btn)
    if ply ~= LocalPlayer() or btn ~= KEY_F7 then return end
    if not LocalPlayer().isTraitor then return end

    local current_time = CurTime()

    if current_time - traitor_panel.last_toggle_time < traitor_panel.toggle_cooldown then
        return
    end

    traitor_panel.last_toggle_time = current_time
    traitor_panel.visible = not traitor_panel.visible

    if traitor_panel.visible then
        surface.PlaySound("buttons/button14.wav")
    end
end)

hook.Add("Think", "TraitorPanelAutoOpen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if ply.isTraitor and ply:Alive() then
        if not traitor_panel.opened_for_traitor then
            traitor_panel.visible = true
            traitor_panel.smooth_toggle = traitor_panel.current_width + 56
            traitor_panel.last_toggle_time = CurTime()
            traitor_panel.opened_for_traitor = true
        end
    else
        traitor_panel.visible = false
        traitor_panel.opened_for_traitor = false
        traitor_panel.was_traitor = false
    end

    traitor_panel.was_traitor = ply.isTraitor or false
end)

hook.Add("HUDPaint", "DrawTraitorPanel", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply.isTraitor or not ply:Alive() then
        traitor_panel.visible = false
        traitor_panel.opened_for_traitor = false
        return
    end

    if not traitor_panel.opened_for_traitor then
        traitor_panel.visible = true
        traitor_panel.opened_for_traitor = true
    end

    local assistants = GetVisibleAssistants(ply)
    local layout = MeasureTraitorPanel(ply, assistants)

    traitor_panel.current_width = UILerp(10, traitor_panel.current_width or layout.width, layout.width)
    traitor_panel.current_height = UILerp(10, traitor_panel.current_height or layout.height, layout.height)

    local target_slide = traitor_panel.visible and 0 or (traitor_panel.current_width + 56)
    traitor_panel.smooth_toggle = UILerp(10, traitor_panel.smooth_toggle or target_slide, target_slide)

    if traitor_panel.smooth_toggle > traitor_panel.current_width + 45 then
        return
    end

    local x = ScrW() - traitor_panel.current_width - 20 + traitor_panel.smooth_toggle
    local y = ScrH() * 0.5 - traitor_panel.current_height * 0.5

    if y < 20 then
        y = 20
    end

    if y + traitor_panel.current_height > ScrH() - 20 then
        y = ScrH() - traitor_panel.current_height - 20
    end

    local visible_frac = 1 - math.Clamp(traitor_panel.smooth_toggle / (traitor_panel.current_width + 56), 0, 1)
    local a = 255 * visible_frac
    local pulse = 0.5 + math.sin(CurTime() * 2.2) * 0.5

    DrawUIBlock(x, y, traitor_panel.current_width, traitor_panel.current_height, Color(UI_DARK.r, UI_DARK.g, UI_DARK.b, a * 0.95), 24)
    DrawUIBlock(x, y, traitor_panel.current_width, traitor_panel.current_height, Color(UI_MAIN_SOFT.r, UI_MAIN_SOFT.g, UI_MAIN_SOFT.b, a * (0.02 + pulse * 0.012)), 24)
    DrawUIOutline(x, y, traitor_panel.current_width, traitor_panel.current_height, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.48), 24, 2)
    DrawUIOutline(x + 3, y + 3, traitor_panel.current_width - 6, traitor_panel.current_height - 6, Color(255, 255, 255, a * 0.025), 22, 1)

    local content_x = x + traitor_panel.padding
    local content_w = traitor_panel.current_width - traitor_panel.padding * 2
    local cursor_y = y + traitor_panel.padding

    DrawUIBlock(content_x, cursor_y, content_w, layout.header_h, Color(UI_DARK_SOFT.r, UI_DARK_SOFT.g, UI_DARK_SOFT.b, a * 0.92), 18)
    DrawUIBlock(content_x, cursor_y, content_w, layout.header_h, Color(255, 255, 255, a * 0.02), 18)
    DrawUIOutline(content_x, cursor_y, content_w, layout.header_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.2), 18, 1)

    local brand_cx = x + traitor_panel.current_width * 0.5
    local title_text = "ПРЕДАТЕЛЬ"

    surface.SetFont("TraitorPanelTitle")
    local title_w = surface.GetTextSize(title_text)

    DrawUISlant(brand_cx - title_w * 0.5 - 20, cursor_y + 11, 4, 13, 4, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.9))
    DrawUISlant(brand_cx + title_w * 0.5 + 12, cursor_y + 11, 4, 13, 4, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.9))
    DrawUIText(title_text, "TraitorPanelTitle", brand_cx, cursor_y + 17, Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    surface.SetFont("TraitorPanelSmall")
    local brand_w = surface.GetTextSize("OT-")
    local city_w = surface.GetTextSize("CITY")
    local hint_text = "  •  F7 — скрыть"
    local hint_w = surface.GetTextSize(hint_text)
    local brand_x = brand_cx - (brand_w + city_w + hint_w) * 0.5

    DrawUIText("OT-", "TraitorPanelSmall", brand_x, cursor_y + 38, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawUIText("CITY", "TraitorPanelSmall", brand_x + brand_w, cursor_y + 38, Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawUIText(hint_text, "TraitorPanelSmall", brand_x + brand_w + city_w, cursor_y + 38, Color(UI_MUTED.r, UI_MUTED.g, UI_MUTED.b, a * 0.95), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    cursor_y = cursor_y + layout.header_h + traitor_panel.section_gap

    DrawUIBlock(content_x, cursor_y, content_w, layout.words_box_h, Color(UI_CARD.r, UI_CARD.g, UI_CARD.b, a * 0.93), 18)
    DrawUIBlock(content_x, cursor_y, content_w, layout.words_box_h, Color(255, 255, 255, a * 0.016), 18)
    DrawUIOutline(content_x, cursor_y, content_w, layout.words_box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.16), 18, 1)

    DrawUIText("Секретные слова", "TraitorPanelText", x + traitor_panel.current_width * 0.5, cursor_y + 17, Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, a * 0.95), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    DrawUIText(layout.word1, "TraitorPanelWords", x + traitor_panel.current_width * 0.5, cursor_y + 42, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    DrawUIText(layout.word2, "TraitorPanelWords", x + traitor_panel.current_width * 0.5, cursor_y + 66, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    cursor_y = cursor_y + layout.words_box_h + traitor_panel.section_gap

    DrawUIBlock(content_x, cursor_y, content_w, layout.assistant_box_h, Color(UI_CARD_SOFT.r, UI_CARD_SOFT.g, UI_CARD_SOFT.b, a * 0.93), 18)
    DrawUIBlock(content_x, cursor_y, content_w, layout.assistant_box_h, Color(255, 255, 255, a * 0.012), 18)
    DrawUIOutline(content_x, cursor_y, content_w, layout.assistant_box_h, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.16), 18, 1)

    DrawUIText("Предатели", "TraitorPanelText", x + traitor_panel.current_width * 0.5, cursor_y + 17, Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, a * 0.95), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local list_y = cursor_y + 34
    local inner_x = content_x + traitor_panel.inner_padding
    local inner_w = content_w - traitor_panel.inner_padding * 2
    local column_gap = layout.column_gap

    if #assistants > 0 then
        local left_w
        local right_w

        if layout.use_two_columns then
            left_w = math.floor((inner_w - column_gap) * 0.5)
            right_w = inner_w - left_w - column_gap
        else
            left_w = inner_w
            right_w = 0
        end

        for i, traitor_info in ipairs(assistants) do
            local name = tostring(traitor_info[2] or "???")
            local is_alive = GetAssistantAliveState(ply, name)

            if not is_alive then
                traitor_panel.dead_anim[name] = traitor_panel.dead_anim[name] or 255
                traitor_panel.dead_anim[name] = math.max(traitor_panel.dead_anim[name] - FrameTime() * 100 * 3, 0)

                if traitor_panel.dead_anim[name] <= 0 then
                    continue
                end
            else
                traitor_panel.dead_anim[name] = nil
            end

            local row
            local draw_x
            local draw_w

            if layout.use_two_columns then
                if i <= layout.left_count then
                    row = i - 1
                    draw_x = inner_x
                    draw_w = left_w
                else
                    row = i - layout.left_count - 1
                    draw_x = inner_x + left_w + column_gap
                    draw_w = right_w
                end
            else
                row = i - 1
                draw_x = inner_x
                draw_w = left_w
            end

            local row_y = list_y + row * traitor_panel.row_height
            local alpha = (traitor_panel.dead_anim[name] or 255) * visible_frac
            local row_bg_alpha = is_alive and 28 or 14
            local marker_color = is_alive and UI_MAIN or UI_LOCKED
            local text_color = is_alive and Color(UI_TEXT.r, UI_TEXT.g, UI_TEXT.b, alpha) or Color(UI_LOCKED.r, UI_LOCKED.g, UI_LOCKED.b, alpha)
            local status = is_alive and "" or " [МЕРТВ]"
            local label = tostring(i) .. ". " .. name .. status
            label = TrimToWidth(label, "TraitorPanelText", draw_w - 26)

            DrawUIBlock(draw_x, row_y, draw_w, traitor_panel.row_height - 2, Color(UI_DARK_SOFT.r, UI_DARK_SOFT.g, UI_DARK_SOFT.b, row_bg_alpha * visible_frac), 10)
            DrawUIOutline(draw_x, row_y, draw_w, traitor_panel.row_height - 2, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, 18 * visible_frac), 10, 1)
            DrawUIBlock(draw_x + 6, row_y + 5, 6, traitor_panel.row_height - 12, Color(marker_color.r, marker_color.g, marker_color.b, math.min(alpha, 230)), 3)

            DrawUIText(label, "TraitorPanelText", draw_x + 18, row_y + traitor_panel.row_height * 0.5 - 1, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    else
        DrawUIBlock(inner_x, list_y + 2, inner_w, 26, Color(UI_DARK_SOFT.r, UI_DARK_SOFT.g, UI_DARK_SOFT.b, a * 0.22), 12)
        DrawUIOutline(inner_x, list_y + 2, inner_w, 26, Color(UI_MAIN.r, UI_MAIN.g, UI_MAIN.b, a * 0.1), 12, 1)
        DrawUIText("Другие предатели отсутствуют", "TraitorPanelText", x + traitor_panel.current_width * 0.5, list_y + 15, Color(UI_MUTED.r, UI_MUTED.g, UI_MUTED.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("PostPlayerDeath", "ClearTraitorPanel", function(ply)
    if ply == LocalPlayer() then
        traitor_panel.dead_anim = {}
        traitor_panel.smooth_toggle = 0
        traitor_panel.visible = false
        traitor_panel.was_traitor = false
        traitor_panel.opened_for_traitor = false
    end
end)

hook.Add("Think", "UpdateTraitorAssistants", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply.isTraitor then return end

    if not traitor_panel.next_assistant_check or traitor_panel.next_assistant_check < CurTime() then
        traitor_panel.next_assistant_check = CurTime() + 0.5

        for name in pairs(traitor_panel.dead_anim) do
            local is_alive = false

            for _, v in player.Iterator() do
                if v.isTraitor and v.CurAppearance and v.CurAppearance.AName == name then
                    is_alive = v:Alive() and (not v.organism or not v.organism.incapacitated)
                    break
                end
            end

            if is_alive then
                traitor_panel.dead_anim[name] = nil
            end
        end
    end
end)

MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "hud loaded\n")
