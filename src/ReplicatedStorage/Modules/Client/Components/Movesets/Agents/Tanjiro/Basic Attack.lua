--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 5})
end)

function Ability:Play(Agent)
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--
	local EffectObj = {}
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	local Sequence = Ability:Begin(Agent, {
		{0, function(_)
			local Track = Ability:PlayAnimation(Agent, 'Tanjiro.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

			Ability:Effect("Tanjiro_Trail", Agent, Track.Length)
			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{.133, function()
			if M1_Count ~= 5 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -66.229, nil, false)
		end},

		{.15, function()
			if M1_Count == 3 then
				Ability:Effect("Hit", Agent, {Emitter = "FrontAttack", Offset = CFrame.new(-0.317, -1.063, -4.817)})
				return
			end
			if M1_Count > 2 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, M1_Count == 1 and -67.608 or -55, nil, M1_Count == 2)
		end},

		{.41, function()
			if M1_Count ~= 5 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, 70, nil, false)
		end},

		{.2, function()
			if M1_Count ~= 4 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -67, nil, true)
		end},

		{.45, function()
			if M1_Count ~= 4 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -78.8)
		end},
	}, true)

	local AttackData = Ability:FromData("Attack_Data", M1_Count)

	Ability:UseAttackData(Sequence, Agent, AttackData, {
		Size = Vector3.new(4, 4, 5),
		Offset = Vector3.new(0, 0, -2.5),
		Hit_Function = function(Target)
			Ability:Hit(Agent, Target, {StopEffect = EffectObj, EffectData = Ability:FromData("Effect_Data")})

			--Target:Hit()
			--Ability:Effect('Hit', Target)
		end
	})

	if M1_Count >= 3 then
		local NewAttackData = Ability:FromData("Attack_Data", M1_Count + 0.1)

		Ability:UseAttackData(Sequence, Agent, NewAttackData, {
			Size = Vector3.new(4, 4, 5),
			Offset = Vector3.new(0, 0, -2.5),
			Hit_Function = function(Target)
				Ability:Hit(Agent, Target, {StopEffect = EffectObj, EffectData = Ability:FromData("Effect_Data")})
				--Target:Hit()
				--Ability:Effect('Hit', Target)
			end
		})
	end

	Sequence:Start()
end

return Ability