--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local LelouchController = require(script.Parent.LelouchGameplayController)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const Elite_Hit = Ability:FromData('Elite_Hit', nil, SkillLevel)
	const Knightmare_Hit = Ability:FromData('Knightmare_Hit', nil, SkillLevel)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')

	const Kneel_Time = Ability:FromData('Kneel_Time')
	const Kneel_Radius = Ability:FromData('Kneel_Radius')
	const Kneel_Duration = Ability:FromData('Kneel_Duration')
	const Subjugate_Time = Ability:FromData('Subjugate_Time')
	const Subjugate_Damage_Taken = Ability:FromData('Subjugate_Damage_Taken')
	const Subjugate_Affliction_Taken = Ability:FromData('Subjugate_Affliction_Taken')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Caster:AddTag('Invulnerability', Attack_State_Time)
			LelouchController:SetTarget(Caster, Context.Target)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Kneel_Time, function()
			Ability:CreateHitbox(Caster, vector.zero, vector.create(Kneel_Radius, 20, Kneel_Radius), function(Enemy)
				if LelouchController:IsNormal(Enemy) then
					LelouchController:Kneel(Enemy, Kneel_Duration)
				else
					Ability:Hit(Caster, Enemy, Elite_Hit)
					LelouchController:Subjugate(Enemy, Subjugate_Damage_Taken, Subjugate_Affliction_Taken, Subjugate_Time)
				end
			end)

			LelouchController:SpawnKnightmares(Caster, Ability, Ability:FromData('Knightmare_Count'), {
				Lifetime = Ability:FromData('Knightmare_Time'),
				Interval = Ability:FromData('Knightmare_Interval'),
				Hit = Knightmare_Hit,
				Blast_Size = Ability:FromData('Knightmare_Blast_Size'),
			})
		end},
	})
end

return Ability
