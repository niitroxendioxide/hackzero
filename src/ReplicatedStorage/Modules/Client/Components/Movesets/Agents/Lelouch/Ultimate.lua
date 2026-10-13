--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local Camera = require(Client.Libraries.Camera)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const GEASS_COLOR = Color3.fromRGB(171, 97, 255)
const HIT_EFFECT_DATA = {
	Highlight = true,
	HighlightColor = GEASS_COLOR,
}

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	if Caster:IsLocalPlayerOwner() then
		Camera:EnableOffset()
	end
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Kneel_Time = Ability:FromData('Kneel_Time')
	const Kneel_Radius = Ability:FromData('Kneel_Radius')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot', {Fade = 0.1})

			if Caster:IsLocalPlayerOwner() then
				Camera:DisableOffset()
			end

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Kneel_Time, function()
			Ability:Effect('Glow', Caster, {Color = GEASS_COLOR})

			Ability:CreateHitbox(Caster, vector.zero, vector.create(Kneel_Radius, 20, Kneel_Radius), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					HitAirborne = true,
					EffectData = HIT_EFFECT_DATA,
				})
			end)
		end},

		{Attack_State_Time, function()
			if Caster:IsLocalPlayerOwner() then
				Camera:EnableOffset()
			end
		end},
	})
end

return Ability
