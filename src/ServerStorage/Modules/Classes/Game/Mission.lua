--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Services = Modules.Services

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
    Create a new mission, there are a few variant parameters

    @param Type "Mission" or "ChaosControl"
    @param Stage The stage to take as reference.
    @param 'Act', can also be 'Data', for custom missions.

--]]
MissionClass.new = function(Type: string, Stage: string, Act: string | {}): Types.MissionClass
    local self = setmetatable({}, MissionClass)
    self.Finished = Signal.new()

    self.__Is_Finished = false
    self.__Active = false
    self.__Act = Act :: string;
    self.__Stage = Stage;
    self.__Current_Events = {};
    self.__Current_Active_Triggers = {};
    self.__Current_State = {};
    self.__Hooks = StageHandlers:Get(Stage, Act) or Mock

    if Type == 'ChaosControl' then
        self.__Is_Chaos_Control = true
        self.__Custom_Data = Act
    end

    return self
end

--
function MissionClass.Begin(self: Types.MissionClass)
    if self.__Active or self.__Is_Finished then
        return
    end

    self.__Active = true

    self.__Hooks:ExecuteHooks(GameEnum.StageHook.Begin)

    self:DetectAreaTriggers()
    self:BeginEvent("Begin", PlayersLibrary:GetAll())
end

function MissionClass.IsFinished(self: Types.MissionClass): boolean
    return self.__Is_Finished
end

function MissionClass.BeginEvent(self: Types.MissionClass, Event: string, Players: {Types.StagePlayer}, Replay_Event, Trigger: BasePart?)
    ---
    
    ---
    local EventData;
    local IsCustom = false;
    if Trigger and Trigger:HasTag("CustomObject") then
        IsCustom = true;
        EventData = MapCache:GetTriggerData(Event)
    elseif not Trigger and self.__Is_Chaos_Control then
        EventData = self.__Custom_Data[Event];
    else
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
        EventObject = EventClass.new(EventData, nil, Event)
    else
        EventObject = EventClass.new(self.__Stage, self.__Act, Event :: string)
    end

    if EventData.Global then
        local Rng = Random.new()
        local Area = GetTrigger(EventData.EventPlace);

        for _, Player in PlayersLibrary:GetAll() do
            if Area then
                local Size = Area.Size
                local Spot = Area:GetPivot()
                local Offset = CFrame.new(Rng:NextInteger(-Size.X/2, Size.X/2), 0, Rng:NextInteger(-Size.Z/2, Size.Z/2))

                AgentService:SnapTo(Player:GetBase(), Spot * Offset)
            end

            EventObject:AddPlayer(Player)
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

        if Next_Stage == "End" then
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
        self.__Hooks:ExecuteTrigger(GameEnum.StageHook.TriggerEnter, {
            Trigger = Trigger,
            Players = Players,
        })
    end

    local Success = EventObject:Start(Trigger)
    if Success == false then
        warn('Error on event: ', Event)
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

function MissionClass.Finish(self: Types.MissionClass)
    self.__Active = false
    self.__Is_Finished = true
    self.Finished:Fire(self.__Current_State)

    for _, Event in self.__Current_Events do
        if not Event:IsFinished() then
            Event:Destroy()
        end
    end
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