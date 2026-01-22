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
    local LabelObj = TransitionFrame:FindFirstChild("Label") :: (TextLabel & {UIStroke: UIStroke})

    LabelObj.Text = Label

    --
    BackgroundFrame.BackgroundTransparency = 1
    BackgroundFrame.Top.Transparency = 1
    BackgroundFrame.Bot.Transparency = 1
    LabelObj.TextTransparency = 1
    LabelObj.UIStroke.Transparency = 1
    TransitionFrame.Icon.ImageTransparency = 1

    --
    EffectsUtil:Tween(BackgroundFrame, {.125}, {BackgroundTransparency = 0})
    EffectsUtil:Tween(LabelObj, {.2}, {TextTransparency = 0})
    EffectsUtil:Tween(LabelObj.UIStroke, {.2}, {Transparency = 0})
    EffectsUtil:Tween(BackgroundFrame.Bot, {.2}, {ImageTransparency = 0.85})
    EffectsUtil:Tween(BackgroundFrame.Top, {.2}, {ImageTransparency = 0.85})
    EffectsUtil:Tween(TransitionFrame.Icon, {.2}, {ImageTransparency = 0})
    task.delay(Time, function()
        EffectsUtil:Tween(BackgroundFrame, {.125}, {BackgroundTransparency = 1})
        EffectsUtil:Tween(LabelObj, {.2}, {TextTransparency = 1})
        EffectsUtil:Tween(LabelObj.UIStroke, {.2}, {Transparency = 1})
        EffectsUtil:Tween(BackgroundFrame.Bot, {.2}, {ImageTransparency = 1})
        EffectsUtil:Tween(BackgroundFrame.Top, {.2}, {ImageTransparency = 1})
        EffectsUtil:Tween(TransitionFrame.Icon, {.2}, {ImageTransparency = 1})

        task.wait(Time / 2)
        TransitionFrame.Visible = false
    end)

    task.wait(.25)
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

                ReturnHolder.UIStroke.Thickness = 0.12 - math.cos(math.rad(Angle)) * 0.02
            end
        end)

        ReturnHolder.UIStroke.Color = Color3.new(1,1,1)
        EffectsUtil:Tween(ReturnHolder.UIScale, {.2}, {Scale = 1.1})
    end)

    Btn.MouseLeave:Connect(function()
        if Thread then
            task.cancel(Thread)
        end

        ReturnHolder.UIStroke.Thickness = 0.07
        ReturnHolder.UIStroke.Color = Color3.new()
        EffectsUtil:Tween(ReturnHolder.UIScale, {.25, 'Cubic'}, {Scale = 1})
    end)

end

return Util