--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)
local LelouchController = require(script.Parent.LelouchGameplayController)

--
local Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.GenericClass)
	Ability:Save(Caster, 'HoldToken', nil)
	LelouchController:SetFocusFire(Caster, false)
end)

local function Shoot(Caster: Types.GenericClass, HitData)
	Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
		Ability:Hit(Caster, Enemy, HitData)
	end)
end

local function FocusFire(Caster: Types.GenericClass, Token: {})
	local Hold_Time = Ability:FromData('Focus_Hold_Time')
	local Shot_Interval = Ability:FromData('Focus_Shot_Interval')
	local HitData = Ability:FromData('Focus_Hit', nil, Caster:GetSkillLevel(Ability.__Name))
	local HoldStart = os.clock()

	local function IsHeld()
		return Ability:Get(Caster, 'HoldToken') == Token and Caster:IsActive()
	end

	while IsHeld() and (os.clock() - HoldStart) < Hold_Time do
		task.wait()
	end

	if not IsHeld() then
		return
	end

	LelouchController:SetFocusFire(Caster, true)

	while IsHeld() and not Caster:IsMoving() do
		Caster:SwitchState('Attacking', Shot_Interval + 0.1)
		Shoot(Caster, HitData)

		task.wait(Shot_Interval)
	end

	LelouchController:SetFocusFire(Caster, false)
end

function Ability:Play(Caster: Types.GenericClass, _, State, Ctx): ()
	if State == 'Release' then
		Ability:Save(Caster, 'HoldToken', nil)

		return
	end

	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end

	local Token = {}
	Ability:Save(Caster, 'HoldToken', Token)
	LelouchController:SetTarget(Caster, Ctx.Target)

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local Is_Geass = M1_Count == Ability:FromData('Geass_Shot')
	local HitData = Ability:FromData(if Is_Geass then "Geass_Hit" else "Hit", nil, SkillLevel)
	local IsReshoot = Ability:Get(Caster, "M1_Thread");
	local HitTime = 0.33;
	if IsReshoot then
		HitTime = 0;
		task.cancel(IsReshoot);
	end

	local Attack_State_Time = Ability:FromData('Attack_State_Time') + HitTime

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_State_Time)

			Ability:Save(Caster, "M1_Thread", task.delay(0.8, function()
				Ability:Save(Caster, "M1_Thread", nil)
			end))
		end},

		{HitTime, function()
			Shoot(Caster, HitData)

			if Is_Geass then
				LelouchController:SummonKnights(Caster, 1)
			end
		end}
	}, true)

	Sequence:Start()

	FocusFire(Caster, Token)
end

return Ability
