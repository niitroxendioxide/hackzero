local Types = require('../../Types')

return {
	Name = 'Anti-Magic Grimoire',
	Icon = 0,
	Tier = 'Epic',

	Piece_Effects = {
		Two_Piece = {
			Pen_Ratio = 8,
			["Attack%"] = 4,
		},

		Four_Piece = {
            Pen_Ratio = 2,
        },
	},

	Piece_Descriptions = {
		Two_Piece = "PEN Ratio +8%, ATK +4%",
		Four_Piece = "PEN Ratio +2%. Basic Attacks accumulate 'Rupture' charges, up to a max of 20. Each Rupture charge gives +1% PEN Ratio. If the enemy is shielded, deal an additional 50% damage to their shield.",
	},

} :: Types.Artifact_Data