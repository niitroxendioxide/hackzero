return {
	Controller = {},
	Computer = {

		--[[ DEFAULT ]]--
		Move_Front = Enum.KeyCode.W,
		Move_Back = Enum.KeyCode.S,
		Move_Left = Enum.KeyCode.A,
		Move_Right = Enum.KeyCode.D,

		Jog = Enum.KeyCode.LeftControl,
		Sprint = Enum.KeyCode.LeftShift,

		TESTING = Enum.KeyCode.K,

		--[[ COMBAT ]]--
		Basic_Attack = Enum.UserInputType.MouseButton1,
		Special = Enum.KeyCode.E,
		Dodge = {Enum.KeyCode.LeftAlt, Enum.UserInputType.MouseButton2},
		Swap_Forth = Enum.KeyCode.Space,
		Swap_Back = Enum.KeyCode.C,
		Ultimate = Enum.KeyCode.Q,
	}
	
}