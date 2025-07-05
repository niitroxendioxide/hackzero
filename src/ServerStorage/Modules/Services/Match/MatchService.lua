--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services
local Database = Shared.Database

local Map = require(ServerStorage.Modules.Libraries.Map)
local Network = require(Shared.Network)
local Targets = require(ServerStorage.Modules.Libraries.Targets)
local GameEnum = require(Shared.GameEnum)
local MissionClass = require(Classes.Game.Mission)
local StageDatabase = require(Database.Stages)
local TeleportService = require(Services.Data.TeleportService);
local DestructibleService = require(Services.Match.DestructibleService)

--
local Service = {
    __Current_Stage = "",
    __Current_Act = "",
    __Active_Match = nil,
    __Total_Players = 0,
    __All_Loaded = false,
    __Player_Status = {},
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
        Service:SetPlayerLifeStatus(Player, true)

        Network:Fire("Match", Player, GameEnum.MatchEvents.SetupStage, MatchData.Stage, MatchData.Act)
    end

    Service:Begin(MatchData.Stage, MatchData.Act)

    --
    Network:On("Match", Service.__HandleEvent)
end

function Service:End(Won: boolean)
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
    local Data = StageDatabase:GetAct(Stage, Act)

    if not CouldLoadMap or not Data then
        warn('Could not fetch stage data.')

        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    Targets:SetDifficulty('EASY')
    local Marker_Data = Map:SetupMarkers(Data.Markers)

    --
    local MissionClass = MissionClass.new(Stage, Act)

    Service.__Current_Stage = Stage
    Service.__Current_Act = Act
    Service.__Active_Match = MissionClass;

    MissionClass:Begin()

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin)

    DestructibleService:SetupStage(Marker_Data)

    --
    MissionClass.Finished:Connect(function(State: boolean)
        Service:End(State)
    end)
end

function Service:SetPlayerLifeStatus(Player: Player, State: boolean)
    Service.__Player_Status[Player] = State

    if State == false then
        local AllDead = true
        for _, OtherPlayerState in Service.__Player_Status do
            if OtherPlayerState == true then
                AllDead = false
            end
        end

        if not AllDead then return end

        Service:Lose()
    end
end

function Service:Lose()
    Service.__Active_Match:Finish(false)
end

function Service:CreateMap(Stage: string): boolean
    local StageInformation = StageDatabase:GetStage(Stage)

    return Map:Unpack(StageInformation.Map)
end

-- ## Private event
function Service.__HandleEvent(Player: Player, Type: number)
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
    elseif Type == GameEnum.MatchEvents.PlayerDied then
        Service:SetPlayerLifeStatus(Player, false)
    end
end

return Service
