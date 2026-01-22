local Types = require('../../Types')

return {
	Name = 'Four Leaf Clover',
	Icon = 0,
	Tier = 'Epic',

	Piece_Effects = {
		Two_Piece = {
			Critical_Rate = 15,
			Attack = "6%",
		},

		Four_Piece = {
            Critical_Rate = 10,
        },
	},

	Piece_Descriptions = {
		Two_Piece = "Crit RATE +15%, ATK +6%",
		Four_Piece = "After hitting a critical hit, ",
	},

} :: Types.Artifact_Data