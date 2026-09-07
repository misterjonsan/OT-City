CreateClientConVar('mantle_depth_ui', 1, true, false)
CreateClientConVar('mantle_theme', 'green', true, false)
CreateClientConVar('mantle_blur', 1, true, false)

Mantle.ui = {
    convar = {
        depth_ui = GetConVar('mantle_depth_ui'):GetBool(),
        theme = 'green',
        blur = GetConVar('mantle_blur'):GetBool()
    }
}

local LOCKED_THEME = 'green'

local themeMap = {
    dark = Mantle.color_dark,
    dark_mono = Mantle.color_dark_mono,
    graphite = Mantle.color_graphite,
    light = Mantle.color_light,
    blue = Mantle.color_blue,
    red = Mantle.color_red,
    green = Mantle.color_green,
    orange = Mantle.color_orange,
    purple = Mantle.color_purple,
    coffee = Mantle.color_coffee,
    ice = Mantle.color_ice,
    wine = Mantle.color_wine,
    violet = Mantle.color_violet,
    moss = Mantle.color_moss,
    coral = Mantle.color_coral
}

local function isColor(v)
    return type(v) == 'table' and type(v.r) == 'number'
end

local transition = {
    active = false,
    to = nil,
    progress = 0,
    speed = 3,
    colorBlend = 8
}

local function ForceCoffeeTheme()
    local convar = GetConVar('mantle_theme')
    if convar and convar:GetString() ~= LOCKED_THEME then
        RunConsoleCommand('mantle_theme', LOCKED_THEME)
    end

    Mantle.ui.convar.theme = LOCKED_THEME
    Mantle.color = table.Copy(Mantle.color_coffee)
end

local function startThemeTransition(_)
    transition.to = table.Copy(Mantle.color_coffee)
    transition.active = true
    transition.progress = 0

    if not hook.GetTable().MantleThemeTransition then
        hook.Add('Think', 'MantleThemeTransition', function()
            if not transition.active then return end

            local dt = FrameTime()
            transition.progress = Mantle.func.approachExp(transition.progress, 1, transition.speed, dt)

            local to = transition.to
            if not to then
                transition.active = false
                hook.Remove('Think', 'MantleThemeTransition')
                return
            end

            for k, v in pairs(to) do
                if isColor(v) then
                    Mantle.color[k] = Mantle.func.LerpColor(transition.colorBlend, Mantle.color[k] or v, v)
                elseif type(v) == 'table' and #v > 0 then
                    Mantle.color[k] = Mantle.color[k] or {}
                    for i = 1, #v do
                        local vi = v[i]
                        if isColor(vi) then
                            Mantle.color[k][i] = Mantle.func.LerpColor(
                                transition.colorBlend,
                                (Mantle.color[k] and Mantle.color[k][i]) or vi,
                                vi
                            )
                        else
                            Mantle.color[k][i] = vi
                        end
                    end
                end
            end

            if transition.progress >= 0.999 then
                Mantle.color = table.Copy(Mantle.color_coffee)
                Mantle.ui.convar.theme = LOCKED_THEME
                transition.active = false
                hook.Remove('Think', 'MantleThemeTransition')
            end
        end)
    end
end

local function ApplyInitialTheme()
    ForceCoffeeTheme()
end

ApplyInitialTheme()

cvars.AddChangeCallback('mantle_depth_ui', function(_, _, newValue)
    Mantle.ui.convar.depth_ui = newValue == '1'
end)

cvars.AddChangeCallback('mantle_theme', function(_, _, newValue)
    if newValue ~= LOCKED_THEME then
        timer.Simple(0, function()
            if GetConVar('mantle_theme') then
                RunConsoleCommand('mantle_theme', LOCKED_THEME)
            end
            Mantle.ui.convar.theme = LOCKED_THEME
            startThemeTransition(LOCKED_THEME)
        end)
        return
    end

    Mantle.ui.convar.theme = LOCKED_THEME
    startThemeTransition(LOCKED_THEME)
end)

cvars.AddChangeCallback('mantle_blur', function(_, _, newValue)
    Mantle.ui.convar.blur = newValue == '1'
end)

hook.Add('InitPostEntity', 'MantleForceCoffeeTheme', function()
    ForceCoffeeTheme()
end)

hook.Add('Think', 'MantleThemeLock', function()
    local convar = GetConVar('mantle_theme')
    if not convar then return end

    if convar:GetString() ~= LOCKED_THEME or Mantle.ui.convar.theme ~= LOCKED_THEME then
        ForceCoffeeTheme()
    end
end)