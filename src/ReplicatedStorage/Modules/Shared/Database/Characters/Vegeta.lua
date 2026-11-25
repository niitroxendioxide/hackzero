return {
	Display_Name = 'Prince Vega IV',
	Nickname = 'Vega',
	Element = 'Energy',
	Role = 'Attack',
	Tier = "Mythical",
	Faction = "Z Warriors",

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 651,
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
		Health = 121.38,
		Attack = 6.33,
		Defense = 9.44,
	},

	Moveset_Data = {
		['Passive'] = {
			Meters = {
				Ki = {
					Ascension = 0,
					Max = 100,
					Id = 1,
					Description = "Ki"
				},
			},
		},
		['Basic Attack'] = {
			Base = {
				Cooldown = .02,
				Attack_State_Time = 0.25,
				Speed = 1,
				Animation_Speed = 1,
				Release = true,

				Damages = {
					[1] = 45,
					[2] = 85,
					[3] = 120,
					[4] = 110,
					[5] = 190,
				},

				Dazes = {
					[1] = 17,
					[2] = 14,
					[3] = 18,
					[4] = 22,
					[5] = 12,
				},

				Hit = {
					Damage = 0,
					Stun = 0.25,
					Daze = 0,
					Affliction_Buildup = 10,
					HitType = 'Blunt',
					Affliction = 'Physical',
					Knockback = {
						vector.create(0, 0, 1),
						10,
						0.2
					},
				}
			}
		},
	},

	Ascension_Data = {
		[1] = {
			Description = 'Vegeta ascension 1',
		},

		[2] = {
			Description = 'Vegeta ascension 2',
		},

		[3] = {
			Description = 'Vegeta ascension 3',
		},

		[4] = {
			Description = 'Vegeta ascension 4',
		},

		[5] = {
			Description = 'Vegeta ascension 5',
		},

		[6] = {
			Description = 'Vegeta ascension 6',
		},
	}
}