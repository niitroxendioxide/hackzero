--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services
local Database = Shared.Database

local Types = require(ReplicatedStorage.Modules.Client.Libraries.Fusion.Types)
local LootService = require(script.Parent.LootService)
local Stages = require(ReplicatedStorage.Modules.Shared.Types.Stages)
local Map = require(ServerStorage.Modules.Libraries.Map)
local Network = require(Shared.Network)
local Targets = require(ServerStorage.Modules.Libraries.Targets)
local GameEnum = require(Shared.GameEnum)
local MissionClass = require(Classes.Game.Mission)
local StageDatabase = require(Database.Stages)
local PlayersLibrary = require(Modules.Libraries.Players)
local AbilityService = require(Services.Combat.AbilityService)
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
    local Rank = Won and List[math.random(1, #List)] or "X"

    local Raw_Rewards = Handler.Rewards.Items
    local Completion_Rewards = {}

    for _, Object in Raw_Rewards do
        table.insert(Completion_Rewards, {Object.Type, Object.Amount, Object.Extra})
    end

    local WinStatus = Won and GameEnum.MatchResults.Victory or GameEnum.MatchResults.Loss

    for _, StagePlayer in PlayersLibrary:GetAll() do
        local Items = table.clone(Completion_Rewards)
        print(StagePlayer:GetObtainedLoot())

        local PlayerEndResult = {
            Status = WinStatus,
            Rank = Rank,

            Stats = {
                Total_Damage = AbilityService.__Total_Damage
            },

            Items = Items,
        }

        Network:Fire("Match", StagePlayer:GetBase(), GameEnum.MatchEvents.MatchEnded, PlayerEndResult)
    end
end

function Service:Begin(Stage: string, Act: string)
    local CouldLoadMap = Service:CreateMap(Stage)
    local Data = StageDatabase:GetAct(Stage, Act)

    if not CouldLoadMap or not Data then
        warn('Could not fetch stage data.')

        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    Targets:SetDifficulty(GameEnum.Difficulties.Easy)

    local Marker_Data = Map:SetupMarkers(Data.Markers)

    --
    local MissionClass = MissionClass.new(Stage, Act)

    Service.__Current_Stage = Stage
    Service.__Current_Act = Act
    Service.__Active_Match = MissionClass;

    MissionClass:Begin()

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin)

    DestructibleService:SetupStage(Marker_Data.Destructibles)
    LootService:SetupChests(Marker_Data.Chests)

    --
    MissionClass.Finished:Connect(function(State: boolean)
        Service:End(State)
    end)

    --

    LootService.OnLootboxOpened:Connect(function(Player, Loot)
        local StagePlayerObject = PlayersLibrary:Get(Player) :: Stages.StagePlayer

        for ItemName, ItemData in Loot.Items do
            StagePlayerObject:AddLoot(ItemName, ItemData)
        end

        print(StagePlayerObject:GetObtainedLoot())
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
