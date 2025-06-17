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
	Experience_Increase_Per_Ascension = {
		[1] = 150,
		[2] = 300,
		[3] = 600,
		[4] = 1200,
		[5] = 2400,
	},

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
}