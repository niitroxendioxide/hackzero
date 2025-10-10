--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)
local Enemies = require(Shared.Libraries.Enemies)

--
local Ability = AbilityClass.new(true)

Ability:SetTargetFinder(function(Caster)
	local last_target = Ability:Get(Caster, "last_hit_enemy");
	if ((Ability:Get(Caster, 'Count') or 0) >= 5) and (last_target ~= nil) then
		return (last_target):GetId(), last_target
	end

	local id, nearest = Enemies:GetNearestEnemy(Caster:GetPivot().Position, 15)

	return id, nearest;
end)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 6})
end)

function Ability:Play(Agent, _, _, Context)
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.2)
	end

	--
	Ability:Save(Agent, "last_hit_enemy", Context.Target);

	local Effect_Data = Ability:FromData('Effect_Data')
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Agent, {
		{0, function()
			local Result = Ability:MatchAirborneHeights(Agent, Context.Target);
			if Result == GameEnum.AirborneMatchState.Raised then
				-- play some effecct here idk
			end

			Agent:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Agent, 'Goku.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		-- 1ST M1
		{.1, function()
			if M1_Count == 1 then
				Agent:Walk(Ability:FromData('Walk_Time'))
			end
		end,},

		-- 2ND M1
		{0.15, function()
			if M1_Count == 2 then
				Agent:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		{0.43, function()
			if M1_Count == 2 then
				Agent:Walk(Ability:FromData('Walk_Time') + .1, 2)
			end
		end},

		-- 3RD M1
		{0.2, function()
			if M1_Count == 3 then
				Agent:Walk(Ability:FromData('Walk_Time'))
			end
		end},

		-- 4TH M1
		{0.06, function()
			if M1_Count == 4 then
				Agent:Walk(Ability:FromData('Walk_Time') + 0.1)
			end
		end},

		-- 5TH M1
		{0.27, function()
			if M1_Count == 5 then
				Agent:WalkBack(Ability:FromData('Walk_Time') + 0.3, 2)
			end
		end},

		-- 6TH M1
		{0.18, function()
			if M1_Count == 6 then
				Agent:Walk(Ability:FromData('Walk_Time') + 0.18, 2.5)
			end
		end},

		{Ability:FromData("Hit_Times", M1_Count), function()
			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Agent, Target, {EffectData = Effect_Data})
			end)
		end,},

		{.567, function()
			if M1_Count ~= 4 then return end

			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Agent, Target, {EffectData = Effect_Data})
			end)
		end,},

		{.5, function()
			if M1_Count ~= 2 then return end

			Ability:CreateHitbox(Agent, Vector3.zAxis*-3, Vector3.one * 5, function(Target)
				Ability:Hit(Agent, Target, {EffectData = Effect_Data})
			end)
		end,},
	})

end

return Ability