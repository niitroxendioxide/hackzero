local GetExpForLevel; GetExpForLevel = function(level)
	if type(level) ~= "number" or level < 1 or level > 60 then
		return nil, "Invalid level. Must be between 1 and 60."
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

return {
	GameVersion = '0.01',

	Max_Player_Level = 60,
	Max_Character_Level = 60,
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
	},

	Dodge_Active_Time = 0.5,
	Dodge_Invulnerability_Time = 0.5,
	Dodge_Counter_React_Time = 0.75,

	Switch_Character_Dash_Strength = 35,

	Get_Health_By_Level = function(Level: number, Health: number)
		local TotalAdded = math.max(Level - 1, 0)
		local Total = math.max(Level // 5, 1)

		return Health + (math.exp(Total/12)/2.71828 * Health * TotalAdded)
	end,

	--
	Dash_Speed_Buff = 0.5,
	Dash_Speed_Buff_Vanish_Time = 1,

	Assist_Counter_Invulnerability_Time = 0.75,

	--
	Difficulty_Targetting_Priorities = {
		EASY = {
			SAME_ATTACKER = 3,
			DIFFERENT_ATTACKER = 2.25,
		},

		MEDIUM = {
			SAME_ATTACKER = 2.5,
			DIFFERENT_ATTACKER = 1.75,
		},

		HARD = {
			SAME_ATTACKER = 1.75,
			DIFFERENT_ATTACKER = 1.3,
		},

		EXTREME = {
			SAME_ATTACKER = 1.25,
			DIFFERENT_ATTACKER = 1,
		},
	},
}