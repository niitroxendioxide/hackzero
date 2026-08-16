--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local AbilityClass = require(Classes.Combat.ServerAbility)
local Types = require(Shared.Types.Abilities)

--
local Ability = AbilityClass.new()

function UseGodFist(Caster: Types.Caster)
	local Data = Ability:FromData("SuperGodFist")

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData('SuperGodFistHit', nil, SkillLevel)

	local function HitEnemy()
		
		Ability:CreateHitbox(Caster, vector.create(0, 0, -7), vector.create(8.5, 6.4, 14.5), function(Enemy)  
			Ability:Hit(Caster, Enemy, HitData)
		end)

	end

	Caster:UpdateMeter('SaiyanSurge', -2)

	Ability:Begin(Caster, {	
		{0, function()
			Caster:SwitchState('Attacking', Data.Attack_State_Time, true)
		end},

		{0.35, function()
			Caster:ImpulseForward(100, 0.75)
		end},

		{0.45, HitEnemy},
		{0.55, HitEnemy},
		{0.65, HitEnemy},
		
	})
end

local function AddSlamFrames(Caster: Types.ClientAgent, Sequence: Types.Sequence)
	local SledgeHammerData = Ability:FromData("SledgeHammerData")

	Sequence:Add(0, function()
		Caster:SwitchState('Attacking', 0.6)
	end)

	Sequence:Add(0.2, function()
		Caster:Walk(0.3, 1, true)
	end)

	Sequence:Add(0.5, function()
		Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.one * 10, function(Enemy)
			Ability:Hit(Caster, Enemy, SledgeHammerData)
		end)
	end)
end

local function AddDiveKickFrames(Caster: Types.ClientAgent, Target: Types.ClientEnemy, Sequence: Types.Sequence)
	local DiveKickHitData = Ability:FromData("DiveKickHitData")
	
	Sequence:Add(0, function()
		Caster:SwitchState('Attacking', 0.9)
	end)

	Sequence:Add(0.3, function()
		Caster:Walk(0.6, .75, true)
	end)

	Sequence:Add(0.7, function()
		Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(5, 5, 10), function(HitTarget)
			if not HitTarget:IsAirborne() then
				return
			end

			Ability:Hit(Caster, HitTarget, DiveKickHitData)
		end)
	end)
end

local function AddDefaultM1Frames(Caster: Types.ClientAgent, Target: any, M1_Count: number, Sequence: Types.Sequence)
	if M1_Count == 6 then
		Sequence:Add(0.18, 0.45, function()
			Caster:LookAtTarget(Target)
		end)
	elseif M1_Count == 5 then

	elseif M1_Count == 4 then

	elseif M1_Count == 3 then

	elseif M1_Count == 2 then
		Sequence:Add(0.43, function()
			Caster:Walk(0.2, 2)
		end)
	elseif M1_Count == 1 then

	end
end

function Ability:Play(Caster, _, State, Context): ()
	local M1_Count = (Context.M1_Count :: number)
	local Meter = Caster:GetMeter("SaiyanSurge")
	if (not M1_Count) then
		return
	end

	local ActiveWaitThread = Ability:Get(Caster, 'ActiveWaitThread')
	if ActiveWaitThread ~= nil then
		task.cancel(ActiveWaitThread)
		Ability:Save(Caster, 'ActiveWaitThread', nil)
	end

	local Held_Time = os.clock() - (Ability:Get(Caster, 'TimeStart') or 0)
	Ability:Save(Caster, 'TimeStart', os.clock())

	if ((State == 'Begin' and Meter >= 2) or (State == 'Release')) then
		local Should_Release = State == 'Release' and Meter >= 2 and (Ability:Get(Caster, 'UsedInHeld') ~= true)
		local Was_Held = (Held_Time > 0.4)

		if Should_Release and Was_Held then
			UseGodFist(Caster)
			Ability:Save(Caster, 'TimeStart', os.clock())

			return
		elseif State == 'Begin' then
			Ability:Save(Caster, 'ActiveWaitThread', task.delay(0.4, function()
				UseGodFist(Caster)
				Ability:Save(Caster, 'UsedInHeld', true)
			end))
		elseif State == 'Release' then
			Ability:Save(Caster, 'UsedInHeld', false)
			return;
		end
	end

	---
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local IsPlayerMidAir = Caster:HasTag('Airborne')

	local Target = Context.Target
	local IsDiveKick = false
	local IsSlam = false
	local Size = vector.create(9, 7, 10.5)
	local Offset = vector.create(0, 0, -5)

	local Hit_Data = Table.CopyDeep(Ability:FromData("Hit_Data"))
	local Attack_Data = Ability:FromData('Attack_Data')

	do
		if IsPlayerMidAir and Target:GetState() ~= 'Airborne' then
			IsSlam = true
			Caster:RemoveTag('Airborne')
		elseif Target ~= nil and Target:HasTag('DiveKickable') then
			Target:RemoveTag('DiveKickable')
			IsDiveKick = true
		end
	end

	local CasterIsAirborne = Caster:HasTag('Airborne')
	local Sequence = Ability:Begin(Caster, {}, true)

	if IsSlam then
		AddSlamFrames(Caster, Sequence)
	elseif IsDiveKick then
		AddDiveKickFrames(Caster, Target, Sequence)
	else
		AddDefaultM1Frames(Caster, Target, M1_Count, Sequence)
	end

	for HitId = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[HitId]
		if not(TickData) or (IsSlam or IsDiveKick) then
			break
		end

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = Size,
			Offset = Offset,
			Hit_Function = function(HitEnemy)
				if HitEnemy:IsAirborne() and not CasterIsAirborne then
					return
				elseif CasterIsAirborne and not HitEnemy:IsAirborne() then
					return
				end

				Hit_Data.Damage = Ability:FromData("Damage_Mult", HitId, SkillLevel)
				Hit_Data.Daze = Ability:FromData("Daze_Mult", HitId, SkillLevel)
				Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", HitId, SkillLevel)

				local Result = Ability:Hit(Caster, HitEnemy, Hit_Data)
				if typeof(Result) == 'table' and (M1_Count == 6 or Result.IsKill) then
					Caster:UpdateMeter('SaiyanSurge', 1);
				end
			end
		})
	end

	Sequence:Start()
end

return Ability


--[[Ability:Begin(Caster, {
		{0, function()
			if IsPlayerMidAir and Target:GetState() ~= 'Airborne' then
				IsSlam = true
				Caster:RemoveTag('Airborne')
			end

			if Target:HasTag('DiveKickable') then
				Target:RemoveTag('DiveKickable')
				IsDiveKick = true
				Attack_Time = .9
			end

			Caster:SwitchState('Attacking', Attack_Time)
		end,},

		-- 1ST M1
		{.1, function()
			if M1_Count == 1 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end,},

		-- 2ND M1
		{0.15, function()
			if M1_Count == 2 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.43, function()
			if M1_Count == 2 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time') + .1, 2)
			end
		end},

		-- 3RD M1
		{0.2, function()
			if M1_Count == 3 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		-- 4TH M1
		{0.06, function()
			if M1_Count == 4 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.1)
			end
		end},

		-- 5TH M1
		{0.27, function()
			if M1_Count == 5 and not IsDiveKick and not IsSlam then
				Caster:WalkBack(Ability:FromData('Walk_Time') + 0.3, -2)
			end
		end},

		-- 6TH M1
		{0.18, function()
			if M1_Count == 6 and not IsDiveKick and not IsSlam then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.12, 2, true)
			end
		end},

		{0.3, function()
			if not IsDiveKick then return end

			Caster:Walk(0.6, .75, true)
		end},

		{0.2, function()
			if not IsSlam then return end

			Caster:Walk(0.25, .5, true)
		end},


		{Ability:FromData("Hit_Times", M1_Count), function()
			if IsDiveKick then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Hit_Data.Damage = Ability:FromData("Damage_Mult", M1_Count, SkillLevel)
				Hit_Data.Daze = Ability:FromData("Daze_Mult", M1_Count, SkillLevel)
				Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", M1_Count, SkillLevel)

				local Result = Ability:Hit(Caster, Target, Hit_Data)
				if typeof(Result) == 'table' and (M1_Count == 6 or Result.IsKill) then
					Caster:UpdateMeter('SaiyanSurge', 1);
				end
			end, M1_Count == 6 and 0.45 or nil)
		end,},

		{.54, function()
			if IsDiveKick then return end
			if M1_Count ~= 4 then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Hit_Data.Damage = Ability:FromData("Damage_Mult", 4.5, SkillLevel)
				Hit_Data.Daze = Ability:FromData("Daze_Mult", 4.5, SkillLevel)
				Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", 4.5, SkillLevel)

				Ability:Hit(Caster, Target, Hit_Data)
			end)
		end,},

		{.5, function()
			if IsDiveKick then return end
			if not (M1_Count == 2) and (not IsSlam) then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				if not IsSlam then
					Hit_Data.Damage = Ability:FromData("Damage_Mult", 2.5, SkillLevel)
					Hit_Data.Daze = Ability:FromData("Daze_Mult", 2.5, SkillLevel)
					Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", 2.5, SkillLevel)

					Ability:Hit(Caster, Target, Hit_Data)
				else
					Ability:Hit(Caster, Target, SledgeHammerData)
				end
			end)
		end,},

		{0.7, function()
			if not IsDiveKick then return end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(5, 5, 10), function(Target)
				Ability:Hit(Caster, Target, DiveKickHitData)
			end)
		end}
	})]]