local Types = require('../../Types')

return {
	Name = 'Sharingan',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Speed = 0.05,
			Critical_Rate = 7.5,
		},

		Four_Piece = {
            Attack = 240,
			Critical_Rate = 15,
        },
	},

	Piece_Descriptions = {
		Two_Piece = "ATK SPD +5%, CRIT RATE +5%",
		Four_Piece = [[ATK +240, CRIT RATE +15%. Passive Effect: When hitting an enemy with a critical hit, gain an "Insight" stack for 7s, can be stacked up to 5 times. 
		For each insight stack, gain CRIT DMG +3% and ATK SPD +2%. When hit, lose 1 insight stack.]],
	},

} :: Types.Artifact_Data