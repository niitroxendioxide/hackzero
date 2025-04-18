--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Stages = require(Database.Stages)
local Signal = require(Shared.Utility.Signal)
local EnemyService = require(Modules.Services.Combat.EnemyService)

--
local EventClass = {}
EventClass.__index = EventClass

function EventClass.new(Stage: string, Act: string, Event: string)
    local self = setmetatable({}, EventClass)
    self.Finished = Signal.new()

    -- Privates
    self.__Stage = Stage
    self.__Act = Act
    self.__Event = Event
    self.__Current_Time = 0;
    self.__Current_Goals = {};
    self.__Current_State = {};

    return self
end

function EventClass.Start(self: Types.EventClass)
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)
    if EventData == nil then
        return
    end

    self.__Current_Wave_Thread = task.delay(EventData.TimeLimit or 7e25, function()
        self.__Current_Wave_Thread = nil
    end)

    --
    print("Started event:", self.__Event)

    for Goal, Value in EventData.Goal do
        local Default = typeof(Value) == "number" and 0 or ''

        self.__Current_State[Goal] = Default;
    end

    self.__Current_Goals = EventData.Goal

    --
    self:SummonEnemyWave(1)
end

function EventClass.SummonEnemyWave(self, WaveNumber: number)
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)
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

function EventClass.HasGoal(self: Types.EventClass, Type: Types.Stage_Objective): boolean
    return self.__Current_Goals[Type] ~= nil
end

function EventClass.UpdateProgress(self: Types.EventClass, GoalType: Types.Stage_Objective, Value: any)
    local Type = typeof(self.__Current_Goals[GoalType])
    if Type == "nil" or Type ~= typeof(Value) then
        print("Invalid type.", Type, GoalType, Value)

        return
    end

    if Type == "number" then
        self.__Current_State[GoalType] += Value
    elseif string.match(GoalType, "ReachPlace") then
        if GoalType == "ReachPlace" then
            self.__Current_State[GoalType] = Value
        else
            self.__Current_State[GoalType] = (self.__Current_State[GoalType] :: number? or 0) + 1
        end
    else
        self.__Current_State[GoalType] = Value
    end

    --
    for Goal, Value in self.__Current_State do
        if Value ~= self.__Current_Goals[Goal] then
            return
        end
    end

    self:Destroy()
end


function EventClass.Destroy(self: Types.EventClass)
    if self.__Current_Wave_Connection then
        self.__Current_Wave_Connection:Disconnect()
        self.__Current_Wave_Connection = nil
    end

    if self.__Current_Wave_Thread then
        task.cancel(self.__Current_Wave_Thread)
        self.__Current_Wave_Thread = nil
    end

    --
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)

    local Next_Stage = EventData.Finished(self:GetCorrectedState())

    self.Finished:Fire(Next_Stage)
end

function EventClass.GetCorrectedState(self: Types.EventClass)
    local State = {}

    for StateName, StateValue in self.__Current_State do
        if self.__Current_Goals[StateName] == StateValue then
            State[StateName] = true
        else
            State[StateName] = false
        end
    end

    print(State)

    return State
end

return EventClass
