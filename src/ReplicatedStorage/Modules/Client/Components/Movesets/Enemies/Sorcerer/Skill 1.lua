-
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Effects = require(Client.Libraries.Effects)
--local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Enemy: Types.EnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Enemy, {
		{0, function()
			Enemy:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Enemy, 'Saiyan.Abilities.Shoot', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1,
				Active_Time = Attack_Time,
			})
		end,},

		{.5, function()

			Ability:CreateHitbox(Enemy, Vector3.zAxis* -30, Vector3.new(2.25, 2.25, 60), function(_: Types.GenericClass)
				print('Hit effect')
			end)
		end,},
	})
end

return Ability