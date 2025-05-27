local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets
local World = workspace:FindFirstChild("World")

local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local UIGroups = require(Client.Libraries.UIGroups)
local LocalData = require(Client.Libraries.LocalData)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)
local ArtifactsDatabase = require(Database.Artifacts)
local DrivesDatabase = require(Database.Drives)

local Component = ComponentClass.new("Inventory", "Lobby")

local States = {
    __Selected_Item = nil,
}
local Filters = {}

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
    DataFrame.ItemType.Text = ItemType
    DataFrame.ItemName.Text = ItemInfo.Name

    if ItemType == 'Drive' then
        --
        DataFrame.LvlBar.Visible = true
        DataFrame.ArtLvl.Visible = false

        DataFrame.LvlBar.Lvl.Text = `Lvl. {ItemInfo.Level} / 60`;
    else
        DataFrame.LvlBar.Visible = false
        DataFrame.ArtLvl.Visible = true

        DataFrame.ArtLvl.Text = `Level: <b>{ItemInfo.Level}</b>`;
        --
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
            FilterObj.State.BackgroundColor3 = Color3.fromRGB(36, 67, 29)
            FilterObj.State.UIStroke.Color = Color3.new(0, 1)
        else
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

local function CreateItem(ItemId: string, Type: 'Drive' | 'Artifact', ItemData: Types.PlayerDriveData & Types.PlayerArtifactData & {Amount: number})
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame
    local Prefix = "rbxassetid://"

    if InventoryFrame.ItemList:FindFirstChild(ItemId) then
        local Prev = InventoryFrame.ItemList:FindFirstChild(ItemId)
        Prev.Equipped.Visible = ItemData.Equipped ~= nil

        return
    end

    local InventoryObject = Assets.Interface.Lobby.Inventory.InventoryObject:Clone()
    InventoryObject.Name = ItemId
    InventoryObject.Id.Value = ItemId
    InventoryObject.Type.Value = Type

    if Type == 'Drive' then
        local DriveData = DrivesDatabase:GetDriveData(ItemData.Name)

        InventoryObject.DriveIcon.Image = Prefix .. DriveData.IconId
        InventoryObject.DriveIcon.Visible = true
        InventoryObject.ArtifactIcon.Visible = false
    elseif Type == 'Artifact' then
        InventoryObject.DriveIcon.Visible = false
        InventoryObject.ArtifactIcon.Visible = true
        --InventoryObject.ArtifactIcon.Image = Prefix .. ItemData.ArtifactIcon
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

    local UsedFilters = {"Artifact", "Drive"}

    for _, FilterName in UsedFilters do
        CreateFilterBtn(FilterName)
    end

    ShowItemInfo(nil)

    Component:BindToStateChange(function(State: boolean)
        if not State then
            local Menu = UIGroups:GetElementClass("Lobby", "MainMenu")

            Menu:Set(true, true)
        elseif State then
            CreateAllItems()
        end
    end)

    --
    local MainFrame = Component:GetFrame()
    local ReturnHolder: Frame & {Btn: TextButton, UIStroke: UIStroke, UIScale: UIScale} = MainFrame.Return
    local ReturnButton: TextButton = ReturnHolder.Btn

    ReturnButton.MouseButton1Click:Connect(function()
        Component:Set(false)
    end)

    ReturnButton.MouseEnter:Connect(function()
        ReturnHolder.UIStroke.Color = Color3.new(1, 1, 1)
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1.1})
    end)

    ReturnButton.MouseLeave:Connect(function()
        ReturnHolder.UIStroke.Color = Color3.new()
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1})
    end)
end

return Component :: Types.UIComponent