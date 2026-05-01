return {
	Display_Name = 'Hatsune Miku',
	Nickname = 'Miku',
	Element = 'Energy',
	Role = 'Support',
	Tier = "Legendary",
	Faction = "VOCALOID",

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

        ['Special'] = {
            Base = {
                Cooldown = 0.2,
                Attack_State_Time = 5e12,
                Speed = 1,
                Animation_Speed = 1,

                Required_Energy = 60,
				CustomVerify = true,

                Buffs = {
                    {
                        Type = "Attack",
                        Time = 20,
                        Value = "25%",
                        Tag = "MikuStrengthBuff",
                    },

                    {
                        Type = "Defense",
                        Time = 20,
                        Value = 120,
                        Tag = "MikuDefenseBuff",
                    }
                },
            },
        },

		['EX Special'] = {
			Base = {
				Cooldown = 2,
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 5e12,
				Required_Energy = 60,
				CustomVerify = true,

				Buffs = {
					{
						Type = "Attack",
						Time = 30,
						Value = "35%",
						Tag = "MikuStrengthBuff",
					},

					{
						Type = "Defense",
						Time = 30,
						Value = 140,
						Tag = "MikuDefenseBuff",
					}
				},
			},
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