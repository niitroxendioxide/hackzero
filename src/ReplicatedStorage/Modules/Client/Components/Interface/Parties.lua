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
local PartyComponent = ComponentClass.new("Parties", "Lobby")

local Scope = PartyComponent:GetScope()

local States = {
    Parties = Scope:Value({}),
    Selected = nil,
}


--
local function FetchParties()
    local PartiesFetched = Fetcher:FetchParties()
    States.Parties:set(PartiesFetched)

    PartyComponent:Set(true)
end

local function RequestJoinParty(Code: string): ()
    Network:Fire("Party", GameEnum.PartyManaging.Join, Code)
end

local function UpdatePartyInfo(Code: string, Owner: string)
    local Frame = PartyComponent:GetFrame()

    Frame.TitleCode.Visible = Code ~= ''
    Frame.Code.Visible = Code ~= ''
    Frame.Owner.Visible = Owner ~= ''

    Frame.Owner.Text = Owner
    Frame.Code.Text = Code
end

local function AddPartyToList(Code: string, Owner: string, PlayerCount: string, AverageLevel: number)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Partylist.PartyObject:Clone()
    Object.Code.Text = Code
    Object.PartyLeader.Text = Owner
    Object.PlayerCount.Text = "Players: "..PlayerCount
    Object.AverageLevel.Text = "Level avg. "..AverageLevel
    Object:SetAttribute("Code", Code)
    Object.Name = Code
    Object.Parent = Main.Parties

    Object.Select.MouseButton1Click:Connect(function()
        if States.Selected == Code then
            Object.SelectedStroke.Enabled = false
            States.Selected = nil

            UpdatePartyInfo('', '')

            return
        elseif States.Selected ~= Code and States.Selected ~= nil then
            local FoundObject = Main.Parties:FindFirstChild(States.Selected)

            if FoundObject then
                FoundObject.SelectedStroke.Enabled = false
            end
        end

        States.Selected = Code
        Object.SelectedStroke.Enabled = true

        UpdatePartyInfo(Code, Owner)
    end)

    return Object
end

--
function PartyComponent:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Parties", true)

    return Main
end


function PartyComponent:Init(): ()
    local Frame = self:GetFrame() :: Frame & {QuitButton: TextButton, PlayButton: TextButton}

    Frame.QuitButton.MouseButton1Click:Connect(function()
        PartyComponent:Set(false)
        local Interactions = UIGroups:GetElementClass("Lobby", "Interactions")
        if not Interactions or not Interactions.FireLeaveSignal then
            return
        end

        Interactions:FireLeaveSignal()
    end)


    Frame.JoinButton.MouseButton1Click:Connect(function()
        if Frame.JoinButton:GetAttribute("State") == false then
            return
        end

        if States.Selected == nil then return end

        RequestJoinParty(States.Selected)
    end)

    Scope:Observer(States.Parties):onChange(function()
        local Parties = Scope.peek(States.Parties)

        for _, Item in Frame.Parties:GetChildren() do
            if Item:IsA("Frame") then
                Item:Destroy()
            end
        end

        for _, Party in Parties do
            AddPartyToList(Party.Code, Party.Owner, Party.PlayerCount, Party.AverageLevel)
        end
    end)

    --[[Scope:Observer(States.Team):onChange(function()
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

    end)]]
end

function PartyComponent:LoadParties()
    return FetchParties()
end

return PartyComponent :: Types.UIComponent & {}