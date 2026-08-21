return {
	Display_Name = 'Ataque Zakashi',
	Nickname = 'Zakashi',
	Element = 'Electric',
	Role = 'Attack',
	Tier = "Mythical",
	Faction = "Team 7",

	
	IconGlowColor = Color3.fromRGB(51, 106, 245),

	Appearance = {
		Height = 2.85
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
		Health = 122.75,
		Attack = 6.7,
		Defense = 9.12,
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
					[1]   = {0.217, .267, .425, 0.2, 1.35},
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
					[1] = 70,
					[2] = 90,
					[3] = 130,
					[3.1] = 180,
					[4] = 110,
					[4.1] = 61,
				},
				Daze = {
					[1] = 15,
					[2] = 22,
					[3] = 6,
					[3.1] = 23,
					[4] = 45,
					[4.1] = 6,
				}
			},
			Upgrade = {
				Damage = {
					[1] = 1.5,
					[2] = 2,
					[3] = 2.5,
					[3.1] = 3.5,
					[4] = 2,
					[4.1] = 0.75,
				},
				Daze = {
					[1] = 0.75,
					[2] = 1,
					[3] = 0.2,
					[3.1] = 0.35,
					[4] = 0.5,
					[4.1] = 0.2,
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