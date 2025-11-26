--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local UIStates = require(Client.States.Interface)
local NavStates = require(Client.States.Navigation)
local InterfaceClass = require(Client.Classes.Interface)

-- comp def
local Component = InterfaceClass.new("Dialogue", "Dialogue")
local States = {
    InAnimation = false,
    IsOpen = false,
    DialogueToEnd = Signal.new(),
}

function WaitForAnimation()
    repeat
        task.wait()    
    until not States.InAnimation
end

function SkipCurrentDialogue()
    States.DialogueToEnd:Fire()
end

function Component:Link(Player: Player): Instance?
    local GUI = Player.PlayerGui
    if not GUI:FindFirstChild("LobbyHUD") then
        return
    end

    local HUD = GUI.LobbyHUD:WaitForChild("Screen", 2)
    if not HUD then
        return
    end

    return HUD:WaitForChild("Dialogues", 10)
end

function Component:Init()

    local MainFrame = Component:GetFrame()
    local Box = MainFrame.Main

    Component:BindToStateChange(function(State: boolean)
        MainFrame.Visible = true
        Box.Visible = true
        UIStates:Set("DIALOGUE", State)

        if State then
            NavStates:Set("Movement_Locked", true)
            States.InAnimation = true


            Box.Size = UDim2.fromScale(0.05, .25)
            Box.Position = UDim2.fromScale(0.5, 1.2)

            Effects:Tween(Box, {.15, 'Back'}, {Position = UDim2.fromScale(0.5, 0.85)})
            task.delay(.1, function()
                Effects:Tween(Box, {.25, 'Back'}, {Size = UDim2.fromScale(0.45, .25)})

                task.wait(.15)
                States.InAnimation = false
            end)
        else
            Box.Position = UDim2.fromScale(0.5, 1.2)

            NavStates:Set("Movement_Locked", false)        
        end
    end)

    self:Set(false)

    Inputs:Bind(Enum.UserInputType.MouseButton1, {
        Callback = function()
            if States.IsOpen and not States.InAnimation then
                SkipCurrentDialogue()
            end
        end,
        Release = false,
    })
end

function Component:OpenDialogue(Name: string, Data: {}): boolean
    if States.IsOpen then
        return false;
    end

    States.IsOpen = true

    local Frame = Component:GetFrame()
    local Box = Frame.Main

    Component:Set(true)

    --
    Box.CharacterName.Visible = false
    Box.NameFrame.UIStroke.Enabled = false
    Box.NameFrame.Size = UDim2.fromScale(0, 0.179)

    WaitForAnimation()

    Component:ShowName(Name)
    Component:DisplayDialogue(Data[1])

    return true
end

function Component:CloseDialogue()
    States.IsOpen = false
    Component:Set(false)

    States.DialogueToEnd:DisconnectAll()
end

function Component:DisplayDialogue(Line: string)
    local Frame = Component:GetFrame()
    local Box = Frame.Main

    Box.DialogueText.TextSize = ScreenUtil:GetTextSize(35)
    
    task.spawn(function()
        for t = 1, #Line do
            Box.DialogueText.Text = Line:sub(1, t)
            task.wait()
        end

    end)
end

function Component:ShowName(Name: string)
    local Frame = Component:GetFrame()
    local Box = Frame.Main
    
    local Count = math.max(#Name - 11, 0)
    local ExtraSize = Count * 0.03/2 + math.clamp(#Name-11, 0 ,1) * 0.005
    local BaseSize = UDim2.fromScale(0.25 + ExtraSize, 0.179)
    local Rate = 0.5 - (BaseSize.X.Scale - 0.25)

    Effects:Tween(Box.NameFrame, {.25, 'Back'}, {Size = BaseSize})
    Effects:Tween(Box.NameFrame.BG, {.25, 'Quad'}, {TileSize = UDim2.fromScale(Rate, 2)})

    Box.NameFrame.UIStroke.Enabled = true
    Box.CharacterName.Visible = true
    Box.CharacterName.Text = Name--string.sub(Name, 1, i)
end

function Component:BoxSkipped(fn: () -> ())
    States.DialogueToEnd:Connect(fn)
end

return Component
