local PREFIX = 'rbxassetid://'
local Sequence = ColorSequence.new
local Key = ColorSequenceKeypoint.new
local White = Color3.new(1, 1, 1)
local RGB = Color3.fromRGB

return {
	Currency = {
		['Money'] = 105549712478275,
		['Gems'] = 94639843447517,
	},

	Buttons = {
		['Inventory'] = 93968693751727,
    	['Agents'] = 126819722091537,
    	['Settings'] = 134273057855463,
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