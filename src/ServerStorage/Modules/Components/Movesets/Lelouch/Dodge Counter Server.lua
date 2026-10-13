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
	const HitData = Ability:FromData('Hit', nil, SkillLevel)
	const Elite_Hit = Ability:FromData('Elite_Hit', nil, SkillLevel)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Geass_Time = Ability:FromData('Geass_Time')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')
	const Hitbox_Offset = Ability:FromData('Hitbox_Offset')
	const Paralyze_Time = Ability:FromData('Paralyze_Time')
	const Paralyze_Immunity_Time = Ability:FromData('Paralyze_Immunity_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			LelouchController:SetTarget(Caster, Context.Target)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Geass_Time, function()
			LelouchController:SummonKnights(Caster, Ability:FromData('Knight_Count'))

			Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
				if LelouchController:IsNormal(Enemy) then
					Ability:Hit(Caster, Enemy, HitData)
					LelouchController:Paralyze(Enemy, Paralyze_Time, Paralyze_Immunity_Time)
				else
					Ability:Hit(Caster, Enemy, Elite_Hit)
				end
			end)
		end},
	})
end

return Ability
