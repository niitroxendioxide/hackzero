local Types = require('../../Types')

return {
	Name = 'Stone Mask',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			["Health%"] = 15,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Health +15%",
		Four_Piece = "Ice damage is boosted based on Maximum Health, up to 150%. When agent enters the battlefield, lose health gradually until 5%, damaging enemies restores a percent of lost hp.",
	},

} :: Types.Artifact_Data