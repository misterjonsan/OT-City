local accessor_fn = esclib.accessor
local PANEL={}

local allowed = {
    ["remove"]=true,
    ["hide"]=true
}

-- AccessorFunc(PANEL, "current_panel", "CurrentPanel")
accessor_fn(PANEL, "switch_method", "SwitchMethod", "remove", function(val)
    val = val or ""
    assert(allowed[val], "Wrong switch method provided: '"..val.."' Allowed: 'remove' or 'hide")
    return val
end)

function PANEL:Init()
    self.current_panel = ""
    self.generated_panels = {}
    self.generators = {}
end

function PANEL:AddPage(name, func)
    self.generators[name] = func
    timer.Simple(0, function()
        if not IsValid(self) then return end
        if self.current_panel ~= "" then return end

        self:Switch(name)
    end)

    -- if self.current_panel == "" then
    --     self:Switch(name)
    -- end
    -- self:SetCurrentPanel(nil)
end

function PANEL:RemovePage(name)
    self.generators[name] = nil
end

function PANEL:HasPage(name)
    return self.generators[name] ~= nil
end

function PANEL:GetActivePage()
    return self.current_panel
end

function PANEL:SetCurrentPanel(name)
    self.current_panel = name
    self:OnChange(name)
end

function PANEL:GetCurrentPanel()
    return self.current_panel
end


function PANEL:OnChange(name)
    -- For override
end

function PANEL:CheckValid()
    local valid = {}
    for _,v in ipairs(self.generated_panels) do
        if IsValid(v) then
            table.insert(valid, v)
        end
    end
    self.generated_panels = valid
end

function PANEL:Switch(name, ...)
    local method = self.switch_method
    name = name or ""

    local need_to_gen = true
    if method == "remove" then
        self:Clear()
        self:CheckValid()
    elseif method == "hide" then
        for _,v in ipairs(self.generated_panels) do
            if v.name ~= name then
                v:Hide()
            else
                v:Show()
                self:SetCurrentPanel(v.name)
                need_to_gen = false
            end
        end
    end

    if not self.generators[name] then return end

    if need_to_gen then
        local generated_bg = self:Add("EditablePanel")
        local px,py,pw,ph = self:GetDockMargin()
        generated_bg:SetSize(self:GetWide()-(px+pw), self:GetTall()-(py+ph))
        generated_bg.name = name
        generated_bg.Paint = nil
        accessor_fn(generated_bg, "name", "Name", name, "string")
        table.insert(self.generated_panels, generated_bg)

        self.generators[name](generated_bg, generated_bg:GetWide(), generated_bg:GetTall(), unpack({...} or {}))
        self:SetCurrentPanel(name)
    end
end

function PANEL:Paint()
    --for override
end

vgui.Register( "esclib.switchmenu", PANEL );