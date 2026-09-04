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
		--[[
			Lightning charges build from landing Electric hits. At 6 the meter is full and
			Lightning Mode becomes available - holding Basic Attack enters it.
			Wired up by TeamService (CreateMeter/OnMeterUpdated) -> AbilityService:TriggerMeterFullEvent
			-> Kakashi/Passives.luau:OnPassiveFilled.
		]]
		['Passive'] = {
			Meters = {
				Lightning = {
					Ascension = 0,
					Max = 6,
					Id = 1,
					Description = "Lightning",
				}
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Attack_State_Time = 0.25,
				Speed = 1,
				Animation_Speed = 1,
				Range = 85,

				-- Holding Basic Attack on a full Lightning meter enters Lightning Mode.
				Release = true,
				Lightning_Mode_Hold_Time = 0.4,
				Lightning_Mode_Time = 20,
				-- Steps that turn Electric while in Lightning Mode (moveset.md: first two punches + last kick).
				Lightning_Mode_Steps = {
					[1] = true,
					[1.1] = true,
					[3.1] = true,
				},
				Lightning_Mode_Hit = {
					Affliction = 'Electric',
					Affliction_Buildup = 55,
				},
				-- Daze resistance shred applied by Lightning Mode basics.
				Lightning_Mode_Daze_Shred = {
					Tag = 'Kakashi_DazeShred',
					Type = 'Daze_Resistance',
					Value = -0.15,
					Time = 8,
				},

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
					[1.1] = 1.5,
					[2] = 2,
					[2.1] = 1.75,
					[2.2] = 1.8,
					[2.3] = 1.85,
					[3] = 1,
					[3.1] = 1.45,
				},
				Daze = {
					[1] = 0.75,
					[1.1] = 0.75,
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
				Cooldown = 1,
				Attack_State_Time = 2,
				Speed = 1,
				Range = 100,
				Required_Energy = 40,
				First_Run_Time = .5,
				Second_Run_Time = .5,

				-- Lightning Mode replaces Raiden with 'Raikiri: Denko Rensen' (zig-zag multi-hit).
				Denko_Rensen_Startup_Time = 0.35,
				Denko_Rensen_Dash_Count = 4,
				Denko_Rensen_Dash_Time = 0.18,
				Denko_Rensen_Dash_Power = 2.1,
				Denko_Rensen_Hitbox_Size = vector.create(14, 5, 12),

				Sosenko_Hit_Max = 6,
				Sosenko_Hit_Frequency = 0.06,
				Sosenko_Dash_Hitbox_Size = vector.create(9, 9, 55),

				Raiden_Run_Time = .6,
				Raiden_Run_Power = 1.5,
				Raiden_Startup_Time = 0.6,
				Raiden_Hit_Frequency = 0.15,
				Raiden_Full_Control = false,

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

				Raiden_Knockback = {
					vector.create(0, 0, 1),
					54,
					0.4,
					true,
				},
				Raiden_Hit = {
					HitType = 'Slash',
					Damage = 792,
					Stun = 0.5,
					Daze = 29,
					Affliction = 'Electric',
					Affliction_Buildup = 119,
					NoRotate = true,
				},
				-- Enemies caught by the Raiden blade are paralyzed briefly (moveset.md).
				Raiden_Paralyze_Time = 0.5,

				Denko_Rensen_Hit = {
					HitType = 'Slash',
					Damage = 245,
					Stun = 0.3,
					Daze = 24,
					Affliction = 'Electric',
					Affliction_Buildup = 105,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.5,
					Daze = 0.5,
					Affliction_Buildup = 2.25,
				},
				Throw_Hit = {
					Damage = 0.75,
					Daze = 0.1,
				},
				Denko_Rensen_Hit = {
					Damage = 1.6,
					Daze = 0.25,
					Affliction_Buildup = 1.15,
				},
				Sosenko_Dash_Hit = {
					Damage = 1.75,
					Daze = 0.25,
					Affliction_Buildup = 1,
				},
				Raiden_Hit = {
					Damage = 1.9,
					Daze = 0.27,
					Affliction_Buildup = 1.1,
				},
			},
		},

		--[[
			Default: 'Raiton: Raiju Tsuiga' - a lightning dog strikes forward and paralyzes.
			Lightning Mode: 'Shishi Rendan' launch, then a 'Raikiri' ground slam.
		]]
		['Dodge Counter'] = {
			Base = {
				Cooldown = 0.5,
				Attack_State_Time = 1.1,
				Speed = 1,
				Animation_Speed = 1,
				Range = 90,

				Startup_Time = 0.2,
				Dog_Speed = 90,
				Dog_Max_Time = 0.9,
				Dog_Size = vector.create(7, 7, 9),
				Paralyze_Time = 2.5,

				Hitbox_Size = vector.create(12, 6, 16),
				Hitbox_Offset = vector.create(0, 0, -8),

				Hit = {
					HitType = 'Slash',
					Damage = 210,
					Stun = 0.55,
					Daze = 34,
					Affliction = 'Electric',
					Affliction_Buildup = 88,
					Knockback = {
						vector.create(0, 0, 1),
						18,
						0.25,
					}
				},

				-- Lightning Mode variant
				Rendan_Kick_Count = 3,
				Rendan_Kick_Frequency = 0.14,
				Rendan_Slam_Time = 0.75,
				Rendan_Slam_Radius = 18,

				Rendan_Hit = {
					HitType = 'Blunt',
					Damage = 96,
					Stun = 0.3,
					Daze = 18,
					Affliction = 'Electric',
					Affliction_Buildup = 42,
					Airborne = true,
					HitsAirborne = true,
				},
				Rendan_Slam_Hit = {
					HitType = 'Slash',
					Damage = 340,
					Stun = 0.6,
					Daze = 45,
					Affliction = 'Electric',
					Affliction_Buildup = 130,
					HitsAirborne = true,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.6,
					Daze = 0.3,
					Affliction_Buildup = 1.2,
				},
				Rendan_Hit = {
					Damage = 0.8,
					Daze = 0.2,
					Affliction_Buildup = 0.6,
				},
				Rendan_Slam_Hit = {
					Damage = 1.85,
					Daze = 0.4,
					Affliction_Buildup = 1.4,
				},
			},
		},

		--[[
			Default: 'Raikiri: Issen' - subs in with a dash into the first target.
			Lightning Mode: Kagebunshin split into two lightning dogs, heavy buildup + paralyze.
		]]
		['Quick Assist'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 1.15,
				Speed = 1,
				Animation_Speed = 1,
				Range = 110,

				Startup_Time = 0.25,
				Dash_Time = 0.35,
				Dash_Power = 2.4,
				Hitbox_Size = vector.create(10, 6, 26),
				Hitbox_Offset = vector.create(0, 0, -12),

				Hit = {
					HitType = 'Slash',
					Damage = 265,
					Stun = 0.5,
					Daze = 38,
					Affliction = 'Electric',
					Affliction_Buildup = 96,
					Knockback = {
						vector.create(0, 0, 1),
						22,
						0.3,
					}
				},

				-- Lightning Mode variant: two dogs, one per clone
				Dog_Count = 2,
				Dog_Speed = 105,
				Dog_Max_Time = 1.1,
				Dog_Size = vector.create(8, 8, 10),
				Dog_Spread = 7,
				Paralyze_Time = 3,

				Dog_Hit = {
					HitType = 'Slash',
					Damage = 315,
					Stun = 0.75,
					Daze = 48,
					Affliction = 'Electric',
					Affliction_Buildup = 165,
				},
				-- Electric buildup shred left on hit targets (moveset.md: faster buildup%).
				Dog_Resistance_Shred = {
					Tag = 'Kakashi_ElectricShred',
					Value = -0.2,
					Time = 10,
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.7,
					Daze = 0.35,
					Affliction_Buildup = 1.25,
				},
				Dog_Hit = {
					Damage = 2,
					Daze = 0.45,
					Affliction_Buildup = 1.8,
				},
			},
		},

		--[[ Kakashi subs in and uses 'Raikiri: Denko Rensen'. ]]
		['Chain Attack'] = {
			Base = {
				Cooldown = 0.5,
				Attack_State_Time = 1.9,
				Speed = 1,
				Animation_Speed = 1,
				Range = 120,

				Startup_Time = 0.4,
				Dash_Count = 5,
				Dash_Time = 0.16,
				Dash_Power = 2.3,
				Hitbox_Size = vector.create(15, 6, 13),

				Hit = {
					HitType = 'Slash',
					Damage = 288,
					Stun = 0.3,
					Daze = 30,
					Affliction = 'Electric',
					Affliction_Buildup = 118,
				},
				Final_Hit = {
					HitType = 'Slash',
					Damage = 640,
					Stun = 0.7,
					Daze = 62,
					Affliction = 'Electric',
					Affliction_Buildup = 190,
					Knockback = {
						vector.create(0, 0, 1),
						35,
						0.35,
					}
				},
			},

			Upgrade = {
				Hit = {
					Damage = 1.8,
					Daze = 0.3,
					Affliction_Buildup = 1.3,
				},
				Final_Hit = {
					Damage = 3.2,
					Daze = 0.6,
					Affliction_Buildup = 2,
				},
			},
		},

		--[[
			'Raikiri: Sōraishin' - dash, launch everything in a small area, zig-zag them
			mid-air, then slam them all down with a final Raikiri.
		]]
		['Ultimate'] = {
			Base = {
				Cooldown = 1,
				Attack_State_Time = 2.25,
				Speed = 1,
				Animation_Speed = 1,
				Range = 130,

				Dash_Time = 0.4,
				Dash_Power = 2.6,
				Dash_Hitbox_Size = vector.create(12, 8, 30),

				Launch_Radius = 22,
				Launch_Time = 0.45,
				Airborne_Hit_Count = 6,
				Airborne_Hit_Frequency = 0.16,
				Slam_Time = 0.8,
				Slam_Radius = 26,

				Launch_Hit = {
					HitType = 'Blunt',
					Damage = 180,
					Stun = 1.4,
					Daze = 40,
					Affliction = 'Electric',
					Affliction_Buildup = 90,
					Airborne = true,
					HitsAirborne = true,
				},
				Airborne_Hit = {
					HitType = 'Slash',
					Damage = 215,
					Stun = 0.3,
					Daze = 22,
					Affliction = 'Electric',
					Affliction_Buildup = 105,
					HitsAirborne = true,
					DontChargeUlt = true,
				},
				Slam_Hit = {
					HitType = 'Slash',
					Damage = 1450,
					Stun = 1,
					Daze = 95,
					Affliction = 'Electric',
					Affliction_Buildup = 240,
					HitsAirborne = true,
					DontChargeUlt = true,
					Knockback = {
						vector.create(0, 0, 1),
						40,
						0.4,
					}
				},
			},

			Upgrade = {
				Launch_Hit = {
					Damage = 1.4,
					Daze = 0.4,
					Affliction_Buildup = 1,
				},
				Airborne_Hit = {
					Damage = 1.55,
					Daze = 0.22,
					Affliction_Buildup = 1.15,
				},
				Slam_Hit = {
					Damage = 6.5,
					Daze = 1.1,
					Affliction_Buildup = 2.6,
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