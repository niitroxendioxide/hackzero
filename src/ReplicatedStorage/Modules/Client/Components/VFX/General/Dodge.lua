---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Duration: number)
	local ColorCorrection = Instance.new('ColorCorrectionEffect')
	ColorCorrection.Parent = game.Lighting
	
	Effects:Tween(ColorCorrection, {.1}, {Saturation = -0.5, Contrast = 0.15})
	
	task.wait(Duration)
	Effects:Tween(ColorCorrection, {.45}, {Saturation = 0, Contrast = 0})
end
