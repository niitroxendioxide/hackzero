--
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Classes = Modules.Classes
local Services = Modules.Services

--local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local ServerAgentClass = require(Classes.Combat.ServerAgent)

local DataService = require(Services.Data.DataService)
local AgentService = require(Services.Combat.AgentService)
local EnemyService = require(Services.Combat.EnemyService)
local TeleportService = require(Services.Data.TeleportService)

--
local Service = {}

function Service:Create(Player: Player)
    local Team = TeleportService:GetPlayerTeamFromData(Player)

    for index, AgentData in Team do
        print(index, AgentData)
        local AgentDataClass = DataService:GetAgent(Player, AgentData.Name)
        local AgentInstance = ServerAgentClass.new(AgentDataClass.Name, AgentData.Level)

        AgentInstance:Init(Player.UserId)
        AgentService:AddAgent(Player, AgentInstance)

        if index == 1 then
            AgentInstance:SetActive(true)
        end
    end

    Player:AddTag("Loaded")
end

function Service:Sync(Player: Player)
    for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer == Player then continue end

		AgentService:Sync(OtherPlayer, Player)
	end

    EnemyService:LoadEnemies(Player)
end

function Service:Clear(Player: Player): ()
    for _, Character in AgentService:GetCharacters(Player) do
		AgentService:RemoveAgent(Player, Character.Name)
	end
end

return Service
