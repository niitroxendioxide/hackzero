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
	local HitData = Ability:FromData("HitData")
	local AttackStateTime = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", AttackStateTime)
			Caster:WalkBack(0.25, 0.85)
		end},

		{0.55, function()
			if Context.Target then
				Ability:Hit(Caster, Context.Target, HitData)

				MikuGameplayController:InflictSlowness(Context.Target)
			end
		end},

		{0.65, function()
			if Context.Target then
				Ability:Hit(Caster, Context.Target, HitData)
			end
		end},

		{0.75, function()
			if Context.Target then
				Ability:Hit(Caster, Context.Target, HitData)
			end
		end},

		{0.85, function()
			local OffsetToTarget = if Context.Target then Caster:GetPivot():ToObjectSpace(Context.Target:GetPivot()) else CFrame.new(0, 0, 0)

			Ability:CreateHitbox(Caster, OffsetToTarget.Position, vector.create(16, 16, 16), function(Enemy)  
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},
	})
end

return Ability
