--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster, _, _, Context): ()
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	local Size = Vector3.one*5
	local Offset = Vector3.zAxis * -3

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time', M1_Count) / Ability:FromData('Speed'))
		end,},

		-- 1ST M1
		{.1, function()
			if M1_Count == 1 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end,},

		-- 2ND M1
		{0.15, function()
			if M1_Count == 2 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.43, function()
			if M1_Count == 2 then
				Caster:Walk(Ability:FromData('Walk_Time') + .1, 2)
			end
		end},

		-- 3RD M1
		{0.2, function()
			if M1_Count == 3 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		-- 4TH M1
		{0.06, function()
			if M1_Count == 4 then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.1)
			end
		end},

		-- 5TH M1
		{0.27, function()
			if M1_Count == 5 then
				Caster:WalkBack(Ability:FromData('Walk_Time') + 0.7, 1.5)
			end
		end},

		-- 6TH M1
		{0.18, function()
			if M1_Count == 6 then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.18, 2.25)
			end
		end},


		{Ability:FromData("Hit_Times", M1_Count), function()
			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', M1_Count, SkillLevel),
					Affliction = 'Physical',
					Stun = .325,
					HitsAirborne = true,
					HitType = 'Blunt',
					Daze = Ability:FromData('Daze_Mult', M1_Count, SkillLevel),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', M1_Count, SkillLevel)
				})
			end, M1_Count == 6 and 0.45 or nil)
		end,},

		{.54, function()
			if M1_Count ~= 4 then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', 4.5, SkillLevel),
					Affliction = 'Physical',
					Stun = .325,
					HitsAirborne = true,
					HitType = 'Blunt',
					Daze = Ability:FromData('Daze_Mult', 4.5, SkillLevel),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', 4.5, SkillLevel)
				})
			end)
		end,},

		{.5, function()
			if M1_Count ~= 2 then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', 2.5, SkillLevel),
					Affliction = 'Physical',
					Stun = .325,
					HitsAirborne = true,
					HitType = 'Blunt',
					Daze = Ability:FromData('Daze_Mult', 2.5, SkillLevel),
					Knockback = Ability:FromData('Knockback'),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', 2.5, SkillLevel)
				})
			end)
		end,},
	})
end

return Ability
