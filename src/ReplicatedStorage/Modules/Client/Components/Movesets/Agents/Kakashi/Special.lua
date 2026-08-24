--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	local Attack_State_Time = Ability:FromData("Attack_State_Time")
	local Hit_Count = Ability:FromData('Hit_Count')
	local Hit_Frequency = Ability:FromData('Hit_Frequency')
	local Single_Hit = false;

	local Track: AnimationTrack = nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Ability:Effect("Kakashi_Raikiri", Caster, 'Charge')
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.RaikiriBegin', {})
		end,},

		{0.4, function()
			Track:Stop(0)
			Track = Ability:PlayAnimation(Caster, "Kakashi.Abilities.Special.RaikiriRun", {Speed = 1.5, Fade = 0.15, Loop = true})
			Caster:Walk(0.5, 1.3, true)
		end},

		{0.4, 0.9, function()
			if Single_Hit then
				return
			end

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -2), vector.create(4, 4, 5), function(Enemy)
				if Single_Hit then
					return
				end

				Caster:Walk(Hit_Count * Hit_Frequency, 1)
				Single_Hit = true;
				Track:Stop(0.175);

				Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Hit_Count * Hit_Frequency + 0.1)

				Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.RaikiriHit', {Fade = 0})
				Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')


				task.wait(1 / 20)
				for i = 1, Hit_Count do
					Ability:Hit(Caster, Enemy, {
						NoHitStop = true,
						EffectData = {
							HueShift = 190,
							Highlight = true,
							HighlightColor = Color3.fromRGB(170, 251, 255)
						}
					})

					task.wait(Hit_Frequency)
				end
			end)
		end},

		{1, function()
			if Track.IsPlaying then
				Track:Stop(.15)
			end
			Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')
		end,},
	})
end

return Ability