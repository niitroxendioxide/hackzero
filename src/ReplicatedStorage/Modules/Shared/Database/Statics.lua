local GetExpForLevel; GetExpForLevel = function(level)
	if type(level) ~= "number" or level < 1 or level > 60 then
		return math.huge, "Invalid level. Must be between 1 and 60."
	end

	if level == 1 then return 0 end

	if level <= 10 then
		return 25 * level^2 - 25 * level
	elseif level <= 19 then
		return GetExpForLevel(10) + 1800 * (level - 10) - 135 * (level - 10) * (level - 11) / 2
	elseif level <= 30 then
		if level == 20 then return 30000 end
		local exp = 30000
		for l = 21, level do
			exp = exp + 4680 + 295 * (l - 21) - 5 * (l - 21) * (l - 22) / 2
		end
		return exp
	elseif level <= 39 then
		return GetExpForLevel(30) + 10800 + 600 * (level - 31) * (level - 30) / 2
	elseif level <= 49 then
		if level == 40 then return 225000 end
		local exp = 225000
		for l = 41, level do
			exp = exp + 900 + 300 * (l - 41)
		end
		return exp
	else
		if level == 50 then return 450000 end
		local exp = 450000
		for l = 51, level do
			exp = exp + 2400 + 2400 * (l - 51)
		end

		return exp
	end
end

local function CompanionExperiencePerLevel(Level: number)
	if Level == 1 then
		return 250
	end

	if Level < 10 then
		return Level + (Level * 10) * math.exp(1.5 + (3 / Level))
	end

	local Ascension = Level // 10

	return (Level * math.exp(Ascension * (1.5/Level)) + (Level * 100)) * (math.pi/2.75*(Level / 5))
end

local Health_Level_Divisors = {
	[1] = 0.25,
	[2] = 0.5,
	[3] = 1,
	[4] = 1.25,
	[5] = 1.8,
	[6] = 0.1,
	[7] = 0.1,
}

return {
	GameVersion = '0.01',

	Max_Player_Level = 100,
	Max_Character_Level = 60,
	Max_Companion_Level = 70,
	Max_Team_Size = 5,

	-- Summoning
	SummonCost = 160,

	--
	AFK_Rewards = {
		Currency = {
			Gems = 2,
			Money = 25,
		},
	},

	AFK_Times = {
		Gems = 30,
		Money = 5,
	},

	Max_Skill_Level = 20,
	Skill_Upgrade_Cost = function(Level: number): number return math.floor(0.17 * Level^2 + 1) end,

	--
	Daze_Length_Level_Multiplier = 0.01416666666,
	Drive_Trait_Chance = 25,

	--
	Ascension_Chip_Cost = {
		[1] = 5,
		[2] = 15,
		[3] = 20,
		[4] = 20,
		[5] = 40,
	},

	Companion_Experience_For_Level = CompanionExperiencePerLevel,
	Experience_For_Level = GetExpForLevel,
	GetExperienceForMax = function(StartLevel, CurrentExperience)
		local ExpForLevels = 0
		for i = StartLevel + 1, 60 - StartLevel do
			ExpForLevels += GetExpForLevel(i)
		end

		return (ExpForLevels - CurrentExperience)
	end,

	Experience_To_Ascend = {
		[1] = 300,
		[2] = 1680,
		[3] = 3480,
		[4] = 900,
		[5] = 6300,
	},

	SubStatIncreases = {
		["Health%"] = {3, 2, 1},
		["Health"] = {112, 79, 39},
		["Attack"] = {26, 18, 11},
		["Attack%"] = {3, 2 ,1},
		["Defense"] = {20, 12, 8},
		["Defense%"] = {5, 3, 1},
		["Crit_Rate"] = {2.4, 1.6, .8},
		["Crit_Damage"] = {5, 3, 1},
		["Penetration"] = {9, 6, 3},
		["Affliction_Aptitude"] = {9, 6, 3},
		["Daze"] = {6, 4, 2},
	},

	Dodge_Active_Time = 0.5,
	Dodge_Invulnerability_Time = 0.5,
	Dodge_Counter_React_Time = 0.75,

	Assist_Ult_Bar_Fill = 3,
	Dodge_Ult_Bar_Fill = 4,
	Chain_Attack_Ult_Bar_Fill = 8,

	Switch_Character_Dash_Strength = 45,


	Get_Agent_Experience_For_Level = function(Level: number)
		local Amount = (Level - 1);
		local AmountIncrease = Level // 7;
		local Ascension = 1 + (Level // 10) * 0.33;

		local ExperienceRequired = 100 + (Amount * (24 + AmountIncrease*5)) * Ascension;

		return ExperienceRequired;
	end,

	Get_Health_By_Level = function(Level: number, Health: number, HealthIncrease: number)
		local Ascensions = Level // 10
		local Added = 0

		local Total = math.max(Level // 5, 1)
		local RandomFactor = math.exp(Total / 12) / 2.71828

		local TotalMult = 0

		for i = 1, Ascensions do
			local Mult = 10
			if i == Ascensions then
				Mult = (Level - 1) % 10
			end

			TotalMult += Mult
			Added += Mult * Health_Level_Divisors[i] * RandomFactor * HealthIncrease
		end

		return Health + Added
	end,

	--
	Dash_Time = 0.5,
	Dash_Strength = 50,
	Dash_Speed_Buff = 0.5,
	Dash_Speed_Buff_Vanish_Time = 1,

	Chain_Attack_Invulnerability_Time = 2,
	Assist_Counter_Invulnerability_Time = 0.75,

	Stat_Tier_Mults = {
		Common = {0.1, 0.3},
		Epic = {0.31, 0.55},
		Legendary = {0.57, 0.82},
		Mythical = {0.85, 0.99},
	},

	--
	Difficulty_Targetting_Priorities = {
		PASSIVE = {
			SAME_ATTACKER = 1000,
			DIFFERENT_ATTACKER = 2500,
		},

		EASY = {
			SAME_ATTACKER = 5,
			DIFFERENT_ATTACKER = 4.25,
		},

		MEDIUM = {
			SAME_ATTACKER = 3.75,
			DIFFERENT_ATTACKER = 3,
		},

		HARD = {
			SAME_ATTACKER = 2,
			DIFFERENT_ATTACKER = 1.75,
		},

		EXTREME = {
			SAME_ATTACKER = 1.25,
			DIFFERENT_ATTACKER = 1,
		},
	},
}