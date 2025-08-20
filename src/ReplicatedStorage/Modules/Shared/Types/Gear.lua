
local GameEnum = require(script.Parent.Parent.GameEnum)
local Agents = require(script.Parent.Agents)
local Abilities = require(script.Parent.Abilities)

export type HookId = typeof(GameEnum.GearHookType.AfterAffliction)

export type ProcessData = {
    Caster: Agents.ServerAgentClass,
    Target: Agents.Enemy,

    HitData: Abilities.HitEnemyData,
    ProcessedData: {Damage: number, Burst: boolean, Burst_Damage: number, Is_Critical: boolean}?
}

export type HookHandler = (Data: ProcessData, Context: GearContext) -> (ProcessData)
export type GearContext = {
    Level: number,
}

export type GearObjectClass = {
    __Name: string,
    __Hooks: {
        [HookId]: HookHandler,
    },

    __Cache: {},
    __Cooldowns: {
        [Agents.ServerAgentClass]: {
            time: number,
            goal: number,
            thread: thread?,
        },
    },

    Connect: (self: GearObjectClass, Event: HookId, fn: HookHandler) -> (),
    SetCooldown: (self: GearObjectClass, Agent: Agents.ServerAgentClass, Time: number) -> (),
    IsOnCooldown: (self: GearObjectClass, Agent: Agents.ServerAgentClass) -> (boolean),

    RunHook: (self: GearObjectClass, Event: HookId, Data: ProcessData) -> (ProcessData?),
    GetName: (self: GearObjectClass) -> (string),
}

export type GearObject = {}

return 0