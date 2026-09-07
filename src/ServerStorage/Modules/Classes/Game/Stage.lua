--[[
    @niitroxendioxide 2025-10

    @class StageHookManager
    In charge of managing the hooks for a stage, preparing the result for the final stage
    or setting up other stuff
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)
local AgentTypes = require(Shared.Types.Agents)
local MissionBuilder = require("./MissionBuilder");

--
local Stage = {}
Stage.__index = Stage

Stage.new = function() : StageHookManager
    local self = setmetatable({}, Stage)
    self.__Hooks = {}
    self.__Cache = {}
    self.__Trigger_Hooks = {}
    self.__Seed = 0
    self.__Builder = nil

    return self :: StageHookManager
end

-- typedef
export type Hook = (p_Mission: Types.MissionClass, p_Data: HookPayload) -> ()

export type HookPayload = {
    --[[
        Seed the map for this run was generated with. 0 for a static map. Roll every
        random decision a hook makes off this and the run stays reproducible.
    ]]
    Seed: number,
    Procedural: boolean?,
    Rooms: {Types.GeneratedRoom}?,

    Trigger: BasePart?,
    Players: {Types.StagePlayer}?,
    Agent: AgentTypes.ServerAgentClass?,
}

type HookData = {
    Type: number,
    fn: Hook,
}

export type StageHookManager = {
    __Hooks: {[number]: HookData},
    __Cache: {[any]: any},
    __Trigger_Hooks: {[string]: (BasePart) -> ()},
    __Seed: number,
    __Builder: Builder?,

    AddHook: (self: StageHookManager, p_Hook_Id: number, p_Hook: Hook) -> (StageHookManager),
    ForTrigger: (self: StageHookManager, p_Trigger: string, fn: (BasePart: BasePart) -> ()) -> (StageHookManager),

    ExecuteHooks: (self: StageHookManager, p_Hook_Type: number, ...any) -> (Hook)?,
    ExecuteTrigger: (self: StageHookManager, p_Trigger: string) -> (),

    OnBuild: (self: StageHookManager, p_BuildHandler: (Builder: Builder) -> ()) -> (StageHookManager),
    HasBuilder: (self: StageHookManager) -> (boolean),
    ExecuteBuild: (self: StageHookManager, p_Builder: MissionBuilder.MissionBuilder) -> (boolean, string?),

    SetSeed: (self: StageHookManager, p_Seed: number) -> (StageHookManager),
    GetSeed: (self: StageHookManager) -> (number),
    GetRandom: (self: StageHookManager, p_Salt: number?) -> (Random),
}

--[[
    Authors a mission's world into the map that was just generated.

    Unlike a `Hook` this runs synchronously and exactly once, before markers are laid out
    and before the mission object exists, because what it produces *is* what the mission
    then runs on.
]]


export type Builder = MissionBuilder.MissionBuilder

--
function Stage.AddHook(self: StageHookManager, p_Hook_Type: number, p_Hook: Hook): ()
    table.insert(self.__Hooks, {
        Type = p_Hook_Type, 
        fn = p_Hook
    } :: HookData)

    return self
end

function Stage.ExecuteHooks(self: StageHookManager, p_Hook_Type: number, ...: any): ()
    for _, Hook in self.__Hooks do
        if Hook.Type == p_Hook_Type then
            task.spawn(Hook.fn, ...)
        end
    end
end

function Stage.ForTrigger(self: StageHookManager, p_Trigger: string, fn: (BasePart: BasePart) -> ()): ()
    if self.__Trigger_Hooks[p_Trigger] then
        return
    end

    self.__Trigger_Hooks[p_Trigger] = fn;

    return self
end

function Stage.ExecuteTrigger(self: StageHookManager, p_Trigger: string, ...: any): ()
    local Handler = self.__Trigger_Hooks[p_Trigger]
    if not Handler then
        return
    end

    task.spawn(Handler, ...)
end

--[[
    Register the world author for this component.

    The function is handed a `MissionBuilder` over the freshly generated map and is expected
    to place the mission into it: pick rooms, attach events, drop NPCs and chests. Whatever
    it builds becomes the mission's world data.

    Only one builder per component, the first one registered wins.
]]
function Stage.OnBuild(self: StageHookManager, p_Build_Function: (p_Builder: Builder) -> ()): ()
    if self.__Builder then
        return self
    end

    self.__Builder = p_Build_Function

    return self
end

function Stage.HasBuilder(self: StageHookManager): boolean
    return self.__Builder ~= nil
end

--[[
    Run the world author. Synchronous on purpose, the caller needs the result before it can
    lay markers out.

    @return Whether a builder ran, plus the error message if it threw.
]]
function Stage.ExecuteBuild(self: StageHookManager, p_Builder: MissionBuilder.MissionBuilder): (boolean, string?)
    if not self.__Builder then
        return false
    end

    local Success, Message = pcall(self.__Builder, p_Builder)
    if not Success then
        return false, Message
    end

    return true
end

--[[
    Seed the run this manager is attached to was built with, set by MatchService before the
    mission begins so every hook sees the same number the map was generated from.
]]
function Stage.SetSeed(self: StageHookManager, p_Seed: number): ()
    self.__Seed = p_Seed or 0

    return self
end

function Stage.GetSeed(self: StageHookManager): number
    return self.__Seed
end

--[[
    A `Random` derived from the run seed, so anything a hook rolls (enemy picks, chest
    contents, room dressing) replays identically for the same mission.

    @param p_Salt Offsets the stream, pass a different one per independent roll so two
           hooks using the same seed do not produce the same sequence.
]]
function Stage.GetRandom(self: StageHookManager, p_Salt: number?): Random
    return Random.new(self.__Seed + (p_Salt or 0))
end

return Stage
