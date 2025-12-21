local Types = require('../../Types')

return {
	Name = 'Dragon Ball',
	Tier = 'Epic',
	Icon = 0,

	Piece_Effects = {
		Two_Piece = {
			Critical_Damage = 16,
			Affliction_Aptitude = 20,
		},

		Four_Piece = {
            Critical_Damage = 14,
			Affliction_Aptitude = 15,
        },
	},

	Piece_Descriptions = {
		Four_Piece = [[After hitting a critical hit, recharge 5% of energy and replenish some of your hp. 
        Hitting three critical hits in less than 5s will result in a damage boost of 10% to any blunt damage.]],
	},

} :: Types.Artifact_Data