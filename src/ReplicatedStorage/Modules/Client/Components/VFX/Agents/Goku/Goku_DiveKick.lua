


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local Rng = Random.new()

local DashKickTweens = {
    Inner = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.45, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .1, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextInteger(1, 1.25) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-12, 0, 0) * CFrame.Angles(math.pi * Rng:NextNumber(-0.22, 0.22), 0, 0) })

        Innermesh.Mesh.Scale *= vector.create(0.65, 0.2, 0.2)
    end,

    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.5, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .5, 'Cubic' }, {Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.45, 1.65) })
        Effects:Tween(Innermesh, { .45, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-7, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(-0.06, 0.06), 0, 0) })

        Innermesh.Mesh.Scale *= vector.create(0.5, 0.45, 0.45)
    end,
}

local KickHitTweens = {
    Orange = function(Innermesh)
        Effects:Tween(Innermesh.Mesh, { .225, 'Cubic' }, { Scale = vector.create(Innermesh.Mesh.Scale.x * 1.35, 0, 0) })
        Effects:Tween(Innermesh, { .45, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-12, 0, 0) * CFrame.Angles(math.pi * Rng:NextNumber(-0.22, 0.22), 0, 0) })

        Innermesh.Mesh.Scale *= vector.create(1.65, 3, 3)
    end,

    Outer = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.37, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .45, 'Cubic' }, {Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.8, 2) })
        Effects:Tween(Innermesh, { .35, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(7, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(-0.1, 0.1), 0, 0) })

        Innermesh.Mesh.Scale *= vector.create(0.5, 0.45, 0.45)
    end,

    Blue = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.5, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .45, 'Cubic' }, {Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.6, 2) })
        Effects:Tween(Innermesh, { .65, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(-0.65, 0.65), 0, 0) })

        Innermesh.Mesh.Scale *= vector.create(0.5, 0.45, 0.45)
    end,

    Main = function(Innermesh)
        Effects:Emit(Innermesh, true)
    end,
}

---
return function(
    Caster: Types.Caster,
    First: boolean?
): ()
    local _CasterModel = Caster:GetModel();

    if First then
        local DashKick = Effects:Create(Assets.Goku.BasicAttack.DashKick, 3)
        DashKick:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.4, 10.77))
        Effects:ForModelParts(DashKick, DashKickTweens)
    else
        local FinalDiveKick = Effects:Create(Assets.Goku.BasicAttack.FinalDiveKick, 3)
        FinalDiveKick:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.3, -3))
        Effects:ForModelParts(FinalDiveKick, KickHitTweens)
    end

end