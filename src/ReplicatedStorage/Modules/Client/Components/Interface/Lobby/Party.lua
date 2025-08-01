local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local AgentModels = ReplicatedStorage.Assets.Characters.Agents
local Assets = ReplicatedStorage.Assets.Interface

local NavStates = require(ReplicatedStorage.Modules.Client.States.Navigation)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)
local Fetcher = require(Client.Libraries.Fetcher)

local UIGroups = require(Client.Libraries.UIGroups)
local StagesDatabase = require(Shared.Database.Stages)
local PartyComponent = ComponentClass.new("Party", "Lobby")

local Scope = PartyComponent:GetScope()

local States = {
    Agents = Scope:Value({}),
    Team = Scope:Value({}),
    CurrentPartyOwner = Scope:Value(0),
    Stage = Scope:Value("Earth"),
    PlayerCount = Scope:Value(0),
    ReadyCount = Scope:Value(0),
    Thread = nil,
}

--
type UnlockedStages = {[string]: {[string]: boolean}}
local THREADS = {}

--
local function RequestPartyCreation()
    --
    Network:Fire("Party", GameEnum.PartyManaging.Create)

    local Data = Fetcher:FetchAgents()
    States.Agents:set(Data)
end

local function RequestInvitePlayer(Player: string)
    Network:Fire("Party", GameEnum.PartyManaging.Invite, Player)
end

local function RequestPartyLeave(): ()
    States.Team:set({});
    PartyComponent:Set(false)
    Network:Fire("Party", GameEnum.PartyManaging.Leave)

    local Interactions = UIGroups:GetElementClass("Lobby", "Interactions")
    if not Interactions then
        return
    end

    local MainMenu = UIGroups:GetElementClass("Lobby", "MainMenu")
    if MainMenu then
        MainMenu:Set(true, true)
    end

    NavStates:Set('Movement_Locked', false)

    Interactions:FireLeaveSignal()
end

local function RequestMapChange(ActName: string): ()
    Network:Fire("Party", GameEnum.PartyManaging.ChangeStage, {"Mission", Scope.peek(States.Stage), ActName})
end

local function RequestPartyTeamUpdate(): ()
    Network:Fire("Party", GameEnum.PartyManaging.ChangeTeam, Scope.peek(States.Team))
end

local function RequestPartyStageBegin(): ()
    if States.Thread then
        task.cancel(States.Thread)
    end

    RequestPartyTeamUpdate()
    Network:Fire("Party", GameEnum.PartyManaging.Start)
end


local function SelectAgent(Name: string)
    local Selected = Scope.peek(States.Team)

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

    States.Thread = task.delay(.2, RequestPartyTeamUpdate)

    return States.Team:set(Selected)
end

local function AddPlayerToList(PlayerId: number, Team: string, IsOwner: boolean)
    local User = Players:GetPlayerByUserId(PlayerId)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.PlayerListObject:Clone()
    Object.PlayerName.Text = User.DisplayName
    Object.TeamCharacters.Text = Team
    Object.Name = PlayerId
    Object.QuitButton.Visible = false
    Object.Parent = Main.Players

    if not IsOwner and Player.UserId == Scope.peek(States.CurrentPartyOwner) then
        Object.QuitButton.Visible = true
    end

    return Object
end

local function AddAgentToList(Agent: string, Level: number)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.CharacterListObject:Clone()
    Object.CharacterName.Text = Agent
    Object.CharacterLevel.Text = 'Lvl. ' .. Level
    Object.Name = Agent
    Object:SetAttribute("AgentName", Agent)
    Object.Parent = Main.Agents

    --
    local AgentModelBase = AgentModels:FindFirstChild(Agent) or AgentModels.Template
    if AgentModelBase then
        local Model = AgentModelBase:Clone()
        Model:PivotTo(CFrame.new())
        Model.Parent = Object.Viewport.World

        --
        local Camera = Instance.new("Camera")
        Camera.CFrame = CFrame.new(0, 1.75, -35) * CFrame.Angles(0, math.pi, 0)
        Camera.Parent = Object.Viewport.World
        Camera.FieldOfView = 5

        Object.Viewport.CurrentCamera = Camera
    end

    Object.Select.MouseButton1Click:Connect(function()
        SelectAgent(Agent)
    end)

    return Object
end


local function UpdatePlayerTeam(PlayerId: number, Team: string)
    local Main = PartyComponent:GetFrame()
    local PlayerObject = Main.Players:FindFirstChild(PlayerId) :: Frame

    if PlayerObject then
        PlayerObject.TeamCharacters.Text = Team
    end
end

local function RemovePlayer(PlayerId: number)
    local Main = PartyComponent:GetFrame()
    local PlayerObject = Main.Players:FindFirstChild(PlayerId) :: Frame

    if PlayerObject then
        PlayerObject:Destroy()
    end
end

local function ClearParty()
    local Main = PartyComponent:GetFrame()
    local PlayerList = Main.Players :: ScrollingFrame

    for _, Object in PlayerList:GetChildren() do
        if Object:IsA("Frame") then
            Object:Destroy()
        end
    end
end

local function SetStageInfoMode(State: boolean)
    local Frame = PartyComponent:GetFrame()

    if State then
        Frame.StageInfo.Size = UDim2.fromScale(0.466, 0.934)
        Frame.MapList.Visible = false
    else
        Frame.MapList.Visible = true
        Frame.StageInfo.Size = UDim2.fromScale(0.253, 0.934)
    end
end

local function UpdateStageInfo(CodeStage: string)
    local Frame = PartyComponent:GetFrame()
    if CodeStage == '' or #CodeStage < 1 then
        Frame.StageInfo.ActName.Text = "No Mission Selected"
        Frame.StageInfo.MapName.Text = "None"
        Frame.StageInfo.Description.Text = ""
        Frame.StageInfo.Difficulties.Visible = false
        Frame.StageInfo.Rewards.Visible = false
        Frame.StageInfo.DifficultyTitle.Visible = false
        Frame.StageInfo.RewardsTitle.Visible = false

        return
    end

    local Split = string.split(CodeStage, "/")
    local Stage = Split[2]
    local Act = Split[3]

    local StageInfo = StagesDatabase:GetStage(Stage)
    local ActInfo = StagesDatabase:GetAct(Stage, Act)

    Frame.StageInfo.Difficulties.Visible = true
    Frame.StageInfo.Rewards.Visible = true
    Frame.StageInfo.DifficultyTitle.Visible = true
    Frame.StageInfo.RewardsTitle.Visible = true


    Frame.StageInfo.ActName.Text = ActInfo.Name or Act
    Frame.StageInfo.MapName.Text = StageInfo.Name or Stage
    Frame.StageInfo.Description.Text = ActInfo.Description or `{Stage}'s mission. Codename {Act}. Information not provided for mission, so beware of possible catastrophes.`
end

local function OpenActSelection(Stage: string, Stages: UnlockedStages)
    local Frame = PartyComponent:GetFrame()
    local StageActs = StagesDatabase:GetAllActs(Stage)

    Frame.MapList.Visible = false
    Frame.ActList.Visible = true
    Frame.ActListBg.Visible = true
    Frame.ActListBg.MapLabel.Text = StagesDatabase:GetStage(Stage).Name

    for _, Act in Frame.ActList:GetChildren() do
        if Act:IsA("TextButton") then
            Act:Destroy()
        end
    end

    for ActName, Data in StageActs do
        local Object = Assets.Lobby.Party.ActButton:Clone()
        Object.Label.Text = Data.Name or ActName
        Object.Parent = Frame.ActList

        if Stages[Stage][ActName] ~= true then
            Object.Lock.Visible = true
            Object.BackgroundTransparency = 0.5
            Object.BackgroundColor3 = Color3.fromRGB(134, 134, 134)
            Object.Bg.ImageColor3 = Color3.fromRGB(0, 0, 0)
            Object.Bg.ImageTransparency = 0.5
            Object.Label.TextTransparency = 0.5
            Object.Label.UIStroke.Transparency = 0.5
            Object.UIStroke.Color = Color3.fromRGB(113, 113, 113)
            Object.UIStroke.Thickness = 1
            Object.UIGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            }
            Object.LayoutOrder = 999
        else
            Object.MouseButton1Click:Connect(function()
                Frame.MapList.Visible = true
                Frame.ActList.Visible = false
                Frame.ActListBg.Visible = false

                RequestMapChange(ActName)
            end)
        end
    end
end

local function UpdateStages(Unlocked: UnlockedStages)
    local Stages = StagesDatabase:GetAll()
    local Frame = PartyComponent:GetFrame()

    for _, obj in Frame.MapList:GetChildren() do
        if obj:IsA("Frame") then
            obj:Destroy()
        end
    end

    if not (Player.UserId == Scope.peek(States.CurrentPartyOwner)) then
        SetStageInfoMode(true)

        return
    end

    for StageName, StageData in Stages do
        local Object = Assets.Lobby.Party.MapObject:Clone()
        Object.Parent = Frame.MapList
        Object.ImageLabel.Image = StageData.Icon and 'rbxassetid://' .. StageData.Icon or "rbxassetid://118719541712234"
        Object.MapName.Text = StageData.Name

        if Unlocked[StageName] == nil then
            Object.ImageLabel.ImageTransparency = 0.5
            Object.Lock.Visible = true
            continue
        end

        Object.UIStroke.Transparency = 0

        Object.TextButton.MouseButton1Click:Connect(function()
            States.Stage:set(StageName)

            OpenActSelection(StageName, Unlocked)
        end)
    end
end

local function UpdateReadyCount(PlayerReadyId: number)
    local Frame = PartyComponent:GetFrame()
    local Ready = Scope.peek(States.ReadyCount)
    local Total = Scope.peek(States.PlayerCount)
    --local IsFull = Total == Ready
    --local IsLastOne = (Scope.peek(States.CurrentPartyOwner) == Player.UserId)

    if PlayerReadyId == Player.UserId then
        Frame.PlayButton.Visible = false
        Frame.CancelButton.Visible = true
    end

    Frame.PlayButton.TabLabel.Text = `Ready ({Ready}/{Total})`
    Frame.CancelButton.TabLabel.Text = `Ready ({Ready}/{Total})`
end

local function CancelReadyCount(PlayerCancelled: number)
    local Frame = PartyComponent:GetFrame()
    local Ready = Scope.peek(States.ReadyCount)
    local Total = Scope.peek(States.PlayerCount)

    if PlayerCancelled == Player.UserId then
        Frame.PlayButton.Visible = true
        Frame.CancelButton.Visible = false
    end

    Frame.PlayButton.TabLabel.Text = `Ready ({Ready}/{Total})`
    Frame.CancelButton.TabLabel.Text = `Ready ({Ready}/{Total})`
end

local function ShowQueueing(Map: string)
    local Split = string.split(Map, "/")
    local Frame = PartyComponent:GetFrame()
    local StageCustomName = StagesDatabase:GetStage(Split[2])

    SetStageInfoMode(true)

    Frame.Queueing.Visible = true
    Frame.Queueing.MissionQueueing.Text = `{StageCustomName.Name or Split[2]}: {Split[3]}`

    Frame.MapList.Visible = false
    Frame.PlayButton.Visible = false
    Frame.InviteButton.Visible = false
    Frame.CancelButton.Visible = false
    Frame.PlayerInvitedName.Visible = false
end

--
function PartyComponent:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Party", true)

    return Main
end


function PartyComponent:Init(): ()
    local Frame = self:GetFrame() :: Frame & {QuitButton: TextButton, PlayButton: TextButton}

    ScreenUtil:AdjustStrokes(self:GetFrame())

    Frame.QuitButton.MouseButton1Click:Connect(RequestPartyLeave)


    Frame.PlayButton.MouseButton1Click:Connect(function()
        if Frame.PlayButton:GetAttribute("State") == false then
            return
        end

        PartyComponent:SetButtonState("Play", false)
        RequestPartyStageBegin()
    end)

    Frame.InviteButton.MouseButton1Click:Connect(function()
        if Frame.PlayButton:GetAttribute("State") == false then
            return
        end

        PartyComponent:SetButtonState("Invite", false)
        task.delay(.5, PartyComponent.SetButtonState, PartyComponent, "Invite", true)

        --
        local Name = Frame.PlayerInvitedName.Text
        for _, OtherPlayer in Players:GetPlayers() do
            if (OtherPlayer.Name:lower()):match(Name:lower()) and OtherPlayer ~= Player then
                Name = OtherPlayer.Name
            end
        end

        RequestInvitePlayer(Name)
    end)

    Scope:Observer(States.Agents):onChange(function()
        local Agents = Scope.peek(States.Agents)

        for _, Item in Frame.Agents:GetChildren() do
            if Item:IsA("Frame") then
                Item:Destroy()
            end
        end

        for _, Agent in Agents do
            AddAgentToList(Agent.Name, Agent.Level)
        end
    end)

    Scope:Observer(States.Team):onChange(function()
        local TeamList = Scope.peek(States.Team)

        for _, ItemInstance in Frame.Agents:GetChildren() do
            if not ItemInstance:IsA("Frame") then continue end

            local Index = table.find(TeamList, ItemInstance:GetAttribute("AgentName"))
            if Index then
                Effects:Tween(ItemInstance.UIScale, {.25, 'Back'}, {Scale = 1})
                ItemInstance.Light.Visible = true
                ItemInstance.AgentId.Visible = true
                ItemInstance.AgentId.Label.Text = Index

                if THREADS[ItemInstance] then
                    continue
                end

                THREADS[ItemInstance] = task.spawn(function()
                    local Angle = 0

                    while true do
                        local Delta = task.wait()

                        Angle += Delta * math.pi
                        local Cos = math.cos(Angle)

                        ItemInstance.UIStroke.Thickness = ScreenUtil:GetStrokeSize(2 + Cos)
                    end
                end)
            else
                ItemInstance.AgentId.Visible = false
                Effects:Tween(ItemInstance.UIScale, {.25, 'Back'}, {Scale = 0.9})
                ItemInstance.Light.Visible = false

                if THREADS[ItemInstance] then
                    task.cancel(THREADS[ItemInstance])
                end

                THREADS[ItemInstance] = nil

                ItemInstance.UIStroke.Thickness = ScreenUtil:GetStrokeSize(1)
            end
        end

    end)
end

function PartyComponent:SetButtonState(ButtonName: string, State: boolean)
    local Frame = self:GetFrame() :: Frame

    local Button = Frame:FindFirstChild(ButtonName.."Button") :: TextButton
    if Button then
        local OriginalColor = Button:GetAttribute("OriginalColor") :: Color3
        if not OriginalColor then
            Button:SetAttribute("OriginalColor", Button.BackgroundColor3)
            OriginalColor = Button.BackgroundColor3
        end

        if State == false then
            local H, S, V = OriginalColor:ToHSV()
            Button.BackgroundColor3 = Color3.fromHSV(H, S * 0.7, V * 0.8)
        else
            Button.BackgroundColor3 = OriginalColor
        end

        Button:SetAttribute("State", State)
    end
end

function PartyComponent:Clear()
    return ClearParty()
end

function PartyComponent:UpdateStages(Data)
    return UpdateStages(Data)
end

function PartyComponent:CreateParty()
    UpdateStageInfo("")

    return RequestPartyCreation()
end

function PartyComponent:AddPlayerToList(ID: number, Team: string, IsOwner: boolean)
    States.PlayerCount:set(Scope.peek(States.PlayerCount) + 1)

    return AddPlayerToList(ID, Team, IsOwner)
end

function PartyComponent:UpdateTeam(ID: number, Team: string)
    return UpdatePlayerTeam(ID, Team)
end

function PartyComponent:RemovePlayerFromlist(ID: number)
    States.PlayerCount:set(Scope.peek(States.PlayerCount) - 1)

    return RemovePlayer(ID)
end

function PartyComponent:SetPlayerReady(Amount: number, PlayerReadyId: number)
    States.ReadyCount:set(Amount)

    return UpdateReadyCount(PlayerReadyId)
end

function PartyComponent:ShowQueueing(Map: string)
    return ShowQueueing(Map)
end

function PartyComponent:CancelReady(Amount: number, PlayerId: number)
    States.ReadyCount:set(Amount)

    return CancelReadyCount(PlayerId)
end

function PartyComponent:UpdateStageInfo(Data)
    return UpdateStageInfo(Data)
end

function PartyComponent:SetPartyOwner(Id: number)
    States.CurrentPartyOwner:set(Id)
end

return PartyComponent :: Types.UIComponent & {
    CreateParty: () -> (),
    AddPlayerToList: (self: Types.UIComponent, Name: string, Team: string) -> (),
    UpdateTeam: (self: Types.UIComponent, Name: string, Team: string) -> (),
}