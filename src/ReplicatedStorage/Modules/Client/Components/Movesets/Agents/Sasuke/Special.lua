--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass)
	--
	Ability:Increase(Caster, 'Counter', { Limit = 2 })

	local Attack_Time = Ability:FromData("Attack_State_Time")
	local Counter = Ability:Get(Caster, 'Counter');


	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, 'Sasuke.Abilities.Special.ThrowKunai' .. Counter, {
				Active_Time = Attack_Time,
			})
		end},

		{0.31, function()
			--- make kunai projectile
			Ability:Effect("KunaiProjectile", Caster, 200, 1)
		end}
	})
end

return Ability
