--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Services = Modules.Services

local Types = require(Shared.Types)
local Stages = require(Database.Stages)
local Signal = require(Shared.Utility.Signal)

local EnemyService = require(Services.Combat.EnemyService)

--
local MissionClass = {}
MissionClass.__index = MissionClass

function MissionClass.new(Stage: string, Act: string): Types.MissionClass
    local self = setmetatable({}, MissionClass)
    self.Finished = Signal.new()

    self.__Act = Act;
    self.__Stage = Stage;
    self.__Current_Time = 0;
    self.__Current_Goals = {};
    self.__Current_Event = "";
    self.__Current_State = {};
    self.__Current_Wave_Thread = nil
    self.__Current_Wave_Connection = nil

    return self
end

--
function MissionClass.FinishEvent(self: Types.MissionClass, Types)
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Current_Event)

    local Next_Stage = EventData.Finished(self.__Current_State)

    if self.__Current_Wave_Connection then
        self.__Current_Wave_Connection:Disconnect()
        self.__Current_Wave_Connection = nil
    end

    if self.__Current_Wave_Thread then
        task.cancel(self.__Current_Wave_Thread)
        self.__Current_Wave_Thread = nil
    end

    if Next_Stage ~= "End" then
        self:BeginEvent(Next_Stage)
    else
        print("All players must leave!")
    end
end

function MissionClass.BeginEvent(self: Types.MissionClass, Event: string?)
    Event = Event or "Begin";

    local EventData = Stages:GetEvent(self.__Stage, self.__Act, Event :: string)
    if EventData == nil then
        return
    end

    self.__Current_Event = Event :: string;
    self.__Current_Wave_Thread = task.delay(EventData.TimeLimit or 7e25, function()
        self.__Current_Wave_Thread = nil

        self:FinishEvent()
    end)

    --
    print("Currently on event:", Event)

    for Goal, Value in EventData.Goal do
        local Default = typeof(Value) == "number" and 0 or ''

        self.__Current_State[Goal] = Default;
    end

    self.__Current_Goals = EventData.Goal

    --
    self:SummonEnemyWave(1)
end

function MissionClass.SummonEnemyWave(self: Types.MissionClass, WaveNumber: number)
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Current_Event)
    local EnemyWaves = EventData.Enemies
    local NextWaveTime = 0.5

    if #EnemyWaves <= 0 or WaveNumber > #EnemyWaves then
        return
    end

    local Total = 0
    local CurrentWave = EnemyWaves[WaveNumber]
    for i = 1, #CurrentWave, 2 do
        local EnemyType = CurrentWave[i]
        local EnemyCount = CurrentWave[i + 1]

        Total += EnemyCount

        for i = 1, EnemyCount do
            EnemyService:Spawn(EnemyType)
        end
    end

    if #CurrentWave % 2 ~= 0 then
        NextWaveTime = CurrentWave[#CurrentWave]
    end

    self.__Current_Wave_Connection = EnemyService.EnemiesCleared:Once(function(...: any): ()
        -- Switch to next wave
        self.__Current_Wave_Connection = nil

        self:UpdateProgress("KillEnemies", Total)

        if (#EnemyWaves < WaveNumber + 1) then
            return
        end

        task.delay(NextWaveTime, self.SummonEnemyWave, self, WaveNumber + 1)
    end)
end

function MissionClass.UpdateProgress(self: Types.MissionClass, GoalType: Types.Stage_Objective, Value: any)
    local Type = typeof(self.__Current_Goals[GoalType])
    if Type == "nil" or Type ~= typeof(Value) then
        return
    end

    if Type == "number" then
        self.__Current_State[GoalType] += Value
    else
        self.__Current_State[GoalType] = Value
    end

    --
    for Goal, Value in self.__Current_State do
        if Value ~= self.__Current_Goals[Goal] then
            return
        end
    end

    self:FinishEvent()
end

function MissionClass.Sync(self: Types.MissionClass): ()
    -- Should send to all clients the info about new event
end

--

return MissionClass