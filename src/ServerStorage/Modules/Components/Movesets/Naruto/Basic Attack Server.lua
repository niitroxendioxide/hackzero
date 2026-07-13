--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	local Hit_Data = Ability:FromData("Hit")
	Hit_Data.Damage = Ability:FromData("Damage_Mult", M1_Count, Caster:GetSkillLevel(Ability.__Name))

	local Sequence = Ability:Begin(Caster, {}, true)

	local Offset = M1_Count >= 3 and Vector3.new(0, 0, -8) or Vector3.new(0, 0, -2.5)
	local Size = M1_Count >= 3 and Vector3.new(8, 8, 14) or Vector3.new(8, 8, 8)

	local AttackData = Ability:FromData("Attack_Data", M1_Count)
	AttackData[3] *= 0.75
	Ability:UseAttackData(Sequence, Caster, AttackData, {
		Size = Size,
		Offset = Offset,
		Debug = true,
		Hit_Function = function(Target)
			
			Ability:Hit(Caster, Target, Hit_Data)

			--Target:Hit()
			--Ability:Effect('Hit', Target)
		end
	})

	Sequence:Start()
end

return Ability
