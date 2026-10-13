--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const GEASS_COLOR = Color3.fromRGB(171, 97, 255)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Geass_Time = Ability:FromData('Geass_Time')
	const Shot_Time = Ability:FromData('Shot_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Geass_Time, function()
			Ability:Effect('Glow', Caster, {Color = GEASS_COLOR})
		end},

		{Shot_Time, function()
			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot', {Fade = 0.1})

			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}, NoCameraShake = true})
			end)
		end},
	})
end

return Ability
