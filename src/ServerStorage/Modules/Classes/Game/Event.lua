--[[
    @niitroxendioxide 2025-07

    @class Event
    In charge of managing an event in the stage, can summon enemies, make areas, etc.
]]

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
local Replicator = require(Modules.Libraries.Replicator)
local EnemyService = require(Modules.Services.Combat.EnemyService)
local ServerCutscenesLibrary = require(Modules.Libraries.Cutscenes)

--
local function ReplicateEvent(Player: Player, EventName: string)
    local Obj = buffer.create(1 + #EventName)
    buffer.writeu8(Obj, 0, GameEnum.Replication.PlayEventDialogue)
    buffer.writestring(Obj, 1, EventName)

    Network:Fire("Replicate", Player, Obj)
end

--
local EventClass = {}
EventClass.__index = EventClass

EventClass.new = function(Stage: string, Act: string, Event: string)
    local self = setmetatable({}, EventClass)
    self.Finished = Signal.new()

    -- Privates
    self.__Finish_Status = false
    if typeof(Stage) == 'string' then
        self.__Stage = Stage
        self.__Act = Act
    end

    self.__Event = Event
    self.__Players = {};
    self.__Current_Time = 0;
    self.__Current_Goals = {};
    self.__Current_State = {};
    self.__Current_Barriers = {};
    self.__Current_Barrier_State = false;

    if typeof(Stage) == 'table' then
        self.__Is_Custom_Event = true;
        self.__Custom_Event_Data = Stage;
        self.__Custom_Event_Type = Act;
    end

    return self
end

function EventClass.Start(self: Types.EventClass, Trigger: BasePart?): (boolean, boolean)
    if self.__Finish_Status then
        return false, "Event is... finished?";
    end

    local EventData;
    if self.__Is_Custom_Event then
        EventData = self.__Custom_Event_Data
    else
        EventData = Stages:GetEvent(self.__Stage, self.__Act, self.__Event)
    end

    if EventData == nil then
        print('No event data for: ', self.__Stage, self.__Act, self.__Event)
        return false;
    end

    self.__Current_Wave_Thread = task.delay(EventData.TimeLimit or 7e25, function()
        self.__Current_Wave_Thread = nil
    end)

    --
    if EventData.Cutscene then
        local PlayersToUse = self:GetPlayerObjects()
        local OneLoaded = ServerCutscenesLibrary:AttemptGroup(PlayersToUse, EventData.Cutscene)

        OneLoaded:Wait()
    end

    local TotalGoals = 0;
    for Goal, Value in (EventData.Goal or {}) do
        local Default = typeof(Value) == "number" and 0 or ''

        TotalGoals += 1;
        self.__Current_State[Goal] = Default;
    end

    if EventData.Dialogue then
        for _, StagePlayer in self:GetPlayerObjects() do
            ReplicateEvent(StagePlayer, self.__Event)
        end

        if TotalGoals <= 0 and (typeof(EventData.Finished) == 'string' and EventData.Finished == 'End') then
            local ToWait = 0;
            for _, Dialogue in EventData.Dialogue do
                ToWait += (Dialogue.NextDialogue or 0)
            end

            task.wait(ToWait)
        end
    end

    if TotalGoals <= 0 and self.__Custom_Event_Type ~= "ChaosControl" then
        self:Destroy()

        return false, true
    end

    self.__Current_Goals = EventData.Goal

    --
    if #EventData.Enemies > 0 then
        if Trigger then
            self:CreateEventAreaModel(Trigger)
        end

        self:SummonEnemyWave(1, EventData, Trigger)

        return true;
    end

    return true
end

function EventClass.SetBarrierCollision(self: Types.EventClass, State: boolean)
    if not self.__Current_Barriers then
        return
    end

    self.__Current_Barrier_State = State

    for k, Object in self.__Current_Barriers do
        if k == 1 then
            Object.CanQuery = false
            continue
        end

        Object.CanQuery = State
    end


    for _, StagePlayer in self.__Players do
        local Team = StagePlayer:GetTeam()

        for _, Agent in Team do
            Agent:SetLimitArea(State and self.__Current_Barriers[1] or nil)
            Agent:SetColliderGroupEnabled(self.__Current_Barriers, State)
        end

        Replicator:SetColliderArea(StagePlayer:GetBase(), State, self.__Current_Barriers[1])
    end
end

function EventClass.CreateEventAreaModel(self: Types.EventClass, Trigger: BasePart)
    if #self.__Current_Barriers > 0 then
        self:SetBarrierCollision(true)

        return
    end

    self.__Current_Barriers = {Trigger}

    local SIZE_K = workspace.World.Map.Design:GetAttribute("Generated") and 1.1 or 1.25
    local Size = (Trigger:GetAttribute("AreaSize") or (Trigger.Size * SIZE_K)) :: Vector3
    local BaseOffset = CFrame.new(Trigger:GetAttribute("AreaOffset") or Vector3.new()) :: CFrame
    local Sizes = {
        Vector3.new(Size.X + 1, Size.Y + 15, 1), CFrame.new(0, 0, -Size.Z/2 - 1),
        Vector3.new(Size.X + 1, Size.Y + 15, 1), CFrame.new(0, 0, Size.Z/2 - 1),
        Vector3.new(1, Size.Y + 15, Size.Z + 1), CFrame.new(-Size.X/2 - 1, 0, 0),
        Vector3.new(1, Size.Y + 15, Size.Z + 1), CFrame.new(Size.X/2 - 1, 0, 0)
    }

    local Parent = workspace.Camera:FindFirstChild("Area_Colliders") or Instance.new("Folder")
	Parent.Name = "Area_Colliders"
	Parent.Parent = workspace.Camera

    for i = 1, #Sizes, 2 do
        local PartSize = Sizes[i]
        local Offset = Sizes[i + 1]

        local Part = Instance.new("Part")
        Part.Size = PartSize
        Part.CFrame = (Trigger:GetPivot() * BaseOffset) * Offset
        Part.Transparency = 0.8
        Part.Color = Color3.new(0.403922, 0.133333, 0.992157)
        Part.Name = Trigger.Name .. 'ColliderPart'
        Part.Anchored = true
        Part.CanQuery = false
        Part.Parent = Parent

        table.insert(self.__Current_Barriers, Part)
    end

    self:SetBarrierCollision(true)
end

function EventClass.SummonEnemyWave(self: Types.EventClass, WaveNumber: number, FromData: {}?, Trigger: BasePart?)
    local EventData = FromData or Stages:GetEvent(self.__Stage, self.__Act, self.__Event)
    local EnemyWaves = EventData.Enemies
    local EnemyBuffs = EventData.EnemyBuffs or {}
    local NextWaveTime = 0.5

    if #EnemyWaves <= 0 or WaveNumber > #EnemyWaves then
        self:SetBarrierCollision(false)

        return
    end

    Network:FireForAll("Match", GameEnum.MatchEvents.UpdateWave, WaveNumber)

    local Total = 0
    local CurrentWave = EnemyWaves[WaveNumber]

    for i = 1, #CurrentWave do
        local EnemyType = CurrentWave[i].Name
        local EnemyCount = CurrentWave[i].Amount
        local EnemyLevel = CurrentWave[i].Level

        Total += EnemyCount
        local NewBuffs = table.clone(EnemyBuffs)

        if CurrentWave[i].Affected_Aura == true then
            table.insert(NewBuffs, {'Affected_Aura'})
        end


        for i = 1, EnemyCount do
            EnemyService:Spawn(EnemyType, EnemyLevel, self.__Event, NewBuffs)
        end
    end

    if typeof(CurrentWave[#CurrentWave]) == 'number' then
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

            task.delay(NextWaveTime, self.SummonEnemyWave, self, WaveNumber + 1, FromData)
        end
    end)
end

function EventClass.HasGoal(self: Types.EventClass, Type: Types.Stage_Objective): boolean
    if not self.__Current_Goals then
        return false
    end

    return self.__Current_Goals[Type] ~= nil
end

function EventClass.UpdateProgress(self: Types.EventClass, GoalType: Types.Stage_Objective, Value: any)
    local Type = typeof(self.__Current_Goals[GoalType])
    if Type == "nil" or Type ~= typeof(Value) then
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

function EventClass.Destroy(self: Types.EventClass, Not_Finished: boolean)
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
    local EventData = if self.__Is_Custom_Event then self.__Custom_Event_Data 
        else Stages:GetEvent(self.__Stage, self.__Act, self.__Event)

    local CorrectedState = self:GetCorrectedState()
    local Next_Stage = typeof(EventData.Finished) == 'function' and EventData.Finished(self.__Current_State) or tostring(EventData.Finished)
    print(EventData)

    self:SetBarrierCollision(false)

    if Not_Finished then
        return;
    end

    self.__Finish_Status = true
    self.Finished:Fire(Next_Stage, CorrectedState)
end

function EventClass.AddPlayer(self: Types.EventClass, Player: Types.StagePlayer)
    if self.__Finish_Status then return end

    for _, OtherPlayer in self.__Players do
        if OtherPlayer:GetBase() == Player:GetBase() then
            return
        end
    end

    Network:Fire("Match", Player:GetBase(), GameEnum.MatchEvents.BeginEvent, self.__Event)

    if self.__Current_Barrier_State then
        local Team = Player:GetTeam()

        for _, Agent in Team do
            Agent:SetColliderGroupEnabled(self.__Current_Barriers, self.__Current_Barrier_State)
        end

        for _, Player in self.__Players do
            Replicator:SetColliderArea(Player:GetBase(), self.__Current_Barrier_State, self.__Current_Barriers[1])
        end

    end

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

function EventClass.GetCompletionValueAdditions(self: Types.EventClass)
    local EventData = if self.__Is_Custom_Event then self.__Custom_Event_Data 
        else Stages:GetEvent(self.__Stage, self.__Act, self.__Event)

    if not EventData then
        return {}
    end

    return (EventData.Complete or {})
end

return EventClass
