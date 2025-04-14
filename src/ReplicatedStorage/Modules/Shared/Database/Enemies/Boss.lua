return {
	Display_Name = 'Boss Enemy',

	Appearance = {
		Height = 4
	},

	--
	Stats = {
		Health = 150,
		Attack = 100,
		Defense = 50,
		Daze = 600,
		Daze_Length = 10,

		Weakness = {'Physical'},
		Strength = {},


		--
		Daze_Multiplier = 150,
		Daze_Resistance = 25,
		Resistance = 15,

		Movement_Speed = 10,
	},

	Level_Stats = {
		Attack = 6.5,
		Health = 1800,
		Defense = 11,
	},

	Moveset_Data = {
		['Skill 1'] = {
			Base = {
				Cooldown = 4,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.66,

				Agent_Stun_Time = 0.3,
				Damage_Mult = 220,
				Attack_Warning = 0.25,
			},

			Upgrades = {
				Damage_Mult = 7.5,
			}
		},
	},
}