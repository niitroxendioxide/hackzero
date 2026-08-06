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
				Range = 75,
				Release = true,
				
				ShurikenSize = vector.create(5, 5),
				ShurikenConfigs = {
					{3, 4},
					{3, -4},
					{6, -4},
				},

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1]   = {0.217, .267, .7, 0.2, 1.35},
					[1.1] = {0.55, 0.633, 0, 0.2,},
					[2]   = {0.267, .33, 1.1, 0.15, 1.35},
					[2.1] = {0.7, 0.767, 0, .233, 1.25},
					[3]   = {0.217, .267, 1.5, 0.175, 1.15},
					[3.1] = {0.567, 0, 0, .35, -1.5},
				},

				HitboxSize = vector.create(5, 5, 7),
				HitboxOffset = vector.create(0, 0, -4),

				Hit = {
					Affliction = "Physical",
					HitType = "Blunt",
					Affliction_Buildup = 15,
					Stun = 0.4,
					Knockback = {
						vector.create(0, 0, 1),
						8,
						0.1,
					}
				},

				ShurikenHit = {
					Affliction = "Physical",
					HitType = "Slash",
					Affliction_Buildup = 3,
					Stun = 0.2,
					Damage = 91,
					Daze = 12,
				},

				Damage = {
					[1] = 70,
					[1.1] = 90,
					[2] = 130,
					[2.1] = 180,
					[3] = 110,
					[3.1] = 61,
				},
				Daze = {
					[1] = 15,
					[1.1] = 22,
					[2] = 6,
					[2.1] = 23,
					[3] = 45,
					[3.1] = 6,
				}
			},
			Upgrade = {
				ShurikenHit = {
					Damage = 1.75,
					Daze = 0.25
				},
				Damage = {
					[1] = 1.5,
					[1.1] = 2,
					[2] = 2.5,
					[2.1] = 3.5,
					[3] = 2,
					[3.1] = 0.75,
				},
				Daze = {
					[1] = 0.75,
					[1.1] = 1,
					[2] = 0.2,
					[2.1] = 0.35,
					[3] = 0.5,
					[3.1] = 0.2,
				}
			},
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
			Upgrades = {
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
			Upgrades = {
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
				Hit_Frequency = 0.03,
				ExplosionRadius = 19,

				Hit = {
					Damage = 75,
					Affliction = "Fire",
					HitType = "Blunt",
					Daze = 32,
					Affliction_Buildup = 65,
					Stun = 0.3,
					Knockback = {
						vector.create(0, 0, -1),
						6,
						.1
					}
				},

				Explosion = {
					Damage = 495,
					Affliction = "Fire",
					HitType = "Slash",
					Daze = 75,
					Affliction_Buildup = 111,
					Stun = 0.6,
					Knockback = {
						vector.create(0, 0, -1),
						12,
						.2
					}
				},
			},
			Upgrades = {
				Hit = {
					Damage = 4,
					Daze = 1,
					Affliction_Buildup = 1,
				},

				Explosion = {
					Damage = 8,
					Daze = 2,
					Affliction_Buildup = 2,
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