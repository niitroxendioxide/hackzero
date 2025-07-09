return {
	Display_Name = 'Kakarot',
	Nickname = 'Son Goku',
	Element = 'Physical',
	Role = 'Affliction',
	Tier = "Legendary",
	Faction = "Z Warriors",

	Appearance = {
		Height = 3.15
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
		['Basic Attack'] = {
			Base = {
				Cooldown = .05,
				Speed = 1.25,

				Attack_State_Time = {
					.63 ,
					.525,
					.67,
					1.3,
					1,
				},
				Animation_Speed = 1.25,

				Hit_Times = {
					0.4,
					0.233,
					0.617,
					0.85
				},

				Walk_Time = 0.3,
				Forward_Impulse = 10,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 10,
				Knockback_Time = 0.2,

				Damage_Mult = {
					[1] = 36,
					[2] = 62,
					[3] = 83,
					[4] = 163,
					[5] = 98,
					[6] = 291,
				},

				Daze_Mult = {
					[1] = 17,
					[2] = 22.5,
					[3] = 25,
					[4] = 32,
					[5] = 22,
					[6] = 27,
				},

				Affliction_Buildup = {
					[1] = 89,
					[2] = 102,
					[3] = 125,
					[4] = 155,
					[5] = 192,
					[6] = 202,
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
				Walk_Time = 0.3,

				Attack_State_Time = 0.5,
				Animation_Speed = 1,
			},
		},
		['EX Special'] = {
			Base = {
				Speed = 1,
				Attack_State_Time = 5,
				Required_Energy = 60,
				Animation_Speed = 1,
				DontConsumeEnergy = true,
				Release = true,
				Hit_Frequency = 14/60,
				Walk_Time = 5/60,
				Energy_Per_Hit = 3,

				Damage_Mult = 248,
				Daze_Mult = 19,
				Affliction_Buildup = 1.5,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 3,
				Knockback_Time = 0.2,
			},

			Upgrades = {
				Damage_Mult = 27,
				Daze_Mult = 1,
			}
		},

		['Ultimate'] = {
			Base = {
				Speed = 1,
				NoAutoTrack = true,

				SSBuff = {{
					Type = 'Attack',
					Value = "25%",
					Time = 10,
				},{
					Type = 'Speed',
					Value = .3,
					Time = 10,
				}}
			},
			Upgrades = {},
		},


		['Quick Assist'] = {
			Base = {
				Speed = 1,

				AssistBuff = {{
					Type = 'Attack',
					Value = "10%",
					Time = 5,
				},{
					Type = 'Speed',
					Value = .25,
					Time = 7,
				}}
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