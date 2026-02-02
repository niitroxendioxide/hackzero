return {
	Display_Name = 'Sasuke Uchiha',
	Nickname = 'Sasuke',
	Element = 'Fire',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Team 7",

	
	IconGlowColor = Color3.fromRGB(255, 222, 199),

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
				Attack_State_Time = 0.35,
				Speed = 1,
				Animation_Speed = 1,

				Hit = {
					Damage = 100,
					Affliction = "Physical",
					HitType = "Blunt",
					Daze = 15,
					Affliction_Buildup = 15,
					Stun = 0.4,
				},
			},
			Upgrade = {},
		},

		['Special'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 0.35,
				Speed = 1,
				Animation_Speed = 1,
				Required_Energy = 1,
			},
			Upgrade = {},
		},

		['EX Special'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 0.75,
				LockRotation = true,
				Speed = 1,
				Range = 120,
				Animation_Speed = 1,
				Required_Energy = 1,

				Burst = {
					Damage = 275,
					Affliction = "Fire",
					HitType = "Blunt",
					Daze = 67,
					Affliction_Buildup = 45,
					Stun = 0.4,
				},

				Fireball = {
					Damage = 330,
					Affliction = "Fire",
					HitType = "Blunt",
					Daze = 32,
					Affliction_Buildup = 33,
					Stun = 0.3,
				},
			},
			Upgrade = {
				Burst = {
					Damage = 3.25,
					Daze = 1,
					Affliction_Buildup = 1.5,
				},

				Fireball = {
					Damage = 2,
					Daze = 0.5,
					Affliction_Buildup = 0.75,
				}
			},
		}
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