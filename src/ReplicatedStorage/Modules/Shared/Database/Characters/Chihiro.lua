return {
	Display_Name = 'Chihiro Rokuhira',
	Nickname = 'Chihiro',
	Element = 'Water',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Kamunabi",

	Appearance = {
		Height = 3
	},

	ImportantStats = {
		'Attack',
        'Critical_Rate',
		'Critical_Damage',
	},

	--
	Stats = {
		Health = 656,
		Attack = 127,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 20,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 90,
		Energy_Regeneration = 1.2,
		Affliction_Aptitude = 90,
		Affliction_Facility = 11,

		--
		Walk_Speed = 10,
		Jog_Speed = 24,
		Sprint_Speed = 34,
	},

	Level_Stats = {
		Health = 122.75,
		Attack = 6.51,
		Defense = 9.12,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = .45,
				Speed = 1,
				Animation_Speed = 1,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1]   = {0.165, .25, .275},
					[2]   = {.117, .18, .225},
					[3]   = {0, .15, .6},
					[3.1] = {0.365, .35, 0, -.4, 1.5},
					[4]   = {0.03, .24, .54, .633},
					[4.1] = {0, .467, 0},
					[5]   = {0.03, .1, .75, .7, 0.33},
					[5.1] = {0, .55, .75},
				},

				Walk_Time = 0.1,

				Effect_Data = {
					Audio = {
						Id = { 6216173737 },
						Volume = 0.35,
					}
				},

				Damage_Mult = {
					[1] = 40,
					[2] = 71,
					[3] = 85,
					[3.1] = 76,
					[4] = 140,
					[4.1] = 170,
					[5] = 90,
					[5.1] = 102,
				},

				Daze_Mult = {
					[1] = 17,
					[2] = 21,
					[3] = 17,
					[3.1] = 32,
					[4] = 55,
					[4.1] = 49,
					[5] = 32,
					[5.1] = 31,
				},

				Affliction_Buildup = {
					[1] = 45,
					[2] = 55,
					[3] = 52,
					[3.1] = 61,
					[4] = 52,
					[4.1] = 45,
					[5] = 34,
					[5.1] = 66,
				}
			}
		},
		--[[['Passive'] = {
			Description = '',
			Meters = {
				SaiyanSurge = {
					Ascension = 2,
					Description = 'When completing a full basic attack string obtain one charge of Saiyan Surge, when hitting an enemy with an EX-Special, get two charges, up to 3. Hold basic attack with two charges to use Super God Fist',
					Id = 1,
					Max = 4,
				},
			},
		},]]
	},

	Ascension_Data = {
		[1] = {
			Description = 'TODO',
		},

		[2] = {
			Description = "",
		},

		[3] = {
			Description = 'All skills +5 Level limit',
		},

		[4] = {
			Description = 'TODO',
		},

		[5] = {
			Description = 'All skills +5 Level limit',
		},

		[6] = {
			Description = "",
		},
	}
}