--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Services = Modules.Services

local Agents = require(ServerStorage.Modules.Libraries.Agents)
local MapCache = require(ServerStorage.Modules.Libraries.MapCache)
local Mock = require(Shared.Utility.Mock)
local Types = require(Shared.Types.Stages)
local Stages = require(Database.Stages)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Modules.Libraries.Hitbox)
local GameEnum = require(Shared.GameEnum)
local EventClass = require(script.Parent.Event)
local AgentService = require(Services.Combat.AgentService)
local StageHandlers = require(Modules.Libraries.StageHandlers)
local PlayersLibrary = require(Modules.Libraries.Players)

--
local function GetTrigger(Name: string?): BasePart?
    if Name == nil then return end

    local World = workspace:FindFirstChild("World") :: Folder
    local Map = World:FindFirstChild("Map")

    if Map:FindFirstChild("Triggers") then
        return Map.Triggers:FindFirstChild(Name)
    end

    return nil
end


--
local MissionClass = {}
MissionClass.__index = MissionClass

--[[
    Create a new mission.

    Takes a single config table (`Types.MissionConfig`) so Stage/Act stay Stage/Act no
    matter the mission type. The world data the mission runs on travels in `Data`, it used
    to be smuggled through the `Act` argument for custom missions, which meant
    `StageHandlers:Get(Stage, Act)` was handed a table and mission hooks never resolved.

    @param p_Config Type / Stage / Act / Data, plus the seed and rooms of a generated map.
]]
MissionClass.new = function(p_Config: Types.MissionConfig): Types.MissionClass
    local self = setmetatable({}, MissionClass)
    self.Finished = Signal.new()

    self.__Is_Finished = false
    self.__Active = false
    self.__Mission_Type = p_Config.Type
    self.__Stage = p_Config.Stage;
    self.__Act = p_Config.Act;
    self.__Custom_Data = p_Config.Data or {};
    self.__Seed = p_Config.Seed or 0;
    self.__Procedural = p_Config.Procedural == true;
    self.__Generated_Rooms = p_Config.Generated_Rooms or {};
    self.__Current_Events = {};
    self.__Current_Active_Triggers = {};
    self.__Current_State = {};
    self.__Hooks = p_Config.Hooks or StageHandlers:Get(p_Config.Stage, p_Config.Act) or Mock

    self.__Hooks:SetSeed(self.__Seed)

    return self
end

function MissionClass.GetHookPayload(self: Types.MissionClass, Extra: {[string]: any}?): {[string]: any}
    local Payload = {
        Seed = self.__Seed,
        Procedural = self.__Procedural,
        Rooms = self.__Generated_Rooms,
    }

    for Key, Value in (Extra or {}) do
        Payload[Key] = Value
    end

    return Payload
end


function MissionClass.GetSeed(self: Types.MissionClass): number
    return self.__Seed
end

function MissionClass.GetGeneratedRooms(self: Types.MissionClass): {Types.GeneratedRoom}
    return self.__Generated_Rooms
end

function MissionClass.IsProcedural(self: Types.MissionClass): boolean
    return self.__Procedural
end

function MissionClass.Begin(self: Types.MissionClass)
    if self.__Active or self.__Is_Finished then
        return
    end

    self.__Active = true

    self.__Hooks:ExecuteHooks(GameEnum.StageHook.Begin, self, self:GetHookPayload())

    self:DetectAreaTriggers()
    self:BeginEvent("Begin", PlayersLibrary:GetAll())
end

function MissionClass.IsFinished(self: Types.MissionClass): boolean
    return self.__Is_Finished
end

function MissionClass.GetProgressValue(self: Types.MissionClass, Key: string)
    return self.__Current_State[Key] 
end

function MissionClass.SetProgressValue(self: Types.MissionClass, Key: string, Value: number | boolean | any)
    self.__Current_State[Key] = Value
end

function MissionClass.BeginEvent(self: Types.MissionClass, Event: string, Players: {Types.StagePlayer}, Replay_Event, Trigger: BasePart?)
    ---
    local EventData;
    local IsCustom = true;
    if Trigger and Trigger:HasTag("CustomObject") then
        EventData = MapCache:GetTriggerData(Event)
    elseif self.__Mission_Type == 'Mission' then
        local Guide = self.__Custom_Data.Guide

        EventData = if Guide then Guide[Event] else self.__Custom_Data
    elseif self.__Mission_Type == 'Expedition' then
        IsCustom = false;
        EventData = Stages:GetEvent(self.__Stage, self.__Act, Event :: string)
    end

    if EventData == nil then
        return
    end

    if self.__Current_Events[Event] ~= nil then
        if not self.__Current_Events[Event]:IsFinished() then
            for _, Player in Players do
                self.__Current_Events[Event]:AddPlayer(Player)
            end
        end

        if not Replay_Event then
            return
        end

        self.__Current_Events[Event]:Destroy();
    end

    -- Start event
    local EventObject;
    if IsCustom then
        EventObject = EventClass.new(EventData, self.__Mission_Type, Event)
    else
        EventObject = EventClass.new(self.__Stage, self.__Act, Event :: string)
    end

    if EventData.Global then
        local Rng = Random.new()
        local Area = Trigger or GetTrigger(EventData.EventPlace);
        local ColliderParams = OverlapParams.new()
        ColliderParams.FilterType = Enum.RaycastFilterType.Include;

        for _, Player in PlayersLibrary:GetAll() do
            EventObject:AddPlayer(Player)

            if Area then
                local ActiveAgent = Agents:GetCurrentActive(Player:GetBase():GetAttribute('ReplicationId') :: number)
                ColliderParams.FilterDescendantsInstances = {ActiveAgent:GetHitbox()}

                if workspace:GetPartsInPart(Area, ColliderParams) then
                    continue
                end

                local Size = Area.Size
                local Spot = Area:GetPivot()
                local Offset = CFrame.new(Rng:NextNumber(-Size.X/2, Size.X/2), 0, Rng:NextNumber(-Size.Z/2, Size.Z/2))

                AgentService:SnapTo(Player:GetBase(), Spot * Offset)
            end
        end
    else
        for _, Player in Players do
            EventObject:AddPlayer(Player)
        end
    end

    EventObject.Finished:Once(function(Next_Stage: string, Data: {[string]: any})
        for Key, Value in Data do
            if self.__Current_State[Key] == nil then
                self.__Current_State[Key] = Value
            elseif typeof(Value) == 'number' then
                self.__Current_State[Key] += Value
            end
        end

        local Values = EventObject:GetCompletionValueAdditions();
        for Keys, AddedValue in Values do
            if typeof(AddedValue) == 'boolean' then
                self.__Current_State[Keys] = AddedValue
            elseif typeof(AddedValue) == 'number' then
                self.__Current_State[Keys] += AddedValue
            end
        end

        if (Next_Stage == "End" or Next_Stage == nil) then
            self:Finish()

            return
        elseif Next_Stage == "None" then
            return
        end

        local Is_Recursive = Next_Stage == Event
        self:BeginEvent(Next_Stage, Players, Is_Recursive, Is_Recursive and Trigger or nil)
    end)

    self.__Current_Events[Event] = EventObject

    if Trigger then
        self.__Hooks:ExecuteHooks(GameEnum.StageHook.TriggerEnter, self, self:GetHookPayload({
            Trigger = Trigger,
            Players = Players,
        }))
    end

    local Success, IsGoallessEvent = EventObject:Start(Trigger, self.__Current_State)
    if Success == false and not (IsGoallessEvent == true) then
        warn('Error on event: ', Event, "Errorcode:", IsGoallessEvent)
    end
end

function MissionClass.DetectAreaTriggers(self: Types.MissionClass)
    local World = workspace:FindFirstChild("World") :: Folder
    local Map = World:FindFirstChild("Map")

    if not Map:FindFirstChild("Triggers") then
        return
    end

    for _, Area in Map.Triggers:GetChildren() do
        self:AddTrigger(Area)
    end
end

function MissionClass.ObtainMissionRank(self: Types.MissionClass, Won: boolean)
    if not Won then
        return 'X'
    end
    
    if self.__Mission_Type == 'Expedition' then
        local EventData = Stages:GetAct(self.__Stage, self.__Act)
        local RewardsTable = EventData and EventData.Completion and EventData.Completion.Rewards;
        if RewardsTable and typeof(RewardsTable.Handler) == 'function' then
            return (RewardsTable.Handler(self.__Current_State) or 'B')
        end

        return 'S'
    end

    local Completion = self.__Custom_Data.Completion;
    if Completion and typeof(Completion.Handler) == 'function' then
        return (Completion.Handler(self.__Current_State) or 'B')
    end

    return 'S';
end

function MissionClass.AddTrigger(self: Types.MissionClass, Area: BasePart)
    self.__Hooks:ExecuteTrigger(Area.Name, Area)

    local TriggerDetectionThread = task.spawn(function()
        while true do
            Hitbox:ForAgentsInZone(Area.Size, Area.CFrame, function(Agent)
                local ReachPlace = false;

                for EventName, Event: Types.EventClass in self.__Current_Events do
                    if Event:HasGoal("ReachPlace") then
                        Event:UpdateProgress("ReachPlace", Area.Name)
                        ReachPlace = true

                        break
                    elseif Event:HasGoal("AllReachPlace") then
                        ReachPlace = true
                        Event:UpdateProgress("ReachPlace", Area.Name)
                    end
                end

                if not ReachPlace then
                    if self.__Current_Events[Area.Name] then
                        return;
                    end

                    self:BeginEvent(Area.Name, {PlayersLibrary:GetFromAgent(Agent) :: Types.StagePlayer}, false, Area)
                end
            end)

            task.wait(1/6)
        end
    end)

    table.insert(self.__Current_Active_Triggers, TriggerDetectionThread);
end

--[[
    Close the mission out.

    @param Won Whether the mission was completed, defaults to true. The win state is fired
           alongside the state table, it used to only fire the state table, which is
           always truthy and so read as a win even on a wipe.
]]
function MissionClass.Finish(self: Types.MissionClass, Won: boolean?)
    if self.__Is_Finished then
        return
    end

    self.__Active = false
    self.__Is_Finished = true
    self.__Won = Won ~= false

    for _, Event in self.__Current_Events do
        if not Event:IsFinished() then
            Event:Destroy()
        end
    end

    self:CleanUpTriggers()

    self.Finished:Fire(self.__Won, self.__Current_State)
end

function MissionClass.CleanUpTriggers(self: Types.MissionClass): ()
    for _, TriggerConnection: RBXScriptConnection | thread in self.__Current_Active_Triggers do
        if typeof(TriggerConnection) == "RBXScriptConnection" then
            TriggerConnection:Disconnect()
        elseif typeof(TriggerConnection) == "thread" then
            task.cancel(TriggerConnection)
        end
    end

    self.__Current_Active_Triggers = {}
end

function MissionClass.Sync(self: Types.MissionClass, Players: {Types.StagePlayer}, Type: number, ...): ()
    -- Should send to all clients the info about new event
    --[[for _, Player in Players do
        Network:Fire("Match", Player:GetBase(), Type, ...)
    end]]

    warn("This event dont rly do nun")
end

--

return MissionClass