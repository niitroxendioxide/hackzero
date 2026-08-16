local Types = require('../../Types')

return {
	Name = 'Hanafuda Earrings',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			['Affliction_Damage%'] = 15,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Affliction Damage +15%",
		Four_Piece = [[Succesfully triggering a Dodge Counter gives a charge of 'Concentration', each of these increase Affliction Damage +7.5% up to 4, each lasting for 15s.]],
	},

} :: Types.Artifact_Data