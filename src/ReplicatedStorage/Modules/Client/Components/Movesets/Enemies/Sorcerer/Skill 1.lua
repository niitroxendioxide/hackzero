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

			Ability:PlayAnimation(Enemy, 'Sorcerer.Abilities.ElectricMoveSmash', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1,
				Active_Time = Attack_Time,
			})
		end,},

		{.2, function()
			Ability:Effect("Sorcerer_ElectricSmash", Enemy, 'Charge')
		end,},

		{0.367, function()
			Ability:Effect("Sorcerer_ElectricSmash", Enemy, 'Jump')
		end},

		{0.783, function()
			Ability:Effect("Sorcerer_ElectricSmash", Enemy, 'Smash')

			Ability:CreateHitbox(Enemy, vector.create(0, 0, -1), vector.one * 20, function(Enemy: Types.EnemyClass)  
				Ability:Hit(Enemy, Enemy, {})
			end)
		end},


	})
end

return Ability