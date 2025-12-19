--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Base(Caster: Types.AgentClass)		
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Ability:Effect('Goku_Sledgehammer', Caster, false)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, "Goku.Abilities.Special.Default", {Fade = .1, Active_Time = Attack_Time})

			Ability:Effect("Glow", Caster)
		end},

		{.2, function()
			Caster:Walk(Ability:FromData('Walk_Time'))
		end},

		{0.23, function()
			Ability:Effect("Goku_Sledgehammer", Caster, true)
		end},

		{0.267, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3.5, vector.one * 6, function(Enemy: Types.ClientEnemy) 
				Ability:Hit(Caster, Enemy, {})
			end)
		end},
	})
end

function InMode(Caster: Types.AgentClass)
	local Attack_Time = Ability:FromData("Attack_State_Time")

	-- since this is a teleportmove, we need to wait for the server response;
	local InitialCF: CFrame? = nil;
	local ActiveTrack;

	Ability:Begin(Caster, {
		{0, function(self)
			ActiveTrack = Ability:PlayAnimation(Caster, "Goku.Abilities.Special.TpPrep", {Fade = .03, Active_Time = Attack_Time})
			Caster:SwitchState('Attacking', Attack_Time)
			InitialCF = Caster:GetPivot();

			-- yield before any other event
			Caster:AwaitServerTriggeredAction(GameEnum.Replication.PivotTo);
		end},


		{1/60, function()
			-- this should occur one frame after the teleport
			-- play an effect at InitialCF;
			if ActiveTrack then
				ActiveTrack:Stop();
			end

			Ability:PlayAnimation(Caster, "Goku.Abilities.Special.AfterTpKick", {Fade = .03, Active_Time = Attack_Time, Speed = 1 / 1.3})

			Ability:Effect("Glow", Caster)
		end},
	})
end

Ability:SetTargetFinder(function(Caster)
	return Enemies:GetNearestEnemy(Caster:GetPivot().Position, 35);
end)

function Ability:Play(Caster: Types.AgentClass)
	local IsInMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	
	-- // default
	if IsInMode then
		InMode(Caster)
	else
		Base(Caster)
	end
end

return Ability
