--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage:WaitForChild("Assets")

local AgentService = require(script.Parent.AgentService)
local EnemyService = require(script.Parent.EnemyService)
local ServerAgentClass = require(Modules.Classes.ServerAgent)
local Types = require(Shared.Types)
local Places = require(Shared.Places)

--
local Service = {
	__Characters = {} :: {[Player]: {Types.ServerAgentClass}},
}

function Service:Init(): ()
	Service:SetupStarterPlayer()

	for _, Player in Players:GetPlayers() do
		Service.PlayerAdded(Player)
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
	Service.__Characters[Player] = {}

	if not Player:HasTag('Ping') then
		repeat task.wait() 
		until Player:HasTag('Ping')
	end

	--
	if Places:CanFight() then
		Service:InitializeCharacters(Player)
	end
end

function Service.PlayerRemoving(Player: Player): ()
	for _, Character in AgentService:GetCharacters(Player) do
		AgentService:RemoveAgent(Player, Character.Name)
	end
end

--
function Service:InitializeCharacters(Player: Player): ()
	Player:LoadCharacter()

	--
	print("Hey!")
	local Characters = {'Goku', 'Template', 'Vegeta'}

	for i, Character in Characters do
		local NewClass = ServerAgentClass.new(Character, 60)
		NewClass:Init(Player.UserId)

		AgentService:AddAgent(Player, NewClass)

		if i == 1 then
			NewClass:SetActive(true)
		end

		table.insert(Service.__Characters[Player], NewClass)
	end

	--
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer == Player then continue end

		AgentService:Sync(OtherPlayer, Player)
	end

	EnemyService:LoadEnemies(Player)
end

return Service
