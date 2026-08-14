---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)

return function(Caster, Offset: CFrame, no_vfx: boolean)
    local Hit_Effect = Effects:Create(Assets.Effects.Agents.Sasuke.BasicAttack.Fist, 3)
    Hit_Effect:PivotTo(Caster:GetModel():GetPivot() * (Offset or CFrame.new()))

    no_vfx = true

    Effects:ForModelParts(Hit_Effect, {
        Outer = function(Outermesh)
            Effects:Tween(Outermesh.Decal, {.27, 'Sine'}, {Transparency = 1})
            Effects:Tween(Outermesh.Mesh, { .2, 'Cubic' }, { Scale = Outermesh.Mesh.Scale * vector.create(1.45, 1.15, 1.15) })
            Effects:Tween(Outermesh, { .35, 'Quart' }, { CFrame = Outermesh.CFrame * CFrame.new(-1.75, 0, 0) * CFrame.Angles(math.pi * .25, 0, 0) })
        end,
        Color = function(Innermesh)
            
            Effects:Tween(Innermesh.Mesh, { .17, 'Quad' }, { Scale = Innermesh.Mesh.Scale * vector.create(1.45, 0, 0) })
            Effects:Tween(Innermesh, { .27, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-3.25, 0, 0) * CFrame.Angles(math.pi * .25, 0, 0) })
            Innermesh.Mesh.Scale *= vector.create(1, 1.25, 1.25)
        end,
        Effect = function(vfx)
            if no_vfx then return end
            Effects:Emit(vfx)
        end
    })
end
