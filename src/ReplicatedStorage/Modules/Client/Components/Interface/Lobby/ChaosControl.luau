local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
--local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Fetcher = require(ReplicatedStorage.Modules.Client.Libraries.Fetcher)
local UIGroups = require(ReplicatedStorage.Modules.Client.Libraries.UIGroups)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local BaseClass = require(Client.Classes.Interface)
local Component = BaseClass.new("ChaosControl", "Lobby", {KeyToBind = Enum.KeyCode.L})

---
local CleanupObjects = {}

local Amounts = {
    ['DailyImprovement'] = 2,
    ['ApocalypseTower'] = 7,
    ['AgentExperience'] = 1,
}

local States = {
    CurrentTab = '',
    Pulled = false,
    Nodes = {},
}

---
function ClearNodes()
    for _, NodeObject in Component:GetFrame().Stages:GetChildren() do
        NodeObject:Destroy()
    end
end

function ShowInformation(Info: {}?)
    local MainFrame = Component:GetFrame();
    local InfoTab = MainFrame.Information :: Frame;
    local StagesTab = MainFrame.Stages :: Frame;
    
    if Info == nil then
        Effects:Tween(StagesTab, { 0.2, 'Cubic' }, { Position = UDim2.fromScale(0.5, StagesTab.Position.Y.Scale) })
        Effects:Tween(InfoTab, { 0.25, 'Sine' }, { Position = UDim2.fromScale(1.5, InfoTab.Position.Y.Scale) })
        
        return;
    end

    Effects:Tween(StagesTab, { 0.25, 'Sine' }, { Position = UDim2.fromScale(-1.5, StagesTab.Position.Y.Scale) })
    Effects:Tween(InfoTab, { 0.2, 'Cubic' }, { Position = UDim2.fromScale(.5, InfoTab.Position.Y.Scale) })
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
            ShowInformation({})

            if not States.Nodes[StageType] then
                States.Nodes[StageType] = {}
            end

            --- Use this data
            local DataToShow = States.Nodes[StageType][NodeId];
            if not DataToShow then
                DataToShow = Fetcher:FetchChaosControl(GameEnum.ChaosControlAction.Fetch, GameEnum.ChaosControlTab[StageType], NodeId)
                States.Nodes[StageType][NodeId] = DataToShow
            end
        end)

        task.delay(NodeId * 1/10, function()
            if not(NodeClone) or not(NodeClone:FindFirstChild('UIScale')) then
                return;
            end

            Effects:Tween(NodeClone.UIScale, { 0.2, 'Back' }, {Scale = 1})
        end)
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

    local ReturnObj = Main.Return;

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
            ShowInformation(nil);
        end)
    end
end

return Component