local Types = require('../../Types')

return {
	Name = 'Four Leaf Grimoire',
	Icon = 0,
	Tier = 'Epic',

	Piece_Effects = {
		Two_Piece = {
			Affliction_Aptitude = 30,
		},

		Four_Piece = {
			Affliction_Aptitude = 5,
		},
	},

	Piece_Descriptions = {
		Two_Piece = "Affliction Aptitude +30",
		Four_Piece = "When character swaps into battle, affliction facility is increased by 30% for 15s. If affliction burst is triggered during this period, deal an extra 15% Affliction Damage for 17s, effect does not stack.",
	},

} :: Types.Artifact_Data