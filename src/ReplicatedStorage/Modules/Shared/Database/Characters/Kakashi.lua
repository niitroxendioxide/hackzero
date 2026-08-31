return {
	Display_Name = 'Ataque Zakashi',
	Nickname = 'Zakashi',
	Element = 'Electric',
	Role = 'Affliction',
	Tier = "Mythical",
	Faction = "Team 7",
	
	IconGlowColor = Color3.fromRGB(51, 106, 245),

	Appearance = {
		Height = 3
	},

	ImportantStats = {
		'Affliction_Aptitude',
        'Critical_Rate',
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
		Daze = 45,
		Speed = 1,
		Energy_Regeneration = 1.2,
		Affliction_Aptitude = 120,
		Affliction_Facility = 11,

		--
		Walk_Speed = 10,
		Jog_Speed = 25,
		Sprint_Speed = 36,
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

		['Special'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 1,
				Speed = 1,
				Animation_Speed = 1,
				Hit_Frequency = 0.05,
				Hit_Count = 5,
				Range = 100,
				Raikiri_Run_Time = .5,
				Required_Energy = 40,

				Hit = {
					Damage = 87,
					Stun = 0.275,
					Daze = 17,
					Affliction = 'Electric',
					Affliction_Buildup = 90,
				},

				KnockbackData = {
					vector.create(0, 0, 1),
					12,
					0.2
				},
			},

			Upgrade = {
				Hit_Count = 0.05,
				Hit = {
					Damage = 2,
					Daze = 0.2,
					Affliction_Buildup = 2,
				},
			},
		},

		['EX Special'] = {
			Base = {
				Attack_State_Time = 2,
				Speed = 1,
				Range = 100,
				Required_Energy = 40,
				First_Run_Time = .5,
				Second_Run_Time = .5,

				Sosenko_Hit_Max = 6,
				Sosenko_Hit_Frequency = 0.06,
				Sosenko_Dash_Hitbox_Size = vector.create(9, 9, 55),


				Throw_Hit = {
					Damage = 45,
					Daze = 5,
					Stun = 0.85,
					Affliction = 'Physical',
					HitType = 'Blunt',
					Knockback = {
						vector.create(0, 0, 1),
						80,
						0.45
					}
				},
				Hit = {
					HitType = 'Slash',
					Damage = 117,
					Stun = 0.3,
					Daze = 22,
					Affliction = 'Electric',
					Affliction_Buildup = 93,
				},
				Sosenko_Dash_Hit = {
					HitType = 'Slash',
					Damage = 370,
					Stun = 0.45,
					Daze = 27,
					Affliction = 'Electric',
					Affliction_Buildup = 112,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.5,
					Daze = 0.5,
					Affliction_Buildup = 2.25,
				},
				Sosenko_Dash_Hit = {
					Damage = 1.75,
					Daze = 0.25,
					Affliction_Buildup = 1,
				},
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