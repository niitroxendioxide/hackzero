--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local SasukeGameplayController = require("./SasukeGameplayController")

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster): ()
	---

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Ability:FromData("Attack_State_Time"))
		end},

		{0.25, function()
			if SasukeGameplayController:HasConnectedThreads(Caster) then
				Ability:Effect("Sasuke_Thread", {Caster, 0, 3}, true)
				SasukeGameplayController:UseEnemyConnectedThreads(Caster, function(Target)  
					local Time = ((Caster:GetPivot().Position - Target:GetPivot().Position).Magnitude / 45) * 0.35
					Target:SetWorldSpeed(0, 0.2 + Time)

					task.wait(0.15 + Time)
					Ability:Hit(Caster, Target, Ability:FromData("Burst", nil, Caster:GetSkillLevel(Ability.__Name)))
				end)
			else
				local Projectile do 
					Projectile = Ability:CreateMovingHitbox(Caster, Caster:GetPivot(), vector.create(12, 12), 90, 1, function(Target)  
						Ability:Hit(Caster, Target, Ability:FromData("Fireball", nil, Caster:GetSkillLevel(Ability.__Name)))
						Projectile:Destroy()
					end)
				end
			end
		end}
	})
end

return Ability
