local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local String = require(ReplicatedStorage.Modules.Shared.Utility.String)
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
local TypeFilters = {"Artifact", "Drive", "Item"}
local Filters = {}
local AgentTokenDesc = "A copy of the agent: %s. Can be exchanged to promote your agent up to 6 times. Each ascension brings upgrades to the characters's gameplay or stats."

--
local GetChipNameFromString = function(Name: string)
    local Cut = string.split(String:SplitTitleCaps(Name), " ")
    for idx, k in Cut do
        if k:lower() == 'chip' then
            return Cut[idx - 1]
        end
    end

    return string.gsub(Name, 'Chip', '')
end

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
    DataFrame.ItemName.Text = string.gsub(OtherData.Name or OtherData.DisplayName or ItemInfo.Name, 'AgentToken:', '')

    DataFrame.ItemInfo.Visible = ItemType == 'Item'
    DataFrame.ItemInfo.Viewport.WorldModel:ClearAllChildren()

    if ItemType == 'Drive' then
        --
        DataFrame.DriveData.Visible = true
        DataFrame.ArtifactData.Visible = false
        DataFrame.ItemInfo.Visible = true
        DataFrame.ItemInfo.ItemCount.Visible = false

        DataFrame.DriveData.Lvl.Text = `Lv. {ItemInfo.Level}`;

        local Exp = DataFrame.DriveData.Exp;
        Exp.Fill.Size = UDim2.fromScale(0, 1);
        EffectUtil:Tween(Exp.Fill, { 0.3, 'Quad' }, {Size = UDim2.fromScale(ItemInfo.Level / 60, 1)})

        DataFrame.ItemInfo.ItemDescription.Text = `<b>Passive Effect:</b> {(OtherData.Passive_Description or "")}`
        DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.931)
    elseif ItemType == 'Artifact' then
        DataFrame.ItemInfo.Visible = true
        DataFrame.ItemInfo.Icon.Visible = false
        DataFrame.DriveData.Visible = false
        DataFrame.ArtifactData.Visible = true
        DataFrame.ItemInfo.ItemCount.Visible = false

        DataFrame.ArtifactData.Level.Text = `Lv. {ItemInfo.Level}`;
        DataFrame.ArtifactData.Slot.Text = `Slot. {ItemInfo.Slot}`;
        UIUtils:CreateArtifactModel(ItemInfo.Name, ItemInfo.Slot, DataFrame.ItemInfo.Viewport, ItemId)

        local Info = OtherData :: Types.Artifact_Data
        local Description = `<b>2-Piece Effect:</b> {Info.Piece_Descriptions.Two_Piece}\n\n<b>4-Piece Effect:</b> {Info.Piece_Descriptions.Four_Piece}`
        DataFrame.ItemInfo.ItemDescription.Text = Description
        DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.931)
        --
    else
        DataFrame.DriveData.Visible = false
        DataFrame.ArtifactData.Visible = false
        DataFrame.ItemInfo.Visible = true
        DataFrame.ItemInfo.ItemCount.Visible = true

        DataFrame.ItemInfo.Icon.Image = 'rbxassetid://' .. (OtherData.Icon or 0)
        DataFrame.ItemInfo.ItemCount.Label.Text = `x{ItemInfo.Amount or 0}`
        local Size = #tostring(ItemInfo.Amount)

        if OtherData.Type == 'Upgrade' then

            local ConvertedTier = 6 - GameEnum.Tiers[OtherData.Tier]
            UIUtils:CreateUpgradeChipModel(GetChipNameFromString(ItemInfo.Name), ConvertedTier, DataFrame.ItemInfo.Viewport)
            DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.75)
        else
            DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.931)
        end

        DataFrame.ItemInfo.ItemCount.Size = UDim2.fromScale(0.182 + (0.05 * math.max(Size - 2, 0)), 0.095)
        DataFrame.ItemInfo.ItemCount.Position = UDim2.fromScale(0.059 + (0.025 * math.max(Size - 2, 0)), 0.035)
        DataFrame.ItemInfo.ItemDescription.Text = OtherData.Description
        
    end
    DataFrame.ItemInfo.ItemDescription.TextSize = ScreenUtil:GetTextSize(24)
    DataFrame.ItemInfo.ItemDescription.TextScaled = not DataFrame.ItemInfo.ItemDescription.TextFits

    DataFrame.EquippedData.Visible = ItemInfo.Equipped ~= nil
    if ItemInfo.Equipped then
        DataFrame.EquippedData.Text = string.format('Equipped On: <b>%s</b>', ItemInfo.Equipped)
    else
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
            FilterObj.State.BackgroundColor3 = Color3.fromRGB(35, 67, 10)
            FilterObj.State.UIStroke.Color = Color3.fromRGB(89, 255, 0)
        else
            EffectUtil:Tween(FilterObj.State.ActiveIcon.UIScale, {.2, 'Sine'}, {Scale = 0})
            EffectUtil:Tween(FilterObj.State.Inactive.UIScale, {.25, 'Back'}, {Scale = 1})
            FilterObj.State.BackgroundColor3 = Color3.fromRGB(67, 18, 18)
            FilterObj.State.UIStroke.Color = Color3.fromRGB(255, 34, 34)
        end
    end

    local IsTypeFilter = table.find(TypeFilters, FilterName)
    local Lower = FilterName:lower()

    for _, Object in InvFrame.ItemList:GetChildren() do
        if not Object:IsA("Frame") or not Object:FindFirstChild('Type') then
            continue
        end

        local Type = Object.Type.Value

        if AllInactive then
            Object.Visible = true
            continue
        end

        local TextMatches = (string.match(string.lower(Object.ObjName.Value), Lower) == Lower)

        if (not IsTypeFilter and State) then
            Object.Visible = Filters[Type] or TextMatches
        else
            Object.Visible = Filters[Type]
        end
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
    if ItemObject == nil then
        return;
    end

    local Design = ItemObject.Design;

    if ItemId == States.__Selected_Item then
        Design.Selected.Visible = false
        States.__Selected_Item = nil

        ShowItemInfo(nil)

        return
    elseif ItemId ~= States.__Selected_Item and (States.__Selected_Item ~= nil) then
        local OldObj = InventoryFrame.ItemList:FindFirstChild(States.__Selected_Item)

        if OldObj then
            OldObj.Design.Selected.Visible = false
        end
    end

    States.__Selected_Item = ItemId
    Design.Selected.Visible = true

    Design.UIScale.Scale = 0.85
    EffectUtil:Tween(Design.UIScale, {.35, 'Back'}, {Scale = 1})

    Design.Selected.BackgroundTransparency = 1
    Design.Selected.UIStroke.Transparency = 1
    Design.Selected.UIScale.Scale = 1.5
    EffectUtil:Tween(Design.Selected, {.3, 'Sine'}, {BackgroundTransparency = 0.85})
    EffectUtil:Tween(Design.Selected.UIStroke, {.3, 'Sine'}, {Transparency = 0})
    EffectUtil:Tween(Design.Selected.UIScale, {.55, 'Back'}, {Scale = 1})

    --
    ItemSelectedThread = task.spawn(function()
        local Angle = 0
        while true do
            local Delta = task.wait();

            Angle += 450 * Delta
            Design.Selected.UIStroke.Thickness = 0.04 + math.sin(math.rad(Angle)) * 0.015
        end
    end)

    ShowItemInfo(ItemId)
end

local OrderTypes = {
    ['Drive'] = 1,
    ['Artifact'] = 2,
    ['Item'] = 3,
}
local function CreateItem(ItemId: string, Type: 'Drive' | 'Artifact' | 'Item', ItemData: Types.PlayerDriveData & Types.PlayerArtifactData & DataTypes.PlayerItemData)
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame
    local Prefix = "rbxassetid://"

    if InventoryFrame.ItemList:FindFirstChild(ItemId) then
        local Prev = InventoryFrame.ItemList:FindFirstChild(ItemId)
        if not Prev:FindFirstChild('Equipped') then
            return
        end

        Prev.Equipped.Visible = ItemData.Equipped ~= nil

        return
    end

    local ItemInfo = ItemDatabase:GetItemData(ItemData.Name) or ArtifactDatabase:GetArtifactData(ItemData.Name)
    local InventoryObject = Assets.Interface.Lobby.Inventory.InventoryObject:Clone()
    InventoryObject.Name = ItemId
    InventoryObject.Id.Value = ItemId
    InventoryObject.Type.Value = Type
    InventoryObject.ObjName.Value = ItemData.Name

    --
    local ObjectDesign = InventoryObject.Design
    local SlotType = (ItemData.Slot or 0);
    local LevelSort = 200 - (ItemData.Level or 0)

    if Type == 'Drive' then
        local DriveData = DrivesDatabase:GetDriveData(ItemData.Name)

        ObjectDesign.DriveIcon.Image = Prefix .. DriveData.IconId
        ObjectDesign.DriveIcon.Visible = true
        ObjectDesign.ItemIcon.Visible = false
        ObjectDesign.Level.Visible = true
        ObjectDesign.Level.Label.Text = 'Lv. '..ItemData.Level
    elseif Type == 'Item' and ItemInfo then
        ObjectDesign.DriveIcon.Visible = false

        local ChipName = ItemInfo.Type == 'Upgrade' and GetChipNameFromString(ItemData.Name) or ItemData.Name
        local Tier = 6 - (GameEnum.Tiers[ItemInfo.Tier] or 5)

        local HasModel = UIUtils:CreateUpgradeChipModel(ChipName, Tier, ObjectDesign.Viewport)
        if HasModel then
            ObjectDesign.ItemIcon.Visible = false
        elseif (ItemInfo and ItemInfo.Icon)then
            ObjectDesign.ItemIcon.Visible = true
            ObjectDesign.ItemIcon.Image = Prefix .. ItemInfo.Icon
        end
    else
        ObjectDesign.DriveIcon.Visible = false

        if ItemData.Level ~= nil then
            ObjectDesign.Level.Visible = true 
            ObjectDesign.Level.Label.Text = 'Lv. '..ItemData.Level
        else
            ObjectDesign.Level.Visible = false
        end
        
        local HasModel = UIUtils:CreateArtifactModel(ItemData.Name, ItemData.Slot, ObjectDesign.Viewport, ItemId)
        if HasModel then
            ObjectDesign.ItemIcon.Visible = false
        elseif (ItemInfo and ItemInfo.Icon)then
            ObjectDesign.ItemIcon.Visible = true
            ObjectDesign.ItemIcon.Image = Prefix .. ItemInfo.Icon
        end
    end

    InventoryObject.LayoutOrder = (OrderTypes[Type] or 5) + (not ItemData.Equipped and 1000 or 0) + (Type == 'Artifact' and SlotType or 0) + LevelSort
    ObjectDesign.Equipped.Visible = ItemData.Equipped ~= nil
    InventoryObject.Button.MouseButton1Click:Connect(function()
        SelectItem(ItemId)
    end)

    ObjectDesign.Amount.Visible = ItemData.Amount ~= nil
    if ItemData.Amount then
        ObjectDesign.Amount.Text = 'x'..ItemData.Amount
    end

    InventoryObject.Parent = InventoryFrame.ItemList
end

local function CreateAllItems()
    local Count = 0;
    for _, Drive in LocalData:GetDrives() do
        CreateItem(Drive.Id, 'Drive', Drive)

        Count += 1;
        if Count > 50 then
            Count = 0
            task.wait(1/10)
        end
    end

    for _, Artifact in LocalData:GetArtifacts() do
        CreateItem(Artifact.Id, 'Artifact', Artifact)

        Count += 1;
        if Count > 50 then
            Count = 0
            task.wait(1/10)
        end
    end

    for _, Item in LocalData:GetItems() do
        CreateItem(Item.Name, 'Item', Item)

        Count += 1;
        if Count > 50 then
            Count = 0
            task.wait(1/10)
        end
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
    local UsedFilters = table.clone(TypeFilters)
    UsedFilters[#UsedFilters + 1] = "Chip"

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
            EffectUtil:Tween(MainFrame.Title.UIScale, {0.5, 'Back'}, {Scale = 0})

            States.ClosingConnection = ClosingTween.Completed:Once(function()
                MainFrame.Visible = false
            end)

            local Menu = UIGroups:GetElementClass("Lobby", "MainMenu")

            if not Menu then return end
            Menu:Set(true, true)
        elseif State then
            EffectUtil:Tween(MainFrame.InventoryFrame.UIScale, {0.25, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Return.UIScale, {0.35, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Title.UIScale, {0.5, 'Back'}, {Scale = 1})
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

    ---
    local UpgradeButtonFrame = MainFrame.InventoryFrame.Data.DriveData.Upgrade
    local UIScale = UpgradeButtonFrame.UIScale

    UpgradeButtonFrame.Button.MouseButton1Click:Connect(function()
        UIScale.Scale = 0.8
        UpgradeButtonFrame.UIStroke.Color = Color3.new(1, 1, 1)
        UpgradeButtonFrame.UIStroke.Thickness = 0.09
        EffectUtil:Tween(UIScale, { 0.25, 'Back' }, {Scale = 1})
        EffectUtil:Tween(UpgradeButtonFrame.UIStroke, { 0.45, 'Sine' }, {Color = Color3.new(0, 0, 0), Thickness = 0.05})
    end)

    UpgradeButtonFrame.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(UpgradeButtonFrame.MidStroke, { 0.3, 'Sine' }, {Color = Color3.fromRGB(128, 128, 128)})
        EffectUtil:Tween(UIScale, { 0.25, 'Quart' }, {Scale = 1.1})
    end)

    
    UpgradeButtonFrame.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(UpgradeButtonFrame.MidStroke, { 0.3, 'Sine' }, {Color = Color3.fromRGB(38, 38, 38)})
        EffectUtil:Tween(UIScale, { 0.25, 'Quart' }, {Scale = 1})
    end)
end

return Component :: Types.UIComponent