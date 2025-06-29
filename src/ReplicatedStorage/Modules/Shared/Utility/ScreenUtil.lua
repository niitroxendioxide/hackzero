local ScreenUtils = {}

function ScreenUtils:GetTextSize(Native: number)
    local NativeRate = 1080 / Native

    local CurrentScreenResolution = workspace.CurrentCamera.ViewportSize.Y

    local Converted = CurrentScreenResolution / NativeRate

    return Converted
end

function ScreenUtils:GetStrokeSize(Native: number)
    local NativeRate = 1080 / Native
    local CurrentScreenResolution = workspace.CurrentCamera.ViewportSize.Y
    local Converted = CurrentScreenResolution / NativeRate

    return Converted
end

return ScreenUtils