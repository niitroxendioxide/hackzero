return {
	Display_Name = 'Monk. The Rookie',
	Nickname = 'Rookie',
	Element = 'Physical',
	Role = 'Stun',
	Tier = "Legendary",
	Faction = "Strawhat Pirates",

	IconGlowColor = Color3.fromRGB(237, 113, 113),

	Appearance = {
		Height = 2.95
	},

	--
	Stats = {
		Health = 638,
		Attack = 70,
		Defense = 10,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 70,
		Speed = 1,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 80,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Attack = 7.2,
		Health = 113.75,
		Defense = 6.3,
		Daze = 0.4,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Cooldown = .02,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1] = {0.2, 0.25, .47},
					[2] = {0.217, 0.267, .955, .22, 1.1},
					[2.1] = {0, 0.283,},
					[2.2] = {0, 0.317,},
					[2.3] = {0, 0.35,},
					[2.4] = {0, 0.8,},
					[3] = {0.283, 0.31, .61, .175, 1.1},
					[4] = {0.22, 0.317, .7, .2, 1.1},
				},

				Sizes = {
					[1] = vector.create(6, 4, 12),
					[2] = vector.create(12, 4, 14),
					[2.1] = vector.create(12, 4, 14),
					[2.2] = vector.create(12, 4, 14),
					[2.3] = vector.create(12, 4, 14),
					[2.4] = vector.create(8, 4, 16),
					[3] = vector.create(8, 4, 16),
					[4] = vector.create(6, 4, 24),
				},

				Damages = {
					[1] = 57,
					[2] = 27,
					[2.1] = 45,
					[2.2] = 41,
					[2.3] = 31,
					[2.4] = 102,
					[3] = 111,
					[4] = 100,
				},

				Dazes = {
					[1] = 71,
					[2] = 55,
					[2.1] = 45,
					[2.2] = 45,
					[2.3] = 55,
					[2.4] = 61,
					[3] = 99,
					[4] = 102,
				},

				Hit = {
					Damage = 1,
					Daze = 1,
					Affliction_Buildup = 10,
					Stun = 0.45,
					Affliction = "Physical",
					HitType = "Blunt",
					Knockback = {
						vector.create(0, 0, 1),
						7,
						.1
					},
				},
			}
		},

		['Special'] = {
			Base = {
				Attack_State_Time = 0.55,
				Speed = 1,
				Animation_Speed = 1,
				Required_Energy = 25,

				Hit = {
					Damage = 127,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 10,
					Stun = 0.55,
					Daze = 85,
					Knockback = {
						vector.create(0, 0, 1),
						17,
						0.2
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 2,
					Daze = 1,
				},
			},
		},

		['EX Special'] = {
			Base = {
				Attack_State_Time = 0.61,
				Speed = 1,
				Animation_Speed = 1,
				Required_Energy = 25,

				Hit = {
					Damage = 280,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 10,
					Stun = 0.55,
					Daze = 85,
					Knockback = {
						vector.create(0, 0, 1),
						32,
						0.3
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 2,
					Daze = 1,
				},
			},
		},
	},

	Ascension_Data = {
		[1] = {
			Description = 'Luffy ascension 1',
		},

		[2] = {
			Description = 'Luffy ascension 2',
		},

		[3] = {
			Description = 'Luffy ascension 3',
		},

		[4] = {
			Description = 'Luffy ascension 4',
		},

		[5] = {
			Description = 'Luffy ascension 5',
		},

		[6] = {
			Description = 'Luffy ascension 6',
		},
	}
}