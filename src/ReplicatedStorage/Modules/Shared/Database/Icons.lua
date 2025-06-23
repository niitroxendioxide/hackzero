local PREFIX = 'rbxassetid://'
local Sequence = ColorSequence.new
local Key = ColorSequenceKeypoint.new
local White = Color3.new(1, 1, 1)
local RGB = Color3.fromRGB

return {
	PREFIX = PREFIX,

	Currency = {
		['Money'] = 105549712478275,
		['Gems'] = 94639843447517,
	},

	Buttons = {
		['Inventory'] = 93968693751727,
		['Agents'] = 126819722091537,
		['Settings'] = 134273057855463,
		['Map'] = 88079458754712,
		['Shop'] = 139099004250521,
		['Quests'] = 82127527330126,
	},

	Skills = {
		Ultimates = {
			['Goku'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(255, 162, 23),
			},

			['Vegeta'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(108, 59, 255),
			},

			['Trunks'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(255, 70, 42),
			},

			['Piccolo'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(140, 254, 91),
			},
		},

		['Basic_Attack'] = 84976350806139,
		['Swap_Forth'] = 76619175136377,
		['Dodge'] = 90333531186937,
	},

	Roles = {
		Affliction = PREFIX .. 131830988316888,
		Attack = PREFIX .. 91651511781661,
		Stun = PREFIX .. 130565420004864,
		Support = PREFIX .. 98271985547867,
	},

	Elements = {
		Ice = PREFIX .. 108516110153642,
		Fire = PREFIX .. 116710794714652,
		Physical = PREFIX .. 127260334479901,
		Electric = PREFIX .. 83449523980359,
		Energy = PREFIX .. 108516110153642,
		Earth = PREFIX .. 108516110153642,
		Wind = PREFIX .. 108516110153642,


		Colors = {
			Ice = {
				Main = RGB(66, 164, 255),
				Meter = RGB(107, 243, 255),
				Gradient = Sequence{Key(0, White), Key(0.5, White), Key(1, RGB(0, 5, 98))}
			},

			Physical = {
				Main = RGB(255, 220, 79),
				Meter = RGB(255, 205, 124),
				Gradient = Sequence{Key(0, White), Key(0.5, White), Key(1, RGB(98, 52, 0))}
			},

			Electric = {
				Main = White,
				Meter = RGB(53, 130, 255),
				Gradient = Sequence{Key(0, RGB(0, 34, 255)), Key(0.337, RGB(24, 93, 255)), Key(0.628, RGB(5, 183, 255)), Key(1, White)}
			},

			Fire = {
				Main = RGB(255, 157, 0),
				Meter = RGB(255, 81, 0),
				Gradient = Sequence{Key(0, White), Key(1, RGB(255, 72, 0))},
			},
		},
	}
}