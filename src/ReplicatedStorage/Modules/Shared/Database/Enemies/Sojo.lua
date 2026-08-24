return {
	Display_Name = 'Genichi Sojo',
	Is_Boss = true,

	Appearance = {
		Height = 3
	},

	--
	Stats = {
		Health = 48_281,
		Attack = 120,
		Defense = 30,
		Daze = 8315,
		Daze_Length = 15,

		Weakness = {'Physical'},
		Strength = {'Water', 'Electric'},

		--
		Daze_Multiplier = 150,
		Daze_Resistance = 71,
		Resistance = 35,

		Movement_Speed = 13,
	},

	Level_Stats = {
		Health = 36597,
		Daze = 79.5,
		Attack = 17.3,
		Defense = 6.36,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = 0.01,
				Range = 15,
				Speed = 1,
				Animation_Speed = 1,

				Hitbox_Size = vector.create(5, 5, 6),
				Hitbox_Offset = vector.create(0, 0, -3.5),
				Attack_State_Time = 0.65,
				Attack_Warning = 0.01,

				Hit = {
					Damage = 24,
					Stun = 0.25,
				},
			},
		},

		['Mei Cloak'] = {
			Base = {
				Cooldown = 1,
				Speed = 1,
				Animation_Speed = 1,
				Range = math.huge,

				Cloak_Time = 15,
				Attack_State_Time = 0.5,
			},
		}
	},
}