--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared


local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local DataService = require(Services.Data.DataService)
local PartyService = require(Services.Lobby.PartyService)
local EnemiesDatabase = require(Shared.Database.Enemies)

----- Setting Up
local AgentExperienceSeedOffset = 0;
local Service = {
    __Daily_Node_Count = 0;
    __Cache = {},
    __Enemies = {
        Bosses = {},
        Default = {},
    },
    __Nodes = {},
}


type UnixDate = {
    Day: number,
    Month: number,
    Year: number,
    Minute: number,
    Hour: number,
    Second: number
}

local Agent_Buffs = {
    {'ATK%', 10},
    {'ATK%', 15},
    {'Crit_DMG', 10},
    {'Crit_DMG', 20},
    {'Stun_DMG%', 10},
    {'Stun_DMG%', 20},
}

local Enemy_Buffs = {
    {'Health%', 250},
    {'Health%', 400},
    {'ATK%', 110},
    {'ATK%', 60},
    {'DEF%', 25},
    {'DEF%', 45},
    {'Daze%', 30},
    {'Daze%', 50},
    {'Daze_Resistance', 2},
    {'Daze_Resistance', 4},
}

local CompletionTemplate = {
    Rewards = {
        ['S'] = {
            {Type = 'Money', Amount = 5000},
        },
        ['A'] = {
            {Type = 'Money', Amount = 3000},
        },
        ['B'] = {
            {Type = 'Money', Amount = 2000},
        }
    },
}

----- Public
function SumUpTotalRewards(Player: Player, RewardList: { [string]: { {Type: string, Amount: number} } })
    local List = {}

    for Tier, Category in RewardList do
        for _, Object in Category do
            if Object.Type == 'Gems' or Object.Type == 'Money' then
                local Found = false;
                for _, Item in List do
                    if Item.Type == Object.Type then
                        Found = true;
                        Item.Amount += Object.Amount;
                    end
                end

                if not Found then
                    table.insert(List, {Type = Object.Type, Amount = Object.Amount})
                end
            else
                table.insert(List, Object)
            end
        end
    end

    return List
end


function HandleEvent(Player: Player, Action: number, Type: number, ...)
    local Args = {...}
    if Action == GameEnum.ChaosControlAction.Fetch then
        if Type == GameEnum.ChaosControlTab.ApocalypseTower then
            print('[IMPORTANT] Must get the floor data from DataService')

            local Floor = 1;
            local Stage = Args[1] :: number;    
            local FloorData = Service:GetApocalypseTowerFloor(Player, Floor)
            local Clone = Table.CopyDeep(FloorData[Stage])

            Clone.Rewards = SumUpTotalRewards(Player, Clone.Completion.Rewards)
            Clone.Completion = nil;

            if FloorData[Stage] then
                --- here you fetch
                Network:Fire('ChaosControl', Player, Action, Type, Clone)
            end
        elseif Type == GameEnum.ChaosControlTab.DailyImprovement then
            local _Seed, NodeData = Service:GetDailyImprovementNode(Player, Args[1] :: number)
            local Rewards = SumUpTotalRewards(Player, NodeData.Completion.Rewards)

            if NodeData then
                Network:Fire('ChaosControl', Player, Action, Type, {
                    AgentBuffs = NodeData.AgentBuffs,
                    EnemyBuffs = NodeData.EnemyBuffs,
                    Enemies = NodeData.Enemies,
                    Rewards = Rewards,
                })
            end
        end

    elseif Action == GameEnum.ChaosControlAction.Begin then
        CreatePartyForPlayer(Player, Type, Args)
    elseif Action == GameEnum.ChaosControlAction.Amount then
        if Type == GameEnum.ChaosControlTab.DailyImprovement then
            Network:Fire('ChaosControl', Player, Action, Type, Service.__Daily_Node_Count)
        end
    elseif Action == GameEnum.ChaosControlAction.Select then
        Service:SelectDailyImprovementReward(Player, Args[1], Args[2])
    end
end

function CreatePartyForPlayer(Player: Player, Type: number, Args: { number })
    local NodeId = Args[1] :: number
    local _Stage = Args[2] :: number

    print(Player, Type, Args)

    local PartyData = {
        Stage = {
            Stage = '',
            Act = 'Intro',
        },
        Data = {
            ChaosControlData = {
                Node = NodeId,
                Type = 'ApocalypseTower',
            },

            Completion = Table.CopyDeep(CompletionTemplate),
        }
    }

    if Type == GameEnum.ChaosControlTab.DailyImprovement then
        local SelectedReward = Service.__Nodes[Player] and Service.__Nodes[Player][NodeId]
        if not SelectedReward then
           return; 
        end

        local _, NodeData = Service:GetDailyImprovementNode(Player, NodeId)
        for Key, Data in NodeData do
            PartyData.Data[Key] = Data
        end

        PartyData.Stage.Stage = 'DailyImprovement'
        PartyData.Data.ChaosControlData.Type = 'DailyImprovement'
    end

    local Party = PartyService:CreateParty(Player)
    Party:SwitchStage('ChaosControl', PartyData.Stage.Stage, PartyData.Stage.Act)
    Party:SetData(PartyData)

    Network:Fire("Party", Player, GameEnum.PartyManaging.Create, Party:Compress(), PartyData)
end

----- Private
function Service:Init() 
    Network.new('ChaosControl', 'Event');
    Network:On("ChaosControl", HandleEvent)

    local AllEnemies = EnemiesDatabase:GetAllEnemyNames();
    for _, EnemyName in AllEnemies do
        local EnemyData = EnemiesDatabase:GetEnemyData(EnemyName)
        if EnemyData.RemoveFromChaosControl then
            continue
        end

        if EnemyData.Is_Boss then
            table.insert(Service.__Enemies.Bosses, EnemyName)
        else
            table.insert(Service.__Enemies.Default, EnemyName)
        end
    end

    ---
    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local CurrentDaySeed = CurrentUnixDate.Day * 1000 + CurrentUnixDate.Day
    local DailyImprovementNodes = Random.new(CurrentDaySeed):NextInteger(2, 3)
    
    Service.__Daily_Node_Count = DailyImprovementNodes
end


function Service:GetDailyImprovementNode(Player: Player, Node: number): (number, { AgentBuffs: {}, EnemyBuffs: {}, Enemies: { [number]: {} } })
    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local CurrentNodeSeed = (CurrentUnixDate.Day + CurrentUnixDate.Month + CurrentUnixDate.Year) * 10 + Node
    local NodeGenerator = Random.new(CurrentNodeSeed)

    local PlayerLevel = DataService:GetLevel(Player)
    local AgentBuffCount = NodeGenerator:NextInteger(0, 2)
    local EnemyBuffCount = NodeGenerator:NextInteger(0, 2)
    local NodeData = {
        AgentBuffs = {},
        EnemyBuffs = {},
        Enemies = {},
        Completion = Table.CopyDeep(CompletionTemplate),
    }

    table.insert(NodeData.Completion.Rewards['S'], {
        Type = 'Gems',
        Amount = 60,
    })

    for _ = 1, EnemyBuffCount do
        table.insert(NodeData.AgentBuffs, Enemy_Buffs[NodeGenerator:NextInteger(1, #Enemy_Buffs)])
    end

    for _ = 1, AgentBuffCount do
        table.insert(NodeData.EnemyBuffs, Agent_Buffs[NodeGenerator:NextInteger(1, #Agent_Buffs)])
    end

    local WaveCount = NodeGenerator:NextInteger(3, 4)
    for Wave = 1, WaveCount do
        NodeData.Enemies[Wave] = {};

        local CurrentWave = NodeData.Enemies[Wave]
        local IsBoss = Wave % 2 == 0;
        local EnemyList = Service.__Enemies.Default
        local EnemyCount = NodeGenerator:NextInteger(5, 9)

        if IsBoss then
            EnemyList = Service.__Enemies.Bosses
            EnemyCount = 1
        end

        local EnemyChosen = EnemyList[NodeGenerator:NextInteger(1, #EnemyList)]
        table.insert(CurrentWave, {
            Name = EnemyChosen,
            Amount = EnemyCount,
            Level = math.min(PlayerLevel, 70),
        })
    end

    return CurrentNodeSeed, NodeData
end

function Service:SelectDailyImprovementReward(Player: Player, Node: number, Reward: { Type: string, Name: string })
    local PlayerData = DataService:GetDataFor(Player);
    local CurrentNodeSeed = Service:GetDailyImprovementNode(Player, Node);
    local ChaosControlData = PlayerData.ChaosControl;

    if ChaosControlData.DailyImprovement[Node] then
        local NodeData = ChaosControlData.DailyImprovement[Node]
        if NodeData.IsCompleted and NodeData.NodeId == CurrentNodeSeed then
            return;
        end
    end

    if not Service.__Nodes[Player] then
        Service.__Nodes[Player] = {}
    end

    Service.__Nodes[Player][Node] = Reward;
end

function Service:GetAgentExperienceStage(Player: Player)
    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData.ChaosControl then
        return;
    end
    
    local CurrentFloorSeed = PlayerData.ChaosControl.AgentExperience.CurrentFloor + AgentExperienceSeedOffset;
    local Generator = Random.new(CurrentFloorSeed);

    local Upgrade = 1 + (CurrentFloorSeed // 100)
    local Difficulty = (CurrentFloorSeed - 100*Upgrade) // 15
    local FloorCombatData = {
        AgentBuffs = {},
        EnemyBuffs = {},
        Enemies = {},
        Completion = {
            Rewards = {
                ["S"] = {
                    {Type = "Money", Amount = 3000},
                    {Type = "Gems", Amount = 30},
                },
            }
        }
    };

    for WaveId = 1, Generator:NextInteger(2, 3) + Difficulty/3 do
        FloorCombatData.Enemies[WaveId] = {}

        local EnemyCount = Generator:NextInteger(math.max(2, Upgrade), 5 + Upgrade) * math.max(Difficulty/3, 1)
        local EnemyBuffCount = Generator:NextInteger(Upgrade // 3, Upgrade // 2 + 1)
        local AgentBuffCount = Generator:NextInteger(Upgrade // 2, 1 + Upgrade // 2)

        for _ = 1, EnemyBuffCount do
            table.insert(FloorCombatData.EnemyBuffs, Enemy_Buffs[Generator:NextInteger(1, #Enemy_Buffs)])
        end;

        for _ = 1, AgentBuffCount do
            table.insert(FloorCombatData.AgentBuffs, Agent_Buffs[Generator:NextInteger(1, #Agent_Buffs)])
        end;

        local EnemyTypes = Generator:NextInteger(1, math.clamp(EnemyCount, 1, math.min(4, #Service.__Enemies.Default)))
        local ChosenTypes = table.clone(Service.__Enemies.Default)

        local Remaining = EnemyCount
        for TypeId = 1, EnemyTypes do
            local ChosenId = Generator:NextInteger(1, #ChosenTypes)
            local ChosenName = ChosenTypes[ChosenId]
            local Amount = EnemyCount // EnemyTypes
            local EnemyLevel = math.min((WaveId + Difficulty) * 4 + Upgrade * 15, 70)
            if TypeId == EnemyTypes and (Remaining - Amount) == 1 then
                Amount = Remaining
            end

            Remaining -= Amount

            table.insert(FloorCombatData.Enemies[WaveId], {
                Name = ChosenName,
                Amount = Amount,
                Level = EnemyLevel,
            })

            table.remove(ChosenTypes, ChosenId)
        end
    end

    return FloorCombatData
end

function Service:GetApocalypseTowerFloor(Player: Player, Floor: number): { [number]: { AgentBuffs: {}, EnemyBuffs: {}, Enemies: {} } }
    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local OsDate = os.date("!*t")
    local WeekFromOrigin = (OsDate.yday // 7) + (CurrentUnixDate.Year - 2026) * 52

    if Service.__Cache[WeekFromOrigin + Floor] then
        return Service.__Cache[WeekFromOrigin + Floor]
    end

    local PlayerLevel = DataService:GetLevel(Player)
    local Completion = Table.CopyDeep(CompletionTemplate)
    local FloorData = {}

    table.insert(Completion.Rewards['S'], {
        Type = 'Gems',
        Amount = 20,
    })
    
    for Stage = 1, 7 do
        local UniqueSeed = Random.new(WeekFromOrigin * 1000 + Floor + Stage);
        local AgentBuffCount = UniqueSeed:NextInteger(0, 2)
        local EnemyBuffCount = UniqueSeed:NextInteger(0, 2)

        FloorData[Stage] = {
            AgentBuffs = {},
            EnemyBuffs = {},
            Enemies = {},
            Completion = Completion,
        }

        for _ = 1, EnemyBuffCount do
            table.insert(FloorData[Stage].AgentBuffs, Enemy_Buffs[UniqueSeed:NextInteger(1, #Enemy_Buffs)])
        end

        for _ = 1, AgentBuffCount do
            table.insert(FloorData[Stage].EnemyBuffs, Agent_Buffs[UniqueSeed:NextInteger(1, #Agent_Buffs)])
        end

        --- 
        local WaveCount = UniqueSeed:NextInteger(3, 4)
        for Wave = 1, WaveCount do
            FloorData[Stage].Enemies[Wave] = {};

            local CurrentWave = FloorData[Stage].Enemies[Wave]
            local IsBoss = Wave % 2 == 0;
            local EnemyList = Service.__Enemies.Default
            local EnemyCount = UniqueSeed:NextInteger(5, 9)

            if IsBoss then
                EnemyList = Service.__Enemies.Bosses
                EnemyCount = 1
            end

            local EnemyChosen = EnemyList[UniqueSeed:NextInteger(1, #EnemyList)]

            table.insert(CurrentWave, {
                Name = EnemyChosen,
                Amount = EnemyCount,
                Level = math.min(PlayerLevel, 70),
            })
        end
    end

    Service.__Cache[WeekFromOrigin + Floor] = FloorData

    return FloorData
end


return Service 