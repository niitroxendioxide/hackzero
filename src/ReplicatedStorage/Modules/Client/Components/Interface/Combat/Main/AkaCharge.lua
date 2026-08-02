local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Chihiro

local Component = {}

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}
function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.AkaCharge:Clone()
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Percent: number)
    local Meter = Frame.Meters:FindFirstChild('AkaCharge');
    if not Meter then
        Meter = Component:Create(Frame)
    end

    Meter.Percent.Text = (math.floor(Percent * 100)) .. "%"

    Effects:Tween(Meter.Fill, { 0.2, 'Quad' }, {Size = UDim2.fromScale(Percent, 1)})
end


return Component