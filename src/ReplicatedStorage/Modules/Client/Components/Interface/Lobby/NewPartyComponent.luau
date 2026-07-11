local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local AgentModels = ReplicatedStorage.Assets.Characters.Agents
local Assets = ReplicatedStorage.Assets.Interface

local LocalData = require(ReplicatedStorage.Modules.Client.Libraries.LocalData)
local UIGroups = require(ReplicatedStorage.Modules.Client.Libraries.UIGroups)
local UIUtils = require(ReplicatedStorage.Modules.Client.Libraries.UIUtils)
local Navigation = require(ReplicatedStorage.Modules.Client.States.Navigation)
local RandomNameGen = require(ReplicatedStorage.Modules.Client.Utility.RandomNameGen)
local Network = require(Shared.Network)
local Fetcher = require(Client.Libraries.Fetcher)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local String = require(ReplicatedStorage.Modules.Shared.Utility.String)
local GameEnum = require(Shared.GameEnum)
local StagesDatabase = require(Shared.Database.Stages)
local MissionsDatabase = require(Shared.Database.Missions)

local BaseClass = require(Client.Classes.Interface)
local Component = BaseClass.new("NewPartyComponent", "Lobby")

--- Constants
local DockPositions = {
    Agents = {
        Open = UDim2.fromScale(0.225, 0.5),
        Closed = UDim2.fromScale(-.25, 0.5)
    },

    Maps = {
        Open = UDim2.fromScale(0.769, 0.512),
        Closed = UDim2.fromScale(1.25, 0.5),
    },

    Mission = {
        Open = UDim2.fromScale(0.5, 0.5),
        Closed = UDim2.fromScale(0.5, 0.5)
    },

    Companions = {
        Open = UDim2.fromScale(0.644, 0.469),
        Closed = UDim2.fromScale(0.51, 0.469)
    },

    Acts = {
        Open = UDim2.fromScale(0.905, 0.397),
        Closed = UDim2.fromScale(1.2, 0.397),
    },

    Info = {
        Open = UDim2.fromScale(0.918, 0.343),
        Closed = UDim2.fromScale(.77, 0.343),
    }
}

local Threads = {}
local States = {
    Agents = true,
    Maps = true,
    MissionId = '',
    SelectedMission = nil,

    IsReady = false,
    Queueing = Component:GetScope():Value(false),

    TotalReady = Component:GetScope():Value(0),

    Companion = nil,

    Stage = Component:GetScope():Value(''),
    CurrentPartyOwner = Component:GetScope():Value(0),
    PlayerCount = Component:GetScope():Value(0),
    Team = Component:GetScope():Value({}),
    OwnedAgents = Component:GetScope():Value({}),
}


--- Networking
local function RequestPartyCreation()
    --
    Network:Fire("Party", GameEnum.PartyManaging.Create)

    local Data = Fetcher:FetchAgents()
    States.OwnedAgents:set(Data)

    return true
end

local function RequestPartyTeamUpdate(): ()
    Network:Fire("Party", GameEnum.PartyManaging.ChangeTeam, Component:Peek(States.Team))
end

local function RequestInvitePlayer(Player: string)
    Network:Fire("Party", GameEnum.PartyManaging.Invite, Player)
end

local function RequestMapChange(ActName: string): ()
    Network:Fire("Party", GameEnum.PartyManaging.ChangeStage, {"Expedition", Component:Peek(States.Stage), ActName})
end

local function RequestMissionChange(): ()
    Network:Fire("Party", GameEnum.PartyManaging.ChangeStage, {"Mission", States.MissionId})
end

local function HandlePlayButton()
    if States['Companions'] == true then
        return;
    end

    if States.Thread then
        task.cancel(States.Thread)
    end

    RequestPartyTeamUpdate()

    --- Animation
    local MissionDock = Component:GetFrame():FindFirstChild("Mission")
    local Play = MissionDock:FindFirstChild("Play")
    Play.UIScale.Scale = 0.75

    Effects:Tween(Play.UIScale, { .25, 'Back' }, {Scale = 1})

    if not(Component:Peek(States.Queueing)) and States.IsReady then
        Network:Fire("Party", GameEnum.PartyManaging.CancelReady)

        States.IsReady = false
        --
        
        ChangePlayButtonState()
    else
        if #Component:Peek(States.Team) < 1 then
            return;
        end

        States.IsReady = true
        ChangePlayButtonState()

        Network:Fire("Party", GameEnum.PartyManaging.Start)
    end
end

function ChangePlayButtonState()
    local MissionDock = Component:GetFrame():FindFirstChild("Mission")
    local Play = MissionDock:FindFirstChild("Play")
    local Queueing = MissionDock:FindFirstChild("Queueing")
    local TotalReady = Component:Peek(States.TotalReady)
    local TotalParty = Component:Peek(States.PlayerCount)

    if Component:Peek(States.Queueing) == true then
        Play.Visible = false
        Queueing.Visible = true
    else
        Play.Visible = true
        Queueing.Visible = false
    end

    if not States.IsReady then
        Play.BackgroundColor3 = Color3.fromRGB(27, 76, 24)
        Play.Inner.Color = Color3.fromRGB(35, 100, 0)
        Play.Tag.UIStroke.Color = Color3.fromRGB(0, 56, 5)
        Play.UIShadow.Color = Color3.fromRGB(24, 58, 15)
        
        if TotalParty <= 1 then
            Play.Tag.Text = 'Ready'
        else
            Play.Tag.Text = 'Ready (' .. TotalReady .. '/' .. TotalParty .. ')'
        end
    else
        Play.BackgroundColor3 = Color3.fromRGB(76, 18, 18)
        Play.Inner.Color = Color3.fromRGB(100, 24, 24)
        Play.Tag.UIStroke.Color = Color3.fromRGB(56, 7, 7)
        Play.Tag.Text = 'Unready (' .. TotalReady .. '/' .. TotalParty .. ')'
        Play.UIShadow.Color = Color3.fromRGB(58, 0, 0)
    end
end

local Debounce = false
local function HandleInvite()
    local MissionDock = Component:GetFrame():FindFirstChild("Mission")
    if Debounce then
        return;
    end

    Debounce = true

    task.delay(0.5, function()
        Debounce = false
    end)

    MissionDock.Invite.UIScale.Scale = 0.75
    Effects:Tween(MissionDock.Invite.UIScale, { .25, 'Back' }, {Scale = 1})
    
    --
    local Name = MissionDock.PlayerInvitedName.Text
    for _, OtherPlayer in Players:GetPlayers() do
        if (OtherPlayer.Name:lower()):match(Name:lower()) and OtherPlayer ~= Player then
            Name = OtherPlayer.Name
        end
    end

    RequestInvitePlayer(Name)
end

--- Helpers
function AnimatePlateHover(Frame: Frame, Button: TextButton)

    local OSThick = Frame.OuterStroke.Thickness
    local Pressed = Button or Frame.Button

    Pressed.MouseEnter:Connect(function()
        Effects:Tween(Frame.UIScale, {.2, 'Quad'}, {Scale = 1.05})
        Effects:Tween(Frame.OuterStroke, {.2, 'Quad'}, {Color = Color3.new(1, 1, 1), Thickness = OSThick * 0.74})
    end)

    Pressed.MouseLeave:Connect(function()
        Effects:Tween(Frame.UIScale, {.2, 'Quad'}, {Scale = 1})
        Effects:Tween(Frame.OuterStroke, {.2, 'Quad'}, {Color = Color3.new(), Thickness = OSThick})
    end)

end

--- Privates
function SetDockState(DockName: string, State: boolean)
    if States[DockName] == State then
        return;
    end

    if (States['Companions'] == true and DockName ~= 'Companions') then
        return; 
    end

    States[DockName] = State

    if Threads[DockName] then
        task.cancel(Threads[DockName])
    end
    
    local MainFrame = Component:GetFrame()
    local Positions = DockPositions[DockName]
    local DockFrame = MainFrame:FindFirstChild(DockName)
    if not DockFrame then
        return;
    end

    if State then
        Effects:Tween(DockFrame.UIScale, { 0.2, 'Cubic' }, { Scale = 1 })
        Effects:Tween(DockFrame, { 0.2, 'Cubic' }, { Position = Positions.Open })

        if DockName == 'Mission' or DockName == 'Info' or DockName == 'Companions' then
            DockFrame.Parent = MainFrame.Transition
            MainFrame.Transition.GroupTransparency = 1

            Effects:Tween(MainFrame.Transition, {.2, 'Quad'}, {GroupTransparency = 0})
            
            Threads[DockName] = task.delay(0.2, function()
                DockFrame.Parent = MainFrame
            end)
        end

        DockFrame.Visible = true
    else
        if DockName == 'Maps' then
            SetDockState('Acts', false)
            SetDockState('Info', false)
        elseif DockName == 'Mission' or DockName == 'Info' or DockName == 'Companions' then
            MainFrame.Transition.GroupTransparency = 0
            DockFrame.Parent = MainFrame.Transition

            Effects:Tween(DockFrame, { 0.3, 'Cubic', 'In' }, { Position = Positions.Closed })
            Effects:Tween(DockFrame.UIScale, { 0.5, 'Cubic', 'In' }, { Scale = 0.5 })
            Effects:Tween(MainFrame.Transition, {.2, 'Quad'}, {GroupTransparency = 1})
            
            Threads[DockName] = task.delay(0.2, function()
                DockFrame.Visible = false
                DockFrame.Parent = MainFrame
            end)

            return
        end

        Effects:Tween(DockFrame.UIScale, { 0.5, 'Cubic', 'In' }, { Scale = 0.5 })
        Effects:Tween(DockFrame, { 0.3, 'Cubic', 'In' }, { Position = Positions.Closed })

        Threads[DockName] = task.delay(0.3, function()
            DockFrame.Visible = false
        end)
    end
end

function SetupCloseButton(DockName: string, button_fn: () -> ())
    local Dock = Component:GetFrame():FindFirstChild(DockName) or Component:GetFrame().Transition:FindFirstChild(DockName)
    if Dock == nil and DockName == 'Mission' then
        Dock = States.MissionDock
    end

    local CloseFrame = Dock:FindFirstChild("CloseButton")
    if not CloseFrame then
        return;
    end

    CloseFrame.Button.MouseEnter:Connect(function()
        if States[DockName] == true then
            Effects:Tween(CloseFrame.UIScale, { 0.2, 'Quad' }, { Scale = 1.1 })
        end
    end)

    CloseFrame.Button.MouseLeave:Connect(function()
        if States[DockName] == true then
            Effects:Tween(CloseFrame.UIScale, { 0.2, 'Quad' }, { Scale = 1 })
        end
    end)

    CloseFrame.Button.MouseButton1Click:Connect(function()
        if button_fn then
            button_fn()
        else
            SetDockState(DockName, false)
        end

        CloseFrame.UIScale.Scale = 0.75
        CloseFrame.InnerStroke.Color = Color3.fromRGB(131, 0, 0)
        CloseFrame.OuterStroke.Color = Color3.fromRGB(83, 0, 0)
        CloseFrame.BackgroundColor3  = Color3.fromRGB(68, 0, 0)

        Effects:Tween(CloseFrame.InnerStroke, { .25, 'Quad' }, { Color = Color3.fromRGB(48, 0, 0) })
        Effects:Tween(CloseFrame.OuterStroke, { .25, 'Quad' }, { Color = Color3.fromRGB(22, 0, 0) })
        Effects:Tween(CloseFrame, { .25, 'Quad' }, { BackgroundColor3 = Color3.fromRGB(27, 0, 0) })

        Effects:Tween(CloseFrame.UIScale, { 0.2, 'Back' }, { Scale = 1 })
    end)
end

function AddAgentObject(Agent: string, Level: number)
    local Dock = Component:GetFrame():FindFirstChild('Agents')
    local List = Dock:FindFirstChild("List") :: ScrollingFrame


    ---
    local CreatedObject = Assets.Lobby.Party.OwnedAgentObject:Clone()
    CreatedObject.CharacterName.Text = Agent
    CreatedObject.CharacterLevel.Text = 'Lvl. ' .. Level
    CreatedObject.Name = Agent
    CreatedObject:SetAttribute("AgentName", Agent)
    CreatedObject.Parent = List
    
    local AgentModelBase = AgentModels:FindFirstChild(Agent) or AgentModels.Template
    if AgentModelBase then
        local Model = AgentModelBase:Clone()
        Model:PivotTo(CFrame.new())
        Model.Parent = CreatedObject.Viewport.World

        --
        local Camera = Instance.new("Camera")
        Camera.CFrame = CFrame.new(0, 1.75, -35) * CFrame.Angles(0, math.pi, 0)
        Camera.Parent = CreatedObject.Viewport.World
        Camera.FieldOfView = 5

        CreatedObject.Viewport.CurrentCamera = Camera
    end

    CreatedObject.Select.MouseButton1Click:Connect(function()
        SelectAgent(Agent)
    end)

    return CreatedObject
end

function AddPlayerToList(PlayerId: number)
    local User = Players:GetPlayerByUserId(PlayerId)
    local MissionDock = States.MissionDock
    local Object = Assets.Lobby.Party.UserObject:Clone()
    Object.PlayerName.Text = User.DisplayName
    --Object.TeamCharacters.Text = Team
    Object.Name = PlayerId
    Object.Kick.Visible = false
    Object.Parent = MissionDock.UsersPlate.List

    Object.HoverButton.MouseEnter:Connect(function()
        if Player.UserId == Component:Peek(States.CurrentPartyOwner) then
            Object.Kick.Visible = true
        end
    end)

    Object.HoverButton.MouseLeave:Connect(function()
        Object.Kick.Visible = false
    end)

    return Object
end

local function RemovePlayer(PlayerId: number)
    local MissionDock = States.MissionDock
    local PlayerObject = MissionDock.UsersPlate.List:FindFirstChild(PlayerId) :: Frame

    if PlayerObject then
        PlayerObject:Destroy()
    end
end

local function ClearParty()
    local MissionDock = States.MissionDock
    local PlayerList = MissionDock.UsersPlate.List :: ScrollingFrame

    for _, Object in PlayerList:GetChildren() do
        if Object:IsA("Frame") then
            Object:Destroy()
        end
    end
end



function SelectAgent(Name: string)
    local Selected = Component:Peek(States.Team)

    local Removed = false;
    for key, Agent in Selected do
        if Name == Agent then
            table.remove(Selected, key)
            Removed = true
        end
    end

    if not Removed then
        if #Selected >= 3 then
            table.insert(Selected, 1, Name)
            table.remove(Selected, 4)
        else
            table.insert(Selected, Name)
        end
    end

    if States.Thread then
        task.cancel(States.Thread)
    end

    States.Thread = task.delay(.25, RequestPartyTeamUpdate)

    UpdateTeamPreviews()
    MarkSelectedAgents()

    return States.Team:set(Selected)
end

function MarkSelectedAgents()
    local Dock = Component:GetFrame():FindFirstChild("Agents")
    local CurrentTeam = Component:Peek(States.Team)

    for _, AgentFrame in Dock.List:GetChildren() do
        if not AgentFrame:IsA('Frame') then
            continue
        end

        if AgentFrame.UIScale.Scale > 0.9 and not(table.find(CurrentTeam, AgentFrame.Name)) then
            Effects:Tween(AgentFrame.UIScale, { 0.25, 'Back' }, { Scale = 0.9 })
            Effects:Tween(AgentFrame.Outer, { 0.2, 'Quad' }, { Color = Color3.new() })
        elseif table.find(CurrentTeam, AgentFrame.Name) then
            Effects:Tween(AgentFrame.UIScale, { 0.25, 'Back' }, { Scale = 1 })
            Effects:Tween(AgentFrame.Outer, { 0.2, 'Quad' }, { Color = Color3.new(1, 1, 1) })
        end
        
    end
end

function UpdateTeamPreviews()
    local Dock = States.MissionDock
    local TeamPlate = Dock:FindFirstChild("TeamPlate")

    local AgentFolder = TeamPlate:FindFirstChild("Agents")
    local AgentList = Component:Peek(States.Team)

    for Index = 1, 3 do
        local AgentName = AgentList[Index]
        local SlotName = 'Slot'..Index
        local Object = AgentFolder:FindFirstChild(SlotName)
        if not Object then
            continue
        end

        local Occupier = AgentName or 'Empty'
        Object.CharName.Text = Occupier
        Object.Viewport.World:ClearAllChildren()

        if Object:GetAttribute("Agent") ~= Occupier and Occupier ~= 'Empty' then
            Object.UIScale.Scale = 0.75
            Object.Outer.Color = Color3.new(1, 1, 1)
            Object.Outer.Thickness = 0.035
            Effects:Tween(Object.UIScale, { 0.3, 'Back' }, {Scale = 1})
            Effects:Tween(Object.Outer, { 0.3 }, {Color = Color3.new(), Thickness = 0.027})
        end

        Object:SetAttribute('Agent', Occupier)

        if not AgentName then
            continue
        end

        local NewCamera = Instance.new("Camera")
        NewCamera.CFrame = CFrame.new(0, 1.75, -25) * CFrame.Angles(0, math.pi, 0)
        NewCamera.FieldOfView = 10
        NewCamera.Parent = Object.Viewport
        Object.Viewport.CurrentCamera = NewCamera;

        local AgentModelBase = AgentModels:FindFirstChild(AgentName) or AgentModels.Template
        if AgentModelBase then
            local Model = AgentModelBase:Clone()
            Model:PivotTo(CFrame.new())
            Model.Parent = Object.Viewport.World
        end
    end
end

local function GetDock(DockName: string)
    return Component:GetFrame():FindFirstChild(DockName) or Component:GetFrame().Transition:FindFirstChild(DockName)
end

local function UpdateMissions(Unlocked: {})
    local Missions = MissionsDatabase:GetAll(true)
    local MapsDock = Component:GetFrame():FindFirstChild("Maps")

    for _, obj in MapsDock.List:GetChildren() do
        if obj:IsA("Frame") then
            obj:Destroy()
        end
    end

    for MissionId, MissionData in Missions do
        if not MissionData.Stage_Act then
            continue
        end

        local StageInfo = StagesDatabase:GetStage(string.split(MissionData.Stage_Act, "/")[1])
        local Object = Assets.Lobby.Party.MissionObject:Clone()
        Object.Parent = MapsDock.List
        Object.MissionName.Text = MissionData.Display_Name or MissionId
        Object.Name = MissionId
        Object.LvlRec.Text = 'Lv.'..(MissionData.Recommended_Level or 1);
        Object.Banner.Image = StageInfo.Icon and 'rbxassetid://' .. StageInfo.Icon or "rbxassetid://118719541712234"

        -- TODO: Make this actually do something lmao.
        if Unlocked[MissionId] == nil then
            --
        end

        Object.Button.MouseButton1Click:Connect(function()
            if States.SelectedMission == MissionId then
                SetDockState('Info', false)
                States.SelectedMission = nil
                Effects:Tween(Object.UIShadow, { 0.25, 'Quad' }, {Transparency = 1})
                Effects:Tween(Object.Outer, { 0.2, 'Quart' }, {Color = Color3.new(0, 0, 0), Thickness = 0.045})
                Effects:Tween(Object.UIScale, { 0.3, 'Quad' }, {Scale = 1})
                return
            elseif States.SelectedMission ~= nil then
                local OldObj = MapsDock.List:FindFirstChild(States.SelectedMission)
                Effects:Tween(OldObj.UIShadow, { 0.25, 'Quad' }, {Transparency = 1})
                Effects:Tween(OldObj.Outer, { 0.2, 'Quart' }, {Color = Color3.new(0, 0, 0), Thickness = 0.045})
                Effects:Tween(OldObj.UIScale, { 0.3, 'Quad' }, {Scale = 1})
            end

            States.SelectedMission = MissionId;

            Effects:Tween(Object.UIShadow, { 0.25, 'Quad' }, {Transparency = 0})
            Effects:Tween(Object.Outer, { 0.2, 'Quart' }, {Color = Color3.new(1, 1, 1), Thickness = 0.025})
            Effects:Tween(Object.UIScale, { 0.3, 'Quad' }, {Scale = 1.05})

            ---
            local InfoDock = GetDock('Info')
            InfoDock.Description.Text = MissionData.Description;
            InfoDock.LvlRec.Lvl.Text = 'Lv.'..(MissionData.Recommended_Level or 1);

            SetDockState('Info', true)
        end)

        Object.Button.MouseEnter:Connect(function()
            Effects:Tween(Object.Outer, { .2, 'Quad' }, {Color = Color3.new(1, 1, 1)})
            Effects:Tween(Object.UIScale, { 0.3, 'Quad' }, {Scale = 1.01})
        end)

        Object.Button.MouseLeave:Connect(function()
            if States.SelectedMission == MissionId then
                return
            end
            
            Effects:Tween(Object.Outer, { .2, 'Quad' }, {Color = Color3.new(), Thickness = 0.045})
            Effects:Tween(Object.UIScale, { 0.3, 'Quad' }, {Scale = 1})
        end)
    end

end


local function UpdateStages(Unlocked: {})
    local Stages = StagesDatabase:GetAll()
    local MapsDock = GetDock("Maps")

    for _, obj in MapsDock.List:GetChildren() do
        if obj:IsA("Frame") then
            obj:Destroy()
        end
    end

    for StageName, StageData in Stages do
        local Object = Assets.Lobby.Party.MapObject:Clone()
        Object.Parent = MapsDock.List
        Object.Banner.Image = StageData.Icon and 'rbxassetid://' .. StageData.Icon or "rbxassetid://118719541712234"
        Object.MapName.Text = StageData.Name

        if Unlocked[StageName] == nil then
            Object.Banner.ImageTransparency = 0.65
            Object.Lock.Visible = true
            Object.LayoutOrder = 1000
            continue
        end

        Object.Button.MouseButton1Click:Connect(function()
            for _, Stage in MapsDock.List:GetChildren() do
                if Stage ~= Object and Stage:IsA('Frame') then
                    Effects:Tween(Stage.Outer, { .2 }, { Color = Color3.new() })            
                    Effects:Tween(Stage.UIScale, { 0.2, 'Quad' }, {Scale = 1})
                end
            end

            Effects:Tween(Object.Outer, { .2 }, { Color = Color3.new(1, 1, 1) })
            Effects:Tween(Object.UIScale, { 0.2, 'Quad' }, {Scale = 1.05})

            States.Stage:set(StageName)

            SetDockState('Acts', true)
            LoadActs(StageName, Unlocked)
        end)
    end
end

function ShowStageInfo(CodeStage: string, Id: string)
    local MissionDock = Component:GetFrame():FindFirstChild("Mission")
    local MapPlate = MissionDock.MapPlate
    
    if CodeStage == '' or #CodeStage < 1 then
        MapPlate.MapName.Text = "Unknown"
        MapPlate.ActName.Text = ""
        MapPlate.Banner.Image = 'rbxassetid://118719541712234'
        
        return
    end
    
    local Split = string.split(CodeStage, "/")
    local Type = Split[1]
    local Stage = Split[2]
    local Act = Split[3]

    if Id ~= nil and Type == 'Mission' then
        
    end

    local StageData = StagesDatabase:GetStage(Stage)

    MapPlate.MapName.Text = String:SplitTitleCaps(Stage)
    MapPlate.ActName.Text = Act
    MapPlate.Banner.Image = 'rbxassetid://'.. (StageData.Icon or 118719541712234)
end

function LoadActs(Stage: string, Stages: {})
    local ActsDock = Component:GetFrame():FindFirstChild("Acts")
    local StageActs = StagesDatabase:GetAllActs(Stage)

    ActsDock.Nameplate.Title.Text = Stage

    for _, Act in ActsDock.List:GetChildren() do
        if Act:IsA("TextButton") then
            Act:Destroy()
        end
    end

    for ActName, Data in StageActs do
        local Object = Assets.Lobby.Party.ActButton:Clone()
        Object.Label.Text = Data.Name or ActName
        Object.Parent = ActsDock.List

        if Stages[Stage][ActName] ~= true then
            Object.Lock.Visible = true
            Object.BackgroundColor3 = Color3.fromRGB(134, 134, 134)
            Object.Bg.ImageColor3 = Color3.fromRGB(0, 0, 0)
            Object.Bg.ImageTransparency = 0.5
            Object.Label.TextTransparency = 0.5
            Object.Label.UIStroke.Transparency = 0.5
            Object.Inner.Color = Color3.fromRGB(109, 109, 109)
            Object.UIGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(91, 91, 91)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            }
            Object.LayoutOrder = 999
        else
            Object.LayoutOrder = 1
            Object.MouseButton1Click:Connect(function()
                SetDockState('Acts', false)

                RequestMapChange(ActName)
            end)
        end
    end
end

function SetMode(State: string, ServerData: {})
    local MainFrame = Component:GetFrame()
    local MissionFrame = MainFrame.Mission

    if State == 'ChaosControl' then
        local ChaosData = ServerData.ChaosControlData
        MissionFrame.MapPlate.Visible = false
        MissionFrame.ChaosPlate.Visible = true

        MissionFrame.ChaosPlate.Type.Text = String:SplitTitleCaps(ChaosData.Type)
        MissionFrame.ChaosPlate.Node.Text = `Node 0{ChaosData.Node}`

        if ChaosData.Type == 'DailyImprovement' then
            local Stage = StagesDatabase:GetStage(ChaosData.MapStage or "DailyImprovement");
            if not Stage then
                return;
            end
            
            MissionFrame.ChaosPlate.Banner.Image = 'rbxassetid://' .. Stage.Icon;
        end
    elseif State == 'Mission' then
        MissionFrame.MapPlate.Visible = true
        MissionFrame.ChaosPlate.Visible = false
    end
end

function ShowRewards(List)
    local MainFrame = Component:GetFrame()

    for _, Item in MainFrame.Mission.RewardsPlate.List:GetChildren() do
        if Item:IsA('Frame') then
            Item:Destroy()
        end
    end

    for _, Item in List do
        UIUtils:CreateRewardItem(Item.Name or Item.Type, Item.Type, Item.Amount, false, MainFrame.Mission.RewardsPlate.List)
    end
end

function HandleMissionSelect()
    local Dock = GetDock('Info')

    Dock.SelectBtn.Button.MouseButton1Click:Connect(function()
        States.MissionId = States.SelectedMission
        RequestMissionChange()
        Dock.SelectBtn.UIScale.Scale = 0.9
        Effects:Tween(Dock.SelectBtn.UIScale, {0.3, 'Back'}, {Scale = 1})
    end)
    Dock.SelectBtn.Button.MouseEnter:Connect(function()
        Effects:Tween(Dock.SelectBtn.OuterStroke, {0.3, 'Quad'}, {Color = Color3.fromRGB(34, 255, 0)})
        Effects:Tween(Dock.SelectBtn.UIShadow, {0.25, 'Quart'}, {Transparency = 0.25})
    end)

    Dock.SelectBtn.Button.MouseLeave:Connect(function()
        Effects:Tween(Dock.SelectBtn.OuterStroke, {0.3, 'Quad'}, {Color = Color3.fromRGB(13, 97, 0)})
        Effects:Tween(Dock.SelectBtn.UIShadow, {0.25, 'Quart'}, {Transparency = 1})
    end)
end

function SelectCompanion(Id: string)
    local Dock = GetDock("Mission")
    local CompanionPlate = Dock.CompanionPlate;

    if string.len(Id) <= 1 then
        CompanionPlate.Companion.Viewport.World:ClearAllChildren();
        CompanionPlate.Companion.Plus.Visible = true

        return;
    end

    local CompanionsFolder = ReplicatedStorage.Assets.Characters.Companions
    local Data = LocalData:GetCompanion(Id);
    local Model = CompanionsFolder:FindFirstChild(Data.Name) 
        or Assets.Characters.Companions:FindFirstChild('Default')
    SetDockState('Companions', false)

    CompanionPlate.CompanionName.Text = RandomNameGen(Data.Id);
    States.Companion = Id;
    CompanionPlate.Companion.Plus.Visible = false

    if Model then
        local Cloned = Model:Clone()
        Cloned.PrimaryPart.Anchored = true
        Cloned:PivotTo(CFrame.new() * CFrame.Angles(0, math.pi, 0))
        Cloned.Parent = CompanionPlate.Companion.Viewport.World;

        local Cam = Instance.new("Camera")
        Cam.CFrame = CFrame.new(0, -0.25, 175)
        Cam.FieldOfView = 1
        Cam.Parent = CompanionPlate.Companion.Viewport;
        CompanionPlate.Companion.Viewport.CurrentCamera = Cam;
    end

    --
    Network:Fire("Party", GameEnum.PartyManaging.SelectCompanion, States.Companion)
end

function LoadCompanionList(State: boolean)
    if LocalData:GetAllCompanions() == nil then
        Fetcher:FetchCompanions()
    end

    local Dock = GetDock("Companions")
    local CompanionsFolder = ReplicatedStorage.Assets.Characters.Companions

    for _, Object in Dock.List:GetChildren() do
        if Object:IsA('Frame') then
            Object:Destroy();
        end
    end

    if State then
        return;
    end

    for _, Companion in LocalData:GetAllCompanions() do
        local Model = CompanionsFolder:FindFirstChild(Companion.Name) or Assets.Characters.Companions:FindFirstChild('Default')
        local CompanionObject = Assets.Companions.CompSelect:Clone();
        CompanionObject.Level.Text = 'Level: ' .. Companion.Level;
        CompanionObject.Id.Text = RandomNameGen(Companion.Id);
        CompanionObject.Parent = Dock.List;
        CompanionObject.LayoutOrder = -Companion.Level;

        if Model then
            local Cloned = Model:Clone()
            Cloned.PrimaryPart.Anchored = true
            Cloned:PivotTo(CFrame.new() * CFrame.Angles(0, math.pi, 0))
            Cloned.Parent = CompanionObject.Viewport.World;

            local Cam = Instance.new("Camera")
            Cam.CFrame = CFrame.new(0, -0.25, 175)
            Cam.FieldOfView = 1
            Cam.Parent = CompanionObject.Viewport;
        end

        CompanionObject.Btn.MouseButton1Click:Connect(function()
            SelectCompanion(Companion.Id)
        end)
    end
end

--- Publics
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("NewParty", true)

    return Main
end

function Component:SetMode(State: string, Data: {})
    SetMode(State or 'Mission', Data)
end


function Component:Init()
    
    local Frame = Component:GetFrame()
    local MissionDock = Frame:FindFirstChild("Mission")

    States.MissionDock = MissionDock

    for Dock in DockPositions do
        SetDockState(Dock, false)
        SetupCloseButton(Dock)
    end

    HandleMissionSelect()

    SetupCloseButton('Mission', function()  
        Network:Fire('Party', GameEnum.PartyManaging.Leave)
        self:Set(false)


        ---
        local MainMenuUI = UIGroups:GetElementClass("Lobby", "MainMenu")
        if MainMenuUI then
            MainMenuUI:Set(true, true)
        end
    end)

    MissionDock.TeamPlate.Button.MouseButton1Click:Connect(function()
        SetDockState('Agents', not States.Agents)
    end)

    MissionDock.CompanionPlate.Button.MouseButton1Click:Connect(function()
        LoadCompanionList(States.Companions)
        SetDockState('Companions', not States.Companions)
    end)

    MissionDock.MapPlate.Button.MouseButton1Click:Connect(function()
        if Component:Peek(States.CurrentPartyOwner) ~= Players.LocalPlayer.UserId then
            SetDockState('Maps', false)

            return
        end

        SetDockState('Maps', not States.Maps)
    end)


    AnimatePlateHover(MissionDock.MapPlate)
    AnimatePlateHover(MissionDock.TeamPlate)
    AnimatePlateHover(MissionDock.CompanionPlate.Companion, MissionDock.CompanionPlate.Button)

    --
    MissionDock.Play.Button.MouseButton1Click:Connect(HandlePlayButton)

    Component:GetScope():Observer(States.OwnedAgents):onChange(function()
        local Agents = Component:Peek(States.OwnedAgents)

        for _, Item in Frame.Agents.List:GetChildren() do
            if Item:IsA("Frame") then
                Item:Destroy()
            end
        end

        for _, Agent in Agents do
            AddAgentObject(Agent.Name, Agent.Level)
        end
    end)

    local WritingBox = MissionDock.PlayerInvitedName :: TextBox
    WritingBox.FocusLost:Connect(function(EnterPressed)
        if EnterPressed then
            HandleInvite()
        end
    end)

    MissionDock.Invite.Button.MouseButton1Click:Connect(HandleInvite)

    Component:BindToStateChange(function(State: boolean)
        if State then
            Navigation:Set("CanInteract", false)
            local Data = Fetcher:FetchAgents()
            States.OwnedAgents:set(Data)
        else
            Navigation:Set("CanInteract", true)
            SetDockState('Agents', false)
            SetDockState('Maps', false)
        end

        --
        Frame.Visible = true

        SetDockState('Mission', State)
        UpdateTeamPreviews()

        Effects:Tween(Frame.Background, { 0.3, 'Quad' }, { BackgroundTransparency = State and 0.45 or 1 })
    end)
end

function Component:IsInParty()
    return Component:IsActive()
end

function Component:CreateParty()
    ShowStageInfo("")

    return RequestPartyCreation()
end

function Component:SetPartyOwner(Id: number)
    States.CurrentPartyOwner:set(Id)
end

function Component:RemoveReady()
    States.IsReady = false
    ChangePlayButtonState()
end

function Component:AddPlayerToList(ID: number)
    States.PlayerCount:set(Component:Peek(States.PlayerCount) + 1)
    ChangePlayButtonState()
    
    return AddPlayerToList(ID)
end

function Component:UpdateStageInfo(CodeStage: string)
    return ShowStageInfo(CodeStage)
end

function Component:ShowRewards(List: {})
    ShowRewards(List)
end

function Component:RemovePlayerFromlist(ID: number)
    States.PlayerCount:set(Component:Peek(States.PlayerCount) - 1)
    ChangePlayButtonState()

    return RemovePlayer(ID)
end

function Component:UpdateStages(Table: {})
    return UpdateStages(Table)
end

function Component:UpdateMissions(Table: {})
    return UpdateMissions(Table)
end

function Component:SetPlayerReady(ReadyCount: number)
    States.TotalReady:set(ReadyCount)

    if ReadyCount <= 0 then
        States.IsReady = false
    end

    ChangePlayButtonState()
end

function Component:SetQueueing(State: boolean)
    States.Queueing:set(State)

    ChangePlayButtonState()
end

function Component:Clear()
    return ClearParty()
end

return Component