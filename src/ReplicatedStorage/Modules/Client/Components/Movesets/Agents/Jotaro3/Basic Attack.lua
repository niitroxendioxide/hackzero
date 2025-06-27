--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass)
	Ability:Increase(Agent, 'Count', {Limit = 5})
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Agent, {
		{0, function()
			Agent:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))
		end,},

		{0.5, function()
			Ability:Effect("JP3_Stand", Agent, {
					At = Vector3.new(0, 0, -(2.5 + 0.25*M1_Count)),
					Time = 0.75,
			})
		end}
	})

end

return Ability