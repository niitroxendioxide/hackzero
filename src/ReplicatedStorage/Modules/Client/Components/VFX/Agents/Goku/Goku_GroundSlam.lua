


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService("Lighting")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)


---
return function(
    Caster: Types.Caster
): ()
    EffectsLib:Play('Glow', Caster, {Color = Color3.new(0.960784, 0.905882, 0.121569)})

    --
    local Explosion = Effects:Create(Assets.Goku.EX_Mode.exp, 10)
    Explosion:PivotTo(Caster:GetPivot() * CFrame.new(0, -2.75, 0))

    Effects:Emit(Explosion, true)
end