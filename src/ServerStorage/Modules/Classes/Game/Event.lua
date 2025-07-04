--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types.Stages)
local Stages = require(Database.Stages)
local Signal = require(Shared.Utility.Signal)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local EnemyService = require(Modules.Services.Combat.EnemyService)
local CutscenesLibrary = require(Modules.Libraries.Cutscenes)

--
local EventClass = {}
EventClass.__index = EventClass

function EventClass.new(Stage: string, Act: string, Event: string)
    local self = setmetatable({}, EventClass)
    self.Finished = Signal.new()

    -- Privates
    self.__Finish_Status = false
    self.__Stage = Stage
    self.__Act = Act
    self.__Event = Event
    self.__Players = {};
    self.__Current_Time = 0;
    self.__Current_Goals = {};
    self.__Current_State = {};

    return self
end

function EventClass.Start(self: Types.EventClass)
    if self.__Finish_Status then
        return
    end

    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)
    if EventData == nil then
        return
    end

    self.__Current_Wave_Thread = task.delay(EventData.TimeLimit or 7e25, function()
        self.__Current_Wave_Thread = nil
    end)

    --
    if EventData.Cutscene then
        local PlayersToUse = self:GetPlayerObjects()
        local OneLoaded = CutscenesLibrary:AttemptGroup(PlayersToUse, EventData.Cutscene)

        OneLoaded:Wait()
    end

    local TotalGoals = 0;
    for Goal, Value in EventData.Goal do
        local Default = typeof(Value) == "number" and 0 or ''

        TotalGoals += 1;
        self.__Current_State[Goal] = Default;
    end

    if TotalGoals <= 0 then
        self:Destroy()

        return
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
    for i = 1, #CurrentWave, 3 do
        local EnemyType = CurrentWave[i]
        local EnemyCount = CurrentWave[i + 1]
        local EnemyLevel = CurrentWave[i + 2]

        Total += EnemyCount

        for i = 1, EnemyCount do
            EnemyService:Spawn(EnemyType, EnemyLevel, self.__Event)
        end
    end

    if #CurrentWave % 2 ~= 0 then
        NextWaveTime = CurrentWave[#CurrentWave]
    end

    local ClearedEnemies = 0
    self.__Current_Wave_Connection = EnemyService.EnemyDied:Connect(function(EnemyTag: string): ()
        if EnemyTag ~= self.__Event then return end

        self:UpdateProgress("KillEnemies", 1)

        ClearedEnemies += 1

        if ClearedEnemies >= Total then
            if self.__Current_Wave_Connection then
                self.__Current_Wave_Connection:Disconnect()
                self.__Current_Wave_Connection = nil
            end

            if (#EnemyWaves < WaveNumber + 1) then
                return
            end

            task.delay(NextWaveTime, self.SummonEnemyWave, self, WaveNumber + 1)
        end
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

    for _, Player in self.__Players do
        Network:Fire("Match", Player:GetBase(), GameEnum.MatchEvents.ProgressUpd, self.__Event, GoalType, self.__Current_State[GoalType])
    end

    --
    for Goal, Value in self.__Current_State do
        if Value ~= self.__Current_Goals[Goal] then
            return
        end
    end

    self:Destroy()
end

function EventClass.IsFinished(self: Types.EventClass)
    return self.__Finish_Status
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

    for _, Player in self.__Players do
        Network:Fire("Match", Player:GetBase(), GameEnum.MatchEvents.EndEvent, self.__Event)
    end

    --
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)

    local Next_Stage = EventData.Finished(self:GetCorrectedState())

    self.__Finish_Status = true
    self.Finished:Fire(Next_Stage)
end

function EventClass.AddPlayer(self: Types.EventClass, Player: Types.StagePlayer)
    if self.__Finish_Status then return end
    for _, OtherPlayer in self.__Players do
        if OtherPlayer:GetBase() == Player then
            return
        end
    end

    Network:Fire("Match", Player:GetBase(), GameEnum.MatchEvents.BeginEvent, self.__Event)

    table.insert(self.__Players, Player)
end

function EventClass.GetPlayerObjects(self: Types.EventClass): {Player}
    local List = {}
    for _, Player in self.__Players do
        table.insert(List, Player:GetBase())
    end
    return List
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

    return State
end

return EventClass
