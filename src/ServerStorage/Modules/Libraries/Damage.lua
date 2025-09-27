--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AgentTypes = require(Shared.Types.Agents)
local DefaultTypes = require(Shared.Types)
local Defense_Factors = require(Shared.Database.Defense)

local Mock = require(Shared.Utility.Mock) --[[{
	RunHook = function() end,
	RunHitProcesses = function() end
}
Mock.__index = function(t, k)
	return function()
		return nil
	end
end]]

--
local RNG = Random.new()
local DamageLibrary = {}

function DamageLibrary:Deal(Agent: any, Enemy:AgentTypes.Enemy, Data: Types.HitEnemyData): (number, boolean, boolean, string, number, number, boolean)
	local EnemyStatus = Enemy.__Status
	local AgentGear: AgentTypes.ServerGearManager = (Agent.GetGearManager and Agent:GetGearManager()) or Mock

	-- Pre-process
	AgentGear:RunHook(GameEnum.GearHookType.HitDataSetup, {Caster = Agent, Target = Enemy, HitData = Data})

	AgentGear:RunHitProcesses("Before", {
		Agent = Agent,
		Target = Enemy,
	})

	local HitType = Data.HitType or 'None'

	-- Agent
	local Attack = Agent:GetStat('Attack')
	local Crit_Rate = Agent:GetStat('Critical_Rate')
	local Crit_Damage = 1 + Agent:GetStat('Critical_Damage') / 100
	local Penetration = Agent:GetStat('Penetration')
	local Pen_Ratio = Agent:GetStat('Pen_Ratio')
	local Affliction_Aptitude = Agent:GetStat('Affliction_Aptitude')
	local Level = Agent.__Level
	local Damage_Bonus_Mult = 1 + (Agent.GetMultBonus and (Agent:GetMultBonus(Data.Affliction :: DefaultTypes.Element) + Agent:GetMultBonus(Data.Attack_Type)) or 0)

	local Is_Critical = RNG:NextNumber(0, 100) <= Crit_Rate

	-- Enemy
	local Level_Factor = Defense_Factors[math.clamp(Level, 0, 60)]
	local Damage_Taken_Mult = EnemyStatus:GetDamageTakenMultiplier()
	local Element_Multiplier = EnemyStatus:GetElementMultiplier(Data.Affliction)
	local Raw_Defense = EnemyStatus:GetStat('Defense')
	local Defense_Mult = Level_Factor / (math.max(Raw_Defense * (1 - (Pen_Ratio / 100)) - Penetration, 0) + Level_Factor)

	--
	local Damage_Type_Extra = math.max(HitType ~= 'None' and AgentGear:GetAddedGearStat((HitType..'%') :: AgentTypes.Stat) or 1, 1)
	local Resistance_Multiplier = 1 - (EnemyStatus:GetResistanceMultiplier() / 100)
	local Crit_Mult = Is_Critical and Crit_Damage or 1
	local Raw_Damage_Mult = Data.Damage / 100
	local Base_Damage = Raw_Damage_Mult * Attack
	local Affliction_Type = Element_Multiplier < 1 and 'Weak' or Data.Affliction
	local Dazed_State_Multiplier = EnemyStatus:IsKnocked() and EnemyStatus:GetDazeMultiplier() or 1

	local Final_Damage = math.max(Base_Damage * Damage_Bonus_Mult * Crit_Mult * Defense_Mult * Element_Multiplier * Resistance_Multiplier * Damage_Taken_Mult * Dazed_State_Multiplier * Damage_Type_Extra, 1)
	local Percent_Bonus = (Final_Damage / EnemyStatus:GetStat('Max_Health')) / 0.63
	local Filled_Affliction = ((Data.Affliction_Buildup or 1) / 100) * (1 + Affliction_Aptitude/90) * (1 + Percent_Bonus)
	local Burst_Damage = 0


	-- Run any hook regarding before-hit or before-affliction
	AgentGear:RunHook(GameEnum.GearHookType.BeforeHit, {Caster = Agent, Target = Enemy, HitData = Data})
	AgentGear:RunHook(GameEnum.GearHookType.BeforeAffliction, {Caster = Agent, Target = Enemy, HitData = Data})
	--

	Enemy:TakeAffliction(Data.Affliction or 'None', Filled_Affliction)

	AgentGear:RunHook(GameEnum.GearHookType.AfterAffliction, {Caster = Agent, Target = Enemy, HitData = Data})

	local AfflictionTriggered = false;
	if Enemy:GetAffliction(Data.Affliction) >= 100 then
		AgentGear:RunHook(GameEnum.GearHookType.OnAfflictionBurst, {Caster = Agent, Target = Enemy, HitData = Data})
		-- TODO: Fix the res mult to change based on enemy stuff idk
		AfflictionTriggered = true;
		Burst_Damage = DamageLibrary:CalculateAfflictionBurst(Attack, Data.Affliction, Defense_Mult, Resistance_Multiplier, Agent, Enemy)
		Enemy:TakeDamage(Burst_Damage)
		Enemy:ResetAffliction(Data.Affliction)

		AgentGear:RunEffectProcesses({
			Agent = Agent,
			Target = Enemy,
			Element = Data.Affliction,
			Total_Damage = Burst_Damage,
		})
	end

	local EnemyDied = Enemy:TakeDamage(Final_Damage)

	-- Run hooks after damage was dealt, this is the last hook
	local AfterData = {Damage = Final_Damage, Burst = AfflictionTriggered, Burst_Damage = Burst_Damage, Is_Critical = Is_Critical}
	AgentGear:RunHook(GameEnum.GearHookType.AfterHit, {Caster = Agent, Target = Enemy, HitData = Data, ProcessedData = AfterData})
	AgentGear:RunHitProcesses("After",{
		Agent = Agent,
		Target = Enemy,
		Element = Data.Affliction,
		Total_Damage = Final_Damage,
		Critical = Is_Critical,
	})


	return Final_Damage, EnemyDied, Is_Critical, Affliction_Type, Filled_Affliction, Burst_Damage, AfflictionTriggered
end

function DamageLibrary:DealEnemyToAgent(Caster: AgentTypes.Enemy, Target: AgentTypes.ServerAgentClass, Data: Types.HitEnemyData)
	local AgentStun = Data.Stun
	local CasterStatus = Caster.__Status

	local Level_Factor = Defense_Factors[math.clamp(Target.__Level, 0, 60)]
	local Raw_Defense = Target:GetStat('Defense')

	local Pen_Ratio = CasterStatus:GetStat('Pen_Ratio') or 0
	local Penetration = CasterStatus:GetStat('Penetration') or 0

	local Attack = CasterStatus:GetStat('Attack')
	local Defense_Mult = Level_Factor / (math.max(Raw_Defense * (1 - (Pen_Ratio / 100)) - Penetration, 0) + Level_Factor)

	local Total = (Data.Damage / 100) * Attack * Defense_Mult

	Target:TakeDamage(Total)

	if AgentStun then
		Target:Hit(Caster, AgentStun)
	end
end


function DamageLibrary:Daze(Agent: AgentTypes.ServerAgentClass, Enemy: AgentTypes.Enemy, Base_Multiplier: number)
	local EnemyStatus = Enemy.__Status
	local AgentGear: AgentTypes.ServerGearManager = Agent.GetGearManager and Agent:GetGearManager()

	AgentGear:RunHook(GameEnum.GearHookType.OnDazeInflicted, {Caster = Agent, Target = Enemy})

	-- Values
	local Daze_Bonus_Attacker = AgentGear:GetAddedGearStat("Stun%")
	local Daze = Agent:GetStat('Daze')
	local Daze_Res = 1 - (EnemyStatus:GetStat('Daze_Resistance') / 100)

	--
	local Total = (Base_Multiplier / 100) * Daze * Daze_Bonus_Attacker * Daze_Res
	local Is_Stunned = Enemy:TakeDaze(Total)

	return Total, Is_Stunned
end

-- MOVE TO DATABASE LATER
local VALUES = {
	Physical = 7.13,
	Ice = 5,
	Electric = 1.25,
	Energy = 0.625,
	Fire = 0.5,
}

function DamageLibrary:CalculateAfflictionBurst(Attack: number, Type: DefaultTypes.Element, Defense: number, Resistance: number, Agent: AgentTypes.ServerAgentClass, Enemy: AgentTypes.Enemy)
	local EnemyStatus = Enemy.__Status

	local Damage_Taken_Mult = EnemyStatus:GetDamageTakenMultiplier()
	local Element_Multiplier = EnemyStatus:GetElementMultiplier(Type)

	local Aptitude_Multiplier = Agent:GetStat('Affliction_Aptitude') / 100
	local Level_Multiplier = Agent.__Level + (1 / 59) * (Agent.__Level - 1)
	local Stacked_Damage = Enemy:GetAfflictionStackedDamage(Type)
	local Base_Divider = (100 + Agent:GetStat('Attack')/100)
	local Taken_Damage = (Base_Divider + Stacked_Damage) / 100
	local Dazed_State_Multiplier = EnemyStatus:IsKnocked() and EnemyStatus:GetDazeMultiplier() or 1

	print(Level_Multiplier)

	local Resistance_Multiplier = 1 - Resistance
	local Daze_Multiplier = 1
	local Affliction_Type_Mult = VALUES[Type]
	local Total_Damage = (Attack * Affliction_Type_Mult) * Level_Multiplier * Element_Multiplier * Aptitude_Multiplier * Defense * Resistance_Multiplier * Daze_Multiplier * Taken_Damage * Dazed_State_Multiplier * Damage_Taken_Mult

	return Total_Damage
end

return DamageLibrary
