--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require(ReplicatedStorage.Modules.Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

--[[Ability:SetTargetFinder(function(Caster)
	local last_target = Ability:Get(Caster, "last_hit_enemy");
	if ((Ability:Get(Caster, 'Count') or 0) >= 5) and (last_target ~= nil) then
		return (last_target):GetId(), last_target
	end


	--
	local id, nearest = Enemies:GetNearestEnemy(Caster:GetPivot().Position, 75, false, nil, function(Target: Types.ClientEnemy)
		if Target:IsAirborne() then
			return 0.95
		end

		return 1;
	end)

	return id, nearest;
end)]]

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 6})
end)

function UseGodFist(Caster)
	local Data = Ability:FromData("SuperGodFist")

	local function HitEnemy()
		
		Ability:CreateHitbox(Caster, vector.create(0, 0, -7), vector.create(8.5, 6.4, 14.5), function(Enemy)  
			Ability:Hit(Caster, Enemy, {})
		end)

	end

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, 'Goku.Abilities.M1.SuperGodFist', {
				Fade = .1,
				Active_Time = Data.Attack_State_Time,
			})

			Caster:SwitchState('Attacking', Data.Attack_State_Time, true)
			Ability:Effect("Goku_SuperGodFist", Caster, 'Charge')
		end},

		{0.35, function()
			Caster:ImpulseForward(60, 0.75)
		end},

		{0.45, function()
			Ability:Effect("Goku_SuperGodFist", Caster, 'Attack')
		end},

		{0.45, HitEnemy},
		{0.55, HitEnemy},
		{0.65, HitEnemy},
	})
end

local function AddSlamFrames(Caster: Types.ClientAgent, Sequence: Types.Sequence)
	local Effect_Data = Ability:FromData("Effect_Data")

	Sequence:Add(0, function()
		Caster:SwitchState('Attacking', 0.6)
	end)

	Sequence:Add(0.2, function()
		Caster:Walk(0.3, 1, true)
	end)

	Sequence:Add(0.06, function()
		Ability:Effect("Goku_Spinning", Caster, 0.225 / (Ability:FromData("Speed") or 1));
	end)

	Sequence:Add(0.5, function()
		Ability:Effect("Goku_Sledgehammer", Caster, true)

		Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.one * 10, function(Enemy)
			Ability:Hit(Caster, Enemy, {EffectData = Effect_Data, NoHitStop = true, Track = 'Characters.Naruto.Abilities.M1.Victim_3', HitAirborne = true})

			Ability:Effect("GroundRocksTrail", Enemy, 0.5, false)
		end)
	end)
end

local function AddDiveKickFrames(Caster: Types.ClientAgent, Target: Types.ClientEnemy, Sequence: Types.Sequence)
	local Effect_Data = Ability:FromData("Effect_Data")

	Sequence:Add(0, function()
		Caster:SwitchState('Attacking', 0.9)
	end)

	Sequence:Add(0.3, function()
		Caster:Walk(0.6, .75, true)
	end)
	
	Sequence:Add(0.3, 0.7, function()
		Caster:LookAtTarget(Target)
	end)
	
	Sequence:Add(0.63, function()
		Ability:Effect("Goku_DiveKick", Caster, true)
	end)

	Sequence:Add(0.7, function()
		local played_effect = false

		Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(5, 5, 10), function(HitEnemy)
			if not HitEnemy:IsAirborne() then
				return
			end

			if not played_effect then
				played_effect = true
				Ability:Effect("Goku_DiveKick", Caster, false)
			end

			Ability:Hit(Caster, HitEnemy, {EffectData = Effect_Data, NoHitStop = true, HitAirborne = true})
		end)
	end)
end

local function AddDefaultM1Frames(Caster: Types.ClientAgent, M1_Count: number, Sequence: Types.Sequence)
	if M1_Count == 6 then
		Sequence:Add(0.18, function()
			Ability:Effect("Goku_M1_2", Caster);
		end)

	elseif M1_Count == 5 then
		Sequence:Add(0.27, function()
			Ability:Effect("Goku_M1_5", Caster)
		end)

	elseif M1_Count == 4 then
		Sequence:Add(0.233, function()
			Ability:Effect("Goku_M1_4", Caster);
		end)

		Sequence:Add(0.5, function()
			Ability:Effect("Goku_M1_4", Caster, 2);
		end)

	elseif M1_Count == 3 then
		Sequence:Add(0.2, function()
			Ability:Effect("Goku_M1_2", Caster, 3);
		end)

	elseif M1_Count == 2 then
		Sequence:Add(0.567, function()
			Ability:Effect("Goku_M1_1", Caster);
		end)

		Sequence:Add(0.43, function()
			Caster:Walk(0.2, 2)
		end)

	elseif M1_Count == 1 then
		Sequence:Add(0.15, function()
			Ability:Effect("Goku_M1_1", Caster);
		end)
	end
end

function Ability:Play(Caster: Types.ClientAgent, _, State, Context)
	local M1_Count = Ability:Get(Caster, 'Count')
	local Meter = Caster:GetMeter("SaiyanSurge")
	
	Ability:Save(Caster, "last_hit_enemy", Context.Target);
	
	local ActiveWaitThread = Ability:Get(Caster, 'ActiveWaitThread')
	if ActiveWaitThread ~= nil then
		task.cancel(ActiveWaitThread)
		Ability:Save(Caster, 'ActiveWaitThread', nil)
	end

	local Held_Time = os.clock() - (Ability:Get(Caster, 'TimeStart') or 0)
	Ability:Save(Caster, 'TimeStart', os.clock())

	if ((State == 'Begin' and Meter >= 2) or (State == 'End')) then
		local Should_Release = State == 'End' and Meter >= 2 and (Ability:Get(Caster, 'UsedInHeld') ~= true)
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
		elseif State == 'End' then
			Ability:Save(Caster, 'UsedInHeld', false)
			return;
		end
	end

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.2)
	end

	local Target = Context.Target
	local IsDiveKick = false
	local IsSlam = false
	local Effect_Data = Ability:FromData('Effect_Data')
	local Attack_Data = Ability:FromData('Attack_Data')

	do
		-- setup attack pre-sequence
		local AnimTrackId = 'Goku.Abilities.M1.'..Ability:Get(Caster, 'Count')
		local Result = Ability:MatchAirborneHeights(Caster, Target, 2.15, false, 0.175);
		if Result == GameEnum.AirborneMatchState.Raised then
			Ability:Effect("Goku_RaiseVfx", Caster)
		elseif Result == GameEnum.AirborneMatchState.Grounded then
			IsSlam = true
			AnimTrackId = 'Goku.Abilities.M1.Sledgehammer'
		end

		if Target ~= nil and Target:HasTag('DiveKickable') then
			IsDiveKick = true
			AnimTrackId = 'Goku.Abilities.M1.DiveKick'
		end

		local Track = Ability:PlayAnimation(Caster, AnimTrackId, {
			Fade = .1,
		})

		Ability:Save(Caster, 'M1_Track', Track)
	end

	local AgentAirborne = Caster:IsAirborne()
	local Sequence = Ability:Begin(Caster, {}, true)

	if IsSlam then
		AddSlamFrames(Caster, Sequence)
	elseif IsDiveKick then
		AddDiveKickFrames(Caster, Target, Sequence)
	elseif not IsSlam and not IsDiveKick then
		AddDefaultM1Frames(Caster, M1_Count, Sequence)
	end 

	for HitId = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[HitId]
		if not(TickData) or (IsSlam or IsDiveKick) then
			break
		end

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = vector.create(9, 7, 10.5),
			Offset = vector.create(0, 0, -5),
			Hit_Function = function(HitEnemy)
				if (AgentAirborne == true and not HitEnemy:IsAirborne()) or (HitEnemy:IsAirborne() and not AgentAirborne) then
					return
				end

				Ability:Hit(Caster, HitEnemy, {EffectData = Effect_Data, NoHitStop = true, HitAirborne = true})
			end
		})
	end

	Sequence:Start()
end

return Ability