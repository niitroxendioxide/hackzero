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
local Service = {
    __Current_Stage = "",
    __Current_Act = "",
    __Active_Match = nil,
    __Total_Players = 0,
    __All_Loaded = false,
}

function Service:Init()
    Network.new("Match", "Event")

    local MatchData = TeleportService:GetStageData()
    local TotalPlayers = MatchData.TotalPlayers
    local LoadedPlayers = 0

    Service.__Total_Players = TotalPlayers

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

    --

    --
    Network:On("Match", Service.__HandleEvent)
end

function Service:End()
    if not Service.__Active_Match or not Service.__Active_Match:IsFinished() then
        return
    end

    ---
    local Handler = StageDatabase:GetAct(Service.__Current_Stage, Service.__Current_Act)


    ---
    local List = {"B", "A", "S"}
    local EndResult = {
        Status = GameEnum.MatchResults.Victory,
        Rank = List[math.random(1, #List)],
    }

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchEnded, EndResult)
end

function Service:Begin(Stage: string, Act: string)
    local CouldLoadMap = Service:CreateMap(Stage)

    if not CouldLoadMap then
        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    --
    local MissionClass = MissionClass.new(Stage, Act)

    Service.__Current_Stage = Stage
    Service.__Current_Act = Act
    Service.__Active_Match = MissionClass;

    MissionClass:Begin()

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin)

    --
    MissionClass.Finished:Connect(function()
        Service:End()
    end)
end

function Service:CreateMap(Stage: string): boolean
    local StageInformation = StageDatabase:GetStage(Stage)

    print(StageInformation, Stage)
    local Map = Assets:WaitForChild("Maps") :: Folder
    local Split = string.split(StageInformation.Map, "/")

    for i = 1, #Split do
        Map = Map:FindFirstChild(Split[i])

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

-- ## Private event
function Service.__HandleEvent(Player: Player, Type: number)
    print(GameEnum.KeyLookup(GameEnum.MatchEvents, Type))

    if Type == GameEnum.MatchEvents.RequestMatchLeave then
        local Result, Message = TeleportService:ReturnToLobby(Players:GetPlayers())
        if not Result then
            warn(Message)
        end
    elseif Type == GameEnum.MatchEvents.RequestMatchRepeat then
        local Result, Message = TeleportService:RepeatStage()
        if not Result then
            warn(Message)
        end
    elseif Type == GameEnum.MatchEvents.MarkClientLoaded then
        Player:AddTag("MapLoaded")
    end
end

return Service
