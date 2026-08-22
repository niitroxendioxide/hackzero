return {
	Display_Name = 'Mitsune Haku',
	Nickname = 'Miku',
	Element = 'Ice',
	Role = 'Support',
	Tier = "Legendary",
	Faction = "VOCALOID",
	
	IconGlowColor = Color3.fromRGB(100, 252, 183),

	Appearance = {
		Height = 3
	},

	--
	Stats = {
		Health = 609,
		Attack = 80,
		Defense = 10,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 70,
		Speed = 1,
		Energy_Regeneration = 1.2,
		Affliction_Aptitude = 80,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Attack = 15,
        Health = 102.3,
        Defense = 2,
	},

	ImportantStats = {
		'Attack',
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
                Cooldown = 0.05,
				AttackData = {
					[1] = {0.15, 0.25, 1},
					[1.1] = {0, 0.35},
					[1.2] = {0, 0.45},
					[1.3] = {0, 0.55},
					[1.4] = {0, 0.65},
					[2] = {0, 0.7, 0.75},
					[2.1] = {0, 0.8},
					[2.2] = {0, 0.9},
					[3] = {0.15, 0.4, 1.35, 0.3},
					[3.1] = {0, 1.27},
				},
                Speed = 1.3,
                Animation_Speed = 1.15,
				Range = 35,

				EffectData = {
					Highlight = true,
					HueShift = 80,
				},

				DamageMult = {
					[1] = 67,
					[2] = 89,
					[3] = 170,
				},

				DazeMult = {
					[1] = 20,
					[2] = 75,
					[3] = 70,
				},

				Hit = {
					Stun = 0.3,
					HitType = "Blunt",
					Affliction = "Ice",
					Knockback = {
						vector.create(0, 0, 1),
						8,
						0.2,
					},
				},
			},

			Upgrade = {
				Damage = {
					[1] = 2,
					[2] = 4,
				},

				Daze = {
					[1] = 0.5,
					[2] = 1,
				}
			}
		},

		['Ultimate'] = {
            Base = {
                Cooldown = 2,
                Speed = 1,
                Animation_Speed = 1,
				
				-- Times
				Ult_Length = 6,
                Attack_State_Time = 2.183,
				Startup_Length = 1.5,
				Hit_Frequency = 1 / 3,

				
                Hit_Data = {
					Damage = 120,
					Daze = 45,
					Affliction = "Ice",
					Affliction_Buildup = 65,
					HitType = "Blunt",
				},

				Collat_Hit = {
					Damage = 65,
					Daze = 15,
					Affliction = "Ice",
					Affliction_Buildup = 25,
					HitType = "Blunt",
					Knockback = {
						vector.create(0, 0, 1),
						8,
						0.2,
					}
				},
            },
        },

		['Quick Assist'] = {
            Base = {
                Cooldown = 0.2,
                Attack_State_Time = 1.1,
                Speed = 1,
                Animation_Speed = 1,

				CustomVerify = true,

				HitData = {
					Damage = 70,
					Daze = 50,
					Affliction = "Ice",
					Affliction_Buildup = 40,
					HitType = "Blunt",
					Knockback = {
						vector.create(0, 0, 1),
						8,
						0.2,
					}
				},

				EffectData = {
					Highlight = true,
					HueShift = 80,
				},
            },

			Upgrade = {

			}
        },

		['Dodge Counter'] = {
            Base = {
                Cooldown = 0.2,
                Attack_State_Time = 1.5,
                Speed = 1,
                Animation_Speed = 1,

				HitData = {
					Damage = 375,
					Daze = 175,
					Affliction = "Ice",
					Affliction_Buildup = 100,
					HitType = "Blunt",
					Knockback = {
						vector.create(0, 0, 1),
						18,
						0.2
					},
				},
            },

			Upgrade = {
				HitData = {
					Damage = 1,
					Daze = 3,
					Affliction_Buildup = 0.5,
				}
			}
        },

		['Special'] = {
            Base = {
                Cooldown = 0.2,
                Attack_State_Time = 5e12,
                Speed = 1,
                Animation_Speed = 1,
				Range = 200,

                Required_Energy = 60,
				CustomVerify = true,
				Assist_Frequency = 7,

				MaxAttackValue = 500,
				MaxDefenseValue = 600,

				StrengthBuffId = 'MikuStrengthBuff',
				DefenseBuffId = 'MikuDefenseBuff',
				StrengthBuffValue = 0.2,
				DefenseBuffValue = 70,
            },

			Upgrade = {
				StrengthBuffValue = 0.01,
				DefenseBuffValue = 70,
			},
        },

		['EX Special'] = {
			Base = {
				Cooldown = 2,
				Speed = 1,
				Range = 200,
				Animation_Speed = 1,
				Attack_State_Time = 5e12,
				Required_Energy = 60,
				CustomVerify = true,
				Assist_Frequency = 4.5,

				OrbBuffs = {
					{
						Type = "Attack",
						Time = 4.5,
						Value = "7%",
						Tag = "MikuOrbStrBuff",
					},

					{
						Type = "Defense",
						Time = 4.5,
						Value = "8%",
						Tag = "MikuOrbDefBuff",
					}
				},

				MaxAttackValue = 750,
				MaxDefenseValue = 600,

				StrengthBuffId = 'MikuStrengthBuff',
				DefenseBuffId = 'MikuDefenseBuff',
				StrengthBuffValue = 0.25,
				DefenseBuffValue = 70,
			},

			Upgrade = {
				StrengthBuffValue = 0.02,
				DefenseBuffValue = 3,
			}
		}
	},

	Ascension_Data = {
		[1] = {
			Description = 'Miku ascension 1',
		},

		[2] = {
			Description = 'Miku ascension 2',
		},

		[3] = {
			Description = 'Miku ascension 3',
		},

		[4] = {
			Description = 'Miku ascension 4',
		},

		[5] = {
			Description = 'Miku ascension 5',
		},

		[6] = {
			Description = 'Miku ascension 6',
		},
	}
}