local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

type BaseInterface = Frame & {
    Leave: Frame & {Btn: TextButton, UIScale: UIScale},
    Background: ImageLabel,
    Title: TextLabel,
}

--
local PageController = {
    Frame = nil :: BaseInterface?,
}

function PageController:Init(Frame: BaseInterface)
    PageController.Frame = Frame

    --
    local Debounce = false
    local Button = Frame.Leave
    Button.Btn.MouseButton1Click:Connect(function()
        if Debounce then return end

        Button.UIScale.Scale = 0.75

        Effects:Tween(Button.UIScale, { 0.25 , 'Back'}, {Scale = 1})

        Debounce = true
        task.delay(0.5, function()
            Debounce = false
        end)

        --
        Network:Fire("Match", GameEnum.MatchEvents.SingularPlayerLeave)
    end)
end

function PageController:Refresh()
    --
end

return PageController;