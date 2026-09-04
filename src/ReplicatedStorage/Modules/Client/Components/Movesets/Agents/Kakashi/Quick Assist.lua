--[[
    ROUGH DRAFT - client half of the Quick Assist. Prediction/feel only, no damage.

    Default:        'Raikiri: Issen' dash-in.
    Lightning Mode: Kagebunshin split into two lightning dogs.
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
	Ability:Effect('Kakashi_RaijuTsuiga', Caster, 'Delete')
end)

const function RaikiriIssen(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')
	const Hitbox_Offset = Ability:FromData('Hitbox_Offset')

	local Track: AnimationTrack = nil;
	local Single_Hit = false;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.QuickAssist.IssenBegin', {Fade = 0.1})
			Ability:Effect('Kakashi_Raikiri', Caster, 'Charge')

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Caster:Walk(Dash_Time, Dash_Power, true)
			Ability:Effect('Kakashi_RaikiriDash', Caster, 'Charge')
		end},

		{Startup_Time, Startup_Time + Dash_Time, function()
			if Single_Hit then
				return
			end

			Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
				if Single_Hit then
					return
				end

				Single_Hit = true;

				Ability:PlayAnimation(Caster, 'Kakashi.Abilities.QuickAssist.IssenHit', {Fade = 0})
				Ability:Effect('Kakashi_RaikiriDash', Caster, '_', Caster:GetPivot())
				Ability:Hit(Caster, Enemy, {EffectData = HIT_EFFECT_DATA})
			end)
		end},

		{Startup_Time + Dash_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

			Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')
		end},
	})
end

const function RaijuTsuigaPair(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dog_Count = Ability:FromData('Dog_Count')
	const Dog_Max_Time = Ability:FromData('Dog_Max_Time')
	const Dog_Spread = Ability:FromData('Dog_Spread')

	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.QuickAssist.Kagebunshin', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Ability:Effect('Kakashi_RaijuTsuiga', Caster, 'Create', Dog_Count, Dog_Spread, Dog_Max_Time)

			Ability:CreateHitbox(Caster, vector.create(0, 0, -16), vector.create(24, 7, 32), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					EffectData = HIT_EFFECT_DATA,
				})
			end)
		end},

		{Startup_Time + Dog_Max_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

			Ability:Effect('Kakashi_RaijuTsuiga', Caster, 'Delete')
		end},
	})
end

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	if Caster:HasTag('LightningMode') then
		RaijuTsuigaPair(Caster, Context)
	else
		RaikiriIssen(Caster, Context)
	end
end

return Ability
