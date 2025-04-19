--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services
local Database = Shared.Database
local Assets = ReplicatedStorage.Assets
local World = workspace:WaitForChild("World")

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local MissionClass = require(Classes.Game.Mission)
local StageDatabase = require(Database.Stages)
local TeleportService = require(Services.Data.TeleportService);

--
local Service = {}

function Service:Init()
    Network.new("Match", "Event")

    local MatchData = TeleportService:GetStageData()
    local TotalPlayers = MatchData.TotalPlayers
    local LoadedPlayers = 0

    while LoadedPlayers < TotalPlayers do
        LoadedPlayers = 0

        for _, Player in Players:GetPlayers() do
            if Player:HasTag("Loaded") then
                LoadedPlayers += 1;
            end
        end

        task.wait()
    end

    for _, Player in Players:GetPlayers() do
        Network:Fire("Match", Player, GameEnum.MatchEvents.SetupStage, MatchData.Stage, MatchData.Act)
    end

    Service:Begin(MatchData.Stage, MatchData.Act)
end

function Service:End()

end

function Service:Begin(Stage: string, Act: string)
    local CouldLoadMap = Service:CreateMap(Stage)

    if not CouldLoadMap then
        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    --
    local MissionClass = MissionClass.new(Stage, Act)

    MissionClass:Begin()

    --
    MissionClass.Finished:Connect(function()
        TeleportService:ReturnToLobby(Players:GetPlayers())
    end)
end

function Service:CreateMap(Stage: string): boolean
    local StageInformation = StageDatabase:GetStage(Stage)
    local Map = Assets:WaitForChild("Maps") :: Folder
    local Split = string.split(StageInformation.Map, "/")

    for i = 1, #Split do
        Map = Map:FindFirstChild(Split[i])

        print(Map, Split[1])
        if Map == nil then
            return false
        end
    end



    --
    local NewMap = Map:Clone()

    for _, Object in NewMap:GetChildren() do
        if Object:IsA("Folder") then
            Object.Parent = World.Map
        end
    end

    return true
end

return Service
