MODE.name = "hl2dm"

local MODE = MODE
local StartTime = 0
local ReinforceArrivalTime = 0
local ReinforcePreviewTeam = nil
local ReinforceTeam = nil
local ReinforcePlayed = false
local TeamScore = {
    [0] = 0,
    [1] = 0
}

net.Receive("HL2DM_start", function()
    StartTime = CurTime()
    ReinforceArrivalTime = StartTime + 120
    ReinforcePreviewTeam = nil
    ReinforceTeam = nil
    ReinforcePlayed = false
    surface.PlaySound("music/HL2_song14.mp3")
    zb.RemoveFade()
    TeamScore = {
        [0] = 0,
        [1] = 0
    }
end)

net.Receive("HL2DM_score", function()
    TeamScore = net.ReadTable() or {
        [0] = 0,
        [1] = 0
    }

    TeamScore[0] = math.max(0, tonumber(TeamScore[0]) or 0)
    TeamScore[1] = math.max(0, tonumber(TeamScore[1]) or 0)
end)

net.Receive("HL2DM_status", function()
    local score = net.ReadTable() or {
        [0] = 0,
        [1] = 0
    }

    TeamScore[0] = math.max(0, tonumber(score[0]) or 0)
    TeamScore[1] = math.max(0, tonumber(score[1]) or 0)

    local timeLeft = math.max(0, net.ReadFloat() or 0)
    local previewTeam = net.ReadInt(4)
    local spawned = net.ReadBool()
    local reinforceTeam = net.ReadInt(4)

    ReinforceArrivalTime = CurTime() + timeLeft
    ReinforcePreviewTeam = previewTeam >= 0 and previewTeam or nil

    if spawned then
        ReinforceTeam = reinforceTeam >= 0 and reinforceTeam or nil
    else
        ReinforceTeam = nil
    end
end)

net.Receive("HL2DM_reinforce", function()
    ReinforceTeam = net.ReadUInt(3)
    ReinforcePreviewTeam = ReinforceTeam
    ReinforcePlayed = true
    ReinforceArrivalTime = CurTime()

    if ReinforceTeam == 1 then
        surface.PlaySound("npc/overwatch/radiovoice/reinforcementteamscode3.wav")
    else
        surface.PlaySound("npc/overwatch/radiovoice/allunitsapplyforwardpressure.wav")
    end
end)

local teams = {
    [0] = {
        objective = "Увидели консерву Альянса —\nломайте кабину без разговоров.",
        name = "Сопротивление",
        color1 = Color(40, 170, 70),
        color2 = Color(40, 170, 70)
    },
    [1] = {
        objective = "Увидели мятежника —\nотправьте его в меню, во имя Сити-17.",
        name = "Альянс",
        color1 = Color(0, 210, 255),
        color2 = Color(0, 210, 255)
    },
}

function MODE:RenderScreenspaceEffects()
    if StartTime + 7.5 < CurTime() then return end
    local fade = math.Clamp(StartTime + 7.5 - CurTime(), 0, 1)

    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
    local lply = LocalPlayer()
    local sw, sh = ScrW(), ScrH()

    if IsValid(lply) and lply:Alive() and CurTime() < StartTime + 8.5 then
        zb.RemoveFade()

        local fade = math.Clamp(StartTime + 8 - CurTime(), 0, 1)
        local team_ = lply:Team()
        local data = teams[team_]

        if data then
            draw.SimpleText("OT-City | Half-Life 2", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(180, 220, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local ColorRole = Color(data.color1.r, data.color1.g, data.color1.b, 255 * fade)
            draw.SimpleText("Вы — " .. data.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.46, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local ColorObj = Color(data.color2.r, data.color2.g, data.color2.b, 255 * fade)
            draw.DrawText(data.objective, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.7, ColorObj, TEXT_ALIGN_CENTER)
        end
    end

    local timeBeforeReinforce = math.max(0, ReinforceArrivalTime - CurTime())

    if ReinforceTeam == nil and timeBeforeReinforce > 0 then
        local teamName = ReinforcePreviewTeam == 1 and "Альянса" or ReinforcePreviewTeam == 0 and "Сопротивления" or "Отстающей стороны"
        local text = "Подкрепление для " .. teamName .. " прибудет через: " .. string.FormattedTime(timeBeforeReinforce, "%02i:%02i")
        local pulse = (math.sin(CurTime() * 3) + 1) / 2
        local col = Color(255 * pulse, 255 * pulse, 255)

        draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02, sh * 0.05, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.05 - 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    elseif ReinforceTeam ~= nil then
        local reinforceName = ReinforceTeam == 1 and "Альянс" or "Сопротивление"
        local reinforceColor = ReinforceTeam == 1 and Color(0, 210, 255) or Color(40, 170, 70)

        draw.SimpleText("Подкрепление прибыло: " .. reinforceName, "ZB_HomicideMedium", sw * 0.02, sh * 0.05, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Подкрепление прибыло: " .. reinforceName, "ZB_HomicideMedium", sw * 0.02 - 2, sh * 0.05 - 2, reinforceColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local CreateEndMenu

net.Receive("HL2DM_roundend", function()
    surface.PlaySound("music/HL2_song23_SuitSong3.mp3")
    CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colBlue = Color(10, 100, 160)
local colBlueUp = Color(40, 130, 200)
local colGreen = Color(20, 120, 40)
local colGreenUp = Color(40, 160, 60)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end

    hmcdEndMenu = vgui.Create("ZFrame")

    surface.PlaySound("ambient/alarms/warningbell1.wav")

    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

    hmcdEndMenu:SetPos(posX, posY)
    hmcdEndMenu:SetSize(sizeX, sizeY)
    hmcdEndMenu:MakePopup()
    hmcdEndMenu:SetKeyboardInputEnabled(false)
    hmcdEndMenu:ShowCloseButton(false)

    local closebutton = vgui.Create("DButton", hmcdEndMenu)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")

    closebutton.DoClick = function()
        if IsValid(hmcdEndMenu) then
            hmcdEndMenu:Close()
            hmcdEndMenu = nil
        end
    end

    closebutton.Paint = function(self, w, h)
        surface.SetDrawColor(122, 122, 122, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lengthX = surface.GetTextSize("Закрыть")
        surface.SetTextPos(lengthX - lengthX / 1.1, 4)
        surface.DrawText("Закрыть")
    end

    hmcdEndMenu.Paint = function(self, w, h)
        BlurBackground(self)

        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local title = "Игроки:"
        local lengthX = surface.GetTextSize(title)
        surface.SetTextPos(w / 2 - lengthX / 2, 20)
        surface.DrawText(title)

        surface.SetDrawColor(0, 170, 255, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

    function DScrollPanel:Paint(w, h)
        BlurBackground(self)
        surface.SetDrawColor(0, 170, 255, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end

        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100, 50)
        but:Dock(TOP)
        but:DockMargin(8, 6, 8, -1)
        but:SetText("")

        but.Paint = function(self, w, h)
            local teamid = ply:Team()
            local alive = ply:Alive()

            local col1, col2
            if not alive then
                col1 = colGray
                col2 = colSpect1
            elseif teamid == 1 then
                col1 = colBlue
                col2 = colBlueUp
            else
                col1 = colGreen
                col2 = colGreenUp
            end

            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)

            local pcol = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")

            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - 10 + 1)
            surface.DrawText(ply:GetPlayerName() or "Игрок вышел")

            surface.SetTextColor(pcol.r, pcol.g, pcol.b, pcol.a)
            surface.SetTextPos(w / 2, h / 2 - 10)
            surface.DrawText(ply:GetPlayerName() or "Игрок вышел")

            local info = ply:Name() .. ((not alive) and " - погиб" or "")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            surface.SetTextPos(15, h / 2 - 10)
            surface.DrawText(info)

            local frags = tostring(math.max(0, ply:Frags() or 0))
            local len = surface.GetTextSize(frags)
            surface.SetTextPos(w - len - 15, h / 2 - 10)
            surface.DrawText(frags)
        end

        function but:DoClick()
            if ply:IsBot() then
                chat.AddText(Color(255, 0, 0), "Нельзя открыть профиль бота")
                return
            end

            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end

        DScrollPanel:AddItem(but)
    end

    return true
end

function MODE:RoundStart()
    ReinforcePreviewTeam = nil
    ReinforceTeam = nil
    ReinforcePlayed = false

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end