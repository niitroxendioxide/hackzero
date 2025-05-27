return {
	Display_Name = 'Training Dummy',

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 5000000,
		Attack = 0,
		Defense = 50,
		Daze = 662,
		Daze_Length = 10,

		Weakness = {'Energy'},
		Strength = {'Physical'},


		--
		Daze_Multiplier = 200,
		Daze_Resistance = 27,
		Resistance = 25,

		Movement_Speed = 10,
	},

	Level_Stats = {
		Attack = 0,
		Health = 5000,
		Defense = 25,
	},

	Moveset_Data = {
		['Skill 1'] = {
			Base = {
				Cooldown = 4000,
			},

			Upgrades = {}
		},
	},
}