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
	Ability:Increase(Caster, 'Count', {Limit = 5})
	local M1_Count = Ability:Get(Caster, 'Count')

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	--
	Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time', M1_Count) / Ability:FromData('Speed'))
		end,},

		{.15, function()
			Caster:Walk(Ability:FromData("Walk_Time"))
		end,},

		{.17, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ServerEnemyClass)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', M1_Count, SkillLevel),
					Affliction = 'Physical',
					Stun = .325,
					Daze = Ability:FromData('Daze_Mult', M1_Count, SkillLevel),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', M1_Count, SkillLevel)
				})
			end)
		end,},

		{.767, function()
			if M1_Count < 5 then return end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ServerEnemyClass)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', M1_Count + 1),
					Affliction = 'Physical',
					Stun = .325,
					Daze = Ability:FromData('Daze_Mult', M1_Count + 1),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', M1_Count)
				})
			end)
		end,}
	})
end

return Ability
