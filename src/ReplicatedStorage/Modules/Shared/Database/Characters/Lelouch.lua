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
			Meters = {
				Checkmate = {
					Ascension = 0,
					Max = 10,
					Id = 1,
					Description = "Checkmate",
				}
			},

			Black_Knights = {
				Max = 5,
				Lifetime = 8,
				Range = 70,
				Interval = 1,
				Focus_Interval = 0.5,
				Focus_Daze_Multiplier = 1.5,
				Size = vector.create(2, 5, 2),

				Hit = {
					HitType = 'Blunt',
					Damage = 14,
					Daze = 26,
					Stun = 0.1,
					Affliction = 'Physical',
					Affliction_Buildup = 12,
					HitsAirborne = true,
					NoRotate = true,
				},
			},

			Grenade = {
				Size = vector.create(14, 8, 14),
				Flashbang_Daze_Multiplier = 1.5,
				Flashbang_Crit_Rate = 15,
				Flashbang_Time = 6,
			},

			Tactics = {
				Cooldown = 8,
				Range = 80,

				Grenade_Hit = {
					HitType = 'Blunt',
					Damage = 60,
					Daze = 45,
					Stun = 0.3,
					Affliction = 'Physical',
					Affliction_Buildup = 30,
					HitsAirborne = true,
					NoRotate = true,
				},
			},

			Knightmares = {
				Size = vector.create(6, 10, 6),
				Distance = 12,
				Spread = 35,
				Range = 90,
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Attack_State_Time = 0.2,
				Speed = 1,
				Animation_Speed = 1,
				Range = 75,

				Release = true,
				Geass_Shot = 5,
				Focus_Hold_Time = 0.35,
				Focus_Shot_Interval = 0.3,

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

				Focus_Hit = {
					Damage = 12,
					Daze = 22,
					Affliction = "Physical",
					HitType = "Blunt",
					Affliction_Buildup = 8,
					Stun = 0.3,
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
				Focus_Hit = {
					Damage = .2,
					Daze = .8
				},
			},
		},

		['Dodge'] = {
			Base = {
				Cooldown = .3,
				Speed = 1,
				Animation_Speed = 1,
				Release = false,

				Fall_Back_Cooldown = 1.5,
				Shot_Times = {0.12, 0.27},

				Hit = {
					HitType = 'Blunt',
					Damage = 28,
					Daze = 24,
					Stun = 0.25,
					Affliction = 'Physical',
					Affliction_Buildup = 10,
				},
			},

			Upgrade = {
				Hit = {
					Damage = .4,
					Daze = .3,
				},
			},
		},

		['Special'] = {
			Base = {
				Cooldown = 8,
				Attack_State_Time = 0.9,
				Speed = 1,
				Animation_Speed = 1,
				Range = 90,
				Required_Energy = 40,

				Throw_Time = 0.3,
				Throw_Distance = 20,
				Geass_Time = 0.6,
				Knight_Count = 2,
				Stand_Still_Slow = -0.1,
				Stand_Still_Time = 6,

				Grenade_Hit = {
					HitType = 'Blunt',
					Damage = 55,
					Daze = 60,
					Stun = 0.4,
					Affliction = 'Physical',
					Affliction_Buildup = 35,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Grenade_Hit = {
					Damage = .9,
					Daze = .6,
					Affliction_Buildup = .4,
				},
			},
		},

		['EX Special'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 1.1,
				Speed = 1,
				Animation_Speed = 1,
				Range = 100,
				Required_Energy = 40,

				Geass_Time = 0.45,
				Knight_Count = 2,
				Yield_Defense = 15,
				Yield_Time = 10,
				Empowered_Yield_Defense = 20,
				Empowered_Yield_Time = 15,
				Empowered_Affliction_Threshold = 50,
				Resistance_Shred = -0.1,

				Hit = {
					HitType = 'Blunt',
					Damage = 90,
					Daze = 55,
					Stun = 0.5,
					Affliction = 'Physical',
					Affliction_Buildup = 40,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.2,
					Daze = .5,
					Affliction_Buildup = .5,
				},
			},
		},

		['Dodge Counter'] = {
			Base = {
				Cooldown = 0.5,
				Attack_State_Time = 1,
				Speed = 1,
				Animation_Speed = 1,
				Range = 80,

				Geass_Time = 0.35,
				Knight_Count = 1,
				Hitbox_Size = vector.create(26, 8, 30),
				Hitbox_Offset = vector.create(0, 0, -15),
				Paralyze_Time = 2,
				Paralyze_Immunity_Time = 10,

				Hit = {
					HitType = 'Blunt',
					Damage = 120,
					Daze = 40,
					Stun = 0.5,
					Affliction = 'Physical',
					Affliction_Buildup = 45,
					HitsAirborne = true,
				},
				Elite_Hit = {
					HitType = 'Blunt',
					Damage = 120,
					Daze = 110,
					Stun = 0.5,
					Affliction = 'Physical',
					Affliction_Buildup = 45,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.4,
					Daze = .4,
					Affliction_Buildup = .5,
				},
				Elite_Hit = {
					Damage = 1.4,
					Daze = 1.1,
					Affliction_Buildup = .5,
				},
			},
		},

		['Quick Assist'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 1.1,
				Speed = 1,
				Animation_Speed = 1,
				Range = 110,

				Geass_Time = 0.3,
				Shot_Time = 0.6,
				Blind_Time = 3,

				Hit = {
					HitType = 'Blunt',
					Damage = 40,
					Daze = 30,
					Stun = 0.4,
					Affliction = 'Physical',
					Affliction_Buildup = 15,
					HitsAirborne = true,
				},
				Elite_Hit = {
					HitType = 'Blunt',
					Damage = 60,
					Daze = 120,
					Stun = 0.4,
					Affliction = 'Physical',
					Affliction_Buildup = 20,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Hit = {
					Damage = .6,
					Daze = .4,
				},
				Elite_Hit = {
					Damage = .8,
					Daze = 1.2,
				},
			},
		},

		['Chain Attack'] = {
			Base = {
				Cooldown = 0.5,
				Attack_State_Time = 1.6,
				Speed = 1,
				Animation_Speed = 1,
				Range = 120,

				Call_Time = 0.3,
				Blast_Count = 3,
				Blast_Interval = 0.35,
				Blast_Size = vector.create(14, 10, 14),

				Blast_Hit = {
					HitType = 'Blunt',
					Damage = 420,
					Daze = 55,
					Stun = 0.5,
					Affliction = 'Physical',
					Affliction_Buildup = 150,
					HitsAirborne = true,
					NoRotate = true,
				},
			},

			Upgrade = {
				Blast_Hit = {
					Damage = 3,
					Daze = .5,
					Affliction_Buildup = 1.5,
				},
			},
		},

		['Ultimate'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 2.4,
				Speed = 1,
				Animation_Speed = 1,
				Range = 130,
				Required_Meter = {
					Name = 'Checkmate',
					Amount = 10,
				},

				Kneel_Time = 1.2,
				Kneel_Radius = 60,
				Kneel_Duration = 5,
				Subjugate_Time = 8,
				Subjugate_Damage_Taken = 0.1,
				Subjugate_Affliction_Taken = 0.3,

				Knightmare_Count = 3,
				Knightmare_Interval = 0.5,
				Knightmare_Time = 8,
				Knightmare_Blast_Size = vector.create(12, 10, 12),

				Elite_Hit = {
					HitType = 'Blunt',
					Damage = 150,
					Daze = 220,
					Stun = 0.6,
					Affliction = 'Physical',
					Affliction_Buildup = 60,
					HitsAirborne = true,
					DontChargeUlt = true,
				},
				Knightmare_Hit = {
					HitType = 'Blunt',
					Damage = 210,
					Daze = 35,
					Stun = 0.3,
					Affliction = 'Physical',
					Affliction_Buildup = 50,
					HitsAirborne = true,
					NoRotate = true,
					DontChargeUlt = true,
				},
			},

			Upgrade = {
				Elite_Hit = {
					Damage = 1.5,
					Daze = 2,
					Affliction_Buildup = .6,
				},
				Knightmare_Hit = {
					Damage = 2.2,
					Daze = .4,
					Affliction_Buildup = .5,
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
