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
	local Ult_Length = Ability:FromData("Ult_Length")
	local Base_Attack_Time = Ability:FromData('Attack_State_Time')
	local Startup_Length = Ability:FromData("Startup_Length")

	Ability:Begin(Agent, {
		{0, function(Seq)
			local Track = Ability:PlayAnimation(Agent, 'Miku.Abilities.Ultimate.Default', {
				Fade = .1,
				Active_Time = Base_Attack_Time + Ult_Length - Startup_Length,
			})

			Ability:Save(Agent, "Track", Track)

			Agent:SwitchState('Attacking', Base_Attack_Time + Ult_Length - Startup_Length)
			Ability:Effect("Miku_StageUltimate", Agent, 'Activate')
		end,},

		{Startup_Length, function()
			local CurrentTrack = Ability:Get(Agent, "Track")
			CurrentTrack:AdjustSpeed(0)
		end},

		{Ult_Length, function()
			local CurrentTrack = Ability:Get(Agent, "Track")
			CurrentTrack:AdjustSpeed(1)
			Ability:Effect("Miku_StageUltimate", Agent, 'Deactivate')
		end},
	})
end

return Ability