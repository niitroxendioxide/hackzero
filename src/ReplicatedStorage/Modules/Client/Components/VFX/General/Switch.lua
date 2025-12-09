---
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Characters = require(Client.Libraries.Characters)
local EffectsLib = require(Client.Libraries.Effects)
local AudioLib = require(Client.Libraries.Audio)
local Effects = require(Shared.Utility.Effects)

---
return function()
    local Duration = 0.3
	local Current = Characters:GetCurrent()
	local ColorCorrection = Instance.new('ColorCorrectionEffect')
	local BloomEffect = Instance.new('BloomEffect')
	BloomEffect.Parent = Lighting
	ColorCorrection.Parent = Lighting

	local Goals = {Saturation = -0.25, Contrast = 0.15, Brightness = 0.06}
	for _, OtherCorrections in Lighting:GetChildren() do
		if OtherCorrections:IsA("ColorCorrectionEffect") then
			Goals.Saturation -= OtherCorrections.Saturation
			Goals.Contrast -= OtherCorrections.Contrast
			Goals.Brightness -= OtherCorrections.Brightness
		end
	end

	EffectsLib:Play("Screen_Text", "Switch")

	local CameraObj = workspace.CurrentCamera
	Camera:UseFov(Duration + 0.1)
	CameraObj.FieldOfView = 60

	task.delay(0.1, function()
		Effects:Tween(CameraObj, {Duration, 'Quad'}, {FieldOfView = 70})
	end)

	
	--
	EffectsLib:Play('Glow', Current)
	
	Effects:Tween(ColorCorrection, {.1}, Goals)
	Effects:Tween(BloomEffect, {0.4}, {Intensity = 1.25, Size = 24, Threshold = 1})
	
	task.wait(Duration + 0.1)
	Effects:Tween(BloomEffect, {0.4}, {Intensity = 1, Size = 24, Threshold = 2})
	Effects:Tween(ColorCorrection, {.6}, {Saturation = 0, Contrast = 0, Brightness = 0})

	Effects:CleanUp(BloomEffect, 0.6)
	Effects:CleanUp(ColorCorrection, 0.6)
end
