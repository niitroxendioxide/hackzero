--[[

    @service

    Handles miku's slowness and fan state for each of the M1's and more

]]


---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

const FAN_STATE_TIME  = 4.5
const SLOWNESS_DEBUFF_TIME = 2.75
const STACK_RESET_LIMIT = 20
const STACKS_PER_TRIGGER = 4

---
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Types = require(Shared.Types)
local Replicator = require(Modules.Libraries.Replicator)

---
local Controller = {}
local Targets = {}

function Controller:InflictSlowness(Target: Types.ServerEnemyClass, OverrwrittenTime: number?)
    local ExistingEffect = Target:GetEffect('mikuslowness')
    if ExistingEffect then
        return;
    end

    ---
    local Time = OverrwrittenTime or SLOWNESS_DEBUFF_TIME
    local NewEffect = {
        Tag = 'mikuslowness',
        Value = -0.75,
        Time = Time,
        Type = 'Speed',
    }

    Target:AddEffect(NewEffect)

    Replicator:Effect("Miku_FanModeEnemy", { Target:GetId(), Time }, true)
end

function Controller:InflictFanState(Target: Types.ServerEnemyClass, TimeOverride: number)
    local StateTime = TimeOverride or FAN_STATE_TIME

    Target:ApplyTrueStun(StateTime)
    Replicator:Effect("Miku_FanModeEnemy", { Target:GetId(), StateTime, true }, true)
end

function Controller:AddFanStateStack(Target: Types.ServerEnemyClass, Amount: number?)
    if typeof(Amount) ~= 'number' then
        Amount = 1
    end
    
    if not Targets[Target] then
        Targets[Target] = {
            InCooldown = false,
            Stacks = 0,
        }
    end

    Targets[Target].Stacks += Amount;

    if (Targets[Target].Stacks % STACKS_PER_TRIGGER == 0 and Targets[Target].Stacks > 0) and not Targets[Target].InCooldown then
        Targets[Target].InCooldown = true;

        local Multiplier = 1 + (math.max((Targets[Target].Stacks - STACKS_PER_TRIGGER) // STACKS_PER_TRIGGER, 0) * 0.1)
        if Targets[Target].Stacks >= STACK_RESET_LIMIT then
            Controller:InflictFanState(Target, FAN_STATE_TIME * Multiplier)

            Targets[Target].Stacks = 0;
        else
            Controller:InflictSlowness(Target, SLOWNESS_DEBUFF_TIME * Multiplier)
        end

        task.delay(5, function()
            Targets[Target].InCooldown = false;
        end)
    end
end

function Controller:PackBuff(_, Type: string, Time: number, BaseValue: number, Id: string)
    
    return {

        Time = Time,
        Type = Type,
        Value = BaseValue,
        Tag = Id,
    }
    
end

return Controller;
