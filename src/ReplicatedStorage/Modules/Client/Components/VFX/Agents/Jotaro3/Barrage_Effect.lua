---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)


---
return function(Caster: Types.AgentClass): ()
    local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
    if not StandModel then
        return
    end

    if not Caster:HasTag('Barraging') then
        return
    end

    local Offset = CFrame.new(0, 0, -1)
    local Effect = Effects:Create(Assets.Effects.Agents.Jotaro3.BarrageEffect, 10)
    Effect.CFrame = StandModel:GetPivot() * Offset

    while Caster:HasTag('Barraging') do
        if not StandModel:IsDescendantOf(workspace) then
            break
        end

        Effect.CFrame = StandModel:GetPivot() * Offset
        task.wait()
    end

    Effects:Toggle(Effect, false)
end