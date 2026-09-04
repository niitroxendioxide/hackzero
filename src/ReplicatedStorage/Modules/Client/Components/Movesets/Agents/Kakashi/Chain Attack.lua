--[[
    ROUGH DRAFT - client half of the Chain Attack. Prediction/feel only, no damage.

    'Raikiri: Denko Rensen' - zig-zag passes through the target, heavier final pass.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const HIT_EFFECT_DATA = {
	HueShift = 175,
	Highlight = true,
	HighlightColor = Color3.fromRGB(117, 150, 244),
}

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dash_Count = Ability:FromData('Dash_Count')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')

	-- The zig-zag is sold by the animation and the dash VFX, not by moving the character around.
	const Total_Time = Dash_Count * Dash_Time
	local LastHit = 0;
	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.ChainAttack.DenkoRensenBegin', {Fade = 0.1})
			Ability:Effect('Kakashi_Raikiri', Caster, 'Charge')

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Caster:Walk(Total_Time, Dash_Power, true)
		end},

		{Startup_Time, Startup_Time + Total_Time, function()
			if (os.clock() - LastHit) < Dash_Time then
				return
			end

			LastHit = os.clock()

			Ability:Effect('Kakashi_RaikiriDash', Caster, '_', Caster:GetPivot())

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					EffectData = HIT_EFFECT_DATA,
				})
			end)
		end},

		{Startup_Time + Total_Time, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = HIT_EFFECT_DATA})
			end)
		end},

		{Attack_State_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

			Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')
		end},
	})
end

return Ability
