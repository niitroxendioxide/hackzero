--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster): ()
	Ability:Increase(Caster, 'Count', {Limit = 5})

	local M1_Count = Ability:Get(Caster, 'Count')
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local AttackData = Ability:FromData("Attack_Data", M1_Count)
	local Sequence = Ability:Begin(Caster, {})

	Ability:UseAttackData(Sequence, Caster, AttackData, {
		Size = Vector3.new(4, 4, 5),
		Offset = Vector3.new(0, 0, -2.5),
		Hit_Function = function(Target: Types.Target)
			Ability:Hit(Caster, Target, {
				Damage = Ability:FromData('Damage_Mult', M1_Count, SkillLevel),
				Daze = Ability:FromData('Daze_Mult', M1_Count, SkillLevel),
				Affliction_Buildup = Ability:FromData('Affliction_Buildup', M1_Count, SkillLevel),
				Affliction = 'Physical',
				HitType = 'Slash',
				Stun = 0.25,
			})
		end
	})

	if M1_Count >= 3 then
		local NewKey = M1_Count + 0.1
		local NewAttackData = Ability:FromData("Attack_Data", NewKey)

		Ability:UseAttackData(Sequence, Caster, NewAttackData, {
			Size = Vector3.new(4, 4, 5),
			Offset = Vector3.new(0, 0, -2.5),
			Hit_Function = function(Target: Types.Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', NewKey, SkillLevel),
					Daze = Ability:FromData('Daze_Mult', NewKey, SkillLevel),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', NewKey, SkillLevel),
					Affliction = 'Physical',
					HitType = 'Slash',
					Stun = 0.25,
				})
			end
		})
	end

	Sequence:Start()
end

return Ability
