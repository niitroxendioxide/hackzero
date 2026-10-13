--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const GEASS_COLOR = Color3.fromRGB(171, 97, 255)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = Ability:FromData('Geass_Shot')})
end)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Save(Caster, 'HoldToken', nil)
end)

local function Shoot(Caster: Types.ClientAgent, EffectData: {[string]: any})
	Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
		Ability:Hit(Caster, Enemy, {EffectData = EffectData, NoCameraShake = true, NoHitStop = true})
	end)
end

local function FocusFire(Caster: Types.ClientAgent, Token: {})
	local Hold_Time = Ability:FromData('Focus_Hold_Time')
	local Shot_Interval = Ability:FromData('Focus_Shot_Interval')
	local HoldStart = os.clock()

	local function IsHeld()
		return Ability:Get(Caster, 'HoldToken') == Token
	end

	while IsHeld() and (os.clock() - HoldStart) < Hold_Time do
		task.wait()
	end

	while IsHeld() and not Caster:IsMoving() do
		Caster:SwitchState('Attacking', Shot_Interval + 0.1)
		Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Repeat', {
			Fade = .05,
		})

		Shoot(Caster, {Highlight = true})

		task.wait(Shot_Interval)
	end
end

function Ability:Play(Caster: Types.ClientAgent, _, State)
	if State == 'Release' then
		Ability:Save(Caster, 'HoldToken', nil)

		return
	end

	local Token = {}
	Ability:Save(Caster, 'HoldToken', Token)

	local Is_Geass = Ability:Get(Caster, 'Count') == Ability:FromData('Geass_Shot')
	local CanReshoot = Ability:Get(Caster, 'M1_Track') and Ability:Get(Caster, 'M1_Track').IsPlaying

	local Time = (0.33)
	if CanReshoot then
		Time = 0
	else
		Ability:Save(Caster, 'M1_Track', nil)
	end

	---
	local Attack_State_Time = Ability:FromData("Attack_State_Time") + Time;

	local _ = Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:Get(Caster, "M1_Track")
			if not Track then
				Track = Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot', {
					Fade = .1,
				})

				Ability:Save(Caster, 'M1_Track', Track)
			else
				Track.TimePosition = 0.317
			end

			Caster:SwitchState('Attacking', Attack_State_Time)
		end,},

		{Time, function()
			if Is_Geass then
				Ability:Effect('Glow', Caster, {Color = GEASS_COLOR})
			end

			Shoot(Caster, if Is_Geass then {Highlight = true, HighlightColor = GEASS_COLOR} else {Highlight = true})
		end}
	})

	FocusFire(Caster, Token)
end

return Ability
