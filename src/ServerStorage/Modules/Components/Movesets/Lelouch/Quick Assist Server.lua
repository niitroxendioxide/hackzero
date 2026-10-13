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
	const Shot_Time = Ability:FromData('Shot_Time')
	const Target = LelouchController:GetTargetInRange(Caster, Context.Target, Ability:FromData('Range'))

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Target then
				Caster:LookAtTarget(Target)
			end
		end},

		{Geass_Time, function()
			if not LelouchController:IsValidTarget(Target) then
				return
			end

			if LelouchController:IsNormal(Target) then
				LelouchController:Blind(Target, Ability:FromData('Blind_Time'))
			else
				Ability:Hit(Caster, Target, Elite_Hit)
			end
		end},

		{Shot_Time, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
				Ability:Hit(Caster, Enemy, HitData)
			end)

			LelouchController:Volley(Caster, Target)
		end},
	})
end

return Ability
