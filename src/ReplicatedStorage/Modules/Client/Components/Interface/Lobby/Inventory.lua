local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets

local ItemNameGen = require(ReplicatedStorage.Modules.Client.Utility.ItemNameGen)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
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
    InSellMode = false,
    SellingItems = {},

    IsConfirming = false,
    LastConfirmClick = os.clock()
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

local function SellItems()
    Network:Fire("SellEvent", GameEnum.SellEvent.SellArtifacts, States.SellingItems)
end

local function ToggleSellMode(ForceState: boolean?)
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame

    if States.InSellMode or (ForceState == false) then
        States.InSellMode = false;
        
        for _, ItemId in States.SellingItems do
            local ItemObj = InventoryFrame.ItemList:FindFirstChild(ItemId)
            if ItemObj then
                ItemObj.Design.Selling.Visible = false
            end
        end

        States.SellingItems = {}
    else
        States.InSellMode = true;
        
        local ItemObj = InventoryFrame.ItemList:FindFirstChild(States.__Selected_Item or '')
        if ItemObj then
            table.insert(States.SellingItems, States.__Selected_Item)
            ItemObj.Design.Selling.Visible = true
        end
    end

    InventoryFrame.CancelButton.Visible = States.InSellMode
    InventoryFrame.ConfirmSell.Visible = States.InSellMode
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
        DataFrame.ItemNickname.Visible = true
        DataFrame.ItemNickname.Text = ItemNameGen(ItemId)

        DataFrame.ItemInfo.ItemDescription.Text = `<b>Passive Effect:</b> {(OtherData.Passive_Description or "")}`
        DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.931)
    elseif ItemType == 'Artifact' then
        DataFrame.ItemInfo.Visible = true
        DataFrame.ItemInfo.Icon.Visible = false
        DataFrame.DriveData.Visible = false
        DataFrame.ArtifactData.Visible = true
        DataFrame.ItemNickname.Visible = true
        DataFrame.ItemInfo.ItemCount.Visible = false
        DataFrame.ItemNickname.Text = ItemNameGen(ItemId)

        DataFrame.ArtifactData.Level.Text = `Lv. {ItemInfo.Level}`;
        DataFrame.ArtifactData.Slot.Text = `Slot. {ItemInfo.Slot}`;
        UIUtils:CreateArtifactModel(ItemInfo.Name, ItemInfo.Slot, DataFrame.ItemInfo.Viewport, ItemId)

        local Info = OtherData :: Types.Artifact_Data
        local Description = `<b>2-Piece Effect:</b> {Info.Piece_Descriptions.Two_Piece}\n\n<b>4-Piece Effect:</b> {Info.Piece_Descriptions.Four_Piece}`
        DataFrame.ItemInfo.ItemDescription.Text = Description
        DataFrame.ItemInfo.ItemDescription.Position = UDim2.fromScale(0.486, 0.931)
        --
    else
        DataFrame.ItemNickname.Visible = false
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

    if FilterName == 'Artifact' or FilterName == 'Drive' then
        CreateDrivesAndArtifacts()
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

        if AllInactive then
            Object.Visible = true
            continue
        end

        local Type = Object.Type.Value
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

local SellableItems = { Artifact = true, }
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

    if SellableItems[ItemObject.Type.Value] then
        local IsInSellList = table.find(States.SellingItems, ItemId)
        if IsInSellList then
            Design.Selling.Visible = false;
            table.remove(States.SellingItems, IsInSellList)
        elseif States.InSellMode then
            Design.Selling.Visible = true;
            table.insert(States.SellingItems, ItemId)
        end
    end

    if ItemId == States.__Selected_Item then
        Design.Selected.Visible = false
        States.__Selected_Item = nil
        Design.Selling.Visible = false;

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
            if not Design or not Design:FindFirstChild('Selected') then
                break
            end

            Design.Selected.UIStroke.Thickness = 0.04 + math.sin(math.rad(Angle)) * 0.015
        end
    end)

    ShowItemInfo(ItemId)
end

local function DeleteItems(IdList: string)
    local MainFrame = Component:GetFrame()
    local InventoryFrame = MainFrame.InventoryFrame

    for _, ItemID in IdList do
        local ItemObj = InventoryFrame.ItemList:FindFirstChild(ItemID)
        if ItemObj then
            ItemObj:Destroy()
        end
    end
end

local OrderTypes = {
    ['Item'] = 1,
    ['Chip'] = 3,
    ['Drive'] = 500,
    ['Artifact'] = 900,
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

        if (DriveData.IconId == 0) then
            ObjectDesign.ItemName.Text = (DriveData.Name or ItemData.Name)
            ObjectDesign.DriveIcon.Visible = false
            ObjectDesign.ItemName.Visible = true
        else
            ObjectDesign.DriveIcon.Image = Prefix .. DriveData.IconId
            ObjectDesign.DriveIcon.Visible = true
        end
        
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
        elseif (ItemInfo and ItemInfo.Icon > 0)then
            ObjectDesign.ItemIcon.Visible = true
            ObjectDesign.ItemIcon.Image = Prefix .. ItemInfo.Icon
        else
            ObjectDesign.ItemIcon.Visible = false
            ObjectDesign.ItemName.Visible = true
            ObjectDesign.ItemName.Text = ((ItemInfo or {}).Name or (ItemData or {}).Name or "Unknown ID")
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
        elseif (ItemInfo and ItemInfo.Icon > 0)then
            ObjectDesign.ItemIcon.Visible = true
            ObjectDesign.ItemIcon.Image = Prefix .. ItemInfo.Icon
        else
            ObjectDesign.ItemIcon.Visible = false
            ObjectDesign.ItemName.Visible = true
            ObjectDesign.ItemName.Text = ((ItemInfo or {}).Name or (ItemData or {}).Name or "Unknown ID")
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

function CreateDrivesAndArtifacts()
    local AllInactive = true
    for _, FilterState in Filters do
        if FilterState then
            AllInactive = false
        end
    end

    local Count = 0;
    for _, Drive in LocalData:GetDrives() do
        if Filters['Drive'] ~= true and not AllInactive then
            break
        end

        CreateItem(Drive.Id, 'Drive', Drive)

        Count += 1;
        if Count > 3 then
            Count = 0

            task.wait()
        end
    end

    for _, Artifact in LocalData:GetArtifacts() do
        if Filters['Artifact'] ~= true and not AllInactive then
            break
        end

        CreateItem(Artifact.Id, 'Artifact', Artifact)

        Count += 1;
        if Count > 3 then
            Count = 0
            task.wait()
        end
    end
end

local function CreateAllItems()
    local Count = 0;
    for _, Item in LocalData:GetItems() do
        CreateItem(Item.Name, 'Item', Item)

        Count += 1;
        if Count > 3 then
            Count = 0
            task.wait()
        end
    end

    CreateDrivesAndArtifacts();
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

    SetFilter('Item', true)
    SetFilter('Chip', true)

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

    --
    local SellButtonFrame = MainFrame.InventoryFrame.Data.ArtifactData.Sell
    local FavButtonFrame = MainFrame.InventoryFrame.Data.ArtifactData.Favorite
    local Colors = {Color3.fromRGB(158, 20, 20), Color3.fromRGB(255, 211, 79)}

    for i, ButtonFrame in {SellButtonFrame, FavButtonFrame} do
        local BaseColor = ButtonFrame.MidStroke.Color;
        ButtonFrame.Button.MouseButton1Click:Connect(function()
            ButtonFrame.UIScale.Scale = 0.8
            ButtonFrame.UIStroke.Color = Color3.new(1, 1, 1)
            ButtonFrame.UIStroke.Thickness = 0.09
            EffectUtil:Tween(ButtonFrame.UIScale, { 0.25, 'Back' }, {Scale = 1})
            EffectUtil:Tween(ButtonFrame.UIStroke, { 0.45, 'Sine' }, {Color = Color3.new(0, 0, 0), Thickness = 0.05})

            if i == 1 then
                ToggleSellMode()
            end
        end)

        ButtonFrame.Button.MouseEnter:Connect(function()
            EffectUtil:Tween(ButtonFrame.MidStroke, { 0.3, 'Sine' }, {Color = Color3.new(1, 1, 1):Lerp(BaseColor, 0.75)})
            EffectUtil:Tween(ButtonFrame.UIShadow, { 0.3, 'Sine' }, {Color = Colors[i]})
            EffectUtil:Tween(ButtonFrame.UIScale, { 0.25, 'Quart' }, {Scale = 1.1})
        end)
        
        ButtonFrame.Button.MouseLeave:Connect(function()
            EffectUtil:Tween(ButtonFrame.MidStroke, { 0.3, 'Sine' }, {Color = BaseColor})
            EffectUtil:Tween(ButtonFrame.UIShadow, { 0.3, 'Sine' }, {Color = Color3.new()})
            EffectUtil:Tween(ButtonFrame.UIScale, { 0.25, 'Quart' }, {Scale = 1})
        end)
    end

    ---
    ToggleSellMode(false)

    local CancelSellButton = MainFrame.InventoryFrame.CancelButton
    local ConfirmSellButton = MainFrame.InventoryFrame.ConfirmSell
    ConfirmSellButton.Button.MouseButton1Click:Connect(function()
        if (os.clock() -  States.LastConfirmClick) < 1 / 10 then
            return
        end

        ConfirmSellButton.UIScale.Scale = 0.8
        ConfirmSellButton.UIStroke.Color = Color3.new(1, 0.423529, 0.423529)
        ConfirmSellButton.UIStroke.Thickness = 0.09
        EffectUtil:Tween(ConfirmSellButton.UIScale, { 0.25, 'Back' }, {Scale = 1})
        EffectUtil:Tween(ConfirmSellButton.UIStroke, { 0.45, 'Sine' }, {Color = Color3.new(0, 0, 0), Thickness = 0.05})

        if States.IsConfirming then
            States.IsConfirming = false;
            ConfirmSellButton.Label.Text = 'Sell'

            SellItems()
            ToggleSellMode(false)
        else
            ConfirmSellButton.Label.Text = 'Are you sure?'
            States.IsConfirming = true

        end
    end)

    CancelSellButton.Button.MouseButton1Click:Connect(function()
        ToggleSellMode(false)
        ConfirmSellButton.Label.Text = 'Sell'
        States.IsConfirming = false
        
        CancelSellButton.UIScale.Scale = 0.8
        CancelSellButton.UIStroke.Color = Color3.new(0.784314, 0.776471, 0.776471)
        CancelSellButton.UIStroke.Thickness = 0.09
        EffectUtil:Tween(CancelSellButton.UIScale, { 0.25, 'Back' }, {Scale = 1})
        EffectUtil:Tween(CancelSellButton.UIStroke, { 0.45, 'Sine' }, {Color = Color3.new(0, 0, 0), Thickness = 0.05})
    end)

    CancelSellButton.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(CancelSellButton.MidStroke, { 0.3, 'Sine' }, {Color = Color3.new(0.847059, 0.847059, 0.847059)})
        EffectUtil:Tween(CancelSellButton.UIScale, { 0.25, 'Quart' }, {Scale = 1.1})
    end)
    
    CancelSellButton.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(CancelSellButton.MidStroke, { 0.3, 'Sine' }, {Color = Color3.fromRGB(58, 58, 58)})
        EffectUtil:Tween(CancelSellButton.UIScale, { 0.25, 'Quart' }, {Scale = 1})
    end)

    ConfirmSellButton.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(ConfirmSellButton.MidStroke, { 0.3, 'Sine' }, {Color = Color3.new(0.694118, 0.145098, 0.145098)})
        EffectUtil:Tween(ConfirmSellButton.UIScale, { 0.25, 'Quart' }, {Scale = 1.1})
    end)
    
    ConfirmSellButton.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(ConfirmSellButton.MidStroke, { 0.3, 'Sine' }, {Color = Color3.fromRGB(58, 9, 9)})
        EffectUtil:Tween(ConfirmSellButton.UIScale, { 0.25, 'Quart' }, {Scale = 1})
    end)

    ---

end

function Component:WipeItems(List: { string })
    return DeleteItems(List)
end

return Component :: Types.UIComponent