--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Notifications = require(Modules.Packages.Notifications)
local TeamService = require(script.Parent.Combat.TeamService)
local PartyService = require(script.Parent.Lobby.PartyService)
local ChatService = require(script.Parent.Lobby.ChatService)
local DataService = require(script.Parent.Data.DataService)
local SummonService = require(script.Parent.Items.SummonService)

local TeleportService = require(script.Parent.Data.TeleportService)
local Places = require(Shared.Places)

local Messages = require(Modules.Packages.Messages)
local LastPlayerId = 0
local AvailableIds = {}

--
local DataCache = {}
local function SyncPlayerDataWithOthers(Player: Player, AgentTeam: {}?, PlayerToSync: Player)
	if DataCache[Player] == nil and AgentTeam ~= nil then
		local AgentHashmap = AgentTeam[1]
		local BorrowedAgents = AgentTeam[2]

		local Agents = DataService:FetchAgents(Player)
		local Drives = DataService:FetchDrives(Player, function(Drive)
			if not Drive.__Equipped then return false end
			return AgentHashmap[Drive.__Equipped.Name]
		end)
		local Artifacts = DataService:FetchArtifacts(Player, function(Artifact)
			if not Artifact.__Equipped then return false end
			return AgentHashmap[Artifact.__Equipped.Name]
		end)

		for _, BorrowedAgent in BorrowedAgents do
			table.insert(Agents, BorrowedAgent)
		end

		DataCache[Player] = {Agents, Drives, Artifacts}
	end

	Network:Fire("SharedData", PlayerToSync, Player, DataCache[Player])
end

local function SavePlayerSettings(SettingsToChange: {[string]: number | boolean})
	
end

--
local Service = {}

function Service:Init(): ()
	Network.new("SharedData", 'Event')
	Network.new('PlayerSettings', 'Event')

	Notifications:Init()
	Service:SetupStarterPlayer()

	for i = 1, 255 do
		table.insert(AvailableIds, i)
	end

	for _, Player in Players:GetPlayers() do
		task.spawn(Service.PlayerAdded, Player)
	end

	Network:On("PlayerSettings", SavePlayerSettings)

	Players.PlayerAdded:Connect(Service.PlayerAdded)
	Players.PlayerRemoving:Connect(Service.PlayerRemoving)
end

function Service:SetupStarterPlayer(): ()
	if not Places:CanFight() then return end;

    local StarterCharacter = Assets:WaitForChild("Characters"):WaitForChild("StarterCharacter")
    StarterCharacter.Parent = StarterPlayer;

	StarterPlayer.LoadCharacterAppearance = false;
	StarterPlayer.EnableMouseLockOption = false;
	StarterPlayer.UserEmotesEnabled = false;
end

function Service:AssignId(Player: Player)
	local Id = AvailableIds[math.random(1, #AvailableIds)]
	local Index = table.find(AvailableIds, Id)

	if Index then
		table.remove(AvailableIds, Index)
	end

	Player:SetAttribute("ReplicationId", Id)
end

function Service:RemoveId(Player: Player)
	local PlayerId = Player:GetAttribute("ReplicationId")

	table.insert(AvailableIds, PlayerId)
end

function Service.PlayerAdded(Player: Player): ()
	LastPlayerId += 1

	Service:AssignId(Player)

	if not RunService:IsStudio() then
		Messages:Post({Content = `{Player.Name} has joined the game!`, Title = "Player joined"})
	end

	if not Player:HasTag('Ping') then
		repeat task.wait()
		until Player:HasTag('Ping')
	end

	-- Initialize data before anything else
	DataService:AddPlayer(Player)
	--DataService:UnlockAllAgents(Player)

	--
	ChatService:SetupChannels(Player)
	SummonService:SyncBanner(Player)
	DataService:SyncPlayerItems(Player)

	-- hi?
	if Places:CanFight() then
		for PlayerInCache in DataCache do
			SyncPlayerDataWithOthers(PlayerInCache, nil, Player)
		end

		--
		local Team = TeleportService:GetPlayerTeamFromData(Player)
		local Borrowed = {}
		local HashMap = {}
		for _, Agent in Team do
			if Agent.IsBorrowed then
				local Class = DataService:ConstructAgentDataClass(Agent)

				table.insert(Borrowed, Class:Compress())
			end

			HashMap[Agent.Name] = true
		end

		for _, NetPlayer in Players:GetPlayers() do
			SyncPlayerDataWithOthers(Player, {HashMap, Borrowed}, NetPlayer)
		end

		Service:InitializeCharacters(Player)
	end
end

function Service.PlayerRemoving(Player: Player): ()
	PartyService:ClearPlayer(Player)
	Service:RemoveId(Player)

	TeamService:Clear(Player)
	DataService:RemovePlayer(Player)
end

--
function Service:InitializeCharacters(Player: Player): ()
	Player:LoadCharacter()

	--
	TeamService:Create(Player)
	TeamService:Sync(Player)
end

return Service
