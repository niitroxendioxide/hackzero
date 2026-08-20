local Types = require('../../Types')

return {
	Name = 'Stone Mask',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			["Health%"] = 15,
			["DMG_Ice%"] = 10,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Health +15%, Ice DMG +10%",
		Four_Piece = "Ice damage is boosted based on Current Health, up to +150%. When any EX Special hits the enemy, recover a fraction of your health.",
	},

} :: Types.Artifact_Data