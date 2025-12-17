


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
    local RaiseVFX = Effects:Create(Assets.Goku.Raise, 10)
    RaiseVFX:PivotTo(Caster:GetPivot())

    Effects:Emit(RaiseVFX, true)
end