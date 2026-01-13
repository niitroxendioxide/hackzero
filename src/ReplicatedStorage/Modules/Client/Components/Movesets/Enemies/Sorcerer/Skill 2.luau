--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Enemy: Types.EnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Enemy, {
		{0, function()
			Enemy:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			Ability:PlayAnimation(Enemy, 'Sorcerer.Abilities.Fireball', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1,
				Active_Time = Attack_Time,
			})
		end,},

		{.1, function()
			Ability:Effect("Sorcerer_Fireball", Enemy, 'Charge')
		end,},

		{0.45, function()
			Ability:Effect("Sorcerer_Fireball", Enemy, 'Shoot')
		end},
	})
end

return Ability