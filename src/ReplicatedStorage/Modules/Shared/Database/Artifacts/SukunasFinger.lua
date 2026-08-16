local Types = require('../../Types')

return {
	Name = 'Cursed Sealed Finger',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Affliction_Aptitude = 30,
			Critical_Rate = 6,
		},

		Four_Piece = {},
	},

	Piece_Descriptions = {
		Two_Piece = "CRIT Rate +6%, Affliction Aptitude +30",
		Four_Piece = [[Every critical hit adds a 'Cursed Energy' stack, once you reach 5, next critical hit will trigger a 'Black Flash', dealing big anomaly damage in burst. Has a cooldown of 7s]],
	},

} :: Types.Artifact_Data