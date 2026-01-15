--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 2})
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
			local Track = Ability:PlayAnimation(Agent, 'Chihiro.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{.133, function()
			if M1_Count ~= 2 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -66.229, nil, false)
		end},

		{.217, function()
			if M1_Count ~= 1 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -67, nil, true)
		end},

		{.41, function()
			if M1_Count ~= 2 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, 70, nil, false)
		end},
	}, true)

	local AttackData = Ability:FromData("Attack_Data", M1_Count)
	local NextData = Ability:FromData("Attack_Data", M1_Count + 0.1)

	Ability:UseAttackData(Sequence, Agent, AttackData, {
		Size = Vector3.new(9, 9, 14),
		Offset = Vector3.new(0, 0, -7),
		Hit_Function = function(Target)
			Ability:Hit(Agent, Target, {StopEffect = EffectObj, EffectData = Ability:FromData("Effect_Data")})
		end
	})

	if typeof(NextData) == 'table' then
		Ability:UseAttackData(Sequence, Agent, NextData, {
			Size = Vector3.new(9, 9, 14),
			Offset = Vector3.new(0, 0, -7),
			Hit_Function = function(Target)
				Ability:Hit(Agent, Target, {StopEffect = EffectObj, EffectData = Ability:FromData("Effect_Data")})
			end
		})

		print('hello')
	end

	Sequence:Start()
end

return Ability