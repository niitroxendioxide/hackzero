--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared


local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local PartyService = require(Services.Lobby.PartyService)

----- Setting Up
local Service = {
    __Daily_Node_Count = 0;
    __Cache = {},
    __Enemies = {
        Bosses = {},
        Default = {},
    },
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

----- Public
function HandleEvent(Player: Player, Action: number, Type: number, ...)
    local Args = {...}
    if Action == GameEnum.ChaosControlAction.Fetch then
        if Type == GameEnum.ChaosControlTab.ApocalypseTower then
            local Floor = Args[1] :: number;
            local Stage = Args[2] :: number;
            local FloorData = Service:GetApocalypseTowerFloor(Floor)

            if FloorData[Stage] then
                --- here you fetch
                Network:Fire('ChaosControl', Player, Action, Type, FloorData[Stage])
            end
        end

    elseif Action == GameEnum.ChaosControlAction.Begin then

    elseif Action == GameEnum.ChaosControlAction.Amount then
        if Type == GameEnum.ChaosControlTab.DailyImprovement then
            Network:Fire('ChaosControl', Player, Action, Type, Service.__Daily_Node_Count)
        end
    end
end

----- Private
function Service:Init() 
    Network.new('ChaosControl', 'Event');
    Network:On("ChaosControl", HandleEvent)

    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local CurrentDaySeed = CurrentUnixDate.Day * 1000 + CurrentUnixDate.Day
    local DailyImprovementNodes = Random.new(CurrentDaySeed):NextInteger(2, 3)
    
    Service.__Daily_Node_Count = DailyImprovementNodes
    Service:GetDailyImprovementNode(1)
end


function Service:GetDailyImprovementNode(Node: number)
    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local CurrentNodeSeed = (CurrentUnixDate.Day + CurrentUnixDate.Month + CurrentUnixDate.Year) * 10 + Node
end


function Service:GetApocalypseTowerFloor(Floor: number): { [number]: { AgentBuffs: {}, EnemyBuffs: {}, Enemies: {} } }
    local CurrentUnixDate = DateTime.now():ToUniversalTime() :: UnixDate
    local OsDate = os.date("!*t")
    local WeekFromOrigin = (OsDate.yday // 7) + (CurrentUnixDate.Year - 2026) * 52

    if Service.__Cache[WeekFromOrigin + Floor] then
        return Service.__Cache[WeekFromOrigin + Floor]
    end

    local FloorData = {}
    
    for Stage = 1, 7 do
        local UniqueSeed = Random.new(WeekFromOrigin * 1000 + Floor + Stage);
        local AgentBuffCount = UniqueSeed:NextInteger(0, 2)
        local EnemyBuffCount = UniqueSeed:NextInteger(0, 2)

        FloorData[Stage] = {
            AgentBuffs = {},
            EnemyBuffs = {},
            Enemies = {},
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
            for _ = 1, EnemyCount do
                table.insert(CurrentWave, EnemyChosen)
            end
        end
    end

    Service.__Cache[WeekFromOrigin + Floor] = FloorData

    return FloorData
end


return Service 