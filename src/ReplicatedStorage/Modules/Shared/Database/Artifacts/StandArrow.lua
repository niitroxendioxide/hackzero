local Types = require('../../Types')

return {
	Name = 'Stand Arrow',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Attack = 120,
			Daze = 15,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Crit DMG +16%, Affliction Aptitude +20",
		Four_Piece = "When EX Special hits an enemy, obtain 1 'Resonance' stack, each providing +3 Daze, when 3 are obtained. Next EX Special will deal double the daze, consuming all 3 charges, cooldown of 7s.",
	},

} :: Types.Artifact_Data