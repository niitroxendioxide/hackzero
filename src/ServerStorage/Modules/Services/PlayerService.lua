--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Notifications = require(Modules.Packages.Notifications)
local TeamService = require(script.Parent.Combat.TeamService)
local PartyService = require(script.Parent.Lobby.PartyService)
local DataService = require(script.Parent.Data.DataService)
local SummonService = require(script.Parent.Items.SummonService)

local PlayerArtifactDataClass = require(script.Parent.Parent.Classes.Data.PlayerArtifactData)

local Places = require(Shared.Places)

local Messages = require(Modules.Packages.Messages)
local LastPlayerId = 0
local AvailableIds = {}

--
local Service = {}

function Service:Init(): ()
	Notifications:Init()
	Service:SetupStarterPlayer()

	for i = 1, 255 do
		table.insert(AvailableIds, i)
	end

	for _, Player in Players:GetPlayers() do
		task.spawn(Service.PlayerAdded, Player)
	end

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
	if Places:CanFight() then
		Service:InitializeCharacters(Player)
	end

	for i = 1, 1 do
		local NewArtifact = PlayerArtifactDataClass.randomize('Wristband', 'Rare', 15)

		DataService:AddArtifact(Player, NewArtifact)
	end

	--
	DataService:UpdatePlayerArtifacts(Player)
	SummonService:SyncBanner(Player)
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
