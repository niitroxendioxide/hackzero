--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local Defense_Factors = require(Shared.Database.Defense)

--
local RNG = Random.new()
local DamageLibrary = {}

function DamageLibrary:Deal(Agent:Types.ServerAgentClass,Enemy:Types.ServerEnemyClass,Data:Types.HitEnemyData): (number, number, number, number, number)
	local EnemyStatus = Enemy.__Status
	
	-- Agent
	local Attack = Agent:GetStat('Attack')
	local Crit_Rate = Agent:GetStat('Critical_Rate')
	local Crit_Damage = 1 + Agent:GetStat('Critical_Damage') / 100
	local Penetration = Agent:GetStat('Penetration')
	local Pen_Ratio = Agent:GetStat('Pen_Ratio')
	local Affliction_Aptitude = Agent:GetStat('Affliction_Aptitude')
	local Level = Agent.__Level
	local Damage_Bonus_Mult = 1 + Agent:GetMultBonus(Data.Affliction :: Types.Element) + Agent:GetMultBonus(Data.Attack_Type)
	
	local Is_Critical = RNG:NextNumber(0, 100) < Crit_Rate
	
	-- Enemy
	local Level_Factor = Defense_Factors[math.clamp(Level, 0, 60)]
	local Damage_Taken_Mult = EnemyStatus:GetDamageTakenMultiplier()
	local Element_Multiplier = EnemyStatus:GetElementMultiplier(Data.Affliction)
	local Raw_Defense = EnemyStatus:GetStat('Defense')
	local Defense_Mult = Level_Factor / (math.max(Raw_Defense * (1 - (Pen_Ratio / 100)) - Penetration, 0) + Level_Factor)
	
	--
	local Resistance_Multiplier = 1 - (EnemyStatus:GetResistanceMultiplier() / 100)
	local Crit_Mult = Is_Critical and Crit_Damage or 1
	local Raw_Damage_Mult = Data.Damage / 100
	local Base_Damage = Raw_Damage_Mult * Attack
	local Affliction_Type = Element_Multiplier < 1 and 'Weak' or Data.Affliction
	local Dazed_State_Multiplier = EnemyStatus:IsKnocked() and EnemyStatus:GetDazeMultiplier() or 1
	
	local Final_Damage = math.max(Base_Damage * Damage_Bonus_Mult * Crit_Mult * Defense_Mult * Element_Multiplier * Resistance_Multiplier * Damage_Taken_Mult * Dazed_State_Multiplier, 1)
	local Percent_Bonus = (Final_Damage / EnemyStatus:GetStat('Max_Health')) / 0.63
	local Filled_Affliction = ((Data.Affliction_Buildup or 1) / 100) * (1 + Affliction_Aptitude/90) * (1 + Percent_Bonus)
	local Burst_Damage = 0
	
	Enemy:TakeAffliction(Data.Affliction, Filled_Affliction)

	local AfflictionTriggered = false;
	if Enemy:GetAffliction(Data.Affliction) >= 100 then
		-- TODO: Fix the res mult to change based on enemy stuff idk
		AfflictionTriggered = true;
		Burst_Damage = DamageLibrary:CalculateAfflictionBurst(Attack, Data.Affliction, Defense_Mult, Resistance_Multiplier, Agent, Enemy)
		Enemy:TakeDamage(Burst_Damage)
	
		Enemy:ResetAffliction(Data.Affliction)
	end
	
	Enemy:TakeDamage(Final_Damage)
	
	return Final_Damage, Is_Critical, Affliction_Type, Filled_Affliction, Burst_Damage, AfflictionTriggered
end


function DamageLibrary:Daze(Agent: Types.ServerAgentClass, Enemy: Types.ServerEnemyClass, Base_Multiplier: number)
	local EnemyStatus = Enemy.__Status

	-- Values
	local Daze = Agent:GetStat('Daze')
	local Daze_Res = 1 - (EnemyStatus:GetStat('Daze_Resistance') / 100)
	local Daze_Bonus_Attacker = 1
	
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

function DamageLibrary:CalculateAfflictionBurst(Attack: number, Type: Types.Element, Defense: number, Resistance: number, Agent: Types.ServerAgentClass, Enemy: Types.ServerEnemyClass)
	local EnemyStatus = Enemy.__Status
	
	local Damage_Taken_Mult = EnemyStatus:GetDamageTakenMultiplier()
	local Element_Multiplier = EnemyStatus:GetElementMultiplier(Type)
	
	local Aptitude_Multiplier = Agent:GetStat('Affliction_Aptitude') / 100
	local Level_Multiplier = Agent.__Level + (1 / 59) * (Agent.__Level - 1)
	local Stacked_Damage = Enemy:GetAfflictionStackedDamage(Type)
	local Base_Divider = (100 + Agent:GetStat('Attack')/100)
	local Taken_Damage = (Base_Divider + Stacked_Damage) / 100
	local Dazed_State_Multiplier = EnemyStatus:IsKnocked() and EnemyStatus:GetDazeMultiplier() or 1
	
	local Resistance_Multiplier = 1 - Resistance
	local Daze_Multiplier = 1
	local Affliction_Type_Mult = VALUES[Type]
	local Total_Damage = (Attack * Affliction_Type_Mult) * Level_Multiplier * Element_Multiplier * Aptitude_Multiplier * Defense * Resistance_Multiplier * Daze_Multiplier * Taken_Damage * Dazed_State_Multiplier * Damage_Taken_Mult

	return Total_Damage
end

return DamageLibrary
