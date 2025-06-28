local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Jotaro3

local Component = {}

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}
function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.Stand:Clone()
    Meter.Name = 'StandMeter'
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Percent: number)
    local BaseMeter = Frame.Meters:FindFirstChild('StandMeter')
    if not BaseMeter then
        BaseMeter = Component:Create(Frame)
    end

    local EffectTransparency = 1 - 0.3 * Percent;
    Effects:Tween(BaseMeter.Main.UIGradient, {.25, 'Quart'}, {
        Offset = Vector2.new(-0.8 + Percent, 0)
    })
    BaseMeter.Effect.ImageTransparency = EffectTransparency
end


return Component