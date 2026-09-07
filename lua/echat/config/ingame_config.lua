local cfg = echat.config

--Init settings on client
local settings = esclib:InitSettings("echat", "client")

--Players can change this settings through menu!
--tab creating
local tab = settings:AddTab("general") --uid
tab:SetNameTranslateKey("s_tab_general") --key in language file
tab:SetPosition(1) --postion

tab:AddVar("chat_spacey", "numslider")
:SetNameTranslateKey("s_chat_spacey_name")
:SetDescTranslateKey("s_chat_spacey_desc")
:SetValue(cfg.chat_spacey)
:SetMin(0)
:SetMax(20)
:SetDecimals(0)
:SetStep(1)

tab:AddVar("msg_time", "numslider")
:SetNameTranslateKey("s_msg_time_name")
:SetDescTranslateKey("s_msg_time_desc")
:SetValue(cfg.message_time)
:SetMin(1)
:SetMax(30)
:SetDecimals(0)
:SetStep(1)

tab:AddVar("max_lines", "float")
:SetNameTranslateKey("s_max_lines_name")
:SetDescTranslateKey("s_max_lines_desc")
:SetValue(cfg.maximum_lines)
:SetMin(10)
:SetMax(2048)

tab:AddVar("autocomplete_count", "float")
:SetNameTranslateKey("s_autocomplete_count_name")
:SetDescTranslateKey("s_autocomplete_count_desc")
:SetValue(cfg.maximum_autocomplete_hints)
:SetMin(1)
:SetMax(512)

tab:AddVar("base_font_size", "numslider")
:SetNameTranslateKey("s_base_font_size_name")
:SetDescTranslateKey("s_base_font_size_desc")
:SetValue(cfg.base_font_size)
:SetMin(12)
:SetMax(48)
:SetDecimals(0)

tab:AddVar("clean_chat", "bool")
:SetNameTranslateKey("s_clean_chat_name")
:SetDescTranslateKey("s_clean_chat_desc")
:SetValue(cfg.clear_chat)

tab:AddVar("ambilight", "bool")
:SetNameTranslateKey("s_ambilight_name")
:SetValue(cfg.ambilight)

--new tab
local tab = settings:AddTab("location") --uid
tab:SetNameTranslateKey("s_tab_location") --key in language file
tab:SetPosition(2) --postion

tab:AddVar("pos_x", "numslider")
:SetNameTranslateKey("s_posx_name")
:SetDescTranslateKey("s_xywh_mod_name")
:SetValue(cfg.pos_x)
:SetMin(0)
:SetMax(1)
:SetDecimals(2)

tab:AddVar("pos_y", "numslider")
:SetNameTranslateKey("s_posy_name")
:SetDescTranslateKey("s_xywh_mod_name")
:SetValue(cfg.pos_y)
:SetMin(0)
:SetMax(1)
:SetDecimals(2)

tab:AddVar("size_w", "numslider")
:SetNameTranslateKey("s_sizew_name")
:SetDescTranslateKey("s_xywh_mod_name")
:SetValue(cfg.size_width)
:SetMin(0)
:SetMax(1)
:SetDecimals(2)

tab:AddVar("size_h", "numslider")
:SetNameTranslateKey("s_sizeh_name")
:SetDescTranslateKey("s_xywh_mod_name")
:SetValue(cfg.size_height)
:SetMin(0)
:SetMax(1)
:SetDecimals(2)

settings:End()


local settings = esclib:InitSettings("echat", "server")

local tab = settings:AddTab("general") --uid
tab:SetNameTranslateKey("s_tab_general") --key in language file
tab:SetPosition(1) --postion

tab:AddVar("ambilight_clr1", "clr")
:SetNameTranslateKey("s_ambilight_clr1_name")
:SetValue(cfg.ambilight_clr1)
:SetShared(true)

tab:AddVar("ambilight_clr2", "clr")
:SetNameTranslateKey("s_ambilight_clr2_name")
:SetValue(cfg.ambilight_clr2)
:SetShared(true)

tab:AddVar("chat_name", "str")
:SetNameTranslateKey("s_chat_name_name")
:SetValue(cfg.chat_name)
:SetMinimumCharCount(1)
:SetMaximumCharCount(128)
:SetPosition(1)
:SetShared(true) --make it accessible on client


settings:End()
