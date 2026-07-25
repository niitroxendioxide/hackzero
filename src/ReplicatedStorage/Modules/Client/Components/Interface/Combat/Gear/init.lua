local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Assets = ReplicatedStorage.Assets

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local GearDatabase = require(Database.Gears)
local BaseClass = require(Client.Classes.Interface)
local Signal = require(Shared.Utility.Signal)

local RNG = Random.new()
local Component = BaseClass.new("Gear", "Gear", {KeyToBind = Enum.KeyCode.P})
local States = {
    CurrentThread = nil,
    CurrentHoverCard = nil,

    ChosenCard = nil :: Signal.ScriptSignal<string, number>?,
    MultipleCards = nil :: Signal.ScriptSignal<{string}>?,
    SelectedCards = {},
    AllCards = {},
}

function Hover(Holder)
    if States.CurrentThread then
        task.cancel(States.CurrentThread)
        States.CurrentThread = nil

        local Card = States.CurrentHoverCard
        Effects:Tween(Card.ActualCard, {.2, 'Quad'}, {Position = UDim2.fromScale(.5, .5)})

        local Main = Card.ActualCard.Frontdesign.Main
        Main.UIStroke.Color = Color3.new()
        Main.UIStroke.Thickness = 0.024

        Card.Button.Stroke.Thickness = 0.06
        Card.Button.Stroke.Color = Color3.new()
    end

    if States.CurrentHoverCard == Holder then
        States.CurrentHoverCard = nil
        return
    end


    States.CurrentHoverCard = Holder

    States.CurrentThread = task.spawn(function()
        local BigOne, SmallOne, Pos = 0, 0, 0
        Holder.Button.Stroke.Color = Color3.new(1, 1, 1)

        local Main = Holder.ActualCard.Frontdesign.Main
        Main.UIStroke.Color = Color3.new(1, 1, 1)

        while true do
            local Delta = task.wait()

            Pos += Delta * math.pi * 1.25
            BigOne += Delta * math.pi
            SmallOne += Delta * math.pi * 0.4
            Main.UIStroke.Thickness = 0.024 + 0.004 * math.sin(BigOne)
            Holder.ActualCard.Position = UDim2.fromScale(0.5, 0.4 + math.sin(Pos) * 0.05)
            Holder.Button.Stroke.Thickness = 0.06 + 0.025 * math.sin(BigOne)
        end

    end)
end

function SelectSingularCard(Name: string, Order: number, Holder: Frame)
    States.ChosenCard:Fire(Name, Order)

    Hover(Holder)

    --
    local BaseFrame = Component:GetFrame()
    local EffectsFolder = BaseFrame.Effects

    for _, OtherCard in States.AllCards do
        local Button = OtherCard.Button

        Button.Btn:Destroy()

        if OtherCard == Holder then
            Effects:Tween(Holder, {.35, 'Cubic', 'InOut'}, {Position = UDim2.fromScale(0.5, .5)})

            task.delay(0.25, function()
                Effects:Tween(Button.UIScale, {.3, 'Back', 'In'}, {Scale = 0})

                Effects:CleanUp(Button, .3)
            end)

            Effects:CleanUp(Holder, 2)

            task.delay(0.4, function()
                Effects:Tween(Holder.ActualCard.Frontdesign.Glow, { 0.35, 'Quad' }, {BackgroundTransparency = 0})
                Effects:Tween(Holder.ActualCard.Frontdesign.Glow.UIScale, { 0.5, 'Quad' }, {Scale = 1.1})

                task.wait(0.35)
                Effects:Tween(Holder.ActualCard.UIScale, {0.3, 'Back', 'In'}, {Scale = 0})

                --
                task.wait(0.3)

                local TextEffect = EffectsFolder.BaseText:Clone()
                TextEffect.Visible = true
                TextEffect.Parent = EffectsFolder
                TextEffect.UIScale.Scale = 0

                local CircleEffect = EffectsFolder.Circle:Clone()
                CircleEffect.Visible = true
                CircleEffect.Size = UDim2.fromScale(0, 0)
                CircleEffect.Parent = EffectsFolder

                Effects:Tween(TextEffect.UIScale, { 0.32, 'Quad', 'Out' }, {Scale = 0.5})
                Effects:Tween(CircleEffect, { 0.4, 'Quad', 'Out' }, {Size = UDim2.fromScale(0.22, 0.22), Transparency = 1})
                task.wait(0.15)
                Effects:Tween(TextEffect, { 0.2, 'Quad', 'Out' }, {TextTransparency = 1})
                Effects:Tween(TextEffect.UIStroke, { 0.2, 'Quad', 'Out' }, {Transparency = 1})

                Effects:CleanUp(CircleEffect, 0.4)
                Effects:CleanUp(TextEffect, 0.4)
            end)
        else
            Effects:Tween(OtherCard.ActualCard, {.3, 'Back', 'In'}, {Position = UDim2.fromScale(0.5, -4)})
            Effects:Tween(Button.UIScale, {.25, 'Quad', 'Out'}, {Scale = 0})

            Effects:CleanUp(OtherCard, 3)
            Effects:CleanUp(Button, .25)
        end
    end

    local MainFrame = Component:GetFrame()
    Effects:Tween(MainFrame.Bg, {.3}, {BackgroundTransparency = 1})
end

function CalculateCardPosition(Order: number, Total: number)
    local Padding = 0.2

    if Total == 2 then
        return Order == 1 and 0.5-(Padding/2) or 0.5+(Padding/2)
    end

    local Start = (0.5 - ((Total - 1)//2) * Padding) - Padding
    local Pos = Start + Padding*Order

    return Pos
end

function CreateCard(Name: string, Order: number, Total: number)
    local GearData = GearDatabase:GetGearData(Name)
    if not GearData then
        warn("Cannot create card for gear:", Name)

        return
    end


    local DescriptionText = GearData.Description or 'None'
    local TextSize = ScreenUtil:GetTextSize(28)
    local Key, Value = next(GearData.Mods)
    local valText = tostring(math.floor(Value)) .. (string.match(Key, "%%") and '%' or '')


    --
    local Holder = Assets.Interface.Gear.CardHolder:Clone()
    Holder.Position = UDim2.fromScale(CalculateCardPosition(Order, Total), .5)
    Holder.ActualCard.Position = UDim2.fromScale(0.5, 5)
    Holder.Parent = Component:GetFrame().List

    table.insert(States.AllCards, Holder)

    -- Connections
    Holder.Button.Btn.MouseEnter:Connect(function()
        Hover(Holder)
    end)

    Holder.Button.Btn.MouseLeave:Connect(function()
        Hover(Holder)
    end)

    Holder.Button.Btn.MouseButton1Click:Once(function()
        SelectSingularCard(Name, Order, Holder)
    end)

    --
    task.delay(Order * 1/12, function()
        Effects:Tween(Holder.ActualCard, {.25, 'Back'}, {Position = UDim2.fromScale(0.5, 0.5)})

        for _, Object in Holder.ActualCard.Frontdesign:GetChildren() do
            if Object:IsA("Frame") or Object:IsA("ImageLabel") or Object:IsA("TextLabel") then
                Object.Visible = false
            end
        end

        for _, Object in Holder.ActualCard.Backdesign:GetChildren() do
            if Object:IsA("Frame") or Object:IsA("ImageLabel") or Object:IsA("TextLabel") then
                Object.Visible = true
            end
        end


        task.wait(.35)
        local CardObject = Holder.ActualCard
        CardObject.Frontdesign.CardName.Text = GearData.Name or Name
        CardObject.Frontdesign.Description.Text = string.format(DescriptionText, math.floor(TextSize+4), valText)
        Effects:Tween(CardObject, {.2, 'Quad', 'In'}, {Size = UDim2.fromScale(0, 1)})

        task.delay(.2, function()
            for _, Object in CardObject.Backdesign:GetChildren() do
                if Object:IsA("Frame") or Object:IsA("ImageLabel") then
                    Object.Visible = false
                end
            end

            for _, Object in CardObject.Frontdesign:GetChildren() do
                if Object:IsA("Frame") or Object:IsA("ImageLabel") or Object:IsA("TextLabel") then
                    Object.Visible = true
                end
            end

            CardObject.Frontdesign.Description.TextSize = 0
            CardObject.Frontdesign.Icon.Image = 'rbxassetid://' .. (GearData.Icon or 0)
            CardObject.Frontdesign.IconBg.Image = 'rbxassetid://' .. (GearData.Icon or 0)

            Effects:Tween(CardObject, {RNG:NextNumber(0.15, 0.3), 'Cubic', 'Out'}, {Size = UDim2.fromScale(1, 1)})
            Effects:Tween(CardObject.Frontdesign.Description, {.2, 'Back'}, {TextSize = TextSize})

            task.wait(.2)
            Holder.Button.Visible = true
        end)
    end)
end

function ClearCards()
    for _, Card in Component:GetFrame().List:GetChildren() do
        if Card:IsA("Frame") then
            Card:Destroy()
        end
    end

    States.AllCards = {}
end

function Component:Link(Player: Player)
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("FullScreenHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Gear", true)

    return Main
end

function Component:Init()

end

function Component:ShowOptions(List: {string})
    local MainFrame = self:GetFrame()

    self:Set(true)

    MainFrame.Bg.Visible = true
    MainFrame.Bg.BackgroundTransparency = 1
    Effects:Tween(MainFrame.Bg, {.25}, {BackgroundTransparency = 0.3})

    ClearCards()
    States.ChosenCard = Signal.new()

    for k, Name in List do
        CreateCard(Name, k, #List)
    end

    --
    return States.ChosenCard
end

return Component
