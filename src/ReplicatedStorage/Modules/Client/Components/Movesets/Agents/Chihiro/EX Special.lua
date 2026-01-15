--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent)
    print('so?')

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Agent, {
		{0, function(_)
			local Track = Ability:PlayAnimation(Agent, 'Chihiro.Abilities.Special.Default', {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

			Ability:Save(Agent, 'M1_Track', Track)
            print('some bs!')
		end,},

		{.217, function()
			Ability:EffectSerial("Slash", Agent, -67, nil, true)
		end},
	})
end

return Ability