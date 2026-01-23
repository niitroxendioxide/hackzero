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
	
	--local M1_Count = Ability:Get(Caster, 'Count')
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local Sequence = Ability:Begin(Caster, {})
	
	for HitCount = M1_Count, M1_Count + 1, 0.1 do
		local AttackData = Ability:FromData("Attack_Data", HitCount)
		if AttackData == nil or AttackData == 0 then
			break
		end

		Ability:UseAttackData(Sequence, Caster, AttackData, {
			Size = Vector3.new(9, 9, 14),
			Offset = Vector3.new(0, 0, -7),
			Hit_Function = function(Target: Types.Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage', HitCount, SkillLevel),
					Daze = Ability:FromData('Daze', HitCount, SkillLevel),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', HitCount, SkillLevel),
					Affliction = 'Physical',
					HitType = 'Slash',
					Stun = 0.25,
					Knockback = {
						vector.create(0, 0, 1),
						15,
						0.1
					}
				})
			end
		})

	end

	Sequence:Start()
end

return Ability
