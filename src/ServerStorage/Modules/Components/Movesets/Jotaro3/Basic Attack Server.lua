--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local StandUtils = require(ServerStorage.Modules.Packages.Utility.StandUtils)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass): ()
	Ability:Increase(Caster, 'Count', {Limit = 4})

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	--
	local M1_Count = Ability:Get(Caster, 'Count')
	local StandSummoned = Caster:GetEffect('StandSummoned')
	local IsStand = (M1_Count >= 4 or StandSummoned)

	--Caster:UpdateMeter('Stand', 100)

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time', M1_Count) / Ability:FromData('Speed'))
		end,},

		{.2, function()
			local Pos  = IsStand and Vector3.zAxis * -4.5 or Vector3.zAxis*-3
			local Size = IsStand and Vector3.new(5, 5, 9) or Vector3.one * 5
			local Daze = Ability:FromData('Daze_Mult', M1_Count, SkillLevel) * (StandSummoned and 1.2 or 1)

			Ability:CreateHitbox(Caster, Pos, Size, function(Target: Types.Enemy)
				local Result = Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', M1_Count, SkillLevel),
					Knockback = Ability:FromData('Knockback'),
					Affliction = IsStand and 'Energy' or 'Physical',
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', M1_Count, SkillLevel),
					Stun = 0.25 + (StandSummoned and 0.15 or 0),
					Daze = Daze,
					HitType = 'Blunt',
				})

				if Result.Hit_Type == 'Entity' then
					local Damage = Result.Damage

					Caster:UpdateMeter('Stand', Damage * 0.01)
				end
			end)
		end,},

		{0.3, function()
			StandUtils:CheckAndSummon(self, Caster)
		end}
    })
end

return Ability
