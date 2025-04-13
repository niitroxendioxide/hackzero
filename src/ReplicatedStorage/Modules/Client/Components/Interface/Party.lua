local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)
local Fetcher = require(Client.Libraries.Fetcher)

local UIGroups = require(Client.Libraries.UIGroups)
local PartyComponent = ComponentClass.new("Party", "Lobby")

local Scope = PartyComponent:GetScope()

local States = {
    Agents = Scope:Value({}),
    Team = Scope:Value({}),
    Thread = nil,
}

--
local AGENT_SELECTED_COLOR = Color3.fromRGB(207, 237, 255)


--
local function RequestPartyCreation()
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
    UIGroups:GetElementClass("Lobby", "Interactions"):FireLeaveSignal()
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

    States.Thread = task.delay(1, RequestPartyTeamUpdate)

    return States.Team:set(Selected)
end

local function AddPlayerToList(PlayerId: number, Team: string)
    local User = Players:GetPlayerByUserId(PlayerId)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.PlayerListObject:Clone()
    Object.PlayerName.Text = User.DisplayName
    Object.TeamCharacters.Text = Team
    Object.Name = PlayerId
    Object.Parent = Main.Players

    return Object
end

local function AddAgentToList(Agent: string, Level: number)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.CharacterListObject:Clone()
    Object.CharacterName.Text = Agent
    Object.CharacterLevel.Text = Level
    Object.Name = Agent
    Object:SetAttribute("AgentName", Agent)
    Object.Parent = Main.Agents

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

            if table.find(TeamList, ItemInstance:GetAttribute("AgentName")) then
                ItemInstance.SelectedStroke.Enabled = true
                ItemInstance.BackgroundColor3 = AGENT_SELECTED_COLOR
            else
                ItemInstance.BackgroundColor3 = Color3.new(1,1,1)
                ItemInstance.SelectedStroke.Enabled = false
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

function PartyComponent:CreateParty()
    return RequestPartyCreation()
end

function PartyComponent:AddPlayerToList(ID: number, Team: string)
    return AddPlayerToList(ID, Team)
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