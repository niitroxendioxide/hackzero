--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local AgentDatabase = require(Database.Characters)
local ScreenUtil = require(Shared.Utility.ScreenUtil)
local EffectUtil = require(Shared.Utility.Effects)
local LocalData = require(Client.Libraries.LocalData)
local Network = require(Shared.Network)

type AscPage = Frame & {
    Data: Folder & {Description: TextLabel},
    NameInfo: Frame & {TextLabel: TextLabel},
}
type AscensionsFrame = Frame & {
    AgentData: Folder & {
        LvlBg: Frame & {UIScale: UIScale, AscensionLevel: TextLabel},
        NameBg: Frame & {UIScale: UIScale, AgentName: TextLabel},
    },

    ItemList: ScrollingFrame & {
        ItemRequired: Frame & {
            Icon: ImageLabel,
            Amount: TextLabel,
        }
    },

    AscPages: Frame & {
        UIPageLayout: UIPageLayout,
        [string]: AscPage,
    },

    Upgrade: Frame & {
        Button: TextButton,
    }
}

--
local States = {
    Agent = '',
    Connection = nil,
    ViewportSize = nil,
    PromoteConnection = nil,
    AscensionTimes = 0,
    PageCount = 1,
}

local SubComponent = {}

function SubComponent:UpdateAscensionInfo(MainFrame: AscensionsFrame, AgentName: string)
    local Agent = LocalData:GetAgent(AgentName)

    --
    if States.Connection then
        States.Connection:Disconnect()
    end

    if States.ViewportSize then
        States.ViewportSize:Disconnect()
    end

    if States.PromoteConnection then
        States.PromoteConnection:Disconnect()
    end

    States.Agent = AgentName
    MainFrame.AgentData.NameBg.AgentName.Text = Agent.Name
    MainFrame.AgentData.LvlBg.AscensionLevel.Text = Agent.Ascensions

    --
    local AgentData = AgentDatabase:GetCharacterData(AgentName)
    local AscensionData = AgentData and AgentData.Ascension_Data or {}
    for _, Ascension: Instance in MainFrame.AscPages:GetChildren() do
        if not Ascension:IsA("Frame") then continue end

        local Page = Ascension :: AscPage
        local PageNum = tonumber(Page.Name, 10)

        if not AscensionData[PageNum] then
            Page.Visible = false
            continue
        end

        Page.Visible = true
        Page.Data.Description.Text = AscensionData[PageNum].Description
        Page.Data.Description.TextSize = ScreenUtil:GetTextSize(15)
    end

    local GuiSize = (MainFrame):FindFirstAncestorOfClass("ScreenGui")
    local FirstPage = MainFrame.AscPages['1']

    MainFrame.AscPages.UIPageLayout:JumpTo(FirstPage)

    local function RefreshItemCount(NewFrame)
        local FrameIndex = tonumber(NewFrame.Name, 10)
        local UpdatedData = LocalData:GetAgent(AgentName)
        local AmountForIt = math.abs(UpdatedData.Ascensions - FrameIndex)
        local ItemData = LocalData:GetItemById('AgentToken:'..AgentName)
        local ItemCount = ItemData and ItemData.Amount or 0

        MainFrame.ItemList.Visible = UpdatedData.Ascensions < FrameIndex

        States.PageCount = FrameIndex

        States.AscensionTimes = AmountForIt
        MainFrame.ItemList.ItemRequired.Amount.Text = `{ItemCount} / <b>{math.abs(AmountForIt)}</b>`
    end

    RefreshItemCount(FirstPage)

    local PageLayout = MainFrame.AscPages.UIPageLayout
    States.Connection = PageLayout.PageEnter:Connect(RefreshItemCount)
    if GuiSize then
        States.ViewportSize = GuiSize:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local Current = PageLayout.CurrentPage

            Current.Data.Description.TextSize = ScreenUtil:GetTextSize(15)
        end)
    end


    MainFrame.AgentData.NameBg.UIScale.Scale = 0.5
    EffectUtil:Tween(MainFrame.AgentData.NameBg.UIScale, {.65, 'Elastic'}, {Scale = 1})

    MainFrame.AgentData.LvlBg.UIScale.Scale = 0.5
    EffectUtil:Tween(MainFrame.AgentData.LvlBg.UIScale, {.8, 'Elastic'}, {Scale = 1})

    FirstPage.UIScale.Scale = 0.6
    EffectUtil:Tween(FirstPage.UIScale, {.5, 'Back'}, {Scale = 1})

    --
    States.PromoteConnection = MainFrame.Upgrade.Button.MouseButton1Click:Connect(function()
        local UpdatedData = LocalData:GetAgent(AgentName)
        if UpdatedData.Ascensions > States.PageCount then
            return
        end

        Network:Fire("UpdateAgent", GameEnum.BuildEvent.AscendAgent, {Agent.Name, States.AscensionTimes})
    end)
end

function SubComponent:RefreshAscensionInfo(MainFrame: AscensionsFrame, AgentName: string)
    local Agent = LocalData:GetAgent(AgentName)

    MainFrame.AgentData.NameBg.AgentName.Text = AgentName
    MainFrame.AgentData.LvlBg.AscensionLevel.Text = Agent.Ascensions

    MainFrame.AgentData.NameBg.UIScale.Scale = 0.5
    EffectUtil:Tween(MainFrame.AgentData.NameBg.UIScale, {.65, 'Elastic'}, {Scale = 1})

    MainFrame.AgentData.LvlBg.UIScale.Scale = 0.5
    EffectUtil:Tween(MainFrame.AgentData.LvlBg.UIScale, {.8, 'Elastic'}, {Scale = 1})

    --
    local ItemData = LocalData:GetItemById('AgentToken:'..AgentName)
    local ItemCount = ItemData and ItemData.Amount or 0
    local AmountForUpgrade = Agent.Ascensions - States.PageCount

    MainFrame.ItemList.Visible = Agent.Ascensions < States.PageCount

    MainFrame.ItemList.ItemRequired.Amount.Text = `{ItemCount} / <b>{AmountForUpgrade}</b>`
end

return SubComponent
