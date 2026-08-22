return {
	Display_Name = 'Ataque Zakashi',
	Nickname = 'Zakashi',
	Element = 'Electric',
	Role = 'Attack',
	Tier = "Mythical",
	Faction = "Team 7",

	
	IconGlowColor = Color3.fromRGB(51, 106, 245),

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
		Attack = 137,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 20,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 90,
		Speed = 1,
		Energy_Regeneration = 1.2,
		Affliction_Aptitude = 25,
		Affliction_Facility = 11,

		--
		Walk_Speed = 10,
		Jog_Speed = 24,
		Sprint_Speed = 34,
	},

	Level_Stats = {
		Health = 128,
		Attack = 7.2,
		Defense = 9,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Attack_State_Time = 0.25,
				Speed = 1,
				Animation_Speed = 1,
				Range = 85,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1]   = {0.26, .33, .65, 0.08, 1.45},
					[1.1]   = {0.5, .58, 0,},
					[2]   = {0.233, .283, .85, 0.325, 1},
					[2.1]   = {0, .75},
					[2.2]   = {0, .85},
					[2.3]   = {0, .95},
					[3]   = {0.25, .417, .98, 0.225},
					[3.1]   = {0.65, .733, 0, 0.15, 1.25},
				},

				HitboxSize = vector.create(8, 5, 9),
				HitboxOffset = vector.create(0, 0, -4),

				Hit = {
					Affliction = "Physical",
					HitType = "Blunt",
					Affliction_Buildup = 15,
					Stun = 0.4,
					Knockback = {
						vector.create(0, 0, 1),
						10,
						0.2,
					}
				},

				Damage = {
					[1] = 91,
					[1.1] = 92,
					[2] = 130,
					[2.1] = 45,
					[2.2] = 47,
					[2.3] = 48,
					[3] = 106,
					[3.1] = 145,
				},
				Daze = {
					[1] = 15,
					[1.1] = 16,
					[2] = 6,
					[2.1] = 23,
					[2.2] = 24,
					[2.3] = 25,
					[3] = 22,
					[3.1] = 37,
				}
			},
			Upgrade = {
				Damage = {
					[1] = 1.5,
					[2] = 2,
					[2.1] = 1.75,
					[2.2] = 1.8,
					[2.3] = 1.85,
					[3] = 1,
					[3.1] = 1.45,
				},
				Daze = {
					[1] = 0.75,
					[2] = 1,
					[2.1] = 0.15,
					[2.2] = 0.16,
					[2.3] = 0.17,
					[3] = 0.15,
					[3.1] = 0.25,
				}
			},
		},
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