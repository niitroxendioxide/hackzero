return {
	Display_Name = 'Laluz Vibrania',
	Nickname = 'Lulu',
	Element = 'Physical',
	Role = 'Support',
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
		['Passive'] = {
			Black_Knights = {
				Max = 5,
				Lifetime = 14,
				Range = 70,
				Interval = 1 / 10,

				Hit = {
					HitType = 'Blunt',
					Damage = 2.5,
					Daze = 26,
					Stun = 0.1,
					Affliction = 'Physical',
					Affliction_Buildup = 12,
					HitsAirborne = true,
					NoRotate = true,
				},
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Attack_State_Time = 0.15,
				Speed = 1,
				Animation_Speed = 1,
				Range = 75,

				Release = true,
				Geass_Shot = 5,

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

				Geass_Hit = {
					Damage = 32,
					Daze = 48,
					Affliction = "Physical",
					HitType = "Blunt",
					Affliction_Buildup = 22,
					Stun = 0.45,
					Knockback = {
						vector.create(0, 0, 1),
						18,
						0.15,
					}
				},
			},
			Upgrade = {
				Hit = {
					Damage = .3,
					Daze = 1
				},
				Geass_Hit = {
					Damage = .5,
					Daze = 1.2
				},
			},
		},

		['Special'] = {
			Base = {
				Cooldown = 1.5,
				Attack_State_Time = 0.15,
				Speed = 1,
				Animation_Speed = 1,
				Range = 75,
				Required_Energy = 45,

				Throw_Distance = 30,
				Grenade_Speed = 90,
				Grenade_Lift = 0.15,
				Grenade_Size = vector.create(7, 7, 7),

				Hit = {
					HitType = 'Blunt',
					Damage = 55,
					Daze = 60,
					Stun = 0.4,
					Affliction = 'Physical',
					Affliction_Buildup = 35,
					HitsAirborne = true,
					NoRotate = true,
				},
			},
			Upgrade = {
				Hit = {
					Damage = .9,
					Daze = .6,
				},
			},
		},

		['EX Special'] = {
			Base = {
				Range = 75,
				Required_Energy = 45,
				Attack_State_Time = 0.55,
				Speed = 1,
				Animation_Speed = 1,

				Geass_Area = vector.create(10, 5, 10),
				Yield_Command = {
					Type = "Defense",
					Value = "15%",
					Time = 10,
					Tag = "Yield",
				},

			},
			Upgrade = {},
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
