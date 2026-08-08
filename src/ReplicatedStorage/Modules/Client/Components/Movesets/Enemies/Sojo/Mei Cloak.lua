--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.EnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local CloakTime = Ability:FromData('Cloak_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			Ability:Effect("Sojo_MeiCloak", Caster, CloakTime)
		end,},

	})
end

return Ability