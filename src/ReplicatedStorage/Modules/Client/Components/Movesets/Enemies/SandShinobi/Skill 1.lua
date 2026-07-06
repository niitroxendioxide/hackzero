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

			local _ = Ability:PlayAnimation(Enemy, 'SandShinobi.Abilities.EarthJutsu', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1,
				Active_Time = Attack_Time,
			})
		end,},


		{.5, function()
			Ability:CreateHitbox(Enemy, Vector3.zAxis* -30, Vector3.new(2.25, 2.25, 60), function(_: Types.GenericClass)
				--
			end)
		end,},
	})
end

return Ability