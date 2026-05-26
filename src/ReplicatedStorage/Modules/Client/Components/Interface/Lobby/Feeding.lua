local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets

local Statics = require(Shared.Database.Statics)
local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)
local TableUtil = require(Shared.Utility.Table)
local Types = require(Shared.Types)
local LocalData = require(Client.Libraries.LocalData)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)
local ItemDatabase = require(Shared.Database.Items)

local Component = ComponentClass.new("Feeding", "Feeding")
local Menus = {"Agent"}
local States = {
    AgentModel = nil,
    ClosingConnection = nil,
    SelectedAgent = nil,
    SelectedFeedItems = {} :: {[string]: number},
    ItemMenuOpen = false,
    CompanionId = '',
    Type = 'Agent',
    PreviewThreads = {} :: {thread}?,
}

local function Feed()
    if not States.SelectedAgent then
        return
    end

    local UpgradeType = States.Type == "Agent" and GameEnum.BuildEvent.LevelAgent or GameEnum.BuildEvent.LevelCompanion

    Network:Fire("UpdateAgent", UpgradeType, {States.SelectedAgent, States.SelectedFeedItems})

    for Item in States.SelectedFeedItems do
        RemoveItemToFeed(Item, true)
    end

    UpdatePreview()
end

local function ToggleItemMenu(State: boolean)
    local MainFrame = Component:GetFrame()
    local HolderList = MainFrame.Agent.ItemList.Holder
    States.ItemMenuOpen = if State ~= nil then State else (not States.ItemMenuOpen)

    local Pos = States.ItemMenuOpen and UDim2.fromScale(1.251,0.5) or UDim2.fromScale(2.25,0.5)

    --EffectUtil:Tween(MainFrame.Agent.ItemList.UIScale, {.3, 'Back'}, {Scale = 1})
    EffectUtil:Tween(MainFrame.Agent.ItemList, {.25, 'Quart', 'Out'}, {Position = Pos})

    if not States.ItemMenuOpen then return end

    for _, Item in LocalData:GetItems() do
        local ItemInformation = ItemDatabase:GetItemData(Item.Name)
        if not ItemInformation then continue end
        if ItemInformation.Type ~= "Feeding" then continue end

        local OwnedAmount = Item.Amount
        local Name = Item.Name

        local Exists = HolderList:FindFirstChild(Name)
        local Object = Exists or Assets.Interface.Lobby.Feeding.Item:Clone()

        Object.Name = Name
        Object.Amount.Text = `{OwnedAmount}`
        Object.Parent = HolderList
        Object.Design.ItemIcon.Image = 'rbxassetid://' .. ItemInformation.Icon

        if Exists then continue end

        Object.Button.MouseButton1Click:Connect(function()
            local ItemDataUpd = LocalData:GetItemById(Name)
            local UpdatedOwnedAmount = ItemDataUpd and ItemDataUpd.Amount or 0
            local Amount = States.SelectedFeedItems[Name]
            if Amount == nil then
                Amount = 0
            end

            States.SelectedFeedItems[Name] = Amount + 1
            Object.Used.Visible = true
            Object.Used.Amount.Text = `{States.SelectedFeedItems[Name]}`
            Object.Amount.Text = `{UpdatedOwnedAmount - States.SelectedFeedItems[Name]}`

            Object.Design.UIScale.Scale = 0.8
            Object.Used.UIScale.Scale = 1.1
            EffectUtil:Tween(Object.Design.UIScale, { 0.5, 'Back', 'Out' }, {Scale = 1})
            EffectUtil:Tween(Object.Used.UIScale, { 0.4, 'Back', 'Out' }, {Scale = 1})

            AddItemToFeed(Name, UpdatedOwnedAmount)
        end)

        Object.Button.MouseEnter:Connect(function()
            EffectUtil:Tween(Object.Design.Outer, { 0.25, 'Quad', 'Out' }, {Color = Color3.new(1, 1, 1)})
        end)

        Object.Button.MouseLeave:Connect(function()
            EffectUtil:Tween(Object.Design.Outer, { 0.25, 'Quad', 'Out' }, {Color = Color3.new()})
        end)
    end
end

function AddItemToFeed(Name: string, Max: number)
    local MainFrame = Component:GetFrame()
    local HolderList = MainFrame.Agent.Items.Holder
    local ItemInformation = ItemDatabase:GetItemData(Name)

    local Exists = HolderList:FindFirstChild(Name)
    local Object = Exists or Assets.Interface.Lobby.Feeding.Item:Clone()
    Object.Name = Name
    Object.Amount.Text = `{States.SelectedFeedItems[Name]}`
    Object.Parent = HolderList
    Object.Design.ItemIcon.Image = 'rbxassetid://' .. ItemInformation.Icon

    UpdatePreview()

    if not Exists then
        Object.Design.UIScale.Scale = 0.1
        Object.Design.Outer.Color = Color3.new(1, 1, 1)
        EffectUtil:Tween(Object.Design.UIScale, { 0.15, 'Quart' }, {Scale = 1})
        EffectUtil:Tween(Object.Design.Outer, { 0.3, 'Quad' }, {Color = Color3.new(), Thickness = 0.025})

        Object.Button.MouseButton1Click:Connect(function()
            Object.Design.UIScale.Scale = 0.85
            EffectUtil:Tween(Object.Design.UIScale, { 0.3, 'Back' }, {Scale = 1})
            RemoveItemToFeed(Name)
        end)

        Object.Button.MouseEnter:Connect(function()
            EffectUtil:Tween(Object.Design.Outer, { 0.25, 'Quad' }, {Color = Color3.new(1, 1, 1), Thickness = 0.035})
        end)

        Object.Button.MouseLeave:Connect(function()
            EffectUtil:Tween(Object.Design.Outer, { 0.25, 'Quad' }, {Color = Color3.new(), Thickness = 0.025})
        end)
    end
end

function RemoveItemToFeed(Name: string, RemoveAll: boolean?)
    local CurrentItem = LocalData:GetItemById(Name)
    local MainFrame = Component:GetFrame()
    local HolderList = MainFrame.Agent.Items.Holder

    States.SelectedFeedItems[Name] = (States.SelectedFeedItems[Name] or 1) - 1

    if RemoveAll then
        States.SelectedFeedItems[Name] = 0
    end

    local Exists = HolderList:FindFirstChild(Name)
    if not Exists then
        return
    end

    if States.SelectedFeedItems[Name] <= 0 then
        States.SelectedFeedItems[Name] = nil

        Exists:Destroy()
    else
        Exists.Amount.Text = `{States.SelectedFeedItems[Name]}`
    end

    UpdatePreview()

    if States.ItemMenuOpen then
        local MainHolder = MainFrame.Agent.ItemList.Holder
        local ItemMain = MainHolder:FindFirstChild(Name)

        if ItemMain and not RemoveAll then
            local SelectedAmount = States.SelectedFeedItems[Name] or 0
            ItemMain.Amount.Text = `{CurrentItem.Amount - SelectedAmount}`
            ItemMain.Used.Amount.Text = `{SelectedAmount}`

            if SelectedAmount <= 0 then
                ItemMain.Used.Visible = false
            end
        end
    end
end

local LastLevelPreview = 0;
function UpdatePreview()
    local MainFrame = Component:GetFrame()
    local LevelBar = MainFrame.Agent.Data.LvlBar
    local IsAgent = States.Type == 'Agent'

    local CharacterData = IsAgent and LocalData:GetAgent(States.SelectedAgent) or LocalData:GetCompanion(States.SelectedAgent)
    local ExpForLevel = IsAgent and Statics.Experience_For_Level(CharacterData.Level + 1) or Statics.Companion_Experience_For_Level(CharacterData.Level + 1)
    if not CharacterData then
        return
    end

    for _, Thread in States.PreviewThreads do
        task.cancel(Thread) 
    end

    if TableUtil:GetDictLength(States.SelectedFeedItems) == 0 then
        LastLevelPreview = 0
        LevelBar.Exp.Preview.Visible = false
        LevelBar.Added.Visible = false
        LevelBar.Added.Text = `+0 Levels`
        LevelBar.Lvl.Text = `Level: {CharacterData.Level} / 60`
        LevelBar.CurrentExperience.Text = `{CharacterData.Experience} EXP`
        LevelBar.NeededExperience.Text = `{ExpForLevel} EXP`
        LevelBar.Lvl.TextColor3 = Color3.new(1, 1, 1)
        EffectUtil:Tween(LevelBar.Exp.Preview, {.2, 'Cubic'}, {Size = UDim2.fromScale(0, 1)})
        
        return
    end

    LevelBar.Exp.Preview.Visible = true

    local AddedLevels = 0
    local Total = CharacterData.Experience
    for Item, Count in States.SelectedFeedItems do
        local ValidItemData = ItemDatabase:GetItemData(Item)
        if not ValidItemData or not ValidItemData.Other or not ValidItemData.Other.FeedExp then continue end

        Total += ValidItemData.Other.FeedExp * Count
    end

    --local TotalAddedExperience = Total

    while Total > ExpForLevel do
        AddedLevels += 1
        Total -= ExpForLevel
        ExpForLevel = IsAgent and Statics.Experience_For_Level(CharacterData.Level + AddedLevels + 1) or Statics.Companion_Experience_For_Level(CharacterData.Level + AddedLevels + 1)
    end

    LevelBar.Exp.Fill.Visible = AddedLevels <= 0
    LevelBar.Lvl.Text = `Level: {CharacterData.Level} / 60`
    LevelBar.Added.Visible = AddedLevels > 0
    LevelBar.Added.Text = `+{LastLevelPreview} Levels`
    LevelBar.CurrentExperience.Text = `{math.floor(Total)} EXP`
    LevelBar.NeededExperience.Text = `{math.ceil(ExpForLevel)} EXP`
    LevelBar.Lvl.TextColor3 = AddedLevels > 0 and Color3.fromRGB(164, 193, 255) or Color3.new(1,1,1)


    local Origin, End = LastLevelPreview, AddedLevels
    local LevelsTweenTime = math.abs(AddedLevels - LastLevelPreview) * 1/16
    table.insert(States.PreviewThreads, task.spawn(function()
        local Start = os.clock() 

        while (os.clock() - Start < LevelsTweenTime) do
            local Alpha = (os.clock() - Start ) / LevelsTweenTime
            local AlfaValue = TweenService:GetValue(Alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local Number = math.floor(math.lerp(Origin, End, AlfaValue))

            LevelBar.Added.Text = `+{Number} Levels`
            LevelBar.Lvl.Text = `Level: {CharacterData.Level + Number} / 60`

            task.wait()
        end

        LevelBar.Added.Text = `+{End} Levels`
        LevelBar.Lvl.Text = `Level: {CharacterData.Level + End} / 60`
    end))

    local BarIsLowerThanCurrent = (LevelBar.Exp.Preview :: GuiObject).Size.X.Scale < Total / ExpForLevel;
    if BarIsLowerThanCurrent then
        local Values = (LastLevelPreview < AddedLevels and {1, 0} or {0, 1})
        LastLevelPreview = AddedLevels

        EffectUtil:Tween(LevelBar.Exp.Preview, {.2, 'Linear'}, {Size = UDim2.fromScale(Values[1], 1)})

        table.insert(States.PreviewThreads, task.delay(0.2, function()
            LevelBar.Exp.Preview.Size = UDim2.fromScale(Values[2], 1)
            EffectUtil:Tween(LevelBar.Exp.Preview, {.2, 'Sine'}, {Size = UDim2.fromScale(Total / ExpForLevel, 1)})
        end))
    else
        LastLevelPreview = AddedLevels

        EffectUtil:Tween(LevelBar.Exp.Preview, {.25, 'Cubic'}, {Size = UDim2.fromScale(Total / ExpForLevel, 1)})
    end
end

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Feeding", true)

    return Main
end

function Component:Init()
    local MainFrame = Component:GetFrame()

    local TransitionTime = {0.3, 'Back'}
    local CloseButtonMain = MainFrame.Agent.Close

    CloseButtonMain.Button.MouseButton1Click:Connect(function()
        if self.__UI_State == false then
            return
        end

        self:Set(false)
        CloseButtonMain.UIScale.Scale = 0.75
        EffectUtil:Tween(CloseButtonMain.UIScale, {0.3, 'Back'}, {Scale = 1})
        ToggleItemMenu(false)
    end)

    CloseButtonMain.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(CloseButtonMain.Inner, {.3, 'Cubic'}, {Thickness = 0.09})
        EffectUtil:Tween(CloseButtonMain.Outer, {.3, 'Cubic'}, {Thickness = 0.09})
        EffectUtil:Tween(CloseButtonMain.UIScale, TransitionTime, {Scale = 1.2})
    end)

    CloseButtonMain.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(CloseButtonMain.Inner, {.3, 'Cubic'}, {Thickness = 0.06})
        EffectUtil:Tween(CloseButtonMain.Outer, {.3, 'Cubic'}, {Thickness = 0.06})
        EffectUtil:Tween(CloseButtonMain.UIScale, TransitionTime, {Scale = 1})
    end)

    Component:BindToStateChange(function(State)
        MainFrame.Visible = true
        MainFrame.Agent.Visible = true
        if States.ClosingConnection then
            States.ClosingConnection:Disconnect()
        end

        if State then
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 0.225})
            EffectUtil:Tween(MainFrame.Agent, {.25, 'Quad', 'Out'}, {Position = UDim2.fromScale(0.5, 0.5)})
        else
            local Tween = EffectUtil:Tween(MainFrame.Agent, {.25, 'Quad', 'Out'}, {Position = UDim2.fromScale(0.5, -0.75)})
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 1})

            States.ClosingConnection = Tween.Completed:Once(function(a0: Enum.PlaybackState)
                MainFrame.Agent.Visible = false
            end)
        end
    end)

    self:Set(false)

    local UpgradeButton = MainFrame.Agent.Upgrade
    UpgradeButton.Btn.MouseButton1Click:Connect(function()
        Feed()

        UpgradeButton.UIScale.Scale = 0.9
        EffectUtil:Tween(UpgradeButton.UIScale, { 0.4, 'Back', 'Out' }, {Scale = 1})
    end)

    local GlowTween: Tween? = nil
    UpgradeButton.MouseEnter:Connect(function()
        if GlowTween then
            GlowTween:Cancel()
        end

        UpgradeButton.Glow.UIGradient.Offset = Vector2.new(-0.9, 0)
        GlowTween = EffectUtil:Tween(UpgradeButton.Glow.UIGradient, { 0.4, 'Quad' }, {Offset = Vector2.new(0.9, 0)})

        EffectUtil:Tween(UpgradeButton, { 0.4, 'Sine' }, {BackgroundColor3 = Color3.fromRGB(22, 65, 0)})
        EffectUtil:Tween(UpgradeButton.UIScale, { 0.35, 'Quad', 'Out' }, {Scale = 1.09})
        EffectUtil:Tween(UpgradeButton.Bg, { 0.4, 'Sine' }, {ImageTransparency = 0.5})
        EffectUtil:Tween(UpgradeButton.UIStroke, { 0.3, 'Quart', 'Out' }, {Color = Color3.fromRGB(97, 255, 24)})
        EffectUtil:Tween(UpgradeButton.TabLabel.UIStroke, { 0.35, 'Quart' }, { Color = Color3.fromRGB(0, 111, 17) })
    end)

    UpgradeButton.MouseLeave:Connect(function()
        EffectUtil:Tween(UpgradeButton, { 0.4, 'Sine' }, {BackgroundColor3 = Color3.fromRGB(14, 43, 0)})
        EffectUtil:Tween(UpgradeButton.Bg, { 0.4, 'Sine' }, {ImageTransparency = 0.85})
        EffectUtil:Tween(UpgradeButton.UIScale, { 0.35, 'Quad', 'Out' }, {Scale = 1})
        EffectUtil:Tween(UpgradeButton.UIStroke, { 0.3, 'Quart', 'Out' }, {Color = Color3.fromRGB(0, 39, 8)})
        EffectUtil:Tween(UpgradeButton.TabLabel.UIStroke, { 0.35, 'Sine' }, { Color = Color3.fromRGB(0, 40, 6) })
    end)

    --
    local AddButton = MainFrame.Agent.Items.Holder.Add
    AddButton.Button.MouseButton1Click:Connect(function()
        ToggleItemMenu()

        AddButton.Design.UIScale.Scale = 0.85
        EffectUtil:Tween(AddButton.Design.UIScale, { 0.3, 'Back' }, {Scale = 1})
    end)

    AddButton.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(AddButton.Design.UIScale, { 0.35, 'Quad', 'Out' }, {Scale = 1.09})
        EffectUtil:Tween(AddButton.Design.Outer, { 0.3, 'Quart', 'Out' }, {Transparency = 0, Thickness = 0.035})
    end)

    AddButton.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(AddButton.Design.UIScale, { 0.25, 'Quad', 'In' }, {Scale = 1})
        EffectUtil:Tween(AddButton.Design.Outer, { 0.3, 'Quart', 'Out' }, {Transparency = 0.4, Thickness = 0.025})
    end)

    local CloseButtonList = MainFrame.Agent.ItemList.Close
    CloseButtonList.Button.MouseButton1Click:Connect(function()
        CloseButtonList.UIScale.Scale = 0.75
        States.SelectedFeedItems = {}
        EffectUtil:Tween(CloseButtonList.UIScale, {0.3, 'Back'}, {Scale = 1})
        ToggleItemMenu(false)
    end)

    CloseButtonList.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(CloseButtonList.UIStroke, TransitionTime, {Thickness = 0.08})
        EffectUtil:Tween(CloseButtonList.UIScale, {.5, 'Cubic'}, {Scale = 1.2})
    end)

    CloseButtonList.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(CloseButtonList.UIStroke, TransitionTime, {Thickness = 0.04})
        EffectUtil:Tween(CloseButtonList.UIScale, {.5, 'Cubic'}, {Scale = 1})
    end)
end

function Component:SetMenu(MenuName: string, State: boolean)
    local MainFrame = Component:GetFrame()
    local MenuFrame = MainFrame:FindFirstChild(MenuName)
    if not MenuFrame then
        return
    end

    if State then
        for _, OtherMenuName in Menus do
            if OtherMenuName ~= MenuName then
                Component:Set(OtherMenuName, false)
            end
        end
    end

    MenuFrame.Visible = State

    return MenuFrame
end

function Component:IsActive(MenuName: string)
    local MainFrame = Component:GetFrame()
    local MenuFrame = MainFrame:FindFirstChild(MenuName)

    if not MenuFrame then
        return false
    end

    return MenuFrame.Visible == true
end

function Component:ShowAgentFeeding(AgentName: string)
    local AgentMenu = Component:SetMenu("Agent", true)
    if not AgentMenu then
        return
    end

    self:Set(true)
    ToggleItemMenu(false)

    local Info = LocalData:GetAgent(AgentName)
    local DataFrame = AgentMenu.Data

    DataFrame.AgentName.Text = AgentName
    DataFrame.LvlBar.Lvl.Text = `Level: {Info.Level} / 60`

    States.Type = "Agent"

    --
    local Model = Assets.Characters.Agents:FindFirstChild(AgentName)
    if Model then
        if States.AgentModel then
            States.AgentModel:Destroy()
        end

        local NewCamera = Instance.new('Camera')
        local Cloned = Model:Clone()
        Cloned.Parent = DataFrame.Viewport.WorldModel
        Cloned:PivotTo(CFrame.new())

        NewCamera.FieldOfView = 1
        NewCamera.CFrame = Cloned:GetPivot() * CFrame.new(0, 1.75, -220) * CFrame.Angles(0, math.pi, 0)
        DataFrame.Viewport.CurrentCamera = NewCamera

        States.AgentModel = Cloned
    end

    States.SelectedAgent = AgentName

    UpdatePreview()

    Component:UpdateProgressBar()
end

function Component:ShowCompanionFeeding(CompanionId: string)
    local AgentMenu = Component:SetMenu("Agent", true)
    if not AgentMenu then
        return
    end

    self:Set(true)
    ToggleItemMenu(false)

    local Info = LocalData:GetCompanion(CompanionId)
    local DataFrame = AgentMenu.Data

    States.Type = "Companion"

    DataFrame.AgentName.Text = Info.Name
    DataFrame.LvlBar.Lvl.Text = `Level: {Info.Level} / 60`

    --
    local Model = Assets.Characters.Companions:FindFirstChild(Info.Name)
    if Model then
        if States.AgentModel then
            States.AgentModel:Destroy()
        end

        local NewCamera = Instance.new('Camera')
        local Cloned = Model:Clone()
        Cloned.Parent = DataFrame.Viewport.WorldModel
        Cloned:PivotTo(CFrame.new())

        NewCamera.FieldOfView = 1
        NewCamera.CFrame = Cloned:GetPivot() * CFrame.new(0, 0, -220) * CFrame.Angles(0, math.pi, 0)
        DataFrame.Viewport.CurrentCamera = NewCamera

        States.AgentModel = Cloned
    end

    States.SelectedAgent = CompanionId

    Component:UpdateProgressBar()
end

function Component:UpdateProgressBar()
    local MainFrame = self:GetFrame()
    local LevelBar = MainFrame.Agent.Data.LvlBar

    local AgentData = States.Type == 'Agent' and LocalData:GetAgent(States.SelectedAgent) or LocalData:GetCompanion(States.SelectedAgent)
    if not AgentData then
        return
    end

    local Maxexp = Statics.Experience_For_Level(AgentData.Level + 1)
    LevelBar.Lvl.Text = `Level: {AgentData.Level} / 60`
    LevelBar.NeededExperience.Text = `{Maxexp} EXP`
    LevelBar.CurrentExperience.Text = `{AgentData.Experience} EXP`
    LevelBar.Lvl.TextColor3 = Color3.new(1, 1, 1)
    LevelBar.Exp.Fill.Visible = true
    LevelBar.Added.Visible = false

    EffectUtil:Tween(LevelBar.Exp.Fill,
        {.3, 'Cubic'},
        {Size = UDim2.fromScale(AgentData.Experience / Maxexp, 1)}
    )
end

return Component :: Types.UIComponent

