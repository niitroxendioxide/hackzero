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

    local function HitEnemy()
        Ability:CreateHitbox(Caster, vector.zero, vector.create(64, 12, 64), function(Enemy)  
            Ability:Hit(Caster, Enemy, HitData)
        end)
    end

	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime, true)
        end},

        {1.3, HitEnemy},
        {1.4, HitEnemy},
        {1.5, HitEnemy},
    })
end

return Ability
