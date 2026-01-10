local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Enemies = require(ReplicatedStorage.Modules.Shared.Database.Enemies)
local Icons = require(ReplicatedStorage.Modules.Shared.Database.Icons)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local String = require(ReplicatedStorage.Modules.Shared.Utility.String)
local Camera = require(Client.Libraries.Camera)
local Fetcher = require(Client.Libraries.Fetcher)
local UIGroups = require(Client.Libraries.UIGroups)
local BaseClass = require(Client.Classes.Interface)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)
local Drives = require(Shared.Database.Drives)
local Artifacts = require(Shared.Database.Artifacts)
local UIUtils = require(Client.Libraries.UIUtils)

local Component = BaseClass.new("ChaosControl", "Lobby", {KeyToBind = Enum.KeyCode.L})

---
local CleanupObjects = {}

local Amounts = {
    ['DailyImprovement'] = 2,
    ['ApocalypseTower'] = 7,
    ['AgentExperience'] = 1,
}

local NodeName = {
    ['DailyImprovement'] = 'Node',
    ['ApocalypseTower'] = 'Stage',
    ['AgentExperience'] = 'Floor',
}

local States = {
    CurrentTab = '',
    Pulled = false,

    InformationFrame = nil,
    Nodes = {},

    SelectedNode = 0,
    ItemListActive = false,
    SelectionDebounce = false,
}

---
function ClearNodes()
    for _, NodeObject in Component:GetFrame().Stages:GetChildren() do
        NodeObject:Destroy()
    end
end

function CreateRewardItem(ItemName: string, ItemType: string, Amount: number, Selected: boolean)
    local RewardsList = States.InformationFrame.RewardsPlate.List
    local NewItem = Assets.Lobby.Nodes.RewardItem:Clone()
    NewItem.Data.Amount.Text = 'x' .. Amount;
    NewItem.Name = ItemName;

    if Selected then
        NewItem.Name = 'SelectedItem';

        if RewardsList:FindFirstChild('SelectReward') then
            local ChangeButton = RewardsList:FindFirstChild('SelectReward');
            ChangeButton.Label.Text = 'Change'
        end
    end

    if Selected and RewardsList:FindFirstChild('SelectedItem') then
        RewardsList:FindFirstChild('SelectedItem'):Destroy()
    end


    if ItemType == 'Artifact' then
        local HasModel = UIUtils:CreateArtifactModel(ItemName, math.random(1, 6), NewItem.Viewport)
        if HasModel then
            NewItem.ItemIcon.Visible = false
        end
    elseif ItemType == 'Drive' then
        NewItem.ItemIcon.Visible = true
    elseif ItemType == 'Money' then
        NewItem.ItemIcon.Visible = true
        NewItem.ItemIcon.Image = Icons.PREFIX .. Icons.Currency.Money
    elseif ItemType == 'Gems' then
        NewItem.ItemIcon.Visible = true
        NewItem.ItemIcon.Image = Icons.PREFIX .. Icons.Currency.Gems
    end

    NewItem.Parent = RewardsList;
end

function AddEnemy(EnemyName: string, Level: number)
    local EnemyData = Enemies:GetEnemyData(EnemyName)
    local DisplayName = EnemyData.Display_Name
    local InfoFrame = States.InformationFrame

    local EnemyAssetObject = Assets.Lobby.Nodes.EnemyIcon:Clone()
    EnemyAssetObject.CharName.Text = DisplayName
    EnemyAssetObject.Data.Amount.Text = `Lv. {Level}`
    EnemyAssetObject.Parent = InfoFrame.EnemiesPlate.List

    UIUtils:CreateEnemyModel(EnemyName, EnemyAssetObject.Viewport)
end

function ClearEnemies()
    local InfoFrame = States.InformationFrame
    for _, Object in InfoFrame.EnemiesPlate.List:GetChildren() do
        if not Object:IsA('Frame') then
            continue
        end

        Object:Destroy()
    end
end

function ShowInformation(Info: {ServerData: {any}, Type: string}?)
    local MainFrame = Component:GetFrame();
    local InfoTab = States.InformationFrame :: Frame;
    local StagesTab = MainFrame.Stages :: Frame;
    
    if Info == nil then
        Effects:Tween(StagesTab, { 0.2, 'Cubic' }, { Position = UDim2.fromScale(0.5, StagesTab.Position.Y.Scale) })
        Effects:Tween(InfoTab, { 0.25, 'Sine' }, { Position = UDim2.fromScale(1.5, InfoTab.Position.Y.Scale) })
        
        return;
    end

    ClearEnemies();

    Effects:Tween(StagesTab, { 0.25, 'Sine' }, { Position = UDim2.fromScale(-1.5, StagesTab.Position.Y.Scale) })
    Effects:Tween(InfoTab, { 0.2, 'Cubic' }, { Position = UDim2.fromScale(.5, InfoTab.Position.Y.Scale) });

    ---
    InfoTab.Nameplate.Title.Text = `{String:SplitTitleCaps(States.CurrentTab)}: {NodeName[States.CurrentTab]} 0{States.SelectedNode}`

    local RewardsPlate = InfoTab.RewardsPlate;
    local StageInformation = Info.ServerData[1];

    for _, Item in RewardsPlate.List:GetChildren() do
        if not Item:IsA('Frame') then
            continue
        end

        Item:Destroy();
    end
    
    if Info.Type == 'DailyImprovement' then
        local SelectRewardButton = Assets.Lobby.Nodes.SelectReward:Clone();
        SelectRewardButton.Parent = RewardsPlate.List;
        SelectRewardButton.Name = 'SelectReward'

        SelectRewardButton.Button.MouseButton1Click:Connect(function()
            if States.ItemListActive then
                return;
            end

            ToggleItemList(true);
        end)
    end

    for _, Item in StageInformation.Rewards do
        CreateRewardItem(Item.Name or Item.Type, Item.Type, Item.Amount, false)
    end

    local Tagged = {}
    for Wave, Enemies in StageInformation.Enemies do
        for _, EnemyObject in Enemies do
            if EnemyObject.Name == nil then
                continue;
            end

            local Key = EnemyObject.Name .. EnemyObject.Level
            if Tagged[Key] then
                continue
            end

            Tagged[Key] = true;
            AddEnemy(EnemyObject.Name, EnemyObject.Level);
        end
    end
end

function CreateNodes(StageType: string, NodeCount: number)
    if States.CurrentTab == StageType then
        return;
    end

    States.CurrentTab = StageType

    local MainFrame = Component:GetFrame()
    local NodeList = Assets.Lobby.Nodes
    local NodeName = StageType .. 'Node'

    local Positions = {}
    if NodeCount == 1 then
        Positions = {UDim2.fromScale(0.5, 0.66)}
    elseif NodeCount == 2 then
        Positions = {UDim2.fromScale(0.33, 0.66), UDim2.fromScale(0.66, 0.66)}
    else
        for Index = 1, NodeCount do
            local X_Position = -1/(NodeCount*2) + (1/NodeCount)*Index 
            local Y_Position = Index % 2 == 0 and 0.4 or 0.77
            
            table.insert(Positions, UDim2.fromScale(X_Position, Y_Position))
        end
    end

    --
    local Asset = NodeList:FindFirstChild(NodeName)
    if not Asset then
        return;
    end

    ClearNodes();
    
    for NodeId = 1, NodeCount do
        local NodeClone = Asset:Clone();
        local NodePosition = Positions[NodeId]

        NodeClone.UIScale.Scale = 0;
        NodeClone.Position = NodePosition;
        NodeClone.Number.Text = string.format("%02i", NodeId);
        NodeClone.Parent = MainFrame.Stages;
        NodeClone.Button.MouseButton1Click:Connect(function()
            if not States.Nodes[StageType] then
                States.Nodes[StageType] = {}
            end

            --- Use this data
            local DataToShow = States.Nodes[StageType][NodeId];
            if not DataToShow then
                DataToShow = Fetcher:FetchChaosControl(GameEnum.ChaosControlAction.Fetch, GameEnum.ChaosControlTab[StageType], NodeId)
                States.Nodes[StageType][NodeId] = DataToShow
            end

            ---
            States.SelectedNode = NodeId;

            ShowInformation({
                ServerData = DataToShow,
                Type = StageType,
            })
        end)

        task.delay(NodeId * 1/10, function()
            if not(NodeClone) or not(NodeClone:FindFirstChild('UIScale')) then
                return;
            end

            Effects:Tween(NodeClone.UIScale, { 0.2, 'Back' }, {Scale = 1})
        end)
    end
end

local ChangeParentThread: thread? = nil;
function ToggleItemList(State: boolean)
    local Main = Component:GetFrame()
    local CategoryList = Main.List.List;

    States.ItemListActive = State;

    if ChangeParentThread then
        task.cancel(ChangeParentThread)
    end

    if State == false then
        Effects:Tween(Main.List.UIScale, { 0.5, 'Back', 'In' }, {Scale = 0})
        Effects:Tween(Main.InfoHolder, { 0.5, 'Quart' }, {GroupTransparency = 0})
        Effects:Tween(States.InformationFrame.UIScale, { 0.6, 'Back', 'Out' }, {Scale = 1})

        ChangeParentThread = task.delay(0.5, function()
            States.InformationFrame.Parent = Main
        end)

        return;
    end

    States.SelectionDebounce = false
    Effects:Tween(Main.List.UIScale, { 0.25, 'Back' }, {Scale = 1})
    Effects:Tween(States.InformationFrame.UIScale, { 0.4, 'Quad', 'Out' }, {Scale = 0.8})
    
    States.InformationFrame.Parent = Main.InfoHolder
    Effects:Tween(Main.InfoHolder, { 0.5, 'Quart' }, {GroupTransparency = 0.4})

    local Categories = {
        Drive = Drives,
        Artifact = Artifacts,
    };

    for Category, Handler in Categories do
        local MainCategoryObject = CategoryList:FindFirstChild(Category)
        if not MainCategoryObject then
            MainCategoryObject = Assets.Lobby.Nodes.ItemCategory:Clone()
            MainCategoryObject.Name = Category
            MainCategoryObject.Parent = CategoryList
        end

        MainCategoryObject.Nameplate.Title.Text = Category
        for _, Item in MainCategoryObject.ItemList:GetChildren() do
            if Item:IsA('Frame') then
                Item:Destroy()
            end
        end

        local ItemNameList = Handler:GetAll();
        for _, Name in ItemNameList do
            local Data = Handler:Get(Name)
            local ItemOption = Assets.Lobby.Nodes.RewardOption:Clone()
            ItemOption.Title.Text = (Data and Data.Name) or Name;
            ItemOption.Parent = MainCategoryObject.ItemList;

            ItemOption.Button.MouseButton1Click:Once(function()
                if States.SelectionDebounce then
                    return;
                end

                CreateRewardItem(Name, Category, 1, true)

                Network:Fire("ChaosControl", GameEnum.ChaosControlAction.Select, GameEnum.ChaosControlTab.DailyImprovement, States.SelectedNode, {
                    Type = Category,
                    Name = Name,
                })

                States.SelectionDebounce = true;
                ToggleItemList(false)

                ItemOption.UIScale.Scale = 0.75
                Effects:Tween(ItemOption.UIScale, { 0.4, 'Back', 'Out' }, {Scale = 1})
                Effects:Tween(ItemOption, { 0.3, 'Quart' }, {BackgroundColor3 = (ItemOption.BackgroundColor3 :: Color3):Lerp(Color3.new(1, 1, 1), 0.75)})

                for _, Stroke in ItemOption:GetChildren() do
                    if Stroke:IsA('UIStroke') then
                        Effects:Tween(Stroke, { 0.3, 'Quart' }, {Color = (Stroke.Color :: Color3):Lerp(Color3.new(1, 1, 1), 0.975)})
                    end
                end
            end)

        end
    end
end


---
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("ChaosControl", true)

    return Main
end

function Component:Init()

    ---
    local Main = Component:GetFrame()

    local PlayButton = Main.Information.Play
    local ReturnObj = Main.Return;
    States.InformationFrame = Main.Information;

    ReturnObj.Btn.MouseEnter:Connect(function()
        Effects:Tween(ReturnObj.UIScale, { 0.2, 'Back' }, { Scale = 1.1 })
        Effects:Tween(ReturnObj.UIStroke, { 0.3, 'Quart' }, { Color = Color3.fromRGB(90, 19, 19) })
        Effects:Tween(ReturnObj.OuterStroke, { 0.25, 'Sine' }, { Color = Color3.fromRGB(143, 0, 0) })
    end)

    ReturnObj.Btn.MouseLeave:Connect(function()
        Effects:Tween(ReturnObj.UIScale, { 0.2, 'Quart' }, { Scale = 1 })
        Effects:Tween(ReturnObj.UIStroke, { 0.3, 'Quart' }, { Color = Color3.fromRGB(62, 24, 24) })
        Effects:Tween(ReturnObj.OuterStroke, { 0.4, 'Quart' }, { Color = Color3.fromRGB() })
    end)

    ReturnObj.Btn.MouseButton1Click:Connect(function()
        self:Set(false)
    end)

    PlayButton.Button.MouseButton1Click:Connect(function()
        if States.ItemListActive then
            return
        end

        print('Katana invocada')

        Network:Fire("ChaosControl", GameEnum.ChaosControlAction.Begin, GameEnum.ChaosControlTab[States.CurrentTab], States.SelectedNode)
    end)

    

    ---
    Component:BindToStateChange(function(State: boolean)  
        Main.Visible = true

        for _, TweenOrThread in CleanupObjects do
            if typeof(TweenOrThread) == 'thread' then
                task.cancel(TweenOrThread)
            else
                TweenOrThread:Cancel()
            end
        end

        CleanupObjects = {}

        if State then
            ShowInformation(nil);

            Camera:MarkUsage("ChaosControl")

            table.insert(CleanupObjects, Effects:Tween(workspace.CurrentCamera, { 0.45, 'Quint' }, { CFrame = workspace.World.LobbyCutscenes.ChaosControl.Main.CFrame }))
            table.insert(CleanupObjects, Effects:Tween(workspace.CurrentCamera, { 0.6, 'Back' }, { FieldOfView = 60 }))
            
            Main.Return.Rotation = -90

            for _, Object in Main.Missions.List:GetChildren() do
                if not Object:IsA('Frame') then
                    continue
                end
                Object.UIScale.Scale = 0
            end
            
            Effects:Tween(Main.Background, {0.3, 'Sine'}, {BackgroundTransparency = 0.45})
            Effects:Tween(Main.Return, {0.5, 'Quart'}, {Position = UDim2.fromScale(0.137, 0.948)})
            Effects:Tween(Main.Return, {0.7, 'Back'}, {Rotation = 0})
            Effects:Tween(Main.Missions, {0.3, 'Quad'}, {Position = UDim2.fromScale(0.5, 0.886)})



            table.insert(CleanupObjects, task.delay(0.15, function()

                table.insert(CleanupObjects, Effects:Tween(Main.Missions.Nameplate.UIScale, {0.3, 'Back'}, {Scale = 1}))

                for k, Object in Main.Missions.List:GetChildren() do
                    if not Object:IsA('Frame') then
                        continue
                    end
                    table.insert(CleanupObjects, Effects:Tween(Object.UIScale, {0.4, 'Back'}, {Scale = 1}))
                    task.wait((k - 1) * 1 / 7)
                end
            end))


            ---
            if not States.Pulled then
                Amounts.DailyImprovement = Fetcher:FetchChaosControl(GameEnum.ChaosControlAction.Amount, GameEnum.ChaosControlTab.DailyImprovement)[1]
            end
        else
            Camera:FreeUsage()

            ClearNodes()
            ShowInformation(nil)
            States.CurrentTab = ""

            local LobbyMain = UIGroups:GetElementClass('Lobby', 'MainMenu')
            LobbyMain:Set(true, true)
            
            Effects:Tween(Main.Return, {0.25, 'Quad'}, {Position = UDim2.fromScale(-0.1, 0.948)})
            Effects:Tween(Main.Return, {0.2, 'Back'}, {Rotation = -90})
            Effects:Tween(Main.Background, {0.2, 'Sine'}, {BackgroundTransparency = 1})
            Effects:Tween(Main.Missions, {0.3, 'Quad', 'In'}, {Position = UDim2.fromScale(0.5, 1.3)})
            Effects:Tween(Main.Missions.Nameplate.UIScale, {0.3, 'Quad'}, {Scale = 0})
        end
    end)

    ---
    local List = Main.Missions.List;

    for _, Object in List:GetChildren() do
        if not Object:IsA('Frame') then
            continue;
        end

        Object.Button.MouseButton1Click:Connect(function()
            CreateNodes(Object.Name, Amounts[Object.Name])
            ToggleItemList(false);
            ShowInformation(nil);
        end)
    end
end

return Component