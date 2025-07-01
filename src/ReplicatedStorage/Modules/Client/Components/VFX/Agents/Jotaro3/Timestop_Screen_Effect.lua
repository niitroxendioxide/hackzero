local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage.Modules.Shared
local Effects = require(Shared.Utility.Effects)

local CORRECTION_THREAD: thread? = nil

return function(Time: number, Data: {[string]: any}?)
    if CORRECTION_THREAD then
        task.cancel(CORRECTION_THREAD)
    end

    local ColorCorrection = Lighting:FindFirstChild('TimestopCorrection') or Instance.new('ColorCorrectionEffect')
    ColorCorrection.Name = 'TimestopCorrection'
    ColorCorrection.Parent = Lighting

    Effects:Tween(ColorCorrection, {.45, 'Cubic'}, Data or {
        Saturation = -1.25,
        Contrast = 0,
        Brightness = -0.125,
        TintColor = Color3.fromRGB(254, 251, 219)
    })

    CORRECTION_THREAD = task.delay(Time, function()
        Effects:Tween(ColorCorrection, {.5, 'Sine'}, {Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1)})
        CORRECTION_THREAD = nil
    end)
end
