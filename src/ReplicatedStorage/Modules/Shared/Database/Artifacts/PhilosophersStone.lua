local Types = require('../../Types')

return {
	Name = 'Philosopher\'s Stone',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			["Energy_Regeneration%"] = 25,
			["Attack%"] = 8,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Attack +8%, Energy_Regeneration +25%",
		Four_Piece = [[Using Special or EX Special marks an enemy for 10s, up to 5 enemies at the time. When any of those enemies receive EX / Special, Chain Attack, or Ultimate Damage, caster receives a percent of Energy casted. If any enemy dies during the 10 seconds period, receive 10% Energy.]],
	},

} :: Types.Artifact_Data