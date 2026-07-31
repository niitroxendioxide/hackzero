--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AbilityClass = require(ServerStorage.Modules.Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Context)

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
    local GodFistHitData = Ability:FromData("Hit_Data", nil, SkillLevel)
	local function HitEnemy()
		
		Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.create(9.5, 7, 14.5), function(Target)  
            Ability:Hit(Caster, Target, GodFistHitData)
		end)

	end

    local Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_State_Time, true)
		end},

		{0.35, function()
			Caster:ImpulseForward(60, 0.75)
		end},

		{0.36, 0.6, function()
			if Context and Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{0.4, HitEnemy},
		{0.5, HitEnemy},
		{0.6, HitEnemy},
	})
end

return Ability