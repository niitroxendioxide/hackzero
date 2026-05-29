local Types = require('../../Types')

return {
	Name = 'Wristband',
	Tier = 'Epic',
	Icon = 74743421149370,

	Piece_Effects = {
		Two_Piece = {
			Critical_Damage = 9,
			Affliction_Aptitude = 20,
		},

		Four_Piece = {

		},
	},

	Piece_Descriptions = {
		Two_Piece = 'CRIT DMG +16%, Affliction Apt. +20',
		Four_Piece = "Passive Effect: After hitting a critical hit",
	},

} :: Types.Artifact_Data