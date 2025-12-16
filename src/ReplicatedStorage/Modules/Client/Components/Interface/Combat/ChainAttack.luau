local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = ReplicatedStorage.Modules.Client
local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local Interface = require(Client.Classes.Interface)

local Component = Interface.new("ChainAttack", "HUD")

local SwitchIcons = {
    [GameEnum.Device.Desktop] = {
        Left = 7031930012,
        Right = 7049040343,
    },

    [GameEnum.Device.Console] = {
        Right = 82590775321190,
        Left = 93081003637759,
    }
}


function Component:Link()
    local PlayerGui = Players.LocalPlayer.PlayerGui
    local HUD = PlayerGui:WaitForChild("FullScreenHUD", 10);
    if not HUD then return end;

    return HUD.Screen:WaitForChild("ChainAttack")
end

---
function UpdateKeyIcons()
    local GUI = Component:GetFrame()

    local Left = GUI.LeftOption.Key.Icon
    local Right = GUI.RightOption.Key.Icon
    local DeviceIcons = SwitchIcons[Inputs:GetDevice()] or SwitchIcons[GameEnum.Device.Desktop]

    Left.Image = 'rbxassetid:// ' .. DeviceIcons.Left
    Right.Image = 'rbxassetid:// ' .. DeviceIcons.Right
end


---
local CompThread: thread? = nil;
function Component:Show()
    if CompThread then
        task.cancel(CompThread)
        CompThread = nil
    end

    local MainFrame = Component:GetFrame()

    MainFrame.Visible = true
    MainFrame.LeftOption.UIScale.Scale = 0
    MainFrame.RightOption.UIScale.Scale = 0
    MainFrame.Line.GroupTransparency = 1
    MainFrame.CAText.TextTransparency = 1
    MainFrame.ChoiceText.TextTransparency = 1
    MainFrame.ChoiceText.UIStroke.Transparency = 1
    MainFrame.Line.UIStroke.Transparency = 1

    Effects:Tween(MainFrame.ChoiceText.UIStroke, {.3, 'Quad'}, { Transparency = 0.75 })
    Effects:Tween(MainFrame.ChoiceText, {.3, 'Quad'}, { TextTransparency = 0.85 })
    Effects:Tween(MainFrame.CAText, {.3, 'Quad'}, { TextTransparency = 0 })
    Effects:Tween(MainFrame.LeftOption.UIScale, {.15, 'Back'}, { Scale = 1 })
    Effects:Tween(MainFrame.RightOption.UIScale, {.15, 'Back'}, { Scale = 1 })
    Effects:Tween(MainFrame.Line, {.15, 'Quad'}, { GroupTransparency = 0 })
    Effects:Tween(MainFrame.Line.UIStroke, {.15, 'Quad'}, { Transparency = 0 })

    ---
    UpdateKeyIcons()

    MainFrame.Line.Fill.Size = UDim2.fromScale(1, 1)

    Effects:Tween(MainFrame.Line.Fill, {Statics.Chain_Attack_Invulnerability_Time}, { Size = UDim2.fromScale(0, 1) })

    --
    CompThread = task.delay(Statics.Chain_Attack_Invulnerability_Time, function()
        Component:Close()
    end)
end

function Component:Choose(Side: number)
    
end

function Component:Close()
    local MainFrame = Component:GetFrame()

    Effects:Tween(MainFrame.ChoiceText.UIStroke, {.3, 'Quad'}, { Transparency = 1 })
    Effects:Tween(MainFrame.ChoiceText, {.3, 'Quad'}, { TextTransparency = 1 })
    Effects:Tween(MainFrame.CAText, {.3, 'Quad'}, { TextTransparency = 1 })

    Effects:Tween(MainFrame.LeftOption.UIScale, {.15, 'Back'}, { Scale = 0 })
    Effects:Tween(MainFrame.RightOption.UIScale, {.15, 'Back'}, { Scale = 0 })
    Effects:Tween(MainFrame.Line, {.15, 'Quad'}, { GroupTransparency = 1 })
    Effects:Tween(MainFrame.Line.UIStroke, {.15, 'Quad'}, { Transparency = 1 })
end


return Component