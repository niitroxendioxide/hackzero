--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const GEASS_COLOR = Color3.fromRGB(171, 97, 255)
const HIT_EFFECT_DATA = {
	Highlight = true,
	HighlightColor = GEASS_COLOR,
}

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Geass_Time = Ability:FromData('Geass_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Geass_Time, function()
			Ability:Effect('Glow', Caster, {Color = GEASS_COLOR})

			if Context.Target then
				Ability:Hit(Caster, Context.Target, {EffectData = HIT_EFFECT_DATA})
			end
		end},
	})
end

return Ability
