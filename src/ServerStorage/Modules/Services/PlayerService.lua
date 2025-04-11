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

local Places = require(Shared.Places)

local Messages = require(Modules.Packages.Messages)

--
local Service = {}

function Service:Init(): ()
	Notifications:Init()
	Service:SetupStarterPlayer()

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

function Service.PlayerAdded(Player: Player): ()
	if not RunService:IsStudio() then
		Messages:Post({Content = `{Player.Name} has joined the game!`, Title = "Player joined"})
	end

	if not Player:HasTag('Ping') then
		repeat task.wait()
		until Player:HasTag('Ping')
	end

	-- Initialize data before anything else
	DataService:AddPlayer(Player)
	DataService:UnlockAllAgents(Player)

	--
	if Places:CanFight() then
		Service:InitializeCharacters(Player)
	end
end

function Service.PlayerRemoving(Player: Player): ()
	PartyService:ClearPlayer(Player)

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
