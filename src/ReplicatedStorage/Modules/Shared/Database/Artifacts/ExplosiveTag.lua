local Types = require('../../Types')

return {
	Name = 'Explosive Tag',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			["Daze%"] = 15,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Daze +15%",
		Four_Piece = [[Whenever any squad member activates a defensive/evasive assist, place an explosive tag on the target, exploding and filling up unconditional 5% Daze, and increasing attacker's Daze by 2% up to 3 times. Cooldown of 7s for the explosive tag]],
	},

} :: Types.Artifact_Data