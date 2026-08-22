--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Ctx): ()
	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	local IsReshoot = Ability:Get(Caster, "M1_Thread");
	local HitTime = 0.33;
	if IsReshoot then
		HitTime = 0;
		task.cancel(IsReshoot);
	end

	local Attack_State_Time = Ability:FromData('Attack_State_Time') + HitTime

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_State_Time)

			Ability:Save(Caster, "M1_Thread", task.delay(0.8, function()
				Ability:Save(Caster, "M1_Thread", nil)
			end))
		end},

		{HitTime, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end}
	}, true)

	Sequence:Start()
end

return Ability
