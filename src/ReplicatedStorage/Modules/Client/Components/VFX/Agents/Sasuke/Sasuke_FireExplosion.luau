local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Rng = Random.new()
local Effects = require(Shared.Utility.Effects)

return function(BasePivot: CFrame)
    local SasukeVFX = Assets.Sasuke

    local Raycast = Effects:CastMapRaycast(BasePivot, vector.create(0, -50))
    if Raycast then
        local ExplosionObject = Effects:Create(SasukeVFX.FireballGroundVFX, 5);
        ExplosionObject.CFrame = CFrame.lookAlong(Raycast.Position + Raycast.Normal * 1, Raycast.Normal)
        Effects:Emit(ExplosionObject, true)

        Effects:ShootRocks(Raycast, {6, 8}, {30, 50}, Effects:GetParent(script.Name))
        Effects:CreateRocks(Raycast, vector.create(3.75, 1.75, 3.75), {9, 11}, {6, 9}, {20, 45}, Effects:GetParent(script.Name))
    end


    local FireballHitVFX = Effects:Create(SasukeVFX.FireballHit, 3.65)
    FireballHitVFX:PivotTo(BasePivot)
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
end
