--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Verify(Caster: Types.Caster)
	if Caster:GetState() == "Attacking" and Caster:HasTag("MikuBoostIdleState") then
		print('Miku can stop attacking!')

		return true
	end

	return Caster:GetState() == "Idle"
end

function Ability:Play(Caster: Types.Caster)
	if Caster:HasTag("MikuBoostIdleState") then
		Caster:SwitchState("Idle", 0)
		Caster:RemoveTag("MikuBoostIdleState")

		return
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Caster, {
		{0, function(_)
			Caster:AddTag('MikuBoostIdleState', Attack_Time)
			Caster:SwitchState('Attacking', Attack_Time)
		end,},
	})
end

return Ability