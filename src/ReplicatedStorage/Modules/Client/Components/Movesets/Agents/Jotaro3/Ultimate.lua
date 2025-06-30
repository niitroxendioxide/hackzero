--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)
local Cutscenes = require(Client.Libraries.Cutscenes)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass)
	Cutscenes:Start('Jotaro3 Timestop', Agent)

	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Agent, {
		{0, function()
			Agent:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))
		end,},
	})
end

return Ability