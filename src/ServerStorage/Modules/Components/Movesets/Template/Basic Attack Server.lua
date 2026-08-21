--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)
local CharDatabase = require(Shared.Database.Characters)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Ctx): ()
	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end

	local Info = CharDatabase:GetCharacterData(Caster.Name, true)
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	print("Basic Attack Template! Count:", M1_Count, ' | Level: ', SkillLevel)
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', 0.25)
		end},

		{0.15, function()
			Caster:Walk(0.15, .75, false)
		end},

		{0.25, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(6, 6, 6), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					Damage = 100,
					Stun = 0.25,
					Daze = 100,
					Affliction_Buildup = 100,
					HitType = 'Blunt',
					Affliction = (Info and Info.Element) or 'None',
					Knockback = {
						vector.create(0, 0, 1),
						10,
						0.2
					},
				})
			end)
		end}
	})
end

return Ability
