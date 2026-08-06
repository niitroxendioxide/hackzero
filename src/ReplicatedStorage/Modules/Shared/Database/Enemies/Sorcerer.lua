return {
	Display_Name = 'Hishaku Ally Sorcerer',

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 1123,
		Attack = 55,
		Defense = 36,
		Daze = 600,
		Daze_Length = 2,

		Weakness = {'Water'},
		Strength = {'Energy'},

		--
		Daze_Multiplier = 200,
		Daze_Resistance = 71,
		Resistance = 35,

		Movement_Speed = 8,
	},

	Level_Stats = {
		Attack = 8,
		Health = 863,
		Defense = 4.5,
		Daze = 5.8,
	},

	Moveset_Data = {
		['Skill 1'] = {
			Base = {
				Cooldown = 3,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.66,

				Agent_Stun_Time = 0.3,
				Damage_Mult = 120,

				Range = 0,
				Attack_Warning = 0.8,
			},

			Upgrades = {
				Damage_Mult = 2,
			}
		},

		['Skill 2'] = {
			Base = {
				Cooldown = 2.5,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.6,

				Hit = {
					Stun = 0.3,
					Damage = 60,
				},

				Range = 110,
				Attack_Warning = 0.4,
			},

			Upgrades = {
				Hit = {
					Damage = 3
				},
			}
		},
	},
}