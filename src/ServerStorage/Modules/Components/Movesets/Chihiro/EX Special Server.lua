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

	local Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.4, function()
			local TargetsHit = {}
			local HitCounter = {}

			local Object do
				Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -1), vector.create(10, 3), 120, 1, function(Target)  
					if TargetsHit[Target:GetId()] or (HitCounter[Target:GetId()] or 0) >= 4 then
						return;
					end

					Object:SetSpeed(20)

					TargetsHit[Target:GetId()] = true;
					HitCounter[Target:GetId()] = (HitCounter[Target:GetId()] or 0) + 1 
					task.delay(1/10, function()
						TargetsHit[Target:GetId()] = false;
					end)

					if HitCounter[Target:GetId()] == 1 then
						--- Apply debuff here
					end

					Ability:Hit(Caster, Target, Ability:FromData("Hit"))
				end)
			end

		end},
	})

end

return Ability
