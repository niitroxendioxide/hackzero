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
	const Geass_Time = Ability:FromData('Geass_Time')
	const Target = LelouchController:GetTargetInRange(Caster, Context.Target, Ability:FromData('Range'))

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Target then
				Caster:LookAtTarget(Target)
			end
		end},

		{Geass_Time, function()
			LelouchController:SummonKnights(Caster, Ability:FromData('Knight_Count'))

			if not LelouchController:IsValidTarget(Target) then
				return
			end

			const HitData, Strategy = LelouchController:ApplyStrategy(Caster, Ability:FromData('Hit', nil, SkillLevel))
			const Affliction_Filled = Target:GetAffliction(Strategy.Element) or 0
			const Is_Empowered = LelouchController:HasCommand(Target) and Affliction_Filled >= Ability:FromData('Empowered_Affliction_Threshold')

			local Yield_Defense = Ability:FromData('Yield_Defense')
			local Yield_Time = Ability:FromData('Yield_Time')

			if Is_Empowered then
				Yield_Defense = Ability:FromData('Empowered_Yield_Defense')
				Yield_Time = Ability:FromData('Empowered_Yield_Time')

				HitData.Forced_Affliction = true
				LelouchController:ForceAffliction(Target, Strategy.Element)
			end

			LelouchController:Yield(Target, Yield_Defense, Yield_Time)

			if Strategy.Affliction then
				LelouchController:ShredResistance(Target, Strategy.Element, Ability:FromData('Resistance_Shred'), Yield_Time)
			end

			Ability:Hit(Caster, Target, HitData)
		end},
	})
end

return Ability
