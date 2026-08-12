return {

    Health = 120,
    Size = Vector3.new(7.75, 10, 7.75),

    Element_Damage_Multipliers = {
        Fire = 1.25,
		Energy = 0.5,
    },

    Default_Structure_Data = {
		Effects = {
			{
				Type = 'Attack',
				Value = '10%',
				Tag = 'CrystalAttackBuff',
				Time = 20,
				Unique = true,
			}
		},
		Other = {
            Energy = 10
        },
	}
}