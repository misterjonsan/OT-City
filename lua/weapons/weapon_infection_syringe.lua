if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_bandage_sh"

SWEP.PrintName = "MTR-9 «Морок»"
SWEP.Instructions = "Экспериментальная ампула MTR-9 «Морок». Запускает медленно прогрессирующее заражение с четырьмя стадиями мутации вплоть до полного захвата нервной системы. Носитель теряет двигательную активность, глаза темнеют, начинается биологическое подчинение. Повторная инъекция требуется в течение 3 минут — в противном случае наступает деструкция головы."
SWEP.Category     = "ZCity Medicine"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot    = 5
SWEP.SlotPos = 10

SWEP.HoldType       = "normal"
SWEP.ViewModel      = ""

SWEP.WorldModel     = "models/bloocobalt/l4d/items/w_eq_adrenaline.mdl"
SWEP.AutoSwitchTo   = false
SWEP.AutoSwitchFrom = false
SWEP.WorkWithFake   = true
SWEP.showstats      = false


SWEP.offsetVec  = Vector(3, -2.5, -1)
SWEP.offsetAng  = Angle(-30, 20, -90)
SWEP.ModelScale = 0.65
SWEP.Color      = Color(0, 180, 60)   

if CLIENT then
    SWEP.WepSelectIcon    = Material("entities/weapon_infection_syringe.png")
    SWEP.IconOverride     = "entities/weapon_infection_syringe.png"
    SWEP.BounceWeaponIcon = false
end


SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.DeploySnd    = ""
SWEP.HolsterSnd   = ""

SWEP.modeNames     = { [1] = "infection" }
SWEP.modeValuesdef = { [1] = 1 }

local hg_healanims = ConVarExists("hg_healanims")
    and GetConVar("hg_healanims")
    or  CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

function SWEP:InitializeAdd()
    self:SetHold(self.HoldType)
    self.modeValues = { [1] = 1 }
end


function SWEP:Think()
    self:SetBodyGroups("11")
    if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
        self:SetHolding(math.max(self:GetHolding() - 4, 0))
    end
end

function SWEP:Animation()
    local hold = self:GetHolding()
    self:BoneSet("r_upperarm", vector_origin, Angle(0, -hold + (100 * (hold / 100)), 0))
    self:BoneSet("r_forearm",  vector_origin, Angle(-hold / 6, -hold * 2, -15))
end

function SWEP:OwnerChanged()
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsNPC() then
        self:SpawnGarbage(nil, nil, nil, self.Color, "2211")
    end
end

if SERVER then
    function SWEP:Heal(ent, mode)
        local owner = self:GetOwner()

        if ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
            self:SetHolding(math.min(self:GetHolding() + 4, 100))
            if self:GetHolding() < 100 then return end
        end

        local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
        entOwner:EmitSound("snd_jack_hmcd_needleprick.wav", 80, math.random(75, 90))

        local targetPly
        if ent:IsPlayer() then
            targetPly = ent
        end

        if not targetPly then return end

        if targetPly.infection_phase and targetPly.infection_phase > 0 then
            if targetPly.infection_phase == 5 then

                Infection_ResetBoomTimer(targetPly)
                self.modeValues[1] = 0
                owner:SelectWeapon("weapon_hands_sh")
                self:SpawnGarbage(nil, nil, nil, self.Color, "2211")
                self:Remove()
            end

            return
        end

        Infection_Begin(targetPly)

        self.modeValues[1] = 0
        owner:SelectWeapon("weapon_hands_sh")
        self:SpawnGarbage(nil, nil, nil, self.Color, "2211")
        self:Remove()
    end
end

if SERVER then
    local next_cough = {}
    
    hook.Add("Think", "Infection_PhaseLogicSync", function()
        for _, ply in ipairs(player.GetAll()) do

            local phase = ply.infection_phase or 0
            ply:SetNWInt("ClientInfectionPhase", phase)

            -- Кашель на 2-й фазе
            if phase == 2 then
                if not next_cough[ply] or CurTime() > next_cough[ply] then
                    ply:EmitSound("ambient/voices/cough" .. math.random(1,4) .. ".wav", 75, 100, 1)
                    next_cough[ply] = CurTime() + math.random(7, 15)
                end
            else
                next_cough[ply] = nil
            end
        end
    end)
end

if CLIENT then
    local symbols = {"β", "Σ", "Ω", "Ø", "π", "§", "Ψ", "≠", "μ", "α"}
    local infection_symbols = {}


    surface.CreateFont("InfectionSymBold", {
        font      = "Arial",
        size      = 52,
        weight    = 900,
        antialias = true,
    })

    hook.Add("HUDPaint", "Infection_PhaseSymbolsHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then
            infection_symbols = {}
            return
        end

        local phase = ply:GetNWInt("ClientInfectionPhase", 0)

        if phase == 4 then
            local scrw, scrh = ScrW(), ScrH()

            if math.random() < 0.12 then
                table.insert(infection_symbols, {
                    sym   = symbols[math.random(1, #symbols)],
                    x     = math.random(20, scrw - 20),
                    y     = scrh + 10,
                    speed = math.random(180, 380),
                })
            end
        else
            infection_symbols = {}
        end

        local scrh = ScrH()
        local fadeZone = scrh * 0.15

        for i = #infection_symbols, 1, -1 do
            local s = infection_symbols[i]
            s.y = s.y - s.speed * FrameTime()

            if s.y < -60 then
                table.remove(infection_symbols, i)
            else
                local alpha = 255
                if s.y < fadeZone then
                    alpha = math.Clamp((s.y / fadeZone) * 255, 0, 255)
                end
                draw.SimpleText(s.sym, "InfectionSymBold", s.x, s.y,
                    Color(255, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)

    local eyeGlowMat = Material("sprites/glow04_noz")

    hook.Add("PostDrawOpaqueRenderables", "FullInfectionEyeGlow", function()
        local lp = LocalPlayer()
        if not IsValid(lp) then return end

        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) then continue end
            if ply:GetNWInt("ClientInfectionPhase", 0) ~= 5 then continue end
            if ply == lp then continue end  

            
            local fakeRag = ply:GetNWEntity("FakeRagdoll")
            local ent     = IsValid(fakeRag) and fakeRag or ply

            local attID = ent:LookupAttachment("eyes")
            if not attID or attID <= 0 then continue end

            local att = ent:GetAttachment(attID)
            if not att then continue end

            local pos      = att.Pos + att.Ang:Forward() * 0.8
            local rightVec = att.Ang:Right()
            local leftEye  = pos + rightVec * -1.6
            local rightEye = pos + rightVec *  1.6
            local pulse    = 2.2 + math.sin(CurTime() * 5) * 0.9
            local col      = Color(255, 0, 0)

            render.SetMaterial(eyeGlowMat)
            render.DrawSprite(leftEye,  pulse * 1.6, pulse * 1.6, col)
            render.DrawSprite(rightEye, pulse * 1.6, pulse * 1.6, col)
            render.DrawSprite(leftEye,  pulse * 4.8, pulse * 4.8, col)
            render.DrawSprite(rightEye, pulse * 4.8, pulse * 4.8, col)
        end
    end)
end
