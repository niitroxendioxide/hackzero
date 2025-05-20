--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local LocalPlayer = Players.LocalPlayer

local EffectsUtil = require(Shared.Utility.Effects)

--

local Util = {}

function Util:Transition(Label: string, Time: number)
    local EffectsHUD = LocalPlayer.PlayerGui:FindFirstChild("EffectsHUD")
    if not EffectsHUD then
        return
    end

    local TransitionFrame = EffectsHUD:FindFirstChild("TransitionFrame") :: Frame
    if not TransitionFrame then
        return
    end

    TransitionFrame.Visible = true

    local BackgroundFrame = TransitionFrame:FindFirstChild("Frame") :: Frame
    local LabelObj = TransitionFrame:FindFirstChild("Label") :: TextLabel
    local OtherLabel = TransitionFrame:FindFirstChild("LabelName") :: TextLabel

    LabelObj.Text = Label

    --
    BackgroundFrame.Position = UDim2.fromScale(-1, 0)

    LabelObj.Position = UDim2.fromScale(-0.85, 0.906)
    OtherLabel.Position = UDim2.fromScale(-0.85, 0.869)
    EffectsUtil:Tween(LabelObj, {.3, 'Quad'}, {Position = UDim2.fromScale(.021, 0.906)})
    EffectsUtil:Tween(OtherLabel, {.15, 'Quad'}, {Position = UDim2.fromScale(.021, 0.869)})

    --
    EffectsUtil:Tween(BackgroundFrame, {.125}, {Position = UDim2.fromScale(0, 0)})
    task.delay(Time, function()
        EffectsUtil:Tween(BackgroundFrame, {.4}, {Position = UDim2.fromScale(1, 0)})
        EffectsUtil:Tween(LabelObj, {.225, 'Quad', 'In'}, {Position = UDim2.fromScale(1, 0.906)})
        EffectsUtil:Tween(OtherLabel, {.25}, {Position = UDim2.fromScale(1, 0.869)})

        task.wait(Time / 2)
        TransitionFrame.Visible = false
    end)

    task.wait(.225)
end

function Util:AnimateReturnButton(Button: Frame, Callback: (...any) -> ()): ()
    local ReturnHolder = Button :: Frame & {Btn: TextButton, UIStroke: UIStroke, UIScale: UIScale}
    local Btn = ReturnHolder.Btn
    local Thread: thread = nil
    Btn.MouseButton1Click:Connect(Callback)


    Btn.MouseEnter:Connect(function()
        if Thread then
            task.cancel(Thread)
        end

        Thread = task.spawn(function()
            local Angle = 0

            while true do
                local Delta = task.wait()

                Angle += Delta * 360

                ReturnHolder.UIStroke.Thickness = 2 + math.sin(math.rad(Angle))
            end
        end)

        ReturnHolder.UIStroke.Color = Color3.new(1,1,1)
        EffectsUtil:Tween(ReturnHolder.UIScale, {.2}, {Scale = 1.1})
    end)

    Btn.MouseLeave:Connect(function()
        if Thread then
            task.cancel(Thread)
        end

        ReturnHolder.UIStroke.Thickness = 1
        ReturnHolder.UIStroke.Color = Color3.new()
        EffectsUtil:Tween(ReturnHolder.UIScale, {.25, 'Cubic'}, {Scale = 1})
    end)

end

return Util