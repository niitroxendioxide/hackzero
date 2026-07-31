--[[

    @service

    Handles miku's slowness and fan state for each of the M1's and more

]]


---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FAN_STATE_TIME  = 3
local SLOWNESS_DEBUFF = {
    Type = "Speed",
    Time = 2,
    Value = -0.75,
    Tag = "mikuslowness",
}


---
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Types = require(Shared.Types)
local Replicator = require(Modules.Libraries.Replicator)

---
local Controller = {}
local Targets = {}

function Controller:InflictSlowness(Target: Types.ServerEnemyClass)
    local Time = SLOWNESS_DEBUFF.Time
    
    Target:AddEffect(SLOWNESS_DEBUFF)

    Replicator:Effect("Miku_FanModeEnemy", { Target:GetId(), Time }, true)
end

function Controller:InflictFanState(Target: Types.ServerEnemyClass, TimeOverride: number)
    local StateTime = TimeOverride or FAN_STATE_TIME

    Target:SwitchState("Frozen", StateTime)
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

    if (Targets[Target].Stacks % 6 == 0 and Targets[Target].Stacks > 0) and not Targets[Target].InCooldown then
        Targets[Target].InCooldown = true;

        local ExtraSeconds = math.max((Targets[Target].Stacks - 6) // 6, 0)
        Controller:InflictFanState(Target, FAN_STATE_TIME + ExtraSeconds)

        if Targets[Target].Stacks >= 18 then
            Targets[Target].Stacks = 0;
        end

        task.delay(5, function()
            Targets[Target].InCooldown = false;
        end)
    end
end

function Controller:PackBuff(Type: string, Time: number, BaseValue: number, Id: string)
    
    return {

        Time = Time,
        Type = Type,
        Value = BaseValue,
        Tag = Id,
    }
    
end

return Controller;
