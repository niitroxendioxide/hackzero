---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff

---
return function(
    Caster: Types.Caster
): ()
    local DodgeAssets = Assets.Chihiro.DodgeCounter
    
    local CutsVFX = Effects:Create(DodgeAssets.Effects, 2)
    CutsVFX:PivotTo(Caster:GetPivot() * CFrame.new(0, 1.85, -7))

    Effects:Toggle(CutsVFX, true)

    local Clock = 0;
    while Clock < 1 do
        Clock += Effects:Wait(1 / 6);

        local TransparencyTime = 0.35
        local Bubble = Effects:Create(DodgeAssets.Bubble, TransparencyTime)
        Bubble.Transparency = 3.75;
        Bubble.Size = vector.zero;
        local Radius = math.random(11, 15)

        Effects:Tween(Bubble, { TransparencyTime, 'Quad' }, { Transparency = 1 })
        Effects:Tween(Bubble, { 0.45, 'Quart' }, { Size = vector.create(Radius, Radius, Radius) })
    end

    Effects:Toggle(CutsVFX, false);
end