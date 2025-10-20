--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services
local Database = Shared.Database

local LootService = require(script.Parent.LootService)
local NPCService = require(script.Parent.NPCService)
local Stages = require(ReplicatedStorage.Modules.Shared.Types.Stages)
local Map = require(ServerStorage.Modules.Libraries.Map)
local MatchStats = require(ServerStorage.Modules.Libraries.MatchStats)
local Network = require(Shared.Network)
local Targets = require(ServerStorage.Modules.Libraries.Targets)
local AgentService = require(ServerStorage.Modules.Services.Combat.AgentService)
local CompanionService = require(ServerStorage.Modules.Services.Combat.CompanionService)
local AchievementService = require(ServerStorage.Modules.Services.Data.AchievementService)
local DataService = require(ServerStorage.Modules.Services.Data.DataService)
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
        if (RunService:IsRunMode()) then
            break
        end

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

    Service.__Active_Match = nil

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
        for _, Item in StagePlayer:GetObtainedLoot() do
            if Item.Type == "Gold" or Item.Type == "Gems" then
                local Found = false
                for _, ExistingItem in Items do
                    if ExistingItem[1] == Item.Type then
                        ExistingItem[2] += Item.Amount
                        Found = true
                    end
                end

                if Found then continue end
            end

            table.insert(Items, {
                Item.Type,
                Item.Amount,
                Item.Extra,
            })
        end

        local PlayerStats = {
            Total_Damage = AbilityService.__Total_Damage,
        }

        local BasePlayer: Player = StagePlayer:GetBase()
        for StatName, Value in (MatchStats:GetAllPlayerStats(BasePlayer) or {}) do
            PlayerStats[StatName] = Value
        end

        local Key = "Stats.TotalMissions"
        local TotalMissions = DataService:Get(BasePlayer, Key) or 0

        DataService:Set(BasePlayer, Key, TotalMissions + 1)
        AchievementService:Give(BasePlayer, "Beginner_Agent")


        local PlayerEndResult = {
            Status = WinStatus,
            Rank = Rank,

            Stats = PlayerStats,

            Items = Items,
        }

        Network:Fire("Match", StagePlayer:GetBase(), GameEnum.MatchEvents.MatchEnded, PlayerEndResult)
    end
end

function Service:Begin(Stage: string, Act: string)
    local CouldLoadMap = Service:CreateMap(Stage, Act)
    local Data = StageDatabase:GetAct(Stage, Act)

    if not CouldLoadMap or not Data then
        warn('Could not fetch stage data.')

        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    if Service.__Active_Match then
        return
    end

    Targets:SetDifficulty(GameEnum.Difficulties.Easy)

    local Marker_Data = Map:SetupMarkers(Data.Markers)

    --
    local AllPlayers = Players:GetPlayers()
    if #AllPlayers == 0 then
        warn('No players found. Match is debug')
        return
    end

    local MissionClass = MissionClass.new(Stage, Act)
    Map:AssignCurrentMission(MissionClass)

    Service.__Current_Stage = Stage
    Service.__Current_Act = Act
    Service.__Active_Match = MissionClass;

    MissionClass:Begin()

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin)

    NPCService.__Stage = Stage
    NPCService.__Act = Act

    DestructibleService:SetupStage(Marker_Data.Destructibles)
    LootService:SetupChests(Marker_Data.Chests)
    NPCService:SetupNPCS(Marker_Data.NPCS)


    --
    local RandomPlayer = AllPlayers[math.random(1, #AllPlayers)]
    local Companions = DataService:GetCompanions(RandomPlayer)
    local FirstAgent = AgentService:GetCurrentCharacter(RandomPlayer)

    CompanionService:CreateCompanion(Companions[1], FirstAgent)

    --
    MissionClass.Finished:Once(function(State: boolean)
        Service:End(State)
    end)

    --
    if not LootService.OnLootboxOpened then return end

    LootService.OnLootboxOpened:Connect(function(Player, Loot)
        local StagePlayerObject = PlayersLibrary:Get(Player) :: Stages.StagePlayer

        for ItemName, ItemData in Loot.Items do
            StagePlayerObject:AddLoot(ItemName, ItemData)
        end
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

function Service:CreateMap(Stage: string, Act: string): boolean
    local StageInformation = StageDatabase:GetStage(Stage)
    local ActInfo = StageDatabase:GetAct(Stage, Act)
    if ActInfo.AutoGenerate then
        return Map:Generate(StageInformation.Map, ActInfo.AutoGenerationData)
    end

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
