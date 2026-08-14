local Types = require('../../Types')

return {
	Name = 'Dragon Ball',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Critical_Damage = 16,
			Affliction_Aptitude = 20,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Crit DMG +16%, Affliction Aptitude +20",
		Four_Piece = [[Gain 1 'Dragon Ball' for each critical hit, or 3 for every affliction burst produced. When 7 Dragon Balls are obtained, all are consumed in exchange for a 'Wish', the users blunt damage gets boosted by 15%, and Affliction Aptitude is raised by 50]],
	},

} :: Types.Artifact_Data