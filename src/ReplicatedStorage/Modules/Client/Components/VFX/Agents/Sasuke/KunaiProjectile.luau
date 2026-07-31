


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Library = require(Client.Libraries.Effects)

local MeshTweens = {
    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.35, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .275, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Effects:Random(0.45, 0.65) })
        Effects:Tween(Innermesh, { .35, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2.25, 0, 0) * CFrame.Angles(-math.pi * Effects:Random(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,

    Shock = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.375, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .35, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Effects:Random(0.5, 0.75) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(4, 0, 0) * CFrame.Angles(-math.pi * Effects:Random(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,
}

---
return function(
    Caster: Types.Caster,
    Speed: number,
    Time: number,
    Size: vector,
    UseShuriken: boolean
): ()
    --
    local KunaiVFX = Assets.Sasuke.Kunai
    local Model = Caster:GetModel()

    local BaseModel = KunaiVFX.Kunai
    if UseShuriken then
        BaseModel = Assets.Sasuke.Shuriken
    end
    
    local Projectile = Effects:Create(BaseModel, Time + 0.1)
    Projectile:PivotTo(Model:GetPivot() * CFrame.new(0, 0, -1))

    local Hit = false

    Effects:MoveProjectile(Projectile, Size or vector.create(4, 4), Speed, Time, function(Target): boolean  
        Library:Play("Hit", Target, {})
        Hit = true
        ---
        Target:Hit()
        Projectile:Destroy()

        return true
    end, nil, function(Delta: number)
        if UseShuriken then
            Projectile.Handle.CFrame *= CFrame.Angles(0, math.pi * Delta * 2, 0)
        end
    end)

    task.spawn(function()
        local Length = os.clock()
        local Last = os.clock()
        while (not Hit) and (os.clock() - Length) < Time do
            local _ = task.wait();

            if os.clock() - Last < 1 / 18 then
                continue
            end

            if Hit then return end
            Last = os.clock()
            
            local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.DashVFX, 3)
            Hit_Effect:PivotTo(Projectile:GetPivot() * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 0, Effects:Random(-math.pi, math.pi)))

            Effects:ForModelParts(Hit_Effect, MeshTweens)
        end
    end)
end