if CLIENT then

local function on(bg) 
    local richtext_orig = echat:GetRichtext()
    local bottom_panel = echat:GetBottomPanel()
    if not IsValid(richtext_orig) or not IsValid(bottom_panel) then return end

    local messages = {}
    local clr = echat.addon:GetColors()
    local space_y = echat.addon:GetVar("chat_spacey")


    local chatbox = echat:GetChatbox()
    local px, py, pw, ph = chatbox:GetDockPadding()
    local rich_mar_x, _, _, _ = richtext_orig:GetDockMargin()
    local bot_px, bot_py, bot_pw, bot_ph = bottom_panel:GetDockPadding()

    local base_panel = chatbox:Add("DPanel")
    
    base_panel:SetSize(chatbox:GetWide()-px-pw, chatbox:GetTall())
    base_panel:SetX(px + rich_mar_x)
    base_panel:SetMouseInputEnabled(false)
    base_panel:NoClipping(true)
    base_panel.Paint = nil

    hook.Add("echat.InvalidateLayout", "echat.livechat_updatesize", function(x,y,w,h)
        if not IsValid(base_panel) then hook.Remove("echat.InvalidateLayout", "echat.livechat_updatesize") return end

        local chatbox = echat:GetChatbox()
        local px, py, pw, ph = chatbox:GetDockPadding()

        base_panel:SetSize(chatbox:GetWide()-px-pw, chatbox:GetTall())
    end)

    

    local function UpdatePositions()
        if not IsValid(base_panel) then return end
        local totaly = base_panel:GetTall()-bottom_panel:GetTall()-ph
        for k,pnl in ipairs(messages) do
            if not IsValid(pnl) then 
                table.remove(messages, k)
                continue
            end
            
            local tall = pnl:GetTall()

            pnl:MoveTo(pnl:GetX(), totaly-tall, 0.1, 0, 0.5)

            totaly = totaly - tall
        end
    end

    local function NewMessage(parsed)
        if not echat:IsValid() then return end
        if not IsValid(base_panel) then return end

        local x,y = base_panel:LocalToScreen(0,base_panel:GetTall())

        local messages_len = #messages
        if messages_len >= 10 then
            local pnl = messages[messages_len]
            if IsValid(pnl) then
                pnl:Remove()
            end
        end

        local richtext = vgui.Create("echat.richtext", base_panel)
        richtext:SetVerticalScrollbarEnabled(true)
        richtext:SetW(richtext_orig:GetWide())
        richtext:GetVBar():SetColor(Color(255,255,255,0)) --transparent

        local success = pcall(function()
            echat:ConvertParsedToRichtext(richtext, parsed)
            richtext:NoClipping(true)
            richtext:SetTall(richtext.pnlCanvas.CalculateMaxTall())
        end)

        if not success then
            richtext:Remove() 
            return 
        end

        richtext:SetY(base_panel:GetTall()-py-ph-4)

        function richtext:Close()
            richtext:AlphaTo(0, 0.6, 0, function()
                if not IsValid(richtext) then return end
                richtext:Remove()
            end)
        end

        table.insert(messages, 1, richtext)

        xpcall( 
            timer.Simple, 

            function() --on error
                if not IsValid(richtext) then return end
                richtext:Close()
            end,
            
            echat.addon:GetVar("msg_time") or 6, 
            function()
                if not IsValid(richtext) then return end
                richtext:Close()
            end 
        )

        timer.Simple(0,function()
            UpdatePositions()
        end)

    end

    hook.Add("echat.OnParsedRetrieved", "echat.LiveChatHandler", function(parsed)
        if not echat:IsValid() then return end

        NewMessage(parsed)

    end)

    hook.Add("StartChat", "echat.LiveChatOnOpenChat", function(is_team)
        if not IsValid(base_panel) then return end
        base_panel:Hide()
    end)

    hook.Add("FinishChat", "echat.LiveChatOnCloseChat", function()
        if not IsValid(base_panel) then return end
        base_panel:Show()
    end)
end

local function off(bg) 
    hook.Remove("ChatText", "echat.LiveChatHandler")
    hook.Remove("StartChat", "echat.LiveChatOnOpenChat")
    hook.Remove("FinishChat", "echat.LiveChatOnCloseChat")
    hook.Remove("echat.InvalidateLayout", "echat.livechat_updatesize")
end

local function custom_check(bg) 
    return true
end

echat:Module("LiveChat", on, off, custom_check)

end