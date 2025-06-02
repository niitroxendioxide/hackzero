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
				Range = 14,
				Cooldown = 2,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.66,

				Agent_Stun_Time = 0.3,
				Damage_Mult = 220,
				Attack_Warning = 0.25,
			},

			Upgrades = {}
		},

		['Skill 2'] = {
			Base = {
				Range = 7,
				Cooldown = 2,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.66,

				Agent_Stun_Time = 0.3,
				Damage_Mult = 220,
				Attack_Warning = 0.25,
			},

			Upgrades = {}
		},
	},
}