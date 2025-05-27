--
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
	if Ability:Get(Enemy, 'Shoot_Track') then
		Ability:Get(Enemy, 'Shoot_Track'):Stop()
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Enemy, {
		{0, function(_: Types.Sequence)
			Enemy:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Enemy, 'Saiyan.Abilities.Shoot', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1, 
				Active_Time = Attack_Time,
			})

			Ability:Save(Enemy, 'Shoot_Track', Track)
		end,},

		{0.15, function()
			Effects:Play('Saiyan_Skill_1', Enemy, 'Charge')
		end,},

		{.5, function()
			Effects:Play('Saiyan_Skill_1', Enemy, 'Shoot')

			Ability:CreateHitbox(Enemy, Vector3.zAxis* -30, Vector3.new(2.25, 2.25, 60), function(_: Types.GenericClass)

			end)
		end,},
	})
end

return Ability