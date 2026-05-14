--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	local HitData = Ability:FromData("HitData")
	local AttackStateTime = Ability:FromData("Attack_State_Time")
	local SlownessEffect = Ability:FromData("SlownessEffect")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", AttackStateTime)
		end},

		{0.45, function()
			Ability:CreateHitbox(Caster, vector.zero, vector.create(36, 12, 36), function(Enemy)  
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},

		{0.85, function()
			if Context.Target then
				Ability:Hit(Caster, Context.Target, HitData)
				Context.Target:AddEffect(SlownessEffect)
			end
		end}
	})
end

return Ability
