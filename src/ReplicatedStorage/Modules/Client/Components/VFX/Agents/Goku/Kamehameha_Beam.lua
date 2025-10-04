---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local GokuAssets = Assets.Effects.Agents.Goku
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local EffectUtil = require(Shared.Utility.Effects)

---
return function(Caster: Types.Caster): ()
    
    local At = Caster:GetPivot() * CFrame.new(0, 0, -3)
    local Beam = EffectUtil:Create(GokuAssets.Kamehameha.Beam, 10)
    local Length = 80

    Beam:PivotTo(At)

    for _, Cylinder in Beam.Beam:GetChildren() do
        local CylSize = Cylinder.Size

        EffectUtil:Tween(Cylinder, {.8}, {
            CFrame = At * CFrame.new(0, 0, -Length/2),
            Size = vector.create(CylSize.X, CylSize.Y, Length),
        })
    end
end