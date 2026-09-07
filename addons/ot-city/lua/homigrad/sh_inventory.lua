hg.TraitorLoot = {
    ["weapon_sogknife"] = 10,
    ["weapon_buck200knife"] = 10,
    ["weapon_hg_shuriken"] = 9,
    ["weapon_glock26"] = 9,
    ["weapon_p22"] = 9,
    ["weapon_zc_fiberwire_standalone"] = 10,
    ["weapon_traitor_ied"] = 8,
    ["weapon_traitor_poison1"] = 7,
    ["weapon_traitor_poison2"] = 6,
    ["weapon_traitor_poison3"] = 5,
    ["weapon_hg_smokenade_tpik"] = 4,
    ["weapon_hg_rgd_tpik"] = 3,
    ["weapon_walkie_talkie"] = 2,
    ["weapon_adrenaline"] = 1,
    ["hg_flashlight"] = 1
}

if CLIENT then
    local INV_MAIN = Color(31, 182, 255)
    local INV_MAIN_SOFT = Color(127, 230, 255)
    local INV_DARK = Color(3, 5, 9)
    local INV_DARK_SOFT = Color(6, 12, 20)
    local INV_CARD = Color(9, 18, 30)
    local INV_CARD_SOFT = Color(12, 22, 36)
    local INV_TEXT = Color(240, 248, 255)
    local INV_MUTED = Color(150, 190, 220)
    local INV_LOCKED = Color(112, 126, 140)
    local INV_TEXT_EDGE = Color(0, 0, 0, 155)
    local INV_RADIUS = 18

    surface.CreateFont("LootInvTitle", {
        font = "Montserrat SemiBold",
        extended = true,
        size = 25,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("LootInvText", {
        font = "Montserrat Medium",
        extended = true,
        size = 17,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("LootInvSmall", {
        font = "Montserrat Medium",
        extended = true,
        size = 14,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("LootInvTiny", {
        font = "Montserrat Medium",
        extended = true,
        size = 12,
        weight = 500,
        antialias = true
    })

    local function UILerp(speed, from, to)
        return Lerp(math.Clamp(FrameTime() * speed, 0, 1), from, to)
    end

    local function DrawUIBlock(x, y, w, h, col, radius)
        radius = math.min(radius or INV_RADIUS, math.floor(math.min(w, h) / 2))

        if RNDX and RNDX.Draw then
            RNDX.Draw(radius, x, y, w, h, col)
        elseif rndx and rndx.Draw then
            rndx.Draw(radius, x, y, w, h, col)
        else
            draw.RoundedBox(radius, x, y, w, h, col)
        end
    end

    local function DrawUIOutline(x, y, w, h, col, radius, thickness)
        radius = math.min(radius or INV_RADIUS, math.floor(math.min(w, h) / 2))
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
        draw.SimpleText(text, font, x + 1, y + 1, INV_TEXT_EDGE, ax, ay)
        draw.SimpleText(text, font, x, y, col, ax, ay)
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

    local function RndxLib()
        if RNDX and RNDX.Draw then return RNDX end
        if rndx and rndx.Draw then return rndx end
        if _G.gSims_RNDX and _G.gSims_RNDX.Draw then return _G.gSims_RNDX end

        return nil
    end

    local function DrawINVBlur(x, y, w, h, radius, amount)
        local lib = RndxLib()
        if not lib or not lib.DrawBlur then return end

        pcall(lib.DrawBlur, radius, x, y, w, h, amount or 1)
    end

    local function DrawINVGlass(x, y, w, h, radius, col, amount)
        DrawINVBlur(x, y, w, h, radius, amount)
        DrawUIBlock(x, y, w, h, col, radius)
    end

    local function DrawINVCircle(cx, cy, radius, col)
        local lib = RndxLib()

        if lib and lib.DrawCircle then
            local ok = pcall(lib.DrawCircle, cx - radius, cy - radius, radius * 2, radius * 2, col)
            if ok then return end
        end

        DrawUIBlock(cx - radius, cy - radius, radius * 2, radius * 2, col, radius)
    end

    local function DrawINVIcon(mat, isTexture, x, y, w, h, alpha, quad)
        if w <= 0 or h <= 0 then return end

        local dw, dh = w, h

        if not isTexture and not isnumber(mat) and istable(getmetatable(mat) or {}) and mat.Width and mat.Height then
            local okw, mw = pcall(mat.Width, mat)
            local okh, mh = pcall(mat.Height, mat)

            if okw and okh and mw and mh and mw > 0 and mh > 0 then
                local scale = math.min(w / mw, h / mh)
                dw = mw * scale
                dh = mh * scale
            end
        end

        if quad then
            dw = dw * 0.86
            dh = dh * 0.86
        end

        if isTexture then
            surface.SetTexture(mat)
        else
            surface.SetMaterial(mat)
        end

        surface.SetDrawColor(255, 255, 255, alpha or 255)
        surface.DrawTexturedRect(math.floor(x + (w - dw) * 0.5), math.floor(y + (h - dh) * 0.5), math.floor(dw), math.floor(dh))
    end

    local function PaintInventoryFrame(self, w, h, title)
        self.OpenAnim = UILerp(14, self.OpenAnim or 0, 1)

        local anim = self.OpenAnim
        local a = 255 * anim
        local headerH = 76
        local pad = 16

        DrawINVGlass(0, 0, w, h, 26, Color(INV_DARK.r, INV_DARK.g, INV_DARK.b, a * 0.93), 1.2)
        DrawUIOutline(0, 0, w, h, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a * 0.32), 26, 1)

        DrawUIBlock(pad + 10, 0, math.max(70, w * 0.2), 3, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a), 2)

        DrawUIBlock(pad + 10, 22, 4, 26, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a), 2)
        DrawUIText(title, "LootInvTitle", pad + 26, 34, Color(INV_TEXT.r, INV_TEXT.g, INV_TEXT.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetFont("LootInvSmall")
        local brand_w = surface.GetTextSize("OT-")

        DrawUIText("OT-", "LootInvSmall", pad + 26, 58, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawUIText("CITY", "LootInvSmall", pad + 26 + brand_w, 58, Color(INV_TEXT.r, INV_TEXT.g, INV_TEXT.b, a * 0.85), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local chips = {
            "R — закрыть",
            "ЛКМ — взять",
            "ПКМ — действие"
        }

        local cx = w - pad - 62

        for i = #chips, 1, -1 do
            local text = chips[i]
            local tw = surface.GetTextSize(text)
            local cw = tw + 22

            cx = cx - cw

            DrawUIBlock(cx, 24, cw, 24, Color(INV_CARD.r, INV_CARD.g, INV_CARD.b, a * 0.55), 12)
            DrawUIOutline(cx, 24, cw, 24, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a * 0.18), 12, 1)
            DrawUIText(text, "LootInvSmall", cx + cw * 0.5, 36, Color(INV_MUTED.r, INV_MUTED.g, INV_MUTED.b, a * 0.92), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            cx = cx - 8
        end

        DrawUIBlock(pad + 10, headerH, w - (pad + 10) * 2, 1, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a * 0.16), 1)

        local bx = 28
        local by = headerH + 20
        local bw = w - 56
        local bh = h - by - 26

        DrawUIBlock(bx, by, bw, bh, Color(INV_DARK_SOFT.r, INV_DARK_SOFT.g, INV_DARK_SOFT.b, a * 0.42), 20)
        DrawUIOutline(bx, by, bw, bh, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, a * 0.14), 20, 1)
    end

    local function PaintLootItem(self, w, h, itemName, itemType, icon, haveIcon, overrideTexture, quad)
        self.HoverFrac = UILerp(12, self.HoverFrac or 0, self:IsHovered() and 1 or 0)
        self.IconAlpha = UILerp(10, self.IconAlpha or 0, 255)

        local hover = self.HoverFrac
        local lift = math.floor(hover * 3)
        local top = lift
        local ih = h - lift

        DrawINVGlass(0, top, w, ih, 16, Color(INV_CARD.r, INV_CARD.g, INV_CARD.b, 190 + 45 * hover), 0.4 + hover * 0.3)
        DrawUIOutline(0, top, w, ih, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 38 + 150 * hover), 16, hover > 0.35 and 2 or 1)

        if hover > 0.02 then
            DrawUIBlock(0, top + ih * 0.28, 3, ih * 0.44, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 60 + 175 * hover), 2)
        end

        local padX = 11
        local iconTop = top + 28
        local iconH = ih - 28 - 26

        if icon then
            self.Icon = self.Icon or (isstring(icon) and Material(icon)) or icon
        end

        if haveIcon and self.Icon then
            DrawINVIcon(self.Icon, overrideTexture and isnumber(icon), 3, iconTop, w - 6, iconH, math.floor(self.IconAlpha), quad)
        else
            DrawUIText("?", "LootInvTitle", w * 0.5, iconTop + iconH * 0.5, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        surface.SetFont("LootInvTiny")
        local type_w = surface.GetTextSize(tostring(itemType or ""))

        DrawUIBlock(padX, top + 9, type_w + 16, 17, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 24 + 32 * hover), 8)
        DrawUIText(itemType, "LootInvTiny", padX + 8, top + 18, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 185 + 70 * hover), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        DrawINVCircle(w - padX - 4, top + 17, 3, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 80 + 150 * hover))

        DrawUIText(itemName, "LootInvTiny", w * 0.5, h - 15, Color(INV_TEXT.r, INV_TEXT.g, INV_TEXT.b, 205 + 50 * hover), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    hook.Add("Player_Death", "foundloot", function(ply)
        if IsValid(ply.FakeRagdoll) then
            ply.FakeRagdoll.foundloot = table.Copy(ply.foundloot or {})
        end

        ply.foundloot = {}
    end)

    local OpenInv
    local currentLootSession = {
        id = "",
        ent = NULL,
        tokens = {}
    }

    local function MakeLootKey(tab, thing, extra)
        if tab == "Armor" then
            return tab .. "|" .. tostring(thing) .. "|" .. tostring(extra or "")
        end

        return tab .. "|" .. tostring(thing)
    end

    net.Receive("loot_open_inv", function()
        local ent = net.ReadEntity()
        local sessionId = net.ReadString()
        local tokens = net.ReadTable() or {}

        currentLootSession.id = sessionId
        currentLootSession.ent = ent
        currentLootSession.tokens = tokens

        OpenInv(ent)
    end)

    local function nameThings(i, thing)
        local weps = weapons.Get(i)
        local entss = scripted_ents.Get(i)

        if weps then return weps.PrintName end
        if entss then return entss.PrintName end
        if hg.armor and hg.armor[i] and hg.armor[i][thing] then return thing end
        if hg.attachmentslaunguage and hg.attachmentslaunguage[thing] then return thing end
        if i == "Money" then return "Деньги, " .. tostring(thing) .. "$" end

        return tostring(i)
    end

    local function getIconThing(i, thing, tab)
        if tab == "Weapons" and weapons.Get(i) then
            local GunTable = weapons.Get(i)
            local Icon = (GunTable.WepSelectIcon2 ~= nil and GunTable.WepSelectIcon2) or GunTable.WepSelectIcon
            local Overide = GunTable.WepSelectIcon2 == nil and true or false

            return Icon, true, Overide, GunTable.WepSelectIcon2box
        end

        if tab == "Attachments" and hg.attachmentsIcons and hg.attachmentsIcons[thing] then
            return hg.attachmentsIcons[thing], true, false, true
        end

        if tab == "Armor" and hg.armorIcons then
            return hg.armorIcons[thing], true, false, true
        end

        if tab == "Money" then
            return "scrappers/money_icon.png", true, false
        end
    end

    local functions2 = {
        ["Weapons"] = function(ply, ent, wep)
            return true
        end,
        ["Ammo"] = function(ply, ent, ammo, amt)
            return true
        end,
        ["Armor"] = function(ply, ent, placement, armor)
            if not hg.armor or not hg.armor[placement] or not hg.armor[placement][armor] then return false end
            if hg.armor[placement][armor].nodrop then return false end
            return true
        end,
        ["Attachments"] = function(ply, ent, att, tbl)
            return true
        end,
        ["Money"] = function(ply, ent)
            return true
        end
    }

    local functions = {
        ["Weapons"] = function(ply, ent, wep)
            if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon() == wep then return false end
            return true
        end,
        ["Ammo"] = function(ply, ent, ammo, amt)
            return true
        end,
        ["Armor"] = function(ply, ent, placement, armor)
            local armors = ply:GetNetVar("Armor", {})
            if armors[placement] then return false end
            return true
        end,
        ["Attachments"] = function(ply, ent, att, tbl)
            return true
        end,
        ["Money"] = function(ply, ent)
            return true
        end
    }

    local cooldown = 0

    local function TakeItem(tblIndex, thing, item, owner, lootKey, token)
        local itemTbl = istable(item) and table.Copy(item) or { item }

        net.Start("ply_take_item")
            net.WriteString(tblIndex)
            net.WriteString(thing)
            net.WriteTable(itemTbl)
            net.WriteEntity(owner)
            net.WriteString(currentLootSession.id or "")
            net.WriteString(lootKey or "")
            net.WriteString(token or "")
        net.SendToServer()
    end

    local plyMenu

    hook.Add("OnNetVarSet", "inventory_netvar", function(index, key, var)
        if key == "Inventory" then
            local ent = Entity(index)

            if IsValid(plyMenu) and plyMenu.entindex == index then
                timer.Simple(0, function()
                end)
            end
        end
    end)

    OpenInv = function(ent)
        if IsValid(plyMenu) then
            plyMenu:Remove()
            plyMenu = nil
        end

        cooldown = CurTime()

        if not IsValid(ent) then return end
        if currentLootSession.ent ~= ent then return end
        if not istable(currentLootSession.tokens) then return end

        local ply = LocalPlayer()
        local inv = ent:GetNetVar("Inventory")

        if not inv then return end

        inv = table.Copy(inv)
        inv["Money"] = {}

        local armor = ent:GetNetVar("Armor")
        inv["Armor"] = armor

        local name = IsValid(ent) and (ent:IsPlayer() or ent:IsRagdoll()) and ent:GetPlayerName() .. "' инвентарь" or "Контейнер"
        local sizeX = math.Clamp(ScrW() * 0.42, 620, 820)
        local sizeY = math.Clamp(ScrH() * 0.58, 460, 660)

        plyMenu = vgui.Create("DFrame")
        plyMenu.ent = ent
        plyMenu.entindex = ent:EntIndex()
        plyMenu:SetTitle("")
        plyMenu:SetSize(sizeX, sizeY)
        plyMenu:Center()
        plyMenu:MakePopup()
        plyMenu:SetKeyBoardInputEnabled(false)
        plyMenu:ShowCloseButton(false)
        plyMenu:SetDraggable(false)
        plyMenu.Created = CurTime()
        plyMenu.OpenAnim = 0

        plyMenu.Paint = function(self, w, h)
            PaintInventoryFrame(self, w, h, name)
        end

        function plyMenu:Think()
            local ent2 = self.ent

            if not IsValid(ent2) then self:Close() return end
            if LocalPlayer().organism and LocalPlayer().organism.otrub then self:Remove() return end
            if not LocalPlayer():Alive() then self:Remove() return end
            if (ent2:GetPos() - LocalPlayer():GetPos()):LengthSqr() > 125 ^ 2 then self:Remove() return end
            if ent2:IsPlayer() and not IsValid(ent2.FakeRagdoll) then self:Remove() return end

            if input.IsKeyDown(KEY_R) then
                self:Close()
            end
        end

        function plyMenu:Close()
            self:AlphaTo(0, 0.12, 0, function(_, pnl)
                if IsValid(pnl) then pnl:Remove() end
            end)
        end

        local close = vgui.Create("DButton", plyMenu)
        close:SetText("")
        close:SetSize(32, 32)
        close:SetPos(sizeX - 52, 27)
        close.HoverFrac = 0

        close.Paint = function(self, w, h)
            self.HoverFrac = UILerp(12, self.HoverFrac, self:IsHovered() and 1 or 0)

            DrawINVGlass(0, 0, w, h, 10, Color(INV_CARD.r, INV_CARD.g, INV_CARD.b, 175 + 45 * self.HoverFrac), 0.45)
            DrawUIOutline(0, 0, w, h, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 70 + 140 * self.HoverFrac), 10, self.HoverFrac > 0.35 and 2 or 1)
            DrawUIText("×", "LootInvText", w * 0.5, h * 0.5 - 1, Color(INV_TEXT.r, INV_TEXT.g, INV_TEXT.b, 200 + 55 * self.HoverFrac), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        close.DoClick = function()
            plyMenu:Close()
        end

        local DScrollPanel = vgui.Create("DScrollPanel", plyMenu)
        DScrollPanel:SetPos(42, 112)
        DScrollPanel:SetSize(sizeX - 84, sizeY - 154)

        local vbar = DScrollPanel:GetVBar()
        vbar:SetWide(6)

        vbar.Paint = function(self, w, h)
            DrawUIBlock(2, 0, w - 4, h, Color(255, 255, 255, 10), 3)
        end

        vbar.btnGrip.Paint = function(self, w, h)
            DrawUIBlock(1, 0, w - 2, h, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, self:IsHovered() and 200 or 120), 4)
        end

        vbar.btnUp.Paint = function() end
        vbar.btnDown.Paint = function() end

        local grid = vgui.Create("DGrid", DScrollPanel)
        grid:SetPos(12, 12)

        local cols = 5
        local gap = 12
        local cell = math.floor((sizeX - 84 - 24 - gap * (cols - 1) - 10) / cols)

        grid:SetCols(cols)
        grid:SetColWide(cell + gap)
        grid:SetRowHeight(cell + gap)

        local count = 0

        for tab, things in pairs(inv) do
            if not istable(things) then continue end

            for i, thing in pairs(things) do
                local extra = nil

                if tab == "Armor" then
                    extra = thing
                end

                local lootKey = MakeLootKey(tab, i, extra)

                if currentLootSession.tokens[lootKey] then
                    ent.foundloot = ent.foundloot or {}
                    count = count + ((ent:IsPlayer() or ent:IsRagdoll()) and ((hg.TraitorLoot[i] and ent:IsPlayer()) and 2 or 0.5) or 1) * (not ent.foundloot[lootKey] and 1 or 0)
                end
            end
        end

        local searchTime = CurTime() + 3

        function DScrollPanel:Paint(w, h)
            local txt = "Идет поиск"

            if searchTime > 0 then
                for i = 1, 3 - math.Round(searchTime - CurTime(), 0) do
                    txt = txt .. "."
                end

                if searchTime < CurTime() then
                    searchTime = CurTime() + 3
                end
            end

            if not ((plyMenu.Created + count + 3) < CurTime()) then
                DrawUIText(txt, "LootInvText", w * 0.5, h * 0.42, Color(INV_MAIN.r, INV_MAIN.g, INV_MAIN.b, 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        for tab, things in pairs(inv) do
            if not istable(things) then continue end

            local keys = table.GetKeys(things)

            table.sort(keys, function(a, b)
                local aextra = nil
                local bextra = nil

                if tab == "Armor" then
                    aextra = things[a]
                    bextra = things[b]
                end

                local ak = MakeLootKey(tab, a, aextra)
                local bk = MakeLootKey(tab, b, bextra)

                return (ent.foundloot[ak] and 1 or 0) > (ent.foundloot[bk] and 1 or 0)
            end)

            for _, i in ipairs(keys) do
                local thing = things[i]
                local thing1 = istable(thing) and thing or { thing }

                if not functions2[tab](ply, ent, i, unpack(thing1)) then continue end
                if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end

                local extra = nil

                if tab == "Armor" then
                    extra = thing1[1]
                end

                local lootKey = MakeLootKey(tab, i, extra)
                local sessionData = currentLootSession.tokens[lootKey]

                if not sessionData then continue end

                ent.foundloot = ent.foundloot or {}

                local button = vgui.Create("DButton", plyMenu)
                button:SetText("")
                button:SetSize(0, 0)
                button.Created = sessionData.revealAt or CurTime()
                button.LootKey = lootKey
                button.LootToken = sessionData.token
                button.HoverFrac = 0
                button.IconAlpha = 0
                button.LootSeed = math.random(1, 9999)

                button.Think = function(self)
                    if self.Created and self.Created < CurTime() then
                        self:SetSize(cell, cell)
                        self:SetAlpha(0)
                        surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
                        self:AlphaTo(255, 0.22, 0)
                        ent.foundloot[self.LootKey] = true
                        self.Created = nil
                    end
                end

                button.DoClick = function()
                    if cooldown > CurTime() then return end

                    cooldown = CurTime() + 0.5

                    if not functions[tab](ply, ent, i, unpack(thing1)) then
                        local OptionsMenu = DermaMenu()
                        OptionsMenu:AddOption("У тебя уже есть такой предмет", function() end)
                        OptionsMenu:Open()
                        return
                    end

                    if istable(thing) then
                        thing["render"] = {}
                    end

                    surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
                    grid.SoundKD = CurTime() + 0.2
                    button:Remove()
                    TakeItem(tab, i, thing, ent, button.LootKey, button.LootToken)
                    currentLootSession.tokens[button.LootKey] = nil
                end

                button.DoRightClick = function()
                    if cooldown > CurTime() then return end

                    cooldown = CurTime() + 0.5

                    if not functions[tab](ply, ent, i, unpack(thing1)) then
                        local OptionsMenu = DermaMenu()
                        OptionsMenu:AddOption("У тебя уже есть такой предмет", function() end)
                        OptionsMenu:Open()
                        return
                    end

                    if istable(thing) then
                        thing["render"] = {}
                    end

                    surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
                    grid.SoundKD = CurTime() + 0.2

                    local OptionsMenu = DermaMenu()
                    OptionsMenu:AddOption("Взять", function()
                        button:Remove()
                        TakeItem(tab, i, thing, ent, button.LootKey, button.LootToken)
                        currentLootSession.tokens[button.LootKey] = nil
                    end)
                    OptionsMenu:Open()
                end

                local displayName = nameThings(i, thing)

                button.Paint = function(self, w, h)
                    if self:IsHovered() then
                        self.SoundKD = self.SoundKD or 0

                        if (grid.SoundKD or 0) < CurTime() and self.SoundKD < CurTime() then
                            surface.PlaySound("arc9_eft_shared/generic_mag_pouch_out" .. math.random(7) .. ".ogg")
                        end

                        self.SoundKD = CurTime() + 0.1
                    end

                    local Icon, HaveIcon, Overide, Quad = getIconThing(i, thing, tab)
                    local Text = (tab == "Ammo" and game.GetAmmoName(displayName)) or language.GetPhrase(displayName)
                    local itemType = tab == "Weapons" and "ПРЕДМЕТ" or tab == "Ammo" and "ПАТРОНЫ" or tab == "Armor" and "БРОНЯ" or tab == "Attachments" and "МОДУЛЬ" or tab == "Money" and "ДЕНЬГИ" or tostring(tab)

                    Text = TrimToWidth(Text, "LootInvTiny", w - 30)

                    PaintLootItem(self, w, h, Text, itemType, Icon, HaveIcon, Overide, Quad)
                end

                grid:AddItem(button)
            end
        end
    end
end

if CLIENT then
    MsgC(Color(31, 182, 255), "[OT-CITY] ", Color(240, 248, 255), "loot inventory loaded\n")
end
