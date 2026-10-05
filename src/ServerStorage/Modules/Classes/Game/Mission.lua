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
local LootService = require(Services.Match.LootService)
local StageHandlers = require(Modules.Libraries.StageHandlers)
local PlayersLibrary = require(Modules.Libraries.Players)

--
local CHANGE_HOOKS = {
    Value = GameEnum.StageHook.ValueChanged,
    Event = GameEnum.StageHook.EventCompleted,
    Interaction = GameEnum.StageHook.Interaction,
}

local function GetTrigger(Name: string?): BasePart?
    if Name == nil then return end

    local World = workspace:FindFirstChild("World") :: Folder
    local Map = World:FindFirstChild("Map")

    if Map:FindFirstChild("Triggers") then
        return Map.Triggers:FindFirstChild(Name)
    end

    return nil
end

--[[
    Write a progress value without telling anyone yet. Callers batch their writes and flush
    once, so a watcher never sees half of a multi-key update.
]]
local function WriteValue(Mission: Types.MissionClass, Key: string, Value: any, Changes: {Types.MissionChange})
    local Previous = Mission.__Current_State[Key]
    Mission.__Current_State[Key] = Value

    if Previous ~= Value then
        table.insert(Changes, {Kind = 'Value', Key = Key, Value = Value, Previous = Previous})
    end
end

local function FlushChanges(Mission: Types.MissionClass, Changes: {Types.MissionChange})
    for _, Change in Changes do
        if Mission.__Is_Finished then
            return
        end

        Mission:__Notify(Change)
    end
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

    self.__Watchers = {};
    self.__Interactions = {};
    self.__Completed_Events = {};
    self.__Completed_Tags = {};

    for _, Watcher in (self.__Custom_Data.Watchers or {}) do
        table.insert(self.__Watchers, Watcher)
    end

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
    local Changes = {}
    WriteValue(self, Key, Value, Changes)

    FlushChanges(self, Changes)
end

--[[
    Apply a `SetValues` block, the shape destructibles and interactions carry.
    A key ending in '+' with a number adds to the current value instead of replacing it.
]]
function MissionClass.ApplySetValues(self: Types.MissionClass, Values: {[string]: any})
    local Changes = {}

    for Key, Value in Values do
        local IsAddition = typeof(Value) == 'number' and string.sub(Key, -1) == '+'
        local CorrectedKey = if IsAddition then string.sub(Key, 1, -2) else Key
        local CorrectedValue = if IsAddition then (self.__Current_State[CorrectedKey] or 0) + Value else Value

        WriteValue(self, CorrectedKey, CorrectedValue, Changes)
    end

    FlushChanges(self, Changes)
end

-- ## Watching

--[[
    Run `Watcher` on every change: a progress value changing, an event completing, an
    interaction being used. Returning a stage advances the mission, see `__Advance`.

    @return Unsubscribes the watcher.
]]
function MissionClass.Watch(self: Types.MissionClass, Watcher: Types.MissionWatcher): () -> ()
    table.insert(self.__Watchers, Watcher)

    return function()
        local Index = table.find(self.__Watchers, Watcher)
        if Index then
            table.remove(self.__Watchers, Index)
        end
    end
end

function MissionClass.__Notify(self: Types.MissionClass, Change: Types.MissionChange)
    if self.__Is_Finished then
        return
    end

    local HookType = CHANGE_HOOKS[Change.Kind]
    if HookType then
        self.__Hooks:ExecuteHooks(HookType, self, self:GetHookPayload({Change = Change}))
    end

    --- Every watcher sees the change before any of them gets to move the mission on.
    local Requested = {}
    for _, Watcher in table.clone(self.__Watchers) do
        local Ran, Result = pcall(Watcher, self, Change)

        if not Ran then
            warn("[Mission] Watcher errored on a", Change.Kind, "change:", Result)
        elseif typeof(Result) == 'string' then
            table.insert(Requested, Result)
        end
    end

    for _, Next in Requested do
        self:__Advance(Next)
    end
end

--[[
    Move the mission on from outside an event: 'End' closes it, 'None' / '' does nothing,
    anything else begins that Guide event. Beginning is spawned so a watcher or an
    interaction never waits on a cutscene, and asking for an event that is already running
    only adds players to it.
]]
function MissionClass.__Advance(self: Types.MissionClass, Next: string, Players: {Types.StagePlayer}?)
    if self.__Is_Finished or Next == 'None' or Next == '' then
        return
    end

    if Next == 'End' then
        self:Finish()

        return
    end

    task.spawn(self.BeginEvent, self, Next, Players or PlayersLibrary:GetAll())
end

function MissionClass.IsEventCompleted(self: Types.MissionClass, Event: string): boolean
    return (self.__Completed_Events[Event] or 0) > 0
end

--- Whether any event carrying `Tag` has completed, e.g. `HasCompletedTag('FinalBoss')`.
function MissionClass.HasCompletedTag(self: Types.MissionClass, Tag: string): boolean
    return (self.__Completed_Tags[Tag] or 0) > 0
end

function MissionClass.GetGuide(self: Types.MissionClass): {[string]: any}
    if self.__Mission_Type == 'Expedition' then
        local ActData = Stages:GetAct(self.__Stage, self.__Act)

        return (ActData and ActData.Guide) or {}
    end

    return self.__Custom_Data.Guide or {}
end

--[[
    Guide events that have not completed yet, including ones nobody has walked into.

    @param Tag Only events carrying this tag, so `#GetPendingEvents('Filler') == 0` reads
           as "every filler room was cleared".
]]
function MissionClass.GetPendingEvents(self: Types.MissionClass, Tag: string?): {string}
    local Pending = {}

    for Name, EventData in self:GetGuide() do
        if Tag and not table.find(EventData.Tags or {}, Tag) then
            continue
        end

        if not self:IsEventCompleted(Name) then
            table.insert(Pending, Name)
        end
    end

    return Pending
end

--[[
    Arena of a fight in progress that contains `Position`, nil when that spot is not
    mid-fight. Checked on X/Z only, so someone mid-jump or knocked up still counts as inside.
    Spatial on purpose: an agent's LimitArea is only set for whoever was in the room when
    the barriers went up.
]]
function MissionClass.GetCombatAreaAt(self: Types.MissionClass, Position: Vector3): Types.Arena?
    for _, Event in self.__Current_Events do
        local Arena = if Event:IsFinished() then nil else Event:GetCombatArea()
        if not Arena then
            continue
        end

        local Offset = Arena.CFrame:PointToObjectSpace(Position)
        if math.abs(Offset.X) <= Arena.Size.X / 2 and math.abs(Offset.Z) <= Arena.Size.Z / 2 then
            return Arena
        end
    end

    return nil
end

-- ## Interactions

--[[
    Pair the interaction markers `SetupMarkers` found with the data the mission declared
    for them, the same split `DestructibleService:SetupStage` takes.
]]
function MissionClass.RegisterInteractions(self: Types.MissionClass, Placed: {{Id: string, Part: BasePart}}?, Data: {[string]: Types.InteractionObject})
    for _, Object in (Placed or {}) do
        local InteractionData = Data[Object.Id]
        if not InteractionData then
            warn("[Mission] Interaction marker with no data:", Object.Id)

            continue
        end

        self.__Interactions[Object.Id] = {
            Id = Object.Id,
            Type = InteractionData.Type,
            Tag = InteractionData.Tag,
            Part = Object.Part,
            Data = InteractionData,
            Used = false,
            Uses = 0,
        }
    end
end

function MissionClass.GetInteraction(self: Types.MissionClass, Id: string): Types.PlacedInteraction?
    return self.__Interactions[Id]
end

function MissionClass.GetInteractions(self: Types.MissionClass, Type: string?, Tag: string?): {Types.PlacedInteraction}
    local List = {}

    for _, Interaction in self.__Interactions do
        if (Type == nil or Interaction.Type == Type) and (Tag == nil or Interaction.Tag == Tag) then
            table.insert(List, Interaction)
        end
    end

    return List
end

--[[
    Use an interaction: hand out its drops, apply its SetValues, tell the watchers, then
    resolve its `Finished` the way an event's is resolved.

    @return Whether it went through. False when the mission is not running, the id is
            unknown, or a single-use interaction was already used.
]]
function MissionClass.Interact(self: Types.MissionClass, Id: string, Player: Types.StagePlayer?): boolean
    local Interaction = self.__Interactions[Id]
    if not Interaction or not self.__Active or self.__Is_Finished then
        return false
    end

    local Data = Interaction.Data
    if Interaction.Used and Data.Once ~= false then
        return false
    end

    Interaction.Used = true
    Interaction.Uses += 1

    if Data.Drops and Player then
        LootService:GiveLootToPlayer(Player:GetBase(), Data.Drops, true)
    end

    if Data.SetValues then
        self:ApplySetValues(Data.SetValues)
    end

    self:__Notify({
        Kind = 'Interaction',
        Interaction = Id,
        Type = Interaction.Type,
        Tag = Interaction.Tag,
        Player = Player,
    })

    if self.__Is_Finished then
        return true
    end

    local Next = if typeof(Data.Finished) == 'function'
        then Data.Finished(self.__Current_State, Interaction)
        else Data.Finished

    if typeof(Next) == 'string' then
        self:__Advance(Next)
    end

    return true
end

-- ## Events

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
        local Changes = {}

        for Key, Value in Data do
            local Current = self.__Current_State[Key]

            if Current == nil then
                WriteValue(self, Key, Value, Changes)
            elseif typeof(Value) == 'number' then
                WriteValue(self, Key, Current + Value, Changes)
            end
        end

        local Values = EventObject:GetCompletionValueAdditions();
        for Keys, AddedValue in Values do
            if typeof(AddedValue) == 'boolean' then
                WriteValue(self, Keys, AddedValue, Changes)
            elseif typeof(AddedValue) == 'number' then
                WriteValue(self, Keys, (self.__Current_State[Keys] or 0) + AddedValue, Changes)
            end
        end

        --- Torn down by `Finish` rather than completed: nothing to record and nowhere to go.
        if self.__Is_Finished then
            return
        end

        self.__Completed_Events[Event] = (self.__Completed_Events[Event] or 0) + 1

        local Tags = EventObject:GetTags()
        for _, Tag in Tags do
            self.__Completed_Tags[Tag] = (self.__Completed_Tags[Tag] or 0) + 1
        end

        FlushChanges(self, Changes)

        self:__Notify({
            Kind = 'Event',
            Event = Event,
            Tags = Tags,
            Next = Next_Stage,
        })

        --- A watcher may have closed the mission out in response.
        if self.__Is_Finished then
            return
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
