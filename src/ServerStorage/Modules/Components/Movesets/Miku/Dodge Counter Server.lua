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
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData("HitData", nil, SkillLevel)
	local AttackStateTime = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", AttackStateTime)
		end},

		{0.45, function()
		end},

		{0.85, function()
			if Context.Target then
				MikuGameplayController:AddFanStateStack(Context.Target, 6)

				Ability:Hit(Caster, Context.Target, HitData)
			end
		end}
	})
end

return Ability
