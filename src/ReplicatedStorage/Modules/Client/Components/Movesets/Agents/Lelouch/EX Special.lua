--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Math = require(Shared.Utility.Math)
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

			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Geass', {
				Fade = .1,
			})

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.267, function()
			Ability:Effect("Lelouch_GeassAffect", Context.Target:GetId())
		end},
	})
end

return Ability
