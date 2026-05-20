--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent, _, _, Context)
	--
	local EffectData = Ability:FromData("EffectData")
	local Attack_Time = Ability:FromData('Attack_State_Time')

	local Sequence = Ability:Begin(Agent, {
		{0, function(_)
			Agent:SwitchState('Attacking', Attack_Time)
		end,},
	
		{.06, function()
		end},

		{0.47, function()
		end},

		{0.85, function()
		end}

	}, true)

	Sequence:Start()
end

return Ability