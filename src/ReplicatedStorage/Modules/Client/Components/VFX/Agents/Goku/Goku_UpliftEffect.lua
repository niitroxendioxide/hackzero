


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
    local Explosion = Effects:Create(Assets.Goku.UpLiftEffect, 10)
    Explosion:PivotTo(Caster:GetPivot() * CFrame.new(0, 0, -2.75))

    Effects:Emit(Explosion, true)
end