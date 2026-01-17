--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Agent, {
		{0, function(_)
			Ability:PlayAnimation(Agent, 'Chihiro.Abilities.Special.Default', {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

            Ability:EffectSerial("Chihiro_Kuro", Agent, 'Charge')
		end,},

		{.4, function()
			Ability:EffectSerial("Chihiro_Kuro", Agent, 'Attack')
		end},
	})
end

return Ability