--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 1})
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
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
			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}, NoCameraShake = true, NoHitStop = true})
			end)
		end}
	})
end

return Ability