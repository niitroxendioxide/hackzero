local Types = require('../../Types')

return {
	Name = 'CC Capsule',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Defense = 120,
			Health = 200,
		},

		Four_Piece = {
            Health = 800,
			Defense = 25,
        },
	},

	Piece_Descriptions = {
		Two_Piece = "DEF +120, HP +200",
		Four_Piece = [[DEF +25, HP +800. Passive Effect: Regen some of your health passively throughout fights. 
        Every time you hit a dodge counter, regen 5% extra energy, and apply a 10% Speed boost to all the team for 5s]],
	},

} :: Types.Artifact_Data