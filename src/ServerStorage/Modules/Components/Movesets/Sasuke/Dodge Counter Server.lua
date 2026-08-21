--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
--local SasukeGameplayController = require("./SasukeGameplayController")

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Ctx): ()
	---
	local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))
	local PunchHitData = Ability:FromData("PunchHit", nil, Caster:GetSkillLevel(Ability.__Name))
	local FireHitData = Ability:FromData("FireHit", nil, Caster:GetSkillLevel(Ability.__Name))
	local HitFrequency = Ability:FromData("HitFrequency")

	local Hits = {}

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Ability:FromData("Attack_State_Time"))
		end},

		{0.45, function()
			for i = -1, 1 do
				local Offset = Vector3.new(math.sin(math.rad(i * 35)) * 15, 0, math.cos(math.rad(i * 33)) * -4)
				Ability:CreateHitbox(Caster, Offset, vector.create(9, 9, 9), function(Enemy)  
					Ability:Hit(Caster, Enemy, HitData)
				end)
			end
		end},

		{0.85, function()
			Caster:Walk(0.25)
		end},

		{1.1, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(8, 8, 8), function(Enemy)
				Ability:Hit(Caster, Enemy, PunchHitData)
			end)
		end},

		{1.6, function()
			Caster:Walk(0.7, -0.2, true)
		end},

		{1.6, 2.3, function()
			if Ctx.Target and Ctx.Target:IsAlive() then
				Caster:LookAtTarget(Ctx.Target)
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -9), vector.create(8, 8, 18), function(Enemy)
				if (Hits[Enemy] == true) then
					return
				end

				Hits[Enemy] = true;
				task.delay(HitFrequency, function()
					Hits[Enemy] = false; 
				end)

				Ability:Hit(Caster, Enemy, FireHitData)
			end)
		end},
	})
end

return Ability
