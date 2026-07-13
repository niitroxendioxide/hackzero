--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local DelayedThreads = {}
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	local Hit_Data = Table.CopyDeep(Ability:FromData("Hit"))
	Hit_Data.Damage = Ability:FromData("Damage_Mult", M1_Count, Caster:GetSkillLevel(Ability.__Name))

	local Sequence = Ability:Begin(Caster, {}, true)

	local Offset = M1_Count >= 3 and Vector3.new(0, 0, -8) or Vector3.new(0, 0, -5)
	local Size = M1_Count >= 3 and Vector3.new(8, 8, 14) or Vector3.new(8, 8, 8)

	local AttackData = Ability:FromData("Attack_Data", M1_Count)
	AttackData[3] *= 0.75

	if M1_Count == 4 then
		Hit_Data.Knockback = {
			vector.create(0, 0, 1),
			27,
			0.5,
		}
	elseif M1_Count == 3 then
		Hit_Data.Knockback = nil
	end

	Ability:UseAttackData(Sequence, Caster, AttackData, {
		Size = Size,
		Offset = Offset,
		Hit_Function = function(Target)
			Ability:Hit(Caster, Target, Hit_Data)

			if DelayedThreads[Target:GetId()] then
				task.cancel(DelayedThreads[Target:GetId()])
			end

			if M1_Count ~= 3 then
				return
			end

			DelayedThreads[Target:GetId()] = task.delay(1.4, function()

				Ability:KnockBack(Caster, Target, {vector.create(0, 0, 1), 13, 0.3})
			end)
		end
	})

	Sequence:Start()
end

return Ability
