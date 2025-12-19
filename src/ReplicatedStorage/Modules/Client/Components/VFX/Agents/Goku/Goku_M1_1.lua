


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster,
    Offset: CFrame?,
    no_vfx: boolean?
): ()
    --
    local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.First, 3)
    Hit_Effect:PivotTo(Caster:GetModel():GetPivot() * (Offset or CFrame.new()))

    Effects:ForModelParts(Hit_Effect, {
        Outer = function(Outermesh)
            Effects:Tween(Outermesh.Decal, {.3, 'Sine'}, {Transparency = 1})
            Effects:Tween(Outermesh.Mesh, { .175, 'Cubic' }, { Scale = Outermesh.Mesh.Scale * vector.create(1.45, 1.1, 1.1) })
            Effects:Tween(Outermesh, { .4, 'Quart' }, { CFrame = Outermesh.CFrame * CFrame.new(-5, 0, 0) * CFrame.Angles(math.pi * .25, 0, 0) })
        end,
        Inner = function(Innermesh)
            Effects:Tween(Innermesh.Decal, {.2, 'Sine'}, {Transparency = 1})
            Effects:Tween(Innermesh.Mesh, { .3, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * vector.create(1.1, 0.8, .8) })
            Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-7, 0, 0) * CFrame.Angles(math.pi * .25, 0, 0) })
        end,
        Orange = function(Innermesh)
            Effects:Tween(Innermesh.Mesh, { .175, 'Quad' }, { Scale = Innermesh.Mesh.Scale * vector.create(1.35, 0, 0) })
            Effects:Tween(Innermesh, { .25, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-7, 0, 0) * CFrame.Angles(math.pi * .25, 0, 0) })
        end,
        Blue = function(Outermesh)
            Effects:Tween(Outermesh.Decal, {.4, 'Sine'}, {Transparency = 1})
            Effects:Tween(Outermesh.Mesh, { .45, 'Cubic' }, { Scale = Outermesh.Mesh.Scale * vector.create(1.75, 1.2, 1.2) })
            Effects:Tween(Outermesh, { .6, 'Quart' }, { CFrame = Outermesh.CFrame * CFrame.new(-5, 0, 0) * CFrame.Angles(math.pi * .5, 0, 0) })
        end,
        Effect = function(vfx)
            if no_vfx then return end
            Effects:Emit(vfx)
        end
    })
end