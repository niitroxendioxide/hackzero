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
	const Grenade_Hit = Ability:FromData('Grenade_Hit', nil, SkillLevel)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Throw_Time = Ability:FromData('Throw_Time')
	const Throw_Distance = Ability:FromData('Throw_Distance')
	const Geass_Time = Ability:FromData('Geass_Time')
	const Target = LelouchController:GetTargetInRange(Caster, Context.Target, Ability:FromData('Range'))

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Target then
				Caster:LookAtTarget(Target)
			end
		end},

		{Throw_Time, function()
			const At = if LelouchController:IsValidTarget(Target) then Target:GetPivot() else Caster:GetPivot() * CFrame.new(0, 0, -Throw_Distance)

			LelouchController:ThrowGrenade(Caster, At, Grenade_Hit, Ability)
		end},

		{Geass_Time, function()
			LelouchController:SummonKnights(Caster, Ability:FromData('Knight_Count'))
			LelouchController:StandStill(Target, Ability:FromData('Stand_Still_Slow'), Ability:FromData('Stand_Still_Time'))
		end},
	})
end

return Ability
