--[[
    ROUGH DRAFT - client half of the Dodge Counter. Prediction/feel only, no damage.

    Default:        'Raiton: Raiju Tsuiga' lightning dog.
    Lightning Mode: 'Shishi Rendan' kicks into a 'Raikiri' ground slam.
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
	Ability:Effect('Kakashi_RaijuTsuiga', Caster, 'Delete')
end)

const function RaijuTsuiga(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dog_Max_Time = Ability:FromData('Dog_Max_Time')

	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.DodgeCounter.RaijuTsuiga', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Ability:Effect('Kakashi_RaijuTsuiga', Caster, 'Create', Dog_Max_Time)

			Ability:CreateHitbox(Caster, vector.create(0, 0, -14), vector.create(9, 7, 28), function(Enemy)
				Ability:Hit(Caster, Enemy, {
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

const function ShishiRendan(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Kick_Count = Ability:FromData('Rendan_Kick_Count')
	const Kick_Frequency = Ability:FromData('Rendan_Kick_Frequency')
	const Slam_Time = Ability:FromData('Rendan_Slam_Time')
	const Slam_Radius = Ability:FromData('Rendan_Slam_Radius')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')
	const Hitbox_Offset = Ability:FromData('Hitbox_Offset')

	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.DodgeCounter.ShishiRendan', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			-- Spawned so the yielding kick loop doesn't hold up the slam frame below.
			task.spawn(function()
				for Index = 1, Kick_Count do
					Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
						Ability:Hit(Caster, Enemy, {
							NoHitStop = true,
							HitAirborne = true,
							EffectData = HIT_EFFECT_DATA,
						})
					end)

					if Index < Kick_Count then
						task.wait(Kick_Frequency)
					end
				end
			end)
		end},

		{Slam_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.1)
			end

			Ability:PlayAnimation(Caster, 'Kakashi.Abilities.DodgeCounter.RaikiriSlam', {Fade = 0})
			Ability:Effect('Kakashi_RaikiriSlam', Caster, Caster:GetPivot())

			Ability:CreateHitbox(Caster, vector.zero, vector.create(Slam_Radius, 12, Slam_Radius), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					HitAirborne = true,
					EffectData = HIT_EFFECT_DATA,
				})
			end)
		end},
	})
end

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	if Caster:HasTag('LightningMode') then
		ShishiRendan(Caster, Context)
	else
		RaijuTsuiga(Caster, Context)
	end
end

return Ability
