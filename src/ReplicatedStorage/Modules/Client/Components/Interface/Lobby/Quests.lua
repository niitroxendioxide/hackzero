local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local Fetcher = require(ReplicatedStorage.Modules.Client.Libraries.Fetcher)
local Data = require(ReplicatedStorage.Modules.Shared.Types.Data)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local UIGroups = require(Client.Libraries.UIGroups)
local UIEffects = require(Client.Utility.UIEffects)
local Interface = require(Client.Classes.Interface)
local UIStates = require(Client.States.Interface)
local EffectUtil = require(Shared.Utility.Effects)

local Component = Interface.new("Quests", "Lobby")

local States = {
    Connection = nil :: RBXScriptConnection?,
}

-- Privates
local function CreateTab(TabName: string)
    local CompFrame = Component:GetFrame().Quests
    local TabList = CompFrame.TabList
    local Pages = CompFrame.Pages

    local QuestsAssets = Assets.Interface.Lobby.Quests
    local ButtonObject = QuestsAssets.QuestCategoryButton:Clone()

    ButtonObject.Design.TabName.Text = TabName
    ButtonObject.Parent = TabList

    --
    local NewPage = QuestsAssets.QuestCategory:Clone()
    NewPage.Name = TabName
    NewPage.Parent = Pages

    ButtonObject.Button.MouseButton1Click:Connect(function()
        Pages.UIPageLayout:JumpTo(NewPage)
    end)
end

local function GetValueFromPath(Origin, Path)
	local Value = Origin
    local Split = string.split(Path, '.')

    for i = 1, #Split do
        Value = Value[Split[i]]
    end

	return Value
end

local function FixDescriptionText(Text, Goals)
	return string.gsub(Text, "{(.-)}", function(key)
		local value = GetValueFromPath(Goals, key)
		return value ~= nil and tostring(value) or "nil"
	end)
end


local function CreateQuestObject(Data: Data.QuestData)
    local CompFrame = Component:GetFrame().Quests
    local QuestList = CompFrame.Pages:FindFirstChild(Data.Type)

    if not QuestList then
        return
    end

    QuestList = QuestList.List

    local QuestAssets = Assets.Interface.Lobby.Quests
    local QuestInstance = QuestList:FindFirstChild(Data.Id)
    if QuestInstance == nil then
        QuestInstance = QuestAssets.QuestObject:Clone()
        QuestInstance.Name = Data.Id
        QuestInstance.Parent = QuestList

        --
        QuestInstance.ClaimBtn.Button.MouseButton1Click:Connect(function()
            print('Claim here!')
        end)
    end

    QuestInstance.QuestId.Value = Data.Id
    QuestInstance.QuestName.Text = Data.Name
    QuestInstance.QuestDescription.Text = FixDescriptionText(Data.Description, Data.Goals) -- apply stuff here
    QuestInstance.QuestDescription.TextSize = ScreenUtil:GetTextSize(29)

    local Maximum = 0
    local TotalProgress = 0
    for Key, Value in Data.Progress do
        if typeof(Value) == 'table' then
            for InKey, InValue in Value do
                if Data.Goals[Key] == nil then continue end
                local NewKey = Key..InKey
                local GoalValueTable = Data.Goals[Key] :: {[string]: number}

                Maximum += GoalValueTable[InKey]
                TotalProgress += math.min(InValue, GoalValueTable[InKey])

                local Objective = QuestInstance.ObjectiveList:FindFirstChild(NewKey) or QuestAssets.QuestObjective:Clone()
                Objective.Text = `{Key} {string.lower(InKey)}: {InValue} / <b>{GoalValueTable[InKey]}</b>`
                Objective.Name = NewKey
                Objective.Parent = QuestInstance.ObjectiveList
            end
        else
            Maximum += Data.Goals[Key]
            TotalProgress += math.min(Value, Data.Goals[Key] :: number)

            local Objective = QuestInstance.ObjectiveList:FindFirstChild(Key) or QuestAssets.QuestObjective:Clone()
            Objective.Text = `{Key}: {Value} / <b>{Data.Goals[Key]}</b>`
            Objective.Name = Key
            Objective.Parent = QuestInstance.ObjectiveList
        end
    end

    local Percent = (TotalProgress / Maximum)

    if Percent >= 1 then
        QuestInstance.ProgressBar.Visible = false
        QuestInstance.ObjectiveList.Visible = false
        QuestInstance.ProgressLabel.Visible = false
        QuestInstance.ClaimBtn.Visible = true
    else
        QuestInstance.ClaimBtn.Visible = false
        QuestInstance.ProgressLabel.Visible = true
        QuestInstance.ObjectiveList.Visible = true
        QuestInstance.ProgressBar.Visible = true
        QuestInstance.ProgressBar.ProgressBar.Size = UDim2.fromScale(Percent, 1)
    end
end

-- Public
function Component:Link(): Instance?
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Quests", true)

    return Main
end

function Component:Init()
    local MainFrame = self:GetFrame()
    local TabIndicator = MainFrame.Quests.TabIndicator
    local PageLayout = MainFrame.Quests.Pages.UIPageLayout :: UIPageLayout

    for _, Tab in {'Daily', 'Main', 'Interactions'} do
        CreateTab(Tab)
    end

    PageLayout.PageEnter:Connect(function(PageObj)
        TabIndicator.CategoryName.Text = PageObj.Name
        --
        local Circle = Instance.new("Frame")
        Circle.SizeConstraint = Enum.SizeConstraint.RelativeXX
        Circle.AnchorPoint = Vector2.new(0.5, 0.5)
        Circle.Size = UDim2.fromScale(0, 0)
        Circle.BackgroundColor3 = Color3.new(1, 1, 1)
        Circle.BorderSizePixel = 0
        Circle.Transparency = 0.75
        Circle.Position = UDim2.fromScale(0.5, 0.5)
        Circle.Parent = TabIndicator

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Circle

        EffectUtil:Tween(TabIndicator.UIScale, {.15, 'Cubic', nil, nil, true}, {Scale = 1.1})

        EffectUtil:Tween(Circle, {.25, 'Quad'}, {Size = UDim2.fromScale(1, 1)})
        EffectUtil:Tween(Circle, {.5, 'Cubic'}, {Transparency = 1})

        EffectUtil:CleanUp(Circle, .5)
    end)

    Component:BindToStateChange(function(State: boolean)
        MainFrame.Visible = true
        if UIStates:Get("MENU_TAB_OPEN") or UIStates:Get("SETTINGS_OPEN") then
            State = false
        end

        UIStates:Set('MENU_BLOCKED', not State)
        UIStates:Set('SHOP_OPEN', State)

        if States.Connection then
            States.Connection:Disconnect()
        end

        if State then
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 0.3})
            EffectUtil:Tween(MainFrame.Quests.UIScale, {1, 'Elastic'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Quests, {.3, 'Back'}, {Position = UDim2.fromScale(0.5, 0.454)})

            --
            local ObtainedQuests = Fetcher:FetchQuests()

            Component:UpdateQuests(ObtainedQuests)
        else
            local PosTween = EffectUtil:Tween(MainFrame.Quests, {.4, 'Back', 'In'}, {Position = UDim2.fromScale(0.5, -.25)})
            EffectUtil:Tween(MainFrame.Quests.UIScale, {.3, 'Quad', 'In'}, {Scale = 0.8})
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 1})

            States.Connection = PosTween.Completed:Once(function()
                MainFrame.Visible = false
            end)

            local Menu = UIGroups:GetElementClass("Lobby", "MainMenu")

            if not Menu then return end
            Menu:Set(true, true)
        end
    end)

    Component:Set(false)

    UIEffects:AnimateReturnButton(MainFrame.Quests.Return, function()
        Component:Set(false)
    end)
end

function Component:UpdateQuests(Quests: {})
    local Ids = {}
    for _, QuestData in Quests do
        Ids[QuestData.Id] = true
        CreateQuestObject(QuestData)
    end

    for _, Object in Component:GetFrame().Quests.Pages:GetChildren() do
        if not Object:IsA("Frame") then continue end
        local List = Object.List:GetChildren()

        for _, QuestObject in List do
            if not QuestObject:IsA("Frame") then continue end

            if not Ids[QuestObject.QuestId.Value] then
                QuestObject:Destroy()
            end
        end
    end

    table.clear(Ids)
end

return Component
