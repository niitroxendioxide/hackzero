local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Sasuke

local Component = {
    Tweens = {}
}

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

    if not Meter.Visible and Corrected > 0 then
        for _, Tween: Tween in Component.Tweens do
            Tween:Cancel()
        end

        for _, Obj in {Meter.First, Meter.Second, Meter.Third} do
            Obj.UIScale.Scale = 0;
            table.insert(Component.Tweens, Effects:Tween(Obj.UIScale, { 0.35, 'Quart' }, {Scale = 1}))
        end
    end

    Meter.Visible = Corrected > 0;
    Meter.Count.Text = tostring(Corrected or 0, 10);

    if Corrected == 1 then
        Effects:Tween(Meter.Second, { 0.3, 'Quad' }, {ImageTransparency = 1})
        Effects:Tween(Meter.Third, { 0.3, 'Quad' }, {ImageTransparency = 1})
    elseif Corrected == 2 then
        Effects:Tween(Meter.Second, { 0.3, 'Quad' }, {ImageTransparency = 0})
        Effects:Tween(Meter.Third, { 0.3, 'Quad' }, {ImageTransparency = 1})
    elseif Corrected == 3 then
        Meter.Second.ImageTransparency = 0
        Meter.Third.ImageTransparency = 1

        Effects:Tween(Meter.Third, { 0.3, 'Quad' }, {ImageTransparency = 0})
    end
end


return Component