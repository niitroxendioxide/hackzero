--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerEnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Attack_Time)
		end,},
		
		{.5, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis* -30, Vector3.new(2.25, 2.25, 60), function(Target: Types.ServerAgentClass)
				Target:TakeDamage(5)
			end)
		end,},
	})
end

return Ability
