local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets
local Companions = Assets.Interface:FindFirstChild('Companions')

local LocalData = require(ReplicatedStorage.Modules.Client.Libraries.LocalData)
local UIEffects = require(ReplicatedStorage.Modules.Client.Utility.UIEffects)
local CompanionsDatabase = require(ReplicatedStorage.Modules.Shared.Database.Companions)
local Icons = require(ReplicatedStorage.Modules.Shared.Database.Icons)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local Types = require(Shared.Types)
local Camera = require(Client.Libraries.Camera)
local Fetcher = require(Client.Libraries.Fetcher)
local UIGroups = require(Client.Libraries.UIGroups)
local RandomNameGen = require(Client.Utility.RandomNameGen)
local ComponentClass = require(Client.Classes.Interface)

local Component = ComponentClass.new("Companions", "Lobby")
local States = {
    IdSelected = '',
    Model = nil,
    LastSelectedFrame = nil,
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
        local NewObject = Companions.CompanionObject:Clone()
        NewObject.Name = CompData.Id
        NewObject.Id.Text = Name
        NewObject.Level.Text = 'Level: '..CompData.Level
        NewObject.LayoutOrder = -CompData.Level
        NewObject.Parent = MainFrame.List

        if CompData.Level > Selected.Level then
            Selected = CompData
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
        Effects:Tween(States.LastSelectedFrame.UIScale, {.3, 'Sine'}, {Scale = 1})
        States.LastSelectedFrame.UIStroke.Color = Color3.new()
        States.LastSelectedFrame.Background.ImageColor3 = Color3.new()
    end

    if States.Model then
        States.Model:Destroy()
    end

    States.IdSelected = Id

    local FrameObject = Frame.List:FindFirstChild(Id)
    Effects:Tween(FrameObject.UIScale, {.25, 'Back'}, {Scale = 1.15})
    FrameObject.UIStroke.Color = Color3.new(1, 1, 1)
    FrameObject.Background.ImageColor3 = Color3.new(1, 1, 1)
    States.LastSelectedFrame = FrameObject

    Camera:TweenTo(Room.Used.CameraCF.CFrame)

    --
    local Name = CompanionData.Name
    local Model = Assets.Characters.Companions:FindFirstChild(Name)
    local CompanionInformation = CompanionsDatabase:GetCompanionData(Name)

    local Cloned = Model:Clone()
    Cloned.PrimaryPart.Anchored = true
    Cloned:PivotTo(Room.Used.CharPlace.CFrame)
    Cloned.Parent = workspace.World.Effects

    --
    Frame.Stats.Id.Text = RandomNameGen(CompanionData.Id)
    Frame.Stats.Level.Text = 'Level: '..CompanionData.Level
    Frame.Stats.Attack.Text = CompanionInformation.Attack.Description
    Frame.Stats.Passive.Text = CompanionInformation.Passive.Description

    Frame.Stats.Attack.TextSize = ScreenUtil:GetTextSize(16)
    Frame.Stats.Passive.TextSize = ScreenUtil:GetTextSize(16)

    --
    ShowCompanionData(CompanionData)
end

function ShowCompanionData(CompanionData)
    local Frame = Component:GetFrame()

    for _, obj in Frame.Stats.List:GetChildren() do
        if not obj:IsA("Frame") then
            continue
        end

        obj:Destroy()
    end

    Frame.Stats.Level.Text = `Level: {CompanionData.Level}`

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
        Object.LayoutOrder = Rarity or 25

        local TierData = Icons.Rarities[TierName]
        if TierName then
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

