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
		Four_Piece = [[DEF +25, HP +800. Hitting a target with Dodge Counter will produce 1 'CC Capsule', up to a limit of 8. Each 'CC Capsule' will provide a defense boost, upon casting any Quick Assist, deal extra damage based on Capsules Stacked, and obtain temporary health regen, effect does not stack.]],
	},

} :: Types.Artifact_Data