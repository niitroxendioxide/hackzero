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

local Places = require(ReplicatedStorage.Modules.Shared.Places)
local LootService = require(script.Parent.LootService)
local NPCService = require(script.Parent.NPCService)
local Stages = require(ReplicatedStorage.Modules.Shared.Types.Stages)
local World = require(ReplicatedStorage.Modules.Shared.World)
local Map = require(ServerStorage.Modules.Libraries.Map)

local Network = require(Shared.Network)
local Targets = require(ServerStorage.Modules.Libraries.Targets)
local AgentService = require(ServerStorage.Modules.Services.Combat.AgentService)
local CompanionService = require(ServerStorage.Modules.Services.Combat.CompanionService)
local DataService = require(ServerStorage.Modules.Services.Data.DataService)
local ChaosControlService = require(ServerStorage.Modules.Services.Lobby.ChaosControlService)
local Rewards = require(ServerStorage.Modules.Services.Match.MatchService.Rewards)
local settings = require(ServerStorage.Modules[".testenv"].settings)
local GameEnum = require(Shared.GameEnum)

local MissionClass = require(Classes.Game.Mission)
local StageDatabase = require(Database.Stages)
local MissionDatabase = require(Database.Missions)
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
    __Mission_Data = nil,
}

function Service:Init()
    Network.new("Match", "Event")

    if not Places:CanFight() then
        return;
    end

    local MatchData = TeleportService:GetStageData()
    local MissionData = MatchData.Mission
    local TotalPlayers = MatchData.TotalPlayers
    local LoadedPlayers = 0

    local Success_Loading;
    if MissionData.Type == 'Mission' or MissionData.Type == 'Expedition' then
        Success_Loading = Service:CreateMap(MissionData.Stage, MissionData.Act)
    elseif MissionData.Type == 'ChaosControl' then
        Success_Loading = Service:CreateMap(MissionData.Stage)
    end

    if not Success_Loading then
        TeleportService:ReturnToLobby(Players:GetPlayers())

        return;
    end

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

        Network:Fire("Match", Player, GameEnum.MatchEvents.SetupStage, MissionData.Stage, MissionData.Act)
    end

    Service:Begin(MissionData.Stage, MissionData.Act)

    --
    Network:On("Match", Service.__HandleEvent)
end

function Service:End(Won: boolean)
    if not Service.__Active_Match or not Service.__Active_Match:IsFinished() then
        print('finished?!')

        return
    end

    ---
    print('hey whats up')

    local IsCustomMission = Service.__Mission_Data ~= nil
    local StageActData = if IsCustomMission then Service.__Mission_Data else StageDatabase:GetAct(Service.__Current_Stage, Service.__Current_Act)

    ---

    ---
    World:SetEndScreenMode(true)
    World:TweenSpeed(0.01, 2)

    --- Calculate and Spread completion info
    local List = {"B", "A", "S"}
    local Rank = Service.__Active_Match:ObtainMissionRank(Won);
    local RawRewards = StageActData.Completion.Rewards
    local CompletionRewards = {}
    local RankTier = table.find(List, Rank)
    
    for Tier, LetterRank in List do
        if Tier > RankTier or RawRewards[LetterRank] == nil then
            continue
        end

        for _, Object in RawRewards[LetterRank] do
            if ((Object.Type == 'Money' or Object.Type == 'Gold') or Object.Type == 'Gems') then
                local Edited = false
                for _, Item in CompletionRewards do
                    if Item.Type ~= Object.Type then continue end

                    Edited = true
                    Item.Amount += Object.Amount;
                end

                if Edited then
                    continue
                end  
            end

            table.insert(CompletionRewards, {Type = Object.Type, Amount = Object.Amount, Extra = Object.Extra})
        end
    end
    
    local MissionInformation  = TeleportService:GetStageData().Mission
    local MatchCompletionData = {
        Stage = {
            Type = MissionInformation.Type,
            Stage = MissionInformation.Stage,
            Act = MissionInformation.Act,
            Seed = MissionInformation.Seed or 0,
            Difficulty = 'Easy', -- MissionInformation.Difficulty,
        },
        WinStatus = Won and GameEnum.MatchResults.Victory or GameEnum.MatchResults.Loss,
        TotalDamage = AbilityService.__Total_Damage,
        Rank = Rank;
        Experience = StageActData.Completion.Experience,
    };

    for _, Player in Players:GetPlayers() do
        ChaosControlService:MarkCompletion(Player, MatchCompletionData)
    end

    Service.__Active_Match = nil

    Rewards:SpreadRewards(PlayersLibrary:GetAll(), CompletionRewards, MatchCompletionData)
end

function Service:CreateMap(Stage: string, Act: string): boolean
    local MapLoaded = Service:GenerateMap(Stage, Act)
    if not MapLoaded then
        return false
    end

    return true;
end

function Service:Begin(Stage: string, Act: string)
    local MissionData = TeleportService:GetStageData().Mission
    local Data = nil; 
    
    if MissionData.Type == 'Mission' then
        local StageData = StageDatabase:GetAct(Stage, Act)

        local MissionId = MissionData.Data.MissionId
        local MissionInfo = MissionDatabase:Get(MissionId)

        local WorldData = {
            Markers = StageData.Markers;
            Guide = MissionInfo.Triggers;
            Destructibles = MissionInfo.Destructibles;
            Completion = MissionInfo.Completion;
        }

        Network:FireForAll("Match", GameEnum.MatchEvents.SetMissionId, MissionId)

        Service.__Mission_Data = WorldData
        Data = WorldData;
    elseif MissionData.Type == 'ChaosControl' then
        Data = MissionData.Data
        Service.__Mission_Data = MissionData.Data
    elseif MissionData.Type == 'Expedition' then
        Data = StageDatabase:GetAct(Stage, Act)
    end

    if not Data and MissionData.Type == 'Mission' then
        warn('[MATCHSERVICE] Could not fetch stage data.')

        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    if Service.__Active_Match then
        return
    end

    local Difficulty = RunService:IsStudio() and settings.DIFFICULTY or GameEnum.Difficulties.Easy
    if Stage == 'Training' and not RunService:IsStudio() then
        Difficulty = GameEnum.Difficulties.Easy
    end

    Targets:SetDifficulty(Difficulty)

    --
    local ClientPayloadData = {}
    local AllPlayers = Players:GetPlayers()
    if #AllPlayers == 0 then
        warn('No players found. Match is debug')
        return
    end

    local Extra = MissionData.Type == 'Expedition' and Act or Data
    local Marker_Data = Map:SetupMarkers(Data.Markers)
    local MissionObject = MissionClass.new(MissionData.Type, Stage, Extra)
    Map:AssignCurrentMission(MissionObject)

    NPCService.__Stage = Stage
    NPCService.__Act = Act

    DestructibleService:SetupStage(Marker_Data.Destructibles, Data.Destructibles or {})
    LootService:SetupChests(Marker_Data.Chests)
    NPCService:SetupNPCS(Marker_Data.NPCS)

    Service.__Current_Stage = Stage
    Service.__Current_Act = Act
    Service.__Active_Match = MissionObject;

    if MissionData.Type == 'ChaosControl' then
        local WaveCount = 0;
        for _, _ in MissionData.Data.Enemies do
            WaveCount += 1;
        end

        ClientPayloadData = {
            TotalWaves = WaveCount,
        }
    end

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin, ClientPayloadData)

    MissionObject:Begin()

    --
    for _, Player in AllPlayers do
        local FirstAgent = AgentService:GetCurrentCharacter(Player)
        --local CompanionId = TeleportService:GetPlayerCompanionFromData(Player)
        local CompData = DataService:GetCompanions(Player, function(Companion): boolean 
            return true
        end, true)

        if CompData ~= nil then
            CompanionService:CreateCompanion(CompData, FirstAgent)
        end
    end

    --
    DestructibleService.StructureSetValuesEvent:Connect(function(Values: {[string]: any})
        for Key, Value in Values do
            local IsAddition = typeof(Value) == 'number' and (string.sub(Key, #Key, #Key) == "+")
            local CorrectedKey = IsAddition and string.sub(Key, 1, #Key - 1) or Key
            local CorrectedValue = IsAddition and (MissionObject:GetProgressValue(CorrectedKey) or 0) + Value or Value

            MissionObject:SetProgressValue(CorrectedKey, CorrectedValue)
        end
    end)

    MissionObject.Finished:Once(function(State: boolean)
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

function Service:GenerateMap(Stage: string, Act: string?): boolean
    local StageInformation = StageDatabase:GetStage(Stage)
    local ActInfo = Act and StageDatabase:GetAct(Stage, Act)
    if Act and ActInfo.AutoGenerate then
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
    elseif Type == GameEnum.MatchEvents.SingularPlayerLeave then
        local Result, Message = TeleportService:ReturnToLobby({Player})
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
