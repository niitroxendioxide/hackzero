return {
	Display_Name = 'Kakarot',
	Nickname = 'Son Goku',
	Element = 'Energy',
	Role = 'Affliction',
	Tier = "Legendary",
	Faction = "Z Warriors",

	Appearance = {
		Height = 3.15
	},

	ImportantStats = {
		'Attack',
		'Affliction_Aptitude',
	},

	--
	Stats = {
		Health = 626,
		Attack = 127,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 90,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 120,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Health = 121.38,
		Attack = 6.33,
		Defense = 9.44,
	},

	Moveset_Data = {
		['Passive'] = {
			Description = '',
			Meters = {
				SaiyanSurge = {
					Ascension = 2,
					Description = 'When completing a full basic attack string obtain one charge of Saiyan Surge, when hitting an enemy with an EX-Special, get two charges, up to 3. Hold basic attack with two charges to use Super God Fist',
					Id = 1,
					Max = 4,
				},
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = 0.1,
				Speed = 1.25,

				Attack_State_Time = {
					.25 ,
					.583,
					.6,
					.7,
					0.34,
					.75,
				},
				Animation_Speed = 1,

				Hit_Times = {
					0.15,
					0.267,
					0.267,
					0.3,
					0.17,
					0.483,
				},

				Effect_Data = {
					Highlight = true,
					Audio = {
						Id = {8595980577}, --{ 9117969687, 175024455 }, -- 8595980577 lighter
						Volume = 0.5,
					}
				},

				Walk_Time = 0.2,
				Forward_Impulse = 10,

				Hit_Data = {
					HitType = 'Blunt',
					Affliction = 'Energy',
					HitsAirborne = true,
					Stun = 0.325,
					Knockback = {
						vector.create(0, 0, 1),
						10,
						0.2,
					}
				},

				Damage_Mult = {
					[1] = 36,
					[2] = 62,
					[2.5] = 121,
					[3] = 83,
					[4] = 92,
					[4.5] = 91,
					[5] = 98,
					[6] = 291,
				},

				Daze_Mult = {
					[1] = 17,
					[2] = 22.5,
					[2.5] = 29,
					[3] = 25,
					[4] = 32,
					[4.5] = 18,
					[5] = 22,
					[6] = 27,
				},

				Affliction_Buildup = {
					[1] = 101,
					[2] = 122,
					[2.5] = 285,
					[3] = 155,
					[4] = 103,
					[4.5] = 92,
					[5] = 212,
					[6] = 170,
				}
			},

			--
			Upgrades = {
				Damage_Mult = {
					[1] = 3.3,
					[2] = 5.7,
					[3] = 7.6,
					[4] = 8,
					[5] = 9,
					[6] = 26,
				},
			}
		},

		['Special'] = {
			Base = {
				Cooldown = 1,
				Speed = 1,

				Required_Energy = 60,
				Walk_Time = 0.1,

				Attack_State_Time = 0.5,
				Animation_Speed = 1,				

				--
				Sledge_Hammer_Effect = {
					Type = 'Defense',
					Value = "-10%",
					Time = 5,
				},

				Ki_Blast_Hit = {
					Damage = 130,
					Affliction = "Energy",
					Stun = 0.4,
					Daze = 30,
					HitType = "Blunt",
					HitsAirborne = true,
					Affliction_Buildup = 70,
				},

				Sledge_Hammer = {
					Damage = 237,
					StunTime = 0.75,
					Daze = 264,
					Affliction_Buildup = 65,
				},
			},

			Upgrade = {
				Ki_Blast_Hit = {
					Damage = 3.75,
					Daze = 1,
					Affliction_Buildup = 3,
				},

				Sledge_Hammer = {
					Damage = 3.75,
					Daze = 2.25,
					Affliction_Buildup = 0.25,
				}
			},
		},
		['EX Special'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = {0.5, 5},
				
				Required_Energy = 45,
				Hit_Frequency = 14/60,
				Walk_Time = 5/60,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 3,
				Knockback_Time = 0.2,


				--
				SSJ2Buff = {{
					Type = 'Attack',
					Value = "30%",
					Time = 3,
				},{
					Type = 'Speed',
					Value = .25,
					Time = 3,
				}},

				ModeEnemyDebuff = {
					Type = 'Defense',
					Value = '15%',
					Time = 3,
				},

				--
				Default = {
					Damage = 248;
					Daze = 19;
					Affliction_Buildup = 22;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 2.5;
					Airborne = true;
				};

				Slam_Hit_Mode = {
					Damage = 102;
					Daze = 19;
					Affliction_Buildup = 8;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 3.5;
					HitsAirborne = true;
					Airborne = true;
				};
				
				Hit_Effect_Data = {
					Highlight = true,
					Audio = {
						Id = { 9117969687, 175024455 }, -- 8595980577 lighter
						Volume = 0.5,
					}
				},

				Hit_Mode = {
					Damage = 312;
					Daze = 22;
					Affliction_Buildup = 33;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 3;
					HitsAirborne = true;


					Knockback = {
						vector.create(0, 0, 1),
						6,
						0.2
					},
				};
			},

			Upgrades = {
				Default = {
					Damage = 11,
					Daze = 1,
				},

				Slam_Hit_Mode = {
					Damage = 3,
					Daze = 0.5,
				},

				Hit_Mode = {
					Damage = 9.8,
					Daze = 1.5,
				}
			}
		},

		['Ultimate'] = {
			Base = {
				Speed = 1,
				NoAutoTrack = true,

				SSBuff = {{
					Type = 'Attack',
					Value = "25%",
					Tag = 'GOKU_MODE_BUFF',
					Time = 15,
				},{
					Type = 'Speed',
					Value = .3,
					Time = 15,
				}}
			},
			Upgrades = {},
		},


		['Quick Assist'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 1.45,
				Hit_Frequency = 4/60,
				Hit_Data = {
					Damage = 34,
					Daze = 3,
					Affliction = 'Energy',
					Affliction_Buildup = 45,
					Stun = 0.3,
					HitType = 'Blunt',
					
					Knockback = {
						Vector3.new(0, 0, 1),
						10,
						0.2,
					},
				},
			},

			Upgrades = {
				Hit_Data = {
					Damage = 0.5,
					Daze = 2.25,
				}
			},
		},


		['Dodge Counter'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 0.6,
				Attack_State_Time = 0.9,
				Cooldown = 1,

				Last_Knockback = {
					Vector3.new(0, 0, 1),
					20,
					0.2,
				},

				Default_Hit_Data = {
					HitsAirborne = true,
					Damage = 55,
					Daze = 7,
					Affliction = 'Energy',
					Affliction_Buildup = 0.1,
					Stun = 0.22,
					HitType = 'Blunt',
				},
			},

			Upgrades = {
				Default_Hit_Data = {
					Damage = 2.5,
				}
			}
		},
	},

	Ascension_Data = {
		[1] = {
			Description = 'Goku ascension 1',
		},

		[2] = {
			Description = 'Goku ascension 2',
		},

		[3] = {
			Description = 'Goku ascension 3',
		},

		[4] = {
			Description = 'Goku ascension 4',
		},

		[5] = {
			Description = 'Goku ascension 5',
		},

		[6] = {
			Description = 'Goku ascension 6',
		},
	}
}