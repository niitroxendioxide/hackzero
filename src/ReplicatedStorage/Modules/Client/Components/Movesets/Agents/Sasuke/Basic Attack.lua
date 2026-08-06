--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)
local Animation = require(Client.Libraries.Animation)

--
local Ability = AbilityClass.new(true)

local function ShootShurikensWithData(Caster: Types.AgentClass, Info: { number })
	local Amount = Info[1];
	local Angle = Info[2];
	local FireProjectile = Caster:HasTag("SharinganActive")
	
	local ShurikenSize = Ability:FromData("ShurikenSize")

	for i = Amount // 2, -Amount // 2, -math.sign(Amount) do
		local new_Angle = Angle * i;
		local Origin = CFrame.Angles(0, math.rad(new_Angle), 0)

		Ability:Effect("KunaiProjectile", Caster, 95, 1, ShurikenSize, true, true, Origin, FireProjectile)
	end
end


local function HandleShurikenBarrage(Caster: Types.AgentClass, Target: Types.ClientEnemy)
	Ability:Save(Caster, "Holding", true)

	local CurrentTrack = Ability:PlayAnimation(Caster, "Sasuke.Abilities.M1.ThrowShurikens", {})
	Caster:SwitchState("Attacking", 2.15)
	
	Animation:StopTracksWithTag(Caster:GetModel(), "Dodge")
	
	local Started = os.clock()
	local Batch = 0;
	local DelayedTime = 0
	local DelayedOrigin = os.clock()
	local Finished = false

	while (Ability:Get(Caster, "Holding") == true) do
		if (os.clock() - Started) >= 2.15 then
			Finished = true
			break
		end

		if Caster:GetState() ~= 'Attacking' then
			CurrentTrack:Stop(0.1)
			Caster:Walk(0.001, 0)

			return false
		end

		if Batch < 3 and (os.clock() - Started >= 1.45) then
			Batch = 3
			DelayedTime = 0.65
			DelayedOrigin = os.clock()
			Caster:Walk(0.45, -1.25)

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			task.delay(0.3, function()
				ShootShurikensWithData(Caster, ConfigData)
			end)
		elseif Batch < 2 and (os.clock() - Started >= .7) then
			Batch = 2
			DelayedTime = 0.23
			DelayedOrigin = os.clock()
			Caster:Walk(0.1, -1)

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			ShootShurikensWithData(Caster, ConfigData)
		elseif Batch < 1 and (os.clock() - Started >= .233) then
			Batch = 1
			DelayedTime = 0.3
			DelayedOrigin = os.clock()

			local ConfigData = Ability:FromData("ShurikenConfigs", Batch)
			task.delay(0.2, function()
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

			CurrentTrack:AdjustSpeed(0.01)
			CurrentTrack:Stop(.35)
			Caster:SwitchState("Attacking", 0.15)
		end)
		
		return false
	end

	return true
end

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 3})
end)

function Ability:Play(Caster: Types.AgentClass, _key, State, Ctx)
	local M1_Count = Ability:Get(Caster, 'Count')
	if State == 'Begin' then
		local ShouldContinue = HandleShurikenBarrage(Caster, Ctx.Target)
		if not ShouldContinue then
			return
		end
	else
		Ability:Save(Caster, "Holding", false)

		return
	end

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	--
	local ShurikenSize = Ability:FromData("ShurikenSize")
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	local Attack_Data = Ability:FromData('Attack_Data')
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:PlayAnimation(Caster, 'Sasuke.Abilities.M1.'..M1_Count, {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{0.267, function()
			Caster:LookAtTarget(Ctx.Target)
			if M1_Count == 1 then
				Ability:Effect("Sasuke_M1", Caster, CFrame.new(-0.536, 0.23, -3.885) * CFrame.Angles(0, math.rad(11.25), 0))
			end
		end},

		{0.567, function()
			Caster:LookAtTarget(Ctx.Target)

			if M1_Count == 3 then
				Ability:Effect("Goku_M1_5", Caster, 0.4, true)
			end
		end},
		
		{0.65, function()
			Caster:LookAtTarget(Ctx.Target)
			if M1_Count == 1 then
				Ability:Effect("Sasuke_M1", Caster, CFrame.new(0.042, -0.032, -3.885) * CFrame.Angles(0, math.rad(-11.25), 0))
			end

		end},

		{1, function()
			Caster:LookAtTarget(Ctx.Target)
			if M1_Count == 3 then
				Ability:Effect("KunaiProjectile", Caster, 75, 1, ShurikenSize, true)
			end
		end},
	}, true)

	
	for i = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[i]
		if not TickData then
			break
		end

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = Ability:FromData("HitboxSize"),
			Offset = Ability:FromData("HitboxOffset"),

			Hit_Function = function(Target)
				Ability:Hit(Caster, Target, {EffectData = {Highlight = true}, NoHitStop = true})
			end
		})
	end

	Sequence:Start()

end

return Ability