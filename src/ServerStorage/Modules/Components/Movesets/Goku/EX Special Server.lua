--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, State: string, ...)
	--
	Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

		{.2, function()
			Caster:Walk(.133)
		end,},

		{.35, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ServerEnemyClass)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', nil, 1),
					Affliction = 'Physical',
					Stun = .45,
					Daze = Ability:FromData('Daze_Mult', nil, 1),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', nil, 1)
				})
			end)
		end,},
	})
end

return Ability
