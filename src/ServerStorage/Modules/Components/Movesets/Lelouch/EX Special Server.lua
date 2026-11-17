--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, State, Ctx): ()
	const TargetId = Ctx.Target:GetId();

	Ability:Begin(Caster, {
		{0, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end

			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end},

		{0.267, function()
			
		end},
	})
end

return Ability
