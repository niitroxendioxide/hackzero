---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")


local Assets = ReplicatedStorage.Assets.Effects
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)

---
return function(Caster: Types.AgentClass, Angle: number, Offset: CFrame, Reverse: boolean, Scale: number, ApplyGroundEffect: boolean): ()
    Offset = Offset or CFrame.new(0, -0.069, 0)
    Angle = Angle or 0
    Scale = Scale or 1

    local AngleOffset = typeof(Angle) == 'number' and CFrame.Angles(0, 0, math.rad(Angle)) or Angle
    local SlashEffect = Effects:Create(Assets.Agents.Tanjiro[Reverse and 'Reverse' or 'Slash'], 2.5)
    SlashEffect:PivotTo(Caster:GetPivot() * Offset * AngleOffset)
    SlashEffect:ScaleTo(1.25 * Scale)

    if Reverse then
        for _, Emitter: ParticleEmitter in SlashEffect:GetDescendants() do
            if not Emitter:IsA("ParticleEmitter") then continue end

            Effects:ReverseEmitter(Emitter)
        end
    end

    if ApplyGroundEffect then
        local Cast = Effects:CastMapRaycast((Caster:GetModel():GetPivot() * Offset * CFrame.new(0, 0, -4)).Position, vector.create(0, -5))

        if Cast then
            local SlashGroundEffect = Effects:Create(Assets.Agents.Tanjiro.SlashGroundCutEffect, 2)
            SlashGroundEffect:PivotTo(CFrame.lookAlong(Cast.Position, Cast.Normal, Caster:GetPivot().LookVector))

            Effects:Emit(SlashGroundEffect)
        end
    end

    Effects:Emit(SlashEffect)
    Effects:CleanUp(SlashEffect, 1.5)

    --
    local Connection = RunService.Heartbeat:Connect(function(Delta: number)
        SlashEffect:PivotTo(Caster:GetPivot() * Offset * AngleOffset)
    end)

    Effects:CleanUp(Connection, 1.5)

    return SlashEffect
end