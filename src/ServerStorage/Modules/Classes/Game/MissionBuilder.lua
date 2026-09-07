--[[
    @class MissionBuilder

    Handed to a world handler's `OnBuild` after the map has been generated but before
    anything has been laid out, so the handler can author a mission into the rooms that
    actually exist this run.

    Everything it rolls comes off the run seed, so the same seed produces the same map
    *and* the same mission inside it.

    A handler never touches markers or the Guide directly, it calls the Add* methods and
    MatchService takes `:Result()` from there.

    ```lua
    Handler:OnBuild(function(Builder)
        local Room = Builder:PickRoom()

        Builder:AddChest(Room, {{Type = 'Artifact', Amount = 1, Extra = {Name = 'Suitcase'}}})
        Builder:AddEvent(Room, {
            Objective = "Recover the suitcase",
            Goal = { ['KillEnemies'] = 3 },
            Enemies = { [1] = {{Name = 'SandShinobi', Level = 5, Amount = 3}} },
            Finished = 'End',
        })
    end)
    ```
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)

--
local MARKER_FOLDER = 'Markers'

local MissionBuilder = {}
MissionBuilder.__index = MissionBuilder

local function GetMarkerFolder(): Folder
    local Map = workspace:WaitForChild('World'):WaitForChild('Map')
    local Markers = Map:FindFirstChild(MARKER_FOLDER)

    if not Markers then
        Markers = Instance.new('Folder')
        Markers.Name = MARKER_FOLDER
        Markers.Parent = Map
    end

    return Markers
end

--[[
    @param p_Config
        Seed  - the run seed, every roll made here derives from it
        Kind  - the mission kind this build is for
        Data  - the mission's own payload, whatever the lobby put in it
        Rooms - every piece the generator placed, halls included
]]
MissionBuilder.new = function(p_Config: {
    Seed: number,
    Kind: string?,
    Data: {[string]: any}?,
    Rooms: {Types.GeneratedRoom}?,
}): MissionBuilder
    local self = setmetatable({}, MissionBuilder)

    self.__Seed = p_Config.Seed or 0
    self.__Kind = p_Config.Kind
    self.__Data = p_Config.Data or {}
    self.__Random = Random.new(self.__Seed)
    self.__Marker_Count = 0

    self.__Spawn_Room = nil
    self.__Rooms = {}
    self.__Available = {}

    for _, Room in (p_Config.Rooms or {}) do
        if Room.IsHall or not Room.Marker then
            continue
        end

        if Room.Id == 0 then
            self.__Spawn_Room = Room
            continue
        end

        table.insert(self.__Rooms, Room)
        table.insert(self.__Available, Room)
    end

    self.__Dialogues = nil
    self.__Markers = {}
    self.__Guide = {}
    self.__Destructibles = {}
    self.__Completion = nil

    return self
end

export type MissionEventEndFunction = (Event_State: {KillEnemies: number}, Mission_State: {[string]: any}) -> ()
export type MissionEvent = {
    Finished: MissionEventEndFunction,
    Goal: { [string]: any },
    Objective: string,
    Dialogue: { [number]: { Text: string, Speaker: string, NextDialogue: number }, },
    Enemies: {
        [number]: {
            [number]: { Name: string, Level: number, Amount: number, Extra: {}?, Affected_Aura: boolean? },
        }, 
    },
}

--[[
    Every method spelled out rather than inferred off the metatable, so autocomplete
    actually lists them where a builder is used.
]]
export type MissionBuilder = typeof(setmetatable({}, MissionBuilder)) & {
    __Seed: number,
    __Kind: string?,
    __Data: {[string]: any},
    __Random: Random,
    __Marker_Count: number,
    __Spawn_Room: Types.GeneratedRoom?,
    __Rooms: {Types.GeneratedRoom},
    __Available: {Types.GeneratedRoom},
    __Markers: {[string]: Types.Marker},
    __Guide: {[string]: any},
    __Destructibles: {[string]: any},
    __Completion: {[string]: any}?,
    __Dialogues: { [string]: {any} }?,

    -- Reading the run
    GetSeed: (self: MissionBuilder) -> (number),
    GetKind: (self: MissionBuilder) -> (string?),
    GetData: (self: MissionBuilder) -> ({[string]: any}),
    GetRandom: (self: MissionBuilder, p_Salt: number?) -> (Random),

    -- Rooms
    GetSpawnRoom: (self: MissionBuilder) -> (Types.GeneratedRoom?),
    GetRooms: (self: MissionBuilder) -> ({Types.GeneratedRoom}),
    GetAvailableCount: (self: MissionBuilder) -> (number),
    PickRoom: (self: MissionBuilder) -> (Types.GeneratedRoom?),
    PickRooms: (self: MissionBuilder, p_Amount: number) -> ({Types.GeneratedRoom}),
    PickFurthestRoom: (self: MissionBuilder) -> (Types.GeneratedRoom?),

    -- Placing
    AddEvent: (self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Event: MissionEvent) -> (boolean),
    SetBeginEvent: (self: MissionBuilder, p_Event: MissionEvent) -> (),
    AddNamedEvent: (self: MissionBuilder, p_Name: string, p_Event: MissionEvent) -> (),
    CreateMarkerPart: (self: MissionBuilder, p_Room: Types.GeneratedRoom, p_Name: string, p_Offset: CFrame?) -> (BasePart),
    AddNPC: (self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Name: string, p_Marker: {[string]: any}?, p_Offset: CFrame?) -> (string?),
    AddChest: (self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Items: {Types.LootItem}, p_Offset: CFrame?) -> (string?),
    AddDestructible: (self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Destructible_Id: string, p_Data: {[string]: any}?, p_Offset: CFrame?) -> (string?),
    SetCompletion: (self: MissionBuilder, p_Completion: {[string]: any}) -> (),

    -- Output
    Result: (self: MissionBuilder) -> ({[string]: any}),
    IsEmpty: (self: MissionBuilder) -> (boolean),
}

-- ## Reading the run

function MissionBuilder.GetSeed(self: MissionBuilder): number
    return self.__Seed
end

--- The mission kind this build is for, e.g. 'Recover'.
function MissionBuilder.GetKind(self: MissionBuilder): string?
    return self.__Kind
end

--- The mission's payload, whatever the lobby put in `Data`.
function MissionBuilder.GetData(self: MissionBuilder): {[string]: any}
    return self.__Data
end

--[[
    A `Random` off the run seed. Pass a different salt per independent roll so two
    unrelated decisions do not share a stream.
]]
function MissionBuilder.GetRandom(self: MissionBuilder, p_Salt: number?): Random
    if p_Salt == nil then
        return self.__Random
    end

    return Random.new(self.__Seed + p_Salt)
end

--- Where the players come in. Not handed out by `PickRoom`.
function MissionBuilder.GetSpawnRoom(self: MissionBuilder): Types.GeneratedRoom?
    return self.__Spawn_Room
end

--- Every room the generator placed, spawn and halls excluded.
function MissionBuilder.GetRooms(self: MissionBuilder): {Types.GeneratedRoom}
    return self.__Rooms
end

--- How many rooms are still unclaimed.
function MissionBuilder.GetAvailableCount(self: MissionBuilder): number
    return #self.__Available
end

--[[
    Claim a room at random. A room is only handed out once, so two objectives never land on
    top of each other.

    @return The room, or nil when they are all claimed.
]]
function MissionBuilder.PickRoom(self: MissionBuilder): Types.GeneratedRoom?
    if #self.__Available < 1 then
        return nil
    end

    local Index = self.__Random:NextInteger(1, #self.__Available)

    return table.remove(self.__Available, Index)
end

--- Claim several rooms. Returns fewer than asked for when the layout runs out.
function MissionBuilder.PickRooms(self: MissionBuilder, p_Amount: number): {Types.GeneratedRoom}
    local Picked = {}

    for _ = 1, p_Amount do
        local Room = self:PickRoom()
        if not Room then
            break
        end

        table.insert(Picked, Room)
    end

    return Picked
end

--[[
    Claim the room furthest from spawn, for whatever ends the mission.

    @return The room, or nil when they are all claimed.
]]
function MissionBuilder.PickFurthestRoom(self: MissionBuilder): Types.GeneratedRoom?
    if #self.__Available < 1 then
        return nil
    end

    local Origin = self.__Spawn_Room and self.__Spawn_Room.Marker.Position or Vector3.zero
    local BestIndex, BestDistance = 1, -1

    for Index, Room in self.__Available do
        local Distance = (Room.Marker.Position - Origin).Magnitude

        if Distance > BestDistance then
            BestIndex, BestDistance = Index, Distance
        end
    end

    return table.remove(self.__Available, BestIndex)
end

-- ## Placing things

--[[
    Turn a room into an event trigger.

    The room already has a marker part from the generator, so this only registers the
    marker entry and the Guide entry the mission reads when a player walks in.

    @param p_Room The room to attach to.
    @param p_Event Event data, same shape as a hand-authored `Triggers` entry.
]]

function MissionBuilder.AddEvent(self: MissionBuilder, p_Room: Types.GeneratedRoom, p_Event: MissionEvent): boolean
    if not p_Room or not p_Room.Marker then
        return false
    end

    local Name = p_Room.Marker.Name

    if p_Event.Dialogue then
        if self.__Dialogues == nil then self.__Dialogues = {} end

        local Index_Exists = 'EVENT_Room_'..p_Room.Id;
        if self.__Dialogues[Index_Exists] ~= nil then
            print("[MISSION_BUILDER] Rewriting dialogue for:", Index_Exists)
        end

        self.__Dialogues[Index_Exists] = p_Event.Dialogue;
    end

    self.__Markers[Name] = { Type = 'Trigger' } :: Types.Marker
    self.__Guide[Name] = p_Event

    return true
end

--[[
    The event that runs the moment the mission starts, before anyone has walked anywhere.
    This is the mission's "Begin" entry.
]]
function MissionBuilder.SetBeginEvent(self: MissionBuilder, p_Event: MissionEvent): ()
    if p_Event.Dialogue then
        if self.__Dialogues == nil then self.__Dialogues = {} end
        self.__Dialogues["EVENT_Begin"] = p_Event.Dialogue;
    end

    self.__Guide.Begin = p_Event
end

function MissionBuilder.AddNamedEvent(self: MissionBuilder, p_Name: string, p_Event: MissionEvent): ()
    if p_Event.Dialogue then
        if self.__Dialogues == nil then self.__Dialogues = {} end
        local Index_Exists = 'EVENT_' .. p_Name;
        if self.__Dialogues[Index_Exists] ~= nil then
            print("[MISSION_BUILDER] Rewriting dialogue for:", Index_Exists)
        end

        self.__Dialogues[Index_Exists] = p_Event.Dialogue;
    end

    self.__Guide[p_Name] = p_Event
end

--[[
    Create a marker part inside a room. Markers are how `SetupMarkers` finds NPCs, chests
    and destructibles, and a generated room has none beyond its own area trigger.

    @param p_Room Room to place it in.
    @param p_Name Marker name, must be unique.
    @param p_Offset Offset from the room centre, defaults to the centre.
]]
function MissionBuilder.CreateMarkerPart(self: MissionBuilder, p_Room: Types.GeneratedRoom, p_Name: string, p_Offset: CFrame?): BasePart
    local Part = Instance.new('Part')
    Part.Name = p_Name
    Part.Size = Vector3.new(4, 4, 4)
    Part.CFrame = p_Room.Marker.CFrame * (p_Offset or CFrame.new())
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CastShadow = false
    Part.Transparency = 1
    Part.Parent = GetMarkerFolder()

    self.__Marker_Count += 1

    return Part
end

--[[
    Drop an NPC into a room.

    @param p_Room Room to place it in.
    @param p_Name NPC name, also the marker name.
    @param p_Marker Marker data (Dialogue and friends), same shape as a hand-authored one.
    @param p_Offset Offset from the room centre.
]]
function MissionBuilder.AddNPC(self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Name: string, p_Marker: {[string]: any}?, p_Offset: CFrame?): string?
    if not p_Room then
        return nil
    end

    self:CreateMarkerPart(p_Room, p_Name, p_Offset)

    if p_Marker.Dialogue then
        if self.__Dialogues == nil then self.__Dialogues = {} end
        local Index_Exists = 'NPC_' .. p_Name;
        if self.__Dialogues[Index_Exists] ~= nil then
            print("[MISSION_BUILDER] Rewriting dialogue for:", Index_Exists)
        end

        self.__Dialogues[Index_Exists] = p_Marker.Dialogue;
    end

    local Marker = p_Marker or {}
    Marker.Type = 'NPC'
    self.__Markers[p_Name] = Marker :: Types.Marker

    return p_Name
end

--[[
    Drop a chest into a room.

    @param p_Room Room to place it in.
    @param p_Items Loot list, same shape as a hand-authored chest's `ItemList`.
    @param p_Offset Offset from the room centre.

    @return The marker name it was placed under.
]]
function MissionBuilder.AddChest(self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Items: {Types.LootItem}, p_Offset: CFrame?): string?
    if not p_Room then
        return nil
    end

    local Name = string.format('Chest_%s_%d', p_Room.Marker.Name, self.__Marker_Count + 1)
    self:CreateMarkerPart(p_Room, Name, p_Offset)

    self.__Markers[Name] = {
        Type = 'Chest',
        ItemList = p_Items,
    } :: Types.Marker

    return Name
end

--[[
    Drop a destructible into a room.

    @param p_Room Room to place it in.
    @param p_Destructible_Id Structure type out of `Database/Destructibles`, e.g. 'Crate'.
           Not a marker name, those are generated here.
    @param p_Data Drops / SetValues, same shape as a mission's `Destructibles` entry.
           `SetValues` lands on the mission's progress state, which is what a Completion
           handler ranks on.
    @param p_Offset Offset from the room centre.

    @return The marker name it was placed under.
]]
function MissionBuilder.AddDestructible(self: MissionBuilder, p_Room: Types.GeneratedRoom?, p_Destructible_Id: string, p_Data: {[string]: any}?, p_Offset: CFrame?): string?
    if not p_Room then
        return nil
    end

    local Name = string.format('%s_%s_%d', p_Destructible_Id, p_Room.Marker.Name, self.__Marker_Count + 1)
    self:CreateMarkerPart(p_Room, Name, p_Offset)

    self.__Markers[Name] = {
        Type = 'Destructible',
        Destructible_Id = p_Destructible_Id,
    } :: Types.Marker

    if p_Data then
        self.__Destructibles[Name] = p_Data
    end

    return Name
end

--- Rewards and rank handler for this mission. Same shape as a hand-authored `Completion`.
function MissionBuilder.SetCompletion(self: MissionBuilder, p_Completion: {[string]: any}): ()
    self.__Completion = p_Completion
end

function MissionBuilder.Result(self: MissionBuilder): {[string]: any}
    return {
        Markers = self.__Markers,
        Triggers = self.__Guide,
        Destructibles = self.__Destructibles,
        Completion = self.__Completion,
        Dialogues = self.__Dialogues,
    }
end

function MissionBuilder.IsEmpty(self: MissionBuilder): boolean
    return next(self.__Markers) == nil and next(self.__Guide) == nil
end

return MissionBuilder
