---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local GokuAssets = Assets.Effects.Agents.Goku
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local EffectUtil = require(Shared.Utility.Effects)

---
return function(Caster: Types.Caster): ()
    --

    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.new()
    Highlight.OutlineTransparency = 1
    Highlight.FillTransparency = 0.75
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.Parent = Caster:GetAppearance():GetModel()

    --

    local At = Caster:GetPivot() * CFrame.new(0, 0, -3)
    local Beam = EffectUtil:Create(GokuAssets.Kamehameha.Beam, 2.5)
    local Length = 80 

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

    --
    task.delay(.75, function()
    
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