--[[
    ROUGH DRAFT - Kakashi's 'Lightning' charge meter (6 pips).

    Auto-registered by Main/init.lua because the module name matches the meter name in
    Kakashi.lua's Moveset_Data.Passive.Meters. Needs an Assets.Interface.Agents.Kakashi.Lightning
    template laid out like Goku's SaiyanSurge (an 'Orbs' folder of LayoutOrder'd Frames, each with
    a MiddleStroke, a Glow and a UIScale).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local InterfaceAssets = Assets.Interface.Agents.Kakashi

local Component = {}

const MAX_CHARGES = 6;
const CHARGED_COLOR = Color3.fromRGB(117, 150, 244);
const CHARGED_STROKE = Color3.fromRGB(35, 58, 140);
const EMPTY_COLOR = Color3.fromRGB(98, 98, 98);
const EMPTY_STROKE = Color3.fromRGB(74, 74, 74);

type FrameObj = Frame & {Meters: Frame & {UIListLayout: UIListLayout}}

function Component:Create(FrameObject: FrameObj)
    local Meter = InterfaceAssets.Lightning:Clone()
    Meter.Parent = FrameObject.Meters

    return Meter
end

function Component:Update(Frame: FrameObj, Percent: number, _Value: number)
    local Meter = Frame.Meters:FindFirstChild('Lightning');
    local ChargesLit = math.round(Percent * MAX_CHARGES);

    if not Meter then
        Meter = Component:Create(Frame)
    end

    for _, Object in Meter.Orbs:GetChildren() do
        if not Object:IsA('Frame') then
            continue
        end

        if Object.LayoutOrder <= ChargesLit then
            Object.BackgroundColor3 = CHARGED_COLOR;
            Object.MiddleStroke.Color = CHARGED_STROKE;
            Object.Glow.Visible = true
            Object.UIScale.Scale = 0.85
            Effects:Tween(Object.UIScale, {0.25, 'Back'}, {Scale = 1})
        else
            Object.BackgroundColor3 = EMPTY_COLOR;
            Object.MiddleStroke.Color = EMPTY_STROKE;
            Object.Glow.Visible = false
        end
    end
end

return Component
