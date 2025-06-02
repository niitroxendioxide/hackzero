local Types = require('../../Types')

return {
	Name = 'Four Leaf Clover',

	Piece_Effects = {
		Two_Piece = {
			Critical_Rate = 15,
			Affliction_Aptitude = 20,
		},

		Four_Piece = {
            Critical_Rate = 10,
        },
	},

	Piece_Descriptions = {
		Four_Piece = "After hitting a critical hit, ",
	},

} :: Types.Artifact_Data