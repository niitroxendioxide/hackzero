--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityTypes = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local LelouchController = require(script.Parent.LelouchGameplayController)

--
local Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.GenericClass)
	Ability:Save(Caster, 'Holding', false)
end)

local function Shoot(Caster: Types.GenericClass, HitData)
	Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
		Ability:Hit(Caster, Enemy, HitData)
	end)
end

const function Geass(Caster: Types.GenericClass)
	if Ability:Get(Caster, "GeassCD") then
		return false
	end

	Ability:Save(Caster, "Holding", true)

	const GeassHit = Ability:FromData("Geass_Hit", nil, Caster:GetSkillLevel(Ability.Name))

	local Track = nil;
	const Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', 0.5)
		end},

		{0.35, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(4, 4, 50), function(Enemy)
				Ability:Hit(Caster, Enemy, GeassHit)
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

function Ability:Play(Caster: Types.GenericClass, _, State, Ctx): ()
	if State == 'Release' then
		Ability:Save(Caster, 'Holding', false)

		return
	end

	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end

	LelouchController:SetTarget(Caster, Ctx.Target)

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	local IsReshoot = Ability:Get(Caster, "M1_Thread");

	const ReleaseSequence = Geass(Caster);
	if ReleaseSequence ~= false then
		IsReshoot = false;
	end

	local HitTime = 0.33;
	if IsReshoot then
		HitTime = 0;
		task.cancel(IsReshoot);
	end

	const Attack_State_Time = Ability:FromData('Attack_State_Time') + HitTime
	const function FirstFrame()
		Caster:SwitchState('Attacking', Attack_State_Time)

		Ability:Save(Caster, "M1_Thread", task.delay(0.8, function()
			Ability:Save(Caster, "M1_Thread", nil)
		end))

		if ReleaseSequence ~= false then
			LelouchController:SummonKnight(Caster)
		end
	end

	const function SecondFrame()
		if Ctx.Target then
			Caster:LookAtTarget(Ctx.Target)
		end
		
		Shoot(Caster, HitData)
	end

	const UsedSequence: AbilityTypes.Sequence = ReleaseSequence ~= false and ReleaseSequence or Ability:Begin(Caster, {}, true)
	const ExtraDelay = if ReleaseSequence ~= false then 0.3 else 0

	UsedSequence:Add(0 + ExtraDelay, FirstFrame)
	UsedSequence:Add(HitTime + ExtraDelay, SecondFrame)

	UsedSequence:Start()
end

return Ability
