


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService("Lighting")

local Assets = ReplicatedStorage.Assets.Effects.Agents.Goku.EnergyExplosion
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)


---
return function(
    Caster: Types.Caster
): ()

    local ChargeUp = Effects:Create(Assets.ChargeUp, 10)
    ChargeUp:PivotTo(Caster:GetPivot())

    local Correction = Instance.new('ColorCorrectionEffect')
    Correction.Parent = Lighting 

    Effects:Tween(Correction, {.25, 'Sine'}, {Brightness = -0.05, TintColor = Color3.fromRGB(207, 236, 255)})

    task.wait(0.25)
    Correction.Brightness = 0.45
    Effects:Tween(Correction, {.25, 'Quad'}, {Brightness = 0, TintColor = Color3.new(1, 1, 1)})


    EffectsLib:Play('Glow', Caster, {Color = Color3.new(0, 1, 1)})
    Effects:Toggle(ChargeUp, false)

    --
    local Explosion = Effects:Create(Assets.Explosion, 10)
    Explosion:PivotTo(Caster:GetPivot())

    Effects:Emit(Explosion, true)
end