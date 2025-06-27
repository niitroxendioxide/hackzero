--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass): ()
	Ability:Increase(Caster, 'Count', {Limit = 4})
	local M1_Count = Ability:Get(Caster, 'Count')

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	--
	Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time', M1_Count) / Ability:FromData('Speed'))
		end,},
    })
end

return Ability
