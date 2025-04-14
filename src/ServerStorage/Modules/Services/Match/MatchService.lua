--
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Classes = Modules.Classes
local Services = Modules.Services

local MissionClass = require(Classes.Game.Mission)
local TeleportService = require(Services.Data.TeleportService);

--
local Service = {}

function Service:Init()
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

    Service:Begin(MatchData.Stage, MatchData.Act)
end

function Service:End()

end

function Service:Begin(Stage: string, Act: string)
    local MissionClass = MissionClass.new(Stage, Act)

    MissionClass:BeginEvent()
end


return Service
