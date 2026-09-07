local masks = esclib.masks
-- Simplified addon settings panel with modular approach
local PANEL = {}

-- Constants
local REALM_CLIENT = "realm_Client"
local REALM_SERVER = "realm_Server"

function PANEL:Init()
	local scrw, scrh = (esclib and esclib.scrw) or ScrW(), (esclib and esclib.scrh) or ScrH()
	self:SetSize(scrw * 0.7, scrh * 0.8)

	self.margin10 = esclib:AdaptiveSize(10)

	self.font_small = esclib:AdaptiveFont("esclib", 20, 500)
	self.font_medium = esclib:AdaptiveFont("esclib", 22, 500)

	-- State management
	self.current_tab = ""
	self.current_realm = ""  -- Will be set when first tab is activated
	self.current_active_tab_id = ""  -- Store currently active tab ID for refresh
	self.settings_changed = false
	self.changed_vars = {}
	self.tab_buttons = {}  -- Store all tab buttons with realm prefixes

	-- Animation
	self:SetAlpha(0)
	self:AlphaTo(255, esclib.addon:GetVar("animtime") or 0.05)
end

function PANEL:SetCloseHandler(fn)
	self.onCloseAny = fn
end

function PANEL:OnClose()
	if self.onCloseAny then
		self.onCloseAny(self)
	end
end

function PANEL:Setup(addon, addon_list, settings_tab)
	self.addon = addon
	self.addon_list = addon_list or {}
	self.bg_root = settings_tab

	self:InitializeUI()
end

-- Initialize the complete UI structure
function PANEL:InitializeUI()
	if not self.addon then return end

	-- self:SetTitle(self.addon.info.name .. " - " .. esclib.addon:Translate("tab_settings", self.addon:GetLanguage()))

	local content = self:GetContent()
	if IsValid(content) then
		content:Clear()
	end

	self:CreateMainContent()
end


function PANEL:GetContent()
	if IsValid(self.content) then return self.content end
	local clr = esclib.addon:GetColors()
	local draw_blur = esclib.addon:GetVar("drawblur")

	self.content = vgui.Create("Panel", self)
	self.content:Dock(FILL)
	self.content:DockMargin(0, 0, 0, 0)
	self.content:InvalidateParent(true)
	function self.content:Paint(w,h)
		masks.Start()
			masks.DrawBlur(self)
			draw.RoundedBox(0, 0, 0, w, h, clr.background.col)
		masks.Source()
			draw.RoundedBox(16, 0, 0, w, h, esclib.white)
		masks.End()
	end

	return self.content
end


-- Refresh panel maintaining current state
function PANEL:RefreshPanel()
	-- Use stored active tab ID
	local current_active_tab = self.current_active_tab_id
	
	timer.Simple(0, function()
		if IsValid(self) then
			self:InitializeUI()
			
			-- Restore active tab after refresh
			timer.Simple(0.1, function()
				if IsValid(self) and current_active_tab ~= "" and self.tab_buttons[current_active_tab] then
					if IsValid(self.content_area) then
						self.content_area:Switch(current_active_tab)
						self:UpdateTabButtonStates(current_active_tab)
						self:ExtractAndSetCurrentState(current_active_tab)
						self.current_active_tab_id = current_active_tab
					end
				end
			end)
		end
	end)
end

-- Create breadcrumbs navigation
function PANEL:CreateBreadcrumbs(content, colors)
	local breadcrumb_height = esclib:AdaptiveSize(35)
	
	self.breadcrumbs = content:Add("Panel")
	self.breadcrumbs:SetTall(breadcrumb_height)
	self.breadcrumbs:Dock(TOP)
	local margin_main = esclib:AdaptiveSizeRound(10)
	local margin_bottom = esclib:AdaptiveSizeRound(5)
	self.breadcrumbs:DockMargin(margin_main, margin_main, margin_main, margin_bottom)
	
	-- Create close button
	self:CreateCloseButton(self.breadcrumbs, colors)
	
	local font_breadcrumb = esclib:AdaptiveFont("esclib", 20, 400)
	local active_text_color = colors.frame.text
	local text_color = colors.frame.text_gray
	local separator_color = colors.frame.text_gray

	local separator_spacing = esclib:AdaptiveSizeRound(15)
	local text_spacing = esclib:AdaptiveSizeRound(10)
	local unsaved_spacing = esclib:AdaptiveSizeRound(15)
	
	self.breadcrumbs.Paint = function(pnl, w, h)
		local addon_name = self.addon.info.name or "Addon"
		local current_tab = self.current_tab or ""
		local current_realm = self.current_realm or ""
		
		local x = unsaved_spacing
		local y = h * 0.5
		
		-- Set font for text size calculations
		surface.SetFont(font_breadcrumb)
		
		-- Show unsaved indicator before addon name
		if self.settings_changed then
			local unsaved_text = esclib.addon:Translate("phrase_Unsaved", self.addon:GetLanguage())
			local unsaved_width, unsaved_height = surface.GetTextSize(unsaved_text .. "!")

			esclib.draw:FullRoundedBox(x-unsaved_spacing, y-unsaved_height*0.5-3, unsaved_width+unsaved_spacing*2, unsaved_height+6, colors.button.discard)
			draw.SimpleText(unsaved_text .. "!", font_breadcrumb, x, y, colors.button.text_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			x = x + unsaved_width + unsaved_spacing*2
		end
		
		-- Draw addon name
		draw.SimpleText(addon_name, font_breadcrumb, x, y, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		local addon_width = surface.GetTextSize(addon_name)
		x = x + addon_width + text_spacing
		
		-- Only show realm and tab if we have an active tab and realm
		if current_tab ~= "" and current_realm ~= "" then
			local realm_name = esclib.addon:Translate(current_realm, self.addon:GetLanguage())
			
			-- Draw separator
			draw.SimpleText("/", font_breadcrumb, x, y, separator_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			x = x + separator_spacing
			
			-- Draw realm name
			draw.SimpleText(realm_name, font_breadcrumb, x, y, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local realm_width = surface.GetTextSize(realm_name)
			x = x + realm_width + text_spacing
			
			-- Draw separator and current tab
			draw.SimpleText("/", font_breadcrumb, x, y, separator_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			x = x + separator_spacing
			draw.SimpleText(current_tab, font_breadcrumb, x, y, active_text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end

-- Create close button
function PANEL:CreateCloseButton(parent, colors)
	local button_size = parent:GetTall() - 4
	
	local close_btn = parent:Add("DButton")
	close_btn:SetSize(button_size, button_size)
	close_btn:SetPos(parent:GetWide() - button_size - 5, 2)
	close_btn:SetText("")
	
	-- Position button on parent resize
	parent.PerformLayout = function(pnl)
		if IsValid(close_btn) then
			close_btn:SetPos(pnl:GetWide() - button_size - 5, 2)
		end
	end
	
	local close_icon = esclib:GetMaterial("cross.png")
	close_btn.Paint = function(btn, w, h)
		local hovered = btn:IsHovered()
		local color = hovered and colors.button.discard_hover or colors.frame.text_gray

		esclib.draw:MaterialCentered(w*0.5, h*0.5, h*0.25, color, close_icon)
	end
	
	close_btn.DoClick = function()
		self:OnClose()
		if IsValid(self.bg_root) then
			self.bg_root:Remove()
		else
			self:Remove()
		end
	end
end

-- Create main content area
function PANEL:CreateMainContent()
	local content = self:GetContent()
	if not IsValid(content) then return end

	local colors = esclib.addon:GetCurrentSkin().colors

	-- Create navigation container
	local nav_container = content:Add("Panel")
	nav_container:SetWide(content:GetWide() * 0.2)
	nav_container:Dock(LEFT)
	local margin_right = esclib:AdaptiveSizeRound(10)
	nav_container:DockMargin(0, 0, margin_right, 0)
	function nav_container:Paint(w,h)
		draw.RoundedBox(16, 0, 0, w, h, colors.frame.bg)
	end

	-- Create addon switch button
	self:CreateAddonSwitch(nav_container, colors)

	-- Create tab navigation scroll panel
	self.tab_scroll = nav_container:Add("esclib.scrollpanel")
	self.tab_scroll:Dock(FILL)
	local margin = esclib:AdaptiveSizeRound(10)
	self.tab_scroll:DockMargin(margin, margin, margin, margin)

	-- Create main content area with breadcrumbs
	local content_wrapper = content:Add("Panel")
	content_wrapper:Dock(FILL)
	
	-- Create breadcrumbs inside content wrapper
	self:CreateBreadcrumbs(content_wrapper, colors)
	
	-- Create main content area
	self.content_area = content_wrapper:Add("esclib.switchmenu")
	self.content_area:Dock(FILL)
	self.content_area:SetSwitchMethod("remove")
	
	-- Override OnChange to update panel state when SwitchMenu automatically switches to first tab
	self.content_area.OnChange = function(switch_menu, tab_name)
		if tab_name and tab_name ~= "" then
			self:UpdateTabButtonStates(tab_name)
			self:ExtractAndSetCurrentState(tab_name)
			self.current_active_tab_id = tab_name
		end
	end

	-- Build unified content structure
	self:BuildUnifiedContent()
end


-- Create addon switch button for switching between addons
function PANEL:CreateAddonSwitch(parent, colors)
	if not self.addon_list or #self.addon_list <= 1 then return end
	local margin = self.margin10
	local padding = esclib:AdaptiveSize(5)

	self.addon_switch = parent:Add("DButton")
	self.addon_switch:SetTall(esclib:AdaptiveSize(60))
	self.addon_switch:Dock(TOP)
	self.addon_switch:DockMargin(margin, margin, margin, 0)
	self.addon_switch:SetText("")

	-- Get current addon info
	local current_addon = self.addon
	local addon_name = current_addon.info.name or "Addon"
	local font_addon = self.font_medium
	local font_hint = self.font_medium
	local text_margin = esclib:AdaptiveSizeRound(15)

	-- Create icon panel
	local icon_panel = self.addon_switch:Add("Panel")
	icon_panel:SetSize(self.addon_switch:GetTall()-padding*2, self.addon_switch:GetTall()-padding*2)
	icon_panel:SetPos(padding, self.addon_switch:GetTall() * 0.5 - icon_panel:GetTall() * 0.5)
	icon_panel:SetMouseInputEnabled(false)
	
	local addon_icon = current_addon.info.thumbnail or esclib:GetMaterial("cog.png")
	local has_icon = type(current_addon.info.thumbnail or "") == "IMaterial"
	
	icon_panel.Paint = function(pnl, w, h)
		local hovered = self.addon_switch:IsHovered()
		local icon_color = hovered and colors.button.text_hover or colors.default.white
		
		if has_icon then
			masks.Start()
				esclib.draw:Material(0, 0, w, h, icon_color, addon_icon)
			masks.Source()
				draw.RoundedBox(8, 0, 0, w, h, esclib.white)
			masks.End()
		end
	end

	local arrow_icon = esclib:GetMaterial("arrow_right.png")
	function self.addon_switch:Paint(w, h)
		local hovered = self:IsHovered()
		
		-- Background
		local border_size = 2
		draw.RoundedBox(16, 0, 0, w, h, colors.button.hover)
		draw.RoundedBox(14, border_size, border_size, w-border_size*2, h-border_size*2, hovered and colors.button.hover or colors.button.main)
		
		-- Addon name
		local text_x = icon_panel:GetX() + icon_panel:GetWide() + text_margin
		local text_color = hovered and colors.button.accent_hover or colors.button.accent
		draw.SimpleText(addon_name, font_addon, text_x, h * 0.5, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		-- Switch arrow
		local arrow_size = h * 0.2
		local arrow_x = w - arrow_size*2
		esclib.draw:MaterialCenteredRotated(arrow_x, h * 0.5, arrow_size, -90, text_color, arrow_icon)
	end

	-- Click handler to show addon selection menu
	self.addon_switch.DoClick = function()
		self:ShowAddonSwitchMenu()
	end
end

-- Show addon selection menu
function PANEL:ShowAddonSwitchMenu()
	if not self.addon_list or #self.addon_list <= 1 then return end

	local colors = esclib.addon:GetCurrentSkin().colors
	local font_menu = esclib:AdaptiveFont("esclib", 18, 400)
	local menu_width = self.addon_switch:GetWide() -- Match button width
	local btn_height = self.addon_switch:GetTall()
	local item_height = esclib:AdaptiveSize(45)
	local max_height = esclib:AdaptiveSize(300) -- Maximum menu height
	local margin = self.margin10
	
	-- Count available addons (excluding current)
	local available_addons = {}
	for _, addon_data in ipairs(self.addon_list) do
		if addon_data.info.uid ~= self.addon.info.uid then
			table.insert(available_addons, addon_data)
		end
	end
	
	if #available_addons == 0 then return end
	
	-- Calculate menu height
	local total_content_height = #available_addons * item_height + margin * 2
	local menu_height = math.min(total_content_height, max_height)
	
	-- Create dropdown menu with background clicker
	local bg_clicker = esclib:GenerateBGClicker()
	bg_clicker.Paint = nil
	local menu = bg_clicker:Add("Panel")
	menu:SetSize(menu_width, menu_height)
	
	-- Position menu above the switch button
	local switch_x, switch_y = self.addon_switch:LocalToScreen(0, 0)
	local screen_x, screen_y = self.bg_root:ScreenToLocal(switch_x, switch_y)
	local menu_offset = esclib:AdaptiveSize(5)
	menu:SetPos(screen_x, screen_y + btn_height + menu_offset)
	
	-- Menu background
	local border_radius = 8
	menu.Paint = function(pnl, w, h)
		draw.RoundedBox(border_radius, 0, 0, w, h, colors.frame.accent)
		draw.RoundedBox(border_radius, 2, 2, w - 4, h - 4, colors.frame.bg)
	end

	-- Create scroll panel
	local scroll = menu:Add("esclib.scrollpanel")
	scroll:SetPos(margin, margin)
	scroll:SetSize(menu_width - margin * 2, menu_height - margin * 2)
	
	-- Add addon items to scroll panel
	local y_pos = 0
	for _, addon_data in ipairs(available_addons) do
		local item = scroll:Add("DButton")
		item:SetPos(0, y_pos)
		item:SetSize(scroll:GetWide(), item_height)
		item:SetText("")
		
		-- Create icon panel for each item
		local icon_panel = item:Add("Panel")
		local icon_size = item_height - self.margin10
		local icon_margin = esclib:AdaptiveSize(8)
		icon_panel:SetSize(icon_size, icon_size)
		icon_panel:SetPos(icon_margin, (item_height - icon_size) * 0.5)
		icon_panel:SetMouseInputEnabled(false)
		
		local has_icon = type(addon_data.info.thumbnail or "") == "IMaterial"
		local item_icon = addon_data.info.thumbnail or esclib:GetMaterial("cog.png")
		
		icon_panel.Paint = function(pnl, w, h)
			local hovered = item:IsHovered()
			local icon_color = hovered and colors.button.text_hover or colors.default.white
			
			if has_icon then
				masks.Start()
					esclib.draw:Material(0, 0, w, h, icon_color, item_icon)
				masks.Source()
					draw.RoundedBox(8, 0, 0, w, h, esclib.white)
				masks.End()
			end
		end
		
		item.Paint = function(btn, w, h)
			local hovered = btn:IsHovered()
			
			if hovered then
				draw.RoundedBox(8, 0, 0, w, h, colors.button.hover)
			end
			
			-- Name
			local text_x = icon_panel:GetX() + icon_panel:GetWide() + esclib:AdaptiveSize(8)
			local text_color = hovered and colors.button.text_hover or colors.button.text
			draw.SimpleText(addon_data.info.name, font_menu, text_x, h * 0.5, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
		item.DoClick = function()
			bg_clicker:Remove()
			esclib:opensettings(addon_data.info.uid, true)
		end
		
		y_pos = y_pos + item_height
	end
end


-- Build unified content with both Client and Server tabs
function PANEL:BuildUnifiedContent()
	if not IsValid(self.content_area) or not IsValid(self.tab_scroll) then return end

	-- Clear existing tabs
	self.tab_scroll:Clear()
	self.tab_buttons = {}

	-- Build Client realm tabs
	self:BuildRealmTabs(REALM_CLIENT)

	-- Build Server realm tabs
	self.addon:RequestServerSettings(function()
		if not IsValid(self) then return end
		
		self:BuildRealmTabs(REALM_SERVER)
	end)
end


-- Get settings data for specific realm
function PANEL:GetRealmSettings(realm)
	local addon = self.addon
	if not addon then return nil end
	
	local data = {
		settings = table.Copy(addon.data.settings) or {},
		vars = table.Copy(addon.data.vars) or {},
		language = addon:GetLanguage(),
		active_skin = addon.info.active_skin,
		changed_vars = {}
	}
	
	if realm == REALM_SERVER then
		if table.IsEmpty(addon.data.server_vars or {}) then 
			return nil
		end
		data.settings = table.Copy(addon.data.server_settings) or {}
		data.vars = table.Copy(addon.data.server_vars) or {}
		
		-- Sync values
		for tab_name, tab in pairs(data.settings) do
			local vars = tab.vars or {}
			for var_name, var in pairs(vars) do
				var.value = data.vars[var_name]
			end
		end
	end

	return data
end

-- Build all tabs for a specific realm
function PANEL:BuildRealmTabs(realm)
	local settings_data = self:GetRealmSettings(realm)
	if not settings_data then return end

	local colors = esclib.addon:GetCurrentSkin().colors
	local realm_display_name = esclib.addon:Translate(realm, self.addon:GetLanguage())
	local realm_icon = realm == REALM_CLIENT and "client.png" or "server.png"
	local realm_icon_material = esclib:GetMaterial(realm_icon)
	local realm_color = realm == REALM_CLIENT and Color(255, 240, 220) or Color(216, 230, 255)
	local font = self.font_medium
	local margin_side = esclib:AdaptiveSizeRound(5)
	local margin_top = esclib:AdaptiveSizeRound(10)

	-- Create realm header
	local header = self.tab_scroll:Add("Panel")
	header:SetTall(draw.GetFontHeight(font)+margin_top)
	header:Dock(TOP)
	header:DockMargin(margin_side, margin_top, margin_side, margin_side)

	local icon_pnl = header:Add("Panel")
	icon_pnl:Dock(LEFT)
	icon_pnl:SetWide(header:GetTall()+margin_side)
	icon_pnl.Paint = function(pnl, w, h)
		esclib.draw:MaterialCentered(w * 0.5, h * 0.5, h * 0.25, realm_color, realm_icon_material)
	end
	
	header.Paint = function(pnl, w, h)
		draw.SimpleText(realm_display_name, font, icon_pnl:GetWide(), h * 0.5, realm_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		--Line
		-- draw.RoundedBox(0, margin_top, h - 2, w - margin_top*2, 2, colors.button.hover)
	end

	-- Get sorted list of tabs for this realm
	local tabs = self:GetTabsList(realm, settings_data)
	
	-- Create tab buttons and content for each tab
	for _, tab_data in ipairs(tabs) do
		if tab_data.stype == "settings" then
			self:CreateSettingsTab(tab_data, settings_data, realm)
		elseif tab_data.stype == "custom" then
			self:CreateCustomTab(tab_data, settings_data, realm)
		elseif tab_data.stype == "default" then
			self:CreateDefaultTab(tab_data, settings_data, realm)
		end
	end
end

-- Get sorted list of tabs for realm
function PANEL:GetTabsList(realm, settings_data)
	local tabs = {}
	
	-- Add settings tabs
	for key, tab in pairs(settings_data.settings) do
		local sort_order = tab.sortOrder or 99
		table.insert(tabs, {stype = "settings", key = key, sortOrder = sort_order})
	end
	
	-- Add custom tabs
	for key, tab in pairs(self.addon:GetAllCustomTabs()) do
		if istable(tab) and tab.realm == realm then
			local sort_order = tab.sortOrder or 99
			table.insert(tabs, {stype = "custom", key = key, sortOrder = sort_order})
		end
	end

	-- Add default tabs
	for key, tab in pairs(esclib:GetAllDefaultTabs()) do
		if tab.realm == realm then
			local sort_order = tab.sortOrder or 99
			table.insert(tabs, {stype = "default", key = key, sortOrder = sort_order})
		end
	end
	
	-- Sort by order
	table.sort(tabs, function(a, b)
		return (a.sortOrder or 99) < (b.sortOrder or 99)
	end)
	
	return tabs
end

-- Create settings tab
function PANEL:CreateSettingsTab(tab_data, settings_data, realm)
	local tab_key = tab_data.key
	local tab_config = settings_data.settings[tab_key]
	if not istable(tab_config) then return end
	
	-- Check custom visibility
	if tab_config.customCheck and isfunction(tab_config.customCheck) then
		if not tab_config.customCheck(tab_config, self.addon) then return end
	end
	
	local tab_name = tab_config.name or 
		(tab_config.name_tr and self.addon:Translate(tab_config.name_tr, self.addon:GetLanguage())) or 
		tab_key
	
	-- Create unique tab identifier with realm prefix
	local unique_tab_id = realm .. "_" .. tab_key
	local display_name = tab_name

	-- Create navigation button
	local nav_btn = self:CreateTabButton(display_name, unique_tab_id)
	
	-- Add page content to main content area
	self.content_area:AddPage(unique_tab_id, function(content)
		return self:CreateSettingsTabContent(content, tab_config, settings_data, realm)
	end)
	
	-- Set up button click handler
	nav_btn.DoClick = function()
		self.content_area:Switch(unique_tab_id)
		self:UpdateTabButtonStates(unique_tab_id)
		self:ExtractAndSetCurrentState(unique_tab_id)
		self.current_active_tab_id = unique_tab_id
	end
end

-- Create settings tab content with action bar
function PANEL:CreateSettingsTabContent(content, tab_config, settings_data, realm)
	-- Create action bar at bottom
	local action_bar = self:CreateActionBar(content, realm, settings_data)
	
	-- Create scroll panel for settings
	local scroll = content:Add("esclib.scrollpanel")
	scroll:SetSize(content:GetWide(), content:GetTall() - action_bar:GetTall())
	scroll:Dock(FILL)

	local list = scroll:Add("esclib.iconlayout")
	list:SetBorder(esclib:AdaptiveSize(15))
	local content_offset = esclib:AdaptiveSizeRound(6)
	list:SetSize(content:GetWide(), content:GetTall() - content_offset)
	local list_spacing = esclib:AdaptiveSizeRound(5)
	list:SetSpaceX(list_spacing)
	list:SetSpaceY(list_spacing)
	
	local button_wide = list:GetColumnSizeFor(2)
	local button_tall = esclib:AdaptiveSize(60)
	
	-- Sort variables by order
	local vars = tab_config.vars or {}
	local sorted_vars = table.GetKeys(vars)
	table.sort(sorted_vars, function(a, b)
		return (vars[a].sortOrder or math.huge) < (vars[b].sortOrder or math.huge)
	end)
	
	-- Create variable controls
	for _, var_id in ipairs(sorted_vars) do
		local var_config = vars[var_id]
		if self:ShouldShowVariable(var_config) then
			self:CreateVariableControl(list, var_id, var_config, settings_data, button_wide, button_tall)
		end
	end
	
	return content
end

-- Create custom tab content
function PANEL:CreateCustomTabContent(content, custom_tab, settings_data, realm)
	-- Custom tabs don't need action bar
	local wrapper = self:CreateTabWrapper(content, function(changed)
		self.settings_changed = changed
	end)
	
	-- Call custom tab function
	custom_tab.func(self.addon, self.bg_root, wrapper, function(changed)
		self.settings_changed = changed
	end)
	
	return content
end

-- Create default tab content  
function PANEL:CreateDefaultTabContent(content, default_tab, settings_data, realm)
	-- Create action bar at bottom for consistency
	local action_bar = self:CreateActionBar(content, realm, settings_data)
	
	-- Create main content area above action bar
	local main_content = content:Add("Panel")
	main_content:SetSize(content:GetWide(), content:GetTall() - action_bar:GetTall())
	main_content:Dock(FILL)
	
	local wrapper = self:CreateTabWrapper(main_content, function(stype, ...)
		local vars = {...}
		if stype == "language" then
			settings_data.language = vars[1]
			-- Mark as changed but don't auto-save
			self.settings_changed = true
		elseif stype == "skin" then
			settings_data.active_skin = vars[1]
			-- Mark as changed but don't auto-save
			self.settings_changed = true
		elseif stype == "custom_skin" then
			self.bg_root.c_themepanel = vars[1]
			if self.onCloseAny then
				self.onCloseAny(self.bg_root.c_themepanel)
			end
		end
	end)
	
	-- Call default tab function
	default_tab.func(self.addon, self.bg_root, wrapper, function(stype, ...)
		local vars = {...}
		if stype == "language" then
			settings_data.language = vars[1]
			-- Mark as changed but don't auto-save
			self.settings_changed = true
		elseif stype == "skin" then
			settings_data.active_skin = vars[1]
			-- Mark as changed but don't auto-save
			self.settings_changed = true
		end
	end)
	
	return content
end

-- Check if variable should be shown
function PANEL:ShouldShowVariable(var_config)
	if var_config.visible == false then return false end
	if var_config.customCheck and isfunction(var_config.customCheck) then
		return var_config.customCheck(var_config, self.addon)
	end
	return true
end

-- Create control for a variable
function PANEL:CreateVariableControl(parent, var_id, var_config, settings_data, width, height)
	if not var_config.name and not var_config.name_tr then
		var_config.name = var_id
	end
	
	local var_type = var_config.type
	if not esclib.allowed_settings_types[var_type] then return end
	
	local settings_type = esclib.allowed_settings_types[var_type]
	if not isfunction(settings_type.Build) then return end
	
	-- Get default value
	local default_val = self.addon.data.default_settings[var_id] or 
		self.addon.data.server_default_settings[var_id]
	
	-- Create base panel
	local base_panel = parent:Add("Panel")
	base_panel:SetSize(width, height)
	base_panel.addon = self.addon
	base_panel.var = var_config
	base_panel.default_value = default_val
	base_panel.var_uid = var_id
	base_panel.initial_values = settings_data.vars
	base_panel.bg = self.bg_root
	base_panel.parent = parent
	base_panel.Paint = nil
	
	-- Set up callbacks
	base_panel.ApplyValue = function()
		self:OnVariableChanged(var_id, var_config.value, settings_data)
	end
	
	base_panel.SaveAll = function()
		self:SaveSettings(settings_data)
	end
	
	-- Build the control
	settings_type:Build(base_panel)
end
-- Create custom tab
function PANEL:CreateCustomTab(tab_data, settings_data, realm)
	local tab_key = tab_data.key
	local custom_tab = self.addon:GetAllCustomTabs()[tab_key]
	if not custom_tab then return end
	
	-- Create unique tab identifier  
	local unique_tab_id = realm .. "_custom_" .. tab_key
	
	-- Extract real tab name first
	local display_name = self:GetCustomTabRealName(custom_tab)
	
	-- Create navigation button with real name
	local nav_btn = self:CreateTabButton(display_name, unique_tab_id)
	
	-- Add page content
	self.content_area:AddPage(unique_tab_id, function(content)
		return self:CreateCustomTabContent(content, custom_tab, settings_data, realm)
	end)
	
	-- Set up button click handler
	nav_btn.DoClick = function()
		self.content_area:Switch(unique_tab_id)
		self:UpdateTabButtonStates(unique_tab_id)
		self:ExtractAndSetCurrentState(unique_tab_id)
		self.current_active_tab_id = unique_tab_id
	end
end

-- Create default tab
function PANEL:CreateDefaultTab(tab_data, settings_data, realm)
	local tab_key = tab_data.key
	local default_tab = esclib:GetAllDefaultTabs()[tab_key]
	if not default_tab then return end
	
	-- Create unique tab identifier
	local unique_tab_id = realm .. "_default_" .. tab_key
	
	-- Extract real tab name first
	local display_name = self:GetDefaultTabRealName(default_tab)

	-- Create navigation button
	local nav_btn = self:CreateTabButton(display_name, unique_tab_id)
	
	-- Add page content
	self.content_area:AddPage(unique_tab_id, function(content)
		return self:CreateDefaultTabContent(content, default_tab, settings_data, realm)
	end)
	
	-- Set up button click handler
	nav_btn.DoClick = function()
		self.content_area:Switch(unique_tab_id)
		self:UpdateTabButtonStates(unique_tab_id)
		self:ExtractAndSetCurrentState(unique_tab_id)
		self.current_active_tab_id = unique_tab_id
	end
end

-- Get real name from tab by calling it with mock wrapper  
function PANEL:GetTabRealName(tab)
	local real_name = tab.name or "Unknown"
	
	-- Create mock wrapper that just captures the tab name
	local mock_wrapper = {
		AddTab = function(_, tab_name, func)
			real_name = tab_name
		end,
		Switch = function() end,
		SetActive = function() end
	}
	
	-- Call tab function safely to extract name
	pcall(tab.func, self.addon, self.bg_root, mock_wrapper, function() end)
	
	return real_name
end

-- Get real name from custom tab
function PANEL:GetCustomTabRealName(custom_tab)
	return self:GetTabRealName(custom_tab)
end

-- Get real name from default tab
function PANEL:GetDefaultTabRealName(default_tab)
	return self:GetTabRealName(default_tab)
end

-- Create wrapper interface for custom/default tabs
function PANEL:CreateTabWrapper(content, callback)
	-- Create internal switch menu for sub-tabs within this tab
	local sub_switcher = content:Add("esclib.switchmenu")
	sub_switcher:Dock(FILL)
	sub_switcher:SetSwitchMethod("remove")
	
	local first_tab_name = nil
	
	return {
		AddTab = function(_, tab_name, func, customCheck)
			if customCheck and isfunction(customCheck) then
				if not customCheck() then return end
			end

			-- Add sub-tab to internal switch menu
			sub_switcher:AddPage(tab_name, func)
			
			-- Remember first tab for auto-activation
			if not first_tab_name then
				first_tab_name = tab_name
				-- Auto-activate first sub-tab after a delay
				timer.Simple(0.01, function()
					if IsValid(sub_switcher) then
						sub_switcher:Switch(tab_name)
					end
				end)
			end
		end,
		
		Switch = function(_, name) 
			if IsValid(sub_switcher) then
				sub_switcher:Switch(name)
			end
		end,
		
		SetActive = function(_, name) 
			if IsValid(sub_switcher) then
				sub_switcher:Switch(name)
			end
		end
	}
end

-- Create action bar with save/reset buttons
function PANEL:CreateActionBar(content, realm, settings_data)
	local colors = esclib.addon:GetCurrentSkin().colors
	local bar_height = content:GetTall() * 0.07
	
	local action_bar = content:Add("Panel")
	action_bar:SetTall(bar_height)
	action_bar:Dock(BOTTOM)
	action_bar:InvalidateParent(true)

	-- Create action buttons
	self:CreateActionButtons(action_bar, realm, settings_data, colors)
	
	return action_bar
end

-- Create action buttons (save, reset, etc.)
function PANEL:CreateActionButtons(parent, realm, settings_data, colors)
	local margin = self.margin10
	local button_tall = parent:GetTall()-margin
	local font_hint = esclib:AdaptiveFont("esclib", 20, 500)
	local center_x = parent:GetWide() * 0.5
	
	-- Reset button (left of center)
	local reset_btn = parent:Add("esclib.button")
	local text = esclib.addon:Translate("phrase_ReturnDefault", self.addon:GetLanguage())
	reset_btn:SetTall(button_tall)
	reset_btn:SetFont(font_hint)
	reset_btn:SetButtonText(text)
	reset_btn:SetIconOffset(margin)
	reset_btn:SetIcon(esclib:GetMaterial("revert.png"))
	reset_btn:SetIconColor(colors.button.discard)
	reset_btn:SetIconSize(0.75)
	reset_btn:SetBackgroundHoverColor2(colors.button.discard)
	reset_btn:StretchWidth(margin*3)
	reset_btn:SetPos(center_x - reset_btn:GetWide() - margin*0.5, 0)

	function reset_btn:PaintBackground(w,h)
		local hovered = self:IsHovered()
		esclib.draw:FullRoundedBox(0,0,w,h,hovered and self:GetBackgroundHoverColor2() or self:GetBackgroundColor2())
		esclib.draw:FullRoundedBox(2,2,w-4,h-4,hovered and self:GetBackgroundHoverColor() or self:GetBackgroundColor())
	end

	reset_btn.DoClick = function()
		self:ResetToDefaults(realm)
	end
	
	-- Save button (right of center)
	local save_btn = parent:Add("esclib.button")
	local text = esclib.addon:Translate("phrase_Save", self.addon:GetLanguage())
	save_btn:SetTall(button_tall)
	save_btn:SetFont(font_hint)
	save_btn:SetText(text)
	save_btn:SetIconOffset(margin)
	save_btn:SetIcon(esclib:GetMaterial("save.png"))
	save_btn:SetIconColor(colors.button.apply)
	save_btn:SetIconSize(0.75)
	save_btn:SetBackgroundHoverColor2(colors.button.apply)
	save_btn:StretchWidth(margin*3)
	save_btn:SetPos(center_x, 0)
	
	function save_btn:PaintBackground(w,h)
		local hovered = self:IsHovered()
		esclib.draw:FullRoundedBox(0,0,w,h,hovered and self:GetBackgroundHoverColor2() or self:GetBackgroundColor2())
		esclib.draw:FullRoundedBox(2,2,w-4,h-4,hovered and self:GetBackgroundHoverColor() or self:GetBackgroundColor())
	end

	-- local save_text = esclib.addon:Translate("phrase_Save", self.addon:GetLanguage())
	-- local save_hint = save_btn:eAddHint(save_text, font_hint, TEXT_ALIGN_CENTER, self.bg_root)
	-- save_hint:SetAccentColor(colors.button.apply)
	
	-- save_btn.Paint = function(btn, w, h)
	-- 	draw.RoundedBox(16, 0, 0, w, h, colors.button.apply)
	-- 	draw.SimpleText(save_text, font_hint, w * 0.5, h * 0.5, colors.button.text_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	-- end
	
	save_btn.DoClick = function()
		self:SaveSettings(settings_data, realm)
	end
	
	-- Admin buttons for client realm (positioned on the left)
	if realm == REALM_CLIENT and esclib:HasAdminAccess(LocalPlayer()) then
		self:CreateAdminButtons(parent, colors, font_hint)
	end
end

-- Create admin-only buttons
function PANEL:CreateAdminButtons(parent, colors, font_hint)
	-- local button_size = parent:GetTall()
	-- local x_pos = 5

	local btn = parent:Add("esclib.button")
	btn:SetTall(parent:GetTall()-self.margin10)
	btn:SetText(esclib.addon:Translate("phrase_Admin", self.addon:GetLanguage()))
	btn:SetFont(self.font_medium)
	btn:SetIcon(esclib:GetMaterial("server.png"))
	btn:SetIconSize(0.75)
	btn:SetIconColor(colors.button.accent)
	btn:SetIconOffset(self.margin10)
	btn:StretchWidth(self.margin10*4)
	btn:SetX(self.margin10)
	btn:eAddHint(esclib.addon:Translate("phrase_AdminInfoButtons", self.addon:GetLanguage()), font_hint, TEXT_ALIGN_CENTER, self.bg_root)

	function btn:PaintBackground(w,h)
		local hovered = self:IsHovered()
		esclib.draw:FullRoundedBox(0,0,w,h,self:GetBackgroundColor2())
		esclib.draw:FullRoundedBox(2,2,w-4,h-4,hovered and self:GetBackgroundHoverColor2() or self:GetBackgroundColor())
	end

	btn.DoClick = function(pnl)
		local context = vgui.Create("esclib.contextmenu", self.bg_root)
		context:SetPosClamped(gui.MouseX() + 5, gui.MouseY() + 5)

		local text = esclib.addon:Translate("phrase_SetGlobalDefault", self.addon:GetLanguage())
		local btn = context:AddButton(text, function()
			self:SetGlobalDefaults()
		end)
		btn:SetIcon(esclib:GetMaterial("cloud.png"))

		local text = esclib.addon:Translate("phrase_BackGlobalDefault", self.addon:GetLanguage())
		local btn = context:AddButton(text, function()
			self:ClearGlobalDefaults()
		end)
		btn:SetIcon(esclib:GetMaterial("revert.png"))
	end
end

-- Create tab navigation button
function PANEL:CreateTabButton(display_name, unique_id)
	local colors = esclib.addon:GetColors()
	local margin_horizontal = esclib:AdaptiveSizeRound(10)
	local margin_vertical = esclib:AdaptiveSizeRound(2)
	
	local btn = self.tab_scroll:Add("esclib.button")
	btn:SetButtonText(display_name)
	btn:Dock(TOP)
	btn:DockMargin(margin_horizontal, margin_vertical, margin_horizontal, margin_vertical)
	btn:SetTextAlignX(TEXT_ALIGN_LEFT)
	btn:SetFont(esclib:AdaptiveFont("esclib", 20, 400))
	btn:SetTall(draw.GetFontHeight(btn:GetFont()) + esclib:AdaptiveSizeRound(15))
	btn:SetBorderRadius(esclib:AdaptiveSizeRound(8))
	
	-- Store button with unique identifier
	self.tab_buttons[unique_id] = btn
	return btn
end

-- Update visual states of tab buttons
function PANEL:UpdateTabButtonStates(active_id)
	local colors = esclib.addon:GetColors()
	
	for tab_id, btn in pairs(self.tab_buttons) do
		if IsValid(btn) then
			if tab_id == active_id then
				-- Active tab styling
				btn:SetBackgroundColor(colors.button.main)
				btn:SetBackgroundColor2(colors.button.hover)
				btn:SetBackgroundHoverColor2(colors.button.hover)
				btn:SetTextColor(colors.button.text_hover)
			else
				-- Inactive tab styling
				btn:SetBackgroundColor(esclib.transparent)
				btn:SetBackgroundColor2(esclib.transparent)
				btn:SetBackgroundHoverColor2(esclib.transparent)
				btn:SetTextColor(colors.button.text)
			end
		end
	end
end


-- Extract realm and tab name from tab_id and set current state
function PANEL:ExtractAndSetCurrentState(tab_id)
	-- Extract realm from different tab_id formats:
	-- Settings: realm_Client_tabname -> realm_Client
	-- Custom: realm_Client_custom_tabname -> realm_Client  
	-- Default: realm_Client_default_tabname -> realm_Client
	local realm = nil
	
	if string.StartsWith(tab_id, REALM_CLIENT) then
		realm = REALM_CLIENT
	elseif string.StartsWith(tab_id, REALM_SERVER) then
		realm = REALM_SERVER
	end
	
	if realm then
		self.current_realm = realm
		
		-- Find the display name from the button
		local btn = self.tab_buttons[tab_id]
		if IsValid(btn) then
			self.current_tab = btn:GetButtonText()
		end
	end
end

-- Handle variable value changes
function PANEL:OnVariableChanged(var_id, value, settings_data)
	if self.current_realm == REALM_CLIENT then
		settings_data.changed_vars[var_id] = value
		self.settings_changed = not table.IsEmpty(settings_data.changed_vars)
	elseif self.current_realm == REALM_SERVER then
		if not esclib.util:IsValuesEqual(settings_data.vars[var_id] or {}, value) then
			self.settings_changed = true
		else
			self.settings_changed = false
		end
		settings_data.changed_vars[var_id] = value
	end
end

-- Save settings
function PANEL:SaveSettings(settings_data, realm)
	realm = realm or self.current_realm
	
	if realm == REALM_CLIENT then
		-- Handle skin changes
		if self.addon.info.active_skin ~= settings_data.active_skin then
			if IsValid(self.bg_root) then 
				self.bg_root:Remove() 
			end
			self.addon:SetSkin(settings_data.active_skin)
			self.addon:SaveCurrentSkin()
		end
		
		-- Handle language changes
		if self.addon:GetLanguage() ~= settings_data.language then
			self.addon:SetLanguage(settings_data.language)
			self.addon:SaveLanguage()
			self:RefreshPanel()
		end
		
		-- Save settings
		self.addon:ReplaceSettings(settings_data.settings)
		hook.Run(self.addon.info.uid .. "_settings_changed", true, settings_data.changed_vars)
		table.Empty(settings_data.changed_vars)
		
	elseif realm == REALM_SERVER then
		if table.IsEmpty(settings_data.changed_vars) then return end
		
		net.Start("esclib.SendServerConfig")
			net.WriteString(self.addon.info.uid)
			esclib:NetWriteCompressedTable(settings_data.changed_vars)
		net.SendToServer()
	end
	
	self.settings_changed = false
	table.Empty(settings_data.changed_vars)
	if self.addon:GetLanguage() == settings_data.language then
		-- Only refresh if language didn't change (language change already triggers refresh)
		timer.Simple(0.05, function()
			if IsValid(self) then
				self:RefreshPanel()
			end
		end)
	end
end

-- Reset settings to defaults
function PANEL:ResetToDefaults(realm)
	local confirm_msg = esclib.addon:Translate("phrase_AreYouSure", self.addon:GetLanguage())
	local sure_msg = esclib.addon:Translate("phrase_SureToReturn", self.addon:GetLanguage())
	
	esclib:ConfirmWindow(confirm_msg, sure_msg, function(confirmed)
		if confirmed then
			if realm == REALM_CLIENT then
				-- Reset addon settings
				self.addon:ReturnSettingsToDefault()
				
				-- For default tabs, also reset language and skin to default
				local default_language = self.addon.data.default_settings.language or "english"
				local default_skin = self.addon.data.default_settings.active_skin or "skin_dark"
				
				self.addon:SetLanguage(default_language) 
				self.addon:SaveLanguage()
				
				if self.addon.info.active_skin ~= default_skin then
					if IsValid(self.bg_root) then
						self.bg_root:Remove()
					end
					self.addon:SetSkin(default_skin)
					self.addon:SaveCurrentSkin()
				end
			else
				net.Start("esclib.ClearServerConfig")
					net.WriteString(self.addon.info.uid)
				net.SendToServer()
			end
			self:RefreshPanel()
		end
	end)
end

-- Set global defaults (admin only)
function PANEL:SetGlobalDefaults()
	local confirm_msg = esclib.addon:Translate("phrase_AreYouSure", self.addon:GetLanguage())
	
	esclib:ConfirmWindow(confirm_msg, "", function(confirmed)
		if confirmed then
			self.addon:CurrentSettingsToGlobal()
			if self.onCloseAny then
				self.onCloseAny(self)
			end
		end
	end)
end

-- Clear global defaults (admin only)
function PANEL:ClearGlobalDefaults()
	local confirm_msg = esclib.addon:Translate("phrase_AreYouSure", self.addon:GetLanguage())
	local sure_msg = esclib.addon:Translate("phrase_SureToReturn", self.addon:GetLanguage())
	
	esclib:ConfirmWindow(confirm_msg, sure_msg, function(confirmed)
		if confirmed then
			self.addon:ClearGlobalConfig()
			if self.onCloseAny then
				self.onCloseAny(self)
			end
		end
	end)
end

vgui.Register("esclib.addon_settings_panel", PANEL, "Panel")