return {
	Display_Name = 'Hatsune Miku',
	Nickname = 'Miku',
	Element = 'Energy',
	Role = 'Support',
	Tier = "Legendary",
	Faction = "VOCALOID",

	Appearance = {
		Height = 3.15
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
			Cooldown = .35
		},

        ['Special'] = {
            Base = {
                Cooldown = 0.2,
                Attack_State_Time = 5e12,
                Speed = 1,
                Animation_Speed = 1,

                Required_Energy = 100,
				CustomVerify = true,

                Buffs = {
                    {
                        Type = "Attack",
                        Time = 30,
                        Value = "30%",
                        Tag = "MikuStrengthBuff",
                    },

                    {
                        Type = "Defense",
                        Time = 30,
                        Value = 120,
                        Tag = "MikuDefenseBuff",
                    }
                },
            },

            ['EX Special'] = {
                Base = {
                    Cooldown = 2,
                    Speed = 1,
                    Animation_Speed = 1,
                    --- (IDK WHAT I?LL DO YET)
                },
            }
        },
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