local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets

local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local Types = require(Shared.Types)
local DataTypes = require(Shared.Types.Data)
local _GameEnum = require(Shared.GameEnum)
local UIGroups = require(Client.Libraries.UIGroups)
local LocalData = require(Client.Libraries.LocalData)
local EffectUtil = require(Shared.Utility.Effects)
local ItemDatabase = require(Database.Items)
local ComponentClass = require(Client.Classes.Interface)
local DrivesDatabase = require(Database.Drives)
local ArtifactDatabase = require(Database.Artifacts)
local UIUtils = require(Client.Libraries.UIUtils)

local Component = ComponentClass.new("Inventory", "Lobby")

local States = {
    __Selected_Item = nil,
    ClosingConnection = nil,
}
local Filters = {}
local AgentTokenDesc = "A copy of the agent: %s. Can be exchanged to promote your agent up to 6 times. Each ascension brings upgrades to the characters's gameplay or stats."

--
local function ShowItemInfo(ItemId: string?)
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame
    local DataFrame = InventoryFrame.Data
    local XPos = 0.885

    DataFrame.Visible = true

    if ItemId == nil then
        EffectUtil:Tween(DataFrame.UIScale, {.25, 'Cubic', 'In'}, {Scale = 0.85})
        EffectUtil:Tween(DataFrame, {.3, 'Quad', 'In'}, {Position = UDim2.fromScale(.6, .5)})

        return
    end

    EffectUtil:Tween(DataFrame.UIScale, {.25, 'Cubic'}, {Scale = 1})
    EffectUtil:Tween(DataFrame, {.3, 'Quint'}, {Position = UDim2.fromScale(XPos, .5)})

    local ItemInfo, ItemType = LocalData:GetItemById(ItemId)
    local OtherData = ItemDatabase:GetItemData(ItemInfo.Name)
    or ArtifactDatabase:GetArtifactData(ItemInfo.Name)
    or DrivesDatabase:GetDriveData(ItemInfo.Name)

    if string.match(ItemId, 'AgentToken') then
        local Name = string.gsub(ItemId, "AgentToken:", "")
        OtherData = {
            Description = string.format(AgentTokenDesc, Name),
            Icon = 0,
        }
    end

    DataFrame.ItemType.Text = ItemType
    DataFrame.ItemName.Text = string.gsub(OtherData.DisplayName or ItemInfo.Name, 'AgentToken:', '')

    DataFrame.ItemInfo.Visible = ItemType == 'Item'
    DataFrame.ItemInfo.Viewport.WorldModel:ClearAllChildren()

    if ItemType == 'Drive' then
        --
        DataFrame.LvlBar.Visible = true
        DataFrame.ArtLvl.Visible = false

        DataFrame.LvlBar.Lvl.Text = `Lvl. {ItemInfo.Level} / 60`;
    elseif ItemType == 'Artifact' then
        DataFrame.LvlBar.Visible = false
        DataFrame.ArtLvl.Visible = true

        DataFrame.ArtLvl.Text = `Level: <b>{ItemInfo.Level}</b>`;
        UIUtils:CreateArtifactModel(ItemInfo.Name, ItemInfo.Slot, DataFrame.ItemInfo.Viewport, ItemId)
        --
    else
        DataFrame.LvlBar.Visible = false
        DataFrame.ArtLvl.Visible = false

        DataFrame.ItemInfo.Icon.Image = 'rbxassetid://' .. (OtherData.Icon or 0)
        DataFrame.ItemInfo.ItemCount.Text = `Amount Owned: <b>{ItemInfo.Amount or 0}</b>`
        DataFrame.ItemInfo.ItemDescription.Text = OtherData.Description
        DataFrame.ItemInfo.ItemDescription.TextSize = ScreenUtil:GetTextSize(24)
        DataFrame.ItemInfo.ItemDescription.TextScaled = not DataFrame.ItemInfo.ItemDescription.TextFits
    end

    DataFrame.EquippedData.Visible = ItemInfo.Equipped ~= nil
    if ItemInfo.Equipped then
        DataFrame.EquippedData.Text = string.format('Equipped On: <b>%s</b>', ItemInfo.Equipped)
        DataFrame.LvlBar.Position = UDim2.fromScale(DataFrame.LvlBar.Position.X.Scale, 0.191)
        DataFrame.ArtLvl.Position = UDim2.fromScale(DataFrame.ArtLvl.Position.X.Scale, 0.215)
    else
        DataFrame.LvlBar.Position = UDim2.fromScale(DataFrame.LvlBar.Position.X.Scale, 0.14)
        DataFrame.ArtLvl.Position = UDim2.fromScale(DataFrame.ArtLvl.Position.X.Scale, 0.152)
    end
end

local function SetFilter(FilterName: string, State: boolean)
    if Filters[FilterName] == nil then
        return
    end

    Filters[FilterName] = State

    --
    local AllInactive = true
    for _, FilterState in Filters do
        if FilterState then
            AllInactive = false
        end
    end

    --
    local MainFrame = Component:GetFrame()
    local InvFrame = MainFrame.InventoryFrame
    local FiltersList = InvFrame.Filters

    for _, FilterObj in FiltersList:GetChildren() do
        if not FilterObj:IsA("Frame") then continue end
        local Active = Filters[FilterObj.Name]

        if Active then
            EffectUtil:Tween(FilterObj.State.Inactive.UIScale, {.2, 'Sine'}, {Scale = 0})
            EffectUtil:Tween(FilterObj.State.ActiveIcon.UIScale, {.25, 'Back'}, {Scale = 1})
            FilterObj.State.BackgroundColor3 = Color3.fromRGB(36, 67, 29)
            FilterObj.State.UIStroke.Color = Color3.new(0, 1)
        else
            EffectUtil:Tween(FilterObj.State.ActiveIcon.UIScale, {.2, 'Sine'}, {Scale = 0})
            EffectUtil:Tween(FilterObj.State.Inactive.UIScale, {.25, 'Back'}, {Scale = 1})
            FilterObj.State.BackgroundColor3 = Color3.fromRGB(67, 32, 32)
            FilterObj.State.UIStroke.Color = Color3.new(1)
        end
    end

    for _, Object in InvFrame.ItemList:GetChildren() do
        if not Object:IsA("Frame") or not Object:FindFirstChild('Type') then
            continue
        end

        local Type = Object.Type.Value

        if AllInactive then
            Object.Visible = true
            continue
        end

        Object.Visible = Filters[Type]
    end
end

local function CreateFilterBtn(Name: string)
    local MainFrame = Component:GetFrame()
    local InvFrame = MainFrame.InventoryFrame
    local FiltersList = InvFrame.Filters

    Filters[Name] = false

    local Object = Assets.Interface.Lobby.Inventory.FilterObj:Clone()
    Object.Name = Name
    Object.TextLabel.Text = Name..'s'
    Object.Parent = FiltersList

    Object.Btn.MouseButton1Click:Connect(function()
        SetFilter(Name, not Filters[Name])

        Object.State.UIScale.Scale = 0.75
        EffectUtil:Tween(Object.State.UIScale, {.3, 'Back'}, {Scale = 1})
    end)
end

local ItemSelectedThread: thread = nil;
local function SelectItem(ItemId: string)
    if ItemSelectedThread then
        task.cancel(ItemSelectedThread)
    end

    if ItemId == nil then
        return
    end

    --
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame
    local ItemObject = InventoryFrame.ItemList:FindFirstChild(ItemId)

    if ItemId == States.__Selected_Item then
        ItemObject.Selected.Visible = false
        States.__Selected_Item = nil

        ShowItemInfo(nil)

        return
    elseif ItemId ~= States.__Selected_Item and (States.__Selected_Item ~= nil) then
        local OldObj = InventoryFrame.ItemList:FindFirstChild(States.__Selected_Item)

        if OldObj then
            OldObj.Selected.Visible = false
        end
    end

    States.__Selected_Item = ItemId
    ItemObject.Selected.Visible = true

    ItemObject.UIScale.Scale = 0.85
    EffectUtil:Tween(ItemObject.UIScale, {.25, 'Back'}, {Scale = 0.9})

    --
    ItemSelectedThread = task.spawn(function()
        local Angle = 0
        while true do
            local Delta = task.wait();

            Angle += 450 * Delta
            ItemObject.Selected.UIStroke.Thickness = 2.5 + math.sin(math.rad(Angle)) * 1.5
        end
    end)

    ShowItemInfo(ItemId)
end

local function CreateItem(ItemId: string, Type: 'Drive' | 'Artifact' | 'Item', ItemData: Types.PlayerDriveData & Types.PlayerArtifactData & DataTypes.PlayerItemData)
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame
    local Prefix = "rbxassetid://"

    if InventoryFrame.ItemList:FindFirstChild(ItemId) then
        local Prev = InventoryFrame.ItemList:FindFirstChild(ItemId)
        Prev.Equipped.Visible = ItemData.Equipped ~= nil

        return
    end

    local ItemInfo = ItemDatabase:GetItemData(ItemData.Name) or ArtifactDatabase:GetArtifactData(ItemData.Name)
    local InventoryObject = Assets.Interface.Lobby.Inventory.InventoryObject:Clone()
    InventoryObject.Name = ItemId
    InventoryObject.Id.Value = ItemId
    InventoryObject.Type.Value = Type

    if Type == 'Drive' then
        local DriveData = DrivesDatabase:GetDriveData(ItemData.Name)

        InventoryObject.DriveIcon.Image = Prefix .. DriveData.IconId
        InventoryObject.DriveIcon.Visible = true
        InventoryObject.ItemIcon.Visible = false
    else
        InventoryObject.DriveIcon.Visible = false
        
        local HasModel = UIUtils:CreateArtifactModel(ItemData.Name, ItemData.Slot, InventoryObject.Viewport, ItemId)
        if HasModel then
            InventoryObject.ItemIcon.Visible = false
        elseif (ItemInfo and ItemInfo.Icon)then
            InventoryObject.ItemIcon.Visible = true
            InventoryObject.ItemIcon.Image = Prefix .. ItemInfo.Icon
        end
    end

    InventoryObject.Equipped.Visible = ItemData.Equipped ~= nil
    InventoryObject.Button.MouseButton1Click:Connect(function()
        SelectItem(ItemId)
    end)

    InventoryObject.Amount.Visible = ItemData.Amount ~= nil
    if ItemData.Amount then
        InventoryObject.Amount.Text = 'x'..ItemData.Amount
    end

    InventoryObject.Parent = InventoryFrame.ItemList
end

local function CreateAllItems()
    for _, Drive in LocalData:GetDrives() do
        CreateItem(Drive.Id, 'Drive', Drive)
    end

    for _, Artifact in LocalData:GetArtifacts() do
        CreateItem(Artifact.Id, 'Artifact', Artifact)
    end

    for _, Item in LocalData:GetItems() do
        CreateItem(Item.Name, 'Item', Item)
    end
end


--

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Inventory", true)

    return Main
end

function Component:Init()
    local MainFrame = Component:GetFrame()
    local UsedFilters = {"Artifact", "Drive", "Item"}

    for _, FilterName in UsedFilters do
        CreateFilterBtn(FilterName)
    end

    ShowItemInfo(nil)

    Component:BindToStateChange(function(State: boolean)
        if States.ClosingConnection then
            States.ClosingConnection:Disconnect()
        end

        MainFrame.Visible = true

        if not State then
            local ClosingTween = EffectUtil:Tween(MainFrame.Bg, {0.5, 'Cubic'}, {Transparency = 1})
            EffectUtil:Tween(MainFrame.InventoryFrame.UIScale, {0.25, 'Back'}, {Scale = 0})
            EffectUtil:Tween(MainFrame.Return.UIScale, {0.35, 'Back'}, {Scale = 0})
            EffectUtil:Tween(MainFrame.TextLabel.UIScale, {0.5, 'Back'}, {Scale = 0})

            States.ClosingConnection = ClosingTween.Completed:Once(function()
                MainFrame.Visible = false
            end)

            local Menu = UIGroups:GetElementClass("Lobby", "MainMenu")

            if not Menu then return end
            Menu:Set(true, true)
        elseif State then
            EffectUtil:Tween(MainFrame.InventoryFrame.UIScale, {0.25, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Return.UIScale, {0.35, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.TextLabel.UIScale, {0.5, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Bg, {0.5, 'Cubic'}, {Transparency = 0.33})

            CreateAllItems()
        end
    end)


    --
    local ReturnHolder: Frame & {Btn: TextButton, UIStroke: UIStroke, UIScale: UIScale} = MainFrame.Return
    local ReturnButton: TextButton = ReturnHolder.Btn

    ReturnButton.MouseButton1Click:Connect(function()
        Component:Set(false)

        ReturnHolder.UIStroke.Color = Color3.new()
    end)

    ReturnButton.MouseEnter:Connect(function()
        if not self.__UI_State then
            return
        end

        ReturnHolder.UIStroke.Color = Color3.new(1, 1, 1)
        EffectUtil:Tween(ReturnHolder.UIScale, {.25, 'Cubic'}, {Scale = 1.1})
    end)

    ReturnButton.MouseLeave:Connect(function()
        if not self.__UI_State then
            return
        end

        ReturnHolder.UIStroke.Color = Color3.new()
        EffectUtil:Tween(ReturnHolder.UIScale, {.25, 'Cubic'}, {Scale = 1})
    end)

    Component:Set(false)
end

return Component :: Types.UIComponent