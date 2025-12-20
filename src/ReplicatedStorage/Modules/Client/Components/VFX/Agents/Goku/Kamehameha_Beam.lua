---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local GokuAssets = Assets.Effects.Agents.Goku
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local EffectUtil = require(Shared.Utility.Effects)

function Shoot(Caster)
    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.new()
    Highlight.OutlineTransparency = 1
    Highlight.FillTransparency = 0.75
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.Parent = Caster:GetAppearance():GetModel()

    --

    local At = Caster:GetPivot() * CFrame.new(0, 0.078, -4.41)
    local Beam = EffectUtil:Create(GokuAssets.Kamehameha.Beam, 2.5)
    local Aura = EffectUtil:Create(GokuAssets.Kamehameha.Aura, 2.5)
    local Length = 80 

    Aura:PivotTo(Caster:GetPivot())
    Beam:PivotTo(At)

    for _, Ball in Beam.Ball:GetChildren() do
        local ballSize = Ball.Size
        Ball.Size = vector.zero

        EffectUtil:Tween(Ball, {.2, 'Back'}, {
            Size = ballSize,
        })
    end
    

    for _, Cylinder in Beam.Beam:GetChildren() do
        local CylSize = Cylinder.Size

        Cylinder.CFrame *= CFrame.new(0, 0, Cylinder.Size.Z/2)
        Cylinder.Size *= vector.create(1, 1, 0);

        EffectUtil:Tween(Cylinder, {.75, 'Quad'}, {
            CFrame = At * CFrame.new(0, 0, -Length/2),
            Size = vector.create(CylSize.X, CylSize.Y, Length),
        })
    end

    for _, Attachment in Beam.BeamFX:GetChildren() do
        if not (string.match(Attachment.Name, "End")) then continue end
        
        local Position = Attachment.Position
        
        Attachment.Position = Position * vector.create(1, 1, 0)
        
        EffectUtil:Tween(Attachment, {.75, 'Quad'}, {
            Position = vector.create(Position.X, Position.Y, -Length)
        })
    end

    local Cast = EffectUtil:CastMapRaycast(At, vector.create(0, -25))
    if Cast then
        Beam.GroundFX.Size *= vector.create(1, 1, 0)
        Beam.GroundFX.CFrame = CFrame.lookAlong(Cast.Position, At.LookVector)

        EffectUtil:Tween(Beam.GroundFX, {.75, 'Quint'}, {
            Size = vector.create(Beam.GroundFX.Size.X, Beam.GroundFX.Size.Y, Length)
        })

    end

    --
    task.delay(.75, function()

        EffectUtil:Toggle(Aura, false)
        EffectUtil:Tween(Aura.Attachment.PointLight, {.25}, {Brightness = 0})

        EffectUtil:Tween(Highlight, {.4}, {FillTransparency = 1})

        EffectUtil:CleanUp(Highlight, .4)

        for _, Cylinder in Beam.Beam:GetChildren() do
            local CylSize = Cylinder.Size

            EffectUtil:Tween(Cylinder, {.3, 'Sine'}, {
                Size = vector.create(0, 0, CylSize.Z),
            })
        end

        for _, Ball in Beam.Ball:GetChildren() do
            EffectUtil:Tween(Ball, {.3, 'Sine'}, {
                Size = vector.zero,
            })
        end

        for _, Attachment in Beam.BeamFX:GetChildren() do
            if not Attachment:IsA("Attachment") then continue end
            local Position = Attachment.Position
            
            EffectUtil:Tween(Attachment, {.35, 'Sine'}, {
                Position = vector.create(0, 0, Position.Z)
            })
        end

        EffectUtil:Toggle(Beam, false)

        for _, Beam in Beam.BeamFX.Beams:GetChildren() do
            EffectUtil:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end
    
    end)
end

local function GetBallCF(Caster: Types.Caster)
    local Model = Caster:GetModel()
    local LArm = Model:FindFirstChild("Left Arm")
    local RArm = Model:FindFirstChild("Right Arm")

    local LCF, RCF = LArm.CFrame * CFrame.new(0, -1, 0), RArm.CFrame * CFrame.new(0, -1, 0)
    local Centre = LCF:Lerp(RCF, 0.5) * CFrame.new(0, .3, 0)

    return Centre
end

---
return function(Caster: Types.Caster, State: boolean): ()
    --

    if State then
        Shoot(Caster)
    else
        local ChargeBall = EffectUtil:Create(GokuAssets.Kamehameha.KameBall, 3)
        ChargeBall:PivotTo(GetBallCF(Caster))

        ChargeBall.Size *= 0;
        EffectUtil:Tween(ChargeBall, {.1, 'Quad'}, {Size = vector.one * 1.085})

        local Aura = EffectUtil:Create(GokuAssets.Kamehameha.ChargeAura, 2.5)

        Aura:PivotTo(Caster:GetPivot())

        local Active_Time = 0;
        while Active_Time < 0.35 do
            Active_Time += EffectUtil:Wait()

            ChargeBall:PivotTo(GetBallCF(Caster))
        end

        ChargeBall.Transparency = 1
        EffectUtil:Toggle(ChargeBall, false)
        EffectUtil:Toggle(Aura, false)
    end
end 