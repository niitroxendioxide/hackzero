


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local Rng = Random.new()
local MeshTweens = {
    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.35, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .275, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.75, 2.45) })
        Effects:Tween(Innermesh, { .35, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2.25, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,

    Shock = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.375, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .35, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.75, 2.75) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(4, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,
}

---
return function(
    Caster: Types.Caster
): ()
    --
    local SasukeVFX = Assets.Sasuke
    local Offset = CFrame.new(0, 0, -2.75)

    local FireballShootVFX = Effects:Create(SasukeVFX.ShootFireball, 1)
    FireballShootVFX:PivotTo(Caster:GetModel():GetPivot() * Offset)
    Effects:Emit(FireballShootVFX)
    
    local FireballVFX = Effects:Create(SasukeVFX.Fireball, 2, workspace)
    FireballVFX:PivotTo(Caster:GetModel():GetPivot() * Offset)
    FireballVFX:ScaleTo(0.001)
    Effects:TweenModel(FireballVFX, .75, 0.45, 'Back')

    local Cleaned = false;
    local function CleanUp()
        if Cleaned then
            return;
        end

        Cleaned = true;

        Effects:Toggle(FireballVFX, false)
        Effects:Tween(FireballVFX.PrimaryPart, { 0.1, 'Quad' }, {Transparency = 1})
    end

    Effects:MoveProjectile(FireballVFX, vector.create(12, 12), 90, 1, function(): boolean  
        CleanUp()

        local Raycast = Effects:CastMapRaycast(FireballVFX:GetPivot(), vector.create(0, -50))
        if Raycast then
            local ExplosionObject = Effects:Create(SasukeVFX.FireballGroundVFX, 5);
            ExplosionObject.CFrame = CFrame.lookAlong(Raycast.Position + Raycast.Normal * 1, Raycast.Normal)
            Effects:Emit(ExplosionObject, true)

            Effects:ShootRocks(Raycast, {6, 8}, {30, 50}, Effects:GetParent(script.Name))
            Effects:CreateRocks(Raycast, vector.create(3.75, 1.75, 3.75), {9, 11}, {6, 9}, {20, 45}, Effects:GetParent(script.Name))
        end


        local FireballHitVFX = Effects:Create(SasukeVFX.FireballHit, 3.65)
        FireballHitVFX:PivotTo(FireballVFX:GetPivot())
        Effects:Emit(FireballHitVFX)

        local Mesh = Effects:Create(SasukeVFX.ExplosionMesh, 2)
        Mesh:PivotTo(FireballHitVFX:GetPivot())
        Effects:ForModelParts(Mesh, {
            Wind = function(Mesh)
                Effects:Tween(Mesh, { 0.75, 'Sine' }, { 
                    Transparency = 1, 
                    CFrame = Mesh.CFrame * Effects:RandomAngles(), 
                    Size = Mesh.Size * Rng:NextNumber(1.8, 2.75) 
                })
            end,

            
            Fire = function(Mesh)
                Effects:Tween(Mesh, { 0.3, 'Sine' }, { 
                    Transparency = 1, 
                    CFrame = Mesh.CFrame * Effects:RandomAngles(),
                    Size = Mesh.Size * Rng:NextNumber(1.4, 1.5)
                })

                Mesh.Size *= 0
            end,

            Smoke = function(Mesh)
                Effects:Tween(Mesh, { 0.85, 'Sine' }, { 
                    Transparency = 1, 
                    CFrame = Mesh.CFrame * Effects:RandomAngles(),
                })
                Effects:Tween(Mesh, {0.4, 'Quart'}, {
                    Size = Mesh.Size * Rng:NextNumber(1.4, 1.6)
                })
                Mesh.Size *= 0
            end
        })

        return true
    end)

    task.delay(1, CleanUp)
    task.spawn(function()
        local Last = os.clock()
        while not Cleaned do
            local _ = task.wait();

            if os.clock() - Last < 1 / 14 then
                continue
            end

            Last = os.clock()
            
            local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.DashVFX, 3)
            Hit_Effect:PivotTo(FireballVFX:GetPivot() * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 0, Rng:NextNumber(-math.pi, math.pi)))

            Effects:ForModelParts(Hit_Effect, MeshTweens)
        end
    end)
end