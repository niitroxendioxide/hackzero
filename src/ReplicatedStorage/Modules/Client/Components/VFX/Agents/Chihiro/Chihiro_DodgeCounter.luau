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
    

    ---
    local CF = Caster:GetPivot() * CFrame.new(0, 1.85, -7)

    local WarningVfx = Effects:Create(DodgeAssets.Startup, 3)
    WarningVfx:PivotTo(CF)

    Effects:Emit(WarningVfx, true)
    Effects:Tween(WarningVfx, { 0.5, 'Quart' }, {CFrame = CF * CFrame.Angles(0, 0, math.pi * 0.25)})

    task.wait(0.15)

    Effects:Toggle(WarningVfx, false)
        
    local CutsVFX = Effects:Create(DodgeAssets.Effects, 3)
    CutsVFX:ScaleTo(0.01)
    CutsVFX:PivotTo(CF)

    Effects:TweenModel(CutsVFX, 1, 0.3, 'Quad', 'Out')
    Effects:Toggle(CutsVFX, true)

    local Clock = 0;
    while Clock < 2 do
        Clock += Effects:Wait(1 / 6);

        local TransparencyTime = 0.2
        local Bubble = Effects:Create(DodgeAssets.Bubble, TransparencyTime)
        Bubble.CFrame = CF
        Bubble.Transparency = 3.75;
        Bubble.Size = vector.zero;
        local Radius = math.random(19, 26)

        Effects:Tween(Bubble, { TransparencyTime, 'Quad' }, { Transparency = 1 })
        Effects:Tween(Bubble, { 0.25, 'Quart' }, { Size = vector.create(Radius, Radius, Radius) })
    end

    Effects:Toggle(CutsVFX, false);
end