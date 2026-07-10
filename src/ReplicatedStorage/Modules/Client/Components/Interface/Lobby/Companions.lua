local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets
local Companions = Assets.Interface:FindFirstChild('Companions')

local LocalData = require(Client.Libraries.LocalData)
local UIEffects = require(Client.Utility.UIEffects)
local CompanionsDatabase = require(Shared.Database.Companions)
local Icons = require(Shared.Database.Icons)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)
local ScreenUtil = require(Shared.Utility.ScreenUtil)
local Types = require(Shared.Types)
local Camera = require(Client.Libraries.Camera)
local Fetcher = require(Client.Libraries.Fetcher)
local UIGroups = require(Client.Libraries.UIGroups)
local RandomNameGen = require(Client.Utility.RandomNameGen)
local ComponentClass = require(Client.Classes.Interface)
local AnimationLib = require(Client.Libraries.Animation)

local Component = ComponentClass.new("Companions", "Lobby")
local States = {
    IdSelected = '',
    Model = nil,
    LastSelectedFrame = nil,
    Threads = {},
}

local function SplitTitleCaps(str)
	str = str:gsub("(%u)", " %1")
	return str:gsub("^%s", "")
end


local function ShowAllCompanions()
    local Data = Fetcher:FetchCompanions()
    local MainFrame = Component:GetFrame()

    for _, Object in MainFrame.List:GetChildren() do
        if Object:IsA("Frame") then
            Object:Destroy()
        end
    end

    States.LastSelectedFrame = nil
    States.IdSelected = ''

    local Selected = Data[1]
    for _, CompData in Data do
        
        local Name = RandomNameGen(CompData.Id)
        local Model = Assets.Characters.Companions:FindFirstChild(CompData.Name) or Assets.Characters.Companions:FindFirstChild('Default')
        local NewObject = Companions.CompanionObject:Clone()
        NewObject.Name = CompData.Id
        NewObject.Id.Text = Name
        NewObject.Level.Text = 'Level: '..CompData.Level
        NewObject.LayoutOrder = -CompData.Level
        NewObject.Parent = MainFrame.List

        if CompData.Level > Selected.Level then
            Selected = CompData
        end
        
        if Model then
            local Cloned = Model:Clone()
            Cloned.PrimaryPart.Anchored = true
            Cloned:PivotTo(CFrame.new() * CFrame.Angles(0, math.pi, 0))
            Cloned.Parent = NewObject.Viewport.World;

            local Cam = Instance.new("Camera")
            Cam.CFrame = CFrame.new(0, -0.25, 175)
            Cam.FieldOfView = 1
            Cam.Parent = NewObject.Viewport;
        end

        NewObject.Btn.MouseButton1Click:Connect(function()
            SelectCompanion(CompData.Id)
        end)
    end

    if Selected == nil then
        Component:Set(false)

        return;
    end

    SelectCompanion(Selected.Id)
end

function SelectCompanion(Id: string)
    local Room = workspace.World.LobbyCutscenes.CompanionRoom
    local CompanionData = LocalData:GetCompanion(Id)
    local Frame = Component:GetFrame()

    if Id == nil or Id == States.IdSelected then
        return
    end

    if States.LastSelectedFrame then
        Effects:Tween(States.LastSelectedFrame.UIScale, {.25, 'Sine'}, {Scale = 1})
        States.LastSelectedFrame.Outer.Color = Color3.new()
        States.LastSelectedFrame.Background.ImageColor3 = Color3.new()
    end

    if States.Model then
        States.Model:Destroy()
    end

    States.IdSelected = Id

    local FrameObject = Frame.List:FindFirstChild(Id)
    Effects:Tween(FrameObject.UIScale, {.15, 'Back'}, {Scale = 1.1})
    FrameObject.Outer.Color = Color3.new(1, 1, 1)
    States.LastSelectedFrame = FrameObject

    Camera:TweenTo(Room.Used.CameraCF.CFrame)

    for _, k in States.Threads do
        task.cancel(k)
    end

    States.Threads = {}

    --
    local Name = CompanionData.Name
    local Model = Assets.Characters.Companions:FindFirstChild(Name)
    local CompanionInformation = CompanionsDatabase:GetCompanionData(Name)

    local StatsTab = Frame.Stats
    local Cloned = Model:Clone()
    Cloned.PrimaryPart.Anchored = true
    Cloned:PivotTo(Room.Used.CharPlace.CFrame)
    Cloned.Parent = workspace.World.Effects
    States.Model = Cloned

    EffectsLib:Play("CharSwitch", Cloned, nil, true)

    AnimationLib:Play(Cloned, Assets.Animations.Companions.Default.Idle, 0)

    --
    StatsTab.Id.Text = RandomNameGen(CompanionData.Id)
    StatsTab.Level.Text = 'Level: '..CompanionData.Level
    
    local PrimaryPlate = StatsTab.PrimaryPlate
    PrimaryPlate.Description.TextSize = ScreenUtil:GetTextSize(16)

    if CompanionInformation.PrimaryAttack ~= nil then
        table.insert(States.Threads, task.delay(0.05, function()
            PrimaryPlate.Description.Text = CompanionInformation.PrimaryAttack.Description
            PrimaryPlate.UIScale.Scale = 0.9
            PrimaryPlate.Outer.Color = Color3.new(1,1,1)
            Effects:Tween(PrimaryPlate.Outer, { 0.25, 'Sine' }, {Color = Color3.new()})
            Effects:Tween(PrimaryPlate.UIScale, { 0.25, 'Sine' }, {Scale = 1})
        end))
    else
        PrimaryPlate.Description.Text = "Companion does not posses an active primary skill."
    end

    local SecondaryPlate = StatsTab.SecondaryPlate
    SecondaryPlate.Description.TextSize = ScreenUtil:GetTextSize(16)

    if CompanionInformation.SecondaryAttack ~= nil then
        table.insert(States.Threads, task.delay(0.1, function()
            SecondaryPlate.Description.Text = CompanionInformation.SecondaryAttack.Description
            SecondaryPlate.UIScale.Scale = 0.9
            SecondaryPlate.Outer.Color = Color3.new(1,1,1)

            Effects:Tween(SecondaryPlate.Outer, { 0.25, 'Sine' }, {Color = Color3.new()})
            Effects:Tween(SecondaryPlate.UIScale, { 0.25, 'Sine' }, {Scale = 1})
        end))
    else
        SecondaryPlate.Description.Text = "Companion does not posses an active secondary skill."
    end

    local PassivePlate = StatsTab.PassivePlate
    PassivePlate.Description.TextSize = ScreenUtil:GetTextSize(16)

    if CompanionInformation.Passive ~= nil then
        PassivePlate.Description.Text = CompanionInformation.Passive.Description
        PassivePlate.UIScale.Scale = 0.9
        PassivePlate.Outer.Color = Color3.new(1,1,1)

        Effects:Tween(PassivePlate.Outer, { 0.25, 'Sine' }, {Color = Color3.new()})
        Effects:Tween(PassivePlate.UIScale, { 0.25, 'Sine' }, {Scale = 1})
    else
        PassivePlate.Description.Text = "Companion does not posses a passive skill."
    end


    --
    ShowCompanionData(CompanionData)
end

function ShowCompanionData(CompanionData)
    local Frame = Component:GetFrame()
    local StatsTab = Frame.Stats

    for _, obj in Frame.Stats.List:GetChildren() do
        if not obj:IsA("Frame") then
            continue
        end

        obj:Destroy()
    end

    StatsTab.Level.Text = `Level: {CompanionData.Level}`

    local Order = {'Attack', 'AttackSpeed', 'AttackRate', 'Defense', 'Speed'}
    local Rarities = CompanionData.Rarities
    for StatName, StatValue in CompanionData.Stats do
        local Rarity = Rarities.Base[StatName]
        if Rarities.Level[StatName] and Rarities.Level[StatName] > Rarity then
            Rarity = Rarities.Level[StatName]
        end

        local TierName = GameEnum.KeyLookup(GameEnum.Tiers, Rarity)
        local Value = string.format("%.2f", StatValue :: unknown)
        local Object = Assets.Interface.Companions.StatObject:Clone()
        Object.Stat.Text = `{SplitTitleCaps(StatName)}: {Value}`
        Object.LayoutOrder = table.find(Order, StatName) or 6
        Object.UIScale.Scale = 0

        task.delay((Object.LayoutOrder - 1) * 0.05, function()
            Effects:Tween(Object.UIScale, {.2, 'Back'}, {Scale = 1})
        end)

        local TierData = Icons.Rarities[TierName]
        if TierData then
            Object.Stat.UIGradient.Color = TierData.TextColorSequence
            Object.RarityIcon.Image = TierData.Id
            Object.RarityIcon.Visible = true

            if TierData.OutlineColor then
                Object.Stat.UIStroke.Color = TierData.OutlineColor
            end
        else
            Object.RarityIcon.Visible = false
            Object.Stat.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
        end

        Object.Parent = Frame.Stats.List
    end
end

function Component:Refresh()
    if States.IdSelected == nil then
        return
    end

    local NewData = LocalData:GetCompanion(States.IdSelected)
    local MainFrame = Component:GetFrame()

    local ListSelected = MainFrame.List:FindFirstChild(States.IdSelected)
    if ListSelected then
        ListSelected.Level.Text = `Level: {NewData.Level}`
    end

    ShowCompanionData(NewData)
end

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Companions", true)

    return Main
end

function Component:Init()
    local MainFrame = Component:GetFrame()
    self:Set(false)


    --
    Component:BindToStateChange(function(State: boolean, Raw)
        if State then
            Camera:MarkUsage("Companions")

            ShowAllCompanions()
        else
            Camera:FreeUsage()

            local LobbyMain = UIGroups:GetElementClass('Lobby', 'MainMenu')
            LobbyMain:Set(true)
        end
    end)

    MainFrame.Stats.LevelUpButton.MouseButton1Click:Connect(function()
        local FeedingElement = UIGroups:GetElementClass('Feeding', 'Feeding')

        FeedingElement:ShowCompanionFeeding(States.IdSelected)
    end)

    UIEffects:AnimateReturnButton(MainFrame.Return, function()
        Component:Set(false)
    end)
end

return Component :: Types.UIComponent

