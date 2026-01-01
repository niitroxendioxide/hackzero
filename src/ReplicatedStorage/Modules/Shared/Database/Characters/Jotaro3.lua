return {
	Display_Name = 'Jotaro Kujo',
	Nickname = 'Jojo',
	Element = 'Physical',
	Role = 'Stun',
	Tier = "Legendary",
	Faction = "Stardust Crusaders",

	Appearance = {
		Height = 3.15
	},

	ImportantStats = {
		'Attack',
		'Daze',
	},

	--
	Stats = {
		Health = 677,
		Attack = 109,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 119,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 90,
		Affliction_Facility = 91,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Health = 126,
        Attack = 10.2,
		Defense = 9.4,
	},

	Moveset_Data = {
		['Passive'] = {
			Meters = {
				Stand = {
					Description = 'Every hit from your basic attacks contributes to filling up your stand meter',
					Id = 1,
					Max = 100,
					EmptySpeed = 2.5,
				}
			},
		},

		['Basic Attack'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = 0.45,
				Animation_Speed = 1.35,
				Speed = 1.35,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 10,
				Knockback_Time = 0.1,

				Walk_Time = 0.1575,

				Damage_Mult = {
					[1] = 73,
					[2] = 88,
					[3] = 102,
					[4] = 182,
				},

				Daze_Mult = {
					[1] = 45.3,
					[2] = 63.9,
					[3] = 81.7,
					[4] = 102.5,
				},

				Affliction_Buildup = {
					[1] = 95,
					[2] = 99,
					[3] = 103,
					[4] = 145,
				}
			},

			Upgrades = {
				Damage_Mult = {
					[1] = 3.3,
					[2] = 5.7,
					[3] = 7.6,
					[4] = 8,
					[5] = 9,
					[6] = 26,
				},

				
			},
		},

		['Special'] = {
			Base = {
				Cooldown = 1.5,
				Speed = 1,
				Animation_Speed = 1,

				Required_Energy = 25,

				Attack_State_Time = .5,
				S_OFF_Damage_Mult = 9,
				S_OFF_Daze_Mult = 9,
				S_OFF_Affliction_Buildup = 9,

				S_ON_Attack_State_Time = .5,
				S_ON_Damage_Mult = 9,
				S_ON_Daze_Mult = 9,
				S_ON_Affliction_Buildup = 9,
			},

			Upgrades = {

			},
		},

		['Quick Assist'] = {
			Base = {
				Attack_State_Time = 0.55,
				Speed = 1,
				Animation_Speed = 1,

				Skill_Freeze_Time = 0.4,

				Daze_Mult = 127,
				Damage_Mult = 91,
				Affliction_Buildup = 27
			},

			Upgrades = {

			}
		},

		['EX Special'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = 7,
				Speed = 1,
				Animation_Speed = 1,

				Hit_Frequency = 10/60,
				Effect_Frequency = 6/60,
				Walk_Time = 3/60,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 8,
				Knockback_Time = 0.1,

				Energy_Per_Hit = 3,
				Required_Energy = 25,
				DontConsumeEnergy = true,
				Release = true,

				Damage_Mult = 106,
				Daze_Mult = 45,
				Affliction_Buildup = 40,
			},

			Upgrades = {
				Damage_Mult = 4,
				Daze_Mult = 4,
				Affliction_Buildup = 1.25,
			},
		},

		['Ultimate'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = 0.3,
				Speed = 1,
				Animation_Speed = 1,

				Duration = 4,
				Range = 80,
			},

			Upgrades = {
				Duration = 0.15,
				Range = 2,
			}
		}
	},

	Ascension_Data = {
		[1] = {
			Description = 'Jotaro ascension 1',
		},

		[2] = {
			Description = 'Jotaro ascension 2',
		},

		[3] = {
			Description = 'Jotaro ascension 3',
		},

		[4] = {
			Description = 'Jotaro ascension 4',
		},

		[5] = {
			Description = 'Jotaro ascension 5',
		},

		[6] = {
			Description = 'Jotaro ascension 6',
		},
	}
}