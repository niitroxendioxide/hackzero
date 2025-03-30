---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)

---
return function(Duration: number)
	local ColorCorrection = Instance.new('ColorCorrectionEffect')
	ColorCorrection.Parent = game:GetService('Lighting')

	Effects:Tween(ColorCorrection, {.1}, {Saturation = -0.75, Contrast = 0.225})

	task.wait(Duration)
	Effects:Tween(ColorCorrection, {.45}, {Saturation = 0, Contrast = 0})
end
