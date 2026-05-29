return {
	Display_Name = 'Template Character',
	Nickname = 'Template',
	Element = 'Physical',
	Role = 'Attack',
	Tier = "Legendary",
	Faction = "Testing",
	NotOnBanner = true,

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 100,
		Attack = 70,
		Defense = 10,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 70,
		Speed = 1,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 80,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Attack = 12,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = .35,
				Attack_State_Time = 0.35,
				Speed = 1,
				Animation_Speed = 1,
				Hit = {
					Damage = 50,
					HitType = 'Blunt',
					Stun = 0.4,
					Daze = 30,
					Affliction = "None",
				},
			},

			Upgrades = {
				Hit = {
					Damage = 1,
				}
			},
		},

		['Dodge'] = {
			Base = {
				Cooldown = 1,
				Speed = 1,
				Animation_Speed = 1,
			},

			Upgrades = {},
		},
	},

	Ascension_Data = {
		[1] = {
			Description = 'Template',
		},

		[2] = {
			Description = 'Template',
		},

		[3] = {
			Description = 'Template',
		},

		[4] = {
			Description = 'Template',
		},

		[5] = {
			Description = 'Template',
		},
	}
}