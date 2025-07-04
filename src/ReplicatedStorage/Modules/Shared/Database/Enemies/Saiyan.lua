return {
	Display_Name = 'Evil Saiyan',

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 500,
		Attack = 120,
		Defense = 72,
		Daze = 662,
		Daze_Length = 2,

		Weakness = {'Energy'},
		Strength = {'Physical'},

		--
		Daze_Multiplier = 200,
		Daze_Resistance = 71,
		Resistance = 35,

		Movement_Speed = 10,
	},

	Level_Stats = {
		Attack = 49,
		Health = 1720,
		Defense = 16,
		Daze = 7.5,
		Daze_Resistance = 0.15,
	},

	Moveset_Data = {
		['Skill 1'] = {
			Base = {
				Cooldown = 5,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.66,

				Agent_Stun_Time = 0.3,
				Damage_Mult = 45,

				Range = 60,
				Attack_Warning = 0.1,
			},

			Upgrades = {
				Damage_Mult = 8,
			}
		},

		['Skill 2'] = {
			Base = {
				Cooldown = 1.25,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.817,

				Agent_Stun_Time = 0.45,
				Damage_Mult = 102,

				Range = 6,
				Attack_Warning = 0.05,
			},

			Upgrades = {
				Damage_Mult = 7.5,
			}
		},
	},
}