--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)
local MikuGameplayController = require(script.Parent.MikuGameplayController)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	local SkillLevel = Caster:GetSkillLevel(Ability.Name)
	local HitData = Ability:FromData("HitData", nil, SkillLevel)
	local AttackStateTime = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", AttackStateTime)
		end},

		{0, 1.1, function()
			Caster:LookAtTarget(Context.Target)
		end},

		{0.767, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4.75), vector.one * 10, function(Enemy)
				MikuGameplayController:AddFanStateStack(Context.Target, 2)

				Ability:Hit(Caster, Context.Target, HitData)
			end)
		end},

		{1.183, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -13), vector.one * 10, function(Enemy)
				MikuGameplayController:AddFanStateStack(Context.Target, 2)

				Ability:Hit(Caster, Context.Target, HitData)
			end)
		end}
	})
end

return Ability
