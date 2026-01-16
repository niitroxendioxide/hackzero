--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local AbilityClass = require(Classes.Combat.ServerAbility)
local Types = require(Shared.Types.Abilities)

--
local Ability = AbilityClass.new()

function UseGodFist(Caster: Types.Caster)
	local Data = Ability:FromData("SuperGodFist")
	local HitData = Ability:FromData('SuperGodFistHit')

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

function Ability:Play(Caster, _, State, Context): ()
	--local Is_Airborne = Context.Buffer[2];
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

	if (State == 'Begin' and Meter >= 2) or (State == 'End') then
		local Should_Release = State == 'End' and Meter >= 2
		local Was_Held = (Held_Time > 0.4)

		if Should_Release and Was_Held then
			UseGodFist(Caster)
			Ability:Save(Caster, 'TimeStart', os.clock())

			return
		elseif State == 'Begin' then
			Ability:Save(Caster, 'ActiveWaitThread', task.delay(0.4, function()
				UseGodFist(Caster)
			end))
		elseif State == 'End' then
			return;
		end
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	local Size = Vector3.one*5
	local Offset = Vector3.zAxis * -3

	local Hit_Data = Ability:FromData("Hit_Data")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time', M1_Count) / Ability:FromData('Speed'))
		end,},

		-- 1ST M1
		{.1, function()
			if M1_Count == 1 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end,},

		-- 2ND M1
		{0.15, function()
			if M1_Count == 2 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.43, function()
			if M1_Count == 2 then
				Caster:Walk(Ability:FromData('Walk_Time') + .1, 2)
			end
		end},

		-- 3RD M1
		{0.2, function()
			if M1_Count == 3 then
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		-- 4TH M1
		{0.06, function()
			if M1_Count == 4 then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.1)
			end
		end},

		-- 5TH M1
		{0.27, function()
			if M1_Count == 5 then
				Caster:WalkBack(Ability:FromData('Walk_Time') + 0.7, 1.5)
			end
		end},

		-- 6TH M1
		{0.18, function()
			if M1_Count == 6 then
				Caster:Walk(Ability:FromData('Walk_Time') + 0.18, 2.25)
			end
		end},


		{Ability:FromData("Hit_Times", M1_Count), function()
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
			if M1_Count ~= 4 then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Hit_Data.Damage = Ability:FromData("Damage_Mult", 4.5, SkillLevel)
				Hit_Data.Daze = Ability:FromData("Daze_Mult", 4.5, SkillLevel)
				Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", 4.5, SkillLevel)

				Ability:Hit(Caster, Target, Hit_Data)
			end)
		end,},

		{.5, function()
			if M1_Count ~= 2 then return end

			Ability:CreateHitbox(Caster, Offset, Size, function(Target)
				Hit_Data.Damage = Ability:FromData("Damage_Mult", 2.5, SkillLevel)
				Hit_Data.Daze = Ability:FromData("Daze_Mult", 2.5, SkillLevel)
				Hit_Data.Affliction_Buildup = Ability:FromData("Affliction_Buildup", 2.5, SkillLevel)

				Ability:Hit(Caster, Target, Hit_Data)
			end)
		end,},
	})
end

return Ability
