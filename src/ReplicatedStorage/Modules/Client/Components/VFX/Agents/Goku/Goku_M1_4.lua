


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster,
    Id: number?
): ()
    --
    local Offset = if Id == 2 then CFrame.Angles(0, 0, math.rad(25))
        else if (Id == 5) then CFrame.Angles(0, 0, math.rad(72)) 
        else if (Id == 6) then CFrame.Angles(0, 0, math.pi * 0.5) 
        else CFrame.new()
    local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.MeshVFXKick, 3)
    Hit_Effect:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.33, 0) * Offset)
    local Rng = Random.new()

    Effects:ForModelParts(Hit_Effect, {
        WhiteSlash = function(Outermesh)
            Effects:Tween(Outermesh.Decal, {.3, 'Sine'}, {Transparency = 1})
            Effects:Tween(Outermesh.Mesh, { .5, 'Cubic' }, { Scale = Outermesh.Mesh.Scale * 1.1 })
            Effects:Tween(Outermesh, { .6, 'Sine' }, { CFrame = Outermesh.CFrame * CFrame.Angles(-math.pi * Rng:NextNumber(0.05, 0.4), 0, 0) })
        end,
        Outer = function(Innermesh)
            Effects:Tween(Innermesh.Decal, {.2, 'Sine'}, {Transparency = 1})
            Effects:Tween(Innermesh.Mesh, { .35, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * 1.2 })
            Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.Angles(-math.pi * Rng:NextNumber(0.02, 0.08), 0, 0) })
        end,
        Orange = function(Orangemesh)
            task.delay(0.1, function()
                Effects:Tween(Orangemesh.Decal, {.075, 'Sine'}, {Transparency = 1})
            end)
            Effects:Tween(Orangemesh.Mesh, { .2, 'Quad' }, { Scale = Orangemesh.Mesh.Scale * vector.create(1.225, 1, 1)})
            Effects:Tween(Orangemesh, { .25, 'Quart' }, { CFrame = Orangemesh.CFrame * CFrame.Angles(-math.pi * 0.1, 0, 0) })
            Orangemesh.CFrame *= CFrame.Angles(math.pi * 0.3, 0, 0)
        end,
        Blue = function(Outermesh)
            Effects:Tween(Outermesh.Decal, {.35, 'Sine'}, {Transparency = 1})
            Effects:Tween(Outermesh.Mesh, { .4, 'Cubic' }, { Scale = Outermesh.Mesh.Scale * 1.2 })
            Effects:Tween(Outermesh, { .55, 'Quart' }, { CFrame = Outermesh.CFrame * CFrame.Angles(-math.pi * Rng:NextNumber(0.1, 0.2), 0, 0) })
        end,
    })
end