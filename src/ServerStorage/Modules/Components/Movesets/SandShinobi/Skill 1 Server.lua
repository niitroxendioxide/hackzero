--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerEnemyClass, _, _, Context)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end,},

		{.6, function()
			local TargetPosition = vector.create(0, 0, -12)
			if (Context.Target ~= nil) then
				local Target = Context.Target;
				
				local Offset = Caster:GetPivot():ToObjectSpace(Target:GetPivot())
				TargetPosition = Offset.Position;
			end

			Ability:Effect("Shinobi_EarthPillar", {(Caster:GetPivot() * CFrame.new(TargetPosition)).Position}, true)

			Ability:CreateHitbox(Caster, TargetPosition, Vector3.new(7, 13, 7), function(Target: Types.GenericClass)
				Ability:Hit(Caster, Target, {
					Damage = 2,
					Stun = 0.9,
					AnimId = 9,
				})
			end)
		end,},
	})
end

return Ability
