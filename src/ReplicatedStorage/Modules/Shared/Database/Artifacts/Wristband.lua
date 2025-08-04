local Types = require('../../Types')

return {
	Name = 'Wristband',
	Tier = 'Epic',
	Icon = 74743421149370,

	Piece_Effects = {
		Two_Piece = {
			Critical_Damage = 16,
			Affliction_Aptitude = 20,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Four_Piece = "After hitting a critical hit, ",
	},

} :: Types.Artifact_Data