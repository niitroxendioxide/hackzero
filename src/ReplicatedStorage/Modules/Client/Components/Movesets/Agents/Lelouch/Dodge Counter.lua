--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent, _, _State, Context)
	const Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.Special.ThrowGrenade', {
				Fade = .1,
			})

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.267, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -11), vector.create(16, 5, 22), function(Target)
				Ability:Effect("Lelouch_GeassAffect", Target:GetId(), 3)
			end)
		end},
	})
end

return Ability
