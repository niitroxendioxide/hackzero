--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
		end,},
	})
end

return Ability