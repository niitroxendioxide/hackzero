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
		Attack = 49,
		Health = 1720,
		Defense = 16,
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