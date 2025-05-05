return {
	Display_Name = 'Kakarot',
	Nickname = 'Son Goku',
	Element = 'Physical',
	Role = 'Affliction',
	Rarity = "Legendary",
	Faction = "Z Warriors",

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 626,
		Attack = 127,
		Defense = 49,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 240,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 120,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Health = 121.38,
		Attack = 6.33,
		Defense = 9.44,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Cooldown = .05,
				Speed = 1.35,

				Attack_State_Time = {
					.25,
					.25,
					.25,
					.25,
					1,
				},
				Animation_Speed = 1.35,

				Walk_Time = 0.133,
				Forward_Impulse = 10,

				Knockback_Direction = Vector3.new(0, 0, 1),
				Knockback_Strength = 10,
				Knockback_Time = 0.2,

				Damage_Mult = {
					[1] = 36,	
					[2] = 62,
					[3] = 83,
					[4] = 163,
					[5] = 98,
					[6] = 291,
				},
				
				Daze_Mult = {
					[1] = 17,	
					[2] = 22.5,
					[3] = 25,
					[4] = 32,
					[5] = 22,
					[6] = 27,
				},
				
				Affliction_Buildup = {
					[1] = 89,
					[2] = 102,
					[3] = 125,
					[4] = 155,
					[5] = 192,
					[6] = 202,
				}
			},
			
			--
			Upgrades = {
				Damage_Mult = {
					[1] = 3.3,	
					[2] = 5.7,
					[3] = 7.6,
					[4] = 8,
					[5] = 9,
					[6] = 26,
				},
			}
		},
		
		['EX Special'] = {
			Base = {
				Cooldown = 1,
				Speed = 1,
				
				Required_Energy = 60,

				Attack_State_Time = 0.5,
				Animation_Speed = 1,
			},
			
		},
	}
}