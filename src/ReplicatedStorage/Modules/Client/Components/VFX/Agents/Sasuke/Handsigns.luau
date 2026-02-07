


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local Rng = Random.new()

---
return function(
    Caster: Types.Caster,
    Time: number
): ()
    --
    local SasukeVFX = Assets.Sasuke
    local Offset = CFrame.new(0, 0.425, -0.3)

    local Model = Caster:GetModel()
    local HandsignsVFX = Effects:Create(SasukeVFX.Signs, Time + 1)
    HandsignsVFX:PivotTo(Model:GetPivot() * Offset * CFrame.Angles(0, math.pi * 0.5, 0))

    Effects:Weld(HandsignsVFX, Model.PrimaryPart)

    local cur_Time = 0
    while cur_Time < Time do
        cur_Time += Effects:Wait()
    end

    Effects:Toggle(HandsignsVFX, false)
end