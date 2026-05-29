return {
	Display_Name = 'Natsuro Uzaki',
	Nickname = 'Naru-kage',
	Element = 'Wind',
	Role = 'Support',
	Tier = "Legendary",
	Faction = "Team 7",
	
	IconGlowColor = Color3.fromRGB(255, 146, 83),

	Appearance = {
		Height = 2.675
	},

	ImportantStats = {
		'Attack',
		'Energy_Regeneration',
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
		--[[['Passive'] = {
			Description = '',
			Meters = {
				SaiyanSurge = {
					Ascension = 2,
					Description = 'When completing a full basic attack string obtain one charge of Saiyan Surge, when hitting an enemy with an EX-Special, get two charges, up to 3. Hold basic attack with two charges to use Super God Fist',
					Id = 1,
					Max = 4,
				},
			},
		},]]
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