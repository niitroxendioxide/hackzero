--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local ServerAgentClass = require(Classes.Combat.ServerAgent)
local StagePlayerClass = require(Classes.Game.Player)

local DataService = require(Services.Data.DataService)
local AgentService = require(Services.Combat.AgentService)
local EnemyService = require(Services.Combat.EnemyService)
local TeleportService = require(Services.Data.TeleportService)
local PlayersLibrary = require(Modules.Libraries.Players)
local Replicator = require(Modules.Libraries.Replicator)
local AgentDatabase = require(Shared.Database.Characters)

--
local Service = {}

function Service:Create(Player: Player)
    local Team = TeleportService:GetPlayerTeamFromData(Player)
    local Agents = {}

    for index, AgentData in Team do
        local AgentDataClass = DataService:GetAgent(Player, AgentData.Name)
        if AgentData.IsBorrowed then
            AgentDataClass = AgentData
        end

        local AgentInfo = AgentDatabase:GetMovesetData(AgentData.Name)
        local AgentInstance = ServerAgentClass.new(AgentDataClass.Name, AgentData.Level, AgentDataClass.Skills)

        if AgentDataClass.Drive then
            local DriveFromQuery = DataService:GetDrives(Player, function(DriveQuery)
                return DriveQuery.__Id == AgentDataClass.Drive
            end, true)

            AgentInstance:BindDrive(DriveFromQuery:ToData())
        end

        if AgentInfo and AgentInfo.Passive and AgentInfo.Passive.Meters then
            local Meters = AgentInfo.Passive.Meters

            for MeterName, Data in Meters do
                AgentInstance.__Status:CreateMeter(MeterName, Data)
            end
        end

        local ArtifactIds = Table:WriteValues(AgentDataClass.Artifacts)

        if #ArtifactIds > 0 then
            local Artifacts = DataService:GetArtifacts(Player, function(QueryArtifact)
                return table.find(ArtifactIds, QueryArtifact.__Id) ~= nil
            end)

            for _, Artifact in Artifacts do
                if typeof(Artifact) ~= 'table' or not Artifact.ToData or not Artifact.__Id then continue end

                AgentInstance:BindArtifact(Artifact:ToData())
            end
        end

        AgentInstance:Init(Player)
        AgentService:AddAgent(Player, AgentInstance)

        if index == 1 then
            AgentInstance:SetActive(true)
        end

        table.insert(Agents, AgentInstance)
    end

    --
    local PlayerClass = StagePlayerClass.new(Player, Agents)
    PlayersLibrary:Add(Player, PlayerClass)

    --
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

    Replicator:ClearPlayerData(Player)
end

return Service
