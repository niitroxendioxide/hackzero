--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

--local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:SetTargetFinder(function(Caster: Types.AgentClass)  
	return Enemies:GetNearestEnemy(Caster:GetPivot().Position, 150, true)
end)

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

function InMode(Caster: Types.AgentClass, Target: Types.ClientEnemy)
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function(self)
			Ability:PlayAnimation(Caster, "Goku.Abilities.Special.Ki_Blasts", {Fade = .03, Active_Time = Attack_Time, Speed = 0.77})
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{0.267, function()
			-- ki blast
			--Caster:LookAtTarget()
			Ability:Effect("Goku_KiBlast", Caster, false)
		end},

		{0.4, function()
			-- ki blast
			Ability:Effect("Goku_KiBlast", Caster, true)
		end},

		{0.533, function()
			-- ki blast
			Ability:Effect("Goku_KiBlast", Caster, false)
		end}
	})
end

function Ability:Play(Caster: Types.AgentClass, _, _, Context)
	local IsInMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	
	-- // default
	if IsInMode then
		InMode(Caster)
	else
		Base(Caster)
	end
end

return Ability
