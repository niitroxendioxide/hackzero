--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared

local Replicator = require(Modules.Libraries.Replicator)
local AgentService = require(script.Parent.AgentService)
local EnemyService = require(script.Parent.EnemyService)
local ServerAgentClass = require(Modules.Classes.ServerAgent)
local Types = require(Shared.Types)

--
local Service = {
	__Characters = {} :: {[Player]: {Types.ServerAgentClass}},
}

function Service:Init()
	for _, Player in Players:GetPlayers() do
		Service.PlayerAdded(Player)
	end
	
	Players.PlayerAdded:Connect(Service.PlayerAdded)
	Players.PlayerRemoving:Connect(Service.PlayerRemoving)
end

function Service.PlayerAdded(Player: Player)
	Service.__Characters[Player] = {}
	
	if not Player:HasTag('Ping') then
		repeat task.wait() until Player:HasTag('Ping')
	end
	
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

function Service.PlayerRemoving(Player: Player)
	for _, Character in AgentService:GetCharacters(Player) do
		AgentService:RemoveAgent(Player, Character.Name)
	end
end

return Service
