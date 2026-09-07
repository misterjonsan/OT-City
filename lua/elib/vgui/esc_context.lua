local PANEL={}
AccessorFunc(PANEL, "color", "Color", FORCE_COLOR)
AccessorFunc(PANEL, "border_color", "BorderColor", FORCE_COLOR)
AccessorFunc(PANEL, "enable_layouting", "EnableLayouting")
AccessorFunc(PANEL, "headerfont", "HeaderFont")
AccessorFunc(PANEL, "buttonfont", "ButtonFont")
AccessorFunc(PANEL, "maxheight", "MaxHeight")


function PANEL:Init()

	self.clr = esclib.addon:GetColors()

	self:SetColor(self.clr.button.main)
	self:SetBorderColor(self.clr.button.hover)
	self:SetEnableLayouting(true)

	local parent = self:GetParent()
	local outpnl = vgui.Create("DButton",parent)
	outpnl:SetSize(parent:GetWide(),parent:GetTall())
	outpnl:SetText("")
	outpnl:SetZPos(10)
	outpnl.Paint = nil
	outpnl:SetCursor("arrow")
	self.contextbackground = outpnl
	function outpnl.Close(pnl)
		pnl:SizeTo(1,1,0.1,0,-1,function()
			if self.OnClose then self:OnClose() end
			pnl:Remove()
		end)
	end
	function outpnl.DoClick()
		outpnl:Close()
		if IsValid(self) then self:Close(true) end
	end
	function outpnl.DoRightClick()
		outpnl:Close()
		if IsValid(self) then self:Close(true) end
	end
	parent.contextbg = outpnl

	self:SetHeaderFont(esclib:AdaptiveFont("esclib", 18, 500))
	self:SetButtonFont(esclib:AdaptiveFont("esclib", 18, 500))
	self.subMenus = {}

	self.next_check = 0
	self.border = esclib:AdaptiveSize(5)
	self.buttonheight = math.max(draw.GetFontHeight(self:GetHeaderFont()),draw.GetFontHeight(self:GetButtonFont())) + 10
	self.sepheight = 2
	self.spacey = 0

	self.player = LocalPlayer()
	self:SetParent(outpnl)

	self:SetSize(100,self.buttonheight)
	self:SetMaxHeight(0) -- 0 means no limit
	
	-- Create scrollpanel as container
	self.scrollpanel = vgui.Create("esclib.scrollpanel", self)
	self.scrollpanel:SetPos(0, 0)
	self.scrollpanel:SetSize(self:GetWide(), self:GetTall())
	
	-- Create DIconLayout inside scrollpanel
	self.list = vgui.Create("DIconLayout", self.scrollpanel)
	self.list:SetBorder(self.border)
	self.list:SetSpaceY(self.spacey)
	self.list:SetSize(self:GetWide()+self.list:GetBorder()*2,self:GetSize())
end

function PANEL:SetWide(wide)
	self:SetSize(wide+self.list:GetBorder()*2,self:GetTall())
	self.scrollpanel:SetSize(self:GetWide(), self:GetTall())
	self.list:SetSize(wide+self.list:GetBorder()*2,self:GetTall())
end

function PANEL:SetBorder(border)
	self.border = border
	self.list:SetBorder(border)
end

function PANEL:GetBorder()
	return self.border
end

function PANEL:Close(anim)
	if anim then

		self:SizeTo(1,1,esclib.addon:GetVar("animtime"),0,-1,function()
			if self.OnClose then self:OnClose() end
			self:Remove()
			if IsValid(self.contextbackground) then self.contextbackground:Remove() end
		end)

	else
		if self.OnClose then self:OnClose() end
		self:Remove()
		if IsValid(self.contextbackground) then self.contextbackground:Remove() end
	end
end

function PANEL:SetPly(ply)
	self.player = ply
end

function PANEL:GetPly(ply)
	return self.player
end

function PANEL:SetPosClamped(posx,posy)
	local x = math.Clamp( posx, 0, ScrW() - self:GetWide() )
	local y = math.Clamp( posy, 0, ScrH() - self:GetTall() )
	self:SetPos(x,y)
end

function PANEL:E_InvalidateLayout()

	local sizex = 1
	local sizey = 0
	for _,v in ipairs(self.list:GetChildren()) do

		local textsize = {w = 200, h = 100}
		if v.text then
			textsize = esclib.util.GetTextSize(v.text,self:GetButtonFont())
		end
		if v.icon then
			textsize.w = textsize.w + v:GetTall()*0.35 + 10
		end
		sizex = math.max(sizex,textsize.w+40)
		sizey = sizey + v:GetTall() + self.spacey
	end

	local finalHeight = sizey + self.list:GetBorder() * 2
	local maxHeight = self:GetMaxHeight()
	
	-- Apply max height limit if set
	if maxHeight > 0 and finalHeight > maxHeight then
		finalHeight = maxHeight
	end

	self:SetSize(sizex + self.list:GetBorder() * 2, finalHeight)
	
	-- Update scrollpanel size to match panel
	self.scrollpanel:SetSize(self:GetWide(), self:GetTall())
	
	-- Set list size to actual content size for proper scrolling
	self.list:SetSize(self:GetWide(), sizey + self.list:GetBorder() * 2)
	
	self.contextbackground:SetZPos(10)

	if not self.enable_layouting then return end
	for _,v in ipairs(self.list:GetChildren()) do
		v:SetWide(sizex)
		if IsValid(v.lbl) then
			v.lbl:Center()
		end
	end
end

function PANEL:AddButton(text,func,icon)
	local button = vgui.Create("DButton",self.list)
	button:SetSize(self.list:GetWide(), self.buttonheight)
	button:SetText("")

	AccessorFunc(button, "text", "Text")
	AccessorFunc(button, "TextColor", "TextColor", FORCE_COLOR)
	AccessorFunc(button, "TextHoverColor", "TextHoverColor", FORCE_COLOR)
	AccessorFunc(button, "IconColor", "IconColor", FORCE_COLOR)
	AccessorFunc(button, "IconHoverColor", "IconHoverColor", FORCE_COLOR)
	AccessorFunc(button, "Color_Hover", "ColorHover", FORCE_COLOR)
	AccessorFunc(button, "icon", "Icon")
	AccessorFunc(button, "font", "Font")
	AccessorFunc(button, "func", "Func")

	button:SetTextColor(self.clr.button.text)
	button:SetTextHoverColor(self.clr.button.text_hover)
	button:SetIconColor(self.clr.button.text)
	button:SetIconHoverColor(self.clr.button.text_hover)
	button:SetColorHover(self.clr.button.hover)
	button:SetFont(self:GetButtonFont())

	button:SetText(text)
	button:SetIcon(icon)
	button:SetFunc(func)

	function button:Paint(w,h)
		local hover = self:IsHovered()

		if hover then
			draw.RoundedBox(8,0,0,w,h,self.Color_Hover)
		end

		draw.SimpleText(self.text,self.font,self.icon and h*0.3*2+15 or 10,h*0.5,hover and self.TextHoverColor or self.TextColor,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

		if self.icon then
			esclib.draw:MaterialCentered(h*0.35+5, h*0.5, h*0.3, hover and self.TextHoverColor or self.TextColor, self.icon)
		end
	end

	function button.DoClick()
		self:Close()
		button.func(self.player)
	end

	function button:SetTextColor(col)
		if IsColor(col) then self.TextColor = col end
	end

	function button:SetTextHoverColor(col)
		if IsColor(col) then self.TextHoverColor = col end
	end

	function button:SetIconColor(col)
		if IsColor(col) then self.IconColor = col end
	end

	function button:SetIconHoverColor(col)
		if IsColor(col) then self.IconHoverColor = col end
	end

	self:E_InvalidateLayout()
	return button
end

function PANEL:IsMouseInside()
	-- if not self:IsVisible() then return false end
    local mouseX, mouseY = gui.MousePos()
    local panelX, panelY = self:GetPos()
    local panelWide, panelTall = self:GetSize()

    if mouseX >= panelX and mouseX <= panelX + panelWide and mouseY >= panelY and mouseY <= panelY + panelTall then
        return true
    end

    for _, subMenu in ipairs(self.subMenus) do
        if subMenu.IsMouseInside and subMenu:IsMouseInside() then
            return true
        end
    end

    return false
end


function PANEL:OnClick()
	--for override
end

function PANEL:OnClose()
	--for override
end

function PANEL:SetFont(font)
	self.headerfont = font
	self.buttonfont = font
end

function PANEL:AddHeader(text,col)
	local pnl = vgui.Create("DPanel",self.list)

	AccessorFunc(pnl, "TextColor", "TextColor", FORCE_COLOR)
	AccessorFunc(pnl, "font", "Font")

	pnl:SetTextColor(col or self.clr.frame.text)
	pnl:SetFont(self.headerfont)
	pnl:SetSize(self.list:GetWide(), self.buttonheight)
	pnl.text = text
	function pnl.Paint(pnl,w,h)
		-- draw.RoundedBox(8,0,0,w,h,self.clr.frame.accent)
		draw.SimpleText(text, pnl.font, w*0.5, h*0.5, pnl.TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function pnl:SetTextColor(col)
		if IsColor(col) then self.TextColor = col end
	end

	self:E_InvalidateLayout()
	return pnl
end

function PANEL:AddSeparator()
	local pnl = vgui.Create("DPanel",self.list)
	pnl.text = ""
	local sepheight = self.sepheight
	AccessorFunc(pnl, "Color", "Color", FORCE_COLOR)
	pnl:SetSize(self.list:GetWide(), sepheight+self.border)
	pnl:SetColor(self.border_color)
	pnl.Paint = function(pnl, w,h)
		surface.SetDrawColor(pnl.Color)
		surface.DrawRect(0,(h-sepheight)*0.5,w,sepheight)
	end
	self:E_InvalidateLayout()
	return pnl
end


function PANEL:AddSubMenu(text, icon)
	local parent = self
    local subMenu = vgui.Create("esclib.contextmenu", self:GetParent())
    subMenu:SetParent(self:GetParent())
	subMenu:SetZPos(self:GetZPos()+1)
	subMenu:SetColor(self:GetColor())
	subMenu:SetBorderColor(self:GetBorderColor())
	subMenu.contextbackground:Remove()
	subMenu.contextbackground = self.contextbackground
	subMenu:SetMouseInputEnabled(true)
	subMenu.button_hovered = false

	function subMenu.eHide(pnl)
		pnl.hidden = true
		pnl:SetAlpha(0)
		pnl:SetMouseInputEnabled(false)
		self.current_subpanel = nil
	end

	function subMenu.eShow(pnl)
		if IsValid(self.current_subpanel) then
			self.current_subpanel:eHide()
		end

		self.current_subpanel = pnl
		pnl.hidden = false
		pnl:SetAlpha(255)
		pnl:SetMouseInputEnabled(true)
	end

	subMenu:eHide()

	table.insert(self.subMenus, subMenu)

    local button = self:AddButton(text, function() end, icon)
	function button:PaintOver(w,h)
		draw.SimpleText(">", self.font, w-10, h*0.5, self.TextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
	local x,y = button:LocalToScreen(0,0)
	subMenu.parent_button = button

	local next_check = 0
	function subMenu:Think()
		if button:IsHovered() then
			self:eShow()

			local x, y = self.parent_button:LocalToScreen(0, 0)
			self:SetPosClamped(x + self.parent_button:GetWide() + self.border * 2, y-self.border)
			next_check = CurTime() + 0.3
			return
		end

		-- if self.hidden then return end

		if next_check < CurTime() then
			next_check = CurTime() + 0.3

			if not self:IsMouseInside() then
				self:eHide()
				return 
			end
		end
	end

    return button, subMenu
end


function PANEL:Paint(w,h)
	draw.RoundedBox(8,0,0,w,h,self.border_color)
	draw.RoundedBox(6,2,2,w-4,h-4,self.color)
end


vgui.Register( "esclib.contextmenu", PANEL )




-- local function CreateContextExample()
--     local frame = vgui.Create("DFrame")
--     frame:SetSize(400, 300)
--     frame:Center()
--     frame:SetTitle("Context Menu Example")
--     frame:MakePopup()
    
--     local button = vgui.Create("DButton", frame)
--     button:SetSize(200, 50)
--     button:SetPos(100, 125)
--     button:SetText("Right Click Me!")
    
--     function button:DoRightClick()
--         -- Create context menu
--         local context = vgui.Create("esclib.contextmenu")
        
--         -- Set position near mouse cursor
--         local x, y = gui_MousePos()
--         context:SetPosClamped(x, y)
        
--         -- Add header
--         context:AddHeader("Player Actions", Color(255, 255, 255))
        
--         -- Add buttons with icons
--         context:AddButton("Teleport to Player", function(ply)
--             print("Teleporting to player: " .. ply:Nick())
--         end, Material("icon16/user.png"))
        
--         context:AddButton("Give Money", function(ply)
--             print("Giving money to: " .. ply:Nick())
--         end, Material("icon16/money.png"))
        
--         -- Add separator
--         context:AddSeparator()
        
--         -- Add submenu
--         local subButton, subMenu = context:AddSubMenu("Admin Actions", Material("icon16/shield.png"))
        
--         -- Add items to submenu
--         subMenu:AddButton("Kick Player", function(ply)
--             print("Kicking player: " .. ply:Nick())
--         end, Material("icon16/door_out.png"))
        
--         subMenu:AddButton("Ban Player", function(ply)
--             print("Banning player: " .. ply:Nick())
--         end, Material("icon16/stop.png"))
        
--         subMenu:AddButton("Slap Player", function(ply)
--             print("Slapping player: " .. ply:Nick())
--         end, Material("icon16/lightning.png"))
        
--         -- Add another separator
--         context:AddSeparator()
        
--         -- Add more buttons
--         context:AddButton("Copy Steam ID", function(ply)
--             SetClipboardText(ply:SteamID())
--             print("Copied Steam ID: " .. ply:SteamID())
--         end, Material("icon16/page_copy.png"))
        
--         context:AddButton("View Profile", function(ply)
--             ply:ShowProfile()
--         end, Material("icon16/world.png"))
        
--         -- Set custom colors for specific button
--         local customButton = context:AddButton("Dangerous Action", function(ply)
--             print("Dangerous action performed on: " .. ply:Nick())
--         end, Material("icon16/exclamation.png"))
        
--         customButton:SetTextColor(Color(255, 100, 100))
--         customButton:SetTextHoverColor(Color(255, 150, 150))
--         customButton:SetColorHover(Color(100, 0, 0))
        
--         -- Set max height to enable scrolling
--         context:SetMaxHeight(300)
        
--         -- Custom close callback
--         function context:OnClose()
--             print("Context menu closed")
--         end
--     end
-- end