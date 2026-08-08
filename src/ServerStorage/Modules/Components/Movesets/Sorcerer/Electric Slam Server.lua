--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

---- This should be the lightning technique
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerEnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end,},

		{0.3, 0.8, function()
			Caster:Move(vector.create(0, 0, -1), 0.783 - 0.367, 45)
		end},

		{1, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis* -1, vector.one * 20, function(Target: Types.GenericClass)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult'),
					Stun = 0.5,
				})
			end)
		end,},
	})
end

return Ability
