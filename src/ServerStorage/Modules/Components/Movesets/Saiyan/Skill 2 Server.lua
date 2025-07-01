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
			Ability:CreateHitbox(Caster, Vector3.zAxis* -4.25, Vector3.new(4.5, 3.5, 8), function(Target: Types.GenericClass)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult'),
					Stun = 0.5,
				})
			end)
		end,},
	})
end

return Ability
