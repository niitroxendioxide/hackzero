local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Goku

local Component = {}

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}
function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.SaiyanSurge:Clone()
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Percent: number)
    local Meter = Frame.Meters:FindFirstChild('SaiyanSurge');
    local AmountOfSpheres = math.round(Percent * 4);
    if not Meter then
        Meter = Component:Create(Frame)
    end

    for _, Object in Meter.Orbs:GetChildren() do
        if Object.LayoutOrder <= AmountOfSpheres then
            Object.BackgroundColor3 = Color3.fromRGB(255, 179, 1);
            Object.MiddleStroke.Color = Color3.fromRGB(112, 95, 0);
            Object.Glow.Visible = true
            Object.UIScale.Scale = 0.85
            Effects:Tween(Object.UIScale, {0.25, 'Back'}, {Scale = 1})
        else
            Object.BackgroundColor3 = Color3.fromRGB(98, 98, 98);
            Object.MiddleStroke.Color = Color3.fromRGB(74, 74, 74);
            Object.Glow.Visible = false
        end
    end
     
end


return Component