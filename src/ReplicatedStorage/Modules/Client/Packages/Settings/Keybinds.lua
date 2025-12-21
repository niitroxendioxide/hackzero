return {
	Controller = {
		Move_Front = Enum.KeyCode.W,
		Move_Back = Enum.KeyCode.A,
		Move_Left = Enum.KeyCode.S,
		Move_Right = Enum.KeyCode.D,

		Jog = Enum.KeyCode.Unknown,
		Sprint = Enum.KeyCode.ButtonL3,

		OpenMenu = Enum.KeyCode.ButtonSelect,
		TESTING = Enum.KeyCode.K,

		--[[ COMBAT ]]--
		Basic_Attack = Enum.KeyCode.ButtonX,
		Special = Enum.KeyCode.ButtonY,
		Dodge = Enum.KeyCode.ButtonA,
		Swap_Forth = Enum.KeyCode.ButtonR1,
		Swap_Back = Enum.KeyCode.ButtonL1,
		Ultimate = Enum.KeyCode.ButtonR2,
	},
	Computer = {

		--[[ DEFAULT ]]--
		Move_Front = Enum.KeyCode.W,
		Move_Back = Enum.KeyCode.S,
		Move_Left = Enum.KeyCode.A,
		Move_Right = Enum.KeyCode.D,

		Jog = Enum.KeyCode.LeftControl,
		Sprint = Enum.KeyCode.LeftShift,

		TESTING = Enum.KeyCode.K,
		OpenMenu = Enum.KeyCode.M,

		--[[ COMBAT ]]--
		Basic_Attack = Enum.UserInputType.MouseButton1,
		Special = Enum.KeyCode.E,
		Dodge = {Enum.KeyCode.LeftAlt, Enum.UserInputType.MouseButton2},
		Swap_Forth = Enum.KeyCode.Space,
		Swap_Back = Enum.KeyCode.C,
		Ultimate = Enum.KeyCode.Q,
	}
}