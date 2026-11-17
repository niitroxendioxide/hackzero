--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = Ability:FromData('Geass_Shot')})
end)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Save(Caster, 'HoldToken', nil)
end)

const function Shoot(Caster: Types.ClientAgent)
	Ability:Effect("Lelouch_UsShoot", Caster);
	Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
		Ability:Hit(Caster, Enemy, {EffectData = {}, NoCameraShake = true, NoHitStop = true})
	end)
end

const function Geass(Caster: Types.ClientAgent)
	if Ability:Get(Caster, "GeassCD") then
		return false
	end
	Ability:Save(Caster, "Holding", true)

	local Track = nil;
	const Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', 0.5)
			Track = Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Geass', {
				Fade = .1,
			})
		end},

		{0.35, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(4, 4, 50), function(Enemy)
				Ability:Effect("Lelouch_GeassAffect", Enemy:GetId());
			end)
		end},
	})
	
	const Start = os.clock();
	while (os.clock() - Start) < 0.25 do
		if Ability:Get(Caster, "Holding") ~= true then
			if Track and Track.IsPlaying then
				Track:Stop()
			end

			Sequence:Destroy()

			return false
		end

		task.wait()
	end

	Ability:Save(Caster, "GeassCD", true)
	task.delay(7, function()
		Ability:Save(Caster, "GeassCD", false)
	end)

	return Sequence
end

function Ability:Play(Caster: Types.ClientAgent, _, State, Context)
	local CanReshoot = Ability:Get(Caster, 'M1_Track') and Ability:Get(Caster, 'M1_Track').IsPlaying;
	local AddedTime = 0;
	
	if State ~= 'Begin' then
		Ability:Save(Caster, "Holding", false)

		return;
	end

	const ResultSequence = Geass(Caster)
	if ResultSequence ~= false then
		AddedTime = 0.33;
		CanReshoot = false;
	end

	local Time = (0.33)
	if CanReshoot then
		Time = 0
	else
		Ability:Save(Caster, 'M1_Track', nil)
	end

	---
	local Attack_State_Time = Ability:FromData("Attack_State_Time") + Time;
	const UsedSequence = ResultSequence ~= false and ResultSequence or Ability:Begin(Caster, {}, true)

	UsedSequence:Add(0 + AddedTime, function()
		local Track = Ability:Get(Caster, "M1_Track")
		if not Track then
			Track = Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot'..math.random(1, 3), {
				Fade = .1,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		else
			Track.TimePosition = 0.3
		end

		Caster:SwitchState('Attacking', Attack_State_Time)
	end)

	UsedSequence:Add(Time + AddedTime, function()
		if Context.Target then
			Caster:LookAtTarget(Context.Target)
		end

		Caster:WalkBack(0.15, 1.15)

		Shoot(Caster)
	end)


	UsedSequence:Start()
end

return Ability
