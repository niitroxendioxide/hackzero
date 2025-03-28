local Types = require('../../Types')

return {
	Name = 'Wristband',
	
	Piece_Effects = {
		Two_Piece = {
			Critical_Damage = 16,
			Speed = -0.075,
		},
		
		Four_Piece = {},
	},
	
	Piece_Descriptions = {
		Four_Piece = "After hitting a critical hit, ",	
	},
	
} :: Types.Artifact_Data