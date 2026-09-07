timer.Simple(.1, function()
netstream.Hook('BodygroupChanger.Update', function(pl, bodygroupID, bodygroupValue)
    if not IsValid(pl) then return end
    if not isnumber(bodygroupID) or not isnumber(bodygroupValue) then return end

    pl:SetBodygroup(bodygroupID, bodygroupValue)
end)

netstream.Hook('BodygroupChanger.UpdateSkin', function(pl, skinID)
    if not IsValid(pl) then return end
    if not isnumber(skinID) then return end

    pl:SetSkin(skinID)
end)
end)

local chatCommands = {
    ['/clothes'] = true,
    ['/одежда'] = true,
    ['!clothes'] = true,
    ['!одежда'] = true
}

hook.Add('PlayerSay', 'BodygroupChanger.ChatCommand', function(pl, text)
    if chatCommands[text:lower()] then
        pl:ConCommand('bodygroupchanger_menu')
        return ''
    end
end)