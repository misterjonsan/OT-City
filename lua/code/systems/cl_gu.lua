local X,Y = ScrW()/2,ScrH()/2
local menu_BackGround = Color(0,0,0,225)
local menu_Black = Color(0,0,0,250)
local button_BackGround = Color(125,125,125,50)
local button_BackGround_noA = Color(125,125,125,200)
local upBar_Color = button_BackGround
local color_White = Color(255,255,255,255)
local color_White150 = Color(255,255,255,10)
local color_Red = Color(255,75,75,200)

vgui.Register("drusher_gui",{
    Init = function(self)
        self:DockPadding( 0,0,0,0 )
        self:SetTitle( "" ) 
        self:SetVisible( true )
        self:SetDraggable( false ) 
        self:ShowCloseButton( false ) 
        self:MakePopup()
        self.Title = self:Add("DPanel")
        self.Title:Dock(TOP)
		self.Title.text = "none"
        self.Title:DockMargin(0, 0, 0, 5)
        self.Title.Paint = function(self,w,h) 
    		draw.RoundedBox( 0, 0, 0, w , h, upBar_Color )
    		draw.SimpleText(self.text, "GPS_Title2", 5, h*0.5, color_White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    	end
        
		self.Title.CloseBtn = self.Title:Add("DButton" )
        self.Title.CloseBtn:Dock(RIGHT)
        self.Title.CloseBtn:SetText("")
		self.Title.CloseBtn:SetSize(16,16)
        self.Title.CloseBtn:DockMargin(2,2,2,2)
		self.Title.CloseBtn.Paint = function(self, w, h)
            draw.SimpleText("X", "TargetID_18", w*0.5, h*0.5,self:IsHovered() and color_Red or color_White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

		self.Title.CloseBtn.DoClick = function(sel)
			self:Remove()
		end
    end,

    SetRemoveOnLoseFocus = function(self) 

    end,

    SetBlur = function(self,bool,count) 
        self.blur = bool
        self.blur_count = count or 3
    end,

    RemoveCloseButton = function(self) 
        if IsValid(self.Title.CloseBtn) then
            self.Title.CloseBtn:Remove()
        end
    end,
    SetTiteText = function(self,text) 
        self.Title.text = tostring(text)
    end,
    SizeCenter = function(self,w,h) 
        self:SetSize(w,h)
        self:SetPos(X-w/2,Y-h/2)
    end,
    Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, menu_BackGround)
        if self.blur then 
            drusherLib.draw.drawBlur(self,self.blur_count)
        end
    end,
}, "DFrame" )

//
//
//

vgui.Register("Icon_Model",{
    Init = function(self)
        self:DockPadding( 0,0,0,0 )
        self:SetTitle( "" ) 
        self:SetVisible( true )
        self:SetDraggable( false ) 
        self:ShowCloseButton( false )
    end,

    SetModel = function(self,model) 
        self.model_ = self:Add("ModelImage")
        self.model_:SetModel( model or "models/Items/item_item_crate.mdl", "0", "000000000" )
        self.model_:Dock(FILL)
        self.model_:DockMargin(2,2,2,2)
    end,
    SetMatIcon = function(self,icon_id) 
        self.image_ = self:Add("DPanel")
        self.image_:Dock(FILL)
        self.image_:DockMargin(2,2,2,2)
        self.image_.Draw_ = function(self,w,h) 
            surface.SetDrawColor( 255, 255, 255, self.alpha or 255)
            surface.SetMaterial( icon_id ) 
            surface.DrawTexturedRect( 2, 2, w-2, h-2 )
        end
        self.image_.Paint = function(self,w,h) 
            self:Draw_(w,h)
        end
    end,
    SetIcon = function(self,icon_id) 
        self.image_ = self:Add("DPanel")
        self.image_:Dock(FILL)
        self.image_:DockMargin(2,2,2,2)
        self.image_.Draw_ = function(self,w,h) 
            local icon = unisono_materials.getByID(icon_id)
            if icon then
                surface.SetDrawColor( 255, 255, 255, self.alpha or 255)
                surface.SetMaterial( icon ) 
                surface.DrawTexturedRect( 2, 2, w-2, h-2 )
            end
        end
        self.image_.Paint = function(self,w,h) 
            self:Draw_(w,h)
        end
    end,
    Paint = nil
}, "DFrame" )