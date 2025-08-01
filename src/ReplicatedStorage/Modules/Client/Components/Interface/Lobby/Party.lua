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
    Thread = nil,
}

--
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

local function UpdateStages(Unlocked: {[string]: {[string]: boolean}})
    local Stages = StagesDatabase:GetAll()
    local Frame = PartyComponent:GetFrame()

    for _, obj in Frame.MapList:GetChildren() do
        if obj:IsA("Frame") then
            obj:Destroy()
        end
    end

    for StageName, StageData in Stages do
        local Object = Assets.Lobby.Party.MapObject:Clone()
        Object.Parent = Frame.MapList
        Object.MapName.Text = StageData.Name

        Object.TextButton.MouseButton1Click:Connect(function()
            States.Stage:set(StageName)

            -- change stuff here :v
        end)
    end
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
    return RequestPartyCreation()
end

function PartyComponent:AddPlayerToList(ID: number, Team: string, IsOwner: boolean)
    return AddPlayerToList(ID, Team, IsOwner)
end

function PartyComponent:UpdateTeam(ID: number, Team: string)
    return UpdatePlayerTeam(ID, Team)
end

function PartyComponent:RemovePlayerFromlist(ID: number)
    return RemovePlayer(ID)
end

return PartyComponent :: Types.UIComponent & {
    CreateParty: () -> (),
    AddPlayerToList: (self: Types.UIComponent, Name: string, Team: string) -> (),
    UpdateTeam: (self: Types.UIComponent, Name: string, Team: string) -> (),
}