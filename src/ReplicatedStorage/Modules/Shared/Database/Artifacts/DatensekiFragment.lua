local Types = require('../../Types')

return {
	Name = 'Datenseki Fragment',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			DMG_Physical = "10%",
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Physical DMG +10%",
		Four_Piece = [[Every basic attack hit in a chain, without being interrupted, will do an extra 4% DMG, stacking up to 40%. Lose all charges upon any hit.]],
	},

} :: Types.Artifact_Data