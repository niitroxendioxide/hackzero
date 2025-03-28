return {
	Display_Name = 'Template Character',
	Nickname = 'Template',
	Element = 'Physical',
	Role = 'Attack',

	Appearance = {
		Height = 3.15
	},

	--
	Stats = {
		Health = 100,
		Attack = 70,
		Defense = 10,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 70,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 80,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Attack = 12,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Cooldown = .35
		},
	}
}