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
	const Side_Offset = Ability:FromData('Side_Offset')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')

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
			for Index = 1, Dash_Count do
				const Side = (Index % 2 == 0) and 1 or -1
				const Origin = Caster:GetPivot()

				if Context.Target then
					const TargetPivot = Context.Target:GetPivot()

					Caster:PivotTo(TargetPivot * CFrame.new(Side_Offset * Side, 0, 6))
					Caster:LookAtTarget(Context.Target)
				end

				Caster:Walk(Dash_Time, Dash_Power, true)

				Ability:PlayAnimation(Caster, 'Kakashi.Abilities.ChainAttack.DenkoRensenPass', {Fade = 0})
				Ability:Effect('Kakashi_RaikiriDash', Caster, '_', Origin)

				Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
					Ability:Hit(Caster, Enemy, {
						NoHitStop = (Index ~= Dash_Count),
						EffectData = HIT_EFFECT_DATA,
					})
				end)

				task.wait(Dash_Time)
			end
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
