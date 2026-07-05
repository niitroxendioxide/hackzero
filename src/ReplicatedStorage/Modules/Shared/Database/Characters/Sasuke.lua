return {
	Display_Name = 'Sazuki Uchiro',
	Nickname = 'Sazuki',
	Element = 'Fire',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Team 7",

	
	IconGlowColor = Color3.fromRGB(255, 222, 199),

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
		['Passive'] = {
			Meters = {
				Sharingan = {
					Ascension = 0,
					Max = 3,
					Id = 1,
					Description = "Sharingan"
				}
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Attack_State_Time = 0.25,
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
				Attack_State_Time = 0.45,
				Speed = 1,
				Range = 200,
				Animation_Speed = 1,
				Required_Energy = 30,

				Hit = {
					Damage = 61,
					Affliction = "Physical",
					HitType = "Slash",
					Daze = 15,
					Stun = 0.15,
					Affliction_Buildup = 21,
				},
			},
			Upgrade = {},
		},

		['Dodge Counter'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 1.5,
				Speed = 1,
				Animation_Speed = 1,

				Hit = {
					Stun = 0.35,
					Damage = 170,
					HitType = "Slash",
					Daze = 35,
					Affliction_Buildup = 75,
					Affliction = "Physical",
					Knockback = {
						vector.create(0, 0, 1),
						14,
						0.1,
					}
				},

				PunchHit = {
					Stun = 0.4,
					Damage = 240,
					HitType = "Blunt",
					Daze = 25,
					Affliction_Buildup = 32,
					Affliction = "Physical",
					Knockback = {
						vector.create(0, 0, 1),
						20,
						0.1,
					}
				}
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
				Required_Energy = 30,

				Burst = {
					Damage = 355,
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
		},

		['Quick Assist'] = {
			Base = {
				Attack_State_Time = 1.1,
				HitRate = 0.5 / 8,
				Speed = 1,
				Animation_Speed = 1,

				Hit = {
					Damage = 36,
					Affliction = "Fire",
					HitType = "Blunt",
					Daze = 27,
					Affliction_Buildup = 15,
					Stun = 0.225,

					Knockback = {
						vector.create(0, 0, 1),
						7,
						0.1
					}
				},
			},
			Upgrade = {
				Hit = {
					Damage = 1,
					Daze = 0.5,
					Stun = 0.01,
				}
			},
		},

		['Ultimate'] = {
			Base = {
				Attack_State_Time = 2.75,
				Speed = 1,
				Animation_Speed = 1,
				Hit_Frequency = 1 / 10,

				Hit = {
					Damage = 90,
					Affliction = "Fire",
					HitType = "Blunt",
					Daze = 32,
					Affliction_Buildup = 85,
					Stun = 0.45,
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