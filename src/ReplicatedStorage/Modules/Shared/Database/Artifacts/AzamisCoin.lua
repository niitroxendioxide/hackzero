local Types = require('../../Types')

return {
	Name = 'Azami\'s Coin',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			["Daze%"] = 5,
			["DMG_Electric%"] = 10,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "Electric DMG +10%, Daze +4%",
		Four_Piece = [[Every basic hit accumulates small electric charges, once 20 charges are reached, next attack will trigger "Paralyze", Electric Affliction Buildup +25% for 12s, and stunning the enemy for 2.25s. Effect has a cooldown of 25s.]],
	},

} :: Types.Artifact_Data