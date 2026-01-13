local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client


local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local ItemsDatabase = require(Shared.Database.Items)
local GameEnum = require(Shared.GameEnum)
local Statics = require(Shared.Database.Statics)
local Icons = require(Shared.Database.Icons)

local Effects = require(Shared.Utility.Effects)
local Network = require(Shared.Network)

local AgentData = require(Shared.Database.Characters)
local LocalData = require(Client.Libraries.LocalData)

--
local DEFAULT_DESCRIPTIONS = {
    Basic_Attack = 'Agent\'s default attack.',
    Ultimate = 'Agent\'s ultimate attack',
    Special = 'Agent\'s special attack',
    Dodge_Counter = 'Agent\'s dodge counter',
    Quick_Assist = 'Agent\'s quick assist',
}

local NOT_ENOUGH_COLOR = Color3.fromRGB(255, 133, 133)
local ENOUGH_COLOR = Color3.new(1, 1, 1)

--
local SkillComponent = {
    __Agent = '',
    __Skill = '',
    __Connection = nil,
    __Thread = nil,
}

type MainFrame = Frame & {
    List: Frame,
    Stats: Frame & {
        UIScale: UIScale,
        Level: TextLabel,
        Desc: TextLabel,
        Upgrade: Frame & {Button: TextButton}
    }
}

local function UpdateSkillUpgradeRequirements(StatsTab, Agent, Skill)
    local AgentCompleteData = AgentData:GetCharacterData(Agent.Name)
    local AgentSkills = Agent.Skills
    local SkillData = AgentCompleteData.Moveset_Data[Skill] or {}
    local Element = AgentCompleteData.Element
    local BaseItem = Element..'Chip'

    local SkillLevel = (AgentSkills[Skill] or 0)

    if SkillLevel < Statics.Max_Skill_Level then
        local TotalItems = LocalData:GetItems()
        local ItemsToUpgrade = {}
        local BaseToUpgrade = Statics.Skill_Upgrade_Cost(SkillLevel + 1)

        local ItemNames = {BaseItem}
        table.insert(ItemsToUpgrade, {BaseItem, BaseToUpgrade})

        for Item, Amount in (SkillData.Upgrade_Requirements or {}) do
            table.insert(ItemNames, Item)
            table.insert(ItemsToUpgrade, {Item, Amount})
        end

        for _, Item in StatsTab.ItemList:GetChildren() do
            if Item:IsA('Frame') and not table.find(ItemNames, Item.Name) then
                Item:Destroy()
            end
        end

        local function GetByName(Name: string)
            for _, Item in TotalItems do
                if Item.Name == Name then
                    return Item
                end
            end

            return;
        end

        for _, Items in ItemsToUpgrade do
            local ItemToShow = Items[1]
            local AmountToShow = Items[2]

            local PlayerItem = GetByName(ItemToShow) or {Amount = 0}
            local PlayerHas = PlayerItem.Amount

            local ItemDBData = ItemsDatabase:GetItemData(ItemToShow)
            if not ItemDBData then
                continue
            end

            local Existed = StatsTab.ItemList:FindFirstChild(ItemToShow)
            local NewItem = Existed or Assets.Interface.Agents.Skills.ItemRequired:Clone()
            NewItem.Name = ItemToShow
            NewItem.Item.ItemIcon.Image = 'rbxassetid://' .. ItemDBData.Icon
            NewItem.Count.TextLabel.Text = `{PlayerHas} / <b>{AmountToShow}</b>`
            NewItem.Count.TextLabel.TextColor3 = PlayerHas >= AmountToShow and ENOUGH_COLOR or NOT_ENOUGH_COLOR
            NewItem.Parent = StatsTab.ItemList

            if Existed then
                NewItem.Count.UIScale.Scale = 0.65
                Effects:Tween(NewItem.Item.UIScale, {.07, 'Cubic', nil, nil, true}, {Scale = 1.1})
                Effects:Tween(NewItem.Count.UIScale, {.3, 'Back'}, {Scale = 1})
            end
        end
    else
        for _, Item in StatsTab.ItemList:GetChildren() do
            if Item:IsA('Frame') then
                Item:Destroy()
            end
        end
    end
end

function SkillComponent:UpdateSkills(MainFrame: MainFrame, Agent: string)
    if SkillComponent.__Agent == Agent then
        return
    end

    --
    SkillComponent.__Agent = Agent
    SkillComponent:ShowInformation(MainFrame, nil)

    local AgentInfo = LocalData:GetAgent(Agent)

    for SkillName in DEFAULT_DESCRIPTIONS do
        local Icon = Icons.Skills[SkillName];

        if SkillName == 'Ultimate' and Icons.Skills.Ultimates[Agent] then
            Icon = Icons.Skills.Ultimates[Agent].Id
        end

        local SkillObject = MainFrame.List:FindFirstChild(SkillName)
        local Existed = SkillObject ~= nil
        if not SkillObject then
            SkillObject = Assets.Interface.Agents.Skills.SkillFrame:Clone()
            SkillObject.Parent = MainFrame.List
        end

        local SkillLvl = AgentInfo.Skills[SkillName]
        SkillObject.Level.Level.Text = `{(SkillLvl or 0)} / 20`
        SkillObject.Icon.Image = Icons.PREFIX .. (Icon or 0)
        SkillObject.Name = SkillName

        Effects:Tween(SkillObject.Level.Bar.Fill, {.25, 'Cubic'}, {Size = UDim2.fromScale((SkillLvl or 0)/20, 1)})

        --
        if not Existed then
            SkillObject.Button.MouseButton1Click:Connect(function()
                SkillComponent:ShowInformation(MainFrame, SkillName)
            end)
        end
    end
end

function SkillComponent:ShowInformation(MainFrame: MainFrame, Skill: string?)
    if SkillComponent.__Agent == nil then
        return
    end

    local StatsTab = MainFrame.Stats
    local AgentObject = LocalData:GetAgent(SkillComponent.__Agent)
    local AgentCompleteData = AgentData:GetCharacterData(SkillComponent.__Agent)
    local AgentMovesetData = AgentCompleteData and AgentCompleteData.Moveset_Data
    local SkillData = AgentMovesetData[Skill] or {}

    if SkillComponent.__Thread then
        local PreviousItem = MainFrame.List:FindFirstChild(SkillComponent.__Skill or '')
        task.cancel(SkillComponent.__Thread)
        SkillComponent.__Thread = nil

        if PreviousItem then
            PreviousItem.Selected.UIStroke.Thickness = 0
        end
    end

    if (not Skill or not AgentMovesetData or not SkillData or not AgentObject) or SkillComponent.__Skill == Skill then
        SkillComponent.__Skill = nil
        Effects:Tween(StatsTab.UIScale, {.3, 'Cubic', 'In'}, {Scale = 0})

        return
    end

    StatsTab.Visible = true

    SkillComponent.__Skill = Skill

    Effects:Tween(StatsTab.UIScale, {.25, 'Back'}, {Scale = 1})

    SkillComponent.__Thread = task.spawn(function()
        local CurrentItem = MainFrame.List:FindFirstChild(Skill)
        if CurrentItem then
            local Angle = 0

            while true do
                local Delta = task.wait()
                Angle += Delta * 180

                CurrentItem.Selected.UIStroke.Thickness = 3.5 + math.sin(math.rad(Angle)) * 1.5
            end
        end
    end)

    -- Showing info
    local SkillLevel = AgentObject.Skills[Skill]
    local Description = SkillData.Description or DEFAULT_DESCRIPTIONS[Skill]

    StatsTab.Label.Text = string.gsub(Skill, '_', ' ')
    StatsTab.Desc.Text = Description
    StatsTab.Desc.TextSize = ScreenUtil:GetTextSize(15)
    StatsTab.Level.Text = `<b>Lvl.</b> {SkillLevel} / 20`

    -- Upgrading
    UpdateSkillUpgradeRequirements(StatsTab, AgentObject, Skill)

    --
    if not SkillComponent.__Connection then
        SkillComponent.__Connection = StatsTab.Upgrade.Button.MouseButton1Click:Connect(function()
            Network:Fire('UpdateAgent', GameEnum.BuildEvent.UpgradeAgentSkill, {
                SkillComponent.__Agent,
                SkillComponent.__Skill,
            })
        end)
    end
end

function SkillComponent:UpdateSkillLevels(MainFrame: MainFrame, Agent: string)
    local AgentInfo = LocalData:GetAgent(Agent)

    for SkillName in DEFAULT_DESCRIPTIONS do
        local SkillObject = MainFrame.List:FindFirstChild(SkillName)
        if not SkillObject then continue end

        local SkillLvl = (AgentInfo.Skills[SkillName] or 0)
        --print(SkillLvl, SkillName, AgentInfo.Skills)

        SkillObject.Level.Level.Text = `{SkillLvl} / 20`
        Effects:Tween(SkillObject.Level.Bar.Fill, {.25, 'Cubic'}, {Size = UDim2.fromScale(SkillLvl/20, 1)})

        if SkillComponent.__Skill == SkillName then
            MainFrame.Stats.Level.Text = `<b>Lvl.</b> {SkillLvl} / 20`

            UpdateSkillUpgradeRequirements(MainFrame.Stats, AgentInfo, SkillName)
        end
    end

end

return SkillComponent