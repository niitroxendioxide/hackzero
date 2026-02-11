local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Sasuke

local Component = {}

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}
function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.Sharingan:Clone()
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Value: number)
    local Meter = Frame.Meters:FindFirstChild('Sharingan');
    local Corrected = Value * 3;
    if not Meter then
        Meter = Component:Create(Frame)
    end
     
    Meter.TextLabel.Text = 'Sharingan: '..(Corrected or 0).."/3";
end


return Component