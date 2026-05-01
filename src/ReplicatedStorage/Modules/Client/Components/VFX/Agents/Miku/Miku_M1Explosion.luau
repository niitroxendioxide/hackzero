---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster,
    Offset: CFrame,
    Scale: number
): ()
    local MikuAssets = Assets.Miku
    local Model = Caster:GetModel()
    local NewOffset = Offset or CFrame.new(0, 0, -5)
    local ModelScale = Scale or 0.75

    local Explosion = Effects:Create(MikuAssets.M1Explosion, 3)
    Explosion:PivotTo(Model:GetPivot() * NewOffset)
    Explosion:ScaleTo(ModelScale)

    Effects:Emit(Explosion, true)
end