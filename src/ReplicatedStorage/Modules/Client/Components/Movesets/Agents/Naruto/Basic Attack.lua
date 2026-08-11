--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 4})
end)

function Ability:Play(Caster: Types.AgentClass, _, _, Context)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			--Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Caster, 'Naruto.Abilities.M1.'.. M1_Count , {
				Fade = .1,
				Active_Time = Attack_Time + .45,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end},

		{0, .1, function()
			Caster:LookAtTarget(Context.Target)
		end},

		{0.1, function()
			if M1_Count >= 3 then
				local Object = Animation:GetAnim('Characters.Naruto.Abilities.M1.Clone_'..M1_Count-2)
				local AnimSpeed = Ability:FromData("Speed") * Ability:FromData("Animation_Speed")
				local Id = Http:GenerateGUID()
				Ability:Save(Caster, "LastCloneId", Id)

				local Extra = M1_Count == 4 and 0.3 or 0
				Ability:Effect('Naruto_Clone', Caster, .75 + Extra, CFrame.new(-1, 0, -5.5), {Id = Id, Object = Object, Speed = AnimSpeed, CFrameTween = {0.35, 'Quad'}, OriginOffset = CFrame.new(-1, -1, 3)})
			end
		end}
	}, true)

	local Offset = M1_Count >= 3 and Vector3.new(0, 0, -8) or Vector3.new(0, 0, -5)
	local Size = M1_Count >= 3 and Vector3.new(8, 8, 14) or Vector3.new(8, 8, 8)

	local TrackToBeUsed = if M1_Count == 1 then nil else  'Characters.Naruto.Abilities.M1.Victim_'..(M1_Count - 1)
	local AttackData = Ability:FromData("Attack_Data", M1_Count)
	Ability:UseAttackData(Sequence, Caster, AttackData, {
		Size = Size,
		Offset = Offset,
		Hit_Function = function(Target)

			local Offset = M1_Count >= 2 and CFrame.new(0, 2.784, 3.064) or CFrame.new()
			if Target:GetState() == 'Frozen' then
				TrackToBeUsed = nil
				Offset = CFrame.new(0, 0.75, 0)
			end
			
			Ability:Hit(Caster, Target, {Track = TrackToBeUsed, HitAirborne = true, EffectData = {
				Offset = Offset
			}})

			if M1_Count == 4 then
				Ability:Effect("GroundRocksTrail", Target, 0.5, true)
			end

			--Target:Hit()
			--Ability:Effect('Hit', Target)
		end
	})

	Sequence:Start()
end

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Agent)
	local LastCloneId = Ability:Get(Agent, "LastCloneId")

	Ability:Effect("Naruto_Clone", true, nil, nil, {Id = LastCloneId})
end)

return Ability