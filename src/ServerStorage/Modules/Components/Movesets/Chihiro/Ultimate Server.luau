--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)
local ChihiroGameplayController = require(script.Parent.ChihiroGameplayController)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local AttackStateTime = Ability:FromData("Attack_State_Time")
    local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local HitData = Table.CopyDeep(Ability:FromData("Hit", nil, SkillLevel))
    local Multiplier = Ability:FromData("AccumulatedDamageMultiplier", nil, SkillLevel)

    local AccumulatedDamage = ChihiroGameplayController:UseUltimateCharge(Caster)

    ---
    local ExponentialAddition = math.min((Multiplier / 10), 0.5)
    local Variation = Ability:FromData("DamageVariation", nil, SkillLevel) 
    local Min, Max = (2500 - Variation), 2500
    local Divisor = math.random(Min, Max)
    local AggregatedDamage = (AccumulatedDamage / Divisor) * Multiplier * math.exp(1.5 + ExponentialAddition)

    HitData.Damage += AggregatedDamage

    local function HitEnemy()
        Ability:CreateHitbox(Caster, vector.zero, vector.create(52, 12, 52), function(Enemy)  
            Ability:Hit(Caster, Enemy, HitData)
        end)
    end

	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime, true)
        end},

        {1.15, HitEnemy},
        {1.2, HitEnemy},
        {1.25, HitEnemy},
        {1.3, HitEnemy},
        {1.35, HitEnemy},
    })
end

return Ability
