--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()

	local Attack_Time = Ability:FromData("Attack_State_Time")
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	local BackHit = Ability:FromData("BackHit", nil, SkillLevel)
	local SecondHit = Ability:FromData("SecondHit", nil, SkillLevel)


	local Marked = {}
	local function AssignClone(Target)
		if Marked[Target] then
			return;
		end

		Marked[Target] = true
	end

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{0, 0.9, function()
			Caster:LookAtTarget(Context.Target)
		end},

		{0.4, function(self)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.create(6, 6, 6), function(Enemy: Types.ServerEnemy)
				Ability:Hit(Caster, Enemy, HitData)
				AssignClone(Enemy)
			end)
		end},

		{0.9, function(self)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -8), vector.create(6, 6, 8), function(Enemy: Types.ServerEnemy)
				Ability:Hit(Caster, Enemy, SecondHit)
				AssignClone(Enemy)
			end)
		end},

		{1.55, function()
			for Target in Marked do
				Ability:Hit(Caster, Target, BackHit)
			end
		end}
	})
end

return Ability
