return {
	Display_Name = 'Hiro Roku',
	Nickname = 'Hiro',
	Element = 'Water',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Kamunabi",

	
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
		Attack = 127,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 20,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 90,
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
	},

	Moveset_Data = {
		['Passive'] = {
			Meters = {
				AkaCharge = {
					Ascension = 0,
					Max = 10_000,
					Id = 1,
					Description = "Gauge that fills up from receiving damage while holding the \'Aka\' stance"
				}
			},
		},


		['Dodge'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				
				Hit = {
					HitType = 'Slash',
					Damage = 74,
					Affliction_Buildup = 10,
					Affliction = 'Physical',
					Daze = 32,
					Stun = 0.25,
					Knockback = {
						vector.create(0, 0, -1),
						20,
						0.1
					},
				},
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = .01,
				Speed = 1.3,
				Animation_Speed = 1.1,
				Range = 75,
				Release = true,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1]   = {0.24, .217, .3},
					[2]   = {0.03, .1, .45, .7, 0.33},
					[2.1] = {0, .55},
					[3]   = {0.2, .183, 0.55, 0.35, 0.5},
					[3.1] = {0, .55},
					[4]   = {0.15, .2, 0.5, 0.35, 0.33},
					[4.1] = {0, .2},
					[4.2] = {0, .5},
				},

				Walk_Time = 0.1,

				Effect_Data = {
					Audio = {
						Id = { 6216173737 },
						Volume = 0.35,
					}
				},

				Damage = {
					[1] = 71,
					[2] = 45,
					[2.1] = 82,
					[3] = 71,
					[3.1] = 122,
					[4] = 81,
					[4.1] = 30,
					[4.2] = 102,
				},

				Daze = {
					[1] = 17,
					[2] = 22,
					[2.1] = 25,
					[3] = 26,
					[3.1] = 19,
					[4] = 19,
					[4.1] = 8,
					[4.2] = 21,
				},

				Affliction_Buildup = {
					[1] = 35,
					[2] = 45,
					[2.1] = 25,
					[3] = 20,
					[3.1] = 58,
					[4] = 21,
					[4.1] = 7,
					[4.2] = 25,
				}
			}
		},

		['Special'] = {
			Base = {
				Cooldown = .25,
				Speed = 1,

				Required_Energy = 30,
				Walk_Time = 0.1,

				Attack_State_Time = 0.5,
				Animation_Speed = 1,

				Hit = {
					Damage = 120,
					HitType = 'Slash',
					Affliction = 'Physical',
					Stun = 0.375,
					Daze = 61,
					Affliction_Buildup = 12,
					HitsAirborne = true,
				},
			},

			Upgrade = {},
		},

		['EX Special'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 1,
				Required_Energy = 30,
				Range = 100,
				Hit = {
					HitType = 'Slash',
					Damage = 164,
					Affliction = 'Water',
					Affliction_Buildup = 15,
					Stun = 0.45,
					Daze = 20,
					HitsAirborne = true,
					Knockback = {
						vector.create(0, 0, 1),
						10,
						0.2
					}
				},

				HitEffectData = {
					HighlightColor = Color3.new(),
					Emitter = 'KuroHit',
					Highlight = true,
					Audio = {
						Id = { 785201669 }, --{ 9117969687, 175024455 }, -- 8595980577 lighter
						Volume = 0.35,
					}
				},
				HitEnemyEffects = {
					{
						Type = 'Defense',
						Value = -5,
						Time = 2,
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 4.5,
					Affliction_Buildup = 5,
					Daze = 1,
				},
			},
		},

		['Dodge Counter'] = {
			Base = {
				Hit_Count = 16,
				Hit_Frequency = 1/16,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 1.5,
				Hit = {
					Damage = 25,
					HitType = 'Slash',
					Affliction = 'Water',
					Stun = 0.5,
					Daze = 5,
					Affliction_Buildup = 3,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.25,
				}
			},
		},

		['Quick Assist'] = {
			Base = {
				Buffs = {
					{
						Type = 'Speed',
						Value = 0.1,
						Tag = 'NishikiBuff',
						Time = 8,
					},

					{
						Hide = true,
						Tag = 'DefNishiki',
						Type = 'Defense',
						Value = "25%",
						Time = 8,
					}
				},

				Hit = {
					Damage = 520,
					Affliction = "Water",
					HitType = "Slash",
					Daze = 80,
					Affliction_Buildup = 120,
					Stun = 0.7,
				},

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.5,
			},

			Upgrade = {
				Hit = {
					Damage = 2.5,
				}
			},
		},

		['Ultimate'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 1.5,

				AccumulatedDamageMultiplier = 4,
				DamageVariation = 750,

				Hit = {
					Damage = 200,
					Daze = 56,
					Affliction_Buildup = 100,
					HitType = 'Slash',
					Stun = 0.66,
					Affliction = 'Water',
					HitsAirborne = true,
				},
			},

			Upgrade = {
				AccumulatedDamageMultiplier = 0.2,
				DamageVariation = -30,
				
				Hit = {
					Damage = 10,
					Daze = 0.75,
					Affliction_Buildup = 1,
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