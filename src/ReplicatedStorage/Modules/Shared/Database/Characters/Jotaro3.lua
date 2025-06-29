return {
	Display_Name = 'Jotaro Kujo',
	Nickname = 'Jojo',
	Element = 'Energy',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Karakura Town",

	Appearance = {
		Height = 3.15
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
			Description = 'Every hit from your basic attacks contributes to filling up your stand meter',
			Meters = {
				Stand = {
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

				Walk_Time = 0.07,

				Damage_Mult = {
					[1] = 73,
					[2] = 88,
					[3] = 102,
					[4] = 182,
				},

				Daze_Mult = {
					[1] = 20,
					[2] = 24.5,
					[3] = 31.5,
					[4] = 39.2,
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

				Daze_Mult = {
					[1] = 0.2,
					[2] = 0.3,
					[3] = 0.15,
					[4] = 0.25,
				},
			},
		},

		['Special'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = .5,
				Speed = 1,
				Animation_Speed = 1,

				Required_Energy = 50,

				Damage_Mult = 9,
				Daze_Mult = 9,
				Affliction_Buildup = 9,
			},

			Upgrades = {
			},
		},

		['EX Special'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = 7,
				Speed = 1,
				Animation_Speed = 1,

				Hit_Frequency = 6/60,
				Walk_Time = 1/60,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 3,
				Knockback_Time = 0.1,

				Energy_Per_Hit = 3,
				Required_Energy = 50,
				DontConsumeEnergy = true,
				Release = true,

				Damage_Mult = 44,
				Daze_Mult = 61,
				Affliction_Buildup = 31,
			},

			Upgrades = {
				Damage_Mult = 1,
				Daze_Mult = 1.5,
				Affliction_Buildup = 0.75,
			},
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