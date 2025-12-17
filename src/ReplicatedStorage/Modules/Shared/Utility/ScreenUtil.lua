local ScreenUtils = {
    BoundConnection = nil
}


--
local StrokeThickness = {}

function SaveStrokeSize(Frame: Frame)
    for _, UIStroke: Instance in Frame:GetDescendants() do
        if not UIStroke:IsA("UIStroke") then
            continue
        end

        if not StrokeThickness[UIStroke] then
            StrokeThickness[UIStroke] = UIStroke.Thickness
        end

        UIStroke.Thickness = ScreenUtils:GetStrokeSize(StrokeThickness[UIStroke])
    end
end

function AdjustStrokeThicknessSavingOriginal()
    for UIStroke: UIStroke, Original in StrokeThickness do
        UIStroke.Thickness = ScreenUtils:GetStrokeSize(Original)
    end
end

--
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


function ScreenUtils:AdjustStrokes(Frame: Frame)
    if true then 
        return;
    end

    local Screen = Frame:FindFirstAncestorOfClass("ScreenGui")

    if not ScreenUtils.BoundConnection and Screen then
        ScreenUtils.BoundConnection = Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(AdjustStrokeThicknessSavingOriginal)
    end

    if Screen then
        SaveStrokeSize(Frame)
    end
end

return ScreenUtils