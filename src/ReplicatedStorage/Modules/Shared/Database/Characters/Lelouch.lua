return {
	Display_Name = 'Laluz Vibrania',
	Nickname = 'Lulu',
	Element = 'Physical',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Team 7",

	
	IconGlowColor = Color3.fromRGB(171, 97, 255),

	Appearance = {
		Height = 2.85
	},

	ImportantStats = {
		'Defense',
		'Energy_Regeneration'
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
				Attack_State_Time = 0.2,
				Speed = 1,
				Animation_Speed = 1,
				Range = 75,

				Hit = {
					Damage = 17,
					Daze = 30,
					Affliction = "Physical",
					HitType = "Blunt",
					Affliction_Buildup = 15,
					Stun = 0.4,
					Knockback = {
						vector.create(0, 0, 1),
						15,
						0.1,
					}
				},
			},
			Upgrade = {
				Hit = {
					Damage = .3,
					Daze = 1
				},
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