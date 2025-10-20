--!strict
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

--
local Stage = {}
Stage.__index = Stage

Stage.new = function() : StageHookManager
    local self = setmetatable({}, Stage)
    self.__Hooks = {}
    self.__Cache = {}
    self.__Trigger_Hooks = {}

    return self :: StageHookManager
end

-- typedef
export type Hook = (p_Mission: Types.MissionClass, p_Data: {
    Trigger: BasePart?,
    Players: {Types.StagePlayer}?,
    Agent: AgentTypes.ServerAgentClass?,
}) -> ()

type HookData = {
    Type: number,
    fn: Hook,
}

export type StageHookManager = typeof(setmetatable({}, Stage)) & {
    __Hooks: {[number]: HookData},
    __Cache: {[any]: any},
    __Trigger_Hooks: {[string]: (BasePart) -> ()},

    AddHook: (self: StageHookManager, p_Hook_Id: number, p_Hook: Hook) -> (StageHookManager),
    ForTrigger: (self: StageHookManager, p_Trigger: string, fn: (BasePart: BasePart) -> ()) -> (StageHookManager),

    ExecuteHooks: (self: StageHookManager, p_Hook_Type: number, ...any) -> (Hook)?,
    ExecuteTrigger: (self: StageHookManager, p_Trigger: string) -> (),
}

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

return Stage
