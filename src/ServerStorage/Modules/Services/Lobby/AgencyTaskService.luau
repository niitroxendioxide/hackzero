--[[
    @service AgencyTaskService
    @niitroxendioxide 2026-9
    
    System created to add tasks to players who talk to random agency npcs, this will prompt them with a new mission, a difficulty, and what they'd have to face
    
--]]
    
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const Shared = ReplicatedStorage.Modules.Shared;
const Modules = ServerStorage.Modules
const Services = Modules.Services

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
const Network = require(Shared.Network)
const GameEnum = require(Shared.GameEnum)
const Math = require(Shared.Utility.Math)
const DataService = require(Services.Data.DataService)
const TaskTypes = require(Shared.Types.Tasks)
const StageTypes = require(Shared.Types.Stages)

---
const Service = {
    Cache = {}
}

const TIER_VALUES = {
    ['S'] = NumberRange.new(3, 5),
    ['A'] = NumberRange.new(2, 3),
    ['B'] = NumberRange.new(1, 2),
}

export type Tier = keyof<typeof(TIER_VALUES)>

const REWARD_VALUES = {
    Gems = 15,
    Money = 1000,
    Artifact = Math:ValueSubOnMul(2),
    Drive = 0.34,
    Item = 0.75,
}

const TIER_REWARDS = {
    ['S'] = { 'Gems', 'Artifact', 'Drive', 'Money', 'Item' },
    ['A'] = { 'Money', 'Item' },
    ['B'] = { 'Money', }
} :: { [Tier]: { string } }

const function CreateRewards(_: Player, Generator: Random):  { [Tier]: { StageTypes.LootItem } }
    const LayeredRewards = table.freeze({ 
        ['S'] = {}, 
        ['B'] = {}, 
        ['A'] = {} 
    });

    for Tier, PossibleRewards in TIER_REWARDS do
        const ValueCount = if #PossibleRewards > 1 then Generator:NextInteger(1, #PossibleRewards) else 1
        const ClonedRewards = table.clone(PossibleRewards)

        for _ = 1, ValueCount do
            const ChosenReward = ClonedRewards[Generator:NextInteger(1, #ClonedRewards)]
            const TierValue = TIER_VALUES[Tier] :: NumberRange;
            const HitCount = Generator:NextInteger(TierValue.Min, TierValue.Max)
            const Amount = math.floor( REWARD_VALUES[ChosenReward] * HitCount );

            if ChosenReward == 'Gems' then
                table.remove(ClonedRewards);
            end

            local Added = false;
            for _, Item in LayeredRewards[Tier] do
                if (Item.Type == ChosenReward) then
                    Added = true;
                    Item.Amount += Amount

                    break
                end
            end
            
            if not Added then
                table.insert(LayeredRewards[Tier], { 
                    Type = ChosenReward,
                    Amount = Amount,
                    Extra = {},
                })
            end
        end
    end

    return LayeredRewards;
end

const function GetMissionLevel(Player: Player, Generator: Random): number
    const PlayerLevel = DataService:Get(Player, 'Level') or 1

    return Generator:NextInteger(math.max(PlayerLevel - 5, 5), math.min(PlayerLevel + 5, 99))
end

const function CreateEscortMission(Player: Player, Seed: number): TaskTypes.AgencyTaskMission
    ---
    const Generator = Random.new(Seed);
    const Level = GetMissionLevel(Player, Generator)
    const Rewards = CreateRewards(Player, Generator)
    
    return {
        Type = 'Escort',
        World = 'DungeonEx',
        Character = 'Agent',
        Level = Level,
        Rewards = Rewards,
    }
end

const function CreateRecoverMission(Player: Player,Seed: number): TaskTypes.AgencyTaskMission
    const Generator = Random.new(Seed);
    const Level = GetMissionLevel(Player, Generator)
    const Rewards = CreateRewards(Player, Generator)

    return {
        Type = 'Recover',
        World = 'DungeonEx',
        Item = 'Suitcase',
        Level = Level,
        Rewards = Rewards
    }
end

const function CreateRevengeMission(Player: Player,Seed: number): TaskTypes.AgencyTaskMission
    const Generator = Random.new(Seed);
    const Level = GetMissionLevel(Player, Generator)
    const Rewards = CreateRewards(Player, Generator)

    return {
        Type = 'Revenge',
        World = 'DungeonEx',
        Character = 'Sorcerer',
        Level = Level,
        Rewards = Rewards
    }
end

---
function Service:Init()
    Network.new("AgencyTasks", "Event")
    Network:On("AgencyTasks", function(Player: Player, ...)
        local Args = { ... };
        local Type : number = Args[1] :: number;
        local UUID : string = Args[2] :: string;

        if Type == GameEnum.AgencyTaskEvent.RetrieveInfoForUUID then
            Service:DistributeToPlayer(Player, UUID)
        elseif Type == GameEnum.AgencyTaskEvent.AcceptUUIDMission then
            Service:AcceptUUIDMission(Player, UUID)
        elseif Type == GameEnum.AgencyTaskEvent.RetrieveAllAccepted then
            local BuiltPacket = Service:RetrieveAllAcceptedMissions(Player)

            Network:Fire('AgencyTasks', Player, GameEnum.AgencyTaskEvent.RetrieveAllAccepted, BuiltPacket)
        end
    end)
end

function Service:ConstructProceduralDataFromUUID(UUID: string): StageTypes.ProceduralMissionData
    local Randomizer = Random.new(Math:ToSeedNumber(UUID))
    local TotalRooms = Randomizer:NextInteger(9, 17);
    local TotalExtent = math.floor(TotalRooms * 1.5 + Randomizer:NextInteger(5, 10))

    return { 
        Source = 'Rooms',
        Rooms = TotalRooms,
        Extent = TotalExtent,
        Infinite = false,
        Trail = 0,
    }
end

function Service:RetrieveUUIDMissionFromCache(Player: Player, UUID: number): (TaskTypes.AgencyTaskMission?)
    if not Service.Cache[Player] then
        return;
    end

    return Service.Cache[Player][UUID]
end

function Service:RetrieveAllAcceptedMissions(Player: Player)
    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData then
        Debugger:DebugLine("Service::RetrieveAllAcceptedMissions", "Returning empty packet, reason: Data Failed", 25)

        return {}
    end

    local MissionTable = {}
    for MissionUUID, Mission in (PlayerData.Tasks or {}) do
        if Mission.Completion.Status == true then
            continue
        end

        local MissionCache = Service:RetrieveUUIDMissionFromCache(Player, MissionUUID)
        if not MissionCache then
            MissionCache = Service:CreateRandomFromUUID(Player, MissionUUID)
        end

        table.insert(MissionTable, MissionCache)
    end

    return MissionTable
end

function Service:AcceptUUIDMission(Player: Player, UUID: string)
    local MissionCache = Service:RetrieveUUIDMissionFromCache(Player, UUID)
    if MissionCache == nil then
        return
    end

    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData then
        Debugger:DebugLine("AgencyTaskService::AcceptUUIDMission", "PlayerData not initialized.", 1)

        return
    end

    if PlayerData.Tasks[UUID] ~= nil then
        Debugger:WarnLine(
            "AgencyTaskService::AcceptUUIDMission", 
            'Player already has this UUID assigned, user tried re-playing it, or an insanely weird bug happened', 
            5
        )
        
        return
    end

    PlayerData.Tasks[UUID] = {
        Id = UUID,
        Completion = {
            Status = false,
            Claimed = false,
        }
    }

    print("User accepted tasks:", PlayerData.Tasks)
end

function Service:CreateRandomFromUUID(Player: Player, UUID: string)
    if not Service.Cache[Player] then
        Service.Cache[Player] = {}
    end

    --
    local PlayerCache = Service.Cache[Player]
    if PlayerCache[UUID] then
        return PlayerCache[UUID]
    end

    local NumberedUUID = Math:ToSeedNumber(UUID);
    local Generator = Random.new(NumberedUUID);
    local Keys = {}; for Key in GameEnum.MissionKind do
        table.insert(Keys, Key)
    end

    local NewKey = Keys[Generator:NextInteger(1, #Keys)];
    local Value = GameEnum.MissionKind[NewKey];

    local CreatedMission: TaskTypes.AgencyTaskMission = nil;
    if Value == GameEnum.MissionKind.Escort then
        CreatedMission = CreateEscortMission(Player, NumberedUUID)
    elseif Value == GameEnum.MissionKind.Recover then
        CreatedMission = CreateRecoverMission(Player,NumberedUUID)
    elseif Value == GameEnum.MissionKind.Revenge then
        CreatedMission = CreateRevengeMission(Player,NumberedUUID)
    end

    CreatedMission.Seed = UUID;
    PlayerCache[UUID] = CreatedMission;

    return CreatedMission
end

function Service:DistributeToPlayer(Player: Player, UUID: string): ()
    local CreatedMission = Service:CreateRandomFromUUID(Player, UUID)
    
    Network:Fire('AgencyTasks', Player, GameEnum.AgencyTaskEvent.RetrieveInfoForUUID, {Id = UUID, Data = CreatedMission})
end

return Service