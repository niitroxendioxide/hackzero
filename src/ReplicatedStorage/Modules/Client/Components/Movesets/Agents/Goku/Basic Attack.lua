--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Agent: Types.GenericClass)
	Ability:Increase(Agent, 'Count', {Limit = 6})
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.15)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Agent, {
		{0, function(_: Types.Sequence)
			Agent:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Agent, 'Goku.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{.1, function()
			Agent:Walk(Ability:FromData('Walk_Time'))
		end,},

		{Ability:FromData("Hit_Times", M1_Count), function()
			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.EnemyClass)
				Target:Hit()
				Ability:Effect('Hit', Target)
			end)
		end,},
	})

end

return Ability