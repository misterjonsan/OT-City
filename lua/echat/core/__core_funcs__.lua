local gm = GM or GAMEMODE
local netstream = esclib.netstream

function echat:IsTeamChat()
	local mode = echat.bg.mode_pnl:GetText()
	local chat_mode = echat.chat_modes[mode]
	return (mode == echat.addon:Translate("chat_mode_team"))
end

--Override GM:OnPlayerChat to empty function
function gm:OnPlayerChat() end

local function limitStringLength(input, maxLength)
    if #input > maxLength then
        return string.sub(input, 1, maxLength).."..."
    end
    return input
end

function echat:SendMessageToServer(text)
	if not text then return end
	local ply = LocalPlayer()

	local text = string.Trim( text, " " )
	text = string.Trim( text, "\n" )
	text = string.Trim( text, " " )
	text = string.Replace( text, "\n", "\\n" )

	if text == "" then
		esclib.print("Tried to send empty message")
		return
	end

	local is_team = echat:IsTeamChat()

	text=limitStringLength(text, echat.config.max_message_len)

	netstream.Start("echat.Message", is_team, text)
end

function echat:IsValid()
	return IsValid(self.bg)
end

--------------------------
-- CLOSE / OPEN RELATED --
--------------------------
function echat:IsOpened()
	if not self:IsValid() then return false end
	return self.chatbox.opened
end

local mouse_pos = {x=0, y=0}
function echat:Open(mode)
	if not self:IsValid() then return end

	self.chatbox.opened_panel:Show()
	self.chatbox.close_button:Show()

	self.chatbox.opened = true
	self.chatbox.opened_panel:SetAlpha(255)

	self.bg:SetMouseInputEnabled(true)
	self.bg:SetKeyboardInputEnabled(true)
	self.chatbox:MakePopup()
	self.chatbox.text_entry:RequestFocus()

	--restore mouse position
	if mouse_pos.x == 0 then mouse_pos.x = (esclib.scrw or 0) * 0.5 end
	if mouse_pos.y == 0 then mouse_pos.y = (esclib.scrh or 0) * 0.5 end
	input.SetCursorPos( mouse_pos.x, mouse_pos.y )

	hook.Run("StartChat", mode == echat.addon:Translate("chat_mode_team"))
	if mode then
		self.bg.mode_pnl:SetText(mode)
		local tw, th = esclib.util:TextSize(mode,self.bg.mode_pnl:GetFont())
		self.bg.mode_pnl:SetWide(tw+30)
	end

end

function echat:Close()
	if not self:IsValid() then return end

	--Save mouse position
	local mx,my = input.GetCursorPos()
	mouse_pos.x = mx
	mouse_pos.y = my

	self.chatbox.opened_panel:Hide()
	self.chatbox.close_button:Hide()
	CloseDermaMenus()
	self.chatbox.opened = false
	
	--clean chat on close
	if echat.addon:GetVar("clean_chat") then
		self.chatbox.text_entry:SetText("")
	end

	self.bg:SetMouseInputEnabled(false)
	self.bg:SetKeyboardInputEnabled(false)
	self.chatbox:SetMouseInputEnabled(false)
	self.chatbox:SetKeyboardInputEnabled(false)
	timer.Simple(0,function() --gmod thing
		hook.Run("FinishChat")
	end)
end

function echat:Restart()
	if self:IsValid() then
		self.bg:Remove() 
	end
	self:Build()
end

function chat.GetChatBoxPos()
	return echat.chatbox:GetPos()
end

function chat.GetChatBoxSize()
	return echat.chatbox:GetSize()
end

function echat:GetRichtext()
	return IsValid(echat.richtext) and echat.richtext or nil
end

function echat:GetBG()
	return IsValid(echat.bg) and echat.bg or nil
end

function echat:GetChatbox()
	return echat.chatbox
end

function echat:GetBottomPanel()
	return echat.bottom_panel
end

function echat:GoToEnd()
	self:GetRichtext():GotoTextEnd()
end

function echat:AddParsedText(parsed)
	-- esclib.print({"Recieved message to add: ", parsed})
	local richtext = self:GetRichtext()
	if richtext then
		local gotoend = (richtext:GetVBar():GetScroll() + 50 > richtext.pnlCanvas:GetTall()-richtext:GetTall())

		hook.Run("echat.OnParsedRetrieved", parsed)
		echat:ConvertParsedToRichtext(richtext, parsed)
		richtext:AppendText("\n") --new line

		if gotoend then
			richtext:GotoTextEnd()
		end
	end
end


-----------
// HOOKS //
-----------
hook.Remove("PlayerBindPress", "echat.override.bind")
hook.Add( "PlayerBindPress", "echat.override.bind", function( ply, bind, isActivated )
	if (bind == "messagemode" or bind == "messagemode2") then

		if isActivated then
			if echat:IsOpened() then
				echat:Close()
			else
				echat:Open((bind == "messagemode2") and echat.addon:Translate("chat_mode_team") or echat.addon:Translate("chat_mode_normal"))
			end
		end

		return true -- Doesn't allow any functions to be called for this bind
	end
end )

--RESOLUTION CHANGE
hook.Add( "OnScreenSizeChanged", "echat.onscreenchange", function(oldw,oldh)
	timer.Simple(1,function() echat:Restart() end)
end)

hook.Add("echat_skin_changed","echat.skin_changed_reload",function(skin_name)
	local skin = echat.addon:GetCurrentSkin()
	if skin then
		echat.skin = skin
		echat:Restart()
	end
end)

hook.Add( "HUDShouldDraw", "echat.shoulddraw.removechat", function( name )
	if name == "CHudChat" then return false end
end )

hook.Add("InitPostEntity","echat_buildhook",function()
	echat:Build()
end)

hook.Add("echat_settings_changed","echat.onsettings_change",function(needrestart, changed_vars)
	if needrestart then
		echat:Restart()
	end
end)

hook.Add("OnPauseMenuShow", "echat.prevent_pause_show", function()
	if echat:IsOpened() then return false end
end)
	




------------------------------------
/// REWRITING ORIGINAL FUNCTIONS ///
------------------------------------
--rewrite original functions
-- table - Color. Will set the color for all following strings until the next Color argument.
-- string - Text to be added to the chat box.
-- Player - Adds the name of the player in the player's team color to the chat box.
-- any - Any other type, such as Entity will be converted to string and added as text.
function chat.AddText(...)
	local parsed = echat:FinalParse(...)
	local parsed = echat:ParseText(parsed)
	echat:AddParsedText(parsed)
	chat.PlaySound()
end

-- local function echatMessageNet(len)
-- 	local from_player = net.ReadBool()
-- 	local ply
-- 	if from_player then
-- 		ply = net.ReadEntity()
-- 	end

-- 	local result = esclib:NetReadCompressedTable()
-- 	if not istable(result) or not result.parsed then return end

-- 	if result.text and from_player and IsValid(ply) then
-- 		if hook.Run("OnPlayerChat", ply, result.text, false, not ply:Alive()) then return end
-- 	end

-- 	echat:AddParsedText(result.parsed)
-- 	chat.PlaySound()
-- end
-- net.Receive("echat.Message", echatMessageNet)

netstream.Hook("echat.Message", function(parsed_text, actual_text, from_player)
	local ply
	if isnumber(from_player) then 
		from_player = Entity(from_player)
	end

	if from_player and IsValid(from_player) then
		ply = from_player
	end

	if not istable(parsed_text) then return end

	if actual_text and from_player and IsValid(ply) then
		if hook.Run("OnPlayerChat", ply, actual_text, false, not ply:Alive()) then return end
	end

	echat:AddParsedText(parsed_text)
	chat.PlaySound()
end)

function chat.Open(mode)
	echat:Open((mode == 1) and echat.addon:Translate("chat_mode_normal") or echat.addon:Translate("chat_mode_team"))
end


-----------------
-- CONCOMMANDS --
-----------------
concommand.Add("echat_print_test", function()
	for k = 0,10 do
		timer.Simple(0.2*k, function()
			local text = "<clr:white>hello world! I am a test message!\n1. Numbers: <clr:pink> "
			for s = 1, 9 do text = text..s end
			text = text.."\n<clr:white>2.<shake:0.5> Shaking text!<shake:end>"
			text = text.."\n3.<clr:gold> Colored text!<clr:white>"
			text = text.."\n4.<rainbow> Rainbow text!<clr:white>"
			text = text.."\n5. Emoji! :bone:"
			text = text.."\n6. <bg_col:255,0,255>Background <bg_col:255,0,0>color!<bg_col:end>"
			text = text.."\n7. <font:es_echatmono_30_500>Any font!"

			local text_parsed = echat:ParseText(echat:FinalParse(text))
			echat:AddParsedText(text_parsed)
			chat.PlaySound()
		end)
	end
end)

concommand.Add("echat_fonts", function()
	PrintTable(echat:GetFonts())
end)

concommand.Add("echat_emojis", function()
	PrintTable(echat:GetEmojiList())
end)

concommand.Add("echat_restart", function()
	if echat:IsValid() then echat:Restart() end
end)

concommand.Add("echat_close", function()
	echat:Close()
end)

concommand.Add("echat_open", function()
	echat:Open()
end)