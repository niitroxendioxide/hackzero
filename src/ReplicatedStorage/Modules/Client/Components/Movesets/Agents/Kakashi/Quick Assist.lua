--[[
    ROUGH DRAFT - client half of the Quick Assist. Prediction/feel only, no damage.

    Default:        'Raikiri: Issen' dash-in.
    Lightning Mode: Kagebunshin split into two lightning dogs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Effects = require(Shared.Utility.Effects)
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
	const Teleport_Distance = Ability:FromData('Teleport_Distance')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')

	local Track: AnimationTrack = nil;
	local Single_Hit = false;
	local Origin: CFrame = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.QuickAssist.IssenBegin', {Fade = 0.1})
			Ability:Effect('Kakashi_Raikiri', Caster, 'Charge')

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:Effect('Kakashi_RaikiriDash', Caster, 'Charge')
		end},

		{Startup_Time, function()
			local Pos = Caster:GetPivot().Position
			local Look = Caster:GetPivot().LookVector
			local Direction = vector.normalize(vector.create(Look.X, 0, Look.Z))
			local Cast = Effects:CastMapRaycast(Pos, Direction * Teleport_Distance)
			local EndCFrame = CFrame.lookAlong(Pos, Direction) * CFrame.new(0, 0, -Teleport_Distance)
			if Cast then
				EndCFrame = CFrame.lookAlong(Cast.Position - Direction * 2, Direction)
			end

			Origin = CFrame.lookAlong(Pos, Direction)
			Ability:Effect('Kakashi_RaikiriDash', Caster, '_', Origin)
			Caster:PivotTo(EndCFrame)
		end},

		{Startup_Time, Startup_Time + Dash_Time, function()
			if Single_Hit or not Origin then
				return
			end

			local Offset = Caster:GetPivot():ToObjectSpace(Origin * CFrame.new(0, 0, -Hitbox_Size.z/2)).Position
			Ability:CreateHitbox(Caster, Offset, Hitbox_Size, function(Enemy)
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
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Shared.RaijuTsuiga', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Shared.RaijuTsuigaLoop', {Fade = 0.1})
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
