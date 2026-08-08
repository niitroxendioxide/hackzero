--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

---- This should be the fireball technique
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerEnemyClass)
	--	
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local HitBlastData = Ability:FromData("Hit")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end,},

		{.45, function()
			local Object; do
				Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -2.5), vector.create(8, 8), 135, 1, function(Target)  
					Object:Destroy()

					Ability:Hit(Caster, Target, HitBlastData)
				end, true)
			end
		end,},
	})
end

return Ability
