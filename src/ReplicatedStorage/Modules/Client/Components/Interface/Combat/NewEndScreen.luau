local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService('Players')
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local UIUtils = require(Client.Libraries.UIUtils)
local Icons = require(Shared.Database.Icons)
local Statics = require(Shared.Database.Statics)
local Types = require(Shared.Types)
local String = require(Shared.Utility.String)
local ComponentClass = require(Client.Classes.Interface)
local NavStates = require(Client.States.Navigation)
local EffectUtil = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)

local Component = ComponentClass.new("EndScreen", "END")
:: Types.UIComponent & Types.UIGetSetButton

-- testing? idk bro

local Disabled = {}
local HoverThreads = {}
local ColorInfo = {
    ["B"] = {Color3.fromRGB(30, 188, 255), Color3.fromRGB(21, 115, 255)},
    ["A"] = {Color3.fromRGB(156, 117, 255), Color3.fromRGB(35, 46, 255)},
    ["S"] = {Color3.fromRGB(255, 209, 43), Color3.fromRGB(255, 74, 74)},
}


--- Public
local function AnimatePress(Name: string)
    local Button = Component:GetButton(Name)
    Button.UIScale.Scale = 0.75

    local Color = Button:GetAttribute('OriginalBackgroundColor')
    if Color == nil then
        Button:SetAttribute('OriginalBackgroundColor', Button.BackgroundColor3)
        Color = Button.BackgroundColor3;
    end

    Button.BackgroundColor3 = Button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.5)
    EffectUtil:Tween(Button, {.6, 'Quad'}, {BackgroundColor3 = Color})
    EffectUtil:Tween(Button.UIScale, {.3, 'Back', 'Out'}, {Scale = 1})

    Disabled[Name] = true
    task.delay(.6, function()
        Disabled[Name] = false
    end)
end

local function RequestLeaveMatch()
    Network:Fire("Match", GameEnum.MatchEvents.RequestMatchLeave)

    AnimatePress("Return")
end

local function RequestAgainMatch()
    Network:Fire("Match", GameEnum.MatchEvents.RequestMatchRepeat)

    AnimatePress("Again")
end


--- Private
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("FullScreenHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("NewEndScreen", true)

    return Main
end

function Component:GetButton(Name: string): Frame
    local Frame = self:GetFrame()

    return Frame.Main:FindFirstChild(Name.."Button")
end

function Component:SetHover(Name: string, State: boolean)
    local Button = Component:GetButton(Name)

    if HoverThreads[Name] then
        HoverThreads[Name]:Disconnect()
        Button.Glow.UIGradient.Offset = Vector2.new(-1, 0)
    end

    if Disabled[Name] then return end

    if not State then
        EffectUtil:Tween(Button.UIScale, {.2, 'Quad'}, {Scale = 1})

        return
    end


    EffectUtil:Tween(Button.UIScale, {.2, 'Quad'}, {Scale = 0.95})

    local Alpha = -1
    HoverThreads[Name] = RunService.Heartbeat:Connect(function(delta: number)
        Alpha += delta * 2

        if Alpha >= 1 then
            Alpha = -1
        end

        Button.Glow.UIGradient.Offset = Vector2.new(Alpha, 0)
    end)
end

function Component:Init()
    ---
    local Leave = Component:GetButton("Return")

    Leave.Button.MouseButton1Click:Connect(RequestLeaveMatch)
    Leave.Button.MouseEnter:Connect(function()
        Component:SetHover("Return", true)
    end)
    Leave.Button.MouseLeave:Connect(function()
        Component:SetHover("Return", false)
    end)


    --
    local Again = Component:GetButton("Again")
    Again.Button.MouseButton1Click:Connect(RequestAgainMatch)
    Again.Button.MouseEnter:Connect(function()
        Component:SetHover("Again", true)
    end)
    Again.Button.MouseLeave:Connect(function()
        Component:SetHover("Again", false)
    end)


    self:Set(false)
end


type MatchResultData = {
    Status: number, 
    Rank: string, 
    Items: {[string]: number}, 
    Stats: {[string]: number}, 
    Experience: number,
    PlayerExperience: number,
    PlayerLevel: number,
    Stage: {
        Act: string,
        Stage: string,
        Type: string,
        Difficulty: string,
    }
}

function Component:ShowMatchResult(ServerData: MatchResultData)
    NavStates:Set("IsOnEndScreen", true)

    local Frame = self:GetFrame()
    local BackgroundEffects = Frame.BackgroundEffects
    local Borders = BackgroundEffects.Borders;
    local Main = Frame.Main
    local WinTab = Frame.WinText;
    local LossTab = Frame.LossText;
    local CurrentExperience = ServerData.PlayerExperience;
    local LevelPlayer = ServerData.PlayerLevel;

    Main.UIScale.Scale = 0;
    Frame.Visible = true;

    --- Win Status
    local ExperienceProgress = math.clamp(CurrentExperience / Statics.Get_Agent_Experience_For_Level(LevelPlayer + 1), 0, 1)
    local ChosenTab = LossTab;

    Main.StatusPlate.LossText.Visible = true
    Main.StatusPlate.VictoryText.Visible = false

    if ServerData.Status == GameEnum.MatchResults.Victory then
        Main.StatusPlate.LossText.Visible = false
        Main.StatusPlate.VictoryText.Visible = true

        ChosenTab = WinTab
    end


    EffectUtil:Tween(Borders, { 0.5, 'Cubic' }, { ImageTransparency = 0 })

    --- Screen Effect
    local ColorCorrection = Instance.new("ColorCorrectionEffect")
    ColorCorrection.Parent = Lighting
    EffectUtil:Tween(ColorCorrection, { 1 }, {
        Contrast = 0.125,
        Saturation = -1,
        Brightness = -0.05,
        TintColor = Color3.fromRGB(233, 238, 255),
    })

    ---
    ChosenTab.Position = UDim2.fromScale(-0.3, 0.5)

    EffectUtil:Tween(ChosenTab, { 0.5, 'Cubic', 'Out' }, { Position = UDim2.fromScale(0.49, 0.5) })
    task.delay(0.4, function() 
        EffectUtil:Tween(ChosenTab, { 0.7, 'Linear' }, { Position = UDim2.fromScale(0.51, 0.5) })

        task.wait(0.7)
        EffectUtil:Tween(ChosenTab, { 1.1, 'Cubic', 'InOut' }, { Position = UDim2.fromScale(1.5, 0.5) })
    end)

    --
    task.wait(1.85)

    EffectUtil:Tween(Main.UIScale, { 0.3, 'Back' }, { Scale = 1 })

    local RankingColor = Icons.RankingColorInfo[ServerData.Rank] or Icons.RankingColorInfo.X

    Main.StageInformation.MapName.Text = String:SplitTitleCaps(ServerData.Stage.Stage);
    Main.StageInformation.RankText.Text = ServerData.Rank;
    Main.StageInformation.Difficulty.Text = ServerData.Stage.Difficulty;

    Main.StageInformation.RankText.TextColor3 = RankingColor[1]
    Main.StageInformation.RankText.UIStroke.Color = RankingColor[2]

    Main.StatusPlate.UIScale.Scale = 0;
    Main.StageInformation.UIScale.Scale = 0;
    Main.Rewards.UIScale.Scale = 0;

    local Objects = {Main.StatusPlate.UIScale, Main.StageInformation.UIScale, Main.Rewards.UIScale}

    task.delay(0.15, function()

        for _, ObjectScale in Objects do
            EffectUtil:Tween(ObjectScale, { 0.3, 'Cubic' }, { Scale = 1 })

            task.wait(1 / 6)
        end
    end)

    Main.StageInformation.PlayerLevelTitle.Text = `Lv. 0`
    Main.StageInformation.ExpBar.Fill.Size = UDim2.fromScale(0, 1)
    task.delay(0.5, function()
        
        EffectUtil:Tween(Main.StageInformation.ExpBar.Fill, { 0.75, 'Cubic' }, {Size = UDim2.fromScale(ExperienceProgress, 1)})

        local Clock = os.clock()
        while os.clock() - Clock <= 0.6 do
            local Alpha = (os.clock() - Clock) / 0.6;
            local Value = TweenService:GetValue(Alpha, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            
            Main.StageInformation.PlayerLevelTitle.Text = `Lv. {math.ceil(math.lerp(0, ServerData.PlayerLevel or 1, Value))}`
            Main.StageInformation.PlayerExpTitle.Text = `+{math.ceil(math.lerp(0, ServerData.Experience or 0, Value))} EXP`
            task.wait()
        end
        
    end)

    ---
    task.wait(0.3);


    for k, Item in ServerData.Items do
        local Type, Amount, Extra = Item.Type, Item.Amount, Item.Extra
        if Type == 'Money' then
            Type = 'Gold'
        end

        local ItemObject = UIUtils:CreateRewardItem(Extra ~= nil and Extra.Name or Type, Type, Amount, false, Main.Rewards.List, Assets.Interface.EndScreen.RewardItem)
        ItemObject.UIScale.Scale = 0;

        EffectUtil:Tween(ItemObject.UIScale, { 0.25, 'Back' }, {Scale = 1});
    end
end

return Component