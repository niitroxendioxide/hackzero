--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local GameEnum = require(Shared.GameEnum)
-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 4})
end)

local function HandleParryAbility(Agent, Target)
	Ability:Save(Agent, "Holding", true)

	local CurrentTrack = Ability:PlayAnimation(Agent, "Chihiro.Abilities.M1.ParryInit", {})
	Agent:SwitchState("Attacking", 9e12)
	
	Animation:StopTracksWithTag(Agent:GetModel(), "Dodge")
	
	local Thread = nil
	local ActivatedParry = false
	local Started = os.clock()
	while (Ability:Get(Agent, "Holding") == true) do
		if not Agent:IsActive() then
			break
		end

		if not ActivatedParry and (os.clock() - Started) >= 0.2  then
			ActivatedParry = true
			Ability:Effect("Chihiro_Stance", Agent)

			Thread = task.delay(0.2, function()
				CurrentTrack:Stop(0.25)
				CurrentTrack = Ability:PlayAnimation(Agent, "Chihiro.Abilities.M1.ParryIdle", {})
			end)

			Agent:AddTag('StunImmunity')
		end

		if Target ~= nil then
			Agent:LookAtTarget(Target)
		end

		task.wait()
	end

	if ActivatedParry then
		Ability:Effect("Chihiro_Stance", Agent)
		
		if Thread then
			task.cancel(Thread)
		end

		if CurrentTrack and CurrentTrack.IsPlaying then
			CurrentTrack:Stop(0.15)
		end

		Agent:RemoveTag('StunImmunity')
		Agent:SwitchState("Attacking", 0.25)

		return true
	end
	
	Agent:SwitchState("Attacking", 0)

	return true
end

function Ability:Play(Agent, _, State, Ctx)
	local M1_Count = Ability:Get(Agent, 'Count')
	if State == 'Begin' then
		local ShouldContinue = HandleParryAbility(Agent, Ctx.Target)
		if not ShouldContinue then
			return
		end
	else
		Ability:Save(Agent, "Holding", false)

		return
	end

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--Debugger:DebugLine("Chihiro.M1", `{State} Started with ID {M1_Count}`, 4)

	--
	local EffectObj = {}
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	local Sequence = Ability:Begin(Agent, {
		{0, function(_)
			local Track = Ability:PlayAnimation(Agent, 'Chihiro.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .125,
				Speed = M1_Count == 3 and 1.2 or 1,
			})

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{.133, function()
			if M1_Count ~= 2 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, -66.229, nil, false)
		end},

		{0.183, function()
			if M1_Count ~= 4 then
				return;
			end

			Ability:Effect("Slash", Agent, -60, nil, true)
		end},

		{.217, function()
			if M1_Count == 1 then
				EffectObj = Ability:EffectSerial("Slash", Agent, -67, nil, true)
			elseif M1_Count == 3 then
				EffectObj = Ability:EffectSerial("Slash", Agent, 31, nil, true, 1.15)
			end

		end},

		{.41, function()
			if M1_Count ~= 2 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, 70, nil, false)
		end},


		{.5, function()
			if M1_Count == 4 then
				Ability:Effect("Slash", Agent, 89, CFrame.new(0, -1.5, 0), false)
			end

			if M1_Count ~= 3 then return end

			EffectObj = Ability:EffectSerial("Slash", Agent, math.random(-2, 2), nil, false, 1.1, true)
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
	end

	Sequence:Start()
end

return Ability