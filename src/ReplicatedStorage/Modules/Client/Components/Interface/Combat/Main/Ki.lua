local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Vegeta

local Component = {
    Tweens = {}
}

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}
function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.Ki:Clone()
    Meter.Fill.Size = UDim2.fromScale(0, 1)
    Meter.Percent.Text = "0%"
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Value: number)
    local Meter = Frame.Meters:FindFirstChild('Ki');
    if not Meter then
        Meter = Component:Create(Frame)
    end
    const Val = (math.floor(Value * 100)) .. "%"

    Meter.Percent.Text = Val
    Effects:Tween(Meter.Fill, { 0.2, 'Quad' }, {Size = UDim2.fromScale(math.clamp(Value, 0, 1), 1)})
end


return Component