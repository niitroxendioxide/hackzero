return {

    Health = 1e5,
    Size = Vector3.new(8.5, 14, 8.5),

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