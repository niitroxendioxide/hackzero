--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local AttackStateTime = Ability:FromData("Attack_State_Time")
    local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))
    local Angle = 0
    local Hits = {}

	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime, true)
        end},

        {0.65, 2.5, function(Sequence, delta: number)
            Angle += delta * (math.pi * 2)
            
            local Radius = (1 + math.floor(Angle / (math.pi * 2))) * 7
            local Cos, Sin = math.cos(-Angle) * Radius, math.sin(-Angle) * Radius

            Ability:CreateHitbox(Caster, vector.create(Sin, 0, Cos), vector.create(12, 12, 12), function(Enemy)  
                if Hits[Enemy] then
                    return
                end

                Ability:Hit(Caster, Enemy, HitData)

                Hits[Enemy] = true
                task.delay(0.2, function()
                    Hits[Enemy] = nil
                end)
            end).Debug(1  /  60)
        end}
    })
end

return Ability
