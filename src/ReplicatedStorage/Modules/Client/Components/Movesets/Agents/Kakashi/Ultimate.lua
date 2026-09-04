--[[
    ROUGH DRAFT - client half of the Ultimate. Prediction/feel only, no damage.

    'Raikiri: Sōraishin' - dash, area launch on contact, zig-zag aerial hits, final ground slam.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local Camera = require(Client.Libraries.Camera)
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

	if Caster:IsLocalPlayerOwner() then
		Camera:EnableOffset()
	end
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Dash_Hitbox_Size = Ability:FromData('Dash_Hitbox_Size')

	const Launch_Radius = Ability:FromData('Launch_Radius')
	const Launch_Time = Ability:FromData('Launch_Time')
	const Airborne_Hit_Frequency = Ability:FromData('Airborne_Hit_Frequency')
	const Slam_Time = Ability:FromData('Slam_Time')
	const Slam_Radius = Ability:FromData('Slam_Radius')

	const Caught = {}
	local LastHit = os.clock()
	local Connected = false;
	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Ultimate.SoraishinDash', {Fade = 0.1})

			Ability:Effect('Kakashi_Raikiri', Caster, 'Charge', true)
			Caster:Walk(Dash_Time, Dash_Power, true)

			if Caster:IsLocalPlayerOwner() then
				Camera:DisableOffset()
			end

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{0, Dash_Time, function()
			if Connected then
				return
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -15), Dash_Hitbox_Size, function(Enemy)
				if Connected then
					return
				end

				Connected = true;

				Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Ultimate.SoraishinLaunch', {Fade = 0})

				Ability:CreateHitbox(Caster, vector.zero, vector.create(Launch_Radius, 14, Launch_Radius), function(Caught_Enemy)
					if Caught[Caught_Enemy] then
						return
					end

					Caught[Caught_Enemy] = true

					Ability:Hit(Caster, Caught_Enemy, {
						HitAirborne = true,
						EffectData = HIT_EFFECT_DATA,
					})
				end)
			end)
		end},

		{Launch_Time, function()
			if not Connected then
				return
			end


			Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Ultimate.SoraishinAerial', {Fade = 0.1, Loop = true})
		end},

		{Launch_Time, Launch_Time + Slam_Time, function()
			if not Connected then
				return
			end

			if (os.clock() - LastHit) > Airborne_Hit_Frequency then
				LastHit = os.clock()
				for Enemy in Caught do
					Ability:Hit(Caster, Enemy, {
						NoHitStop = true,
						HitAirborne = true,
						EffectData = HIT_EFFECT_DATA,
					})
				end
			end
		end},

		{Launch_Time + Slam_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.1)
			end

			if not Connected then
				return
			end

			Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Ultimate.SoraishinSlam', {Fade = 0})
			Ability:Effect('Kakashi_RaikiriSlam', Caster, Caster:GetPivot())

			Ability:CreateHitbox(Caster, vector.zero, vector.create(Slam_Radius, 16, Slam_Radius), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					HitAirborne = true,
					EffectData = HIT_EFFECT_DATA,
				})
			end)
		end},

		{Attack_State_Time, function()
			Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')

			if Caster:IsLocalPlayerOwner() then
				Camera:EnableOffset()
			end
		end},
	})
end

return Ability
