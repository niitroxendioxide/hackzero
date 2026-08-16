return {
	Display_Name = 'Sonku (Z)',
	Nickname = 'Kokun (Z)',
	Element = 'Physical',
	Role = 'Affliction',
	Tier = "Legendary",
	Faction = "Z Warriors",

	IconGlowColor = Color3.fromRGB(255, 146, 83),

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
				Release = true,
				ReleaseVerify = true,
				Cooldown = 0,
				Speed = 1,
				Range = 75,
				
				Attack_Data = {
					--- move, hit, endlag
					[1]   = {0.1, 0.15, 0.25, 0.15, 1.5},
					[2]   = {0.15, 0.267, 0.5, 0.2},
					[2.1] = {0, 0.5},
					[3]   = {0.2, 0.267, 0.6, 0.1, 2},
					[4]   = {0.06, 0.3, 0.55, 0.15, 1.5},
					[4.1] = {0, 0.53},
					[5]   = {0.3, 0.27, 0.45, 0.5, -2.25},
					[6]   = {0.18, 0.483, 0.52, 0.3, 2, true},
				},

				Animation_Speed = 1,

				Effect_Data = {
					Highlight = true,
					Audio = {
						Id =  {8595980577}, --{ 9117969687, 175024455 }, -- 8595980577 lighter  --{ 135200034075896, 135175485527318 }, 
						Volume = 0.5,
					}
				},

				Walk_Time = 0.2,
				Forward_Impulse = 10,

				SuperGodFist = {
					Walk_Time = 0.4,
					Attack_State_Time = 0.75,
				},

				SuperGodFistHit = {
					Damage = 140,
					Daze = 20,
					Affliction_Buildup = 90,
					Affliction = 'Physical',
					HitsAirborne = true,
					Stun = 0.4,
					Knockback = {
						vector.create(0, 0, 1),
						30,
						0.2,
					},
				},

				DiveKickHitData = {
					Damage = 175,
					Daze = 10,
					Affliction_Buildup = 115,
					Affliction = 'Physical',
					HitsAirborne = true,
					Stun = 0.5,
					Knockback = {
						vector.create(0, 0, 1),
						25,
						0.5,
					},
				},

				SledgeHammerData = {
					CanChainAttack = true,
					Damage = 120,
					Daze = 25,
					Affliction_Buildup = 75,
					Affliction = 'Physical',
					HitsAirborne = true,
					Stun = 0.5,
					Knockback = {
						vector.create(0, 0, 1),
						45,
						0.5,
					},
				},

				Hit_Data = {
					HitType = 'Blunt',
					Affliction = 'Physical',
					HitsAirborne = true,
					Stun = 0.325,
					Knockback = {
						vector.create(0, 0, 1),
						15,
						0.1,
					}
				},

				Damage_Mult = {
					[1] = 36,
					[2] = 62,
					[2.1] = 121,
					[3] = 83,
					[4] = 92,
					[4.1] = 91,
					[5] = 98,
					[6] = 291,
				},

				Daze_Mult = {
					[1] = 17,
					[2] = 22.5,
					[2.1] = 29,
					[3] = 25,
					[4] = 32,
					[4.1] = 18,
					[5] = 22,
					[6] = 27,
				},

				Affliction_Buildup = {
					[1] = 101,
					[2] = 122,
					[2.1] = 285,
					[3] = 155,
					[4] = 103,
					[4.1] = 92,
					[5] = 212,
					[6] = 170,
				}
			},

			--
			Upgrades = {
				Damage_Mult = {
					[1] = 3.3,
					[2] = 5.7,
					[2.1] = 5.7,
					[3] = 7.6,
					[4] = 8,
					[4.1] = 8,
					[5] = 9,
					[6] = 26,
				},

				SledgeHammerData = {
					Damage = 2,
					Daze = 0.75,
					Affliction_Buildup = 1,
				},
			}
		},

		['Special'] = {
			Base = {
				Cooldown = 1,
				Speed = 1,

				Required_Energy = 35,
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
					DontChargeEnergy = true,
				},

				Sledge_Hammer = {
					Damage = 237,
					StunTime = 0.75,
					Daze = 264,
					Affliction_Buildup = 65,					
					DontChargeEnergy = true,
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
				Cooldown = 0.25,
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.5,
				Range = 75,

				DiskTime = 1,
				DiskSpeed = 150,

				Required_Energy = 35,
				Hit_Frequency = 14/60,
				Walk_Time = 5/60,
				GroundExtraTime = 0.317,
				DestructoDiskTime = 0.767,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 3,
				Knockback_Time = 0.2,

				--
				SSJ2Buff = {{
					Type = 'Attack',
					Value = "20%",
					Tag = 'SS2',
					Time = 3,
				},{
					Hide = true,
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
					CanChainAttack = false,
					Damage = 248;
					Daze = 19;
					Affliction_Buildup = 22;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 2.5;
					Airborne = true;
					Knockback = {
						vector.create(0, 0, 1),
						61,
						0.2,
					},
				};

				DestructoDisk = {
					CanChainAttack = false,
					Damage = 100;
					Daze = 32;
					Affliction_Buildup = 45;
					Affliction = 'Energy';
					HitType = 'Slash';
					Stun = .5;
					HitsAirborne = true,
				};

				ExtenderMidAir = {
					CanChainAttack = false,
					Damage = 350;
					Daze = 22;
					Affliction_Buildup = 35;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 0.65;
					HitsAirborne = true;
					Knockback = {
						vector.create(0, 0, 1),
						15,
						0.3,
					},
				};

				Slam_Hit_Mode = {
					Damage = 102;
					Daze = 19;
					Affliction_Buildup = 8;
					Affliction = 'Physical';
					HitType = 'Blunt';
					Stun = 3.5;
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
					Time = 22,
				},{
					Hide = true,
					Type = 'Speed',
					Value = .3,
					Time = 22,
				}}
			},
			Upgrades = {},
		},


		['Quick Assist'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 2.5,
				Hit_Frequency = 4/60,
				Hit_Data = {
					Damage = 67,
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
					Damage = 1,
					Daze = 2.25,
				}
			},
		},

		['Chain Attack'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.75,
				Hit_Data = {
					Damage = 150,
					Daze = 32,
					Affliction = 'Energy',
					Affliction_Buildup = 61,
					Stun = 0.3,
					HitType = 'Blunt',
					
					Knockback = {
						Vector3.new(0, 0, 1),
						20,
						0.1,
					},
				},
			},

			Upgrades = {
				Hit_Data = {
					Damage = 2,
					Daze = 0.5,
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
			Description = 'TODO',
		},

		[2] = {
			Description = [[Unlocks 'Saiyan Surge', for every completed 'Basic Attack' String or succesful hit of 'EX Special: Upwards Kick', obtain a charge of Saiyan Surge, up to a maximum of 4.
			Hold 'Basic Attack' with 2 charges of 'Saiyan Surge' to use 'Super God Fist', it's damage scales with the enemies HP, up to a 200% extra damage the lower the enemies HP is.
			]],
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
			Description = [[Your ultimate, 'Saiyan Rage' is replaced with 'Ultimate: Super Saiyan 3'. Instead of bringing a power up alone, super saiyan 3 stuns all enemies nearby after transforming.
			Super Saiyan 3 increases the strength obtained from transforming, as well as a slightly faster attack speed. Goku may also dodge incoming attacks by himself, as well as having automatic energy regeneration.
			Your 'EX Special: Super Saiyan 2', gets replaced with ...
			]],
		},
	}
}