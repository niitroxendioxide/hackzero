


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Library = require(Client.Libraries.Effects)

local Cache = {}
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
    Offset: CFrame,
    Hitfn: () -> ()
): ()
    --
    local NarutoVFX = Assets.Naruto
    local Model = Caster:GetModel()
    local ShurikenModel = Model:FindFirstChild('Shuriken')

    if Speed == true then
        if ShurikenModel then
            Cache[Caster] = Effects:Tween(ShurikenModel, { 0.175 }, {Transparency = 0})
        end

        return
    elseif Speed == false then
        if ShurikenModel then
            if Cache[Caster] then
                Cache[Caster]:Cancel()
            end
            
            ShurikenModel.Transparency = 1;
        end

        return
    end

    ShurikenModel.Transparency = 1;

    Offset = Offset or CFrame.new()
    
    local Projectile = Effects:Create(NarutoVFX.Shuriken, Time + 1)
    Projectile:PivotTo(Model:GetPivot() * CFrame.new(0, 0, -1) * Offset)

    local Hit = false

    Effects:MoveProjectile(Projectile, vector.create(4, 4), Speed, Time, function(Target): boolean  
        Library:Play("Hit", Target, {})
        Hit = true
        ---
        Target:Hit()
        Effects:Toggle(Projectile, false)

        if Hitfn then
            Hitfn(Target)
        end

        return true
    end, nil, function(Delta: number)
        Projectile.Handle.CFrame *= CFrame.Angles(0, 0, math.tau * 6 * Delta)
    end)

    task.spawn(function()
        local Length = os.clock()
        local Last = os.clock()
        local ref_time = (1 / 18)
        local base = Assets.Goku.BasicAttack.DashVFX
    
        while (not Hit) and (os.clock() - Length) < Time do
            local _ = task.wait();

            if os.clock() - Last < ref_time then
                continue
            end

            if Hit then return end
            Last = os.clock()
            
            local Hit_Effect = Effects:Create(base, 3)
            Hit_Effect:PivotTo(Projectile:GetPivot() * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 0, Effects:Random(-math.pi, math.pi)))

            Effects:ForModelParts(Hit_Effect, MeshTweens)
        end

        Effects:Toggle(Projectile, false)
        for _, Obj in Projectile:GetDescendants() do
            if Obj:IsA('BasePart') then
                Obj.Transparency = 1;
            end
        end
    end)
end