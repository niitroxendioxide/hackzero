local Types = require('../../Types')

return {
	Name = 'Sharingan Eye',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Speed = 0.05,
			Critical_Rate = 15,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "ATK SPD +5%, CRIT RATE +15%",
		Four_Piece = [[When hitting an enemy with a critical hit, gain an "Insight" stack for 7s, can be stacked up to 5 times. 
		For each insight stack, gain CRIT DMG +4% and ATK SPD +2%. When hit, lose 1 insight stack.]],
	},

} :: Types.Artifact_Data