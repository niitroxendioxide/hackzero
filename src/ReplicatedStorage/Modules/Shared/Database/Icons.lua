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

	
	RankingColorInfo = {
		["X"] = {Color3.fromRGB(30, 188, 255), Color3.fromRGB(21, 115, 255)},
		["B"] = {Color3.fromRGB(30, 188, 255), Color3.fromRGB(21, 115, 255)},
		["A"] = {Color3.fromRGB(156, 117, 255), Color3.fromRGB(35, 46, 255)},
		["S"] = {Color3.fromRGB(255, 209, 43), Color3.fromRGB(255, 74, 74)},
	},

	StatusEffects = {
		DEFAULT = 72824425525185,
		
		Tags = {
			GOKU_MODE_BUFF = 92866058949877,
			SS2 = 110082389480306,
		},

		Values = {
			Speed = 98497771635964,
			Attack = 85258130749383,
			Defense = 139849133488257,
			Health = 139849133488257,
		}
	},

	Buttons = {
		['Map'] = 88079458754712,
		['Shop'] = 139099004250521,
		['Quests'] = 82127527330126,
		['Agents'] = 126819722091537,
		['Settings'] = 134273057855463,
		['Inventory'] = 93968693751727,
		['Companions'] = 75933963205055,
	},

	Keybinds = {
		[Enum.KeyCode.ButtonB] = 119504278354393,
		[Enum.KeyCode.ButtonY] = 112125644503859,
		[Enum.KeyCode.ButtonX] = 86251548517872,
		[Enum.KeyCode.ButtonA] = 121581338630377,
		[Enum.UserInputType.MouseButton1] = 131889465930150,
		[Enum.UserInputType.MouseButton2] = 126051687805709,

	},

	Rarities = {
		['Common'] = {
			Id = PREFIX .. 126340402420755,

			TextColorSequence = Sequence { Key(0, RGB(152, 152, 152)), Key(1, White) }
		},
		['Epic'] = {
			Id = PREFIX .. 140502637235592,

			TextColorSequence = Sequence { Key(0, RGB(212, 0, 255)), Key(1, RGB(223, 147, 255)) }
		},
		['Legendary'] = {
			Id = PREFIX .. 101596220681824,

			TextColorSequence = Sequence { Key(0, RGB(255, 111, 39)), Key(1, White) }
		},
		['Mythical'] = {
			Id = PREFIX .. 103396654374573,

			OutlineColor = RGB(103, 0, 132),
			TextColorSequence = Sequence { Key(0, White), Key(0.244, RGB(13, 167, 255)), Key(0.574, RGB(130, 57, 255)), Key(1, RGB(212, 0, 255)) }
		},
	},

	Skills = {
		Ultimates = {
			['Goku'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(255, 162, 23),
			},

			['Jotaro3'] = {
				Id = 139304669014108,
				Color = Color3.fromRGB(79, 50, 227),
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
		['Special'] = 122820271635943,
		['Dodge'] = 90333531186937,
		['Quick_Assist'] = 98536901483249,
		['Dodge_Counter'] = 72165520047011,
	},

	Roles = {
		Affliction = PREFIX .. 131830988316888,
		Attack = PREFIX .. 91651511781661, --10626165
		Stun = PREFIX .. 130565420004864,
		Support = PREFIX .. 98271985547867,
	},

	Elements = {
		Ice = PREFIX .. 108516110153642,
		Fire = PREFIX .. 71851600908599,
		Physical = PREFIX .. 135264772222943,
		Water = PREFIX .. 89916641703745,
		Electric = PREFIX .. 114411657809403,
		Energy = PREFIX .. 131830988316888,
		Earth = PREFIX .. 108297083537522,
		Wind = PREFIX .. 88351380181917,


		Colors = {
			Ice = {
				Main = RGB(66, 164, 255),
				Meter = RGB(107, 243, 255),
				Gradient = Sequence{Key(0, White), Key(0.5, White), Key(1, RGB(0, 5, 98))}
			},

			Water = {
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
				Main = RGB(255, 157, 0), -- the icon
				Meter = RGB(255, 81, 0), -- the circle
				Gradient = Sequence{Key(0, White), Key(1, RGB(255, 72, 0))}, -- icon gradient
			},

			Energy = {
				Main = White,
				Meter = RGB(52, 157, 255),
				Gradient = Sequence{Key(0, RGB(0, 242, 255)), Key(1, RGB(255, 0, 230))},
			}
		},
	}
}