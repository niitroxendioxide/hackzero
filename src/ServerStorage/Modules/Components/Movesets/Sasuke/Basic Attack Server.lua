--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local SasukeGameplayController = require("./SasukeGameplayController")

--
local Ability = AbilityClass.new()

local function ShootShurikensWithData(Caster: Types.ServerAgent, Info: { number })
	local Amount = Info[1];
	local Angle = Info[2];
	local FireProjectile = Caster:HasTag("SharinganActive")
	local ShurikenSize = Ability:FromData("ShurikenSize")
	local ShurikenHit = Table.CopyDeep(Ability:FromData("ShurikenHit"))

	if FireProjectile then
		ShurikenHit.Affliction = 'Fire';
		ShurikenHit.Affliction_Buildup += 10;
	end

	for i = 1, Amount do
		local new_Angle = -(Angle / 2) + (Angle * (i - 1) / (Amount - 1))
		local Origin = Caster:GetPivot() * CFrame.Angles(0, math.rad(new_Angle), 0)

		local Projectile; Projectile = Ability:CreateMovingHitbox(Caster, Origin, ShurikenSize, 95, 1, function(Target)
			Projectile:Destroy()
			Ability:Hit(Caster, Target, ShurikenHit)
		end)
	end
end

local function HandleShurikenBarrage(Caster: Types.ServerAgent, Target: Types.ServerEnemy)
	Ability:Save(Caster, "Holding", true)
	
	local EditedSpeed =  Caster:GetStat('Speed') * Ability:FromData("Speed") * Ability:FromData("Animation_Speed")
	Caster:SwitchState("Attacking", 2.15 / EditedSpeed)

	local DelayedOrigin = os.clock()
	local Started = os.clock()
	local Batch = 0;
	local DelayedTime = 0
	local Finished = false;
	
	while (Ability:Get(Caster, "Holding") == true) do
		if (os.clock() - Started) >= (2.15 / EditedSpeed) then
			Finished = true
			break
		end

		if Caster:GetState() ~= 'Attacking' then
			return false
		end

		if Batch < 3 and (os.clock() - Started >= (1.45 / EditedSpeed)) then
			Batch = 3
			DelayedTime = 0.65
			Caster:Walk(0.45, -1.25)
			DelayedOrigin = os.clock()

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			task.delay(0.3 / EditedSpeed, function()
				ShootShurikensWithData(Caster, ConfigData)
			end)
		elseif Batch < 2 and (os.clock() - Started >= (.7 / EditedSpeed)) then
			Batch = 2
			DelayedTime = 0.23
			Caster:Walk(0.1, -1)
			DelayedOrigin = os.clock()

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			ShootShurikensWithData(Caster, ConfigData)
		elseif Batch < 1 and (os.clock() - Started >= (.233 / EditedSpeed)) then
			Batch = 1
			DelayedTime = 0.3
			DelayedOrigin = os.clock()

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			task.delay(0.2 / EditedSpeed, function()
				Caster:Walk(0.1, -1)
				ShootShurikensWithData(Caster, ConfigData)
			end)
		end

		if Target ~= nil then
			Caster:LookAtTarget(Target)
		end

		task.wait()
	end

	if Batch > 0 then
		local RemainingTime = 0;
		if DelayedTime > 0 then
			RemainingTime = DelayedTime - (os.clock() - DelayedOrigin)
		end

		task.delay(RemainingTime, function()
			if Finished then return end
		end)
		
		return false
	end

	return true
end

function Ability:Play(Caster: Types.Caster, _, State, Context): ()
	if State == 'Begin' then
		local ShouldContinue = HandleShurikenBarrage(Caster, Context.Target);
		if not ShouldContinue then
			return
		end
	elseif State == 'Release' then
		Ability:Save(Caster, "Holding", false)
		return
	end
	
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local BaseHitData = Table.CopyDeep(Ability:FromData("Hit"))
	local Attack_Data = Ability:FromData("Attack_Data")
	local ShurikenSize = Ability:FromData("ShurikenSize")
	

	local Sequence = Ability:Begin(Caster, {
		{0, function()
		end},
	}, true)

	for i = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[i]
		if not TickData then
			break
		end

		BaseHitData.Damage = Ability:FromData("Damage", i, SkillLevel)
		BaseHitData.Daze = Ability:FromData("Daze", i, SkillLevel)

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = Ability:FromData("HitboxSize"),
			Offset = Ability:FromData("HitboxOffset"),

			Hit_Function = function(Target)
				if i == 2.1 then
					BaseHitData.Knockback = {
						vector.create(0, 0, 1),
						36,
						0.2,
					}
				end

				Ability:Hit(Caster, Target, BaseHitData)
			end
		})

		if i == 3.1 then
			Sequence:Add(1, function()
				local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot(), ShurikenSize, 95, 1, function(Target)
					SasukeGameplayController:ConnectThread(Target, Caster)
					Object:Destroy()

					Ability:Hit(Caster, Target, BaseHitData)
				end)
			end)
		end
	end

	Sequence:Start()
end

return Ability
