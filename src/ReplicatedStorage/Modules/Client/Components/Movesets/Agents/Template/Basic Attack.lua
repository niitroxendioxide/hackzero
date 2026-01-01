--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 5})
end)

function Ability:Play(Agent: Types.GenericClass)
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Agent, {
		{0, function()
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

		{.18, function()
			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.EnemyClass)
				Target:Hit()
				Ability:Effect('Hit', Target)
			end)
		end,},

		{.767, function()
			if M1_Count < 5 then return end

			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.EnemyClass)
				Target:Hit()
				Ability:Effect('Hit', Target)
			end)
		end,}
	})

end

return Ability