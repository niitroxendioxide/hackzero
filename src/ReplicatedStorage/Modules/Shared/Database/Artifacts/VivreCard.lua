local Types = require('../../Types')

return {
	Name = 'Vivre Card',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Health = "12%",
			Attack = "10%",
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "HP +12%, ATK +10%",
		Four_Piece = [[When Agent hp reaches 50%, this card starts burning, generating a stack of "Will" every 3s, up to 10. Getting hit removes 3 of them. Each stack gives an extra 2% ATK.]],
	},

} :: Types.Artifact_Data