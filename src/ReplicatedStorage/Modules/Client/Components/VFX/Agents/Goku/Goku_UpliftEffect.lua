


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster
): ()
    --
    local CasterModel = Caster:GetModel()
    local Explosion = Effects:Create(Assets.Goku.UpLiftEffect, 10)
    Explosion:PivotTo(CasterModel:GetPivot() * CFrame.new(0, 0, -2.75))

    Effects:Emit(Explosion, true)

    ---
    local CastGround = Effects:CastMapRaycast(CasterModel:GetPivot().Position, vector.create(0, -5))
    if CastGround then
        Effects:RecolorSmoke(CastGround, Explosion.Main.Ground:GetChildren())
    else
        Explosion.Main.Ground:Destroy()
    end
end