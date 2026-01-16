return {
	Display_Name = 'Strongest Dummy',
	Is_Boss = true,
	RemoveFromChaosControl = true,

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 100_000,
		Attack = 120,
		Defense = 72,
		Daze = 662,
		Daze_Length = 2,

		Weakness = {'Energy'},
		Strength = {},

		--
		Daze_Multiplier = 200,
		Daze_Resistance = 71,
		Resistance = 35,

		Movement_Speed = 10,
	},

	Level_Stats = {
		Attack = 8,
		Health = 100_000,
		Defense = 21,
		Daze = 15,
		Daze_Resistance = 0.05,
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
				Damage_Mult = 0.3,
			}
		},

		['Skill 2'] = {
			Base = {
				Cooldown = 1.25,

				Speed = 1,
				Animation_Speed = 1,
				Attack_State_Time = 0.817,

				Agent_Stun_Time = 0.45,
				Damage_Mult = 106,

				Range = 6,
				Attack_Warning = 0.05,
			},

			Upgrades = {
				Damage_Mult = 0.5,
			}
		},
	},
}