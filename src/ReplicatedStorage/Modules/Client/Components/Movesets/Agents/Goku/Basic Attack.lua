--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)
local Enemies = require(Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)

--
local Ability = AbilityClass.new(true)

Ability:SetTargetFinder(function(Caster)
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
end)

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

function Ability:Play(Caster, _, State, Context)
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
	local Effect_Data = Ability:FromData('Effect_Data')
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)

	Ability:Begin(Caster, {
		{0, function()
			local Result = Ability:MatchAirborneHeights(Caster, Target, 2);
			if Result == GameEnum.AirborneMatchState.Raised then
				Ability:Effect("Goku_RaiseVfx", Caster)
			end

			local AttackTime = Attack_Time / (Ability:FromData('Speed') or 1)
			local AnimTrackId = 'Goku.Abilities.M1.'..Ability:Get(Caster, 'Count')

			if Target ~= nil and Target:HasTag('DiveKickable') then
				IsDiveKick = true
				AttackTime = .9
				AnimTrackId = 'Goku.Abilities.M1.DiveKick'
			end
			
			Caster:SwitchState('Attacking', AttackTime)
			
			local Track = Ability:PlayAnimation(Caster, AnimTrackId, {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		-- 1ST M1
		{.1, function()
			if M1_Count == 1 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end,},

		-- 2ND M1
		{0.15, function()
			if M1_Count == 1 and not IsDiveKick then
				Ability:Effect("Goku_M1_1", Caster);
			end

			if M1_Count == 2 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.43, function()
			if M1_Count == 2 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Caster:Walk(Ability:FromData('Walk_Time') + .1, 2)
			end
		end},

		-- 3RD M1
		{0.2, function()
			if M1_Count == 3 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Ability:Effect("Goku_M1_2", Caster, 3);
				Caster:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.233, function()
			if M1_Count == 4 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Ability:Effect("Goku_M1_4", Caster);
			end
		end},

		-- 4TH M1
		{0.06, function()
			if M1_Count == 4 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Caster:Walk(Ability:FromData('Walk_Time') + 0.1)
			end
		end},

		-- 5TH M1
		{0.27, function()
			if M1_Count == 5 and not IsDiveKick then
				Ability:MatchAirborneHeights(Caster, Target, 2);
				Ability:Effect("Goku_M1_5", Caster)
				Caster:WalkBack(Ability:FromData('Walk_Time') + 0.3, 2)
			end
		end},

		-- 6TH M1
		{0.18, function()
			if M1_Count == 2 and not IsDiveKick then
				Ability:Effect("Goku_M1_2", Caster);
			end

			if M1_Count == 6 and not IsDiveKick then
				Ability:Effect("Goku_M1_6", Caster)
				Ability:MatchAirborneHeights(Caster, Target, 2);

				Caster:Walk(Ability:FromData('Walk_Time') + 0.18, 2.5)
			end
		end},

		{Ability:FromData("Hit_Times", M1_Count), function()
			if M1_Count == 6 and not IsDiveKick then
				Ability:Effect("Goku_M1_1", Caster);
			end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Caster, Target, {EffectData = Effect_Data, NoHitStop = true})
			end)
		end,},

		{.567, function()
			if M1_Count == 2 and not IsDiveKick then
				Ability:Effect("Goku_M1_1", Caster);
			end
			if M1_Count ~= 4 or IsDiveKick then return end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Caster, Target, {EffectData = Effect_Data, NoHitStop = true})
			end)
		end,},

		{0.3, function()
			if not IsDiveKick then
				return
			end

			Caster:Walk(0.6, .75, true)
		end},

		{.3, 0.7, function()
			if not IsDiveKick then return end

			Caster:LookAtTarget(Target)
		end,},

		{.7, function()
			if not IsDiveKick then return end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(5, 5, 10), function(Target)
				Ability:Hit(Caster, Target, {EffectData = Effect_Data, NoHitStop = true})
			end)
		end,},

		{.5, function()
			if M1_Count == 4 and not IsDiveKick then
				Ability:Effect("Goku_M1_4", Caster, 2);
			end
			if M1_Count ~= 2 or IsDiveKick then return end

			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Caster, Target, {EffectData = Effect_Data, NoHitStop = true})
			end)
		end,},
	})

end

return Ability