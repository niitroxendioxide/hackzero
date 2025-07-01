---
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Characters = require(Client.Libraries.Characters)
local EffectsLib = require(Client.Libraries.Effects)
local Effects = require(Shared.Utility.Effects)

---
return function(Duration: number)
	local Current = Characters:GetCurrent()
	local ColorCorrection = Instance.new('ColorCorrectionEffect')
	local BloomEffect = Instance.new('BloomEffect')
	BloomEffect.Parent = Lighting
	ColorCorrection.Parent = Lighting

	--
	EffectsLib:Play('Glow', Current)

	Effects:Tween(ColorCorrection, {.1}, {Saturation = -0.75, Contrast = 0.355, Brightness = -.075})
	Effects:Tween(BloomEffect, {0.4}, {Intensity = 1.25, Size = 24, Threshold = 1})

	task.wait(Duration + 0.1)
	Effects:Tween(BloomEffect, {0.4}, {Intensity = 1, Size = 24, Threshold = 2})
	Effects:Tween(ColorCorrection, {.6}, {Saturation = 0, Contrast = 0, Brightness = 0})

	Effects:CleanUp(BloomEffect, 0.6)
	Effects:CleanUp(ColorCorrection, 0.6)
end
