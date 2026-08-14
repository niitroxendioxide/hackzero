local Types = require('../../Types')

return {
	Name = 'Zero\'s Helmet',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Energy_Regeneration = "25%",
		},

		Four_Piece = {
			
		},
	},

	Piece_Descriptions = {
		Two_Piece = "Energy Regen +25%",
		Four_Piece = [[When any squad member's EX Skill hits an enemy, trigger 'Mark'. For 15s, damage dealt towards that enemy recharges every squad member's energy by x2 the default amount. Cooldown of 15s post-use.]],
	},

} :: Types.Artifact_Data