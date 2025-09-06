local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Database = ReplicatedStorage.Modules.Shared.Database
local Assets = ReplicatedStorage.Assets

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local GearDatabase = require(Database.Gears)
local BaseClass = require(Client.Classes.Interface)

local RNG = Random.new()
local Component = BaseClass.new("Gear", "Gear", {KeyToBind = Enum.KeyCode.P})
local States = {
    CurrentThread = nil,
    CurrentHoverCard = nil,
}

function Hover(Holder)
    if States.CurrentThread then
        task.cancel(States.CurrentThread)
        States.CurrentThread = nil

        local Card = States.CurrentHoverCard
        Card.ActualCard.Stroke.Enabled = false
        Effects:Tween(Card.ActualCard, {.2, 'Quad'}, {Position = UDim2.fromScale(.5, .5)})
        Card.Button.Stroke.Thickness = ScreenUtil:GetStrokeSize(4)
        Card.Button.Stroke.Color = Color3.new()
    end

    if States.CurrentHoverCard == Holder then
        States.CurrentHoverCard = nil
        return
    end


    States.CurrentHoverCard = Holder

    States.CurrentThread = task.spawn(function()
        local BigOne, SmallOne, Pos = 0, 0, 0
        Holder.ActualCard.Stroke.Enabled = true
        Holder.Button.Stroke.Color = Color3.new(1, 1, 1)

        local Default = ScreenUtil:GetStrokeSize(2)
        local Extra = ScreenUtil:GetStrokeSize(1)

        while true do
            local Delta = task.wait()

            Pos += Delta * math.pi * 1.25
            BigOne += Delta * math.pi
            SmallOne += Delta * math.pi * 0.4
            Holder.ActualCard.Stroke.Thickness = Default + Extra * math.sin(BigOne)
            Holder.ActualCard.Position = UDim2.fromScale(0.5, 0.4 + math.sin(Pos) * 0.05)
            Holder.Button.Stroke.Thickness = ScreenUtil:GetStrokeSize(4) + ScreenUtil:GetStrokeSize(2) * math.sin(BigOne)
        end

    end)
end

function CreateCard(Name: string, Order: number)
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
    Holder.ActualCard.Position = UDim2.fromScale(0.5, 5)
    Holder.Button.Btn.MouseEnter:Connect(function()
        Hover(Holder)
    end)
    Holder.Button.Btn.MouseLeave:Connect(function()
        Hover(Holder)
    end)
    Holder.Parent = Component:GetFrame().List

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
            CardObject.Frontdesign.Icon.Image = 'rbxassetid://' .. GearData.Icon
            CardObject.Frontdesign.IconBg.Image = 'rbxassetid://' .. GearData.Icon

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
end

function Component:Link(Player: Player)
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("FullScreenHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Gear", true)

    return Main
end

function Component:Init()

    Component:BindToStateChange(function(State)
        if State then
            Component:ShowOptions({"Dumbbells", "BoxingGloves", "Daggers"})
        end
    end)

end

function Component:ShowOptions(List: {string})
    local MainFrame = self:GetFrame()

    MainFrame.Bg.Visible = true
    MainFrame.Bg.BackgroundTransparency = 1
    Effects:Tween(MainFrame.Bg, {.25}, {BackgroundTransparency = 0.3})

    ClearCards()

    for k, Name in List do
        CreateCard(Name, k)
    end
end

return Component
