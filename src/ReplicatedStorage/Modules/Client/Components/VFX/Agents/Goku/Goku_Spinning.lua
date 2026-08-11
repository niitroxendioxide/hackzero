


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

local function get_cf(Caster: Types.ClientAgent)
    return CFrame.lookAlong(Caster:GetModel().Torso.Position, Caster:GetPivot().LookVector)
end

---
return function(
    Caster: Types.Caster,
    Time: number
): ()
    ---
    Time = Time or 0.3

    local DashEffect = Effects:Create(Assets.Goku.Spinning, Time + 1)
    DashEffect.Anchored = true
    DashEffect:PivotTo(get_cf(Caster))
    
    local Toggled = false
    local Start = os.clock()
    while (os.clock() - Start) < (Time + 1) do
        if (os.clock() - Start) > Time and not Toggled then
            Toggled = true
            Effects:Toggle(DashEffect, false)
        end

        DashEffect:PivotTo(get_cf(Caster))

        task.wait()
    end
end