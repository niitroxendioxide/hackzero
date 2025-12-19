


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local Rng = Random.new()

local MeshTweens = {
    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.2, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .15, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.1, 1.3) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2.25, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,

    Shock = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.1, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .2, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.1, 1.3) })
        Effects:Tween(Innermesh, { .15, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(4, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,
}

---
return function(
    Caster: Types.Caster
): ()
    ---
    local DashEffect = Effects:Create(Assets.Goku.BasicAttack.DashBack, 2)
    DashEffect.Anchored = false
    DashEffect:PivotTo(Caster:GetModel():GetPivot() * CFrame.Angles(0, math.pi, 0))
    Effects:Weld(DashEffect, Caster:GetModel().PrimaryPart)
    Effects:RecolorToGroundColor(Caster:GetModel():GetPivot().Position, DashEffect.att:GetChildren())

    local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.DashVFX, 3)
    Hit_Effect:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.33, -1))

    Effects:ForModelParts(Hit_Effect, MeshTweens)

    --
    local Active_Time = 0
    while Active_Time < 0.225 do
        Active_Time += Effects:Wait()
    end

    Effects:Toggle(DashEffect, false)
end