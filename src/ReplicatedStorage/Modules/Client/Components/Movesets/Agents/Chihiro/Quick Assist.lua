--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:Effect("Chihiro_NishikiFish", Caster)
		end,}, 
	}, true);

    Sequence:Start()
end

return Ability