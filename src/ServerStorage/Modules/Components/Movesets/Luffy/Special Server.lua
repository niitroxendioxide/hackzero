--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AbilityClass = require(ServerStorage.Modules.Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.GenericClass)
	--
	const Attack_State_Time = Ability:FromData("Attack_State_Time")
	const Hit = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.Name))
	
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_State_Time)
		end,},

		{0.35, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -12.5), vector.create(6, 6, 25), function(Target: Types.EnemyClass)
				Ability:Hit(Caster, Target, Hit)
			end)
		end},
	})
end

return Ability