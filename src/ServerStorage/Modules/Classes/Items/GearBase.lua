--
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Shared = ReplicatedStorage.Modules.Shared
local World = require(ReplicatedStorage.Modules.Shared.World)
local GameEnum = require(Shared.GameEnum)

local Agents = require(Shared.Types.Agents)
local Types = require(Shared.Types.Gear)
--
local GearClass = {}
GearClass.__index = GearClass

function GearClass.new(Name: string): Types.GearObjectClass
    local self = setmetatable({}, GearClass)
    self.__Name = Name
    self.__Hooks = {}
    self.__Cache = {}
    self.__Cooldowns = {}

    return self
end

function GearClass.Connect(self: Types.GearObjectClass, HookType: Types.HookId, fn: Types.HookHandler)
    local hookName = GameEnum.KeyLookup(GameEnum.GearHookType, HookType)
    if self.__Hooks[HookType] then
        warn("Overriding hook of type: ", hookName)
    end

    assert(typeof(fn) == 'function', `Invalid connector for hook {hookName} for gear {self.__Name}`)

    self.__Hooks[HookType] = fn
end

function GearClass.RunHook(self: Types.GearObjectClass, HookType: Types.HookId, Data: Types.ProcessData)
    if not (self.__Hooks[HookType]) then
        return Data
    end

    local Success, Obtained = pcall(self.__Hooks[HookType], Data, {Level = 1})

    if Success then
        return (Obtained or Data)
    end

    warn("Error when running hook: ", GameEnum.KeyLookup(GameEnum.GearHookType, HookType))

    return Data
end

function GearClass.SetCooldown(self: Types.GearObjectClass, Agent: Agents.ServerAgentClass, Time: number)
    local ObjectExists = self.__Cooldowns[Agent]
    if ObjectExists then
        ObjectExists.goal = Time
        ObjectExists.time = 0

        if ObjectExists.thread then
            task.cancel(ObjectExists.thread :: thread)
        end
    end

    self.__Cooldowns[Agent] = {
        time = 0,
        goal = Time,
    }

    self.__Cooldowns[Agent].thread = task.spawn(function()
        local Object = self.__Cooldowns[Agent]

        while Object.time < Object.goal do
            local Delta = task.wait()

            Object.time += Delta * World:GetSpeed()
        end

        self.__Cooldowns[Agent].thread = nil
    end)
end

function GearClass.IsOnCooldown(self: Types.GearObjectClass, Agent: Agents.ServerAgentClass)
    local Cooldownobject = self.__Cooldowns[Agent]
    if Cooldownobject then
        return Cooldownobject.time >= Cooldownobject.goal
    end

    return false
end

return GearClass