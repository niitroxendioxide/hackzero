local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local World = workspace:FindFirstChild("World")
local Assets = ReplicatedStorage.Assets
local Types = require(Shared.Types)
local _GameEnum = require(Shared.GameEnum)
local CharacterDatabase = require(Database.Characters)
local ComponentClass = require(Client.Classes.Interface)
local Fetcher = require(Client.Libraries.Fetcher)
local Cutscenes = require(Client.Libraries.Cutscenes)
local Camera = require(Client.Libraries.Camera)

--
local RoomLocations = World:FindFirstChild("LobbyCutscenes")
if RoomLocations then
    RoomLocations = RoomLocations:FindFirstChild("AgentsRoom").Used
end

--
local Component = ComponentClass.new(script.Name, 'Lobby', {KeyToBind = Enum.KeyCode.C}) :: Types.UIComponent
local States = {
    __Current_Model = nil,
    __Current_Agent = nil,
}

--
local function SwitchModel(Name: string)
    if States.__Current_Model then
        States.__Current_Model:Destroy()
    end

    local CharacterModel = Assets.Characters.Agents:FindFirstChild(Name)
    if CharacterModel then
        local Cloned = CharacterModel:Clone()
        Cloned.PrimaryPart.Anchored = true;
        Cloned:PivotTo(RoomLocations.CharacterPlace.CFrame)
        Cloned.Parent = World.Entities.Appearances

        States.__Current_Model = Cloned
    end
end

local function CreateAgentIcons(): ()
    local Frame = Component:GetFrame()

    for _, Obj in Frame.Agents.Holder:GetChildren() do
        if Obj:IsA("Frame") then
            Obj:Destroy()
        end
    end

    --
    local AgentsTable = Fetcher:FetchAgents()
    local LastAgent;

    for _, Agent in AgentsTable do
        local AgentName = Agent.Name
        local AgentIcon = Assets.Interface.Agents.AgentIcon:Clone()

        AgentIcon.Btn.MouseButton1Click:Connect(function()
            Component:SetInfo(Agent)
        end)

        AgentIcon.AgentName.Text = AgentName
        AgentIcon.Parent = Frame.Agents.Holder

        LastAgent = Agent;
    end

    Component:SetInfo(LastAgent)
end

--
function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("AgentMenu", true)

	return Main;
end

function Component:Init()
    --

    --
    Component:BindToStateChange(function(State: boolean)
        if State then
            Camera:MarkUsage("AgentMenu")

            CreateAgentIcons()

            --
        else
            Camera:FreeUsage()
        end
    end)
end

function Component:CheckAvailable(): boolean
    if Cutscenes:IsInCutscene() then
        return false
    end

    return true
end

function Component:SetInfo(AgentData: Types.ClientAgentData)
    States.__Current_Agent = AgentData.Name

    --
    local Frame = self:GetFrame()
    local AgentStats = CharacterDatabase:GetStatsAtLevel(AgentData.Name, AgentData.Level)
    local AgentInfo = CharacterDatabase:GetCharacterData(AgentData.Name)

    SwitchModel(AgentData.Name)

    Camera:TweenTo(RoomLocations.StatsTab.CFrame)

    --
    for _, Obj in Frame.Stats.ValuesArea.Holder:GetChildren() do
        if Obj:IsA("UIGridLayout") then continue end

        Obj:Destroy()
    end

    local Ignored = {"Penetration", "Jog_Speed", "Walk_Speed", "Sprint_Speed"}
    for Stat, Value in AgentStats do
        if table.find(Ignored, Stat) then continue end

        local NewFrame = Assets.Interface.Agents.Stats.Stat:Clone()
        NewFrame.StatName.Text = string.gsub(Stat, "_", " ")
        NewFrame.StatValue.Text = Value
        NewFrame.Parent = Frame.Stats.ValuesArea.Holder
    end

    --
    local AgentDataFrame = Frame.Stats.AgentData
    AgentDataFrame.AgentFaction.Text = AgentInfo.Faction
    AgentDataFrame.AgentFullName.Text = AgentInfo.Display_Name
    local Nickname = AgentInfo.Nickname
    local NewText = ""

    for i = 1, #Nickname do
        local TextChar = string.sub(Nickname, i, i)
        if TextChar == " " then
            TextChar = "   "
        end
        NewText = NewText..TextChar.." "
    end

    AgentDataFrame.AgentNickname.Text = NewText--AgentInfo.Nickname

    AgentDataFrame.Playstyle.Role.RoleName.Text = AgentInfo.Role
    AgentDataFrame.Playstyle.Element.ElementName.Text = AgentInfo.Element

    AgentDataFrame.Level.AgentLevel.Text = `Level: {AgentData.Level}/{math.ceil(AgentData.Level / 10) * 10}`
end

return Component
