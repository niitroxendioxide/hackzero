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
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Call_Time = Ability:FromData('Call_Time')
	const Blast_Count = Ability:FromData('Blast_Count')
	const Blast_Interval = Ability:FromData('Blast_Interval')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			LelouchController:SetTarget(Caster, Context.Target)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Call_Time, function()
			LelouchController:SpawnKnightmares(Caster, Ability, 1, {
				Lifetime = Blast_Count * Blast_Interval + Blast_Interval / 2,
				Interval = Blast_Interval,
				Hit = Ability:FromData('Blast_Hit', nil, SkillLevel),
				Blast_Size = Ability:FromData('Blast_Size'),
				Use_Strategy = true,
			})
		end},
	})
end

return Ability
