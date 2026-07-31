return {
	Display_Name = 'Natsuro Uzaki',
	Nickname = 'Naru-kage',
	Element = 'Wind',
	Role = 'Stun',
	Tier = "Legendary",
	Faction = "Team 7",
	
	IconGlowColor = Color3.fromRGB(255, 146, 83),

	Appearance = {
		Height = 2.675
	},

	ImportantStats = {
		'Attack',
		'Energy_Regeneration',
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
		Daze = 100,
		Speed = 1,
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
		Daze = 0.75,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = 0.05,
				Speed = 1.3,
				Animation_Speed = 1,
				Attack_State_Time = 0.65,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1]   = {0.35, .46, .61, 0.25, 1.35},
					[2]   = {.12, .38, .6, 0.27, 1.1},
					[3]   = {0,.45, .9},
					[4]   = {0.03, .9, 1.45}
				},

				StunTimes = {
					[1] = 0.65,
					[2] = 1.35,
					[3] = 1.65,
					[4] = 1.7,
				},

				Hit = {
					HitType = 'Blunt',
					Stun = 1.75,
					Daze = 135,
					Affliction_Buildup = 15,
					Affliction = 'Physical',
					Knockback = {
						vector.create(0, 0, 1),
						12,
						0.2,
					},
				},

				Damage_Mult = {
					[1] = 25,
					[2] = 95,
					[3] = 125,
					[4] = 75,
					[5] = 120,
				},
			},

			Upgrade = {
				Damage_Mult = {
					[1] = 2,
					[2] = 3,
					[3] = 4,
					[4] = 2,
					[5] = 1,
				},
			},
		},

		['Special'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = .55,
				Clone_Range = 20,
				Range = 23, 
				Required_Energy = 45,

				Hit = {
					HitType = 'Blunt',
					Stun = 1,
					Daze = 220,
					Damage = 164,
					Affliction_Buildup = 15,
					Affliction = 'Physical',
					Knockback = {
						vector.create(0, 0, -1),
						22,
						0.3,
					},
				},
			},
			Upgrade = {

			},
		},

		['EX Special'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 3.7,
				Range = 100,
				Required_Energy = 45,
				Length = 2,
				Limit = 1,
				Hitbox_Offset = vector.create(0, 0, -2.5),
				Hitbox_Size = vector.create(5, 5, 5),
				Hit_Count = 5,
				
				Hit = {
					HitType = 'Blunt',
					Stun = .3,
					Daze = 24,
					Damage = 36,
					Affliction_Buildup = 9,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						7,
						0.2,
					},
				},

				Final = {
					HitType = 'Blunt',
					Stun = 1,
					Daze = 45,
					Damage = 102,
					Affliction_Buildup = 25,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						45,
						0.3,
					},
				},
			},
			Upgrade = {

			},
		},

		['Chain Attack'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.75,
				
				Range = 45,
				Size = vector.create(4, 4, 7),
				Offset = vector.create(0, 0, -4.75),
				HitCount = 8,
				HitFrequency = 0.125,

				Hit = {
					HitType = 'Blunt',
					Stun = 1,
					Daze = 12,
					Damage = 18,
					Affliction_Buildup = 6,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						24,
						0.2,
					},
				},

				Final = {
					HitType = 'Blunt',
					Stun = 1,
					Daze = 100,
					Damage = 140,
					Affliction_Buildup = 12,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						60,
						0.2,
					},
				},
			},
			Upgrade = {},
		},

		['Dodge Counter'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.65,
				
				Range = 30,
				HitboxOffset = vector.create(0, 0, -8),
				HitboxSize = vector.create(8, 8, 11),

				Hit = {
					HitType = 'Blunt',
					Stun = .85,
					HitsAirborne = true,
					Airborne = true,
					Daze = 120,
					Damage = 45,
					Affliction_Buildup = 55,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						7,
						0.2,
					},
				},
			},
			Upgrade = {},
		},

		['Quick Assist'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 1.65,
				
				Range = 45,
				HitboxOffset = vector.create(0, 0, -10),
				HitboxSize = vector.create(8, 8, 14),

				Hit = {
					HitType = 'Blunt',
					Stun = .45,
					HitsAirborne = true,
					Daze = 60,
					Damage = 61,
					Affliction_Buildup = 32,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						5,
						0.1,
					},
				},

				FinalHit = {
					HitType = 'Blunt',
					Stun = .75,
					HitsAirborne = true,
					Daze = 90,
					Damage = 120,
					Affliction_Buildup = 32,
					Affliction = 'Wind',
					Knockback = {
						vector.create(0, 0, 1),
						30,
						0.5,
					},
				},
			},
			Upgrade = {},
		},

		['Ultimate'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.65,
				
				Clone_Grab_Time = 3,
				Range = 30,

				Hit = {},
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