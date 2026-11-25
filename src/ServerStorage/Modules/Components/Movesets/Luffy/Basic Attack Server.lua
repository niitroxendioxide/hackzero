--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)
--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Ctx): ()
	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end


	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	const Hit = Table.CopyDeep(Ability:FromData("Hit"))
	const Sequence = Ability:Begin(Caster, {}, true)

	for i = 0, 0.9, 0.1 do
		const Id = M1_Count + i
		const AttackData = Ability:FromData("Attack_Data", Id)
		if AttackData == nil then
			continue
		end

		const Damage = Ability:FromData("Damages", Id, SkillLevel)
		const Daze = Ability:FromData("Dazes", Id, SkillLevel)

		const Size = Ability:FromData("Sizes", Id)
		Ability:UseAttackData(Sequence, Caster, AttackData, {
			Size = Size,
			Offset = vector.create(0, 0, -Size.Z/2),
			Hit_Function = function(Target)
				Hit.Damage = Damage;
				Hit.Daze = Daze;

				if Id == 4 then
					Hit.Knockback = {
						vector.create(0, 0, 1),
						22,
						0.2,
					}
				end

				Ability:Hit(Caster, Target, Hit)
			end,
		})
	end

	Sequence:Start()
end

return Ability
