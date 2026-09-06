--
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local ForgeVFX = require(ReplicatedStorage.Packages.ForgeVFX)

local ChargeOffset = CFrame.new(0.432, -1.001, -1.74)
local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local Args = {...}

    local KakashiVfx = Assets.Effects.Agents.Kakashi
    local Model = Caster:GetModel()
    
    if State == 'Charge' then
        local ChargeVFX = Effects:Create(KakashiVfx.ChargingRaikiri2, 5)
        ChargeVFX:PivotTo(Model:GetPivot() * ChargeOffset)

        task.delay(0.15, function()
            for i = 1, 2 do
                local NewShockwave = Effects:Create(Effects.General.Shockwaves.SmallGroundWind, 2.25)
                NewShockwave:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, -2.5 + Effects:Random(-0.25, 0.25), -1.7))
                ForgeVFX.emit(Effects:Random(1, 1.3), NewShockwave)
            end
        end)
        
        Cache[Caster] = function()
            Effects:Toggle(ChargeVFX, false)
            Effects:CleanUp(ChargeVFX, 0.5)
        end
    else
        const _ = Cache[Caster] and Cache[Caster]()

        --local Base = Caster:GetModel():GetPivot()
        local ForwardAt = 45
        local Base = Args[1];
        local EndCFrame = Base * CFrame.new(0, 0, -ForwardAt)
        local raikiri_dash_end = Effects:Create(KakashiVfx.DashVFX.RaikiriDashEffectEnd, 5)

        --- DashVFX
        local Beams = Effects:Create(KakashiVfx.DashVFX.Beams, 5);
        Beams:PivotTo(EndCFrame * CFrame.new(0, 0, ForwardAt/2));
        Effects:Emit(Beams)

        --- Bolt VFX
        task.spawn(function()
            for i = 1, 4 do
                local Origin = Base.Position;
                local End = EndCFrame.Position;

                Effects:CreateLightningBolt({
                    A1WorldPos = End,
                    A0WorldPos = Origin,
                    CasterModel = Caster:GetModel(),
                })

                task.wait()
            end
        end)

        ---
        for _, Asset: Instance in Beams:GetDescendants() do
            if Asset:IsA('Beam') then
                local W0, W1 = Asset.Width0, Asset.Width1

                Asset.Width0, Asset.Width1 = 0, 0
                Effects:Tween(Asset, {0.65, 'Linear'}, {TextureSpeed = 0})
                Effects:Tween(Asset, {0.275, 'Back'}, {Width0 = W0, Width1 = W1})
                Effects:FadeOutBeams(Asset, {0.6})
            elseif Asset:IsA('Attachment') and Asset.Name == "End" then
                local Pos = Asset.Position;
                Asset.Position = vector.create(Pos.X, Pos.Y, -ForwardAt/2)

                Effects:Tween(Asset, { 0.3, 'Sine' }, { Position = Pos })
            end
        end

        ----
        local Meshes = {KakashiVfx.DashVFX.DashWind3rdEffect, KakashiVfx.DashVFX.DashLineEffect, KakashiVfx.DashVFX.DashAccompaniedEffect}
        local MeshScales = { 0.92, 1, 1.18 }
        for i, scale in MeshScales do
            local NewShockwave = Effects:Create(KakashiVfx.DashVFX.DashShockwaveVFX, 5)
            NewShockwave:PivotTo(Base * CFrame.new(0, 0, -16 * i))
            ForgeVFX.emit(scale, NewShockwave)

            task.wait()
        end

        for _, MeshObj in Meshes do
            local created_mesh = Effects:Create(MeshObj, 5)
            created_mesh:PivotTo(EndCFrame)
            task.delay(0.07, function()
                ForgeVFX.emit(created_mesh)
            end)
        end 

        for i = 1, 5 do
            Effects:CreateLightningBolt({
                CasterModel = Caster:GetModel(),
                Color3 = Color3.fromRGB(112, 150, 255),
                SubpartColor = Color3.fromRGB(51, 78, 255),
                A1WorldPos = Base * Effects:RandomV3(0.75),
                A0WorldPos = EndCFrame.Position + Effects:RandomV3(),
            })
        end

        task.wait(0.07)
        raikiri_dash_end:PivotTo(Base * CFrame.new(0, 0, -40))
        for _, child_wave in raikiri_dash_end:GetChildren() do
            ForgeVFX.emit(child_wave)
        end
    end
end