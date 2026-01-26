return {

    Health = 120,
    Size = Vector3.new(10, 11, 10),

    Element_Damage_Multipliers = {
        Fire = 1.25,
    },

    Default_Structure_Data = {
		Effects = {
			{
				Type = 'Attack',
				Value = '20%',
				Tag = 'CrystalAttackBuff',
				Time = 10,
				Unique = true,
			}
		},
		Other = {
            Energy = 10
        },
	}
}