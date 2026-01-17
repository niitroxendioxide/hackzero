---
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Characters = require(Client.Libraries.Characters)
local EffectsLib = require(Client.Libraries.Effects)
local Effects = require(Shared.Utility.Effects)

---
local ChainCC;

return function()
    local Duration = 2
	local Current = Characters:GetCurrent()
    if ChainCC then
        ChainCC:Destroy()
    end

	ChainCC = Instance.new('ColorCorrectionEffect')
	ChainCC.Parent = Lighting

	local Goals = {Saturation = -0.4, Contrast = 0.15, Brightness = -0.05}
	EffectsLib:Play("Screen_Text", "Chain")

	local CameraObj = workspace.CurrentCamera
	Camera:UseFov(Duration + 0.1)
	CameraObj.FieldOfView = 55

	Effects:Tween(CameraObj, {Duration, 'Back', 'InOut'}, {FieldOfView = 70})

	
	--
	EffectsLib:Play('Glow', Current)
	
	Effects:Tween(ChainCC, {.1}, Goals)
	
	task.wait(Duration + 0.1)
	Effects:Tween(ChainCC, {.6}, {Saturation = 0, Contrast = 0, Brightness = 0})
	Effects:CleanUp(ChainCC, 0.6)
end
